// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_source_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(imageSourceService)
final imageSourceServiceProvider = ImageSourceServiceProvider._();

final class ImageSourceServiceProvider
    extends
        $FunctionalProvider<
          ImageSourceService,
          ImageSourceService,
          ImageSourceService
        >
    with $Provider<ImageSourceService> {
  ImageSourceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageSourceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageSourceServiceHash();

  @$internal
  @override
  $ProviderElement<ImageSourceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageSourceService create(Ref ref) {
    return imageSourceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageSourceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageSourceService>(value),
    );
  }
}

String _$imageSourceServiceHash() =>
    r'871baf5211081c8653e0f6582e9955b60f3f9d22';
