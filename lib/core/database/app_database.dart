import 'package:drift/drift.dart';

import 'app_database_open.dart';
import 'daos/app_meta_dao.dart';
import 'daos/pages_dao.dart';
import 'daos/words_dao.dart';
import 'tables/app_meta.dart';
import 'tables/captured_crops.dart';
import 'tables/captured_pages.dart';
import 'tables/crop_words.dart';
import 'tables/user_word_states.dart';
import 'tables/user_words.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppMeta,
    CapturedPages,
    CapturedCrops,
    UserWords,
    UserWordStates,
    CropWords,
  ],
  daos: [AppMetaDao, PagesDao, WordsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await batch((batch) {
          batch.insertAll(appMeta, [
            AppMetaCompanion.insert(key: 'hello', value: 'MangaJP M0.1'),
            AppMetaCompanion.insert(key: 'schema_version', value: '3'),
            AppMetaCompanion.insert(key: 'engine_id', value: 'sm2-jr@1'),
            AppMetaCompanion.insert(key: 'ocr_engine_id', value: 'manga_ocr'),
          ]);
        });
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(capturedPages);
          await m.createTable(capturedCrops);
          await into(appMeta).insert(
            AppMetaCompanion.insert(key: 'schema_version', value: '2'),
            onConflict: DoUpdate(
              (_) => const AppMetaCompanion(value: Value('2')),
            ),
          );
          await into(appMeta).insert(
            AppMetaCompanion.insert(key: 'ocr_engine_id', value: 'manga_ocr'),
            onConflict: DoUpdate(
              (_) => const AppMetaCompanion(value: Value('manga_ocr')),
            ),
          );
        }
        if (from < 3) {
          await m.createTable(userWords);
          await m.createTable(userWordStates);
          await m.createTable(cropWords);
          await into(appMeta).insert(
            AppMetaCompanion.insert(key: 'schema_version', value: '3'),
            onConflict: DoUpdate(
              (_) => const AppMetaCompanion(value: Value('3')),
            ),
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() => openMangaJpDatabase();
}
