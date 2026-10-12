import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/capture/domain/crop_order.dart';
import 'package:manga_jp/features/capture/domain/crop_rect.dart';

void main() {
  test('RTL numbering is right-to-left, then top-to-bottom', () {
    const topLeft = CropRect(left: 0.08, top: 0.10, width: 0.36, height: 0.32);
    const topRight = CropRect(left: 0.54, top: 0.06, width: 0.38, height: 0.30);
    const bottomRight = CropRect(
      left: 0.52,
      top: 0.54,
      width: 0.40,
      height: 0.32,
    );
    const crops = [topLeft, topRight, bottomRight];

    expect(rtlCropOrder(crops), [1, 0, 2]);
    expect(rtlCropNumbers(crops), [2, 1, 3]);
  });

  test('a single crop is number 1', () {
    expect(rtlCropNumbers(const [CropRect.initial]), [1]);
  });

  test('empty list stays empty', () {
    expect(rtlCropOrder(const []), isEmpty);
    expect(rtlCropNumbers(const []), isEmpty);
  });
}
