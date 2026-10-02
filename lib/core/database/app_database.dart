import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
    if (!Platform.isLinux) {
      return driftDatabase(name: 'mangajp');
    }
    return driftDatabase(
      name: 'mangajp',
      native: const DriftNativeOptions(
        databaseDirectory: linuxDatabaseDirectory,
      ),
    );
  }
}

/// Linux-only directory for `mangajp.sqlite`.
///
/// Android and iOS use Drift’s default (`getApplicationDocumentsDirectory()`).
/// On Linux that call can fail when XDG Documents is missing, so we try
/// app-support, then documents, then system temp.
Future<Directory> linuxDatabaseDirectory() async {
  try {
    return await getApplicationSupportDirectory();
  } catch (_) {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }
}
