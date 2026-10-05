import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/utils/ids.dart';
import '../domain/word_state.dart';

part 'words_repository.g.dart';

@Riverpod(keepAlive: true)
WordsRepository wordsRepository(Ref ref) {
  return WordsRepository(ref.watch(appDatabaseProvider));
}

/// Words + word_states + crop_words. Save never creates a card.
///
/// [removeFromNotebook] deletes the word and dependents (state, crop_words,
/// and if a card exists: review_logs, card_srs, cards). Crops and pages stay.
/// FKs have no ON DELETE CASCADE; dependents are deleted in the same
/// transaction. Does not insert a leftover `word_states` row.
class WordsRepository {
  const WordsRepository(this._db);

  final AppDatabase _db;

  /// True when [wordId] has a `cards` row. Used by Caderno confirmations.
  Future<bool> hasCard(String wordId) async {
    return (await _db.cardsDao.cardForWord(wordId)) != null;
  }

  /// Persist the chosen JMdict entry against [cropId].
  ///
  /// Writes `words` (keyed by `seq`), `word_states=saved` when missing, and
  /// `crop_words`. A second save is a no-op. Existing learning / known /
  /// ignored states are left as-is.
  Future<void> saveFromLookup({
    required String cropId,
    required int seq,
    required String lemma,
    required String reading,
  }) {
    return _db.transaction(() async {
      final existing = await _db.wordsDao.wordBySeq(seq);
      final wordId = existing?.id ?? newId();
      if (existing == null) {
        await _db.wordsDao.insertWord(
          UserWordsCompanion.insert(
            id: wordId,
            seq: seq,
            lemma: lemma,
            reading: reading,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }

      final stateRow = await _db.wordsDao.stateFor(wordId);
      if (stateRow == null) {
        await _db.wordsDao.insertState(
          UserWordStatesCompanion.insert(
            wordId: wordId,
            state: WordState.saved.name,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      } else {
        final current = WordState.fromDb(stateRow.state);
        if (!current.isProtected && current != WordState.saved) {
          await _db.wordsDao.updateState(
            wordId: wordId,
            state: WordState.saved.name,
            updatedAt: DateTime.now().toUtc(),
          );
        }
      }

      await _db.wordsDao.insertCropWord(
        CropWordsCompanion.insert(
          cropId: cropId,
          wordId: wordId,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  /// Delete [wordId] from the Caderno.
  ///
  /// Missing word → no-op. Existing word → drop that word's `crop_words`,
  /// `word_states`, and `words`. If a card exists, drop that card's
  /// `review_logs`, then `card_srs`, then `cards` (FK order) first. Crops
  /// and pages are not rewritten. No leftover `word_states` row is inserted.
  Future<void> removeFromNotebook(String wordId) {
    return _db.transaction(() async {
      final word = await _db.wordsDao.wordById(wordId);
      if (word == null) {
        return;
      }

      final card = await _db.cardsDao.cardForWord(wordId);
      if (card != null) {
        await _db.cardsDao.deleteLogsFor(card.id);
        await _db.cardsDao.deleteSrs(card.id);
        await _db.cardsDao.deleteCard(card.id);
      }

      await _db.wordsDao.deleteCropWordsFor(wordId);
      await _db.wordsDao.deleteState(wordId);
      await _db.wordsDao.deleteWord(wordId);
    });
  }
}
