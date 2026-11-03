import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/captured_pages.dart';
import '../tables/saved_kanji.dart';

part 'saved_kanji_dao.g.dart';

@DriftAccessor(tables: [SavedKanji, CapturedPages])
class SavedKanjiDao extends DatabaseAccessor<AppDatabase>
    with _$SavedKanjiDaoMixin {
  SavedKanjiDao(super.db);

  Future<SavedKanjiData?> byLiteral(String literal) {
    return (select(
      savedKanji,
    )..where((t) => t.literal.equals(literal))).getSingleOrNull();
  }

  /// Newest [SavedKanji.savedAt] first.
  Future<List<SavedKanjiData>> listNewestFirst() {
    return (select(
      savedKanji,
    )..orderBy([(t) => OrderingTerm.desc(t.savedAt)])).get();
  }

  /// Inserts when missing. Duplicate [SavedKanji.literal] is a no-op.
  Future<int> insertIgnore(SavedKanjiCompanion row) {
    return into(savedKanji).insert(row, mode: InsertMode.insertOrIgnore);
  }

  Future<int> deleteLiteral(String literal) {
    return (delete(savedKanji)..where((t) => t.literal.equals(literal))).go();
  }
}
