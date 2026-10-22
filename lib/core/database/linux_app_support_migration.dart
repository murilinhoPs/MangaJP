import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

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

  /// [newDir] already has a real [kMangaJpDatabaseFileName] — do not overwrite.
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
/// a [kMangaJpDatabaseFileName] with user data (or a sqlite we cannot
/// inspect). A leftover empty sqlite from a failed #66 copy is replaced
/// only when [oldDir] has user data. An empty directory, leftover files
/// such as JMdict, or a half-written `.migrating` sibling do not count as
/// data.
///
/// Idempotent. Never deletes [oldDir]. Never overwrites a sqlite that
/// already has user data. Copy goes through a sibling `.migrating`
/// staging directory; a leftover staging tree is deleted at the start of
/// each attempt. [newDir] is never wiped — only staging and empty Drift
/// sidecars created by a previous attempt are removed.
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
  if (_newDatabaseBlocksMigration(newDir, oldDir)) {
    return LinuxAppSupportMigrationResult.skippedNewHasData;
  }

  final staging = Directory('$newPath.migrating');
  try {
    _deleteStaging(staging);
    _copyDirectory(oldDir, staging);
    _installStaging(staging: staging, newDir: newDir);
    return LinuxAppSupportMigrationResult.migrated;
  } on Object catch (error) {
    _log(
      'MangaJP: Linux app-support copy failed; using legacy directory '
      '$oldPath (new folder has no user $kMangaJpDatabaseFileName, so the '
      'next launch retries). Error: $error',
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
/// folder still has no user `mangajp.sqlite` (leftover `.migrating` is
/// deleted at the start of that attempt).
///
/// Throws if [linuxXdgDataHome] cannot be resolved. Callers must not fall
/// back to the new APPLICATION_ID folder in that case — that would open
/// an empty Drift database. Use
/// [resolveLinuxAppSupportDirectoryFromPathProvider] instead.
Directory resolveLinuxAppSupportDirectory({Map<String, String>? environment}) {
  final cached = _resolvedThisProcess;
  if (cached != null) {
    return cached;
  }
  try {
    final dataHome = linuxXdgDataHome(environment: environment);
    final resolved = resolveLinuxAppSupportDirectoryFrom(
      oldDir: Directory('${dataHome.path}/$kLegacyLinuxApplicationId'),
      newDir: Directory('${dataHome.path}/$kLinuxApplicationId'),
    );
    _resolvedThisProcess = resolved;
    return resolved;
  } on Object catch (error) {
    _log(
      'MangaJP: Linux app-support cannot resolve XDG data home (HOME and '
      'XDG_DATA_HOME unset or empty); not creating an empty database in '
      'the new folder. Error: $error',
    );
    rethrow;
  }
}

/// Recovers when [resolveLinuxAppSupportDirectory] cannot read XDG.
///
/// [pathProviderSupportDir] is `getApplicationSupportDirectory()` — the
/// new APPLICATION_ID folder. The legacy folder is the sibling named
/// [kLegacyLinuxApplicationId]. This keeps Drift on the old sqlite
/// instead of creating an empty one under the new id.
Directory resolveLinuxAppSupportDirectoryFromPathProvider(
  Directory pathProviderSupportDir, {
  Object? resolveError,
}) {
  final cached = _resolvedThisProcess;
  if (cached != null) {
    return cached;
  }
  final newDir = Directory(pathProviderSupportDir.absolute.path);
  if (resolveError != null) {
    _log(
      'MangaJP: Linux app-support resolve failed; recovering via '
      'application support directory ${newDir.path} so the legacy sibling '
      'is not skipped. Error: $resolveError',
    );
  }
  final resolved = resolveLinuxAppSupportDirectoryFrom(
    oldDir: Directory('${newDir.parent.path}/$kLegacyLinuxApplicationId'),
    newDir: newDir,
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
Directory linuxXdgDataHome({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final xdg = env['XDG_DATA_HOME'];
  if (xdg != null && xdg.isNotEmpty) {
    return Directory(xdg);
  }
  final home = env['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME is not set');
  }
  return Directory('$home/.local/share');
}

Directory? _resolvedThisProcess;

File _databaseFile(Directory dir) {
  return File('${dir.path}${Platform.pathSeparator}$kMangaJpDatabaseFileName');
}

/// User tables. `app_meta` is seeded on an empty Drift open, so it does
/// not count as user data.
const _kUserDataTables = <String>[
  'words',
  'pages',
  'crops',
  'cards',
  'word_states',
  'crop_words',
  'card_srs',
  'review_logs',
];

enum _SqliteProbe { empty, hasUserData, unknown }

bool _newDatabaseBlocksMigration(Directory newDir, Directory oldDir) {
  final newFile = _databaseFile(newDir);
  if (!newFile.existsSync()) {
    return false;
  }
  switch (_probeMangaJpDatabase(newFile)) {
    case _SqliteProbe.hasUserData:
    case _SqliteProbe.unknown:
      return true;
    case _SqliteProbe.empty:
      final oldFile = _databaseFile(oldDir);
      if (!oldFile.existsSync()) {
        return true;
      }
      if (_probeMangaJpDatabase(oldFile) == _SqliteProbe.hasUserData) {
        _log(
          'MangaJP: Linux app-support found empty $kMangaJpDatabaseFileName '
          'in ${newDir.absolute.path} while ${oldDir.absolute.path} has user '
          'data; migrating.',
        );
        return false;
      }
      return true;
  }
}

_SqliteProbe _probeMangaJpDatabase(File file) {
  try {
    if (file.statSync().type != FileSystemEntityType.file) {
      return _SqliteProbe.unknown;
    }
    if (file.lengthSync() == 0) {
      return _SqliteProbe.empty;
    }
  } on Object {
    return _SqliteProbe.unknown;
  }
  Database? db;
  try {
    db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    for (final table in _kUserDataTables) {
      final found = db.select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [table],
      );
      if (found.isEmpty) {
        continue;
      }
      final rows = db.select('SELECT 1 FROM "$table" LIMIT 1');
      if (rows.isNotEmpty) {
        return _SqliteProbe.hasUserData;
      }
    }
    return _SqliteProbe.empty;
  } on Object {
    return _SqliteProbe.unknown;
  } finally {
    db?.close();
  }
}

void _installStaging({required Directory staging, required Directory newDir}) {
  if (!newDir.existsSync()) {
    staging.renameSync(newDir.path);
    return;
  }
  if (newDir.listSync(followLinks: false).isEmpty) {
    newDir.deleteSync();
    staging.renameSync(newDir.path);
    return;
  }
  _removeMangaJpDatabaseSidecars(newDir);
  _mergeCopiedFiles(staging, newDir);
  _deleteStaging(staging);
}

void _removeMangaJpDatabaseSidecars(Directory dir) {
  const suffixes = <String>['', '-wal', '-shm', '-journal'];
  for (final suffix in suffixes) {
    final file = File(
      '${dir.path}${Platform.pathSeparator}$kMangaJpDatabaseFileName$suffix',
    );
    if (file.existsSync() &&
        file.statSync().type == FileSystemEntityType.file) {
      file.deleteSync();
    }
  }
}

void _mergeCopiedFiles(Directory source, Directory dest) {
  dest.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = _basename(entity.path);
    final targetPath = '${dest.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      _mergeCopiedFiles(entity, Directory(targetPath));
    } else if (entity is File) {
      final target = File(targetPath);
      if (target.existsSync() && !_isMangaJpDatabaseSidecar(name)) {
        continue;
      }
      entity.copySync(targetPath);
    }
  }
}

bool _isMangaJpDatabaseSidecar(String name) {
  return name == kMangaJpDatabaseFileName ||
      name.startsWith('$kMangaJpDatabaseFileName-');
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
