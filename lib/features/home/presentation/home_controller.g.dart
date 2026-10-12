// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Due + queue segments for the Home **Fila de hoje** / Biblioteca counts.
///
/// Refetches when a `/review` answer persists, and again when the shell
/// returns to `/home` (Home stays mounted as a branch, so a one-shot
/// FutureProvider would otherwise stay stale).

@ProviderFor(homeReviewCounts)
final homeReviewCountsProvider = HomeReviewCountsProvider._();

/// Due + queue segments for the Home **Fila de hoje** / Biblioteca counts.
///
/// Refetches when a `/review` answer persists, and again when the shell
/// returns to `/home` (Home stays mounted as a branch, so a one-shot
/// FutureProvider would otherwise stay stale).

final class HomeReviewCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeReviewCounts>,
          HomeReviewCounts,
          FutureOr<HomeReviewCounts>
        >
    with $FutureModifier<HomeReviewCounts>, $FutureProvider<HomeReviewCounts> {
  /// Due + queue segments for the Home **Fila de hoje** / Biblioteca counts.
  ///
  /// Refetches when a `/review` answer persists, and again when the shell
  /// returns to `/home` (Home stays mounted as a branch, so a one-shot
  /// FutureProvider would otherwise stay stale).
  HomeReviewCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeReviewCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeReviewCountsHash();

  @$internal
  @override
  $FutureProviderElement<HomeReviewCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeReviewCounts> create(Ref ref) {
    return homeReviewCounts(ref);
  }
}

String _$homeReviewCountsHash() => r'dd0e7d916385a609dd8d634ce090b53f737d2a50';

/// Newest pages for Home **Capturas recentes** / **Páginas recentes**.
///
/// Refetches when the shell returns to `/home` (Home stays mounted as a
/// branch, so a one-shot FutureProvider would otherwise stay stale after
/// `/capture` → `/pages/:id`).

@ProviderFor(homeRecentPages)
final homeRecentPagesProvider = HomeRecentPagesProvider._();

/// Newest pages for Home **Capturas recentes** / **Páginas recentes**.
///
/// Refetches when the shell returns to `/home` (Home stays mounted as a
/// branch, so a one-shot FutureProvider would otherwise stay stale after
/// `/capture` → `/pages/:id`).

final class HomeRecentPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HomeRecentEntry>>,
          List<HomeRecentEntry>,
          FutureOr<List<HomeRecentEntry>>
        >
    with
        $FutureModifier<List<HomeRecentEntry>>,
        $FutureProvider<List<HomeRecentEntry>> {
  /// Newest pages for Home **Capturas recentes** / **Páginas recentes**.
  ///
  /// Refetches when the shell returns to `/home` (Home stays mounted as a
  /// branch, so a one-shot FutureProvider would otherwise stay stale after
  /// `/capture` → `/pages/:id`).
  HomeRecentPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRecentPagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRecentPagesHash();

  @$internal
  @override
  $FutureProviderElement<List<HomeRecentEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HomeRecentEntry>> create(Ref ref) {
    return homeRecentPages(ref);
  }
}

String _$homeRecentPagesHash() => r'a3346a988795f8d414e4e0e39876464375abca71';

@ProviderFor(homePageCount)
final homePageCountProvider = HomePageCountProvider._();

final class HomePageCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  HomePageCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homePageCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homePageCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return homePageCount(ref);
  }
}

String _$homePageCountHash() => r'b76700baa822063d7bdf8605c6483d9f58de402c';

/// Last 7 study-days of `review_logs`. `null` when the week has no answers.

@ProviderFor(homeWeekRhythm)
final homeWeekRhythmProvider = HomeWeekRhythmProvider._();

/// Last 7 study-days of `review_logs`. `null` when the week has no answers.

final class HomeWeekRhythmProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeWeekRhythm?>,
          HomeWeekRhythm?,
          FutureOr<HomeWeekRhythm?>
        >
    with $FutureModifier<HomeWeekRhythm?>, $FutureProvider<HomeWeekRhythm?> {
  /// Last 7 study-days of `review_logs`. `null` when the week has no answers.
  HomeWeekRhythmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWeekRhythmProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWeekRhythmHash();

  @$internal
  @override
  $FutureProviderElement<HomeWeekRhythm?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeWeekRhythm?> create(Ref ref) {
    return homeWeekRhythm(ref);
  }
}

String _$homeWeekRhythmHash() => r'f37a0640a39ed06d29faffd3ad80af4b14d43882';
