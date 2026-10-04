import 'dart:io';

/// Sidecar URL from `--dart-define=MANGA_OCR_URL=…` or the process environment.
String? mangaOcrUrl() {
  const defined = String.fromEnvironment('MANGA_OCR_URL');
  if (defined.isNotEmpty) return defined;
  return Platform.environment['MANGA_OCR_URL'];
}
