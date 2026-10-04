import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/ocr/data/manga_ocr_engine.dart';

import '../capture/fixture_png.dart';

void main() {
  test(
    'MangaOcrEngine POSTs crop PNG to the sidecar and parses text',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/ocr');
        final body = await request.fold<List<int>>(
          <int>[],
          (p, e) => p..addAll(e),
        );
        expect(body, isNotEmpty);
        final payload = jsonEncode({'text': '千鶴屋？', 'engine_id': 'manga_ocr'});
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(payload);
        await request.response.close();
      });

      final engine = MangaOcrEngine(baseUrl: 'http://127.0.0.1:${server.port}');
      final result = await engine.recognize(fixturePng());
      expect(result.engineId, 'manga_ocr');
      expect(result.fullText, '千鶴屋？');
      expect(result.blocks.single.text, '千鶴屋？');
    },
  );

  test('MangaOcrEngine errors when the sidecar is down', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);

    final engine = MangaOcrEngine(baseUrl: 'http://127.0.0.1:$port');
    expect(() => engine.recognize(fixturePng()), throwsA(isA<StateError>()));
  });
}
