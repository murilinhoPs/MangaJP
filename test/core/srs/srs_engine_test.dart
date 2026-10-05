import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/core/srs/srs_engine.dart';

void main() {
  const engine = Sm2JrEngine();
  final now = DateTime(2026, 10, 2);

  test('Sm2JrEngine advertises engine_id sm2-jr@1', () {
    const SrsEngine typed = engine;
    expect(typed.engineId, 'sm2-jr@1');
    expect(kSm2JrEngineId, 'sm2-jr@1');
  });

  test('schedule maps first good onto review / learned', () {
    final prev = CardSrsState(
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
      dueAt: now,
      phase: CardPhase.neu,
    );
    final next = engine.schedule(prev, 4, now);
    expect(next.intervalDays, 1);
    expect(next.repetitions, 1);
    expect(next.phase, CardPhase.review);
    expect(next.dueAt, DateTime(2026, 10, 3));
    expect(next.engineId, 'sm2-jr@1');
  });

  test('failed→learning when previous phase is new/learning', () {
    final prev = CardSrsState(
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
      dueAt: now,
      phase: CardPhase.neu,
    );
    final next = engine.schedule(prev, 0, now);
    expect(next.phase, CardPhase.learning);
    expect(next.intervalDays, 0);
    expect(next.repetitions, 0);
    expect(next.dueAt, DateTime(2026, 10, 2));
  });

  test('failed→relearning when previous phase is review (learned)', () {
    final prev = CardSrsState(
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      dueAt: now,
      phase: CardPhase.review,
    );
    final next = engine.schedule(prev, 0, now);
    expect(next.phase, CardPhase.relearning);
    expect(next.intervalDays, 0);
    expect(next.repetitions, 0);
    expect(
      mangaJpPhaseFor(JrReviewStatus.learning, CardPhase.review),
      CardPhase.relearning,
    );
  });

  test('learned/mastered→review', () {
    expect(
      mangaJpPhaseFor(JrReviewStatus.learned, CardPhase.learning),
      CardPhase.review,
    );
    expect(
      mangaJpPhaseFor(JrReviewStatus.mastered, CardPhase.relearning),
      CardPhase.review,
    );
  });

  test('ratingFor is 1–4 and qualityFor is 0/3/4/5', () {
    expect(ratingFor(ReviewRating.again), 1);
    expect(ratingFor(ReviewRating.hard), 2);
    expect(ratingFor(ReviewRating.good), 3);
    expect(ratingFor(ReviewRating.easy), 4);
    expect(qualityFor(ReviewRating.again), 0);
    expect(qualityFor(ReviewRating.hard), 3);
    expect(qualityFor(ReviewRating.good), 4);
    expect(qualityFor(ReviewRating.easy), 5);
  });

  test('preview schedules all four ratings from qualityFor', () {
    final prev = CardSrsState(
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      dueAt: now,
      phase: CardPhase.review,
    );
    final preview = engine.preview(prev, now);
    expect(preview.keys, ReviewRating.values);
    for (final rating in ReviewRating.values) {
      expect(preview[rating], engine.schedule(prev, qualityFor(rating), now));
    }
  });
}
