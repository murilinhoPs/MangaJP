import 'dart:io';

import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_provider.dart';
import 'package:manga_jp/features/dictionary/data/jmdict_service.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_word_page.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../dictionary/bake_jmdict_fixture.dart';

const _taberuSeq = 1358280;
final _progressedDue = DateTime.utc(2026, 6, 15);

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
      expect(find.byKey(NotebookWordKeys.learn), findsOneWidget);
      expect(find.byKey(NotebookWordKeys.known), findsOneWidget);
      expect(find.byKey(NotebookWordKeys.ignore), findsOneWidget);
      expect(find.byKey(NotebookWordKeys.deleteCard), findsOneWidget);

      _expectNoOutOfScopeControls(tester);
      final states = await env.db.select(env.db.userWordStates).get();
      expect(states, hasLength(1));
      expect(states.single.state, WordState.saved.name);
      expect(states.single.updatedAt, env.stateUpdatedAt);
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

    _expectNoOutOfScopeControls(tester);
    final states = await env.db.select(env.db.userWordStates).get();
    expect(states.single.state, WordState.saved.name);
    expect(states.single.updatedAt, env.stateUpdatedAt);
  });

  testWidgets('Aprender with no card sets learning and creates golden SRS', (
    tester,
  ) async {
    final env = await _openWord(tester, jmdictPath: jmdictPath);

    await tester.ensureVisible(find.byKey(NotebookWordKeys.learn));
    await tester.tap(find.byKey(NotebookWordKeys.learn));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Aprendendo',
    );
    expect(find.byKey(NotebookWordKeys.learn), findsOneWidget);
    _expectNoOutOfScopeControls(tester);

    final state = (await env.db.select(env.db.userWordStates).get()).single;
    expect(state.state, WordState.learning.name);

    final card = (await env.db.select(env.db.userCards).get()).single;
    expect(card.wordId, env.wordId);
    expect(card.kind, FlashcardKind.vocab.name);
    final srs = (await env.db.select(env.db.userCardSrs).get()).single;
    expect(srs.cardId, card.id);
    expect(srs.easeFactor, kDefaultEaseFactor);
    expect(srs.intervalDays, 0);
    expect(srs.repetitions, 0);
    expect(srs.phase, CardPhase.neu.name);
    expect(srs.engineId, kSm2JrEngineId);
  });

  testWidgets('second Aprender tap is a no-op when already learning', (
    tester,
  ) async {
    final env = await _openWord(
      tester,
      jmdictPath: jmdictPath,
      state: WordState.learning,
      card: true,
    );
    final beforeCard = (await env.db.select(env.db.userCards).get()).single;
    final beforeSrs = await _srsSnapshot(env.db);
    final beforeState =
        (await env.db.select(env.db.userWordStates).get()).single;

    await tester.ensureVisible(find.byKey(NotebookWordKeys.learn));
    await tester.tap(find.byKey(NotebookWordKeys.learn));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NotebookWordKeys.learn));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Aprendendo',
    );
    final cards = await env.db.select(env.db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, beforeCard.id);
    expect(cards.single.createdAt, beforeCard.createdAt);
    expect(await _srsSnapshot(env.db), beforeSrs);
    final state = (await env.db.select(env.db.userWordStates).get()).single;
    expect(state.state, WordState.learning.name);
    expect(state.updatedAt, beforeState.updatedAt);
  });

  testWidgets('Aprender from known returns to learning without resetting SRS', (
    tester,
  ) async {
    final env = await _openWord(
      tester,
      jmdictPath: jmdictPath,
      state: WordState.known,
      card: true,
    );
    final beforeCard = (await env.db.select(env.db.userCards).get()).single;
    final beforeSrs = await _srsSnapshot(env.db);

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Conhecido',
    );
    await tester.ensureVisible(find.byKey(NotebookWordKeys.learn));
    await tester.tap(find.byKey(NotebookWordKeys.learn));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Aprendendo',
    );
    final cards = await env.db.select(env.db.userCards).get();
    expect(cards, hasLength(1));
    expect(cards.single.id, beforeCard.id);
    expect(await _srsSnapshot(env.db), beforeSrs);
    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.learning.name,
    );
  });

  testWidgets(
    'Aprender from ignored returns to learning without resetting SRS',
    (tester) async {
      final env = await _openWord(
        tester,
        jmdictPath: jmdictPath,
        state: WordState.ignored,
        card: true,
      );
      final beforeCard = (await env.db.select(env.db.userCards).get()).single;
      final beforeSrs = await _srsSnapshot(env.db);

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Ignorado',
      );
      await tester.ensureVisible(find.byKey(NotebookWordKeys.learn));
      await tester.tap(find.byKey(NotebookWordKeys.learn));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Aprendendo',
      );
      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, beforeCard.id);
      expect(await _srsSnapshot(env.db), beforeSrs);
      expect(
        (await env.db.select(env.db.userWordStates).get()).single.state,
        WordState.learning.name,
      );
    },
  );

  testWidgets(
    'Conhecido with a card sets known and suspend_reason without touching SRS',
    (tester) async {
      final env = await _openWord(
        tester,
        jmdictPath: jmdictPath,
        state: WordState.learning,
        card: true,
      );
      final beforeCard = (await env.db.select(env.db.userCards).get()).single;
      final beforeSrs = await _srsSnapshot(env.db);
      final tablesBefore = await _tableNames(env.db);

      await tester.ensureVisible(find.byKey(NotebookWordKeys.known));
      await tester.tap(find.byKey(NotebookWordKeys.known));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Conhecido',
      );
      expect(find.byKey(NotebookWordKeys.known), findsOneWidget);
      expect(find.byKey(NotebookWordKeys.ignore), findsOneWidget);
      expect(find.byKey(NotebookWordKeys.learn), findsOneWidget);
      _expectNoOutOfScopeControls(tester);

      final state = (await env.db.select(env.db.userWordStates).get()).single;
      expect(state.state, WordState.known.name);
      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, beforeCard.id);
      expect(cards.single.createdAt, beforeCard.createdAt);
      expect(cards.single.suspendReason, WordState.known.name);
      expect(await _srsSnapshot(env.db), beforeSrs);
      expect(await env.db.select(env.db.userCardSrs).get(), hasLength(1));
      expect(await _tableNames(env.db), tablesBefore);
    },
  );

  testWidgets(
    'Ignorar with a card sets ignored and suspend_reason without touching SRS',
    (tester) async {
      final env = await _openWord(
        tester,
        jmdictPath: jmdictPath,
        state: WordState.learning,
        card: true,
      );
      final beforeCard = (await env.db.select(env.db.userCards).get()).single;
      final beforeSrs = await _srsSnapshot(env.db);

      await tester.ensureVisible(find.byKey(NotebookWordKeys.ignore));
      await tester.tap(find.byKey(NotebookWordKeys.ignore));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Ignorado',
      );
      final cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, beforeCard.id);
      expect(cards.single.suspendReason, WordState.ignored.name);
      expect(await _srsSnapshot(env.db), beforeSrs);
    },
  );

  testWidgets('Conhecido without a card only changes state', (tester) async {
    final env = await _openWord(tester, jmdictPath: jmdictPath);

    await tester.ensureVisible(find.byKey(NotebookWordKeys.known));
    await tester.tap(find.byKey(NotebookWordKeys.known));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Conhecido',
    );
    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.known.name,
    );
    expect(await env.db.select(env.db.userCards).get(), isEmpty);
    expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
  });

  testWidgets('Ignorar without a card only changes state', (tester) async {
    final env = await _openWord(tester, jmdictPath: jmdictPath);

    await tester.ensureVisible(find.byKey(NotebookWordKeys.ignore));
    await tester.tap(find.byKey(NotebookWordKeys.ignore));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Ignorado',
    );
    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.ignored.name,
    );
    expect(await env.db.select(env.db.userCards).get(), isEmpty);
  });

  testWidgets(
    'switching known to ignored updates suspend_reason and keeps the card',
    (tester) async {
      final env = await _openWord(
        tester,
        jmdictPath: jmdictPath,
        state: WordState.known,
        card: true,
        suspendReason: WordState.known.name,
      );
      final beforeCard = (await env.db.select(env.db.userCards).get()).single;
      final beforeSrs = await _srsSnapshot(env.db);

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Conhecido',
      );
      await tester.ensureVisible(find.byKey(NotebookWordKeys.ignore));
      await tester.tap(find.byKey(NotebookWordKeys.ignore));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Ignorado',
      );
      var cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, beforeCard.id);
      expect(cards.single.suspendReason, WordState.ignored.name);
      expect(await _srsSnapshot(env.db), beforeSrs);

      await tester.tap(find.byKey(NotebookWordKeys.known));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Conhecido',
      );
      cards = await env.db.select(env.db.userCards).get();
      expect(cards, hasLength(1));
      expect(cards.single.id, beforeCard.id);
      expect(cards.single.suspendReason, WordState.known.name);
      expect(await _srsSnapshot(env.db), beforeSrs);
    },
  );

  testWidgets('second Conhecido tap is a no-op', (tester) async {
    final env = await _openWord(
      tester,
      jmdictPath: jmdictPath,
      state: WordState.learning,
      card: true,
    );

    await tester.ensureVisible(find.byKey(NotebookWordKeys.known));
    await tester.tap(find.byKey(NotebookWordKeys.known));
    await tester.pumpAndSettle();
    final afterFirst = await _studySnapshot(env.db);

    await tester.tap(find.byKey(NotebookWordKeys.known));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NotebookWordKeys.known));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Conhecido',
    );
    expect(await _studySnapshot(env.db), afterFirst);
  });

  testWidgets('second Ignorar tap is a no-op', (tester) async {
    final env = await _openWord(
      tester,
      jmdictPath: jmdictPath,
      state: WordState.learning,
      card: true,
    );

    await tester.ensureVisible(find.byKey(NotebookWordKeys.ignore));
    await tester.tap(find.byKey(NotebookWordKeys.ignore));
    await tester.pumpAndSettle();
    final afterFirst = await _studySnapshot(env.db);

    await tester.tap(find.byKey(NotebookWordKeys.ignore));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Ignorado',
    );
    expect(await _studySnapshot(env.db), afterFirst);
  });

  testWidgets('known word stays on the Caderno list and detail', (
    tester,
  ) async {
    final env = await _openWord(tester, jmdictPath: jmdictPath);

    await tester.ensureVisible(find.byKey(NotebookWordKeys.known));
    await tester.tap(find.byKey(NotebookWordKeys.known));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookWordPage), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data, '食べる');
    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Conhecido',
    );

    const NotebookRoute().go(tester.element(find.byType(NotebookWordPage)));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookPage), findsOneWidget);
    expect(find.byKey(NotebookKeys.row(env.wordId)), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.byKey(NotebookKeys.row(env.wordId)))
          .trailing,
      isA<Text>().having((text) => text.data, 'label', 'Conhecido'),
    );

    await tester.tap(find.byKey(NotebookKeys.row(env.wordId)));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookWordPage), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data, '食べる');
    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Conhecido',
    );
    expect(
      (await env.db.select(env.db.userWordStates).get()).single.state,
      WordState.known.name,
    );
  });

  testWidgets(
    'confirming Remover card deletes card and SRS and returns to saved',
    (tester) async {
      final env = await _openWord(
        tester,
        jmdictPath: jmdictPath,
        state: WordState.learning,
        card: true,
      );
      final tablesBefore = await _tableNames(env.db);

      await _tapDeleteCard(tester, confirm: true);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(NotebookWordPage), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data,
        '食べる',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Salvo',
      );
      expect(find.byKey(NotebookWordKeys.deleteCard), findsOneWidget);
      _expectNoOutOfScopeControls(tester);

      expect(
        (await env.db.select(env.db.userWordStates).get()).single.state,
        WordState.saved.name,
      );
      expect(
        (await env.db.select(env.db.userWords).get()).single.id,
        env.wordId,
      );
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);
      expect(await env.db.select(env.db.cropWords).get(), isNotEmpty);
      expect(await _tableNames(env.db), tablesBefore);
      expect(tablesBefore, isNot(contains('review_logs')));

      const NotebookRoute().go(tester.element(find.byType(NotebookWordPage)));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookPage), findsOneWidget);
      expect(find.byKey(NotebookKeys.row(env.wordId)), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(NotebookKeys.row(env.wordId)))
            .trailing,
        isA<Text>().having((text) => text.data, 'label', 'Salvo'),
      );

      await tester.tap(find.byKey(NotebookKeys.row(env.wordId)));
      await tester.pumpAndSettle();

      expect(find.byType(NotebookWordPage), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data,
        '食べる',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Salvo',
      );
    },
  );

  testWidgets('cancelling Remover card is a no-op', (tester) async {
    final env = await _openWord(
      tester,
      jmdictPath: jmdictPath,
      state: WordState.learning,
      card: true,
    );
    final before = await _studySnapshot(env.db);

    await _tapDeleteCard(tester, confirm: false);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(NotebookWordPage), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
      'Aprendendo',
    );
    expect(await _studySnapshot(env.db), before);
    expect(await env.db.select(env.db.userCards).get(), hasLength(1));
    expect(await env.db.select(env.db.userCardSrs).get(), hasLength(1));
  });

  testWidgets(
    'Remover card without a card does not delete the word or create a card',
    (tester) async {
      final env = await _openWord(tester, jmdictPath: jmdictPath);
      final before = await _studySnapshot(env.db);

      await _tapDeleteCard(tester, confirm: true);

      expect(find.byType(NotebookWordPage), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.lemma)).data,
        '食べる',
      );
      expect(
        tester.widget<Text>(find.byKey(NotebookWordKeys.state)).data,
        'Salvo',
      );
      expect(await _studySnapshot(env.db), before);
      expect(
        (await env.db.select(env.db.userWords).get()).single.id,
        env.wordId,
      );
      expect(await env.db.select(env.db.userCards).get(), isEmpty);
      expect(await env.db.select(env.db.userCardSrs).get(), isEmpty);

      const NotebookRoute().go(tester.element(find.byType(NotebookWordPage)));
      await tester.pumpAndSettle();

      expect(find.byKey(NotebookKeys.row(env.wordId)), findsOneWidget);
    },
  );
}

class _Env {
  const _Env({
    required this.db,
    required this.wordId,
    required this.pageId,
    required this.stateUpdatedAt,
  });

  final AppDatabase db;
  final String wordId;
  final String pageId;
  final DateTime stateUpdatedAt;
}

typedef _SrsSnapshot = ({
  double easeFactor,
  double intervalDays,
  int repetitions,
  DateTime dueAt,
  String phase,
  String engineId,
});

Future<_Env> _openNotebook(
  WidgetTester tester, {
  required String jmdictPath,
  WordState state = WordState.saved,
  bool card = false,
  String? suspendReason,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);

  const wordId = 'eat';
  const pageId = 'page-eat';
  final seededAt = DateTime.utc(2026, 1, 1);

  await db
      .into(db.userWords)
      .insert(
        UserWordsCompanion.insert(
          id: wordId,
          seq: _taberuSeq,
          lemma: '食べる',
          reading: 'たべる',
          createdAt: seededAt,
        ),
      );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: wordId,
          state: state.name,
          updatedAt: seededAt,
        ),
      );
  if (card) {
    await db
        .into(db.userCards)
        .insert(
          UserCardsCompanion.insert(
            id: 'card-eat',
            wordId: wordId,
            kind: FlashcardKind.vocab.name,
            createdAt: DateTime.utc(2026, 2, 1),
            suspendReason: Value(suspendReason),
          ),
        );
    await db
        .into(db.userCardSrs)
        .insert(
          UserCardSrsCompanion.insert(
            cardId: 'card-eat',
            easeFactor: 2.36,
            intervalDays: 14,
            repetitions: 3,
            dueAt: _progressedDue,
            phase: CardPhase.review.name,
            engineId: kSm2JrEngineId,
          ),
        );
  }
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
  final stateUpdatedAt =
      (await db.select(db.userWordStates).get()).single.updatedAt;
  return _Env(
    db: db,
    wordId: wordId,
    pageId: pageId,
    stateUpdatedAt: stateUpdatedAt,
  );
}

Future<_Env> _openWord(
  WidgetTester tester, {
  required String jmdictPath,
  WordState state = WordState.saved,
  bool card = false,
  String? suspendReason,
}) async {
  final env = await _openNotebook(
    tester,
    jmdictPath: jmdictPath,
    state: state,
    card: card,
    suspendReason: suspendReason,
  );
  await tester.tap(find.byKey(NotebookKeys.row(env.wordId)));
  await tester.pumpAndSettle();
  return env;
}

Future<_SrsSnapshot> _srsSnapshot(AppDatabase db) async {
  final row = (await db.select(db.userCardSrs).get()).single;
  return (
    easeFactor: row.easeFactor,
    intervalDays: row.intervalDays,
    repetitions: row.repetitions,
    dueAt: row.dueAt,
    phase: row.phase,
    engineId: row.engineId,
  );
}

typedef _StudySnapshot = ({
  String state,
  DateTime stateUpdatedAt,
  String? cardId,
  DateTime? cardCreatedAt,
  String? suspendReason,
  _SrsSnapshot? srs,
});

Future<_StudySnapshot> _studySnapshot(AppDatabase db) async {
  final state = (await db.select(db.userWordStates).get()).single;
  final cards = await db.select(db.userCards).get();
  final card = cards.isEmpty ? null : cards.single;
  return (
    state: state.state,
    stateUpdatedAt: state.updatedAt,
    cardId: card?.id,
    cardCreatedAt: card?.createdAt,
    suspendReason: card?.suspendReason,
    srs: card == null ? null : await _srsSnapshot(db),
  );
}

Future<Set<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return {for (final row in rows) row.read<String>('name')};
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

Future<void> _tapDeleteCard(
  WidgetTester tester, {
  required bool confirm,
}) async {
  final delete = find.byKey(NotebookWordKeys.deleteCard);
  await tester.scrollUntilVisible(
    delete,
    80,
    scrollable: find.descendant(
      of: find.byType(NotebookWordPage),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(delete);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Remover card?'), findsOneWidget);
  final key = confirm
      ? NotebookWordKeys.deleteCardConfirm
      : NotebookWordKeys.deleteCardCancel;
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void _expectNoOutOfScopeControls(WidgetTester tester) {
  expect(find.text('Remover palavra'), findsNothing);
  expect(find.text('Remove'), findsNothing);
  expect(find.text('Add card'), findsNothing);
  expect(find.text('Salvar'), findsNothing);
  expect(find.byType(DeckPage), findsNothing);
  expect(find.byIcon(Icons.delete_outline), findsNothing);
}
