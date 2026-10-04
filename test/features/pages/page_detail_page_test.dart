import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../capture/fixture_png.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('/pages/:id shows ocr_text already persisted in Drift', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const recognized = 'よぉ、相棒';
    const pageId = 'page-from-drift';

    await PagesRepository(db).saveRecognizedCrop(
      pageId: pageId,
      sourceSha256: sha256Hex(fixturePng()),
      left: 0.2,
      top: 0.2,
      width: 0.6,
      height: 0.6,
      ocrText: recognized,
      engineId: 'fake',
    );

    await tester.pumpWidget(
      MangaJpApp(
        overrides: [appDatabaseProvider.overrideWith((ref) => db)],
      ),
    );
    await tester.pumpAndSettle();

    PageDetailRoute(id: pageId).go(tester.element(find.byType(HomePage)));
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/$pageId',
    );
    expect(find.byKey(PageDetailKeys.ocrText), findsOneWidget);
    expect(find.text(recognized), findsOneWidget);
  });
}
