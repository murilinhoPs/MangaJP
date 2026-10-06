# MangaJP Study

A personal, Android-first Flutter app for learning Japanese vocabulary **from the manga you are actually reading**.

Its goal is to **help you read a manga in Japanese while learning the words and kanji you don't know yet**. Instead of stopping to look things up somewhere else, you look them up from the page itself, keep them, and review them until reading gets easier.

You share (or import) a manga page, crop a speech bubble, and the app reads the Japanese text with OCR. Tap any word to see its dictionary form and meaning, save it to your notebook (**Caderno**), and turn it into a spaced-repetition flashcard. Every word keeps a link back to the sentence and page where you found it.

## Why this exists

Reading raw manga is one of the most motivating ways to learn Japanese, but the lookup loop is slow: the text is vertical, stylized, full of kanji you can't type, and verbs are conjugated so they don't match a dictionary headword. Words you look up are then easy to forget, because they end up in a separate flashcard app with no memory of where they came from.

MangaJP Study closes that loop in one place:

1. **Get the text out of the image** without typing — crop the bubble and OCR it with a manga-specific model.
2. **Look the word up correctly** — deinflect conjugated forms (食べた → 食べる) and match them against a local JMdict, which shows the reading of words written in kanji you can't read yet.
3. **Decide what to do with it** — save it, learn it, mark it as known, or ignore it.
4. **Remember it** — review learned words with an SM-2 scheduler: the card front shows the word as written (in kanji when it has them), and the back reveals the reading and meaning, with the original manga sentence as context.

It is a **single-user, local-first tool** built for the author's own study routine: no accounts, no server, no sync. All data lives in an on-device SQLite database. The UI is in Brazilian Portuguese and the study day follows the `America/Sao_Paulo` time zone.

## How it works

```text
Share / import image → crop bubble → OCR (manga-ocr) → page text
      → tap a word → deinflect + JMdict lookup → Salvar → Caderno
      → Aprender → flashcard (sm2-jr@1) → /review
```

| Step | Screen | What happens |
| --- | --- | --- |
| Capture | `/capture` | Share an image to MangaJP (Android / iOS) or use Home → **Galeria**. Draw one or more crop rectangles and confirm. |
| OCR | — | Each crop is sent to the local manga-ocr sidecar; the recognized text is stored with the crop. |
| Read | `/pages/:id` | Shows the page's OCR text. Tapping a form deinflects it and shows the JMdict gloss (highest `forms.priority` wins on ties). |
| Save | lookup sheet | **Salvar** adds the word to the Caderno in the `saved` state, linked to the crop it came from. No flashcard yet. |
| Notebook | `/notebook` | Lists every word you have touched, newest first, with lemma/reading search and a state filter. |
| Word detail | `/notebook/word/:id` | Lemma, reading, state, gloss, first source sentence and a link to its page. Actions: **Aprender**, **Conhecido**, **Ignorar**, **Remover card**, **Remover do Caderno**. |
| Review | `/review` | One due card at a time: front is the lemma, **Revelar** shows reading + gloss, then rate **Again / Hard / Good / Easy**. |
| Home | `/home` | The **Revisar** block shows how many cards are due and **Novos hoje** (`N de 15`). |

### Word states

| State | Meaning | Flashcard |
| --- | --- | --- |
| `saved` | Collected while reading, not studying yet | none |
| `learning` | **Aprender** — actively studying | created with the initial `sm2-jr@1` state |
| `known` | **Conhecido** — already know it | kept but suspended |
| `ignored` | **Ignorar** — not worth studying | kept but suspended |

**Remover card** deletes only the flashcard and its review history (the word goes back to `saved`). **Remover do Caderno** deletes the word and everything attached to it, but keeps the captured pages and crops.

### Review rules

- The **study day** rolls over at **04:00 America/Sao_Paulo**.
- Queue order: learning / relearning, then review, then new cards; oldest `due_at` first.
- At most **15 new cards per study day** (`new_per_day`, no settings screen yet).
- Only the **first answer** of a card in a study day updates its schedule. Later answers in the same day are logged as drills (`is_drill=1`).
- **Again / Hard** send the card to the back of the current session; **Good / Easy** remove it from the session.

## Project status

The core study loop (M1) is implemented end to end. Still stubs: the pages list (`/pages`, Home → **Capturas recentes**), the deck screen (`/deck`), and settings (`/settings`). OCR requires the local Python sidecar to be running; there is no on-device OCR yet. Kanji are learned through the words that contain them: the lookup sheet, the Caderno, the word detail, and the review card all show the word in its kanji form (when it has one) together with its kana reading and meaning. What is still missing is per-character information (the meaning and on/kun readings of each kanji on its own): the KANJIDIC2 `kanji` table is baked into `jmdict.sqlite`, but no screen uses it yet.

See [Milestone history](#milestone-history) for the detailed behavior of each step.

## Key technical decisions

- **OCR: manga-ocr as a local sidecar.** ML Kit, Google Cloud Vision, and manga-ocr were scored on 44 hand-transcribed manga crops (M0.3 bake-off). manga-ocr had the lowest character error rate (**20.75%**, vs. Cloud Vision 44.53% and ML Kit 95.47%), so it is the working default. It runs as a Python HTTP service (`tools/manga_ocr_sidecar/`) instead of embedding torch in the app. None of the engines hit the 10% target, so the OCR choice (Q-B1) is still open. Details: [`docs/m0.3-cer-bakeoff.md`](docs/m0.3-cer-bakeoff.md).
- **Dictionary: local JMdict.** A read-only `jmdict.sqlite` (plus optional KANJIDIC2) is baked by `tools/build_jmdict_sqlite/` and shipped as an asset, so lookups work offline.
- **Deinflection: Yomitan port.** `lib/core/deinflect/` is a pure Dart port of Yomitan's Japanese transforms, which is why the project is **GPL-3.0**.
- **SRS: `sm2-jr@1`.** `lib/core/srs/` is a pure Dart port of the SM-2 implementation in the `japanese-reader` project (`sm2.clj`), verified by golden tests ported from its Clojure test suite.
- **Storage: Drift (SQLite)** for pages, crops, words, word states, cards, SRS state, and review logs.

## Tech stack

Flutter / Dart, Riverpod (codegen), go_router (typed routes), Drift, freezed / json_serializable, `receive_sharing_intent` (share target), `image_picker` + `image` (crop). Python tooling for the dictionary build, OCR sidecar, and OCR bake-off.

## Project layout

Feature-first + MVVM (PRD §12.2).

| Path | Contents |
| --- | --- |
| `lib/core/` | `router`, `theme`, `widgets`, `utils`, `database` (Drift tables + DAOs), `srs` (`sm2-jr@1`), `deinflect` (Yomitan port) |
| `lib/features/` | `home`, `capture`, `ocr`, `dictionary`, `pages`, `words`, `notebook`, `flashcards`, `review`, `settings` |
| `tools/build_jmdict_sqlite/` | Builds `assets/dict/jmdict.sqlite` from JMdict / KANJIDIC2 |
| `tools/manga_ocr_sidecar/` | Local HTTP OCR service used by the app |
| `tools/cer_bakeoff/` | Reproducible OCR engine comparison (M0.3) |
| `docs/` | Design write-ups (OCR bake-off) |
| `scripts/` | Flutter / Android SDK bootstrap and Cloud Agents install |
| `test/` | Unit, golden, and widget tests mirroring `lib/` |

## Setup

Requires [Flutter stable](https://docs.flutter.dev/get-started/install) (developed on 3.47.x / Dart 3.13). Android APKs need an Android SDK (`compileSdk` 37, required by `receive_sharing_intent`). iOS builds need Xcode on macOS.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Regenerate after changing `@riverpod`, `@DriftDatabase` / DAOs, `@freezed`, or `@TypedGoRoute` types.

To use the full loop you also need the dictionary and the OCR sidecar:

1. Bake the dictionary — see [Dictionary](#dictionary-jmdictsqlite).
2. Start the OCR sidecar (reuses the bake-off venv, see `tools/cer_bakeoff/README.md`):

   ```bash
   source tools/cer_bakeoff/.venv/bin/activate
   python3 tools/manga_ocr_sidecar/serve.py
   ```

   The app POSTs crop PNG bytes to `http://127.0.0.1:8765/ocr`. Override with `--dart-define=MANGA_OCR_URL=...` if needed.

## Run on Android

```bash
flutter devices
flutter run
```

The app opens `/home`. Drift `onCreate` seeds `app_meta.hello = MangaJP M0.1`; Home reads it through a Riverpod codegen provider. Home **Galeria** pushes `/capture` (outside the tab shell). Sharing an image on Android or iOS also opens `/capture`. Confirming a crop runs the default manga-ocr sidecar, writes `crops.ocr_text`, and goes to `/pages/:id`. Tapping OCR text there looks up the lemma in the local JMdict (`assets/dict/jmdict.sqlite`). **Salvar** persists the chosen entry without creating a flashcard.

See `lib/features/capture/README.md` for AndroidManifest filters, the iOS Share Extension, the manga-ocr sidecar, and device steps. CI: `flutter test test/features/capture/ test/features/pages/`.

## Run on iOS

```bash
flutter devices
flutter run
```

Needs a Mac with Xcode. Bundle ID / display name match Android: `dev.murilinhops.mangajp` / **MangaJP**. Signing team and App Group `group.dev.murilinhops.mangajp` are configured in Xcode on first device run (see capture README).

## Run on Linux desktop

Linux is a **dev convenience** for the crop/gallery UI. There is no Linux share
target. Drift uses a Linux-only directory fallback (app-support → documents →
temp); Android and iOS keep Drift’s default documents path.

Dependencies (Ubuntu): `ninja-build`, `libgtk-3-dev`, `g++`.

```bash
flutter run -d linux
```

Then Home → **Galeria** → **Escolher da galeria** → pick an image → **Confirmar crop**. The app goes to `/pages/:id` with the persisted OCR text if `tools/manga_ocr_sidecar/serve.py` is running. `/capture` has no bottom tabs.

## Run on Chrome (Flutter web)

Web is a **dev convenience** for the crop/gallery UI in Cloud Agents / desktops without an emulator. There is no share target. `receive_sharing_intent` stays Android + iOS.

Drift uses `sqlite3.wasm` + `drift_worker.js` in `web/` (from the drift **2.35.1** release). JMdict lookup loads the same wasm module and opens `assets/dict/jmdict.sqlite` in memory.

```bash
flutter run -d chrome
```

Then Home → **Galeria** → **Escolher da galeria** → pick an image → **Confirmar crop**. The app goes to `/pages/:id` with the persisted OCR text if `tools/manga_ocr_sidecar/serve.py` is running (the sidecar sends CORS headers for the Chrome origin). `/capture` has no bottom tabs.

Override the sidecar URL with `--dart-define=MANGA_OCR_URL=http://127.0.0.1:8765` if needed.

## Dictionary (`jmdict.sqlite`)

Bake the read-only JMdict DB (PRD §9.2: `entries` / `forms` / `sense_pos` / `kanji`):

```bash
python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py \
  --output assets/dict/jmdict.sqlite \
  --with-kanji
```

The full DB is gitignored. The app copies `assets/dict/jmdict.sqlite` out of the Flutter bundle on first lookup (sqlite needs a real filesystem path). Fixture smoke (no download):

```bash
python3 tools/build_jmdict_sqlite/test_smoke.py
```

Details: `tools/build_jmdict_sqlite/README.md`.

## OCR CER bake-off (M0.3 / Q-B1)

Score ML Kit, Cloud Vision, and manga-ocr against the M0.2 kanji GT (44 crops). Glyph-as-drawn CER (no NFKC). Measured: **manga-ocr 20.75%**, **Cloud Vision 44.53%** (44/44). An unofficial Vision ruby-box filter (size+position) is **21.32%** and is not the official CER. ML Kit skips unless you pass a device dump.

```bash
python3 tools/cer_bakeoff/test_cer.py
python3 tools/cer_bakeoff/bakeoff.py --gt-dir tools/cer_bakeoff/gt
```

See `tools/cer_bakeoff/README.md` and `docs/m0.3-cer-bakeoff.md`.

## Checks

```bash
python3 tools/build_jmdict_sqlite/test_smoke.py
python3 tools/cer_bakeoff/test_cer.py
flutter analyze
flutter test
```

CI (GitHub Actions) runs the JMdict fixture smoke, the CER-protocol unit tests (no OCR models), then `build_runner`, `flutter analyze`, and `flutter test` on Ubuntu (no iOS compile job). `analysis_options.yaml` excludes generated `*.g.dart` / `*.freezed.dart` plus `android/**`, `ios/**`, `linux/**`, `web/**`, `lib/**/*_web.dart`, and `build/**`.

## Cloud Agents environment

Repo config is `.cursor/environment.json`. `install` runs `scripts/cloud-agent-install.sh`, which bootstraps Flutter stable + Android cmdline-tools/SDK (API 37/36, build-tools, NDK 28.2) when missing, then `flutter pub get` and `dart run build_runner build`.

After this is merged, start Cloud Agents on `main` (or this branch). Cursor uses `.cursor/environment.json` from the git revision the agent boots.

**Dashboard (one-time, if the Environment panel still asks to Save):**

1. Open the Cloud Agents environment for this repo.
2. Confirm **Install** is `./scripts/cloud-agent-install.sh` (no Start command).
3. Click **Save** so future agents boot from the tested snapshot/build instead of a blank VM.

Local equivalent (Ubuntu):

```bash
./scripts/bootstrap-flutter-android.sh
./scripts/cloud-agent-install.sh
flutter analyze && flutter test
flutter build apk --debug
```

Cloud VMs typically have no nested Android emulator even when KVM is present; `flutter build apk` is the reliable Android check. `flutter run` needs a device or emulator you attach yourself.

## Milestone history

M0 set up the foundation: app shell and routing (M0.1), OCR ground truth and engine bake-off (M0.2–M0.3), the JMdict build (M0.5), and the share/gallery crop UI (M0.8). M1 builds the study loop on top of it:

| Milestone | Behavior |
| --- | --- |
| **M1.1** | Share/import → `/capture` → ≥1 crop → manga-ocr sidecar → OCR text persisted in Drift. |
| **M1.2** | `/pages/:id` shows that `ocr_text`. |
| **M1.3** | Tapping a form on the page deinflects it and shows the local JMdict gloss (highest `forms.priority` when several entries match). |
| **M1.4** | **Salvar** on the lookup sheet writes `words` + `word_states=saved` + `crop_words` (no card). |
| **M1.5** | `/notebook` lists every word with a `word_state` (saved / learning / known / ignored), newest `first_saved_at` first, with lemma/reading search and a state filter. |
| **M1.6** | Tapping a Caderno row opens `/notebook/word/:id` (lemma, reading, state, JMdict gloss by seq, first crop sentence + page link). |
| **M1.7** | **Aprender** sets `word_states=learning` and creates `cards` + `card_srs` with the golden `sm2-jr@1` initial state. No duplicate and no SRS reset if a card already exists. |
| **M1.8** | **Conhecido** / **Ignorar** set `word_states` to `known` / `ignored` and, when a card exists, `cards.suspend_reason` to the same value. No card create/delete, no SRS rewrite; the word stays in the Caderno. |
| **M1.9** | **Remover card** asks for confirmation; confirm deletes `cards` + `card_srs` + that card's `review_logs` and sets `word_states=saved`. The word stays in the Caderno. Cancel is a no-op. Without a card, nothing is deleted or created. |
| **M1.10** | `/review` shows one due, unsuspended card (learning/relearning, then review, then new; oldest `card_srs.due_at` first). Front is the lemma; **Revelar** shows reading + JMdict gloss. Again / Hard / Good / Easy write `review_logs` (rating 1/2/3/4, quality 0/3/4/5, `engine_id` `sm2-jr@1`) and, on the first answer of that card in the study day, update `card_srs` in the same transaction. |
| **M1.11** | The study day rolls at 04:00 America/Sao_Paulo. Later answers of the same card that day write `is_drill=1` and don't change `card_srs`. Again / Hard go to the back of the in-memory session; Good / Easy leave it. `word_state` stays `learning`. |
| **M1.12** | At most 15 new (`neu`) cards per study day (`new_per_day` constant). A `neu` card counts on its first non-drill answer; leftover `neu` cards wait for the next 04:00. Due learning / relearning / review cards still enter, and a `neu` card already in the session (Again/Hard) stays. |
| **M1.13** | Home **Revisar** shows due cards (learning / relearning / review that would enter the queue now) and **Novos hoje** (`N de 15`). Tap opens `/review`. The block stays visible at `0` / `0 de 15`. |
| **M1.14** | **Remover do Caderno** asks for confirmation (a second one when the word has a card) and deletes the word, `word_states`, `crop_words`, and, if present, `cards` + `card_srs` + that card's `review_logs`. Crops and pages stay. Cancel on either dialog is a no-op. |

## License

**GPL-3.0**, required by the Yomitan-derived deinflector (Q-B3). JMdict and KANJIDIC2 data are © EDRDG; see `tools/build_jmdict_sqlite/README.md` for attribution.
