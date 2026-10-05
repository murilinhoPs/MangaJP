// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod codegen hello: reads `app_meta.hello` seeded by Drift `onCreate`.

@ProviderFor(HelloMeta)
final helloMetaProvider = HelloMetaProvider._();

/// Riverpod codegen hello: reads `app_meta.hello` seeded by Drift `onCreate`.
final class HelloMetaProvider
    extends $AsyncNotifierProvider<HelloMeta, String> {
  /// Riverpod codegen hello: reads `app_meta.hello` seeded by Drift `onCreate`.
  HelloMetaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'helloMetaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$helloMetaHash();

  @$internal
  @override
  HelloMeta create() => HelloMeta();
}

String _$helloMetaHash() => r'2430771fd64876e190d37eef934ae6a1440c298c';

/// Riverpod codegen hello: reads `app_meta.hello` seeded by Drift `onCreate`.

abstract class _$HelloMeta extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Due + novos hoje for the Home **Revisar** block. Uses the review clock.
///
/// Refetches when a `/review` answer persists, and again when the shell
/// returns to `/home` (Home stays mounted as a branch, so a one-shot
/// FutureProvider would otherwise stay stale).

@ProviderFor(homeReviewCounts)
final homeReviewCountsProvider = HomeReviewCountsProvider._();

/// Due + novos hoje for the Home **Revisar** block. Uses the review clock.
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
  /// Due + novos hoje for the Home **Revisar** block. Uses the review clock.
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

String _$homeReviewCountsHash() => r'a97e950a86bb928c0880f1fb9560ce794ecc274f';
