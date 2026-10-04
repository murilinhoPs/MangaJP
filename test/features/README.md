# Feature tests

Capture path tests live in `test/features/capture/` (fixture PNG → `/capture` →
one rect → OCR → persisted `crops.ocr_text`). Default `OcrEngine` wiring
(`manga_ocr` sidecar) is in `test/features/ocr/`.
