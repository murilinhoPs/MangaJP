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
        await writeDesktopBackupAtomically(File(path), contents);
      }
    }
    return BackupSaveResult.saved;
  }
}

/// Writes [contents] to [file] only after a full, flushed, validated temp
/// file is renamed into place. A mid-write failure used to leave bytes in
/// [file] (`exists && length > 0`) and count as success — a corrupt backup
/// the user would restore later.
typedef DesktopBackupTmpWriter =
    Future<void> Function(File tmp, List<int> bytes);

@visibleForTesting
Future<void> writeDesktopBackupAtomically(
  File file,
  String contents, {
  DesktopBackupTmpWriter? writeTmp,
}) async {
  final bytes = utf8.encode(contents);
  final tmp = File('${file.path}.tmp');
  try {
    await (writeTmp ?? _writeTmpFlushed)(tmp, bytes);
    if (!tmp.existsSync()) {
      throw FileSystemException('temp file missing after write', tmp.path);
    }
    final written = tmp.lengthSync();
    if (written != bytes.length) {
      throw FileSystemException(
        'partial write: $written != ${bytes.length}',
        tmp.path,
      );
    }
    jsonDecode(utf8.decode(tmp.readAsBytesSync()));
    await tmp.rename(file.path);
  } catch (_) {
    _deleteQuietly(tmp);
    rethrow;
  }
}

/// Kept as a name tests / call sites may still mention. Always atomic.
@visibleForTesting
Future<void> writeDesktopBackupIfEmpty(File file, String contents) {
  return writeDesktopBackupAtomically(file, contents);
}

Future<void> _writeTmpFlushed(File tmp, List<int> bytes) async {
  final raf = await tmp.open(mode: FileMode.write);
  try {
    await raf.writeFrom(bytes);
    await raf.flush();
  } finally {
    await raf.close();
  }
}

void _deleteQuietly(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup of a partial temp file.
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
