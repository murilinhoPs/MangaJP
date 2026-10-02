import 'card_srs_state.dart';

/// SM-2 (and later engines) implement this. Domain is Dart-only (PRD §10.4 / §12.1).
abstract class SrsEngine {
  /// Versioned engine id. Default implementation is `'sm2-jr@1'`.
  String get engineId;

  CardSrsState schedule(CardSrsState prev, int quality, DateTime now);

  Map<ReviewRating, CardSrsState> preview(CardSrsState prev, DateTime now);
}
