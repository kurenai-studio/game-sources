"""The Code Mirror panel: shows a snippet and highlights the line that matches
the Step currently playing."""
from __future__ import annotations

import pygame

from ..codemirror import library
from . import theme


class CodePanel:
    def __init__(self, rect: pygame.Rect, language: str):
        self.rect = rect
        self.language = language
        self.snippet: library.Snippet | None = None
        self.table: tuple[list[str], list[tuple[str, list[str]]]] | None = None
        self.table_title = ""
        self.bar_y: float | None = None
        self._goal_y: float | None = None

    def update(self, dt: float) -> None:
        if self._goal_y is None:
            return
        if self.bar_y is None:
            self.bar_y = self._goal_y
        self.bar_y += (self._goal_y - self.bar_y) * min(1.0, 18 * dt)

    def show(self, key: str | None) -> None:
        if key:
            snippet = library.load(key, self.language)
            if snippet:
                self.snippet, self.table = snippet, None

    def show_table(self, table, title: str = "Big-O for this job") -> None:
        """Select Puzzles and the Nexus Lesson: a Big-O table in place of code, as (operations, rows)."""
        self.table, self.table_title, self.snippet = table, title, None

    def show_for(self, structure: str, op: str, preferred: str = "") -> None:
        self.show(preferred or library.DEFAULT_BY_OP.get((structure, op)))

    def draw(self, surf, step_kind: str | None) -> None:
        theme.panel(surf, self.rect)
        label = "CODE MIRROR · " + ("Java" if self.language == "java" else "Python")
        theme.draw_text(surf, label, (self.rect.x + 14, self.rect.y + 10), 15, theme.MUTED, bold=True)
        if self.table:
            self._draw_table(surf)
            return
        if not self.snippet:
            return
        active = set(self.snippet.lines_for(step_kind)) if step_kind else set()
        longest = max((len(l) for l in self.snippet.lines), default=1)
        f = theme.font(max(11, min(15, int((self.rect.w - 30) / (longest * 0.55)))), mono=True)
        top, lh = self.rect.y + 40, f.get_linesize()
        self._goal_y = top + min(active) * lh if active else None
        if self._goal_y is None:
            self.bar_y = None
        clip = surf.get_clip()
        surf.set_clip(self.rect.inflate(-8, -8))
        if self.bar_y is not None:
            pygame.draw.rect(surf, (70, 62, 25), (self.rect.x + 6, self.bar_y - 1, self.rect.w - 12, lh + 2),
                             border_radius=4)
            pygame.draw.rect(surf, theme.ACTIVE, (self.rect.x + 6, self.bar_y - 1, 4, lh + 2))
        y = top
        for i, line in enumerate(self.snippet.lines):
            img = f.render(line.replace("\t", "    "), True, theme.TEXT if i in active else (185, 195, 215))
            surf.blit(img, (self.rect.x + 16, y))
            y += f.get_linesize()
        surf.set_clip(clip)

    def _draw_table(self, surf) -> None:
        """One row per operation, one column per structure: the same in Java and Python."""
        ops, rows = self.table
        x0, y = self.rect.x + 14, self.rect.y + 44
        theme.draw_text(surf, self.table_title, (x0, y), 18, theme.TEXT, bold=True)
        y += 34
        op_w = 118
        col_w = (self.rect.right - 14 - x0 - op_w) / max(1, len(rows))
        centres = [x0 + op_w + col_w * (k + 0.5) for k in range(len(rows))]
        bottom = y
        for cx, (name, _) in zip(centres, rows):
            bottom = max(bottom, theme.draw_text(surf, name, (cx, y), 14, theme.MUTED, bold=True,
                                                 width=int(col_w) - 4, center=True))
        y = bottom + 8
        for i, op in enumerate(ops):
            pygame.draw.line(surf, theme.PANEL_EDGE, (x0, y - 4), (self.rect.right - 14, y - 4))
            end = theme.draw_text(surf, op, (x0, y + 2), 14, theme.TEXT, width=op_w - 8)
            for cx, (_, cells) in zip(centres, rows):
                cell = cells[i]
                colour = theme.MUTED if cell == "—" else (theme.GOOD if cell == "O(1)" else theme.ACTIVE)
                theme.draw_text(surf, cell, (cx, y + 4), 16, colour, mono=True, center=True)
            y = max(end, y + 24) + 6
        theme.draw_text(surf, "— means it can't do that at all.", (x0, y + 6), 13, theme.MUTED)
