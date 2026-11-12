import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

bool pageImageFileExists(String? path) {
  if (path == null || path.isEmpty) {
    return false;
  }
  return File(path).existsSync();
}

Size? pageImagePixelSize(String? path) {
  if (!pageImageFileExists(path)) {
    return null;
  }
  final decoded = img.decodeImage(File(path!).readAsBytesSync());
  if (decoded == null) {
    return null;
  }
  return Size(decoded.width.toDouble(), decoded.height.toDouble());
}

Widget buildPageImage(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.fill,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
  );
}
