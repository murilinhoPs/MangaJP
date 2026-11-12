import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/ocr/data/manga_ocr_engine.dart';
import 'package:manga_jp/features/ocr/domain/ocr_exception.dart';

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
    try {
      await engine.recognize(fixturePng());
      fail('expected MangaOcrUnavailable');
    } on MangaOcrUnavailable catch (error) {
      expect(error.userMessage, 'OCR indisponível: manga-ocr não respondeu.');
      expect('$error', error.userMessage);
      expect('$error', isNot(contains('Bad state')));
      expect('$error', isNot(contains('SocketException')));
      expect('$error', isNot(contains('errno')));
      expect('$error', isNot(contains('$port')));
    }
  });

  test('MangaOcrEngine HTTP error is typed, not the sidecar body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('traceback: boom');
      await request.response.close();
    });

    final engine = MangaOcrEngine(baseUrl: 'http://127.0.0.1:${server.port}');
    try {
      await engine.recognize(fixturePng());
      fail('expected MangaOcrUnavailable');
    } on MangaOcrUnavailable catch (error) {
      expect('$error', isNot(contains('traceback')));
      expect('$error', isNot(contains('HTTP 500')));
    }
  });
}
