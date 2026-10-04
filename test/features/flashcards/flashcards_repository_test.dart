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

    expect(await db.appMetaDao.getValue('schema_version'), '4');
    final names = await _tableNames(db);
    expect(names, containsAll(<String>['cards', 'card_srs']));
    expect(await db.select(db.userCards).get(), isEmpty);
    expect(await db.select(db.userCardSrs).get(), isEmpty);
  });

  test('learn with no card sets learning and inserts golden initial SRS', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.saved);

    await env.cards.learn('eat');

    final state = (await env.db.select(env.db.userWordStates).get()).single;
    expect(state.state, WordState.learning.name);

    final card = (await env.db.select(env.db.userCards).get()).single;
    expect(card.wordId, 'eat');
    expect(card.kind, FlashcardKind.vocab.name);

    final srs = (await env.db.select(env.db.userCardSrs).get()).single;
    expect(srs.cardId, card.id);
    final initial = initialCardSrsState(srs.dueAt);
    expect(srs.easeFactor, initial.easeFactor);
    expect(srs.intervalDays, initial.intervalDays);
    expect(srs.repetitions, initial.repetitions);
    expect(srs.phase, CardPhase.neu.name);
    expect(srs.engineId, kSm2JrEngineId);
    expect(srs.intervalDays, isNot(1));
  });

  test('learn when a card exists does not duplicate or reset SRS', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.learning);
    final seeded = await _seedCard(
      env.db,
      wordId: 'eat',
      srs: _progressedSrs,
    );

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
    );

    await env.cards.learn('eat');

    final state = (await env.db.select(env.db.userWordStates).get()).single;
    expect(state.state, WordState.learning.name);
    expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

    final cards = await env.db.select(env.db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, seeded.cardId);
    expect(await _srsSnapshot(env.db), seeded.srs);
  });

  test('learn from ignored returns to learning without resetting SRS', () async {
    final env = await _openRepo();
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', state: WordState.ignored);
    final seeded = await _seedCard(
      env.db,
      wordId: 'eat',
      srs: _progressedSrs,
    );

    await env.cards.learn('eat');

    final state = (await env.db.select(env.db.userWordStates).get()).single;
    expect(state.state, WordState.learning.name);
    expect(state.updatedAt.isAfter(seeded.stateUpdatedAt), isTrue);

    final cards = await env.db.select(env.db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, seeded.cardId);
    expect(await _srsSnapshot(env.db), seeded.srs);
  });
}

const _progressedSrs = (
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
  final stateUpdatedAt = (await db.select(db.userWordStates).get())
      .single
      .updatedAt;
  return _SeededCard(
    cardId: cardId,
    createdAt: createdAt,
    stateUpdatedAt: stateUpdatedAt,
    srs: (
      easeFactor: srs.easeFactor,
      intervalDays: srs.intervalDays,
      repetitions: srs.repetitions,
      dueAt: dueAt,
      phase: srs.phase,
      engineId: srs.engineId,
    ),
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

Future<Set<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return {for (final row in rows) row.read<String>('name')};
}
