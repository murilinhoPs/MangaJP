import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('Home shows MangaJP; Ajustes opens Settings with Drift hello', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MangaJpApp(overrides: [appDatabaseProvider.overrideWith((ref) => db)]),
    );
    await tester.pumpAndSettle();

    expect(find.text('MangaJP'), findsOneWidget);
    expect(find.textContaining('app_meta.hello'), findsNothing);
    expect(find.text('Início'), findsWidgets);

    await tester.tap(find.byKey(ShellKeys.navCard('ajustes')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(SettingsPage))).state.uri.path,
      '/settings',
    );
    expect(
      find.textContaining('app_meta.hello = MangaJP M0.1'),
      findsOneWidget,
    );
    expect(find.byType(HomePage), findsNothing);
  });
}
