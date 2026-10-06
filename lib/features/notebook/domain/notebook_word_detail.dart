import '../../words/domain/word_state.dart';

/// Caderno word: Drift fields plus the first crop's sentence / page.
///
/// Gloss is not stored here. Load it from JMdict with [seq] (empty for
/// custom entries). [userNote] is the custom-entry note, if any.
class NotebookWordDetail {
  const NotebookWordDetail({
    required this.wordId,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.state,
    this.userNote,
    this.sentence,
    this.pageId,
  });

  final String wordId;
  final int seq;
  final String lemma;
  final String reading;
  final WordState state;

  /// Custom-entry note. Null for JMdict-backed words.
  final String? userNote;

  /// `crops.ocr_text` of the earliest `crop_words` row, if any.
  final String? sentence;

  /// Page of that first crop (`crops.page_id`).
  final String? pageId;
}
