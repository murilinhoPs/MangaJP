import 'package:flutter/services.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';

import 'jmdict_service.dart';

const _sqlite3Wasm = 'sqlite3.wasm';
const _jmdictVfsPath = '/jmdict.sqlite';

/// Web has no filesystem path for sqlite; lookup goes through [openJmdictFromAsset].
CommonDatabase openJmdictFile(String path) {
  throw UnsupportedError(
    'Filesystem sqlite paths are not available on web. '
    'Use openJmdictFromAsset().',
  );
}

/// Loads `sqlite3.wasm` and opens the JMdict asset in an in-memory VFS.
Future<CommonDatabase> openJmdictFromAsset() async {
  final data = await rootBundle.load(JmdictService.assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse(_sqlite3Wasm));
  final fs = InMemoryFileSystem();
  sqlite.registerVirtualFileSystem(fs, makeDefault: true);
  final opened = fs.xOpen(
    Sqlite3Filename(_jmdictVfsPath),
    SqlFlag.SQLITE_OPEN_CREATE | SqlFlag.SQLITE_OPEN_READWRITE,
  );
  opened.file
    ..xWrite(bytes, 0)
    ..xClose();
  return sqlite.open(_jmdictVfsPath, mode: OpenMode.readOnly);
}
