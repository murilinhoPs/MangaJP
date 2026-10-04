# Feature tests

Capture path tests live in `test/features/capture/` (fixture PNG → `/capture` →
one rect → OCR → persist → `/pages/:id` shows `crops.ocr_text`). Page detail
reads Drift in `test/features/pages/`. Tap-to-lookup (deinflect + fixture
JMdict gloss / priority) is in `test/features/dictionary/` and the page-detail
widget tests. Save (words + word_states=saved + crop_words, no card) is in
`test/features/words/`. Caderno list / search / state filter, and tapping a row
to `/notebook/word/:id` (fixture JMdict gloss by seq, first crop sentence, page
link), and **Aprender** (word_states=learning + one card / card_srs, no SRS reset
on a second tap), is in
`test/features/notebook/` plus `test/features/flashcards/`. Default
`OcrEngine` wiring (`manga_ocr` sidecar) is in `test/features/ocr/`.
