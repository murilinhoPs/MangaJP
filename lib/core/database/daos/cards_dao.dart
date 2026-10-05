import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_card_srs.dart';
import '../tables/user_cards.dart';
import '../tables/user_review_logs.dart';
import '../tables/user_words.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [UserCards, UserCardSrs, UserReviewLogs, UserWords])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Future<UserCard?> cardById(String cardId) {
    return (select(
      userCards,
    )..where((t) => t.id.equals(cardId))).getSingleOrNull();
  }

  Future<UserCard?> cardForWord(String wordId) {
    return (select(
      userCards,
    )..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
  }

  Future<CardSrsRow?> srsFor(String cardId) {
    return (select(
      userCardSrs,
    )..where((t) => t.cardId.equals(cardId))).getSingleOrNull();
  }

  Future<void> insertCard(UserCardsCompanion row) {
    return into(userCards).insert(row);
  }

  Future<void> insertSrs(UserCardSrsCompanion row) {
    return into(userCardSrs).insert(row);
  }

  Future<void> updateSuspendReason(String cardId, String? reason) {
    return (update(userCards)..where((t) => t.id.equals(cardId))).write(
      UserCardsCompanion(suspendReason: Value(reason)),
    );
  }

  Future<void> writeSrs(String cardId, UserCardSrsCompanion row) {
    return (update(
      userCardSrs,
    )..where((t) => t.cardId.equals(cardId))).write(row);
  }

  Future<void> insertLog(UserReviewLogsCompanion row) {
    return into(userReviewLogs).insert(row);
  }

  Future<ReviewLogRow?> latestLogFor(String cardId) {
    return (select(userReviewLogs)
          ..where((t) => t.cardId.equals(cardId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.ratedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> deleteLogsFor(String cardId) {
    return (delete(userReviewLogs)..where((t) => t.cardId.equals(cardId))).go();
  }

  Future<void> deleteSrs(String cardId) {
    return (delete(userCardSrs)..where((t) => t.cardId.equals(cardId))).go();
  }

  Future<void> deleteCard(String cardId) {
    return (delete(userCards)..where((t) => t.id.equals(cardId))).go();
  }

  /// Distinct cards whose first non-drill `review_logs` row is at or after
  /// [since]. That is a `neu` card leaving new on this study-day.
  Future<int> countNewIntroducedSince(DateTime since) async {
    final today =
        await (select(userReviewLogs)..where(
              (t) =>
                  t.isDrill.equals(0) & t.ratedAt.isBiggerOrEqualValue(since),
            ))
            .get();
    final ids = {for (final log in today) log.cardId};
    if (ids.isEmpty) {
      return 0;
    }
    final earlier =
        await (select(userReviewLogs)..where(
              (t) =>
                  t.isDrill.equals(0) &
                  t.ratedAt.isSmallerThanValue(since) &
                  t.cardId.isIn(ids),
            ))
            .get();
    final seenBefore = {for (final log in earlier) log.cardId};
    return ids.difference(seenBefore).length;
  }

  /// Due, unsuspended cards: learning/relearning, then review, then new
  /// (`neu`). Oldest `card_srs.due_at` first inside each group.
  Future<List<(UserCard, CardSrsRow, UserWord)>> dueQueue(DateTime now) async {
    final query = select(userCards).join([
      innerJoin(userCardSrs, userCardSrs.cardId.equalsExp(userCards.id)),
      innerJoin(userWords, userWords.id.equalsExp(userCards.wordId)),
    ]);
    query.where(
      userCards.suspendReason.isNull() &
          userCardSrs.dueAt.isSmallerOrEqualValue(now),
    );
    query.orderBy([
      OrderingTerm.asc(
        const CustomExpression<int>(
          "CASE WHEN card_srs.phase IN ('learning', 'relearning') THEN 0 "
          "WHEN card_srs.phase = 'review' THEN 1 ELSE 2 END",
        ),
      ),
      OrderingTerm.asc(userCardSrs.dueAt),
      OrderingTerm.asc(userCards.id),
    ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          row.readTable(userCards),
          row.readTable(userCardSrs),
          row.readTable(userWords),
        ),
    ];
  }
}
