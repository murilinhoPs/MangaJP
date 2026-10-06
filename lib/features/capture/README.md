# Capture (M1.1)

Path: **share or import → `/capture` → ≥1 crop → OCR → persist → `/pages/:id`**. Capture is
**not** a bottom tab (PRD §11 / F2 / F3). Default OCR is **manga-ocr** as a local
sidecar (`docs/m0.3-cer-bakeoff.md`, official CER **20.75%**). Lookup / Caderno /
Android share-intent device smoke are later M1.

## Packages

| Package | Role |
|---------|------|
| `receive_sharing_intent` | Android `ACTION_SEND` / `SEND_MULTIPLE` and iOS Share Extension (`image/*`) |
| `image_picker` | Home **Galeria** pick (and `/capture` empty-state fallback) |
| `image` | Decode + `copyCrop` + encode PNG (PRD §9.4) |

OCR talks to `tools/manga_ocr_sidecar/serve.py` (kha-white/manga-ocr). Crop UI is a
Flutter `CustomPainter` rect (not `image_cropper`) so `flutter test` can prove the
path with a fake `OcrEngine`. `google_mlkit_*` and Cloud Vision are **not** in
`pubspec.yaml`.

## AndroidManifest (real device / emulator)

`android/app/src/main/AndroidManifest.xml`:

- `android:launchMode="singleTask"` on `MainActivity` so a warm share reuses the
  activity (`ShareIntentBinder` then `go('/capture', extra: image)`).
- Intent filters: `SEND` + `SEND_MULTIPLE` with `image/*`.
- `READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"` for older `file://` shares.
  Android 13+ uses the system photo picker / content URIs (plugin copies to cache).

## iOS (`receive_sharing_intent` 1.9.0)

`ios/` follows the plugin’s documented Share Extension setup (SPM-only; no CocoaPods
podspec). M0.8 only accepts images, matching Android `image/*`.

- Bundle ID `dev.murilinhops.mangajp` (same as Android `applicationId`).
- Display name `MangaJP`.
- App Group `group.dev.murilinhops.mangajp` on **Runner** and **ShareExtension**
  (`CUSTOM_GROUP_ID`, entitlements, `AppGroupId` in both Info.plist files).
- URL scheme `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` so the extension can
  reopen the host app.
- `ShareExtension` activation: images only (`NSExtensionActivationSupportsImageWithMaxCount`).
- `ShareViewController` inherits `RSIShareViewController` and auto-redirects
  into `/capture` (no compose sheet).
- Photo library + camera usage strings in `ios/Runner/Info.plist` for
  `image_picker` (gallery is M0.8; camera is still Could / F28).

Device-only remaining steps (need a Mac + Apple Developer team):

1. Open `ios/Runner.xcworkspace` in Xcode and set a Development Team on **Runner**
   and **ShareExtension**.
2. Confirm the App Group `group.dev.murilinhops.mangajp` in Signing & Capabilities
   (creates the group on the developer portal if needed).
3. First `flutter pub get` / `flutter build ios` on macOS fills
   `ios/Flutter/ephemeral/Packages/.packages/receive_sharing_intent` so the Share
   Extension can link the `receive-sharing-intent` Swift product.
4. Photos / Files → **Share** → **MangaJP** should open `/capture` with the image.

`flutter build ios` is not run in this Linux CI / Cloud Agent environment (no
Xcode).

## Verify on emulator

```bash
flutter run
```

**Gallery (no share sheet):** Home → **Galeria** → pick any image → (optional)
drag the rect / corners → **Confirmar crop**. The app must go to `/pages/:id`
and show the persisted OCR text. Canceling the picker stays on Home. Logcat:
`M0.8 crop PNG bytes.length=…` then `M1.1 OCR manga_ocr: …`.

**Share:** in Photos / Files / a screenshot, **Share** → **MangaJP**. The app
opens `/capture` with the image (no Home hop, no Capture tab). Confirm crop as
above.

### Share without a photo app (adb)

Simulates **Share → MangaJP** with a MediaStore `content://` URI (needs
`READ_EXTERNAL_STORAGE` granted, as a sender app would hold on API ≤ 32):

```bash
adb push page.jpg /sdcard/Pictures/ && adb shell am broadcast \
  -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/page.jpg
adb shell pm grant dev.murilinhops.mangajp android.permission.READ_EXTERNAL_STORAGE
ID=$(adb shell content query --uri content://media/external/images/media \
  --projection _id:_display_name | rg page.jpg | rg -o '_id=\d+' | cut -d= -f2)
adb shell am start -a android.intent.action.SEND -t image/jpeg \
  --grant-read-uri-permission --eu android.intent.extra.STREAM \
  content://media/external/images/media/$ID -n dev.murilinhops.mangajp/.MainActivity
```

Then tap **Confirmar crop**; the app goes to `/pages/:id` with the saved OCR
text. Logcat shows `M0.8 crop PNG bytes.length=…` and `M1.1 OCR manga_ocr: …`
when the sidecar is running.

## manga-ocr sidecar (M1.1)

Product OCR is the same Python [manga-ocr](https://github.com/kha-white/manga-ocr)
scored in `tools/cer_bakeoff/` (working default, **20.75%** CER). Run it as a
local HTTP service — do not embed torch in Flutter:

```bash
source tools/cer_bakeoff/.venv/bin/activate
python3 tools/manga_ocr_sidecar/serve.py
```

The app POSTs crop PNG bytes to `http://127.0.0.1:8765/ocr` (`MANGA_OCR_URL` to
override). Android emulator share-intent device smoke is a follow-up (`--host
0.0.0.0` + `MANGA_OCR_URL=http://10.0.2.2:8765`).

## Verify on Linux desktop

Linux has no share target. The crop UI is Flutter-only, so `flutter run -d linux`
is enough to click through gallery → rect → bytes:

```bash
# Ubuntu: ninja-build libgtk-3-dev g++
flutter run -d linux
```

Home → **Galeria** → pick an image → **Confirmar
crop**. The app goes to `/pages/:id` with the persisted OCR text when the
sidecar is up. `/capture` is not a bottom tab.

## Verify on Chrome (Flutter web)

Web has no share target. Gallery uses the browser file picker; Drift uses
`web/sqlite3.wasm` + `web/drift_worker.js`. The sidecar must send CORS
headers (already in `serve.py`) so Chrome can POST crop PNG bytes:

```bash
flutter run -d chrome
```

Home → **Galeria** → pick an image → **Confirmar
crop**. Same `/pages/:id` check when the sidecar is up. `/capture` is not a
bottom tab.

## CI

```bash
flutter test test/features/capture/ test/features/ocr/ test/features/pages/
```

Fixture PNG → `CapturePage` / share extra / Home **Galeria** pick → default rect →
crop bytes, OCR text persisted in Drift `crops`, then `/pages/:id` shows that
text (fake `OcrEngine`; default wiring is still `manga_ocr`).
