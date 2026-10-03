# M0.3 CER bake-off

Reproducible CER harness for PRD §18 M0 / §20.1 **Q-B1** (which OCR engine?).
Reads the M0.2 GT package (`manifest-kanji.csv` + `crops/*.png`) and scores:

| Engine id | Implementation | Typical Linux Cloud Agent |
| --- | --- | --- |
| `mlkit_ja` | ML Kit Japanese (`TextRecognition` + bundled `com.google.mlkit:text-recognition-japanese`). Device dump via `tools/cer_bakeoff/mlkit_harness/` + `--predictions`. | Replay `results/predictions_mlkit_ja.json` (measured **95.47%**, 506/530, 44/44). Live engine is Android/iOS only. |
| `cloud_vision` | Cloud Vision `DOCUMENT_TEXT_DETECTION`, `languageHints: ["ja"]` | This corpus: **44.53%** (236/530), 44/44. |
| `manga_ocr` | [kha-white/manga-ocr](https://github.com/kha-white/manga-ocr) `MangaOcr()`, model `kha-white/manga-ocr-base` | Runnable on Linux CPU. This corpus: **20.75%** (110/530), 44/44. |

Q-B1 write-up (measured numbers + recommendation): [`docs/m0.3-cer-bakeoff.md`](../../docs/m0.3-cer-bakeoff.md). Committed tables: `results/` (`manga_ocr` **20.75%**; `cloud_vision` **44.53%**; `mlkit_ja` **95.47%**). Unofficial Vision ruby-box filter (size+position, not a rescore): `ruby_boxes.py` + `results/cloud_vision_boxes.json` → **21.32%** (113/530), 44/44.

## CER protocol (glyph-as-drawn)

- Metric: **Levenshtein** (insert/delete/substitute = 1) / **GT length**, Unicode **code points**.
- Headline number: **corpus CER** = Σ edits / Σ GT chars (successful crops). Also report macro mean of per-crop CER.
- **No** NFKC, kana folding, or ASCII↔fullwidth digit folding. `1` ≠ `１`, `よぉ` ≠ `よお`, `…` ≠ `...`, `―` ≠ `-`.
- Strip **whitespace only** (`str.isspace()`, including newlines and U+3000) on both GT and OCR. GT texts are never rewritten on disk.

manga-ocr’s own `post_process` (whitespace join, `…`→`...`, `jaconv.h2z` ascii/digit) is **engine behavior** and is scored as-is.

Hiragana CSV from M0.2 is out of scope. Do not change `gt_text`. Match `crop_id` **exactly** (`page_6.b1`, `page_6.1_b1`, …).

Skipped engines are recorded as `SKIPPED (reason)` — this tool will not invent a CER %.

## GT package

Not in git (manga page crops). Unzip the M0.2 attachment:

```bash
unzip mangajp-m0.2-gt.zip -d tools/cer_bakeoff/gt
# expects tools/cer_bakeoff/gt/manifest-kanji.csv and tools/cer_bakeoff/gt/crops/*.png
```

## Setup (manga-ocr on Linux CPU)

```bash
python3 -m venv tools/cer_bakeoff/.venv
source tools/cer_bakeoff/.venv/bin/activate
pip install -U pip
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install -r tools/cer_bakeoff/requirements.txt
```

First `MangaOcr()` download is ~400 MB (`kha-white/manga-ocr-base` via HuggingFace). Optional:

```bash
export HF_HOME="$PWD/tools/cer_bakeoff/.cache/hf"
```

## Run

```bash
python3 tools/cer_bakeoff/bakeoff.py \
  --gt-dir tools/cer_bakeoff/gt \
  --out-dir tools/cer_bakeoff/results
```

Subset / replay:

```bash
# manga-ocr only
python3 tools/cer_bakeoff/bakeoff.py --gt-dir tools/cer_bakeoff/gt --engines manga_ocr

# Cloud Vision when you have a key
CLOUD_VISION_API_KEY=... python3 tools/cer_bakeoff/bakeoff.py --gt-dir tools/cer_bakeoff/gt --engines cloud_vision

# ML Kit (or any engine) from a device dump
python3 tools/cer_bakeoff/bakeoff.py --gt-dir tools/cer_bakeoff/gt \
  --engines mlkit_ja --predictions mlkit_ja=path/to/mlkit_predictions.json
```

`GOOGLE_APPLICATION_CREDENTIALS` (service account JSON) also works for Vision if `google-auth` is installed; otherwise an API key is enough.

Outputs:

- `results/engines.csv` — per-engine corpus/macro CER or SKIPPED
- `results/per_crop.csv` — per-crop GT, OCR, edits, CER
- `results/predictions_<engine>.json` — dump for replay
- `results/SUMMARY.md` — markdown tables
- `results/run_meta.json` — host / protocol

## ML Kit device dump

`google_mlkit_text_recognition` does not support Linux (or this repo’s `flutter run -d linux`). On Android/iOS, for each `crops/{crop_id}.png`:

```dart
final recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
final result = await recognizer.processImage(InputImage.fromFilePath(path));
final text = result.text;
```

Write JSON (UTF-8):

```json
{
  "engine_id": "mlkit_ja",
  "predictions": {
    "page_0_b1": "recognized text…",
    "page_6.b1": "お母さん、"
  }
}
```

Do **not** NFKC the dump. Then `--predictions mlkit_ja=that.json`.

Device runner (Android emulator, bundled Japanese model, BitmapFactory PNG decode — not Dart zlib):

```bash
bash tools/cer_bakeoff/run_mlkit_emulator.sh \
  --gt-dir tools/cer_bakeoff/gt \
  --out tools/cer_bakeoff/results/predictions_mlkit_ja.json
```

Do not add `google_mlkit_text_recognition` to the app `pubspec.yaml` until Q-B1 picks an on-device engine — it is not a Linux plugin and would break the desktop runner. The bake-off APK is a separate project under `mlkit_harness/`.

## License

Harness code in this directory is GPL-3.0 like the rest of MangaJP.

[manga-ocr](https://github.com/kha-white/manga-ocr) is Apache-2.0 (Maciej Budyś / kha-white). It is **not vendored**; `pip install manga-ocr` pulls it plus `kha-white/manga-ocr-base`. Apache-2.0 is compatible with GPL-3.0. Keep this attribution if you distribute bake-off tooling that depends on it.

Cloud Vision / ML Kit are Google products; you need your own GCP / Android setup.

## Checks (no model)

```bash
python3 tools/cer_bakeoff/test_cer.py
```

CI runs the same command. It does not download weights or the GT zip.

## Unofficial Cloud Vision ruby-box filter

Not the official CER. Official `cloud_vision` stays **44.53%** (raw `fullTextAnnotation`). Word/paragraph boxes are in `results/cloud_vision_boxes.json` (no API key). Filter: narrower word to the **right** of a larger neighbor with y-overlap (`ruby_boxes.py`). Recompute against the kanji GT:

```bash
python3 tools/cer_bakeoff/ruby_boxes.py \
  --boxes tools/cer_bakeoff/results/cloud_vision_boxes.json \
  --gt-dir tools/cer_bakeoff/gt
```

Do not treat the 31.13% hiragana-line diagnostic in the Q-B1 doc as this number.
