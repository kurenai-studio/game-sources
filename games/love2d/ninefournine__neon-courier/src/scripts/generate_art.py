#!/usr/bin/env python3
"""Reproduce original NEON COURIER vehicle pixel sprites, using only Python stdlib.

Art source, not a gameplay renderer. Real gameplay evidence is captured from LÖVE.
No external images, fonts, generation services, or third-party source assets.
"""
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "art"
ROWS = [
    "........................",
    ".....kkk........kkk.....",
    ".....kkk........kkk.....",
    "...dddddddddddddddd.....",
    "..daaaabbbbccccccccad...",
    ".daaaaabbbbccccccccaad..",
    ".daaeeabbbbfffcccccaahd.",
    ".daaeeabbbbfffcccccaahd.",
    ".daaeeabbbbfffcccccaahd.",
    ".daaeeabbbbfffcccccaahd.",
    ".daaaaabbbbccccccccaad..",
    "..daaaabbbbccccccccad...",
    "...dddddddddddddddd.....",
    ".....kkk........kkk.....",
    ".....kkk........kkk.....",
    "........................",
]
PALETTES = {
    "courier": ((.15,.71,.72),(.23,.86,.87),(.065,.17,.23),(1,.75,.35),(.90,.95,.94)),
    "police": ((.19,.25,.32),(.26,.32,.39),(.045,.095,.16),(.98,.31,.59),(.90,.95,.94)),
    "traffic_rust": ((.60,.30,.25),(.79,.44,.32),(.065,.13,.21),(.35,.19,.18),(1,.75,.35)),
    "traffic_slate": ((.40,.43,.58),(.55,.60,.72),(.075,.13,.20),(.33,.36,.49),(.90,.95,.94)),
    "traffic_taxi": ((.59,.51,.35),(.79,.69,.44),(.075,.13,.20),(.50,.42,.25),(1,.75,.35)),
}


def chunk(name, data):
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data))


def save_png(path, palette):
    body, roof, window, stripe, light = palette
    colors = {"k":(.025,.034,.047),"d":(.09,.15,.18),"a":body,
              "b":window,"c":roof,"e":stripe,"f":stripe,"h":light}
    width, height = 24, 16
    pixels = bytearray()
    for row in ROWS:
        pixels.append(0)  # PNG scanline filter: none.
        for column in range(width):
            code = row[column] if column < len(row) else "."
            c = colors.get(code)
            pixels.extend([round(v*255) for v in c] + [255] if c else [0,0,0,0])
    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", width,height,8,6,0,0,0))
    data += chunk(b"IDAT", zlib.compress(pixels, 9))
    data += chunk(b"IEND", b"")
    path.write_bytes(data)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, palette in PALETTES.items():
        path = OUT / (name + ".png")
        save_png(path,palette)
        print(f"{path.relative_to(ROOT)}: 24x16 original RGBA sprite")


if __name__ == "__main__":
    main()
