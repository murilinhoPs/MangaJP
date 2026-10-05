import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/srs/card_srs_state.dart';
import '../../../core/srs/sm2_jr.dart';
import '../../../core/srs/srs_engine.dart';
import '../../../core/utils/ids.dart';
import '../domain/review_card.dart';

part 'review_repository.g.dart';

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) {
  return ReviewRepository(ref.watch(appDatabaseProvider));
}

/// Due queue and first-answer write for `/review`.
///
/// Queue: unsuspended (`suspend_reason` null) cards with `card_srs.due_at`
/// ≤ now. Order: learning/relearning, then review, then new (`neu`); oldest
/// due first inside each group.
///
/// [answer] writes `review_logs` (rating 1–4, quality 0/3/4/5, `sm2-jr@1`,
/// `is_drill=0`) and updates `card_srs` via [SrsEngine.schedule] in one
/// transaction. It does not change `word_states`.
class ReviewRepository {
  ReviewRepository(
    this._db, {
    this._engine = const Sm2JrEngine(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final SrsEngine _engine;
  final DateTime Function() _clock;

  DateTime _nowUtc() {
    final now = _clock();
    return now.isUtc ? now : now.toUtc();
  }

  Future<List<ReviewCard>> dueQueue() async {
    final rows = await _db.cardsDao.dueQueue(_nowUtc());
    return [for (final row in rows) _toCard(row)];
  }

  Future<ReviewCard?> nextDue() async {
    final queue = await dueQueue();
    return queue.isEmpty ? null : queue.first;
  }

  /// Record [rating] and reschedule with the existing `sm2-jr@1` engine.
  ///
  /// Missing or suspended card → no-op. `word_states` is not rewritten.
  Future<void> answer(String cardId, ReviewRating rating) {
    return _db.transaction(() async {
      final card = await _db.cardsDao.cardById(cardId);
      if (card == null || card.suspendReason != null) {
        return;
      }
      final srsRow = await _db.cardsDao.srsFor(cardId);
      if (srsRow == null) {
        return;
      }

      final now = _nowUtc();
      final prev = _srsFromRow(srsRow);
      final quality = qualityFor(rating);
      final next = _engine.schedule(prev, quality, now);

      await _db.cardsDao.insertLog(
        UserReviewLogsCompanion.insert(
          id: newId(),
          cardId: cardId,
          ratedAt: now,
          rating: ratingFor(rating),
          quality: quality,
          engineId: _engine.engineId,
          isDrill: 0,
        ),
      );
      await _db.cardsDao.writeSrs(
        cardId,
        UserCardSrsCompanion(
          easeFactor: Value(next.easeFactor),
          intervalDays: Value(next.intervalDays),
          repetitions: Value(next.repetitions),
          dueAt: Value(next.dueAt),
          phase: Value(next.phase.name),
          engineId: Value(next.engineId),
        ),
      );
    });
  }

  ReviewCard _toCard((UserCard, CardSrsRow, UserWord) row) {
    final (card, srs, word) = row;
    return ReviewCard(
      cardId: card.id,
      wordId: word.id,
      seq: word.seq,
      lemma: word.lemma,
      reading: word.reading,
      srs: _srsFromRow(srs),
    );
  }

  CardSrsState _srsFromRow(CardSrsRow row) {
    return CardSrsState(
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
      dueAt: row.dueAt,
      phase: CardPhase.values.byName(row.phase),
      engineId: row.engineId,
    );
  }
}
