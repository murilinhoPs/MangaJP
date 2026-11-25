import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../pages/domain/image_magic.dart';

/// Page bytes stored as `{pageId}.png`.
///
/// JPEG/WebP (gallery, share) are decoded, EXIF-baked, and encoded as PNG.
/// PNG input is returned as-is so screenshots stay bit-identical.
Uint8List encodePagePng(Uint8List sourceBytes) {
  if (detectImageMagic(sourceBytes) == ImageMagic.png) {
    return sourceBytes;
  }
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw const FormatException('Could not decode image bytes');
  }
  final oriented = img.bakeOrientation(decoded);
  return Uint8List.fromList(img.encodePng(oriented));
}
