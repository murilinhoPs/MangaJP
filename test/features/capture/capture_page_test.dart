import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/capture_labels.dart';
import 'package:manga_jp/features/capture/domain/crop_rect.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/capture/presentation/crop_overlay.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine.dart';
import 'package:manga_jp/features/ocr/domain/ocr_result.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../ocr/fake_ocr_engine.dart';
import 'fake_image_source_service.dart';
import 'fixture_png.dart';

List<Override> _harness({
  required AppDatabase db,
  ImageSourceService? source,
  OcrEngine ocr = const FakeOcrEngine(),
}) {
  return [
    appDatabaseProvider.overrideWith((ref) => db),
    ocrEngineProvider.overrideWithValue(ocr),
    if (source != null)
      imageSourceServiceProvider.overrideWith((ref) => source),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List png;

  setUp(() {
    png = fixturePng();
  });

  testWidgets('fixture image → crop screen → 1 rect → non-empty PNG bytes', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    Uint8List? cropped;
    await tester.pumpWidget(
      CapturePage(
        image: IncomingImage(bytes: png),
        onCropped: (bytes) => cropped = bytes,
      ).wrap(overrides: _harness(db: db)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CaptureKeys.page), findsOneWidget);
    expect(find.text('Confirmar crop'), findsOneWidget);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    expect(cropped, isNotNull);
    expect(cropped!.length, greaterThan(0));
    expect(find.byKey(CaptureKeys.cropBytes), findsOneWidget);
    expect(find.textContaining('Crop PNG:'), findsOneWidget);
    expect(find.textContaining('bytes'), findsOneWidget);
  });

  testWidgets('share intent extra opens /capture without bottom tabs', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      MangaJpApp(
        overrides: _harness(
          db: db,
          source: FakeImageSourceService(initial: IncomingImage(bytes: png)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.byKey(CaptureKeys.page), findsOneWidget);
    expect(find.text('Caderno'), findsNothing);
    expect(find.text('Review'), findsNothing);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byType(PageDetailPage), findsOneWidget);
  });

  testWidgets('empty /capture gallery pick loads crop UI', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      const CapturePage().wrap(
        overrides: _harness(
          db: db,
          source: FakeImageSourceService(
            galleryImage: IncomingImage(bytes: png),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escolher da galeria'), findsOneWidget);
    await tester.tap(find.byKey(CaptureKeys.pickGallery));
    await tester.pumpAndSettle();

    expect(find.byKey(CaptureKeys.confirm), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsNothing);
  });

  testWidgets(
    'Home Galeria pick opens /capture crop; confirm goes to /pages/:id',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        MangaJpApp(
          overrides: _harness(
            db: db,
            source: FakeImageSourceService(
              galleryImage: IncomingImage(bytes: png),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeKeys.gallery));
      await tester.pumpAndSettle();

      expect(find.byType(CapturePage), findsOneWidget);
      expect(find.text('Caderno'), findsNothing);
      expect(find.byKey(CaptureKeys.pickGallery), findsNothing);
      expect(find.text('Confirmar crop'), findsOneWidget);

      await tester.tap(find.byKey(CaptureKeys.confirm));
      await tester.pumpAndSettle();
      expect(find.byType(PageDetailPage), findsOneWidget);
    },
  );

  testWidgets('Home Galeria cancel stays on /home', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final source = FakeImageSourceService();

    await tester.pumpWidget(
      MangaJpApp(
        overrides: _harness(db: db, source: source),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeKeys.gallery));
    await tester.pumpAndSettle();

    expect(source.galleryCalls, 1);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
    expect(
      GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
      '/home',
    );
  });

  testWidgets(
    'share extra → crop confirm → /pages/:id shows persisted ocr_text',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      const recognized = 'よぉ、相棒';

      await tester.pumpWidget(
        MangaJpApp(
          overrides: _harness(
            db: db,
            source: FakeImageSourceService(initial: IncomingImage(bytes: png)),
            ocr: const FakeOcrEngine(text: recognized),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CapturePage), findsOneWidget);

      await tester.tap(find.byKey(CaptureKeys.confirm));
      await tester.pumpAndSettle();

      expect(find.byType(CapturePage), findsNothing);
      expect(find.byType(PageDetailPage), findsOneWidget);

      final crops = await db.pagesDao.listCrops();
      expect(crops, hasLength(1));
      expect(crops.single.ocrText, recognized);
      expect(crops.single.engineId, 'fake');
      expect(
        GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
        '/pages/${crops.single.pageId}',
      );
      expect(find.byKey(PageDetailKeys.ocrText), findsOneWidget);
      expect(find.text(recognized), findsOneWidget);
    },
  );

  testWidgets(
    'gallery import → crop confirm → /pages/:id shows persisted ocr_text',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      const recognized = '千鶴屋？';

      await tester.pumpWidget(
        MangaJpApp(
          overrides: _harness(
            db: db,
            source: FakeImageSourceService(
              galleryImage: IncomingImage(bytes: png),
            ),
            ocr: const FakeOcrEngine(text: recognized),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeKeys.gallery));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CaptureKeys.confirm));
      await tester.pumpAndSettle();

      expect(find.byType(PageDetailPage), findsOneWidget);
      expect(find.text(recognized), findsOneWidget);
      final crops = await db.pagesDao.listCrops();
      expect(crops, hasLength(1));
      expect(crops.single.ocrText, recognized);
      expect(
        GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
        '/pages/${crops.single.pageId}',
      );
    },
  );

  testWidgets('RTL numbers: right-to-left then top-to-bottom', (tester) async {
    await _pumpCrop(tester, crops: _threeCrops, activeIndex: 0);

    expect(find.byKey(CaptureKeys.cropNumber(1)), findsOneWidget);
    expect(find.byKey(CaptureKeys.cropNumber(2)), findsOneWidget);
    expect(find.byKey(CaptureKeys.cropNumber(3)), findsOneWidget);

    final n1 = tester.getCenter(find.byKey(CaptureKeys.cropNumber(1)));
    final n2 = tester.getCenter(find.byKey(CaptureKeys.cropNumber(2)));
    final n3 = tester.getCenter(find.byKey(CaptureKeys.cropNumber(3)));
    expect(n1.dx, greaterThan(n2.dx));
    expect(n1.dy, lessThan(n3.dy));
    expect(n2.dy, lessThan(n3.dy));
  });

  testWidgets('active crop uses coral ring; inactive is dashed violet', (
    tester,
  ) async {
    await _pumpCrop(tester, crops: _threeCrops, activeIndex: 0);

    final paint = tester.widget<CustomPaint>(find.byKey(CaptureKeys.overlay));
    final painter = paint.painter! as CropOverlayPainter;
    expect(painter.activeColor, AppColors.coral);
    expect(painter.inactiveColor, AppColors.violet);
    expect(painter.inactiveDashed, isTrue);
    expect(painter.activeIndex, 0);
    expect(painter.rects, hasLength(3));
  });

  testWidgets('dock hides central info without an image; shows it with crops', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      const CapturePage().wrap(overrides: _harness(db: db)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
    expect(find.byKey(ShellKeys.dockMeta), findsNothing);
    expect(find.text(CaptureLabels.arrasteParaCriar), findsNothing);

    await tester.pumpWidget(
      CapturePage(image: IncomingImage(bytes: png))
          .wrap(overrides: _harness(db: db)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ShellKeys.dockMeta), findsOneWidget);
    expect(find.text(CaptureLabels.recortesMeta(1)), findsOneWidget);
    expect(find.text(CaptureLabels.arrasteParaCriar), findsOneWidget);
  });

  testWidgets('cancel from gallery crop without edit returns to Home', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      MangaJpApp(
        overrides: _harness(
          db: db,
          source: FakeImageSourceService(
            galleryImage: IncomingImage(bytes: png),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeKeys.gallery));
    await tester.pumpAndSettle();
    expect(find.byType(CapturePage), findsOneWidget);

    await tester.tap(find.byKey(ShellKeys.dockAction('close')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
    expect(
      GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
      '/home',
    );
  });

  testWidgets('Esc with no crops exits to Home', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openEmptyCapture(tester, db: db);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
  });

  testWidgets('dock X with no crops exits to Home', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openEmptyCapture(tester, db: db);

    await tester.tap(find.byKey(ShellKeys.dockAction('close')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
  });

  testWidgets('Esc without edit exits to Home', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openGalleryCrop(tester, db: db, png: png);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
  });

  testWidgets('Esc after edit shows dialog; cancel keeps the crops', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openGalleryCrop(tester, db: db, png: png);
    await _editActiveCrop(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(CaptureKeys.discardDialog), findsOneWidget);
    expect(find.text(CaptureLabels.descartarTitulo), findsOneWidget);
    expect(find.text(CaptureLabels.descartarCorpo), findsOneWidget);

    await tester.tap(find.byKey(CaptureKeys.discardCancel));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.byKey(CaptureKeys.overlay), findsOneWidget);
    expect(find.text(CaptureLabels.recortesMeta(1)), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('dock X after edit shows dialog; confirm exits to Home', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openGalleryCrop(tester, db: db, png: png);
    await _editActiveCrop(tester);

    await tester.tap(find.byKey(ShellKeys.dockAction('close')));
    await tester.pumpAndSettle();

    expect(find.byKey(CaptureKeys.discardDialog), findsOneWidget);
    expect(find.byType(CapturePage), findsOneWidget);

    await tester.tap(find.byKey(CaptureKeys.discardConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(CapturePage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets(
    'Android back after edit shows dialog; cancel keeps; discard goes Home',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _openGalleryCrop(tester, db: db, png: png);
      await _editActiveCrop(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(CaptureKeys.discardDialog), findsOneWidget);
      expect(find.text(CaptureLabels.descartarTitulo), findsOneWidget);

      await tester.tap(find.byKey(CaptureKeys.discardCancel));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CapturePage), findsOneWidget);
      expect(find.byKey(CaptureKeys.overlay), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(CaptureKeys.discardDialog), findsOneWidget);
      await tester.tap(find.byKey(CaptureKeys.discardConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CapturePage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets(
      'iOS back after edit shows discard dialog; cancel keeps; discard goes Home at $label',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
        });

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await _openCropWithImage(tester, db: db, png: png, size: size);
        await _editActiveCrop(tester);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byKey(CaptureKeys.discardDialog), findsOneWidget);
        expect(find.text(CaptureLabels.descartarTitulo), findsOneWidget);
        expect(find.text(CaptureLabels.descartarCorpo), findsOneWidget);

        await tester.tap(find.byKey(CaptureKeys.discardCancel));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(CapturePage), findsOneWidget);
        expect(find.byKey(CaptureKeys.overlay), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(CaptureKeys.discardDialog), findsOneWidget);
        await tester.tap(find.byKey(CaptureKeys.discardConfirm));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(CapturePage), findsNothing);
        expect(find.byType(HomePage), findsOneWidget);

        // addTearDown runs after _verifyInvariants — reset here.
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets(
      'top-edge crop badge sits below status bar plus extra gap at $label',
      (tester) async {
        tester.view.padding = const FakeViewPadding(top: 62);
        tester.view.viewPadding = const FakeViewPadding(top: 62);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        await _pumpCrop(
          tester,
          crops: const [CropRect(left: 0.2, top: 0, width: 0.6, height: 0.4)],
          size: size,
        );

        final canvas = tester.getRect(find.byKey(CaptureKeys.canvas));
        expect(canvas.top, greaterThanOrEqualTo(62));
        final badge = tester.getRect(find.byKey(CaptureKeys.cropNumber(1)));
        expect(
          badge.top,
          greaterThanOrEqualTo(canvas.top + CropOverlay.badgeMinGap - 0.5),
        );
        expect(badge.top, greaterThanOrEqualTo(62 + CropOverlay.badgeMinGap - 0.5));
      },
    );

    testWidgets('Crop canvas sits below a 62px top inset at $label', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 62);
      tester.view.viewPadding = const FakeViewPadding(top: 62);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _openCropWithImage(tester, db: db, png: png, size: size);

      final canvas = tester.getRect(find.byKey(CaptureKeys.canvas));
      expect(canvas.top, greaterThanOrEqualTo(62));

      if (size.width < 900) {
        expect(find.byKey(CaptureKeys.confirm), findsOneWidget);
        expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
        expect(
          canvas.bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(ShellKeys.taskDock)).top + 0.5,
          ),
        );
      } else {
        expect(find.byKey(ShellKeys.commandBar), findsOneWidget);
        expect(
          canvas.bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byKey(ShellKeys.commandBar)).top + 0.5,
          ),
        );
      }
    });
  }

  testWidgets('Android back without image exits to Home', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openEmptyCapture(tester, db: db);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
  });

  testWidgets('drag on empty canvas creates a new crop', (tester) async {
    await _pumpCrop(tester, crops: const [CropRect.initial]);

    expect(find.byKey(CaptureKeys.cropNumber(1)), findsOneWidget);
    expect(find.byKey(CaptureKeys.cropNumber(2)), findsNothing);
    expect(find.text(CaptureLabels.recortesMeta(1)), findsOneWidget);

    await _dragNewCrop(tester);

    expect(find.byKey(CaptureKeys.cropNumber(1)), findsOneWidget);
    expect(find.byKey(CaptureKeys.cropNumber(2)), findsOneWidget);
    expect(find.text(CaptureLabels.recortesMeta(2)), findsOneWidget);
  });

  testWidgets(
    'Android back with image and no edits exits to Home without a dialog',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _openGalleryCrop(tester, db: db, png: png);

      expect(find.byType(CapturePage), findsOneWidget);
      expect(find.byKey(CaptureKeys.overlay), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(CapturePage), findsNothing);
    },
  );

  testWidgets('OCR retry does not duplicate already saved crops', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ocr = _FlakyOcrEngine(failOnCall: 2);
    await _pumpCrop(tester, crops: _threeCrops, db: db, ocr: ocr);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.byType(CapturePage), findsOneWidget);
    expect(await db.pagesDao.listCrops(), hasLength(1));

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    expect(await db.pagesDao.listCrops(), hasLength(3));
    expect(ocr.calls, 4);
  });

  testWidgets('confirm persists every crop in RTL order', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpCrop(tester, crops: _threeCrops, db: db);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    final crops = await db.pagesDao.listCrops();
    expect(crops, hasLength(3));
    expect(crops.first.left, closeTo(_threeCrops[1].left, 1e-9));
    expect(crops[1].left, closeTo(_threeCrops[0].left, 1e-9));
    expect(crops[2].left, closeTo(_threeCrops[2].left, 1e-9));
  });
}

const _threeCrops = <CropRect>[
  CropRect(left: 0.08, top: 0.10, width: 0.36, height: 0.32),
  CropRect(left: 0.54, top: 0.06, width: 0.38, height: 0.30),
  CropRect(left: 0.52, top: 0.54, width: 0.40, height: 0.32),
];

Future<void> _openEmptyCapture(
  WidgetTester tester, {
  required AppDatabase db,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MangaJpApp(overrides: _harness(db: db)));
  await tester.pumpAndSettle();
  final ctx = tester.element(find.byType(HomePage));
  const CaptureRoute().go(ctx);
  await tester.pumpAndSettle();
  expect(find.byType(CapturePage), findsOneWidget);
  expect(find.byKey(CaptureKeys.pickGallery), findsOneWidget);
}

Future<void> _openCropWithImage(
  WidgetTester tester, {
  required AppDatabase db,
  required Uint8List png,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MangaJpApp(overrides: _harness(db: db)));
  await tester.pumpAndSettle();
  final ctx = tester.element(find.byType(HomePage));
  CaptureRoute($extra: IncomingImage(bytes: png)).go(ctx);
  await tester.pumpAndSettle();
  expect(find.byType(CapturePage), findsOneWidget);
  expect(find.byKey(CaptureKeys.overlay), findsOneWidget);
}

Future<void> _openGalleryCrop(
  WidgetTester tester, {
  required AppDatabase db,
  required Uint8List png,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MangaJpApp(
      overrides: _harness(
        db: db,
        source: FakeImageSourceService(galleryImage: IncomingImage(bytes: png)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(HomeKeys.gallery));
  await tester.pumpAndSettle();
  expect(find.byType(CapturePage), findsOneWidget);
  expect(find.byKey(CaptureKeys.overlay), findsOneWidget);
}

Future<void> _editActiveCrop(WidgetTester tester) async {
  await tester.drag(find.byKey(CaptureKeys.overlay), const Offset(-24, 0));
  await tester.pumpAndSettle();
}

/// Pan starts outside the initial 0.2–0.8 crop so overlay `_Hit.create` fires.
Future<void> _dragNewCrop(WidgetTester tester) async {
  final overlay = find.byKey(CaptureKeys.overlay);
  final paint = tester.widget<CustomPaint>(overlay);
  final dest = (paint.painter! as CropOverlayPainter).dest;
  final origin = tester.getTopLeft(overlay);
  final start = origin + dest.topLeft + const Offset(8, 8);
  final delta = Offset(dest.width * 0.15, dest.height * 0.15);
  await tester.timedDragFrom(start, delta, const Duration(milliseconds: 280));
  await tester.pumpAndSettle();
}

Future<void> _pumpCrop(
  WidgetTester tester, {
  required List<CropRect> crops,
  int activeIndex = 0,
  AppDatabase? db,
  OcrEngine ocr = const FakeOcrEngine(),
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final database = db ?? AppDatabase(NativeDatabase.memory());
  if (db == null) {
    addTearDown(database.close);
  }
  await tester.pumpWidget(
    CapturePage(
      image: IncomingImage(bytes: fixturePng()),
      initialCrops: crops,
      initialActiveIndex: activeIndex,
    ).wrap(
      overrides: _harness(db: database, ocr: ocr),
    ),
  );
  await tester.pumpAndSettle();
}

class _FlakyOcrEngine implements OcrEngine {
  _FlakyOcrEngine({required this.failOnCall});

  final int failOnCall;
  int calls = 0;

  @override
  String get engineId => 'fake';

  @override
  Future<OcrResult> recognize(Uint8List image) async {
    calls += 1;
    if (calls == failOnCall) {
      throw Exception('ocr failed on call $calls');
    }
    return const OcrResult(
      fullText: 'よぉ、相棒',
      blocks: [OcrBlock(text: 'よぉ、相棒')],
      engineId: 'fake',
    );
  }
}

extension on CapturePage {
  Widget wrap({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: this),
      ),
    );
  }
}
