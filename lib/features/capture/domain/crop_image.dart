import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'crop_rect.dart';

/// PNG bytes of one crop, plus pixel size (debug / tests).
class CropPng {
  const CropPng({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Crop [sourceBytes] to [rect] and encode PNG (PRD §9.4 crops are PNG).
CropPng cropToPng(Uint8List sourceBytes, CropRect rect) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw const FormatException('Could not decode image bytes');
  }
  final oriented = img.bakeOrientation(decoded);

  final clamped = rect.clamped();
  final x = (clamped.left * oriented.width).round().clamp(
    0,
    oriented.width - 1,
  );
  final y = (clamped.top * oriented.height).round().clamp(
    0,
    oriented.height - 1,
  );
  var width = (clamped.width * oriented.width).round();
  var height = (clamped.height * oriented.height).round();
  width = width.clamp(1, oriented.width - x);
  height = height.clamp(1, oriented.height - y);

  final cropped = img.copyCrop(
    oriented,
    x: x,
    y: y,
    width: width,
    height: height,
  );
  return CropPng(
    bytes: Uint8List.fromList(img.encodePng(cropped)),
    width: cropped.width,
    height: cropped.height,
  );
}
