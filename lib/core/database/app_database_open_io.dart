import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'linux_app_support_migration.dart';

/// Opens the persisted Drift DB on native platforms.
///
/// Android and iOS keep Drift’s default documents directory. Linux uses
/// [linuxDatabaseDirectory] because XDG Documents can be missing.
QueryExecutor openMangaJpDatabase() {
  if (!Platform.isLinux) {
    return driftDatabase(name: 'mangajp');
  }
  return driftDatabase(
    name: 'mangajp',
    native: const DriftNativeOptions(databaseDirectory: linuxDatabaseDirectory),
  );
}

/// Linux-only directory for `mangajp.sqlite`.
///
/// Migrates the legacy APPLICATION_ID folder when needed. On copy failure
/// this returns the legacy folder so Drift does not create an empty database
/// under the new id.
///
/// When HOME/XDG are unset, resolves home via `getpwuid(getuid())->pw_dir`
/// and uses `$home/.local/share`. If that also fails, throws — never
/// [Directory.systemTemp] (that opened an empty `/tmp/mangajp.sqlite`).
/// Android and iOS use Drift’s default documents directory.
Future<Directory> linuxDatabaseDirectory({
  Map<String, String>? environment,
  LinuxPasswdHomeLookup? passwdHome,
}) async {
  final dir = resolveLinuxAppSupportDirectory(
    environment: environment,
    passwdHome: passwdHome,
  );
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}
