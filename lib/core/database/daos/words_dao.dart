import 'package:drift/drift.dart';

import '../../utils/graphemes.dart';
import '../../utils/ids.dart';
import '../app_database.dart';
import '../tables/captured_crops.dart';
import '../tables/crop_words.dart';
import '../tables/user_word_states.dart';
import '../tables/user_words.dart';

part 'words_dao.g.dart';

@DriftAccessor(tables: [UserWords, UserWordStates, CropWords, CapturedCrops])
class WordsDao extends DatabaseAccessor<AppDatabase> with _$WordsDaoMixin {
  WordsDao(super.db);

  Future<UserWord?> wordById(String id) {
    return (select(userWords)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<UserWord?> wordBySeq(int seq) {
    return (select(
      userWords,
    )..where((t) => t.seq.equals(seq))).getSingleOrNull();
  }

  /// Custom row whose [UserWords.lemmaKey] equals [lemmaKey].
  Future<UserWord?> customWordByLemmaKey(String lemmaKey) {
    return (select(userWords)..where(
          (t) =>
              t.id.like('$customWordIdPrefix%') & t.lemmaKey.equals(lemmaKey),
        ))
        .getSingleOrNull();
  }

  Future<void> insertWord(UserWordsCompanion row) {
    if (row.lemma.present) {
      final key = stripVariationSelectors(row.lemma.value);
      if (!row.lemmaKey.present || row.lemmaKey.value != key) {
        row = row.copyWith(lemmaKey: Value(key));
      }
    }
    return into(userWords).insert(row);
  }

  Future<void> updateUserNote(String wordId, String? note) {
    return (update(userWords)..where((t) => t.id.equals(wordId))).write(
      UserWordsCompanion(userNote: Value(note)),
    );
  }

  Future<void> insertState(UserWordStatesCompanion row) {
    return into(userWordStates).insert(row);
  }

  Future<void> updateState({
    required String wordId,
    required String state,
    required DateTime updatedAt,
  }) {
    return (update(
      userWordStates,
    )..where((t) => t.wordId.equals(wordId))).write(
      UserWordStatesCompanion(state: Value(state), updatedAt: Value(updatedAt)),
    );
  }

  Future<void> insertCropWord(CropWordsCompanion row) {
    return into(cropWords).insert(row, mode: InsertMode.insertOrIgnore);
  }

  Future<void> deleteCropWordsFor(String wordId) {
    return (delete(cropWords)..where((t) => t.wordId.equals(wordId))).go();
  }

  Future<void> deleteState(String wordId) {
    return (delete(userWordStates)..where((t) => t.wordId.equals(wordId))).go();
  }

  Future<void> deleteWord(String wordId) {
    return (delete(userWords)..where((t) => t.id.equals(wordId))).go();
  }

  /// Earliest `crop_words` link for [wordId], with that crop's OCR sentence.
  Future<CapturedCrop?> firstCropFor(String wordId) async {
    final query = select(capturedCrops).join([
      innerJoin(cropWords, cropWords.cropId.equalsExp(capturedCrops.id)),
    ]);
    query.where(cropWords.wordId.equals(wordId));
    query.orderBy([
      OrderingTerm.asc(cropWords.createdAt),
      OrderingTerm.asc(cropWords.cropId),
    ]);
    query.limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(capturedCrops);
  }

  Future<UserWordState?> stateFor(String wordId) {
    return (select(
      userWordStates,
    )..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
  }

  /// Words that have a listed study state, newest [UserWords.createdAt] first.
  ///
  /// [createdAt] is first-saved time: Save inserts the word once and never
  /// rewrites it. Optional [search] matches lemma or reading; optional
  /// [state] keeps a single listed state.
  Future<List<(UserWord, UserWordState)>> listWithStates({
    String search = '',
    String? state,
  }) async {
    final query = select(userWords).join([
      innerJoin(userWordStates, userWordStates.wordId.equalsExp(userWords.id)),
    ]);

    Expression<bool> predicate = userWordStates.state.isIn(const [
      'saved',
      'learning',
      'known',
      'ignored',
    ]);
    final trimmed = search.trim();
    if (trimmed.isNotEmpty) {
      final pattern = '%$trimmed%';
      predicate =
          predicate &
          (userWords.lemma.like(pattern) | userWords.reading.like(pattern));
    }
    if (state != null) {
      predicate = predicate & userWordStates.state.equals(state);
    }

    query.where(predicate);
    query.orderBy([OrderingTerm.desc(userWords.createdAt)]);

    final rows = await query.get();
    return [
      for (final row in rows)
        (row.readTable(userWords), row.readTable(userWordStates)),
    ];
  }
}
