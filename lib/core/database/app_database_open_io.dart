import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
/// under the new id. If XDG cannot be resolved, recovers from
/// `getApplicationSupportDirectory()` as the new-id folder (sibling legacy
/// id is still migrated) instead of opening that folder blindly.
/// Android and iOS use Drift’s default documents directory.
Future<Directory> linuxDatabaseDirectory() async {
  try {
    return _ensureDirectory(resolveLinuxAppSupportDirectory());
  } on Object catch (error) {
    try {
      final support = await getApplicationSupportDirectory();
      return _ensureDirectory(
        resolveLinuxAppSupportDirectoryFromPathProvider(
          support,
          resolveError: error,
        ),
      );
    } on Object {
      try {
        return await getApplicationDocumentsDirectory();
      } on Object {
        return Directory.systemTemp;
      }
    }
  }
}

Directory _ensureDirectory(Directory dir) {
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}
