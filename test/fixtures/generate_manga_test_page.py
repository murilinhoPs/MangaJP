#!/usr/bin/env python3
"""Synthetic manga page for macOS Galeria QA. No copyrighted art."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/NotoSansJP-VF.ttf"
OUT = Path(__file__).with_name("manga_test_page.png")

W, H = 1200, 1700
INK = (28, 24, 32)
PANEL = (18, 16, 22)
PAPER = (255, 255, 255)
BALLOON = (255, 255, 255)


def _font(size: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT), size=size)
    font.set_variation_by_name(b"Medium")
    return font


def _draw_vertical(
    draw: ImageDraw.ImageDraw,
    text: str,
    cx: int,
    top: int,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int] = INK,
    gap: int = 4,
) -> int:
    y = top
    for ch in text:
        bbox = draw.textbbox((0, 0), ch, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.text((cx - tw / 2, y), ch, font=font, fill=fill)
        y += max(th, int(font.size * 0.95)) + gap
    return y


def _balloon(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    text: str,
    font: ImageFont.FreeTypeFont,
    tail: list[tuple[int, int]] | None = None,
) -> None:
    x0, y0, x1, y1 = box
    if tail is not None:
        draw.polygon(tail, fill=BALLOON, outline=INK, width=4)
    draw.rounded_rectangle(box, radius=48, fill=BALLOON, outline=INK, width=4)
    if tail is not None:
        # Cover the balloon edge where the tail attaches.
        ax, ay = tail[0]
        cx, cy = tail[2]
        draw.line([(ax, ay), (cx, cy)], fill=BALLOON, width=8)
    _draw_vertical(draw, text, (x0 + x1) // 2, y0 + 36, font)


def main() -> None:
    img = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(img)
    draw.rectangle((48, 48, W - 48, 980), outline=PANEL, width=6)
    draw.rectangle((48, 1020, 560, H - 48), outline=PANEL, width=6)
    draw.rectangle((600, 1020, W - 48, H - 48), outline=PANEL, width=6)

    body = _font(46)
    small = _font(28)
    _balloon(
        draw,
        (200, 90, 460, 820),
        "「今日はいい天気ですね」",
        body,
        tail=[(300, 818), (270, 900), (360, 818)],
    )
    _balloon(
        draw,
        (700, 140, 980, 780),
        "本当だ雲一つない",
        body,
        tail=[(820, 778), (790, 860), (880, 778)],
    )
    _balloon(
        draw,
        (180, 1080, 430, 1580),
        "散歩に行こうか",
        body,
        tail=[(280, 1578), (250, 1645), (340, 1578)],
    )
    caption = "MangaJP QA · página sintética"
    bbox = draw.textbbox((0, 0), caption, font=small)
    draw.text(
        ((W - (bbox[2] - bbox[0])) / 2, H - 40),
        caption,
        font=small,
        fill=(120, 116, 128),
    )
    img.save(OUT, "PNG")
    print(f"wrote {OUT} {img.size}")


if __name__ == "__main__":
    main()
