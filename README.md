# MangaJP Study

Personal Android-first Flutter app for studying Japanese from manga (share/crop → OCR → JMdict → Caderno → SM-2). Domain SM-2 (`sm2-jr@1`, a port of japanese-reader `sm2.clj`) lives in `lib/core/srs/`. **M0.8** is the share-intent + crop smoke (`/capture`, not a tab). OCR, Drift `pages`/`crops`, and deinflect rules are still later M0.

License: **GPL-3.0** (Q-B3 / Yomitan deinflect).

## Setup

Requires [Flutter stable](https://docs.flutter.dev/get-started/install) (developed on 3.47.x / Dart 3.13). Android APKs need an Android SDK (`compileSdk` 36). iOS builds need Xcode on macOS.

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

The app opens `/home`. Drift `onCreate` seeds `app_meta.hello = MangaJP M0.1`; Home reads it through a Riverpod codegen provider. Home **Galeria** pushes `/capture` (outside the tab shell). Sharing an image on Android or iOS also opens `/capture`.

### Share + crop (M0.8)

See `lib/features/capture/README.md` for AndroidManifest filters, the iOS Share Extension, and device steps (share from Photos, or gallery pick on `/capture`). Confirm crop prints `Crop PNG: N bytes` with N > 0. CI: `flutter test test/features/capture/`.

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

Then Home → **Galeria** → **Escolher da galeria** → pick an image → **Confirmar crop**. Expect `Crop PNG: N bytes` with N > 0. `/capture` has no bottom tabs.

## Dictionary (`jmdict.sqlite`)

Bake the read-only JMdict DB (PRD §9.2: `entries` / `forms` / `sense_pos` / `kanji`):

```bash
python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py \
  --output assets/dict/jmdict.sqlite \
  --with-kanji
```

The full DB is gitignored. Fixture smoke (no download):

```bash
python3 tools/build_jmdict_sqlite/test_smoke.py
```

Details: `tools/build_jmdict_sqlite/README.md`.

## OCR CER bake-off (M0.3 / Q-B1)

Score ML Kit, Cloud Vision, and manga-ocr against the M0.2 kanji GT (44 crops). Glyph-as-drawn CER (no NFKC). Linux can run **manga-ocr**; ML Kit and Cloud Vision skip unless you pass a device dump or GCP key.

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

CI (GitHub Actions) runs the JMdict fixture smoke, the CER-protocol unit tests (no OCR models), then `build_runner`, `flutter analyze`, and `flutter test` on Ubuntu (no iOS compile job). `analysis_options.yaml` excludes generated `*.g.dart` / `*.freezed.dart` plus `android/**`, `ios/**`, `linux/**`, and `build/**`.

## Cloud Agents environment

Repo config is `.cursor/environment.json`. `install` runs `scripts/cloud-agent-install.sh`, which bootstraps Flutter stable + Android cmdline-tools/SDK (API 36, build-tools, NDK 28.2) when missing, then `flutter pub get` and `dart run build_runner build`.

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
