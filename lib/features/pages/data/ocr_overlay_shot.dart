import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../capture/domain/capture_shot.dart';
import '../domain/ocr_block_geometry.dart';
import 'ocr_blocks_json.dart';
import 'page_image_store.dart';

/// Screenshot helper. Off by default; ignored in release.
///
/// `flutter run --dart-define=MANGAJP_OCR_OVERLAY_SHOT=on_selected`
/// (also `off`, `hover_selected`, `no_image`).
const kOcrOverlayShot = String.fromEnvironment('MANGAJP_OCR_OVERLAY_SHOT');

const kOcrOverlayShotPageId = 'overlay-page';
const kOcrOverlayShotOldPageId = 'overlay-old';

bool get kOcrOverlayShotEnabled => !kReleaseMode && kOcrOverlayShot.isNotEmpty;

bool get kOcrOverlayShotSelectFirst =>
    kOcrOverlayShot == 'on_selected' || kOcrOverlayShot == 'hover_selected';

bool get kOcrOverlayShotHoverSecond => kOcrOverlayShot == 'hover_selected';

bool get kOcrOverlayShotForceOff => kOcrOverlayShot == 'off';

/// Seeds a page with a stored image + boxes, and an old page without image.
Future<void> seedOcrOverlayShotIfRequested(
  AppDatabase db, {
  PageImageStore store = const PageImageStore(),
  Uint8List Function()? imageBytes,
}) async {
  if (!kOcrOverlayShotEnabled) {
    return;
  }
  final existing = await (db.select(
    db.capturedPages,
  )..where((t) => t.id.equals(kOcrOverlayShotPageId))).getSingleOrNull();
  if (existing != null) {
    return;
  }

  final now = DateTime.now().toUtc();
  final bytes = imageBytes?.call() ?? buildMangaPanelPng();
  final imagePath = await store.savePageImage(
    pageId: kOcrOverlayShotPageId,
    bytes: bytes,
  );

  await db.pagesDao.insertPage(
    CapturedPagesCompanion.insert(
      id: kOcrOverlayShotPageId,
      sha256: 'overlay-sha',
      createdAt: now,
      imagePath: Value(imagePath),
    ),
  );

  final visionBlocks = OcrBlocksJson.encode(const [
    OcrBlockGeometry(
      text: '高い',
      confidence: 0.92,
      left: 0.10,
      top: 0.12,
      width: 0.80,
      height: 0.76,
    ),
  ]);
  final lowBlocks = OcrBlocksJson.encode(const [
    OcrBlockGeometry(
      text: '見せる',
      confidence: 0.31,
      left: 0.08,
      top: 0.10,
      width: 0.84,
      height: 0.80,
    ),
  ]);

  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'overlay-crop-1',
      pageId: kOcrOverlayShotPageId,
      ocrText: '猫を食べた。',
      engineId: 'manga_ocr',
      left: 0.08,
      top: 0.10,
      width: 0.36,
      height: 0.32,
      createdAt: now,
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'overlay-crop-2',
      pageId: kOcrOverlayShotPageId,
      ocrText: '高い',
      engineId: 'cloud_vision',
      left: 0.54,
      top: 0.06,
      width: 0.38,
      height: 0.30,
      createdAt: now.add(const Duration(seconds: 1)),
      ocrBlocksJson: Value(visionBlocks),
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'overlay-crop-3',
      pageId: kOcrOverlayShotPageId,
      ocrText: '見せる',
      engineId: 'cloud_vision',
      left: 0.52,
      top: 0.54,
      width: 0.40,
      height: 0.32,
      createdAt: now.add(const Duration(seconds: 2)),
      ocrBlocksJson: Value(lowBlocks),
    ),
  );

  await db.pagesDao.insertPage(
    CapturedPagesCompanion.insert(
      id: kOcrOverlayShotOldPageId,
      sha256: 'overlay-old-sha',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'overlay-old-crop',
      pageId: kOcrOverlayShotOldPageId,
      ocrText: '猫を食べた。',
      engineId: 'manga_ocr',
      left: 0.2,
      top: 0.2,
      width: 0.6,
      height: 0.6,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  );
}
