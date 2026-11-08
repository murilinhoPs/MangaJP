import 'dart:ui' show Rect;

class OcrBlock {
  const OcrBlock({required this.text, this.confidence, this.boundingBox});

  final String text;
  final double? confidence;
  final Rect? boundingBox;
}

class OcrResult {
  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.engineId,
  });

  final String fullText;
  final List<OcrBlock> blocks;
  final String engineId;
}
