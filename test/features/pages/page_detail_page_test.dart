import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/copy/recortes_label.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/dictionary/presentation/lookup_sheet.dart';
import 'package:manga_jp/features/flashcards/data/flashcards_repository.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/domain/page_labels.dart';
import 'package:manga_jp/features/pages/presentation/ocr_char_index.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/words/data/words_repository.dart';
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

  testWidgets('tap right half of 高 in 高い opens 高い, not い', (tester) async {
    const ocr = '高い';
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-takai-right',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _glyphLocal(paragraph, start: 0, end: 1, rightHalf: true);
    expect(
      charIndexAt(paragraph, local),
      0,
      reason: 'right half of 高 must resolve 高, not い',
    );

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    await _expectTakaiLookup(tester);
  });

  testWidgets('tap left half of 高 in 高い opens 高い', (tester) async {
    const ocr = '高い';
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-takai-left',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _glyphLocal(paragraph, start: 0, end: 1, rightHalf: false);
    expect(charIndexAt(paragraph, local), 0);

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    await _expectTakaiLookup(tester);
  });

  testWidgets('tap right half of 高 on the second wrapped OCR line opens 高い', (
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
      pageId: 'page-wrap-takai-right',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final start = ocr.indexOf('高い');
    final local = _glyphLocal(
      paragraph,
      start: start,
      end: start + 1,
      rightHalf: true,
    );
    expect(
      paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: start + 1),
          )
          .first
          .toRect()
          .top,
      greaterThan(10),
      reason: '高い must wrap onto a second line at this width',
    );
    expect(
      charIndexAt(paragraph, local),
      start,
      reason: 'right half of wrapped 高 must stay on 高, not い',
    );

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    await _expectTakaiLookup(tester);
  });

  testWidgets('tap empty space after line 1 of wrapped OCR does not select', (
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
      pageId: 'page-empty-line1',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _emptyAfterLine(paragraph, lineIndex: 0);
    expect(charIndexAt(paragraph, local), isNull);

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsNothing);
    expect(find.text('Nenhuma entrada no dicionário.'), findsNothing);
  });

  testWidgets('tap empty space after line 2 of wrapped OCR does not select', (
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
      pageId: 'page-empty-line2',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _emptyAfterLine(paragraph, lineIndex: 1);
    expect(charIndexAt(paragraph, local), isNull);

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsNothing);
    expect(find.text('Nenhuma entrada no dicionário.'), findsNothing);
  });

  testWidgets('tap a character after missing empty space still opens lookup', (
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
      pageId: 'page-empty-then-char',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final empty = _emptyAfterLine(paragraph, lineIndex: 0);
    expect(charIndexAt(paragraph, empty), isNull);
    await tester.tapAt(paragraph.localToGlobal(empty));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsNothing);

    final start = ocr.indexOf('高い');
    final local = _glyphLocal(
      paragraph,
      start: start,
      end: start + 1,
      rightHalf: false,
    );
    expect(charIndexAt(paragraph, local), start);
    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    await _expectTakaiLookup(tester);
  });

  testWidgets(
    'tap left and right halves of a surrogate kanji in the middle select it whole',
    (tester) async {
      const kanji = '𠮟';
      const ocr = '猫$kanjiを';
      expect(kanji.length, 2);
      final start = ocr.indexOf(kanji);
      expect(start, 1);

      await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-surrogate-mid',
        ocrText: ocr,
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.byKey(PageDetailKeys.ocrText),
      );
      for (final rightHalf in [false, true]) {
        final local = _glyphLocal(
          paragraph,
          start: start,
          end: start + kanji.length,
          rightHalf: rightHalf,
        );
        expect(
          charIndexAt(paragraph, local),
          start,
          reason:
              'surrogate ${rightHalf ? 'right' : 'left'} half must be '
              'the pair start, not a code unit',
        );
        expect(charIndexAt(paragraph, local), isNot(start + 1));
      }

      await tester.tapAt(
        paragraph.localToGlobal(
          _glyphLocal(
            paragraph,
            start: start,
            end: start + kanji.length,
            rightHalf: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.miss), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(LookupSheetKeys.sheet),
          matching: find.textContaining(kanji),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'tap right half of trailing 葛+IVS (3 UTF-16 units) selects the cluster',
    (tester) async {
      const ivs = '\u{E0100}';
      const cluster = '葛$ivs';
      const ocr = '猫$cluster';
      expect(cluster.length, 3);
      final start = ocr.indexOf('葛');

      await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-kuzu-ivs-end',
        ocrText: ocr,
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.byKey(PageDetailKeys.ocrText),
      );
      final local = _glyphLocal(
        paragraph,
        start: start,
        end: start + cluster.length,
        rightHalf: true,
      );
      expect(charIndexAt(paragraph, local), start);
      expect(charIndexAt(paragraph, local), isNot(start + 1));
      expect(charIndexAt(paragraph, local), isNot(start + 2));

      await tester.tapAt(paragraph.localToGlobal(local));
      await tester.pumpAndSettle();
      expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.miss), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(LookupSheetKeys.sheet),
          matching: find.text('葛'),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('tap right half of 𠮷+IVS (4 UTF-16 units) selects the cluster', (
    tester,
  ) async {
    const ivs = '\u{E0100}';
    const cluster = '𠮷$ivs';
    const ocr = '猫$cluster';
    expect(cluster.length, 4);
    final start = ocr.indexOf('𠮷');

    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-yoshi-ivs',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _glyphLocal(
      paragraph,
      start: start,
      end: start + cluster.length,
      rightHalf: true,
    );
    expect(charIndexAt(paragraph, local), start);
    expect(charIndexAt(paragraph, local), isNot(start + 1));
    expect(charIndexAt(paragraph, local), isNot(start + 2));
    expect(charIndexAt(paragraph, local), isNot(start + 3));

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.miss), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.textContaining('𠮷'),
      ),
      findsWidgets,
    );
  });

  testWidgets('tap right half of kanji+VS16 selects the cluster', (
    tester,
  ) async {
    const vs16 = '\u{FE0F}';
    const cluster = '葛$vs16';
    const ocr = '猫$cluster';
    expect(cluster.length, 2);
    final start = ocr.indexOf('葛');

    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-kuzu-vs16',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _glyphLocal(
      paragraph,
      start: start,
      end: start + cluster.length,
      rightHalf: true,
    );
    expect(charIndexAt(paragraph, local), start);
    expect(charIndexAt(paragraph, local), isNot(start + 1));

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.miss), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.text('葛'),
      ),
      findsWidgets,
    );
  });

  testWidgets('two IVS kanji: tap on the second highlights only that cluster', (
    tester,
  ) async {
    const ivs = '\u{E0100}';
    const first = '辻$ivs';
    const second = '葛$ivs';
    const ocr = '$first$second';
    final start = first.length;

    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-two-ivs',
      ocrText: ocr,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    final local = _glyphLocal(
      paragraph,
      start: start,
      end: start + second.length,
      rightHalf: true,
    );
    expect(charIndexAt(paragraph, local), start);

    await tester.tapAt(paragraph.localToGlobal(local));
    await tester.pumpAndSettle();
    expect(_spanBackground(tester, second), AppColors.overlaySelecaoToque);
    expect(_spanBackground(tester, first), isNull);
    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.text('葛'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(LookupSheetKeys.sheet),
        matching: find.text('辻'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'tap left and right halves of a trailing surrogate kanji select it whole',
    (tester) async {
      const kanji = '𩸽';
      const ocr = '猫$kanji';
      expect(kanji.length, 2);
      final start = ocr.indexOf(kanji);

      await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-surrogate-end',
        ocrText: ocr,
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.byKey(PageDetailKeys.ocrText),
      );
      for (final rightHalf in [false, true]) {
        final local = _glyphLocal(
          paragraph,
          start: start,
          end: start + kanji.length,
          rightHalf: rightHalf,
        );
        expect(
          charIndexAt(paragraph, local),
          start,
          reason:
              'trailing surrogate ${rightHalf ? 'right' : 'left'} half '
              'must cover both code units',
        );
        expect(charIndexAt(paragraph, local), isNot(ocr.length - 1));
      }

      await tester.tapAt(
        paragraph.localToGlobal(
          _glyphLocal(
            paragraph,
            start: start,
            end: start + kanji.length,
            rightHalf: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.miss), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(LookupSheetKeys.sheet),
          matching: find.textContaining(kanji),
        ),
        findsWidgets,
      );
    },
  );

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
      tester
          .widget<LookupActionButton>(find.byKey(LookupSheetKeys.save))
          .enabled,
      isFalse,
    );

    await tester.tap(find.byKey(LookupSheetKeys.save));
    await tester.pumpAndSettle();
    expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
    expect(await db.select(db.userWords).get(), isEmpty);

    await tester.enterText(find.byKey(LookupSheetKeys.note), '   ');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LookupActionButton>(find.byKey(LookupSheetKeys.save))
          .enabled,
      isFalse,
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

  testWidgets('OCR tokens use state color; touched token is coral 25%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const ocr = '高い猫を食べた。ぴよ';
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-colors',
      ocrText: ocr,
      seed: (db, cropId) async {
        final words = WordsRepository(db);
        final cards = FlashcardsRepository(db);
        await words.saveFromLookup(
          cropId: cropId,
          seq: 1411580,
          lemma: '高い',
          reading: 'たかい',
        );
        await cards.markKnown(
          await words.saveFromLookup(
            cropId: cropId,
            seq: 1583470,
            lemma: '猫',
            reading: 'ねこ',
          ),
        );
        await cards.learn(
          await words.saveFromLookup(
            cropId: cropId,
            seq: 1358280,
            lemma: '食べる',
            reading: 'たべる',
          ),
        );
        await cards.markIgnored(
          await words.saveCustomFromLookup(
            cropId: cropId,
            surface: 'ぴよ',
            userNote: 'nome',
          ),
        );
      },
    );

    expect(_spanColor(tester, '高い'), AppColors.text); // Salvo
    expect(_spanColor(tester, 'を'), AppColors.text); // Novo
    expect(_spanColor(tester, '猫'), AppColors.mint);
    expect(_spanColor(tester, '食べた'), AppColors.violetText);
    expect(_spanColor(tester, 'ぴよ'), AppColors.text3);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(PageDetailKeys.ocrText),
    );
    await tester.tapAt(
      paragraph.localToGlobal(
        _glyphLocal(paragraph, start: 0, end: 1, rightHalf: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(_spanBackground(tester, '高い'), AppColors.overlaySelecaoToque);
    expect(
      tester
          .widget<LookupActionButton>(find.byKey(LookupSheetKeys.save))
          .active,
      isTrue,
    );
  });

  testWidgets('lookup actions are Aprendendo · Conhecido · Ignorar · Salvar', (
    tester,
  ) async {
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-actions',
      ocrText: '食べた',
    );
    await tester.tap(find.byKey(PageDetailKeys.ocrText));
    await tester.pumpAndSettle();

    final buttons = tester
        .widgetList<LookupActionButton>(find.byType(LookupActionButton))
        .toList();
    expect(buttons.map((button) => button.label), [
      PageLabels.aprendendo,
      PageLabels.conhecido,
      PageLabels.ignorar,
      PageLabels.salvar,
    ]);
    expect(buttons.map((button) => button.shortcut), ['A', 'K', 'I', 'S']);
    expect(
      tester.getSize(find.byKey(LookupSheetKeys.save)).height,
      AppTargets.acaoEstado,
    );
    expect(find.byKey(LookupSheetKeys.phrase), findsOneWidget);
  });

  for (final shortcut in _lookupShortcuts) {
    testWidgets(
      'lookup shortcut ${shortcut.label} applies ${shortcut.state.name}',
      (tester) async {
        final db = await _openPage(
          tester,
          jmdictPath: jmdictPath,
          pageId: 'page-shortcut-${shortcut.state.name}',
          ocrText: '食べた',
        );
        await tester.tap(find.byKey(PageDetailKeys.ocrText));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(shortcut.key);
        await tester.pumpAndSettle();

        expect(find.byKey(LookupSheetKeys.sheet), findsNothing);
        final states = await db.select(db.userWordStates).get();
        expect(states, hasLength(1));
        expect(states.single.state, shortcut.state.name);
        expect(
          await db.select(db.userCards).get(),
          shortcut.createsCard ? hasLength(1) : isEmpty,
        );
      },
    );
  }

  testWidgets(
    'lookup shortcuts do not fire while the note TextField is focused',
    (tester) async {
      final db = await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-shortcut-typing',
        ocrText: 'ぴよ',
      );
      await tester.tap(find.byKey(PageDetailKeys.ocrText));
      await tester.pumpAndSettle();

      expect(find.byKey(LookupSheetKeys.note), findsOneWidget);
      await tester.tap(find.byKey(LookupSheetKeys.note));
      await tester.pump();

      expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyK), isFalse);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyI), isFalse);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyS), isFalse);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyA), isFalse);
      await tester.enterText(find.byKey(LookupSheetKeys.note), 'kis');
      await tester.pump();

      expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
      expect(find.text('kis'), findsOneWidget);
      expect(await db.select(db.userWords).get(), isEmpty);
      expect(await db.select(db.userWordStates).get(), isEmpty);
    },
  );

  testWidgets(
    'mobile lookup is a half-screen sheet; desktop is a 400px drawer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-sheet',
        ocrText: '食べた',
      );
      await tester.tap(find.byKey(PageDetailKeys.ocrText));
      await tester.pumpAndSettle();

      expect(find.byKey(LookupSheetKeys.modal), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.drawer), findsNothing);
      expect(
        tester.getSize(find.byKey(LookupSheetKeys.modal)).height,
        closeTo(844 * PageLayout.lookupSheetFraction, 0.5),
      );
      _expectSheetRadius(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PageDetailKeys.ocrText));
      await tester.pumpAndSettle();

      expect(find.byKey(LookupSheetKeys.drawer), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.modal), findsNothing);
      expect(
        tester.getSize(find.byKey(LookupSheetKeys.drawer)).width,
        PageLayout.lookupDrawerWidth,
      );
      expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.empty), findsNothing);
    },
  );

  testWidgets('desktop drawer starts empty until a token is tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: 'page-drawer-empty',
      ocrText: '食べた',
    );

    expect(find.byKey(LookupSheetKeys.drawer), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.empty), findsOneWidget);
    expect(find.byKey(LookupSheetKeys.sheet), findsNothing);
    expect(find.text(PageLabels.toquePalavra), findsOneWidget);
  });

  testWidgets('desktop command bar is Voltar · meta · Editar · +', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const pageId = 'page-desktop-meta';
    await _openPage(
      tester,
      jmdictPath: jmdictPath,
      pageId: pageId,
      ocrText: '食べた',
    );

    expect(find.byKey(ShellKeys.taskDock), findsNothing);
    expect(find.byKey(ShellKeys.commandBar), findsOneWidget);
    expect(find.byKey(ShellKeys.command('back')), findsOneWidget);
    expect(find.byKey(ShellKeys.dockMeta), findsOneWidget);
    expect(find.byKey(ShellKeys.command('edit')), findsOneWidget);
    expect(find.byKey(ShellKeys.command('add')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ShellKeys.dockMeta),
        matching: find.text(pageId),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ShellKeys.dockMeta),
        matching: find.text(RecortesLabel.count(1)),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(ShellKeys.command('back'))).dx,
      lessThan(tester.getTopLeft(find.byKey(ShellKeys.dockMeta)).dx),
    );
    expect(
      tester.getTopLeft(find.byKey(ShellKeys.dockMeta)).dx,
      lessThan(tester.getTopLeft(find.byKey(ShellKeys.command('edit'))).dx),
    );
    expect(
      tester.getTopLeft(find.byKey(ShellKeys.command('edit'))).dx,
      lessThan(tester.getTopLeft(find.byKey(ShellKeys.command('add'))).dx),
    );
  });

  testWidgets(
    'desktop drawer marks Aprendendo active with coral ring and 14% ink',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-drawer-learn',
        ocrText: '食べた',
        seed: _seedTaberuLearning,
      );

      await tester.tap(find.byKey(PageDetailKeys.ocrText));
      await tester.pumpAndSettle();

      expect(find.byKey(LookupSheetKeys.drawer), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.modal), findsNothing);
      _expectAprendendoActive(tester);
    },
  );

  testWidgets(
    'mobile lookup sheet marks Aprendendo active with coral ring and 14% ink',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openPage(
        tester,
        jmdictPath: jmdictPath,
        pageId: 'page-sheet-learn',
        ocrText: '食べた',
        seed: _seedTaberuLearning,
      );

      await tester.tap(find.byKey(PageDetailKeys.ocrText));
      await tester.pumpAndSettle();

      expect(find.byKey(LookupSheetKeys.modal), findsOneWidget);
      expect(find.byKey(LookupSheetKeys.drawer), findsNothing);
      expect(
        tester.getSize(find.byKey(LookupSheetKeys.modal)).height,
        closeTo(844 * PageLayout.lookupSheetFraction, 0.5),
      );
      _expectSheetRadius(tester);
      _expectAprendendoActive(tester);
    },
  );

  for (final size in [_phone, _desktop]) {
    testWidgets(
      'page meta is 1 recorte singular at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        _setSize(tester, size);
        await _openPage(
          tester,
          jmdictPath: jmdictPath,
          pageId: 'page-one-crop',
          ocrText: '食べた',
        );
        expect(find.text(RecortesLabel.count(1)), findsOneWidget);
        expect(find.text('1 recortes'), findsNothing);
      },
    );

    testWidgets(
      'page meta is 2 recortes plural at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        _setSize(tester, size);
        await _openPage(
          tester,
          jmdictPath: jmdictPath,
          pageId: 'page-two-crops',
          ocrText: '食べた',
          extraCrops: 1,
        );
        expect(find.text(RecortesLabel.count(2)), findsOneWidget);
        expect(find.text('1 recorte'), findsNothing);
      },
    );
  }
}

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

const _lookupShortcuts =
    <
      ({
        String label,
        LogicalKeyboardKey key,
        WordState state,
        bool createsCard,
      })
    >[
      (
        label: 'A',
        key: LogicalKeyboardKey.keyA,
        state: WordState.learning,
        createsCard: true,
      ),
      (
        label: 'K',
        key: LogicalKeyboardKey.keyK,
        state: WordState.known,
        createsCard: false,
      ),
      (
        label: 'I',
        key: LogicalKeyboardKey.keyI,
        state: WordState.ignored,
        createsCard: false,
      ),
      (
        label: 'S',
        key: LogicalKeyboardKey.keyS,
        state: WordState.saved,
        createsCard: false,
      ),
    ];

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectSheetRadius(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .ancestor(
          of: find.byKey(LookupSheetKeys.modal),
          matching: find.byType(Material),
        )
        .first,
  );
  final shape = material.shape! as RoundedRectangleBorder;
  expect(
    shape.borderRadius,
    const BorderRadius.vertical(top: Radius.circular(AppRadius.sheetReview)),
  );
}

Future<void> _seedTaberuLearning(AppDatabase db, String cropId) async {
  final words = WordsRepository(db);
  final cards = FlashcardsRepository(db);
  await cards.learn(
    await words.saveFromLookup(
      cropId: cropId,
      seq: 1358280,
      lemma: '食べる',
      reading: 'たべる',
    ),
  );
}

void _expectAprendendoActive(WidgetTester tester) {
  expect(
    tester.widget<LookupActionButton>(find.byKey(LookupSheetKeys.learn)).active,
    isTrue,
  );
  expect(
    tester.widget<LookupActionButton>(find.byKey(LookupSheetKeys.known)).active,
    isFalse,
  );
  expect(
    tester.widget<LookupActionButton>(find.byKey(LookupSheetKeys.save)).active,
    isFalse,
  );
  expect(
    tester
        .widget<LookupActionButton>(find.byKey(LookupSheetKeys.ignore))
        .active,
    isFalse,
  );
  final material = tester.widget<Material>(
    find.descendant(
      of: find.byKey(LookupSheetKeys.learn),
      matching: find.byType(Material),
    ),
  );
  expect(
    material.color,
    Color.alphaBlend(AppColors.overlayEstadoAtivo, AppColors.surface),
  );
  final shape = material.shape! as RoundedRectangleBorder;
  expect(shape.side.color, AppColors.coral);
  expect(shape.side.width, 1.5);
}

Future<AppDatabase> _openPage(
  WidgetTester tester, {
  required String jmdictPath,
  required String pageId,
  required String ocrText,
  int extraCrops = 0,
  Future<void> Function(AppDatabase db, String cropId)? seed,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  final pages = PagesRepository(db);
  await pages.saveRecognizedCrop(
    pageId: pageId,
    sourceSha256: sha256Hex(fixturePng()),
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: ocrText,
    engineId: 'fake',
  );
  for (var i = 0; i < extraCrops; i++) {
    await pages.saveRecognizedCrop(
      pageId: pageId,
      sourceSha256: sha256Hex(fixturePng()),
      left: 0.1 + i * 0.05,
      top: 0.1,
      width: 0.3,
      height: 0.3,
      ocrText: '文$i',
      engineId: 'fake',
    );
  }
  if (seed != null) {
    final cropId = (await db.select(db.capturedCrops).get()).single.id;
    await seed(db, cropId);
  }

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

Offset _glyphLocal(
  RenderParagraph paragraph, {
  required int start,
  required int end,
  required bool rightHalf,
}) {
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  expect(boxes, isNotEmpty);
  var rect = boxes.first.toRect();
  for (final box in boxes.skip(1)) {
    rect = rect.expandToInclude(box.toRect());
  }
  expect(rect.width, greaterThan(4));
  return Offset(rightHalf ? rect.right - 2 : rect.left + 2, rect.center.dy);
}

Offset _emptyAfterLine(RenderParagraph paragraph, {required int lineIndex}) {
  final text = paragraph.text.toPlainText();
  final boxes = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .map((box) => box.toRect())
      .toList();
  expect(boxes, isNotEmpty);
  final tops = boxes.map((rect) => rect.top).toSet().toList()..sort();
  expect(tops.length, greaterThan(lineIndex));
  final top = tops[lineIndex];
  final onLine = boxes.where((rect) => (rect.top - top).abs() < 1);
  final last = onLine.reduce((a, b) => a.right >= b.right ? a : b);
  final x = math.min(last.right + 8, paragraph.size.width - 1);
  expect(x, greaterThan(last.right));
  final local = Offset(x, last.center.dy);
  expect(
    boxes.any((rect) => rect.contains(local)),
    isFalse,
    reason: 'probe must sit outside every glyph box',
  );
  return local;
}

Color? _spanColor(WidgetTester tester, String needle) {
  return _spanStyle(tester, needle)?.color;
}

Color? _spanBackground(WidgetTester tester, String needle) {
  return _spanStyle(tester, needle)?.backgroundColor;
}

TextStyle? _spanStyle(WidgetTester tester, String needle) {
  final text = tester.widget<Text>(find.byKey(PageDetailKeys.ocrText));
  TextStyle? found;
  void walk(InlineSpan span) {
    if (span is! TextSpan) {
      return;
    }
    if (span.text != null && span.text!.contains(needle)) {
      found = span.style;
    }
    span.children?.forEach(walk);
  }

  walk(text.textSpan!);
  return found;
}

Future<void> _expectTakaiLookup(WidgetTester tester) async {
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
  expect(
    find.descendant(
      of: find.byKey(LookupSheetKeys.sheet),
      matching: find.text('い'),
    ),
    findsNothing,
  );
}
