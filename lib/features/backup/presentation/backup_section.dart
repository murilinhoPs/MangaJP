import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/shell_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../data/backup_file_port.dart';
import '../data/backup_repository.dart';
import '../data/backup_shot.dart';
import '../domain/backup_codec.dart';
import '../domain/backup_document.dart';
import '../domain/backup_exception.dart';
import '../domain/backup_labels.dart';
import 'backup_keys.dart';

/// Ajustes › Backup: export / restore JSON of Caderno + SRS + `saved_kanji`.
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _busy = false;
  bool _didShot = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    _maybeShot();
    return Card(
      key: BackupKeys.section,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BackupLabels.section,
              style: AppTypeScale.ui14.copyWith(
                color: tokens.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              BackupLabels.subtitle,
              style: AppTypeScale.metadados12.copyWith(color: tokens.text2),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: BackupKeys.export,
                  onPressed: _busy ? null : _export,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(BackupLabels.exportJson),
                ),
                OutlinedButton(
                  key: BackupKeys.restore,
                  onPressed: _busy ? null : _restore,
                  child: const Text(BackupLabels.restoreJson),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _maybeShot() {
    if (_didShot) {
      return;
    }
    if (kBackupShotConfirm ||
        kBackupShotRejected ||
        kBackupShotOk ||
        kBackupShotSkipped) {
      _didShot = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Scrollable.ensureVisible(
          context,
          alignment: 0.15,
          duration: Duration.zero,
        );
        if (kBackupShotConfirm) {
          _showConfirmDialog();
        } else if (kBackupShotRejected) {
          _snack(BackupLabels.unknownSchema(fileSchema: 11, appSchema: 10));
        } else if (kBackupShotOk) {
          _snack(BackupLabels.restoreOk);
        } else if (kBackupShotSkipped) {
          _snack(BackupLabels.restoreOkSkipped(2));
        }
      });
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final doc = await ref.read(backupRepositoryProvider).export();
      final json = encodeBackupJson(doc);
      final saved = await ref
          .read(backupFilePortProvider)
          .saveBackupJson(fileName: 'mangajp-backup.json', contents: json);
      if (!mounted) {
        return;
      }
      if (saved == BackupSaveResult.saved) {
        _snack(BackupLabels.exportOk);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restore() async {
    final source = await ref.read(backupFilePortProvider).pickBackupJson();
    if (!mounted || source == null) {
      return;
    }
    final schemaVersion = ref.read(backupRepositoryProvider).schemaVersion;
    late final BackupDocument doc;
    try {
      doc = decodeBackupJson(source, currentSchemaVersion: schemaVersion);
    } on BackupRejectedException catch (error) {
      _snack(error.message);
      return;
    }
    final confirmed = await _showConfirmDialog();
    if (!mounted || confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(backupRepositoryProvider).restore(doc);
      if (!mounted) {
        return;
      }
      _snack(_okMessage(result));
    } on BackupRestoreFailedException catch (error) {
      if (mounted) {
        _snack(error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _okMessage(BackupRestoreResult result) {
    if (result.skippedKanji > 0) {
      return BackupLabels.restoreOkSkipped(result.skippedKanji);
    }
    return BackupLabels.restoreOk;
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: BackupKeys.confirmDialog,
          title: const Text(BackupLabels.confirmTitle),
          content: const Text(BackupLabels.confirmBody),
          actions: [
            TextButton(
              key: BackupKeys.confirmCancel,
              style: TextButton.styleFrom(
                foregroundColor: dialogContext.tokens.text2,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                side: BorderSide.none,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(BackupLabels.cancel),
            ),
            FilledButton(
              key: BackupKeys.confirmRestore,
              style: FilledButton.styleFrom(
                backgroundColor: dialogContext.tokens.danger,
                foregroundColor: dialogContext.tokens.onCoral,
                surfaceTintColor: Colors.transparent,
                side: BorderSide(color: dialogContext.tokens.danger),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(BackupLabels.confirmAction),
            ),
          ],
        );
      },
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          ShellLayout.commandBarPaddingOf(context) + 8,
        ),
        duration: kBackupShotRejected || kBackupShotOk || kBackupShotSkipped
            ? const Duration(minutes: 5)
            : const Duration(seconds: 4),
      ),
    );
  }
}
