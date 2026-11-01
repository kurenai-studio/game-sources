"""Checks a finished PNG against the ls32 palette and the set it is allowed to draw from.

Run it on every asset as it is finished:

    python docs/design/palette/lint-art.py assets/bg-city.png background
    python docs/design/palette/lint-art.py assets/enemy-tank.png gameplay
    python docs/design/palette/lint-art.py assets/shot-e-small.png hostile

It reports colours that are not in the palette at all, and colours that belong to a set this asset
may not use - a background reaching for a gameplay colour is the failure the whole visual direction
is built to prevent, and it is invisible until the level is running.

Reads 8-bit non-interlaced PNGs: greyscale, indexed, RGB and RGBA. That covers what Aseprite,
GIMP and Krita export. Plain Python, no dependencies.
"""

import struct
import sys
import zlib

from check import BACKGROUND, GAMEPLAY, HOSTILE, OUTLINE, PALETTE

# Outlines are shared: N0 belongs to every sprite and to the void behind the level.
ALLOWED = {
    "background": {BACKGROUND, OUTLINE},
    "gameplay": {GAMEPLAY, OUTLINE},
    "hostile": {HOSTILE, OUTLINE},
}

BY_RGB = {
    tuple(int(hex_value[i:i + 2], 16) for i in (0, 2, 4)): (name, kind)
    for name, hex_value, kind, _ in PALETTE
}

CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


def read_png(path):
    """Returns (width, height, channels, palette, rows) with rows already unfiltered."""
    with open(path, "rb") as handle:
        data = handle.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")

    offset, header, plte, idat = 8, None, None, bytearray()
    while offset < len(data):
        length, kind = struct.unpack(">I4s", data[offset:offset + 8])
        body = data[offset + 8:offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            plte = body
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break

    width, height, depth, colour, compression, filter_method, interlace = header
    if depth != 8:
        raise ValueError(f"only 8-bit PNGs are supported, this one is {depth}-bit")
    if interlace:
        raise ValueError("interlaced PNGs are not supported; export without Adam7")
    if compression or filter_method:
        raise ValueError("unsupported compression or filter method")

    channels = CHANNELS[colour]
    stride = width * channels
    raw = zlib.decompress(bytes(idat))
    rows, previous = [], bytearray(stride)
    for y in range(height):
        start = y * (stride + 1)
        method = raw[start]
        line = bytearray(raw[start + 1:start + 1 + stride])
        for i in range(stride):
            left = line[i - channels] if i >= channels else 0
            up = previous[i]
            upper_left = previous[i - channels] if i >= channels else 0
            if method == 1:
                line[i] = (line[i] + left) & 0xFF
            elif method == 2:
                line[i] = (line[i] + up) & 0xFF
            elif method == 3:
                line[i] = (line[i] + (left + up) // 2) & 0xFF
            elif method == 4:
                line[i] = (line[i] + paeth(left, up, upper_left)) & 0xFF
            elif method != 0:
                raise ValueError(f"unknown filter {method} on row {y}")
        rows.append(line)
        previous = line
    return width, height, colour, channels, plte, rows


def pixels(width, height, colour, channels, plte, rows):
    """Yields opaque pixels as (x, y, rgb). Fully transparent ones are not drawn, so they do not count."""
    for y in range(height):
        line = rows[y]
        for x in range(width):
            base = x * channels
            if colour == 3:
                index = line[base] * 3
                rgb = (plte[index], plte[index + 1], plte[index + 2])
            elif colour == 0:
                value = line[base]
                rgb = (value, value, value)
            elif colour == 4:
                if line[base + 1] == 0:
                    continue
                value = line[base]
                rgb = (value, value, value)
            elif colour == 6:
                if line[base + 3] == 0:
                    continue
                rgb = (line[base], line[base + 1], line[base + 2])
            else:
                rgb = (line[base], line[base + 1], line[base + 2])
            yield x, y, rgb


def main(argv):
    if len(argv) != 3 or argv[2] not in ALLOWED:
        print(__doc__.strip().splitlines()[0])
        print("usage: python lint-art.py <file.png> background|gameplay|hostile")
        return 2

    path, role = argv[1], argv[2]
    width, height, colour, channels, plte, rows = read_png(path)

    unknown, forbidden, used = {}, {}, {}
    for x, y, rgb in pixels(width, height, colour, channels, plte, rows):
        entry = BY_RGB.get(rgb)
        if entry is None:
            unknown.setdefault(rgb, (x, y, 0))
            first = unknown[rgb]
            unknown[rgb] = (first[0], first[1], first[2] + 1)
            continue
        name, kind = entry
        used[name] = used.get(name, 0) + 1
        if kind not in ALLOWED[role]:
            forbidden.setdefault(name, (kind, x, y, 0))
            first = forbidden[name]
            forbidden[name] = (first[0], first[1], first[2], first[3] + 1)

    print(f"{path}: {width}x{height}, drawn as {role}")
    print("palette colours used:", ", ".join(sorted(used)) or "none")

    for rgb, (x, y, count) in sorted(unknown.items()):
        print(f"FAIL: #{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X} is not in the palette"
              f" - {count} px, first at {x},{y}")
    for name, (kind, x, y, count) in sorted(forbidden.items()):
        print(f"FAIL: {name} is {kind}-only and this asset is {role}"
              f" - {count} px, first at {x},{y}")

    if unknown or forbidden:
        return 1
    print("ok - every pixel is inside the palette and inside its set")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
