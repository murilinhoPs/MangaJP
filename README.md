# MangaJP Study

Personal Android-first Flutter app for studying Japanese from manga (share/crop → OCR → JMdict → Caderno → SM-2). **M0.1 is scaffold only** — no OCR, SM-2 algorithm, JMdict import, or capture UI.

License: **GPL-3.0** (Q-B3 / Yomitan deinflect).

## Setup

Requires [Flutter stable](https://docs.flutter.dev/get-started/install) (developed on 3.47.x / Dart 3.13).

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

The app opens `/home`. The Home stub writes `app_meta.hello = MangaJP M0.1` through Drift and shows it via a Riverpod codegen provider.

## Checks

```bash
flutter analyze
flutter test
```

`analysis_options.yaml` excludes `*.g.dart` / `*.freezed.dart` (codegen) plus `android/**` and `build/**`.

## Layout

Feature-first + MVVM as in the PRD §12.2: `lib/core/{router,theme,widgets,utils,srs,deinflect,database}` and `lib/features/{home,capture,ocr,dictionary,words,flashcards,review,pages,notebook,settings}`.
