import 'package:sqlite3/sqlite3.dart';

/// Read-only JMdict (`jmdict.sqlite`, PRD §9.2).
///
/// Bake the DB with `tools/build_jmdict_sqlite`. Longest-prefix lookup and the
/// lookup sheet land in later M0 work — this only opens the file.
class JmdictService {
  JmdictService();

  Database? _db;

  /// Flutter asset path listed in `pubspec.yaml`. Copy out of the bundle
  /// before [openFile]; sqlite needs a real filesystem path.
  static const assetPath = 'assets/dict/jmdict.sqlite';

  bool get isOpen => _db != null;

  Database get database {
    final db = _db;
    if (db == null) {
      throw StateError('JmdictService is not open');
    }
    return db;
  }

  /// Opens [path] read-only. Caller owns copying the Flutter asset to disk.
  void openFile(String path) {
    close();
    _db = sqlite3.open(path, mode: OpenMode.readOnly);
  }

  void close() {
    _db?.close();
    _db = null;
  }

  List<String> tableNames() {
    final rows = database.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    return [for (final row in rows) row['name'] as String];
  }

  /// POS tags for one JMdict seq (Yomitan deinflect filter input).
  List<String> posForSeq(int seq) {
    final rows = database.select(
      'SELECT pos FROM sense_pos WHERE seq = ? ORDER BY pos',
      [seq],
    );
    return [for (final row in rows) row['pos'] as String];
  }
}
