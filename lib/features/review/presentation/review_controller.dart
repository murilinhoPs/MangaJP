import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../dictionary/data/jmdict_provider.dart';
import '../../dictionary/data/jmdict_service.dart';
import '../data/review_repository.dart';
import '../domain/review_card.dart';
import '../domain/review_rating.dart';
import '../domain/review_session_queue.dart';

part 'review_controller.g.dart';

/// Due card plus JMdict gloss loaded by seq (never stored on `words`).
class ReviewView {
  const ReviewView({
    required this.card,
    required this.glossText,
    this.showSeq = 0,
  });

  final ReviewCard card;

  /// Copied from JMdict `entries.data_json` for [ReviewCard.seq].
  final String glossText;

  /// Bumps each time the session presents a card so the front resets.
  final int showSeq;
}

/// In-memory `/review` session: snapshot of [ReviewRepository.dueQueue] at
/// first build (already capped to leftover new-per-day slots). Again/Hard
/// go to the back; Good/Easy leave. Extra `neu` never join this snapshot;
/// a `neu` already here (Again/Hard) stays. Persistence (study-day / drill
/// vs SRS) lives in [ReviewRepository.answer].
@riverpod
class ReviewSession extends _$ReviewSession {
  List<ReviewCard>? _remaining;
  int _showSeq = 0;

  @override
  Future<ReviewView?> build() async {
    final repo = ref.watch(reviewRepositoryProvider);
    final jmdict = await ref.watch(jmdictServiceProvider.future);
    _remaining ??= [...await repo.dueQueue()];
    return _viewFor(_remaining!, jmdict);
  }

  Future<void> answer(ReviewRating rating) async {
    final current = state.asData?.value;
    final remaining = _remaining;
    if (current == null || remaining == null || remaining.isEmpty) {
      return;
    }
    await ref
        .read(reviewRepositoryProvider)
        .answer(current.card.cardId, rating);
    ref.read(reviewRevisionProvider.notifier).bump();
    final answeredId = current.card.cardId;
    _remaining = [
      for (final card in applySessionRating(remaining, rating))
        card.cardId == answeredId ? card.asDrill() : card,
    ];
    _showSeq++;
    final jmdict = await ref.read(jmdictServiceProvider.future);
    state = AsyncData(_viewFor(_remaining!, jmdict));
  }

  ReviewView? _viewFor(List<ReviewCard> remaining, JmdictService jmdict) {
    if (remaining.isEmpty) {
      return null;
    }
    final card = remaining.first;
    final entry = jmdict.entryBySeq(card.seq);
    return ReviewView(
      card: card,
      glossText: entry?.glossText ?? '',
      showSeq: _showSeq,
    );
  }
}
