import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
    native: const DriftNativeOptions(
      databaseDirectory: linuxDatabaseDirectory,
    ),
  );
}

/// Linux-only directory for `mangajp.sqlite`.
///
/// Android and iOS use Drift’s default (`getApplicationDocumentsDirectory()`).
/// On Linux that call can fail when XDG Documents is missing, so we try
/// app-support, then documents, then system temp.
Future<Directory> linuxDatabaseDirectory() async {
  try {
    return await getApplicationSupportDirectory();
  } catch (_) {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }
}
