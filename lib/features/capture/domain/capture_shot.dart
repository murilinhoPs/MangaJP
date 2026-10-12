import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'crop_rect.dart';

/// Screenshot helper. Off by default.
///
/// `flutter run --dart-define=MANGAJP_CAPTURE_SHOT=1` (single crop) or `=3`.
const kCaptureShotCrops = int.fromEnvironment(
  'MANGAJP_CAPTURE_SHOT',
  defaultValue: 0,
);

Uint8List? captureShotImage() {
  if (kCaptureShotCrops <= 0) {
    return null;
  }
  return buildMangaPanelPng();
}

List<CropRect> captureShotRects() {
  if (kCaptureShotCrops >= 3) {
    return const [
      // Top-left → number 2 (active, matches the Deck).
      CropRect(left: 0.08, top: 0.10, width: 0.36, height: 0.32),
      // Top-right → number 1.
      CropRect(left: 0.54, top: 0.06, width: 0.38, height: 0.30),
      // Bottom-right → number 3.
      CropRect(left: 0.52, top: 0.54, width: 0.40, height: 0.32),
    ];
  }
  return const [CropRect.initial];
}

int captureShotActiveIndex() => kCaptureShotCrops >= 3 ? 0 : 0;

/// Small grayscale 2×2 manga page (speech-bubble ellipses, no large binary).
Uint8List buildMangaPanelPng({int width = 360, int height = 520}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(22, 22, 26));

  const gutter = 8;
  final panelW = (width - gutter * 3) ~/ 2;
  final panelH = (height - gutter * 3) ~/ 2;
  final tones = <img.ColorRgb8>[
    img.ColorRgb8(36, 36, 40),
    img.ColorRgb8(42, 42, 46),
    img.ColorRgb8(32, 32, 36),
    img.ColorRgb8(38, 38, 42),
  ];
  final origins = <(int, int)>[
    (gutter, gutter),
    (gutter * 2 + panelW, gutter),
    (gutter, gutter * 2 + panelH),
    (gutter * 2 + panelW, gutter * 2 + panelH),
  ];
  for (var i = 0; i < 4; i++) {
    final (x, y) = origins[i];
    img.fillRect(
      image,
      x1: x,
      y1: y,
      x2: x + panelW - 1,
      y2: y + panelH - 1,
      color: tones[i],
    );
  }

  void bubble(int panel, double nx, double ny, double rx, double ry) {
    final (px, py) = origins[panel];
    final cx = px + (nx * panelW).round();
    final cy = py + (ny * panelH).round();
    final rxPx = (rx * panelW).round().clamp(8, panelW ~/ 2);
    final ryPx = (ry * panelH).round().clamp(8, panelH ~/ 2);
    img.fillCircle(
      image,
      x: cx,
      y: cy,
      radius: rxPx > ryPx ? rxPx : ryPx,
      color: img.ColorRgb8(210, 208, 214),
    );
  }

  bubble(0, 0.50, 0.42, 0.34, 0.22);
  bubble(1, 0.50, 0.40, 0.32, 0.22);
  bubble(3, 0.50, 0.42, 0.34, 0.22);

  return Uint8List.fromList(img.encodePng(image));
}
