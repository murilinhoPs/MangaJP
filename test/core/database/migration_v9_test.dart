import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';

import '../../drift/schema.dart';
import '../../drift/schema_v8.dart' as v8;

int _unix(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('schema dump v8 upgrades to v9 and creates saved_kanji', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);
    expect(await db.appMetaDao.getValue('schema_version'), '9');

    final names = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    expect({
      for (final row in names) row.read<String>('name'),
    }, contains('saved_kanji'));

    final info = await db.customSelect('PRAGMA table_info(saved_kanji)').get();
    expect(
      {for (final row in info) row.read<String>('name')},
      {'literal', 'saved_at', 'origin_page_id'},
    );
    final pk = info.singleWhere((row) => row.read<String>('name') == 'literal');
    expect(pk.read<int>('pk'), isNonZero);

    final indexes = await db
        .customSelect("PRAGMA index_list('saved_kanji')")
        .get();
    expect({
      for (final row in indexes) row.read<String>('name'),
    }, contains('idx_saved_kanji_saved_at'));

    final fks = await db
        .customSelect('PRAGMA foreign_key_list(saved_kanji)')
        .get();
    expect(fks, hasLength(1));
    expect(fks.single.read<String>('table'), 'pages');
    expect(fks.single.read<String>('from'), 'origin_page_id');
    expect(fks.single.read<String>('to'), 'id');
    expect(fks.single.read<String>('on_delete').toUpperCase(), 'SET NULL');
  });

  test('v8 data survives v9; deleting the origin page keeps the kanji and '
      'nulls origin_page_id with foreign_keys ON', () async {
    final schema = await verifier.schemaAt(8);
    addTearDown(schema.close);
    final old = v8.DatabaseAtV8(schema.newConnection());
    final created = _unix(DateTime.utc(2026, 1, 1));
    await old
        .into(old.pages)
        .insert(
          v8.PagesCompanion.insert(
            id: 'page-keep',
            sha256: 'sha-keep',
            createdAt: created,
          ),
        );
    await old
        .into(old.pages)
        .insert(
          v8.PagesCompanion.insert(
            id: 'page-drop',
            sha256: 'sha-drop',
            createdAt: created,
          ),
        );
    await old
        .into(old.words)
        .insert(
          v8.WordsCompanion.insert(
            id: 'eat',
            seq: 1358280,
            lemma: '食べる',
            reading: 'たべる',
            createdAt: created,
            lemmaKey: const Value('食べる'),
          ),
        );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 9);

    final fk = await db.customSelect('PRAGMA foreign_keys').get();
    expect(fk.single.read<int>('foreign_keys'), 1);

    expect(await db.appMetaDao.getValue('schema_version'), '9');
    expect((await db.select(db.userWords).get()).single.lemma, '食べる');
    expect(
      (await db.select(db.capturedPages).get()).map((row) => row.id).toSet(),
      {'page-keep', 'page-drop'},
    );

    await db
        .into(db.savedKanji)
        .insert(
          SavedKanjiCompanion.insert(
            literal: '食',
            savedAt: DateTime.utc(2026, 2, 1),
            originPageId: const Value('page-drop'),
          ),
        );

    await (db.delete(
      db.capturedPages,
    )..where((t) => t.id.equals('page-drop'))).go();

    final kanji = (await db.select(db.savedKanji).get()).single;
    expect(kanji.literal, '食');
    expect(kanji.originPageId, isNull);
    expect(
      (await db.select(db.capturedPages).get()).map((row) => row.id).toSet(),
      {'page-keep'},
    );
  });
}
