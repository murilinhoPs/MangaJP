import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/utils/graphemes.dart';
import 'package:manga_jp/core/utils/kanji.dart';

const ivs = '\u{E0100}';
const vs16 = '\u{FE0F}';

void main() {
  test('stripVariationSelectors leaves 叱 and 𠮟 distinct', () {
    const shikaBmp = '叱';
    const shikaExtb = '𠮟';
    expect(shikaBmp.runes.single, 0x53F1);
    expect(shikaExtb.runes.single, 0x20B9F);
    expect(stripVariationSelectors(shikaBmp), shikaBmp);
    expect(stripVariationSelectors(shikaExtb), shikaExtb);
    expect(stripVariationSelectors(shikaBmp), isNot(shikaExtb));
    expect(normalizeKanjiLiteral(shikaBmp), shikaBmp);
    expect(normalizeKanjiLiteral(shikaExtb), shikaExtb);
    expect(
      normalizeKanjiLiteral(shikaBmp),
      isNot(normalizeKanjiLiteral(shikaExtb)),
    );
    expect(normalizeKanjiLiteral('$shikaBmp$ivs'), shikaBmp);
    expect(normalizeKanjiLiteral('$shikaExtb$ivs'), shikaExtb);
    expect(
      normalizeKanjiLiteral('$shikaBmp$ivs'),
      isNot(normalizeKanjiLiteral('$shikaExtb$ivs')),
    );
  });

  test('normalizeKanjiLiteral strips IVS/VS and requires one code point', () {
    expect(normalizeKanjiLiteral('食$ivs'), '食');
    expect(normalizeKanjiLiteral('食$vs16'), '食');
    expect(normalizeKanjiLiteral('𠮷$ivs'), '𠮷');
    expect(normalizeKanjiLiteral('食べる'), isNull);
    expect(normalizeKanjiLiteral(''), isNull);
    expect(normalizeKanjiLiteral(ivs), isNull);
    expect(normalizeKanjiLiteral('食$ivsべ'), isNull);
  });

  test('isSingleCjkIdeograph covers BMP and extension B', () {
    expect(isSingleCjkIdeograph('食'), isTrue);
    expect(isSingleCjkIdeograph('叱'), isTrue);
    expect(isSingleCjkIdeograph('𠮟'), isTrue);
    expect(isSingleCjkIdeograph('べ'), isFalse);
    expect(isSingleCjkIdeograph('A'), isFalse);
    expect(isSingleCjkIdeograph('食べる'), isFalse);
  });
}
