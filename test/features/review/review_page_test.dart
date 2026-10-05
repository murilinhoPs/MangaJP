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
      await _openReview(
        tester,
        jmdictPath: jmdictPath,
        cards: [_taberuCard],
      );

      expect(
        GoRouter.of(tester.element(find.byType(ReviewPage))).state.uri.path,
        '/review',
      );
      expect(
        tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data,
        '食べる',
      );
      expect(find.byKey(ReviewKeys.reading), findsNothing);
      expect(find.byKey(ReviewKeys.gloss), findsNothing);
      expect(find.byKey(ReviewKeys.rating(ReviewRating.again)), findsNothing);
      expect(find.byKey(ReviewKeys.reveal), findsOneWidget);

      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(ReviewKeys.reading)).data,
        'たべる',
      );
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
      _expectNoOutOfScopeControls(tester);
    },
  );

  testWidgets(
    'Good writes rating 3 / quality 4, updates SRS, keeps learning',
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

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        reviewRepositoryProvider.overrideWith(
          (ref) => ReviewRepository(db, clock: () => _now),
        ),
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

void _expectNoOutOfScopeControls(WidgetTester tester) {
  expect(find.text('Drill'), findsNothing);
  expect(find.text('Remover palavra'), findsNothing);
  expect(find.text('Remover card'), findsNothing);
  expect(find.byType(DeckPage), findsNothing);
}
