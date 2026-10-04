import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// manga-ocr (kha-white) — M0.3 bake-off id `manga_ocr`, Q-B1 working default.
///
/// Calls the local sidecar in `tools/manga_ocr_sidecar/serve.py` (same Python
/// package scored at 20.75% CER). Does not embed torch in the Flutter app.
/// Uses `package:http` so Chrome / Flutter web can POST as well as native.
class MangaOcrEngine implements OcrEngine {
  const MangaOcrEngine({this.baseUrl = defaultBaseUrl, this.client});

  static const defaultBaseUrl = 'http://127.0.0.1:8765';
  static const engineName = 'manga_ocr';

  final String baseUrl;
  final http.Client? client;

  @override
  String get engineId => engineName;

  @override
  Future<OcrResult> recognize(Uint8List image) async {
    final uri = Uri.parse(baseUrl).resolve('/ocr');
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .post(
            uri,
            headers: {'Content-Type': 'image/png'},
            body: image,
          )
          .timeout(const Duration(seconds: 120));
      if (response.statusCode != 200) {
        throw StateError(
          'manga-ocr sidecar HTTP ${response.statusCode}: ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body);
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
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw StateError(
        'manga-ocr sidecar is not reachable at $baseUrl. '
        'Start tools/manga_ocr_sidecar/serve.py. ($error)',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
