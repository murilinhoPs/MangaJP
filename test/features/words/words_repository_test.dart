import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/core/utils/ids.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
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

    expect(await db.appMetaDao.getValue('schema_version'), '7');
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
    final wordCols = await db.customSelect("PRAGMA table_info('words')").get();
    expect(
      {for (final row in wordCols) row.read<String>('name')},
      contains('user_note'),
    );
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

  test('custom save writes custom:<uuid>, surface lemma, required note', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);

    await env.words.saveCustomFromLookup(
      cropId: env.cropId,
      surface: 'ぴよ',
      userNote: '  nome do personagem  ',
    );

    final words = await env.db.select(env.db.userWords).get();
    expect(words, hasLength(1));
    expect(words.single.id, startsWith(customWordIdPrefix));
    expect(words.single.lemma, 'ぴよ');
    expect(words.single.reading, 'ぴよ');
    expect(words.single.userNote, 'nome do personagem');
    expect(words.single.seq, lessThan(0));

    final states = await env.db.select(env.db.userWordStates).get();
    expect(states, hasLength(1));
    expect(states.single.wordId, words.single.id);
    expect(states.single.state, WordState.saved.name);

    final links = await env.db.select(env.db.cropWords).get();
    expect(links, hasLength(1));
    expect(links.single.cropId, env.cropId);
    expect(links.single.wordId, words.single.id);
    expect(await _cardRowCount(env.db), 0);
  });

  test('custom save rejects empty or whitespace-only note', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);

    await expectLater(
      env.words.saveCustomFromLookup(
        cropId: env.cropId,
        surface: 'ぴよ',
        userNote: '   ',
      ),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      env.words.saveCustomFromLookup(
        cropId: env.cropId,
        surface: 'ぴよ',
        userNote: '',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(await env.db.select(env.db.userWords).get(), isEmpty);
    expect(await env.db.select(env.db.userWordStates).get(), isEmpty);
    expect(await env.db.select(env.db.cropWords).get(), isEmpty);
  });

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

  test(
    'crop_words / word_states / cards FKs are not ON DELETE CASCADE',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      Future<Set<String>> onDelete(String table) async {
        final rows = await db
            .customSelect('PRAGMA foreign_key_list($table)')
            .get();
        return {
          for (final row in rows) row.read<String>('on_delete').toUpperCase(),
        };
      }

      expect(await onDelete('crop_words'), isNot(contains('CASCADE')));
      expect(await onDelete('word_states'), isNot(contains('CASCADE')));
      expect(await onDelete('cards'), isNot(contains('CASCADE')));
      expect(await onDelete('card_srs'), isNot(contains('CASCADE')));
      expect(await onDelete('review_logs'), isNot(contains('CASCADE')));
    },
  );

  test('removeFromNotebook without a card deletes word, state, crop_words; '
      'crop and page stay unchanged', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: '食べる',
      reading: 'たべる',
    );
    final wordId = (await env.db.select(env.db.userWords).get()).single.id;
    final cropBefore = (await env.db.select(env.db.capturedCrops).get()).single;
    final pageBefore = (await env.db.select(env.db.capturedPages).get()).single;

    await env.words.removeFromNotebook(wordId);

    expect(await env.db.select(env.db.userWords).get(), isEmpty);
    expect(await env.db.select(env.db.userWordStates).get(), isEmpty);
    expect(await env.db.select(env.db.cropWords).get(), isEmpty);
    expect(await env.db.select(env.db.userCards).get(), isEmpty);
    expect(await env.db.wordsDao.wordBySeq(_taberuSeq), isNull);

    final cropAfter = (await env.db.select(env.db.capturedCrops).get()).single;
    final pageAfter = (await env.db.select(env.db.capturedPages).get()).single;
    expect(_cropSnapshot(cropAfter), _cropSnapshot(cropBefore));
    expect(_pageSnapshot(pageAfter), _pageSnapshot(pageBefore));
  });

  test(
    'removeFromNotebook with a card also deletes card, SRS, and logs',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await env.words.saveFromLookup(
        cropId: env.cropId,
        seq: _taberuSeq,
        lemma: '食べる',
        reading: 'たべる',
      );
      final wordId = (await env.db.select(env.db.userWords).get()).single.id;
      await _seedCardAndLog(env.db, wordId: wordId);
      final cropBefore =
          (await env.db.select(env.db.capturedCrops).get()).single;
      final pageBefore =
          (await env.db.select(env.db.capturedPages).get()).single;
      expect(await env.db.select(env.db.userReviewLogs).get(), hasLength(1));

      await env.words.removeFromNotebook(wordId);

      expect(await env.db.select(env.db.userWords).get(), isEmpty);
      expect(await env.db.select(env.db.userWordStates).get(), isEmpty);
      expect(await env.db.select(env.db.cropWords).get(), isEmpty);
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
      expect(await env.db.select(env.db.userReviewLogs).get(), isEmpty);
      expect(
        _cropSnapshot((await env.db.select(env.db.capturedCrops).get()).single),
        _cropSnapshot(cropBefore),
      );
      expect(
        _pageSnapshot((await env.db.select(env.db.capturedPages).get()).single),
        _pageSnapshot(pageBefore),
      );
    },
  );

  test('removeFromNotebook on a missing word is a no-op', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: '食べる',
      reading: 'たべる',
    );
    final beforeWords = await env.db.select(env.db.userWords).get();
    final beforeStates = await env.db.select(env.db.userWordStates).get();
    final beforeLinks = await env.db.select(env.db.cropWords).get();

    await env.words.removeFromNotebook('missing');

    expect(
      (await env.db.select(env.db.userWords).get()).single.id,
      beforeWords.single.id,
    );
    expect(
      (await env.db.select(env.db.userWordStates).get()).single.updatedAt,
      beforeStates.single.updatedAt,
    );
    expect(
      (await env.db.select(env.db.cropWords).get()).single.createdAt,
      beforeLinks.single.createdAt,
    );
  });

  test(
    'removeFromNotebook leaves a second word, its card, SRS, logs, and links',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await env.words.saveFromLookup(
        cropId: env.cropId,
        seq: _taberuSeq,
        lemma: '食べる',
        reading: 'たべる',
      );
      final eatId = (await env.db.select(env.db.userWords).get()).single.id;
      await _seedCardAndLog(env.db, wordId: eatId);

      await env.db
          .into(env.db.userWords)
          .insert(
            UserWordsCompanion.insert(
              id: 'drink',
              seq: _highHomographSeq,
              lemma: '飲む',
              reading: 'のむ',
              createdAt: DateTime.utc(2026, 1, 2),
            ),
          );
      await env.db
          .into(env.db.userWordStates)
          .insert(
            UserWordStatesCompanion.insert(
              wordId: 'drink',
              state: WordState.learning.name,
              updatedAt: DateTime.utc(2026, 1, 2),
            ),
          );
      await env.db
          .into(env.db.userCards)
          .insert(
            UserCardsCompanion.insert(
              id: 'card-drink',
              wordId: 'drink',
              kind: FlashcardKind.vocab.name,
              createdAt: DateTime.utc(2026, 2, 2),
            ),
          );
      await env.db
          .into(env.db.userCardSrs)
          .insert(
            UserCardSrsCompanion.insert(
              cardId: 'card-drink',
              easeFactor: 2.5,
              intervalDays: 7,
              repetitions: 2,
              dueAt: DateTime.utc(2026, 7, 1),
              phase: 'review',
              engineId: kSm2JrEngineId,
            ),
          );
      await env.db
          .into(env.db.userReviewLogs)
          .insert(
            UserReviewLogsCompanion.insert(
              id: 'log-drink',
              cardId: 'card-drink',
              ratedAt: DateTime.utc(2026, 3, 2),
              rating: 4,
              quality: 5,
              engineId: kSm2JrEngineId,
              isDrill: 0,
            ),
          );
      await env.db
          .into(env.db.cropWords)
          .insert(
            CropWordsCompanion.insert(
              cropId: env.cropId,
              wordId: 'drink',
              createdAt: DateTime.utc(2026, 1, 6),
            ),
          );

      await env.words.removeFromNotebook(eatId);

      expect((await env.db.select(env.db.userWords).get()).single.id, 'drink');
      expect(
        (await env.db.select(env.db.userWordStates).get()).single.wordId,
        'drink',
      );
      expect(
        (await env.db.select(env.db.userCards).get()).single.id,
        'card-drink',
      );
      expect(
        (await env.db.select(env.db.userCardSrs).get()).single.cardId,
        'card-drink',
      );
      expect(
        (await env.db.select(env.db.userReviewLogs).get()).single.id,
        'log-drink',
      );
      expect(
        (await env.db.select(env.db.cropWords).get()).single.wordId,
        'drink',
      );
    },
  );

  test('after removeFromNotebook, lookup of the same seq is unknown and Save '
      'inserts a new word without leftover state', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: '食べる',
      reading: 'たべる',
    );
    final oldId = (await env.db.select(env.db.userWords).get()).single.id;
    await env.words.removeFromNotebook(oldId);

    expect(await env.db.wordsDao.wordBySeq(_taberuSeq), isNull);
    expect(await env.db.wordsDao.stateFor(oldId), isNull);
    expect(await env.db.select(env.db.userWordStates).get(), isEmpty);

    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: '食べる',
      reading: 'たべる',
    );

    final words = await env.db.select(env.db.userWords).get();
    expect(words, hasLength(1));
    expect(words.single.id, isNot(oldId));
    expect(words.single.seq, _taberuSeq);
    final states = await env.db.select(env.db.userWordStates).get();
    expect(states, hasLength(1));
    expect(states.single.wordId, words.single.id);
    expect(states.single.state, WordState.saved.name);
    expect(states.single.wordId, isNot(oldId));
  });

  test('hasCard is true only when a cards row exists', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await env.words.saveFromLookup(
      cropId: env.cropId,
      seq: _taberuSeq,
      lemma: '食べる',
      reading: 'たべる',
    );
    final wordId = (await env.db.select(env.db.userWords).get()).single.id;
    expect(await env.words.hasCard(wordId), isFalse);
    await _seedCardAndLog(env.db, wordId: wordId);
    expect(await env.words.hasCard(wordId), isTrue);
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

Future<void> _seedCardAndLog(AppDatabase db, {required String wordId}) async {
  await db
      .into(db.userCards)
      .insert(
        UserCardsCompanion.insert(
          id: 'card-$wordId',
          wordId: wordId,
          kind: FlashcardKind.vocab.name,
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );
  await db
      .into(db.userCardSrs)
      .insert(
        UserCardSrsCompanion.insert(
          cardId: 'card-$wordId',
          easeFactor: 2.36,
          intervalDays: 14,
          repetitions: 3,
          dueAt: DateTime.utc(2026, 6, 15),
          phase: 'review',
          engineId: kSm2JrEngineId,
        ),
      );
  await db
      .into(db.userReviewLogs)
      .insert(
        UserReviewLogsCompanion.insert(
          id: 'log-$wordId',
          cardId: 'card-$wordId',
          ratedAt: DateTime.utc(2026, 3, 1),
          rating: 3,
          quality: 4,
          engineId: kSm2JrEngineId,
          isDrill: 0,
        ),
      );
}

typedef _CropSnapshot = ({
  String id,
  String pageId,
  String ocrText,
  String engineId,
  double left,
  double top,
  double width,
  double height,
  DateTime createdAt,
});

typedef _PageSnapshot = ({String id, String sha256, DateTime createdAt});

_CropSnapshot _cropSnapshot(CapturedCrop row) {
  return (
    id: row.id,
    pageId: row.pageId,
    ocrText: row.ocrText,
    engineId: row.engineId,
    left: row.left,
    top: row.top,
    width: row.width,
    height: row.height,
    createdAt: row.createdAt,
  );
}

_PageSnapshot _pageSnapshot(CapturedPage row) {
  return (id: row.id, sha256: row.sha256, createdAt: row.createdAt);
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
