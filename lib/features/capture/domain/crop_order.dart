import 'crop_rect.dart';

/// Vertical overlap, as a fraction of the shorter crop, that counts as one row.
const kRtlSameRowOverlap = 0.35;

/// Manga reading order: right-to-left, then top-to-bottom.
///
/// Rows are clustered by overlap (stairs / chain overlap count as one row),
/// then each row is sorted by [CropRect.centerX] descending.
/// Returns crop indices in that order (index 0 = first to read = number 1).
List<int> rtlCropOrder(List<CropRect> rects) {
  if (rects.length <= 1) {
    return List<int>.generate(rects.length, (i) => i);
  }
  final remaining = List<int>.generate(rects.length, (i) => i)
    ..sort((ia, ib) {
      final byTop = rects[ia].top.compareTo(rects[ib].top);
      if (byTop != 0) {
        return byTop;
      }
      return rects[ib].centerX.compareTo(rects[ia].centerX);
    });

  final order = <int>[];
  while (remaining.isNotEmpty) {
    final row = <int>[remaining.removeAt(0)];
    var grew = true;
    while (grew) {
      grew = false;
      for (var i = 0; i < remaining.length; i++) {
        final index = remaining[i];
        if (row.any((r) => _sameRow(rects[r], rects[index]))) {
          row.add(remaining.removeAt(i));
          grew = true;
          break;
        }
      }
    }
    row.sort((ia, ib) => rects[ib].centerX.compareTo(rects[ia].centerX));
    order.addAll(row);
  }
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
