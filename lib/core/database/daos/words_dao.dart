import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/crop_words.dart';
import '../tables/user_word_states.dart';
import '../tables/user_words.dart';

part 'words_dao.g.dart';

@DriftAccessor(tables: [UserWords, UserWordStates, CropWords])
class WordsDao extends DatabaseAccessor<AppDatabase> with _$WordsDaoMixin {
  WordsDao(super.db);

  Future<UserWord?> wordBySeq(int seq) {
    return (select(
      userWords,
    )..where((t) => t.seq.equals(seq))).getSingleOrNull();
  }

  Future<UserWordState?> stateFor(String wordId) {
    return (select(
      userWordStates,
    )..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
  }

  Future<void> insertWord(UserWordsCompanion row) {
    return into(userWords).insert(row);
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
}
