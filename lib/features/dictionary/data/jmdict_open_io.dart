import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'jmdict_service.dart';

/// Opens a JMdict sqlite file from a real filesystem path (tests + native).
CommonDatabase openJmdictFile(String path) {
  return sqlite3.open(path, mode: OpenMode.readOnly);
}

/// Copies `assets/dict/jmdict.sqlite` (M0.5 bake) to a filesystem path.
Future<String> ensureJmdictFile() async {
  final dir = await _jmdictDiskDirectory();
  await dir.create(recursive: true);
  final file = File('${dir.path}/jmdict.sqlite');
  if (!file.existsSync()) {
    final data = await rootBundle.load(JmdictService.assetPath);
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }
  return file.path;
}

Future<Directory> _jmdictDiskDirectory() async {
  try {
    return await getApplicationSupportDirectory();
  } catch (_) {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }
}

/// Native: copy the Flutter asset out of the bundle, then open it read-only.
Future<CommonDatabase> openJmdictFromAsset() async {
  final path = await ensureJmdictFile();
  return openJmdictFile(path);
}
