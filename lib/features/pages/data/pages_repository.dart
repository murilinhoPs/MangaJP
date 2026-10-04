import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/utils/ids.dart';
import '../domain/page.dart';
import '../domain/page_crop.dart';

part 'pages_repository.g.dart';

@Riverpod(keepAlive: true)
PagesRepository pagesRepository(Ref ref) {
  return PagesRepository(ref.watch(appDatabaseProvider));
}

/// Pages + crops persistence (M1.1: OCR text; M1.3 lookup is dictionary).
class PagesRepository {
  const PagesRepository(this._db);

  final AppDatabase _db;

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

  Future<MangaPage?> pageById(String id) async {
    final row = await (_db.select(
      _db.capturedPages,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
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
