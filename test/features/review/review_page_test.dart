import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/review/domain/review_labels.dart';
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

  test('DS rating intervals match tokens.json srs.*.interval', () {
    expect(ReviewLabels.interval(ReviewRating.again), 'agora');
    expect(ReviewLabels.interval(ReviewRating.hard), '10 min');
    expect(ReviewLabels.interval(ReviewRating.good), '1 dia');
    expect(ReviewLabels.interval(ReviewRating.easy), '4 dias');
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
    expect(find.byKey(ReviewKeys.done), findsNothing);
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
    expect(find.byKey(ReviewKeys.done), findsNothing);
    expect(find.text('食べる'), findsNothing);
    _expectNoOutOfScopeControls(tester);
  });

  testWidgets(
    'front is the lemma; Mostrar shows reading and fixture JMdict gloss',
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
      expect(find.text(ReviewLabels.errei), findsOneWidget);
      expect(find.text(ReviewLabels.dificil), findsOneWidget);
      expect(find.text(ReviewLabels.bom), findsOneWidget);
      expect(find.text(ReviewLabels.facil), findsOneWidget);
      expect(find.text('Again'), findsNothing);
      expect(find.text('Hard'), findsNothing);
      expect(find.text('Good'), findsNothing);
      expect(find.text('Easy'), findsNothing);
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
      expect(ratingSide(ReviewRating.again)?.color, AppColors.border);
      expect(ratingFill(ReviewRating.again), AppColors.surface);
      expect(ratingSide(ReviewRating.hard)?.color, AppColors.border);
      expect(ratingFill(ReviewRating.hard), AppColors.surface);
      expect(ratingSide(ReviewRating.good)?.color, AppColors.mint);
      expect(ratingFill(ReviewRating.good), AppColors.srsBomFill);
      expect(ratingSide(ReviewRating.easy)?.color, AppColors.border);
      expect(ratingFill(ReviewRating.easy), AppColors.surface);
      expect(find.byKey(ReviewKeys.note), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.again)))
            .data,
        ReviewLabels.interval(ReviewRating.again),
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.hard)))
            .data,
        ReviewLabels.interval(ReviewRating.hard),
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.good)))
            .data,
        ReviewLabels.interval(ReviewRating.good),
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.easy)))
            .data,
        ReviewLabels.interval(ReviewRating.easy),
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

    // Kana identical to the lemma is not repeated; the note is the back.
    expect(find.byKey(ReviewKeys.reading), findsNothing);
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
    'rating row uses DS interval captions, not live sm2-jr day counts',
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
        ReviewLabels.interval(ReviewRating.again),
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.hard)))
            .data,
        ReviewLabels.interval(ReviewRating.hard),
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.easy)))
            .data,
        ReviewLabels.interval(ReviewRating.easy),
      );
      expect(find.text('hoje'), findsNothing);
      expect(find.text('16 dias'), findsNothing);
    },
  );

  testWidgets('drill answer still shows DS interval captions', (tester) async {
    await _openReview(tester, jmdictPath: jmdictPath, cards: [_taberuCard]);

    await tester.tap(find.byKey(ReviewKeys.reveal));
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewKeys.interval(ReviewRating.good)), findsOneWidget);

    await tester.tap(find.byKey(ReviewKeys.rating(ReviewRating.again)));
    await tester.pumpAndSettle();

    expect(find.byKey(ReviewKeys.reveal), findsOneWidget);
    expect(find.byKey(ReviewKeys.interval(ReviewRating.again)), findsNothing);

    await tester.tap(find.byKey(ReviewKeys.reveal));
    await tester.pumpAndSettle();

    expect(find.byKey(ReviewKeys.rating(ReviewRating.again)), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.again)))
          .data,
      ReviewLabels.interval(ReviewRating.again),
    );
    expect(
      tester
          .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.good)))
          .data,
      ReviewLabels.interval(ReviewRating.good),
    );
    expect(find.text('hoje'), findsNothing);
  });

  testWidgets(
    'a card already answered this study-day still shows DS intervals',
    (tester) async {
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
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.again)))
            .data,
        ReviewLabels.interval(ReviewRating.again),
      );
      expect(
        tester
            .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.good)))
            .data,
        ReviewLabels.interval(ReviewRating.good),
      );
    },
  );

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
    expect(find.byKey(ReviewKeys.done), findsOneWidget);
    expect(find.byKey(ReviewKeys.empty), findsNothing);

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
      expect(find.byKey(ReviewKeys.done), findsOneWidget);
      expect(find.byKey(ReviewKeys.empty), findsNothing);

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
      expect(find.byKey(ReviewKeys.done), findsOneWidget);
      expect(find.byKey(ReviewKeys.empty), findsNothing);
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
      // Again left the card due now. Snapshot is empty → done + requeue,
      // extra neu stay capped out. Reload continues with 新14.
      expect(find.byKey(ReviewKeys.done), findsOneWidget);
      expect(
        find.text(kReviewRequeuedLabel.replaceAll('{n}', '1')),
        findsOneWidget,
      );
      expect(find.text('新15'), findsNothing);
      await tester.tap(find.byKey(ReviewKeys.reload));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '新14');
      expect(find.text('新15'), findsNothing);
    },
  );

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= 900;

    testWidgets('empty state uses DS card copy at $label', (tester) async {
      await _openReview(tester, jmdictPath: jmdictPath, size: size);

      expect(find.byKey(ReviewKeys.empty), findsOneWidget);
      expect(find.byKey(ReviewKeys.done), findsNothing);
      expect(find.text(ReviewLabels.empty), findsOneWidget);
      expect(find.text(ReviewLabels.emptyHint), findsOneWidget);
      expect(
        find.descendant(of: find.byType(ReviewPage), matching: find.text('復習')),
        findsOneWidget,
      );
      if (wide) {
        expect(find.byKey(ShellKeys.commandBar), findsOneWidget);
        expect(find.byKey(ShellKeys.taskDock), findsNothing);
      } else {
        expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
      }
    });

    testWidgets(
      'session card uses sheet-review radius and JP scale at $label',
      (tester) async {
        await _openReview(
          tester,
          jmdictPath: jmdictPath,
          cards: [_taberuCard],
          size: size,
        );

        expect(find.byKey(ReviewKeys.card), findsOneWidget);
        final material = tester.widget<Material>(find.byKey(ReviewKeys.card));
        final shape = material.shape! as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          BorderRadius.circular(AppRadius.sheetReview),
        );
        expect(shape.side.color, AppColors.border);
        expect(material.color, AppColors.surface);
        expect(
          tester.widget<Text>(find.byKey(ReviewKeys.lemma)).style?.fontSize,
          wide ? 120 : 72,
        );
        expect(
          tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
          ReviewLabels.restantes(1),
        );
        expect(find.text('Revelar'), findsNothing);
        expect(find.byKey(ReviewKeys.reveal), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        if (wide) {
          expect(find.text(ReviewLabels.mostrar), findsNWidgets(2));
          expect(find.byKey(ShellKeys.command('mostrar')), findsOneWidget);
          final bar = tester.widget<Material>(
            find
                .ancestor(
                  of: find.byKey(ShellKeys.command('mostrar')),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(bar.color, isNot(AppColors.overlayPrimaria));
          expect(bar.color, isNot(AppColors.coral));
          final shape = bar.shape! as RoundedRectangleBorder;
          expect(shape.side.color, AppColors.border);
          expect(shape.side.color, isNot(AppColors.coral));
          expect(find.text('Espaço'), findsOneWidget);
          final chip = tester.widget<Container>(
            find
                .ancestor(
                  of: find.text('Espaço'),
                  matching: find.byType(Container),
                )
                .first,
          );
          final chipBorder = (chip.decoration! as BoxDecoration).border!;
          expect(chipBorder.top.color, isNot(AppColors.coral));
        } else {
          expect(find.text(ReviewLabels.mostrar), findsOneWidget);
          expect(find.byKey(ShellKeys.command('mostrar')), findsNothing);
          expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(ShellKeys.taskDock),
              matching: find.text(ReviewLabels.mostrar),
            ),
            findsNothing,
          );
        }
      },
    );

    testWidgets(
      'revealed back is kana+meaning, DS intervals, Bom-only fill at $label',
      (tester) async {
        await _openReview(
          tester,
          jmdictPath: jmdictPath,
          cards: [_taberuCard],
          size: size,
        );
        await tester.tap(find.byKey(ReviewKeys.reveal));
        await tester.pumpAndSettle();

        expect(
          tester.widget<Text>(find.byKey(ReviewKeys.lemma)).style?.fontSize,
          wide ? 120 : 72,
        );
        expect(tester.widget<Text>(find.byKey(ReviewKeys.reading)).data, 'たべる');
        expect(find.text('食べる'), findsWidgets);
        final gloss = tester.widget<Text>(find.byKey(ReviewKeys.gloss)).data!;
        expect(gloss, contains('to eat'));

        expect(find.text(ReviewLabels.errei), findsOneWidget);
        expect(find.text(ReviewLabels.dificil), findsOneWidget);
        expect(find.text(ReviewLabels.bom), findsOneWidget);
        expect(find.text(ReviewLabels.facil), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.again)))
              .data,
          ReviewLabels.interval(ReviewRating.again),
        );
        expect(
          tester
              .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.hard)))
              .data,
          ReviewLabels.interval(ReviewRating.hard),
        );
        expect(
          tester
              .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.good)))
              .data,
          ReviewLabels.interval(ReviewRating.good),
        );
        expect(
          tester
              .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.easy)))
              .data,
          ReviewLabels.interval(ReviewRating.easy),
        );
        expect(find.text('hoje'), findsNothing);

        Color? ratingFill(ReviewRating rating) => tester
            .widget<FilledButton>(find.byKey(ReviewKeys.rating(rating)))
            .style
            ?.backgroundColor
            ?.resolve(const <WidgetState>{});
        BorderSide? ratingSide(ReviewRating rating) => tester
            .widget<FilledButton>(find.byKey(ReviewKeys.rating(rating)))
            .style
            ?.side
            ?.resolve(const <WidgetState>{});
        expect(ratingFill(ReviewRating.again), AppColors.surface);
        expect(ratingSide(ReviewRating.again)?.color, AppColors.border);
        expect(ratingFill(ReviewRating.hard), AppColors.surface);
        expect(ratingSide(ReviewRating.hard)?.color, AppColors.border);
        expect(ratingFill(ReviewRating.good), AppColors.srsBomFill);
        expect(ratingSide(ReviewRating.good)?.color, AppColors.mint);
        expect(ratingFill(ReviewRating.easy), AppColors.surface);
        expect(ratingSide(ReviewRating.easy)?.color, AppColors.border);
        expect(ratingFill(ReviewRating.again), isNot(AppColors.srsBomFill));
        expect(ratingFill(ReviewRating.again), isNot(AppColors.srsErreiFill));
        expect(
          tester
              .widget<Text>(find.byKey(ReviewKeys.interval(ReviewRating.again)))
              .style
              ?.color,
          AppColors.coralText,
        );

        final ratingHeight = tester
            .getSize(find.byKey(ReviewKeys.rating(ReviewRating.good)))
            .height;
        if (wide) {
          expect(ratingHeight, greaterThanOrEqualTo(AppTargets.min));
          expect(find.byKey(ShellKeys.taskDock), findsNothing);
          // Rail badge uses waiting (= remaining), so "1" is badge + keycap.
          expect(
            tester
                .widget<Text>(
                  find.descendant(
                    of: find.byKey(ShellKeys.reviewBadge),
                    matching: find.byType(Text),
                  ),
                )
                .data,
            '1',
          );
          expect(find.text('1'), findsNWidgets(2));
          expect(find.text('2'), findsOneWidget);
          expect(find.text('3'), findsOneWidget);
          expect(find.text('4'), findsOneWidget);
        } else {
          expect(ratingHeight, AppTargets.respostaReviewMobile);
          final goodBox = tester.getRect(
            find.byKey(ReviewKeys.rating(ReviewRating.good)),
          );
          final dockBox = tester.getRect(find.byKey(ShellKeys.taskDock));
          expect(goodBox.bottom, lessThanOrEqualTo(dockBox.top + 0.5));
          expect(find.text('1'), findsNothing);
          expect(find.text('2'), findsNothing);
          expect(find.text('3'), findsNothing);
          expect(find.text('4'), findsNothing);
        }
      },
    );

    testWidgets(
      'Good on the last snapshot card still due in DB keeps the session at $label',
      (tester) async {
        await _openReview(
          tester,
          jmdictPath: jmdictPath,
          cards: [_hayaiCard, _taberuCard],
          size: size,
          customizeDb: (db) async {
            await db.cardsDao.insertLog(
              UserReviewLogsCompanion.insert(
                id: 'log-early',
                cardId: 'card-early',
                ratedAt: _now,
                rating: 1,
                quality: 0,
                engineId: kSm2JrEngineId,
                isDrill: 0,
              ),
            );
          },
        );

        expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '早い');
        expect(
          tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
          ReviewLabels.restantes(2),
        );
        await _revealAndRate(tester, ReviewRating.good);
        expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '食べる');
        await _revealAndRate(tester, ReviewRating.good);

        expect(find.byKey(ReviewKeys.done), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
          ReviewLabels.restantes(1),
        );
        expect(
          find.text(kReviewRequeuedLabel.replaceAll('{n}', '1')),
          findsOneWidget,
        );
        if (wide) {
          expect(
            tester
                .widget<Text>(
                  find.descendant(
                    of: find.byKey(ShellKeys.reviewBadge),
                    matching: find.byType(Text),
                  ),
                )
                .data,
            '1',
          );
        }
        await tester.tap(find.byKey(ReviewKeys.reload));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '早い');
        expect(
          tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
          ReviewLabels.restantes(1),
        );
      },
    );

    testWidgets('Good leaves the session on the done state at $label', (
      tester,
    ) async {
      await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_taberuCard],
        size: size,
      );
      await _revealAndRate(tester, ReviewRating.good);

      expect(find.byKey(ReviewKeys.done), findsOneWidget);
      expect(find.byKey(ReviewKeys.empty), findsNothing);
      expect(find.text(ReviewLabels.done), findsOneWidget);
      expect(find.text(ReviewLabels.doneHint), findsOneWidget);
      expect(find.byKey(ReviewKeys.card), findsNothing);
    });

    testWidgets('2 remaining uses plural at $label', (tester) async {
      await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_hayaiCard, _fukushuCard],
        size: size,
      );
      expect(
        tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
        ReviewLabels.restantes(2),
      );
    });
  }

  testWidgets('Space reveals; 1–4 rate', (tester) async {
    await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [_taberuCard],
      size: _phone,
    );

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewKeys.reading), findsOneWidget);

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit3), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewKeys.done), findsOneWidget);
  });

  testWidgets('1 Again, 2 Hard, 4 Easy match the rating keys', (tester) async {
    await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [_hayaiCard, _fukushuCard],
      size: _phone,
    );

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isTrue);
    await tester.pumpAndSettle();
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit2), isTrue);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '復習');

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isTrue);
    await tester.pumpAndSettle();
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit4), isTrue);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '早い');

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isTrue);
    await tester.pumpAndSettle();
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit1), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewKeys.reveal), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '早い');
  });

  testWidgets('review shortcuts pass through when a TextField is focused', (
    tester,
  ) async {
    await _openReview(
      tester,
      jmdictPath: jmdictPath,
      cards: [_taberuCard],
      size: _desktop,
    );

    final probe = _insertReviewTypingProbe(tester);
    addTearDown(probe.remove);
    await tester.pump();
    final editable = find.descendant(
      of: find.byKey(_typingProbeKey),
      matching: find.byType(EditableText),
    );
    tester.state<EditableTextState>(editable).requestKeyboard();
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.space), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit1), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit2), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit3), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit4), isFalse);
    await tester.pumpAndSettle();

    expect(find.byKey(ReviewKeys.reveal), findsOneWidget);
    expect(find.byKey(ReviewKeys.reading), findsNothing);
    expect(find.byKey(ReviewKeys.done), findsNothing);
    expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '食べる');
  });
}

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);
const _typingProbeKey = Key('review-typing-probe');

OverlayEntry _insertReviewTypingProbe(WidgetTester tester) {
  final overlay = Overlay.of(tester.element(find.byType(ReviewPage)));
  final entry = OverlayEntry(
    builder: (context) {
      return const Align(
        alignment: Alignment.bottomLeft,
        child: SizedBox(
          width: 120,
          height: 40,
          child: Material(
            child: TextField(
              key: _typingProbeKey,
              decoration: InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  return entry;
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
  Size size = const Size(390, 844),
  Future<void> Function(ReviewRepository review)? prepare,
  Future<void> Function(AppDatabase db)? customizeDb,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
