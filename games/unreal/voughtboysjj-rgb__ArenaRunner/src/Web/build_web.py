#!/usr/bin/env python3
"""Build docs/index.html from Web/index.template.html + vendor + src/game.js.

Everything is inlined so the result is a single self-contained file: no CDN, no
network access needed, works from file:// and from GitHub Pages.

Usage:  python3 Web/build_web.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent
TEMPLATE = ROOT / "index.template.html"
THREE = ROOT / "vendor" / "three.min.js"
GAME = ROOT / "src" / "game.js"
OUTPUT = ROOT.parent / "docs" / "index.html"

MARKERS = ("/*__THREE_LIB__*/", "/*__GAME_JS__*/")


def main() -> int:
    for path in (TEMPLATE, THREE, GAME):
        if not path.exists():
            print(f"error: missing {path}", file=sys.stderr)
            return 1

    html = TEMPLATE.read_text(encoding="utf-8")
    for marker in MARKERS:
        if marker not in html:
            print(f"error: marker {marker} missing from template", file=sys.stderr)
            return 1

    three = THREE.read_text(encoding="utf-8").replace("</script", "<\\/script")
    game = GAME.read_text(encoding="utf-8").replace("</script", "<\\/script")

    out = html.replace(MARKERS[0], three).replace(MARKERS[1], game)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(out, encoding="utf-8")

    ext = re.findall(r'(?:src|href)="(https?://[^"]+)"', out)
    print(f"wrote {OUTPUT} ({len(out):,} bytes) · external refs: {ext or 'none'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
