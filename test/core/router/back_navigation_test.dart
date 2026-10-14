import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_word_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../../features/capture/fixture_png.dart';
import '../../features/dictionary/bake_jmdict_fixture.dart';

const _pageId = 'page-back';
const _wordId = 'eat';
const _taberuSeq = 1358280;
const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('back_nav_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets(
      'recent capture opens Leitor; AppBar back pops to Home ($label)',
      (tester) async {
        await _openHomeWithPage(tester, jmdictPath: jmdictPath, size: size);
        await _openReaderFromRecent(tester);

        expect(find.text('/pages — stub (M0.1)'), findsNothing);
        expect(find.byKey(PageDetailKeys.back), findsOneWidget);
        expect(_path(tester), '/pages/$_pageId');

        await tester.tap(find.byKey(PageDetailKeys.back));
        await tester.pumpAndSettle();

        expect(find.byType(PageDetailPage), findsNothing);
        expect(find.byType(HomePage), findsOneWidget);
        expect(_path(tester), '/home');
        expect(find.text('/pages — stub (M0.1)'), findsNothing);
      },
    );

    testWidgets(
      'recent capture opens Leitor; iOS back swipe pops to Home ($label)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await _openHomeWithPage(tester, jmdictPath: jmdictPath, size: size);
          await _openReaderFromRecent(tester);

          expect(_path(tester), '/pages/$_pageId');
          expect(GoRouter.of(_routerContext(tester)).canPop(), isTrue);
          _expectCupertinoPage(tester);

          await _iosEdgeSwipe(tester, size: size);

          expect(find.byType(PageDetailPage), findsNothing);
          expect(_path(tester), '/home');
          expect(find.byType(HomePage), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('word detail AppBar back pops to Caderno ($label)', (
      tester,
    ) async {
      await _openWordDetail(tester, jmdictPath: jmdictPath, size: size);

      expect(find.byKey(NotebookWordKeys.back), findsOneWidget);
      expect(_path(tester), '/notebook/word/$_wordId');

      await tester.tap(find.byKey(NotebookWordKeys.back));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookWordPage), findsNothing);
      expect(find.byType(NotebookPage), findsOneWidget);
      expect(_path(tester), '/notebook');
    });

    testWidgets('word detail iOS back swipe pops to Caderno ($label)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await _openWordDetail(tester, jmdictPath: jmdictPath, size: size);

        expect(_path(tester), '/notebook/word/$_wordId');
        expect(GoRouter.of(_routerContext(tester)).canPop(), isTrue);
        _expectCupertinoPage(tester);

        await _iosEdgeSwipe(tester, size: size);

        expect(find.byType(NotebookWordPage), findsNothing);
        expect(find.byType(NotebookPage), findsOneWidget);
        expect(_path(tester), '/notebook');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Leitor stays opaque mid iOS push and swipe ($label)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await _openHomeWithPage(tester, jmdictPath: jmdictPath, size: size);
        await _tapRecent(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.byType(PageDetailPage), findsOneWidget);
        expect(find.byType(HomePage), findsOneWidget);
        _expectOpaqueFill(tester, find.byType(PageDetailPage));

          await tester.pumpAndSettle();
          final swipe = await _startIosEdgeSwipe(tester, size: size);
          expect(find.byType(PageDetailPage), findsOneWidget);
          expect(
            find.byType(HomePage, skipOffstage: false),
            findsOneWidget,
          );
          _expectOpaqueFill(tester, find.byType(PageDetailPage));
          await swipe.up();
          await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('word detail stays opaque mid iOS push and swipe ($label)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await _openNotebookList(tester, jmdictPath: jmdictPath, size: size);
        await tester.tap(find.byKey(NotebookKeys.row(_wordId)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.byType(NotebookWordPage), findsOneWidget);
        expect(find.byType(NotebookPage), findsOneWidget);
        _expectOpaqueFill(tester, find.byType(NotebookWordPage));

        await tester.pumpAndSettle();
        final swipe = await _startIosEdgeSwipe(tester, size: size);
        expect(find.byType(NotebookWordPage), findsOneWidget);
        expect(find.byType(NotebookPage), findsOneWidget);
        _expectOpaqueFill(tester, find.byType(NotebookWordPage));
        await swipe.up();
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}

Future<void> _openReaderFromRecent(WidgetTester tester) async {
  await _tapRecent(tester);
  await tester.pumpAndSettle();
  expect(find.byType(PageDetailPage), findsOneWidget);
}

Future<void> _tapRecent(WidgetTester tester) async {
  final thumb = find.byKey(HomeKeys.recentThumb(_pageId));
  final row = find.byKey(HomeKeys.recentPage(_pageId));
  final target = thumb.evaluate().isNotEmpty ? thumb : row;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

/// Real iOS edge swipe. Must not fall back to [Navigator.maybePop] — that
/// would still pass after swapping [CupertinoPage] for [MaterialPage].
///
/// Start 5px inside the route's left edge (`_kBackGestureWidth` is 20). On
/// a phone that is `Offset(5, y)`; beside the rail it is `railWidth + 5`.
Future<void> _iosEdgeSwipe(WidgetTester tester, {required Size size}) async {
  final page = find.byType(PageDetailPage).evaluate().isNotEmpty
      ? find.byType(PageDetailPage)
      : find.byType(NotebookWordPage);
  final start = Offset(tester.getTopLeft(page).dx + 5, size.height / 2);
  await tester.dragFrom(start, Offset(size.width * 0.6, 0));
  await tester.pumpAndSettle();
}

/// Hold the back-swipe mid-transition (finger down, previous route visible).
Future<TestGesture> _startIosEdgeSwipe(
  WidgetTester tester, {
  required Size size,
}) async {
  final page = find.byType(PageDetailPage).evaluate().isNotEmpty
      ? find.byType(PageDetailPage)
      : find.byType(NotebookWordPage);
  final start = Offset(tester.getTopLeft(page).dx + 5, size.height / 2);
  final gesture = await tester.startGesture(start);
  await tester.pump();
  await gesture.moveBy(Offset(size.width * 0.4, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return gesture;
}

void _expectOpaqueFill(WidgetTester tester, Finder page) {
  final scaffold = tester.widget<Scaffold>(
    find.descendant(of: page, matching: find.byType(Scaffold)).first,
  );
  expect(scaffold.backgroundColor, AppColors.bg);
  expect(scaffold.backgroundColor!.a, 1.0);

  final fill = tester.widget<ColoredBox>(
    find.ancestor(of: page, matching: find.byType(ColoredBox)).first,
  );
  expect(fill.color, AppColors.bg);
  expect(fill.color.a, 1.0);
}

void _expectCupertinoPage(WidgetTester tester) {
  final route = ModalRoute.of(_routerContext(tester));
  expect(
    route is CupertinoRouteTransitionMixin,
    isTrue,
    reason: 'edge swipe requires CupertinoPage, not MaterialPage',
  );
}

BuildContext _routerContext(WidgetTester tester) {
  for (final finder in [
    find.byType(PageDetailPage),
    find.byType(NotebookWordPage),
    find.byType(NotebookPage),
    find.byType(HomePage),
  ]) {
    if (finder.evaluate().isNotEmpty) {
      return tester.element(finder);
    }
  }
  return tester.element(find.byType(MangaJpMaterialApp));
}

String _path(WidgetTester tester) {
  return GoRouter.of(_routerContext(tester)).state.uri.path;
}

Future<void> _openHomeWithPage(
  WidgetTester tester, {
  required String jmdictPath,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await PagesRepository(db).saveRecognizedCrop(
    pageId: _pageId,
    sourceSha256: sha256Hex(fixturePng()),
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: '文',
    engineId: 'test',
  );

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        jmdictServiceProvider.overrideWith((ref) async {
          final service = JmdictService()..openFile(jmdictPath);
          ref.onDispose(service.close);
          return service;
        }),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openNotebookList(
  WidgetTester tester, {
  required String jmdictPath,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final now = DateTime.utc(2026, 1, 1);
  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: _wordId,
          seq: _taberuSeq,
          lemma: '食べる',
          reading: 'たべる',
          createdAt: now,
        ),
      );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: _wordId,
          state: WordState.saved.name,
          updatedAt: now,
        ),
      );

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        jmdictServiceProvider.overrideWith((ref) async {
          final service = JmdictService()..openFile(jmdictPath);
          ref.onDispose(service.close);
          return service;
        }),
      ],
    ),
  );
  await tester.pumpAndSettle();

  const NotebookRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  expect(find.byType(NotebookPage), findsOneWidget);
}

Future<void> _openWordDetail(
  WidgetTester tester, {
  required String jmdictPath,
  required Size size,
}) async {
  await _openNotebookList(tester, jmdictPath: jmdictPath, size: size);
  await tester.tap(find.byKey(NotebookKeys.row(_wordId)));
  await tester.pumpAndSettle();
  expect(find.byType(NotebookWordPage), findsOneWidget);
}
