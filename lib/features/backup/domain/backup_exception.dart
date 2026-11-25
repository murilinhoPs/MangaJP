/// Thrown when a backup file is rejected **before** any row is written.
class BackupRejectedException implements Exception {
  const BackupRejectedException(this.message);

  final String message;

  @override
  String toString() => 'BackupRejectedException: $message';
}

/// Thrown when restore starts writing and then fails. The Drift transaction
/// has already rolled back; the database is unchanged.
class BackupRestoreFailedException implements Exception {
  const BackupRestoreFailedException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'BackupRestoreFailedException: $message';
}
