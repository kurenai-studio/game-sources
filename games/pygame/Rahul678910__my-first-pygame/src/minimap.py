"""
minimap.py  –  Phase 3
Minimap overlay: explored-tile tracking, player dot, and exit marker.

Public API
----------
Minimap
    .update(lit_tiles)                      – mark lit tiles as explored
    .draw(surface, dungeon, px, py)         – render the overlay
"""

import pygame

from settings import (
    TILE, COLS, ROWS,
    MINIMAP_WALL, MINIMAP_FLOOR, MINIMAP_PLAYER, MINIMAP_EXIT, MINIMAP_BG,
    T_EMPTY, T_WALL, T_STAIRS,
)

# ── Minimap display constants ─────────────────────────────────────────────────
_SCALE  = 3     # screen pixels per dungeon tile
_MM_W   = COLS * _SCALE
_MM_H   = ROWS * _SCALE
_PAD    = 8     # margin from screen edge (top-right corner)
_BORDER = 2     # border thickness of the minimap panel


class Minimap:
    """
    Tracks which tiles the player has explored and renders a compact map.

    The minimap is drawn in the **top-right** corner of the screen.
    Tiles are shown in three states:
        • Explored wall  → dark purple
        • Explored floor/corridor/door → light purple
        • Stairs         → bright green dot
        • Player         → bright blue dot
        • Unexplored     → not drawn (transparent / hidden)
    """

    def __init__(self):
        self.explored: set = set()   # (col, row) tiles the player has seen

    def update(self, lit_tiles: set) -> None:
        """Permanently reveal all tiles in *lit_tiles*."""
        self.explored |= lit_tiles

    def draw(
        self,
        surface: pygame.Surface,
        dungeon,
        player_x: float,
        player_y: float,
    ) -> None:
        """
        Render the minimap overlay.

        Parameters
        ----------
        surface   : pygame.Surface   Target screen surface.
        dungeon   : Dungeon          Current dungeon (grid + exit_pos).
        player_x  : float            Player pixel X.
        player_y  : float            Player pixel Y.
        """
        total_w = _MM_W + _BORDER * 2
        total_h = _MM_H + _BORDER * 2

        mm = pygame.Surface((total_w, total_h), pygame.SRCALPHA)
        mm.fill((10, 8, 18, 185))                              # translucent bg
        pygame.draw.rect(mm, (80, 70, 120),
                         (0, 0, total_w, total_h), _BORDER)   # border

        # ── Tile pixels ───────────────────────────────────────────────────────
        for r in range(ROWS):
            for c in range(COLS):
                if (c, r) not in self.explored:
                    continue
                tt = dungeon.grid[r][c]
                if tt == T_EMPTY:
                    continue
                locked = getattr(dungeon, "locked_doors", set())
                col = MINIMAP_WALL if tt == T_WALL else \
                      MINIMAP_EXIT if tt == T_STAIRS else \
                      (235, 170, 45) if (c, r) in locked else \
                      MINIMAP_FLOOR
                rx = _BORDER + c * _SCALE
                ry = _BORDER + r * _SCALE
                pygame.draw.rect(mm, col, (rx, ry, _SCALE, _SCALE))

        # ── Merchant marker ───────────────────────────────────────────────────
        if getattr(dungeon, "merchant_spawn", None):
            mc, mr = dungeon.merchant_spawn
            if (mc, mr) in self.explored:
                mx = _BORDER + mc * _SCALE + _SCALE // 2
                my = _BORDER + mr * _SCALE + _SCALE // 2
                pygame.draw.circle(mm, (60, 220, 160), (mx, my), 2)

        # ── Exit marker (blinking) ────────────────────────────────────────────
        ec, er = dungeon.exit_pos
        if (ec, er) in self.explored:
            ex = _BORDER + ec * _SCALE + _SCALE // 2
            ey = _BORDER + er * _SCALE + _SCALE // 2
            blink = (pygame.time.get_ticks() // 400) % 2 == 0
            if blink:
                pygame.draw.circle(mm, MINIMAP_EXIT, (ex, ey), 3)

        # ── Player dot (always on top) ────────────────────────────────────────
        pc = int(player_x) // TILE
        pr = int(player_y) // TILE
        px = _BORDER + pc * _SCALE + _SCALE // 2
        py = _BORDER + pr * _SCALE + _SCALE // 2
        pygame.draw.circle(mm, MINIMAP_PLAYER, (px, py), 3)

        # ── Blit to top-right corner ──────────────────────────────────────────
        screen_x = surface.get_width()  - total_w - _PAD
        screen_y = _PAD
        surface.blit(mm, (screen_x, screen_y))
