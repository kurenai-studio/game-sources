#!/usr/bin/env python3
"""Write nearest-neighbour upscaled previews of art/reference/*.png into art/reference/previews/.

Requires Pillow (pip install pillow). Previews are for docs and review only; the 1x PNGs are the assets.
"""
import glob
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
REF = os.path.join(ROOT, "art", "reference")
SCALE = {"strip_v2": 3, "strip_v2_night": 3, "villager_A_sheet_v2": 5, "workshop_stages": 5}

os.makedirs(os.path.join(REF, "previews"), exist_ok=True)
for path in sorted(glob.glob(os.path.join(REF, "*.png"))):
    name = os.path.splitext(os.path.basename(path))[0]
    k = SCALE.get(name, 4)
    im = Image.open(path).convert("RGBA")
    out = os.path.join(REF, "previews", f"{name}_x{k}.png")
    im.resize((im.width * k, im.height * k), Image.NEAREST).save(out)
    print("wrote", os.path.relpath(out, ROOT))
