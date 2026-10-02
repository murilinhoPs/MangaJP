# Capture (M0.8)

Smoke path: **image → `/capture` crop UI → 1 rect → PNG bytes**. Capture is **not** a
bottom tab (PRD §11 / F2 / F3). OCR, Drift `pages`/`crops`, and dedupe are out of
scope here.

## Packages

| Package | Role |
|---------|------|
| `receive_sharing_intent` | Android `ACTION_SEND` / `SEND_MULTIPLE` image share target |
| `image_picker` | Gallery stub (Home **Galeria** → `/capture` → pick) |
| `image` | Decode + `copyCrop` + encode PNG (PRD §9.4) |

Crop UI is a Flutter `CustomPainter` rect (not `image_cropper`) so `flutter test`
can prove `bytes.length > 0` in CI.

## AndroidManifest (real device / emulator)

`android/app/src/main/AndroidManifest.xml`:

- `android:launchMode="singleTask"` on `MainActivity` so a warm share reuses the
  activity (`ShareIntentBinder` then `go('/capture', extra: image)`).
- Intent filters: `SEND` + `SEND_MULTIPLE` with `image/*`.
- `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"` for older `file://` shares.
  Android 13+ uses the system photo picker / content URIs (plugin copies to cache).

## Verify on emulator

```bash
flutter run
```

**Gallery (no share sheet):** Home → **Galeria** → `/capture` → **Escolher da
galeria** → pick any image → (optional) drag the rect / corners → **Confirmar
crop**. The screen must show `Crop PNG: N bytes (W×H)` with N > 0. Logcat:
`M0.8 crop PNG bytes.length=…`.

**Share:** in Photos / Files / a screenshot, **Share** → **MangaJP**. The app
opens `/capture` with the image (no Home hop, no Capture tab). Confirm crop as
above.

## Verify on Linux desktop

Share intent is Android-only. The crop UI is Flutter-only, so Linux is enough
to click through gallery → rect → bytes:

```bash
# Ubuntu: ninja-build libgtk-3-dev g++
flutter run -d linux
```

Home → **Galeria** → **Escolher da galeria** → pick an image → **Confirmar
crop**. Same `Crop PNG: N bytes` check. `/capture` is not a bottom tab.

## CI

```bash
flutter test test/features/capture/
```

Fixture PNG → `CapturePage` / share extra / Home Galeria stub → default rect →
`bytes.length > 0`.
