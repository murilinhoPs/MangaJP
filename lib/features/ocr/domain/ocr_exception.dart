/// User-facing OCR failure. [userMessage] is PT copy; never socket/HTTP guts.
sealed class OcrException implements Exception {
  const OcrException({required this.userMessage});

  final String userMessage;

  @override
  String toString() => userMessage;
}

/// Local manga-ocr sidecar down, HTTP error, or unreadable response.
final class MangaOcrUnavailable extends OcrException {
  const MangaOcrUnavailable()
    : super(userMessage: 'OCR indisponível: manga-ocr não respondeu.');
}

/// Cloud Vision failed and the manga-ocr fallback also failed.
final class OcrBothUnavailable extends OcrException {
  const OcrBothUnavailable()
    : super(
        userMessage: 'OCR indisponível: Cloud Vision e manga-ocr falharam.',
      );
}

/// Catch-all so the UI never shows a raw [StateError] / [SocketException].
final class OcrUnavailable extends OcrException {
  const OcrUnavailable() : super(userMessage: 'OCR indisponível.');
}
