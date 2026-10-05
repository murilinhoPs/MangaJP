import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';

void main() {
  test('onCreate seeds app_meta hello once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.appMetaDao.getValue('hello'), 'MangaJP M0.1');
    expect(await db.appMetaDao.getValue('schema_version'), '5');
    expect(await db.appMetaDao.getValue('engine_id'), 'sm2-jr@1');
    expect(await db.appMetaDao.getValue('ocr_engine_id'), 'manga_ocr');
  });

  test('app_meta roundtrip', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.appMetaDao.upsert('hello', 'updated');
    expect(await db.appMetaDao.getValue('hello'), 'updated');
  });

  test('onCreate creates pages and crops tables', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    final names = {for (final row in rows) row.read<String>('name')};
    expect(
      names,
      containsAll(<String>[
        'app_meta',
        'pages',
        'crops',
        'words',
        'word_states',
        'crop_words',
        'cards',
        'card_srs',
      ]),
    );
    expect(names, isNot(contains('review_logs')));
    expect(await db.select(db.userCards).get(), isEmpty);
    expect(await db.select(db.userCardSrs).get(), isEmpty);
  });

  test('linuxDatabaseDirectory resolves to a real directory', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await linuxDatabaseDirectory();
    expect(dir.existsSync(), isTrue);
  });
}
