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
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/review/domain/study_day.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../capture/fake_image_source_service.dart';
import '../capture/fixture_png.dart';
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
    expect(find.text('Revisar →'), findsOneWidget);
    expect(find.text('FILA DE HOJE'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '0');
    expect(find.text('cards esperando'), findsOneWidget);
    expect(find.text('0 novos'), findsOneWidget);
    expect(find.text('0 revisões'), findsOneWidget);
    expect(find.text('0 drill'), findsOneWidget);
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
    _expectGalleryBelowRecent(tester);

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

    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '4');
    expect(find.text('3 revisões'), findsOneWidget);
    expect(find.text('1 novos'), findsOneWidget);
    expect(find.text('0 drill'), findsOneWidget);
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

    expect((await env.review.homeCounts()).newToday, 3);
    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '0');

    clock.now = StudyDay.instant(2026, 10, 5, 3, 59);
    await _pumpHome(tester, env);
    expect((await env.review.homeCounts()).newToday, 3);

    clock.now = StudyDay.instant(2026, 10, 5, 4);
    await _pumpHome(tester, env);
    expect((await env.review.homeCounts()).newToday, 0);
    expect(find.byKey(HomeKeys.review), findsOneWidget);
  });

  testWidgets(
    'returning to Home after /review answers refreshes due and novos hoje',
    (tester) async {
      final env = await _openHome(
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

      expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '2');
      expect(find.text('1 revisões'), findsOneWidget);
      expect(find.text('1 novos'), findsOneWidget);

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
      expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '0');
      expect((await env.review.homeCounts()).newToday, 1);
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
    await tester.pumpAndSettle();
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

    expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '1');
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

  testWidgets('Galeria CTA sits under Capturas recentes', (tester) async {
    await _openHome(tester, jmdictPath: jmdictPath);

    expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
    expect(find.byKey(HomeKeys.gallery), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsOneWidget);
    expect(find.text('Import → /capture (crop → OCR)'), findsNothing);
    expect(find.byKey(HomeKeys.review), findsOneWidget);
    expect(find.text('Capturas recentes'), findsOneWidget);
    _expectGalleryBelowRecent(tester);
  });

  testWidgets('Galeria pick opens /capture crop with the image', (tester) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      source: FakeImageSourceService(
        galleryImage: IncomingImage(bytes: fixturePng()),
      ),
    );

    await tester.tap(find.byKey(HomeKeys.gallery));
    await tester.pumpAndSettle();

    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.text('Captura'), findsOneWidget);
    expect(find.text('Confirmar crop'), findsOneWidget);
    expect(find.byKey(CaptureKeys.pickGallery), findsNothing);
    expect(find.text('Caderno'), findsNothing);
    expect(
      GoRouter.of(tester.element(find.byType(CapturePage))).state.uri.path,
      '/capture',
    );
  });

  testWidgets('Galeria cancel stays on /home', (tester) async {
    final source = FakeImageSourceService();
    await _openHome(tester, jmdictPath: jmdictPath, source: source);

    await tester.tap(find.byKey(HomeKeys.gallery));
    await tester.pumpAndSettle();

    expect(source.galleryCalls, 1);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CapturePage), findsNothing);
    expect(find.byKey(HomeKeys.review), findsOneWidget);
    expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
      '/home',
    );
  });

  testWidgets(
    'queue card shows novos/revisões/drill counts in queue colors',
    (tester) async {
      await _openHome(
        tester,
        jmdictPath: jmdictPath,
        cards: [
          _SeedCard(
            id: 'rev',
            lemma: '残る',
            phase: CardPhase.review,
            dueAt: DateTime.utc(2026, 9, 1),
          ),
          _SeedCard(
            id: 'new-a',
            lemma: '新A',
            phase: CardPhase.neu,
            dueAt: DateTime.utc(2026, 10, 1),
          ),
          _SeedCard(
            id: 'new-b',
            lemma: '新B',
            phase: CardPhase.neu,
            dueAt: DateTime.utc(2026, 10, 1, 0, 1),
          ),
          _SeedCard(
            id: 'drill',
            lemma: 'ドリル',
            phase: CardPhase.learning,
            dueAt: DateTime.utc(2026, 9, 8),
            drillToday: true,
          ),
        ],
      );

      expect(tester.widget<Text>(find.byKey(HomeKeys.due)).data, '4');
      expect(find.text('2 novos'), findsOneWidget);
      expect(find.text('1 revisões'), findsOneWidget);
      expect(find.text('1 drill'), findsOneWidget);
      expect(_queueCountColor(tester, HomeKeys.novos), AppColors.violetText);
      expect(_queueCountColor(tester, HomeKeys.revisoes), AppColors.mint);
      expect(_queueCountColor(tester, HomeKeys.drill), AppColors.coral);
    },
  );

  testWidgets('Páginas recentes list tap opens /pages/:id', (tester) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      size: const Size(1280, 800),
      pages: [
        _SeedPage(
          id: 'page-a',
          createdAt: DateTime.utc(2026, 10, 5),
          ocrText: 'この町には、もう誰も残っていない。',
          crops: 3,
        ),
        _SeedPage(
          id: 'page-b',
          createdAt: DateTime.utc(2026, 10, 4),
          ocrText: '見せる',
          crops: 2,
        ),
      ],
    );

    expect(find.text('PÁGINAS RECENTES'), findsOneWidget);
    expect(find.byKey(HomeKeys.recentPage('page-a')), findsOneWidget);
    expect(find.textContaining('3 recortes'), findsOneWidget);

    await tester.tap(find.byKey(HomeKeys.recentPage('page-a')));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/page-a',
    );
  });

  testWidgets('Ajustes card opens /settings', (tester) async {
    await _openHome(tester, jmdictPath: jmdictPath);

    await tester.tap(find.byKey(ShellKeys.navCard('ajustes')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(SettingsPage))).state.uri.path,
      '/settings',
    );
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('/more redirects to /settings and Mais is gone', (tester) async {
    await _openHome(tester, jmdictPath: jmdictPath);
    final router = GoRouter.of(tester.element(find.byType(HomePage)));
    router.go('/more');
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/settings');
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Mais'), findsNothing);
    expect(find.text('/more'), findsNothing);
  });

  testWidgets('/pages list redirects to /home', (tester) async {
    await _openHome(tester, jmdictPath: jmdictPath);
    final router = GoRouter.of(tester.element(find.byType(HomePage)));
    router.go('/pages');
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/home');
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('/pages — stub (M0.1)'), findsNothing);
  });

  testWidgets('desktop 1 opens recent page; focused field swallows 1-3', (
    tester,
  ) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      size: const Size(1280, 800),
      pages: [
        _SeedPage(
          id: 'page-1',
          createdAt: DateTime.utc(2026, 10, 5),
          ocrText: '一文',
        ),
        _SeedPage(
          id: 'page-2',
          createdAt: DateTime.utc(2026, 10, 4),
          ocrText: '二文',
        ),
        _SeedPage(
          id: 'page-3',
          createdAt: DateTime.utc(2026, 10, 3),
          ocrText: '三文',
        ),
      ],
    );

    await tester.tap(find.byType(HomePage));
    await tester.pump();

    final probe = find.byKey(HomeKeys.typingProbe, skipOffstage: false);
    expect(probe, findsOneWidget);
    final editable = find.descendant(
      of: probe,
      matching: find.byType(EditableText),
      skipOffstage: false,
    );
    tester.state<EditableTextState>(editable).requestKeyboard();
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit1), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit2), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit3), isFalse);
    expect(
      GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
      '/home',
    );
    expect(find.byType(PageDetailPage), findsNothing);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byType(HomePage));
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit1), isTrue);
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/page-1',
    );
  });
}

Color? _queueCountColor(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(
    find.descendant(of: find.byKey(key), matching: find.byType(Text)),
  );
  final span = text.textSpan! as TextSpan;
  return (span.children!.first as TextSpan).style?.color;
}

class _SeedPage {
  const _SeedPage({
    required this.id,
    required this.createdAt,
    this.ocrText,
    this.crops = 0,
  });

  final String id;
  final DateTime createdAt;
  final String? ocrText;
  final int crops;
}

class _SeedCard {
  const _SeedCard({
    required this.id,
    required this.lemma,
    required this.phase,
    required this.dueAt,
    this.suspendReason,
    this.priorNonDrillAt,
    this.drillToday = false,
  });

  final String id;
  final String lemma;
  final CardPhase phase;
  final DateTime dueAt;
  final String? suspendReason;
  final DateTime? priorNonDrillAt;
  final bool drillToday;
}

class _Env {
  const _Env({
    required this.db,
    required this.review,
    required this.jmdictPath,
    required this.source,
  });

  final AppDatabase db;
  final ReviewRepository review;
  final String jmdictPath;
  final ImageSourceService source;
}

Future<_Env> _openHome(
  WidgetTester tester, {
  required String jmdictPath,
  List<_SeedCard> cards = const [],
  List<_SeedPage> pages = const [],
  ImageSourceService? source,
  _Clock? clock,
  Size size = const Size(390, 844),
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
    final cropCount = page.ocrText != null && page.crops == 0 ? 1 : page.crops;
    for (var i = 0; i < cropCount; i++) {
      await db.pagesDao.insertCrop(
        CapturedCropsCompanion.insert(
          id: 'crop-${page.id}-$i',
          pageId: page.id,
          ocrText: page.ocrText ?? '文',
          engineId: 'test',
          left: 0.1,
          top: 0.1,
          width: 0.4,
          height: 0.4,
          createdAt: page.createdAt,
        ),
      );
    }
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
    if (card.drillToday) {
      await db.cardsDao.insertLog(
        UserReviewLogsCompanion.insert(
          id: 'drill-${card.id}',
          cardId: 'card-${card.id}',
          ratedAt: DateTime.utc(2026, 10, 5, 11),
          rating: 1,
          quality: 0,
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

  final env = _Env(
    db: db,
    review: review,
    jmdictPath: jmdictPath,
    source: source ?? FakeImageSourceService(),
  );
  await _pumpHome(tester, env, size: size);
  return env;
}

Future<void> _pumpHome(
  WidgetTester tester,
  _Env env, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MangaJpApp(
      key: UniqueKey(),
      overrides: [
        appDatabaseProvider.overrideWith((ref) => env.db),
        reviewRepositoryProvider.overrideWith((ref) => env.review),
        imageSourceServiceProvider.overrideWith((ref) => env.source),
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
  expect(find.text('新0'), findsNothing);
  expect(find.text('既知'), findsNothing);
  expect(find.byKey(ReviewKeys.lemma), findsNothing);
  expect(find.text('Intervalo'), findsNothing);
  expect(find.text('Resumo'), findsNothing);
}

void _expectGalleryBelowRecent(WidgetTester tester) {
  expect(find.byKey(HomeKeys.gallery), findsOneWidget);
  expect(find.text('Galeria'), findsOneWidget);
  expect(find.text('Escolher da galeria'), findsOneWidget);
  expect(
    tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy,
    lessThan(tester.getTopLeft(find.byKey(HomeKeys.gallery)).dy),
  );
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
