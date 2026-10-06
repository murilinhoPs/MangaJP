import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/flashcards/data/flashcards_repository.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

void main() {
  test('onCreate has cards and card_srs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.appMetaDao.getValue('schema_version'), '7');
    final names = await _tableNames(db);
    expect(names, containsAll(<String>['cards', 'card_srs', 'review_logs']));
    expect(await db.select(db.userCards).get(), isEmpty);
    expect(await db.select(db.userCardSrs).get(), isEmpty);
    expect(await db.select(db.userReviewLogs).get(), isEmpty);
    final columns = await db.customSelect('PRAGMA table_info(cards)').get();
    expect({
      for (final row in columns) row.read<String>('name'),
    }, contains('suspend_reason'));
  });

  test(
    'learn with no card sets learning and inserts golden initial SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.saved);

      await env.cards.learn('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.learning.name);

      final card = (await env.db.select(env.db.userCards).get()).single;
      expect(card.wordId, 'eat');
      expect(card.kind, FlashcardKind.vocab.name);
      expect(card.suspendReason, isNull);

      final srs = (await env.db.select(env.db.userCardSrs).get()).single;
      expect(srs.cardId, card.id);
      final initial = initialCardSrsState(srs.dueAt);
      expect(srs.easeFactor, initial.easeFactor);
      expect(srs.intervalDays, initial.intervalDays);
      expect(srs.repetitions, initial.repetitions);
      expect(srs.phase, CardPhase.neu.name);
      expect(srs.engineId, kSm2JrEngineId);
      expect(srs.intervalDays, isNot(1));
    },
  );

  test('learn when a card exists does not duplicate or reset SRS', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.learning);
    final seeded = await _seedCard(env.db, wordId: 'eat', srs: _progressedSrs);

    await env.cards.learn('eat');
    await env.cards.learn('eat');

    final cards = await env.db.select(env.db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, seeded.cardId);
    expect(cards.single.createdAt, seeded.createdAt);

    final states = await env.db.select(env.db.userWordStates).get();
    expect(states, hasLength(1));
    expect(states.single.state, WordState.learning.name);
    expect(states.single.updatedAt, seeded.stateUpdatedAt);

    expect(await _srsSnapshot(env.db), seeded.srs);
  });

  test('learn from known returns to learning without resetting SRS', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.known);
    final seeded = await _seedCard(
      env.db,
      wordId: 'eat',
      srs: _progressedSrs,
      suspendReason: WordState.known.name,
    );

    await env.cards.learn('eat');

    final state = (await env.db.select(env.db.userWordStates).get()).single;
    expect(state.state, WordState.learning.name);
    expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

    final cards = await env.db.select(env.db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, seeded.cardId);
    expect(await _srsSnapshot(env.db), seeded.srs);
    expect(cards.single.suspendReason, isNull);
  });

  test(
    'learn from ignored returns to learning without resetting SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.ignored);
      final seeded = await _seedCard(
        env.db,
        wordId: 'eat',
        srs: _progressedSrs,
        suspendReason: WordState.ignored.name,
      );

      await env.cards.learn('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.learning.name);
      expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, seeded.cardId);
      expect(await _srsSnapshot(env.db), seeded.srs);
      expect(cards.single.suspendReason, isNull);
    },
  );

  test(
    'known with a card sets state and suspend_reason without touching SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.learning);
      final seeded = await _seedCard(
        env.db,
        wordId: 'eat',
        srs: _progressedSrs,
      );
      final tablesBefore = await _tableNames(env.db);

      await env.cards.markKnown('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.known.name);
      expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, seeded.cardId);
      expect(cards.single.createdAt, seeded.createdAt);
      expect(cards.single.suspendReason, WordState.known.name);
      expect(await _srsSnapshot(env.db), seeded.srs);
      expect(await env.db.select(env.db.userCardSrs).get(), hasLength(1));
      expect(await _tableNames(env.db), tablesBefore);
    },
  );

  test(
    'ignored with a card sets state and suspend_reason without touching SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.learning);
      final seeded = await _seedCard(
        env.db,
        wordId: 'eat',
        srs: _progressedSrs,
      );

      await env.cards.markIgnored('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.ignored.name);

      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, seeded.cardId);
      expect(cards.single.suspendReason, WordState.ignored.name);
      expect(await _srsSnapshot(env.db), seeded.srs);
    },
  );

  test(
    'known without a card only changes state and does not create a card',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.saved);

      await env.cards.markKnown('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.known.name);
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
    },
  );

  test(
    'ignored without a card only changes state and does not create a card',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.saved);

      await env.cards.markIgnored('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.ignored.name);
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
    },
  );

  test(
    'switching known to ignored updates suspend_reason and keeps SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.known);
      final seeded = await _seedCard(
        env.db,
        wordId: 'eat',
        srs: _progressedSrs,
        suspendReason: WordState.known.name,
      );

      await env.cards.markIgnored('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.ignored.name);
      expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, seeded.cardId);
      expect(cards.single.createdAt, seeded.createdAt);
      expect(cards.single.suspendReason, WordState.ignored.name);
      expect(await _srsSnapshot(env.db), seeded.srs);

      await env.cards.markKnown('eat');
      expect(
        (await env.db.select(env.db.userWordStates).get()).single.state,
        WordState.known.name,
      );
      expect(
        (await env.db.select(env.db.userCards).get()).single.suspendReason,
        WordState.known.name,
      );
      expect(await _srsSnapshot(env.db), seeded.srs);
      expect(await env.db.select(env.db.userCards).get(), hasLength(1));
    },
  );

  test(
    'second known tap is a no-op on state, suspend_reason, card, and SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.saved);
      final seeded = await _seedCard(
        env.db,
        wordId: 'eat',
        srs: _progressedSrs,
      );

      await env.cards.markKnown('eat');
      final afterFirst = await _studySnapshot(env.db);

      await env.cards.markKnown('eat');
      await env.cards.markKnown('eat');

      expect(await _studySnapshot(env.db), afterFirst);
      expect(afterFirst.state, WordState.known.name);
      expect(afterFirst.suspendReason, WordState.known.name);
      expect(afterFirst.cardId, seeded.cardId);
      expect(afterFirst.srs, seeded.srs);
    },
  );

  test(
    'second ignored tap is a no-op on state, suspend_reason, card, and SRS',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.saved);
      await _seedCard(env.db, wordId: 'eat', srs: _progressedSrs);

      await env.cards.markIgnored('eat');
      final afterFirst = await _studySnapshot(env.db);

      await env.cards.markIgnored('eat');

      expect(await _studySnapshot(env.db), afterFirst);
      expect(afterFirst.state, WordState.ignored.name);
      expect(afterFirst.suspendReason, WordState.ignored.name);
    },
  );

  test(
    'deleteCard with a card removes card and SRS and returns to saved',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.learning);
      final seeded = await _seedCard(
        env.db,
        wordId: 'eat',
        srs: _progressedSrs,
      );
      final tablesBefore = await _tableNames(env.db);

      await env.cards.deleteCard('eat');

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.saved.name);
      expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

      expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
      expect(await _tableNames(env.db), tablesBefore);
      expect(tablesBefore, contains('review_logs'));
      expect(await env.db.select(env.db.userReviewLogs).get(), isEmpty);
    },
  );

  test('deleteCard from known removes card, SRS, suspend_reason and returns to saved', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.known);
    await _seedCard(
      env.db,
      wordId: 'eat',
      srs: _progressedSrs,
      suspendReason: WordState.known.name,
    );

    await env.cards.deleteCard('eat');

    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.saved.name,
    );
    expect(await env.db.select(env.db.userCards).get(), isEmpty);
    expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
    expect((await env.db.select(env.db.userWords).get()), hasLength(1));
  });

  test(
    'deleteCard without a card does not delete the word or create a card',
    () async {
      final env = await _openRepo();
      addTearDown(env.db.close);
      await _seedWord(env.db, id: 'eat', state: WordState.known);
      final before = await _studySnapshot(env.db);

      await env.cards.deleteCard('eat');

      expect(await _studySnapshot(env.db), before);
      expect(before.state, WordState.known.name);
      expect(before.cardId, isNull);
      expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
    },
  );

  test('deleteCard on a missing word is a no-op', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.learning);
    await _seedCard(env.db, wordId: 'eat', srs: _progressedSrs);
    final before = await _studySnapshot(env.db);

    await env.cards.deleteCard('missing');

    expect(await _studySnapshot(env.db), before);
    expect(await env.db.select(env.db.userCards).get(), hasLength(1));
  });

  test('deleteCard leaves a second word card and SRS untouched', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.learning);
    await _seedCard(env.db, wordId: 'eat', srs: _progressedSrs);
    await env.db
        .into(env.db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: 'drink',
            seq: 1358300,
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

    await env.cards.deleteCard('eat');

    expect(await env.db.select(env.db.userWords).get(), hasLength(2));
    final leftover = (await env.db.select(env.db.userCards).get()).single;
    expect(leftover.id, 'card-drink');
    expect(leftover.wordId, 'drink');
    final leftoverSrs = (await env.db.select(env.db.userCardSrs).get()).single;
    expect(leftoverSrs.cardId, 'card-drink');
    expect(leftoverSrs.intervalDays, 7);
  });

  test('deleteCard drops review_logs for that card only', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.learning);
    await _seedCard(env.db, wordId: 'eat', srs: _progressedSrs);
    await env.db
        .into(env.db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: 'drink',
            seq: 1358300,
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
            id: 'log-eat',
            cardId: 'card-eat',
            ratedAt: DateTime.utc(2026, 3, 1),
            rating: 3,
            quality: 4,
            engineId: kSm2JrEngineId,
            isDrill: 0,
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

    await env.cards.deleteCard('eat');

    final leftover = await env.db.select(env.db.userReviewLogs).get();
    expect(leftover, hasLength(1));
    expect(leftover.single.id, 'log-drink');
    expect(leftover.single.cardId, 'card-drink');
    expect(await env.db.select(env.db.userCards).get(), hasLength(1));
    expect(
      (await env.db.select(env.db.userCards).get()).single.id,
      'card-drink',
    );
    expect(await _tableNames(env.db), contains('review_logs'));
  });
}

final _progressedSrs = (
  easeFactor: 2.36,
  intervalDays: 14.0,
  repetitions: 3,
  dueAt: DateTime.utc(2026, 6, 15),
  phase: 'review',
  engineId: kSm2JrEngineId,
);

class _Env {
  const _Env({required this.db, required this.cards});

  final AppDatabase db;
  final FlashcardsRepository cards;
}

class _SeededCard {
  const _SeededCard({
    required this.cardId,
    required this.createdAt,
    required this.stateUpdatedAt,
    required this.srs,
  });

  final String cardId;
  final DateTime createdAt;
  final DateTime stateUpdatedAt;
  final _SrsSnapshot srs;
}

typedef _SrsSnapshot = ({
  double easeFactor,
  double intervalDays,
  int repetitions,
  DateTime dueAt,
  String phase,
  String engineId,
});

Future<_Env> _openRepo() async {
  final db = AppDatabase(NativeDatabase.memory());
  return _Env(db: db, cards: FlashcardsRepository(db));
}

Future<void> _seedWord(
  AppDatabase db, {
  required String id,
  required WordState state,
}) async {
  final createdAt = DateTime.utc(2026, 1, 1);
  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: id,
          seq: 1358280,
          lemma: '食べる',
          reading: 'たべる',
          createdAt: createdAt,
        ),
      );
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

Future<_SeededCard> _seedCard(
  AppDatabase db, {
  required String wordId,
  required ({
    double easeFactor,
    double intervalDays,
    int repetitions,
    DateTime dueAt,
    String phase,
    String engineId,
  })
  srs,
  String? suspendReason,
}) async {
  const cardId = 'card-eat';
  final createdAt = DateTime.utc(2026, 2, 1);
  final dueAt = srs.dueAt;
  await db
      .into(db.userCards)
      .insert(
        UserCardsCompanion.insert(
          id: cardId,
          wordId: wordId,
          kind: FlashcardKind.vocab.name,
          createdAt: createdAt,
          suspendReason: Value(suspendReason),
        ),
      );
  await db
      .into(db.userCardSrs)
      .insert(
        UserCardSrsCompanion.insert(
          cardId: cardId,
          easeFactor: srs.easeFactor,
          intervalDays: srs.intervalDays,
          repetitions: srs.repetitions,
          dueAt: dueAt,
          phase: srs.phase,
          engineId: srs.engineId,
        ),
      );
  final card = (await db.select(db.userCards).get()).single;
  final persisted = await _srsSnapshot(db);
  final stateUpdatedAt =
      (await db.select(db.userWordStates).get()).single.updatedAt;
  return _SeededCard(
    cardId: card.id,
    createdAt: card.createdAt,
    stateUpdatedAt: stateUpdatedAt,
    srs: persisted,
  );
}

Future<_SrsSnapshot> _srsSnapshot(AppDatabase db) async {
  final row = (await db.select(db.userCardSrs).get()).single;
  return (
    easeFactor: row.easeFactor,
    intervalDays: row.intervalDays,
    repetitions: row.repetitions,
    dueAt: row.dueAt,
    phase: row.phase,
    engineId: row.engineId,
  );
}

typedef _StudySnapshot = ({
  String state,
  DateTime stateUpdatedAt,
  String? cardId,
  DateTime? cardCreatedAt,
  String? suspendReason,
  _SrsSnapshot? srs,
});

Future<_StudySnapshot> _studySnapshot(AppDatabase db) async {
  final state = (await db.select(db.userWordStates).get()).single;
  final cards = await db.select(db.userCards).get();
  final card = cards.isEmpty ? null : cards.single;
  return (
    state: state.state,
    stateUpdatedAt: state.updatedAt,
    cardId: card?.id,
    cardCreatedAt: card?.createdAt,
    suspendReason: card?.suspendReason,
    srs: card == null ? null : await _srsSnapshot(db),
  );
}

Future<Set<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return {for (final row in rows) row.read<String>('name')};
}
