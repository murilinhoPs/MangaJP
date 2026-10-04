import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/ocr/data/manga_ocr_url.dart';

void main() {
  test('native share is off on desktop / web hosts', () async {
    final source = ImageSourceService();
    expect(kIsWeb, isFalse);
    expect(
      defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS,
      isFalse,
    );
    expect(await source.initialMedia(), isNull);
  });

  test('manga-ocr URL is unset unless dart-define or env is set', () {
    expect(mangaOcrUrl(), isNull);
  });
}
