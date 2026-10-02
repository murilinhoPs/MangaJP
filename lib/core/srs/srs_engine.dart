import 'card_srs_state.dart';

/// SM-2 (and later engines) implement this. Domain is Dart-only (PRD §12.1).
abstract class SrsEngine {
  String get engineId;

  CardSrsState schedule(CardSrsState prev, int quality, DateTime now);

  Map<ReviewRating, CardSrsState> preview(CardSrsState prev, DateTime now);
}
