/// One JMdict entry (`entries.seq`) with glosses from `data_json`.
class DictEntry {
  const DictEntry({
    required this.seq,
    required this.lemma,
    required this.reading,
    required this.glosses,
    this.priority,
  });

  final int seq;

  /// Headword as stored in JMdict (kanji if present, else kana).
  final String lemma;

  /// First kana reading from `data_json`, else [lemma].
  final String reading;

  /// Gloss strings copied from JMdict senses. Never invented by the app.
  final List<String> glosses;

  /// Best `forms.priority` among matching surfaces (higher = more common).
  final int? priority;

  String get glossText => glosses.join('; ');
}
