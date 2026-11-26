import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/image_magic.dart';

/// Prefix read for [pageImagePixelSize]. [kPageImageHeaderCap] covers PNG
/// IHDR, WebP VP8/VP8L/VP8X dimension bytes, and a typical JPEG APP1
/// (max 64 KiB) plus SOF.
///
/// JPEG with huge XMP / ICC / MPF segments before SOF can still miss the
/// size and fall back to text cards — acceptable for the overlay gate.

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
    final n = math.min(length, kPageImageHeaderCap);
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
