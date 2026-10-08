import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/crop_rect.dart';

enum _Hit { none, body, nw, ne, sw, se }

/// CustomPainter rect overlay (M0: one balloon). Drag body to move, corners to resize.
class CropOverlay extends StatefulWidget {
  const CropOverlay({
    super.key,
    required this.imageSize,
    required this.rect,
    required this.onChanged,
  });

  final Size imageSize;
  final CropRect rect;
  final ValueChanged<CropRect> onChanged;

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  static const _handleHit = 28.0;

  _Hit _hit = _Hit.none;
  CropRect? _startRect;
  Offset? _startNorm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.biggest;
        if (layout.isEmpty || widget.imageSize.isEmpty) {
          return const SizedBox.expand();
        }
        final dest = _containedDest(layout, widget.imageSize);
        final display = _displayRect(dest, widget.rect);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _hit = _hitTest(details.localPosition, display);
            _startRect = widget.rect;
            _startNorm = _toNormalized(details.localPosition, dest);
          },
          onPanUpdate: (details) {
            final startRect = _startRect;
            final startNorm = _startNorm;
            final norm = _toNormalized(details.localPosition, dest);
            if (startRect == null || startNorm == null || _hit == _Hit.none) {
              return;
            }
            widget.onChanged(_apply(_hit, startRect, startNorm, norm));
          },
          onPanEnd: (_) {
            _hit = _Hit.none;
            _startRect = null;
            _startNorm = null;
          },
          child: CustomPaint(
            size: layout,
            painter: _CropPainter(
              dest: dest,
              rect: display,
              dimColor: AppColors.bg.withValues(alpha: 0.6),
              handleColor: AppColors.text,
            ),
          ),
        );
      },
    );
  }

  static Rect _containedDest(Size layout, Size imageSize) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, layout);
    return Alignment.center.inscribe(fitted.destination, Offset.zero & layout);
  }

  static Rect _displayRect(Rect dest, CropRect rect) {
    return Rect.fromLTWH(
      dest.left + rect.left * dest.width,
      dest.top + rect.top * dest.height,
      rect.width * dest.width,
      rect.height * dest.height,
    );
  }

  static Offset _toNormalized(Offset local, Rect dest) {
    if (dest.width <= 0 || dest.height <= 0) return Offset.zero;
    return Offset(
      ((local.dx - dest.left) / dest.width).clamp(0.0, 1.0),
      ((local.dy - dest.top) / dest.height).clamp(0.0, 1.0),
    );
  }

  _Hit _hitTest(Offset local, Rect display) {
    bool near(Offset corner) => (local - corner).distance <= _handleHit;
    if (near(display.topLeft)) return _Hit.nw;
    if (near(display.topRight)) return _Hit.ne;
    if (near(display.bottomLeft)) return _Hit.sw;
    if (near(display.bottomRight)) return _Hit.se;
    if (display.inflate(8).contains(local)) return _Hit.body;
    return _Hit.none;
  }

  CropRect _apply(_Hit hit, CropRect start, Offset startNorm, Offset norm) {
    switch (hit) {
      case _Hit.none:
        return start;
      case _Hit.body:
        return start.shift(norm.dx - startNorm.dx, norm.dy - startNorm.dy);
      case _Hit.nw:
        return CropRect(
          left: norm.dx,
          top: norm.dy,
          width: start.right - norm.dx,
          height: start.bottom - norm.dy,
        ).clamped();
      case _Hit.ne:
        return CropRect(
          left: start.left,
          top: norm.dy,
          width: norm.dx - start.left,
          height: start.bottom - norm.dy,
        ).clamped();
      case _Hit.sw:
        return CropRect(
          left: norm.dx,
          top: start.top,
          width: start.right - norm.dx,
          height: norm.dy - start.top,
        ).clamped();
      case _Hit.se:
        return CropRect(
          left: start.left,
          top: start.top,
          width: norm.dx - start.left,
          height: norm.dy - start.top,
        ).clamped();
    }
  }
}

class _CropPainter extends CustomPainter {
  const _CropPainter({
    required this.dest,
    required this.rect,
    required this.dimColor,
    required this.handleColor,
  });

  final Rect dest;
  final Rect rect;
  final Color dimColor;
  final Color handleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path()
      ..addRect(dest)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = dimColor);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = handleColor;
    canvas.drawRect(rect, border);

    const handle = 10.0;
    final fill = Paint()..color = handleColor;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: corner, width: handle, height: handle),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.dest != dest ||
        oldDelegate.rect != rect ||
        oldDelegate.dimColor != dimColor ||
        oldDelegate.handleColor != handleColor;
  }
}
