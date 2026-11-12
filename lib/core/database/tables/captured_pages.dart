import 'package:drift/drift.dart';

/// Shared page (`pages`, PRD §9.4). One row per imported / shared image.
class CapturedPages extends Table {
  @override
  String get tableName => 'pages';

  TextColumn get id => text()();
  TextColumn get sha256 => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// Copied page image in app documents (`path_provider`). Null on pages
  /// captured before schema 10 — overlay stays hidden and `/pages/:id`
  /// keeps the text cards.
  TextColumn get imagePath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
