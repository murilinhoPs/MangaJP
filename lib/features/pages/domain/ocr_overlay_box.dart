import 'ocr_block_geometry.dart';
import 'page_crop.dart';

/// Confidence below this draws a dashed border (motif TOKENS.md).
const ocrOverlayLowConfidence = 0.5;

/// One overlay box on the **page**, in page-normalized 0..1 coordinates.
///
/// Geometry rules (Murilo, F22):
/// - Engine `Rect` present (Cloud Vision) → that box, mapped from crop space
///   onto the page via the crop's saved rectangle.
/// - No `Rect` (manga-ocr default) → the crop's own saved rectangle.
/// - Fallback crop-rect boxes use the same tokens/states as engine boxes.
///   Dashed is only [isLowConfidence], never a special fallback style.
class OcrOverlayBox {
  const OcrOverlayBox({
    required this.id,
    required this.cropId,
    required this.number,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.text,
    this.confidence,
  });

  final String id;
  final String cropId;

  /// 1-based badge drawn on the box.
  final int number;

  final double left;
  final double top;
  final double width;
  final double height;
  final String text;
  final double? confidence;

  bool get isLowConfidence =>
      confidence != null && confidence! < ocrOverlayLowConfidence;
}

/// Maps persisted crops + optional engine blocks onto page-normalized boxes.
List<OcrOverlayBox> overlayBoxesFor(List<PageCrop> crops) {
  final out = <OcrOverlayBox>[];
  var number = 1;
  for (final crop in crops) {
    final withRect = [
      for (final block in crop.ocrBlocks)
        if (block.hasRect) block,
    ];
    if (withRect.isEmpty) {
      out.add(
        OcrOverlayBox(
          id: crop.id,
          cropId: crop.id,
          number: number++,
          left: crop.left,
          top: crop.top,
          width: crop.width,
          height: crop.height,
          text: crop.ocrText,
        ),
      );
      continue;
    }
    for (var i = 0; i < withRect.length; i++) {
      out.add(
        _mapBlock(crop: crop, block: withRect[i], index: i, number: number++),
      );
    }
  }
  return out;
}

OcrOverlayBox _mapBlock({
  required PageCrop crop,
  required OcrBlockGeometry block,
  required int index,
  required int number,
}) {
  return OcrOverlayBox(
    id: '${crop.id}#$index',
    cropId: crop.id,
    number: number,
    left: crop.left + block.left! * crop.width,
    top: crop.top + block.top! * crop.height,
    width: block.width! * crop.width,
    height: block.height! * crop.height,
    text: block.text,
    confidence: block.confidence,
  );
}
