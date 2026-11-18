import 'ocr_block_geometry.dart';

/// One persisted crop + OCR text (M1.1). Tap-to-lookup is M1.3 (no Caderno).
class PageCrop {
  const PageCrop({
    required this.id,
    required this.pageId,
    required this.ocrText,
    required this.engineId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.createdAt,
    this.ocrBlocks = const [],
  });

  final String id;
  final String pageId;
  final String ocrText;
  final String engineId;
  final double left;
  final double top;
  final double width;
  final double height;
  final DateTime createdAt;

  /// Engine boxes, crop-normalized. Empty → overlay uses this crop's rect.
  final List<OcrBlockGeometry> ocrBlocks;
}
