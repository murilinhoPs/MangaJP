import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_srs_state.freezed.dart';
part 'card_srs_state.g.dart';

enum CardPhase { neu, learning, review, relearning }

enum ReviewRating { again, hard, good, easy }

/// japanese-reader `next-review` `:status` (`"learning"` / `"learned"` / `"mastered"`).
enum JrReviewStatus { learning, learned, mastered }

int qualityFor(ReviewRating rating) => switch (rating) {
  ReviewRating.again => 0,
  ReviewRating.hard => 3,
  ReviewRating.good => 4,
  ReviewRating.easy => 5,
};

/// Persisted `review_logs.rating` (1–4). Quality stays [qualityFor] (0/3/4/5).
int ratingFor(ReviewRating rating) => switch (rating) {
  ReviewRating.again => 1,
  ReviewRating.hard => 2,
  ReviewRating.good => 3,
  ReviewRating.easy => 4,
};

/// Map JR status strings onto MangaJP [CardPhase] **without** changing SM-2 math.
///
/// - failed (`JrReviewStatus.learning`) → [CardPhase.learning] or
///   [CardPhase.relearning] (relearning if the card was already in review)
/// - `learned` / `mastered` → [CardPhase.review]
CardPhase mangaJpPhaseFor(JrReviewStatus jrStatus, CardPhase previous) {
  return switch (jrStatus) {
    JrReviewStatus.learned || JrReviewStatus.mastered => CardPhase.review,
    JrReviewStatus.learning
        when previous == CardPhase.review || previous == CardPhase.relearning =>
      CardPhase.relearning,
    JrReviewStatus.learning => CardPhase.learning,
  };
}

@freezed
abstract class CardSrsState with _$CardSrsState {
  const factory CardSrsState({
    required double easeFactor,
    required double intervalDays,
    required int repetitions,
    required DateTime dueAt,
    required CardPhase phase,
    @Default('sm2-jr@1') String engineId,
  }) = _CardSrsState;

  factory CardSrsState.fromJson(Map<String, dynamic> json) =>
      _$CardSrsStateFromJson(json);
}
