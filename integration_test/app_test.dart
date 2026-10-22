import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_breakpoints.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_word_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/domain/review_labels.dart';
import 'package:manga_jp/features/review/domain/review_rating.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';

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

      await tester.pumpWidget(const MangaJpApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await _openLeitor(tester);
      await _edgeSwipe(tester);
      expect(find.byType(PageDetailPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.byKey(ShellKeys.navCard('caderno')));
      await tester.pumpAndSettle();
      expect(find.byType(NotebookPage), findsOneWidget);

      await tester.tap(find.byKey(NotebookKeys.row('demo-taberu')));
      await tester.pumpAndSettle();
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

      await tester.tap(find.byKey(ReviewKeys.reveal));
      await tester.pumpAndSettle();
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

      await tester.pumpWidget(const MangaJpApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

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
      expect(find.byType(PageDetailPage), findsOneWidget);

      await _tapRail(tester, 'revisar');
      expect(find.byType(ReviewPage), findsOneWidget);
    },
  );
}

Future<void> _openLeitor(WidgetTester tester) async {
  final thumb = find.byKey(HomeKeys.recentThumb('demo-page'));
  final row = find.byKey(HomeKeys.recentPage('demo-page'));
  final target = thumb.evaluate().isNotEmpty ? thumb : row;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(find.byType(PageDetailPage), findsOneWidget);
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
