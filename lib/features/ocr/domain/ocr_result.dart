import 'dart:ui' show Rect;

class OcrBlock {
  const OcrBlock({
    required this.text,
    this.confidence,
    this.boundingBox,
    this.normalized = false,
  });

  final String text;
  final double? confidence;
  final Rect? boundingBox;

  /// When true, [boundingBox] is already 0..1 of the source image
  /// (Cloud Vision `normalizedVertices`). When false, it is pixels.
  final bool normalized;
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
