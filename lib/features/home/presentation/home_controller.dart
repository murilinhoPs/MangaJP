import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/router/app_router.dart';
import '../../pages/data/pages_repository.dart';
import '../../pages/domain/recent_pages.dart';
import '../../review/data/review_repository.dart';
import '../../review/domain/home_review_counts.dart';
import '../../review/domain/study_day.dart';
import '../domain/home_recent_entry.dart';
import '../domain/home_week_rhythm.dart';

part 'home_controller.g.dart';

void _refetchOnReturnHome(Ref ref) {
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
}

/// Due + queue segments for the Home **Fila de hoje** / Biblioteca counts.
///
/// Refetches when a `/review` answer persists, and again when the shell
/// returns to `/home` (Home stays mounted as a branch, so a one-shot
/// FutureProvider would otherwise stay stale).
@riverpod
Future<HomeReviewCounts> homeReviewCounts(Ref ref) {
  ref.watch(reviewRevisionProvider);
  _refetchOnReturnHome(ref);
  return ref.watch(reviewRepositoryProvider).homeCounts();
}

/// Newest pages for Home **Capturas recentes** / **Páginas recentes**.
///
/// Refetches when the shell returns to `/home` (Home stays mounted as a
/// branch, so a one-shot FutureProvider would otherwise stay stale after
/// `/capture` → `/pages/:id`).
@riverpod
Future<List<HomeRecentEntry>> homeRecentPages(Ref ref) async {
  _refetchOnReturnHome(ref);
  final repo = ref.watch(pagesRepositoryProvider);
  final pages = await repo.listRecentPages(limit: RecentPages.limit);
  final out = <HomeRecentEntry>[];
  for (final page in pages) {
    final crops = await repo.cropsForPage(page.id);
    out.add(
      HomeRecentEntry(
        id: page.id,
        createdAt: page.createdAt,
        cropCount: crops.length,
        ocrPreview: crops.isEmpty ? null : crops.first.ocrText,
      ),
    );
  }
  return out;
}

@riverpod
Future<int> homePageCount(Ref ref) {
  _refetchOnReturnHome(ref);
  return ref.watch(pagesRepositoryProvider).countPages();
}

/// Current week (Mon→Sun study-days) of `review_logs`. `null` when empty.
@riverpod
Future<HomeWeekRhythm?> homeWeekRhythm(Ref ref) async {
  ref.watch(reviewRevisionProvider);
  _refetchOnReturnHome(ref);
  final review = ref.watch(reviewRepositoryProvider);
  final now = review.nowUtc();
  final times = await review.reviewTimesSince(StudyDay.weekStartOf(now));
  final week = HomeWeekRhythm.fromLogs(now, times);
  if (!week.hasActivity) {
    return null;
  }
  return week;
}
