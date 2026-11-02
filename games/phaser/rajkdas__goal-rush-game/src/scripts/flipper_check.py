"""Pixel-level QA for the GOAL RUSH flipper zone.

Crops the flipper region from a browser screenshot (canvas CSS rect is
known) and measures how much bright-cream / neon content is present, plus
a contrast estimate between the flipper bats and the surrounding pitch.

Usage: python3 flipper_check.py <screenshot.png>
"""
import sys
from PIL import Image

# Canvas CSS rect measured via agent-browser (1280x577 viewport).
CANVAS = {"x": 319.6875, "y": 134.0, "w": 246.734375, "h": 438.65625}
LOGICAL_W, LOGICAL_H = 540, 960


def to_shot(lx: float, ly: float) -> tuple[float, float]:
    s = CANVAS["w"] / LOGICAL_W
    return (CANVAS["x"] + lx * s, CANVAS["y"] + ly * s)


def luminance(rgb: tuple) -> float:
    r, g, b = rgb[:3]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def analyze(path: str) -> None:
    img = Image.open(path).convert("RGB")
    print(f"image: {img.size}")

    # Flipper band: logical y 855..910, x 150..390 (both bats + gap).
    x0, y0 = to_shot(150, 855)
    x1, y1 = to_shot(390, 910)
    crop = img.crop((int(x0), int(y0), int(x1), int(y1)))
    px = list(crop.getdata())
    bright = [p for p in px if luminance(p) > 150]          # cream body / neon
    mid = [p for p in px if 80 < luminance(p) <= 150]
    dark = [p for p in px if luminance(p) <= 80]
    n = len(px)
    print(f"flipper band {n} px: bright {len(bright)/n:.1%}, "
          f"mid {len(mid)/n:.1%}, dark {len(dark)/n:.1%}")
    if bright:
        avg = tuple(sum(c[i] for c in bright) // len(bright) for i in range(3))
        print(f"  avg bright color (should be cream/white/neon): {avg}")
    if dark:
        avg = tuple(sum(c[i] for c in dark) // len(dark) for i in range(3))
        print(f"  avg dark color (pitch): {avg}")
    # Contrast ratio between avg bright and avg dark.
    if bright and dark:
        lb = sum(luminance(c) for c in bright) / len(bright)
        ld = sum(luminance(c) for c in dark) / len(dark)
        print(f"  luminance bright {lb:.0f} vs dark {ld:.0f} -> ratio {lb/max(ld,1):.1f}x")

    crop.save("/tmp/render/flipper-band.png")

    # Glow band just under the bats (logical y 905..935).
    x0, y0 = to_shot(150, 905)
    x1, y1 = to_shot(390, 935)
    crop2 = img.crop((int(x0), int(y0), int(x1), int(y1)))
    px2 = list(crop2.getdata())
    lit = [p for p in px2 if luminance(p) > 70]
    print(f"under-bat band: lit {len(lit)/len(px2):.1%} (glow presence)")

    # Left flipper crop for a zoomed look.
    x0, y0 = to_shot(140, 840)
    x1, y1 = to_shot(280, 925)
    img.crop((int(x0), int(y0), int(x1), int(y1))).resize(
        (int((x1 - x0) * 4), int((y1 - y0) * 4), ), Image.LANCZOS
    ).save("/tmp/render/left-flipper-zoom.png")


if __name__ == "__main__":
    analyze(sys.argv[1] if len(sys.argv) > 1 else "/tmp/render/goalrush-play.png")
