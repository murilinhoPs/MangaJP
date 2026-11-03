import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/features/notebook/data/notebook_repository.dart';
import 'package:manga_jp/features/notebook/domain/notebook_kanji.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

const _ivs = '\u{E0100}';

void main() {
  test(
    'save, list newest first, duplicate normalized literal is a no-op',
    () async {
      final env = await _open();
      addTearDown(env.db.close);

      await _page(env.db, 'page-a');
      await env.db
          .into(env.db.savedKanji)
          .insert(
            SavedKanjiCompanion.insert(
              literal: '高',
              savedAt: DateTime.utc(2026, 1, 1),
              originPageId: const Value('page-a'),
            ),
          );
      await env.notebook.saveKanji(literal: '食$_ivs', originPageId: 'page-a');

      var listed = await env.notebook.listKanji();
      expect(listed.map((row) => row.literal).toList(), ['食', '高']);
      final firstSavedAt = listed.first.savedAt;
      final firstOrigin = listed.first.originPageId;

      await _page(env.db, 'page-b');
      await env.notebook.saveKanji(literal: '食', originPageId: 'page-b');
      listed = await env.notebook.listKanji();
      expect(listed, hasLength(2));
      expect(listed.first.literal, '食');
      expect(listed.first.savedAt, firstSavedAt);
      expect(listed.first.originPageId, firstOrigin);

      expect(await env.db.select(env.db.userWords).get(), isEmpty);
      expect(await env.db.select(env.db.userWordStates).get(), isEmpty);
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
    },
  );

  test('叱 and 𠮟 stay two rows after IVS strip', () async {
    final env = await _open();
    addTearDown(env.db.close);

    await env.notebook.saveKanji(literal: '叱');
    await env.notebook.saveKanji(literal: '𠮟');
    await env.notebook.saveKanji(literal: '叱$_ivs');

    final listed = await env.notebook.listKanji();
    expect(listed.map((row) => row.literal).toSet(), {'叱', '𠮟'});
  });

  test('remove deletes only the saved_kanji row', () async {
    final env = await _open();
    addTearDown(env.db.close);

    await env.notebook.saveKanji(literal: '食');
    await env.notebook.saveKanji(literal: '高');
    await env.notebook.removeKanji('食$_ivs');

    expect(
      (await env.notebook.listKanji()).map((row) => row.literal).toList(),
      ['高'],
    );
    await env.notebook.removeKanji('missing');
    expect((await env.notebook.listKanji()).single.literal, '高');
  });

  test('search without KANJIDIC2 only matches the literal', () {
    final view = NotebookKanjiView(
      literal: '食',
      savedAt: DateTime.utc(2026, 1, 1),
    );
    expect(view.matchesSearch('食'), isTrue);
    expect(view.matchesSearch('eat'), isFalse);
    expect(view.matchesSearch('ショク'), isFalse);
    expect(view.matchesSearch(''), isTrue);
  });

  test(
    'wordsContainingKanji lists Caderno lemmas that include the literal',
    () async {
      final env = await _open();
      addTearDown(env.db.close);

      await _word(
        env.db,
        id: 'eat',
        lemma: '食べる',
        reading: 'たべる',
        createdAt: DateTime.utc(2026, 2, 1),
      );
      await _word(
        env.db,
        id: 'high',
        lemma: '高い',
        reading: 'たかい',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await _word(
        env.db,
        id: 'ghost',
        lemma: '食事',
        reading: 'しょくじ',
        createdAt: DateTime.utc(2026, 3, 1),
        withState: false,
      );

      final hits = await env.notebook.wordsContainingKanji('食');
      expect(hits.map((row) => row.wordId).toList(), ['eat']);
      expect(hits.single.lemma, '食べる');
    },
  );

  test('saveKanji rejects more than one code point', () async {
    final env = await _open();
    addTearDown(env.db.close);
    expect(
      () => env.notebook.saveKanji(literal: '食べる'),
      throwsA(isA<ArgumentError>()),
    );
  });
}

class _Env {
  const _Env({required this.db, required this.notebook});

  final AppDatabase db;
  final NotebookRepository notebook;
}

Future<_Env> _open() async {
  final db = AppDatabase(NativeDatabase.memory());
  return _Env(db: db, notebook: NotebookRepository(db));
}

Future<void> _page(AppDatabase db, String id) {
  return db
      .into(db.capturedPages)
      .insert(
        CapturedPagesCompanion.insert(
          id: id,
          sha256: id,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        mode: InsertMode.insertOrIgnore,
      );
}

Future<void> _word(
  AppDatabase db, {
  required String id,
  required String lemma,
  required String reading,
  required DateTime createdAt,
  bool withState = true,
}) async {
  await db.wordsDao.insertWord(
    UserWordsCompanion.insert(
      id: id,
      seq: id.hashCode,
      lemma: lemma,
      reading: reading,
      createdAt: createdAt,
    ),
  );
  if (!withState) {
    return;
  }
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: id,
          state: WordState.saved.name,
          updatedAt: createdAt,
        ),
      );
}
