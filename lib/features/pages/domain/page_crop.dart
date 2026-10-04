/// One persisted crop + OCR text (M1.1). Lookup / Caderno are later M1.
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
}
