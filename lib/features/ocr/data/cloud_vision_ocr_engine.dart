import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// Cloud Vision (`cloud_vision`) — M0.3 bake-off. Not implemented in the app.
class CloudVisionOcrEngine implements OcrEngine {
  const CloudVisionOcrEngine();

  @override
  String get engineId => 'cloud_vision';

  @override
  Future<OcrResult> recognize(Uint8List image) {
    throw UnimplementedError(
      'Cloud Vision OCR is scored in tools/cer_bakeoff/; not called from the app yet.',
    );
  }
}
