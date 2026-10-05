// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory `/review` session: snapshot of [ReviewRepository.dueQueue] at
/// first build (already capped to leftover new-per-day slots). Again/Hard
/// go to the back; Good/Easy leave. Extra `neu` never join this snapshot;
/// a `neu` already here (Again/Hard) stays. Persistence (study-day / drill
/// vs SRS) lives in [ReviewRepository.answer].

@ProviderFor(ReviewSession)
final reviewSessionProvider = ReviewSessionProvider._();

/// In-memory `/review` session: snapshot of [ReviewRepository.dueQueue] at
/// first build (already capped to leftover new-per-day slots). Again/Hard
/// go to the back; Good/Easy leave. Extra `neu` never join this snapshot;
/// a `neu` already here (Again/Hard) stays. Persistence (study-day / drill
/// vs SRS) lives in [ReviewRepository.answer].
final class ReviewSessionProvider
    extends $AsyncNotifierProvider<ReviewSession, ReviewView?> {
  /// In-memory `/review` session: snapshot of [ReviewRepository.dueQueue] at
  /// first build (already capped to leftover new-per-day slots). Again/Hard
  /// go to the back; Good/Easy leave. Extra `neu` never join this snapshot;
  /// a `neu` already here (Again/Hard) stays. Persistence (study-day / drill
  /// vs SRS) lives in [ReviewRepository.answer].
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

String _$reviewSessionHash() => r'd51bcd5f424edc8749ac7fd326b3bbfe88e7ac2e';

/// In-memory `/review` session: snapshot of [ReviewRepository.dueQueue] at
/// first build (already capped to leftover new-per-day slots). Again/Hard
/// go to the back; Good/Easy leave. Extra `neu` never join this snapshot;
/// a `neu` already here (Again/Hard) stays. Persistence (study-day / drill
/// vs SRS) lives in [ReviewRepository.answer].

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
