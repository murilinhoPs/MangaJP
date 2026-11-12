// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deck list. Refetches when a `/review` answer persists and when F23
/// suspend / reactivate bumps [reviewRevisionProvider].

@ProviderFor(deckCards)
final deckCardsProvider = DeckCardsProvider._();

/// Deck list. Refetches when a `/review` answer persists and when F23
/// suspend / reactivate bumps [reviewRevisionProvider].

final class DeckCardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DeckCard>>,
          List<DeckCard>,
          FutureOr<List<DeckCard>>
        >
    with $FutureModifier<List<DeckCard>>, $FutureProvider<List<DeckCard>> {
  /// Deck list. Refetches when a `/review` answer persists and when F23
  /// suspend / reactivate bumps [reviewRevisionProvider].
  DeckCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deckCardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deckCardsHash();

  @$internal
  @override
  $FutureProviderElement<List<DeckCard>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DeckCard>> create(Ref ref) {
    return deckCards(ref);
  }
}

String _$deckCardsHash() => r'830f688e4f22eaf9570972d952c6eb8f59d14303';
