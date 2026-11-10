#!/usr/bin/env python3
"""Scale the 32x32 game icon into the files the project uses (nearest, so it stays crisp).

  art/reference/game_icon.png  (from `bundle.py --run game_icon`)
    -> game/icon.png   256x256, the project icon
    -> game/icon.ico   16, 24, 32, 48, 64, 128 and 256 px, for the Windows executable

Run from anywhere: python tools/art/make_icon.py
"""
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SOURCE = os.path.join(ROOT, "art", "reference", "game_icon.png")
SIZES = (16, 24, 32, 48, 64, 128, 256)


def main():
    if not os.path.exists(SOURCE):
        raise SystemExit("Missing %s: run `python tools/art/bundle.py --run game_icon` first" % SOURCE)
    base = Image.open(SOURCE).convert("RGBA")
    if base.size != (32, 32):
        raise SystemExit("game_icon.png should be 32x32, got %s" % (base.size,))
    big = base.resize((256, 256), Image.NEAREST)
    big.save(os.path.join(ROOT, "game", "icon.png"))
    # 16 and 24 px are not whole multiples of 32, so shrink the 256 px image with a box filter.
    frames = [big.resize((s, s), Image.NEAREST if s % 32 == 0 else Image.BOX) for s in SIZES]
    frames[-1].save(
        os.path.join(ROOT, "game", "icon.ico"), format="ICO", sizes=[(s, s) for s in SIZES],
        append_images=frames[:-1],
    )
    print("wrote game/icon.png and game/icon.ico")


if __name__ == "__main__":
    main()
