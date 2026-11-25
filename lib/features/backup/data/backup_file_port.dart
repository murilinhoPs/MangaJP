import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/backup_exception.dart';
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
    try {
      final bytes = file.bytes;
      if (bytes != null) {
        return utf8.decode(bytes);
      }
      final path = file.path;
      if (path == null || path.isEmpty) {
        return null;
      }
      return await File(path).readAsString();
    } on FormatException {
      throw const BackupRejectedException(BackupLabels.invalidFile);
    } on FileSystemException {
      throw const BackupRejectedException(BackupLabels.invalidFile);
    }
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
    // Android/iOS persist [bytes] in the platform channel. Do not
    // dart:io-rewrite the SAF path (it throws after a successful save).
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      if (path.isNotEmpty && !path.startsWith('content:')) {
        await writeDesktopBackupIfEmpty(File(path), contents);
      }
    }
    return BackupSaveResult.saved;
  }
}

/// Desktop follow-up write. file_picker may return a path without writing
/// [contents]. Swallow [FileSystemException] only when the file already
/// has bytes (the picker wrote them). Otherwise rethrow so the UI shows
/// «Falha ao exportar.» instead of a false «Backup exportado.».
@visibleForTesting
Future<void> writeDesktopBackupIfEmpty(File file, String contents) async {
  try {
    if (!file.existsSync() || file.lengthSync() == 0) {
      await file.writeAsString(contents);
    }
  } on FileSystemException {
    if (file.existsSync() && file.lengthSync() > 0) {
      return;
    }
    rethrow;
  }
}

/// In-memory double for widget / domain tests. No plugins.
class MemoryBackupFilePort implements BackupFilePort {
  MemoryBackupFilePort({this.importJson, this.pickError, this.saveError});

  String? importJson;
  String? lastExported;
  String? lastFileName;
  bool cancelPick = false;
  bool cancelSave = false;
  Object? pickError;
  Object? saveError;

  @override
  Future<String?> pickBackupJson() async {
    final error = pickError;
    if (error != null) {
      throw error;
    }
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
    final error = saveError;
    if (error != null) {
      throw error;
    }
    if (cancelSave) {
      return BackupSaveResult.cancelled;
    }
    lastFileName = fileName;
    lastExported = contents;
    return BackupSaveResult.saved;
  }
}
