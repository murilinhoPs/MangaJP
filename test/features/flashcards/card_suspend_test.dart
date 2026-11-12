import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';
import 'package:manga_jp/features/flashcards/domain/card_suspend.dart';
import 'package:manga_jp/features/flashcards/domain/suspend_reason.dart';
import 'package:manga_jp/features/words/domain/word_state.dart';

void main() {
  final srs = CardSrsState(
    easeFactor: 2.36,
    intervalDays: 14,
    repetitions: 3,
    dueAt: DateTime.utc(2026, 6, 15),
    phase: CardPhase.review,
    engineId: kSm2JrEngineId,
  );

  CardStudySnapshot learning() {
    return CardStudySnapshot(
      suspendReason: null,
      wordState: WordState.learning,
      srs: srs,
    );
  }

  test('unsuspended cards are in the review queue', () {
    expect(isEligibleForReview(null), isTrue);
    expect(learning().isInReviewQueue, isTrue);
  });

  test('user / known / ignored suspended cards stay out of the queue', () {
    expect(isEligibleForReview(SuspendReason.user.dbValue), isFalse);
    expect(isEligibleForReview(WordState.known.name), isFalse);
    expect(isEligibleForReview(WordState.ignored.name), isFalse);
    expect(isEligibleForReview('user'), isFalse);
  });

  test('user suspend is not known, ignored, or a missing reason', () {
    expect(SuspendReason.user.dbValue, 'user');
    expect(SuspendReason.user.dbValue, isNot(WordState.known.name));
    expect(SuspendReason.user.dbValue, isNot(WordState.ignored.name));
    expect(SuspendReason.fromDb('user'), SuspendReason.user);
    expect(SuspendReason.fromDb(null), isNull);
    expect(SuspendReason.fromDb(''), isNull);
  });

  test('suspend by user leaves the queue and keeps SM-2 and word_states', () {
    final next = applyUserSuspend(learning());
    expect(next.suspendReason, SuspendReason.user.dbValue);
    expect(next.wordState, WordState.learning);
    expect(next.srs, srs);
    expect(next.isInReviewQueue, isFalse);
    expect(next.srs.easeFactor, 2.36);
    expect(next.srs.intervalDays, 14);
    expect(next.srs.repetitions, 3);
    expect(next.srs.dueAt, DateTime.utc(2026, 6, 15));
    expect(next.srs.phase, CardPhase.review);
    expect(next.srs.engineId, kSm2JrEngineId);
  });

  test('reactivate returns to the queue with SM-2 preserved', () {
    final suspended = applyUserSuspend(learning());
    final next = applyReactivate(suspended);
    expect(next.suspendReason, isNull);
    expect(next.wordState, WordState.learning);
    expect(next.srs, srs);
    expect(next.isInReviewQueue, isTrue);
    expect(identical(next.srs, srs) || next.srs == srs, isTrue);
  });

  test('reactivate from known sets learning and does not reset SRS', () {
    final known = CardStudySnapshot(
      suspendReason: WordState.known.name,
      wordState: WordState.known,
      srs: srs,
    );
    final next = applyReactivate(known);
    expect(next.suspendReason, isNull);
    expect(next.wordState, WordState.learning);
    expect(next.srs, srs);
    expect(next.isInReviewQueue, isTrue);
  });
}
