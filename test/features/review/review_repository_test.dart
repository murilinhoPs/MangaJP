import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/review/domain/study_day.dart';
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
      expect(
        await env.review.nextDue().then((c) => c?.cardId),
        'card-learn-early',
      );
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

  test(
    'each rating writes rating, quality, engine_id and is_drill=0',
    () async {
      const engine = Sm2JrEngine();
      for (final rating in ReviewRating.values) {
        final env = await _openRepo(now);
        try {
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
          expect(log.ratedAt.isAtSameMomentAs(now), isTrue);

          final srs = (await env.db.select(env.db.userCardSrs).get()).single;
          final expected = engine.schedule(prev, qualityFor(rating), now);
          expect(srs.easeFactor, expected.easeFactor);
          expect(srs.intervalDays, expected.intervalDays);
          expect(srs.repetitions, expected.repetitions);
          expect(srs.dueAt.isAtSameMomentAs(expected.dueAt), isTrue);
          expect(srs.phase, expected.phase.name);
          expect(srs.engineId, expected.engineId);

          final state =
              (await env.db.select(env.db.userWordStates).get()).single;
          expect(state.state, WordState.learning.name);
          expect(
            state.updatedAt.isAtSameMomentAs(DateTime.utc(2026, 1, 1)),
            isTrue,
          );
        } finally {
          await env.db.close();
        }
      }
    },
  );

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
    expect(srs.dueAt.isAtSameMomentAs(expected.dueAt), isTrue);
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

  test('dueQueue isDrill is true after a same study-day answer', () async {
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

    expect((await env.review.dueQueue()).single.isDrill, isFalse);
    await env.review.answer('card-eat', ReviewRating.again);
    expect((await env.review.dueQueue()).single.isDrill, isTrue);
  });

  test(
    'second answer on the same study-day is drill and does not change SRS',
    () async {
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
      final afterFirst = await _srsSnapshot(env.db);
      final expected = const Sm2JrEngine().schedule(prev, 4, now);
      expect(afterFirst.intervalDays, expected.intervalDays);
      expect(afterFirst.repetitions, expected.repetitions);
      expect(afterFirst.phase, expected.phase.name);

      env.clock.now = now.add(const Duration(seconds: 1));
      await env.review.answer('card-eat', ReviewRating.again);
      env.clock.now = now.add(const Duration(seconds: 2));
      await env.review.answer('card-eat', ReviewRating.hard);

      final logs = await _logs(env.db);
      expect(logs, hasLength(3));
      expect(logs[0].isDrill, 0);
      expect(logs[0].rating, 3);
      expect(logs[0].quality, 4);
      expect(logs[0].engineId, kSm2JrEngineId);
      expect(logs[1].isDrill, 1);
      expect(logs[1].rating, 1);
      expect(logs[1].quality, 0);
      expect(logs[1].engineId, kSm2JrEngineId);
      expect(logs[2].isDrill, 1);
      expect(logs[2].rating, 2);
      expect(logs[2].quality, 3);
      expect(await _srsSnapshot(env.db), afterFirst);
      expect(
        (await env.db.select(env.db.userWordStates).get()).single.state,
        WordState.learning.name,
      );
    },
  );

  test(
    '03:59 is drill after a same study-day answer; 04:00 schedules again',
    () async {
      final env = await _openRepo(StudyDay.instant(2026, 10, 4, 12));
      addTearDown(env.db.close);
      await _seedPair(
        env.db,
        id: 'eat',
        lemma: '食べる',
        phase: CardPhase.neu,
        dueAt: StudyDay.instant(2026, 10, 4, 12),
        state: WordState.learning,
      );
      final prev = (await env.review.nextDue())!.srs;

      await env.review.answer('card-eat', ReviewRating.good);
      final afterFirst = await _srsSnapshot(env.db);
      expect(
        afterFirst.intervalDays,
        const Sm2JrEngine()
            .schedule(prev, 4, StudyDay.instant(2026, 10, 4, 12))
            .intervalDays,
      );

      env.clock.now = StudyDay.instant(2026, 10, 5, 3, 59);
      await env.review.answer('card-eat', ReviewRating.again);
      expect(await _srsSnapshot(env.db), afterFirst);

      env.clock.now = StudyDay.instant(2026, 10, 5, 4);
      await env.review.answer('card-eat', ReviewRating.hard);
      final afterRollover = await _srsSnapshot(env.db);
      final expected = const Sm2JrEngine().schedule(
        CardSrsState(
          easeFactor: afterFirst.easeFactor,
          intervalDays: afterFirst.intervalDays,
          repetitions: afterFirst.repetitions,
          dueAt: afterFirst.dueAt,
          phase: CardPhase.values.byName(afterFirst.phase),
          engineId: afterFirst.engineId,
        ),
        3,
        StudyDay.instant(2026, 10, 5, 4),
      );
      expect(afterRollover.easeFactor, expected.easeFactor);
      expect(afterRollover.intervalDays, expected.intervalDays);
      expect(afterRollover.repetitions, expected.repetitions);
      expect(afterRollover.dueAt.isAtSameMomentAs(expected.dueAt), isTrue);
      expect(afterRollover.phase, expected.phase.name);
      expect(afterRollover.engineId, expected.engineId);

      final logs = await _logs(env.db);
      expect([for (final log in logs) log.isDrill], [0, 1, 0]);
      expect(
        logs[1].ratedAt.isAtSameMomentAs(StudyDay.instant(2026, 10, 5, 3, 59)),
        isTrue,
      );
      expect(
        logs[2].ratedAt.isAtSameMomentAs(StudyDay.instant(2026, 10, 5, 4)),
        isTrue,
      );
    },
  );

  test('first answer at exactly 04:00 is not drill', () async {
    final at0400 = StudyDay.instant(2026, 10, 5, 4);
    final env = await _openRepo(at0400);
    addTearDown(env.db.close);
    await _seedPair(
      env.db,
      id: 'eat',
      lemma: '食べる',
      phase: CardPhase.neu,
      dueAt: at0400,
    );

    await env.review.answer('card-eat', ReviewRating.easy);
    final log = (await env.db.select(env.db.userReviewLogs).get()).single;
    expect(log.isDrill, 0);
    expect(log.rating, 4);
    expect(log.quality, 5);
    final srs = await _srsSnapshot(env.db);
    expect(srs.repetitions, 1);
    expect(srs.phase, CardPhase.review.name);
  });

  test('fewer than 15 neu all enter the due queue', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    for (var i = 0; i < 5; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, i),
      );
    }

    final queue = await env.review.dueQueue();
    expect(queue, hasLength(5));
    expect(
      [for (final card in queue) card.cardId],
      ['card-new-0', 'card-new-1', 'card-new-2', 'card-new-3', 'card-new-4'],
    );
  });

  test('due queue takes at most 15 neu, oldest due first', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    for (var i = 0; i < 16; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, i),
      );
    }

    final queue = await env.review.dueQueue();
    expect(queue, hasLength(15));
    expect(
      [for (final card in queue) card.cardId],
      [for (var i = 0; i < 15; i++) 'card-new-$i'],
    );
  });

  test('first non-drill on a neu counts once; leftover neu stay out', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    for (var i = 0; i < 16; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, i),
      );
    }

    for (var i = 0; i < 15; i++) {
      await env.review.answer('card-new-$i', ReviewRating.good);
    }

    final queue = await env.review.dueQueue();
    expect(queue, isEmpty);
  });

  test('drill on a neu does not consume another new slot', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    for (var i = 0; i < 16; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, i),
      );
    }

    await env.review.answer('card-new-0', ReviewRating.again);
    env.clock.now = now.add(const Duration(seconds: 1));
    await env.review.answer('card-new-0', ReviewRating.again);
    env.clock.now = now.add(const Duration(seconds: 2));
    for (var i = 1; i < 15; i++) {
      await env.review.answer('card-new-$i', ReviewRating.good);
    }

    final queue = await env.review.dueQueue();
    expect([for (final card in queue) card.cardId], ['card-new-0']);
    expect(queue.single.srs.phase, CardPhase.learning);
    final logs = await _logs(env.db);
    expect(
      [
        for (final log in logs.where((log) => log.cardId == 'card-new-0'))
          log.isDrill,
      ],
      [0, 1],
    );
  });

  test(
    'learning, relearning and review still enter when the cap is full',
    () async {
      final env = await _openRepo(now);
      addTearDown(env.db.close);
      for (var i = 0; i < 16; i++) {
        await _seedPair(
          env.db,
          id: 'new-$i',
          lemma: '新$i',
          phase: CardPhase.neu,
          dueAt: DateTime.utc(2026, 10, 1, 0, i),
        );
      }
      await _seedPair(
        env.db,
        id: 'learn',
        lemma: '学ぶ',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 9, 8),
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
        id: 'review',
        lemma: '復習',
        phase: CardPhase.review,
        dueAt: DateTime.utc(2026, 9, 1),
      );

      for (var i = 0; i < 15; i++) {
        await env.review.answer('card-new-$i', ReviewRating.good);
      }

      final queue = await env.review.dueQueue();
      expect(
        [for (final card in queue) card.cardId],
        ['card-learn', 'card-relearn', 'card-review'],
      );
      expect(queue.map((c) => c.srs.phase), isNot(contains(CardPhase.neu)));
    },
  );

  test('answering a learning card does not consume a new slot', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);
    await _seedPair(
      env.db,
      id: 'learn',
      lemma: '学ぶ',
      phase: CardPhase.learning,
      dueAt: DateTime.utc(2026, 9, 8),
    );
    await _seedLog(
      env.db,
      cardId: 'card-learn',
      ratedAt: StudyDay.instant(2026, 10, 4, 12),
    );
    for (var i = 0; i < 16; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, i),
      );
    }

    await env.review.answer('card-learn', ReviewRating.good);

    final queue = await env.review.dueQueue();
    expect(
      [for (final card in queue) card.cardId],
      [for (var i = 0; i < 15; i++) 'card-new-$i'],
    );
  });

  test('after 04:00 leftover neu can enter again, up to 15', () async {
    final env = await _openRepo(StudyDay.instant(2026, 10, 4, 12));
    addTearDown(env.db.close);
    for (var i = 0; i < 20; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: StudyDay.instant(2026, 10, 4, 4),
      );
    }

    for (var i = 0; i < 15; i++) {
      await env.review.answer('card-new-$i', ReviewRating.good);
    }
    expect([
      for (final card in await env.review.dueQueue()) card.srs.phase,
    ], isNot(contains(CardPhase.neu)));

    env.clock.now = StudyDay.instant(2026, 10, 5, 3, 59);
    final beforeRollover = await env.review.dueQueue();
    expect([
      for (final card in beforeRollover) card.srs.phase,
    ], everyElement(CardPhase.review));
    expect([
      for (final card in beforeRollover) card.cardId,
    ], isNot(contains('card-new-15')));

    env.clock.now = StudyDay.instant(2026, 10, 5, 4);
    final afterRollover = await env.review.dueQueue();
    expect(
      [
        for (final card in afterRollover)
          if (card.srs.phase == CardPhase.neu) card.cardId,
      ],
      [for (var i = 15; i < 20; i++) 'card-new-$i'],
    );
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

  test('homeCounts is 0 due and 0 new when the queue is empty', () async {
    final env = await _openRepo(now);
    addTearDown(env.db.close);

    final counts = await env.review.homeCounts();
    expect(counts.due, 0);
    expect(counts.newToday, 0);
  });

  test(
    'homeCounts due is the non-neu queue; waiting neu are not newToday',
    () async {
      final env = await _openRepo(now);
      addTearDown(env.db.close);
      await _seedPair(
        env.db,
        id: 'learn',
        lemma: '学ぶ',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 9, 8),
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
        id: 'review',
        lemma: '復習',
        phase: CardPhase.review,
        dueAt: DateTime.utc(2026, 9, 1),
      );
      await _seedPair(
        env.db,
        id: 'new-0',
        lemma: '新0',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1),
      );
      await _seedPair(
        env.db,
        id: 'new-1',
        lemma: '新1',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, 1),
      );
      await _seedPair(
        env.db,
        id: 'later',
        lemma: '明日',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 10, 6),
      );
      await _seedPair(
        env.db,
        id: 'known',
        lemma: '既知',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 8, 1),
        suspendReason: WordState.known.name,
      );

      final counts = await env.review.homeCounts();
      expect(counts.due, 3);
      expect(counts.newToday, 0);
    },
  );

  test(
    'homeCounts newToday is first non-drill neu answers this study-day',
    () async {
      final env = await _openRepo(now);
      addTearDown(env.db.close);
      await _seedPair(
        env.db,
        id: 'learn',
        lemma: '学ぶ',
        phase: CardPhase.learning,
        dueAt: DateTime.utc(2026, 9, 8),
      );
      await _seedPair(
        env.db,
        id: 'new-0',
        lemma: '新0',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1),
      );
      await _seedPair(
        env.db,
        id: 'new-1',
        lemma: '新1',
        phase: CardPhase.neu,
        dueAt: DateTime.utc(2026, 10, 1, 0, 1),
      );

      await env.review.answer('card-new-0', ReviewRating.good);
      env.clock.now = now.add(const Duration(seconds: 1));
      await env.review.answer('card-new-1', ReviewRating.good);
      env.clock.now = now.add(const Duration(seconds: 2));
      await env.review.answer('card-new-0', ReviewRating.good);

      final counts = await env.review.homeCounts();
      expect(counts.newToday, 2);
      expect(counts.due, 1);
    },
  );

  test('homeCounts newToday resets at 04:00 America/Sao_Paulo', () async {
    final env = await _openRepo(StudyDay.instant(2026, 10, 4, 12));
    addTearDown(env.db.close);
    for (var i = 0; i < 3; i++) {
      await _seedPair(
        env.db,
        id: 'new-$i',
        lemma: '新$i',
        phase: CardPhase.neu,
        dueAt: StudyDay.instant(2026, 10, 4, 4),
      );
    }
    for (var i = 0; i < 3; i++) {
      await env.review.answer('card-new-$i', ReviewRating.good);
    }

    expect((await env.review.homeCounts()).newToday, 3);

    env.clock.now = StudyDay.instant(2026, 10, 5, 3, 59);
    expect((await env.review.homeCounts()).newToday, 3);

    env.clock.now = StudyDay.instant(2026, 10, 5, 4);
    expect((await env.review.homeCounts()).newToday, 0);
  });
}

class _Clock {
  _Clock(this.now);
  DateTime now;
}

class _Env {
  const _Env({required this.db, required this.review, required this.clock});

  final AppDatabase db;
  final ReviewRepository review;
  final _Clock clock;
}

Future<_Env> _openRepo(DateTime now) async {
  final db = AppDatabase(NativeDatabase.memory());
  final clock = _Clock(now);
  return _Env(
    db: db,
    review: ReviewRepository(db, clock: () => clock.now),
    clock: clock,
  );
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

Future<void> _seedLog(
  AppDatabase db, {
  required String cardId,
  required DateTime ratedAt,
  int isDrill = 0,
}) async {
  await db.cardsDao.insertLog(
    UserReviewLogsCompanion.insert(
      id: 'log-$cardId-${ratedAt.microsecondsSinceEpoch}',
      cardId: cardId,
      ratedAt: ratedAt,
      rating: 3,
      quality: 4,
      engineId: kSm2JrEngineId,
      isDrill: isDrill,
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

Future<List<ReviewLogRow>> _logs(AppDatabase db) async {
  final rows = await db.select(db.userReviewLogs).get();
  rows.sort((a, b) => a.ratedAt.compareTo(b.ratedAt));
  return rows;
}

Future<Set<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return {for (final row in rows) row.read<String>('name')};
}
