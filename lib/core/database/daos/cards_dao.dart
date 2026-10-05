import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_card_srs.dart';
import '../tables/user_cards.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [UserCards, UserCardSrs])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

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

  Future<void> deleteSrs(String cardId) {
    return (delete(userCardSrs)..where((t) => t.cardId.equals(cardId))).go();
  }

  Future<void> deleteCard(String cardId) {
    return (delete(userCards)..where((t) => t.id.equals(cardId))).go();
  }
}
