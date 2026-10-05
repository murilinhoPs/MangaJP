import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/ocr/data/manga_ocr_url.dart';

void main() {
  test('native share is off on the CI / desktop host', () async {
    expect(Platform.isAndroid || Platform.isIOS, isFalse);
    expect(await ImageSourceService().initialMedia(), isNull);
  });

  test('manga-ocr URL is unset unless dart-define or env is set', () {
    expect(mangaOcrUrl(), isNull);
  });
}
