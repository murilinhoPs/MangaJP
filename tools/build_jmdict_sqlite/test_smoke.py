#!/usr/bin/env python3
"""Smoke-check jmdict.sqlite schema + a known entry (食べる / seq 1358280)."""

from __future__ import annotations

import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import build_jmdict_sqlite as builder  # noqa: E402

FIXTURE_JMDICT = TOOL_DIR / "testdata" / "jmdict_fixture.xml"
FIXTURE_KANJI = TOOL_DIR / "testdata" / "kanjidic2_fixture.xml"
TABERU_SEQ = 1358280


class JmdictSqliteSmoke(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._tmp = tempfile.TemporaryDirectory(prefix="jmdict-smoke-")
        cls.db_path = Path(cls._tmp.name) / "jmdict.sqlite"
        builder.build(
            output=cls.db_path,
            input_path=FIXTURE_JMDICT,
            url=builder.JMDICT_E_URL,
            cache_dir=Path(cls._tmp.name) / "cache",
            download_source=False,
            kanjidic=FIXTURE_KANJI,
            kanjidic_url=builder.KANJIDIC2_URL,
            with_kanji=False,
            limit=None,
        )
        cls.con = sqlite3.connect(f"file:{cls.db_path}?mode=ro", uri=True)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.con.close()
        cls._tmp.cleanup()

    def test_required_tables_exist(self) -> None:
        names = {
            row[0]
            for row in self.con.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )
        }
        self.assertGreaterEqual(
            names,
            {"entries", "forms", "sense_pos", "kanji"},
        )

    def test_prd_columns(self) -> None:
        def cols(table: str) -> list[str]:
            return [row[1] for row in self.con.execute(f"PRAGMA table_info({table})")]

        self.assertEqual(cols("entries"), ["seq", "data_json"])
        self.assertEqual(cols("forms"), ["text", "seq", "is_kana", "priority"])
        self.assertEqual(cols("sense_pos"), ["seq", "pos"])
        self.assertEqual(
            cols("kanji"),
            ["character", "readings_json", "meanings_json", "stroke_count", "freq"],
        )

    def test_taberu_sense_pos_has_v1(self) -> None:
        pos = {
            row[0]
            for row in self.con.execute(
                "SELECT pos FROM sense_pos WHERE seq = ?", (TABERU_SEQ,)
            )
        }
        self.assertIn("v1", pos)
        self.assertIn("vt", pos)

    def test_taberu_forms_and_inherited_sense(self) -> None:
        forms = list(
            self.con.execute(
                "SELECT text, is_kana FROM forms WHERE seq = ? ORDER BY is_kana, text",
                (TABERU_SEQ,),
            )
        )
        self.assertIn(("食べる", 0), forms)
        self.assertIn(("たべる", 1), forms)

        (data_json,) = self.con.execute(
            "SELECT data_json FROM entries WHERE seq = ?", (TABERU_SEQ,)
        ).fetchone()
        self.assertIn("to eat", data_json)
        # Second sense omits <pos> in XML; builder inherits v1/vt.
        self.assertIn("to live on", data_json)
        self.assertIn('"pos":["v1","vt"]', data_json.replace(" ", ""))

    def test_indexes(self) -> None:
        indexes = {
            row[0]
            for row in self.con.execute(
                "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
            )
        }
        self.assertIn("idx_forms_text", indexes)
        self.assertIn("idx_sense_pos_pos", indexes)

    def test_kanji_fixture_row(self) -> None:
        row = self.con.execute(
            "SELECT stroke_count, freq, readings_json, meanings_json FROM kanji WHERE character = ?",
            ("食",),
        ).fetchone()
        self.assertIsNotNone(row)
        stroke, freq, readings, meanings = row
        self.assertEqual(stroke, 9)
        self.assertEqual(freq, 328)
        self.assertIn("ショク", readings)
        self.assertIn("eat", meanings)
        self.assertNotIn("nourriture", meanings)


if __name__ == "__main__":
    unittest.main(verbosity=2)
