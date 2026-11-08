import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import 'cloud_vision_store.dart';

/// Screenshot helper. Off by default; ignored in release.
///
/// `flutter run --dart-define=MANGAJP_CLOUD_VISION_SHOT=masked` (and siblings).
/// Fake key is `cv-test-key` — not a Google-looking value. Never a real key.
const kCloudVisionShot = String.fromEnvironment('MANGAJP_CLOUD_VISION_SHOT');

const kCloudVisionShotFakeKey = 'cv-test-key';

MemoryCloudVisionStore? cloudVisionShotStore({bool release = kReleaseMode}) {
  if (release) {
    return null;
  }
  return switch (kCloudVisionShot) {
    'idle' => MemoryCloudVisionStore(),
    'masked' || 'privacy' || 'error' => MemoryCloudVisionStore(
      storedKey: kCloudVisionShotFakeKey,
    ),
    'on' => MemoryCloudVisionStore(
      storedKey: kCloudVisionShotFakeKey,
      enabledFlag: true,
      privacyAcceptedFlag: true,
    ),
    'nokeyring' => MemoryCloudVisionStore(keyringAvailable: false),
    'mixed' => MemoryCloudVisionStore(
      storedKey: kCloudVisionShotFakeKey,
      enabledFlag: true,
      privacyAcceptedFlag: true,
    ),
    _ => null,
  };
}

bool get kCloudVisionShotPrivacyDialog =>
    !kReleaseMode && kCloudVisionShot == 'privacy';

bool get kCloudVisionShotErrorBanner =>
    !kReleaseMode && kCloudVisionShot == 'error';

/// Seeds `/pages/cv-mixed` with one manga-ocr crop and one Cloud Vision crop.
Future<void> seedCloudVisionShotIfRequested(AppDatabase db) async {
  if (kReleaseMode || kCloudVisionShot != 'mixed') {
    return;
  }
  final existing = await (db.select(
    db.capturedPages,
  )..where((t) => t.id.equals('cv-mixed'))).getSingleOrNull();
  if (existing != null) {
    return;
  }
  final now = DateTime.now().toUtc();
  await db.pagesDao.insertPage(
    CapturedPagesCompanion.insert(
      id: 'cv-mixed',
      sha256: 'cv-mixed-sha',
      createdAt: now,
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'cv-mixed-manga',
      pageId: 'cv-mixed',
      ocrText: 'よぉ、相棒',
      engineId: 'manga_ocr',
      left: 0.1,
      top: 0.1,
      width: 0.4,
      height: 0.3,
      createdAt: now,
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'cv-mixed-vision',
      pageId: 'cv-mixed',
      ocrText: '来てたんだな',
      engineId: 'cloud_vision',
      left: 0.5,
      top: 0.4,
      width: 0.4,
      height: 0.3,
      createdAt: now,
    ),
  );
}
