import 'package:drift/drift.dart';

/// Key/value store (`app_meta` from PRD §9.1).
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
