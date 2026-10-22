import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_breakpoints.dart';
import 'package:manga_jp/features/flashcards/data/flashcards_repository.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_word_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/domain/review_labels.dart';
import 'package:manga_jp/features/review/domain/review_rating.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';
import 'package:manga_jp/features/words/data/words_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Fail-message fragment when a step still needs the demo fixture.
const _kDemoSeedHint = 'rode com --dart-define=MANGAJP_DEMO_SEED=true';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One Dart file on purpose: `flutter test integration_test` relaunches the
  // macOS app per file, and the second launch fails with
  // "Unable to start the app on the device".

  testWidgets(
    'real iOS edge swipe pops Leitor, word detail, and Review (confirm)',
    (tester) async {
      // Nav cards (ShellKeys.navCard) exist only in the narrow chrome.
      // AppChrome swaps them for the desktop rail when
      // MediaQuery width >= AppBreakpoints.wide (900) — the same cut
      // ShellLayout.isWide uses. macOS defaults to 1280, so this test
      // skips there even though iPhone stays on nav cards.
      final logicalWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      if (logicalWidth >= AppBreakpoints.wide) {
        markTestSkipped(
          'needs mobile nav cards; logical width '
          '${logicalWidth.toStringAsFixed(0)} >= ${AppBreakpoints.wide} '
          'uses the desktop rail',
        );
        return;
      }

      final fixture = await _openIsolatedApp(tester);

      await _openLeitor(tester, fixture.pageId);
      await _edgeSwipe(tester);
      expect(find.byType(PageDetailPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.byKey(ShellKeys.navCard('caderno')));
      await tester.pumpAndSettle();
      expect(find.byType(NotebookPage), findsOneWidget);

      await _tapNotebookWord(tester, fixture.wordId);
      expect(find.byType(NotebookWordPage), findsOneWidget);

      await _edgeSwipe(tester);
      expect(find.byType(NotebookWordPage), findsNothing);
      expect(find.byType(NotebookPage), findsOneWidget);

      await tester.tap(find.byKey(ShellKeys.navCard('inicio')));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.byKey(HomeKeys.review));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);

      await _tapReveal(tester);
      await tester.tap(find.byKey(ReviewKeys.rating(ReviewRating.good)));
      await tester.pumpAndSettle();

      await _edgeSwipe(tester);
      expect(find.byKey(ReviewKeys.leaveDialog), findsOneWidget);
      expect(find.text(ReviewLabels.sairTitulo), findsOneWidget);

      await tester.tap(find.byKey(ReviewKeys.leaveCancel));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);

      await _edgeSwipe(tester);
      expect(find.byKey(ReviewKeys.leaveDialog), findsOneWidget);
      await tester.tap(find.byKey(ReviewKeys.leaveConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  testWidgets(
    'desktop rail opens Biblioteca, Caderno, Deck, Ajustes, Leitor, Revisar',
    (tester) async {
      // Rail items (ShellKeys.railItem) exist only in the wide chrome.
      // AppChrome swaps them for mobile nav cards when MediaQuery width
      // < AppBreakpoints.wide (900) — the same cut ShellLayout.isWide uses.
      // iPhone stays under 900, so this test skips there; macOS defaults
      // to 1280 and actually runs the flow.
      final logicalWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      if (logicalWidth < AppBreakpoints.wide) {
        markTestSkipped(
          'needs desktop rail; logical width '
          '${logicalWidth.toStringAsFixed(0)} < ${AppBreakpoints.wide} '
          'uses mobile nav cards',
        );
        return;
      }

      await _openIsolatedApp(tester);

      expect(find.byType(HomePage), findsOneWidget);

      await _tapRail(tester, 'caderno');
      expect(find.byType(NotebookPage), findsOneWidget);

      await _tapRail(tester, 'deck');
      expect(find.byType(DeckPage), findsOneWidget);

      await _tapRail(tester, 'ajustes');
      expect(find.byType(SettingsPage), findsOneWidget);

      await _tapRail(tester, 'biblioteca');
      expect(find.byType(HomePage), findsOneWidget);

      await _tapRail(tester, 'leitor');
      expect(
        find.byType(PageDetailPage),
        findsOneWidget,
        reason:
            'Leitor did not open PageDetailPage. recentPageId is null when '
            'the isolated DB has no page; this test creates one via '
            'PagesRepository before tapping the rail. $_kDemoSeedHint',
      );

      await _tapRail(tester, 'revisar');
      expect(find.byType(ReviewPage), findsOneWidget);
    },
  );
}

class _ItestFixture {
  const _ItestFixture({required this.pageId, required this.wordId});

  final String pageId;
  final String wordId;
}

/// Isolated Drift file under the app temp dir (not `mangajp.sqlite`).
Future<_ItestFixture> _openIsolatedApp(WidgetTester tester) async {
  final tmp = await getTemporaryDirectory();
  final dir = await Directory(
    '${tmp.path}/mangajp_itest_${DateTime.now().microsecondsSinceEpoch}',
  ).create(recursive: true);

  final db = AppDatabase(
    driftDatabase(
      name: 'mangajp_itest',
      native: DriftNativeOptions(databaseDirectory: () async => dir),
    ),
  );
  addTearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  const pageId = 'itest-page';
  final pages = PagesRepository(db);
  final crop = await pages.saveRecognizedCrop(
    pageId: pageId,
    sourceSha256: 'itest-sha',
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: 'あいうえおかきくけこさしすせ高い猫を食べた。',
    engineId: 'itest',
  );
  // Drift stores DateTime as whole seconds. Demo seed uses DateTime.now()
  // in beforeOpen, so bump so this page is strictly the most recent.
  await (db.update(db.capturedPages)..where((t) => t.id.equals(pageId))).write(
    CapturedPagesCompanion(
      createdAt: Value(DateTime.now().toUtc().add(const Duration(seconds: 2))),
    ),
  );

  final recent = await pages.listRecentPages(limit: 1);
  if (recent.isEmpty || recent.first.id != pageId) {
    fail(
      'PagesRepository did not persist $pageId as the recent page. '
      '$_kDemoSeedHint',
    );
  }

  final wordId = await WordsRepository(
    db,
  ).saveFromLookup(cropId: crop.id, seq: 1358280, lemma: '食べる', reading: 'たべる');
  await FlashcardsRepository(db).learn(wordId);

  await tester.pumpWidget(
    MangaJpApp(overrides: [appDatabaseProvider.overrideWith((ref) => db)]),
  );
  await tester.pumpAndSettle(const Duration(seconds: 5));

  return _ItestFixture(pageId: pageId, wordId: wordId);
}

Future<void> _openLeitor(WidgetTester tester, String pageId) async {
  final thumb = find.byKey(HomeKeys.recentThumb(pageId));
  final row = find.byKey(HomeKeys.recentPage(pageId));
  final target = thumb.evaluate().isNotEmpty ? thumb : row;
  if (target.evaluate().isEmpty) {
    fail(
      'No recent page $pageId on Home. Isolated DB should have created it '
      'via PagesRepository. $_kDemoSeedHint',
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(find.byType(PageDetailPage), findsOneWidget);
}

Future<void> _tapNotebookWord(WidgetTester tester, String wordId) async {
  final row = find.byKey(NotebookKeys.row(wordId));
  if (row.evaluate().isEmpty) {
    fail(
      'Notebook row $wordId missing. Isolated DB should have saved it via '
      'WordsRepository. $_kDemoSeedHint',
    );
  }
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _tapReveal(WidgetTester tester) async {
  final reveal = find.byKey(ReviewKeys.reveal);
  if (reveal.evaluate().isEmpty) {
    fail(
      'Review reveal missing — due queue empty. Isolated DB should have '
      'a due card via FlashcardsRepository.learn. $_kDemoSeedHint',
    );
  }
  await tester.tap(reveal);
  await tester.pumpAndSettle();
}

Future<void> _edgeSwipe(WidgetTester tester) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  Finder page = find.byType(PageDetailPage);
  if (page.evaluate().isEmpty) {
    page = find.byType(NotebookWordPage);
  }
  if (page.evaluate().isEmpty) {
    page = find.byType(ReviewPage);
  }
  final start = Offset(tester.getTopLeft(page).dx + 5, size.height / 2);
  await tester.dragFrom(start, Offset(size.width * 0.6, 0));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _tapRail(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ShellKeys.railItem(id)));
  await tester.pumpAndSettle();
}
