import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/database/app_database.dart';

import '../../drift/schema.dart';
import '../../drift/schema_v9.dart' as v9;

int _unix(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
    'schema dump v9 upgrades to v10 and adds image_path + ocr_blocks_json',
    () async {
      final connection = await verifier.startAt(9);
      final db = AppDatabase(connection);
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 10);
      expect(await db.appMetaDao.getValue('schema_version'), '10');

      final pages = await db.customSelect('PRAGMA table_info(pages)').get();
      expect({
        for (final row in pages) row.read<String>('name'),
      }, contains('image_path'));
      final imagePath = pages.singleWhere(
        (row) => row.read<String>('name') == 'image_path',
      );
      expect(imagePath.read<int>('notnull'), 0);

      final crops = await db.customSelect('PRAGMA table_info(crops)').get();
      expect({
        for (final row in crops) row.read<String>('name'),
      }, contains('ocr_blocks_json'));
      final blocks = crops.singleWhere(
        (row) => row.read<String>('name') == 'ocr_blocks_json',
      );
      expect(blocks.read<int>('notnull'), 0);
    },
  );

  test(
    'v9 rows survive v10 with image_path and ocr_blocks_json null',
    () async {
      final schema = await verifier.schemaAt(9);
      addTearDown(schema.close);
      final old = v9.DatabaseAtV9(schema.newConnection());
      final created = _unix(DateTime.utc(2026, 1, 1));
      await old
          .into(old.pages)
          .insert(
            v9.PagesCompanion.insert(
              id: 'page-old',
              sha256: 'sha-old',
              createdAt: created,
            ),
          );
      await old
          .into(old.crops)
          .insert(
            v9.CropsCompanion.insert(
              id: 'crop-old',
              pageId: 'page-old',
              ocrText: '猫を食べた。',
              engineId: 'manga_ocr',
              left: 0.2,
              top: 0.2,
              width: 0.6,
              height: 0.6,
              createdAt: created,
            ),
          );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 10);

      expect(await db.appMetaDao.getValue('schema_version'), '10');
      final page = (await db.select(db.capturedPages).get()).single;
      expect(page.id, 'page-old');
      expect(page.imagePath, isNull);
      final crop = (await db.select(db.capturedCrops).get()).single;
      expect(crop.id, 'crop-old');
      expect(crop.ocrText, '猫を食べた。');
      expect(crop.ocrBlocksJson, isNull);

      await db
          .into(db.capturedPages)
          .insert(
            CapturedPagesCompanion.insert(
              id: 'page-new',
              sha256: 'sha-new',
              createdAt: DateTime.utc(2026, 2, 1),
              imagePath: const Value('/tmp/page-new.png'),
            ),
          );
      final fresh = await (db.select(
        db.capturedPages,
      )..where((t) => t.id.equals('page-new'))).getSingle();
      expect(fresh.imagePath, '/tmp/page-new.png');
    },
  );
}
