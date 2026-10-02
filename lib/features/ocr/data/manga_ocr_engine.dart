import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// manga-ocr (kha-white) — M0.3 bake-off id `manga_ocr`. Not wired to UI.
class MangaOcrEngine implements OcrEngine {
  const MangaOcrEngine();

  @override
  String get engineId => 'manga_ocr';

  @override
  Future<OcrResult> recognize(Uint8List image) {
    throw UnimplementedError(
      'manga-ocr is scored in tools/cer_bakeoff/; not called from the app yet.',
    );
  }
}
