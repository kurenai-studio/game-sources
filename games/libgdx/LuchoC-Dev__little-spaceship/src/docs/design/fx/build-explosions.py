"""Generate the four explosion animations as PNG frame strips.

    python docs/design/fx/build-explosions.py

Writes, next to this script, one strip per size plus a specimen contact sheet:

    fx-explosion-small.png    5 frames of 21x21   basic, light, shooter, rush, projectiles
    fx-explosion-medium.png   6 frames of 31x31   tank, structures, the player
    fx-explosion-large.png    8 frames of 47x47   carrier, boss parts
    fx-explosion-boss.png    10 frames of 95x95   the final chain
    specimen.png              all four, stacked, at 3x on N2

Explosions are generated rather than drawn, and that is a decision rather than a shortcut. What an
explosion is, at this resolution, is an expanding annulus running down the fire ramp with the ring
breaking into fragments as it goes -- 29 frames of it hand-drawn would be 29 chances to put a pixel
where the physics does not, and none of the 29 is a shape the player ever looks at for more than
16 ms. The silhouettes that matter are hand-drawn; these are not silhouettes.

Deterministic: the fragment breakup runs off a fixed seed, so the same frames come out every time
and a diff in the strip means somebody changed the recipe.

Colours are gameplay-only, from the fire ramp of docs/design/01-palette.md: W3 -> W4 -> F1, with N0
as the outline every frame carries. F1 appears only in the first two frames of any explosion, which
is what keeps rule 3's brightest pixels tied to the moment of destruction rather than smeared over
the whole animation.
"""
import math
import pathlib
import struct
import zlib

HERE = pathlib.Path(__file__).parent

N0 = (0x0B, 0x0E, 0x14)
W3 = (0xE5, 0x82, 0x2C)
W4 = (0xFF, 0xC9, 0x4A)
F1 = (0xFF, 0xF6, 0xD9)
CLEAR = (0, 0, 0, 0)

SIZES = [("small", 21, 5), ("medium", 31, 6), ("large", 47, 8), ("boss", 95, 10)]


def rng(seed):
    state = [seed & 0xFFFFFFFF]

    def next_float():
        # xorshift32; any cheap deterministic source will do, the point is that it is fixed
        x = state[0]
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        state[0] = x
        return x / 0xFFFFFFFF

    return next_float


def frame(size, index, count, seed):
    """One frame: an annulus whose outer edge expands and whose inner edge expands faster."""
    r = (size - 1) / 2.0
    t = (index + 0.5) / count
    outer = r * (0.35 + 0.65 * t)
    inner = r * max(0.0, (t - 0.32) / 0.68) ** 0.8 * 0.95
    # How ragged the ring is: smooth at first, breaking apart as it thins. Capped low on purpose --
    # at 0.75 the last frames dissolved into single scattered pixels, and scattered pixels at 1x are
    # noise, which is what R7 of 05-legibility-rules.md says bullets hide in. The explosion has to
    # end as chunks, not as dust.
    ragged = 0.10 + 0.40 * t
    noise = rng(seed)
    wobble = [1.0 + ragged * (noise() - 0.5) for _ in range(64)]

    pixels = [[CLEAR] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            dx, dy = x - r, y - r
            d = math.hypot(dx, dy)
            if d < 0.5:
                d = 0.5
            sector = int((math.atan2(dy, dx) + math.pi) / (2 * math.pi) * 64) % 64
            k = wobble[sector]
            lo, hi = inner * k, outer * k
            if not (lo <= d <= hi):
                continue
            band = (d - lo) / max(hi - lo, 1e-6)   # 0 inside edge, 1 outside edge
            if band > 0.86:
                colour = N0
            elif t < 0.34 and band < 0.30:
                colour = F1
            elif band < 0.55:
                colour = W4
            else:
                colour = W3
            pixels[y][x] = colour + (255,)

    # close the outline: every lit pixel touching transparency becomes N0
    lit = [[pixels[y][x][3] > 0 for x in range(size)] for y in range(size)]
    for y in range(size):
        for x in range(size):
            if not lit[y][x]:
                continue
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if not (0 <= ny < size and 0 <= nx < size) or not lit[ny][nx]:
                    pixels[y][x] = N0 + (255,)
                    break
    return pixels


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


def main():
    specimen_rows = []
    for name, size, count in SIZES:
        frames = [frame(size, i, count, 0x5EED + size) for i in range(count)]
        strip = [[CLEAR] * (size * count) for _ in range(size)]
        for i, f in enumerate(frames):
            for y in range(size):
                for x in range(size):
                    strip[y][i * size + x] = f[y][x]
        write_png(HERE / ("fx-explosion-%s.png" % name), strip, size * count, size)
        print("fx-explosion-%s.png - %d frames of %dx%d" % (name, count, size, size))
        specimen_rows.append(strip)

    ground = (36, 44, 59, 255)
    width = max(len(r[0]) for r in specimen_rows)
    canvas = []
    for strip in specimen_rows:
        for row in strip:
            canvas.append([p if p[3] else ground for p in row] + [ground] * (width - len(row)))
        canvas.append([ground] * width)
    scale = 3
    big = [[canvas[y // scale][x // scale] for x in range(width * scale)]
           for y in range(len(canvas) * scale)]
    write_png(HERE / "specimen.png", big, width * scale, len(canvas) * scale)
    print("specimen.png - %dx%d" % (width * scale, len(canvas) * scale))


if __name__ == "__main__":
    main()
