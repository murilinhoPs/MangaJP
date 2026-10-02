/// Inflected surface → expected JMdict lemma (as written).
///
/// Lemmas use the common dictionary headword: kanji when that is the usual
/// written form (`食べる`, `行く`, `来る`), kana for `する`.
class LemmaVector {
  const LemmaVector({
    required this.surface,
    required this.lemma,
    required this.group,
  });

  final String surface;
  final String lemma;

  /// Coverage bucket: ichidan / godan / te / past / negative / polite / irregular.
  final String group;

  @override
  String toString() => '$group: $surface → $lemma';
}

/// Committed M0.7 lemma set (≥50). Do not drop cases to inflate hit rate.
const List<LemmaVector> lemmaVectors = [
  // Ichidan
  LemmaVector(surface: '食べた', lemma: '食べる', group: 'ichidan-past'),
  LemmaVector(surface: '食べて', lemma: '食べる', group: 'ichidan-te'),
  LemmaVector(surface: '食べない', lemma: '食べる', group: 'ichidan-negative'),
  LemmaVector(surface: '食べます', lemma: '食べる', group: 'ichidan-polite'),
  LemmaVector(surface: '食べました', lemma: '食べる', group: 'ichidan-polite'),
  LemmaVector(surface: '食べてる', lemma: '食べる', group: 'ichidan-te'),
  LemmaVector(surface: '食べよう', lemma: '食べる', group: 'ichidan'),
  LemmaVector(surface: '食べれば', lemma: '食べる', group: 'ichidan'),
  LemmaVector(surface: '食べさせる', lemma: '食べる', group: 'ichidan'),
  LemmaVector(surface: '食べたい', lemma: '食べる', group: 'ichidan'),
  LemmaVector(surface: '見た', lemma: '見る', group: 'ichidan-past'),
  LemmaVector(surface: '見て', lemma: '見る', group: 'ichidan-te'),
  LemmaVector(surface: '見ない', lemma: '見る', group: 'ichidan-negative'),
  LemmaVector(surface: '見ます', lemma: '見る', group: 'ichidan-polite'),
  LemmaVector(surface: '見ました', lemma: '見る', group: 'ichidan-polite'),
  LemmaVector(surface: '起きた', lemma: '起きる', group: 'ichidan-past'),
  LemmaVector(surface: '起きて', lemma: '起きる', group: 'ichidan-te'),
  LemmaVector(surface: '起きない', lemma: '起きる', group: 'ichidan-negative'),
  LemmaVector(surface: '閉じた', lemma: '閉じる', group: 'ichidan-past'),
  LemmaVector(surface: '閉じて', lemma: '閉じる', group: 'ichidan-te'),

  // Godan
  LemmaVector(surface: '書いた', lemma: '書く', group: 'godan-past'),
  LemmaVector(surface: '書いて', lemma: '書く', group: 'godan-te'),
  LemmaVector(surface: '書かない', lemma: '書く', group: 'godan-negative'),
  LemmaVector(surface: '書きます', lemma: '書く', group: 'godan-polite'),
  LemmaVector(surface: '書こう', lemma: '書く', group: 'godan'),
  LemmaVector(surface: '泳いだ', lemma: '泳ぐ', group: 'godan-past'),
  LemmaVector(surface: '泳いで', lemma: '泳ぐ', group: 'godan-te'),
  LemmaVector(surface: '泳がない', lemma: '泳ぐ', group: 'godan-negative'),
  LemmaVector(surface: '話した', lemma: '話す', group: 'godan-past'),
  LemmaVector(surface: '話して', lemma: '話す', group: 'godan-te'),
  LemmaVector(surface: '話さない', lemma: '話す', group: 'godan-negative'),
  LemmaVector(surface: '待った', lemma: '待つ', group: 'godan-past'),
  LemmaVector(surface: '待って', lemma: '待つ', group: 'godan-te'),
  LemmaVector(surface: '待たない', lemma: '待つ', group: 'godan-negative'),
  LemmaVector(surface: '死んだ', lemma: '死ぬ', group: 'godan-past'),
  LemmaVector(surface: '死んで', lemma: '死ぬ', group: 'godan-te'),
  LemmaVector(surface: '遊んだ', lemma: '遊ぶ', group: 'godan-past'),
  LemmaVector(surface: '遊ばない', lemma: '遊ぶ', group: 'godan-negative'),
  LemmaVector(surface: '飲んだ', lemma: '飲む', group: 'godan-past'),
  LemmaVector(surface: '飲んで', lemma: '飲む', group: 'godan-te'),
  LemmaVector(surface: '飲まない', lemma: '飲む', group: 'godan-negative'),
  LemmaVector(surface: '取った', lemma: '取る', group: 'godan-past'),
  LemmaVector(surface: '取って', lemma: '取る', group: 'godan-te'),
  LemmaVector(surface: '買った', lemma: '買う', group: 'godan-past'),
  LemmaVector(surface: '買って', lemma: '買う', group: 'godan-te'),
  LemmaVector(surface: '買わない', lemma: '買う', group: 'godan-negative'),
  LemmaVector(surface: '読んだ', lemma: '読む', group: 'godan-past'),
  LemmaVector(surface: '読みます', lemma: '読む', group: 'godan-polite'),
  LemmaVector(surface: '聞いた', lemma: '聞く', group: 'godan-past'),
  LemmaVector(surface: '聞きます', lemma: '聞く', group: 'godan-polite'),
  LemmaVector(surface: '持った', lemma: '持つ', group: 'godan-past'),
  LemmaVector(surface: '持って', lemma: '持つ', group: 'godan-te'),

  // Irregulars
  LemmaVector(surface: 'した', lemma: 'する', group: 'irregular-past'),
  LemmaVector(surface: 'して', lemma: 'する', group: 'irregular-te'),
  LemmaVector(surface: 'しない', lemma: 'する', group: 'irregular-negative'),
  LemmaVector(surface: 'します', lemma: 'する', group: 'irregular-polite'),
  LemmaVector(surface: 'しました', lemma: 'する', group: 'irregular-polite'),
  LemmaVector(surface: 'できる', lemma: 'する', group: 'irregular'),
  LemmaVector(surface: '来た', lemma: '来る', group: 'irregular-past'),
  LemmaVector(surface: '来て', lemma: '来る', group: 'irregular-te'),
  LemmaVector(surface: '来ない', lemma: '来る', group: 'irregular-negative'),
  LemmaVector(surface: '来ます', lemma: '来る', group: 'irregular-polite'),
  LemmaVector(surface: '来い', lemma: '来る', group: 'irregular'),
  LemmaVector(surface: '行った', lemma: '行く', group: 'irregular-past'),
  LemmaVector(surface: '行って', lemma: '行く', group: 'irregular-te'),
  LemmaVector(surface: '行かない', lemma: '行く', group: 'irregular-negative'),
  LemmaVector(surface: '行きます', lemma: '行く', group: 'irregular-polite'),

  // i-adjectives (same suffix table; lemmas still live in forms)
  LemmaVector(surface: '高かった', lemma: '高い', group: 'adj-past'),
  LemmaVector(surface: '高くない', lemma: '高い', group: 'adj-negative'),
  LemmaVector(surface: '高くて', lemma: '高い', group: 'adj-te'),
  LemmaVector(surface: '新しかった', lemma: '新しい', group: 'adj-past'),
  LemmaVector(surface: '新しくない', lemma: '新しい', group: 'adj-negative'),
];
