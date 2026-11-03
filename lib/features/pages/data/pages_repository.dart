import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/utils/ids.dart';
import '../domain/page.dart';
import '../domain/page_crop.dart';
import '../domain/page_list_entry.dart';
import '../domain/recent_pages.dart';

part 'pages_repository.g.dart';

@Riverpod(keepAlive: true)
PagesRepository pagesRepository(Ref ref) {
  return PagesRepository(ref.watch(appDatabaseProvider));
}

/// Pages + crops persistence (M1.1: OCR text; lookup/save is dictionary/words).
class PagesRepository {
  const PagesRepository(this._db);

  final AppDatabase _db;

  /// Persist one OCR crop on [pageId].
  ///
  /// Dedupes by **geometry** (`left`/`top`/`width`/`height`) on that page:
  /// identical rects count as one row, and an OCR retry of a crop already
  /// written for this page returns the existing row instead of inserting
  /// another. A different rect on the same page is a new crop.
  Future<PageCrop> saveRecognizedCrop({
    required String pageId,
    required String sourceSha256,
    required double left,
    required double top,
    required double width,
    required double height,
    required String ocrText,
    required String engineId,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: pageId,
        sha256: sourceSha256,
        createdAt: now,
      ),
    );
    final existing = await cropsForPage(pageId);
    for (final crop in existing) {
      if (crop.left == left &&
          crop.top == top &&
          crop.width == width &&
          crop.height == height) {
        return crop;
      }
    }
    final cropId = newId();
    await _db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: cropId,
        pageId: pageId,
        ocrText: ocrText,
        engineId: engineId,
        left: left,
        top: top,
        width: width,
        height: height,
        createdAt: now,
      ),
    );
    return PageCrop(
      id: cropId,
      pageId: pageId,
      ocrText: ocrText,
      engineId: engineId,
      left: left,
      top: top,
      width: width,
      height: height,
      createdAt: now,
    );
  }

  Future<List<PageCrop>> listCrops() async {
    final rows = await _db.pagesDao.listCrops();
    return [for (final row in rows) _toCrop(row)];
  }

  Future<List<PageCrop>> cropsForPage(String pageId) async {
    final rows = await _db.pagesDao.cropsForPage(pageId);
    return [for (final row in rows) _toCrop(row)];
  }

  Future<void> updateCropOcr({
    required String cropId,
    required String ocrText,
  }) {
    return _db.pagesDao.updateCropOcr(cropId: cropId, ocrText: ocrText);
  }

  Future<MangaPage?> pageById(String id) async {
    final row = await (_db.select(
      _db.capturedPages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toPage(row);
  }

  /// Newest [limit] pages (`created_at` descending). Does not load crops.
  Future<List<MangaPage>> listRecentPages({
    int limit = RecentPages.limit,
  }) async {
    final rows = await _db.pagesDao.listRecentPages(limit);
    return [for (final row in rows) _toPage(row)];
  }

  /// Full history, newest first. Does not load crops.
  Future<List<MangaPage>> listPages() async {
    final rows = await _db.pagesDao.listPages();
    return [for (final row in rows) _toPage(row)];
  }

  /// Full `/pages` history with the first crop's OCR as title/thumb source.
  Future<List<PageListEntry>> listPageEntries() async {
    final rows = await _db.pagesDao.listPagesWithFirstOcr();
    return [for (final row in rows) _toListEntry(row)];
  }

  /// Live `/pages` history. Emits again when a page or crop is written.
  Stream<List<PageListEntry>> watchPageEntries() {
    return _db.pagesDao.watchPagesWithFirstOcr().map((rows) {
      return [for (final row in rows) _toListEntry(row)];
    });
  }

  static PageListEntry _toListEntry((CapturedPage, String?) row) {
    final (page, ocrPreview) = row;
    return PageListEntry(
      id: page.id,
      createdAt: page.createdAt,
      ocrPreview: ocrPreview,
    );
  }

  Future<int> countPages() => _db.pagesDao.countPages();

  static MangaPage _toPage(CapturedPage row) {
    return MangaPage(id: row.id, sha256: row.sha256, createdAt: row.createdAt);
  }

  static PageCrop _toCrop(CapturedCrop row) {
    return PageCrop(
      id: row.id,
      pageId: row.pageId,
      ocrText: row.ocrText,
      engineId: row.engineId,
      left: row.left,
      top: row.top,
      width: row.width,
      height: row.height,
      createdAt: row.createdAt,
    );
  }
}
