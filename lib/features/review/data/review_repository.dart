import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/srs/card_srs_state.dart';
import '../../../core/srs/sm2_jr.dart';
import '../../../core/srs/srs_engine.dart';
import '../../../core/utils/ids.dart';
import '../domain/home_review_counts.dart';
import '../domain/new_per_day.dart';
import '../domain/review_card.dart';
import '../domain/study_day.dart';

part 'review_repository.g.dart';

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) {
  return ReviewRepository(ref.watch(appDatabaseProvider));
}

/// Bumped after a persisted `/review` answer so Home refetches due / novos hoje.
@Riverpod(keepAlive: true)
class ReviewRevision extends _$ReviewRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Due queue and answer write for `/review`.
///
/// Queue: unsuspended (`suspend_reason` null) cards with `card_srs.due_at`
/// ≤ now. Order: learning/relearning, then review, then new (`neu`); oldest
/// due first inside each group. At most [NewPerDay.limit] `neu` cards per
/// study-day (first non-drill answer counts once; leftover `neu` stay out
/// until the next 04:00 America/Sao_Paulo). Learning / relearning / review
/// due cards always enter.
///
/// [answer] writes `review_logs` (rating 1–4, quality 0/3/4/5, `sm2-jr@1`)
/// in one transaction. The first answer of the card on the current study-day
/// (America/Sao_Paulo, rolls at 04:00) updates `card_srs` via
/// [SrsEngine.schedule] and sets `is_drill=0`. A later answer that same
/// study-day sets `is_drill=1` and leaves `card_srs` unchanged. It does not
/// change `word_states`.
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
    return (await _dueSnapshot()).queue;
  }

  /// Home **Revisar** block: non-`neu` due now, and `neu` already counted today.
  Future<HomeReviewCounts> homeCounts() async {
    final snap = await _dueSnapshot();
    var due = 0;
    for (final card in snap.queue) {
      if (card.srs.phase != CardPhase.neu) {
        due++;
      }
    }
    return HomeReviewCounts(due: due, newToday: snap.introduced);
  }

  Future<ReviewCard?> nextDue() async {
    final queue = await dueQueue();
    return queue.isEmpty ? null : queue.first;
  }

  Future<({List<ReviewCard> queue, int introduced})> _dueSnapshot() async {
    final now = _nowUtc();
    final rows = await _db.cardsDao.dueQueue(now);
    final introduced = await _db.cardsDao.countNewIntroducedSince(
      StudyDay.startOf(now),
    );
    final latestRatedAt = await _latestRatedAt([
      for (final row in rows) row.$1.id,
    ]);
    final queue = applyNewPerDayLimit(
      [
        for (final row in rows)
          _toCard(
            row,
            isDrill: StudyDay.isDrill(now, latestRatedAt[row.$1.id]),
          ),
      ],
      introduced: introduced,
      isNew: (card) => card.srs.phase == CardPhase.neu,
    );
    return (queue: queue, introduced: introduced);
  }

  Future<Map<String, DateTime>> _latestRatedAt(List<String> cardIds) async {
    if (cardIds.isEmpty) {
      return {};
    }
    final logs = await (_db.select(
      _db.userReviewLogs,
    )..where((t) => t.cardId.isIn(cardIds))).get();
    final latest = <String, ReviewLogRow>{};
    for (final log in logs) {
      final prev = latest[log.cardId];
      if (prev == null ||
          log.ratedAt.isAfter(prev.ratedAt) ||
          (log.ratedAt.isAtSameMomentAs(prev.ratedAt) &&
              log.id.compareTo(prev.id) > 0)) {
        latest[log.cardId] = log;
      }
    }
    return {for (final entry in latest.entries) entry.key: entry.value.ratedAt};
  }

  /// Record [rating]. First answer of the study-day reschedules; later ones
  /// are drill.
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
      final last = await _db.cardsDao.latestLogFor(cardId);
      final drill = StudyDay.isDrill(now, last?.ratedAt);
      final quality = qualityFor(rating);

      await _db.cardsDao.insertLog(
        UserReviewLogsCompanion.insert(
          id: newId(),
          cardId: cardId,
          ratedAt: now,
          rating: ratingFor(rating),
          quality: quality,
          engineId: _engine.engineId,
          isDrill: drill ? 1 : 0,
        ),
      );
      if (drill) {
        return;
      }

      final prev = _srsFromRow(srsRow);
      final next = _engine.schedule(prev, quality, now);
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

  ReviewCard _toCard(
    (UserCard, CardSrsRow, UserWord) row, {
    required bool isDrill,
  }) {
    final (card, srs, word) = row;
    return ReviewCard(
      cardId: card.id,
      wordId: word.id,
      seq: word.seq,
      lemma: word.lemma,
      reading: word.reading,
      srs: _srsFromRow(srs),
      userNote: word.userNote,
      isDrill: isDrill,
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
