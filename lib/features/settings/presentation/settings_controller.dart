import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database_provider.dart';

part 'settings_controller.g.dart';

/// Riverpod codegen hello: reads `app_meta.hello` seeded by Drift `onCreate`.
/// Shown on **Ajustes** (moved off Home in M1.21).
@riverpod
class HelloMeta extends _$HelloMeta {
  static const metaKey = 'hello';
  static const initialValue = 'MangaJP M0.1';

  @override
  Future<String> build() async {
    final dao = ref.watch(appDatabaseProvider).appMetaDao;
    return await dao.getValue(metaKey) ?? initialValue;
  }
}
