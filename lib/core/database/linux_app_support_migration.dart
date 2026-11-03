import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

/// Current Linux GApplication / `APPLICATION_ID`.
const kLinuxApplicationId = 'dev.murilinhops.mangajp';

/// Linux `APPLICATION_ID` used before the #62 rename.
const kLegacyLinuxApplicationId = 'dev.murilinhops.manga_jp';

/// Drift file name (`driftDatabase(name: 'mangajp')`).
const kMangaJpDatabaseFileName = 'mangajp.sqlite';

/// Optional sink for migration logs (tests). Stderr always gets a copy.
void Function(String message)? linuxAppSupportLog;

/// Lookup for `getpwuid(getuid())->pw_dir`. Tests inject a fake.
typedef LinuxPasswdHomeLookup = String? Function();

/// QA/test: pretend `getpwuid` failed. Use with `env -u HOME -u XDG_DATA_HOME`
/// and `--dart-define=MANGAJP_FORCE_GETPWUID_FAILURE=true`.
/// Ignored in release ([kReleaseMode]); QA uses `--profile`.
const kForceLinuxGetpwuidFailure = bool.fromEnvironment(
  'MANGAJP_FORCE_GETPWUID_FAILURE',
);

/// Whether [kForceLinuxGetpwuidFailure] is honored. Release always false.
@visibleForTesting
bool resolveLinuxForceGetpwuidFailure({
  required bool defined,
  required bool release,
}) {
  return !release && defined;
}

/// Test hook: skip `VACUUM INTO` and `wal_checkpoint` so
/// [_foldWalIntoStagedSqlite] throws and migrate returns [failed].
@visibleForTesting
bool linuxAppSupportForceWalFoldFailure = false;

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
/// each attempt. [newDir] is never wiped — leftover files such as JMdict
/// stay. When [newDir] already has files, non-sqlite contents are merged
/// first; WAL is folded (`VACUUM INTO` / `wal_checkpoint(TRUNCATE)`) so
/// one sqlite file is written to a sibling `.incoming` and renamed into
/// place last. `-wal`/`-shm` are never copied after that rename.
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
/// When HOME/XDG are unset, [linuxXdgDataHome] uses
/// `getpwuid(getuid())->pw_dir`. If that also fails this throws — callers
/// must not fall back to temp or documents (that would open an empty DB).
///
/// [environment] and [passwdHome] only apply on the first call in this
/// process; later calls return the cached directory and ignore them.
/// Tests must [resetLinuxAppSupportDirectoryCache] between attempts.
Directory resolveLinuxAppSupportDirectory({
  Map<String, String>? environment,
  LinuxPasswdHomeLookup? passwdHome,
}) {
  final cached = _resolvedThisProcess;
  if (cached != null) {
    return cached;
  }
  try {
    final dataHome = linuxXdgDataHome(
      environment: environment,
      passwdHome: passwdHome,
    );
    final resolved = resolveLinuxAppSupportDirectoryFrom(
      oldDir: Directory('${dataHome.path}/$kLegacyLinuxApplicationId'),
      newDir: Directory('${dataHome.path}/$kLinuxApplicationId'),
    );
    _resolvedThisProcess = resolved;
    return resolved;
  } on Object catch (error) {
    _log(
      'MangaJP: Linux app-support cannot resolve a data directory. '
      'Not creating an empty database in temp. Error: $error',
    );
    rethrow;
  }
}

/// Linux-only resolve used from `main`.
///
/// Returns the [StateError] when HOME/XDG and getpwuid all fail so the
/// caller can show an error screen instead of a crash. Other errors are
/// logged and swallowed (next launch retries).
Object? linuxAppSupportStartupError({
  Map<String, String>? environment,
  LinuxPasswdHomeLookup? passwdHome,
}) {
  if (!Platform.isLinux) {
    return null;
  }
  try {
    resolveLinuxAppSupportDirectory(
      environment: environment,
      passwdHome: passwdHome,
    );
    return null;
  } on StateError catch (error) {
    return error;
  } on Object catch (error) {
    _log('MangaJP: Linux app-support resolve failed: $error');
    return null;
  }
}

/// Drops the per-process cache so tests can run more than one attempt.
void resetLinuxAppSupportDirectoryCache() {
  _resolvedThisProcess = null;
}

/// Same base as `xdg_directories` `dataHome` / `path_provider_linux` 2.2.2.
///
/// When `HOME` / `XDG_DATA_HOME` are empty, uses [passwdHome] or
/// [linuxHomeFromGetpwuid] (`getpwuid(getuid())->pw_dir`, like glib).
/// Never reads `USER`. Never falls back to temp.
Directory linuxXdgDataHome({
  Map<String, String>? environment,
  LinuxPasswdHomeLookup? passwdHome,
}) {
  final env = environment ?? Platform.environment;
  final xdg = env['XDG_DATA_HOME'];
  if (xdg != null && xdg.isNotEmpty) {
    return Directory(xdg);
  }
  final home = env['HOME'];
  if (home != null && home.isNotEmpty) {
    return Directory('$home/.local/share');
  }
  final lookup = passwdHome ?? linuxHomeFromGetpwuid;
  final fromPasswd = lookup();
  if (fromPasswd != null &&
      fromPasswd.startsWith('/') &&
      fromPasswd.length > 1) {
    _log(
      'MangaJP: HOME and XDG_DATA_HOME unset; using passwd home '
      '$fromPasswd for the data directory.',
    );
    return Directory('$fromPasswd/.local/share');
  }
  throw StateError(
    'MangaJP: cannot resolve Linux data directory: HOME and '
    'XDG_DATA_HOME are unset and getpwuid(getuid())->pw_dir failed. '
    'Not opening a database in temp.',
  );
}

/// `getpwuid(getuid())->pw_dir` via libc. Null when not Linux or on error.
String? linuxHomeFromGetpwuid() {
  if (resolveLinuxForceGetpwuidFailure(
        defined: kForceLinuxGetpwuidFailure,
        release: kReleaseMode,
      ) ||
      !Platform.isLinux) {
    return null;
  }
  try {
    DynamicLibrary libc;
    try {
      libc = DynamicLibrary.open('libc.so.6');
    } on Object {
      libc = DynamicLibrary.process();
    }
    final getuid = libc.lookupFunction<_GetuidNative, _GetuidDart>('getuid');
    final getpwuid = libc.lookupFunction<_GetpwuidNative, _GetpwuidDart>(
      'getpwuid',
    );
    final pwd = getpwuid(getuid());
    if (pwd == nullptr) {
      return null;
    }
    final dir = _cstring(pwd.ref.pwDir);
    if (dir == null || !dir.startsWith('/') || dir.length <= 1) {
      return null;
    }
    return dir;
  } on Object {
    return null;
  }
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
  // readOnly can fail when a -wal exists without a writable -shm.
  // immutable=1 ignores the WAL (SQLite 3.46), so an empty-looking main
  // file would look like [empty] and overwrite user data. Copy sqlite +
  // -wal to a temp dir and open that instead (SQLite recreates -shm).
  final direct = _probeOpen(file.path);
  if (direct != _SqliteProbe.unknown) {
    return direct;
  }
  return _probeViaWalCopy(file);
}

/// Unlocked copy of sqlite + `-wal`/`-journal` into a temp dir.
///
/// The copy does **not** lock against a live writer. It is only a probe
/// snapshot so `mode=ro` failures (unreadable `-shm`) do not look like
/// [empty]. SQLite recreates `-shm` in the temp dir. Never use this copy
/// as a destination for user data.
_SqliteProbe _probeViaWalCopy(File file) {
  Directory? tmp;
  try {
    tmp = Directory.systemTemp.createTempSync('mangajp-probe-');
    final dest = File(
      '${tmp.path}${Platform.pathSeparator}$kMangaJpDatabaseFileName',
    );
    file.copySync(dest.path);
    for (final suffix in const ['-wal', '-journal']) {
      final side = File('${file.path}$suffix');
      if (!side.existsSync()) {
        continue;
      }
      try {
        side.copySync('${dest.path}$suffix');
      } on Object {
        // Sidecar exists but cannot be copied — do not treat the
        // main file as empty (WAL-only data would be lost).
        return _SqliteProbe.unknown;
      }
    }
    return _probeOpen(dest.path, mode: OpenMode.readWrite);
  } on Object {
    return _SqliteProbe.unknown;
  } finally {
    try {
      tmp?.deleteSync(recursive: true);
    } on Object {
      // Leave the temp dir; next boot's /tmp cleanup will get it.
    }
  }
}

_SqliteProbe _probeOpen(String path, {OpenMode mode = OpenMode.readOnly}) {
  Database? db;
  try {
    db = sqlite3.open(path, mode: mode);
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

const _kIncomingDatabaseFileName = '$kMangaJpDatabaseFileName.incoming';

const _kSqliteSidecarSuffixes = <String>['-wal', '-shm', '-journal'];

void _installStaging({required Directory staging, required Directory newDir}) {
  _deleteIncoming(newDir);
  _foldWalIntoStagedSqlite(staging);
  if (!newDir.existsSync()) {
    staging.renameSync(newDir.path);
    return;
  }
  if (newDir.listSync(followLinks: false).isEmpty) {
    newDir.deleteSync();
    staging.renameSync(newDir.path);
    return;
  }
  _mergeNonSqliteFiles(staging, newDir);
  _installSqliteAtomically(staging, newDir);
  _deleteStaging(staging);
}

void _mergeNonSqliteFiles(Directory source, Directory dest) {
  dest.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = _basename(entity.path);
    if (_isMangaJpDatabaseSidecar(name)) {
      continue;
    }
    final targetPath = '${dest.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      _mergeNonSqliteFiles(entity, Directory(targetPath));
    } else if (entity is File) {
      final target = File(targetPath);
      if (target.existsSync()) {
        continue;
      }
      entity.copySync(targetPath);
    }
  }
}

void _installSqliteAtomically(Directory staging, Directory newDir) {
  final staged = File(
    '${staging.path}${Platform.pathSeparator}$kMangaJpDatabaseFileName',
  );
  if (!staged.existsSync()) {
    return;
  }
  final incoming = File(
    '${newDir.path}${Platform.pathSeparator}$_kIncomingDatabaseFileName',
  );
  if (incoming.existsSync()) {
    incoming.deleteSync();
  }
  if (!_vacuumSqliteInto(staged, incoming)) {
    if (_hasMangaJpSidecars(staging)) {
      throw Exception(
        'MangaJP: could not fold WAL/SHM into $kMangaJpDatabaseFileName; '
        'keeping the legacy directory.',
      );
    }
    staged.copySync(incoming.path);
  }
  _removeSqliteWalSidecars(newDir);
  final destSqlite = _databaseFile(newDir);
  if (destSqlite.existsSync() &&
      destSqlite.statSync().type == FileSystemEntityType.file) {
    destSqlite.deleteSync();
  }
  incoming.renameSync(destSqlite.path);
}

/// Checkpoint / `VACUUM INTO` so dest gets one sqlite file, never a
/// post-rename `-wal`/`-shm` copy (those can be lost mid-crash).
void _foldWalIntoStagedSqlite(Directory staging) {
  final staged = _databaseFile(staging);
  if (!staged.existsSync()) {
    return;
  }
  var hasSidecar = false;
  for (final suffix in _kSqliteSidecarSuffixes) {
    if (File('${staged.path}$suffix').existsSync()) {
      hasSidecar = true;
      break;
    }
  }
  if (!hasSidecar) {
    return;
  }
  final vacuumed = File('${staged.path}.vacuum');
  if (vacuumed.existsSync()) {
    vacuumed.deleteSync();
  }
  if (_vacuumSqliteInto(staged, vacuumed)) {
    staged.deleteSync();
    vacuumed.renameSync(staged.path);
    _removeSqliteWalSidecars(staging);
  } else {
    if (vacuumed.existsSync()) {
      vacuumed.deleteSync();
    }
    if (_checkpointWal(staged)) {
      _removeSqliteWalSidecars(staging);
    }
  }
  if (_hasMangaJpSidecars(staging)) {
    throw Exception(
      'MangaJP: could not fold WAL/SHM into $kMangaJpDatabaseFileName; '
      'keeping the legacy directory.',
    );
  }
}

bool _hasMangaJpSidecars(Directory dir) {
  final sqlite = _databaseFile(dir);
  for (final suffix in _kSqliteSidecarSuffixes) {
    if (File('${sqlite.path}$suffix').existsSync()) {
      return true;
    }
  }
  return false;
}

bool _vacuumSqliteInto(File source, File dest) {
  if (linuxAppSupportForceWalFoldFailure) {
    return false;
  }
  if (dest.existsSync()) {
    dest.deleteSync();
  }
  Database? db;
  try {
    db = sqlite3.open(source.path, mode: OpenMode.readWrite);
    db.execute('VACUUM INTO ${_sqlStringLiteral(dest.path)}');
    return dest.existsSync() && dest.lengthSync() > 0;
  } on Object {
    if (dest.existsSync()) {
      dest.deleteSync();
    }
    return false;
  } finally {
    db?.close();
  }
}

bool _checkpointWal(File sqliteFile) {
  if (linuxAppSupportForceWalFoldFailure) {
    return false;
  }
  Database? db;
  try {
    db = sqlite3.open(sqliteFile.path, mode: OpenMode.readWrite);
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    return true;
  } on Object {
    return false;
  } finally {
    db?.close();
  }
}

String _sqlStringLiteral(String value) {
  return "'${value.replaceAll("'", "''")}'";
}

void _deleteIncoming(Directory dir) {
  if (!dir.existsSync()) {
    return;
  }
  final incoming = File(
    '${dir.path}${Platform.pathSeparator}$_kIncomingDatabaseFileName',
  );
  if (incoming.existsSync() &&
      incoming.statSync().type == FileSystemEntityType.file) {
    incoming.deleteSync();
  }
}

void _removeSqliteWalSidecars(Directory dir) {
  for (final suffix in _kSqliteSidecarSuffixes) {
    final file = File(
      '${dir.path}${Platform.pathSeparator}$kMangaJpDatabaseFileName$suffix',
    );
    if (file.existsSync() &&
        file.statSync().type == FileSystemEntityType.file) {
      file.deleteSync();
    }
  }
}

bool _isMangaJpDatabaseSidecar(String name) {
  return name == kMangaJpDatabaseFileName ||
      name == _kIncomingDatabaseFileName ||
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

final class _Passwd extends Struct {
  external Pointer<Char> pwName;
  external Pointer<Char> pwPasswd;
  @UnsignedInt()
  external int pwUid;
  @UnsignedInt()
  external int pwGid;
  external Pointer<Char> pwGecos;
  external Pointer<Char> pwDir;
  external Pointer<Char> pwShell;
}

typedef _GetuidNative = UnsignedInt Function();
typedef _GetuidDart = int Function();
typedef _GetpwuidNative = Pointer<_Passwd> Function(UnsignedInt);
typedef _GetpwuidDart = Pointer<_Passwd> Function(int);

String? _cstring(Pointer<Char> ptr) {
  if (ptr == nullptr) {
    return null;
  }
  final bytes = <int>[];
  for (var i = 0; ; i++) {
    final b = ptr[i];
    if (b == 0) {
      break;
    }
    bytes.add(b);
  }
  return utf8.decode(bytes);
}
