class OcrBlock {
  const OcrBlock({
    required this.text,
    this.confidence,
  });

  final String text;
  final double? confidence;
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
