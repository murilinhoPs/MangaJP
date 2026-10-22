import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_breakpoints.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'desktop rail opens Biblioteca, Caderno, Deck, Ajustes, Leitor, Revisar',
    (tester) async {
      // Rail items (ShellKeys.railItem) exist only in the wide chrome.
      // AppChrome swaps them for mobile nav cards when MediaQuery width
      // < AppBreakpoints.wide (900) — the same cut ShellLayout.isWide uses.
      // iPhone stays under 900, so this file skips there; macOS defaults
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

Future<void> _tapRail(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ShellKeys.railItem(id)));
  await tester.pumpAndSettle();
}
