/// Portuguese date fragments for Home. No deck name — decks are still a stub.
abstract final class HomeDates {
  /// Monday → Sunday initials as in the DS week strip (Seg Ter Qua Qui Sex Sáb Dom).
  static const weekdayLetters = <String>['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  static const _weekdays = <String>[
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  static const _weekdayShort = <String>[
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

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

  /// `Quinta, 1 out` — weekday + day + short month. No year, no deck.
  static String headerSubline(DateTime now) {
    final local = now.toLocal();
    return '${_weekdays[local.weekday - 1]}, ${local.day} ${_months[local.month - 1]}';
  }

  /// `hoje` / `ontem` / short weekday for capture timestamps.
  static String relativeDay(DateTime when, DateTime now) {
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
    return _weekdayShort[localWhen.weekday - 1];
  }
}
