import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_labels.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_ids.dart';
import 'package:manga_jp/features/ocr/presentation/cloud_vision_keys.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../capture/fixture_png.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('single engine chip is Cloud Vision at $label', (tester) async {
      await _openPage(
        tester,
        size: size,
        engines: const [OcrEngineIds.cloudVision],
      );
      expect(find.byKey(CloudVisionKeys.engineChip), findsOneWidget);
      expect(find.text(CloudVisionLabels.chipCloudVision), findsOneWidget);
      expect(find.text(CloudVisionLabels.chipMixed), findsNothing);
    });

    testWidgets('mixed engine chip when crops differ at $label', (tester) async {
      await _openPage(
        tester,
        size: size,
        engines: const [OcrEngineIds.mangaOcr, OcrEngineIds.cloudVision],
      );
      expect(find.byKey(CloudVisionKeys.engineChip), findsOneWidget);
      expect(find.text(CloudVisionLabels.chipMixed), findsOneWidget);
    });
  }
}

Future<void> _openPage(
  WidgetTester tester, {
  required Size size,
  required List<String> engines,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  const pageId = 'page-chip';
  final pages = PagesRepository(db);
  for (var i = 0; i < engines.length; i++) {
    await pages.saveRecognizedCrop(
      pageId: pageId,
      sourceSha256: sha256Hex(fixturePng()),
      left: 0.1 + i * 0.2,
      top: 0.1,
      width: 0.3,
      height: 0.3,
      ocrText: '文$i',
      engineId: engines[i],
    );
  }

  await tester.pumpWidget(
    MangaJpApp(overrides: [appDatabaseProvider.overrideWith((ref) => db)]),
  );
  await tester.pumpAndSettle();
  const PageDetailRoute(id: pageId).go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  expect(find.byType(PageDetailPage), findsOneWidget);
}
