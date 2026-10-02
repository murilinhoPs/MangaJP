import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Solid-ish PNG used by M0.8 smoke tests (red field, blue center).
Uint8List fixturePng({int width = 64, int height = 64}) {
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
  return Uint8List.fromList(img.encodePng(image));
}
