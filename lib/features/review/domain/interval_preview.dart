import '../../../core/srs/card_srs_state.dart';
import '../../../core/srs/sm2_jr.dart';
import '../../../core/srs/srs_engine.dart';

/// Portuguese interval copy for `/review` rating buttons.
///
/// `0` is today (`hoje`). Anything else is a whole-day count (`1 dia`,
/// `16 dias`). The number itself comes from [SrsEngine.preview].
String intervalPreviewLabel(int intervalDays) {
  if (intervalDays <= 0) {
    return 'hoje';
  }
  if (intervalDays == 1) {
    return '1 dia';
  }
  return '$intervalDays dias';
}

/// Labels each rating would schedule from [prev], or `null` on a drill
/// answer (second answer of the card on this study-day). Pure: it only
/// calls [SrsEngine.preview] and does not write logs or `card_srs`.
Map<ReviewRating, String>? ratingPreviewLabels(
  CardSrsState prev, {
  required bool isDrill,
  SrsEngine engine = const Sm2JrEngine(),
  DateTime? now,
}) {
  if (isDrill) {
    return null;
  }
  final preview = engine.preview(prev, now ?? prev.dueAt);
  return {
    for (final rating in ReviewRating.values)
      rating: intervalPreviewLabel(preview[rating]!.intervalDays.truncate()),
  };
}
