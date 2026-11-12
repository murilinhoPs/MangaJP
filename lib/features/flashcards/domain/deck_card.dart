import '../../../core/srs/card_srs_state.dart';
import '../../words/domain/word_state.dart';
import 'suspend_reason.dart';

/// One Deck row: a vocab card with its word, Caderno state, and SRS.
class DeckCard {
  const DeckCard({
    required this.cardId,
    required this.wordId,
    required this.lemma,
    required this.reading,
    required this.createdAt,
    required this.wordState,
    required this.srs,
    this.suspendReason,
  });

  final String cardId;
  final String wordId;
  final String lemma;
  final String reading;
  final DateTime createdAt;
  final WordState wordState;
  final CardSrsState srs;
  final String? suspendReason;

  SuspendReason? get reason => SuspendReason.fromDb(suspendReason);

  bool get isUserSuspended => reason == SuspendReason.user;

  bool get canSuspend => suspendReason == null;

  bool get canReactivate => isUserSuspended;
}
