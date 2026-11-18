// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_image_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pageImageStore)
final pageImageStoreProvider = PageImageStoreProvider._();

final class PageImageStoreProvider
    extends $FunctionalProvider<PageImageStore, PageImageStore, PageImageStore>
    with $Provider<PageImageStore> {
  PageImageStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageImageStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageImageStoreHash();

  @$internal
  @override
  $ProviderElement<PageImageStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PageImageStore create(Ref ref) {
    return pageImageStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageImageStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageImageStore>(value),
    );
  }
}

String _$pageImageStoreHash() => r'70e29ad4049a806af555d67ce467e8150cefed30';
