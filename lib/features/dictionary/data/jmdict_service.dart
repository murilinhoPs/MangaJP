import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../domain/dict_entry.dart';

/// One `forms` row joined to `entries.data_json`.
class FormHit {
  const FormHit({
    required this.text,
    required this.seq,
    required this.isKana,
    required this.priority,
    required this.dataJson,
  });

  final String text;
  final int seq;
  final bool isKana;
  final int? priority;
  final String dataJson;
}

/// Read-only JMdict (`jmdict.sqlite`, PRD §9.2).
///
/// Bake the DB with `tools/build_jmdict_sqlite`. Copy the Flutter asset to a
/// real filesystem path before [openFile] (sqlite cannot open the bundle).
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

  /// Exact surface in `forms` (kanji or kana). Used to score deinflect lemmas.
  bool hasForm(String text) {
    final rows = database.select('SELECT 1 FROM forms WHERE text = ? LIMIT 1', [
      text,
    ]);
    return rows.isNotEmpty;
  }

  /// `forms` ⨝ `entries` for exact [texts] (kanji or kana).
  List<FormHit> formHits(Iterable<String> texts) {
    final unique = <String>{...texts}.toList();
    if (unique.isEmpty) {
      return const [];
    }
    final placeholders = List.filled(unique.length, '?').join(', ');
    final rows = database.select(
      'SELECT f.text, f.seq, f.is_kana, f.priority, e.data_json '
      'FROM forms f '
      'JOIN entries e ON e.seq = f.seq '
      'WHERE f.text IN ($placeholders)',
      unique,
    );
    return [
      for (final row in rows)
        FormHit(
          text: row['text'] as String,
          seq: row['seq'] as int,
          isKana: (row['is_kana'] as int) != 0,
          priority: row['priority'] as int?,
          dataJson: row['data_json'] as String,
        ),
    ];
  }

  /// Parse glosses / lemma / reading from one `entries.data_json` blob.
  static DictEntry entryFromDataJson({
    required int seq,
    required String dataJson,
    int? priority,
  }) {
    final data = jsonDecode(dataJson) as Map<String, dynamic>;
    final kanji = _formTexts(data['kanji']);
    final kana = _formTexts(data['kana']);
    final lemma = kanji.isNotEmpty ? kanji.first : kana.first;
    final reading = kana.isNotEmpty ? kana.first : lemma;
    return DictEntry(
      seq: seq,
      lemma: lemma,
      reading: reading,
      glosses: _glosses(data['senses']),
      priority: priority,
    );
  }

  static List<String> _formTexts(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map && item['text'] is String) item['text'] as String,
    ];
  }

  static List<String> _glosses(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final sense in raw)
        if (sense is Map && sense['gloss'] is List)
          for (final gloss in sense['gloss'] as List)
            if (gloss is String && gloss.isNotEmpty) gloss,
    ];
  }
}
