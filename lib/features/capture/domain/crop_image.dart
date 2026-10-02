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

  final clamped = rect.clamped();
  final x = (clamped.left * decoded.width).round().clamp(0, decoded.width - 1);
  final y = (clamped.top * decoded.height).round().clamp(0, decoded.height - 1);
  var width = (clamped.width * decoded.width).round();
  var height = (clamped.height * decoded.height).round();
  width = width.clamp(1, decoded.width - x);
  height = height.clamp(1, decoded.height - y);

  final cropped = img.copyCrop(
    decoded,
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
