"""Generate the Tomate app icon as an Icon Composer bundle (.icon).

A round tomato seen from the side, nine seeds in a ring (six yellow, three dark red)
and a star calyx of pointed sepals on a short stem. Each part is one layer PNG
(1024x1024, the canvas is the whole rounded square); icon.json carries the
background, gradients, glass and shadow.

Writes Resources/Tomate.icon (the app icon) and Liquid Glass previews in
design/logo/preview/.

Usage: python3 -I design/logo/tomate.py
Needs resvg, and Xcode's ictool for the previews (run outside the sandbox:
ictool needs the GPU).
"""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
ICON = HERE.parent.parent / "Resources" / "Tomate.icon"
PREVIEWS = HERE / "preview"
ICTOOL = "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"

# Round body: a shallow dip at the top where the stem goes in, almost circular below.
BODY = (
    "M512 268 C460 262 420 248 370 252 C250 262 160 380 160 565 "
    "C160 760 320 890 512 890 C704 890 864 760 864 565 "
    "C864 380 774 262 654 252 C604 248 564 262 512 268 Z"
)

# Seeds: SEED_COUNT ellipses on a ring, long axis pointing out from its centre, the
# first one at the top. Going clockwise, the first YELLOW_SEEDS are yellow, the rest dark.
SEED_CENTRE, SEED_RING_RADIUS = (512, 590), 146
SEED_RADII = (28, 44)
SEED_COUNT, YELLOW_SEEDS = 9, 6
YELLOW, DARK_RED = "#F6A91E", "#B01E0C"

# Star calyx: a short stem with two pointed sepals on each side. A sepal is a triangle
# from the stem base; the thick round-joined stroke of its own colour rounds its tips.
CALYX_BASE = (512, 300)
STEM = (494, 140, 36, 160)  # x, y, width, height
SEPALS = ((340, 240, 420, 286), (400, 190, 452, 280))  # tip x, tip y, inner x, inner y
SEPAL_ROUNDING = 24
GREEN = "#637225"


def seeds() -> str:
    """Return the ring of seeds, the yellow ones first going clockwise from the top."""
    cx, cy = SEED_CENTRE
    rx, ry = SEED_RADII
    step = 360 / SEED_COUNT
    return "".join(
        f'<ellipse cx="{cx}" cy="{cy - SEED_RING_RADIUS}" rx="{rx}" ry="{ry}" '
        f'fill="{YELLOW if i < YELLOW_SEEDS else DARK_RED}" '
        f'transform="rotate({i * step:g} {cx} {cy})"/>'
        for i in range(SEED_COUNT)
    )


def calyx() -> str:
    """Return the stem and the four sepals, mirrored around the stem."""
    bx, by = CALYX_BASE
    x, y, w, h = STEM
    parts = [
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{w / 2:g}" fill="{GREEN}"/>'
    ]
    for tip_x, tip_y, inner_x, inner_y in SEPALS:
        for mirror in (False, True):
            tx, ix = (2 * bx - tip_x, 2 * bx - inner_x) if mirror else (tip_x, inner_x)
            parts.append(
                f'<path d="M{bx} {by} L{tx} {tip_y} L{ix} {inner_y} Z" fill="{GREEN}" '
                f'stroke="{GREEN}" stroke-width="{SEPAL_ROUNDING}" stroke-linejoin="round"/>'
            )
    return "".join(parts)


@dataclass(frozen=True)
class LayerSpec:
    """One layer of the icon: its PNG name, display name, SVG fragment and optional settings."""

    id: str
    name: str
    svg: str
    extra: dict[str, object]


# Front to back. The tomato and the leaves get a gradient fill; the seeds keep their
# PNG colours under glass.
LAYER_SPECS = [
    LayerSpec(
        "leaves-stems",
        "Leaves and stems",
        calyx(),
        {
            "fill": {
                "linear-gradient": [
                    "display-p3:0.39315,0.42994,0.18002,1.00000",
                    "display-p3:0.39315,0.91707,0.18002,1.00000",
                ],
                "orientation": {
                    "start": {"x": 0.5, "y": 0},
                    "stop": {"x": 0.5, "y": 0.7},
                },
            }
        },
    ),
    LayerSpec("seeds", "Seeds", seeds(), {"blend-mode": "normal", "glass": True}),
    LayerSpec(
        "tomato",
        "Tomato",
        f'<path d="{BODY}" fill="#DE1F08"/>',
        {
            "blend-mode": "normal",
            "fill": {
                "linear-gradient": [
                    "display-p3:0.87059,0.00000,0.30885,1.00000",
                    "srgb:0.87059,0.00000,0.14058,1.00000",
                ],
                "orientation": {
                    "start": {"x": 0.5, "y": 0},
                    "stop": {"x": 0.5, "y": 0.88},
                },
            },
        },
    ),
]


def build_icon() -> None:
    """Write the layer PNGs and icon.json of the .icon bundle."""
    shutil.rmtree(ICON, ignore_errors=True)
    (ICON / "Assets").mkdir(parents=True)
    entries = []
    with tempfile.TemporaryDirectory() as tmp:
        for spec in LAYER_SPECS:
            src = Path(tmp) / f"{spec.id}.svg"
            src.write_text(
                f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{spec.svg}</svg>'
            )
            png = f"{spec.id}.png"
            subprocess.run(
                ["resvg", "-w", "1024", str(src), str(ICON / "Assets" / png)],
                check=True,
            )
            entries.append({"image-name": png, "name": spec.name, **spec.extra})
    document = {
        "fill": "system-dark",
        "groups": [
            {
                "layers": entries,
                "shadow": {"kind": "neutral", "opacity": 0.5},
                "translucency": {"enabled": True, "value": 0.42},
            }
        ],
        "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
    }
    (ICON / "icon.json").write_text(json.dumps(document, indent=2) + "\n")


def build_previews() -> None:
    """Render Liquid Glass previews of the icon with ictool."""
    PREVIEWS.mkdir(exist_ok=True)
    for size in (512, 128, 64, 32):
        subprocess.run(
            [
                ICTOOL,
                str(ICON),
                "--export-image",
                "--output-file",
                str(PREVIEWS / f"tomate-{size}.png"),
                "--platform",
                "macOS",
                "--rendition",
                "Default",
                "--width",
                str(size),
                "--height",
                str(size),
                "--scale",
                "1",
            ],
            check=True,
            capture_output=True,
        )


if __name__ == "__main__":
    build_icon()
    build_previews()
    print(f"built {ICON}")
