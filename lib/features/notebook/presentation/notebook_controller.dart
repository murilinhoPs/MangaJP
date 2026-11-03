import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/graphemes.dart';
import '../../../core/utils/kanji.dart';
import '../../dictionary/data/jmdict_provider.dart';
import '../../words/domain/word_state.dart';
import '../data/notebook_repository.dart';
import '../domain/notebook_entry.dart';
import '../domain/notebook_kanji.dart';
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

enum NotebookTab { words, kanji }

@riverpod
class NotebookSelectedTab extends _$NotebookSelectedTab {
  @override
  NotebookTab build() => NotebookTab.words;

  void setTab(NotebookTab tab) {
    state = tab;
  }
}

@riverpod
class NotebookKanjiQuery extends _$NotebookKanjiQuery {
  @override
  String build() => '';

  void setSearch(String search) {
    state = search;
  }
}

/// Unfiltered Caderno words, newest first.
///
/// Palavras search/state and Kanji related-words both watch this so a
/// remove or study refreshes both tabs without leaking the Palavras filter
/// into the Kanji list.
@riverpod
Future<List<NotebookEntry>> notebookListedWords(Ref ref) {
  return ref.watch(notebookRepositoryProvider).list();
}

/// Caderno rows for the current search / state filter.
@riverpod
Future<List<NotebookEntry>> notebookEntries(Ref ref) async {
  final query = ref.watch(notebookListQueryProvider);
  await ref.watch(notebookListedWordsProvider.future);
  return ref
      .watch(notebookRepositoryProvider)
      .list(search: query.search, state: query.state);
}

/// Saved kanji for the Kanji tab, newest first, filtered by search.
@riverpod
Future<List<NotebookKanjiView>> notebookKanjiEntries(Ref ref) async {
  final search = ref.watch(notebookKanjiQueryProvider);
  final repo = ref.watch(notebookRepositoryProvider);
  final saved = await repo.listKanji();
  if (saved.isEmpty) {
    return const [];
  }
  final listedWords = await ref.watch(notebookListedWordsProvider.future);
  final jmdict = await ref.watch(jmdictServiceProvider.future);
  final lookups = jmdict.kanjiByCharacters([
    for (final row in saved) row.literal,
  ]);
  final views = <NotebookKanjiView>[];
  for (final row in saved) {
    final words = [
      for (final word in listedWords)
        if (stripVariationSelectors(word.lemma).contains(row.literal)) word,
    ];
    final view = NotebookKanjiView(
      literal: row.literal,
      savedAt: row.savedAt,
      originPageId: row.originPageId,
      lookup: lookups[row.literal],
      notebookWords: words,
    );
    if (view.matchesSearch(search)) {
      views.add(view);
    }
  }
  return views;
}

/// `/notebook/kanji/:char` payload.
@riverpod
Future<NotebookKanjiView?> notebookKanji(Ref ref, String char) async {
  final literal = normalizeKanjiLiteral(char);
  if (literal == null) {
    return null;
  }
  final repo = ref.watch(notebookRepositoryProvider);
  final row = await repo.kanjiByLiteral(literal);
  if (row == null) {
    return null;
  }
  await ref.watch(notebookListedWordsProvider.future);
  final jmdict = await ref.watch(jmdictServiceProvider.future);
  return NotebookKanjiView(
    literal: row.literal,
    savedAt: row.savedAt,
    originPageId: row.originPageId,
    lookup: jmdict.kanjiByCharacter(literal),
    notebookWords: await repo.wordsContainingKanji(literal),
  );
}

@riverpod
Future<bool> kanjiIsSaved(Ref ref, String literal) {
  return ref.watch(notebookRepositoryProvider).isKanjiSaved(literal);
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
