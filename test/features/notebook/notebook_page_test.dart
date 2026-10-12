import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/kbd_chip.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_labels.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
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

    await tester.ensureVisible(
      find.byKey(NotebookKeys.stateFilter(WordState.known)),
    );
    await tester.tap(find.byKey(NotebookKeys.stateFilter(WordState.known)));
    await tester.pumpAndSettle();

    expect(find.byKey(NotebookKeys.row('known')), findsOneWidget);
    expect(find.byKey(NotebookKeys.row('saved')), findsNothing);
    expect(find.byKey(NotebookKeys.row('learning')), findsNothing);
    expect(find.byKey(NotebookKeys.row('ignored')), findsNothing);
    expect(_listLemmas(tester), ['既知']);
  });

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= AppBreakpoints.wide;

    testWidgets('Caderno list uses DS tokens and row cards at $label', (
      tester,
    ) async {
      await _openNotebook(
        tester,
        size: size,
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
            id: 'learn',
            seq: 11,
            lemma: '学ぶ',
            reading: 'まなぶ',
            state: WordState.learning,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      expect(find.byType(NotebookPage), findsOneWidget);
      expect(find.byKey(NotebookKeys.list), findsOneWidget);
      expect(find.byKey(NotebookKeys.empty), findsNothing);
      expect(find.text(NotebookLabels.searchHint), findsOneWidget);
      expect(find.text(NotebookLabels.todos), findsOneWidget);

      if (wide) {
        expect(find.byKey(ShellKeys.rail), findsOneWidget);
        expect(find.byKey(ShellKeys.navCards), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(NotebookKeys.search),
            matching: find.byType(KbdChip),
          ),
          findsOneWidget,
        );
        final slash = tester.widget<Text>(
          find.descendant(
            of: find.byKey(NotebookKeys.search),
            matching: find.text('/'),
          ),
        );
        expect(slash.style?.fontFamily, AppFonts.mono);
      } else {
        expect(find.byKey(ShellKeys.navCards), findsOneWidget);
        expect(find.byKey(ShellKeys.rail), findsNothing);
        expect(find.text('/'), findsNothing);
      }

      final lemma = tester.widget<Text>(
        find.descendant(
          of: find.byKey(NotebookKeys.row('eat')),
          matching: find.text('食べる'),
        ),
      );
      expect(lemma.style?.fontFamily, AppFonts.jp);
      expect(lemma.style?.fontSize, 21);
      expect(lemma.style?.color, AppColors.text);

      final saved = tester.widget<Text>(
        find.descendant(
          of: find.byKey(NotebookKeys.row('eat')),
          matching: find.text('Salvo'),
        ),
      );
      expect(saved.style?.color, AppColors.text);
      final learning = tester.widget<Text>(
        find.descendant(
          of: find.byKey(NotebookKeys.row('learn')),
          matching: find.text('Aprendendo'),
        ),
      );
      expect(learning.style?.color, AppColors.violetText);

      final rowMaterial = tester.widget<Material>(
        find
            .ancestor(
              of: find.byKey(NotebookKeys.row('eat')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(rowMaterial.color, AppColors.surface);
      final shape = rowMaterial.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.linha));
      expect(shape.side.color, AppColors.border);

      final todos = tester.widget<FilterChip>(find.byKey(NotebookKeys.stateAll));
      expect(todos.selected, isTrue);
      expect(todos.side?.color, AppColors.coral);
      expect(todos.selectedColor, AppColors.overlayPrimaria);
    });

    testWidgets('Caderno empty state is not a search miss at $label', (
      tester,
    ) async {
      await _openNotebook(tester, size: size, words: const []);

      expect(find.byKey(NotebookKeys.empty), findsOneWidget);
      expect(find.byKey(NotebookKeys.noResults), findsNothing);
      expect(find.byKey(NotebookKeys.list), findsNothing);
      expect(find.text(NotebookLabels.empty), findsOneWidget);
      expect(find.text(NotebookLabels.emptyHint), findsOneWidget);
      expect(find.text(NotebookLabels.watermark), findsOneWidget);
      final title = tester.widget<Text>(find.byKey(NotebookKeys.empty));
      expect(title.style?.color, AppColors.text);
      final hint = tester.widget<Text>(find.text(NotebookLabels.emptyHint));
      expect(hint.style?.color, AppColors.text3);
      expect(hint.style?.color, isNot(AppColors.coral));
      final jp = tester.widget<Text>(find.text(NotebookLabels.watermark));
      expect(jp.style?.color, isNot(AppColors.coral));
      expect(jp.style?.fontFamily, AppFonts.jp);
    });

    testWidgets('Caderno search shows results and a miss empty at $label', (
      tester,
    ) async {
      await _openNotebook(
        tester,
        size: size,
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
      expect(find.byKey(NotebookKeys.empty), findsNothing);
      expect(find.byKey(NotebookKeys.noResults), findsNothing);

      await tester.enterText(find.byKey(NotebookKeys.search), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.byKey(NotebookKeys.noResults), findsOneWidget);
      expect(find.byKey(NotebookKeys.empty), findsNothing);
      expect(find.text(NotebookLabels.noResults), findsOneWidget);
      expect(find.text(NotebookLabels.noResultsHint), findsOneWidget);
      expect(find.byKey(NotebookKeys.list), findsNothing);
    });

    testWidgets(
      'Esc in Caderno search clears then blurs without shell shortcuts at $label',
      (tester) async {
        await _openNotebook(
          tester,
          size: size,
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

        await tester.tap(find.byKey(NotebookKeys.search));
        await tester.pump();
        await tester.enterText(find.byKey(NotebookKeys.search), '食べ');
        await tester.pumpAndSettle();
        expect(find.byKey(NotebookKeys.row('eat')), findsOneWidget);
        expect(find.byKey(NotebookKeys.row('drink')), findsNothing);

        final field = tester.widget<TextField>(find.byKey(NotebookKeys.search));
        expect(field.focusNode!.hasFocus, isTrue);
        expect(field.controller!.text, '食べ');

        expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyR), isFalse);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.slash), isFalse);
        expect(find.byType(ReviewPage), findsNothing);

        expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isTrue);
        await tester.pumpAndSettle();
        expect(field.controller!.text, isEmpty);
        expect(field.focusNode!.hasFocus, isTrue);
        expect(find.byKey(NotebookKeys.row('eat')), findsOneWidget);
        expect(find.byKey(NotebookKeys.row('drink')), findsOneWidget);
        expect(
          GoRouter.of(tester.element(find.byType(NotebookPage))).state.uri.path,
          '/notebook',
        );
        expect(find.byType(ReviewPage), findsNothing);

        expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isTrue);
        await tester.pumpAndSettle();
        expect(field.focusNode!.hasFocus, isFalse);
        expect(
          GoRouter.of(tester.element(find.byType(NotebookPage))).state.uri.path,
          '/notebook',
        );
        expect(find.byType(ReviewPage), findsNothing);
      },
    );
  }
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

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

Future<void> _openNotebook(
  WidgetTester tester, {
  required List<_Seed> words,
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

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
