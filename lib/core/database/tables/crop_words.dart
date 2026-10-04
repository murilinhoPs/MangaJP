import 'package:drift/drift.dart';

import 'captured_crops.dart';
import 'user_words.dart';

/// Link from a crop to a saved word (`crop_words`).
class CropWords extends Table {
  @override
  String get tableName => 'crop_words';

  TextColumn get cropId => text().references(CapturedCrops, #id)();
  TextColumn get wordId => text().references(UserWords, #id)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cropId, wordId};
}
