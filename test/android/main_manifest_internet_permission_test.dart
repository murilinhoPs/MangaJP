import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release merges only `src/main`. debug/profile INTERNET is not enough for OCR.
const _mainManifestPath = 'android/app/src/main/AndroidManifest.xml';

void main() {
  test('main AndroidManifest declares INTERNET for release OCR', () {
    final manifest = File(_mainManifestPath);
    expect(
      manifest.existsSync(),
      isTrue,
      reason: 'expected $_mainManifestPath (cwd is the package root)',
    );
    final hasInternet = RegExp(
      r'<uses-permission[^>]*android:name="android\.permission\.INTERNET"',
      dotAll: true,
    ).hasMatch(manifest.readAsStringSync());
    expect(
      hasInternet,
      isTrue,
      reason:
          'Release APK omits debug/profile manifests. Without INTERNET, '
          'manga-ocr and Cloud Vision fail with a network error.',
    );
  });
}
