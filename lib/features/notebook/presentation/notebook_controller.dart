import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../words/domain/word_state.dart';
import '../data/notebook_repository.dart';
import '../domain/notebook_entry.dart';

part 'notebook_controller.g.dart';

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
