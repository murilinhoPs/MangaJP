# QA notes — real manga page, head `a7773f7`, Linux Flutter

QA only. No app source changes. No merge. No video. No production deploy.

## Platform (actual)

- Cloud Ubuntu 24.04, XFCE + TigerVNC `DISPLAY=:1`.
- **Linux Flutter GTK window**, binary `manga_jp`, application id `dev.murilinhops.mangajp`.
- `flutter devices`: `Linux (desktop) • linux • linux-x64` and Chrome. **No Android device.**
- `flutter doctor`: **Android toolchain missing** (`Unable to locate Android SDK`). No `emulator`, no `adb`. `/dev/kvm` exists; an AVD was **not** installed for this run.
- Phone prints: window resized so **client area is 390×844**, captured with `import -window` (no title bar). **fonte: janela Linux**. This is **not** Android.
- Desktop prints: same process at **1280×800**.
- Flutter 3.47.9 (stable) / Dart 3.13.7.

## App head tested

```
a7773f7442030ea90f0575878e2bcc96bcf50b37
a7773f7 docs: remove Pendentes da F26 já aprovada (#103)
```

Matches `origin/main` at QA time (`git fetch origin main`).

## OCR configuration inspected (not changed)

Official default = manga-ocr (ADR-0001). Current code:

- `lib/features/ocr/data/ocr_repository.dart` `ocrEngine` **always** returns `MangaOcrEngine`.
- `MangaOcrEngine.engineId = manga_ocr`, default URL `http://127.0.0.1:8765`.
- `CloudVisionOcrEngine` and `MlkitOcrEngine` exist as **unimplemented stubs** and are not wired into `ocrEngine`.
- Drift seed: `app_meta.ocr_engine_id = manga_ocr`.
- `/settings` is a stub: `Drift + Riverpod` / `app_meta.hello = MangaJP M0.1`. **No OCR engine picker, no Cloud Vision toggle, no key field.** F26 (#59) is not in this head.

Sidecar (intended local service, already documented in README):

```
source tools/cer_bakeoff/.venv/bin/activate
HF_HOME=tools/cer_bakeoff/.cache/hf
python3 tools/manga_ocr_sidecar/serve.py --host 127.0.0.1 --port 8765
curl -sS http://127.0.0.1:8765/health
# {"ok": true, "engine_id": "manga_ocr"}
```

App launch:

```
flutter run -d linux --dart-define=MANGA_OCR_URL=http://127.0.0.1:8765
```

No fake OCR, no typed Japanese as OCR, no Cloud Vision key requested, no settings switch.

## Input image

Attached original JPEG copied to `~/MangaJP-QA/real-manga-page.jpg` (print-rules picker folder; **not** `test/fixtures/manga_test_page.png`).

- 1179×1788 JPEG, 8-bit sRGB, 450750 bytes
- sha256 `a2ef40a9bd0319ab54bf57c7298bbfa492fb7385d1374f89251204d6ce5d34e1`
- Preserved as `original_real_manga_page.jpg` in this folder and in local artifacts.

Page content used for the flow: school-uniform two-shot, middle balloon **宇宙軍団から我ヶ丘を守らないといけないだろ**, shop sign 千鶴屋商店.

## Commands / tests actually run

| Command | Result |
| --- | --- |
| `git fetch origin main pr-assets` | main = `a7773f7…`, pr-assets = `9a31f38…` at start |
| `flutter doctor -v` | Linux toolchain OK; Android SDK absent |
| `flutter pub get` | OK |
| `dart run build_runner build` | OK (generated outputs discarded; `main` left clean) |
| `python3 tools/build_jmdict_sqlite/build_jmdict_sqlite.py --with-kanji` | wrote `assets/dict/jmdict.sqlite` 105M, 219036 entries, 13108 kanji |
| manga-ocr 0.1.16 + `kha-white/manga-ocr-base` CPU in bake-off venv | sidecar `POST /ocr` 200 |
| `flutter run -d linux` | built `build/linux/x64/debug/bundle/manga_jp`, Impeller OpenGLESSDF |
| **No** `flutter test` / **no** `integration_test` on this head | not executed |

Automated suites were **not** claimed green. Evidence is the live GUI session + sidecar/app logs.

Flutter log (real OCR, not invented):

```
M1.1 OCR manga_ocr: また、実際から来る方を守るないといけないだろ
M0.8 crop PNG bytes.length=126304
```

Sidecar: `POST /ocr HTTP/1.1` 200 after `GET /health` 200.

## Exercised flow (exact)

1. **Home** empty: Fila de hoje 0, Capturas recentes only “+ Nova da galeria”. Print `01_home.png`.
2. Click **+ Nova da galeria**. Native GTK dialog title **Open File** (English). Navigate `ubuntu > MangaJP-QA`, select `real-manga-page.jpg` (450.8 kB, Image). Print `02_gallery_picker.png` (dialog 1179×884; recaptured later in the same session with the same file visible, Cancel not Open). First Open of this file is what fed `/capture`.
3. `/capture` shows the **attached manga page**. Default crop rect (normalized 0.2,0.2,0.6,0.6) covers most of the art. Bar: `1 recorte · ordem ← automática`, `arraste para criar`, **Confirmar crop**. Print `03_crop_real_page.png`.
4. Crop was then tightened toward the middle balloon (handles dragged). Tightened-rect still was **not** captured before confirm (gap for reel: only the default overlay print exists).
5. **Confirmar crop**. Sidecar OCR ~1–2 s. Leitor `/pages/:id` shows:

   `また、実際から来る方を守るないといけないだろ`

   Dock: truncated UUID `78a45420-1018-4469-9e8c-183…`, `1 recorte`, pencil, +. **No engine chip.** Print `04_ocr_page.png`.
6. Tap **実際**. Lookup sheet: lemma `実際`, reading `じっさい`, JMdict gloss (reality; actuality; … bhutakoti). Buttons Aprendendo / Conhecido / Ignorar / Salvar with kbd A/K/I. Print `05_lookup_jissai.png`.
7. Tap kanji **実** on the lemma. Ficha: ON `ジツ · シツ`, KUN `み · みの.る · まこと · みの · みち.る`, SIGNIFICADOS `reality; truth; seed; fruit; nut`, TRAÇOS `8`, **Salvar kanji**. Print `06_kanji_jitsu.png`.
8. **Salvar kanji** — sheet closed, **no snackbar**. **Salvar** on the word — sheet closed, **no snackbar**.
9. Caderno **Palavras**: `実際` / `じっさい` / chip **Salvo**. Print `07_caderno_palavras.png`.
10. Caderno **Kanji**: `実` with the same KANJIDIC2 fields, source lemma `実際`. Print `08_caderno_kanji.png`.
11. Word detail → **Aprender**. State **Salvo → Aprendendo**. Aprender button disappears. No dialog. Home Fila de hoje went **0 → 1 cards esperando**, `1 novos · limite 15/dia`.
12. Home **Revisar →**. Review front: `SESSÃO` / `1 restante` / lemma `実際` / **Mostrar**. Print `10_review_front.png`.
13. **Mostrar**. Back: `じっさい` + gloss. Ratings as on the print (not from memory): **Errei agora**, **Difícil 10 min**, **Bom 1 dia** (green), **Fácil 4 dias**. Print `11_review_back.png`.
14. **Bom**. Session ended. Home Fila de hoje back to **0** (card due tomorrow, not now).
15. Word detail state **Aprendendo**, FRASE is the OCR sentence, Ver página present. Print `09_word_detail_aprendendo.png`.
16. Ajustes stub. Print `13_ajustes_stub.png`.
17. Home after: Continuar lendo + Capturas recentes show **person silhouette placeholders**, OCR preview `また、実際か…`, badge `1`. Ritmo da semana Saturday coral. Print `12_home_after.png`.
18. Desktop 1280×800 Home (rail Biblioteca) and Caderno Palavras (`実際` **Aprendendo**).

## Observed failures / gaps (for dash — not fixed here)

1. **OCR mismatch vs balloon (real manga-ocr).** Intended middle balloon: `宇宙軍団から我ヶ丘を守らないといけないだろ`. Sidecar returned `また、実際から来る方を守るないといけないだろ`. Repro: import this JPEG → crop the middle balloon (tight) → Confirmar crop with sidecar up. Possible mix of crop geometry + engine CER (official 20.75%). **Do not “correct” the on-screen text for the reel.**
2. **Home / Continuar lendo thumbs are not the page image.** `HomeRecentEntry` comment: pages have no thumbnail bytes. UI uses `Icons.person_outline`. README still says “page thumbs”. `/pages` list-as-placeholder was an owner decision (2026-11-04); Home recent captures still look like a missing image.
3. **Leitor title is a truncated UUID**, not OCR/title copy. Dock `78a45420-1018-4469-9e8c-183…`.
4. **Ajustes has no OCR controls.** Engine is hardcoded manga-ocr. Cannot verify a user-visible default chip. F26 not shipped.
5. **Save is silent.** Salvar / Salvar kanji / Aprender: no toast. Success is only the list/state change.
6. **Lookup kbd chips A/K/I show at 390×844.** Kanji spec says the S hint is wide-only; word actions still show letter chips on phone width.
7. **Linux Galeria is GTK “Open File” in English**, not a Photos-style gallery. Spec `galeria.md`: “Pendente: seletor nativo em Linux e web.”
8. **Android emulator n/a.** No SDK/AVD. Phone prints are Linux 390×844 only. `n/a: sem emulador (#93)` if a platform-flow PR needed emulator (share, system back, real gallery). This QA is Linux-window-allowed for 390×844.
9. **Tightened crop still missing from the still set.** Reel crop frame is the **default large overlay** on the real page (`03_crop_real_page.png`), which is honest but not the rect that produced the OCR bytes.

## UX notes (reasons)

- Dark `#0E0D12` chrome, coral `#FF5C7A` CTAs, phone nav Início/Caderno/Deck/Ajustes, and desktop rail match the design system.
- End-to-end loop **works** on Linux once sidecar + JMdict are present: Galeria → crop → manga-ocr → JMdict lookup → Salvar palavra + Salvar kanji → Caderno both tabs → Aprender → Review Mostrar → Bom.
- Lookup of OCR **実際** is a real JMdict hit (`じっさい`) even though 実際 is **not** what the balloon says — the study loop follows OCR, not ground truth.
- Review intervals on a new card (from the print): Good = 1 day, Easy = 4 days, Hard = 10 min, Again = now.
- Impeller `libEGL warning: DRI3 error` on this VM; UI still rendered.

## What was not done

- No Mac / iOS (`n/a: Mac offline (#54)` if those prints were required).
- No Android emulator screenshots.
- No `flutter test` / integration_test dump.
- No app source fix, no settings change, no fake OCR, no video, no force-push.
