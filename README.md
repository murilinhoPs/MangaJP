# MangaJP Study

Personal Android-first Flutter app for studying Japanese from manga (share/crop → OCR → JMdict → Caderno → SM-2). **M0.1 is scaffold only** — no OCR, SM-2 algorithm, JMdict import, or capture UI.

License: **GPL-3.0** (Q-B3 / Yomitan deinflect).

## Setup

Requires [Flutter stable](https://docs.flutter.dev/get-started/install) (developed on 3.47.x / Dart 3.13) and, for APKs, an Android SDK (`compileSdk` 36).

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

The app opens `/home`. Drift `onCreate` seeds `app_meta.hello = MangaJP M0.1`; Home reads it through a Riverpod codegen provider.

## Checks

```bash
flutter analyze
flutter test
```

CI (GitHub Actions) runs `build_runner`, then `flutter analyze`, then `flutter test`. `analysis_options.yaml` excludes generated `*.g.dart` / `*.freezed.dart` plus `android/**` and `build/**`.

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
