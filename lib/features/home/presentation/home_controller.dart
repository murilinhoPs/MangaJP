import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database_provider.dart';
import '../../review/data/review_repository.dart';
import '../../review/domain/home_review_counts.dart';

part 'home_controller.g.dart';

/// Riverpod codegen hello: reads `app_meta.hello` seeded by Drift `onCreate`.
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

/// Due + novos hoje for the Home **Revisar** block. Uses the review clock.
@riverpod
Future<HomeReviewCounts> homeReviewCounts(Ref ref) {
  return ref.watch(reviewRepositoryProvider).homeCounts();
}
