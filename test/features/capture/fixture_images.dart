import 'dart:typed_data';

import 'package:image/image.dart' as img;

export 'fixture_png.dart';

/// Same panel as [fixturePng], encoded JPEG.
Uint8List fixtureJpeg({
  int width = 64,
  int height = 64,
  int quality = 90,
  int? orientation,
}) {
  final image = _panel(width: width, height: height);
  if (orientation != null) {
    image.exif.imageIfd.orientation = orientation;
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}

/// Same panel as [fixturePng], encoded lossy WebP (fast method for tests).
Uint8List fixtureWebp({int width = 64, int height = 64}) {
  final image = _panel(width: width, height: height);
  return Uint8List.fromList(
    img.encodeWebP(image, lossless: false, quality: 75, method: 0),
  );
}

/// Simple VP8 WebP whose declared chunk is [minLength] bytes. A 128 KiB
/// header prefix cannot contain the whole bitstream — the size fields still
/// sit in the first 20 bytes.
Uint8List fixtureWebpInflatedTo(
  int minLength, {
  int width = 48,
  int height = 36,
}) {
  final webp = fixtureWebp(width: width, height: height);
  if (webp.length < 20) {
    throw StateError('WebP fixture too short');
  }
  if (minLength < webp.length) {
    throw ArgumentError.value(minLength, 'minLength');
  }
  final out = Uint8List(minLength);
  out.setRange(0, webp.length, webp);
  final riffSize = minLength - 8;
  final chunkSize = minLength - 20;
  out[4] = riffSize & 0xFF;
  out[5] = (riffSize >> 8) & 0xFF;
  out[6] = (riffSize >> 16) & 0xFF;
  out[7] = (riffSize >> 24) & 0xFF;
  out[16] = chunkSize & 0xFF;
  out[17] = (chunkSize >> 8) & 0xFF;
  out[18] = (chunkSize >> 16) & 0xFF;
  out[19] = (chunkSize >> 24) & 0xFF;
  return out;
}

img.Image _panel({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 40, 40));
  img.fillRect(
    image,
    x1: width ~/ 4,
    y1: height ~/ 4,
    x2: (width * 3 ~/ 4) - 1,
    y2: (height * 3 ~/ 4) - 1,
    color: img.ColorRgb8(20, 40, 200),
  );
  return image;
}
