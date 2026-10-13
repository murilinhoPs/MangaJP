import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/dictionary/data/dictionary_lookup.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/pages/presentation/ocr_token_spans.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';
import 'package:manga_jp/features/words/domain/word_state_index.dart';

import '../dictionary/bake_jmdict_fixture.dart';

void main() {
  late Directory tmp;
  late DictionaryLookup lookup;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('ocr_spans_');
    final path = await bakeJmdictFixture(tmp);
    lookup = DictionaryLookup(JmdictService()..openFile(path));
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  test('conjugated 食べた picks up 食べる learning state', () {
    const text = '高い猫を食べた。ぴよ';
    const states = WordStateIndex(
      bySeq: {
        1411580: WordState.saved,
        1583470: WordState.known,
        1358280: WordState.learning,
      },
      byLemma: {'ぴよ': WordState.ignored},
    );
    final spans = tokenizeOcr(text, lookup, states);
    String slice(OcrTokenSpan span) => text.substring(span.start, span.end);

    expect(slice(spans.firstWhere((span) => slice(span) == '高い')), '高い');
    expect(
      spans.firstWhere((span) => slice(span) == '高い').state,
      WordState.saved,
    );
    expect(
      spans.firstWhere((span) => slice(span) == '猫').state,
      WordState.known,
    );
    expect(
      spans.firstWhere((span) => slice(span) == '食べた').state,
      WordState.learning,
    );
    expect(
      spans.firstWhere((span) => slice(span) == 'ぴよ').state,
      WordState.ignored,
    );
    expect(
      spans.firstWhere((span) => slice(span) == '。').state,
      WordState.unknown,
    );
  });

  test('two IVS kanji stay separate spans on original offsets', () {
    const ivs = '\u{E0100}';
    const first = '辻$ivs';
    const second = '葛$ivs';
    const text = '$first$second';
    final spans = tokenizeOcr(text, lookup, WordStateIndex.empty);
    expect(spans, hasLength(2));
    expect(spans[0].start, 0);
    expect(spans[0].end, first.length);
    expect(spans[1].start, first.length);
    expect(spans[1].end, text.length);
    expect(text.substring(spans[1].start, spans[1].end), second);
  });

  test('surrogate-pair kanji is one unknown span', () {
    const kanji = '𩸽';
    const text = '猫$kanji。';
    final spans = tokenizeOcr(text, lookup, WordStateIndex.empty);
    String slice(OcrTokenSpan span) => text.substring(span.start, span.end);
    expect(kanji.length, 2);
    expect(slice(spans.firstWhere((span) => slice(span) == kanji)), kanji);
    expect(
      spans.where(
        (span) =>
            span.end - span.start == 1 &&
            slice(span) != '猫' &&
            slice(span) != '。',
      ),
      isEmpty,
      reason: 'must not emit a half-surrogate span',
    );
  });
}
