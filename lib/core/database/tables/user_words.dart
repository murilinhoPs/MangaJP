import 'package:drift/drift.dart';

/// Dictionary-backed user word (`words`). Identity is JMdict `seq`.
class UserWords extends Table {
  @override
  String get tableName => 'words';

  TextColumn get id => text()();
  IntColumn get seq => integer().unique()();
  TextColumn get lemma => text()();
  TextColumn get reading => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
