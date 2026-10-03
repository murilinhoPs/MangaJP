#!/usr/bin/env python3
"""CER protocol + harness tests (stdlib only; no OCR models)."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import bakeoff  # noqa: E402
import cer  # noqa: E402
import engines  # noqa: E402
import ruby_boxes  # noqa: E402


class StripAndDistance(unittest.TestCase):
    def test_identical_is_zero(self) -> None:
        s = cer.score("雛子", "雛子")
        self.assertEqual(s.edits, 0)
        self.assertEqual(s.cer, 0.0)

    def test_whitespace_only_noise(self) -> None:
        s = cer.score("あい", "あ\n い\t")
        self.assertEqual(s.gt, "あい")
        self.assertEqual(s.hyp, "あい")
        self.assertEqual(s.edits, 0)

    def test_ideographic_space_stripped(self) -> None:
        s = cer.score("あい", "あ　い")
        self.assertEqual(s.edits, 0)

    def test_small_kana_not_folded(self) -> None:
        s = cer.score("よぉ", "よお")
        self.assertEqual(s.gt_len, 2)
        self.assertEqual(s.edits, 1)
        self.assertAlmostEqual(s.cer, 0.5)

    def test_fullwidth_digit_not_ascii_folded(self) -> None:
        s = cer.score("１００", "100")
        self.assertEqual(s.gt_len, 3)
        self.assertEqual(s.edits, 3)
        self.assertEqual(cer.score("１００", "１００").edits, 0)

    def test_no_nfkc_on_ellipsis_or_dash(self) -> None:
        self.assertEqual(cer.score("痛い…", "痛い…").edits, 0)
        self.assertNotEqual(cer.score("痛い…", "痛い...").edits, 0)
        self.assertNotEqual(cer.score("君は――", "君は--").edits, 0)

    def test_hiragana_katakana_not_folded(self) -> None:
        s = cer.score("ゔ", "ヴ")
        self.assertEqual(s.edits, 1)

    def test_empty_ocr_is_all_deletes(self) -> None:
        s = cer.score("雛子", "")
        self.assertEqual(s.edits, 2)
        self.assertEqual(s.cer, 1.0)

    def test_substitution_one_of_n(self) -> None:
        s = cer.score("abc", "adc")
        self.assertEqual(s.edits, 1)
        self.assertAlmostEqual(s.cer, 1 / 3)


class Manifest(unittest.TestCase):
    def test_matches_odd_crop_ids_exactly(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            crops = root / "crops"
            crops.mkdir()
            (crops / "page_6.b1.png").write_bytes(b"\x89PNG\r\n\x1a\n")
            (crops / "page_6.1_b1.png").write_bytes(b"\x89PNG\r\n\x1a\n")
            (root / "manifest-kanji.csv").write_text(
                "page_id,crop_id,gt_text\n"
                "page_6,page_6.b1,お母さん、\n"
                'page_6.1,page_6.1_b1,"ひどいことを言われて、"\n',
                encoding="utf-8",
            )
            loaded = bakeoff.load_manifest(root)
            self.assertEqual([c.crop_id for c in loaded], ["page_6.b1", "page_6.1_b1"])
            self.assertEqual(loaded[0].gt_text, "お母さん、")
            self.assertEqual(loaded[1].gt_text, "ひどいことを言われて、")

    def test_missing_png_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "crops").mkdir()
            (root / "manifest-kanji.csv").write_text(
                "page_id,crop_id,gt_text\npage_0,page_0_b1,x\n",
                encoding="utf-8",
            )
            with self.assertRaises(FileNotFoundError):
                bakeoff.load_manifest(root)


class HarnessSkipAndReplay(unittest.TestCase):
    def test_skipped_engine_has_no_cer(self) -> None:
        skipped = engines.SkippedEngine("mlkit_ja", "SKIPPED (no Android)")
        crop = bakeoff.Crop("p", "p_b1", "あい", Path("p_b1.png"))
        summary = bakeoff.run_engine(skipped, [crop])
        self.assertEqual(summary.status, "skipped")
        self.assertIsNone(summary.cer_corpus)
        self.assertEqual(summary.crops, [])

    def test_predictions_file_roundtrip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            crops_dir = root / "crops"
            crops_dir.mkdir()
            (crops_dir / "tiny_b1.png").write_bytes(b"\x89PNG\r\n\x1a\n")
            (root / "manifest-kanji.csv").write_text(
                "page_id,crop_id,gt_text\npage_t,tiny_b1,よぉ相棒\n",
                encoding="utf-8",
            )
            pred = root / "pred.json"
            pred.write_text(
                json.dumps(
                    {
                        "engine_id": "manga_ocr",
                        "predictions": {"tiny_b1": "よお相棒"},
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )
            out = root / "out"
            bakeoff.main(
                [
                    "--gt-dir",
                    str(root),
                    "--out-dir",
                    str(out),
                    "--engines",
                    "manga_ocr",
                    "--predictions",
                    f"manga_ocr={pred}",
                ]
            )
            engines_csv = (out / "engines.csv").read_text(encoding="utf-8")
            self.assertIn("manga_ocr", engines_csv)
            self.assertIn("0.250000", engines_csv)  # よぉ vs よお → 1/4
            per = (out / "per_crop.csv").read_text(encoding="utf-8")
            self.assertIn("tiny_b1", per)
            self.assertIn("よぉ相棒", per)
            self.assertIn("よお相棒", per)

    def test_cloud_vision_skip_without_creds(self) -> None:
        engine = engines.resolve_cloud_vision(api_key=None)
        # If this environment somehow has ADC, skip this assertion.
        if isinstance(engine, engines.SkippedEngine):
            self.assertIn("SKIPPED", engine.reason)
        info = engine.info()
        self.assertEqual(info.engine_id, "cloud_vision")


class RubyBoxFilter(unittest.TestCase):
    """Unofficial size+position filter. Not hiragana-line drop."""

    def test_narrow_word_to_the_right_is_ruby(self) -> None:
        body = {"text": "雛子", "x": 100, "y": 100, "w": 120, "h": 200}
        ruby = {"text": "ひなこ", "x": 230, "y": 110, "w": 40, "h": 160}
        words = [ruby, body]
        self.assertTrue(ruby_boxes.is_ruby_word(ruby, words))
        self.assertFalse(ruby_boxes.is_ruby_word(body, words))
        kept, dropped = ruby_boxes.filter_words(words)
        self.assertEqual(dropped, ["ひなこ"])
        self.assertEqual(kept, "雛子")

    def test_same_column_punctuation_not_ruby(self) -> None:
        # Vertical stack: comma is above the next glyph (smaller y), same width.
        comma = {"text": "、", "x": 100, "y": 100, "w": 120, "h": 40}
        te = {"text": "て", "x": 100, "y": 150, "w": 120, "h": 100}
        words = [comma, te]
        self.assertFalse(ruby_boxes.is_ruby_word(comma, words))
        kept, dropped = ruby_boxes.filter_words(words)
        self.assertEqual(dropped, [])
        self.assertEqual(kept, "、て")

    def test_wide_hiragana_body_is_kept(self) -> None:
        # Proves the filter is geometry, not "drop hiragana-only lines".
        hira = {"text": "だいじょうぶ", "x": 80, "y": 40, "w": 70, "h": 400}
        q = {"text": "?", "x": 80, "y": 450, "w": 68, "h": 60}
        words = [hira, q]
        kept, dropped = ruby_boxes.filter_words(words)
        self.assertEqual(dropped, [])
        self.assertIn("だいじょうぶ", kept)

    def test_committed_dump_is_44_of_44_and_not_the_official_cer(self) -> None:
        boxes_path = TOOL_DIR / "results" / "cloud_vision_boxes.json"
        engines_csv = (TOOL_DIR / "results" / "engines.csv").read_text(encoding="utf-8")
        self.assertIn("0.445283", engines_csv)
        self.assertIn("44.53", engines_csv)
        data = ruby_boxes.load_boxes(boxes_path)
        crops = data["crops"]
        self.assertEqual(len(crops), 44)
        for cid, crop in crops.items():
            self.assertTrue(crop["raw_text"], cid)
            self.assertTrue(crop["words"], cid)
            kept, _dropped = ruby_boxes.filter_words(crop["words"])
            self.assertIsInstance(kept, str)
        # Official raw CER against committed predictions file (not this filter).
        pred = json.loads(
            (TOOL_DIR / "results" / "predictions_cloud_vision.json").read_text(
                encoding="utf-8"
            )
        )["predictions"]
        self.assertEqual(len(pred), 44)
        self.assertEqual(set(pred), set(crops))
        for cid, crop in crops.items():
            self.assertEqual(pred[cid], crop["raw_text"], cid)

    def test_variant_json_matches_filter_on_committed_boxes(self) -> None:
        boxes = ruby_boxes.load_boxes(TOOL_DIR / "results" / "cloud_vision_boxes.json")
        variant = json.loads(
            (TOOL_DIR / "results" / "cloud_vision_ruby_filter.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertTrue(variant["unofficial"])
        self.assertEqual(variant["n_ok"], 44)
        self.assertEqual(variant["n_crops"], 44)
        self.assertEqual(variant["edits"], 113)
        self.assertEqual(variant["gt_chars"], 530)
        self.assertEqual(variant["cer_corpus_pct"], "21.32")
        for cid, crop in boxes["crops"].items():
            kept, dropped = ruby_boxes.filter_words(crop["words"])
            self.assertEqual(variant["predictions"][cid], kept, cid)
            self.assertEqual(variant["dropped"][cid], dropped, cid)


if __name__ == "__main__":
    unittest.main(verbosity=2)
