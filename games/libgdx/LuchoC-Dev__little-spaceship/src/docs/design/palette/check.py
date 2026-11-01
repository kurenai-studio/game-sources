"""Recomputes and verifies the ls32 palette described in docs/design/01-palette.md.

The visual direction rests on three claims that are cheap to state and easy to break by adding
one colour: a hue band reserved for enemy fire, a lightness ceiling for backgrounds and a
lightness floor for gameplay. This script recomputes them from the hex values so the document
cannot drift away from the palette it describes.

Plain Python, no dependencies:  python docs/design/palette/check.py
"""

import colorsys
import sys

RESERVED_HUE = (320, 350)
BACKGROUND_CEILING = 45.0
GAMEPLAY_FLOOR = 48.0

BACKGROUND = "background"
GAMEPLAY = "gameplay"
HOSTILE = "hostile"
OUTLINE = "outline"

PALETTE = [
    ("N0", "0B0E14", OUTLINE, "void, letterbox, every outline"),
    ("N1", "161B26", BACKGROUND, "deepest background mass"),
    ("N2", "242C3B", BACKGROUND, "background mass, HUD plate"),
    ("N3", "3B475C", BACKGROUND, "background detail, panel frame"),
    ("N4", "5C6B85", BACKGROUND, "distant relief, lit Moon rock, HUD labels"),
    ("B1", "0E1730", BACKGROUND, "night sky, deep space"),
    ("B2", "1A2C55", BACKGROUND, "atmosphere, city haze"),
    ("B3", "2A4680", BACKGROUND, "mid distance, orbital limb"),
    ("T1", "10333A", BACKGROUND, "glass, water, coolant"),
    ("T2", "1C5C63", BACKGROUND, "lit teal surface, signage"),
    ("W1", "43231A", BACKGROUND, "ember, brick, dark rust"),
    ("W2", "8A4020", BACKGROUND, "fire glow below, mid rust"),
    ("G1", "1B4A34", BACKGROUND, "vegetation, dark alien tech"),
    ("V1", "201530", BACKGROUND, "alien dark"),
    ("V2", "382050", BACKGROUND, "alien mid"),
    ("V3", "58347A", BACKGROUND, "biomechanical tissue"),
    ("M1", "2E1A16", BACKGROUND, "organic dark"),
    ("M2", "5E3028", BACKGROUND, "organic mid"),
    ("N5", "8D9CB5", GAMEPLAY, "hull shade"),
    ("N6", "C9D6E8", GAMEPLAY, "hull light"),
    ("N7", "FFFFFF", GAMEPLAY, "white, impact frame, HUD value text"),
    ("C1", "2FBFD4", GAMEPLAY, "player engine, player fire body"),
    ("C2", "9DF2FA", GAMEPLAY, "player fire core"),
    ("W3", "E5822C", GAMEPLAY, "explosion body, human markings"),
    ("W4", "FFC94A", GAMEPLAY, "explosion peak, muzzle flash"),
    ("F1", "FFF6D9", GAMEPLAY, "hottest explosion frame, sparkle"),
    ("G2", "34A75C", GAMEPLAY, "pickup body"),
    ("G3", "7FE08A", GAMEPLAY, "pickup highlight"),
    ("V4", "8E5CB8", GAMEPLAY, "alien hull light"),
    ("H1", "8C0F4B", HOSTILE, "enemy bullet outline"),
    ("H2", "FF3D8A", HOSTILE, "enemy bullet body"),
    ("H3", "FFD9EA", HOSTILE, "enemy bullet core"),
]


def channels(hex_value):
    return tuple(int(hex_value[i:i + 2], 16) for i in (0, 2, 4))


def linear(component):
    c = component / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def lightness(rgb):
    """CIE L* over D65, which is the perceptual measure the palette split is defined in."""
    y = 0.2126 * linear(rgb[0]) + 0.7152 * linear(rgb[1]) + 0.0722 * linear(rgb[2])
    return 116 * (y ** (1 / 3)) - 16 if y > 0.008856 else 903.3 * y


def hue(rgb):
    h, _, _ = colorsys.rgb_to_hsv(*[c / 255.0 for c in rgb])
    return h * 360.0


def reserved(h, rgb):
    """Grey has no meaningful hue, so it can never fall inside the reserved band."""
    return max(rgb) != min(rgb) and RESERVED_HUE[0] <= h <= RESERVED_HUE[1]


def main():
    failures = []
    print(f"{'id':4}{'hex':9}{'H':>5}{'L*':>7}  {'class':11} use")
    for name, hex_value, kind, use in PALETTE:
        rgb = channels(hex_value)
        h, lum = hue(rgb), lightness(rgb)
        print(f"{name:4}#{hex_value:8}{h:5.0f}{lum:7.1f}  {kind:11} {use}")
        if kind != HOSTILE and reserved(h, rgb):
            failures.append(f"{name} enters the reserved hue band at {h:.0f} degrees")
        if kind == BACKGROUND and lum > BACKGROUND_CEILING:
            failures.append(f"{name} breaks the background ceiling at L* {lum:.1f}")
        if kind == GAMEPLAY and lum < GAMEPLAY_FLOOR:
            failures.append(f"{name} falls below the gameplay floor at L* {lum:.1f}")

    if len({name for name, _, _, _ in PALETTE}) != len(PALETTE):
        failures.append("duplicate identifier")
    if len({hex_value for _, hex_value, _, _ in PALETTE}) != len(PALETTE):
        failures.append("duplicate colour")
    if len(PALETTE) != 32:
        failures.append(f"the palette is closed at 32 colours, found {len(PALETTE)}")

    print()
    for failure in failures:
        print("FAIL:", failure)
    if failures:
        return 1
    print(f"ok - {len(PALETTE)} colours, the two sets do not overlap")
    return 0


if __name__ == "__main__":
    sys.exit(main())
