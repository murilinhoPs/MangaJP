#!/usr/bin/env python3
"""M0.3 CER bake-off: M0.2 GT crops × ML Kit / Cloud Vision / manga-ocr.

Does not rewrite GT texts. Compares glyph-as-drawn (whitespace strip only).
Never invents CER numbers for skipped engines.
"""

from __future__ import annotations

import argparse
import csv
import json
import platform
import sys
import traceback
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))

import cer as cer_mod  # noqa: E402
import engines as eng  # noqa: E402


@dataclass
class Crop:
    page_id: str
    crop_id: str
    gt_text: str
    image_path: Path


@dataclass
class CropResult:
    engine_id: str
    crop: Crop
    status: str  # ok | error
    ocr_text: str = ""
    edits: int | None = None
    gt_len: int | None = None
    cer: float | None = None
    error: str = ""


@dataclass
class EngineSummary:
    engine_id: str
    status: str  # ok | skipped | error
    skip_reason: str = ""
    version: str = ""
    n_crops: int = 0
    n_ok: int = 0
    n_error: int = 0
    gt_chars: int = 0
    edits: int = 0
    cer_corpus: float | None = None
    cer_macro: float | None = None
    crops: list[CropResult] = field(default_factory=list)


def load_manifest(gt_dir: Path) -> list[Crop]:
    gt_dir = gt_dir.resolve()
    manifest = gt_dir / "manifest-kanji.csv"
    crops_dir = gt_dir / "crops"
    if not manifest.is_file():
        raise FileNotFoundError(f"missing {manifest}")
    if not crops_dir.is_dir():
        raise FileNotFoundError(f"missing {crops_dir}")

    crops: list[Crop] = []
    with manifest.open(newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        required = {"page_id", "crop_id", "gt_text"}
        if reader.fieldnames is None or not required.issubset(set(reader.fieldnames)):
            raise ValueError(
                f"{manifest}: need columns {sorted(required)}, got {reader.fieldnames}"
            )
        seen: set[str] = set()
        for row in reader:
            crop_id = row["crop_id"]
            if crop_id in seen:
                raise ValueError(f"duplicate crop_id {crop_id!r}")
            seen.add(crop_id)
            image_path = crops_dir / f"{crop_id}.png"
            if not image_path.is_file():
                raise FileNotFoundError(
                    f"crop PNG missing for crop_id={crop_id!r}: expected {image_path}"
                )
            crops.append(
                Crop(
                    page_id=row["page_id"],
                    crop_id=crop_id,
                    gt_text=row["gt_text"],
                    image_path=image_path,
                )
            )
    if not crops:
        raise ValueError(f"{manifest}: no rows")
    return crops


def run_engine(engine: eng.OcrEngine, crops: list[Crop]) -> EngineSummary:
    info = engine.info()
    summary = EngineSummary(
        engine_id=info.engine_id,
        status="skipped" if info.status == "skipped" else "ok",
        skip_reason=info.skip_reason,
        version=info.version,
        n_crops=len(crops),
    )
    if info.status == "skipped":
        print(f"== {info.engine_id}: {info.skip_reason}", flush=True)
        return summary

    print(f"== {info.engine_id}: loading", flush=True)
    try:
        engine.prepare()
        info = engine.info()
        summary.version = info.version
    except eng.EngineUnavailable as exc:
        summary.status = "skipped"
        summary.skip_reason = str(exc)
        print(f"== {info.engine_id}: {exc}", flush=True)
        return summary
    except Exception as exc:  # noqa: BLE001 — engine load failure is a result row
        summary.status = "error"
        summary.skip_reason = f"engine failed to load: {exc}"
        print(f"== {info.engine_id}: LOAD ERROR {exc}", flush=True)
        traceback.print_exc()
        return summary

    cer_sum = 0.0
    for i, crop in enumerate(crops, start=1):
        print(f"   [{i}/{len(crops)}] {crop.crop_id}", flush=True)
        try:
            hyp = engine.recognize(crop.image_path)
            scored = cer_mod.score(crop.gt_text, hyp)
            row = CropResult(
                engine_id=info.engine_id,
                crop=crop,
                status="ok",
                ocr_text=hyp,
                edits=scored.edits,
                gt_len=scored.gt_len,
                cer=scored.cer,
            )
            summary.n_ok += 1
            summary.gt_chars += scored.gt_len
            summary.edits += scored.edits
            cer_sum += scored.cer
        except Exception as exc:  # noqa: BLE001
            row = CropResult(
                engine_id=info.engine_id,
                crop=crop,
                status="error",
                error=f"{type(exc).__name__}: {exc}",
            )
            summary.n_error += 1
            print(f"      ERROR {exc}", flush=True)
        summary.crops.append(row)

    if summary.n_ok == 0:
        summary.status = "error"
        summary.skip_reason = summary.skip_reason or "all crops failed"
        return summary
    summary.cer_corpus = summary.edits / summary.gt_chars if summary.gt_chars else None
    summary.cer_macro = cer_sum / summary.n_ok
    return summary


def _fmt_pct(cer: float | None) -> str:
    if cer is None:
        return ""
    return f"{cer * 100:.2f}"


def write_outputs(
    out_dir: Path,
    summaries: list[EngineSummary],
    *,
    gt_dir: Path,
    argv: list[str],
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    per_crop = out_dir / "per_crop.csv"
    with per_crop.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(
            [
                "engine_id",
                "page_id",
                "crop_id",
                "status",
                "gt_text",
                "ocr_text",
                "gt_len",
                "edits",
                "cer",
                "cer_pct",
                "error",
            ]
        )
        for summary in summaries:
            if summary.status == "skipped":
                continue
            for row in summary.crops:
                writer.writerow(
                    [
                        row.engine_id,
                        row.crop.page_id,
                        row.crop.crop_id,
                        row.status,
                        row.crop.gt_text,
                        row.ocr_text,
                        "" if row.gt_len is None else row.gt_len,
                        "" if row.edits is None else row.edits,
                        "" if row.cer is None else f"{row.cer:.6f}",
                        "" if row.cer is None else _fmt_pct(row.cer),
                        row.error,
                    ]
                )

    engines_csv = out_dir / "engines.csv"
    with engines_csv.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(
            [
                "engine_id",
                "status",
                "n_crops",
                "n_ok",
                "n_error",
                "gt_chars",
                "edits",
                "cer_corpus",
                "cer_corpus_pct",
                "cer_macro",
                "cer_macro_pct",
                "version",
                "skip_reason",
            ]
        )
        for summary in summaries:
            writer.writerow(
                [
                    summary.engine_id,
                    summary.status,
                    summary.n_crops,
                    summary.n_ok,
                    summary.n_error,
                    summary.gt_chars if summary.status != "skipped" else "",
                    summary.edits if summary.status != "skipped" else "",
                    "" if summary.cer_corpus is None else f"{summary.cer_corpus:.6f}",
                    _fmt_pct(summary.cer_corpus),
                    "" if summary.cer_macro is None else f"{summary.cer_macro:.6f}",
                    _fmt_pct(summary.cer_macro),
                    summary.version,
                    summary.skip_reason,
                ]
            )

    for summary in summaries:
        if summary.status == "skipped":
            continue
        pred_path = out_dir / f"predictions_{summary.engine_id}.json"
        pred_path.write_text(
            json.dumps(
                {
                    "engine_id": summary.engine_id,
                    "version": summary.version,
                    "predictions": {
                        row.crop.crop_id: row.ocr_text
                        for row in summary.crops
                        if row.status == "ok"
                    },
                    "errors": {
                        row.crop.crop_id: row.error
                        for row in summary.crops
                        if row.status == "error"
                    },
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    meta = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "gt_dir": str(gt_dir),
        "argv": argv,
        "python": sys.version,
        "platform": platform.platform(),
        "machine": platform.machine(),
        "cer_protocol": {
            "metric": "Levenshtein / len(GT)",
            "unit": "Unicode code points",
            "normalize": "strip whitespace (str.isspace) only; no NFKC, no kana fold, no 1↔１",
        },
    }
    (out_dir / "run_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    (out_dir / "SUMMARY.md").write_text(
        render_summary_md(summaries, gt_dir=gt_dir, generated_at=meta["generated_at"]),
        encoding="utf-8",
    )


def render_summary_md(
    summaries: list[EngineSummary],
    *,
    gt_dir: Path,
    generated_at: str,
) -> str:
    lines: list[str] = [
        "# M0.3 CER bake-off results",
        "",
        f"Generated: `{generated_at}`",
        f"GT: `{gt_dir}` (`manifest-kanji.csv`, glyph-as-drawn).",
        "",
        "Protocol: OCR vs GT **code points as drawn**. Strip whitespace only. "
        "No NFKC, no kana folding, no ASCII/fullwidth digit folding (`1` ≠ `１`, `よぉ` ≠ `よお`).",
        "",
        "Headline CER is **corpus** = Σ edits / Σ GT length (successful crops only). "
        "Skipped engines have **no** invented numbers.",
        "",
        "| Engine | Status | Corpus CER | Macro CER | Crops ok | GT chars | Edits | Notes |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for s in summaries:
        if s.status == "skipped":
            notes = s.skip_reason.replace("|", "/")
            lines.append(
                f"| `{s.engine_id}` | SKIPPED | — | — | — | — | — | {notes} |"
            )
            continue
        corpus = f"{s.cer_corpus * 100:.2f}%" if s.cer_corpus is not None else "—"
        macro = f"{s.cer_macro * 100:.2f}%" if s.cer_macro is not None else "—"
        notes = s.version or s.skip_reason
        notes = notes.replace("|", "/")
        lines.append(
            f"| `{s.engine_id}` | {s.status} | {corpus} | {macro} | "
            f"{s.n_ok}/{s.n_crops} | {s.gt_chars} | {s.edits} | {notes} |"
        )
    lines.extend(["", "## Per-crop (measured engines)", ""])
    for s in summaries:
        if s.status == "skipped":
            continue
        lines.append(f"### `{s.engine_id}`")
        lines.append("")
        lines.append("| crop_id | CER % | edits | gt_len | GT | OCR |")
        lines.append("| --- | ---: | ---: | ---: | --- | --- |")
        for row in s.crops:
            if row.status != "ok":
                err = row.error.replace("|", "/")
                lines.append(
                    f"| `{row.crop.crop_id}` | ERROR | — | — | {row.crop.gt_text} | {err} |"
                )
                continue
            gt = row.crop.gt_text.replace("|", "\\|")
            hyp = row.ocr_text.replace("|", "\\|")
            lines.append(
                f"| `{row.crop.crop_id}` | {_fmt_pct(row.cer)} | {row.edits} | "
                f"{row.gt_len} | {gt} | {hyp} |"
            )
        lines.append("")
    lines.append("See `per_crop.csv` / `engines.csv` for the machine-readable table.")
    lines.append("")
    return "\n".join(lines)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--gt-dir",
        type=Path,
        required=True,
        help="Unzipped M0.2 GT dir (manifest-kanji.csv + crops/*.png)",
    )
    p.add_argument(
        "--out-dir",
        type=Path,
        default=TOOL_DIR / "results",
        help="CSV + markdown output directory",
    )
    p.add_argument(
        "--engines",
        default=",".join(eng.ENGINE_IDS),
        help=f"Comma-separated subset of {','.join(eng.ENGINE_IDS)}",
    )
    p.add_argument(
        "--predictions",
        action="append",
        default=[],
        metavar="ENGINE=PATH",
        help="Replay JSON dump instead of a live engine (repeatable)",
    )
    p.add_argument(
        "--cloud-vision-api-key",
        default=None,
        help="Optional Vision API key (else env CLOUD_VISION_API_KEY)",
    )
    p.add_argument(
        "--manga-ocr-model",
        default="kha-white/manga-ocr-base",
        help="HuggingFace id or local path for manga-ocr",
    )
    p.add_argument("--limit", type=int, default=None, help="First N crops only (debug)")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    wanted = [e.strip() for e in args.engines.split(",") if e.strip()]
    unknown = [e for e in wanted if e not in eng.ENGINE_IDS]
    if unknown:
        raise SystemExit(f"unknown engine(s) {unknown}; choose from {eng.ENGINE_IDS}")
    preds = eng.parse_predictions_args(args.predictions)
    crops = load_manifest(args.gt_dir)
    if args.limit is not None:
        crops = crops[: args.limit]
    print(f"GT crops: {len(crops)} from {args.gt_dir}", flush=True)
    engine_list = eng.build_engines(
        wanted,
        preds,
        cloud_vision_api_key=args.cloud_vision_api_key,
        manga_ocr_model=args.manga_ocr_model,
    )
    summaries = [run_engine(engine, crops) for engine in engine_list]
    write_outputs(args.out_dir, summaries, gt_dir=args.gt_dir, argv=sys.argv)
    print(f"Wrote {args.out_dir}", flush=True)
    for s in summaries:
        if s.status == "skipped":
            print(f"  {s.engine_id}: SKIPPED", flush=True)
        elif s.cer_corpus is None:
            print(f"  {s.engine_id}: {s.status}", flush=True)
        else:
            print(
                f"  {s.engine_id}: corpus CER {s.cer_corpus * 100:.2f}% "
                f"({s.edits}/{s.gt_chars})",
                flush=True,
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
