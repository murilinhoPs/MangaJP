import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../dictionary/bake_jmdict_fixture.dart';

const _taberuSeq = 1358280;
final _now = DateTime.utc(2026, 10, 5, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('review_page_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  test('gloss is loaded from JMdict by seq, not stored or hardcoded', () {
    expect(JmdictService.assetPath, 'assets/dict/jmdict.sqlite');
    for (final path in [
      'lib/features/review/presentation/review_page.dart',
      'lib/features/review/presentation/review_controller.dart',
      'lib/features/review/data/review_repository.dart',
      'lib/features/review/domain/review_card.dart',
      'lib/core/database/tables/user_words.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src, isNot(contains('to eat')), reason: path);
      expect(src, isNot(contains('to live on')), reason: path);
    }
    expect(
      File('lib/core/database/tables/user_words.dart').readAsStringSync(),
      isNot(contains('gloss')),
    );
  });

  testWidgets('empty queue shows a message and does not throw', (tester) async {
    await _openReview(tester, jmdictPath: jmdictPath);

    expect(find.byType(ReviewPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byKey(ReviewKeys.empty), findsOneWidget);
    expect(find.text('Nenhum card para revisar.'), findsOneWidget);
    expect(find.byKey(ReviewKeys.lemma), findsNothing);
    expect(find.byKey(ReviewKeys.reveal), findsNothing);
    expect(find.text('/review — stub (M0.1)'), findsNothing);
    _expectNoOutOfScopeControls(tester);
  });

  testWidgets('suspended card is skipped and the queue stays empty', (
    tester,
  ) async {
    await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [
        (
          id: 'eat',
          lemma: '食べる',
          reading: 'たべる',
          seq: _taberuSeq,
          phase: CardPhase.learning,
          dueAt: DateTime.utc(2026, 10, 1),
          suspendReason: WordState.known.name,
          state: WordState.known,
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(ReviewKeys.empty), findsOneWidget);
    expect(find.text('食べる'), findsNothing);
    _expectNoOutOfScopeControls(tester);
  });

  testWidgets(
    'front is the lemma; Revelar shows reading and fixture JMdict gloss',
    (tester) async {
      await _openReview(tester, jmdictPath: jmdictPath, cards: [_taberuCard]);

      expect(
        GoRouter.of(tester.element(find.byType(ReviewPage))).state.uri.path,
        '/review',
      );
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '食べる');
      expect(find.byKey(ReviewKeys.reading), findsNothing);
      expect(find.byKey(ReviewKeys.gloss), findsNothing);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.again)), findsNothing);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.good)), findsNothing);
      expect(find.byKey(ReviewKeys.reveal), findsOneWidget);

      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(ReviewKeys.reading)).data, 'たべる');
      final gloss = tester.widget<Text>(find.byKey(ReviewKeys.gloss)).data!;
      final jmdict = JmdictService()..openFile(jmdictPath);
      addTearDown(jmdict.close);
      final entry = jmdict.entryBySeq(_taberuSeq)!;
      expect(gloss, entry.glossText);
      expect(gloss, contains('to eat'));
      expect(gloss, contains('to live on (e.g. a salary)'));
      final dataJson =
          jmdict.database.select(
                'SELECT data_json FROM entries WHERE seq = ?',
                [_taberuSeq],
              ).single['data_json']
              as String;
      for (final item in entry.glosses) {
        expect(dataJson, contains(item));
      }

      expect(find.byKey(ReviewKeys.rating(ReviewRating.again)), findsOneWidget);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.hard)), findsOneWidget);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.good)), findsOneWidget);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.easy)), findsOneWidget);
      BorderSide? ratingSide(ReviewRating rating) => tester
          .widget<FilledButton>(find.byKey(ReviewKeys.rating(rating)))
          .style
          ?.side
          ?.resolve(const <WidgetState>{});
      Color? ratingFill(ReviewRating rating) => tester
          .widget<FilledButton>(find.byKey(ReviewKeys.rating(rating)))
          .style
          ?.backgroundColor
          ?.resolve(const <WidgetState>{});
      expect(ratingSide(ReviewRating.again)?.color, AppColors.coral);
      expect(ratingFill(ReviewRating.again), AppColors.srsErreiFill);
      expect(ratingSide(ReviewRating.hard)?.color, AppColors.border);
      expect(ratingFill(ReviewRating.hard), AppColors.surface);
      expect(ratingSide(ReviewRating.good)?.color, AppColors.mint);
      expect(ratingFill(ReviewRating.good), AppColors.srsBomFill);
      expect(ratingSide(ReviewRating.easy)?.color, AppColors.border);
      expect(ratingFill(ReviewRating.easy), AppColors.surface);
      expect(find.byKey(ReviewKeys.note), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.good)))
            .data,
        '1 dia',
      );
      _expectNoOutOfScopeControls(tester);
    },
  );

  testWidgets('custom word Revelar shows user_note and no JMdict gloss', (
    tester,
  ) async {
    await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [
        (
          id: 'custom:piyo',
          lemma: 'ぴよ',
          reading: 'ぴよ',
          seq: -1,
          phase: CardPhase.neu,
          dueAt: null,
          suspendReason: null,
          state: WordState.learning,
        ),
      ],
      customizeDb: (db) async {
        await (db.update(
          db.userWords,
        )..where((t) => t.id.equals('custom:piyo'))).write(
          const UserWordsCompanion(userNote: Value('nome do personagem')),
        );
      },
    );

    expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, 'ぴよ');
    expect(find.byKey(ReviewKeys.note), findsNothing);

    await tester.tap(find.byKey(ReviewKeys.reveal));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(ReviewKeys.reading)).data, 'ぴよ');
    expect(find.byKey(ReviewKeys.gloss), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(ReviewKeys.note)).data,
      'nome do personagem',
    );
  });

  testWidgets(
    'revealing writes nothing; new card Good preview is 1 dia from sm2-jr@1',
    (tester) async {
      final env = await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_taberuCard],
      );
      final srsBefore = (await env.db.select(env.db.userCardSrs).get()).single;

      expect(find.byKey(ReviewKeys.interval(ReviewRating.good)), findsNothing);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.good)), findsNothing);

      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.good)))
            .data,
        '1 dia',
      );
      expect(await env.db.select(env.db.userReviewLogs).get(), isEmpty);
      final srsAfter = (await env.db.select(env.db.userCardSrs).get()).single;
      expect(srsAfter.easeFactor, srsBefore.easeFactor);
      expect(srsAfter.intervalDays, srsBefore.intervalDays);
      expect(srsAfter.repetitions, srsBefore.repetitions);
      expect(srsAfter.dueAt, srsBefore.dueAt);
      expect(srsAfter.phase, srsBefore.phase);
      expect(srsAfter.engineId, srsBefore.engineId);
    },
  );

  testWidgets(
    'interval 6 EF 2.5 shows Again hoje and Easy 16 dias from sm2-jr@1',
    (tester) async {
      await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_fukushuCard],
        customizeDb: (db) async {
          await (db.update(
            db.userCardSrs,
          )..where((t) => t.cardId.equals('card-review'))).write(
            const UserCardSrsCompanion(
              easeFactor: Value(2.5),
              intervalDays: Value(6),
              repetitions: Value(2),
              phase: Value('review'),
            ),
          );
        },
      );

      expect(find.byKey(ReviewKeys.interval(ReviewRating.again)), findsNothing);
      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.again)))
            .data,
        'hoje',
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.easy)))
            .data,
        '16 dias',
      );
    },
  );

  testWidgets(
    'drill answer (second same study-day) shows no interval preview',
    (tester) async {
      await _openReview(tester, jmdictPath: jmdictPath, cards: [_taberuCard]);

      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ReviewKeys.interval(ReviewRating.good)),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ReviewKeys.rating(ReviewRating.again)));
      await tester.pumpAndSettle();

      expect(find.byKey(ReviewKeys.reveal), findsOneWidget);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.again)), findsNothing);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.good)), findsNothing);

      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();

      expect(find.byKey(ReviewKeys.rating(ReviewRating.again)), findsOneWidget);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.again)), findsNothing);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.hard)), findsNothing);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.good)), findsNothing);
      expect(find.byKey(ReviewKeys.interval(ReviewRating.easy)), findsNothing);
      expect(find.text('hoje'), findsNothing);
      expect(find.text('1 dia'), findsNothing);
    },
  );

  testWidgets('a card already answered this study-day opens with no preview', (
    tester,
  ) async {
    await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [_taberuCard],
      customizeDb: (db) async {
        await db.cardsDao.insertLog(
          UserReviewLogsCompanion.insert(
            id: 'log-eat',
            cardId: 'card-eat',
            ratedAt: _now,
            rating: 1,
            quality: 0,
            engineId: kSm2JrEngineId,
            isDrill: 0,
          ),
        );
      },
    );

    await tester.tap(find.byKey(ReviewKeys.reveal));
    await tester.pumpAndSettle();

    expect(find.byKey(ReviewKeys.rating(ReviewRating.good)), findsOneWidget);
    expect(find.byKey(ReviewKeys.interval(ReviewRating.again)), findsNothing);
    expect(find.byKey(ReviewKeys.interval(ReviewRating.good)), findsNothing);
    expect(find.text('1 dia'), findsNothing);
  });

  testWidgets('Good writes rating 3 / quality 4, updates SRS, keeps learning', (
    tester,
  ) async {
    final env = await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [_taberuCard],
    );
    final prev = CardSrsState(
      easeFactor: kDefaultEaseFactor,
      intervalDays: 0,
      repetitions: 0,
      dueAt: _now,
      phase: CardPhase.neu,
      engineId: kSm2JrEngineId,
    );

    await tester.tap(find.byKey(ReviewKeys.reveal));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ReviewKeys.rating(ReviewRating.good)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(ReviewKeys.empty), findsOneWidget);

    final log = (await env.db.select(env.db.userReviewLogs).get()).single;
    expect(log.cardId, 'card-eat');
    expect(log.rating, 3);
    expect(log.quality, 4);
    expect(log.engineId, kSm2JrEngineId);
    expect(log.isDrill, 0);

    final expected = const Sm2JrEngine().schedule(prev, 4, log.ratedAt);
    final srs = (await env.db.select(env.db.userCardSrs).get()).single;
    expect(srs.easeFactor, expected.easeFactor);
    expect(srs.intervalDays, expected.intervalDays);
    expect(srs.repetitions, expected.repetitions);
    expect(srs.dueAt, expected.dueAt);
    expect(srs.phase, expected.phase.name);
    expect(srs.engineId, kSm2JrEngineId);

    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.learning.name,
    );
    _expectNoOutOfScopeControls(tester);
  });

  testWidgets(
    'Again puts the card at the back, resets the front, and the next tap is drill',
    (tester) async {
      final env = await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_taberuCard],
      );
      final prev = CardSrsState(
        easeFactor: kDefaultEaseFactor,
        intervalDays: 0,
        repetitions: 0,
        dueAt: _now,
        phase: CardPhase.neu,
        engineId: kSm2JrEngineId,
      );

      await _revealAndRate(tester, ReviewRating.again);

      expect(tester.takeException(), isNull);
      expect(find.byKey(ReviewKeys.empty), findsNothing);
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '食べる');
      expect(find.byKey(ReviewKeys.reveal), findsOneWidget);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.again)), findsNothing);

      await _revealAndRate(tester, ReviewRating.again);

      final logs = await env.db.select(env.db.userReviewLogs).get();
      expect(logs, hasLength(2));
      expect(logs[0].isDrill, 0);
      expect(logs[0].rating, 1);
      expect(logs[0].quality, 0);
      expect(logs[1].isDrill, 1);
      expect(logs[1].rating, 1);
      expect(logs[1].quality, 0);
      expect(logs[1].engineId, kSm2JrEngineId);

      final expected = const Sm2JrEngine().schedule(prev, 0, logs[0].ratedAt);
      final srs = (await env.db.select(env.db.userCardSrs).get()).single;
      expect(srs.easeFactor, expected.easeFactor);
      expect(srs.intervalDays, expected.intervalDays);
      expect(srs.repetitions, expected.repetitions);
      expect(srs.dueAt, expected.dueAt);
      expect(srs.phase, expected.phase.name);
      expect(
        (await env.db.select(env.db.userWordStates).get()).single.state,
        WordState.learning.name,
      );
    },
  );

  testWidgets(
    'Hard sends the card to the end; Good and Easy leave the session',
    (tester) async {
      final env = await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_hayaiCard, _fukushuCard],
      );

      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '早い');
      await _revealAndRate(tester, ReviewRating.hard);
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '復習');
      expect(find.byKey(ReviewKeys.reveal), findsOneWidget);

      await _revealAndRate(tester, ReviewRating.good);
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '早い');

      await _revealAndRate(tester, ReviewRating.easy);
      expect(find.byKey(ReviewKeys.empty), findsOneWidget);

      final logs = await env.db.select(env.db.userReviewLogs).get();
      expect(
        {for (final log in logs) (log.cardId, log.isDrill, log.rating)},
        {('card-early', 0, 2), ('card-review', 0, 3), ('card-early', 1, 4)},
      );
      final early = (await env.db.select(env.db.userCardSrs).get()).singleWhere(
        (row) => row.cardId == 'card-early',
      );
      final firstHard = logs.firstWhere(
        (log) => log.cardId == 'card-early' && log.isDrill == 0,
      );
      final expected = const Sm2JrEngine().schedule(
        CardSrsState(
          easeFactor: kDefaultEaseFactor,
          intervalDays: 0,
          repetitions: 0,
          dueAt: DateTime.utc(2026, 9, 1),
          phase: CardPhase.learning,
          engineId: kSm2JrEngineId,
        ),
        3,
        firstHard.ratedAt,
      );
      expect(early.easeFactor, expected.easeFactor);
      expect(early.intervalDays, expected.intervalDays);
      expect(early.repetitions, expected.repetitions);
      expect(early.dueAt.isAtSameMomentAs(expected.dueAt), isTrue);
      expect(early.phase, expected.phase.name);
    },
  );

  testWidgets(
    'after 15 new cards leftover neu stay out and due learning still shows',
    (tester) async {
      await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [
          for (var i = 0; i < 16; i++)
            (
              id: 'new-$i',
              lemma: '新$i',
              reading: 'よみ',
              seq: i + 10,
              phase: CardPhase.neu,
              dueAt: DateTime.utc(2026, 10, 1, 0, i),
              suspendReason: null,
              state: WordState.learning,
            ),
          (
            id: 'learn',
            lemma: '学ぶ',
            reading: 'まなぶ',
            seq: 100,
            phase: CardPhase.learning,
            dueAt: DateTime.utc(2026, 9, 8),
            suspendReason: null,
            state: WordState.learning,
          ),
        ],
        prepare: (review) async {
          for (var i = 0; i < 15; i++) {
            await review.answer('card-new-$i', ReviewRating.good);
          }
        },
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '学ぶ');
      expect(find.text('新15'), findsNothing);
      await _revealAndRate(tester, ReviewRating.good);
      expect(find.byKey(ReviewKeys.empty), findsOneWidget);
      expect(find.text('新15'), findsNothing);
      _expectNoOutOfScopeControls(tester);
    },
  );

  testWidgets(
    'a neu already in the session stays after the cap fills; extra neu never join',
    (tester) async {
      await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [
          for (var i = 0; i < 16; i++)
            (
              id: 'new-$i',
              lemma: '新$i',
              reading: 'よみ',
              seq: i + 10,
              phase: CardPhase.neu,
              dueAt: DateTime.utc(2026, 10, 1, 0, i),
              suspendReason: null,
              state: WordState.learning,
            ),
        ],
        prepare: (review) async {
          for (var i = 0; i < 14; i++) {
            await review.answer('card-new-$i', ReviewRating.good);
          }
        },
      );

      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '新14');
      await _revealAndRate(tester, ReviewRating.again);
      expect(tester.takeException(), isNull);
      expect(find.byKey(ReviewKeys.empty), findsNothing);
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '新14');
      expect(find.text('新15'), findsNothing);

      await _revealAndRate(tester, ReviewRating.good);
      expect(find.byKey(ReviewKeys.empty), findsOneWidget);
      expect(find.text('新15'), findsNothing);
    },
  );
}

const _taberuCard = (
  id: 'eat',
  lemma: '食べる',
  reading: 'たべる',
  seq: _taberuSeq,
  phase: CardPhase.neu,
  dueAt: null,
  suspendReason: null,
  state: WordState.learning,
);

final _hayaiCard = (
  id: 'early',
  lemma: '早い',
  reading: 'はやい',
  seq: 1,
  phase: CardPhase.learning,
  dueAt: DateTime.utc(2026, 9, 1),
  suspendReason: null,
  state: WordState.learning,
);

final _fukushuCard = (
  id: 'review',
  lemma: '復習',
  reading: 'ふくしゅう',
  seq: 2,
  phase: CardPhase.review,
  dueAt: DateTime.utc(2026, 9, 20),
  suspendReason: null,
  state: WordState.learning,
);

class _Env {
  const _Env({required this.db});

  final AppDatabase db;
}

typedef _SeedCard = ({
  String id,
  String lemma,
  String reading,
  int seq,
  CardPhase phase,
  DateTime? dueAt,
  String? suspendReason,
  WordState state,
});

Future<_Env> _openReview(
  WidgetTester tester, {
  required String jmdictPath,
  List<_SeedCard> cards = const [],
  Future<void> Function(ReviewRepository review)? prepare,
  Future<void> Function(AppDatabase db)? customizeDb,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  for (final card in cards) {
    await db
        .into(db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: card.id,
            seq: card.seq,
            lemma: card.lemma,
            reading: card.reading,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db
        .into(db.userWordStates)
        .insert(
          UserWordStatesCompanion.insert(
            wordId: card.id,
            state: card.state.name,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db
        .into(db.userCards)
        .insert(
          UserCardsCompanion.insert(
            id: 'card-${card.id}',
            wordId: card.id,
            kind: FlashcardKind.vocab.name,
            createdAt: DateTime.utc(2026, 2, 1),
            suspendReason: Value(card.suspendReason),
          ),
        );
    await db
        .into(db.userCardSrs)
        .insert(
          UserCardSrsCompanion.insert(
            cardId: 'card-${card.id}',
            easeFactor: kDefaultEaseFactor,
            intervalDays: 0,
            repetitions: 0,
            dueAt: card.dueAt ?? _now,
            phase: card.phase.name,
            engineId: kSm2JrEngineId,
          ),
        );
  }

  if (customizeDb != null) {
    await customizeDb(db);
  }

  final review = ReviewRepository(db, clock: () => _now);
  if (prepare != null) {
    await prepare(review);
  }

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        reviewRepositoryProvider.overrideWith((ref) => review),
        jmdictServiceProvider.overrideWith((ref) async {
          final service = JmdictService()..openFile(jmdictPath);
          ref.onDispose(service.close);
          return service;
        }),
      ],
    ),
  );
  await tester.pumpAndSettle();

  const ReviewRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  return _Env(db: db);
}

Future<void> _revealAndRate(WidgetTester tester, ReviewRating rating) async {
  await tester.tap(find.byKey(ReviewKeys.reveal));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ReviewKeys.rating(rating)));
  await tester.pumpAndSettle();
}

void _expectNoOutOfScopeControls(WidgetTester tester) {
  expect(find.text('Drill'), findsNothing);
  expect(find.text('Remover palavra'), findsNothing);
  expect(find.text('Remover card'), findsNothing);
  expect(find.text('Novos por dia'), findsNothing);
  expect(find.byType(DeckPage), findsNothing);
}
