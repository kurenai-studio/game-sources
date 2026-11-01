"""Assembles the self-contained mock pages from the sources in src/.

    python docs/design/mockups/build.py

Each page is published as an Artifact, which means it must carry everything it needs in one file:
no external scripts, no shared stylesheet at runtime. But three pages that each hold their own copy
of the rasteriser rot the moment a sprite changes, so the copy happens here instead of by hand.

Sources, all in src/:

    NN-*.js         the engine, concatenated in numeric order and shared by every page
    <name>.page.html   that page's title and markup
    <name>.ui.js       that page's own interface code
    shared.css         the stylesheet every page uses
    <name>.css         optional, appended after shared.css for one page only

Output is <name>.html next to this script. The generated files are committed on purpose: they are
what gets published, and a reviewer should be able to read them without running anything.
"""

import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")

FONT_LINKS = """<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?\
family=Martian+Mono:wght@400;600;700&family=IBM+Plex+Sans:ital,wght@0,400;0,500;1,400&display=swap">"""


def read(name):
    return io.open(os.path.join(SRC, name), encoding="utf-8").read()


def engine():
    parts = sorted(f for f in os.listdir(SRC) if re.match(r"^\d\d-.*\.js$", f))
    return "\n".join(read(p) for p in parts), parts


def pages():
    return sorted(f[:-len(".page.html")] for f in os.listdir(SRC) if f.endswith(".page.html"))


def build(name, engine_js):
    page = read(name + ".page.html")
    match = re.search(r"<title>.*?</title>", page, re.S)
    if not match:
        raise SystemExit(name + ".page.html has no <title>, and the artifact would be named by its file")
    title, markup = match.group(0), page.replace(match.group(0), "", 1).strip()

    css = read("shared.css")
    extra = name + ".css"
    if os.path.exists(os.path.join(SRC, extra)):
        css += "\n" + read(extra)

    html = "\n".join([
        title, FONT_LINKS,
        "<style>", css.strip(), "</style>", "",
        markup, "",
        "<script>", engine_js.strip(), "</script>",
        "<script>", read(name + ".ui.js").strip(), "</script>", ""
    ])
    out = os.path.join(HERE, name + ".html")
    io.open(out, "w", encoding="utf-8", newline="\n").write(html)
    return out, len(html)


def main():
    engine_js, parts = engine()
    print("engine:", ", ".join(parts))
    for name in pages():
        out, size = build(name, engine_js)
        print("built", os.path.basename(out), "-", size, "bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
