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
    expect(await db.appMetaDao.getValue('schema_version'), '8');
  });

  test(
    'v7 IVS-duplicate custom words merge into one row with card, SRS and notes',
    () async {
      final schema = await verifier.schemaAt(7);
      addTearDown(schema.close);

      const ivsLemma = '辻$_ivs';
      final older = _unix(DateTime.utc(2026, 1, 1));
      final newer = _unix(DateTime.utc(2026, 2, 1));
      final reviewed = _unix(DateTime.utc(2026, 3, 15));
      final due = _unix(DateTime.utc(2026, 4, 1));

      final oldDb = v7.DatabaseAtV7(schema.newConnection());
      await oldDb
          .into(oldDb.pages)
          .insert(
            v7.PagesCompanion.insert(
              id: 'page-1',
              sha256: 'abc',
              createdAt: older,
            ),
          );
      await oldDb
          .into(oldDb.crops)
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
              createdAt: older,
            ),
          );
      await oldDb
          .into(oldDb.crops)
          .insert(
            v7.CropsCompanion.insert(
              id: 'crop-2',
              pageId: 'page-1',
              ocrText: ivsLemma,
              engineId: 'fake',
              left: 0.1,
              top: 0.1,
              width: 0.5,
              height: 0.5,
              createdAt: newer,
            ),
          );

      await oldDb
          .into(oldDb.words)
          .insert(
            v7.WordsCompanion.insert(
              id: 'custom:tsuji-plain',
              seq: -1,
              lemma: '辻',
              reading: '辻',
              userNote: const Value('plain note'),
              createdAt: older,
            ),
          );
      await oldDb
          .into(oldDb.words)
          .insert(
            v7.WordsCompanion.insert(
              id: 'custom:tsuji-ivs',
              seq: -2,
              lemma: ivsLemma,
              reading: ivsLemma,
              userNote: const Value('ivs note'),
              createdAt: newer,
            ),
          );
      await oldDb
          .into(oldDb.words)
          .insert(
            v7.WordsCompanion.insert(
              id: 'jmdict-taberu',
              seq: 1358280,
              lemma: '食べる',
              reading: 'たべる',
              createdAt: older,
            ),
          );
      await oldDb
          .into(oldDb.words)
          .insert(
            v7.WordsCompanion.insert(
              id: 'custom:kuzu-old',
              seq: -3,
              lemma: '葛',
              reading: '葛',
              userNote: const Value('same note'),
              createdAt: older,
            ),
          );
      await oldDb
          .into(oldDb.words)
          .insert(
            v7.WordsCompanion.insert(
              id: 'custom:kuzu-new',
              seq: -4,
              lemma: '葛$_ivs',
              reading: '葛$_ivs',
              userNote: const Value('same note'),
              createdAt: newer,
            ),
          );

      await oldDb
          .into(oldDb.wordStates)
          .insert(
            v7.WordStatesCompanion.insert(
              wordId: 'custom:tsuji-plain',
              state: WordState.saved.name,
              updatedAt: older,
            ),
          );
      await oldDb
          .into(oldDb.wordStates)
          .insert(
            v7.WordStatesCompanion.insert(
              wordId: 'custom:tsuji-ivs',
              state: WordState.learning.name,
              updatedAt: newer,
            ),
          );
      await oldDb
          .into(oldDb.wordStates)
          .insert(
            v7.WordStatesCompanion.insert(
              wordId: 'custom:kuzu-old',
              state: WordState.saved.name,
              updatedAt: older,
            ),
          );
      await oldDb
          .into(oldDb.wordStates)
          .insert(
            v7.WordStatesCompanion.insert(
              wordId: 'custom:kuzu-new',
              state: WordState.saved.name,
              updatedAt: newer,
            ),
          );

      await oldDb
          .into(oldDb.cropWords)
          .insert(
            v7.CropWordsCompanion.insert(
              cropId: 'crop-1',
              wordId: 'custom:tsuji-plain',
              createdAt: older,
            ),
          );
      await oldDb
          .into(oldDb.cropWords)
          .insert(
            v7.CropWordsCompanion.insert(
              cropId: 'crop-1',
              wordId: 'custom:tsuji-ivs',
              createdAt: newer,
            ),
          );
      await oldDb
          .into(oldDb.cropWords)
          .insert(
            v7.CropWordsCompanion.insert(
              cropId: 'crop-2',
              wordId: 'custom:tsuji-ivs',
              createdAt: newer,
            ),
          );

      await oldDb
          .into(oldDb.cards)
          .insert(
            v7.CardsCompanion.insert(
              id: 'card-tsuji-ivs',
              wordId: 'custom:tsuji-ivs',
              kind: FlashcardKind.vocab.name,
              createdAt: newer,
            ),
          );
      await oldDb
          .into(oldDb.cardSrs)
          .insert(
            v7.CardSrsCompanion.insert(
              cardId: 'card-tsuji-ivs',
              easeFactor: 2.36,
              intervalDays: 14,
              repetitions: 5,
              dueAt: due,
              phase: 'review',
              engineId: kSm2JrEngineId,
            ),
          );
      await oldDb
          .into(oldDb.reviewLogs)
          .insert(
            v7.ReviewLogsCompanion.insert(
              id: 'log-tsuji-ivs',
              cardId: 'card-tsuji-ivs',
              ratedAt: reviewed,
              rating: 3,
              quality: 4,
              engineId: kSm2JrEngineId,
              isDrill: 0,
            ),
          );
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 8);

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
      expect(
        links.map((row) => (row.cropId, row.wordId)).toSet(),
        {('crop-1', 'custom:tsuji-ivs'), ('crop-2', 'custom:tsuji-ivs')},
      );

      final cards = await db.select(db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, 'card-tsuji-ivs');
      expect(cards.single.wordId, 'custom:tsuji-ivs');

      final srs = (await db.select(db.userCardSrs).get()).single;
      expect(srs.cardId, 'card-tsuji-ivs');
      expect(srs.repetitions, 5);
      expect(srs.easeFactor, 2.36);
      expect(srs.intervalDays, 14);

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

      expect(await db.wordsDao.customWordByLemmaKey('辻'), isNotNull);
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
}
