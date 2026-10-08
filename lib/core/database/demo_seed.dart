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
      ocrText: '猫を食べた。',
      engineId: 'demo',
      left: 0.2,
      top: 0.2,
      width: 0.6,
      height: 0.6,
      createdAt: now,
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
}
