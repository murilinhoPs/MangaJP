// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `/review` session: order is an in-memory snapshot of
/// [ReviewRepository.dueQueue] (already capped to leftover new-per-day
/// slots). Again/Hard go to the back; Good/Easy leave. **restantes** is
/// always the live DB queue length (same as the rail badge). When the
/// snapshot runs out, the done state reports how many are still due now;
/// [reloadQueue] refetches `dueQueue` and continues. Persistence
/// (study-day / drill vs SRS) lives in [ReviewRepository.answer].

@ProviderFor(ReviewSession)
final reviewSessionProvider = ReviewSessionProvider._();

/// `/review` session: order is an in-memory snapshot of
/// [ReviewRepository.dueQueue] (already capped to leftover new-per-day
/// slots). Again/Hard go to the back; Good/Easy leave. **restantes** is
/// always the live DB queue length (same as the rail badge). When the
/// snapshot runs out, the done state reports how many are still due now;
/// [reloadQueue] refetches `dueQueue` and continues. Persistence
/// (study-day / drill vs SRS) lives in [ReviewRepository.answer].
final class ReviewSessionProvider
    extends $AsyncNotifierProvider<ReviewSession, ReviewView?> {
  /// `/review` session: order is an in-memory snapshot of
  /// [ReviewRepository.dueQueue] (already capped to leftover new-per-day
  /// slots). Again/Hard go to the back; Good/Easy leave. **restantes** is
  /// always the live DB queue length (same as the rail badge). When the
  /// snapshot runs out, the done state reports how many are still due now;
  /// [reloadQueue] refetches `dueQueue` and continues. Persistence
  /// (study-day / drill vs SRS) lives in [ReviewRepository.answer].
  ReviewSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewSessionHash();

  @$internal
  @override
  ReviewSession create() => ReviewSession();
}

String _$reviewSessionHash() => r'0ac8a40fe1e7306fc4b7fead2384c03b994f475c';

/// `/review` session: order is an in-memory snapshot of
/// [ReviewRepository.dueQueue] (already capped to leftover new-per-day
/// slots). Again/Hard go to the back; Good/Easy leave. **restantes** is
/// always the live DB queue length (same as the rail badge). When the
/// snapshot runs out, the done state reports how many are still due now;
/// [reloadQueue] refetches `dueQueue` and continues. Persistence
/// (study-day / drill vs SRS) lives in [ReviewRepository.answer].

abstract class _$ReviewSession extends $AsyncNotifier<ReviewView?> {
  FutureOr<ReviewView?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ReviewView?>, ReviewView?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReviewView?>, ReviewView?>,
              AsyncValue<ReviewView?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
