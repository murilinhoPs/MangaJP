import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:manga_jp/features/capture/domain/crop_image.dart';
import 'package:manga_jp/features/capture/domain/crop_rect.dart';

import 'fixture_png.dart';

void main() {
  test('cropToPng emits non-empty PNG of the requested rect', () {
    final source = fixturePng();
    const rect = CropRect(left: 0.25, top: 0.25, width: 0.5, height: 0.5);

    final crop = cropToPng(source, rect);

    expect(crop.bytes.length, greaterThan(0));
    expect(crop.width, 32);
    expect(crop.height, 32);

    final decoded = img.decodeImage(crop.bytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 32);
    expect(decoded.height, 32);

    final pixel = decoded.getPixel(16, 16);
    expect(pixel.r, 20);
    expect(pixel.g, 40);
    expect(pixel.b, 200);
  });

  test('default rect still yields bytes.length > 0', () {
    final crop = cropToPng(fixturePng(), CropRect.initial);
    expect(crop.bytes.length, greaterThan(0));
    expect(crop.width, greaterThan(0));
    expect(crop.height, greaterThan(0));
  });

  test('cropAllToPngOffUi matches cropToPng for each rect', () async {
    final source = fixturePng();
    const rects = [
      CropRect(left: 0.25, top: 0.25, width: 0.5, height: 0.5),
      CropRect.initial,
    ];
    final offUi = await cropAllToPngOffUi(source, rects);
    expect(offUi, hasLength(2));
    for (var i = 0; i < rects.length; i++) {
      final expected = cropToPng(source, rects[i]);
      expect(offUi[i].width, expected.width);
      expect(offUi[i].height, expected.height);
      expect(offUi[i].bytes, expected.bytes);
    }
  });

  test('Isolate.run cropAllToPng matches cropToPng', () async {
    final source = fixturePng();
    const rects = [CropRect(left: 0.25, top: 0.25, width: 0.5, height: 0.5)];
    final isolated = await Isolate.run(
      () => cropAllToPng(CropAllRequest(bytes: source, rects: rects)),
    );
    final expected = cropToPng(source, rects.single);
    expect(isolated.single.width, expected.width);
    expect(isolated.single.height, expected.height);
    expect(isolated.single.bytes, expected.bytes);
  });
}
