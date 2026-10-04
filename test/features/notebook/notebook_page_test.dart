import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('/notebook lists word_states newest first by first_saved_at', (
    tester,
  ) async {
    await _openNotebook(
      tester,
      words: [
        _Seed(
          id: 'oldest',
          seq: 1,
          lemma: '古い',
          reading: 'ふるい',
          state: WordState.saved,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        _Seed(
          id: 'middle',
          seq: 2,
          lemma: '学ぶ',
          reading: 'まなぶ',
          state: WordState.learning,
          createdAt: DateTime.utc(2026, 2, 1),
        ),
        _Seed(
          id: 'newest',
          seq: 3,
          lemma: '知る',
          reading: 'しる',
          state: WordState.known,
          createdAt: DateTime.utc(2026, 3, 1),
        ),
      ],
    );

    final lemmas = _listLemmas(tester);
    expect(lemmas, ['知る', '学ぶ', '古い']);
    expect(
      tester.getTopLeft(find.byKey(NotebookKeys.row('newest'))).dy,
      lessThan(tester.getTopLeft(find.byKey(NotebookKeys.row('middle'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(NotebookKeys.row('middle'))).dy,
      lessThan(tester.getTopLeft(find.byKey(NotebookKeys.row('oldest'))).dy),
    );
  });

  testWidgets('/notebook search matches lemma and reading', (tester) async {
    await _openNotebook(
      tester,
      words: [
        _Seed(
          id: 'eat',
          seq: 10,
          lemma: '食べる',
          reading: 'たべる',
          state: WordState.saved,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        _Seed(
          id: 'drink',
          seq: 11,
          lemma: '飲む',
          reading: 'のむ',
          state: WordState.saved,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    await tester.enterText(find.byKey(NotebookKeys.search), '食べ');
    await tester.pumpAndSettle();
    expect(find.byKey(NotebookKeys.row('eat')), findsOneWidget);
    expect(find.byKey(NotebookKeys.row('drink')), findsNothing);

    await tester.enterText(find.byKey(NotebookKeys.search), 'のむ');
    await tester.pumpAndSettle();
    expect(find.byKey(NotebookKeys.row('drink')), findsOneWidget);
    expect(find.byKey(NotebookKeys.row('eat')), findsNothing);
  });

  testWidgets('/notebook state filter hides the other states', (tester) async {
    await _openNotebook(
      tester,
      words: [
        _Seed(
          id: 'saved',
          seq: 20,
          lemma: '保存',
          reading: 'ほぞん',
          state: WordState.saved,
          createdAt: DateTime.utc(2026, 1, 4),
        ),
        _Seed(
          id: 'learning',
          seq: 21,
          lemma: '学習',
          reading: 'がくしゅう',
          state: WordState.learning,
          createdAt: DateTime.utc(2026, 1, 3),
        ),
        _Seed(
          id: 'known',
          seq: 22,
          lemma: '既知',
          reading: 'きち',
          state: WordState.known,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        _Seed(
          id: 'ignored',
          seq: 23,
          lemma: '無視',
          reading: 'むし',
          state: WordState.ignored,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    await tester.tap(find.byKey(NotebookKeys.stateFilter(WordState.known)));
    await tester.pumpAndSettle();

    expect(find.byKey(NotebookKeys.row('known')), findsOneWidget);
    expect(find.byKey(NotebookKeys.row('saved')), findsNothing);
    expect(find.byKey(NotebookKeys.row('learning')), findsNothing);
    expect(find.byKey(NotebookKeys.row('ignored')), findsNothing);
    expect(_listLemmas(tester), ['既知']);
  });
}

class _Seed {
  const _Seed({
    required this.id,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.state,
    required this.createdAt,
  });

  final String id;
  final int seq;
  final String lemma;
  final String reading;
  final WordState state;
  final DateTime createdAt;
}

Future<void> _openNotebook(
  WidgetTester tester, {
  required List<_Seed> words,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  for (final word in words) {
    await db
        .into(db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: word.id,
            seq: word.seq,
            lemma: word.lemma,
            reading: word.reading,
            createdAt: word.createdAt,
          ),
        );
    await db
        .into(db.userWordStates)
        .insert(
          UserWordStatesCompanion.insert(
            wordId: word.id,
            state: word.state.name,
            updatedAt: word.createdAt,
          ),
        );
  }

  await tester.pumpWidget(
    MangaJpApp(overrides: [appDatabaseProvider.overrideWith((ref) => db)]),
  );
  await tester.pumpAndSettle();

  const NotebookRoute().go(tester.element(find.byType(HomePage)));
  await tester.pumpAndSettle();
}

List<String> _listLemmas(WidgetTester tester) {
  final tiles = tester.widgetList<ListTile>(
    find.descendant(
      of: find.byKey(NotebookKeys.list),
      matching: find.byType(ListTile),
    ),
  );
  return [
    for (final tile in tiles)
      if (tile.title case final Text title when title.data != null) title.data!,
  ];
}
