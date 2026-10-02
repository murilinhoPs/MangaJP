# build_jmdict_sqlite

M0.5: bake a read-only `jmdict.sqlite` for lookup / longest-prefix / Yomitan POS filtering (PRD §9.2).

Python 3.10+ stdlib only (`xml.etree`, `sqlite3`, `urllib`, `gzip`). Does not run inside the Flutter isolate.

## Output

Default path: **`assets/dict/jmdict.sqlite`**

That file is gitignored (`*.sqlite`). The app lists `assets/dict/` in `pubspec.yaml` so a locally baked DB is picked up as a Flutter asset. Do not commit the full dictionary (~tens of MB).

Tiny XML fixtures used by tests live in `testdata/` (not a substitute for JMdict).

## Local: full JMdict_e

```bash
# from repo root — downloads JMdict_e.gz (~10 MB) into tools/build_jmdict_sqlite/.cache/
python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py \
  --output assets/dict/jmdict.sqlite \
  --with-kanji
```

`--with-kanji` also fetches [KANJIDIC2](http://ftp.edrdg.org/pub/Nihongo/kanjidic2.xml.gz) and fills `kanji`. Omit it to create the `kanji` table empty (schema still matches the PRD).

Reuse a file you already have:

```bash
python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py \
  --input /path/to/JMdict_e.gz \
  --kanjidic /path/to/kanjidic2.xml.gz \
  --output assets/dict/jmdict.sqlite
```

## Local / CI: fixture smoke

```bash
python3 tools/build_jmdict_sqlite/test_smoke.py
```

Builds a throwaway DB from `testdata/jmdict_fixture.xml` and asserts:

- tables `entries`, `forms`, `sense_pos` (and `kanji`)
- PRD column names
- `sense_pos` for seq **1358280** (`食べる`) includes `v1`

CI runs the same command. `flutter test` also rebuilds the fixture and opens it through `JmdictService`.

## Schema (PRD §9.2)

| Table | Columns | Role |
|-------|---------|------|
| `entries` | `seq` PK, `data_json` | JMdict `ent_seq` + glosses / senses JSON |
| `forms` | `text`, `seq`, `is_kana`, `priority` | Surface forms; `idx_forms_text` for exact / longest-prefix |
| `sense_pos` | `seq`, `pos` PK | Normalized POS tags (`v1`, `v5r`, `adj-i`, …) for deinflect filters |
| `kanji` | `character`, `readings_json`, `meanings_json`, `stroke_count`, `freq` | KANJIDIC2 lookup (F24 / M2); optional rows |

`is_kana` is `1` for `r_ele` / `0` for `k_ele`. `priority` is a numeric score (higher = more common): `ichi1=90`, `news1/spec1=80`, `gai1=70`, `ichi2=45`, `news2/spec2=35`, `gai2=25`, `nfXX=49-XX`. `NULL` when the form has no `ke_pri`/`re_pri`.

`data_json` shape:

```json
{
  "kanji": [{"text": "食べる", "pri": ["ichi1"], "info": []}],
  "kana": [{"text": "たべる", "pri": ["ichi1"], "info": [], "restr": [], "nokanji": false}],
  "senses": [
    {"pos": ["v1", "vt"], "gloss": ["to eat"], "misc": [], "field": [], "dial": [], "info": null}
  ]
}
```

POS/misc/field/dial on later senses inherit the previous sense when omitted (JMdict convention). Entity codes are stored (`v1`), not the English DTD expansion (`Ichidan verb`).

## License

JMdict and KANJIDIC2 are © [Electronic Dictionary Research and Development Group](https://www.edrdg.org/), used under the [EDRDG licence](https://www.edrdg.org/edrdg/licence.html) (Creative Commons Attribution-ShareAlike). Keep this attribution with any distributed DB.
