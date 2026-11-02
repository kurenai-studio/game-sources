#!/usr/bin/env python3
"""GOAL RUSH visual QA — pixel analysis of the rendered canvas.

Maps logical playfield coordinates (540x960) to canvas pixels and checks:
 1. Flipper regions contain bright bat pixels (white/green)
 2. HUD text region has high-contrast bright pixels on dark bg
 3. Overall luminance distribution (no all-dark screen)
"""
from PIL import Image

img = Image.open('/tmp/render/play.png').convert('RGB')
W, H = img.size
px = img.load()

# Locate the game canvas: the tallest dark vertical band. The React frame has
# a marquee (~44px) on top; the canvas fills the rest, aspect-locked 9:16.
# Scan for the dark playfield background color ~ (7, 11, 20).
def is_bg(c, tol=26):
    r, g, b = c
    return abs(r - 7) < tol and abs(g - 11) < tol and abs(b - 20) < tol

# column darkness profile between y=40..H
dark_cols = []
for x in range(W):
    cnt = sum(1 for y in range(40, H, 4) if is_bg(px[x, y]))
    dark_cols.append(cnt)
# find contiguous band where darkness > 50% of max
mx = max(dark_cols)
left = next(i for i, c in enumerate(dark_cols) if c > mx * 0.5)
right = W - 1 - next(i for i, c in enumerate(reversed(dark_cols)) if c > mx * 0.5)
print(f'game band x: {left}..{right} (w={right-left})')

# row profile inside that band
dark_rows = []
for y in range(H):
    cnt = sum(1 for x in range(left, right, 4) if is_bg(px[x, y]))
    dark_rows.append(cnt)
mxy = max(dark_rows)
top = next(i for i, c in enumerate(dark_rows) if c > mxy * 0.5)
bot = H - 1 - next(i for i, c in enumerate(reversed(dark_rows)) if c > mxy * 0.5)
print(f'game band y: {top}..{bot} (h={bot-top})')

# logical -> canvas mapping
bw, bh = right - left, bot - top
scale = min(bw / 540, bh / 960)
ox = left + (bw - 540 * scale) / 2
oy = top + (bh - 960 * scale) / 2

def to_canvas(x, y):
    return int(ox + x * scale), int(oy + y * scale)

def region_stats(cx, cy, rw, rh, label):
    """Count bright pixels (luminance>140) and average color in region."""
    x0, y0 = int(cx - rw / 2), int(cy - rh / 2)
    bright = 0
    total = 0
    rs = gs = bs = 0
    for y in range(max(0, y0), min(H, y0 + rh)):
        for x in range(max(0, x0), min(W, x0 + rw)):
            r, g, b = px[x, y]
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            total += 1
            rs += r; gs += g; bs += b
            if lum > 140:
                bright += 1
    avg = (rs // total, gs // total, bs // total) if total else (0, 0, 0)
    print(f'{label:28s} bright px: {bright:5d}/{total} ({100*bright/total:.1f}%)  avg RGB {avg}')
    return bright

print(f'scale={scale:.3f} offset=({ox:.0f},{oy:.0f})')

# 1. Flipper bats (pivots at 178/362, y 862; bat extends inward ~82 logical px)
lx, ly = to_canvas(205, 872)  # left bat center-ish
rx, ry = to_canvas(335, 872)
region_stats(lx, ly, int(90 * scale), int(40 * scale), 'LEFT FLIPPER area')
region_stats(rx, ry, int(90 * scale), int(40 * scale), 'RIGHT FLIPPER area')

# 2. HUD bar text (credits/jackpot/mult/balls row at y ~ 925)
hx, hy = to_canvas(240, 928)
region_stats(hx, hy, int(300 * scale), int(36 * scale), 'HUD strip (text)')

# 3. Marquee (React header) text
region_stats(W // 2, 22, 300, 30, 'React marquee (text)')

# 4. Playfield mid (bumpers at y 330-420)
bx, by = to_canvas(230, 380)
region_stats(bx, by, int(200 * scale), int(120 * scale), 'Bumper cluster (mid)')

# 5. Whole canvas luminance
hist = [0] * 5
for y in range(0, H, 3):
    for x in range(0, W, 3):
        r, g, b = px[x, y]
        lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        hist[min(4, int(lum / 51))] += 1
tot = sum(hist)
print('luminance buckets (dark->bright):', [f'{100*h/tot:.1f}%' for h in hist])
