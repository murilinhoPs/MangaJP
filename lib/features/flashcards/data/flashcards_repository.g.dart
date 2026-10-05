// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcards_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flashcardsRepository)
final flashcardsRepositoryProvider = FlashcardsRepositoryProvider._();

final class FlashcardsRepositoryProvider
    extends
        $FunctionalProvider<
          FlashcardsRepository,
          FlashcardsRepository,
          FlashcardsRepository
        >
    with $Provider<FlashcardsRepository> {
  FlashcardsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flashcardsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flashcardsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FlashcardsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlashcardsRepository create(Ref ref) {
    return flashcardsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlashcardsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlashcardsRepository>(value),
    );
  }
}

String _$flashcardsRepositoryHash() =>
    r'a89b1c70df531077af92e221b7cc63cc0340b130';
