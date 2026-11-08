import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_ocr_engine.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_store.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_ids.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../capture/fixture_png.dart';
import 'fake_ocr_engine.dart';
import 'scripted_http_client.dart';

const _fakeKey = 'cv-test-key';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('401 on a crop falls back and shows a non-blocking notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
                return http.Response('{}', 401);
              }),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    CaptureRoute(
      $extra: IncomingImage(bytes: fixturePng()),
    ).go(tester.element(find.byType(HomePage)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CaptureKeys.confirm));
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(
      find.text('Chave inválida. Recorte lido com manga-ocr.'),
      findsOneWidget,
    );
    expect(find.text('よぉ、相棒'), findsOneWidget);
    expect(await store.readApiKey(), _fakeKey);
    expect(find.text(_fakeKey), findsNothing);
    final crops = await db.pagesDao.listCrops();
    expect(crops, hasLength(1));
    expect(crops.single.engineId, OcrEngineIds.mangaOcr);
  });
}
