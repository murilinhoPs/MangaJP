# MangaJP Study

Personal Android-first Flutter app for studying Japanese from manga (share/crop → OCR → JMdict → Caderno → SM-2). Domain SM-2 (`sm2-jr@1`, a port of japanese-reader `sm2.clj`) lives in `lib/core/srs/`. Japanese deinflection (`lib/core/deinflect/`) is a GPL port of Yomitan transforms. **M1.1** is share/import → `/capture` → ≥1 crop → manga-ocr sidecar → persisted Drift text. **M1.2** opens `/pages/:id` with that `ocr_text`. **M1.3** taps a form on that page, deinflects it, and shows the local JMdict gloss (highest `forms.priority` when several entries match). **M1.4** Save on that sheet writes `words` + `word_states=saved` + `crop_words` (no card, no Caderno). **M1.5** `/notebook` lists every word with a `word_state` (saved / learning / known / ignored), newest `first_saved_at` first, with lemma/reading search and a state filter. **M1.6** taps a Caderno row to open `/notebook/word/:id` (lemma, reading, state, JMdict gloss by seq, first crop sentence + page link). **M1.7** **Aprender** on that detail sets `word_states=learning` and creates a `cards` + `card_srs` row with the golden `sm2-jr@1` initial state (no duplicate / no SRS reset if a card already exists). **M1.8** **Conhecido** / **Ignorar** on that detail set `word_states` to `known` / `ignored` and, when a card exists, `cards.suspend_reason` to the same value (no card create/delete, no SRS rewrite, word stays in the Caderno). **M1.9** **Remover card** on that detail asks for confirmation; confirm deletes `cards` + `card_srs` + that card's `review_logs` and sets `word_states=saved`. The word stays in the Caderno. Cancel is a no-op. No card → the word is not deleted and no card is created. **M1.10** `/review` shows one due unsuspended card (learning/relearning, then review, then new; oldest `card_srs.due_at` first). The front is the lemma; Revelar shows the reading and the JMdict gloss by seq. Again / Hard / Good / Easy write `review_logs` (rating 1/2/3/4, quality 0/3/4/5, `engine_id` `sm2-jr@1`) and, on the first answer of that card in the current study-day, update `card_srs` with the existing `schedule` in the same transaction. **M1.11** study-day rolls at 04:00 America/Sao_Paulo. A later answer of the same card on that study-day writes `is_drill=1` and does not change `card_srs`. Again / Hard go to the back of the in-memory session; Good / Easy leave it. `word_state` stays `learning`. **M1.12** `/review` takes at most 15 new (`neu`) cards per study-day (`new_per_day` constant, no settings screen). A `neu` card counts on its first non-drill answer that study-day; leftover `neu` stay out until the next 04:00 America/Sao_Paulo. Due learning / relearning / review still enter. A `neu` already in the session (Again/Hard) stays. **M1.13** Home **Revisar** shows due (learning / relearning / review that would enter the queue now) and **Novos hoje** (`N de 15`, `neu` already counted this study-day). Tap opens `/review`. The block stays with `0` / `0 de 15`. **M1.14** **Remover do Caderno** on `/notebook/word/:id` asks for confirmation (a second confirmation when the word has a card) and deletes the word, `word_states`, `crop_words`, and if a card exists `cards` + `card_srs` + that card's `review_logs`. Crops and pages stay. Cancel on either dialog is a no-op. **Remover card** (M1.9) is unchanged.

License: **GPL-3.0** (Q-B3 / Yomitan deinflect).

## Setup

Requires [Flutter stable](https://docs.flutter.dev/get-started/install) (developed on 3.47.x / Dart 3.13). Android APKs need an Android SDK (`compileSdk` 37, required by `receive_sharing_intent`). iOS builds need Xcode on macOS.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Regenerate after changing `@riverpod`, `@DriftDatabase` / DAOs, `@freezed`, or `@TypedGoRoute` types.

## Run on Android

```bash
flutter devices
flutter run
```

The app opens `/home`. Drift `onCreate` seeds `app_meta.hello = MangaJP M0.1`; Home reads it through a Riverpod codegen provider. Home **Galeria** pushes `/capture` (outside the tab shell). Sharing an image on Android or iOS also opens `/capture`. Confirming a crop runs the default manga-ocr sidecar, writes `crops.ocr_text`, and goes to `/pages/:id`. Tapping OCR text there looks up the lemma in the local JMdict (`assets/dict/jmdict.sqlite`). **Salvar** persists the chosen entry without creating a flashcard.

### Share + crop + OCR (M1.1)

See `lib/features/capture/README.md` for AndroidManifest filters, the iOS Share Extension, the manga-ocr sidecar, and device steps. Confirm crop navigates to `/pages/:id` with the persisted OCR text. CI: `flutter test test/features/capture/ test/features/pages/`.

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

## Layout

Feature-first + MVVM as in the PRD §12.2: `lib/core/{router,theme,widgets,utils,srs,deinflect,database}` and `lib/features/{home,capture,ocr,dictionary,words,flashcards,review,pages,notebook,settings}`.
