#!/usr/bin/env python3
"""Build read-only jmdict.sqlite (PRD §9.2) from JMdict_e XML.

Schema (column names are the PRD's):
  entries(seq, data_json)
  forms(text, seq, is_kana, priority)
  sense_pos(seq, pos)  -- normalized JMdict tags: v1, v5r, adj-i, …
  kanji(character, readings_json, meanings_json, stroke_count, freq)

Stdlib only. See README.md for download URLs and license attribution.
"""

from __future__ import annotations

import argparse
import gzip
import json
import re
import sqlite3
import sys
import tempfile
import urllib.request
from pathlib import Path
from typing import IO, Iterable, Iterator
from xml.etree import ElementTree as ET

JMDICT_E_URL = "http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz"
KANJIDIC2_URL = "http://ftp.edrdg.org/pub/Nihongo/kanjidic2.xml.gz"

XML_PREDEFINED = frozenset({"amp", "lt", "gt", "quot", "apos"})
ENTITY_DECL = re.compile(r'<!ENTITY\s+([A-Za-z][\w.-]*)\s+"([^"]*)"\s*>')
ENTITY_REF = re.compile(r"&([A-Za-z][\w.-]*);")
DOCTYPE_OPEN = re.compile(r"<!DOCTYPE\s+\w+\s*\[", re.IGNORECASE)

PRI_SCORES = {
    "ichi1": 90,
    "news1": 80,
    "spec1": 80,
    "gai1": 70,
    "ichi2": 45,
    "news2": 35,
    "spec2": 35,
    "gai2": 25,
}

USER_AGENT = "MangaJP-build_jmdict_sqlite/0.5 (+https://github.com/murilinhoPs/MangaJP)"

SCHEMA_SQL = """
CREATE TABLE entries (
  seq INTEGER PRIMARY KEY,
  data_json TEXT NOT NULL
);

CREATE TABLE forms (
  text TEXT NOT NULL,
  seq INTEGER NOT NULL REFERENCES entries(seq),
  is_kana INTEGER NOT NULL,
  priority INTEGER
);

CREATE TABLE sense_pos (
  seq INTEGER NOT NULL REFERENCES entries(seq),
  pos TEXT NOT NULL,
  PRIMARY KEY (seq, pos)
);

CREATE TABLE kanji (
  character TEXT PRIMARY KEY NOT NULL,
  readings_json TEXT,
  meanings_json TEXT,
  stroke_count INTEGER,
  freq INTEGER
);
"""

INDEX_SQL = """
CREATE INDEX idx_forms_text ON forms(text);
CREATE INDEX idx_sense_pos_pos ON sense_pos(pos);
"""


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_output() -> Path:
    return repo_root() / "assets" / "dict" / "jmdict.sqlite"


def default_cache_dir() -> Path:
    return Path(__file__).resolve().parent / ".cache"


def priority_score(tags: Iterable[str]) -> int | None:
    best: int | None = None
    for tag in tags:
        score = PRI_SCORES.get(tag)
        if score is None and tag.startswith("nf") and tag[2:].isdigit():
            score = max(0, 49 - int(tag[2:]))
        if score is None:
            continue
        if best is None or score > best:
            best = score
    return best


def normalize_tag(text: str | None, entities: dict[str, str]) -> str | None:
    if text is None:
        return None
    value = text.strip()
    if not value:
        return None
    if value in entities:
        return value
    for name, expansion in entities.items():
        if expansion == value:
            return name
    return value


def texts(parent: ET.Element, tag: str) -> list[str]:
    out: list[str] = []
    for child in parent.findall(tag):
        if child.text and child.text.strip():
            out.append(child.text.strip())
    return out


def download(url: str, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {url} -> {dest}", file=sys.stderr)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=120) as resp, dest.open("wb") as out:
        while True:
            chunk = resp.read(1024 * 256)
            if not chunk:
                break
            out.write(chunk)
    return dest


def open_xml_stream(path: Path) -> IO[bytes]:
    raw = path.open("rb")
    magic = raw.read(2)
    raw.seek(0)
    if magic == b"\x1f\x8b":
        return gzip.GzipFile(fileobj=raw)  # type: ignore[return-value]
    return raw


def extract_entities_and_rewrite(src: IO[bytes], dest: Path) -> dict[str, str]:
    """Strip the internal DTD and replace &v1; with v1 (entity *names*).

    JMdict POS/misc/field tags are XML entities whose expansions are English
    phrases. Yomitan deinflect filtering needs the short codes (v1, adj-i, …).
    """
    text_src = _read_text(src)
    entities: dict[str, str] = {}
    match = DOCTYPE_OPEN.search(text_src)
    body = text_src
    if match:
        end = text_src.find("]>", match.end())
        if end != -1:
            dtd = text_src[match.end() : end]
            for name, expansion in ENTITY_DECL.findall(dtd):
                entities[name] = expansion
            body = text_src[: match.start()] + text_src[end + 2 :]

    def repl(m: re.Match[str]) -> str:
        name = m.group(1)
        if name in XML_PREDEFINED:
            return m.group(0)
        if name in entities:
            return name
        return m.group(0)

    dest.write_text(ENTITY_REF.sub(repl, body), encoding="utf-8")
    return entities


def _read_text(src: IO[bytes]) -> str:
    data = src.read()
    if isinstance(data, str):
        return data
    return data.decode("utf-8")


def parse_entry(elem: ET.Element, entities: dict[str, str]) -> dict:
    seq_text = elem.findtext("ent_seq")
    if not seq_text:
        raise ValueError("entry missing ent_seq")
    seq = int(seq_text.strip())

    kanji_forms: list[dict] = []
    forms: list[tuple[str, int, int | None]] = []

    for k_ele in elem.findall("k_ele"):
        keb = k_ele.findtext("keb")
        if not keb:
            continue
        keb = keb.strip()
        pri = texts(k_ele, "ke_pri")
        info = [
            tag
            for raw in texts(k_ele, "ke_inf")
            if (tag := normalize_tag(raw, entities))
        ]
        kanji_forms.append({"text": keb, "pri": pri, "info": info})
        forms.append((keb, 0, priority_score(pri)))

    kana_forms: list[dict] = []
    for r_ele in elem.findall("r_ele"):
        reb = r_ele.findtext("reb")
        if not reb:
            continue
        reb = reb.strip()
        pri = texts(r_ele, "re_pri")
        info = [
            tag
            for raw in texts(r_ele, "re_inf")
            if (tag := normalize_tag(raw, entities))
        ]
        kana_forms.append(
            {
                "text": reb,
                "pri": pri,
                "info": info,
                "restr": texts(r_ele, "re_restr"),
                "nokanji": r_ele.find("re_nokanji") is not None,
            }
        )
        forms.append((reb, 1, priority_score(pri)))

    senses: list[dict] = []
    pos_tags: set[str] = set()
    inherited = {"pos": [], "misc": [], "field": [], "dial": []}
    for sense in elem.findall("sense"):
        current = {}
        for key, tag in (
            ("pos", "pos"),
            ("misc", "misc"),
            ("field", "field"),
            ("dial", "dial"),
        ):
            values = [
                t
                for raw in texts(sense, tag)
                if (t := normalize_tag(raw, entities))
            ]
            if values:
                inherited[key] = values
            current[key] = list(inherited[key])
        gloss = texts(sense, "gloss")
        info_text = sense.findtext("s_inf")
        senses.append(
            {
                **current,
                "gloss": gloss,
                "info": info_text.strip() if info_text and info_text.strip() else None,
            }
        )
        pos_tags.update(current["pos"])

    data = {"kanji": kanji_forms, "kana": kana_forms, "senses": senses}
    return {"seq": seq, "data": data, "forms": forms, "pos": sorted(pos_tags)}


def iter_jmdict_entries(xml_path: Path, entities: dict[str, str]) -> Iterator[dict]:
    for event, elem in ET.iterparse(xml_path, events=("end",)):
        if elem.tag != "entry":
            continue
        try:
            parsed = parse_entry(elem, entities)
        finally:
            elem.clear()
        yield parsed


def parse_kanji_character(elem: ET.Element) -> dict | None:
    literal = elem.findtext("literal")
    if not literal:
        return None
    literal = literal.strip()
    misc = elem.find("misc")
    stroke = None
    freq = None
    if misc is not None:
        stroke_text = misc.findtext("stroke_count")
        if stroke_text and stroke_text.strip().isdigit():
            stroke = int(stroke_text.strip())
        freq_text = misc.findtext("freq")
        if freq_text and freq_text.strip().isdigit():
            freq = int(freq_text.strip())

    on_readings: list[str] = []
    kun_readings: list[str] = []
    meanings: list[str] = []
    for reading in elem.findall(".//reading"):
        r_type = reading.get("r_type")
        text = (reading.text or "").strip()
        if not text:
            continue
        if r_type == "ja_on":
            on_readings.append(text)
        elif r_type == "ja_kun":
            kun_readings.append(text)
    for meaning in elem.findall(".//meaning"):
        if meaning.get("m_lang"):
            continue
        text = (meaning.text or "").strip()
        if text:
            meanings.append(text)

    return {
        "character": literal,
        "readings_json": json.dumps(
            {"on": on_readings, "kun": kun_readings},
            ensure_ascii=False,
            separators=(",", ":"),
        ),
        "meanings_json": json.dumps(meanings, ensure_ascii=False, separators=(",", ":")),
        "stroke_count": stroke,
        "freq": freq,
    }


def iter_kanjidic_characters(xml_path: Path) -> Iterator[dict]:
    for event, elem in ET.iterparse(xml_path, events=("end",)):
        if elem.tag != "character":
            continue
        try:
            parsed = parse_kanji_character(elem)
        finally:
            elem.clear()
        if parsed:
            yield parsed


def dumps(obj: object) -> str:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def create_schema(con: sqlite3.Connection) -> None:
    con.executescript("PRAGMA foreign_keys = ON;")
    con.executescript(SCHEMA_SQL)


def insert_entries(con: sqlite3.Connection, entries: Iterable[dict], limit: int | None) -> int:
    cur = con.cursor()
    count = 0
    form_rows: list[tuple] = []
    pos_rows: list[tuple] = []
    for parsed in entries:
        cur.execute(
            "INSERT INTO entries(seq, data_json) VALUES (?, ?)",
            (parsed["seq"], dumps(parsed["data"])),
        )
        for text, is_kana, pri in parsed["forms"]:
            form_rows.append((text, parsed["seq"], is_kana, pri))
        for pos in parsed["pos"]:
            pos_rows.append((parsed["seq"], pos))
        count += 1
        if count % 2000 == 0:
            cur.executemany(
                "INSERT INTO forms(text, seq, is_kana, priority) VALUES (?, ?, ?, ?)",
                form_rows,
            )
            cur.executemany(
                "INSERT OR IGNORE INTO sense_pos(seq, pos) VALUES (?, ?)",
                pos_rows,
            )
            form_rows.clear()
            pos_rows.clear()
            con.commit()
            print(f"  entries: {count}", file=sys.stderr)
        if limit is not None and count >= limit:
            break
    if form_rows:
        cur.executemany(
            "INSERT INTO forms(text, seq, is_kana, priority) VALUES (?, ?, ?, ?)",
            form_rows,
        )
    if pos_rows:
        cur.executemany(
            "INSERT OR IGNORE INTO sense_pos(seq, pos) VALUES (?, ?)",
            pos_rows,
        )
    con.commit()
    return count


def insert_kanji(con: sqlite3.Connection, characters: Iterable[dict]) -> int:
    rows = [
        (
            row["character"],
            row["readings_json"],
            row["meanings_json"],
            row["stroke_count"],
            row["freq"],
        )
        for row in characters
    ]
    con.executemany(
        "INSERT OR REPLACE INTO kanji(character, readings_json, meanings_json, stroke_count, freq) "
        "VALUES (?, ?, ?, ?, ?)",
        rows,
    )
    con.commit()
    return len(rows)


def finish_db(con: sqlite3.Connection) -> None:
    con.executescript(INDEX_SQL)
    con.execute("PRAGMA journal_mode = DELETE;")
    con.commit()
    con.execute("VACUUM;")


def resolve_input(
    input_path: Path | None,
    url: str,
    cache_dir: Path,
    download_source: bool,
) -> Path:
    if input_path is not None:
        return input_path
    if not download_source:
        raise SystemExit("Provide --input or omit --no-download to fetch JMdict_e.")
    cache_dir.mkdir(parents=True, exist_ok=True)
    dest = cache_dir / Path(url).name
    if dest.exists() and dest.stat().st_size > 0:
        print(f"Using cached {dest}", file=sys.stderr)
        return dest
    return download(url, dest)


def prepare_xml(path: Path, work_dir: Path) -> tuple[Path, dict[str, str]]:
    rewritten = work_dir / "jmdict.rewritten.xml"
    with open_xml_stream(path) as src:
        entities = extract_entities_and_rewrite(src, rewritten)
    return rewritten, entities


def copy_maybe_gunzip(path: Path, dest: Path) -> Path:
    with open_xml_stream(path) as src:
        data = src.read()
    dest.write_bytes(data if isinstance(data, (bytes, bytearray)) else data.encode("utf-8"))
    return dest


def build(
    *,
    output: Path,
    input_path: Path | None,
    url: str,
    cache_dir: Path,
    download_source: bool,
    kanjidic: Path | None,
    kanjidic_url: str,
    with_kanji: bool,
    limit: int | None,
) -> Path:
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp_out = output.with_suffix(output.suffix + ".tmp")
    if tmp_out.exists():
        tmp_out.unlink()

    source = resolve_input(input_path, url, cache_dir, download_source)

    with tempfile.TemporaryDirectory(prefix="jmdict-build-") as tmp:
        work = Path(tmp)
        xml_path, entities = prepare_xml(source, work)
        print(f"Parsed {len(entities)} JMdict entities from DTD", file=sys.stderr)

        con = sqlite3.connect(tmp_out)
        try:
            con.execute("PRAGMA foreign_keys = ON;")
            con.execute("PRAGMA synchronous = OFF;")
            con.execute("PRAGMA journal_mode = MEMORY;")
            create_schema(con)
            n_entries = insert_entries(con, iter_jmdict_entries(xml_path, entities), limit)
            print(f"Inserted {n_entries} entries", file=sys.stderr)

            n_kanji = 0
            kanji_source: Path | None = kanjidic
            if kanji_source is None and with_kanji:
                kanji_source = resolve_input(
                    None, kanjidic_url, cache_dir, download_source=True
                )
            if kanji_source is not None:
                kanji_xml = copy_maybe_gunzip(kanji_source, work / "kanjidic2.xml")
                n_kanji = insert_kanji(con, iter_kanjidic_characters(kanji_xml))
                print(f"Inserted {n_kanji} kanji", file=sys.stderr)
            else:
                print("kanji table created empty (pass --with-kanji or --kanjidic)", file=sys.stderr)

            finish_db(con)
        finally:
            con.close()

    tmp_out.replace(output)
    print(f"Wrote {output}", file=sys.stderr)
    return output


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Build jmdict.sqlite (entries / forms / sense_pos / kanji) from JMdict_e."
    )
    p.add_argument(
        "--output",
        type=Path,
        default=default_output(),
        help=f"SQLite output path (default: {default_output()})",
    )
    p.add_argument(
        "--input",
        type=Path,
        help="Local JMdict XML or .gz (skip download)",
    )
    p.add_argument("--url", default=JMDICT_E_URL, help="JMdict_e download URL")
    p.add_argument(
        "--cache-dir",
        type=Path,
        default=default_cache_dir(),
        help="Where to store downloaded .gz files",
    )
    p.add_argument(
        "--no-download",
        action="store_true",
        help="Do not fetch JMdict; --input is required",
    )
    p.add_argument(
        "--kanjidic",
        type=Path,
        help="Local KANJIDIC2 XML or .gz",
    )
    p.add_argument("--kanjidic-url", default=KANJIDIC2_URL)
    p.add_argument(
        "--with-kanji",
        action="store_true",
        help="Download KANJIDIC2 and fill the kanji table",
    )
    p.add_argument("--limit", type=int, default=None, help="Stop after N JMdict entries")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.input is None and args.no_download:
        print("error: --input is required with --no-download", file=sys.stderr)
        return 2
    if args.input is not None and not args.input.exists():
        print(f"error: input not found: {args.input}", file=sys.stderr)
        return 2
    build(
        output=args.output,
        input_path=args.input,
        url=args.url,
        cache_dir=args.cache_dir,
        download_source=not args.no_download,
        kanjidic=args.kanjidic,
        kanjidic_url=args.kanjidic_url,
        with_kanji=args.with_kanji,
        limit=args.limit,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
