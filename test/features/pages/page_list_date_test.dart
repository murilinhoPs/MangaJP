import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/pages/domain/page_list_date.dart';

void main() {
  test('hoje and ontem are calendar-day relative to now', () {
    final now = DateTime(2026, 11, 3, 18);
    expect(PageListDate.format(DateTime(2026, 11, 3, 9), now), 'hoje');
    expect(PageListDate.format(DateTime(2026, 11, 2, 23), now), 'ontem');
  });

  test('older days use d MMM without word_state badges', () {
    final now = DateTime(2026, 11, 3);
    expect(PageListDate.format(DateTime(2026, 10, 5), now), '5 out');
    expect(PageListDate.format(DateTime(2026, 1, 15), now), '15 jan');
  });

  test('other years include yyyy', () {
    final now = DateTime(2026, 11, 3);
    expect(PageListDate.format(DateTime(2025, 12, 31), now), '31 dez 2025');
  });
}
