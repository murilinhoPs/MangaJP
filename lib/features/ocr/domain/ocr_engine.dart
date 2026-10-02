import 'dart:typed_data';

import 'ocr_result.dart';

/// Pluggable OCR (PRD §13). Default engine is Q-B1 / later M0.
abstract class OcrEngine {
  String get engineId;

  Future<OcrResult> recognize(Uint8List image);
}
