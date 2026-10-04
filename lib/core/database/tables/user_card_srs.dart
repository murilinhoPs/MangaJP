import 'package:drift/drift.dart';

import 'user_cards.dart';

/// SM-2 fields for a card (`card_srs`): ease, interval, repetitions, due, phase.
@DataClassName('CardSrsRow')
class UserCardSrs extends Table {
  @override
  String get tableName => 'card_srs';

  TextColumn get cardId => text().references(UserCards, #id)();
  RealColumn get easeFactor => real()();
  RealColumn get intervalDays => real()();
  IntColumn get repetitions => integer()();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get phase => text()();
  TextColumn get engineId => text()();

  @override
  Set<Column<Object>> get primaryKey => {cardId};
}
