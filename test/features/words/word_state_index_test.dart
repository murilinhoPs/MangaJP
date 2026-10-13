import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/utils/graphemes.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';
import 'package:manga_jp/features/words/domain/word_state_index.dart';

const ivs = '\u{E0100}';
const vs16 = '\u{FE0F}';

void main() {
  test('ofLemma treats IVS / VS forms as the stripped key', () {
    const kuzu = '葛';
    const yoshi = '𠮷';
    final index = WordStateIndex(
      bySeq: const {},
      byLemma: {
        stripVariationSelectors('$kuzu$ivs'): WordState.ignored,
        stripVariationSelectors('$yoshi$ivs$vs16'): WordState.known,
      },
    );

    expect(index.ofLemma(kuzu), WordState.ignored);
    expect(index.ofLemma('$kuzu$ivs'), WordState.ignored);
    expect(index.ofLemma('$kuzu$vs16'), WordState.ignored);
    expect(index.ofLemma(yoshi), WordState.known);
    expect(index.ofLemma('$yoshi$ivs'), WordState.known);
    expect(index.ofLemma('$yoshi$ivs$vs16'), WordState.known);
    expect(index.ofLemma('ぴよ'), WordState.unknown);
  });
}
