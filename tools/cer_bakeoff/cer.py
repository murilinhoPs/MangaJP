#!/usr/bin/env python3
"""Glyph-as-drawn CER: edit distance / GT length. No NFKC / kana / digit folding."""

from __future__ import annotations

from dataclasses import dataclass


def strip_ocr_noise(text: str) -> str:
    """Drop whitespace only (ASCII + Unicode Zs/Zl/Zp via str.isspace).

    Does **not** NFKC, kana-fold, halfwidth/fullwidth-fold, or map 1↔１ / よぉ↔よお.
    """
    return "".join(ch for ch in text if not ch.isspace())


def levenshtein(a: str, b: str) -> int:
    """Unicode code-point Levenshtein (insert/delete/substitute cost 1)."""
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    if len(a) < len(b):
        a, b = b, a
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        cur = [i]
        for j, cb in enumerate(b, start=1):
            ins = cur[j - 1] + 1
            delete = prev[j] + 1
            sub = prev[j - 1] + (ca != cb)
            cur.append(min(ins, delete, sub))
        prev = cur
    return prev[-1]


@dataclass(frozen=True)
class CerScore:
    gt_raw: str
    hyp_raw: str
    gt: str
    hyp: str
    edits: int
    gt_len: int

    @property
    def cer(self) -> float:
        if self.gt_len == 0:
            raise ZeroDivisionError("empty GT after whitespace strip")
        return self.edits / self.gt_len

    @property
    def cer_pct(self) -> float:
        return self.cer * 100.0


def score(gt_text: str, hyp_text: str) -> CerScore:
    gt = strip_ocr_noise(gt_text)
    hyp = strip_ocr_noise(hyp_text)
    edits = levenshtein(gt, hyp)
    return CerScore(
        gt_raw=gt_text,
        hyp_raw=hyp_text,
        gt=gt,
        hyp=hyp,
        edits=edits,
        gt_len=len(gt),
    )
