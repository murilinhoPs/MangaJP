/// Why a vocab card is out of `/review`. Null on the row means not suspended.
///
/// [user] is F23 (Deck). [known] / [ignored] are Caderno (F12 / AC-known).
enum SuspendReason {
  user,
  known,
  ignored;

  /// Value stored in `cards.suspend_reason`.
  String get dbValue => name;

  static SuspendReason? fromDb(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final reason in SuspendReason.values) {
      if (reason.name == value) {
        return reason;
      }
    }
    return null;
  }
}
