import 'package:flutter/foundation.dart';

/// Screenshot helper. Off by default; ignored in release.
///
/// `flutter run --dart-define=MANGAJP_BACKUP_SHOT=confirm` (and siblings).
const kBackupShot = String.fromEnvironment('MANGAJP_BACKUP_SHOT');

bool get kBackupShotConfirm => !kReleaseMode && kBackupShot == 'confirm';

bool get kBackupShotRejected => !kReleaseMode && kBackupShot == 'rejected';

bool get kBackupShotOk => !kReleaseMode && kBackupShot == 'ok';

bool get kBackupShotAbout => !kReleaseMode && kBackupShot == 'about';

bool get kBackupShotSkipped => !kReleaseMode && kBackupShot == 'skipped';
