import 'package:drift/drift.dart';

import 'user_cards.dart';

/// One answered review (`review_logs`). Rating 1–4 and SM-2 quality together.
@DataClassName('ReviewLogRow')
class UserReviewLogs extends Table {
  @override
  String get tableName => 'review_logs';

  TextColumn get id => text()();
  TextColumn get cardId => text().references(UserCards, #id)();
  DateTimeColumn get ratedAt => dateTime()();
  IntColumn get rating => integer()();
  IntColumn get quality => integer()();
  TextColumn get engineId => text()();
  IntColumn get isDrill => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
