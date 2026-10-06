# Feature tests

Capture path tests live in `test/features/capture/` (fixture PNG → `/capture` →
one rect → OCR → persist → `/pages/:id` shows `crops.ocr_text`). Page detail
reads Drift in `test/features/pages/`. Tap-to-lookup (deinflect + fixture
JMdict gloss / priority) is in `test/features/dictionary/` and the page-detail
widget tests. Save (words + word_states=saved + crop_words, no card) is in
`test/features/words/`. Caderno list / search / state filter, and tapping a row
to `/notebook/word/:id` (fixture JMdict gloss by seq, first crop sentence, page
link), **Aprender** (word_states=learning + one card / card_srs, no SRS reset
on a second tap), **Conhecido** / **Ignorar** (word_states + optional
`cards.suspend_reason`, card / SRS / Caderno list kept), **Remover card**
(confirm deletes card + SRS and returns to saved; cancel is a no-op; no card
does not delete the word), and **Remover do Caderno** (one confirm without a
card, two in sequence with a card; confirm deletes the word and dependents;
cancel on either dialog is a no-op; crops/pages stay), is in
`test/features/notebook/` plus `test/features/flashcards/` and
`test/features/words/`. `/review` (due
queue, study-day at 04:00 America/Sao_Paulo, first answer vs drill, session
Again/Hard requeue, reveal, Again/Hard/Good/Easy → `review_logs` +
`sm2-jr@1` schedule, `new_per_day=15`) is in `test/features/review/`. Home
**Revisar** (due + novos hoje, tap → `/review`, 04:00 clock), **Capturas
recentes**, and **Galeria** (mocked `image_picker` → `/capture` crop; cancel
stays on Home) are in `test/features/home/`. Default `OcrEngine` wiring (`manga_ocr`
sidecar) is in `test/features/ocr/`.
