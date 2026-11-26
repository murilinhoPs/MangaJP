import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'crop_rect.dart';
import 'off_ui.dart';

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

/// Decode [sourceBytes] once, bake EXIF, crop every rect, encode PNG.
///
/// Top-level so [offUiCompute] can send it to a worker isolate.
List<CropPng> cropAllToPng(CropAllRequest request) {
  final oriented = _orientedImage(request.bytes);
  return [for (final rect in request.rects) _cropOriented(oriented, rect)];
}

/// [cropAllToPng] off the UI isolate. Empty [rects] skips the spawn.
Future<List<CropPng>> cropAllToPngOffUi(
  Uint8List sourceBytes,
  List<CropRect> rects,
) {
  if (rects.isEmpty) {
    return Future<List<CropPng>>.value(const []);
  }
  return offUiCompute(
    cropAllToPng,
    CropAllRequest(bytes: sourceBytes, rects: rects),
  );
}

/// Crop [sourceBytes] to [rect] and encode PNG (PRD §9.4 crops are PNG).
CropPng cropToPng(Uint8List sourceBytes, CropRect rect) {
  return _cropOriented(_orientedImage(sourceBytes), rect);
}

/// Input for [cropAllToPng] across an isolate boundary.
class CropAllRequest {
  const CropAllRequest({required this.bytes, required this.rects});

  final Uint8List bytes;
  final List<CropRect> rects;
}

img.Image _orientedImage(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw const FormatException('Could not decode image bytes');
  }
  return img.bakeOrientation(decoded);
}

CropPng _cropOriented(img.Image oriented, CropRect rect) {
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
