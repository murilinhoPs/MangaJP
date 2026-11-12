import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/ocr/domain/ocr_result.dart';
import 'package:manga_jp/features/pages/data/ocr_blocks_json.dart';
import 'package:manga_jp/features/pages/domain/ocr_block_geometry.dart';

void main() {
  test('encode is null when no block has a Rect', () {
    expect(OcrBlocksJson.encode(const []), isNull);
    expect(OcrBlocksJson.encode(const [OcrBlockGeometry(text: '猫')]), isNull);
  });

  test('round-trip keeps crop-normalized geometry and confidence', () {
    const blocks = [
      OcrBlockGeometry(
        text: '高い',
        confidence: 0.92,
        left: 0.1,
        top: 0.2,
        width: 0.3,
        height: 0.4,
      ),
      OcrBlockGeometry(text: 'no-rect'),
    ];
    final raw = OcrBlocksJson.encode(blocks);
    expect(raw, isNotNull);
    expect(raw, contains('"text":"高い"'));
    expect(raw, contains('"left":0.1'));
    final decoded = OcrBlocksJson.decode(raw);
    expect(decoded, hasLength(2));
    expect(decoded.first.text, '高い');
    expect(decoded.first.confidence, 0.92);
    expect(decoded.first.left, 0.1);
    expect(decoded.first.hasRect, isTrue);
    expect(decoded.last.hasRect, isFalse);
  });

  test('fromResult normalizes pixel Rects by crop size', () {
    const result = OcrResult(
      fullText: '高い',
      engineId: 'cloud_vision',
      blocks: [
        OcrBlock(
          text: '高い',
          confidence: 0.8,
          boundingBox: Rect.fromLTWH(20, 10, 40, 30),
        ),
      ],
    );
    final blocks = OcrBlocksJson.fromResult(
      result,
      cropWidth: 100,
      cropHeight: 50,
    );
    expect(blocks.single.left, closeTo(0.2, 1e-9));
    expect(blocks.single.top, closeTo(0.2, 1e-9));
    expect(blocks.single.width, closeTo(0.4, 1e-9));
    expect(blocks.single.height, closeTo(0.6, 1e-9));
  });

  test('fromResult keeps already-normalized vertices', () {
    const result = OcrResult(
      fullText: '猫',
      engineId: 'cloud_vision',
      blocks: [
        OcrBlock(text: '猫', boundingBox: Rect.fromLTWH(0.1, 0.2, 0.3, 0.4)),
      ],
    );
    final blocks = OcrBlocksJson.fromResult(
      result,
      cropWidth: 200,
      cropHeight: 200,
    );
    expect(blocks.single.left, closeTo(0.1, 1e-9));
    expect(blocks.single.width, closeTo(0.3, 1e-9));
  });

  test('decode of null / junk is empty', () {
    expect(OcrBlocksJson.decode(null), isEmpty);
    expect(OcrBlocksJson.decode(''), isEmpty);
    expect(OcrBlocksJson.decode('{}'), isEmpty);
    expect(OcrBlocksJson.decode('not-json'), isEmpty);
  });
}
