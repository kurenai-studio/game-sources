"""Emit the boss half-rows for 01-sprites.js. 47x87 is not hand-typeable."""
import math


def bands(spec):
    """spec: list of (count, width) -> list of widths, one per row."""
    out = []
    for count, width in spec:
        out += [width] * count
    return out


def build(w, h, widths, shade):
    assert len(widths) == h, (len(widths), h)
    cx = (w - 1) // 2
    grid = [['.'] * w for _ in range(h)]
    for y, width in enumerate(widths):
        half = (width - 1) // 2
        for x in range(cx - half, cx + half + 1):
            grid[y][x] = 'v'
    # outline: any filled pixel with an empty or off-grid 4-neighbour
    for y in range(h):
        for x in range(w):
            if grid[y][x] == '.':
                continue
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if not (0 <= ny < h and 0 <= nx < w) or grid[ny][nx] == '.':
                    grid[y][x] = 'k'
                    break
    for y in range(h):
        for x in range(w):
            if grid[y][x] == 'v':
                grid[y][x] = shade(x, y, widths, cx) or 'v'
    return [''.join(row[:cx + 1]) for row in grid]


def emit(name, rows):
    print(name)
    for r in rows:
        print("    '%s'," % r)
    print()


# ---------------------------------------------------------------- core 47x87
CORE_W, CORE_H = 47, 87
CORE = bands([(4, 11), (4, 15), (6, 15), (6, 25), (8, 33), (6, 41),
              (24, 47), (6, 41), (6, 33), (6, 25), (6, 17), (5, 11)])
CORE_CX, CORE_CY = 23, 43


def core_shade(x, y, widths, cx):
    dx = abs(x - cx)
    d = math.hypot(x - CORE_CX, y - CORE_CY)
    if d <= 3.5:
        return 'f'
    if d <= 6.5:
        return 'O'
    if d <= 8.5:
        return 'o'
    if d <= 9.5:
        return 'k'
    if d <= 11.5:
        return 's'
    # the row that starts a wider band is top-lit
    if y > 0 and widths[y] > widths[y - 1]:
        return 'l'
    half = (widths[y] - 1) // 2
    if dx >= half - 1:
        return 's'
    if dx in (9, 10):          # the two ribs that run the whole hull
        return 's'
    return 'v'


# ----------------------------------------------------------------- pod 25x25
POD_W, POD_H = 25, 25
POD = bands([(1, 9), (1, 13), (1, 17), (1, 19), (1, 21), (1, 23),
             (13, 25),
             (1, 23), (1, 21), (1, 19), (1, 17), (1, 13), (1, 9)])
POD_CX, POD_CY = 12, 12


def pod_shade(x, y, widths, cx):
    # At rest the pod's iris is W3 and nothing brighter: beat 1 of the tell fills it W4 and beat 2
    # fills it F1, so a pod that already held W4 would leave the charge nowhere to go. The dark
    # pupil is what keeps a flat W3 disc from reading as a sticker.
    d = math.hypot(x - POD_CX, y - POD_CY)
    if d <= 1.5:
        return 'k'
    if d <= 5.5:
        return 'o'
    if d <= 6.5:
        return 'k'
    if d <= 8.5:
        return 's'
    if y <= 2:
        return 'l'
    return 'v'


# ----------------------------------------------------------------- arm 31x45
ARM_W, ARM_H = 31, 45
ARM = bands([(2, 13), (4, 19), (4, 25), (16, 31), (6, 25), (5, 19), (4, 13), (4, 9)])
ARM_CX, ARM_CY = 15, 22


def arm_shade(x, y, widths, cx):
    dx = abs(x - cx)
    half = (widths[y] - 1) // 2
    if 36 <= y <= 40 and dx <= 2:
        return 'k'
    if 34 <= y <= 42 and dx <= 4:
        return 'o'
    if y <= 1 or (y > 0 and widths[y] > widths[y - 1]):
        return 'l'
    if dx >= half - 1:
        return 's'
    if 10 <= y <= 30 and dx in (5, 6):
        return 's'
    return 'v'


emit('boss-core', build(CORE_W, CORE_H, CORE, core_shade))
emit('boss-pod', build(POD_W, POD_H, POD, pod_shade))
emit('boss-arm', build(ARM_W, ARM_H, ARM, arm_shade))
