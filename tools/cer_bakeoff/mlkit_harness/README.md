# ML Kit Japanese CER harness

Standalone Android Flutter app used **only** to dump `mlkit_ja` predictions for
[`../bakeoff.py`](../bakeoff.py). It is **not** wired into MangaJP `/capture`.

PNG crops are decoded with **Android `BitmapFactory`**, then recognized with the
bundled ML Kit Japanese model (`com.google.mlkit:text-recognition-japanese`,
not a Play Services download). Dart zlib is never used to decode crops.

```bash
# from repo root, with ANDROID_SDK_ROOT set and an AVD booted
bash tools/cer_bakeoff/run_mlkit_emulator.sh \
  --gt-dir tools/cer_bakeoff/gt \
  --out tools/cer_bakeoff/results/predictions_mlkit_ja.json
```

Replay (does not call Vision):

```bash
python3 tools/cer_bakeoff/bakeoff.py \
  --gt-dir tools/cer_bakeoff/gt \
  --engines mlkit_ja \
  --predictions mlkit_ja=tools/cer_bakeoff/results/predictions_mlkit_ja.json
```
