import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_labels.dart';
import 'package:manga_jp/features/flashcards/presentation/deck_page.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_labels.dart';
import 'package:manga_jp/features/review/data/review_repository.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

class _SeedCard {
  const _SeedCard({
    required this.id,
    required this.lemma,
    required this.reading,
    required this.state,
    required this.createdAt,
    this.suspendReason,
    this.dueAt,
  });

  final String id;
  final String lemma;
  final String reading;
  final WordState state;
  final DateTime createdAt;
  final String? suspendReason;
  final DateTime? dueAt;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [_phone, _desktop]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final wide = size.width >= AppBreakpoints.wide;

    testWidgets('empty /deck shows Nenhum card at $label', (tester) async {
      await _openDeck(
        tester,
        size: size,
        cards: const [],
        body: () async {
          expect(find.byType(DeckPage), findsOneWidget);
          expect(find.byKey(DeckKeys.empty), findsOneWidget);
          expect(find.text(DeckLabels.empty), findsOneWidget);
          expect(find.text(DeckLabels.emptyHint), findsOneWidget);
          expect(find.byKey(DeckKeys.list), findsNothing);
          expect(find.text('/deck — stub (M0.1)'), findsNothing);
          expect(find.text(DeckLabels.title), findsWidgets);
        },
      );
    });

    testWidgets(
      'Deck lists cards, suspends with confirm, and reactivates at $label',
      (tester) async {
        final due = DateTime.now().toUtc().subtract(const Duration(hours: 1));
        await _openDeck(
          tester,
          size: size,
          cards: [
            _SeedCard(
              id: 'eat',
              lemma: '食べる',
              reading: 'たべる',
              state: WordState.learning,
              createdAt: DateTime.utc(2026, 3, 1),
              dueAt: due,
            ),
            _SeedCard(
              id: 'known',
              lemma: '猫',
              reading: 'ねこ',
              state: WordState.known,
              createdAt: DateTime.utc(2026, 2, 1),
              suspendReason: WordState.known.name,
              dueAt: due,
            ),
          ],
          body: () async {
            expect(find.byType(DeckPage), findsOneWidget);
            expect(find.byKey(DeckKeys.list), findsOneWidget);
            expect(find.byKey(DeckKeys.row('eat')), findsOneWidget);
            expect(find.byKey(DeckKeys.row('known')), findsOneWidget);
            expect(find.text('食べる'), findsOneWidget);
            expect(find.text('たべる'), findsOneWidget);
            expect(find.text('猫'), findsOneWidget);
            expect(
              find.byKey(DeckKeys.status('eat')),
              findsOneWidget,
            );
            expect(find.text(NotebookLabels.state(WordState.learning)), findsWidgets);
            expect(find.text(NotebookLabels.state(WordState.known)), findsOneWidget);
            expect(find.byKey(DeckKeys.suspend('eat')), findsOneWidget);
            expect(find.byKey(DeckKeys.reactivate('eat')), findsNothing);
            expect(find.byKey(DeckKeys.suspend('known')), findsNothing);
            expect(find.byKey(DeckKeys.reactivate('known')), findsNothing);
            expect(find.text('/deck — stub (M0.1)'), findsNothing);

            expect(
              tester.getTopLeft(find.byKey(DeckKeys.row('eat'))).dy,
              lessThan(tester.getTopLeft(find.byKey(DeckKeys.row('known'))).dy),
            );

            if (wide) {
              expect(find.byKey(ShellKeys.railItem('deck')), findsOneWidget);
              expect(find.byKey(ShellKeys.navCards), findsNothing);
            } else {
              expect(find.byKey(ShellKeys.navCards), findsOneWidget);
              expect(find.byKey(ShellKeys.navCard('deck')), findsOneWidget);
            }

            await tester.tap(find.byKey(DeckKeys.suspend('eat')));
            await tester.pumpAndSettle();
            expect(find.byKey(DeckKeys.suspendDialog), findsOneWidget);
            expect(find.text(DeckLabels.suspenderTitulo), findsOneWidget);
            expect(find.text(DeckLabels.suspenderBody), findsOneWidget);

            await tester.tap(find.byKey(DeckKeys.suspendCancel));
            await tester.pumpAndSettle();
            expect(find.byKey(DeckKeys.suspendDialog), findsNothing);
            expect(find.byKey(DeckKeys.suspend('eat')), findsOneWidget);
            expect(find.text(DeckLabels.suspenso), findsNothing);

            await tester.tap(find.byKey(DeckKeys.suspend('eat')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(DeckKeys.suspendConfirm));
            await tester.pumpAndSettle();

            expect(find.byKey(DeckKeys.row('eat')), findsOneWidget);
            expect(find.text(DeckLabels.suspenso), findsOneWidget);
            expect(find.byKey(DeckKeys.reactivate('eat')), findsOneWidget);
            expect(find.byKey(DeckKeys.suspend('eat')), findsNothing);
            expect(find.byKey(DeckKeys.row('known')), findsOneWidget);

            await tester.tap(find.byKey(DeckKeys.reactivate('eat')));
            await tester.pumpAndSettle();
            expect(find.byKey(DeckKeys.suspend('eat')), findsOneWidget);
            expect(find.byKey(DeckKeys.reactivate('eat')), findsNothing);
            expect(find.text(DeckLabels.suspenso), findsNothing);
            expect(find.text(NotebookLabels.state(WordState.learning)), findsWidgets);
          },
        );
      },
    );

    testWidgets(
      'suspended Deck card stays out of /review until reactivated at $label',
      (tester) async {
        final due = DateTime.now().toUtc().subtract(const Duration(hours: 1));
        late AppDatabase db;
        await _openDeck(
          tester,
          size: size,
          cards: [
            _SeedCard(
              id: 'eat',
              lemma: '食べる',
              reading: 'たべる',
              state: WordState.learning,
              createdAt: DateTime.utc(2026, 3, 1),
              dueAt: due,
            ),
          ],
          onDb: (opened) => db = opened,
          body: () async {
            final review = ReviewRepository(db);
            expect(await review.dueQueue(), hasLength(1));

            await tester.tap(find.byKey(DeckKeys.suspend('eat')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(DeckKeys.suspendConfirm));
            await tester.pumpAndSettle();
            expect(find.text(DeckLabels.suspenso), findsOneWidget);
            expect(await review.dueQueue(), isEmpty);

            await tester.tap(find.byKey(DeckKeys.reactivate('eat')));
            await tester.pumpAndSettle();
            final queue = await review.dueQueue();
            expect(queue, hasLength(1));
            expect(queue.single.lemma, '食べる');
          },
        );
      },
    );
  }

  testWidgets('mobile nav card Deck opens /deck', (tester) async {
    await _pumpApp(
      tester,
      size: _phone,
      cards: const [],
      body: () async {
        await tester.tap(find.byKey(ShellKeys.navCard('deck')));
        await tester.pumpAndSettle();
        expect(find.byType(DeckPage), findsOneWidget);
        expect(
          GoRouter.of(tester.element(find.byType(DeckPage))).state.uri.path,
          '/deck',
        );
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(ReviewPage), findsNothing);
      },
    );
  });
}

Future<void> _openDeck(
  WidgetTester tester, {
  required Size size,
  required List<_SeedCard> cards,
  required Future<void> Function() body,
  void Function(AppDatabase db)? onDb,
}) {
  return _pumpApp(
    tester,
    size: size,
    cards: cards,
    onDb: onDb,
    body: () async {
      const DeckRoute().go(tester.element(find.byType(HomePage)));
      await tester.pumpAndSettle();
      await body();
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
  required List<_SeedCard> cards,
  required Future<void> Function() body,
  void Function(AppDatabase db)? onDb,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final db = AppDatabase(NativeDatabase.memory());
  onDb?.call(db);
  for (final card in cards) {
    await db
        .into(db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: card.id,
            seq: card.id.hashCode.abs(),
            lemma: card.lemma,
            reading: card.reading,
            createdAt: card.createdAt,
          ),
        );
    await db
        .into(db.userWordStates)
        .insert(
          UserWordStatesCompanion.insert(
            wordId: card.id,
            state: card.state.name,
            updatedAt: card.createdAt,
          ),
        );
    final cardId = 'card-${card.id}';
    await db
        .into(db.userCards)
        .insert(
          UserCardsCompanion.insert(
            id: cardId,
            wordId: card.id,
            kind: FlashcardKind.vocab.name,
            createdAt: card.createdAt,
            suspendReason: Value(card.suspendReason),
          ),
        );
    await db
        .into(db.userCardSrs)
        .insert(
          UserCardSrsCompanion.insert(
            cardId: cardId,
            easeFactor: kDefaultEaseFactor,
            intervalDays: 6,
            repetitions: 2,
            dueAt: card.dueAt ?? DateTime.utc(2026, 6, 15),
            phase: CardPhase.review.name,
            engineId: kSm2JrEngineId,
          ),
        );
  }

  await tester.pumpWidget(
    MangaJpApp(overrides: [appDatabaseProvider.overrideWith((ref) => db)]),
  );
  await tester.pumpAndSettle();
  try {
    await body();
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.binding.runAsync(db.close);
  }
}
