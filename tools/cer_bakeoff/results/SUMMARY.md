# M0.3 CER bake-off results

Generated: `2026-10-02T22:10:53.212083+00:00`
GT: `/tmp/mangajp-m0.2-gt` (`manifest-kanji.csv`, glyph-as-drawn).

Protocol: OCR vs GT **code points as drawn**. Strip whitespace only. No NFKC, no kana folding, no ASCII/fullwidth digit folding (`1` ≠ `１`, `よぉ` ≠ `よお`).

Headline CER is **corpus** = Σ edits / Σ GT length (successful crops only). Skipped engines have **no** invented numbers.

| Engine | Status | Corpus CER | Macro CER | Exact | Crops ok | GT chars | Edits | Notes |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `mlkit_ja` | SKIPPED | — | — | — | — | — | — | SKIPPED (google_mlkit_text_recognition is Android/iOS-only; this Linux agent has no emulator. Re-run with --predictions mlkit_ja=dump.json — see tools/cer_bakeoff/README.md) |
| `cloud_vision` | SKIPPED | — | — | — | — | — | — | SKIPPED (no GCP credentials: set CLOUD_VISION_API_KEY or GOOGLE_APPLICATION_CREDENTIALS, or `gcloud auth application-default login`) |
| `manga_ocr` | ok | 20.75% | 22.76% | 25/44 | 44/44 | 530 | 110 | manga-ocr 0.1.16; model=kha-white/manga-ocr-base; device=cpu |

## Q-B1 gate (corpus CER ≤ 10%)

**None ≤ 10%.** Best measured: `manga_ocr` at **20.75%** (110/530). Do not invent numbers for skipped engines. Working default = best measured (PRD: Cloud/manga) until the skipped engines are scored on this same GT.

Skipped:
- `mlkit_ja`: SKIPPED (google_mlkit_text_recognition is Android/iOS-only; this Linux agent has no emulator. Re-run with --predictions mlkit_ja=dump.json — see tools/cer_bakeoff/README.md)
- `cloud_vision`: SKIPPED (no GCP credentials: set CLOUD_VISION_API_KEY or GOOGLE_APPLICATION_CREDENTIALS, or `gcloud auth application-default login`)

## Per-crop (measured engines)

### `manga_ocr`

| crop_id | CER % | edits | gt_len | GT | OCR |
| --- | ---: | ---: | ---: | --- | --- |
| `page_0_b1` | 85.25 | 52 | 61 | 全世界累計出荷本数１００万本突破の大人気サイコロジカルホラー、竜騎士０７描き下ろしの「新たなエンディング」でコミカライズ！ | 今年夏葉市出荷末など、１００万ド突破の人ということですが、 |
| `page_0_b2` | 0.00 | 0 | 14 | 美しいがゆえに、おぞましい。 | 美しいがゆえに、おぞましい。 |
| `page_1_b1` | 100.00 | 3 | 3 | 痛い… | 痛い．．． |
| `page_1_b2` | 100.00 | 3 | 3 | 誰か… | 誰か．．． |
| `page_1_b3` | 0.00 | 0 | 5 | 止めてくれ | 止めてくれ |
| `page_1_b4` | 133.33 | 4 | 3 | 雛子… | 「雛子．．． |
| `page_3_b1` | 0.00 | 0 | 8 | 狐に噛まれたんだ | 狐に噛まれたんだ |
| `page_3_b2` | 0.00 | 0 | 7 | だいじょうぶ？ | だいじょうぶ？ |
| `page_3_b3` | 66.67 | 6 | 9 | ありがとう…でも… | ありがとう．．．でも．．． |
| `page_4_b1` | 0.00 | 0 | 17 | ぼ、ぼくは、ことゆきっていいます！ | ぼ、ぼくは、ことゆきっていいます！ |
| `page_4_b2` | 25.00 | 1 | 4 | 君は―― | 君は――― |
| `page_4_b3` | 0.00 | 0 | 5 | 私の名前は | 私の名前は |
| `page_4_b4` | 0.00 | 0 | 3 | 雛子！ | 雛子！ |
| `page_5_b1` | 0.00 | 0 | 17 | 親に向かって、その言い草は何だぁ！ | 親に向かって、その言い草は何だぁ！ |
| `page_5_b2` | 0.00 | 0 | 23 | そんなにお母さんの作るご飯が気にくわないなら、 | そんなにお母さんの作るご飯が気にくわないなら、 |
| `page_5_b3` | 0.00 | 0 | 10 | 食べなきゃいいでしょ | 食べなきゃいいでしょ |
| `page_5_b4` | 22.22 | 4 | 18 | なんだと……もういっぺん言ってみろ！ | なんだと．．．もういっへん言ってみろ！ |
| `page_6.1_b1` | 0.00 | 0 | 11 | ひどいことを言われて、 | ひどいことを言われて、 |
| `page_6.1_b2` | 0.00 | 0 | 16 | なんでへらへら笑っていられるの？ | なんでへらへら笑っていられるの？ |
| `page_6.1_b3` | 150.00 | 3 | 2 | 雛子 | ．．．雛子 |
| `page_6.b1` | 60.00 | 3 | 5 | お母さん、 | しかしお母さん、 |
| `page_6_b2` | 0.00 | 0 | 19 | こんな人にご飯なんて作らなくっていいよ | こんな人にご飯なんて作らなくっていいよ |
| `page_6_b3` | 0.00 | 0 | 22 | 雛子、やめて。お父さんにそんな言い方しないで | 雛子、やめて。お父さんにそんな言い方しないで |
| `page_6_b4` | 10.00 | 1 | 10 | お母さんもお母さんだ | お母さんもお母ちんだ |
| `page_6_b5` | 0.00 | 0 | 12 | こんなひどいことされて、 | こんなひどいことされて、 |
| `page_7_b1` | 0.00 | 0 | 11 | お父さんに、謝りなさい | お父さんに、謝りなさい |
| `page_7_b2` | 50.00 | 3 | 6 | ……どうして | ．．．どうして |
| `page_7_b3` | 20.00 | 3 | 15 | …もうすぐ、大切な日なんだから | ．．．もうすぐ、大切な日なんだから |
| `page_7_b4` | 0.00 | 0 | 16 | 私、お母さんみたいになりたくない | 私、お母さんみたいになりたくない |
| `page_8_b1` | 33.33 | 2 | 6 | どこ行くの？ | どこ行くの？．． |
| `page_8_b2` | 0.00 | 0 | 10 | こっち通るの珍しいね | こっち通るの珍しいね |
| `page_8_b3` | 0.00 | 0 | 3 | 咲子！ | 咲子！ |
| `page_8_b4` | 0.00 | 0 | 4 | 千鶴屋？ | 千鶴屋？ |
| `page_8_b5` | 27.27 | 3 | 11 | うん…誰かと喋りたくて | うん．．．誰かと喋りたくて |
| `page_9_b1` | 0.00 | 0 | 8 | 私も後から行くね | 私も後から行くね |
| `page_9_b2` | 42.86 | 3 | 7 | ……うんじゃあ | ．．．うんじゃあ |
| `page_9_b3` | 0.00 | 0 | 4 | 裏切り者 | 裏切り者 |
| `page_9_b4` | 22.22 | 2 | 9 | 咲子――五十嵐咲子 | 咲子ー五十嵐咲子 |
| `page_9_b5` | 13.89 | 5 | 36 | 昔から、「ずっと一緒」と私のことをそれなりに好きでいてくれている…はず。 | 昔から、ずっと一緒と私のことをそれなりに好きでいてくれている．．．はず。 |
| `page_9_b6` | 14.29 | 3 | 21 | だが…なぜか私のことを「裏切り者」と呼ぶ。 | だが．．．なぜか私のことを「裏切り者」と呼ぶ。 |
| `page_9_b7` | 25.00 | 6 | 24 | 少し天然…なのか、人とは違う不思議な部分がある… | 少し天然．．．なのか、人とは違う不思議な部分がある．．． |
| `page_10_b1` | 0.00 | 0 | 5 | よぉ、相棒 | よぉ、相棒 |
| `page_10_b2` | 0.00 | 0 | 6 | 来てたんだな | 来てたんだな |
| `page_10_b3` | 0.00 | 0 | 21 | 宇宙軍団から戎ヶ丘を守らないといけないだろ | 宇宙軍団から戎ヶ丘を守らないといけないだろ |

See `per_crop.csv` / `engines.csv` for the machine-readable table.
