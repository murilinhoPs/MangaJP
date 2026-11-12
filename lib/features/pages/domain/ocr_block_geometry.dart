/// One OCR block persisted from `crops.ocr_blocks_json`.
///
/// Coordinates are **normalized to the crop** (0..1), not the page and not
/// pixels. JSON mapping lives in the data layer.
class OcrBlockGeometry {
  const OcrBlockGeometry({
    required this.text,
    this.confidence,
    this.left,
    this.top,
    this.width,
    this.height,
  });

  final String text;
  final double? confidence;

  /// Crop-normalized left. All four of [left]/[top]/[width]/[height] must
  /// be set to count as a Rect.
  final double? left;
  final double? top;
  final double? width;
  final double? height;

  bool get hasRect =>
      left != null && top != null && width != null && height != null;
}
