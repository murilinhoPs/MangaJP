import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/dictionary/presentation/lookup_sheet.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../../features/capture/fake_image_source_service.dart';
import '../../features/capture/fixture_png.dart';
import '../../features/dictionary/bake_jmdict_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('commandBarClearance uses the real 66px bar, not 60', () {
    expect(ShellLayout.commandBarHeight, 66);
    expect(ShellLayout.commandBarClearance, 24 + 66);
  });

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('m124_clearance_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  const phone = Size(390, 844);
  const desktop = Size(1280, 800);

  for (final size in [phone, desktop]) {
    final label = size == phone ? 'narrow 390x844' : 'wide 1280x800';

    testWidgets('Home panel is not clipped by commandBarClearance ($label)', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPage(db, id: 'home-page');
      await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);

      final panel = size == phone
          ? find.byKey(HomeKeys.review)
          : find.byKey(HomeKeys.recentPages);
      expect(panel, findsOneWidget);
      _expectPanelVisible(tester, panel, size: size);
    });

    testWidgets(
      'Captura panel is not clipped by commandBarClearance ($label)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await _pump(
          tester,
          size: size,
          db: db,
          jmdictPath: jmdictPath,
          source: FakeImageSourceService(
            initial: IncomingImage(bytes: fixturePng()),
          ),
        );
        expect(find.byType(CapturePage), findsOneWidget);

        if (size == desktop) {
          expect(find.byKey(CaptureKeys.recortesPanel), findsOneWidget);
          _expectSidePanelFullBleed(
            tester,
            find.byKey(CaptureKeys.recortesPanel),
            size: size,
          );
          final bar = tester.getRect(find.byKey(ShellKeys.commandBar));
          expect(
            bar.height - ShellLayout.commandBarBottom,
            closeTo(ShellLayout.commandBarHeight, 1.5),
          );
          _expectContentAboveBar(tester, find.byKey(CaptureKeys.recorteRow(1)));
          _expectContentAboveBar(tester, find.byKey(CaptureKeys.canvas));
        } else {
          _expectPanelVisible(
            tester,
            find.byKey(CaptureKeys.overlay),
            size: size,
          );
        }
      },
    );

    testWidgets(
      'Página lookup panel is not clipped by commandBarClearance ($label)',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await _seedPage(db, id: 'page-clearance');
        await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);
        const PageDetailRoute(id: 'page-clearance')
            .go(tester.element(find.byType(HomePage)));
        await tester.pumpAndSettle();
        expect(find.byType(PageDetailPage), findsOneWidget);

        if (size == desktop) {
          expect(find.byKey(LookupSheetKeys.drawer), findsOneWidget);
          _expectSidePanelFullBleed(
            tester,
            find.byKey(LookupSheetKeys.drawer),
            size: size,
          );
          await tester.tap(find.byKey(PageDetailKeys.ocrText));
          await tester.pumpAndSettle();
          _expectContentAboveBar(tester, find.byKey(LookupSheetKeys.learn));
        } else {
          await tester.tap(find.byKey(PageDetailKeys.ocrText));
          await tester.pumpAndSettle();
          expect(find.byKey(LookupSheetKeys.modal), findsOneWidget);
          _expectPanelVisible(
            tester,
            find.byKey(LookupSheetKeys.modal),
            size: size,
          );
        }
      },
    );

    testWidgets(
      'withCommandBarPadding does not add device safe area ($label)',
      (tester) async {
        const notch = FakeViewPadding(top: 47, bottom: 34);
        tester.view.padding = notch;
        tester.view.viewPadding = notch;
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await _seedPage(db, id: 'notch-page');
        await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);
        const PageDetailRoute(id: 'notch-page')
            .go(tester.element(find.byType(HomePage)));
        await tester.pumpAndSettle();

        final listFinder = find.ancestor(
          of: find.byKey(PageDetailKeys.ocrText),
          matching: find.byType(ListView),
        );
        expect(listFinder, findsOneWidget);
        final list = tester.widget<ListView>(listFinder);
        const base = 24.0;
        final extra = size == desktop ? ShellLayout.commandBarClearance : 0.0;
        final bottom = (list.padding! as EdgeInsets).bottom;
        expect(
          bottom,
          base + extra,
          reason:
              'Página list padding.bottom=$bottom must be $base + '
              'command-bar ($extra), not device safe area 34',
        );
      },
    );

    testWidgets('Review card is not clipped by commandBarClearance ($label)', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedDue(db);
      await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);
      const ReviewRoute().go(tester.element(find.byType(HomePage)));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);
      expect(find.byKey(ReviewKeys.card), findsOneWidget);
      _expectPanelVisible(tester, find.byKey(ReviewKeys.card), size: size);
    });
  }

  test('paddingBesideRail drops start inset covered by the rail', () {
    const pad = EdgeInsets.fromLTRB(24, 62, 18, 34);
    final ltr = ShellLayout.paddingBesideRail(
      pad,
      textDirection: TextDirection.ltr,
    );
    expect(ltr.left, 0);
    expect(ltr.top, 62);
    expect(ltr.right, 18);
    expect(ltr.bottom, 34);

    final rtl = ShellLayout.paddingBesideRail(
      pad,
      textDirection: TextDirection.rtl,
    );
    expect(rtl.left, 24);
    expect(rtl.right, 0);
  });

  test('paddingBesideRail keeps leftover when inset exceeds rail', () {
    const pad = EdgeInsets.fromLTRB(100, 62, 18, 34);
    expect(
      ShellLayout.paddingBesideRail(pad, textDirection: TextDirection.ltr).left,
      100 - ShellLayout.railWidth,
    );
  });

  testWidgets('withSafePadding adds unused top and side insets', (
    tester,
  ) async {
    late EdgeInsets result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.fromLTRB(24, 62, 18, 34),
        ),
        child: CommandBarInset(
          bottom: 0,
          child: Builder(
            builder: (context) {
              result = ShellLayout.withSafePadding(
                context,
                const EdgeInsets.fromLTRB(16, 20, 16, 24),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(result.top, 20 + 62);
    expect(result.left, 16 + 24);
    expect(result.right, 16 + 18);
    expect(result.bottom, 24);
  });

  const inset = FakeViewPadding(top: 62, left: 24);
  for (final size in [phone, desktop]) {
    final label = size == phone ? 'narrow 390x844' : 'wide 1280x800';
    final wide = size == desktop;

    Future<void> applyInset(WidgetTester tester) async {
      tester.view.padding = inset;
      tester.view.viewPadding = inset;
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
    }

    testWidgets('Home clears top and side insets ($label)', (tester) async {
      await applyInset(tester);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPage(db, id: 'home-inset');
      await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);

      final content = wide
          ? find.byKey(HomeKeys.due)
          : find.byKey(HomeKeys.title);
      expect(content, findsOneWidget);
      _expectClearsInsets(tester, content, size: size, wide: wide);

      final listFinder = find.ancestor(
        of: content,
        matching: find.byType(ListView),
      );
      expect(listFinder, findsOneWidget);
      final pad = tester.widget<ListView>(listFinder).padding! as EdgeInsets;
      if (wide) {
        expect(pad.top, 36 + 62);
        expect(
          pad.left,
          48,
          reason: 'rail already consumed the 24px start inset',
        );
        expect(pad.right, 48);
      } else {
        expect(pad.top, 20 + 62);
        expect(pad.left, 16 + 24);
        expect(pad.right, 16);
      }
    });

    testWidgets('Página clears top and side insets ($label)', (tester) async {
      await applyInset(tester);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedPage(db, id: 'page-inset');
      await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);
      const PageDetailRoute(id: 'page-inset')
          .go(tester.element(find.byType(HomePage)));
      await tester.pumpAndSettle();
      expect(find.byType(PageDetailPage), findsOneWidget);

      final content = find.byKey(PageDetailKeys.ocrText);
      expect(content, findsOneWidget);
      _expectClearsInsets(
        tester,
        content,
        size: size,
        wide: wide,
        packedToTop: false,
      );

      final listFinder = find.ancestor(
        of: content,
        matching: find.byType(ListView),
      );
      expect(listFinder, findsOneWidget);
      final pad = tester.widget<ListView>(listFinder).padding! as EdgeInsets;
      expect(pad.top, 16 + 62);
      expect(pad.left, wide ? 20 : 20 + 24);
      expect(pad.right, 20);
    });

    testWidgets('Review clears top and side insets ($label)', (tester) async {
      await applyInset(tester);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await _seedDue(db);
      await _pump(tester, size: size, db: db, jmdictPath: jmdictPath);
      const ReviewRoute().go(tester.element(find.byType(HomePage)));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);
      expect(find.byKey(ReviewKeys.card), findsOneWidget);

      _expectClearsInsets(
        tester,
        find.byKey(ReviewKeys.card),
        size: size,
        wide: wide,
        packedToTop: false,
      );

      final pad = _safeWrapPadding(tester, find.byKey(ReviewKeys.card));
      expect(pad, isNotNull);
      if (wide) {
        expect(pad!.top, 36 + 62);
        expect(
          pad.left,
          48,
          reason: 'rail already consumed the 24px start inset',
        );
        expect(pad.right, 48);
      } else {
        expect(pad!.top, 16 + 62);
        expect(pad.left, 16 + 24);
        expect(pad.right, 16);
      }
    });
  }
}

void _expectClearsInsets(
  WidgetTester tester,
  Finder content, {
  required Size size,
  required bool wide,
  bool packedToTop = true,
}) {
  const topInset = 62.0;
  const leftInset = 24.0;
  final rect = tester.getRect(content);
  expect(rect.top, greaterThanOrEqualTo(topInset));
  if (packedToTop) {
    expect(
      rect.top,
      lessThan(topInset * 2),
      reason: 'top inset must not be counted twice',
    );
  }
  if (wide) {
    expect(rect.left, greaterThanOrEqualTo(ShellLayout.railWidth));
    if (packedToTop) {
      expect(
        rect.left,
        lessThan(ShellLayout.railWidth + 48 + leftInset),
        reason: 'left inset beside the rail must not be counted twice',
      );
    }
  } else {
    expect(rect.left, greaterThanOrEqualTo(leftInset));
    if (packedToTop) {
      expect(
        rect.left,
        lessThan(leftInset * 2 + 16),
        reason: 'left inset must not be counted twice',
      );
    }
  }
  expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
}

EdgeInsets? _safeWrapPadding(WidgetTester tester, Finder inner) {
  for (final el
      in find.ancestor(of: inner, matching: find.byType(Padding)).evaluate()) {
    final padding = (el.widget as Padding).padding;
    if (padding is EdgeInsets && padding.top >= 62) {
      return padding;
    }
  }
  return null;
}

/// Cards / sheets sit in the visible area and above CommandBar or TaskDock.
void _expectPanelVisible(
  WidgetTester tester,
  Finder panel, {
  required Size size,
}) {
  final rect = tester.getRect(panel);
  expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
  expect(rect.top, greaterThanOrEqualTo(-0.5));
  expect(rect.left, greaterThanOrEqualTo(-0.5));
  expect(rect.right, lessThanOrEqualTo(size.width + 0.5));

  final bar = find.byKey(ShellKeys.commandBar);
  if (bar.evaluate().isNotEmpty) {
    expect(rect.bottom, lessThanOrEqualTo(tester.getRect(bar).top + 0.5));
  } else {
    final dock = find.byKey(ShellKeys.taskDock);
    final nav = find.byKey(ShellKeys.navCards);
    if (panel.evaluate().any((el) => el.widget.key == LookupSheetKeys.modal)) {
      return;
    }
    if (dock.evaluate().isNotEmpty) {
      expect(rect.bottom, lessThanOrEqualTo(tester.getRect(dock).top + 0.5));
    } else if (nav.evaluate().isNotEmpty) {
      expect(rect.bottom, lessThanOrEqualTo(tester.getRect(nav).top + 0.5));
    }
  }
}

/// Side drawer / inspector paints through clearance to the window bottom.
void _expectSidePanelFullBleed(
  WidgetTester tester,
  Finder panel, {
  required Size size,
}) {
  final rect = tester.getRect(panel);
  expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
  expect(
    rect.bottom,
    greaterThan(size.height - ShellLayout.commandBarClearance + 8),
    reason:
        'panel bottom ${rect.bottom} is still cut off by '
        'commandBarClearance (${ShellLayout.commandBarClearance})',
  );
  expect(rect.bottom, closeTo(size.height, 1.5));
}

void _expectContentAboveBar(WidgetTester tester, Finder content) {
  final bar = find.byKey(ShellKeys.commandBar);
  expect(bar, findsOneWidget);
  // Compare to the measured bar top (~66px visual + 24 offset), not a 60px
  // constant. commandBarClearance matches that real height so Captura's
  // canvas stays above the bar.
  expect(
    tester.getRect(content).bottom,
    lessThanOrEqualTo(tester.getRect(bar).top + 0.5),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required AppDatabase db,
  required String jmdictPath,
  ImageSourceService? source,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        jmdictServiceProvider.overrideWith((ref) async {
          final service = JmdictService()..openFile(jmdictPath);
          ref.onDispose(service.close);
          return service;
        }),
        if (source != null)
          imageSourceServiceProvider.overrideWith((ref) => source),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _seedPage(AppDatabase db, {required String id}) async {
  await PagesRepository(db).saveRecognizedCrop(
    pageId: id,
    sourceSha256: sha256Hex(fixturePng()),
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: '食べた',
    engineId: 'fake',
  );
}

Future<void> _seedDue(AppDatabase db) async {
  const id = 'due-clearance';
  final dueAt = DateTime.now().toUtc().subtract(const Duration(hours: 1));
  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: id,
          seq: 1,
          lemma: '食べる',
          reading: 'たべる',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: id,
          state: WordState.learning.name,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
  await db
      .into(db.userCards)
      .insert(
        UserCardsCompanion.insert(
          id: 'card-$id',
          wordId: id,
          kind: FlashcardKind.vocab.name,
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );
  await db
      .into(db.userCardSrs)
      .insert(
        UserCardSrsCompanion.insert(
          cardId: 'card-$id',
          easeFactor: kDefaultEaseFactor,
          intervalDays: 6,
          repetitions: 2,
          dueAt: dueAt,
          phase: CardPhase.learning.name,
          engineId: kSm2JrEngineId,
        ),
      );
}
