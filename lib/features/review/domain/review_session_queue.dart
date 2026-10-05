import 'review_rating.dart';

/// Again and Hard stay in the current `/review` session, at the back.
/// Good and Easy leave and do not return in this session.
bool requeuesInSession(ReviewRating rating) =>
    rating == ReviewRating.again || rating == ReviewRating.hard;

/// Next in-memory session order after answering the front card.
List<T> applySessionRating<T>(List<T> remaining, ReviewRating rating) {
  if (remaining.isEmpty) {
    return remaining;
  }
  final rest = remaining.sublist(1);
  if (requeuesInSession(rating)) {
    return [...rest, remaining.first];
  }
  return rest;
}
