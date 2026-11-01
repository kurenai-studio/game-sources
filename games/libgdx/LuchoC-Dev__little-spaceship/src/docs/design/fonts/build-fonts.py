"""Export the two bitmap fonts as PNG sheets, plus a specimen that can be looked at.

The glyphs live in ``docs/design/mockups/src/00-palette.js`` because the mock pages draw text with
them, and a font that exists twice diverges. This script is the only thing that turns them into the
files the game loads, so the sheet and the mock can never disagree.

    python docs/design/fonts/build-fonts.py

Writes, next to this script:

    font-mini.png    96 x 60, ASCII 32-126, 16 columns of 6 x 10 cells
    font-title.png   128 x 78, same grid, 8 x 13 cells, uncovered cells empty
    specimen.png     both fonts drawn as text at 4x on N2, for looking at

Both sheets are white on transparent: colour comes from the batch tint at draw time, which is what
lets an N4 label and an N7 value share one texture and one draw call.

No third-party libraries on purpose. PIL is not installed here and the toolchain must not grow a
dependency for a design-time script.
"""
import pathlib
import re
import struct
import sys
import zlib

HERE = pathlib.Path(__file__).parent
GLYPH_SOURCE = HERE.parent / "mockups" / "src" / "00-palette.js"

COLUMNS = 16
FIRST, LAST = 32, 126

FONTS = {
    "font-mini": {"table": "FONT5", "gw": 5, "cw": 6, "ch": 10},
    "font-title": {"table": "FONT7", "gw": 7, "cw": 8, "ch": 13},
}


def read_table(text, name):
    """Pull one ``const NAME = { ... };`` object of bitmask rows out of the JavaScript.

    The keys are single characters written as JS string literals, so the two that need escaping in
    the source -- the backslash and whichever quote encloses them -- are unescaped here.
    """
    body = re.search(r"const " + name + r" = \{(.*?)\n\};", text, re.S).group(1)
    table = {}
    for key, rows in re.findall(r"\n  (\"(?:[^\"\\]|\\.)\"|'(?:[^'\\]|\\.)')\: \[([^\]]*)\]", body):
        ch = key[1:-1].replace("\\\\", "\\").replace("\\'", "'").replace('\\"', '"')
        table[ch] = [int(v, 0) for v in rows.split(",")]
    return table


def sheet(table, gw, cw, ch):
    """One RGBA sheet, cell index = code - 32, row-major across 16 columns."""
    rows = -(-(LAST - FIRST + 1) // COLUMNS)
    width, height = COLUMNS * cw, rows * ch
    pixels = [[(255, 255, 255, 0)] * width for _ in range(height)]
    drawn = 0
    for code in range(FIRST, LAST + 1):
        glyph = table.get(chr(code))
        if glyph is None:
            continue
        drawn += 1
        index = code - FIRST
        ox, oy = (index % COLUMNS) * cw, (index // COLUMNS) * ch
        for y, bits in enumerate(glyph):
            for x in range(gw):
                if bits & (1 << (gw - 1 - x)):
                    pixels[oy + y][ox + x] = (255, 255, 255, 255)
    return pixels, width, height, drawn


def write_png(path, pixels, width, height):
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in row) for row in pixels)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


SPECIMEN = [
    ("font-title", "LITTLE SPACESHIP"),
    ("font-title", "SCORE 0012500 - WAVE 3"),
    ("font-mini", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
    ("font-mini", "abcdefghijklmnopqrstuvwxyz"),
    ("font-mini", "0123456789 !\"#$%&'()*+,-./"),
    ("font-mini", ":;<=>?@[\\]^_`{|}~"),
    ("font-mini", "Jumpy pigs quiz vex a wug: 40 fj."),
    ("font-mini", "LIVES 3  BOMBS 2  SHIELD OFF"),
]


def specimen(tables, scale=4):
    """Both fonts as running text, so the glyphs are judged the way they will be read."""
    lines = []
    for font, string in SPECIMEN:
        spec = FONTS[font]
        table, gw, cw, ch = tables[font], spec["gw"], spec["cw"], spec["ch"]
        cells = []
        for character in string:
            glyph = table.get(character) or table.get(character.upper()) or table[" "]
            cells.append(glyph)
        width = len(string) * cw
        rows = [[0] * width for _ in range(ch)]
        for i, glyph in enumerate(cells):
            for y, bits in enumerate(glyph):
                for x in range(gw):
                    if bits & (1 << (gw - 1 - x)):
                        rows[y][i * cw + x] = 1
        lines.append(rows)

    width = max(len(row[0]) for row in lines)
    canvas = []
    for rows in lines:
        for row in rows:
            canvas.append(row + [0] * (width - len(row)))
        canvas.append([0] * width)

    ground, ink = (36, 44, 59, 255), (255, 255, 255, 255)
    big = [[ink if canvas[y // scale][x // scale] else ground for x in range(width * scale)]
           for y in range(len(canvas) * scale)]
    return big, width * scale, len(canvas) * scale


def main():
    text = GLYPH_SOURCE.read_text(encoding="utf-8")
    tables = {name: read_table(text, spec["table"]) for name, spec in FONTS.items()}

    for name, spec in FONTS.items():
        table = tables[name]
        too_wide = [c for c, g in table.items() if any(b >> spec["gw"] for b in g)]
        too_tall = [c for c, g in table.items() if len(g) > spec["ch"] - 1]
        if too_wide or too_tall:
            print("%s: glyphs outside the cell - %s" % (name, too_wide + too_tall))
            return 1
        pixels, width, height, drawn = sheet(table, spec["gw"], spec["cw"], spec["ch"])
        write_png(HERE / (name + ".png"), pixels, width, height)
        print("%s.png - %dx%d, %d glyphs" % (name, width, height, drawn))

    pixels, width, height = specimen(tables)
    write_png(HERE / "specimen.png", pixels, width, height)
    print("specimen.png - %dx%d" % (width, height))
    return 0


if __name__ == "__main__":
    sys.exit(main())
