import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/utils/kanji.dart';
import 'package:manga_jp/features/backup/data/backup_repository.dart';
import 'package:manga_jp/features/backup/domain/backup_codec.dart';
import 'package:manga_jp/features/backup/domain/backup_document.dart';
import 'package:manga_jp/features/backup/domain/backup_exception.dart';
import 'package:manga_jp/features/backup/domain/backup_labels.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

import 'backup_fixtures.dart';

void main() {
  test('onCreate schema is 10 and export includes empty saved_kanji', () async {
    final env = await _open();
    addTearDown(env.db.close);

    expect(env.db.schemaVersion, 10);
    expect(await env.db.appMetaDao.getValue('schema_version'), '10');

    final json = encodeBackupJson(await env.backup.export());
    expect(json, contains('"schema_version": 10'));
    expect(json, contains('"format_version": 2'));
    expect(json, contains('"saved_kanji": []'));
    expect(json, contains('"crop_words": []'));
    expect(json, contains('"words": []'));
  });

  test('round-trip restores the same words, cards/SRS and kanji', () async {
    final env = await _open();
    addTearDown(env.db.close);
    await _page(env.db, 'page-a');
    await env.backup.restore(sampleDocument());

    final json = encodeBackupJson(await env.backup.export());
    final other = await _open();
    addTearDown(other.db.close);
    await _page(other.db, 'page-a');
    await other.backup.restoreJson(json);

    final words = await other.db.select(other.db.userWords).get();
    expect(words.single.id, 'eat');
    expect(words.single.lemma, '食べる');
    expect(words.single.userNote, 'comer');
    expect(
      (await other.db.select(other.db.userWordStates).get()).single.state,
      'learning',
    );
    expect(
      (await other.db.select(other.db.userCards).get()).single.id,
      'card-eat',
    );
    final srs = (await other.db.select(other.db.userCardSrs).get()).single;
    expect(srs.intervalDays, 1);
    expect(srs.engineId, 'sm2-jr@1');
    expect(
      (await other.db.select(other.db.userReviewLogs).get()).single.id,
      'log-1',
    );
    final kanji = (await other.db.select(other.db.savedKanji).get()).single;
    expect(kanji.literal, '食');
    expect(kanji.originPageId, 'page-a');
  });

  test(
    'round-trip keeps a crop_words link when the crop still exists',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      await _page(env.db, 'page-a');
      await _crop(env.db, id: 'crop-a', pageId: 'page-a');
      await env.backup.restore(sampleDocument(cropWords: [sampleCropWord()]));

      final json = encodeBackupJson(await env.backup.export());
      expect(json, contains('"crop_id": "crop-a"'));

      final other = await _open();
      addTearDown(other.db.close);
      await _page(other.db, 'page-a');
      await _crop(other.db, id: 'crop-a', pageId: 'page-a');
      await other.backup.restoreJson(json);

      final links = await other.db.select(other.db.cropWords).get();
      expect(links, hasLength(1));
      expect(links.single.cropId, 'crop-a');
      expect(links.single.wordId, 'eat');
      expect(
        (await other.db.select(other.db.userWords).get()).single.id,
        'eat',
      );
    },
  );

  test(
    'crop_words whose crop is gone are skipped; the rest restores',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      await _page(env.db, 'page-a');
      await _crop(env.db, id: 'crop-keep', pageId: 'page-a');

      await env.backup.restore(
        sampleDocument(
          cropWords: [
            sampleCropWord(cropId: 'crop-gone'),
            sampleCropWord(cropId: 'crop-keep'),
          ],
        ),
      );

      final links = await env.db.select(env.db.cropWords).get();
      expect(links, hasLength(1));
      expect(links.single.cropId, 'crop-keep');
      expect(links.single.wordId, 'eat');
      expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
      expect(
        (await env.db.select(env.db.savedKanji).get()).single.literal,
        '食',
      );
    },
  );

  test(
    'format 1 backup without crop_words restores words and no links',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      await _page(env.db, 'page-a');
      await _crop(env.db, id: 'crop-a', pageId: 'page-a');

      await env.backup.restoreJson(sampleJson(formatVersion: 1));
      expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
      expect(await env.db.select(env.db.cropWords).get(), isEmpty);
    },
  );

  test(
    'schema 8 backup without saved_kanji restores Caderno + SRS, empty Kanji',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      await env.db
          .into(env.db.savedKanji)
          .insert(
            SavedKanjiCompanion.insert(
              literal: '高',
              savedAt: DateTime.utc(2026, 1, 1),
            ),
          );

      final result = await env.backup.restoreJson(schema8Json());
      expect(result.savedKanjiCount, 0);
      expect(result.skippedKanji, 0);
      expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
      expect(
        (await env.db.select(env.db.userCards).get()).single.id,
        'card-eat',
      );
      expect(await env.db.select(env.db.savedKanji).get(), isEmpty);
    },
  );

  test(
    'origin_page_id null or missing page keeps the kanji with null origin',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      await _page(env.db, 'page-a');

      final result = await env.backup.restore(
        sampleDocument(
          savedKanji: [
            BackupSavedKanji(literal: '食', savedAt: DateTime.utc(2026, 1, 5)),
            BackupSavedKanji(
              literal: '高',
              savedAt: DateTime.utc(2026, 1, 6),
              originPageId: 'page-a',
            ),
            BackupSavedKanji(
              literal: '本',
              savedAt: DateTime.utc(2026, 1, 7),
              originPageId: 'page-missing',
            ),
          ],
        ),
      );

      expect(result.savedKanjiCount, 3);
      final rows = await env.db.select(env.db.savedKanji).get();
      final byLiteral = {for (final row in rows) row.literal: row.originPageId};
      expect(byLiteral, {'食': null, '高': 'page-a', '本': null});
    },
  );

  test('unknown schema is rejected and the database is unchanged', () async {
    final env = await _open();
    addTearDown(env.db.close);
    await _seedLocalWord(env.db);

    expect(
      () => env.backup.restoreJson(sampleJson(schemaVersion: 11)),
      throwsA(
        isA<BackupRejectedException>().having(
          (e) => e.message,
          'message',
          BackupLabels.unknownSchema(fileSchema: 11, appSchema: 10),
        ),
      ),
    );
    expect((await env.db.select(env.db.userWords).get()).single.id, 'keep-me');
    expect(await env.db.select(env.db.savedKanji).get(), isEmpty);
  });

  test(
    'unknown format_version is rejected and the database is unchanged',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      await _seedLocalWord(env.db);

      expect(
        () => env.backup.restoreJson(sampleJson(formatVersion: 3)),
        throwsA(isA<BackupRejectedException>()),
      );
      expect(
        (await env.db.select(env.db.userWords).get()).single.id,
        'keep-me',
      );
    },
  );

  test('failure mid-import leaves the database unchanged', () async {
    final env = await _open();
    addTearDown(env.db.close);
    await _seedLocalWord(env.db);

    final broken = sampleDocument();
    final bad = BackupDocument(
      formatVersion: broken.formatVersion,
      schemaVersion: broken.schemaVersion,
      exportedAt: broken.exportedAt,
      words: broken.words,
      wordStates: broken.wordStates,
      cards: [
        BackupCard(
          id: 'orphan-card',
          wordId: 'missing-word',
          kind: 'vocab',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
      cardSrs: const [],
      reviewLogs: const [],
      savedKanji: broken.savedKanji,
    );

    expect(
      () => env.backup.restore(bad),
      throwsA(isA<BackupRestoreFailedException>()),
    );
    expect((await env.db.select(env.db.userWords).get()).single.id, 'keep-me');
    expect(await env.db.select(env.db.userCards).get(), isEmpty);
    expect(await env.db.select(env.db.savedKanji).get(), isEmpty);
  });

  test(
    'invalid literals are skipped; valid ones restore; IVS is stripped',
    () async {
      final env = await _open();
      addTearDown(env.db.close);
      const ivs = '\u{E0100}';

      final result = await env.backup.restore(
        sampleDocument(
          savedKanji: [
            BackupSavedKanji(
              literal: '食$ivs',
              savedAt: DateTime.utc(2026, 1, 1),
            ),
            BackupSavedKanji(literal: '食べる', savedAt: DateTime.utc(2026, 1, 2)),
            BackupSavedKanji(literal: '', savedAt: DateTime.utc(2026, 1, 3)),
            BackupSavedKanji(literal: '叱', savedAt: DateTime.utc(2026, 1, 4)),
            BackupSavedKanji(literal: '𠮟', savedAt: DateTime.utc(2026, 1, 5)),
          ],
        ),
      );

      expect(result.skippedKanji, 2);
      expect(result.savedKanjiCount, 3);
      final literals = {
        for (final row in await env.db.select(env.db.savedKanji).get())
          row.literal,
      };
      expect(literals, {'食', '叱', '𠮟'});
      expect(normalizeKanjiLiteral('食$ivs'), '食');
    },
  );

  test('restore replaces existing Caderno + SRS + saved_kanji', () async {
    final env = await _open();
    addTearDown(env.db.close);
    await _seedLocalWord(env.db);
    await env.db
        .into(env.db.savedKanji)
        .insert(
          SavedKanjiCompanion.insert(
            literal: '古',
            savedAt: DateTime.utc(2025, 1, 1),
          ),
        );

    await env.backup.restore(sampleDocument(savedKanji: const []));
    expect((await env.db.select(env.db.userWords).get()).single.id, 'eat');
    expect(await env.db.select(env.db.savedKanji).get(), isEmpty);
  });
}

class _Env {
  const _Env({required this.db, required this.backup});

  final AppDatabase db;
  final BackupRepository backup;
}

Future<_Env> _open() async {
  final db = AppDatabase(NativeDatabase.memory());
  return _Env(db: db, backup: BackupRepository(db));
}

Future<void> _page(AppDatabase db, String id) {
  return db
      .into(db.capturedPages)
      .insert(
        CapturedPagesCompanion.insert(
          id: id,
          sha256: id,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        mode: InsertMode.insertOrIgnore,
      );
}

Future<void> _crop(
  AppDatabase db, {
  required String id,
  required String pageId,
}) {
  return db.pagesDao.insertCrop(
    CapturedCropsCompanion.insert(
      id: id,
      pageId: pageId,
      ocrText: '食べるのは楽しい。',
      engineId: 'test',
      left: 0.1,
      top: 0.1,
      width: 0.5,
      height: 0.5,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
}

Future<void> _seedLocalWord(AppDatabase db) async {
  await db.wordsDao.insertWord(
    UserWordsCompanion.insert(
      id: 'keep-me',
      seq: 1,
      lemma: '古い',
      reading: 'ふるい',
      createdAt: DateTime.utc(2025, 1, 1),
    ),
  );
  await db
      .into(db.userWordStates)
      .insert(
        UserWordStatesCompanion.insert(
          wordId: 'keep-me',
          state: WordState.saved.name,
          updatedAt: DateTime.utc(2025, 1, 1),
        ),
      );
}
