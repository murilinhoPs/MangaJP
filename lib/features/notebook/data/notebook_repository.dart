import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../words/domain/word_state.dart';
import '../domain/notebook_entry.dart';
import '../domain/notebook_word_detail.dart';

part 'notebook_repository.g.dart';

@Riverpod(keepAlive: true)
NotebookRepository notebookRepository(Ref ref) {
  return NotebookRepository(ref.watch(appDatabaseProvider));
}

/// Caderno queries (list / search / filter / word detail). Read-only.
class NotebookRepository {
  const NotebookRepository(this._db);

  final AppDatabase _db;

  /// Lemma / reading / state plus the first crop's sentence and page.
  ///
  /// Does not load a gloss. Callers look up JMdict by [NotebookWordDetail.seq].
  Future<NotebookWordDetail?> byId(String wordId) async {
    final word = await _db.wordsDao.wordById(wordId);
    if (word == null) {
      return null;
    }
    final stateRow = await _db.wordsDao.stateFor(wordId);
    final crop = await _db.wordsDao.firstCropFor(wordId);
    return NotebookWordDetail(
      wordId: word.id,
      seq: word.seq,
      lemma: word.lemma,
      reading: word.reading,
      state: WordState.fromDb(stateRow?.state ?? ''),
      sentence: crop?.ocrText,
      pageId: crop?.pageId,
    );
  }

  /// Every word with a listed [WordState], newest [NotebookEntry.firstSavedAt]
  /// first. [search] matches lemma or reading; [state] keeps one listed state.
  Future<List<NotebookEntry>> list({
    String search = '',
    WordState? state,
  }) async {
    final stateName = state != null && WordState.listed.contains(state)
        ? state.name
        : null;
    final rows = await _db.wordsDao.listWithStates(
      search: search,
      state: stateName,
    );
    return [
      for (final row in rows)
        if (WordState.listed.contains(WordState.fromDb(row.$2.state)))
          NotebookEntry(
            wordId: row.$1.id,
            lemma: row.$1.lemma,
            reading: row.$1.reading,
            state: WordState.fromDb(row.$2.state),
            firstSavedAt: row.$1.createdAt,
          ),
    ];
  }
}
