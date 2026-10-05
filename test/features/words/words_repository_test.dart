import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/core/utils/ids.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/words/data/words_repository.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../capture/fixture_png.dart';

const _taberuSeq = 1358280;
const _highHomographSeq = 9990001;
const _lowHomographSeq = 9990002;

void main() {
  test('onCreate has words / word_states / crop_words / cards', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.appMetaDao.getValue('schema_version'), '5');
    final names = await _tableNames(db);
    expect(
      names,
      containsAll(<String>[
        'words',
        'word_states',
        'crop_words',
        'cards',
        'card_srs',
      ]),
    );
    expect(await _cardRowCount(db), 0);
  });

  test(
    'Save writes words + word_states=saved + crop_words and no card',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);

      await env.words.saveFromLookup(
        cropId: env.cropId,
        seq: _taberuSeq,
        lemma: '食べる',
        reading: 'たべる',
      );

      final words = await env.db.select(env.db.userWords).get();
      expect(words, hasLength(1));
      expect(words.single.seq, _taberuSeq);
      expect(words.single.lemma, '食べる');
      expect(words.single.reading, 'たべる');

      final states = await env.db.select(env.db.userWordStates).get();
      expect(states, hasLength(1));
      expect(states.single.wordId, words.single.id);
      expect(states.single.state, WordState.saved.name);

      final links = await env.db.select(env.db.cropWords).get();
      expect(links, hasLength(1));
      expect(links.single.cropId, env.cropId);
      expect(links.single.wordId, words.single.id);

      expect(await _cardRowCount(env.db), 0);
    },
  );

  test('second Save is a no-op: no duplicate rows, no field changes', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);

    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: '食べる',
      reading: 'たべる',
    );
    final firstWord = (await env.db.select(env.db.userWords).get()).single;
    final firstState =
        (await env.db.select(env.db.userWordStates).get()).single;
    final firstLink = (await env.db.select(env.db.cropWords).get()).single;

    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: 'spoof',
      reading: 'spoof',
    );

    final words = await env.db.select(env.db.userWords).get();
    expect(words, hasLength(1));
    expect(words.single.id, firstWord.id);
    expect(words.single.seq, firstWord.seq);
    expect(words.single.lemma, '食べる');
    expect(words.single.reading, 'たべる');
    expect(words.single.createdAt, firstWord.createdAt);

    final states = await env.db.select(env.db.userWordStates).get();
    expect(states, hasLength(1));
    expect(states.single.wordId, firstState.wordId);
    expect(states.single.state, WordState.saved.name);
    expect(states.single.updatedAt, firstState.updatedAt);

    final links = await env.db.select(env.db.cropWords).get();
    expect(links, hasLength(1));
    expect(links.single.cropId, firstLink.cropId);
    expect(links.single.wordId, firstLink.wordId);
    expect(links.single.createdAt, firstLink.createdAt);
    expect(await _cardRowCount(env.db), 0);
  });

  for (final state in <WordState>[
    WordState.learning,
    WordState.known,
    WordState.ignored,
  ]) {
    test('Save does not downgrade existing ${state.name} state', () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      final wordId = await _seedWord(env.db, seq: _taberuSeq, state: state);
      final before = (await env.db.wordsDao.stateFor(wordId))!;

      await env.words.saveFromLookup(
        cropId: env.cropId,
        seq: _taberuSeq,
        lemma: '食べる',
        reading: 'たべる',
      );

      final words = await env.db.select(env.db.userWords).get();
      expect(words, hasLength(1));
      expect(words.single.id, wordId);

      final states = await env.db.select(env.db.userWordStates).get();
      expect(states, hasLength(1));
      expect(states.single.state, state.name);
      expect(states.single.updatedAt, before.updatedAt);

      final links = await env.db.select(env.db.cropWords).get();
      expect(links, hasLength(1));
      expect(links.single.wordId, wordId);
      expect(links.single.cropId, env.cropId);
      expect(await _cardRowCount(env.db), 0);
    });
  }

  test('Save of a different seq from the same crop is a second word', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);

    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _highHomographSeq,
      lemma: '優先語',
      reading: 'ゆうせんご',
    );
    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _lowHomographSeq,
      lemma: '優先語',
      reading: 'ゆうせんご',
    );

    final words = await env.db.select(env.db.userWords).get();
    expect(words.map((row) => row.seq).toSet(), {
      _highHomographSeq,
      _lowHomographSeq,
    });
    expect(await env.db.select(env.db.userWordStates).get(), hasLength(2));
    expect(await env.db.select(env.db.cropWords).get(), hasLength(2));
    expect(await _cardRowCount(env.db), 0);
  });
}

class _Env {
  const _Env({required this.db, required this.words, required this.cropId});

  final AppDatabase db;
  final WordsRepository words;
  final String cropId;
}

Future<_Env> _openRepo() async {
  final db = AppDatabase(NativeDatabase.memory());
  final crop = await PagesRepository(db).saveRecognizedCrop(
    pageId: 'page-save',
    sourceSha256: sha256Hex(fixturePng()),
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: '食べた',
    engineId: 'fake',
  );
  return _Env(db: db, words: WordsRepository(db), cropId: crop.id);
}

Future<String> _seedWord(
  AppDatabase db, {
  required int seq,
  required WordState state,
  String lemma = '食べる',
  String reading = 'たべる',
}) async {
  final id = newId();
  final now = DateTime.now().toUtc();
  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: id,
          seq: seq,
          lemma: lemma,
          reading: reading,
          createdAt: now,
        ),
      );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: id,
          state: state.name,
          updatedAt: now,
        ),
      );
  return id;
}

Future<Set<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return {for (final row in rows) row.read<String>('name')};
}

Future<int> _cardRowCount(AppDatabase db) async {
  final names = await _tableNames(db);
  const cardTables = {'cards', 'flashcards', 'card_srs'};
  var total = 0;
  for (final name in names.intersection(cardTables)) {
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM $name')
        .getSingle();
    total += row.read<int>('c');
  }
  return total;
}
