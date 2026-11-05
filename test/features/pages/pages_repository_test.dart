import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';
import 'package:manga_jp/core/utils/hashing.dart';
import 'package:manga_jp/features/pages/data/pages_repository.dart';
import 'package:manga_jp/features/pages/domain/page_crop.dart';

import '../capture/fixture_png.dart';

void main() {
  test('saveRecognizedCrop persists OCR text on a crop row', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);
    final png = fixturePng();

    final crop = await repo.saveRecognizedCrop(
      pageId: 'page-1',
      sourceSha256: sha256Hex(png),
      left: 0.2,
      top: 0.2,
      width: 0.6,
      height: 0.6,
      ocrText: 'よぉ、相棒',
      engineId: 'manga_ocr',
    );

    expect(crop.ocrText, 'よぉ、相棒');
    expect(crop.engineId, 'manga_ocr');

    final listed = await repo.listCrops();
    expect(listed, hasLength(1));
    expect(listed.single.ocrText, 'よぉ、相棒');
    expect(listed.single.pageId, 'page-1');

    final page = await repo.pageById('page-1');
    expect(page, isNotNull);
    expect(page!.sha256, sha256Hex(png));
  });

  test('saveRecognizedCrop is idempotent for the same page geometry', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);
    const pageId = 'page-retry';

    Future<PageCrop> save() {
      return repo.saveRecognizedCrop(
        pageId: pageId,
        sourceSha256: 'sha',
        left: 0.2,
        top: 0.2,
        width: 0.6,
        height: 0.6,
        ocrText: 'よぉ、相棒',
        engineId: 'fake',
      );
    }

    final first = await save();
    final second = await save();
    expect(second.id, first.id);
    expect(await repo.listCrops(), hasLength(1));
    expect(await repo.cropsForPage(pageId), hasLength(1));
  });

  test(
    'listRecentPages returns at most 6 pages by created_at descending',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PagesRepository(db);

      for (var i = 1; i <= 7; i++) {
        await db.pagesDao.insertPage(
          CapturedPagesCompanion.insert(
            id: 'page-$i',
            sha256: 'sha-$i',
            createdAt: DateTime.utc(2026, 1, i),
          ),
        );
      }

      final recent = await repo.listRecentPages();
      expect(recent.map((page) => page.id).toList(), [
        'page-7',
        'page-6',
        'page-5',
        'page-4',
        'page-3',
        'page-2',
      ]);
    },
  );

  test('listRecentPages is empty when there are no pages', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await PagesRepository(db).listRecentPages(), isEmpty);
  });

  test('listPages returns every page newest first, not capped at 6', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);

    for (var i = 1; i <= 7; i++) {
      await db.pagesDao.insertPage(
        CapturedPagesCompanion.insert(
          id: 'page-$i',
          sha256: 'sha-$i',
          createdAt: DateTime.utc(2026, 1, i),
        ),
      );
    }

    final all = await repo.listPages();
    expect(all.map((page) => page.id).toList(), [
      'page-7',
      'page-6',
      'page-5',
      'page-4',
      'page-3',
      'page-2',
      'page-1',
    ]);
  });

  test('listPages is empty when there are no pages', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await PagesRepository(db).listPages(), isEmpty);
    expect(await PagesRepository(db).listPageEntries(), isEmpty);
  });

  test('listPageEntries uses first crop OCR as title source', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);

    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'with-ocr',
        sha256: 'sha-a',
        createdAt: DateTime.utc(2026, 2, 2),
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'crop-a',
        pageId: 'with-ocr',
        ocrText: 'この町には、もう誰も残っていない。',
        engineId: 'test',
        left: 0.1,
        top: 0.1,
        width: 0.4,
        height: 0.4,
        createdAt: DateTime.utc(2026, 2, 2),
      ),
    );
    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'no-ocr',
        sha256: 'sha-b',
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    );

    final entries = await repo.listPageEntries();
    expect(entries, hasLength(2));
    expect(entries.first.id, 'with-ocr');
    expect(entries.first.title, 'この町には、もう誰も残っていない。');
    expect(entries.last.id, 'no-ocr');
    expect(entries.last.title, 'Página');
    expect(entries.last.ocrPreview, isNull);
  });

  test('listPageEntries uses the earliest crop when a page has two', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);

    await db.pagesDao.insertPage(
      CapturedPagesCompanion.insert(
        id: 'two-crops',
        sha256: 'sha',
        createdAt: DateTime.utc(2026, 3, 1),
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'crop-second',
        pageId: 'two-crops',
        ocrText: 'segundo',
        engineId: 'test',
        left: 0.5,
        top: 0.1,
        width: 0.4,
        height: 0.4,
        createdAt: DateTime.utc(2026, 3, 1, 1),
      ),
    );
    await db.pagesDao.insertCrop(
      CapturedCropsCompanion.insert(
        id: 'crop-first',
        pageId: 'two-crops',
        ocrText: 'primeiro',
        engineId: 'test',
        left: 0.1,
        top: 0.1,
        width: 0.4,
        height: 0.4,
        createdAt: DateTime.utc(2026, 3, 1, 0),
      ),
    );

    final entries = await repo.listPageEntries();
    expect(entries, hasLength(1));
    expect(entries.single.ocrPreview, 'primeiro');
    expect(entries.single.title, 'primeiro');
  });

  test('watchPageEntries emits after a page and crop are written', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PagesRepository(db);
    final events = <List<String>>[];
    final sub = repo.watchPageEntries().listen((rows) {
      events.add([for (final row in rows) row.id]);
    });
    addTearDown(sub.cancel);

    await pumpEventQueue();
    expect(events, [
      <String>[],
    ]);

    await repo.saveRecognizedCrop(
      pageId: 'live-1',
      sourceSha256: 'sha',
      left: 0.1,
      top: 0.1,
      width: 0.4,
      height: 0.4,
      ocrText: '見せる',
      engineId: 'test',
    );
    await pumpEventQueue();

    expect(events.last, ['live-1']);
    expect((await repo.watchPageEntries().first).single.title, '見せる');
  });
}
