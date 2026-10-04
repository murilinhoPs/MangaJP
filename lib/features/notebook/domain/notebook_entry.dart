import '../../words/domain/word_state.dart';

/// One Caderno row: a word that already has a listed [WordState].
///
/// [firstSavedAt] is `words.created_at` (first insert / first save).
class NotebookEntry {
  const NotebookEntry({
    required this.wordId,
    required this.lemma,
    required this.reading,
    required this.state,
    required this.firstSavedAt,
  });

  final String wordId;
  final String lemma;
  final String reading;
  final WordState state;
  final DateTime firstSavedAt;
}
