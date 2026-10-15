import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:manga_jp/core/shell/kbd_chip.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/core/widgets/crop_number_badge.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/home/presentation/home_controller.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/presentation/review_controller.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/review/domain/new_per_day.dart';
import 'package:manga_jp/features/review/domain/review_labels.dart';
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
    expect(
      find.text('0 novos · limite ${NewPerDay.limit}/dia'),
      findsOneWidget,
    );
    expect(find.text('0 revisões'), findsOneWidget);
    expect(find.text('0 drill'), findsOneWidget);
    expect(find.text('Due + novos hoje — stub'), findsNothing);
    expect(find.text('Thumbs → /pages/:id — stub'), findsNothing);
    expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
    expect(find.text('Capturas recentes'), findsOneWidget);
    expect(find.byKey(HomeKeys.recentEmpty), findsOneWidget);
    expect(find.text('Nenhuma captura ainda.'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(HomeKeys.review)).dy,
      lessThan(tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy),
    );
    _expectNoCardList(tester);
    _expectGalleryHighlight(tester, wide: false);

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
    expect(
      find.text('1 novos · limite ${NewPerDay.limit}/dia'),
      findsOneWidget,
    );
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
      expect(
        find.text('1 novos · limite ${NewPerDay.limit}/dia'),
        findsOneWidget,
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
      expect(find.byKey(ReviewKeys.done), findsOneWidget);

      const HomeRoute().go(tester.element(find.byType(ReviewPage)));
      await tester.pumpAndSettle();
      expect(find.byKey(ReviewKeys.leaveDialog), findsNothing);
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
      expect(find.text('Nenhuma captura ainda.'), findsNothing);
      expect(find.text('Capturas recentes'), findsOneWidget);
      expect(find.byKey(HomeKeys.gallery), findsOneWidget);
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
    expect(find.text('/pages — stub (M0.1)'), findsNothing);
    expect(find.byKey(PageDetailKeys.back), findsOneWidget);
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
    expect(find.text('+ Nova da galeria'), findsOneWidget);
    expect(find.text('Galeria +'), findsOneWidget);
    expect(find.text('Galeria'), findsNothing);
    expect(find.text('Escolher da galeria'), findsNothing);
    expect(find.text('Import → /capture (crop → OCR)'), findsNothing);
    expect(find.byKey(HomeKeys.review), findsOneWidget);
    expect(find.text('Capturas recentes'), findsOneWidget);
    _expectGalleryHighlight(tester, wide: false);
  });

  testWidgets('Galeria pick opens /capture crop with the image', (
    tester,
  ) async {
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
    expect(find.byKey(CaptureKeys.page), findsOneWidget);
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

  testWidgets('queue card shows novos/revisões/drill counts in queue colors', (
    tester,
  ) async {
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
    expect(
      find.text('2 novos · limite ${NewPerDay.limit}/dia'),
      findsOneWidget,
    );
    expect(find.text('1 revisões'), findsOneWidget);
    expect(find.text('1 drill'), findsOneWidget);
    expect(_queueCountColor(tester, HomeKeys.novos), AppColors.violetText);
    expect(_queueCountColor(tester, HomeKeys.revisoes), AppColors.mint);
    expect(_queueCountColor(tester, HomeKeys.drill), AppColors.coral);
    expect(tester.getSize(find.byKey(HomeKeys.queueBar)).height, 8);
    expect(tester.getSize(_queueSeg(AppColors.violet)).width, greaterThan(8));
    expect(tester.getSize(_queueSeg(AppColors.mint)).width, greaterThan(8));
    expect(tester.getSize(_queueSeg(AppColors.coral)).width, greaterThan(8));
  });

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
          crops: 1,
        ),
      ],
    );

    expect(find.text('Capturas recentes'), findsOneWidget);
    expect(find.text('PÁGINAS RECENTES'), findsNothing);
    expect(find.byKey(HomeKeys.recentThumb('page-a')), findsOneWidget);
    expect(find.byKey(HomeKeys.gallery), findsOneWidget);
    expect(find.text('Galeria +'), findsOneWidget);

    await tester.tap(find.byKey(HomeKeys.recentThumb('page-a')));
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

  testWidgets('desktop 1 opens recent page; focused field swallows 1-3/R/', (
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

    expect(find.byKey(_typingProbeKey), findsNothing);
    final probe = _insertChromeTypingProbe(tester);
    await tester.pump();

    final editable = find.descendant(
      of: find.byKey(_typingProbeKey),
      matching: find.byType(EditableText),
    );
    expect(editable, findsOneWidget);
    tester.state<EditableTextState>(editable).requestKeyboard();
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit1), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit2), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit3), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyR), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyG), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.slash), isFalse);
    expect(
      GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
      '/home',
    );
    expect(find.byType(PageDetailPage), findsNothing);
    expect(find.byType(ReviewPage), findsNothing);

    probe.remove();
    await tester.pump();
    await tester.tap(find.text('para revisar'));
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.digit1), isTrue);
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/page-1',
    );
  });

  testWidgets('rail badge matches para revisar from the same counts', (
    tester,
  ) async {
    await _openHome(
      tester,
      jmdictPath: jmdictPath,
      size: const Size(1280, 800),
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

    final paraRevisar = tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(HomeKeys.due),
                matching: find.byType(Text),
              )
              .first,
        )
        .data;
    final badge = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(ShellKeys.reviewBadge),
            matching: find.byType(Text),
          ),
        )
        .data;
    expect(paraRevisar, '4');
    Color? desktopCountColor(Key key) {
      return tester
          .widget<Text>(
            find
                .descendant(of: find.byKey(key), matching: find.byType(Text))
                .first,
          )
          .style
          ?.color;
    }

    expect(desktopCountColor(HomeKeys.due), AppColors.text);
    expect(desktopCountColor(HomeKeys.novos), AppColors.violet);
    expect(desktopCountColor(HomeKeys.revisoes), AppColors.mint);
    expect(desktopCountColor(HomeKeys.drill), AppColors.coral);
    expect(_homeCountValue(tester, HomeKeys.novos), '2');
    expect(_homeCountValue(tester, HomeKeys.revisoes), '1');
    expect(_homeCountValue(tester, HomeKeys.drill), '1');
    expect(badge, paraRevisar);
  });

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= 900;

    testWidgets('Home due count matches Review remaining at $label', (
      tester,
    ) async {
      await _openHome(
        tester,
        jmdictPath: jmdictPath,
        size: size,
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

      final due = _homeDueCount(tester);
      expect(due, '4');
      expect(_homeCountValue(tester, HomeKeys.novos), '2');
      expect(_homeCountValue(tester, HomeKeys.revisoes), '1');
      expect(_homeCountValue(tester, HomeKeys.drill), '1');

      if (wide) {
        await tester.tap(find.byKey(ShellKeys.command('revisar')));
      } else {
        await tester.tap(find.byKey(HomeKeys.review));
      }
      await tester.pumpAndSettle();

      expect(find.byType(ReviewPage), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
        ReviewLabels.restantes(int.parse(due)),
      );
    });
  }

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= 900;

    testWidgets(
      'live waiting matches on Biblioteca, Leitor, Review and done at $label',
      (tester) async {
        const pageId = 'page-a';
        await _openHome(
          tester,
          jmdictPath: jmdictPath,
          size: size,
          pages: [
            _SeedPage(
              id: pageId,
              createdAt: DateTime.utc(2026, 10, 5),
              ocrText: '文',
              crops: 1,
            ),
          ],
          cards: [
            _SeedCard(
              id: 'learn',
              lemma: '学ぶ',
              phase: CardPhase.learning,
              dueAt: DateTime.utc(2026, 9, 7),
            ),
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
              id: 'drill',
              lemma: 'ドリル',
              phase: CardPhase.learning,
              dueAt: DateTime.utc(2026, 9, 8),
              drillToday: true,
            ),
          ],
        );

        void expectWaiting(int n) =>
            _expectLiveWaiting(tester, waiting: n, wide: wide);

        Future<void> openLeitor() async {
          final confirm = _reviewNeedsExitConfirm(tester);
          const PageDetailRoute(id: pageId).go(_shellContext(tester));
          await tester.pumpAndSettle();
          if (confirm) {
            await _confirmLeaveReview(tester);
          } else {
            expect(find.byKey(ReviewKeys.leaveDialog), findsNothing);
          }
          expect(find.byType(PageDetailPage), findsOneWidget);
        }

        Future<void> openHome() async {
          final confirm = _reviewNeedsExitConfirm(tester);
          const HomeRoute().go(_shellContext(tester));
          await tester.pumpAndSettle();
          if (confirm) {
            await _confirmLeaveReview(tester);
          } else {
            expect(find.byKey(ReviewKeys.leaveDialog), findsNothing);
          }
          expect(find.byType(HomePage), findsOneWidget);
        }

        Future<void> openReview() async {
          const ReviewRoute().go(_shellContext(tester));
          await tester.pumpAndSettle();
          expect(find.byType(ReviewPage), findsOneWidget);
        }

        final start = int.parse(_homeDueCount(tester));
        expect(start, 4);
        expectWaiting(start);

        await openLeitor();
        expectWaiting(start);

        await openReview();
        expectWaiting(start);

        await _revealAndRate(tester, ReviewRating.again);
        final afterErrei = _restantesCount(tester)!;
        expectWaiting(afterErrei);

        await openLeitor();
        expectWaiting(afterErrei);
        await openHome();
        expectWaiting(afterErrei);

        await openReview();
        await _revealAndRate(tester, ReviewRating.hard);
        expectWaiting(_restantesCount(tester)!);

        for (var i = 0; i < 16; i++) {
          if (find.byKey(ReviewKeys.done).evaluate().isNotEmpty) {
            break;
          }
          if (find.byKey(ReviewKeys.reveal).evaluate().isEmpty) {
            break;
          }
          await _revealAndRate(tester, ReviewRating.good);
          if (find.byKey(ReviewKeys.done).evaluate().isEmpty) {
            expectWaiting(_restantesCount(tester)!);
          }
        }

        expect(find.byKey(ReviewKeys.done), findsOneWidget);
        final leftover = _doneN(tester);
        expect(leftover, greaterThan(0));
        expectWaiting(leftover);
        await tester.tap(find.byKey(ReviewKeys.reload));
        await tester.pumpAndSettle();
        expect(find.byKey(ReviewKeys.done), findsNothing);
        expect(find.byKey(ReviewKeys.card), findsOneWidget);
        expectWaiting(leftover);

        await openLeitor();
        expectWaiting(leftover);
        await openHome();
        expectWaiting(leftover);

        await _openHome(
          tester,
          jmdictPath: jmdictPath,
          size: size,
          pages: [
            _SeedPage(
              id: pageId,
              createdAt: DateTime.utc(2026, 10, 5),
              ocrText: '文',
              crops: 1,
            ),
          ],
          cards: [
            _SeedCard(
              id: 'fin-rev',
              lemma: '町',
              phase: CardPhase.review,
              dueAt: DateTime.utc(2026, 9, 1),
            ),
            _SeedCard(
              id: 'fin-new',
              lemma: '誰',
              phase: CardPhase.neu,
              dueAt: DateTime.utc(2026, 10, 1),
            ),
          ],
        );
        expectWaiting(2);
        await openReview();
        expectWaiting(2);
        await _revealAndRate(tester, ReviewRating.hard);
        expectWaiting(_restantesCount(tester)!);
        await _revealAndRate(tester, ReviewRating.easy);
        if (find.byKey(ReviewKeys.reveal).evaluate().isNotEmpty) {
          await _revealAndRate(tester, ReviewRating.easy);
        }
        expect(find.byKey(ReviewKeys.done), findsOneWidget);
        expect(find.byKey(ReviewKeys.remaining), findsNothing);
        expectWaiting(0);
        await openHome();
        expectWaiting(0);
      },
    );
  }

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= 900;

    testWidgets('Home gallery highlight: order, tile, link, G at $label', (
      tester,
    ) async {
      await _openHome(
        tester,
        jmdictPath: jmdictPath,
        size: size,
        source: FakeImageSourceService(
          galleryImage: IncomingImage(bytes: fixturePng()),
        ),
        pages: [
          _SeedPage(
            id: 'page-a',
            createdAt: DateTime.utc(2026, 10, 5),
            ocrText: 'この町には、もう誰も残っていない。',
            crops: 1,
          ),
          _SeedPage(
            id: 'page-b',
            createdAt: DateTime.utc(2026, 10, 4),
            ocrText: '見せる',
            crops: 1,
          ),
          _SeedPage(
            id: 'page-c',
            createdAt: DateTime.utc(2026, 10, 3),
            ocrText: '残る',
            crops: 1,
          ),
        ],
        cards: [
          _SeedCard(
            id: 'drill',
            lemma: 'ドリル',
            phase: CardPhase.learning,
            dueAt: DateTime.utc(2026, 9, 8),
            drillToday: true,
          ),
        ],
      );

      _expectHomeOrder(tester, wide: wide);
      _expectGalleryHighlight(tester, wide: wide, badges: 3);
      expect(find.text('3 de 3'), findsNothing);
      expect(find.text('Escolher da galeria'), findsNothing);
      expect(find.text('Galeria'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Galeria'), findsNothing);
      expect(
        find.widgetWithText(FilledButton, '+ Nova da galeria'),
        findsNothing,
      );
      expect(find.widgetWithText(FilledButton, 'Galeria +'), findsNothing);

      if (!wide) {
        expect(
          tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy,
          lessThan(844),
        );
        expect(
          tester.getTopLeft(find.byKey(HomeKeys.gallery)).dy,
          lessThan(844),
        );
      }

      final galleryLeft = tester.getTopLeft(find.byKey(HomeKeys.gallery));
      final firstThumb = tester.getTopLeft(
        find.byKey(HomeKeys.recentThumb('page-a')),
      );
      expect(galleryLeft.dx, lessThanOrEqualTo(firstThumb.dx));
      if (galleryLeft.dx == firstThumb.dx) {
        expect(galleryLeft.dy, lessThan(firstThumb.dy));
      }

      if (wide) {
        expect(find.byKey(ShellKeys.command('revisar')), findsOneWidget);
        expect(find.byKey(ShellKeys.command('galeria')), findsOneWidget);
        expect(find.text('Abrir galeria'), findsOneWidget);
        expect(
          tester
              .widget<Material>(
                find
                    .ancestor(
                      of: find.byKey(ShellKeys.command('revisar')),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .color,
          AppColors.overlayPrimaria,
        );
        expect(
          tester
              .widget<Material>(
                find
                    .ancestor(
                      of: find.byKey(ShellKeys.command('galeria')),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .color,
          isNull,
        );
      }

      await tester.tap(find.byType(HomePage));
      await tester.pump();
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyG), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(CapturePage), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(CapturePage))).state.uri.path,
        '/capture',
      );
    });

    testWidgets('Galeria + link opens gallery at $label', (tester) async {
      await _openHome(
        tester,
        jmdictPath: jmdictPath,
        size: size,
        source: FakeImageSourceService(
          galleryImage: IncomingImage(bytes: fixturePng()),
        ),
      );

      await tester.tap(find.byKey(HomeKeys.galleryLink));
      await tester.pumpAndSettle();
      expect(find.byType(CapturePage), findsOneWidget);
    });
  }
}

String _homeDueCount(WidgetTester tester) =>
    _homeCountValue(tester, HomeKeys.due);

String _homeCountValue(WidgetTester tester, Key key) {
  final host = find.byKey(key);
  final nested = find.descendant(of: host, matching: find.byType(Text));
  final Text text;
  if (nested.evaluate().isNotEmpty) {
    text = tester.widget<Text>(nested.first);
  } else {
    text = tester.widget<Text>(host);
  }
  if (text.data != null) {
    return text.data!.split(' ').first;
  }
  final span = text.textSpan! as TextSpan;
  return (span.children!.first as TextSpan).text!;
}

String? _railBadge(WidgetTester tester) {
  final badge = find.byKey(ShellKeys.reviewBadge);
  if (badge.evaluate().isEmpty) {
    return null;
  }
  return tester
      .widget<Text>(find.descendant(of: badge, matching: find.byType(Text)))
      .data;
}

int? _restantesCount(WidgetTester tester) {
  final remaining = find.byKey(ReviewKeys.remaining);
  if (remaining.evaluate().isEmpty) {
    return null;
  }
  final data = tester.widget<Text>(remaining).data!;
  return int.parse(data.split(' ').first);
}

BuildContext _shellContext(WidgetTester tester) {
  for (final finder in [
    find.byType(ReviewPage),
    find.byType(PageDetailPage),
    find.byType(HomePage),
  ]) {
    if (finder.evaluate().isNotEmpty) {
      return tester.element(finder);
    }
  }
  return tester.element(find.byType(MangaJpMaterialApp));
}

int _providerWaiting(WidgetTester tester) {
  return ProviderScope.containerOf(_shellContext(tester))
      .read(homeReviewCountsProvider)
      .value!
      .waiting;
}

int _doneN(WidgetTester tester) {
  if (find.byKey(ReviewKeys.requeued).evaluate().isNotEmpty) {
    final data = tester.widget<Text>(find.byKey(ReviewKeys.requeued)).data!;
    return int.parse(RegExp(r'^(\d+)').firstMatch(data)!.group(1)!);
  }
  expect(find.text(ReviewLabels.doneHint), findsOneWidget);
  return 0;
}

void _expectLiveWaiting(
  WidgetTester tester, {
  required int waiting,
  required bool wide,
}) {
  expect(_providerWaiting(tester), waiting);
  if (wide) {
    expect(_railBadge(tester), waiting == 0 ? isNull : '$waiting');
  }
  if (find.byKey(ReviewKeys.done).evaluate().isNotEmpty) {
    expect(find.text(ReviewLabels.done), findsOneWidget);
    expect(find.text(ReviewLabels.doneRequeuedHint(waiting)), findsOneWidget);
    if (waiting == 0) {
      expect(find.byKey(ReviewKeys.reload), findsNothing);
    } else {
      expect(find.byKey(ReviewKeys.reload), findsOneWidget);
    }
    return;
  }
  if (find.byKey(ReviewKeys.remaining).evaluate().isNotEmpty) {
    expect(
      tester.widget<Text>(find.byKey(ReviewKeys.remaining)).data,
      ReviewLabels.restantes(waiting),
    );
  }
  if (find.byKey(HomeKeys.due).evaluate().isNotEmpty) {
    expect(_homeDueCount(tester), '$waiting');
  }
}

Color? _queueCountColor(WidgetTester tester, Key key) {
  final text = tester.widget<Text>(
    find.descendant(of: find.byKey(key), matching: find.byType(Text)),
  );
  final span = text.textSpan! as TextSpan;
  return (span.children!.first as TextSpan).style?.color;
}

const _typingProbeKey = Key('home-typing-probe');

OverlayEntry _insertChromeTypingProbe(WidgetTester tester) {
  final overlay = Overlay.of(tester.element(find.byType(HomePage)));
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

Finder _queueSeg(Color color) {
  return find.descendant(
    of: find.byKey(HomeKeys.queueBar),
    matching: find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) {
        return false;
      }
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.color == color;
    }),
  );
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

void _expectHomeOrder(WidgetTester tester, {required bool wide}) {
  final queue = wide ? find.byKey(HomeKeys.due) : find.byKey(HomeKeys.review);
  expect(queue, findsOneWidget);
  expect(find.byKey(HomeKeys.continueReading), findsOneWidget);
  expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
  expect(find.byKey(HomeKeys.weekRhythm), findsOneWidget);
  expect(
    tester.getTopLeft(queue).dy,
    lessThan(tester.getTopLeft(find.byKey(HomeKeys.continueReading)).dy),
  );
  expect(
    tester.getTopLeft(find.byKey(HomeKeys.continueReading)).dy,
    lessThan(tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy),
  );
  expect(
    tester.getTopLeft(find.byKey(HomeKeys.recentCaptures)).dy,
    lessThan(tester.getTopLeft(find.byKey(HomeKeys.weekRhythm)).dy),
  );
}

void _expectGalleryHighlight(
  WidgetTester tester, {
  required bool wide,
  int badges = 0,
}) {
  expect(find.byKey(HomeKeys.gallery), findsOneWidget);
  expect(find.byKey(HomeKeys.galleryLink), findsOneWidget);
  expect(find.text('+ Nova da galeria'), findsOneWidget);
  expect(find.text('Galeria +'), findsOneWidget);
  expect(find.text('Escolher da galeria'), findsNothing);
  expect(find.text('Galeria'), findsNothing);

  final galleryMaterial = tester.widget<Material>(
    find
        .ancestor(
          of: find.byKey(HomeKeys.gallery),
          matching: find.byType(Material),
        )
        .first,
  );
  expect(galleryMaterial.color, AppColors.coral.withValues(alpha: 0.06));

  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byKey(HomeKeys.gallery),
      matching: find.byType(CustomPaint),
    ),
  );
  final painter = paint.painter! as DashedRRectPainter;
  expect(painter.strokeWidth, 1.5);
  expect(painter.color, AppColors.coral);

  final label = tester.widget<Text>(find.text('+ Nova da galeria'));
  expect(label.style?.color, AppColors.coral);

  final kbd = find.descendant(
    of: find.byKey(HomeKeys.galleryLink),
    matching: find.byType(KbdChip),
  );
  if (wide) {
    expect(kbd, findsOneWidget);
    final chip = tester.widget<KbdChip>(kbd);
    expect(chip.label, 'G');
    expect(
      tester
          .widget<Text>(find.descendant(of: kbd, matching: find.text('G')))
          .style
          ?.fontFamily,
      AppFonts.mono,
    );
  } else {
    expect(kbd, findsNothing);
  }

  expect(find.byType(CropNumberBadge), findsNWidgets(badges));
  if (badges == 0) {
    return;
  }
  for (final badge in tester.widgetList<CropNumberBadge>(
    find.byType(CropNumberBadge),
  )) {
    expect(badge.neutral, isTrue);
  }
  final deco =
      tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(CropNumberBadge).first,
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;
  expect(deco.color, AppColors.surfaceRaised);
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

bool _reviewNeedsExitConfirm(WidgetTester tester) {
  if (find.byType(ReviewPage).evaluate().isEmpty) {
    return false;
  }
  final view = ProviderScope.containerOf(_shellContext(tester))
      .read(reviewSessionProvider)
      .asData
      ?.value;
  return view?.needsExitConfirm ?? false;
}

Future<void> _confirmLeaveReview(WidgetTester tester) async {
  expect(find.byKey(ReviewKeys.leaveDialog), findsOneWidget);
  await tester.tap(find.byKey(ReviewKeys.leaveConfirm));
  await tester.pumpAndSettle();
}
