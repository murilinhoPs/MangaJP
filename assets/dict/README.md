# jmdict.sqlite

Read-only JMdict asset for lookup (PRD §9.2). **Not committed** — `*.sqlite` is gitignored.

Generate it:

```bash
python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py \
  --output assets/dict/jmdict.sqlite \
  --with-kanji
```

See `tools/build_jmdict_sqlite/README.md` for flags, schema, fixtures, and EDRDG attribution.

After baking, the file is included via `pubspec.yaml` `assets/dict/`. Native copies it out of the Flutter bundle (`ensureJmdictFile` in `jmdict_open_io.dart`) because sqlite needs a real filesystem path. Flutter web loads `web/sqlite3.wasm` and opens the asset bytes in an in-memory VFS (`jmdict_open_web.dart`).
