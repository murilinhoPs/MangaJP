// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'words_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wordsRepository)
final wordsRepositoryProvider = WordsRepositoryProvider._();

final class WordsRepositoryProvider
    extends
        $FunctionalProvider<WordsRepository, WordsRepository, WordsRepository>
    with $Provider<WordsRepository> {
  WordsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WordsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WordsRepository create(Ref ref) {
    return wordsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordsRepository>(value),
    );
  }
}

String _$wordsRepositoryHash() => r'd5e271844e789fae210b746e2bc9907933e83062';
