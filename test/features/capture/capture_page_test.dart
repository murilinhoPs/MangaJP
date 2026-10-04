import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../ocr/fake_ocr_engine.dart';
import 'fixture_png.dart';

class FakeImageSourceService extends ImageSourceService {
  FakeImageSourceService({this.galleryImage, this.initial});

  final IncomingImage? galleryImage;
  final IncomingImage? initial;

  @override
  Stream<IncomingImage> get mediaStream => const Stream.empty();

  @override
  Future<IncomingImage?> initialMedia() async => initial;

  @override
  Future<IncomingImage?> pickFromGallery() async => galleryImage;
}

List<Override> _harness({
  required AppDatabase db,
  ImageSourceService? source,
  FakeOcrEngine ocr = const FakeOcrEngine(),
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

    expect(find.text('Captura'), findsOneWidget);
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
    expect(find.text('Captura'), findsOneWidget);
    expect(find.text('Caderno'), findsNothing);
    expect(find.text('Review'), findsNothing);

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byType(PageDetailPage), findsOneWidget);
  });

  testWidgets('Home Galeria opens /capture; confirm goes to /pages/:id', (
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

    await tester.tap(find.text('Galeria'));
    await tester.pumpAndSettle();

    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.text('Caderno'), findsNothing);

    await tester.tap(find.byKey(CaptureKeys.pickGallery));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.byType(PageDetailPage), findsOneWidget);
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

      await tester.tap(find.text('Galeria'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CaptureKeys.pickGallery));
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
}

extension on CapturePage {
  Widget wrap({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: this),
    );
  }
}
