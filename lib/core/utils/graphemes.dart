import 'package:characters/characters.dart';

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
