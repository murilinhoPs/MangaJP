import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../review/data/review_repository.dart';
import '../data/flashcards_repository.dart';
import '../domain/deck_card.dart';

part 'deck_controller.g.dart';

/// Deck list. Refetches when a `/review` answer persists and when F23
/// suspend / reactivate bumps [reviewRevisionProvider].
@riverpod
Future<List<DeckCard>> deckCards(Ref ref) {
  ref.watch(reviewRevisionProvider);
  return ref.watch(flashcardsRepositoryProvider).listDeck();
}
