# `core/srs` — `sm2-jr@1`

Pure Dart port of japanese-reader `logic/srs/sm2.clj`. Golden tests live in
`test/core/srs/` (ported from `sm2_test.clj`). Spec = Clojure: if PRD prose
and `sm2.clj` conflict, **`sm2.clj` wins**.

## M0 confirmation vs `sm2.clj`

1. **EF on fail** — ease factor **always** updates, including `q < 3`. (An
   older PRD sentence said “do not change EF on fail”; that is not the spec.)
2. **Rounding** — `Math/round` / Dart `num.round()`, not ceil.
3. **Interval uses EF'** — for `repetitions >= 3`,
   `max(1, round(previousInterval * updatedEase))` with the **post-review**
   ease, not the incoming EF.

JR `:status` (`learning` / `learned` / `mastered`) is mapped to MangaJP
`CardPhase` in Dart types only (`mangaJpPhaseFor`): failed →
`learning`/`relearning`; learned/mastered → `review`. Scheduling numbers are
unchanged.
