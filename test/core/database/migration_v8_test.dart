import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../../drift/schema.dart';
import '../../drift/schema_v7.dart' as v7;

const _ivs = '\u{E0100}';

int _unix(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('schema dump v7 upgrades to v8', () async {
    final connection = await verifier.startAt(7);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 8);
    await _expectNoFkViolations(db);
    expect(await db.appMetaDao.getValue('schema_version'), '8');
  });

  test(
    'v7 IVS-duplicate custom words merge into one row with card, SRS and notes',
    () async {
      final env = await _v7(verifier);
      const ivsLemma = '辻$_ivs';
      final older = _unix(DateTime.utc(2026, 1, 1));
      final newer = _unix(DateTime.utc(2026, 2, 1));
      final reviewed = _unix(DateTime.utc(2026, 3, 15));
      final due = _unix(DateTime.utc(2026, 4, 1));

      await _word(
        env.old,
        id: 'custom:tsuji-plain',
        seq: -1,
        lemma: '辻',
        note: 'plain note',
        createdAt: older,
        state: WordState.saved,
      );
      await _word(
        env.old,
        id: 'custom:tsuji-ivs',
        seq: -2,
        lemma: ivsLemma,
        note: 'ivs note',
        createdAt: newer,
        state: WordState.learning,
      );
      await _word(
        env.old,
        id: 'jmdict-taberu',
        seq: 1358280,
        lemma: '食べる',
        reading: 'たべる',
        createdAt: older,
        custom: false,
      );
      await _word(
        env.old,
        id: 'custom:kuzu-old',
        seq: -3,
        lemma: '葛',
        note: 'same note',
        createdAt: older,
      );
      await _word(
        env.old,
        id: 'custom:kuzu-new',
        seq: -4,
        lemma: '葛$_ivs',
        note: 'same note',
        createdAt: newer,
      );

      await env.old
          .into(env.old.cropWords)
          .insert(
            v7.CropWordsCompanion.insert(
              cropId: 'crop-1',
              wordId: 'custom:tsuji-plain',
              createdAt: older,
            ),
          );
      await env.old
          .into(env.old.cropWords)
          .insert(
            v7.CropWordsCompanion.insert(
              cropId: 'crop-1',
              wordId: 'custom:tsuji-ivs',
              createdAt: newer,
            ),
          );
      await env.old
          .into(env.old.cropWords)
          .insert(
            v7.CropWordsCompanion.insert(
              cropId: 'crop-2',
              wordId: 'custom:tsuji-ivs',
              createdAt: newer,
            ),
          );

      await _card(
        env.old,
        id: 'card-tsuji-ivs',
        wordId: 'custom:tsuji-ivs',
        createdAt: newer,
        repetitions: 5,
        dueAt: due,
        ratedAt: reviewed,
        logId: 'log-tsuji-ivs',
      );
      await env.old.close();

      final db = await _migrate(verifier, env.schema);
      expect(await db.appMetaDao.getValue('schema_version'), '8');

      final words = await db.select(db.userWords).get();
      expect(words.map((row) => row.id).toSet(), {
        'custom:tsuji-ivs',
        'custom:kuzu-old',
        'jmdict-taberu',
      });

      final tsuji = words.singleWhere((row) => row.id == 'custom:tsuji-ivs');
      expect(tsuji.lemma, ivsLemma);
      expect(tsuji.reading, ivsLemma);
      expect(tsuji.lemmaKey, '辻');
      expect(tsuji.userNote, 'ivs note\nplain note');

      final kuzu = words.singleWhere((row) => row.id == 'custom:kuzu-old');
      expect(kuzu.lemma, '葛');
      expect(kuzu.lemmaKey, '葛');
      expect(kuzu.userNote, 'same note');

      final jmdict = words.singleWhere((row) => row.id == 'jmdict-taberu');
      expect(jmdict.lemma, '食べる');
      expect(jmdict.lemmaKey, '食べる');

      final states = await db.select(db.userWordStates).get();
      expect(states.map((row) => row.wordId).toSet(), {
        'custom:tsuji-ivs',
        'custom:kuzu-old',
      });
      expect(
        states.singleWhere((row) => row.wordId == 'custom:tsuji-ivs').state,
        WordState.learning.name,
      );

      final links = await db.select(db.cropWords).get();
      expect(links.map((row) => (row.cropId, row.wordId)).toSet(), {
        ('crop-1', 'custom:tsuji-ivs'),
        ('crop-2', 'custom:tsuji-ivs'),
      });

      final cards = await db.select(db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, 'card-tsuji-ivs');
      expect(cards.single.wordId, 'custom:tsuji-ivs');

      final srs = (await db.select(db.userCardSrs).get()).single;
      expect(srs.cardId, 'card-tsuji-ivs');
      expect(srs.repetitions, 5);

      final logs = await db.select(db.userReviewLogs).get();
      expect(logs, hasLength(1));
      expect(logs.single.cardId, 'card-tsuji-ivs');

      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND name "
            "IN ('idx_words_lemma_key', 'idx_words_custom_lemma_key')",
          )
          .get();
      expect(
        {for (final row in indexes) row.read<String>('name')},
        {'idx_words_lemma_key', 'idx_words_custom_lemma_key'},
      );

      expect(
        (await db.wordsDao.customWordByLemmaKey('辻'))!.id,
        'custom:tsuji-ivs',
      );
      expect(
        (await db.wordsDao.customWordByLemmaKey('葛'))!.id,
        'custom:kuzu-old',
      );
    },
  );

  test(
    'both duplicates have cards: logs move to survivor card; one card and SRS',
    () async {
      final env = await _v7(verifier);
      final older = _unix(DateTime.utc(2026, 1, 1));
      final newer = _unix(DateTime.utc(2026, 2, 1));
      final early = _unix(DateTime.utc(2026, 3, 1));
      final late = _unix(DateTime.utc(2026, 3, 20));

      await _word(
        env.old,
        id: 'custom:plain',
        seq: -1,
        lemma: '辻',
        note: 'plain',
        createdAt: older,
        state: WordState.learning,
      );
      await _word(
        env.old,
        id: 'custom:ivs',
        seq: -2,
        lemma: '辻$_ivs',
        note: 'ivs',
        createdAt: newer,
        state: WordState.learning,
      );
      await _card(
        env.old,
        id: 'card-plain',
        wordId: 'custom:plain',
        createdAt: older,
        repetitions: 1,
        ratedAt: early,
        logId: 'log-plain',
      );
      await _card(
        env.old,
        id: 'card-ivs',
        wordId: 'custom:ivs',
        createdAt: newer,
        repetitions: 4,
        ratedAt: late,
        logId: 'log-ivs',
      );
      await env.old.close();

      final db = await _migrate(verifier, env.schema);
      expect((await db.select(db.userWords).get()).single.id, 'custom:ivs');

      final cards = await db.select(db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, 'card-ivs');
      expect(cards.single.wordId, 'custom:ivs');

      final srs = await db.select(db.userCardSrs).get();
      expect(srs, hasLength(1));
      expect(srs.single.cardId, 'card-ivs');
      expect(srs.single.repetitions, 4);

      final logs = await db.select(db.userReviewLogs).get();
      expect(logs.map((row) => row.id).toSet(), {'log-plain', 'log-ivs'});
      expect({for (final log in logs) log.cardId}, {'card-ivs'});
    },
  );

  test('only the loser has a card: word_id is rewritten to the survivor', () async {
    final env = await _v7(verifier);
    final older = _unix(DateTime.utc(2026, 1, 1));
    final newer = _unix(DateTime.utc(2026, 2, 1));

    await _word(
      env.old,
      id: 'custom:plain',
      seq: -1,
      lemma: '辻',
      note: 'plain',
      createdAt: older,
    );
    await _word(
      env.old,
      id: 'custom:ivs',
      seq: -2,
      lemma: '辻$_ivs',
      note: 'ivs',
      createdAt: newer,
    );
    await _card(
      env.old,
      id: 'card-loser',
      wordId: 'custom:ivs',
      createdAt: newer,
    );
    await env.old.close();

    final db = await _migrate(verifier, env.schema);
    expect((await db.select(db.userWords).get()).single.id, 'custom:plain');

    final cards = await db.select(db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, 'card-loser');
    expect(cards.single.wordId, 'custom:plain');
    expect((await db.select(db.userCardSrs).get()).single.cardId, 'card-loser');
  });

  test('equal reps: most recent review_logs.rated_at is the survivor', () async {
    final env = await _v7(verifier);
    final older = _unix(DateTime.utc(2026, 1, 1));
    final newer = _unix(DateTime.utc(2026, 2, 1));
    final early = _unix(DateTime.utc(2026, 3, 1));
    final late = _unix(DateTime.utc(2026, 4, 1));

    await _word(
      env.old,
      id: 'custom:plain',
      seq: -1,
      lemma: '辻',
      note: 'plain',
      createdAt: older,
      state: WordState.learning,
    );
    await _word(
      env.old,
      id: 'custom:ivs',
      seq: -2,
      lemma: '辻$_ivs',
      note: 'ivs',
      createdAt: newer,
      state: WordState.learning,
    );
    await _card(
      env.old,
      id: 'card-plain',
      wordId: 'custom:plain',
      createdAt: older,
      repetitions: 2,
      ratedAt: late,
      logId: 'log-plain',
    );
    await _card(
      env.old,
      id: 'card-ivs',
      wordId: 'custom:ivs',
      createdAt: newer,
      repetitions: 2,
      ratedAt: early,
      logId: 'log-ivs',
    );
    await env.old.close();

    final db = await _migrate(verifier, env.schema);
    expect((await db.select(db.userWords).get()).single.id, 'custom:plain');
    expect((await db.select(db.userCards).get()).single.id, 'card-plain');
    expect(
      (await db.select(db.userReviewLogs).get()).map((row) => row.cardId).toSet(),
      {'card-plain'},
    );
  });
}

class _V7 {
  const _V7(this.schema, this.old);

  final InitializedSchema schema;
  final v7.DatabaseAtV7 old;
}

Future<_V7> _v7(SchemaVerifier verifier) async {
  final schema = await verifier.schemaAt(7);
  addTearDown(schema.close);
  final old = v7.DatabaseAtV7(schema.newConnection());
  final created = _unix(DateTime.utc(2026, 1, 1));
  await old
      .into(old.pages)
      .insert(
        v7.PagesCompanion.insert(id: 'page-1', sha256: 'abc', createdAt: created),
      );
  await old
      .into(old.crops)
      .insert(
        v7.CropsCompanion.insert(
          id: 'crop-1',
          pageId: 'page-1',
          ocrText: '辻',
          engineId: 'fake',
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          createdAt: created,
        ),
      );
  await old
      .into(old.crops)
      .insert(
        v7.CropsCompanion.insert(
          id: 'crop-2',
          pageId: 'page-1',
          ocrText: '辻$_ivs',
          engineId: 'fake',
          left: 0.1,
          top: 0.1,
          width: 0.5,
          height: 0.5,
          createdAt: created,
        ),
      );
  return _V7(schema, old);
}

Future<AppDatabase> _migrate(
  SchemaVerifier verifier,
  InitializedSchema schema,
) async {
  final db = AppDatabase(schema.newConnection());
  addTearDown(db.close);
  await verifier.migrateAndValidate(db, 8);
  await _expectNoFkViolations(db);
  return db;
}

Future<void> _expectNoFkViolations(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA foreign_key_check').get();
  expect(
    rows,
    isEmpty,
    reason: [for (final row in rows) row.data.toString()].join('; '),
  );
}

Future<void> _word(
  v7.DatabaseAtV7 db, {
  required String id,
  required int seq,
  required String lemma,
  required int createdAt,
  String? reading,
  String? note,
  WordState state = WordState.saved,
  bool custom = true,
}) async {
  await db
      .into(db.words)
      .insert(
        v7.WordsCompanion.insert(
          id: id,
          seq: seq,
          lemma: lemma,
          reading: reading ?? lemma,
          userNote: Value(note),
          createdAt: createdAt,
        ),
      );
  if (custom) {
    await db
        .into(db.wordStates)
        .insert(
          v7.WordStatesCompanion.insert(
            wordId: id,
            state: state.name,
            updatedAt: createdAt,
          ),
        );
  }
}

Future<void> _card(
  v7.DatabaseAtV7 db, {
  required String id,
  required String wordId,
  required int createdAt,
  int repetitions = 0,
  int dueAt = 0,
  int? ratedAt,
  String? logId,
}) async {
  await db
      .into(db.cards)
      .insert(
        v7.CardsCompanion.insert(
          id: id,
          wordId: wordId,
          kind: FlashcardKind.vocab.name,
          createdAt: createdAt,
        ),
      );
  await db
      .into(db.cardSrs)
      .insert(
        v7.CardSrsCompanion.insert(
          cardId: id,
          easeFactor: 2.5,
          intervalDays: repetitions == 0 ? 0 : 14,
          repetitions: repetitions,
          dueAt: dueAt == 0 ? createdAt : dueAt,
          phase: repetitions == 0 ? 'neu' : 'review',
          engineId: kSm2JrEngineId,
        ),
      );
  if (ratedAt != null) {
    await db
        .into(db.reviewLogs)
        .insert(
          v7.ReviewLogsCompanion.insert(
            id: logId ?? 'log-$id',
            cardId: id,
            ratedAt: ratedAt,
            rating: 3,
            quality: 4,
            engineId: kSm2JrEngineId,
            isDrill: 0,
          ),
        );
  }
}
