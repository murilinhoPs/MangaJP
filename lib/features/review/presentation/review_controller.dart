import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../dictionary/data/jmdict_provider.dart';
import '../../dictionary/data/jmdict_service.dart';
import '../data/review_repository.dart';
import '../domain/review_card.dart';
import '../domain/review_rating.dart';
import '../domain/review_session_queue.dart';

part 'review_controller.g.dart';

/// Due card plus JMdict gloss loaded by seq (never stored on `words`).
///
/// [card] is null when the session has nothing to show: empty queue
/// ([isEmpty]) or every card has left ([isDone]).
class ReviewView {
  const ReviewView({
    required this.remaining,
    required this.startedWith,
    this.card,
    this.reading = '',
    this.glossText = '',
    this.showSeq = 0,
  });

  final ReviewCard? card;

  /// Kana from JMdict `data_json`, else the stored `words.reading`.
  final String reading;

  /// Copied from JMdict `entries.data_json` for [ReviewCard.seq].
  final String glossText;

  /// Bumps each time the session presents a card so the front resets.
  final int showSeq;

  /// Cards still in this in-memory session (Again/Hard stay).
  final int remaining;

  /// Queue size when the session opened.
  final int startedWith;

  bool get isEmpty => card == null && startedWith == 0;
  bool get isDone => card == null && startedWith > 0;
}

/// In-memory `/review` session: snapshot of [ReviewRepository.dueQueue] at
/// first build (already capped to leftover new-per-day slots). Again/Hard
/// go to the back; Good/Easy leave. Extra `neu` never join this snapshot;
/// a `neu` already here (Again/Hard) stays. Persistence (study-day / drill
/// vs SRS) lives in [ReviewRepository.answer].
@riverpod
class ReviewSession extends _$ReviewSession {
  List<ReviewCard>? _remaining;
  int _startedWith = 0;
  int _showSeq = 0;

  @override
  Future<ReviewView?> build() async {
    final repo = ref.watch(reviewRepositoryProvider);
    final jmdict = await ref.watch(jmdictServiceProvider.future);
    if (_remaining == null) {
      _remaining = [...await repo.dueQueue()];
      _startedWith = _remaining!.length;
    }
    return _viewFor(_remaining!, jmdict);
  }

  Future<void> answer(ReviewRating rating) async {
    final current = state.asData?.value;
    final remaining = _remaining;
    if (current?.card == null || remaining == null || remaining.isEmpty) {
      return;
    }
    await ref
        .read(reviewRepositoryProvider)
        .answer(current!.card!.cardId, rating);
    ref.read(reviewRevisionProvider.notifier).bump();
    final answeredId = current.card!.cardId;
    _remaining = [
      for (final card in applySessionRating(remaining, rating))
        card.cardId == answeredId ? card.asDrill() : card,
    ];
    _showSeq++;
    final jmdict = await ref.read(jmdictServiceProvider.future);
    state = AsyncData(_viewFor(_remaining!, jmdict));
  }

  ReviewView _viewFor(List<ReviewCard> remaining, JmdictService jmdict) {
    if (remaining.isEmpty) {
      return ReviewView(remaining: 0, startedWith: _startedWith);
    }
    final card = remaining.first;
    final entry = jmdict.entryBySeq(card.seq);
    final kana = entry?.reading;
    return ReviewView(
      card: card,
      reading: (kana != null && kana.isNotEmpty) ? kana : card.reading,
      glossText: entry?.glossText ?? '',
      remaining: remaining.length,
      startedWith: _startedWith,
      showSeq: _showSeq,
    );
  }
}
