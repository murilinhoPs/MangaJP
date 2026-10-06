import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database_provider.dart';
import '../../../core/router/app_router.dart';
import '../../pages/data/pages_repository.dart';
import '../../pages/domain/page.dart';
import '../../pages/domain/recent_pages.dart';
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
///
/// Refetches when a `/review` answer persists, and again when the shell
/// returns to `/home` (Home stays mounted as a branch, so a one-shot
/// FutureProvider would otherwise stay stale).
@riverpod
Future<HomeReviewCounts> homeReviewCounts(Ref ref) {
  ref.watch(reviewRevisionProvider);
  final router = ref.watch(appRouterProvider);
  var path = router.state.uri.path;
  void onRoute() {
    final next = router.state.uri.path;
    if (next == '/home' && path != '/home') {
      ref.invalidateSelf();
    }
    path = next;
  }

  router.routerDelegate.addListener(onRoute);
  ref.onDispose(() => router.routerDelegate.removeListener(onRoute));
  return ref.watch(reviewRepositoryProvider).homeCounts();
}

/// Newest pages for Home **Capturas recentes** (at most [RecentPages.limit]).
///
/// Refetches when the shell returns to `/home` (Home stays mounted as a
/// branch, so a one-shot FutureProvider would otherwise stay stale after
/// `/capture` → `/pages/:id`).
@riverpod
Future<List<MangaPage>> homeRecentPages(Ref ref) {
  final router = ref.watch(appRouterProvider);
  var path = router.state.uri.path;
  void onRoute() {
    final next = router.state.uri.path;
    if (next == '/home' && path != '/home') {
      ref.invalidateSelf();
    }
    path = next;
  }

  router.routerDelegate.addListener(onRoute);
  ref.onDispose(() => router.routerDelegate.removeListener(onRoute));
  return ref
      .watch(pagesRepositoryProvider)
      .listRecentPages(limit: RecentPages.limit);
}
