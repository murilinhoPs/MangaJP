import 'graphemes.dart';

/// CJK Unified Ideographs, compatibility ideographs, and extensions A–H.
bool isCjkIdeograph(int codePoint) {
  return (codePoint >= 0x3400 && codePoint <= 0x4DBF) ||
      (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
      (codePoint >= 0xF900 && codePoint <= 0xFAFF) ||
      (codePoint >= 0x20000 && codePoint <= 0x2A6DF) ||
      (codePoint >= 0x2A700 && codePoint <= 0x2B73F) ||
      (codePoint >= 0x2B740 && codePoint <= 0x2B81F) ||
      (codePoint >= 0x2B820 && codePoint <= 0x2CEAF) ||
      (codePoint >= 0x2CEB0 && codePoint <= 0x2EBEF) ||
      (codePoint >= 0x30000 && codePoint <= 0x3134F) ||
      (codePoint >= 0x31350 && codePoint <= 0x323AF);
}

/// [text] is exactly one CJK ideograph (UTF-32 code point).
bool isSingleCjkIdeograph(String text) {
  final runes = text.runes.toList();
  return runes.length == 1 && isCjkIdeograph(runes.single);
}

/// Identity for `saved_kanji.literal` and `/notebook/kanji/:char`.
///
/// Drops IVS (U+E0100–U+E01EF) and VS1–VS16 (U+FE00–U+FE0F) via
/// [stripVariationSelectors], then requires exactly one remaining code point.
/// `叱` (U+53F1) and `𠮟` (U+20B9F) stay distinct — they are not selectors.
String? normalizeKanjiLiteral(String raw) {
  final stripped = stripVariationSelectors(raw);
  if (stripped.runes.length != 1) {
    return null;
  }
  return stripped;
}
