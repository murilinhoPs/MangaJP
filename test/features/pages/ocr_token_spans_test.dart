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
    expect(spans.firstWhere((span) => slice(span) == '猫').state, WordState.known);
    expect(
      spans.firstWhere((span) => slice(span) == '食べた').state,
      WordState.learning,
    );
    expect(spans.firstWhere((span) => slice(span) == 'ぴよ').state, WordState.ignored);
    expect(spans.firstWhere((span) => slice(span) == '。').state, WordState.unknown);
  });
}
