/// Axis-aligned crop in **normalized** image space (0..1).
class CropRect {
  const CropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Default balloon-sized inset used so confirm is 1 tap (PRD O4).
  static const initial = CropRect(left: 0.2, top: 0.2, width: 0.6, height: 0.6);

  static const minSize = 0.05;

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  CropRect shift(double dx, double dy) {
    return CropRect(
      left: left + dx,
      top: top + dy,
      width: width,
      height: height,
    ).clamped();
  }

  CropRect clamped() {
    var w = width.clamp(minSize, 1.0);
    var h = height.clamp(minSize, 1.0);
    var l = left.clamp(0.0, 1.0 - w);
    var t = top.clamp(0.0, 1.0 - h);
    w = w.clamp(minSize, 1.0 - l);
    h = h.clamp(minSize, 1.0 - t);
    return CropRect(left: l, top: t, width: w, height: h);
  }
}
