import '../../dictionary/domain/kanji_entry.dart';
import 'notebook_entry.dart';

/// One Caderno kanji row plus optional KANJIDIC2 fields and notebook words.
class NotebookKanjiView {
  const NotebookKanjiView({
    required this.literal,
    required this.savedAt,
    this.originPageId,
    this.lookup,
    this.notebookWords = const [],
  });

  final String literal;
  final DateTime savedAt;
  final String? originPageId;

  /// KANJIDIC2 row, or null when the `kanji` table has no line.
  final KanjiEntry? lookup;

  /// Caderno words whose `lemma_key` contains [literal].
  final List<NotebookEntry> notebookWords;

  /// Search hits the literal always; readings/meanings only with [lookup].
  bool matchesSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    if (literal.contains(trimmed)) {
      return true;
    }
    return lookup?.matchesSearch(trimmed) ?? false;
  }
}
