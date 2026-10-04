import '../../words/domain/word_state.dart';

/// Read-only Caderno word: Drift fields plus the first crop's sentence / page.
///
/// Gloss is not stored here. Load it from JMdict with [seq].
class NotebookWordDetail {
  const NotebookWordDetail({
    required this.wordId,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.state,
    this.sentence,
    this.pageId,
  });

  final String wordId;
  final int seq;
  final String lemma;
  final String reading;
  final WordState state;

  /// `crops.ocr_text` of the earliest `crop_words` row, if any.
  final String? sentence;

  /// Page of that first crop (`crops.page_id`).
  final String? pageId;
}
