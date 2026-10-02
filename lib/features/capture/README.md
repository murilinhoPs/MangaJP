# Capture (M0.8)

Smoke path: **image → `/capture` crop UI → 1 rect → PNG bytes**. Capture is **not** a
bottom tab (PRD §11 / F2 / F3). OCR, Drift `pages`/`crops`, and dedupe are out of
scope here.

## Packages

| Package | Role |
|---------|------|
| `receive_sharing_intent` | Android `ACTION_SEND` / `SEND_MULTIPLE` and iOS Share Extension (`image/*`) |
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

**Gallery (no share sheet):** Home → **Galeria** → `/capture` → **Escolher da
galeria** → pick any image → (optional) drag the rect / corners → **Confirmar
crop**. The screen must show `Crop PNG: N bytes (W×H)` with N > 0. Logcat:
`M0.8 crop PNG bytes.length=…`.

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

Then tap **Confirmar crop**; logcat shows `M0.8 crop PNG bytes.length=…`.

## Verify on Linux desktop

Linux has no share target. The crop UI is Flutter-only, so `flutter run -d linux`
is enough to click through gallery → rect → bytes:

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
