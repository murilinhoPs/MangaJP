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
    if (Platform.isAndroid || Platform.isIOS) {
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
      return BackupSaveResult.saved;
    }
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      throw UnsupportedError('backup export is not supported on this platform');
    }
    final mode = desktopBackupWriteModeFor();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: BackupLabels.exportDialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: desktopPickerBytes(mode, bytes),
    );
    if (path == null) {
      return BackupSaveResult.cancelled;
    }
    if (path.isEmpty || path.startsWith('content:')) {
      throw FileSystemException('desktop backup path missing', path);
    }
    await persistPickedDesktopBackup(File(path), contents, mode: mode);
    return BackupSaveResult.saved;
  }
}

/// How the dest file is finalized after the save dialog.
enum DesktopBackupWriteMode {
  /// Linux / Windows: unique sidecar next to dest, then rename.
  atomicSidecar,

  /// macOS sandbox: the save panel only grants the chosen file, not the
  /// folder. Never create a sibling `.tmp`. Trust picker bytes if they
  /// already match; otherwise rewrite [file] in place.
  inPlace,
}

@visibleForTesting
DesktopBackupWriteMode desktopBackupWriteModeFor({
  bool? macos,
  bool? linux,
  bool? windows,
}) {
  if (macos ?? Platform.isMacOS) {
    return DesktopBackupWriteMode.inPlace;
  }
  if ((linux ?? Platform.isLinux) || (windows ?? Platform.isWindows)) {
    return DesktopBackupWriteMode.atomicSidecar;
  }
  throw UnsupportedError('desktop backup only on macOS/Linux/Windows');
}

/// `file_picker` `saveFile(bytes:)` writes straight onto dest
/// (`File(path).writeAsBytes`). On Linux/Windows that would clobber a good
/// backup before the atomic sidecar runs. On macOS the picker *must* write
/// the user-selected file (sandbox grant).
@visibleForTesting
Uint8List? desktopPickerBytes(DesktopBackupWriteMode mode, Uint8List bytes) {
  return mode == DesktopBackupWriteMode.inPlace ? bytes : null;
}

/// Writes [contents] to [file] only after a full, flushed, validated temp
/// file is renamed into place. A mid-write failure used to leave bytes in
/// [file] (`exists && length > 0`) and count as success — a corrupt backup
/// the user would restore later.
typedef DesktopBackupTmpWriter = Future<void> Function(
  File tmp,
  List<int> bytes,
);

@visibleForTesting
bool desktopBackupMatches(File file, String contents) {
  if (!file.existsSync()) {
    return false;
  }
  final expected = utf8.encode(contents);
  if (file.lengthSync() != expected.length) {
    return false;
  }
  try {
    final decoded = utf8.decode(file.readAsBytesSync());
    jsonDecode(decoded);
    return decoded == contents;
  } on FormatException {
    return false;
  } on FileSystemException {
    return false;
  }
}

@visibleForTesting
Future<void> persistPickedDesktopBackup(
  File file,
  String contents, {
  required DesktopBackupWriteMode mode,
  DesktopBackupTmpWriter? writeTmp,
}) async {
  switch (mode) {
    case DesktopBackupWriteMode.inPlace:
      await writeDesktopBackupInPlace(file, contents);
    case DesktopBackupWriteMode.atomicSidecar:
      await writeDesktopBackupAtomically(file, contents, writeTmp: writeTmp);
  }
  if (!desktopBackupMatches(file, contents)) {
    throw FileSystemException(
      'backup on disk does not match exported JSON',
      file.path,
    );
  }
}

@visibleForTesting
Future<void> writeDesktopBackupInPlace(File file, String contents) async {
  if (desktopBackupMatches(file, contents)) {
    return;
  }
  final bytes = utf8.encode(contents);
  await _writeTmpFlushed(file, bytes);
}

@visibleForTesting
Future<void> writeDesktopBackupAtomically(
  File file,
  String contents, {
  DesktopBackupTmpWriter? writeTmp,
}) async {
  final bytes = utf8.encode(contents);
  final tmp = File(
    '${file.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
  );
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
