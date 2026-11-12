import '../../../core/srs/card_srs_state.dart';
import '../../words/domain/word_state.dart';
import 'suspend_reason.dart';

/// Study snapshot F23 reads: queue eligibility, Caderno state, SM-2 fields.
///
/// Suspend / reactivate never rewrite [srs]. Domain SRS stays in Dart puro
/// (`lib/core/srs`); this type only carries the row so tests can assert it
/// is unchanged.
class CardStudySnapshot {
  const CardStudySnapshot({
    required this.suspendReason,
    required this.wordState,
    required this.srs,
  });

  final String? suspendReason;
  final WordState wordState;
  final CardSrsState srs;

  bool get isInReviewQueue => isEligibleForReview(suspendReason);
}

/// Due queue (F14) only includes unsuspended cards (`suspend_reason` null).
bool isEligibleForReview(String? suspendReason) => suspendReason == null;

/// F23 suspend: `suspend_reason = user`. SRS and [wordState] stay.
CardStudySnapshot applyUserSuspend(CardStudySnapshot current) {
  return CardStudySnapshot(
    suspendReason: SuspendReason.user.dbValue,
    wordState: current.wordState,
    srs: current.srs,
  );
}

/// F23 reactivate: `suspend_reason = null`, `word_states = learning`. SRS stays.
CardStudySnapshot applyReactivate(CardStudySnapshot current) {
  return CardStudySnapshot(
    suspendReason: null,
    wordState: WordState.learning,
    srs: current.srs,
  );
}
