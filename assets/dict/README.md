# jmdict.sqlite

Read-only JMdict asset for lookup (PRD §9.2). **Not committed** — `*.sqlite` is gitignored.

Generate it:

```bash
python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py \
  --output assets/dict/jmdict.sqlite \
  --with-kanji
```

See `tools/build_jmdict_sqlite/README.md` for flags, schema, fixtures, and EDRDG attribution.

After baking, the file is included via `pubspec.yaml` `assets/dict/`. At runtime the app copies it out of the bundle (`ensureJmdictFile`) and `JmdictService` opens that filesystem path read-only.
