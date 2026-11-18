import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/features/capture/domain/capture_labels.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_ocr_engine.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_store.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_exception.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_labels.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_ids.dart';
import 'package:manga_jp/features/ocr/domain/ocr_exception.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../capture/fixture_png.dart';
import 'fake_ocr_engine.dart';
import 'scripted_http_client.dart';

const _fakeKey = 'cv-test-key';
const _phone = Size(390, 844);
const _desktop = Size(1280, 800);
const _fallbackNotice = 'Chave inválida. Recorte lido com manga-ocr.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('401 on a crop falls back and shows a notice at $label', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = MemoryCloudVisionStore(
        storedKey: _fakeKey,
        enabledFlag: true,
        privacyAcceptedFlag: true,
      );

      await _confirmCrop(
        tester,
        db: db,
        store: store,
        size: size,
        handler: (request) async => http.Response('{}', 401),
      );

      _expectVisibleFallback(tester, size: size);
      expect(find.byType(PageDetailPage), findsOneWidget);
      expect(find.byKey(PageDetailKeys.image), findsOneWidget);
      expect(find.byKey(PageDetailKeys.overlay), findsOneWidget);
      expect(await store.readApiKey(), _fakeKey);
      expect(find.text(_fakeKey), findsNothing);
      final crops = await db.pagesDao.listCrops();
      expect(crops, hasLength(1));
      expect(crops.single.ocrText, 'よぉ、相棒');
      expect(crops.single.engineId, OcrEngineIds.mangaOcr);
    });

    testWidgets('401 plus sidecar down shows dual-fail copy at $label', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = MemoryCloudVisionStore(
        storedKey: _fakeKey,
        enabledFlag: true,
        privacyAcceptedFlag: true,
      );

      await _confirmCrop(
        tester,
        db: db,
        store: store,
        size: size,
        handler: (request) async => http.Response('{}', 401),
        local: const FakeOcrEngine(
          id: OcrEngineIds.mangaOcr,
          error: MangaOcrUnavailable(),
        ),
      );

      expect(find.byType(CapturePage), findsOneWidget);
      expect(find.byType(PageDetailPage), findsNothing);
      expect(find.text(const OcrBothUnavailable().userMessage), findsOneWidget);
      expect(
        find.text(const OcrBothUnavailable().userMessage).hitTestable(),
        findsOneWidget,
      );
      _expectNoRawOcrException(tester);
      expect(await store.readApiKey(), _fakeKey);
      expect(find.text(_fakeKey), findsNothing);
      expect(await db.pagesDao.listCrops(), isEmpty);
    });

    testWidgets('sidecar down without Vision shows local copy at $label', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = MemoryCloudVisionStore();

      await _confirmCrop(
        tester,
        db: db,
        store: store,
        size: size,
        handler: (request) async => http.Response('{}', 200),
        local: const FakeOcrEngine(
          id: OcrEngineIds.mangaOcr,
          error: MangaOcrUnavailable(),
        ),
      );

      expect(find.byType(CapturePage), findsOneWidget);
      expect(
        find.text(const MangaOcrUnavailable().userMessage),
        findsOneWidget,
      );
      expect(find.text(const OcrBothUnavailable().userMessage), findsNothing);
      _expectNoRawOcrException(tester);
    });

    testWidgets('slow keyring on a crop is not missing-key copy at $label', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = MemoryCloudVisionStore(
        storedKey: _fakeKey,
        enabledFlag: true,
        privacyAcceptedFlag: true,
        keyringSlow: true,
      );

      await _confirmCrop(
        tester,
        db: db,
        store: store,
        size: size,
        handler: (request) async => http.Response('{}', 200),
      );

      expect(find.byType(CapturePage), findsOneWidget);
      expect(find.byType(PageDetailPage), findsNothing);
      expect(find.text(CloudVisionLabels.keyringSlow), findsOneWidget);
      expect(
        find.text(CloudVisionLabels.keyringSlow).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Sem chave. Recorte lido com manga-ocr.'), findsNothing);
      expect(find.text(CloudVisionLabels.needKeyFirst), findsNothing);
      expect(store.storedKey, _fakeKey);
      expect(await store.isEnabled, isTrue);
      expect(await db.pagesDao.listCrops(), isEmpty);
    });
  }

  testWidgets('400 API_KEY_INVALID on a crop falls back like 401', (
    tester,
  ) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = MemoryCloudVisionStore(
      storedKey: _fakeKey,
      enabledFlag: true,
      privacyAcceptedFlag: true,
    );

    await tester.pumpWidget(
      MangaJpApp(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          ocrEngineProvider.overrideWithValue(
            const FakeOcrEngine(text: 'よぉ、相棒', id: OcrEngineIds.mangaOcr),
          ),
          cloudVisionStoreProvider.overrideWithValue(store),
          cloudVisionOcrEngineProvider.overrideWithValue(
            CloudVisionOcrEngine(
              readApiKey: store.readApiKey,
              client: ScriptedHttpClient((request) async {
                return jsonHttpResponse(cloudVisionApiKeyInvalidError(), 400);
              }),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    CaptureRoute($extra: IncomingImage(bytes: fixturePng()))
        .go(tester.element(find.byType(HomePage)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(find.text(_fallbackNotice), findsOneWidget);
    expect(
      find.text(const CloudVisionUnexpected().fallbackMessage),
      findsNothing,
    );
    expect(find.byKey(PageDetailKeys.image), findsOneWidget);
    expect(find.byKey(PageDetailKeys.overlay), findsOneWidget);
    expect(await store.readApiKey(), _fakeKey);
    expect(find.text(_fakeKey), findsNothing);
    final crops = await db.pagesDao.listCrops();
    expect(crops, hasLength(1));
    expect(crops.single.ocrText, 'よぉ、相棒');
    expect(crops.single.engineId, OcrEngineIds.mangaOcr);
  });
}

Future<void> _confirmCrop(
  WidgetTester tester, {
  required AppDatabase db,
  required MemoryCloudVisionStore store,
  required Size size,
  required Future<http.Response> Function(http.BaseRequest request) handler,
  FakeOcrEngine local = const FakeOcrEngine(
    text: 'よぉ、相棒',
    id: OcrEngineIds.mangaOcr,
  ),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        ocrEngineProvider.overrideWithValue(local),
        cloudVisionStoreProvider.overrideWithValue(store),
        cloudVisionOcrEngineProvider.overrideWithValue(
          CloudVisionOcrEngine(
            readApiKey: store.readApiKey,
            client: ScriptedHttpClient(handler),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  CaptureRoute($extra: IncomingImage(bytes: fixturePng()))
      .go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();

  expect(find.byType(CapturePage), findsOneWidget);
  expect(find.text(CaptureLabels.confirmar), findsOneWidget);
  final wide = size.width >= 900;
  final confirm = wide
      ? find.byKey(ShellKeys.command('confirm'))
      : find.byKey(CaptureKeys.confirm);
  expect(confirm, findsOneWidget);
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

/// Visible copy + SnackBar (wide layout included). Not an implementation probe.
void _expectVisibleFallback(WidgetTester tester, {required Size size}) {
  expect(find.text(_fallbackNotice), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(_fallbackNotice),
    ),
    findsOneWidget,
  );
  expect(find.text(_fallbackNotice).hitTestable(), findsOneWidget);
  final rect = tester.getRect(find.text(_fallbackNotice));
  expect(rect.top, greaterThanOrEqualTo(-0.5));
  expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
  expect(rect.left, greaterThanOrEqualTo(-0.5));
  expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
}

void _expectNoRawOcrException(WidgetTester tester) {
  expect(find.textContaining('Bad state'), findsNothing);
  expect(find.textContaining('SocketException'), findsNothing);
  expect(find.textContaining('ClientException'), findsNothing);
  expect(find.textContaining('errno'), findsNothing);
  expect(find.textContaining('8765'), findsNothing);
  expect(find.textContaining('sidecar is not reachable'), findsNothing);
}
