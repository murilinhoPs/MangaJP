import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/captured_crops.dart';
import '../tables/captured_pages.dart';

part 'pages_dao.g.dart';

@DriftAccessor(tables: [CapturedPages, CapturedCrops])
class PagesDao extends DatabaseAccessor<AppDatabase> with _$PagesDaoMixin {
  PagesDao(super.db);

  Future<void> insertPage(CapturedPagesCompanion row) {
    return into(capturedPages).insert(row, mode: InsertMode.insertOrIgnore);
  }

  Future<void> insertCrop(CapturedCropsCompanion row) {
    return into(capturedCrops).insert(row);
  }

  Future<List<CapturedCrop>> listCrops() {
    return (select(
      capturedCrops,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  Future<List<CapturedCrop>> cropsForPage(String pageId) {
    return (select(capturedCrops)
          ..where((t) => t.pageId.equals(pageId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<CapturedPage>> listRecentPages(int limit) {
    return (select(capturedPages)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<int> countPages() async {
    final rows = await select(capturedPages).get();
    return rows.length;
  }
}
