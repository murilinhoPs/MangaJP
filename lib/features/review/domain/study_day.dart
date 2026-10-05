/// Study-day used to decide first-answer vs drill and the new-card daily cap.
///
/// Time zone is America/Sao_Paulo (fixed UTC−3; DST ended in 2019). The day
/// rolls at 04:00 local. That boundary names the study-day. The new-card
/// daily cap counts a `neu` card's first non-drill answer against this
/// window.
abstract final class StudyDay {
  static const String timeZoneName = 'America/Sao_Paulo';
  static const int rolloverHour = 4;
  static const Duration utcOffset = Duration(hours: -3);

  /// Instant of the 04:00 America/Sao_Paulo that started [now]'s study-day.
  static DateTime startOf(DateTime now) {
    final utc = now.toUtc();
    final local = utc.add(utcOffset);
    var startLocal = DateTime.utc(
      local.year,
      local.month,
      local.day,
      rolloverHour,
    );
    if (local.hour < rolloverHour) {
      startLocal = startLocal.subtract(const Duration(days: 1));
    }
    return startLocal.subtract(utcOffset);
  }

  /// True when [lastRatedAt] already sits on [now]'s study-day.
  static bool isDrill(DateTime now, DateTime? lastRatedAt) {
    if (lastRatedAt == null) {
      return false;
    }
    return !lastRatedAt.toUtc().isBefore(startOf(now));
  }

  /// Wall-clock in America/Sao_Paulo as a UTC instant (for tests).
  static DateTime instant(
    int year,
    int month,
    int day,
    int hour, [
    int minute = 0,
    int second = 0,
  ]) {
    return DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
    ).subtract(utcOffset);
  }
}
