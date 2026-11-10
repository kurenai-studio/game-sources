#!/usr/bin/env python3
"""Composite the role overlays over real villager sheets to check they sit right on every look and outfit.

Writes art/reference/role_overlays.png (or the path given as the first argument):
for each profession, three bodies (different looks and outfits) times idle, a walk frame, a chop frame,
a hammer frame and the spear, at 4x. Requires Pillow.
"""
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W = os.path.join(ROOT, "game", "assets", "world")
ROLES = ["smith", "trader", "forager", "scout"]
BODIES = ["cave/villagers/mira", "settled/villagers/field/theo", "bronze/villagers/town/wren", "bronze/villagers/fittings/mira"]
CELLS = [0, 2, 3, 6, 9, 10]
CELL_W, CELL_H, K = 28, 30, 4


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "art", "reference", "role_overlays.png")
    rows = [(r, b) for r in ROLES for b in BODIES]
    sheet = Image.new("RGBA", (len(CELLS) * CELL_W * K, len(rows) * CELL_H * K), (111, 168, 118, 255))
    for row, (role, body) in enumerate(rows):
        overlay = Image.open(os.path.join(W, "roles", role + ".png")).convert("RGBA")
        base = Image.open(os.path.join(W, body + ".png")).convert("RGBA")
        for col, c in enumerate(CELLS):
            box = (c * CELL_W, 0, (c + 1) * CELL_W, CELL_H)
            cell = base.crop(box)
            cell.alpha_composite(overlay.crop(box))
            sheet.alpha_composite(cell.resize((CELL_W * K, CELL_H * K), Image.NEAREST), (col * CELL_W * K, row * CELL_H * K))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    sheet.save(out_path)
    print("wrote", out_path)


if __name__ == "__main__":
    main()
