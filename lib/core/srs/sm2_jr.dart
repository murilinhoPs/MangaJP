import 'card_srs_state.dart';
import 'srs_engine.dart';

/// SM-2 port of japanese-reader `sm2.clj` (`engine_id = sm2-jr@1`).
///
/// Where PRD prose and `sm2.clj` diverge, **Clojure wins**. M0 confirmation:
///
/// 1. **EF always updates**, including on fail (`q < 3`). The PRD's older
///    "do not change EF on fail" text is not the spec.
/// 2. **Rounding is `Math/round`** (Dart `num.round()`), not ceil.
/// 3. **Interval uses EF'** — `round(previousInterval * updatedEase)`, the
///    ease *after* this review, not the incoming EF.
const String kSm2JrEngineId = 'sm2-jr@1';

const double kDefaultEaseFactor = 2.5;
const double kMinimumEaseFactor = 1.3;

/// New-card SRS before any review. Same `prev` the golden tests schedule from:
/// EF 2.5, interval 0, repetitions 0, [CardPhase.neu], due [now].
CardSrsState initialCardSrsState(DateTime now) {
  return CardSrsState(
    easeFactor: kDefaultEaseFactor,
    intervalDays: 0,
    repetitions: 0,
    dueAt: now,
    phase: CardPhase.neu,
    engineId: kSm2JrEngineId,
  );
}

/// Result of [nextReview], mirroring the map returned by Clojure `next-review`.
class Sm2Review {
  const Sm2Review({
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
    required this.nextReviewDate,
    required this.status,
  });

  /// Days until next review (`:interval`). Integer, as in `sm2.clj`.
  final int interval;

  /// Ease after this review (`:ease-factor`). Floor 1.3.
  final double easeFactor;

  /// Successful-rep streak (`:repetitions`). 0 on fail.
  final int repetitions;

  /// Calendar date of the next review (`:next-review-date`).
  final DateTime nextReviewDate;

  /// JR status string as [JrReviewStatus] (`learning` / `learned` / `mastered`).
  final JrReviewStatus status;
}

/// Normalize supported review answers to an SM-2 quality score.
///
/// Port of `quality-score`: rating strings (`again`/`hard`/`good`/`easy`),
/// numeric scores, and the roadmap `correct?` boolean shape.
int qualityScore({Object? rating, num? quality, bool? correct}) {
  if (quality != null) {
    return _clampQuality(quality);
  }
  if (rating is num) {
    return _clampQuality(rating);
  }
  final ratingName = rating is ReviewRating ? rating.name : rating;
  if (ratingName == 'again') return 0;
  if (ratingName == 'hard') return 3;
  if (ratingName == 'good') return 4;
  if (ratingName == 'easy') return 5;
  if (correct == false) return 0;
  if (correct == true) return 4;
  return 4;
}

int _clampQuality(num value) {
  final n = value.toInt();
  if (n < 0) return 0;
  if (n > 5) return 5;
  return n;
}

/// SM-2 ease update. Always applied (including `q < 3`). Floor [kMinimumEaseFactor].
double updatedEaseFactor(double easeFactor, int quality) {
  final nextEf =
      easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  return nextEf < kMinimumEaseFactor ? kMinimumEaseFactor : nextEf;
}

/// Pure SM-2 scheduling update. Port of Clojure `next-review`.
///
/// [now] is the Dart stand-in for `LocalDate/now`; due dates are calendar
/// dates (`plusDays`), not 24-hour durations.
Sm2Review nextReview({
  int interval = 0,
  int repetitions = 0,
  double easeFactor = kDefaultEaseFactor,
  required Object quality,
  required DateTime now,
}) {
  final q = quality is num
      ? qualityScore(quality: quality)
      : qualityScore(rating: quality);
  final failed = q < 3;
  final nextRepetitions = failed ? 0 : repetitions + 1;
  final nextEase = updatedEaseFactor(easeFactor, q);
  final nextInterval = failed
      ? 0
      : switch (nextRepetitions) {
          1 => 1,
          2 => 6,
          _ => _max1((interval * nextEase).round()),
        };
  final status = failed
      ? JrReviewStatus.learning
      : nextRepetitions >= 8
      ? JrReviewStatus.mastered
      : JrReviewStatus.learned;

  return Sm2Review(
    interval: nextInterval,
    easeFactor: nextEase,
    repetitions: nextRepetitions,
    nextReviewDate: _addCalendarDays(now, nextInterval),
    status: status,
  );
}

int _max1(int value) => value < 1 ? 1 : value;

DateTime _addCalendarDays(DateTime now, int days) {
  return now.isUtc
      ? DateTime.utc(now.year, now.month, now.day + days)
      : DateTime(now.year, now.month, now.day + days);
}

/// japanese-reader SM-2 engine (`engine_id = sm2-jr@1`).
class Sm2JrEngine implements SrsEngine {
  const Sm2JrEngine();

  @override
  String get engineId => kSm2JrEngineId;

  @override
  CardSrsState schedule(CardSrsState prev, int quality, DateTime now) {
    final review = nextReview(
      interval: prev.intervalDays.truncate(),
      repetitions: prev.repetitions,
      easeFactor: prev.easeFactor,
      quality: quality,
      now: now,
    );
    return CardSrsState(
      easeFactor: review.easeFactor,
      intervalDays: review.interval.toDouble(),
      repetitions: review.repetitions,
      dueAt: review.nextReviewDate,
      phase: mangaJpPhaseFor(review.status, prev.phase),
      engineId: engineId,
    );
  }

  @override
  Map<ReviewRating, CardSrsState> preview(CardSrsState prev, DateTime now) {
    return {
      for (final rating in ReviewRating.values)
        rating: schedule(prev, qualityFor(rating), now),
    };
  }
}
