import 'package:flutter/rendering.dart';

/// UTF-16 index of the glyph under [local] in a laid-out [paragraph].
///
/// [RenderParagraph.getPositionForOffset] snaps to the nearest caret, so a tap
/// on the right half of a character returns the offset *after* it. Selection
/// boxes of the previous and current code units are tested (x and y) so a
/// wrapped previous glyph on another line is not chosen.
///
/// Taps that miss every glyph box (gap between lines, padding) keep the
/// nearest-caret index, matching the previous hit-test.
int? charIndexAt(RenderParagraph paragraph, Offset local) {
  final text = paragraph.text.toPlainText();
  if (text.isEmpty) {
    return null;
  }

  var offset = paragraph.getPositionForOffset(local).offset;
  if (offset < 0) {
    offset = 0;
  } else if (offset > text.length) {
    offset = text.length;
  }

  if (offset > 0 && _boxContains(paragraph, local, offset - 1, offset)) {
    return offset - 1;
  }
  if (offset < text.length &&
      _boxContains(paragraph, local, offset, offset + 1)) {
    return offset;
  }
  if (offset >= text.length) {
    return text.length - 1;
  }
  return offset;
}

bool _boxContains(RenderParagraph paragraph, Offset local, int start, int end) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  return boxes.any((box) => box.toRect().contains(local));
}
