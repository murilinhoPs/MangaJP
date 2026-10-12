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

  /// [ReviewRepository.dueQueue] length right now — same number as
  /// Biblioteca **para revisar** / the rail badge / done requeue count.
  final int remaining;

  /// Queue size when the session opened.
  final int startedWith;

  bool get isEmpty => card == null && startedWith == 0;
  bool get isDone => card == null && startedWith > 0;
}

/// `/review` session: order is an in-memory snapshot of
/// [ReviewRepository.dueQueue] (already capped to leftover new-per-day
/// slots). Again/Hard go to the back; Good/Easy leave. **restantes** is
/// always the live DB queue length (same as the rail badge). When the
/// snapshot runs out, the done state reports how many are still due now;
/// [reloadQueue] refetches `dueQueue` and continues. Persistence
/// (study-day / drill vs SRS) lives in [ReviewRepository.answer].
@riverpod
class ReviewSession extends _$ReviewSession {
  List<ReviewCard>? _remaining;
  int _startedWith = 0;
  int _showSeq = 0;

  @override
  Future<ReviewView?> build() async {
    final repo = ref.watch(reviewRepositoryProvider);
    final jmdict = await ref.watch(jmdictServiceProvider.future);
    final queue = [...await repo.dueQueue()];
    if (_remaining == null) {
      _remaining = queue;
      _startedWith = queue.length;
    }
    return _viewFor(_remaining!, jmdict, waiting: queue.length);
  }

  Future<void> answer(ReviewRating rating) async {
    final current = state.asData?.value;
    final remaining = _remaining;
    if (current?.card == null || remaining == null || remaining.isEmpty) {
      return;
    }
    final repo = ref.read(reviewRepositoryProvider);
    await repo.answer(current!.card!.cardId, rating);
    ref.read(reviewRevisionProvider.notifier).bump();
    final answeredId = current.card!.cardId;
    final next = [
      for (final card in applySessionRating(remaining, rating))
        card.cardId == answeredId ? card.asDrill() : card,
    ];
    final queue = [...await repo.dueQueue()];
    _remaining = next;
    _showSeq++;
    final jmdict = await ref.read(jmdictServiceProvider.future);
    state = AsyncData(_viewFor(next, jmdict, waiting: queue.length));
  }

  /// Rebuild the in-memory pass from the live DB queue (Errei/Difícil
  /// cards still due now). No-op when that queue is empty.
  Future<void> reloadQueue() async {
    final repo = ref.read(reviewRepositoryProvider);
    final queue = [...await repo.dueQueue()];
    if (queue.isEmpty) {
      return;
    }
    _remaining = queue;
    if (_startedWith == 0) {
      _startedWith = queue.length;
    }
    _showSeq++;
    final jmdict = await ref.read(jmdictServiceProvider.future);
    state = AsyncData(_viewFor(queue, jmdict, waiting: queue.length));
  }

  ReviewView _viewFor(
    List<ReviewCard> remaining,
    JmdictService jmdict, {
    required int waiting,
  }) {
    if (remaining.isEmpty) {
      return ReviewView(remaining: waiting, startedWith: _startedWith);
    }
    final card = remaining.first;
    final entry = jmdict.entryBySeq(card.seq);
    final kana = entry?.reading;
    return ReviewView(
      card: card,
      reading: (kana != null && kana.isNotEmpty) ? kana : card.reading,
      glossText: entry?.glossText ?? '',
      remaining: waiting,
      startedWith: _startedWith,
      showSeq: _showSeq,
    );
  }
}
