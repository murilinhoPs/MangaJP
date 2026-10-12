import 'dict_entry.dart';

/// Homograph list for one matched surface, defaulted to highest [DictEntry.priority].
class LookupResult {
  LookupResult({
    required this.surface,
    required this.entries,
    this.start = 0,
    int? selectedSeq,
  }) : assert(entries.isNotEmpty, 'LookupResult requires at least one entry'),
       selectedSeq = selectedSeq ?? entries.first.seq;

  /// OCR / deinflected surface that hit `forms`.
  final String surface;

  /// UTF-16 start of [surface] in the OCR string.
  final int start;

  int get end => start + surface.length;

  /// Distinct seqs, highest priority first (NULL priority last).
  final List<DictEntry> entries;

  final int selectedSeq;

  DictEntry get selected =>
      entries.firstWhere((entry) => entry.seq == selectedSeq);
}
