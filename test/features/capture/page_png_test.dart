import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:manga_jp/features/capture/domain/page_png.dart';
import 'package:manga_jp/features/pages/domain/image_magic.dart';

import 'fixture_images.dart';

void main() {
  test('encodePagePng converts JPEG to PNG of the same pixel size', () {
    final jpeg = fixtureJpeg(width: 48, height: 32);
    final png = encodePagePng(jpeg);
    expect(detectImageMagic(png), ImageMagic.png);
    expect(identical(png, jpeg), isFalse);
    final decoded = img.decodeImage(png);
    expect(decoded, isNotNull);
    expect(decoded!.width, 48);
    expect(decoded.height, 32);
  });

  test('encodePagePng bakes JPEG EXIF orientation 6 (90° CW)', () {
    final stored = img.Image(width: 8, height: 16);
    img.fill(stored, color: img.ColorRgb8(20, 20, 20));
    img.fillRect(
      stored,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      color: img.ColorRgb8(220, 10, 10),
    );
    stored.exif.imageIfd.orientation = 6;
    final jpeg = Uint8List.fromList(img.encodeJpg(stored, quality: 100));
    expect(jpegSizeFromHeader(jpeg), const Size(16, 8));

    final png = encodePagePng(jpeg);
    expect(detectImageMagic(png), ImageMagic.png);
    expect(pngSizeFromHeader(png), const Size(16, 8));

    final decoded = img.decodeImage(png)!;
    expect(decoded.width, 16);
    expect(decoded.height, 8);
    // Orientation 6: stored (0,0) → baked (h-1, 0) = (15, 0).
    final pixel = decoded.getPixel(15, 0);
    expect(pixel.r, greaterThan(150));
    expect(pixel.g, lessThan(80));
    expect(pixel.b, lessThan(80));
  });

  test('encodePagePng handles a large JPEG without blowing time or format', () {
    final jpeg = fixtureJpeg(width: 2048, height: 1536, quality: 70);
    final sw = Stopwatch()..start();
    final png = encodePagePng(jpeg);
    sw.stop();
    expect(detectImageMagic(png), ImageMagic.png);
    expect(pngSizeFromHeader(png), const Size(2048, 1536));
    expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('encodePagePng converts WebP to PNG of the same pixel size', () {
    final webp = fixtureWebp(width: 40, height: 24);
    final png = encodePagePng(webp);
    expect(detectImageMagic(png), ImageMagic.png);
    final decoded = img.decodeImage(png)!;
    expect(decoded.width, 40);
    expect(decoded.height, 24);
  });

  test('encodePagePng passes PNG through without re-encoding', () {
    final png = fixturePng(width: 32, height: 48);
    final out = encodePagePng(png);
    expect(identical(out, png), isTrue);
    expect(out, png);
  });

  test(
    'encodePagePngOffUi matches encodePagePng for JPEG, EXIF 6, WebP, PNG',
    () async {
      final jpeg = fixtureJpeg(width: 48, height: 32);
      expect(await encodePagePngOffUi(jpeg), encodePagePng(jpeg));

      final stored = img.Image(width: 8, height: 16);
      img.fill(stored, color: img.ColorRgb8(20, 20, 20));
      img.fillRect(
        stored,
        x1: 0,
        y1: 0,
        x2: 1,
        y2: 1,
        color: img.ColorRgb8(220, 10, 10),
      );
      stored.exif.imageIfd.orientation = 6;
      final exifJpeg = Uint8List.fromList(img.encodeJpg(stored, quality: 100));
      final offUi = await encodePagePngOffUi(exifJpeg);
      final onUi = encodePagePng(exifJpeg);
      expect(offUi, onUi);
      expect(pngSizeFromHeader(offUi), const Size(16, 8));

      final webp = fixtureWebp(width: 40, height: 24);
      expect(await encodePagePngOffUi(webp), encodePagePng(webp));

      final png = fixturePng(width: 32, height: 48);
      final passed = await encodePagePngOffUi(png);
      expect(identical(passed, png), isTrue);
      expect(passed, encodePagePng(png));
    },
  );

  test('Isolate.run encodePagePng matches sync JPEG, EXIF 6, WebP', () async {
    final jpeg = fixtureJpeg(width: 48, height: 32);
    expect(await Isolate.run(() => encodePagePng(jpeg)), encodePagePng(jpeg));

    final stored = img.Image(width: 8, height: 16);
    img.fill(stored, color: img.ColorRgb8(20, 20, 20));
    img.fillRect(
      stored,
      x1: 0,
      y1: 0,
      x2: 1,
      y2: 1,
      color: img.ColorRgb8(220, 10, 10),
    );
    stored.exif.imageIfd.orientation = 6;
    final exifJpeg = Uint8List.fromList(img.encodeJpg(stored, quality: 100));
    expect(
      await Isolate.run(() => encodePagePng(exifJpeg)),
      encodePagePng(exifJpeg),
    );

    final webp = fixtureWebp(width: 40, height: 24);
    expect(await Isolate.run(() => encodePagePng(webp)), encodePagePng(webp));
  });
}
