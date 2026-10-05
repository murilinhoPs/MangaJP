import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/srs/card_srs_state.dart';
import 'package:manga_jp/features/review/domain/review_session_queue.dart';

void main() {
  test('Again and Hard move the front card to the back', () {
    expect(applySessionRating(['a', 'b', 'c'], ReviewRating.again), [
      'b',
      'c',
      'a',
    ]);
    expect(applySessionRating(['a', 'b', 'c'], ReviewRating.hard), [
      'b',
      'c',
      'a',
    ]);
  });

  test('Good and Easy remove the front card from the session', () {
    expect(applySessionRating(['a', 'b', 'c'], ReviewRating.good), ['b', 'c']);
    expect(applySessionRating(['a', 'b', 'c'], ReviewRating.easy), ['b', 'c']);
  });

  test('Again on the only remaining card keeps it', () {
    expect(applySessionRating(['a'], ReviewRating.again), ['a']);
    expect(applySessionRating(['a'], ReviewRating.good), isEmpty);
  });

  test('requeuesInSession is only Again and Hard', () {
    expect(requeuesInSession(ReviewRating.again), isTrue);
    expect(requeuesInSession(ReviewRating.hard), isTrue);
    expect(requeuesInSession(ReviewRating.good), isFalse);
    expect(requeuesInSession(ReviewRating.easy), isFalse);
  });
}
