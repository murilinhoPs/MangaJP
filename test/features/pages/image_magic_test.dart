import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/pages/domain/image_magic.dart';

import '../capture/fixture_images.dart';

void main() {
  test('detectImageMagic reads PNG/JPEG/WebP/unknown from magic bytes', () {
    expect(detectImageMagic(fixturePng()), ImageMagic.png);
    expect(detectImageMagic(fixtureJpeg()), ImageMagic.jpeg);
    expect(detectImageMagic(fixtureWebp()), ImageMagic.webp);
    expect(detectImageMagic(Uint8List(0)), ImageMagic.unknown);
    expect(
      detectImageMagic(Uint8List.fromList([0, 1, 2, 3])),
      ImageMagic.unknown,
    );
    expect(
      detectImageMagic(Uint8List.fromList('GIF89a'.codeUnits)),
      ImageMagic.unknown,
    );
  });

  test('detectImageMagic ignores a .png-like name and uses bytes', () {
    final jpeg = fixtureJpeg();
    expect(detectImageMagic(jpeg), ImageMagic.jpeg);
    expect(imageSizeFromHeader(jpeg), isNotNull);
  });

  test('webpSizeFromHeader reads VP8 dimensions from a truncated prefix', () {
    const width = 48;
    const height = 36;
    final full = fixtureWebpInflatedTo(
      kPageImageHeaderCap + 64 * 1024,
      width: width,
      height: height,
    );
    expect(full.length, greaterThan(kPageImageHeaderCap));
    final prefix = Uint8List.sublistView(full, 0, kPageImageHeaderCap);
    expect(webpSizeFromHeader(prefix), const Size(48, 36));
    expect(imageSizeFromHeader(prefix), const Size(48, 36));
  });
}
