import 'dart:math' as math;

import '../../../core/utils/graphemes.dart';
import '../../dictionary/data/dictionary_lookup.dart';
import '../../words/domain/word_state.dart';
import '../../words/domain/word_state_index.dart';

/// One OCR run colored by Caderno state (novo when unknown).
class OcrTokenSpan {
  const OcrTokenSpan({
    required this.start,
    required this.end,
    this.seq,
    this.state = WordState.unknown,
  });

  final int start;
  final int end;
  final int? seq;
  final WordState state;
}

/// Walk [text] with longest-cover lookup so conjugated forms pick up lemma state.
///
/// A JMdict miss must not swallow a later dict hit: `を食べた` is `を` + `食べた`,
/// not one kana/kanji run. Custom lemmas (no JMdict row) still use the miss
/// surface when that lemma is in the Caderno.
List<OcrTokenSpan> tokenizeOcr(
  String text,
  DictionaryLookup lookup,
  WordStateIndex states,
) {
  if (text.isEmpty) {
    return const [];
  }
  final spans = <OcrTokenSpan>[];
  var i = 0;
  while (i < text.length) {
    final hit = lookup.findAt(text, tapIndex: i);
    if (hit != null && hit.end > i && hit.start <= i) {
      spans.add(
        OcrTokenSpan(
          start: math.max(hit.start, i),
          end: hit.end,
          seq: hit.selected.seq,
          state: states.ofSeq(hit.selected.seq),
        ),
      );
      i = hit.end;
      continue;
    }
    if (hit != null && hit.start > i) {
      _emitUntil(spans, text, lookup, states, i, hit.start);
      i = hit.start;
      continue;
    }
    final miss = lookup.missAt(text, tapIndex: i);
    if (miss != null &&
        miss.start == i &&
        states.ofLemma(miss.surface) != WordState.unknown) {
      spans.add(
        OcrTokenSpan(
          start: miss.start,
          end: miss.end,
          state: states.ofLemma(miss.surface),
        ),
      );
      i = miss.end;
      continue;
    }
    final end = graphemeEnd(text, i);
    spans.add(OcrTokenSpan(start: i, end: end));
    i = end;
  }
  return spans;
}

void _emitUntil(
  List<OcrTokenSpan> spans,
  String text,
  DictionaryLookup lookup,
  WordStateIndex states,
  int from,
  int to,
) {
  var i = from;
  while (i < to) {
    final miss = lookup.missAt(text, tapIndex: i);
    if (miss != null &&
        miss.start == i &&
        miss.end <= to &&
        states.ofLemma(miss.surface) != WordState.unknown) {
      spans.add(
        OcrTokenSpan(
          start: miss.start,
          end: miss.end,
          state: states.ofLemma(miss.surface),
        ),
      );
      i = miss.end;
      continue;
    }
    final end = graphemeEnd(text, i);
    spans.add(OcrTokenSpan(start: i, end: end));
    i = end;
  }
}
