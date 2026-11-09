"""Generate local Play/App Store graphic placeholders (no network)."""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store-ops" / "assets"


def _chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, w: int, h: int, rgba: bool, pixel_at) -> None:
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            c = pixel_at(x, y, w, h)
            raw.extend(c if rgba else c[:3])
    color = 6 if rgba else 2
    ihdr = struct.pack(">IIBBBBB", w, h, 8, color, 0, 0, 0)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + _chunk(b"IEND", b"")
    )


def _lerp(a: tuple[int, ...], b: tuple[int, ...], t: float) -> tuple[int, ...]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def _in_rect(x: int, y: int, rx: int, ry: int, rw: int, rh: int, rad: int) -> bool:
    cx = min(max(x, rx + rad), rx + rw - rad - 1)
    cy = min(max(y, ry + rad), ry + rh - rad - 1)
    if (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad:
        if rx <= x < rx + rw and ry <= y < ry + rh:
            return True
    return rx + rad <= x < rx + rw - rad and ry <= y < ry + rh


def _gem(x: int, y: int, rx: int, ry: int, s: int, rgb: tuple[int, int, int]) -> tuple[int, int, int] | None:
    if not _in_rect(x, y, rx, ry, s, s, max(4, s // 10)):
        return None
    t = (x - rx) / max(s, 1)
    hi = _lerp(rgb, (255, 255, 255), 0.28)
    lo = _lerp(rgb, (10, 12, 20), 0.25)
    base = _lerp(hi, lo, (y - ry) / max(s, 1) * 0.7 + t * 0.15)
    if y < ry + max(4, s // 7) and x < rx + int(s * 0.62):
        return _lerp(base, (255, 240, 230), 0.45)
    return base


def icon_pixel(x: int, y: int, w: int, h: int) -> tuple[int, int, int, int]:
    t = y / max(h - 1, 1)
    bg = _lerp((8, 11, 20), (18, 28, 48), t)
    stars = ((22, 18), (88, 14), (40, 96), (108, 40), (70, 118))
    scale = w / 128.0
    r, g, b = bg
    for sx, sy in stars:
        dx = x - sx * scale
        dy = y - sy * scale
        if dx * dx + dy * dy < (1.6 * scale) ** 2:
            r, g, b = 210, 220, 255
    pad = int(14 * scale)
    gap = int(8 * scale)
    cell = (w - pad * 2 - gap) // 2
    gems = (
        ((pad, pad), (242, 115, 89)),
        ((pad + cell + gap, pad), (94, 200, 240)),
        ((pad, pad + cell + gap), (110, 224, 138)),
        ((pad + cell + gap, pad + cell + gap), (230, 204, 77)),
    )
    for (gx, gy), col in gems:
        hit = _gem(x, y, gx, gy, cell, col)
        if hit:
            r, g, b = hit
    return (r, g, b, 255)


def feature_pixel(x: int, y: int, w: int, h: int) -> tuple[int, int, int, int]:
    t = x / max(w - 1, 1)
    bg = _lerp((8, 12, 22), (22, 40, 70), t)
    r, g, b = bg
    if (x * 13 + y * 7) % 97 == 0:
        r, g, b = 200, 214, 255
    gems = (
        (80, 90, 140, (242, 115, 89)),
        (250, 70, 160, (94, 200, 240)),
        (430, 110, 120, (110, 224, 138)),
        (620, 80, 150, (230, 204, 77)),
        (800, 100, 130, (200, 122, 250)),
    )
    for gx, gy, s, col in gems:
        hit = _gem(x, y, gx, gy, s, col)
        if hit:
            r, g, b = hit
    # title bar band (no font raster — solid plaque)
    if 40 <= y <= 120 and 40 <= x <= 420:
        r, g, b = _lerp((12, 18, 32), (30, 50, 80), (y - 40) / 80)
    return (r, g, b, 255)


def shot_pixel(kind: int):
    def pixel(x: int, y: int, w: int, h: int) -> tuple[int, int, int, int]:
        t = y / max(h - 1, 1)
        r, g, b = _lerp((6, 8, 16), (16, 24, 40), t)
        hud_h = int(h * 0.11)
        if y < hud_h:
            r, g, b = 14, 20, 34
        board = int(min(w, h) * 0.62)
        ox = (w - board) // 2
        oy = int(h * 0.16)
        cell = board // 8
        palette = (
            (242, 115, 89),
            (94, 200, 240),
            (110, 224, 138),
            (230, 204, 77),
            (200, 122, 250),
            (248, 132, 196),
        )
        pattern = (
            (0, 0, 1),
            (1, 0, 1),
            (3, 2, 2),
            (4, 2, 2),
            (5, 2, 3),
            (2, 5, 0),
            (2, 6, 0),
            (6, 6, 4),
            (7, 6, 4),
        )
        extra = ()
        if kind == 1:
            extra = ((0, 7, 5), (1, 7, 5), (2, 7, 5))
        elif kind == 2:
            extra = tuple((7, i, 3) for i in range(5))
        elif kind == 3:
            extra = ((3, 3, 1), (4, 3, 1), (3, 4, 1), (4, 4, 1))
        filled = {(cx, cy): col for cx, cy, col in pattern + extra}
        if ox <= x < ox + board and oy <= y < oy + board:
            cx = (x - ox) // cell
            cy = (y - oy) // cell
            if 0 <= cx < 8 and 0 <= cy < 8:
                inset = 3
                if (x - ox) % cell < inset or (y - oy) % cell < inset:
                    r, g, b = 10, 14, 24
                elif (cx, cy) in filled:
                    r, g, b = palette[filled[(cx, cy)]]
                else:
                    r, g, b = 22, 28, 42
        tray_y = int(h * 0.78)
        if tray_y <= y < tray_y + int(h * 0.08):
            r, g, b = 18, 26, 40
        return (r, g, b, 255)

    return pixel


def main() -> None:
    write_png(OUT / "play" / "icon-512.png", 512, 512, True, icon_pixel)
    write_png(OUT / "apple" / "icon-1024.png", 1024, 1024, False, icon_pixel)
    write_png(OUT / "play" / "feature-1024x500.png", 1024, 500, False, feature_pixel)
    for i in range(1, 5):
        write_png(OUT / "play" / f"phone-1080x1920-0{i}.png", 1080, 1920, False, shot_pixel(i))
    for i in range(1, 4):
        write_png(OUT / "apple" / f"iphone-6.9-1320x2868-0{i}.png", 1320, 2868, False, shot_pixel(i))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
