import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

void main() {
  final now = DateTime.utc(2026, 10, 5, 12);

  test('onCreate has review_logs and due_at on card_srs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.appMetaDao.getValue('schema_version'), '6');
    final tables = await _tableNames(db);
    expect(tables, contains('review_logs'));
    final columns = await db.customSelect('PRAGMA table_info(card_srs)').get();
    final names = {for (final row in columns) row.read<String>('name')};
    expect(names, contains('due_at'));
    expect(names, isNot(contains('due')));
    expect(names, isNot(contains('due_date')));
    final logColumns = await db
        .customSelect('PRAGMA table_info(review_logs)')
        .get();
    expect(
      {for (final row in logColumns) row.read<String>('name')},
      containsAll(<String>[
        'id',
        'card_id',
        'rated_at',
        'rating',
        'quality',
        'engine_id',
        'is_drill',
      ]),
    );
    expect(await db.select(db.userReviewLogs).get(), isEmpty);
  });

  test('due queue is empty when there are no unsuspended due cards', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    await _seedWord(env.db, id: 'eat', lemma: '食べる', reading: 'たべる', seq: 1);
    await _seedCard(
      env.db,
      cardId: 'future',
      wordId: 'eat',
      phase: CardPhase.review,
      dueAt: DateTime.utc(2026, 10, 6),
    );
    await _seedWord(env.db, id: 'known', lemma: '知る', reading: 'しる', seq: 2);
    await _seedCard(
      env.db,
      cardId: 'suspended',
      wordId: 'known',
      phase: CardPhase.learning,
      dueAt: DateTime.utc(2026, 10, 1),
      suspendReason: WordState.known.name,
    );

    expect(await env.review.dueQueue(), isEmpty);
    expect(await env.review.nextDue(), isNull);
  });

  test(
    'queue is learning/relearning, then review, then new; oldest due first',
    () async {
      final env = await _openRepo(now);
      addTearDown(env.db.close);

      await _seedPair(
        env.db,
        id: 'new-old',
        lemma: '新しい',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 8, 1),
      );
      await _seedPair(
        env.db,
        id: 'review-old',
        lemma: '復習',
        phase: CardPhase.review,
        dueAt: DateTime.utc(2026, 9, 1),
      );
      await _seedPair(
        env.db,
        id: 'review-new',
        lemma: '後',
        phase: CardPhase.review,
        dueAt: DateTime.utc(2026, 9, 20),
      );
      await _seedPair(
        env.db,
        id: 'learn-late',
        lemma: '学ぶ',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 9, 15),
      );
      await _seedPair(
        env.db,
        id: 'relearn',
        lemma: '再',
        phase: CardPhase.relearning,
        dueAt: DateTime.utc(2026, 9, 10),
      );
      await _seedPair(
        env.db,
        id: 'learn-early',
        lemma: '早い',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 9, 8),
      );
      await _seedPair(
        env.db,
        id: 'not-due',
        lemma: '明日',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 10, 6),
      );
      await _seedPair(
        env.db,
        id: 'suspended',
        lemma: '既知',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 8, 1),
        suspendReason: WordState.ignored.name,
      );

      final queue = await env.review.dueQueue();
      expect(
        [for (final card in queue) card.cardId],
        [
          'card-learn-early',
          'card-relearn',
          'card-learn-late',
          'card-review-old',
          'card-review-new',
          'card-new-old',
        ],
      );
      expect(queue.first.lemma, '早い');
      expect(await env.review.nextDue().then((c) => c?.cardId), 'card-learn-early');
    },
  );

  test('suspended cards never enter the queue', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    await _seedPair(
      env.db,
      id: 'open',
      lemma: '開',
      phase: CardPhase.review,
      dueAt: DateTime.utc(2026, 10, 1),
    );
    await _seedPair(
      env.db,
      id: 'known',
      lemma: '知',
      phase: CardPhase.learning,
      dueAt: DateTime.utc(2026, 9, 1),
      suspendReason: WordState.known.name,
    );
    await _seedPair(
      env.db,
      id: 'ignored',
      lemma: '無視',
      phase: CardPhase.relearning,
      dueAt: DateTime.utc(2026, 9, 1),
      suspendReason: WordState.ignored.name,
    );

    final queue = await env.review.dueQueue();
    expect(queue, hasLength(1));
    expect(queue.single.cardId, 'card-open');
  });

  test('each rating writes rating, quality, engine_id and is_drill=0', () async {
    const engine = Sm2JrEngine();
    for (final rating in ReviewRating.values) {
      final env = await _openRepo(now);
      addTearDown(env.db.close);
      await _seedPair(
        env.db,
        id: 'eat',
        lemma: '食べる',
        reading: 'たべる',
        seq: 1358280,
        phase: CardPhase.neu,
        dueAt: now,
        state: WordState.learning,
      );
      final prev = (await env.review.nextDue())!.srs;

      await env.review.answer('card-eat', rating);

      final log = (await env.db.select(env.db.userReviewLogs).get()).single;
      expect(log.cardId, 'card-eat');
      expect(log.rating, ratingFor(rating));
      expect(log.quality, qualityFor(rating));
      expect(log.engineId, kSm2JrEngineId);
      expect(log.isDrill, 0);
      expect(log.ratedAt, now);

      final srs = (await env.db.select(env.db.userCardSrs).get()).single;
      final expected = engine.schedule(prev, qualityFor(rating), now);
      expect(srs.easeFactor, expected.easeFactor);
      expect(srs.intervalDays, expected.intervalDays);
      expect(srs.repetitions, expected.repetitions);
      expect(srs.dueAt, expected.dueAt);
      expect(srs.phase, expected.phase.name);
      expect(srs.engineId, expected.engineId);

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.learning.name);
      expect(state.updatedAt, DateTime.utc(2026, 1, 1));
    }
  });

  test('answer updates SRS and log in the same transaction', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    await _seedPair(
      env.db,
      id: 'eat',
      lemma: '食べる',
      phase: CardPhase.neu,
      dueAt: now,
      state: WordState.learning,
    );
    final prev = (await env.review.nextDue())!.srs;

    await env.review.answer('card-eat', ReviewRating.good);

    expect(await env.db.select(env.db.userReviewLogs).get(), hasLength(1));
    final srs = (await env.db.select(env.db.userCardSrs).get()).single;
    final expected = const Sm2JrEngine().schedule(prev, 4, now);
    expect(srs.intervalDays, expected.intervalDays);
    expect(srs.repetitions, expected.repetitions);
    expect(srs.phase, CardPhase.review.name);
    expect(srs.dueAt, expected.dueAt);
  });

  test('answer does not promote word_state off learning', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    await _seedPair(
      env.db,
      id: 'eat',
      lemma: '食べる',
      phase: CardPhase.review,
      dueAt: DateTime.utc(2026, 10, 1),
      state: WordState.learning,
    );

    await env.review.answer('card-eat', ReviewRating.easy);
    await env.review.answer('card-eat', ReviewRating.again);

    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.learning.name,
    );
    expect(await env.db.select(env.db.userReviewLogs).get(), hasLength(2));
  });

  test('answer on a suspended card is a no-op', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    await _seedPair(
      env.db,
      id: 'eat',
      lemma: '食べる',
      phase: CardPhase.learning,
      dueAt: DateTime.utc(2026, 10, 1),
      state: WordState.known,
      suspendReason: WordState.known.name,
    );
    final srsBefore = await _srsSnapshot(env.db);

    await env.review.answer('card-eat', ReviewRating.good);

    expect(await env.db.select(env.db.userReviewLogs).get(), isEmpty);
    expect(await _srsSnapshot(env.db), srsBefore);
    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.known.name,
    );
  });
}

class _Env {
  const _Env({required this.db, required this.review});

  final AppDatabase db;
  final ReviewRepository review;
}

Future<_Env> _openRepo(DateTime now) async {
  final db = AppDatabase(NativeDatabase.memory());
  return _Env(db: db, review: ReviewRepository(db, clock: () => now));
}

Future<void> _seedPair(
  AppDatabase db, {
  required String id,
  required String lemma,
  required CardPhase phase,
  required DateTime dueAt,
  String reading = 'よみ',
  int? seq,
  WordState state = WordState.learning,
  String? suspendReason,
}) async {
  await _seedWord(
    db,
    id: id,
    lemma: lemma,
    reading: reading,
    seq: seq ?? id.hashCode.abs(),
    state: state,
  );
  await _seedCard(
    db,
    cardId: 'card-$id',
    wordId: id,
    phase: phase,
    dueAt: dueAt,
    suspendReason: suspendReason,
  );
}

Future<void> _seedWord(
  AppDatabase db, {
  required String id,
  required String lemma,
  required String reading,
  required int seq,
  WordState state = WordState.learning,
}) async {
  final createdAt = DateTime.utc(2026, 1, 1);
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

Future<void> _seedCard(
  AppDatabase db, {
  required String cardId,
  required String wordId,
  required CardPhase phase,
  required DateTime dueAt,
  String? suspendReason,
}) async {
  await db
      .into(db.userCards)
      .insert(
        UserCardsCompanion.insert(
          id: cardId,
          wordId: wordId,
          kind: FlashcardKind.vocab.name,
          createdAt: DateTime.utc(2026, 2, 1),
          suspendReason: Value(suspendReason),
        ),
      );
  await db
      .into(db.userCardSrs)
      .insert(
        UserCardSrsCompanion.insert(
          cardId: cardId,
          easeFactor: kDefaultEaseFactor,
          intervalDays: phase == CardPhase.neu ? 0 : 6,
          repetitions: phase == CardPhase.neu ? 0 : 2,
          dueAt: dueAt,
          phase: phase.name,
          engineId: kSm2JrEngineId,
        ),
      );
}

typedef _SrsSnapshot = ({
  double easeFactor,
  double intervalDays,
  int repetitions,
  DateTime dueAt,
  String phase,
  String engineId,
});

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
