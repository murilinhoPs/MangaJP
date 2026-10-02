import 'card_srs_state.dart';
import 'srs_engine.dart';

/// Placeholder for the japanese-reader SM-2 port (`engine_id = sm2-jr@1`).
///
/// Algorithm + golden tests are **not** part of M0.1 — see PRD §10 / M0 later.
class Sm2JrEngine implements SrsEngine {
  const Sm2JrEngine();

  @override
  String get engineId => 'sm2-jr@1';

  @override
  CardSrsState schedule(CardSrsState prev, int quality, DateTime now) {
    throw UnimplementedError(
      'SM-2 schedule is not implemented in the M0.1 scaffold.',
    );
  }

  @override
  Map<ReviewRating, CardSrsState> preview(CardSrsState prev, DateTime now) {
    throw UnimplementedError(
      'SM-2 preview is not implemented in the M0.1 scaffold.',
    );
  }
}
