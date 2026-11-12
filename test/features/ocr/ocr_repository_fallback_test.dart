import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:manga_jp/features/ocr/data/cloud_vision_ocr_engine.dart';
import 'package:manga_jp/features/ocr/data/cloud_vision_store.dart';
import 'package:manga_jp/features/ocr/data/ocr_repository.dart';
import 'package:manga_jp/features/ocr/domain/cloud_vision_exception.dart';
import 'package:manga_jp/features/ocr/domain/ocr_engine_ids.dart';

import '../capture/fixture_png.dart';
import 'fake_ocr_engine.dart';
import 'scripted_http_client.dart';

const _fakeKey = 'cv-test-key';

void main() {
  test('toggle off never calls Cloud Vision (NF6)', () async {
    var cloudCalled = false;
    final repo = OcrRepository(
      const FakeOcrEngine(text: 'local', id: OcrEngineIds.mangaOcr),
      cloud: CloudVisionOcrEngine(
        readApiKey: () async {
          cloudCalled = true;
          return _fakeKey;
        },
        client: ScriptedHttpClient((request) async {
          cloudCalled = true;
          return http.Response('{}', 200);
        }),
      ),
      store: MemoryCloudVisionStore(storedKey: _fakeKey),
    );
    final outcome = await repo.recognizeCrop(fixturePng());
    expect(cloudCalled, isFalse);
    expect(outcome.fallback, isNull);
    expect(outcome.result.engineId, OcrEngineIds.mangaOcr);
    expect(outcome.result.fullText, 'local');
  });

  test('401 falls back to manga-ocr and keeps the key', () async {
    final store = MemoryCloudVisionStore(
      storedKey: _fakeKey,
      enabledFlag: true,
    );
    final repo = OcrRepository(
      const FakeOcrEngine(text: 'manga', id: OcrEngineIds.mangaOcr),
      cloud: CloudVisionOcrEngine(
        readApiKey: store.readApiKey,
        client: ScriptedHttpClient((request) async {
          return http.Response('{}', 401);
        }),
      ),
      store: store,
    );
    final outcome = await repo.recognizeCrop(fixturePng());
    expect(outcome.result.engineId, OcrEngineIds.mangaOcr);
    expect(outcome.result.fullText, 'manga');
    expect(outcome.fallback, isA<CloudVisionInvalidApiKey>());
    expect(await store.readApiKey(), _fakeKey);
    expect(await store.isEnabled, isTrue);
  });

  test('400 API_KEY_INVALID falls back like 401 and keeps the key', () async {
    final store = MemoryCloudVisionStore(
      storedKey: _fakeKey,
      enabledFlag: true,
    );
    final repo = OcrRepository(
      const FakeOcrEngine(text: 'manga', id: OcrEngineIds.mangaOcr),
      cloud: CloudVisionOcrEngine(
        readApiKey: store.readApiKey,
        client: ScriptedHttpClient((request) async {
          return jsonHttpResponse(cloudVisionApiKeyInvalidError(), 400);
        }),
      ),
      store: store,
    );
    final outcome = await repo.recognizeCrop(fixturePng());
    expect(outcome.result.engineId, OcrEngineIds.mangaOcr);
    expect(outcome.result.fullText, 'manga');
    expect(outcome.fallback, isA<CloudVisionInvalidApiKey>());
    expect(await store.readApiKey(), _fakeKey);
    expect(await store.isEnabled, isTrue);
  });

  test('success uses Cloud Vision engineId', () async {
    final store = MemoryCloudVisionStore(
      storedKey: _fakeKey,
      enabledFlag: true,
    );
    final repo = OcrRepository(
      const FakeOcrEngine(text: 'manga', id: OcrEngineIds.mangaOcr),
      cloud: CloudVisionOcrEngine(
        readApiKey: store.readApiKey,
        client: ScriptedHttpClient((request) async {
          return jsonHttpResponse({
            'responses': [
              {
                'fullTextAnnotation': {'text': '来てたんだな'},
              },
            ],
          });
        }),
      ),
      store: store,
    );
    final outcome = await repo.recognizeCrop(fixturePng());
    expect(outcome.fallback, isNull);
    expect(outcome.result.engineId, OcrEngineIds.cloudVision);
    expect(outcome.result.fullText, '来てたんだな');
  });
}
