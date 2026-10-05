import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../dictionary/data/jmdict_provider.dart';
import '../data/review_repository.dart';
import '../domain/review_card.dart';
import '../domain/review_rating.dart';

part 'review_controller.g.dart';

/// Due card plus JMdict gloss loaded by seq (never stored on `words`).
class ReviewView {
  const ReviewView({required this.card, required this.glossText});

  final ReviewCard card;

  /// Copied from JMdict `entries.data_json` for [ReviewCard.seq].
  final String glossText;
}

@riverpod
class ReviewSession extends _$ReviewSession {
  @override
  Future<ReviewView?> build() async {
    final card = await ref.watch(reviewRepositoryProvider).nextDue();
    if (card == null) {
      return null;
    }
    final jmdict = await ref.watch(jmdictServiceProvider.future);
    final entry = jmdict.entryBySeq(card.seq);
    return ReviewView(card: card, glossText: entry?.glossText ?? '');
  }

  Future<void> answer(ReviewRating rating) async {
    final current = await future;
    if (current == null) {
      return;
    }
    await ref.read(reviewRepositoryProvider).answer(current.card.cardId, rating);
    ref.invalidateSelf();
  }
}
