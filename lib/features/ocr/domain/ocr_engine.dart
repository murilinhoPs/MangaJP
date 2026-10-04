import 'dart:typed_data';

import 'ocr_result.dart';

/// Pluggable OCR (PRD §13). Default is manga-ocr sidecar (`manga_ocr`).
abstract class OcrEngine {
  String get engineId;

  Future<OcrResult> recognize(Uint8List image);
}
