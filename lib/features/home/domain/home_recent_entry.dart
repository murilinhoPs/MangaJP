/// One row of Home **Páginas recentes** / **Capturas recentes**.
///
/// Pages have no title, thumbnail bytes, or reading progress in Drift.
/// [ocrPreview] is the first crop's OCR when that exists.
class HomeRecentEntry {
  const HomeRecentEntry({
    required this.id,
    required this.createdAt,
    required this.cropCount,
    this.ocrPreview,
  });

  final String id;
  final DateTime createdAt;
  final int cropCount;
  final String? ocrPreview;

  /// First OCR line, or **Página** when the page has no text.
  String get title {
    final text = ocrPreview?.trim();
    if (text == null || text.isEmpty) {
      return 'Página';
    }
    final line = text.split('\n').first.trim();
    if (line.length <= 36) {
      return line;
    }
    return '${line.substring(0, 36)}…';
  }
}
