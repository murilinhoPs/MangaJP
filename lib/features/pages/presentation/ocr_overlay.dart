import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crop_number_badge.dart';
import '../../capture/presentation/crop_overlay.dart';
import '../domain/ocr_overlay_box.dart';

/// Overlay of OCR boxes on the page image. Hit target is at least 44px.
class OcrPageOverlay extends StatelessWidget {
  const OcrPageOverlay({
    super.key,
    required this.boxes,
    required this.imageSize,
    this.selectedId,
    this.hoveredId,
    this.onSelect,
    this.onHover,
  });

  final List<OcrOverlayBox> boxes;
  final Size imageSize;
  final String? selectedId;
  final String? hoveredId;
  final ValueChanged<OcrOverlayBox>? onSelect;
  final ValueChanged<OcrOverlayBox?>? onHover;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.biggest;
        if (layout.isEmpty || imageSize.isEmpty) {
          return const SizedBox.expand();
        }
        final dest = containedDest(layout, imageSize);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final box in boxes)
              _OcrBoxHit(
                box: box,
                visual: _pageRect(dest, box),
                selected: box.id == selectedId,
                hovered: box.id == hoveredId,
                onSelect: onSelect,
                onHover: onHover,
              ),
          ],
        );
      },
    );
  }

  static Rect _pageRect(Rect dest, OcrOverlayBox box) {
    return Rect.fromLTWH(
      dest.left + box.left * dest.width,
      dest.top + box.top * dest.height,
      box.width * dest.width,
      box.height * dest.height,
    );
  }
}

class _OcrBoxHit extends StatelessWidget {
  const _OcrBoxHit({
    required this.box,
    required this.visual,
    required this.selected,
    required this.hovered,
    this.onSelect,
    this.onHover,
  });

  final OcrOverlayBox box;
  final Rect visual;
  final bool selected;
  final bool hovered;
  final ValueChanged<OcrOverlayBox>? onSelect;
  final ValueChanged<OcrOverlayBox?>? onHover;

  @override
  Widget build(BuildContext context) {
    final hitW = math.max(visual.width, AppTargets.min);
    final hitH = math.max(visual.height, AppTargets.min);
    final left = visual.center.dx - hitW / 2;
    final top = visual.center.dy - hitH / 2;
    final dx = visual.left - left;
    final dy = visual.top - top;
    return Positioned(
      left: left,
      top: top,
      width: hitW,
      height: hitH,
      child: MouseRegion(
        onEnter: (_) => onHover?.call(box),
        onExit: (_) => onHover?.call(null),
        child: Semantics(
          container: true,
          button: true,
          selected: selected,
          label: box.text,
          child: GestureDetector(
            key: PageOverlayKeys.box(box.id),
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect?.call(box),
            child: ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: dx,
                    top: dy,
                    width: visual.width,
                    height: visual.height,
                    child: _OcrBoxVisual(
                      box: box,
                      selected: selected,
                      hovered: hovered,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OcrBoxVisual extends StatelessWidget {
  const _OcrBoxVisual({
    required this.box,
    required this.selected,
    required this.hovered,
  });

  final OcrOverlayBox box;
  final bool selected;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = selected
        ? tokens.overlaySelecaoToque
        : hovered
        ? tokens.overlayPrimaria
        : tokens.overlayOcrBoxFill;
    final border = hovered || selected
        ? tokens.coral
        : tokens.overlayOcrBoxBorder;
    final width = selected ? 2.0 : 1.5;
    return DecoratedBox(
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.ocrBox),
              boxShadow: [
                BoxShadow(
                  color: tokens.overlayOcrBoxHalo,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            )
          : const BoxDecoration(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              key: PageOverlayKeys.boxPaint(box.id),
              painter: OcrBoxPainter(
                fill: fill,
                border: border,
                borderWidth: width,
                dashed: box.isLowConfidence,
                radius: AppRadius.ocrBox,
                selected: selected,
                hovered: hovered,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: CropNumberBadge(
              number: box.number,
              size: CropNumberBadge.overlaySize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Public so widget tests can read fill / dashed / selected.
class OcrBoxPainter extends CustomPainter {
  const OcrBoxPainter({
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.dashed,
    required this.radius,
    required this.selected,
    required this.hovered,
  });

  final Color fill;
  final Color border;
  final double borderWidth;
  final bool dashed;
  final double radius;
  final bool selected;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = fill);
    final paint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    if (dashed) {
      _drawDashedRRect(canvas, rrect, paint);
    } else {
      canvas.drawRRect(rrect, paint);
    }
  }

  static void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      const dash = 4.0;
      const gap = 3.0;
      while (distance < metric.length) {
        final next = distance + (draw ? dash : gap);
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, math.min(next, metric.length)),
            paint,
          );
        }
        distance = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant OcrBoxPainter old) {
    return old.fill != fill ||
        old.border != border ||
        old.borderWidth != borderWidth ||
        old.dashed != dashed ||
        old.radius != radius ||
        old.selected != selected ||
        old.hovered != hovered;
  }
}

/// Keys for `/pages/:id` overlay (image + boxes + toggle).
abstract final class PageOverlayKeys {
  static const image = Key('page-detail-image');
  static const overlay = Key('page-detail-overlay');
  static const toggle = Key('page-detail-overlay-toggle');

  static Key box(String id) => Key('page-detail-ocr-box-$id');
  static Key boxPaint(String id) => Key('page-detail-ocr-box-paint-$id');
}
