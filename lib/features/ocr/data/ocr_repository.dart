import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';
import 'manga_ocr_engine.dart';
import 'manga_ocr_url.dart';

part 'ocr_repository.g.dart';

/// Default OCR is the manga-ocr sidecar (`docs/m0.3-cer-bakeoff.md`, 20.75% CER).
@Riverpod(keepAlive: true)
OcrEngine ocrEngine(Ref ref) {
  final url = mangaOcrUrl();
  return MangaOcrEngine(
    baseUrl: (url == null || url.isEmpty) ? MangaOcrEngine.defaultBaseUrl : url,
  );
}

@Riverpod(keepAlive: true)
OcrRepository ocrRepository(Ref ref) {
  return OcrRepository(ref.watch(ocrEngineProvider));
}

class OcrRepository {
  const OcrRepository(this.engine);

  final OcrEngine engine;

  Future<OcrResult> recognize(Uint8List image) => engine.recognize(image);
}
