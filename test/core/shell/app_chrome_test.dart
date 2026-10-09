import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_jp/app.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/database/app_database_provider.dart';
import 'package:manga_jp/core/router/routes.dart';
import 'package:manga_jp/core/shell/shell_layout.dart';
import 'package:manga_jp/core/shell/task_dock.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/core/theme/app_theme.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';
import 'package:manga_jp/features/capture/presentation/capture_page.dart';
import 'package:manga_jp/features/flashcards/domain/flashcard.dart';
import 'package:manga_jp/features/home/presentation/home_page.dart';
import 'package:manga_jp/features/notebook/presentation/notebook_page.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/presentation/page_detail_page.dart';
import 'package:manga_jp/features/review/presentation/review_page.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import '../../features/capture/fake_image_source_service.dart';
import '../../features/capture/fixture_png.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile shows 4 nav cards with labels and Início active', (
    tester,
  ) async {
    await _pumpShell(tester, size: _mobile);

    expect(find.byKey(ShellKeys.navCards), findsOneWidget);
    expect(find.byKey(ShellKeys.navCard('inicio')), findsOneWidget);
    expect(find.byKey(ShellKeys.navCard('caderno')), findsOneWidget);
    expect(find.byKey(ShellKeys.navCard('deck')), findsOneWidget);
    expect(find.byKey(ShellKeys.navCard('ajustes')), findsOneWidget);
    expect(find.text('Início'), findsWidgets);
    expect(find.text('Caderno'), findsOneWidget);
    expect(find.text('Deck'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(_cardLabelColor(tester, 'inicio', 'Início'), AppColors.coral);
    expect(
      _cardLabelColor(tester, 'caderno', 'Caderno'),
      isNot(AppColors.coral),
    );
    expect(find.byKey(ShellKeys.rail), findsNothing);
    expect(find.byKey(ShellKeys.commandBar), findsNothing);
  });

  testWidgets('mobile Caderno card is active on /notebook', (tester) async {
    await _pumpShell(tester, size: _mobile);
    await tester.tap(find.byKey(ShellKeys.navCard('caderno')));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookPage), findsOneWidget);
    expect(_cardLabelColor(tester, 'caderno', 'Caderno'), AppColors.coral);
    expect(_cardLabelColor(tester, 'inicio', 'Início'), isNot(AppColors.coral));
    expect(
      GoRouter.of(tester.element(find.byType(NotebookPage))).state.uri.path,
      '/notebook',
    );
  });

  testWidgets('Página hides nav cards and shows the dock', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    const pageId = 'page-dock';
    await PagesRepository(db).saveRecognizedCrop(
      pageId: pageId,
      sourceSha256: sha256Hex(fixturePng()),
      left: 0.2,
      top: 0.2,
      width: 0.6,
      height: 0.6,
      ocrText: '猫',
      engineId: 'fake',
    );

    await _pumpShell(tester, size: _mobile, db: db);
    const PageDetailRoute(id: pageId).go(tester.element(find.byType(HomePage)));
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailPage), findsOneWidget);
    expect(find.byKey(ShellKeys.navCards), findsNothing);
    expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
    expect(find.byKey(ShellKeys.dockAction('back')), findsOneWidget);
    expect(find.byKey(ShellKeys.dockMeta), findsOneWidget);
    expect(find.text(pageId), findsWidgets);
  });

  testWidgets('Review hides nav cards and shows the dock', (tester) async {
    await _pumpShell(tester, size: _mobile);
    const ReviewRoute().go(tester.element(find.byType(HomePage)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.byKey(ShellKeys.navCards), findsNothing);
    expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
    expect(find.byKey(ShellKeys.dockAction('close')), findsOneWidget);
  });

  testWidgets('Captura hides nav cards and shows the dock', (tester) async {
    await _pumpShell(
      tester,
      size: _mobile,
      source: FakeImageSourceService(
        initial: IncomingImage(bytes: fixturePng()),
      ),
    );

    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.byKey(ShellKeys.navCards), findsNothing);
    expect(find.text('Caderno'), findsNothing);
    expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
    expect(find.byKey(CaptureKeys.confirm), findsOneWidget);
    expect(find.byKey(ShellKeys.dockMeta), findsNothing);
  });

  testWidgets('dock without meta renders no empty pill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: TaskDock(
            leading: [DockIconButton(icon: Icons.close, onPressed: _noop)],
            trailing: [
              DockTextButton(label: 'Confirmar crop', onPressed: _noop),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
    expect(find.byKey(ShellKeys.dockMeta), findsNothing);
    expect(find.text('Confirmar crop'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: TaskDock(
            meta: '   ',
            leading: [DockIconButton(icon: Icons.close, onPressed: _noop)],
          ),
        ),
      ),
    );

    expect(find.byKey(ShellKeys.dockMeta), findsNothing);
  });

  testWidgets('desktop rail is 76px with Ajustes at the bottom', (
    tester,
  ) async {
    await _pumpShell(tester, size: _desktop);

    expect(find.byKey(ShellKeys.navCards), findsNothing);
    expect(find.byKey(ShellKeys.rail), findsOneWidget);
    expect(tester.getSize(find.byKey(ShellKeys.rail)).width, 76);
    expect(find.byKey(ShellKeys.jpSeal), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Leitor'), findsOneWidget);
    expect(find.text('Revisar'), findsWidgets);
    expect(find.text('Caderno'), findsOneWidget);
    expect(find.text('Deck'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(ShellKeys.railAjustes)).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(ShellKeys.railItem('biblioteca'))).dy,
      ),
    );
    expect(find.byKey(ShellKeys.commandBar), findsOneWidget);
    expect(find.text('Ctrl+O'), findsOneWidget);
    expect(find.text('R'), findsWidgets);
    expect(find.byKey(ShellKeys.reviewBadge), findsNothing);
  });

  testWidgets('desktop Revisar mint badge is hidden at 0', (tester) async {
    await _pumpShell(tester, size: _desktop);
    expect(find.byKey(ShellKeys.reviewBadge), findsNothing);
  });

  testWidgets('desktop Revisar mint badge shows para revisar', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedDue(db, count: 3);
    await _pumpShell(tester, size: _desktop, db: db);

    expect(find.byKey(ShellKeys.reviewBadge), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(ShellKeys.reviewBadge),
              matching: find.byType(Text),
            ),
          )
          .data,
      '3',
    );
  });

  testWidgets('rail Leitor is disabled when there are no pages', (
    tester,
  ) async {
    await _pumpShell(tester, size: _desktop);

    final ink = tester.widget<InkWell>(
      find.byKey(ShellKeys.railItem('leitor')),
    );
    expect(ink.onTap, isNull);
    expect(_railLabelColor(tester, 'leitor', 'Leitor'), AppColors.text4);

    await tester.tap(find.byKey(ShellKeys.railItem('leitor')));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(HomePage))).state.uri.path,
      '/home',
    );
    expect(find.byType(PageDetailPage), findsNothing);
  });

  testWidgets('rail Leitor opens the most recent page', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedCapturedPage(
      db,
      id: 'older',
      createdAt: DateTime.utc(2026, 10, 1),
    );
    await _seedCapturedPage(
      db,
      id: 'newest',
      createdAt: DateTime.utc(2026, 10, 8),
    );
    await _pumpShell(tester, size: _desktop, db: db);

    final ink = tester.widget<InkWell>(
      find.byKey(ShellKeys.railItem('leitor')),
    );
    expect(ink.onTap, isNotNull);
    expect(_railLabelColor(tester, 'leitor', 'Leitor'), isNot(AppColors.text4));

    await tester.tap(find.byKey(ShellKeys.railItem('leitor')));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/newest',
    );
  });

  testWidgets('desktop Caderno is active in the rail', (tester) async {
    await _pumpShell(tester, size: _desktop);
    await tester.tap(find.byKey(ShellKeys.railItem('caderno')));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookPage), findsOneWidget);
    expect(_railLabelColor(tester, 'caderno', 'Caderno'), AppColors.coral);
    expect(
      _railLabelColor(tester, 'biblioteca', 'Biblioteca'),
      isNot(AppColors.coral),
    );
    expect(find.byKey(ShellKeys.commandBar), findsNothing);
  });

  testWidgets('Ctrl+K opens the palette and an item navigates', (tester) async {
    await _pumpShell(tester, size: _desktop);
    await tester.tap(find.byType(HomePage));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.byKey(ShellKeys.palette), findsOneWidget);
    expect(find.byKey(ShellKeys.paletteItem('caderno')), findsOneWidget);
    expect(find.byKey(ShellKeys.paletteItem('more')), findsNothing);
    expect(find.byKey(ShellKeys.paletteItem('paginas')), findsNothing);
    expect(find.text('Páginas'), findsNothing);
    expect(find.text('Abrir página recente'), findsNothing);
    expect(find.text('Mais'), findsNothing);

    await tester.tap(find.byKey(ShellKeys.paletteItem('caderno')));
    await tester.pumpAndSettle();

    expect(find.byType(NotebookPage), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(NotebookPage))).state.uri.path,
      '/notebook',
    );
  });

  testWidgets('palette Abrir página recente opens the latest page', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedCapturedPage(
      db,
      id: 'older',
      createdAt: DateTime.utc(2026, 10, 1),
    );
    await _seedCapturedPage(
      db,
      id: 'newest',
      createdAt: DateTime.utc(2026, 10, 8),
    );
    await _pumpShell(tester, size: _desktop, db: db);
    await tester.tap(find.byType(HomePage));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Abrir página recente'), findsOneWidget);
    expect(find.text('Páginas'), findsNothing);
    await tester.tap(find.byKey(ShellKeys.paletteItem('pagina-recente')));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(PageDetailPage))).state.uri.path,
      '/pages/newest',
    );
  });

  testWidgets('R navigates to Review', (tester) async {
    await _pumpShell(tester, size: _mobile);
    await tester.tap(find.byType(HomePage));
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyR), isTrue);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ReviewPage), findsOneWidget);
    expect(find.byKey(ShellKeys.navCards), findsNothing);
    expect(find.byKey(ShellKeys.taskDock), findsOneWidget);
  });

  testWidgets('R and / are not handled while Caderno search is focused', (
    tester,
  ) async {
    await _pumpShell(tester, size: _mobile);
    await tester.tap(find.byKey(ShellKeys.navCard('caderno')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(NotebookKeys.search));
    await tester.pump();

    expect(await tester.sendKeyEvent(LogicalKeyboardKey.keyR), isFalse);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.slash), isFalse);
    expect(
      GoRouter.of(tester.element(find.byType(NotebookPage))).state.uri.path,
      '/notebook',
    );
    expect(find.byType(ReviewPage), findsNothing);
  });
}

void _noop() {}

const _mobile = Size(390, 844);
const _desktop = Size(1280, 800);

Color? _cardLabelColor(WidgetTester tester, String id, String label) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(ShellKeys.navCard(id)),
          matching: find.text(label),
        ),
      )
      .style
      ?.color;
}

Color? _railLabelColor(WidgetTester tester, String id, String label) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(ShellKeys.railItem(id)),
          matching: find.text(label),
        ),
      )
      .style
      ?.color;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  AppDatabase? db,
  ImageSourceService? source,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final database = db ?? AppDatabase(NativeDatabase.memory());
  if (db == null) {
    addTearDown(database.close);
  }

  await tester.pumpWidget(
    MangaJpApp(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => database),
        if (source != null)
          imageSourceServiceProvider.overrideWith((ref) => source),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _seedCapturedPage(
  AppDatabase db, {
  required String id,
  required DateTime createdAt,
}) async {
  await db.pagesDao.insertPage(
    CapturedPagesCompanion.insert(
      id: id,
      sha256: 'sha-$id',
      createdAt: createdAt,
    ),
  );
  await db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: 'crop-$id',
      pageId: id,
      ocrText: '文',
      engineId: 'test',
      left: 0.1,
      top: 0.1,
      width: 0.4,
      height: 0.4,
      createdAt: createdAt,
    ),
  );
}

Future<void> _seedDue(AppDatabase db, {required int count}) async {
  final dueAt = DateTime.now().toUtc().subtract(const Duration(hours: 1));
  for (var i = 0; i < count; i++) {
    final id = 'due-$i';
    await db
        .into(db.userWords)
        .insert(
          UserWordsCompanion.insert(
            id: id,
            seq: i + 1,
            lemma: '語$i',
            reading: 'よみ',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db
        .into(db.userWordStates)
        .insert(
          UserWordStatesCompanion.insert(
            wordId: id,
            state: WordState.learning.name,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
    await db
        .into(db.userCards)
        .insert(
          UserCardsCompanion.insert(
            id: 'card-$id',
            wordId: id,
            kind: FlashcardKind.vocab.name,
            createdAt: DateTime.utc(2026, 2, 1),
          ),
        );
    await db
        .into(db.userCardSrs)
        .insert(
          UserCardSrsCompanion.insert(
            cardId: 'card-$id',
            easeFactor: kDefaultEaseFactor,
            intervalDays: 6,
            repetitions: 2,
            dueAt: dueAt,
            phase: CardPhase.learning.name,
            engineId: kSm2JrEngineId,
          ),
        );
  }
}
