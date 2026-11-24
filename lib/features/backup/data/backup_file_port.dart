import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/backup_labels.dart';

part 'backup_file_port.g.dart';

enum BackupSaveResult { saved, cancelled }

/// Picks / saves the backup JSON. Widget tests inject [MemoryBackupFilePort].
abstract class BackupFilePort {
  Future<String?> pickBackupJson();

  Future<BackupSaveResult> saveBackupJson({
    required String fileName,
    required String contents,
  });
}

@Riverpod(keepAlive: true)
BackupFilePort backupFilePort(Ref ref) => FilePickerBackupPort();

class FilePickerBackupPort implements BackupFilePort {
  @override
  Future<String?> pickBackupJson() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: BackupLabels.importDialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes != null) {
      return utf8.decode(bytes);
    }
    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return File(path).readAsString();
  }

  @override
  Future<BackupSaveResult> saveBackupJson({
    required String fileName,
    required String contents,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: BackupLabels.exportDialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    if (path == null) {
      return BackupSaveResult.cancelled;
    }
    if (path.isNotEmpty && !path.startsWith('content:')) {
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() == 0) {
        await file.writeAsString(contents);
      }
    }
    return BackupSaveResult.saved;
  }
}

/// In-memory double for widget / domain tests. No plugins.
class MemoryBackupFilePort implements BackupFilePort {
  MemoryBackupFilePort({this.importJson});

  String? importJson;
  String? lastExported;
  String? lastFileName;
  bool cancelPick = false;
  bool cancelSave = false;

  @override
  Future<String?> pickBackupJson() async {
    if (cancelPick) {
      return null;
    }
    return importJson;
  }

  @override
  Future<BackupSaveResult> saveBackupJson({
    required String fileName,
    required String contents,
  }) async {
    if (cancelSave) {
      return BackupSaveResult.cancelled;
    }
    lastFileName = fileName;
    lastExported = contents;
    return BackupSaveResult.saved;
  }
}
