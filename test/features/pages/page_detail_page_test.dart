import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/dictionary/presentation/lookup_sheet.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../capture/fixture_png.dart';
import '../dictionary/bake_jmdict_fixture.dart';

const _highHomographSeq = 9990001;
const _lowHomographSeq = 9990002;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('page_lookup_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

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
      MangaJpApp(overrides: [appDatabaseProvider.overrideWith((ref) => db)]),
    );
    await tester.pumpAndSettle();

    const PageDetailRoute(id: pageId).go(tester.element(find.byType(HomePage)));
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/$pageId',
    );
    expect(find.byKey(PageDetailKeys.ocrText), findsOneWidget);
    expect(find.text(recognized), findsOneWidget);
  });

  testWidgets('tap conjugated OCR form shows lemma gloss from JMdict', (
    tester,
  ) async {
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-tabeta',
      ocrText: '食べた',
    );

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();

    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    final gloss = tester.widget<Text>(find.byKey(LookupSheetKeys.gloss)).data!;
    expect(gloss, contains('to eat'));
    expect(gloss, contains('to live on (e.g. a salary)'));
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.text('Caderno'),
      ),
      findsNothing,
    );
    expect(find.text('Add card'), findsNothing);
  });

  testWidgets('several JMdict hits: list options, default highest priority', (
    tester,
  ) async {
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-homograph',
      ocrText: '優先語',
    );

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();

    expect(
      find.byKey(LookupSheetKeys.option(_highHomographSeq)),
      findsOneWidget,
    );
    expect(
      find.byKey(LookupSheetKeys.option(_lowHomographSeq)),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(LookupSheetKeys.gloss)).data,
      'high-priority fixture homograph',
    );

    await tester.tap(find.byKey(LookupSheetKeys.option(_lowHomographSeq)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(LookupSheetKeys.gloss)).data,
      'low-priority fixture homograph',
    );
  });
}

Future<void> _openPage(
  WidgetTester tester, {
  required String jmdictPath,
  required String pageId,
  required String ocrText,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await PagesRepository(db).saveRecognizedCrop(
    pageId: pageId,
    sourceSha256: sha256Hex(fixturePng()),
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: ocrText,
    engineId: 'fake',
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

  PageDetailRoute(id: pageId).go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
}
