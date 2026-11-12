// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_vision_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CloudVisionSettings)
final cloudVisionSettingsProvider = CloudVisionSettingsProvider._();

final class CloudVisionSettingsProvider
    extends
        $AsyncNotifierProvider<CloudVisionSettings, CloudVisionSettingsState> {
  CloudVisionSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudVisionSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudVisionSettingsHash();

  @$internal
  @override
  CloudVisionSettings create() => CloudVisionSettings();
}

String _$cloudVisionSettingsHash() =>
    r'4118c7cf91d69cb397a4085100f44d2e46d3b6e1';

abstract class _$CloudVisionSettings
    extends $AsyncNotifier<CloudVisionSettingsState> {
  FutureOr<CloudVisionSettingsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CloudVisionSettingsState>,
              CloudVisionSettingsState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CloudVisionSettingsState>,
                CloudVisionSettingsState
              >,
              AsyncValue<CloudVisionSettingsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
