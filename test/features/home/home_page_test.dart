import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/review/domain/new_per_day.dart';
import 'package:manga_jp/features/review/domain/study_day.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../dictionary/bake_jmdict_fixture.dart';

class _Clock {
  _Clock(this.now);
  DateTime now;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('home_page_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  testWidgets('empty Revisar block stays visible and opens /review', (
    tester,
  ) async {
    await _openHome(tester, jmdictPath: jmdictPath);

    expect(find.byKey(HomeKeys.review), findsOneWidget);
    expect(find.text('Revisar'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, 'Due: 0');
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
      'Novos hoje: 0 de ${NewPerDay.limit}',
    );
    expect(find.text('Due + novos hoje — stub'), findsNothing);
    expect(find.text('Thumbs → /pages/:id — stub'), findsNothing);
    expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
    expect(find.text('Capturas recentes'), findsOneWidget);
    expect(find.byKey(HomeKeys.recentEmpty), findsOneWidget);
    expect(find.text('Nenhuma captura ainda.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(HomeKeys.review)).dy,
      lessThan(tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy),
    );
    _expectNoCardList(tester);
    _expectOutOfScopeStubs(tester);

    await tester.tap(find.byKey(HomeKeys.review));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(ReviewPage))).state.uri.path,
      '/review',
    );
    expect(find.byType(ReviewPage), findsOneWidget);
  });

  testWidgets('Revisar shows due (non-neu) and novos hoje; tap opens /review', (
    tester,
  ) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      cards: [
        _SeedCard(
          id: 'learn',
          lemma: '学ぶ',
          phase: CardPhase.learning,
          dueAt: DateTime.utc(2026, 9, 8),
        ),
        _SeedCard(
          id: 'relearn',
          lemma: '再',
          phase: CardPhase.relearning,
          dueAt: DateTime.utc(2026, 9, 10),
        ),
        _SeedCard(
          id: 'review',
          lemma: '復習',
          phase: CardPhase.review,
          dueAt: DateTime.utc(2026, 9, 1),
        ),
        _SeedCard(
          id: 'new-0',
          lemma: '新0',
          phase: CardPhase.neu,
          dueAt: DateTime.utc(2026, 10, 1),
        ),
        _SeedCard(
          id: 'later',
          lemma: '明日',
          phase: CardPhase.learning,
          dueAt: DateTime.utc(2026, 10, 6),
        ),
        _SeedCard(
          id: 'known',
          lemma: '既知',
          phase: CardPhase.learning,
          dueAt: DateTime.utc(2026, 8, 1),
          suspendReason: WordState.known.name,
        ),
      ],
    );

    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, 'Due: 3');
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
      'Novos hoje: 0 de 15',
    );
    _expectNoCardList(tester);

    await tester.tap(find.byKey(HomeKeys.review));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(ReviewPage))).state.uri.path,
      '/review',
    );
  });

  testWidgets('novos hoje counts introduced neu and resets at 04:00', (
    tester,
  ) async {
    final clock = _Clock(StudyDay.instant(2026, 10, 4, 12));
    final env = await _openHome(
      tester,
      jmdictPath: jmdictPath,
      clock: clock,
      cards: [
        for (var i = 0; i < 3; i++)
          _SeedCard(
            id: 'new-$i',
            lemma: '新$i',
            phase: CardPhase.neu,
            dueAt: StudyDay.instant(2026, 10, 4, 4),
          ),
      ],
      prepare: (review) async {
        for (var i = 0; i < 3; i++) {
          await review.answer('card-new-$i', ReviewRating.good);
        }
      },
    );

    expect(
      tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
      'Novos hoje: 3 de 15',
    );

    clock.now = StudyDay.instant(2026, 10, 5, 3, 59);
    await _pumpHome(tester, env);
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
      'Novos hoje: 3 de 15',
    );

    clock.now = StudyDay.instant(2026, 10, 5, 4);
    await _pumpHome(tester, env);
    expect(
      tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
      'Novos hoje: 0 de 15',
    );
    expect(find.byKey(HomeKeys.review), findsOneWidget);
  });

  testWidgets(
    'returning to Home after /review answers refreshes due and novos hoje',
    (tester) async {
      await _openHome(
        tester,
        jmdictPath: jmdictPath,
        cards: [
          _SeedCard(
            id: 'learn',
            lemma: '学ぶ',
            phase: CardPhase.learning,
            dueAt: DateTime.utc(2026, 9, 8),
            priorNonDrillAt: DateTime.utc(2026, 10, 4, 12),
          ),
          _SeedCard(
            id: 'new-0',
            lemma: '新0',
            phase: CardPhase.neu,
            dueAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      );

      expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, 'Due: 1');
      expect(
        tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
        'Novos hoje: 0 de 15',
      );

      await tester.tap(find.byKey(HomeKeys.review));
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(ReviewPage))).state.uri.path,
        '/review',
      );
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '学ぶ');

      await _revealAndRate(tester, ReviewRating.good);
      expect(tester.widget<Text>(find.byKey(ReviewKeys.lemma)).data, '新0');
      await _revealAndRate(tester, ReviewRating.good);
      expect(find.byKey(ReviewKeys.empty), findsOneWidget);

      const HomeRoute().go(tester.element(find.byType(ReviewPage)));
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
        '/home',
      );
      expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, 'Due: 0');
      expect(
        tester.widget<Text>(find.byKey(HomeKeys.newToday)).data,
        'Novos hoje: 1 de 15',
      );
      _expectNoCardList(tester);
    },
  );

  testWidgets(
    'empty Capturas recentes stays visible and does not open /pages',
    (tester) async {
      await _openHome(tester, jmdictPath: jmdictPath);

      expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
      expect(find.byKey(HomeKeys.recentEmpty), findsOneWidget);
      expect(find.text('Nenhuma captura ainda.'), findsOneWidget);
      expect(find.text('Capturas recentes'), findsOneWidget);
      expect(find.byKey(HomeKeys.review), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(HomeKeys.review)).dy,
        lessThan(tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy),
      );

      await tester.tap(find.text('Capturas recentes'));
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
        '/home',
      );
      expect(find.text('/pages — stub (M0.1)'), findsNothing);
    },
  );

  testWidgets('Capturas recentes shows 6 newest thumbs; tap opens /pages/:id', (
    tester,
  ) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      pages: [
        for (var i = 1; i <= 7; i++)
          _SeedPage(id: 'page-$i', createdAt: DateTime.utc(2026, 1, i)),
      ],
    );

    expect(find.byKey(HomeKeys.recentEmpty), findsNothing);
    expect(find.byKey(HomeKeys.recentThumb('page-7')), findsOneWidget);
    expect(find.byKey(HomeKeys.recentThumb('page-2')), findsOneWidget);
    expect(find.byKey(HomeKeys.recentThumb('page-1')), findsNothing);
    expect(_recentThumbIds(tester), [
      'page-7',
      'page-6',
      'page-5',
      'page-4',
      'page-3',
      'page-2',
    ]);
    expect(find.byKey(HomeKeys.review), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(HomeKeys.review)).dy,
      lessThan(tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy),
    );

    await tester.ensureVisible(find.byKey(HomeKeys.recentThumb('page-7')));
    await tester.tap(find.byKey(HomeKeys.recentThumb('page-7')));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/page-7',
    );
    expect(find.byType(PageDetailPage), findsOneWidget);
  });

  testWidgets('Revisar still opens /review when recent pages exist', (
    tester,
  ) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      pages: [_SeedPage(id: 'page-a', createdAt: DateTime.utc(2026, 2, 1))],
      cards: [
        _SeedCard(
          id: 'learn',
          lemma: '学ぶ',
          phase: CardPhase.learning,
          dueAt: DateTime.utc(2026, 9, 8),
        ),
      ],
    );

    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, 'Due: 1');
    expect(find.byKey(HomeKeys.recentThumb('page-a')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(HomeKeys.review)).dy,
      lessThan(tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy),
    );

    await tester.tap(find.byKey(HomeKeys.review));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(ReviewPage))).state.uri.path,
      '/review',
    );
  });

  testWidgets('returning to Home after a new page shows that thumb', (
    tester,
  ) async {
    final env = await _openHome(tester, jmdictPath: jmdictPath);
    expect(find.byKey(HomeKeys.recentEmpty), findsOneWidget);

    await env.db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'page-late',
        sha256: 'sha-late',
        createdAt: DateTime.utc(2026, 3, 1),
      ),
    );

    await tester.tap(find.byKey(HomeKeys.review));
    await tester.pumpAndSettle();
    const HomeRoute().go(tester.element(find.byType(ReviewPage)));
    await tester.pumpAndSettle();

    expect(find.byKey(HomeKeys.recentEmpty), findsNothing);
    expect(find.byKey(HomeKeys.recentThumb('page-late')), findsOneWidget);
  });
}

class _SeedPage {
  const _SeedPage({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;
}

class _SeedCard {
  const _SeedCard({
    required this.id,
    required this.lemma,
    required this.phase,
    required this.dueAt,
    this.suspendReason,
    this.priorNonDrillAt,
  });

  final String id;
  final String lemma;
  final CardPhase phase;
  final DateTime dueAt;
  final String? suspendReason;
  final DateTime? priorNonDrillAt;
}

class _Env {
  const _Env({
    required this.db,
    required this.review,
    required this.jmdictPath,
  });

  final AppDatabase db;
  final ReviewRepository review;
  final String jmdictPath;
}

Future<_Env> _openHome(
  WidgetTester tester, {
  required String jmdictPath,
  List<_SeedCard> cards = const [],
  List<_SeedPage> pages = const [],
  _Clock? clock,
  Future<void> Function(ReviewRepository review)? prepare,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  for (final page in pages) {
    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: page.id,
        sha256: 'sha-${page.id}',
        createdAt: page.createdAt,
      ),
    );
  }

  for (final card in cards) {
    await db
        .into(db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: card.id,
            seq: card.id.hashCode.abs(),
            lemma: card.lemma,
            reading: 'よみ',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db
        .into(db.userWordStates)
        .insert(
          UserWordStatesCompanion.insert(
            wordId: card.id,
            state: WordState.learning.name,
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
            intervalDays: card.phase == CardPhase.neu ? 0 : 6,
            repetitions: card.phase == CardPhase.neu ? 0 : 2,
            dueAt: card.dueAt,
            phase: card.phase.name,
            engineId: kSm2JrEngineId,
          ),
        );
    if (card.priorNonDrillAt != null) {
      await db.cardsDao.insertLog(
        UserReviewLogsCompanion.insert(
          id: 'log-${card.id}',
          cardId: 'card-${card.id}',
          ratedAt: card.priorNonDrillAt!,
          rating: 3,
          quality: 4,
          engineId: kSm2JrEngineId,
          isDrill: 0,
        ),
      );
    }
  }

  final reviewClock = clock ?? _Clock(DateTime.utc(2026, 10, 5, 12));
  final review = ReviewRepository(db, clock: () => reviewClock.now);
  if (prepare != null) {
    await prepare(review);
  }

  final env = _Env(db: db, review: review, jmdictPath: jmdictPath);
  await _pumpHome(tester, env);
  return env;
}

Future<void> _pumpHome(WidgetTester tester, _Env env) async {
  await tester.pumpWidget(
    MangaJpApp(
      key: UniqueKey(),
      overrides: [
        appDatabaseProvider.overrideWith((ref) => env.db),
        reviewRepositoryProvider.overrideWith((ref) => env.review),
        jmdictServiceProvider.overrideWith((ref) async {
          final service = JmdictService()..openFile(env.jmdictPath);
          ref.onDispose(service.close);
          return service;
        }),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void _expectNoCardList(WidgetTester tester) {
  expect(find.text('学ぶ'), findsNothing);
  expect(find.text('復習'), findsNothing);
  expect(find.text('新0'), findsNothing);
  expect(find.text('既知'), findsNothing);
  expect(find.byKey(ReviewKeys.lemma), findsNothing);
  expect(find.text('Intervalo'), findsNothing);
  expect(find.text('Resumo'), findsNothing);
}

void _expectOutOfScopeStubs(WidgetTester tester) {
  expect(find.text('Galeria'), findsOneWidget);
}

List<String> _recentThumbIds(WidgetTester tester) {
  return tester
      .widgetList(
        find.descendant(
          of: find.byKey(HomeKeys.recentCaptures),
          matching: find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('home-recent-thumb-');
          }),
        ),
      )
      .map((widget) {
        final key = widget.key! as ValueKey<String>;
        return key.value.substring('home-recent-thumb-'.length);
      })
      .toList();
}

Future<void> _revealAndRate(WidgetTester tester, ReviewRating rating) async {
  await tester.tap(find.byKey(ReviewKeys.reveal));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ReviewKeys.rating(rating)));
  await tester.pumpAndSettle();
}
