import 'crop_rect.dart';

/// Vertical overlap, as a fraction of the shorter crop, that counts as one row.
const kRtlSameRowOverlap = 0.35;

/// Manga reading order: right-to-left, then top-to-bottom.
///
/// Returns crop indices in that order (index 0 = first to read = number 1).
List<int> rtlCropOrder(List<CropRect> rects) {
  final order = List<int>.generate(rects.length, (i) => i);
  order.sort((ia, ib) {
    final a = rects[ia];
    final b = rects[ib];
    if (_sameRow(a, b)) {
      return b.centerX.compareTo(a.centerX);
    }
    return a.centerY.compareTo(b.centerY);
  });
  return order;
}

/// 1-based reading-order number for each crop index.
List<int> rtlCropNumbers(List<CropRect> rects) {
  final order = rtlCropOrder(rects);
  final numbers = List<int>.filled(rects.length, 0);
  for (var n = 0; n < order.length; n++) {
    numbers[order[n]] = n + 1;
  }
  return numbers;
}

bool _sameRow(CropRect a, CropRect b) {
  final overlap = _min(a.bottom, b.bottom) - _max(a.top, b.top);
  if (overlap <= 0) {
    return false;
  }
  return overlap >= _min(a.height, b.height) * kRtlSameRowOverlap;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;
