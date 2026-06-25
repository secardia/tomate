#!/usr/bin/env python3
"""Generate Tomate macOS AppIcon assets."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT / "Tomate" / "Assets.xcassets" / "AppIcon.appiconset"

BG = (28, 28, 31, 255)
TOMATO = (230, 120, 115, 255)
TOMATO_SHADOW = (176, 78, 74, 255)
TOMATO_HIGHLIGHT = (255, 168, 162, 210)
STEM = (92, 158, 104, 255)
LEAF = (110, 176, 118, 255)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    radius: float,
    fill: tuple[int, int, int, int],
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pad = size * 0.08
    rounded_rect(draw, (pad, pad, size - pad, size - pad), size * 0.22, BG)

    cx = size * 0.5
    cy = size * 0.56
    rx = size * 0.27
    ry = size * 0.30

    shadow_offset = max(1, size * 0.02)
    draw.ellipse(
        (cx - rx, cy - ry + shadow_offset, cx + rx, cy + ry + shadow_offset),
        fill=TOMATO_SHADOW,
    )
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=TOMATO)

    highlight_rx = rx * 0.42
    highlight_ry = ry * 0.30
    draw.ellipse(
        (
            cx - rx * 0.35 - highlight_rx,
            cy - ry * 0.55 - highlight_ry,
            cx - rx * 0.35 + highlight_rx,
            cy - ry * 0.55 + highlight_ry,
        ),
        fill=TOMATO_HIGHLIGHT,
    )

    stem_w = max(2, size * 0.05)
    stem_h = size * 0.11
    stem_top = cy - ry - stem_h * 0.15
    draw.rounded_rectangle(
        (cx - stem_w / 2, stem_top - stem_h, cx + stem_w / 2, stem_top + stem_h * 0.15),
        radius=stem_w / 2,
        fill=STEM,
    )

    leaf_cx = cx + size * 0.07
    leaf_cy = stem_top - stem_h * 0.55
    leaf_r = size * 0.075
    draw.ellipse(
        (leaf_cx - leaf_r, leaf_cy - leaf_r * 0.65, leaf_cx + leaf_r, leaf_cy + leaf_r * 0.65),
        fill=LEAF,
    )
    draw.ellipse(
        (cx - leaf_r * 1.1, leaf_cy - leaf_r * 0.5, cx - leaf_r * 0.2, leaf_cy + leaf_r * 0.5),
        fill=LEAF,
    )

    return img


def write_iconset() -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)

    specs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    images: list[dict] = []
    for filename, pixel_size in specs:
        draw_icon(pixel_size).save(ICONSET / filename, format="PNG")
        logical = pixel_size // (2 if "@" in filename else 1)
        scale = "2x" if "@" in filename else "1x"
        images.append(
            {
                "filename": filename,
                "idiom": "mac",
                "scale": scale,
                "size": f"{logical}x{logical}",
            }
        )

    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (ICONSET / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    write_iconset()
    print(f"Wrote AppIcon to {ICONSET}")
