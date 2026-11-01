"""Play screen: searchable, scrollable level list with saved high scores."""

from __future__ import annotations

import math

import pygame

from ..core.scene import Scene
from ..ui import theme
from ..ui.widgets import Button, TextField

ROW_X, ROW_W, ROW_H, ROW_GAP = 300, 680, 56, 10
PITCH = ROW_H + ROW_GAP          # vertical distance between row tops
ROW_Y0 = 184                     # list sits below the search bar
VISIBLE = 5                      # full rows on screen without scrolling
LIST_H = VISIBLE * PITCH - ROW_GAP
# drawing/hit-test region: rows + selection glow + arrow + scrollbar
VIEW = pygame.Rect(ROW_X - 60, ROW_Y0 - 6, ROW_W + 96, LIST_H + 12)

# display-only difficulty rating derived from note density
_DIFF_BANDS = ((3.0, "EASY", theme.GREEN),
               (5.0, "NORMAL", theme.CYAN),
               (7.0, "HARD", theme.YELLOW),
               (9.0, "EXPERT", theme.MAGENTA),
               (float("inf"), "EXTREME", theme.RED))

# difficulty tuning
_PEAK_WINDOW_MS = 5000      # sliding window for peak density
_PEAK_WEIGHT = 0.65         # how much peak density contributes (vs average)
_STAMINA_THRESHOLD_S = 120  # song length where stamina bonus starts
_STAMINA_RATE = 0.005       # nps per second beyond threshold


def _peak_nps(notes: list, window_ms: int) -> float:
    """Maximum notes per second over any sliding window."""
    if not notes:
        return 0.0
    times = sorted(n["time"] for n in notes)
    max_hits = 0
    left = 0
    for right, t in enumerate(times):
        while times[left] < t - window_ms:
            left += 1
        max_hits = max(max_hits, right - left + 1)
    return max_hits / (window_ms / 1000.0)


def difficulty(info):
    notes = info.notes or []
    if not notes:
        return "EASY", theme.GREEN
    dur = info.end or max((n.get("end") or n.get("time")) for n in notes)
    dur_s = max(dur / 1000.0, 1.0)
    avg_nps = len(notes) / dur_s
    peak = _peak_nps(notes, _PEAK_WINDOW_MS)
    blended = (1.0 - _PEAK_WEIGHT) * avg_nps + _PEAK_WEIGHT * peak

    # stamina bonus for long songs (endurance factor)
    if dur_s > _STAMINA_THRESHOLD_S:
        blended += (dur_s - _STAMINA_THRESHOLD_S) * _STAMINA_RATE

    for limit, name, color in _DIFF_BANDS:
        if blended < limit:
            return name, color
    return "EXPERT", theme.MAGENTA


class PlayListScene(Scene):
    def __init__(self, game):
        super().__init__(game)
        self.levels = game.levels.scan()
        self.filtered = list(self.levels)
        self.selected = 0
        self.scroll = 0.0
        self.search = TextField((410, 134, 460, 38),
                                placeholder="search levels...")
        self.search.active = True       # typing filters right away
        self.back = Button((ROW_X, theme.BASE_H - 92, 160, 46), "BACK",
                           self._back, size=20)

    # ------------------------------------------------------------- helpers
    def _back(self) -> None:
        from .main_menu import MainMenuScene
        self.game.scenes.change(MainMenuScene(self.game))

    def _launch(self, info) -> None:
        if not info.valid:
            return
        from .play import PlayScene
        self.game.scenes.change(PlayScene(self.game, info))

    def _max_scroll(self) -> float:
        return max(0.0, len(self.filtered) * PITCH - ROW_GAP - LIST_H)

    def _clamp(self) -> None:
        self.scroll = max(0.0, min(self.scroll, self._max_scroll()))

    def _row_rect(self, i: int) -> pygame.Rect:
        return pygame.Rect(ROW_X, ROW_Y0 + i * PITCH - int(self.scroll),
                           ROW_W, ROW_H)

    def _scroll_into_view(self, i: int) -> None:
        top = i * PITCH - self.scroll
        if top < 0:
            self.scroll = i * PITCH
        elif top + ROW_H > LIST_H:
            self.scroll = i * PITCH + ROW_H - LIST_H
        self._clamp()

    def _refilter(self) -> None:
        keep = None
        if self.filtered and 0 <= self.selected < len(self.filtered):
            keep = self.filtered[self.selected].name
        query = self.search.text.strip().lower()
        if query:
            self.filtered = [lv for lv in self.levels
                             if query in lv.name.lower()]
        else:
            self.filtered = list(self.levels)
        self.selected = 0
        if keep:
            for idx, lv in enumerate(self.filtered):
                if lv.name == keep:
                    self.selected = idx
                    break
        self.selected = min(self.selected, max(len(self.filtered) - 1, 0))
        self._clamp()
        self._scroll_into_view(self.selected)

    # -------------------------------------------------------------- events
    def handle_event(self, event) -> None:
        cfg = self.game.config

        if self.back.handle_event(event):
            return

        # Enter inside the search bar launches the highlighted match
        if (event.type == pygame.KEYDOWN and self.search.active
                and event.key in (pygame.K_RETURN, pygame.K_KP_ENTER)):
            if self.filtered:
                self._launch(self.filtered[self.selected])
            return

        if self.search.handle_event(event):
            self._refilter()
            return

        if event.type == pygame.MOUSEWHEEL:
            self.scroll -= getattr(event, "precise_y", event.y) * PITCH
            self._clamp()
            return

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if not VIEW.collidepoint(event.pos):
                return
            i = int((event.pos[1] - ROW_Y0 + self.scroll) // PITCH)
            if 0 <= i < len(self.filtered):
                rect = self._row_rect(i)
                if rect.collidepoint(event.pos):
                    self.selected = i
                    if self.filtered[i].valid:
                        self._launch(self.filtered[i])
            return

        if event.type == pygame.KEYDOWN:
            if event.key == cfg.key("cancel"):
                if self.search.text:
                    self.search.text = ""
                    self.search.active = False
                    self._refilter()
                else:
                    self._back()
            elif event.key == cfg.key("menu_up"):
                if self.filtered:
                    self.selected = max(0, self.selected - 1)
                    self._scroll_into_view(self.selected)
            elif event.key == cfg.key("menu_down"):
                if self.filtered:
                    self.selected = min(len(self.filtered) - 1,
                                        self.selected + 1)
                    self._scroll_into_view(self.selected)
            elif (event.key == cfg.key("confirm")
                  or event.key == pygame.K_KP_ENTER):
                if self.filtered:
                    self._launch(self.filtered[self.selected])
            elif (not self.search.active and not self.search.text
                  and getattr(event, "unicode", "")
                  and event.unicode.isprintable()):
                # typing anywhere focuses the search bar
                self.search.active = True
                self.search.text = event.unicode
                self._refilter()

    # -------------------------------------------------------------- update
    def update(self, dt: float) -> None:
        self.search.update(dt)

    # ---------------------------------------------------------------- draw
    def draw(self, surface) -> None:
        theme.title_text(surface, "SELECT TRACK", theme.BASE_W // 2, 54,
                         size=44, glow=theme.MAGENTA)
        theme.draw_text(surface, "— CHOOSE YOUR ARENA —",
                        theme.BASE_W // 2, 110, size=15,
                        color=theme.LAVENDER, align="center")
        self.search.draw(surface)

        if not self.levels:
            theme.draw_text(surface, "No levels yet.",
                            theme.BASE_W // 2, 280, size=26,
                            color=theme.TEXT, align="center")
            theme.draw_text(surface, "Use CREATE in the main menu to add a song.",
                            theme.BASE_W // 2, 320, size=18,
                            color=theme.DIM, align="center")
            self.back.draw(surface)
            return

        if not self.filtered:
            query = self.search.text.strip()
            theme.draw_text(surface, f"No levels match \u201c{query}\u201d",
                            theme.BASE_W // 2, VIEW.centery - 34, size=24,
                            color=theme.TEXT, align="center")
            theme.draw_text(surface,
                            f"{self.game.config.label('cancel')} clears "
                            "the search",
                            theme.BASE_W // 2, VIEW.centery + 4, size=17,
                            color=theme.DIM, align="center")
            self.back.draw(surface)
            return

        pulse = 0.5 + 0.5 * math.sin(pygame.time.get_ticks() / 400.0)
        prev = surface.get_clip()
        surface.set_clip(VIEW)
        for i, info in enumerate(self.filtered):
            rect = self._row_rect(i)
            if rect.bottom < VIEW.y or rect.y > VIEW.bottom:
                continue
            active = i == self.selected
            valid = info.valid
            accent = theme.CYAN if valid else theme.RED

            if active and valid:
                theme.alpha_rect(surface, rect.inflate(14, 10), theme.MAGENTA,
                                 int(45 + 40 * pulse), radius=12)
            fill = theme.PANEL_LIGHT if (active and valid) else theme.PANEL
            border = (theme.CYAN if valid else theme.BORDER) if active \
                else theme.BORDER
            theme.panel(surface, rect, fill=fill, border=border, radius=8,
                        glow=accent if active else None)
            # left accent bar
            theme.alpha_rect(surface, pygame.Rect(rect.x + 4, rect.y + 6, 5,
                                                  rect.h - 12),
                             accent, 255, radius=3)

            name_color = theme.WHITE if valid else theme.DIM
            theme.draw_text(surface, info.name, rect.x + 22, rect.y + 15,
                            size=22, color=name_color,
                            glow=theme.VIOLET if active and valid else None)
            if not valid:
                theme.draw_text(surface, f"BROKEN: {info.error}",
                                rect.x + 220, rect.y + 20, size=14,
                                color=theme.RED)
                continue

            # difficulty badge + high score
            label, color = difficulty(info)
            badge = pygame.Rect(rect.right - 262, rect.y + 13, 96, 30)
            theme.panel(surface, badge, fill=(18, 12, 40), border=color,
                        radius=8)
            theme.draw_text(surface, label, badge.centerx, badge.y + 6,
                            size=15, color=color, align="center")

            high = self.game.save.high_score(info.name)
            if high:
                theme.draw_text(surface, "HIGH SCORE", rect.right - 18,
                                rect.y + 7, size=13, color=theme.LAVENDER,
                                align="right")
                theme.draw_text(surface, f"{high:,}", rect.right - 18,
                                rect.y + 23, size=21, color=theme.YELLOW,
                                align="right")

            if active:
                theme.draw_text(surface, "\u25b6", rect.x - 40, rect.y + 14,
                                size=22, color=theme.WHITE, align="center",
                                glow=theme.CYAN)
        surface.set_clip(prev)

        self._draw_scrollbar(surface)

        count = (f"{len(self.filtered)}/{len(self.levels)} level(s)"
                 if self.search.text.strip() else
                 f"{len(self.levels)} level(s)")
        parts = [f"{self.game.config.label('confirm')} = play",
                 f"{self.game.config.label('cancel')} = "
                 + ("clear search" if self.search.text.strip() else "back"),
                 count]
        if len(self.filtered) > VISIBLE:
            parts.append("wheel scrolls")
        theme.draw_text(surface, "  ·  ".join(parts),
                        theme.BASE_W // 2, theme.BASE_H - 150, size=16,
                        color=theme.DIM, align="center")
        self.back.draw(surface)

    def _draw_scrollbar(self, surface) -> None:
        if self._max_scroll() <= 0:
            return
        track = pygame.Rect(VIEW.right - 14, VIEW.y + 2, 8, VIEW.h - 4)
        pygame.draw.rect(surface, theme.BORDER, track, border_radius=4)
        content_h = len(self.filtered) * PITCH - ROW_GAP
        thumb_h = max(28, int(track.h * LIST_H / content_h))
        frac = self.scroll / self._max_scroll()
        thumb_y = track.y + int((track.h - thumb_h) * frac)
        pygame.draw.rect(surface, theme.MAGENTA,
                         pygame.Rect(track.x, thumb_y, track.w, thumb_h),
                         border_radius=4)
