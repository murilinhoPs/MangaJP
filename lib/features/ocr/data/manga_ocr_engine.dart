import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// manga-ocr (kha-white) — M0.3 bake-off id `manga_ocr`, Q-B1 working default.
///
/// Calls the local sidecar in `tools/manga_ocr_sidecar/serve.py` (same Python
/// package scored at 20.75% CER). Does not embed torch in the Flutter app.
class MangaOcrEngine implements OcrEngine {
  const MangaOcrEngine({this.baseUrl = defaultBaseUrl});

  static const defaultBaseUrl = 'http://127.0.0.1:8765';
  static const engineName = 'manga_ocr';

  final String baseUrl;

  @override
  String get engineId => engineName;

  @override
  Future<OcrResult> recognize(Uint8List image) async {
    final uri = Uri.parse(baseUrl).resolve('/ocr');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType('image', 'png');
      request.contentLength = image.lengthInBytes;
      request.add(image);
      final response = await request.close().timeout(
        const Duration(seconds: 120),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'manga-ocr sidecar HTTP ${response.statusCode}: $body',
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException(
          'manga-ocr sidecar returned non-object JSON',
        );
      }
      final text = '${decoded['text'] ?? decoded['full_text'] ?? ''}';
      return OcrResult(
        fullText: text,
        blocks: [if (text.isNotEmpty) OcrBlock(text: text)],
        engineId: engineId,
      );
    } on SocketException catch (error) {
      throw StateError(
        'manga-ocr sidecar is not reachable at $baseUrl. '
        'Start tools/manga_ocr_sidecar/serve.py. ($error)',
      );
    } finally {
      client.close(force: true);
    }
  }
}
