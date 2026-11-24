import 'package:flutter/widgets.dart';

/// Widget keys for Ajustes › Backup and Sobre / Fontes.
abstract final class BackupKeys {
  static const section = Key('settings-backup');
  static const export = Key('settings-backup-export');
  static const restore = Key('settings-backup-restore');
  static const confirmDialog = Key('settings-backup-confirm-dialog');
  static const confirmCancel = Key('settings-backup-confirm-cancel');
  static const confirmRestore = Key('settings-backup-confirm-restore');
  static const aboutSection = Key('settings-about');
  static const kanjidicAttr = Key('settings-about-kanjidic');
  static const jmdictAttr = Key('settings-about-jmdict');
  static const yomitanAttr = Key('settings-about-yomitan');
}
