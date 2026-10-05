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
class FlashcardsRepository {
  const FlashcardsRepository(this._db);

  final AppDatabase _db;

  /// Mark [wordId] as learning and ensure it has one vocab card.
  ///
  /// Missing card → insert with [initialCardSrsState] (`sm2-jr@1` golden).
  /// Existing card → same row, same interval / ease / repetitions / due / phase.
  /// Already learning with a card → no-op.
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
}
