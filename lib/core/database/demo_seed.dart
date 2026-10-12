import 'package:drift/drift.dart';

import '../srs/sm2_jr.dart';
import 'app_database.dart';

/// Off by default. Enable with `--dart-define=MANGAJP_DEMO_SEED=true`.
const kMangaJpDemoSeed = bool.fromEnvironment('MANGAJP_DEMO_SEED');

/// Idempotent fixture rows so Home / Caderno / Review / lookup can be photographed.
Future<void> seedDemoIfRequested(AppDatabase db) async {
  if (!kMangaJpDemoSeed) {
    return;
  }
  final existing = await (db.select(
    db.userWords,
  )..where((t) => t.id.equals('demo-taberu'))).getSingleOrNull();
  if (existing != null) {
    return;
  }

  final now = DateTime.now().toUtc();
  final due = now.subtract(const Duration(hours: 1));

  await db.transaction(() async {
    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'demo-page',
        sha256: 'demo-sha',
        createdAt: now,
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'demo-crop',
        pageId: 'demo-page',
        // ~14 JP glyphs/line at 22px on a phone; 高い starts the 2nd line.
        ocrText: 'あいうえおかきくけこさしすせ高い猫を食べた。',
        engineId: 'demo',
        left: 0.2,
        top: 0.2,
        width: 0.6,
        height: 0.6,
        createdAt: now,
      ),
    );
    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'demo-page-2',
        sha256: 'demo-sha-2',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'demo-crop-2',
        pageId: 'demo-page-2',
        ocrText: 'この町には、もう誰も残っていない。',
        engineId: 'demo',
        left: 0.15,
        top: 0.2,
        width: 0.7,
        height: 0.4,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    );
    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'demo-page-3',
        sha256: 'demo-sha-3',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'demo-crop-3a',
        pageId: 'demo-page-3',
        ocrText: '雛子、早く逃げなきゃ……',
        engineId: 'demo',
        left: 0.1,
        top: 0.1,
        width: 0.5,
        height: 0.3,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'demo-crop-3b',
        pageId: 'demo-page-3',
        ocrText: '見せる',
        engineId: 'demo',
        left: 0.4,
        top: 0.5,
        width: 0.4,
        height: 0.3,
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
    );

    Future<void> word({
      required String id,
      required int seq,
      required String lemma,
      required String reading,
      required String state,
      bool card = false,
      String phase = 'learning',
    }) async {
      await db.wordsDao.insertWord(
        UserWordsCompanion.insert(
          id: id,
          seq: seq,
          lemma: lemma,
          reading: reading,
          createdAt: now,
        ),
      );
      await db.wordsDao.insertState(
        UserWordStatesCompanion.insert(
          wordId: id,
          state: state,
          updatedAt: now,
        ),
      );
      await db.wordsDao.insertCropWord(
        CropWordsCompanion.insert(
          cropId: 'demo-crop',
          wordId: id,
          createdAt: now,
        ),
      );
      if (!card) {
        return;
      }
      final cardId = 'card-$id';
      await db
          .into(db.userCards)
          .insert(
            UserCardsCompanion.insert(
              id: cardId,
              wordId: id,
              kind: 'vocab',
              createdAt: now,
              suspendReason: Value(
                state == 'known' || state == 'ignored' ? state : null,
              ),
            ),
          );
      await db
          .into(db.userCardSrs)
          .insert(
            UserCardSrsCompanion.insert(
              cardId: cardId,
              easeFactor: kDefaultEaseFactor,
              intervalDays: phase == 'neu' ? 0 : 6,
              repetitions: phase == 'neu' ? 0 : 2,
              dueAt: due,
              phase: phase,
              engineId: kSm2JrEngineId,
            ),
          );
    }

    await word(
      id: 'demo-taberu',
      seq: 1358280,
      lemma: '食べる',
      reading: 'たべる',
      state: 'learning',
      card: true,
    );
    await word(
      id: 'demo-takai',
      seq: 1411580,
      lemma: '高い',
      reading: 'たかい',
      state: 'saved',
    );
    await word(
      id: 'demo-neko',
      seq: 1583470,
      lemma: '猫',
      reading: 'ねこ',
      state: 'known',
      card: true,
    );
    await word(
      id: 'demo-yusengo',
      seq: 9990001,
      lemma: '優先語',
      reading: 'ゆうせんご',
      state: 'ignored',
    );

    Future<void> extraCard({
      required String id,
      required int seq,
      required String lemma,
      required String phase,
      bool drill = false,
    }) async {
      await word(
        id: id,
        seq: seq,
        lemma: lemma,
        reading: lemma,
        state: 'learning',
        card: true,
        phase: phase,
      );
      if (!drill) {
        return;
      }
      await db.cardsDao.insertLog(
        UserReviewLogsCompanion.insert(
          id: 'log-$id',
          cardId: 'card-$id',
          ratedAt: now.subtract(const Duration(minutes: 20)),
          rating: 1,
          quality: 0,
          engineId: kSm2JrEngineId,
          isDrill: 0,
        ),
      );
    }

    await extraCard(
      id: 'demo-review-1',
      seq: 9990101,
      lemma: '残る',
      phase: 'review',
    );
    await extraCard(
      id: 'demo-review-2',
      seq: 9990102,
      lemma: '町',
      phase: 'review',
    );
    await extraCard(
      id: 'demo-learn-2',
      seq: 9990103,
      lemma: '早い',
      phase: 'learning',
    );
    await extraCard(
      id: 'demo-new-1',
      seq: 9990104,
      lemma: '誰',
      phase: 'neu',
    );
    await extraCard(
      id: 'demo-new-2',
      seq: 9990105,
      lemma: 'もう',
      phase: 'neu',
    );
    await extraCard(
      id: 'demo-new-3',
      seq: 9990106,
      lemma: 'いない',
      phase: 'neu',
    );
    await extraCard(
      id: 'demo-drill-1',
      seq: 9990107,
      lemma: '逃げる',
      phase: 'learning',
      drill: true,
    );
    await extraCard(
      id: 'demo-drill-2',
      seq: 9990108,
      lemma: '見せる',
      phase: 'relearning',
      drill: true,
    );

    for (var i = 1; i <= 4; i++) {
      await db.cardsDao.insertLog(
        UserReviewLogsCompanion.insert(
          id: 'log-week-$i',
          cardId: 'card-demo-taberu',
          ratedAt: now.subtract(Duration(days: i)),
          rating: 3,
          quality: 4,
          engineId: kSm2JrEngineId,
          isDrill: 0,
        ),
      );
    }
  });
}
