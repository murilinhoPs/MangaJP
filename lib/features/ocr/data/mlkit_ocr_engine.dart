import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// ML Kit JP (`mlkit_ja`) — M0.3 bake-off. Not implemented in the app.
class MlkitOcrEngine implements OcrEngine {
  const MlkitOcrEngine();

  @override
  String get engineId => 'mlkit_ja';

  @override
  Future<OcrResult> recognize(Uint8List image) {
    throw UnimplementedError('ML Kit OCR is scored in tools/cer_bakeoff/; not called from the app yet.');
  }
}
