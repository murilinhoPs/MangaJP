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

  Future<void> updateCropOcr({
    required String cropId,
    required String ocrText,
  }) {
    return (update(
      capturedCrops,
    )..where((t) => t.id.equals(cropId))).write(
      CapturedCropsCompanion(ocrText: Value(ocrText)),
    );
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

  /// Every page, newest `created_at` first. `/pages` history (F21).
  Future<List<CapturedPage>> listPages() {
    return (select(
      capturedPages,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// Pages + OCR of the earliest crop, newest page first. One join, not N+1.
  Future<List<(CapturedPage, String?)>> listPagesWithFirstOcr() {
    return _pagesWithFirstOcr().get().then(_firstOcrPerPage);
  }

  /// Same as [listPagesWithFirstOcr], live on `pages` / `crops` writes.
  Stream<List<(CapturedPage, String?)>> watchPagesWithFirstOcr() {
    return _pagesWithFirstOcr().watch().map(_firstOcrPerPage);
  }

  JoinedSelectStatement _pagesWithFirstOcr() {
    final query = select(capturedPages).join([
      leftOuterJoin(
        capturedCrops,
        capturedCrops.pageId.equalsExp(capturedPages.id),
      ),
    ]);
    query.orderBy([
      OrderingTerm.desc(capturedPages.createdAt),
      OrderingTerm.asc(capturedCrops.createdAt),
      OrderingTerm.asc(capturedCrops.id),
    ]);
    return query;
  }

  List<(CapturedPage, String?)> _firstOcrPerPage(List<TypedResult> rows) {
    final seen = <String>{};
    final out = <(CapturedPage, String?)>[];
    for (final row in rows) {
      final page = row.readTable(capturedPages);
      if (!seen.add(page.id)) {
        continue;
      }
      final crop = row.readTableOrNull(capturedCrops);
      out.add((page, crop?.ocrText));
    }
    return out;
  }

  Future<int> countPages() async {
    final count = capturedPages.id.count();
    final row = await (selectOnly(
      capturedPages,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }
}
