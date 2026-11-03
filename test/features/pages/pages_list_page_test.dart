import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/domain/page_labels.dart';
import 'package:manga_jp/features/pages/domain/page_title.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/pages/presentation/pages_list_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../capture/fake_image_source_service.dart';
import '../capture/fixture_png.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

class _SeedPage {
  const _SeedPage({
    required this.id,
    required this.createdAt,
    this.ocrText,
  });

  final String id;
  final DateTime createdAt;
  final String? ocrText;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= AppBreakpoints.wide;

    testWidgets(
      '/pages lists every page with thumb, title and date at $label',
      (tester) async {
        final now = DateTime.now();
        await _openPages(
          tester,
          size: size,
          pages: [
            for (var i = 1; i <= 7; i++)
              _SeedPage(
                id: 'page-$i',
                createdAt: now.subtract(Duration(days: 7 - i)),
                ocrText: i == 1 ? null : '文$i',
              ),
          ],
        );

        expect(find.byType(PagesListPage), findsOneWidget);
        expect(find.byKey(PagesKeys.title), findsOneWidget);
        expect(find.text(PageLabels.pagesTitle), findsOneWidget);
        expect(find.byKey(PagesKeys.list), findsOneWidget);
        expect(find.byKey(PagesKeys.empty), findsNothing);
        expect(
          GoRouter.of(tester.element(find.byType(PagesListPage))).state.uri.path,
          '/pages',
        );

        expect(find.byKey(PagesKeys.row('page-7')), findsOneWidget);
        expect(find.byKey(PagesKeys.thumb('page-7')), findsOneWidget);
        expect(find.text('文7'), findsWidgets);
        expect(find.text('hoje'), findsWidgets);
        expect(
          tester.getTopLeft(find.byKey(PagesKeys.row('page-7'))).dy,
          lessThan(tester.getTopLeft(find.byKey(PagesKeys.row('page-6'))).dy),
        );

        final scrollable = find.descendant(
          of: find.byKey(PagesKeys.list),
          matching: find.byType(Scrollable),
        );
        for (var i = 7; i >= 1; i--) {
          final row = find.byKey(PagesKeys.row('page-$i'));
          await tester.scrollUntilVisible(row, 120, scrollable: scrollable);
          await tester.pumpAndSettle();
          expect(row, findsOneWidget);
          expect(find.byKey(PagesKeys.thumb('page-$i')), findsOneWidget);
        }
        expect(find.text(PageTitle.fallback), findsOneWidget);
        expect(find.text(WordState.learning.name), findsNothing);
        expect(find.text(PageLabels.aprendendo), findsNothing);
        expect(find.text(PageLabels.conhecido), findsNothing);
        expect(find.text(PageLabels.ignorar), findsNothing);

        if (wide) {
          expect(find.byKey(ShellKeys.railItem('leitor')), findsOneWidget);
          expect(find.byKey(ShellKeys.navCards), findsNothing);
          await tester.tap(find.byKey(ShellKeys.railItem('leitor')));
          await tester.pumpAndSettle();
          expect(
            GoRouter.of(
              tester.element(find.byType(PageDetailPage)),
            ).state.uri.path,
            '/pages/page-7',
          );
        } else {
          expect(find.byKey(ShellKeys.navCards), findsOneWidget);
          expect(find.byKey(ShellKeys.taskDock), findsNothing);
        }
      },
    );

    testWidgets('empty /pages shows Nenhuma página and Galeria + at $label', (
      tester,
    ) async {
      final source = FakeImageSourceService(
        galleryImage: IncomingImage(bytes: fixturePng()),
      );
      await _openPages(tester, size: size, source: source);

      expect(find.byKey(PagesKeys.empty), findsOneWidget);
      expect(find.text(PageLabels.empty), findsOneWidget);
      expect(find.text(PageLabels.emptyHint), findsOneWidget);
      expect(find.byKey(PagesKeys.gallery), findsOneWidget);
      expect(find.text(PageLabels.gallery), findsOneWidget);
      expect(find.byKey(PagesKeys.list), findsNothing);
      expect(find.text('/pages — stub (M0.1)'), findsNothing);

      await tester.tap(find.byKey(PagesKeys.gallery));
      await tester.pumpAndSettle();
      expect(source.galleryCalls, 1);
      expect(find.byType(CapturePage), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(CapturePage))).state.uri.path,
        '/capture',
      );
    });

    testWidgets('tapping a /pages row opens /pages/:id at $label', (
      tester,
    ) async {
      const ocr = 'この町には、もう誰も残っていない。';
      await _openPages(
        tester,
        size: size,
        pages: [
          _SeedPage(
            id: 'page-open',
            createdAt: DateTime.now(),
            ocrText: ocr,
          ),
          _SeedPage(
            id: 'page-other',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ocrText: '見せる',
          ),
        ],
      );

      expect(find.text(ocr), findsWidgets);
      await tester.tap(find.byKey(PagesKeys.row('page-open')));
      await tester.pumpAndSettle();

      expect(find.byType(PageDetailPage), findsOneWidget);
      expect(
        GoRouter.of(
          tester.element(find.byType(PageDetailPage)),
        ).state.uri.path,
        '/pages/page-open',
      );
      expect(find.byKey(PageDetailKeys.ocrText), findsOneWidget);
      expect(find.text(ocr), findsOneWidget);
      expect(find.text('/pages — stub (M0.1)'), findsNothing);
    });
  }

  testWidgets('Home Capturas recentes stay capped; Ver todas opens /pages', (
    tester,
  ) async {
    final now = DateTime.now();
    await _openHome(
      tester,
      size: _phone,
      pages: [
        for (var i = 1; i <= 7; i++)
          _SeedPage(
            id: 'page-$i',
            createdAt: now.subtract(Duration(days: 7 - i)),
            ocrText: '文$i',
          ),
      ],
    );

    expect(find.byKey(HomeKeys.recentCaptures), findsOneWidget);
    expect(find.text('Capturas recentes'), findsOneWidget);
    expect(find.byKey(HomeKeys.recentThumb('page-7')), findsOneWidget);
    expect(find.byKey(HomeKeys.recentThumb('page-2')), findsOneWidget);
    expect(find.byKey(HomeKeys.recentThumb('page-1')), findsNothing);
    expect(find.byKey(HomeKeys.pagesLink), findsOneWidget);
    expect(find.text(PageLabels.verTodas), findsOneWidget);

    await tester.tap(find.byKey(HomeKeys.pagesLink));
    await tester.pumpAndSettle();
    expect(find.byType(PagesListPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(PagesListPage))).state.uri.path,
      '/pages',
    );
    expect(find.byKey(PagesKeys.row('page-7')), findsOneWidget);
    expect(find.byKey(PagesKeys.row('page-1')), findsOneWidget);
  });
}

Future<AppDatabase> _openPages(
  WidgetTester tester, {
  required Size size,
  List<_SeedPage> pages = const [],
  ImageSourceService? source,
}) async {
  final db = await _pumpApp(
    tester,
    size: size,
    pages: pages,
    source: source,
  );
  const PagesRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  return db;
}

Future<AppDatabase> _openHome(
  WidgetTester tester, {
  required Size size,
  List<_SeedPage> pages = const [],
}) {
  return _pumpApp(tester, size: size, pages: pages);
}

Future<AppDatabase> _pumpApp(
  WidgetTester tester, {
  required Size size,
  List<_SeedPage> pages = const [],
  ImageSourceService? source,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
    if (page.ocrText == null) {
      continue;
    }
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'crop-${page.id}',
        pageId: page.id,
        ocrText: page.ocrText!,
        engineId: 'test',
        left: 0.1,
        top: 0.1,
        width: 0.4,
        height: 0.4,
        createdAt: page.createdAt,
      ),
    );
  }

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        if (source != null)
          imageSourceServiceProvider.overrideWith((ref) => source),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
