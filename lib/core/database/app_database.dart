import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/app_meta_dao.dart';
import 'tables/app_meta.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AppMeta], daos: [AppMetaDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await batch((batch) {
          batch.insertAll(appMeta, [
            AppMetaCompanion.insert(key: 'hello', value: 'MangaJP M0.1'),
            AppMetaCompanion.insert(key: 'schema_version', value: '1'),
            AppMetaCompanion.insert(key: 'engine_id', value: 'sm2-jr@1'),
          ]);
        });
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mangajp');
  }
}
