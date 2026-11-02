#!/usr/bin/env python3
"""
Pack all sprite strips into a single texture atlas for Rainbow Climb.
Generates a libGDX-compatible .atlas file + PNG.
Uses simple shelf packing (sprites are horizontal strips).
"""

import os
from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
ATLAS_NAME = "game"
PADDING = 2  # pixels between sprites

def find_sprites():
    """Find all PNG sprite files to pack."""
    entries = []
    dirs = ["sprites/player", "sprites/enemies/walker", "sprites/enemies/flyer",
            "sprites/enemies/hopper", "sprites/enemies/shooter", "sprites/enemies/bomber",
            "sprites/enemies/chaser", "sprites/boss", "sprites/collectibles", "sprites/gems",
            "sprites/player_alt/ninja_frog", "sprites/player_alt/mask_dude",
            "sprites/player_alt/virtual_guy",
            "tiles"]
    for d in dirs:
        full = os.path.join(BASE, d)
        if not os.path.isdir(full):
            continue
        for f in sorted(os.listdir(full)):
            if f.endswith(".png"):
                path = os.path.join(full, f)
                img = Image.open(path)
                name = f"{d}/{f}".replace("/", "_").replace(".png", "")
                entries.append({
                    "name": name,
                    "path": path,
                    "width": img.width,
                    "height": img.height,
                    "rel_path": f"{d}/{f}"
                })
    return entries

def pack(entries, max_width=2048):
    """Simple shelf packing algorithm."""
    # Sort by height descending for better packing
    entries.sort(key=lambda e: -e["height"])

    x, y = 0, 0
    shelf_height = 0
    placements = []

    for entry in entries:
        w = entry["width"] + PADDING
        h = entry["height"] + PADDING

        if x + w > max_width:
            # New shelf
            x = 0
            y += shelf_height
            shelf_height = 0

        placements.append({
            **entry,
            "atlas_x": x,
            "atlas_y": y
        })
        shelf_height = max(shelf_height, h)
        x += w

    atlas_w = max_width
    atlas_h = y + shelf_height

    # Round up to power of 2 for GPU efficiency
    def next_pow2(v):
        p = 1
        while p < v:
            p *= 2
        return p

    atlas_w = next_pow2(max(p["atlas_x"] + p["width"] for p in placements))
    atlas_h = next_pow2(atlas_h)

    return placements, atlas_w, atlas_h

def generate(placements, atlas_w, atlas_h):
    """Generate atlas PNG and .atlas file."""
    # Create atlas image
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))

    for p in placements:
        img = Image.open(p["path"])
        atlas.paste(img, (p["atlas_x"], p["atlas_y"]))

    out_png = os.path.join(BASE, f"{ATLAS_NAME}.png")
    atlas.save(out_png)
    print(f"Atlas PNG: {out_png} ({atlas_w}x{atlas_h})")

    # Generate libGDX .atlas file
    out_atlas = os.path.join(BASE, f"{ATLAS_NAME}.atlas")
    with open(out_atlas, "w") as f:
        f.write(f"{ATLAS_NAME}.png\n")
        f.write(f"size: {atlas_w},{atlas_h}\n")
        f.write("format: RGBA8888\n")
        f.write("filter: Nearest,Nearest\n")
        f.write("repeat: none\n")

        for p in placements:
            f.write(f"{p['name']}\n")
            f.write(f"  rotate: false\n")
            f.write(f"  xy: {p['atlas_x']}, {p['atlas_y']}\n")
            f.write(f"  size: {p['width']}, {p['height']}\n")
            f.write(f"  orig: {p['width']}, {p['height']}\n")
            f.write(f"  offset: 0, 0\n")
            f.write(f"  index: -1\n")

    print(f"Atlas file: {out_atlas} ({len(placements)} regions)")

    return out_png, out_atlas

# Run
entries = find_sprites()
print(f"Found {len(entries)} sprite files")
placements, w, h = pack(entries)
generate(placements, w, h)
print(f"\nTotal sprites packed: {len(placements)}")
print(f"Atlas size: {w}x{h} ({w*h*4/1024:.0f} KB uncompressed)")
