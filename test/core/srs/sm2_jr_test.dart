import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';

/// Golden port of `japanese-reader` `sm2_test.clj`.
///
/// Each `is` / `testing` block is mirrored. [now] stands in for `LocalDate/now`.
void main() {
  // Frozen calendar date so due-date asserts do not flake across midnight.
  final now = DateTime(2026, 10, 2);

  test('initialCardSrsState is the golden prev, not a scheduled review', () {
    final initial = initialCardSrsState(now);
    expect(initial.easeFactor, kDefaultEaseFactor);
    expect(initial.intervalDays, 0);
    expect(initial.repetitions, 0);
    expect(initial.dueAt, now);
    expect(initial.phase.name, 'neu');
    expect(initial.engineId, kSm2JrEngineId);
    final afterGood = nextReview(
      interval: 0,
      repetitions: 0,
      easeFactor: 2.5,
      quality: 4,
      now: now,
    );
    expect(afterGood.interval, 1);
    expect(initial.intervalDays, isNot(afterGood.interval));
  });

  group('quality-score-test', () {
    test('normalizes supported answer shapes', () {
      expect(qualityScore(rating: 'again'), 0);
      expect(qualityScore(rating: 'hard'), 3);
      expect(qualityScore(rating: 'good'), 4);
      expect(qualityScore(rating: 'easy'), 5);
      expect(qualityScore(correct: true), 4);
      expect(qualityScore(correct: false), 0);
    });
  });

  group('next-review-test', () {
    test(
      'marks first successful review as learned and schedules it for tomorrow',
      () {
        final review = nextReview(
          interval: 0,
          repetitions: 0,
          easeFactor: 2.5,
          quality: 4,
          now: now,
        );
        expect(review.interval, 1);
        expect(review.repetitions, 1);
        expect(review.status.name, 'learned');
        expect(review.nextReviewDate, DateTime(2026, 10, 3));
      },
    );

    test('resets repetitions for failed cards', () {
      final review = nextReview(
        interval: 6,
        repetitions: 2,
        easeFactor: 2.5,
        quality: 0,
        now: now,
      );
      expect(review.interval, 0);
      expect(review.repetitions, 0);
      expect(review.status.name, 'learning');
      expect(review.nextReviewDate, DateTime(2026, 10, 2));
    });

    test('uses later intervals after repeated successful reviews', () {
      final review = nextReview(
        interval: 6,
        repetitions: 2,
        easeFactor: 2.5,
        quality: 5,
        now: now,
      );
      expect(review.interval, 16);
      expect(review.repetitions, 3);
      expect(review.status.name, 'learned');
      expect(review.easeFactor, greaterThan(2.5));
    });

    test('marks heavily repeated successful cards as mastered', () {
      final review = nextReview(
        interval: 40,
        repetitions: 7,
        easeFactor: 2.5,
        quality: 5,
        now: now,
      );
      expect(review.repetitions, 8);
      expect(review.status.name, 'mastered');
    });
  });

  group('M0 confirmation vs sm2.clj', () {
    test('EF always updates on fail (q < 3)', () {
      final review = nextReview(
        interval: 6,
        repetitions: 2,
        easeFactor: 2.5,
        quality: 0,
        now: now,
      );
      // 2.5 + (0.1 - 5*(0.08 + 5*0.02)) = 1.7
      expect(review.easeFactor, closeTo(1.7, 1e-9));
    });

    test('interval uses round(prev * EF\') not ceil and not pre-update EF', () {
      // q=5 → EF' = 2.6; 6 * 2.6 = 15.6 → round 16 (ceil would also be 16).
      // If the interval used the incoming EF 2.5, 6*2.5 = 15.
      final review = nextReview(
        interval: 6,
        repetitions: 2,
        easeFactor: 2.5,
        quality: 5,
        now: now,
      );
      expect(review.easeFactor, closeTo(2.6, 1e-9));
      expect(review.interval, 16);
    });

    test('hard (q=3) interval uses Math.round not ceil', () {
      // q=3 → EF' = 2.5 + (0.1 - 2*(0.08 + 2*0.02)) = 2.36
      // 6 * 2.36 = 14.16 → round 14; ceil would be 15.
      final review = nextReview(
        interval: 6,
        repetitions: 2,
        easeFactor: 2.5,
        quality: 3,
        now: now,
      );
      expect(review.easeFactor, closeTo(2.36, 1e-9));
      expect(review.interval, 14);
      expect(review.repetitions, 3);
      expect(review.status.name, 'learned');
    });
  });
}
