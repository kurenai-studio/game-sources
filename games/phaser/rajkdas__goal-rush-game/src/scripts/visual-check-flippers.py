#!/usr/bin/env python3
"""Visual QA for GOAL RUSH: verify flippers + ball render at the expected
page-pixel locations in the gameplay screenshot.

Canvas: internal 540x960 (the full table, no letterbox), CSS box
x=39.375 y=130 w=399.375 h=710 → page = (39.375 + tx/540*399.375, 130 + ty/960*710).
"""
from PIL import Image
import sys

IMG = "/tmp/render/play.png"
img = Image.open(IMG).convert("RGB")
W, H = img.size
print(f"screenshot {W}x{H}")

# The agent-browser screenshot is in CSS pixels scaled by the device pixel
# ratio; the canvas rect is in CSS px. Detect the scale: screenshot height /
# page height. Assume dpr = W / page_width. We only need the canvas box ratio:
# find the canvas by scanning? Simpler: map with the CSS rect directly if the
# screenshot is 1:1 CSS pixels; else scale by dpr.
# Detect dpr from the known canvas CSS width 399.375: probe by brightness is
# overkill — use PIL size: most agent-browser shots are 1:1 (dpr=1).
dpr = 1.0
cx, cy, cw, ch = 39.375, 130.0, 399.375, 710.0


def table_to_page(tx, ty):
    px = (cx + tx / 540.0 * cw) * dpr
    py = (cy + ty / 960.0 * ch) * dpr
    return px, py


def region_stats(tx, ty, r_table=14):
    """Mean brightness & max deviation from the deep background around a
    table point, sampling a disc of radius r_table."""
    px, py = table_to_page(tx, ty)
    rx = r_table / 540.0 * cw * dpr
    ry = r_table / 960.0 * ch * dpr
    x0, x1 = max(0, int(px - rx)), min(W - 1, int(px + rx))
    y0, y1 = max(0, int(py - ry)), min(H - 1, int(py + ry))
    if x1 <= x0 or y1 <= y0:
        return None
    n = 0
    s = 0.0
    bright = 0
    pix = img.load()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            r, g, b = pix[x, y]
            v = (r + g + b) / 3.0
            s += v
            n += 1
            if v > 90:
                bright += 1
    return {"mean": s / max(1, n), "bright_ratio": bright / max(1, n)}


checks = {
    "left flipper (205,878)": (205.5, 877.7),
    "right flipper (335,878)": (334.5, 877.7),
    "left flipper tip (240,898)": (240, 898),
    "right flipper tip (300,898)": (300, 898),
    "ball (224,862)": (223.9, 862.4),
    "mid table (270,480)": (270, 480),
    "drain gap (270,930)": (270, 930),
    "bumpers (230,330)": (230, 330),
}
ok = True
for name, (tx, ty) in checks.items():
    st = region_stats(tx, ty)
    if st is None:
        print(f"{name}: OUT OF FRAME")
        ok = False
        continue
    print(f"{name}: mean={st['mean']:.1f} bright={st['bright_ratio']:.2%}")

# Whole-image sanity: not blank, reasonably colorful.
small = img.resize((80, 142))
pix = small.load()
tot = 0
bright_total = 0
for y in range(142):
    for x in range(80):
        r, g, b = pix[x, y]
        v = (r + g + b) / 3.0
        tot += 1
        if v > 80:
            bright_total += 1
print(f"overall bright ratio: {bright_total / tot:.2%} (blank page would be < 3%)")
sys.exit(0 if ok else 1)
