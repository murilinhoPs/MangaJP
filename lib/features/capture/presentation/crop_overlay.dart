import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crop_number_badge.dart';
import '../domain/crop_order.dart';
import '../domain/crop_rect.dart';

enum _Hit { none, body, nw, ne, sw, se, create }

/// Multi-crop overlay. Active = coral ring + handles; others = dashed violet.
class CropOverlay extends StatefulWidget {
  const CropOverlay({
    super.key,
    required this.imageSize,
    required this.crops,
    required this.activeIndex,
    required this.onChanged,
  });

  /// Extra gap under the status bar / SafeArea so a top-edge crop's badge
  /// is not only ~6pt below the inset.
  static const badgeMinGap = 12.0;

  final Size imageSize;
  final List<CropRect> crops;
  final int activeIndex;
  final void Function(List<CropRect> crops, int activeIndex) onChanged;

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  static const _handleHit = 28.0;

  _Hit _hit = _Hit.none;
  CropRect? _startRect;
  Offset? _startNorm;
  CropRect? _creating;
  int _gestureIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.biggest;
        if (layout.isEmpty || widget.imageSize.isEmpty) {
          return const SizedBox.expand();
        }
        final dest = containedDest(layout, widget.imageSize);
        final display = [
          for (final crop in widget.crops) displayRect(dest, crop),
        ];
        final draft = _creating;
        final draftDisplay = draft == null ? null : displayRect(dest, draft);
        final numbers = rtlCropNumbers(widget.crops);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _onPanStart(details.localPosition, dest, display);
          },
          onPanUpdate: (details) {
            _onPanUpdate(details.localPosition, dest);
          },
          onPanEnd: (_) => _onPanEnd(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                key: const Key('capture-overlay'),
                size: layout,
                painter: CropOverlayPainter(
                  dest: dest,
                  rects: [...display, ?draftDisplay],
                  activeIndex: draftDisplay != null
                      ? display.length
                      : widget.activeIndex.clamp(0, display.length - 1),
                  activeColor: tokens.coral,
                  inactiveColor: tokens.violet,
                  radius: AppRadius.linha,
                  handleSize: 10,
                ),
              ),
              for (var i = 0; i < display.length; i++)
                _badge(display[i], numbers[i]),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(Rect rect, int number) {
    const half = CropNumberBadge.size / 2;
    final minTop = MediaQuery.paddingOf(context).top + CropOverlay.badgeMinGap;
    return Positioned(
      left: rect.left - half,
      top: math.max(rect.top - half, minTop),
      child: IgnorePointer(
        child: CropNumberBadge(
          key: Key('capture-crop-number-$number'),
          number: number,
        ),
      ),
    );
  }

  void _onPanStart(Offset local, Rect dest, List<Rect> display) {
    final active = widget.activeIndex.clamp(0, display.length - 1);
    if (display.isNotEmpty) {
      final activeHit = _hitTest(local, display[active]);
      if (activeHit != _Hit.none) {
        _hit = activeHit;
        _gestureIndex = active;
        _startRect = widget.crops[active];
        _startNorm = toNormalized(local, dest);
        return;
      }
      for (var i = 0; i < display.length; i++) {
        if (i == active) {
          continue;
        }
        if (display[i].inflate(8).contains(local)) {
          _hit = _Hit.body;
          _gestureIndex = i;
          _startRect = widget.crops[i];
          _startNorm = toNormalized(local, dest);
          widget.onChanged(widget.crops, i);
          return;
        }
      }
    }
    _hit = _Hit.create;
    _gestureIndex = widget.crops.length;
    _startNorm = toNormalized(local, dest);
    _creating = CropRect.fromPoints(
      _startNorm!.dx,
      _startNorm!.dy,
      _startNorm!.dx,
      _startNorm!.dy,
    );
    setState(() {});
  }

  void _onPanUpdate(Offset local, Rect dest) {
    final startNorm = _startNorm;
    if (startNorm == null || _hit == _Hit.none) {
      return;
    }
    final norm = toNormalized(local, dest);
    if (_hit == _Hit.create) {
      setState(() {
        _creating = CropRect.fromPoints(
          startNorm.dx,
          startNorm.dy,
          norm.dx,
          norm.dy,
        );
      });
      return;
    }
    final startRect = _startRect;
    if (startRect == null) {
      return;
    }
    final next = _apply(_hit, startRect, startNorm, norm);
    final crops = [...widget.crops];
    crops[_gestureIndex] = next;
    widget.onChanged(crops, _gestureIndex);
  }

  void _onPanEnd() {
    if (_hit == _Hit.create) {
      final draft = _creating;
      if (draft != null &&
          draft.width >= CropRect.minSize &&
          draft.height >= CropRect.minSize) {
        widget.onChanged([
          ...widget.crops,
          draft.clamped(),
        ], widget.crops.length);
      }
    }
    _hit = _Hit.none;
    _startRect = null;
    _startNorm = null;
    _creating = null;
    if (mounted) {
      setState(() {});
    }
  }

  _Hit _hitTest(Offset local, Rect display) {
    bool near(Offset corner) => (local - corner).distance <= _handleHit;
    if (near(display.topLeft)) {
      return _Hit.nw;
    }
    if (near(display.topRight)) {
      return _Hit.ne;
    }
    if (near(display.bottomLeft)) {
      return _Hit.sw;
    }
    if (near(display.bottomRight)) {
      return _Hit.se;
    }
    if (display.inflate(8).contains(local)) {
      return _Hit.body;
    }
    return _Hit.none;
  }

  CropRect _apply(_Hit hit, CropRect start, Offset startNorm, Offset norm) {
    switch (hit) {
      case _Hit.none:
      case _Hit.create:
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

Rect containedDest(Size layout, Size imageSize) {
  final fitted = applyBoxFit(BoxFit.contain, imageSize, layout);
  return Alignment.center.inscribe(fitted.destination, Offset.zero & layout);
}

Rect displayRect(Rect dest, CropRect rect) {
  return Rect.fromLTWH(
    dest.left + rect.left * dest.width,
    dest.top + rect.top * dest.height,
    rect.width * dest.width,
    rect.height * dest.height,
  );
}

Offset toNormalized(Offset local, Rect dest) {
  if (dest.width <= 0 || dest.height <= 0) {
    return Offset.zero;
  }
  return Offset(
    ((local.dx - dest.left) / dest.width).clamp(0.0, 1.0),
    ((local.dy - dest.top) / dest.height).clamp(0.0, 1.0),
  );
}

/// Public so widget tests can read ring colors and the dashed flag.
class CropOverlayPainter extends CustomPainter {
  const CropOverlayPainter({
    required this.dest,
    required this.rects,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.radius,
    required this.handleSize,
    this.inactiveDashed = true,
    this.dashOn = 5,
    this.dashOff = 4,
  });

  final Rect dest;
  final List<Rect> rects;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double radius;
  final double handleSize;
  final bool inactiveDashed;

  /// Dash length is not in `tokens.json` (Deck crop strokes).
  final double dashOn;
  final double dashOff;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < rects.length; i++) {
      final active = i == activeIndex;
      final color = active ? activeColor : inactiveColor;
      final rrect = RRect.fromRectAndRadius(rects[i], Radius.circular(radius));
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color;
      if (active || !inactiveDashed) {
        canvas.drawRRect(rrect, stroke);
      } else {
        _drawDashedRRect(canvas, rrect, stroke);
      }
      if (active) {
        final fill = Paint()..color = color;
        final rect = rects[i];
        for (final corner in [
          rect.topLeft,
          rect.topRight,
          rect.bottomLeft,
          rect.bottomRight,
        ]) {
          canvas.drawRect(
            Rect.fromCenter(
              center: corner,
              width: handleSize,
              height: handleSize,
            ),
            fill,
          );
        }
      }
    }
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      final length = metric.length;
      var draw = true;
      while (dist < length) {
        final span = draw ? dashOn : dashOff;
        final end = dist + span;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(dist, end.clamp(0, length)),
            paint,
          );
        }
        dist = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.dest != dest ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.inactiveDashed != inactiveDashed ||
        oldDelegate.radius != radius ||
        oldDelegate.handleSize != handleSize ||
        oldDelegate.dashOn != dashOn ||
        oldDelegate.dashOff != dashOff ||
        !_rectsEqual(oldDelegate.rects, rects);
  }

  static bool _rectsEqual(List<Rect> a, List<Rect> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
