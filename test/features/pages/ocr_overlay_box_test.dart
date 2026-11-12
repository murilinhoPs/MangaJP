import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/pages/domain/ocr_block_geometry.dart';
import 'package:manga_jp/features/pages/domain/ocr_overlay_box.dart';
import 'package:manga_jp/features/pages/domain/page_crop.dart';

PageCrop _crop({
  required String id,
  double left = 0.1,
  double top = 0.2,
  double width = 0.5,
  double height = 0.4,
  String ocrText = '猫を食べた。',
  List<OcrBlockGeometry> ocrBlocks = const [],
}) {
  return PageCrop(
    id: id,
    pageId: 'page',
    ocrText: ocrText,
    engineId: 'test',
    left: left,
    top: top,
    width: width,
    height: height,
    createdAt: DateTime.utc(2026, 1, 1),
    ocrBlocks: ocrBlocks,
  );
}

void main() {
  test('no Rect falls back to the crop rectangle, not dashed', () {
    final boxes = overlayBoxesFor([
      _crop(
        id: 'manga',
        ocrBlocks: const [OcrBlockGeometry(text: '猫を食べた。')],
      ),
    ]);
    expect(boxes, hasLength(1));
    final box = boxes.single;
    expect(box.cropId, 'manga');
    expect(box.left, 0.1);
    expect(box.top, 0.2);
    expect(box.width, 0.5);
    expect(box.height, 0.4);
    expect(box.text, '猫を食べた。');
    expect(box.confidence, isNull);
    expect(box.isLowConfidence, isFalse);
    expect(box.number, 1);
  });

  test('empty ocrBlocks also falls back to the crop rectangle', () {
    final boxes = overlayBoxesFor([_crop(id: 'empty')]);
    expect(boxes.single.left, 0.1);
    expect(boxes.single.width, 0.5);
    expect(boxes.single.isLowConfidence, isFalse);
  });

  test('engine Rect is mapped from crop space onto the page', () {
    final boxes = overlayBoxesFor([
      _crop(
        id: 'vision',
        left: 0.2,
        top: 0.1,
        width: 0.4,
        height: 0.5,
        ocrBlocks: const [
          OcrBlockGeometry(
            text: '高い',
            confidence: 0.92,
            left: 0.25,
            top: 0.20,
            width: 0.50,
            height: 0.40,
          ),
        ],
      ),
    ]);
    expect(boxes, hasLength(1));
    final box = boxes.single;
    expect(box.left, closeTo(0.2 + 0.25 * 0.4, 1e-9));
    expect(box.top, closeTo(0.1 + 0.20 * 0.5, 1e-9));
    expect(box.width, closeTo(0.50 * 0.4, 1e-9));
    expect(box.height, closeTo(0.40 * 0.5, 1e-9));
    expect(box.text, '高い');
    expect(box.confidence, 0.92);
    expect(box.isLowConfidence, isFalse);
  });

  test('confidence below 0.5 is low-confidence (dashed)', () {
    final boxes = overlayBoxesFor([
      _crop(
        id: 'low',
        ocrBlocks: const [
          OcrBlockGeometry(
            text: '見せる',
            confidence: 0.49,
            left: 0,
            top: 0,
            width: 1,
            height: 1,
          ),
        ],
      ),
    ]);
    expect(boxes.single.isLowConfidence, isTrue);
    expect(boxes.single.confidence, 0.49);
  });

  test('confidence 0.5 is not dashed', () {
    final boxes = overlayBoxesFor([
      _crop(
        id: 'edge',
        ocrBlocks: const [
          OcrBlockGeometry(
            text: '見せる',
            confidence: 0.5,
            left: 0,
            top: 0,
            width: 1,
            height: 1,
          ),
        ],
      ),
    ]);
    expect(boxes.single.isLowConfidence, isFalse);
  });

  test('blocks without Rect are skipped when another block has one', () {
    final boxes = overlayBoxesFor([
      _crop(
        id: 'mixed',
        ocrBlocks: const [
          OcrBlockGeometry(text: 'skip'),
          OcrBlockGeometry(
            text: 'keep',
            left: 0.1,
            top: 0.1,
            width: 0.2,
            height: 0.2,
          ),
        ],
      ),
    ]);
    expect(boxes, hasLength(1));
    expect(boxes.single.text, 'keep');
  });
}
