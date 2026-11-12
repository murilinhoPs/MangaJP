import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

bool pageImageFileExists(String? path) {
  if (path == null || path.isEmpty) {
    return false;
  }
  return File(path).existsSync();
}

/// PNG IHDR only — no full-image decode. Missing / unreadable / not PNG → null.
Size? pageImagePixelSize(String? path) {
  if (!pageImageFileExists(path)) {
    return null;
  }
  final raf = File(path!).openSync();
  try {
    final header = raf.readSync(24);
    return pngSizeFromHeader(header);
  } finally {
    raf.closeSync();
  }
}

/// Parses width × height from a PNG signature + IHDR (24 bytes).
Size? pngSizeFromHeader(List<int> header) {
  if (header.length < 24) {
    return null;
  }
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < signature.length; i++) {
    if (header[i] != signature[i]) {
      return null;
    }
  }
  final bytes = Uint8List.fromList(header);
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (width == 0 || height == 0) {
    return null;
  }
  return Size(width.toDouble(), height.toDouble());
}

Widget buildPageImage(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.fill,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
  );
}
