import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_word_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../dictionary/bake_jmdict_fixture.dart';

const _taberuSeq = 1358280;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String jmdictPath;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('notebook_word_');
    jmdictPath = await bakeJmdictFixture(tmp);
  });

  tearDownAll(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  test('gloss is loaded from JMdict by seq, not stored or hardcoded', () {
    expect(JmdictService.assetPath, 'assets/dict/jmdict.sqlite');
    for (final path in [
      'lib/features/notebook/presentation/notebook_word_page.dart',
      'lib/features/notebook/presentation/notebook_controller.dart',
      'lib/features/notebook/data/notebook_repository.dart',
      'lib/features/notebook/domain/notebook_word_detail.dart',
      'lib/core/database/tables/user_words.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src, isNot(contains('to eat')), reason: path);
      expect(src, isNot(contains('to live on')), reason: path);
    }
    expect(
      File('lib/core/database/tables/user_words.dart').readAsStringSync(),
      isNot(contains('gloss')),
    );
    expect(
      File('lib/features/notebook/data/notebook_repository.dart')
          .readAsStringSync(),
      isNot(contains('gloss')),
    );
  });

  testWidgets(
    'tap on the list opens /notebook/word/:id with lemma, reading, state, '
    'fixture gloss, and first crop sentence',
    (tester) async {
      final env = await _openNotebook(tester, jmdictPath: jmdictPath);

      expect(find.byType(NotebookPage), findsOneWidget);
      expect(find.byType(NotebookWordPage), findsNothing);

      await tester.tap(find.byKey(NotebookKeys.row(env.wordId)));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookWordPage), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(NotebookWordPage)))
            .state
            .uri
            .path,
        '/notebook/word/${env.wordId}',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data,
        '食べる',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.reading)).data,
        'たべる',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Salvo',
      );

      final gloss = tester
          .widget<Text>(find.byKey(NotebookWordKeys.gloss))
          .data!;
      final jmdict = JmdictService()..openFile(jmdictPath);
      addTearDown(jmdict.close);
      final entry = jmdict.entryBySeq(_taberuSeq)!;
      expect(gloss, entry.glossText);
      expect(gloss, contains('to eat'));
      expect(gloss, contains('to live on (e.g. a salary)'));
      final dataJson =
          jmdict.database.select(
                'SELECT data_json FROM entries WHERE seq = ?',
                [_taberuSeq],
              ).single['data_json']
              as String;
      for (final item in entry.glosses) {
        expect(dataJson, contains(item));
      }

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.sentence)).data,
        '食べたよ、相棒',
      );
      expect(find.text('later sentence'), findsNothing);
      expect(find.byKey(NotebookWordKeys.pageLink), findsOneWidget);

      _expectReadOnly(tester);
      final states = await env.db.select(env.db.userWordStates).get();
      expect(states, hasLength(1));
      expect(states.single.state, WordState.saved.name);
      expect(states.single.updatedAt, env.savedAt);
    },
  );

  testWidgets('page link goes to the first crop page', (tester) async {
    final env = await _openNotebook(tester, jmdictPath: jmdictPath);

    await tester.tap(find.byKey(NotebookKeys.row(env.wordId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NotebookWordKeys.pageLink));
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/${env.pageId}',
    );
    expect(find.text('食べたよ、相棒'), findsOneWidget);
    expect(find.text('later sentence'), findsNothing);

    _expectReadOnly(tester);
    final states = await env.db.select(env.db.userWordStates).get();
    expect(states.single.state, WordState.saved.name);
    expect(states.single.updatedAt, env.savedAt);
  });
}

class _Env {
  const _Env({
    required this.db,
    required this.wordId,
    required this.pageId,
    required this.savedAt,
  });

  final AppDatabase db;
  final String wordId;
  final String pageId;
  final DateTime savedAt;
}

Future<_Env> _openNotebook(
  WidgetTester tester, {
  required String jmdictPath,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  const wordId = 'eat';
  const pageId = 'page-eat';
  final savedAt = DateTime.utc(2026, 1, 1);

  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: wordId,
          seq: _taberuSeq,
          lemma: '食べる',
          reading: 'たべる',
          createdAt: savedAt,
        ),
      );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: wordId,
          state: WordState.saved.name,
          updatedAt: savedAt,
        ),
      );
  await _seedCrop(
    db,
    cropId: 'crop-later',
    pageId: 'page-later',
    ocrText: 'later sentence',
    createdAt: DateTime.utc(2026, 1, 3),
  );
  await _seedCrop(
    db,
    cropId: 'crop-first',
    pageId: pageId,
    ocrText: '食べたよ、相棒',
    createdAt: DateTime.utc(2026, 1, 4),
  );
  await db
      .into(db.cropWords)
      .insert(
        CropWordsCompanion.insert(
          cropId: 'crop-first',
          wordId: wordId,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );
  await db
      .into(db.cropWords)
      .insert(
        CropWordsCompanion.insert(
          cropId: 'crop-later',
          wordId: wordId,
          createdAt: DateTime.utc(2026, 1, 5),
        ),
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

  const NotebookRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
  return _Env(db: db, wordId: wordId, pageId: pageId, savedAt: savedAt);
}

Future<void> _seedCrop(
  AppDatabase db, {
  required String cropId,
  required String pageId,
  required String ocrText,
  required DateTime createdAt,
}) async {
  await db
      .into(db.capturedPages)
      .insert(
        CapturedPagesCompanion.insert(
          id: pageId,
          sha256: pageId,
          createdAt: createdAt,
        ),
        mode: InsertMode.insertOrIgnore,
      );
  await db
      .into(db.capturedCrops)
      .insert(
        CapturedCropsCompanion.insert(
          id: cropId,
          pageId: pageId,
          ocrText: ocrText,
          engineId: 'fake',
          left: 0.1,
          top: 0.1,
          width: 0.5,
          height: 0.5,
          createdAt: createdAt,
        ),
      );
}

void _expectReadOnly(WidgetTester tester) {
  expect(find.text('Aprender'), findsNothing);
  expect(find.text('Remover'), findsNothing);
  expect(find.text('Remove'), findsNothing);
  expect(find.text('Add card'), findsNothing);
  expect(find.text('Salvar'), findsNothing);
  expect(find.byType(DeckPage), findsNothing);
  expect(find.byIcon(Icons.delete_outline), findsNothing);
  expect(find.byIcon(Icons.style), findsNothing);
}
