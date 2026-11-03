import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/theme/app_breakpoints.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/core/shell/kbd_chip.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/dictionary/presentation/kanji_sheet.dart';
import 'package:manga_jp/features/dictionary/presentation/lookup_sheet.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_labels.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/domain/page_labels.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';

import '../capture/fixture_png.dart';
import 'bake_jmdict_fixture.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;
  late String emptyKanjiPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('kanji_sheet_');
    jmdictPath = await bakeJmdictFixture(tmp);
    emptyKanjiPath = await bakeJmdictFixture(
      Directory('${tmp.path}${Platform.pathSeparator}empty'),
      withKanji: false,
    );
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= AppBreakpoints.wide;

    testWidgets('tapping 食 on the word ficha opens KANJIDIC2 sheet at $label', (
      tester,
    ) async {
      final db = await _openLookup(tester, jmdictPath: jmdictPath, size: size);

      expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
      _expectSaveShortcut(tester, LookupSheetKeys.save, wide: wide);
      await tester.tap(find.byKey(LookupSheetKeys.kanji('食')));
      await tester.pumpAndSettle();

      expect(find.byKey(KanjiSheetKeys.sheet), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(KanjiSheetKeys.literal)).data, '食');
      expect(
        tester.widget<Text>(find.byKey(KanjiSheetKeys.on)).data,
        'ショク · ジキ',
      );
      expect(
        tester.widget<Text>(find.byKey(KanjiSheetKeys.kun)).data,
        contains('た.べる'),
      );
      expect(
        tester.widget<Text>(find.byKey(KanjiSheetKeys.meanings)).data,
        'eat; food',
      );
      expect(tester.widget<Text>(find.byKey(KanjiSheetKeys.strokes)).data, '9');
      expect(find.text(NotebookLabels.salvarKanji), findsOneWidget);
      expect(find.byKey(KanjiSheetKeys.save), findsOneWidget);
      _expectSaveShortcut(tester, KanjiSheetKeys.save, wide: wide);

      await tester.tap(find.byKey(KanjiSheetKeys.save));
      await tester.pumpAndSettle();

      final saved = await db.select(db.savedKanji).get();
      expect(saved, hasLength(1));
      expect(saved.single.literal, '食');
      expect(saved.single.originPageId, 'page-tabeta');
      expect(await db.select(db.userWords).get(), isEmpty);
      expect(await db.select(db.userWordStates).get(), isEmpty);
      expect(await db.select(db.userCards).get(), isEmpty);
      expect(find.byKey(KanjiSheetKeys.sheet), findsNothing);
    });

    testWidgets(
      'ficha opens without KANJIDIC2 rows and Salvar kanji still works at $label',
      (tester) async {
        final db = await _openLookup(
          tester,
          jmdictPath: emptyKanjiPath,
          size: size,
        );

        expect(find.byKey(LookupSheetKeys.sheet), findsOneWidget);
        await tester.tap(find.byKey(LookupSheetKeys.kanji('食')));
        await tester.pumpAndSettle();

        expect(find.byKey(KanjiSheetKeys.sheet), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(KanjiSheetKeys.literal)).data,
          '食',
        );
        expect(find.byKey(KanjiSheetKeys.on), findsNothing);
        expect(find.byKey(KanjiSheetKeys.kun), findsNothing);
        expect(find.byKey(KanjiSheetKeys.meanings), findsNothing);
        expect(find.byKey(KanjiSheetKeys.strokes), findsNothing);
        expect(find.byKey(KanjiSheetKeys.save), findsOneWidget);

        await tester.tap(find.byKey(KanjiSheetKeys.save));
        await tester.pumpAndSettle();
        expect((await db.select(db.savedKanji).get()).single.literal, '食');
      },
    );

    testWidgets('meanings stay reachable above pinned Salvar kanji at $label', (
      tester,
    ) async {
      await _openLookup(tester, jmdictPath: jmdictPath, size: size);
      await tester.tap(find.byKey(LookupSheetKeys.kanji('食')));
      await tester.pumpAndSettle();

      expect(find.byKey(KanjiSheetKeys.sheet), findsOneWidget);
      expect(find.byKey(KanjiSheetKeys.save), findsOneWidget);
      final saveBefore = tester.getRect(find.byKey(KanjiSheetKeys.save));
      expect(saveBefore.height, greaterThan(0));
      final modalRect = tester.getRect(find.byKey(KanjiSheetKeys.modal));
      expect(
        modalRect.bottom - saveBefore.bottom,
        lessThan(24),
        reason: 'Salvar kanji must sit at the bottom of the ficha, not above the command bar',
      );

      final scrollable = find.descendant(
        of: find.byKey(KanjiSheetKeys.sheet),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      final extent = tester
          .state<ScrollableState>(scrollable)
          .position
          .maxScrollExtent;
      if (extent > 0.5) {
        expect(find.byKey(KanjiSheetKeys.scrollEdge), findsOneWidget);
      }

      await tester.ensureVisible(find.byKey(KanjiSheetKeys.meanings));
      await tester.pumpAndSettle();

      expect(find.text(NotebookLabels.salvarKanji), findsOneWidget);
      final meaningsRect = tester.getRect(find.byKey(KanjiSheetKeys.meanings));
      final saveRect = tester.getRect(find.byKey(KanjiSheetKeys.save));
      expect(
        meaningsRect.overlaps(saveRect),
        isFalse,
        reason: 'meanings must not sit under Salvar kanji',
      );
      expect(saveRect, saveBefore);

      expect(
        _hitIncludes(
          tester,
          find.byKey(KanjiSheetKeys.save),
          at: tester.getCenter(find.byKey(KanjiSheetKeys.meanings)),
        ),
        isFalse,
        reason: 'Salvar kanji must not steal the meanings hit-test',
      );
      expect(
        _hitIncludes(
          tester,
          find.byKey(KanjiSheetKeys.meanings),
          at: tester.getCenter(find.byKey(KanjiSheetKeys.meanings)),
        ),
        isTrue,
      );

      if (extent > 0.5) {
        await tester.scrollUntilVisible(
          find.byKey(KanjiSheetKeys.strokes),
          80,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .getRect(find.byKey(KanjiSheetKeys.strokes))
              .overlaps(tester.getRect(find.byKey(KanjiSheetKeys.save))),
          isFalse,
        );
        expect(find.byKey(KanjiSheetKeys.scrollEdge), findsNothing);
      }
      expect(find.byKey(KanjiSheetKeys.save), findsOneWidget);
    });

    testWidgets(
      'page bar does not receive taps while kanji ficha is open at $label',
      (tester) async {
        await _openLookup(tester, jmdictPath: jmdictPath, size: size);
        await tester.tap(find.byKey(LookupSheetKeys.kanji('食')));
        await tester.pumpAndSettle();
        expect(find.byKey(KanjiSheetKeys.sheet), findsOneWidget);

        final edit = wide
            ? find.byKey(ShellKeys.command('edit'))
            : find.byKey(PageDetailKeys.edit);
        final add = wide
            ? find.byKey(ShellKeys.command('add'))
            : find.byKey(PageDetailKeys.add);
        expect(edit, findsOneWidget);
        expect(add, findsOneWidget);

        expect(_hitIncludes(tester, edit), isFalse);
        expect(_hitIncludes(tester, add), isFalse);

        await tester.tapAt(tester.getCenter(edit));
        await tester.pumpAndSettle();
        expect(find.byKey(PageDetailKeys.ocrEditor), findsNothing);
        expect(find.text(PageLabels.editarOcrTitulo), findsNothing);
        expect(find.byType(CapturePage), findsNothing);
        expect(find.byType(PageDetailPage), findsOneWidget);

        if (find.byKey(KanjiSheetKeys.sheet).evaluate().isEmpty) {
          await tester.tap(find.byKey(LookupSheetKeys.kanji('食')));
          await tester.pumpAndSettle();
          expect(find.byKey(KanjiSheetKeys.sheet), findsOneWidget);
        }

        await tester.tapAt(tester.getCenter(add));
        await tester.pumpAndSettle();
        expect(find.byType(CapturePage), findsNothing);
        expect(find.byKey(PageDetailKeys.ocrEditor), findsNothing);
        expect(find.byType(PageDetailPage), findsOneWidget);
      },
    );
  }

  test('wide breakpoint stays 900', () {
    expect(AppBreakpoints.wide, 900);
  });
}

Future<AppDatabase> _openLookup(
  WidgetTester tester, {
  required String jmdictPath,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await PagesRepository(db).saveRecognizedCrop(
    pageId: 'page-tabeta',
    sourceSha256: sha256Hex(fixturePng()),
    left: 0.2,
    top: 0.2,
    width: 0.6,
    height: 0.6,
    ocrText: '食べた',
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

  const PageDetailRoute(id: 'page-tabeta')
      .go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(PageDetailKeys.ocrText));
  await tester.pumpAndSettle();
  return db;
}

bool _hitIncludes(WidgetTester tester, Finder finder, {Offset? at}) {
  final root = tester.renderObject(finder);
  final hit = tester.hitTestOnBinding(at ?? tester.getCenter(finder));
  return hit.path.any((entry) {
    final target = entry.target;
    if (target is! RenderObject) {
      return false;
    }
    RenderObject? node = target;
    while (node != null) {
      if (node == root) {
        return true;
      }
      node = node.parent;
    }
    return false;
  });
}

void _expectSaveShortcut(
  WidgetTester tester,
  Key button, {
  required bool wide,
}) {
  final chip = find.descendant(
    of: find.byKey(button),
    matching: find.byType(KbdChip),
  );
  if (wide) {
    expect(chip, findsOneWidget);
    expect(tester.widget<KbdChip>(chip).label, 'S');
  } else {
    expect(chip, findsNothing);
  }
}
