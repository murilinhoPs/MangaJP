import '../../../core/srs/card_srs_state.dart';

/// One due vocab card for `/review`. Gloss is loaded from JMdict by [seq].
class ReviewCard {
  const ReviewCard({
    required this.cardId,
    required this.wordId,
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.srs,
  });

  final String cardId;
  final String wordId;
  final int seq;
  final String lemma;
  final String reading;
  final CardSrsState srs;
}
