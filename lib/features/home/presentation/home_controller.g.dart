// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod codegen hello: read/write a trivial `app_meta` key via Drift.

@ProviderFor(HelloMeta)
final helloMetaProvider = HelloMetaProvider._();

/// Riverpod codegen hello: read/write a trivial `app_meta` key via Drift.
final class HelloMetaProvider
    extends $AsyncNotifierProvider<HelloMeta, String> {
  /// Riverpod codegen hello: read/write a trivial `app_meta` key via Drift.
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

String _$helloMetaHash() => r'd8cfa886850083062f9e2c6dd0e20800f6c5b20f';

/// Riverpod codegen hello: read/write a trivial `app_meta` key via Drift.

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
