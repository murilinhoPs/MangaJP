import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/dictionary/presentation/lookup_sheet.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/data/ocr_blocks_json.dart';
import 'package:manga_jp/features/pages/domain/ocr_block_geometry.dart';
import 'package:manga_jp/features/pages/domain/page_labels.dart';
import 'package:manga_jp/features/pages/presentation/ocr_overlay.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/pages/presentation/page_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dictionary/bake_jmdict_fixture.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

/// Widget tests skip FileImage; a non-empty path is enough for hasImage.
const _imagePath = '/overlay-test.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('overlay_page_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugPageImageUsePlaceholder = true;
  });

  tearDown(() {
    debugPageImageUsePlaceholder = false;
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= 900;

    testWidgets('overlay on draws boxes on the page image at $label', (
      tester,
    ) async {
      await _openPage(
        tester,
        size: size,
        jmdictPath: jmdictPath,
        imagePath: _imagePath,
        cropId: 'box-on',
      );

      expect(find.byKey(PageDetailKeys.image), findsOneWidget);
      expect(find.byKey(PageDetailKeys.overlay), findsOneWidget);
      expect(find.byKey(PageOverlayKeys.box('box-on')), findsOneWidget);
      expect(find.byKey(PageDetailKeys.ocrText), findsNothing);
      expect(_toggle(wide), findsOneWidget);
      if (!wide) {
        expect(
          tester.getSize(find.byKey(PageDetailKeys.overlayToggle)),
          const Size(48, 48),
        );
      }

      final paint = tester.widget<CustomPaint>(
        find.byKey(PageOverlayKeys.boxPaint('box-on')),
      );
      final painter = paint.painter! as OcrBoxPainter;
      expect(painter.dashed, isFalse);
      expect(painter.borderWidth, 1.5);
      expect(painter.fill, AppColors.overlayOcrBoxFill);
      expect(painter.selected, isFalse);
    });

    testWidgets('overlay off hides boxes and keeps the image at $label', (
      tester,
    ) async {
      await _openPage(
        tester,
        size: size,
        jmdictPath: jmdictPath,
        imagePath: _imagePath,
        cropId: 'box-off',
      );

      await tester.tap(_toggle(wide));
      await tester.pumpAndSettle();

      expect(find.byKey(PageDetailKeys.image), findsOneWidget);
      expect(find.byKey(PageDetailKeys.overlay), findsNothing);
      expect(find.byKey(PageOverlayKeys.box('box-off')), findsNothing);
      expect(find.byKey(PageDetailKeys.ocrText), findsNothing);
    });

    testWidgets('toggle is hidden when the page has no image at $label', (
      tester,
    ) async {
      await _openPage(
        tester,
        size: size,
        jmdictPath: jmdictPath,
        cropId: 'no-img',
      );

      expect(find.byKey(PageDetailKeys.overlayToggle), findsNothing);
      expect(find.byKey(ShellKeys.command('ocr-overlay')), findsNothing);
      expect(find.byKey(PageDetailKeys.image), findsNothing);
      expect(find.byKey(PageDetailKeys.ocrText), findsOneWidget);
      expect(find.text('猫を食べた。'), findsOneWidget);
    });

    testWidgets('tap box opens lookup for the first term at $label', (
      tester,
    ) async {
      await _openPage(
        tester,
        size: size,
        jmdictPath: jmdictPath,
        imagePath: _imagePath,
        cropId: 'tap-box',
      );

      await tester.tap(find.byKey(PageOverlayKeys.box('tap-box')));
      await tester.pumpAndSettle();

      if (wide) {
        expect(find.byKey(LookupSheetKeys.drawer), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(LookupSheetKeys.drawer),
            matching: find.text('猫'),
          ),
          findsWidgets,
        );
      } else {
        expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(LookupSheetKeys.sheet),
            matching: find.text('猫'),
          ),
          findsWidgets,
        );
      }
      final paint = tester.widget<CustomPaint>(
        find.byKey(PageOverlayKeys.boxPaint('tap-box')),
      );
      expect((paint.painter! as OcrBoxPainter).selected, isTrue);
      expect((paint.painter! as OcrBoxPainter).borderWidth, 2);
    });

    testWidgets('low-confidence box is dashed at $label', (tester) async {
      await _openPage(
        tester,
        size: size,
        jmdictPath: jmdictPath,
        imagePath: _imagePath,
        cropId: 'low',
        blocks: const [
          OcrBlockGeometry(
            text: '猫',
            confidence: 0.3,
            left: 0.1,
            top: 0.1,
            width: 0.8,
            height: 0.8,
          ),
        ],
      );

      final paint = tester.widget<CustomPaint>(
        find.byKey(PageOverlayKeys.boxPaint('low#0')),
      );
      expect((paint.painter! as OcrBoxPainter).dashed, isTrue);
    });
  }

  testWidgets('B toggles overlay on 1280x800', (tester) async {
    await _openPage(
      tester,
      size: _desktop,
      jmdictPath: jmdictPath,
      imagePath: _imagePath,
      cropId: 'key-b',
    );
    expect(find.byKey(PageDetailKeys.overlay), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(find.byKey(PageDetailKeys.overlay), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(find.byKey(PageDetailKeys.overlay), findsOneWidget);
  });

  testWidgets('Tab / Enter / Esc on 1280x800', (tester) async {
    await _openPage(
      tester,
      size: _desktop,
      jmdictPath: jmdictPath,
      imagePath: _imagePath,
      cropId: 'key-tab',
      extraCropId: 'key-tab-2',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    var paint = tester.widget<CustomPaint>(
      find.byKey(PageOverlayKeys.boxPaint('key-tab')),
    );
    expect((paint.painter! as OcrBoxPainter).selected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.drawer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.drawer),
        matching: find.text('猫'),
      ),
      findsWidgets,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    paint = tester.widget<CustomPaint>(
      find.byKey(PageOverlayKeys.boxPaint('key-tab')),
    );
    expect((paint.painter! as OcrBoxPainter).selected, isFalse);
    expect(find.text(PageLabels.toquePalavra), findsOneWidget);
  });

  testWidgets('desktop hover uses the hover fill token', (tester) async {
    await _openPage(
      tester,
      size: _desktop,
      jmdictPath: jmdictPath,
      imagePath: _imagePath,
      cropId: 'hover',
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(PageOverlayKeys.box('hover'))),
    );
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.byKey(PageOverlayKeys.boxPaint('hover')),
    );
    final painter = paint.painter! as OcrBoxPainter;
    expect(painter.hovered, isTrue);
    expect(painter.fill, AppColors.overlayPrimaria);
    expect(painter.border, AppColors.coral);
  });

  testWidgets('reader.ocrOverlay persists across rebuilds', (tester) async {
    SharedPreferences.setMockInitialValues({'reader.ocrOverlay': false});
    await _openPage(
      tester,
      size: _phone,
      jmdictPath: jmdictPath,
      imagePath: _imagePath,
      cropId: 'pref',
    );
    expect(find.byKey(PageDetailKeys.overlay), findsNothing);
    expect(find.byKey(PageDetailKeys.image), findsOneWidget);
  });
}

Finder _toggle(bool wide) {
  return wide
      ? find.byKey(ShellKeys.command('ocr-overlay'))
      : find.byKey(PageDetailKeys.overlayToggle);
}

Future<void> _openPage(
  WidgetTester tester, {
  required Size size,
  required String jmdictPath,
  required String cropId,
  String? imagePath,
  String? extraCropId,
  List<OcrBlockGeometry> blocks = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  const pageId = 'overlay-test';
  final now = DateTime.utc(2026, 4, 1);
  await db.pagesDao.insertPage(
    CapturedPagesCompanion.insert(
      id: pageId,
      sha256: 'sha',
      createdAt: now,
      imagePath: Value(imagePath),
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: cropId,
      pageId: pageId,
      ocrText: '猫を食べた。',
      engineId: 'test',
      left: 0.1,
      top: 0.15,
      width: 0.4,
      height: 0.3,
      createdAt: now,
      ocrBlocksJson: Value(OcrBlocksJson.encode(blocks)),
    ),
  );
  if (extraCropId != null) {
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: extraCropId,
        pageId: pageId,
        ocrText: '高い',
        engineId: 'test',
        left: 0.55,
        top: 0.15,
        width: 0.35,
        height: 0.28,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    );
  }

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        jmdictServiceProvider.overrideWith((ref) async {
          final service = JmdictService()..openFile(jmdictPath);
          ref.onDispose(service.close);
          return service;
        }),
      ],
    ),
  );
  await tester.pumpAndSettle();
  const PageDetailRoute(id: pageId).go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  expect(find.byType(PageDetailPage), findsOneWidget);
}
