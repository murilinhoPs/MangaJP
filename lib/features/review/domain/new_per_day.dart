/// Daily cap of new (`neu`) cards that may enter `/review`.
///
/// A `neu` card counts when it receives its first non-drill answer of the
/// current study-day (04:00 America/Sao_Paulo). Drill does not count. The
/// cap is a constant — no settings screen in this cut.
abstract final class NewPerDay {
  static const int limit = 15;
}

/// Keep every learning / relearning / review card. Keep at most
/// ([NewPerDay.limit] − [introduced]) `neu` cards, in existing order.
///
/// [introduced] is how many `neu` cards already had a non-drill answer
/// this study-day. Extra `neu` stay out of the due queue; they are not
/// dropped from an in-memory session that already snapshotted them.
List<T> applyNewPerDayLimit<T>(
  List<T> due, {
  required int introduced,
  required bool Function(T card) isNew,
}) {
  var remaining = NewPerDay.limit - introduced;
  if (remaining < 0) {
    remaining = 0;
  }
  final out = <T>[];
  for (final card in due) {
    if (isNew(card)) {
      if (remaining <= 0) {
        continue;
      }
      remaining--;
    }
    out.add(card);
  }
  return out;
}
