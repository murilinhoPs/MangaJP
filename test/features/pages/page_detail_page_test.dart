import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

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

  testWidgets('tap leftmost kanji of 猫を食べた。 opens 猫, not the trailing 。', (
    tester,
  ) async {
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-neko-tabeta',
      ocrText: '猫を食べた。',
    );

    final topLeft = tester.getTopLeft(find.byKey(PageDetailKeys.ocrText));
    await tester.tapAt(topLeft + const Offset(8, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.miss), findsNothing);
    expect(find.text('Nenhuma entrada no dicionário.'), findsNothing);
    final gloss = tester.widget<Text>(find.byKey(LookupSheetKeys.gloss)).data!;
    expect(gloss, contains('cat'));
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.text('猫'),
      ),
      findsWidgets,
    );
  });

  testWidgets('tap kanji on the second wrapped OCR line opens that word', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const ocr = 'あいうえおかきくけこさしすせ高い';
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-wrap-takai',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final start = ocr.indexOf('高い');
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + 1),
    );
    expect(boxes, isNotEmpty);
    expect(
      boxes.first.toRect().top,
      greaterThan(10),
      reason: '高い must wrap onto a second line at this width',
    );
    await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
    await tester.pumpAndSettle();

    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.miss), findsNothing);
    expect(find.text('Nenhuma entrada no dicionário.'), findsNothing);
    final gloss = tester.widget<Text>(find.byKey(LookupSheetKeys.gloss)).data!;
    expect(gloss, contains('high'));
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.text('高い'),
      ),
      findsWidgets,
    );
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
    expect(find.byKey(LookupSheetKeys.save), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.note), findsNothing);
    expect(find.byKey(LookupSheetKeys.miss), findsNothing);
  });

  testWidgets('Salvar persists word + saved state + crop link, not a card', (
    tester,
  ) async {
    const pageId = 'page-save';
    final db = await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: pageId,
      ocrText: '食べた',
    );

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(find.byType(NotebookPage), findsNothing);
    expect(find.byKey(LookupSheetKeys.sheet), findsNothing);
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/$pageId',
    );

    final words = await db.select(db.userWords).get();
    expect(words, hasLength(1));
    expect(words.single.lemma, '食べる');
    expect(words.single.seq, 1358280);

    final states = await db.select(db.userWordStates).get();
    expect(states, hasLength(1));
    expect(states.single.state, WordState.saved.name);
    expect(states.single.wordId, words.single.id);

    final crops = await db.select(db.capturedCrops).get();
    final links = await db.select(db.cropWords).get();
    expect(links, hasLength(1));
    expect(links.single.wordId, words.single.id);
    expect(links.single.cropId, crops.single.id);

    expect(await db.select(db.userCards).get(), isEmpty);
    expect(await db.select(db.userCardSrs).get(), isEmpty);
  });

  testWidgets('Salvar again from the sheet does not duplicate rows', (
    tester,
  ) async {
    final db = await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-save-twice',
      ocrText: '食べた',
    );

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(await db.select(db.userWords).get(), hasLength(1));
    expect(await db.select(db.userWordStates).get(), hasLength(1));
    expect(await db.select(db.cropWords).get(), hasLength(1));
    expect(
      (await db.select(db.userWordStates).get()).single.state,
      WordState.saved.name,
    );
    expect(find.byType(NotebookPage), findsNothing);
  });

  testWidgets('Salvar writes the chosen homograph seq, not the default', (
    tester,
  ) async {
    final db = await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-save-homograph',
      ocrText: '優先語',
    );

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LookupSheetKeys.option(_lowHomographSeq)));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    final words = await db.select(db.userWords).get();
    expect(words, hasLength(1));
    expect(words.single.seq, _lowHomographSeq);
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

  testWidgets('no JMdict hit opens custom sheet; Salvar needs a note', (
    tester,
  ) async {
    const pageId = 'page-custom';
    final db = await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: pageId,
      ocrText: 'ぴよ',
    );

    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();

    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.miss), findsOneWidget);
    expect(find.text('ぴよ'), findsWidgets);
    expect(find.byKey(LookupSheetKeys.gloss), findsNothing);
    expect(find.byKey(LookupSheetKeys.note), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(LookupSheetKeys.save)).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(LookupSheetKeys.save));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(await db.select(db.userWords).get(), isEmpty);

    await tester.enterText(find.byKey(LookupSheetKeys.note), '   ');
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byKey(LookupSheetKeys.save)).onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(LookupSheetKeys.note), ' nome na fala ');
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(find.byKey(LookupSheetKeys.sheet), findsNothing);
    final words = await db.select(db.userWords).get();
    expect(words, hasLength(1));
    expect(words.single.id, startsWith('custom:'));
    expect(words.single.lemma, 'ぴよ');
    expect(words.single.reading, 'ぴよ');
    expect(words.single.userNote, 'nome na fala');
    expect(
      (await db.select(db.userWordStates).get()).single.state,
      WordState.saved.name,
    );
    expect(await db.select(db.userCards).get(), isEmpty);
  });
}

Future<AppDatabase> _openPage(
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
  return db;
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.byKey(LookupSheetKeys.save);
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}
