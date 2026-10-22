import 'dart:io';

/// Current Linux GApplication / `APPLICATION_ID`.
const kLinuxApplicationId = 'dev.murilinhops.mangajp';

/// Linux `APPLICATION_ID` used before the #62 rename.
const kLegacyLinuxApplicationId = 'dev.murilinhops.manga_jp';

/// Drift file name (`driftDatabase(name: 'mangajp')`).
const kMangaJpDatabaseFileName = 'mangajp.sqlite';

/// Optional sink for migration logs (tests). Stderr always gets a copy.
void Function(String message)? linuxAppSupportLog;

/// Outcome of [migrateLinuxAppSupportDirectory].
enum LinuxAppSupportMigrationResult {
  /// [oldDir] is missing — nothing to move. First launch or already moved.
  skippedOldMissing,

  /// [newDir] already has [kMangaJpDatabaseFileName] — do not overwrite.
  skippedNewHasData,

  /// Contents copied from [oldDir] into [newDir].
  migrated,

  /// Copy failed. [oldDir] is unchanged; caller must keep using it.
  failed,
}

/// Copies Linux app-support files from [oldDir] to [newDir] once.
///
/// Used when `APPLICATION_ID` changes: `path_provider_linux` 2.2.2
/// (`getApplicationSupportPath`, lines 47–62) joins `$XDG_DATA_HOME` (or
/// `~/.local/share`) with `g_application_get_application_id`, so Drift
/// (`mangajp.sqlite`) and JMdict would otherwise open an empty folder.
///
/// [newDir] is treated as empty (retry allowed) unless it already contains
/// `mangajp.sqlite`. That is the simplest safe rule: Drift always creates
/// that file once it opens the new folder, so a failed copy never produces
/// it if the caller keeps using [oldDir] ([resolveLinuxAppSupportDirectory]).
/// An empty directory, leftover files, or a half-written `.migrating` sibling
/// do not count as data.
///
/// Idempotent. Never deletes [oldDir]. Never overwrites a real new database.
/// Copy goes through a sibling `.migrating` staging directory; a leftover
/// staging tree is deleted at the start of each attempt.
LinuxAppSupportMigrationResult migrateLinuxAppSupportDirectory({
  required Directory oldDir,
  required Directory newDir,
}) {
  final oldPath = oldDir.absolute.path;
  final newPath = newDir.absolute.path;
  if (oldPath == newPath) {
    return LinuxAppSupportMigrationResult.skippedNewHasData;
  }
  if (!oldDir.existsSync()) {
    return LinuxAppSupportMigrationResult.skippedOldMissing;
  }
  if (_hasMangaJpDatabase(newDir)) {
    return LinuxAppSupportMigrationResult.skippedNewHasData;
  }

  final staging = Directory('$newPath.migrating');
  try {
    _deleteStaging(staging);
    _copyDirectory(oldDir, staging);
    if (newDir.existsSync()) {
      newDir.deleteSync(recursive: true);
    }
    staging.renameSync(newPath);
    return LinuxAppSupportMigrationResult.migrated;
  } on Object catch (error) {
    _log(
      'MangaJP: Linux app-support copy failed; using legacy directory '
      '$oldPath (new folder has no $kMangaJpDatabaseFileName, so the next '
      'launch retries). Error: $error',
    );
    return LinuxAppSupportMigrationResult.failed;
  }
}

/// Directory Drift and JMdict must use on Linux after attempting migration.
///
/// On [LinuxAppSupportMigrationResult.failed], returns [oldDir] so this
/// process does not create an empty `mangajp.sqlite` under the new id.
Directory resolveLinuxAppSupportDirectoryFrom({
  required Directory oldDir,
  required Directory newDir,
}) {
  final result = migrateLinuxAppSupportDirectory(
    oldDir: oldDir,
    newDir: newDir,
  );
  switch (result) {
    case LinuxAppSupportMigrationResult.failed:
      return oldDir;
    case LinuxAppSupportMigrationResult.migrated:
    case LinuxAppSupportMigrationResult.skippedNewHasData:
    case LinuxAppSupportMigrationResult.skippedOldMissing:
      return newDir;
  }
}

/// Linux-only: `$XDG_DATA_HOME/<legacy id>` → `<new id>` if needed.
///
/// Returns the directory Drift/JMdict should open. On copy failure this
/// process keeps the legacy folder; the next launch retries if the new
/// folder still has no `mangajp.sqlite` (leftover `.migrating` is deleted
/// at the start of that attempt).
Directory resolveLinuxAppSupportDirectory() {
  final cached = _resolvedThisProcess;
  if (cached != null) {
    return cached;
  }
  final dataHome = linuxXdgDataHome();
  final resolved = resolveLinuxAppSupportDirectoryFrom(
    oldDir: Directory('${dataHome.path}/$kLegacyLinuxApplicationId'),
    newDir: Directory('${dataHome.path}/$kLinuxApplicationId'),
  );
  _resolvedThisProcess = resolved;
  return resolved;
}

/// Linux-only wrapper used from `main`.
void maybeMigrateLinuxAppSupport() {
  if (!Platform.isLinux) {
    return;
  }
  try {
    resolveLinuxAppSupportDirectory();
  } on Object catch (error) {
    _log('MangaJP: Linux app-support resolve failed: $error');
  }
}

/// Drops the per-process cache so tests can run more than one attempt.
void resetLinuxAppSupportDirectoryCache() {
  _resolvedThisProcess = null;
}

/// Same base as `xdg_directories` `dataHome` / `path_provider_linux` 2.2.2.
Directory linuxXdgDataHome() {
  final xdg = Platform.environment['XDG_DATA_HOME'];
  if (xdg != null && xdg.isNotEmpty) {
    return Directory(xdg);
  }
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME is not set');
  }
  return Directory('$home/.local/share');
}

Directory? _resolvedThisProcess;

bool _hasMangaJpDatabase(Directory dir) {
  return File('${dir.path}${Platform.pathSeparator}$kMangaJpDatabaseFileName')
      .existsSync();
}

void _deleteStaging(Directory staging) {
  final asFile = File(staging.path);
  if (asFile.existsSync() &&
      asFile.statSync().type == FileSystemEntityType.file) {
    asFile.deleteSync();
    return;
  }
  if (staging.existsSync()) {
    staging.deleteSync(recursive: true);
  }
}

void _copyDirectory(Directory source, Directory dest) {
  dest.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final targetPath =
        '${dest.path}${Platform.pathSeparator}${_basename(entity.path)}';
    if (entity is Directory) {
      _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    }
  }
}

String _basename(String path) {
  final sep = Platform.pathSeparator;
  var trimmed = path;
  while (trimmed.endsWith(sep) && trimmed.length > sep.length) {
    trimmed = trimmed.substring(0, trimmed.length - sep.length);
  }
  final index = trimmed.lastIndexOf(sep);
  return index < 0 ? trimmed : trimmed.substring(index + sep.length);
}

void _log(String message) {
  linuxAppSupportLog?.call(message);
  stderr.writeln(message);
}
