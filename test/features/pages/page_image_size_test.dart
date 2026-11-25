import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/pages/presentation/page_image.dart';

import '../capture/fixture_images.dart';

void main() {
  test('pngSizeFromHeader reads IHDR width and height', () {
    final header = Uint8List(24);
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    header.setRange(0, 8, signature);
    ByteData.sublistView(header).setUint32(16, 390);
    ByteData.sublistView(header).setUint32(20, 844);
    expect(pngSizeFromHeader(header), const Size(390, 844));
  });

  test('pngSizeFromHeader rejects non-PNG', () {
    expect(pngSizeFromHeader(Uint8List(24)), isNull);
    expect(pngSizeFromHeader(Uint8List(8)), isNull);
  });

  test('jpegSizeFromHeader reads SOF width and height', () {
    final jpeg = fixtureJpeg(width: 80, height: 60);
    expect(jpegSizeFromHeader(jpeg), const Size(80, 60));
    expect(imageSizeFromHeader(jpeg), const Size(80, 60));
  });

  test('jpegSizeFromHeader swaps size for EXIF orientation 6', () {
    final jpeg = fixtureJpeg(width: 8, height: 16, orientation: 6);
    expect(jpegSizeFromHeader(jpeg), const Size(16, 8));
  });

  test('webpSizeFromHeader reads canvas width and height', () {
    final webp = fixtureWebp(width: 50, height: 70);
    expect(webpSizeFromHeader(webp), const Size(50, 70));
    expect(imageSizeFromHeader(webp), const Size(50, 70));
  });

  test('pageImagePixelSize is null for a missing file', () async {
    debugPageImageUsePlaceholder = false;
    addTearDown(() => debugPageImageUsePlaceholder = false);
    expect(await pageImagePixelSize('/no-such-overlay.png'), isNull);
  });

  test(
    'pageImagePixelSize reads a real PNG header without full decode',
    () async {
      debugPageImageUsePlaceholder = false;
      addTearDown(() => debugPageImageUsePlaceholder = false);
      final dir = await Directory.systemTemp.createTemp('page-img-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/page.png');
      file.writeAsBytesSync(_tinyPng(4, 6), flush: true);
      expect(await pageImagePixelSize(file.path), const Size(4, 6));
    },
  );

  test(
    'pageImagePixelSize reads JPEG and WebP saved with a .png name',
    () async {
      debugPageImageUsePlaceholder = false;
      addTearDown(() => debugPageImageUsePlaceholder = false);
      final dir = await Directory.systemTemp.createTemp('page-img-fmt-');
      addTearDown(() => dir.deleteSync(recursive: true));

      final jpegFile = File('${dir.path}/legacy-jpeg.png');
      jpegFile.writeAsBytesSync(
        fixtureJpeg(width: 96, height: 48),
        flush: true,
      );
      expect(await pageImagePixelSize(jpegFile.path), const Size(96, 48));

      final webpFile = File('${dir.path}/legacy-webp.png');
      webpFile.writeAsBytesSync(
        fixtureWebp(width: 36, height: 72),
        flush: true,
      );
      expect(await pageImagePixelSize(webpFile.path), const Size(36, 72));
    },
  );

  test(
    'pageImagePixelSize sizes a WebP >128KiB named .png (overlay gate)',
    () async {
      debugPageImageUsePlaceholder = false;
      addTearDown(() => debugPageImageUsePlaceholder = false);
      final dir = await Directory.systemTemp.createTemp('page-img-big-webp-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/legacy-big.webp.png');
      final bytes = fixtureWebpInflatedTo(
        kPageImageHeaderCap + 32 * 1024,
        width: 48,
        height: 36,
      );
      expect(bytes.length, greaterThan(kPageImageHeaderCap));
      file.writeAsBytesSync(bytes, flush: true);
      // hasImage / overlay follows this size; FileImage of WebP does not
      // settle under AutomatedTestWidgetsFlutterBinding.
      expect(await pageImagePixelSize(file.path), const Size(48, 36));
    },
  );
}

/// 4×6 RGB PNG, 1×1 IHDR + empty IDAT is invalid; use a known-good tiny PNG.
Uint8List _tinyPng(int width, int height) {
  // Uncompressed 4×6 RGB via the `image` encoder would pull a heavy import.
  // Minimal valid PNG: signature + IHDR + IEND.
  final ihdr = BytesBuilder();
  final len = ByteData(4)..setUint32(0, 13);
  ihdr.add(len.buffer.asUint8List());
  ihdr.add('IHDR'.codeUnits);
  final dims = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  ihdr.add(dims.buffer.asUint8List());
  ihdr.add(ByteData(4).buffer.asUint8List()); // CRC ignored by our parser
  final iend = BytesBuilder();
  iend.add(ByteData(4).buffer.asUint8List());
  iend.add('IEND'.codeUnits);
  iend.add(ByteData(4).buffer.asUint8List());
  return Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    ...ihdr.takeBytes(),
    ...iend.takeBytes(),
  ]);
}
