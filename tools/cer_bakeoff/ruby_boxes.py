#!/usr/bin/env python3
"""Unofficial Cloud Vision furigana filter from word boxes (not official CER).

Helm: ruby is the *small* text sitting with the kanji. On this M0.2 GT the
balloons are vertical columns, so that geometry is **narrower + to the right**
with overlapping y — not “drop hiragana-only lines” and not image-y “above”
(that is how vertical type stacks; punctuation would be dropped).

Official Cloud Vision CER remains raw `fullTextAnnotation.text` (44.53%).
This module only reads a committed boxes dump so testers can recompute
without an API key.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import cer as cer_mod  # noqa: E402

# Width ratio sits in the observed gap: ruby/body 0.24–0.44, body/body ≥ 0.51.
RUBY_MAX_WIDTH_RATIO = 0.5
# Candidate must start at least this far across the body box (not same column).
RUBY_MIN_RIGHT_SHIFT = 0.4
# Vertical alignment with the body word (fraction of the candidate height).
RUBY_MIN_Y_OVERLAP = 0.3

FILTER_ID = "cloud_vision_ruby_boxes"
FILTER_RULE = (
    "Drop a word W if some other word B in the same crop has "
    f"W.w ≤ {RUBY_MAX_WIDTH_RATIO}×B.w, "
    f"W.x ≥ B.x + {RUBY_MIN_RIGHT_SHIFT}×B.w (to the right, not same column), "
    f"and y-overlap(W,B) ≥ {RUBY_MIN_Y_OVERLAP}×W.h. "
    "Rejoin remaining words in Vision order. Glyph-as-drawn CER after."
)


def y_overlap(a: Mapping[str, Any], b: Mapping[str, Any]) -> int:
    a0 = int(a["y"])
    a1 = a0 + int(a["h"])
    b0 = int(b["y"])
    b1 = b0 + int(b["h"])
    return max(0, min(a1, b1) - max(a0, b0))


def is_ruby_word(word: Mapping[str, Any], others: Sequence[Mapping[str, Any]]) -> bool:
    """True if `word` is small text sitting to the right of a larger neighbor."""
    ww = int(word.get("w") or 0)
    wh = int(word.get("h") or 0)
    if ww <= 0 or wh <= 0:
        return False
    wx = int(word.get("x") or 0)
    for body in others:
        if body is word:
            continue
        bw = int(body.get("w") or 0)
        bh = int(body.get("h") or 0)
        if bw <= 0 or bh <= 0:
            continue
        if ww > RUBY_MAX_WIDTH_RATIO * bw:
            continue
        if y_overlap(word, body) < RUBY_MIN_Y_OVERLAP * wh:
            continue
        bx = int(body.get("x") or 0)
        if wx >= bx + RUBY_MIN_RIGHT_SHIFT * bw:
            return True
    return False


def filter_words(words: Sequence[Mapping[str, Any]]) -> tuple[str, list[str]]:
    """Return (kept text, dropped word texts) in original Vision order."""
    kept: list[str] = []
    dropped: list[str] = []
    for word in words:
        text = str(word.get("text") or "")
        if is_ruby_word(word, words):
            dropped.append(text)
        else:
            kept.append(text)
    return "".join(kept), dropped


@dataclass(frozen=True)
class CropVariant:
    crop_id: str
    raw_text: str
    filtered_text: str
    dropped: tuple[str, ...]
    edits: int
    gt_len: int
    cer: float
    gt_text: str


def load_boxes(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "crops" not in data:
        raise ValueError(f"{path}: expected object with 'crops'")
    return data


def variant_for_crop(
    crop_id: str, crop: Mapping[str, Any], gt_text: str
) -> CropVariant:
    words = list(crop.get("words") or [])
    filtered, dropped = filter_words(words)
    scored = cer_mod.score(gt_text, filtered)
    return CropVariant(
        crop_id=crop_id,
        raw_text=str(crop.get("raw_text") or ""),
        filtered_text=filtered,
        dropped=tuple(dropped),
        edits=scored.edits,
        gt_len=scored.gt_len,
        cer=scored.cer,
        gt_text=gt_text,
    )


def score_dump(
    boxes: Mapping[str, Any],
    gt_by_id: Mapping[str, str],
) -> list[CropVariant]:
    crops = boxes.get("crops") or {}
    missing = [cid for cid in gt_by_id if cid not in crops]
    if missing:
        raise KeyError(f"boxes dump missing crops: {missing[:8]}")
    extra_ok = True  # extra dump keys ignored
    del extra_ok
    return [variant_for_crop(cid, crops[cid], gt) for cid, gt in gt_by_id.items()]


def corpus(rows: Sequence[CropVariant]) -> tuple[int, int, int, int]:
    """n_ok, n_exact, edits, gt_chars. Empty filtered text still counts as ok."""
    n_ok = len(rows)
    n_exact = sum(1 for r in rows if r.edits == 0)
    edits = sum(r.edits for r in rows)
    gt_chars = sum(r.gt_len for r in rows)
    return n_ok, n_exact, edits, gt_chars


def load_gt_texts(gt_dir: Path) -> dict[str, str]:
    manifest = gt_dir / "manifest-kanji.csv"
    out: dict[str, str] = {}
    with manifest.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            out[row["crop_id"]] = row["gt_text"]
    if not out:
        raise ValueError(f"{manifest}: no rows")
    return out


def write_outputs(
    out_dir: Path,
    rows: Sequence[CropVariant],
    *,
    boxes_path: Path,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    n_ok, n_exact, edits, gt_chars = corpus(rows)
    n = len(rows)
    cer = edits / gt_chars if gt_chars else None
    try:
        boxes_rel = str(boxes_path.resolve().relative_to(TOOL_DIR.parent.parent))
    except ValueError:
        boxes_rel = boxes_path.name
    summary = {
        "filter_id": FILTER_ID,
        "unofficial": True,
        "rule": FILTER_RULE,
        "constants": {
            "RUBY_MAX_WIDTH_RATIO": RUBY_MAX_WIDTH_RATIO,
            "RUBY_MIN_RIGHT_SHIFT": RUBY_MIN_RIGHT_SHIFT,
            "RUBY_MIN_Y_OVERLAP": RUBY_MIN_Y_OVERLAP,
        },
        "boxes": boxes_rel,
        "n_crops": n,
        "n_ok": n_ok,
        "n_exact": n_exact,
        "n_error": 0,
        "gt_chars": gt_chars,
        "edits": edits,
        "cer_corpus": None if cer is None else round(cer, 6),
        "cer_corpus_pct": None if cer is None else f"{cer * 100:.2f}",
        "note": (
            "Not official Cloud Vision CER. Official is raw fullTextAnnotation "
            "(44.53% / 236/530). This filter is box size+position, not hiragana-line drop."
        ),
        "predictions": {r.crop_id: r.filtered_text for r in rows},
        "dropped": {r.crop_id: list(r.dropped) for r in rows},
        "raw_text": {r.crop_id: r.raw_text for r in rows},
    }
    (out_dir / "cloud_vision_ruby_filter.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    csv_path = out_dir / "cloud_vision_ruby_filter.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(
            [
                "crop_id",
                "status",
                "gt_text",
                "raw_text",
                "filtered_text",
                "dropped",
                "gt_len",
                "edits",
                "cer",
                "cer_pct",
            ]
        )
        for r in rows:
            writer.writerow(
                [
                    r.crop_id,
                    "ok",
                    r.gt_text,
                    r.raw_text,
                    r.filtered_text,
                    " | ".join(t.replace("\n", "\\n") for t in r.dropped),
                    r.gt_len,
                    r.edits,
                    f"{r.cer:.6f}",
                    f"{r.cer * 100:.2f}",
                ]
            )

    lines = [
        "# Unofficial Cloud Vision ruby-box filter",
        "",
        "Not the official bake-off CER. Official `cloud_vision` remains "
        "**44.53% (236/530)** from raw `fullTextAnnotation.text`.",
        "",
        FILTER_RULE,
        "",
        f"| Status | Crops | Exact | Edits | GT chars | Corpus CER |",
        f"| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    if n_ok != n:
        lines.append(
            f"| incomplete | {n_ok}/{n} | — | — | — | **no corpus CER** (not 44/44) |"
        )
    else:
        lines.append(
            f"| ok | {n_ok}/{n} | {n_exact}/{n_ok} | {edits} | {gt_chars} | "
            f"**{cer * 100:.2f}%** ({edits}/{gt_chars}) |"
        )
    lines.extend(
        [
            "",
            "Recompute: `python3 tools/cer_bakeoff/ruby_boxes.py "
            "--boxes tools/cer_bakeoff/results/cloud_vision_boxes.json "
            "--gt-dir <unzipped GT>`.",
            "",
            "| crop_id | CER % | edits | dropped | filtered |",
            "| --- | ---: | ---: | --- | --- |",
        ]
    )
    for r in rows:
        dropped = ", ".join(
            json.dumps(t, ensure_ascii=False) for t in r.dropped
        ) or "—"
        filt = r.filtered_text.replace("|", "\\|").replace("\n", " / ")
        lines.append(
            f"| `{r.crop_id}` | {r.cer * 100:.2f} | {r.edits} | {dropped} | {filt} |"
        )
    lines.append("")
    (out_dir / "cloud_vision_ruby_filter.md").write_text(
        "\n".join(lines), encoding="utf-8"
    )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--boxes",
        type=Path,
        default=TOOL_DIR / "results" / "cloud_vision_boxes.json",
        help="Committed Vision boxes dump (no API key)",
    )
    p.add_argument(
        "--gt-dir",
        type=Path,
        required=True,
        help="Unzipped M0.2 GT dir (manifest-kanji.csv)",
    )
    p.add_argument(
        "--out-dir",
        type=Path,
        default=TOOL_DIR / "results",
        help="Where to write unofficial csv/json/md",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    gt = load_gt_texts(args.gt_dir)
    boxes = load_boxes(args.boxes)
    rows = score_dump(boxes, gt)
    n_ok, n_exact, edits, gt_chars = corpus(rows)
    write_outputs(args.out_dir, rows, boxes_path=args.boxes)
    print(f"crops {n_ok}/{len(rows)} exact {n_exact}", flush=True)
    if n_ok != len(gt):
        print("NO corpus CER: not 44/44", flush=True)
        return 1
    print(
        f"unofficial ruby-box corpus CER {edits / gt_chars * 100:.2f}% "
        f"({edits}/{gt_chars})",
        flush=True,
    )
    print("official raw fullTextAnnotation is unchanged (44.53%)", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
