import 'dart:convert';

import '../../ocr/domain/ocr_result.dart';
import '../domain/ocr_block_geometry.dart';

/// JSON stored in `crops.ocr_blocks_json`.
///
/// A JSON **array of objects**. Coordinates are **normalized to the crop**
/// (0..1), not the page and not pixels. Pixel `Rect`s from Cloud Vision are
/// divided by the crop PNG size at persist time.
///
/// ```json
/// [
///   {
///     "text": "食べた",
///     "confidence": 0.92,
///     "left": 0.10,
///     "top": 0.20,
///     "width": 0.80,
///     "height": 0.40
///   }
/// ]
/// ```
///
/// - `text` (string, required). Empty text is kept (the overlay still draws).
/// - `confidence` (number, optional). Below 0.5 → dashed box. Omitted → solid.
/// - `left` / `top` / `width` / `height` (numbers, optional as a set). All
///   four must be present and finite to count as a Rect. A block without a
///   Rect is ignored at overlay-mapping time; if **no** block on the crop
///   has a Rect, the overlay uses the crop's own saved rectangle.
///
/// Column `null` or `[]` means "engine gave no boxes" (manga-ocr).
abstract final class OcrBlocksJson {
  static String? encode(List<OcrBlockGeometry> blocks) {
    if (blocks.isEmpty || !blocks.any((block) => block.hasRect)) {
      return null;
    }
    return jsonEncode([for (final block in blocks) _toJson(block)]);
  }

  static List<OcrBlockGeometry> decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) {
      return const [];
    }
    final out = <OcrBlockGeometry>[];
    for (final item in decoded) {
      if (item is Map) {
        out.add(_fromJson(Map<dynamic, dynamic>.from(item)));
      }
    }
    return out;
  }

  /// Maps an [OcrResult] into crop-normalized geometry. Pixel boxes are
  /// divided by [cropWidth]/[cropHeight]. Values already in 0..1 (Vision
  /// `normalizedVertices`) are kept as-is.
  static List<OcrBlockGeometry> fromResult(
    OcrResult result, {
    required int cropWidth,
    required int cropHeight,
  }) {
    final dw = cropWidth <= 0 ? 1.0 : cropWidth.toDouble();
    final dh = cropHeight <= 0 ? 1.0 : cropHeight.toDouble();
    return [
      for (final block in result.blocks)
        OcrBlockGeometry(
          text: block.text,
          confidence: block.confidence,
          left: _norm(block.boundingBox?.left, dw),
          top: _norm(block.boundingBox?.top, dh),
          width: _norm(block.boundingBox?.width, dw),
          height: _norm(block.boundingBox?.height, dh),
        ),
    ];
  }

  static Map<String, Object?> _toJson(OcrBlockGeometry block) {
    return {
      'text': block.text,
      if (block.confidence != null) 'confidence': block.confidence,
      if (block.hasRect) ...{
        'left': block.left,
        'top': block.top,
        'width': block.width,
        'height': block.height,
      },
    };
  }

  static OcrBlockGeometry _fromJson(Map<dynamic, dynamic> json) {
    return OcrBlockGeometry(
      text: '${json['text'] ?? ''}',
      confidence: _num(json['confidence']),
      left: _num(json['left']),
      top: _num(json['top']),
      width: _num(json['width']),
      height: _num(json['height']),
    );
  }

  static double? _num(Object? value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    return null;
  }

  /// Pixel coordinates (any component > 1) are divided by [span]. Values
  /// already in 0..1 pass through.
  static double? _norm(double? value, double span) {
    if (value == null || !value.isFinite) {
      return null;
    }
    if (value.abs() <= 1) {
      return value;
    }
    if (span <= 0) {
      return null;
    }
    return value / span;
  }
}
