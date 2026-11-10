#!/usr/bin/env python3
"""Bundle Tiny Ages art scripts into single LibreSprite-runnable files.

LibreSprite resets its script environment on app.open(), so every script must
open its document first and then define everything else. This tool emits, per
scene script:  var DIR=...; app.open(DIR + <@open file>);  <lib.js>  <script>.

Header directives (first lines of a scene script):
  // @open <repo-relative png>   document to open (created blank if missing)
  // @canvas <W>x<H>             size of the blank PNG to create when missing
  // @nolib                      do not prepend lib.js

Usage:
  python tools/art/bundle.py              # bundle all scripts
  python tools/art/bundle.py strip night  # bundle selected scripts
  python tools/art/bundle.py --run        # bundle and execute each via `libresprite -b --script`
                                          # (set LIBRESPRITE_EXE if it is not on PATH)
Output: tools/art/dist/<name>.bundle.js (git-ignored). Bundles can also be run in the
LibreSprite UI (copy into its scripts folder) or via the libresprite MCP run_script tool.
"""
import os
import re
import struct
import subprocess
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DIST = os.path.join(HERE, "dist")
SCENES = ["strip", "cave_strip", "cave_pages", "cave_river", "cave_villagers", "cave_celestial", "cave_stars", "settled_camp", "settled_villagers", "bronze_camp", "bronze_villagers", "iron_camp", "iron_villagers", "classical_camp", "signature_landmarks", "classical_villagers", "role_overlays", "weather", "ui_icons", "ui_seasons", "ui_achievements", "game_icon", "ui_skin_hide", "ui_skin_clay", "ui_skin_bronze", "ui_skin_iron", "ui_skin_classical", "night", "villager_sheet", "villager_walk", "workshop_stages"]  # night reads strip's output


def write_blank_png(path, w, h):
    raw = b"".join(b"\x00" + b"\x00" * (w * 4) for _ in range(h))

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw))
           + chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def bundle(name):
    src_path = os.path.join(HERE, name + ".js")
    with open(src_path, encoding="utf-8") as f:
        body = f.read()
    opened = re.search(r"^//\s*@open\s+(\S+)", body, re.M)
    if not opened:
        raise SystemExit(f"{name}.js: missing // @open directive")
    rel = opened.group(1)
    target = os.path.join(ROOT, *rel.split("/"))
    canvas = re.search(r"^//\s*@canvas\s+(\d+)x(\d+)", body, re.M)
    if not os.path.exists(target):
        if not canvas:
            raise SystemExit(f"{rel} does not exist and {name}.js has no // @canvas")
        write_blank_png(target, int(canvas.group(1)), int(canvas.group(2)))
        print(f"created blank canvas {rel}")
    parts = [
        f'var DIR = "{ROOT.replace(os.sep, "/")}/";',
        f'var DOC = app.open(DIR + "{rel}");',
        "var SPR = DOC.sprite;  // works in UI and --batch mode (app.activeSprite does not)",
    ]
    if not re.search(r"^//\s*@nolib", body, re.M):
        with open(os.path.join(HERE, "lib.js"), encoding="utf-8") as f:
            parts.append(f.read())
    parts.append(body)
    os.makedirs(os.path.join(ROOT, "art", "reference", "layers"), exist_ok=True)
    os.makedirs(DIST, exist_ok=True)
    out = os.path.join(DIST, name + ".bundle.js")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(parts))
    print("wrote", os.path.relpath(out, ROOT))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    run = "--run" in sys.argv[1:]
    names = args or SCENES
    for n in names:
        bundle(n)
        if run:
            exe = os.environ.get("LIBRESPRITE_EXE", "libresprite")
            out = os.path.join(DIST, n + ".bundle.js")
            subprocess.run([exe, "-b", "--script", out], check=True)
            if n == "role_overlays":  # its preview is composited over the real villager sheets
                subprocess.run([sys.executable, os.path.join(HERE, "role_preview.py")], check=True)
