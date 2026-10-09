import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/home/domain/home_week_rhythm.dart';
import 'package:manga_jp/features/review/domain/study_day.dart';

void main() {
  test('Monday 03:59 still belongs to the previous week', () {
    final now = StudyDay.instant(2026, 10, 5, 3, 59);
    final week = HomeWeekRhythm.fromLogs(now, [
      StudyDay.instant(2026, 9, 28, 12),
      StudyDay.instant(2026, 10, 4, 12),
    ]);

    expect(week.days, hasLength(7));
    expect(week.days.first.start, StudyDay.weekStartOf(now));
    expect(week.days.first.start, StudyDay.instant(2026, 9, 28, 4));
    expect(week.days.first.count, 1);
    expect(week.days.last.isToday, isTrue);
    expect(week.days.last.count, 1);
    expect(week.hasActivity, isTrue);
  });

  test('Monday 04:00 starts a new week and drops Sunday night', () {
    final now = StudyDay.instant(2026, 10, 5, 4);
    final week = HomeWeekRhythm.fromLogs(now, [
      StudyDay.instant(2026, 10, 4, 23),
      StudyDay.instant(2026, 10, 5, 10),
    ]);

    expect(week.days.first.start, StudyDay.instant(2026, 10, 5, 4));
    expect(week.days.first.isToday, isTrue);
    expect(week.days.first.count, 1);
    expect(week.days.last.count, 0);
    expect(week.days.where((day) => day.count > 0), hasLength(1));
  });

  test('Sunday night stays in the current week', () {
    final now = StudyDay.instant(2026, 10, 11, 23, 30);
    final week = HomeWeekRhythm.fromLogs(now, [
      StudyDay.instant(2026, 10, 5, 8),
      StudyDay.instant(2026, 10, 11, 22),
    ]);

    expect(week.days.first.start, StudyDay.instant(2026, 10, 5, 4));
    expect(week.days.first.count, 1);
    expect(week.days.last.isToday, isTrue);
    expect(week.days.last.count, 1);
  });

  test('a log from the previous week does not count', () {
    final now = StudyDay.instant(2026, 10, 7, 12);
    final week = HomeWeekRhythm.fromLogs(now, [
      StudyDay.instant(2026, 10, 4, 18),
      StudyDay.instant(2026, 10, 6, 9),
    ]);

    expect(week.days[1].count, 1);
    expect(
      week.days.every((day) => day.count == 0 || day.start.day == 6),
      isTrue,
    );
    expect(week.maxCount, 1);
  });

  test('no logs means no activity', () {
    final week = HomeWeekRhythm.fromLogs(
      StudyDay.instant(2026, 10, 7, 12),
      const [],
    );
    expect(week.hasActivity, isFalse);
    expect(week.maxCount, 0);
    expect(week.days.where((day) => day.isToday), hasLength(1));
  });
}
