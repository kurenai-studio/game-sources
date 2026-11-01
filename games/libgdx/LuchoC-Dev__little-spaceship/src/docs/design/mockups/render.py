"""Render the character art in src/01-sprites.js to a PNG contact sheet.

The mock pages prove a sprite is legal; this proves what it looks like. An agent
cannot open an HTML page, but it can Read a PNG, so this is the only way the art
gets seen by whoever is drawing it. No third-party libraries on purpose: PIL is
not installed here and the web target's toolchain must not grow a dependency for
a design-time script.

    python render.py              every sprite, 6x, on a dark ground
    python render.py tank 12      one sprite by id fragment, at 12x
    python render.py enemy 8 flat every match filled flat, for the silhouette test

The flat mode is the silhouette test of docs/design/05-legibility-rules.md, which asks for every
archetype filled with one colour and looked at side by side. It fills with N4 rather than the N0 the
rule names, because a black shape on the dark ground this sheet uses is a shape you cannot see.
"""
import re, sys, zlib, struct, pathlib

HERE = pathlib.Path(__file__).parent
SRC = HERE / "src"


def palette():
    text = (SRC / "00-palette.js").read_text(encoding="utf-8")
    colours = re.search(r"const PALETTE = \[(.*?)\];", text, re.S).group(1)
    colours = re.findall(r"'#([0-9A-Fa-f]{6})'", colours)
    chars = re.search(r"const CHARS = \{(.*?)\};", text, re.S).group(1)
    table = {}
    for ch, idx in re.findall(r"'(.)': (-?\d+)", chars):
        table[ch] = int(idx)
    return [tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) for c in colours], table


def sprites():
    """Read the art blocks, applying sym() the same way the mock does.

    Wide sprites are authored as half rows and mirrored, so the mirror cannot
    drift; a renderer that ignored sym() would draw half a tank and look like a
    bug in the art.
    """
    text = (SRC / "01-sprites.js").read_text(encoding="utf-8")
    found = {}
    pattern = r"'([\w-]+)':\s*\{[^}]*?art:\s*(sym\()?\[(.*?)\]"
    for match in re.finditer(pattern, text, re.S):
        rows = re.findall(r"'([^']*)'", match.group(3))
        if not rows:
            continue
        if match.group(2):
            rows = [half + half[:-1][::-1] for half in rows]
        found[match.group(1)] = rows
    return found


def png(path, pixels, width, height):
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in row) for row in pixels)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def main():
    colours, chars = palette()
    art = sprites()
    wanted = sys.argv[1] if len(sys.argv) > 1 else None
    scale = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    flat = len(sys.argv) > 3 and sys.argv[3] == "flat"
    if wanted:
        art = {k: v for k, v in art.items() if wanted in k}
    if not art:
        print("no sprite matched")
        return

    ground = (22, 27, 38)
    gap, columns = 4, 6
    cells = list(art.items())
    rows_of = [cells[i:i + columns] for i in range(0, len(cells), columns)]
    cell_w = max(len(r[0]) for _, rows in cells for r in [rows]) + gap
    cell_h = max(len(rows) for _, rows in cells) + gap

    width, height = cell_w * columns, cell_h * len(rows_of)
    canvas = [[ground] * width for _ in range(height)]

    for band, band_cells in enumerate(rows_of):
        for column, (name, rows) in enumerate(band_cells):
            ox = column * cell_w + gap // 2
            oy = band * cell_h + gap // 2
            for y, row in enumerate(rows):
                for x, ch in enumerate(row):
                    index = chars.get(ch, -1)
                    if index >= 0:
                        canvas[oy + y][ox + x] = colours[4] if flat else colours[index]

    big = [[canvas[y // scale][x // scale] for x in range(width * scale)]
           for y in range(height * scale)]
    stem = "sprites" if not wanted else "sprite-%s" % wanted
    out = HERE / ((stem + "-flat.png") if flat else (stem + ".png"))
    png(out, big, width * scale, height * scale)
    print("%s - %d sprites, %dx%d at %dx" % (out.name, len(cells), width, height, scale))


if __name__ == "__main__":
    main()
