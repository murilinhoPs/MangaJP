import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database_provider.dart';

part 'home_controller.g.dart';

/// Riverpod codegen hello: read/write a trivial `app_meta` key via Drift.
@riverpod
class HelloMeta extends _$HelloMeta {
  static const metaKey = 'hello';
  static const initialValue = 'MangaJP M0.1';

  @override
  Future<String> build() async {
    final dao = ref.watch(appDatabaseProvider).appMetaDao;
    await dao.upsert('schema_version', '1');
    await dao.upsert('engine_id', 'sm2-jr@1');
    final existing = await dao.getValue(metaKey);
    if (existing != null) {
      return existing;
    }
    await dao.upsert(metaKey, initialValue);
    return initialValue;
  }
}
