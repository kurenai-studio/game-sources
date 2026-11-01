"""Generate the scene2d Skin: one atlas page, its .atlas index, and skin.json.

    python docs/design/skin/build-skin.py

Writes, next to this script:

    skin.png      128 x 64, the whole widget set
    skin.atlas    the region index, with the nine-patch splits
    skin.json     the Skin itself, in the JsonValue form libGDX reads

There is no CSS here and nothing scales. A button is 60 x 12 px and every drawable in this atlas is
sized so that a nine-patch stretched to 60 x 12 lands on whole pixels; that is the entire layout
system. Every colour is an ls32 index, background-legal only, because the HUD plates and the menus
are scenery as far as the palette split is concerned -- the one exception is W4 on the selected
entry and on a bar fill, which 03-typography.md already fixes.

The fonts are not in this atlas. They are separate sheets under docs/design/fonts/ with their own
indexing rule, and skin.json refers to them by name: the loader registers `font-mini` and
`font-title` in the Skin before it reads this file. Keeping them out is deliberate -- a font that
lives in a widget atlas cannot be used by the HUD, which draws text and no widgets.
"""
import json
import pathlib
import struct
import zlib

HERE = pathlib.Path(__file__).parent

C = {
    'N0': (0x0B, 0x0E, 0x14), 'N1': (0x16, 0x1B, 0x26), 'N2': (0x24, 0x2C, 0x3B),
    'N3': (0x3B, 0x47, 0x5C), 'N4': (0x5C, 0x6B, 0x85), 'N5': (0x8D, 0x9C, 0xB5),
    'N6': (0xC9, 0xD6, 0xE8), 'N7': (0xFF, 0xFF, 0xFF), 'W3': (0xE5, 0x82, 0x2C),
    'W4': (0xFF, 0xC9, 0x4A), 'C1': (0x2F, 0xBF, 0xD4), 'H2': (0xFF, 0x3D, 0x8A),
}
CLEAR = (0, 0, 0, 0)

# Each drawable is written as rows of colour keys; '.' is transparent.
DRAWABLES = {}


def box(fill, top, bottom, edge, size=13):
    """A bevelled panel: N0 outline, a lit top edge, a shaded bottom edge, flat inside."""
    rows = []
    for y in range(size):
        row = []
        for x in range(size):
            if x in (0, size - 1) or y in (0, size - 1):
                row.append('N0')
            elif y == 1:
                row.append(top)
            elif y == size - 2:
                row.append(bottom)
            elif x in (1, size - 2):
                row.append(edge)
            else:
                row.append(fill)
        rows.append(row)
    return rows


DRAWABLES['white'] = ([['N7']], None)
DRAWABLES['panel'] = (box('N2', 'N3', 'N1', 'N3', 11), (3, 3, 3, 3))
DRAWABLES['plate'] = (box('N2', 'N3', 'N0', 'N2', 11), (3, 3, 3, 3))
DRAWABLES['button-up'] = (box('N3', 'N4', 'N1', 'N3', 13), (5, 5, 5, 5))
DRAWABLES['button-over'] = (box('N4', 'N5', 'N2', 'N4', 13), (5, 5, 5, 5))
DRAWABLES['button-down'] = (box('N2', 'N1', 'N3', 'N2', 13), (5, 5, 5, 5))
DRAWABLES['button-disabled'] = (box('N1', 'N1', 'N1', 'N2', 13), (5, 5, 5, 5))
DRAWABLES['bar-back'] = (box('N1', 'N1', 'N1', 'N1', 7), (2, 2, 2, 2))
DRAWABLES['bar-fill'] = ([['W4'] * 5 for _ in range(5)], (2, 2, 2, 2))
DRAWABLES['bar-fill-low'] = ([['W3'] * 5 for _ in range(5)], (2, 2, 2, 2))


def parse(text):
    return [list(row) for row in text.strip('\n').split('\n')]


def keyed(text, table):
    return [[table.get(ch, '.') for ch in row] for row in parse(text)]

# The pointer is the menu's only moving part, so it is drawn rather than bevelled: a chevron in W4,
# the same W4 03-typography.md gives the selected entry, so the mark and the word agree.
DRAWABLES['cursor'] = (keyed("""
#....
##...
###..
####.
###..
##...
#....
""", {'#': 'W4'}), None)

DRAWABLES['check-off'] = (keyed("""
kkkkkkkkk
k3333333k
k3111113k
k3111113k
k3111113k
k3111113k
k3111113k
k3333333k
kkkkkkkkk
""", {'k': 'N0', '3': 'N3', '1': 'N1'}), None)

DRAWABLES['check-on'] = (keyed("""
kkkkkkkkk
k3333333k
k31111c3k
k3c11cc3k
k3cc1c13k
k31ccc13k
k311c113k
k3333333k
kkkkkkkkk
""", {'k': 'N0', '3': 'N3', '1': 'N1', 'c': 'C1'}), None)

DRAWABLES['focus'] = (keyed("""
##.##
#....
.....
#....
##.##
""", {'#': 'W4'}), (2, 2, 2, 2))


def pack(width=128):
    """Shelf packing, left to right, one pixel of gap so nothing bleeds under a filter."""
    placed, x, y, shelf = {}, 0, 0, 0
    for name in DRAWABLES:
        rows = DRAWABLES[name][0]
        w, h = len(rows[0]), len(rows)
        if x + w > width:
            x, y, shelf = 0, y + shelf + 1, 0
        placed[name] = (x, y, w, h)
        x += w + 1
        shelf = max(shelf, h)
    return placed, y + shelf


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


SKIN = {
    "com.badlogic.gdx.graphics.Color": {
        "label": {"r": 0.361, "g": 0.420, "b": 0.522, "a": 1},
        "value": {"r": 1, "g": 1, "b": 1, "a": 1},
        "disabled": {"r": 0.231, "g": 0.278, "b": 0.361, "a": 1},
        "selected": {"r": 1, "g": 0.788, "b": 0.290, "a": 1},
        "warning": {"r": 0.898, "g": 0.510, "b": 0.173, "a": 1}
    },
    "com.badlogic.gdx.scenes.scene2d.ui.Label$LabelStyle": {
        "default": {"font": "font-mini", "fontColor": "value"},
        "label": {"font": "font-mini", "fontColor": "label"},
        "title": {"font": "font-title", "fontColor": "value"},
        "warning": {"font": "font-mini", "fontColor": "warning"}
    },
    "com.badlogic.gdx.scenes.scene2d.ui.TextButton$TextButtonStyle": {
        "default": {
            "font": "font-mini", "fontColor": "value",
            "up": "button-up", "over": "button-over", "down": "button-down",
            "disabled": "button-disabled",
            "overFontColor": "value", "downFontColor": "selected",
            "disabledFontColor": "disabled"
        }
    },
    "com.badlogic.gdx.scenes.scene2d.ui.CheckBox$CheckBoxStyle": {
        "default": {
            "font": "font-mini", "fontColor": "value",
            "checkboxOn": "check-on", "checkboxOff": "check-off",
            "disabledFontColor": "disabled"
        }
    },
    "com.badlogic.gdx.scenes.scene2d.ui.ProgressBar$ProgressBarStyle": {
        "default-horizontal": {"background": "bar-back", "knobBefore": "bar-fill"},
        "default-vertical": {"background": "bar-back", "knobBefore": "bar-fill"},
        "boss": {"background": "bar-back", "knobBefore": "bar-fill"},
        "boss-low": {"background": "bar-back", "knobBefore": "bar-fill-low"}
    },
    "com.badlogic.gdx.scenes.scene2d.ui.Slider$SliderStyle": {
        "default-horizontal": {"background": "bar-back", "knobBefore": "bar-fill", "knob": "cursor"}
    },
    "com.badlogic.gdx.scenes.scene2d.ui.Window$WindowStyle": {
        "default": {"titleFont": "font-title", "background": "panel", "titleFontColor": "value"}
    }
}


def ninepatch(rows, split, w, h):
    """Stretch a nine-patch to w x h by repeating its centre bands, the way scene2d does."""
    left, right, top, bottom = split
    sw, sh = len(rows[0]), len(rows)

    def axis(size, before, after, total):
        mid = size - before - after
        out = list(range(before))
        for i in range(total - before - after):
            out.append(before + i % mid)
        out += [size - after + i for i in range(after)]
        return out

    xs, ys = axis(sw, left, right, w), axis(sh, top, bottom, h)
    return [[rows[j][i] for i in xs] for j in ys]


def specimen():
    """Draw the widgets at the sizes they ship at. A nine-patch that looks right in the atlas and
    wrong at 60 x 12 is the normal outcome, and there is no way to know without stretching it."""
    glyphs = _font5()

    W, H = 220, 140
    canvas = [[C['N0'] + (255,)] * W for _ in range(H)]

    def put(rows, ox, oy):
        for j, row in enumerate(rows):
            for i, key in enumerate(row):
                if key != '.':
                    canvas[oy + j][ox + i] = C[key] + (255,)

    def text(string, ox, oy, colour):
        for n, ch in enumerate(string):
            g = glyphs.get(ch) or glyphs[' ']
            for j, bits in enumerate(g):
                for i in range(5):
                    if bits & (1 << (4 - i)):
                        canvas[oy + j][ox + n * 6 + i] = C[colour] + (255,)

    put(ninepatch(*DRAWABLES['panel'], 200, 120), 10, 10)
    text('OPTIONS', 20, 18, 'N7')
    for n, (state, label) in enumerate((('button-up', 'RESUME'), ('button-over', 'OPTIONS'),
                                        ('button-down', 'RESTART'),
                                        ('button-disabled', 'CONTINUE'))):
        y = 32 + n * 16
        put(ninepatch(*DRAWABLES[state], 60, 12), 20, y)
        text(label, 24, y + 3, 'N7' if state != 'button-disabled' else 'N3')
    put(DRAWABLES['check-off'][0], 100, 34)
    text('MUSIC', 112, 36, 'N4')
    put(DRAWABLES['check-on'][0], 100, 50)
    text('SOUND', 112, 52, 'N4')
    put(ninepatch(*DRAWABLES['bar-back'], 80, 7), 100, 70)
    put(ninepatch(*DRAWABLES['bar-fill'], 52, 7), 100, 70)
    text('BOSS', 100, 82, 'N4')
    put(DRAWABLES['cursor'][0], 100, 96)

    scale = 4
    big = [[canvas[y // scale][x // scale] for x in range(W * scale)] for y in range(H * scale)]
    write_png(HERE / "specimen.png", big, W * scale, H * scale)
    print("specimen.png - %dx%d" % (W * scale, H * scale))


def _font5():
    """Borrow the glyph reader from the font builder rather than writing a second one."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "buildfonts", HERE.parent / "fonts" / "build-fonts.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.read_table(module.GLYPH_SOURCE.read_text(encoding="utf-8"), "FONT5")


def main():
    placed, height = pack()
    width = 128
    height = max(height, 1)
    canvas = [[CLEAR] * width for _ in range(height)]
    for name, (x, y, w, h) in placed.items():
        rows = DRAWABLES[name][0]
        for j in range(h):
            for i in range(w):
                key = rows[j][i]
                if key != '.':
                    canvas[y + j][x + i] = C[key] + (255,)
    write_png(HERE / "skin.png", canvas, width, height)

    lines = ["skin.png", "size: %d,%d" % (width, height), "format: RGBA8888",
             "filter: Nearest,Nearest", "repeat: none"]
    for name, (x, y, w, h) in placed.items():
        split = DRAWABLES[name][1]
        lines += [name, "  rotate: false", "  xy: %d, %d" % (x, y), "  size: %d, %d" % (w, h)]
        if split:
            lines.append("  split: %d, %d, %d, %d" % split)
        lines += ["  orig: %d, %d" % (w, h), "  offset: 0, 0", "  index: -1"]
    (HERE / "skin.atlas").write_text("\n".join(lines) + "\n", encoding="utf-8")

    (HERE / "skin.json").write_text(json.dumps(SKIN, indent=2) + "\n", encoding="utf-8")
    print("skin.png - %dx%d, %d regions" % (width, height, len(placed)))
    print("skin.atlas, skin.json")
    specimen()


if __name__ == "__main__":
    main()
