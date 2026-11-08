import '../domain/cloud_vision_exception.dart';
import '../domain/ocr_result.dart';

/// One crop's OCR, with an optional visible Cloud Vision → manga-ocr fallback.
class CropOcrOutcome {
  const CropOcrOutcome({required this.result, this.fallback});

  final OcrResult result;
  final CloudVisionException? fallback;
}
