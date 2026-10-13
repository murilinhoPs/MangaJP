import 'package:characters/characters.dart';

/// IVS (U+E0100–U+E01EF) or VS1–VS16 (U+FE00–U+FE0F).
bool _isVariationSelector(int codePoint) {
  return (codePoint >= 0xFE00 && codePoint <= 0xFE0F) ||
      (codePoint >= 0xE0100 && codePoint <= 0xE01EF);
}

/// Drops variation selectors so a JMdict key matches the unadorned form.
///
/// Display text, highlight, and UTF-16 offsets stay on the original string.
String stripVariationSelectors(String text) {
  if (text.isEmpty) {
    return text;
  }
  final buffer = StringBuffer();
  var changed = false;
  for (final codePoint in text.runes) {
    if (_isVariationSelector(codePoint)) {
      changed = true;
      continue;
    }
    buffer.writeCharCode(codePoint);
  }
  return changed ? buffer.toString() : text;
}

/// Inclusive UTF-16 start of the grapheme that contains [offset].
int graphemeStart(String text, int offset) {
  if (text.isEmpty || offset <= 0) {
    return 0;
  }
  if (offset >= text.length) {
    return text.length;
  }
  var start = 0;
  for (final grapheme in text.characters) {
    final end = start + grapheme.length;
    if (offset < end) {
      return start;
    }
    start = end;
  }
  return start;
}

/// Exclusive UTF-16 end of the grapheme that starts at [start].
int graphemeEnd(String text, int start) {
  if (start < 0) {
    return 0;
  }
  if (start >= text.length) {
    return text.length;
  }
  return start + text.substring(start).characters.first.length;
}
