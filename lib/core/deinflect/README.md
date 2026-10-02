# `core/deinflect` — Yomitan Japanese transforms

Pure Dart port of Yomitan's Japanese deinflector (Q-B3 / GPL-3.0). No Flutter
import.

| File | Yomitan source (commit `67db60ddc2cbd7b5172d777c117e3201d7ddff0f`) |
| --- | --- |
| `rules.dart` | `ext/js/language/ja/japanese-transforms.js` (suffix + whole-word rules, condition map) |
| `deinflector.dart` | `ext/js/language/language-transformer.js` (flag compiler + BFS) plus `suffixInflection` / `wholeWordInflection` from `language-transforms.js` |

`Deinflector.candidates(surface)` returns unique strings, original first,
including intermediate forms (て-form, ます-stem, …). POS filtering against
JMdict `sense_pos` is M1 lookup, not this package.

Lemma hit-rate vectors live in `test/core/deinflect/lemma_vectors.dart`. Expected
lemmas are the dictionary headword **as written** (kanji when the verb is
usually kanji, kana for `する`). The suite also bakes those lemmas into
`forms` via `tools/build_jmdict_sqlite` so a hit is a real dictionary form, not
an invented spelling.
