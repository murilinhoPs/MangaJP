import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/review/domain/new_per_day.dart';

void main() {
  test('new_per_day is the constant 15', () {
    expect(NewPerDay.limit, 15);
  });

  test('keeps every non-neu card and at most 15 neu in order', () {
    final due = [
      (id: 'learn', isNew: false),
      (id: 'relearn', isNew: false),
      (id: 'review', isNew: false),
      for (var i = 0; i < 20; i++) (id: 'new-$i', isNew: true),
    ];

    final out = applyNewPerDayLimit(
      due,
      introduced: 0,
      isNew: (card) => card.isNew,
    );

    expect(
      [for (final card in out) card.id],
      ['learn', 'relearn', 'review', for (var i = 0; i < 15; i++) 'new-$i'],
    );
  });

  test('introduced today reduces remaining neu slots', () {
    final due = [
      (id: 'learn', isNew: false),
      for (var i = 0; i < 8; i++) (id: 'new-$i', isNew: true),
    ];

    final out = applyNewPerDayLimit(
      due,
      introduced: 10,
      isNew: (card) => card.isNew,
    );

    expect(
      [for (final card in out) card.id],
      ['learn', 'new-0', 'new-1', 'new-2', 'new-3', 'new-4'],
    );
  });

  test('no neu enter once 15 have been introduced', () {
    final due = [
      (id: 'learn', isNew: false),
      (id: 'review', isNew: false),
      (id: 'new-0', isNew: true),
      (id: 'new-1', isNew: true),
    ];

    final out = applyNewPerDayLimit(
      due,
      introduced: 15,
      isNew: (card) => card.isNew,
    );

    expect([for (final card in out) card.id], ['learn', 'review']);
  });

  test('introduced above the cap still keeps non-neu cards', () {
    final out = applyNewPerDayLimit(
      [(id: 'learn', isNew: false), (id: 'new-0', isNew: true)],
      introduced: 20,
      isNew: (card) => card.isNew,
    );
    expect([for (final card in out) card.id], ['learn']);
  });
}
