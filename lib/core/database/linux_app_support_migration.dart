import 'dart:io';

/// Current Linux GApplication / `APPLICATION_ID`.
const kLinuxApplicationId = 'dev.murilinhops.mangajp';

/// Linux `APPLICATION_ID` used before the #62 rename.
const kLegacyLinuxApplicationId = 'dev.murilinhops.manga_jp';

/// Outcome of [migrateLinuxAppSupportDirectory].
enum LinuxAppSupportMigrationResult {
  /// [oldDir] is missing — nothing to move. First launch or already moved.
  skippedOldMissing,

  /// [newDir] already has files — do not overwrite.
  skippedNewHasData,

  /// Contents copied from [oldDir] into [newDir].
  migrated,
}

/// Copies Linux app-support files from [oldDir] to [newDir] once.
///
/// Used when `APPLICATION_ID` changes: `path_provider_linux` 2.2.2
/// (`getApplicationSupportPath`, lines 47–62) joins `$XDG_DATA_HOME` (or
/// `~/.local/share`) with `g_application_get_application_id`, so Drift
/// (`mangajp.sqlite`) and JMdict would otherwise open an empty folder.
///
/// Idempotent. Never deletes [oldDir]. Copy goes through a sibling
/// `.migrating` staging directory and is renamed into [newDir] only after
/// the copy finishes, so a failed attempt does not replace existing data.
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
  if (!_directoryMissingOrEmpty(newDir)) {
    return LinuxAppSupportMigrationResult.skippedNewHasData;
  }

  final staging = Directory('$newPath.migrating');
  if (staging.existsSync()) {
    staging.deleteSync(recursive: true);
  }
  _copyDirectory(oldDir, staging);
  if (newDir.existsSync()) {
    newDir.deleteSync(recursive: true);
  }
  staging.renameSync(newPath);
  return LinuxAppSupportMigrationResult.migrated;
}

/// Linux-only: migrate `$XDG_DATA_HOME/<legacy id>` → `<new id>` if needed.
///
/// No-op on other platforms. Swallows I/O errors so a failed copy never
/// deletes [kLegacyLinuxApplicationId] and the app can still start.
void maybeMigrateLinuxAppSupport() {
  if (!Platform.isLinux) {
    return;
  }
  try {
    final dataHome = linuxXdgDataHome();
    migrateLinuxAppSupportDirectory(
      oldDir: Directory('${dataHome.path}/$kLegacyLinuxApplicationId'),
      newDir: Directory('${dataHome.path}/$kLinuxApplicationId'),
    );
  } on Object {
    // Keep the legacy directory; the next launch retries.
  }
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

bool _directoryMissingOrEmpty(Directory dir) {
  if (!dir.existsSync()) {
    return true;
  }
  return dir.listSync(followLinks: false).isEmpty;
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
