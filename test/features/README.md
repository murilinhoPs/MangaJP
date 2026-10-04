# Feature tests

Capture path tests live in `test/features/capture/` (fixture PNG → `/capture` →
one rect → OCR → persist → `/pages/:id` shows `crops.ocr_text`). Page detail
reads Drift in `test/features/pages/`. Tap-to-lookup (deinflect + fixture
JMdict gloss / priority) is in `test/features/dictionary/` and the page-detail
widget tests. Save (words + word_states=saved + crop_words, no card) is in
`test/features/words/`. Default `OcrEngine` wiring (`manga_ocr` sidecar) is in
`test/features/ocr/`.
