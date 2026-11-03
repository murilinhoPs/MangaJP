import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_kanji_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_labels.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_word_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../dictionary/bake_jmdict_fixture.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('notebook_kanji_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= AppBreakpoints.wide;

    testWidgets(
      'Kanji tab lists newest first with on/kun/meanings/strokes at $label',
      (tester) async {
        final env = await _openNotebook(
          tester,
          jmdictPath: jmdictPath,
          size: size,
        );

        expect(find.byKey(NotebookKeys.tabKanji), findsOneWidget);
        expect(find.byKey(NotebookKeys.tabWords), findsOneWidget);
        await tester.tap(find.byKey(NotebookKeys.tabKanji));
        await tester.pumpAndSettle();

        expect(find.text(NotebookLabels.kanjiSearchHint), findsOneWidget);
        expect(find.byKey(NotebookKeys.stateAll), findsNothing);
        expect(find.byKey(NotebookKeys.kanjiList), findsOneWidget);

        final literals = _listLiterals(tester);
        expect(literals, ['食', '高', '猫']);
        expect(
          tester.getTopLeft(find.byKey(NotebookKeys.kanjiRow('食'))).dy,
          lessThan(
            tester.getTopLeft(find.byKey(NotebookKeys.kanjiRow('高'))).dy,
          ),
        );

        expect(find.text('ON ショク · ジキ'), findsOneWidget);
        expect(find.textContaining('た.べる'), findsWidgets);
        expect(find.text('eat; food'), findsOneWidget);
        expect(find.text('TRAÇOS 9'), findsOneWidget);
        expect(find.text('食べる'), findsWidgets);
        expect(find.byKey(NotebookKeys.kanjiNoDict('猫')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(NotebookKeys.kanjiRow('食')),
            matching: find.text(NotebookLabels.kanjiNoDict),
          ),
          findsNothing,
        );

        if (wide) {
          expect(find.byKey(ShellKeys.rail), findsOneWidget);
          expect(find.byKey(ShellKeys.navCards), findsNothing);
        } else {
          expect(find.byKey(ShellKeys.navCards), findsOneWidget);
          expect(find.byKey(ShellKeys.rail), findsNothing);
        }

        expect(await env.db.select(env.db.userCards).get(), isEmpty);
      },
    );

    testWidgets('Kanji empty and search miss copy at $label', (tester) async {
      await _openNotebook(
        tester,
        jmdictPath: jmdictPath,
        size: size,
        seedKanji: false,
      );
      await tester.tap(find.byKey(NotebookKeys.tabKanji));
      await tester.pumpAndSettle();

      expect(find.byKey(NotebookKeys.kanjiEmpty), findsOneWidget);
      expect(find.text(NotebookLabels.kanjiEmpty), findsOneWidget);
      expect(find.text(NotebookLabels.kanjiEmptyHint), findsOneWidget);
      expect(find.textContaining('lookup'), findsNothing);
      expect(find.text(NotebookLabels.kanjiWatermark), findsOneWidget);
      expect(find.byKey(NotebookKeys.kanjiNoResults), findsNothing);
    });

    testWidgets(
      'saved kanji without KANJIDIC2 shows sem dados do dicionário at $label',
      (tester) async {
        await _openNotebook(tester, jmdictPath: jmdictPath, size: size);
        await tester.tap(find.byKey(NotebookKeys.tabKanji));
        await tester.pumpAndSettle();

        expect(find.byKey(NotebookKeys.kanjiRow('猫')), findsOneWidget);
        expect(find.byKey(NotebookKeys.kanjiNoDict('猫')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(NotebookKeys.kanjiRow('猫')),
            matching: find.text(NotebookLabels.kanjiNoDict),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(NotebookKeys.kanjiRow('猫')));
        await tester.pumpAndSettle();
        expect(find.byType(NotebookKanjiPage), findsOneWidget);
        expect(find.byKey(NotebookKanjiKeys.noDict), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(NotebookKanjiKeys.noDict)).data,
          NotebookLabels.kanjiNoDict,
        );
        expect(find.byKey(NotebookKanjiKeys.on), findsNothing);
        expect(find.byKey(NotebookKanjiKeys.kun), findsNothing);
        expect(find.byKey(NotebookKanjiKeys.meanings), findsNothing);
        expect(find.byKey(NotebookKanjiKeys.strokes), findsNothing);
      },
    );

    testWidgets('Kanji search matches reading and meaning at $label', (
      tester,
    ) async {
      await _openNotebook(tester, jmdictPath: jmdictPath, size: size);
      await tester.tap(find.byKey(NotebookKeys.tabKanji));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(NotebookKeys.search), 'ショク');
      await tester.pumpAndSettle();
      expect(find.byKey(NotebookKeys.kanjiRow('食')), findsOneWidget);
      expect(find.byKey(NotebookKeys.kanjiRow('高')), findsNothing);

      await tester.enterText(find.byKey(NotebookKeys.search), 'tall');
      await tester.pumpAndSettle();
      expect(find.byKey(NotebookKeys.kanjiRow('高')), findsOneWidget);
      expect(find.byKey(NotebookKeys.kanjiRow('食')), findsNothing);

      await tester.enterText(find.byKey(NotebookKeys.search), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.byKey(NotebookKeys.kanjiNoResults), findsOneWidget);
      expect(find.text(NotebookLabels.noResults), findsOneWidget);
      expect(find.text(NotebookLabels.kanjiNoResultsHint), findsOneWidget);
      expect(find.byKey(NotebookKeys.kanjiEmpty), findsNothing);
    });

    testWidgets('Kanji detail shows fields, words, and Remover at $label', (
      tester,
    ) async {
      await _openNotebook(tester, jmdictPath: jmdictPath, size: size);
      await tester.tap(find.byKey(NotebookKeys.tabKanji));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NotebookKeys.kanjiRow('食')));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookKanjiPage), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(NotebookKanjiPage)))
            .state
            .uri
            .path,
        '/notebook/kanji/${Uri.encodeComponent('食')}',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookKanjiKeys.literal)).data,
        '食',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookKanjiKeys.on)).data,
        'ショク · ジキ',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookKanjiKeys.kun)).data,
        contains('た.べる'),
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookKanjiKeys.meanings)).data,
        'eat; food',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookKanjiKeys.strokes)).data,
        '9',
      );
      expect(find.byKey(NotebookKanjiKeys.words), findsOneWidget);
      expect(find.byKey(NotebookKanjiKeys.word('eat')), findsOneWidget);
      expect(find.text(NotebookLabels.aprender), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(DeckPage), findsNothing);
      expect(find.byKey(NotebookKanjiKeys.remove), findsOneWidget);

      if (wide) {
        expect(find.byKey(ShellKeys.rail), findsOneWidget);
      } else {
        expect(find.byKey(ShellKeys.navCards), findsOneWidget);
      }
    });

    testWidgets('Remover do Caderno deletes the kanji at $label', (
      tester,
    ) async {
      final env = await _openNotebook(
        tester,
        jmdictPath: jmdictPath,
        size: size,
      );
      await tester.tap(find.byKey(NotebookKeys.tabKanji));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NotebookKeys.kanjiRow('食')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(NotebookKanjiKeys.remove),
        80,
        scrollable: find.descendant(
          of: find.byType(NotebookKanjiPage),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(NotebookKanjiKeys.remove));
      await tester.pumpAndSettle();
      expect(find.text('Remover do Caderno?'), findsOneWidget);
      expect(find.text(NotebookLabels.kanjiRemoveBody), findsOneWidget);
      expect(find.text('Apagar o card também?'), findsNothing);
      await tester.tap(find.byKey(NotebookKanjiKeys.removeConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookPage), findsOneWidget);
      expect(find.byKey(NotebookKeys.kanjiRow('食')), findsNothing);
      expect(find.byKey(NotebookKeys.kanjiRow('高')), findsOneWidget);
      expect(
        (await env.db.select(env.db.savedKanji).get())
            .map((row) => row.literal)
            .toSet(),
        {'高', '猫'},
      );
      expect(await env.db.select(env.db.userWords).get(), isNotEmpty);
    });

    testWidgets('removing a Caderno word drops it from the 食 row at $label', (
      tester,
    ) async {
      await _openNotebook(tester, jmdictPath: jmdictPath, size: size);
      await tester.tap(find.byKey(NotebookKeys.tabKanji));
      await tester.pumpAndSettle();
      expect(find.byKey(NotebookKeys.kanjiRow('食')), findsOneWidget);
      expect(find.text('食べる'), findsWidgets);

      await tester.tap(find.byKey(NotebookKeys.kanjiRow('食')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NotebookKanjiKeys.word('eat')));
      await tester.pumpAndSettle();
      expect(find.byType(NotebookWordPage), findsOneWidget);

      final remove = find.byKey(NotebookWordKeys.removeFromNotebook);
      await tester.scrollUntilVisible(
        remove,
        80,
        scrollable: find.descendant(
          of: find.byType(NotebookWordPage),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(NotebookWordKeys.removeFromNotebookConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookPage), findsOneWidget);
      expect(find.byKey(NotebookKeys.kanjiRow('食')), findsOneWidget);
      expect(find.text('食べる'), findsNothing);
      expect(find.byKey(NotebookKanjiKeys.word('eat')), findsNothing);
    });
  }

  testWidgets('related word on the kanji detail opens the word page', (
    tester,
  ) async {
    await _openNotebook(tester, jmdictPath: jmdictPath);
    await tester.tap(find.byKey(NotebookKeys.tabKanji));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NotebookKeys.kanjiRow('食')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NotebookKanjiKeys.word('eat')));
    await tester.pumpAndSettle();
    expect(find.byType(NotebookWordPage), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data, '食べる');
  });
}

class _Env {
  const _Env({required this.db});

  final AppDatabase db;
}

Future<_Env> _openNotebook(
  WidgetTester tester, {
  required String jmdictPath,
  Size size = _phone,
  bool seedKanji = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  await db.wordsDao.insertWord(
    UserWordsCompanion.insert(
      id: 'eat',
      seq: 1358280,
      lemma: '食べる',
      reading: 'たべる',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: 'eat',
          state: WordState.saved.name,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
  if (seedKanji) {
    await db
        .into(db.savedKanji)
        .insert(
          SavedKanjiCompanion.insert(
            literal: '食',
            savedAt: DateTime.utc(2026, 3, 1),
          ),
        );
    await db
        .into(db.savedKanji)
        .insert(
          SavedKanjiCompanion.insert(
            literal: '高',
            savedAt: DateTime.utc(2026, 2, 1),
          ),
        );
    await db
        .into(db.savedKanji)
        .insert(
          SavedKanjiCompanion.insert(
            literal: '猫',
            savedAt: DateTime.utc(2026, 1, 1),
          ),
        );
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
  const NotebookRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  return _Env(db: db);
}

List<String> _listLiterals(WidgetTester tester) {
  final inks = tester.widgetList<InkWell>(
    find.descendant(
      of: find.byKey(NotebookKeys.kanjiList),
      matching: find.byType(InkWell),
    ),
  );
  return [
    for (final ink in inks)
      if (ink.key is ValueKey<String>)
        (ink.key! as ValueKey<String>).value.replaceFirst(
          'notebook-kanji-row-',
          '',
        ),
  ];
}
