import 'package:flutter/rendering.dart';

import '../../../core/utils/graphemes.dart';

/// UTF-16 index of the glyph under [local] in a laid-out [paragraph].
///
/// Only a tap that lands inside a real [getBoxesForSelection] glyph box
/// counts. Empty space after a line, gaps between lines, and padding return
/// null so nothing is selected.
///
/// Offsets are grapheme starts ([Characters]): a supplementary-plane kanji
/// (surrogate pair) or a kanji plus variation selector is one character,
/// never half and never a leftover selector.
int? charIndexAt(RenderParagraph paragraph, Offset local) {
  final text = paragraph.text.toPlainText();
  if (text.isEmpty) {
    return null;
  }

  final offset = paragraph.getPositionForOffset(local).offset;
  final probed = offset < 0
      ? 0
      : (offset >= text.length ? text.length - 1 : offset);
  final current = graphemeStart(text, probed);
  if (_boxContains(paragraph, local, current, graphemeEnd(text, current))) {
    return current;
  }
  if (current > 0) {
    final previous = graphemeStart(text, current - 1);
    if (_boxContains(paragraph, local, previous, graphemeEnd(text, previous))) {
      return previous;
    }
  }
  return null;
}

bool _boxContains(RenderParagraph paragraph, Offset local, int start, int end) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  return boxes.any((box) => box.toRect().contains(local));
}
