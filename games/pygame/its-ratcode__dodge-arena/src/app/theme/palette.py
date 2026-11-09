"""The color palette.

All colors live on one shared ``PALETTE`` object that the drawing code reads
at draw time, so changing a color here changes it everywhere, and
``apply_colors`` can recolor the whole game while it runs (color modes).
"""

from dataclasses import dataclass, fields

from app.util.mathx import Color, lerp_color


@dataclass
class Palette:
    """Every color the game uses, grouped by purpose."""

    # Surfaces
    background: Color = (7, 10, 16)          # behind everything
    arena_center: Color = (19, 29, 38)
    arena_edge: Color = (8, 12, 18)
    grid_line: Color = (255, 255, 255)       # drawn with low alpha over the arena
    border: Color = (33, 43, 62)

    # Player
    player: Color = (70, 170, 255)
    player_light: Color = (160, 210, 255)    # highlight
    player_outline: Color = (215, 238, 255)
    marker: Color = (90, 230, 140)           # click-to-move marker

    # Threats
    bolt: Color = (225, 60, 70)
    bolt_core: Color = (255, 150, 140)
    bolt_front: Color = (255, 232, 210)      # bright leading edge shows the flight direction
    laser: Color = (255, 110, 196)
    laser_core: Color = (255, 250, 255)

    # Abilities
    shield: Color = (120, 200, 255)
    wall: Color = (150, 110, 240)
    wall_outline: Color = (230, 210, 255)
    dash: Color = (80, 236, 214)

    # Utility spells
    sprint: Color = (255, 215, 70)
    blink: Color = (255, 236, 130)

    # Power-ups and Second Wind
    stasis: Color = (255, 200, 105)
    time_warp: Color = (130, 150, 255)
    warp: Color = (200, 150, 255)
    nova: Color = (205, 245, 255)
    second_wind: Color = (255, 232, 150)

    # Coins
    coin: Color = (255, 200, 60)
    coin_dark: Color = (170, 110, 20)        # rim
    coin_shine: Color = (255, 246, 210)

    # Interface
    panel_top: Color = (26, 34, 52)          # panels are a vertical gradient top -> bottom
    panel_bottom: Color = (14, 19, 30)
    line: Color = (48, 60, 86)               # panel borders and separators
    row: Color = (22, 29, 44)                # a settings row or sidebar entry ...
    row_hover: Color = (31, 41, 62)          # ... and the same row while focused
    key_face: Color = (40, 50, 72)           # keycaps showing a key binding
    key_shadow: Color = (8, 11, 18)

    # Text and feedback
    text: Color = (236, 240, 248)
    text_dim: Color = (162, 174, 196)
    text_faint: Color = (106, 118, 142)
    accent: Color = (64, 206, 226)           # the interface accent (focus, main buttons); players can pick it
    calm: Color = (64, 206, 226)             # low danger: fixed, so the danger bar reads the same with any accent
    success: Color = (88, 218, 148)          # maxed upgrades, the next level's value
    warning: Color = (250, 196, 80)          # medium danger
    danger: Color = (236, 76, 88)            # high danger, game over
    track: Color = (36, 45, 64)              # empty part of progress bars


PALETTE = Palette()
DEFAULT_PALETTE = Palette()             # untouched copy, to reset from

# --- Color modes -------------------------------------------------------------------------
# Each mode overrides some colors (based on the color-blind-safe Okabe-Ito palette).
# Lighter and darker shades (player_light, bolt_core ...) are derived automatically.
COLOR_MODES: dict[str, dict[str, Color]] = {
    "default": {},
    "deuteranopia": {"player": (86, 180, 233), "bolt": (230, 159, 0), "laser": (240, 228, 66),
                     "marker": (235, 235, 235), "danger": (230, 120, 0)},
    "protanopia": {"player": (86, 180, 233), "bolt": (245, 175, 40), "laser": (240, 228, 66),
                   "marker": (235, 235, 235), "danger": (245, 150, 40)},
    "tritanopia": {"player": (40, 210, 200), "bolt": (235, 50, 60), "laser": (240, 240, 250),
                   "coin": (255, 150, 60), "shield": (150, 230, 230), "marker": (240, 240, 240),
                   "danger": (235, 50, 60), "sprint": (255, 150, 60)},
    "high_contrast": {"arena_center": (8, 9, 12), "arena_edge": (0, 0, 0), "player": (0, 230, 255),
                      "bolt": (255, 45, 45), "laser": (255, 255, 0), "coin": (255, 215, 0),
                      "wall": (190, 140, 255), "marker": (255, 255, 255), "shield": (120, 220, 255)},
}

# Colors a player can pick for the three most important things on screen.
SWATCHES: dict[str, Color | None] = {
    "Auto": None,                       # follow the color mode
    "Blue": (70, 170, 255), "Cyan": (40, 220, 230), "Green": (80, 220, 120), "Yellow": (245, 225, 70),
    "Orange": (240, 150, 40), "Red": (230, 60, 70), "Pink": (255, 110, 196), "Purple": (160, 110, 250),
    "White": (240, 240, 245),
}

WHITE = (255, 255, 255)
# (base color, shade, how far toward white). A shade is re-derived only when its base changed,
# so the hand-tuned default shades stay exactly as they are.
DERIVED_SHADES = (("player", "player_light", 0.45), ("player", "player_outline", 0.75),
                  ("bolt", "bolt_core", 0.45), ("bolt", "bolt_front", 0.82), ("laser", "laser_core", 0.9),
                  ("wall", "wall_outline", 0.7), ("coin", "coin_shine", 0.75))


# The interface accent a player can choose. Cyan is the default: it stays clearly apart from gold coins
# and from the amber and red of the danger bar, also for red-green color blindness.
ACCENTS: dict[str, Color] = {"Cyan": (64, 206, 226), "Gold": (226, 186, 104), "Violet": (164, 142, 255)}


def apply_colors(mode: str, custom: dict[str, str], accent: str = "Cyan") -> None:
    """Reset the palette, apply a color mode, then the player's own picks.

    ``custom`` maps a palette field ("player", "bolt", "laser") to a swatch name;
    ``accent`` is a name from ``ACCENTS``.
    """
    for f in fields(Palette):
        setattr(PALETTE, f.name, getattr(DEFAULT_PALETTE, f.name))
    for name, color in COLOR_MODES.get(mode, {}).items():
        setattr(PALETTE, name, color)
    for name, swatch in custom.items():
        if SWATCHES.get(swatch):
            setattr(PALETTE, name, SWATCHES[swatch])
    PALETTE.accent = ACCENTS.get(accent, DEFAULT_PALETTE.accent)
    for base, shade, toward_white in DERIVED_SHADES:
        if getattr(PALETTE, base) != getattr(DEFAULT_PALETTE, base):
            setattr(PALETTE, shade, lerp_color(getattr(PALETTE, base), WHITE, toward_white))
    if PALETTE.coin != DEFAULT_PALETTE.coin:
        PALETTE.coin_dark = tuple(int(c * 0.66) for c in PALETTE.coin)


def danger_color(level: float) -> Color:
    """Color for a danger level 0..1: calm -> warning -> danger.

    Going through a middle color avoids the muddy grey you get when blending
    cyan straight into red.
    """
    if level < 0.5:
        return lerp_color(PALETTE.calm, PALETTE.warning, level * 2)
    return lerp_color(PALETTE.warning, PALETTE.danger, (level - 0.5) * 2)
