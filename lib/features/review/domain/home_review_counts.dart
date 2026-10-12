/// Home **Fila de hoje** / Biblioteca numbers from the due queue.
///
/// [due] is the non-`neu` part of [ReviewRepository.dueQueue] — learning,
/// relearning, and review that would enter now. Suspended cards and `neu`
/// (even those still in the queue under the daily cap) are not due.
///
/// [newToday] is the same introduced-`neu` count the `new_per_day` cap uses:
/// distinct cards whose first non-drill answer sits on this study-day.
///
/// [novos] / [revisoes] / [drill] split that same queue for the segmented bar
/// (`queue.novos` violet, `queue.revisoes` mint, `queue.drill` coral).
///
/// [waiting] is [ReviewRepository.dueQueue] length — the single source for
/// Biblioteca **para revisar**, the rail badge, `/review` **restantes**, and
/// the done-state requeue count. The in-memory session is one pass; when it
/// ends, remaining still reports this value. Reload refetches the queue.
/// Not the mint [revisoes] slice.
class HomeReviewCounts {
  const HomeReviewCounts({
    required this.due,
    required this.newToday,
    this.novos = 0,
    this.revisoes = 0,
    this.drill = 0,
  });

  final int due;
  final int newToday;
  final int novos;
  final int revisoes;
  final int drill;

  int get waiting => novos + revisoes + drill;
}
