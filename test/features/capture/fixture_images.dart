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
