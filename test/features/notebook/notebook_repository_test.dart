import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/features/notebook/data/notebook_repository.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

void main() {
  test(
    'list is first_saved_at descending for every listed word_state',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);

      await _seedWord(
        env.db,
        id: 'oldest',
        seq: 1,
        lemma: '古い',
        reading: 'ふるい',
        state: WordState.saved,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await _seedWord(
        env.db,
        id: 'middle',
        seq: 2,
        lemma: '学ぶ',
        reading: 'まなぶ',
        state: WordState.learning,
        createdAt: DateTime.utc(2026, 2, 1),
      );
      await _seedWord(
        env.db,
        id: 'newest',
        seq: 3,
        lemma: '知る',
        reading: 'しる',
        state: WordState.known,
        createdAt: DateTime.utc(2026, 3, 1),
      );
      await _seedWord(
        env.db,
        id: 'ignored',
        seq: 4,
        lemma: '無視',
        reading: 'むし',
        state: WordState.ignored,
        createdAt: DateTime.utc(2026, 2, 15),
      );
      await _seedWord(
        env.db,
        id: 'no-state',
        seq: 5,
        lemma: '無し',
        reading: 'なし',
        createdAt: DateTime.utc(2026, 4, 1),
      );
      await _seedWord(
        env.db,
        id: 'unknown',
        seq: 6,
        lemma: '不明',
        reading: 'ふめい',
        state: WordState.unknown,
        createdAt: DateTime.utc(2026, 5, 1),
      );

      final listed = await env.notebook.list();
      expect(listed.map((row) => row.wordId).toList(), [
        'newest',
        'ignored',
        'middle',
        'oldest',
      ]);
      expect(
        listed
            .map(
              (row) => (
                row.firstSavedAt.year,
                row.firstSavedAt.month,
                row.firstSavedAt.day,
              ),
            )
            .toList(),
        [(2026, 3, 1), (2026, 2, 15), (2026, 2, 1), (2026, 1, 1)],
      );
      for (var i = 0; i < listed.length - 1; i++) {
        expect(
          listed[i].firstSavedAt.isAfter(listed[i + 1].firstSavedAt),
          isTrue,
        );
      }
    },
  );

  test('search matches lemma and reading', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);

    await _seedWord(
      env.db,
      id: 'eat',
      seq: 10,
      lemma: '食べる',
      reading: 'たべる',
      state: WordState.saved,
      createdAt: DateTime.utc(2026, 1, 2),
    );
    await _seedWord(
      env.db,
      id: 'drink',
      seq: 11,
      lemma: '飲む',
      reading: 'のむ',
      state: WordState.saved,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final byLemma = await env.notebook.list(search: '食べ');
    expect(byLemma, hasLength(1));
    expect(byLemma.single.wordId, 'eat');
    expect(byLemma.single.lemma, '食べる');

    final byReading = await env.notebook.list(search: 'のむ');
    expect(byReading, hasLength(1));
    expect(byReading.single.wordId, 'drink');
    expect(byReading.single.reading, 'のむ');
  });

  test('state filter hides the other states', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);

    await _seedWord(
      env.db,
      id: 'saved',
      seq: 20,
      lemma: '保存',
      reading: 'ほぞん',
      state: WordState.saved,
      createdAt: DateTime.utc(2026, 1, 4),
    );
    await _seedWord(
      env.db,
      id: 'learning',
      seq: 21,
      lemma: '学習',
      reading: 'がくしゅう',
      state: WordState.learning,
      createdAt: DateTime.utc(2026, 1, 3),
    );
    await _seedWord(
      env.db,
      id: 'known',
      seq: 22,
      lemma: '既知',
      reading: 'きち',
      state: WordState.known,
      createdAt: DateTime.utc(2026, 1, 2),
    );
    await _seedWord(
      env.db,
      id: 'ignored',
      seq: 23,
      lemma: '無視',
      reading: 'むし',
      state: WordState.ignored,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final learning = await env.notebook.list(state: WordState.learning);
    expect(learning.map((row) => row.wordId).toList(), ['learning']);
    expect(learning.single.state, WordState.learning);

    final known = await env.notebook.list(state: WordState.known);
    expect(known.map((row) => row.wordId).toList(), ['known']);
    expect(known.single.state, WordState.known);
    expect(known.map((row) => row.state), isNot(contains(WordState.saved)));
    expect(known.map((row) => row.state), isNot(contains(WordState.learning)));
    expect(known.map((row) => row.state), isNot(contains(WordState.ignored)));
  });
}

class _Env {
  const _Env({required this.db, required this.notebook});

  final AppDatabase db;
  final NotebookRepository notebook;
}

Future<_Env> _openRepo() async {
  final db = AppDatabase(NativeDatabase.memory());
  return _Env(db: db, notebook: NotebookRepository(db));
}

Future<void> _seedWord(
  AppDatabase db, {
  required String id,
  required int seq,
  required String lemma,
  required String reading,
  WordState? state,
  required DateTime createdAt,
}) async {
  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: id,
          seq: seq,
          lemma: lemma,
          reading: reading,
          createdAt: createdAt,
        ),
      );
  if (state == null) {
    return;
  }
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: id,
          state: state.name,
          updatedAt: createdAt,
        ),
      );
}
