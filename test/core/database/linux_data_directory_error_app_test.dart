import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app_bootstrap.dart';
import 'package:manga_jp/core/database/linux_app_support_migration.dart';
import 'package:manga_jp/core/database/linux_data_directory_error_app.dart';
import 'package:manga_jp/core/theme/app_colors.dart';

void main() {
  Future<void> pumpError(
    WidgetTester tester, {
    required Size size,
    Widget? app,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app ?? const LinuxDataDirectoryErrorApp());
    await tester.pumpAndSettle();
  }

  void expectErrorScreenVisible(WidgetTester tester) {
    expect(find.byKey(LinuxDataDirectoryErrorKeys.screen), findsOneWidget);
    expect(find.text(LinuxDataDirectoryErrorCopy.title), findsOneWidget);
    expect(find.textContaining('HOME'), findsWidgets);
    expect(find.textContaining('pasta de dados'), findsWidgets);
    expect(
      find.textContaining('HOME=/home/<usuário> manga_jp'),
      findsOneWidget,
    );
    expect(find.textContaining('getpwuid'), findsNothing);
    expect(find.byType(SelectableText), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(
      find.byKey(LinuxDataDirectoryErrorKeys.screen),
    );
    expect(scaffold.backgroundColor, AppColors.bg);
  }

  testWidgets('error screen is readable on a narrow 390×844 layout', (
    tester,
  ) async {
    await pumpError(tester, size: const Size(390, 844));
    expectErrorScreenVisible(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error screen is readable on a wide 1280×800 layout', (
    tester,
  ) async {
    await pumpError(tester, size: const Size(1280, 800));
    expectErrorScreenVisible(tester);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(
      scroll.padding,
      const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bootstrap shows the error screen when HOME and getpwuid fail',
    skip: !Platform.isLinux,
    (tester) async {
      resetLinuxAppSupportDirectoryCache();
      addTearDown(resetLinuxAppSupportDirectoryCache);
      await pumpError(
        tester,
        size: const Size(390, 844),
        app: mangaJpBootstrapApp(
          environment: const <String, String>{},
          passwdHome: () => null,
        ),
      );
      expectErrorScreenVisible(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
