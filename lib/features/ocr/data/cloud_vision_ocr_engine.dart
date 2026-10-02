import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// Cloud Vision fallback — not implemented in the scaffold.
class CloudVisionOcrEngine implements OcrEngine {
  const CloudVisionOcrEngine();

  @override
  String get engineId => 'cloud_vision';

  @override
  Future<OcrResult> recognize(Uint8List image) {
    throw UnimplementedError('Cloud Vision OCR is not part of M0.1.');
  }
}
