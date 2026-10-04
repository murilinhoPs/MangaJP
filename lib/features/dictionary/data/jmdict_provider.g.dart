// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jmdict_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens the M0.5 JMdict asset read-only. Tests override with a fixture file.

@ProviderFor(jmdictService)
final jmdictServiceProvider = JmdictServiceProvider._();

/// Opens the M0.5 JMdict asset read-only. Tests override with a fixture file.

final class JmdictServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<JmdictService>,
          JmdictService,
          FutureOr<JmdictService>
        >
    with $FutureModifier<JmdictService>, $FutureProvider<JmdictService> {
  /// Opens the M0.5 JMdict asset read-only. Tests override with a fixture file.
  JmdictServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jmdictServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jmdictServiceHash();

  @$internal
  @override
  $FutureProviderElement<JmdictService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JmdictService> create(Ref ref) {
    return jmdictService(ref);
  }
}

String _$jmdictServiceHash() => r'ed5f13b4e7563849be1f2c2b3a091e8621504206';

@ProviderFor(dictionaryLookup)
final dictionaryLookupProvider = DictionaryLookupProvider._();

final class DictionaryLookupProvider
    extends
        $FunctionalProvider<
          AsyncValue<DictionaryLookup>,
          DictionaryLookup,
          FutureOr<DictionaryLookup>
        >
    with $FutureModifier<DictionaryLookup>, $FutureProvider<DictionaryLookup> {
  DictionaryLookupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dictionaryLookupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dictionaryLookupHash();

  @$internal
  @override
  $FutureProviderElement<DictionaryLookup> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DictionaryLookup> create(Ref ref) {
    return dictionaryLookup(ref);
  }
}

String _$dictionaryLookupHash() => r'b2416d7429b1e52fadb8f0388667711e34867d11';
