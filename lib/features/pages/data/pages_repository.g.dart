// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pages_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pagesRepository)
final pagesRepositoryProvider = PagesRepositoryProvider._();

final class PagesRepositoryProvider
    extends
        $FunctionalProvider<PagesRepository, PagesRepository, PagesRepository>
    with $Provider<PagesRepository> {
  PagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pagesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pagesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PagesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PagesRepository create(Ref ref) {
    return pagesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PagesRepository>(value),
    );
  }
}

String _$pagesRepositoryHash() => r'bf3e5fac0753f93670b1070b214262dba9f63258';
