import 'package:characters/characters.dart';
import 'package:flutter/rendering.dart';

/// UTF-16 index of the glyph under [local] in a laid-out [paragraph].
///
/// Only a tap that lands inside a real [getBoxesForSelection] glyph box
/// counts. Empty space after a line, gaps between lines, and padding return
/// null so nothing is selected.
///
/// Offsets are grapheme starts ([Characters]): a supplementary-plane kanji
/// (surrogate pair) is one character, never half.
int? charIndexAt(RenderParagraph paragraph, Offset local) {
  final text = paragraph.text.toPlainText();
  if (text.isEmpty) {
    return null;
  }

  var start = 0;
  for (final grapheme in text.characters) {
    final end = start + grapheme.length;
    if (_boxContains(paragraph, local, start, end)) {
      return start;
    }
    start = end;
  }
  return null;
}

bool _boxContains(RenderParagraph paragraph, Offset local, int start, int end) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  return boxes.any((box) => box.toRect().contains(local));
}
