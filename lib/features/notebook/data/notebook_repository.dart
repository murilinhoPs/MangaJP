import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../words/domain/word_state.dart';
import '../domain/notebook_entry.dart';

part 'notebook_repository.g.dart';

@Riverpod(keepAlive: true)
NotebookRepository notebookRepository(Ref ref) {
  return NotebookRepository(ref.watch(appDatabaseProvider));
}

/// Caderno queries (list / search / filter). Read-only over words + word_states.
class NotebookRepository {
  const NotebookRepository(this._db);

  final AppDatabase _db;

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
