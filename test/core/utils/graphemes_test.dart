import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/utils/graphemes.dart';

const ivs = '\u{E0100}';
const vs1 = '\u{FE00}';
const vs16 = '\u{FE0F}';

void main() {
  test('IVS and VS join the previous kanji as one grapheme', () {
    expect(('葛$ivs').length, 3);
    expect(('葛$ivs').characters.length, 1);
    expect(('𠮷$ivs').length, 4);
    expect(('𠮷$ivs').characters.length, 1);
    expect(('葛$vs16').length, 2);
    expect(('葛$vs16').characters.length, 1);
    expect(graphemeStart('葛$ivs', 2), 0);
    expect(graphemeEnd('葛$ivs', 0), 3);
    expect(graphemeStart('𠮷$ivs', 3), 0);
    expect(graphemeEnd('𠮷$ivs', 0), 4);
  });

  test('stripVariationSelectors drops IVS and VS1–VS16 only', () {
    expect(stripVariationSelectors('辻$ivs'), '辻');
    expect(stripVariationSelectors('葛$ivs'), '葛');
    expect(stripVariationSelectors('𠮷$ivs'), '𠮷');
    expect(stripVariationSelectors('辻$vs1'), '辻');
    expect(stripVariationSelectors('葛$vs16'), '葛');
    expect(stripVariationSelectors('辻$ivs葛$ivs'), '辻葛');
    expect(stripVariationSelectors('高い'), '高い');
    expect(stripVariationSelectors(''), '');
    expect(stripVariationSelectors(ivs), '');
  });

  test('stripVariationSelectors drops stacked selectors and surrogate IVS', () {
    expect(('𠮷$ivs').length, 4, reason: 'surrogate pair + IVS is 4 UTF-16');
    expect(stripVariationSelectors('葛$ivs$vs16'), '葛');
    expect(stripVariationSelectors('葛$ivs$vs1'), '葛');
    expect(stripVariationSelectors('𠮷$ivs$vs16'), '𠮷');
    expect(stripVariationSelectors('𠮷$ivs葛$vs16'), '𠮷葛');
    expect(stripVariationSelectors('辻$ivs葛$vs1𠮷$vs16'), '辻葛𠮷');
  });
}
