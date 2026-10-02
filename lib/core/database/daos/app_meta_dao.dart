import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/app_meta.dart';

part 'app_meta_dao.g.dart';

@DriftAccessor(tables: [AppMeta])
class AppMetaDao extends DatabaseAccessor<AppDatabase> with _$AppMetaDaoMixin {
  AppMetaDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(
      appMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> upsert(String key, String value) {
    return into(appMeta).insert(
      AppMetaCompanion.insert(key: key, value: value),
      onConflict: DoUpdate((_) => AppMetaCompanion(value: Value(value))),
    );
  }
}
