/// Portuguese dates for the `/pages` history (hoje / ontem / `d MMM`).
abstract final class PageListDate {
  static const _months = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static String format(DateTime when, DateTime now) {
    final localWhen = when.toLocal();
    final localNow = now.toLocal();
    final a = DateTime(localWhen.year, localWhen.month, localWhen.day);
    final b = DateTime(localNow.year, localNow.month, localNow.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) {
      return 'hoje';
    }
    if (diff == 1) {
      return 'ontem';
    }
    final month = _months[localWhen.month - 1];
    if (localWhen.year != localNow.year) {
      return '${localWhen.day} $month ${localWhen.year}';
    }
    return '${localWhen.day} $month';
  }
}
