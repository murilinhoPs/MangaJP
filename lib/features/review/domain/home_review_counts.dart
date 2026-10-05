/// Home **Revisar** numbers: due now, plus `neu` already counted today.
///
/// [due] is the non-`neu` part of [ReviewRepository.dueQueue] — learning,
/// relearning, and review that would enter now. Suspended cards and `neu`
/// (even those still in the queue under the daily cap) are not due.
///
/// [newToday] is the same introduced-`neu` count the `new_per_day` cap uses:
/// distinct cards whose first non-drill answer sits on this study-day.
class HomeReviewCounts {
  const HomeReviewCounts({required this.due, required this.newToday});

  final int due;
  final int newToday;
}
