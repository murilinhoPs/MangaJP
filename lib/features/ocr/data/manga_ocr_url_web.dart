/// Sidecar URL from `--dart-define=MANGA_OCR_URL=…` (no process env on web).
String? mangaOcrUrl() {
  const defined = String.fromEnvironment('MANGA_OCR_URL');
  return defined.isEmpty ? null : defined;
}
