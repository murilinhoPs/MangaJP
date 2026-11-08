import 'dart:math' as math;
import 'dart:ui' show Rect;

import '../domain/ocr_engine_ids.dart';
import '../domain/ocr_result.dart';

/// Parses a Cloud Vision `images:annotate` JSON body into [OcrResult].
///
/// Uses `fullTextAnnotation.text` (ruby filter is unofficial and not default).
OcrResult parseCloudVisionResponse(Object? decoded) {
  if (decoded is! Map) {
    throw const FormatException('Cloud Vision returned non-object JSON');
  }
  final responses = decoded['responses'];
  if (responses is! List || responses.isEmpty) {
    return const OcrResult(
      fullText: '',
      blocks: [],
      engineId: OcrEngineIds.cloudVision,
    );
  }
  final first = responses.first;
  if (first is! Map) {
    throw const FormatException('Cloud Vision response is not an object');
  }
  final annotation = first['fullTextAnnotation'];
  if (annotation is Map) {
    final fullText = '${annotation['text'] ?? ''}';
    return OcrResult(
      fullText: fullText,
      blocks: _blocksFromAnnotation(Map<dynamic, dynamic>.from(annotation)),
      engineId: OcrEngineIds.cloudVision,
    );
  }
  final annotations = first['textAnnotations'];
  if (annotations is List && annotations.isNotEmpty) {
    final top = annotations.first;
    final text = top is Map ? '${top['description'] ?? ''}' : '';
    return OcrResult(
      fullText: text,
      blocks: [if (text.isNotEmpty) OcrBlock(text: text)],
      engineId: OcrEngineIds.cloudVision,
    );
  }
  return const OcrResult(
    fullText: '',
    blocks: [],
    engineId: OcrEngineIds.cloudVision,
  );
}

/// Google JSON error `status`, if any (top-level or first response).
String? cloudVisionErrorStatus(Object? decoded) {
  if (decoded is! Map) {
    return null;
  }
  final top = decoded['error'];
  if (top is Map) {
    final status = top['status'];
    if (status is String && status.isNotEmpty) {
      return status;
    }
  }
  final responses = decoded['responses'];
  if (responses is List && responses.isNotEmpty) {
    final first = responses.first;
    if (first is Map) {
      final nested = first['error'];
      if (nested is Map) {
        final status = nested['status'];
        if (status is String && status.isNotEmpty) {
          return status;
        }
      }
    }
  }
  return null;
}

List<OcrBlock> _blocksFromAnnotation(Map<dynamic, dynamic> annotation) {
  final pages = annotation['pages'];
  if (pages is! List) {
    final text = '${annotation['text'] ?? ''}';
    return [if (text.isNotEmpty) OcrBlock(text: text)];
  }
  final blocks = <OcrBlock>[];
  for (final page in pages) {
    if (page is! Map) {
      continue;
    }
    final rawBlocks = page['blocks'];
    if (rawBlocks is! List) {
      continue;
    }
    for (final raw in rawBlocks) {
      if (raw is! Map) {
        continue;
      }
      final text = _blockText(Map<dynamic, dynamic>.from(raw));
      if (text.isEmpty) {
        continue;
      }
      final confidence = raw['confidence'];
      blocks.add(
        OcrBlock(
          text: text,
          confidence: confidence is num ? confidence.toDouble() : null,
          boundingBox: boundingBoxFromVision(raw['boundingBox']),
        ),
      );
    }
  }
  return blocks;
}

String _blockText(Map<dynamic, dynamic> block) {
  final buffer = StringBuffer();
  final paragraphs = block['paragraphs'];
  if (paragraphs is List) {
    for (final paragraph in paragraphs) {
      if (paragraph is! Map) {
        continue;
      }
      final words = paragraph['words'];
      if (words is! List) {
        continue;
      }
      for (final word in words) {
        if (word is! Map) {
          continue;
        }
        final symbols = word['symbols'];
        if (symbols is! List) {
          continue;
        }
        for (final symbol in symbols) {
          if (symbol is Map) {
            buffer.write('${symbol['text'] ?? ''}');
          }
        }
      }
    }
  }
  return buffer.toString();
}

Rect? boundingBoxFromVision(Object? boundingBox) {
  if (boundingBox is! Map) {
    return null;
  }
  final vertices = boundingBox['vertices'] ?? boundingBox['normalizedVertices'];
  if (vertices is! List || vertices.isEmpty) {
    return null;
  }
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = -double.infinity;
  var maxY = -double.infinity;
  var saw = false;
  for (final vertex in vertices) {
    if (vertex is! Map) {
      continue;
    }
    final x = (vertex['x'] as num?)?.toDouble() ?? 0;
    final y = (vertex['y'] as num?)?.toDouble() ?? 0;
    minX = math.min(minX, x);
    minY = math.min(minY, y);
    maxX = math.max(maxX, x);
    maxY = math.max(maxY, y);
    saw = true;
  }
  if (!saw) {
    return null;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
