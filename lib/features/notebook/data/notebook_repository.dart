import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/utils/kanji.dart';
import '../../words/domain/word_state.dart';
import '../domain/notebook_entry.dart';
import '../domain/notebook_word_detail.dart';

part 'notebook_repository.g.dart';

@Riverpod(keepAlive: true)
NotebookRepository notebookRepository(Ref ref) {
  return NotebookRepository(ref.watch(appDatabaseProvider));
}

/// Caderno queries (list / search / filter / word detail / saved kanji).
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
      userNote: word.userNote,
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

  Future<SavedKanjiData?> kanjiByLiteral(String literal) {
    final normalized = normalizeKanjiLiteral(literal);
    if (normalized == null) {
      return Future<SavedKanjiData?>.value(null);
    }
    return _db.savedKanjiDao.byLiteral(normalized);
  }

  Future<bool> isKanjiSaved(String literal) async {
    return (await kanjiByLiteral(literal)) != null;
  }

  /// Saved kanji, newest [SavedKanjiData.savedAt] first.
  Future<List<SavedKanjiData>> listKanji() {
    return _db.savedKanjiDao.listNewestFirst();
  }

  /// Persist [literal] in `saved_kanji`. No card, no `words`, no `word_states`.
  ///
  /// [literal] is normalized with [normalizeKanjiLiteral] before insert.
  /// A second save of the same identity is a no-op and does not rewrite
  /// `saved_at` or `origin_page_id`.
  Future<void> saveKanji({
    required String literal,
    String? originPageId,
  }) async {
    final normalized = normalizeKanjiLiteral(literal);
    if (normalized == null) {
      throw ArgumentError.value(
        literal,
        'literal',
        'exactly one code point after stripping IVS/VS',
      );
    }
    await _db.savedKanjiDao.insertIgnore(
      SavedKanjiCompanion.insert(
        literal: normalized,
        savedAt: DateTime.now().toUtc(),
        originPageId: Value(originPageId),
      ),
    );
  }

  /// Delete the `saved_kanji` row. Missing literal is a no-op.
  Future<void> removeKanji(String literal) async {
    final normalized = normalizeKanjiLiteral(literal) ?? literal;
    await _db.savedKanjiDao.deleteLiteral(normalized);
  }

  /// Listed Caderno words whose `lemma_key` contains [literal].
  Future<List<NotebookEntry>> wordsContainingKanji(String literal) async {
    final normalized = normalizeKanjiLiteral(literal);
    if (normalized == null) {
      return const [];
    }
    final pattern = '%${_escapeLike(normalized)}%';
    final query = _db.select(_db.userWords).join([
      innerJoin(
        _db.userWordStates,
        _db.userWordStates.wordId.equalsExp(_db.userWords.id),
      ),
    ]);
    query.where(
      _db.userWordStates.state.isIn(const [
            'saved',
            'learning',
            'known',
            'ignored',
          ]) &
          _db.userWords.lemmaKey.like(pattern, escapeChar: r'\'),
    );
    query.orderBy([OrderingTerm.desc(_db.userWords.createdAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        if (WordState.listed.contains(
          WordState.fromDb(row.readTable(_db.userWordStates).state),
        ))
          NotebookEntry(
            wordId: row.readTable(_db.userWords).id,
            lemma: row.readTable(_db.userWords).lemma,
            reading: row.readTable(_db.userWords).reading,
            state: WordState.fromDb(row.readTable(_db.userWordStates).state),
            firstSavedAt: row.readTable(_db.userWords).createdAt,
          ),
    ];
  }
}

String _escapeLike(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
