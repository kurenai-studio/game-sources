"""Shared constants for the 2048 game (logic + UI)."""

from __future__ import annotations

# Board
ROWS = 4
COLS = 4
WIN_VALUE = 2048

# Window / animation
FPS = 60
WIDTH = 500
HEIGHT = 620  # extra room for score header
BOARD_SIZE = 500
HEADER_HEIGHT = HEIGHT - BOARD_SIZE
GRID_PADDING = 12
CELL_GAP = 10

MOVE_VEL = 25  # pixels per animation frame

# Colors (classic 2048 palette)
BACKGROUND_COLOR = (250, 248, 239)
BOARD_COLOR = (187, 173, 160)
HEADER_COLOR = (250, 248, 239)
SCORE_BOX_COLOR = (187, 173, 160)
FONT_DARK = (119, 110, 101)
FONT_LIGHT = (249, 246, 242)
WHITE = (255, 255, 255)

# Tile background by exponent of 2 (2^1=2 → index 0). Last color reused for huge tiles.
TILE_COLORS: dict[int, tuple[int, int, int]] = {
    0: (205, 193, 180),  # empty
    2: (238, 228, 218),
    4: (237, 224, 200),
    8: (242, 177, 121),
    16: (245, 149, 99),
    32: (246, 124, 95),
    64: (246, 94, 59),
    128: (237, 207, 114),
    256: (237, 204, 97),
    512: (237, 200, 80),
    1024: (237, 197, 63),
    2048: (237, 194, 46),
}
TILE_COLOR_FALLBACK = (60, 58, 50)

# Light text on darker tiles (8+)
LIGHT_TEXT_FROM = 8
