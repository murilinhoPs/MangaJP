// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReviewSession)
final reviewSessionProvider = ReviewSessionProvider._();

final class ReviewSessionProvider
    extends $AsyncNotifierProvider<ReviewSession, ReviewView?> {
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

String _$reviewSessionHash() => r'8de16170bca9c1235b969c5d5c4f3c309bb3ade8';

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
