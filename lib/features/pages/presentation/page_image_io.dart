import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/image_magic.dart';

/// Enough for PNG IHDR, WebP VP8X, and a JPEG APP1 (max 64 KiB) plus SOF.
const _headerCap = 128 * 1024;

bool pageImageFileExists(String? path) {
  if (path == null || path.isEmpty) {
    return false;
  }
  return File(path).existsSync();
}

/// Magic-bytes size. Missing / unreadable / unknown format → null.
Size? pageImagePixelSize(String? path) {
  if (!pageImageFileExists(path)) {
    return null;
  }
  final raf = File(path!).openSync();
  try {
    final length = raf.lengthSync();
    final n = math.min(length, _headerCap);
    final header = raf.readSync(n);
    return imageSizeFromHeader(header);
  } finally {
    raf.closeSync();
  }
}

Widget buildPageImage(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.fill,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
  );
}
