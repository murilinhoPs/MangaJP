import '../../review/domain/study_day.dart';

/// One column of **Ritmo da semana** (Monday → Sunday study-days).
class HomeWeekDay {
  const HomeWeekDay({
    required this.start,
    required this.count,
    required this.isToday,
  });

  final DateTime start;
  final int count;
  final bool isToday;
}

/// Review-log histogram for the current week. Hidden when [hasActivity] is false.
class HomeWeekRhythm {
  const HomeWeekRhythm({required this.days});

  final List<HomeWeekDay> days;

  bool get hasActivity => days.any((day) => day.count > 0);

  int get maxCount {
    var max = 0;
    for (final day in days) {
      if (day.count > max) {
        max = day.count;
      }
    }
    return max;
  }

  static HomeWeekRhythm fromLogs(DateTime now, Iterable<DateTime> ratedAt) {
    final todayStart = StudyDay.startOf(now);
    final todayLocal = todayStart.add(StudyDay.utcOffset);
    final fromMonday = todayLocal.weekday - DateTime.monday;
    final mondayStart = todayStart.subtract(Duration(days: fromMonday));
    final days = <HomeWeekDay>[
      for (var i = 0; i < 7; i++)
        _day(
          start: mondayStart.add(Duration(days: i)),
          todayStart: todayStart,
          ratedAt: ratedAt,
        ),
    ];
    return HomeWeekRhythm(days: days);
  }

  static HomeWeekDay _day({
    required DateTime start,
    required DateTime todayStart,
    required Iterable<DateTime> ratedAt,
  }) {
    final end = start.add(const Duration(days: 1));
    var count = 0;
    for (final stamp in ratedAt) {
      final utc = stamp.toUtc();
      if (!utc.isBefore(start) && utc.isBefore(end)) {
        count++;
      }
    }
    return HomeWeekDay(
      start: start,
      count: count,
      isToday: start.isAtSameMomentAs(todayStart),
    );
  }
}
