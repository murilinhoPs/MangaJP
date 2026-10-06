import 'package:drift/drift.dart';

/// User word (`words`). JMdict rows are keyed by unique `seq`. Custom rows
/// (no JMdict hit) use id `custom:<uuid>` and a required [userNote].
class UserWords extends Table {
  @override
  String get tableName => 'words';

  TextColumn get id => text()();
  IntColumn get seq => integer().unique()();
  TextColumn get lemma => text()();
  TextColumn get reading => text()();
  TextColumn get userNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
