import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../dictionary/data/jmdict_provider.dart';
import '../../words/domain/word_state.dart';
import '../data/notebook_repository.dart';
import '../domain/notebook_entry.dart';
import '../domain/notebook_word_detail.dart';

part 'notebook_controller.g.dart';

/// Drift word + first crop, with JMdict gloss loaded by seq (not stored).
class NotebookWordView {
  const NotebookWordView({required this.detail, required this.glossText});

  final NotebookWordDetail detail;

  /// Copied from JMdict `entries.data_json` for [NotebookWordDetail.seq].
  final String glossText;
}

/// Search text + optional state filter for `/notebook`.
class NotebookQuery {
  const NotebookQuery({this.search = '', this.state});

  final String search;
  final WordState? state;

  NotebookQuery withSearch(String search) =>
      NotebookQuery(search: search, state: state);

  NotebookQuery withState(WordState? state) =>
      NotebookQuery(search: search, state: state);
}

@riverpod
class NotebookListQuery extends _$NotebookListQuery {
  @override
  NotebookQuery build() => const NotebookQuery();

  void setSearch(String search) {
    state = state.withSearch(search);
  }

  void setState(WordState? wordState) {
    state = state.withState(wordState);
  }
}

/// Caderno rows for the current search / state filter.
@riverpod
Future<List<NotebookEntry>> notebookEntries(Ref ref) {
  final query = ref.watch(notebookListQueryProvider);
  return ref
      .watch(notebookRepositoryProvider)
      .list(search: query.search, state: query.state);
}

/// `/notebook/word/:id` payload. Gloss comes from JMdict by seq.
@riverpod
Future<NotebookWordView?> notebookWord(Ref ref, String wordId) async {
  final detail = await ref.watch(notebookRepositoryProvider).byId(wordId);
  if (detail == null) {
    return null;
  }
  final jmdict = await ref.watch(jmdictServiceProvider.future);
  final entry = jmdict.entryBySeq(detail.seq);
  return NotebookWordView(detail: detail, glossText: entry?.glossText ?? '');
}
