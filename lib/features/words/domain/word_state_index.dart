import 'word_state.dart';

/// Listed Caderno states keyed for Página coloring and lookup actions.
class WordStateIndex {
  const WordStateIndex({required this.bySeq, required this.byLemma});

  static const empty = WordStateIndex(bySeq: {}, byLemma: {});

  final Map<int, WordState> bySeq;
  final Map<String, WordState> byLemma;

  WordState ofSeq(int seq) => bySeq[seq] ?? WordState.unknown;

  WordState ofLemma(String lemma) => byLemma[lemma] ?? WordState.unknown;
}
