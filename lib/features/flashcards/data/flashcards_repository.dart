import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/srs/sm2_jr.dart';
import '../../../core/utils/ids.dart';
import '../../words/domain/word_state.dart';
import '../domain/flashcard.dart';

part 'flashcards_repository.g.dart';

@Riverpod(keepAlive: true)
FlashcardsRepository flashcardsRepository(Ref ref) {
  return FlashcardsRepository(ref.watch(appDatabaseProvider));
}

/// Cards + card_srs. [learn] sets `word_states=learning` and creates a card
/// only when the word has none; existing SRS is never rewritten.
///
/// [markKnown] / [markIgnored] set `word_states` and, when a card exists,
/// `cards.suspend_reason`. They never create, delete, or reschedule a card.
///
/// [deleteCard] removes `cards` + `card_srs` (SRS first, FK) and sets
/// `word_states=saved`. The word and `crop_words` stay. No card → no-op on
/// the word (does not delete it, does not create a card). This schema has
/// no `review_logs` table; if that table already exists, only that card's
/// log rows are deleted. This method never creates the table.
class FlashcardsRepository {
  const FlashcardsRepository(this._db);

  final AppDatabase _db;

  /// Mark [wordId] as learning and ensure it has one vocab card.
  ///
  /// Missing card → insert with [initialCardSrsState] (`sm2-jr@1` golden).
  /// Existing card → same row, same interval / ease / repetitions / due / phase.
  /// A leftover `suspend_reason` is cleared; SRS is not rewritten.
  /// Already learning with a card and no suspend reason → no-op.
  Future<void> learn(String wordId) {
    return _db.transaction(() async {
      final word = await _db.wordsDao.wordById(wordId);
      if (word == null) {
        return;
      }

      final now = DateTime.now().toUtc();
      final stateRow = await _db.wordsDao.stateFor(wordId);
      final current = WordState.fromDb(stateRow?.state ?? '');
      if (stateRow == null) {
        await _db.wordsDao.insertState(
          UserWordStatesCompanion.insert(
            wordId: wordId,
            state: WordState.learning.name,
            updatedAt: now,
          ),
        );
      } else if (current != WordState.learning) {
        await _db.wordsDao.updateState(
          wordId: wordId,
          state: WordState.learning.name,
          updatedAt: now,
        );
      }

      final existing = await _db.cardsDao.cardForWord(wordId);
      if (existing != null) {
        if (existing.suspendReason != null) {
          await _db.cardsDao.updateSuspendReason(existing.id, null);
        }
        return;
      }

      final cardId = newId();
      final srs = initialCardSrsState(now);
      await _db.cardsDao.insertCard(
        UserCardsCompanion.insert(
          id: cardId,
          wordId: wordId,
          kind: FlashcardKind.vocab.name,
          createdAt: now,
        ),
      );
      await _db.cardsDao.insertSrs(
        UserCardSrsCompanion.insert(
          cardId: cardId,
          easeFactor: srs.easeFactor,
          intervalDays: srs.intervalDays,
          repetitions: srs.repetitions,
          dueAt: srs.dueAt,
          phase: srs.phase.name,
          engineId: srs.engineId,
        ),
      );
    });
  }

  /// Set `word_states=known`. If a card exists, set `suspend_reason=known`.
  Future<void> markKnown(String wordId) =>
      _setSuspended(wordId, WordState.known);

  /// Set `word_states=ignored`. If a card exists, set `suspend_reason=ignored`.
  Future<void> markIgnored(String wordId) =>
      _setSuspended(wordId, WordState.ignored);

  Future<void> _setSuspended(String wordId, WordState target) {
    assert(
      target == WordState.known || target == WordState.ignored,
      'suspend_reason is only known or ignored',
    );
    return _db.transaction(() async {
      final word = await _db.wordsDao.wordById(wordId);
      if (word == null) {
        return;
      }

      final stateRow = await _db.wordsDao.stateFor(wordId);
      final current = WordState.fromDb(stateRow?.state ?? '');
      final card = await _db.cardsDao.cardForWord(wordId);
      final stateAlready = stateRow != null && current == target;
      final reasonAlready = card == null || card.suspendReason == target.name;
      if (stateAlready && reasonAlready) {
        return;
      }

      final now = DateTime.now().toUtc();
      if (stateRow == null) {
        await _db.wordsDao.insertState(
          UserWordStatesCompanion.insert(
            wordId: wordId,
            state: target.name,
            updatedAt: now,
          ),
        );
      } else if (current != target) {
        await _db.wordsDao.updateState(
          wordId: wordId,
          state: target.name,
          updatedAt: now,
        );
      }

      if (card != null && card.suspendReason != target.name) {
        await _db.cardsDao.updateSuspendReason(card.id, target.name);
      }
    });
  }

  /// Delete the vocab card and its SRS. The word stays in the Caderno as saved.
  ///
  /// Missing word or missing card → no-op (does not delete the word, does not
  /// create a card). Existing card → delete `card_srs` then `cards`, then set
  /// `word_states=saved`.
  Future<void> deleteCard(String wordId) {
    return _db.transaction(() async {
      final word = await _db.wordsDao.wordById(wordId);
      if (word == null) {
        return;
      }

      final card = await _db.cardsDao.cardForWord(wordId);
      if (card == null) {
        return;
      }

      await _deleteReviewLogsIfPresent(card.id);
      await _db.cardsDao.deleteSrs(card.id);
      await _db.cardsDao.deleteCard(card.id);

      final now = DateTime.now().toUtc();
      final stateRow = await _db.wordsDao.stateFor(wordId);
      final current = WordState.fromDb(stateRow?.state ?? '');
      if (stateRow == null) {
        await _db.wordsDao.insertState(
          UserWordStatesCompanion.insert(
            wordId: wordId,
            state: WordState.saved.name,
            updatedAt: now,
          ),
        );
        return;
      }
      if (current != WordState.saved) {
        await _db.wordsDao.updateState(
          wordId: wordId,
          state: WordState.saved.name,
          updatedAt: now,
        );
      }
    });
  }

  /// `review_logs` is not in this schema. If a future migration adds it,
  /// drop only the rows for [cardId]; never create the table here.
  Future<void> _deleteReviewLogsIfPresent(String cardId) async {
    final rows = await _db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'review_logs'",
        )
        .get();
    if (rows.isEmpty) {
      return;
    }
    await _db.customStatement('DELETE FROM review_logs WHERE card_id = ?', [
      cardId,
    ]);
  }
}
