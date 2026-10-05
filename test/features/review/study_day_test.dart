import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/review/domain/study_day.dart';

void main() {
  test('03:59 America/Sao_Paulo is still the previous study-day', () {
    final at0359 = StudyDay.instant(2026, 10, 5, 3, 59);
    expect(at0359, DateTime.utc(2026, 10, 5, 6, 59));
    expect(StudyDay.startOf(at0359), StudyDay.instant(2026, 10, 4, 4));
    expect(StudyDay.startOf(at0359), DateTime.utc(2026, 10, 4, 7));
  });

  test('04:00 America/Sao_Paulo starts the new study-day', () {
    final at0400 = StudyDay.instant(2026, 10, 5, 4);
    expect(at0400, DateTime.utc(2026, 10, 5, 7));
    expect(StudyDay.startOf(at0400), at0400);
  });

  test('isDrill is false until a log exists on this study-day', () {
    final at0359 = StudyDay.instant(2026, 10, 5, 3, 59);
    final at0400 = StudyDay.instant(2026, 10, 5, 4);
    final previousAfternoon = StudyDay.instant(2026, 10, 4, 12);

    expect(StudyDay.isDrill(at0359, null), isFalse);
    expect(StudyDay.isDrill(at0359, previousAfternoon), isTrue);
    expect(StudyDay.isDrill(at0400, previousAfternoon), isFalse);
    expect(StudyDay.isDrill(at0400, at0359), isFalse);
    expect(StudyDay.isDrill(at0400, at0400), isTrue);
  });

  test('new year 03:59 rolls back to 31 Dec 04:00', () {
    final at0359 = StudyDay.instant(2026, 1, 1, 3, 59);
    expect(StudyDay.startOf(at0359), StudyDay.instant(2025, 12, 31, 4));
  });
}
