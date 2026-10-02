import 'dart:typed_data';

import '../domain/ocr_engine.dart';
import '../domain/ocr_result.dart';

/// ML Kit JP — bake-off later M0. Not implemented in the scaffold.
class MlkitOcrEngine implements OcrEngine {
  const MlkitOcrEngine();

  @override
  String get engineId => 'mlkit_ja';

  @override
  Future<OcrResult> recognize(Uint8List image) {
    throw UnimplementedError('ML Kit OCR is not part of M0.1.');
  }
}
