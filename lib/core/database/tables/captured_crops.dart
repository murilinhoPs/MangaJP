import 'package:drift/drift.dart';

import 'captured_pages.dart';

/// One balloon crop + persisted OCR text (`crops`, PRD §9.4).
class CapturedCrops extends Table {
  @override
  String get tableName => 'crops';

  TextColumn get id => text()();
  TextColumn get pageId => text().references(CapturedPages, #id)();
  TextColumn get ocrText => text()();
  TextColumn get engineId => text()();
  RealColumn get left => real()();
  RealColumn get top => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
