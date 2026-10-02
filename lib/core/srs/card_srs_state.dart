import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_srs_state.freezed.dart';
part 'card_srs_state.g.dart';

enum CardPhase { neu, learning, review, relearning }

enum ReviewRating { again, hard, good, easy }

int qualityFor(ReviewRating rating) => switch (rating) {
  ReviewRating.again => 0,
  ReviewRating.hard => 3,
  ReviewRating.good => 4,
  ReviewRating.easy => 5,
};

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
