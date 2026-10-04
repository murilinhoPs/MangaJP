import 'package:drift/drift.dart';

/// Shared page (`pages`, PRD §9.4). One row per imported / shared image.
class CapturedPages extends Table {
  @override
  String get tableName => 'pages';

  TextColumn get id => text()();
  TextColumn get sha256 => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
