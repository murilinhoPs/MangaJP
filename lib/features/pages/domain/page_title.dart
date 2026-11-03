/// Title for a captured page when Drift has no `pages.title`.
///
/// First OCR line, truncated; **Página** when the page has no text.
abstract final class PageTitle {
  static const fallback = 'Página';
  static const maxChars = 36;

  static String fromOcr(String? ocrPreview) {
    final text = ocrPreview?.trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    final line = text.split('\n').first.trim();
    if (line.length <= maxChars) {
      return line;
    }
    return '${line.substring(0, maxChars)}…';
  }
}
