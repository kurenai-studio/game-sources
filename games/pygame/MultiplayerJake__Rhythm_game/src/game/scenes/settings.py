"""Settings: rebind any shortcut, with a scrollable list.

Every shortcut in the game is an action defined in
``game/core/config.py`` (``DEFAULT_KEYS`` / ``GROUPS``); this screen
lists them all, grouped, and scrolls when they do not fit on one screen.
"""

from __future__ import annotations

import pygame

from ..core.config import GROUPS, LABELS
from ..core.scene import Scene
from ..ui import theme
from ..ui.widgets import Button, IconButton

VIEW = pygame.Rect(180, 110, 920, 420)
ROW_H, ROW_GAP = 44, 8
HEAD_H, HEAD_GAP = 30, 6
KEY_W = 150
SCROLL_STEP = 56

# non-keybind controls rendered above the keybind groups
VISUAL_ROWS = (("slider", "volume", "MUSIC VOLUME"),
               ("toggle", "scanlines", "SCANLINES"),
               ("toggle", "particles", "PARTICLES"))


class SettingsScene(Scene):
    def __init__(self, game):
        super().__init__(game)
        self.waiting = None        # action name waiting for a key, else None
        self.focus = 0             # index into self.actions
        self.hover = None          # action name under the mouse
        self.hover_entry = None    # full entry under the mouse
        self.scroll = 0.0
        self._layout()

        self.back = Button((theme.BASE_W // 2 - 80, theme.BASE_H - 102, 160, 46),
                           "BACK", self._back, size=20)

    # ------------------------------------------------------------- layout
    def _layout(self) -> None:
        """Build content-space rows: audio/visual controls + keybinds."""
        self.entries = []          # {"kind", "y", "h", ...}
        self.actions = []          # bindable action names, display order
        self.dragging = None       # slider id while the mouse is held
        y = 0

        self.entries.append({"kind": "head", "title": "AUDIO & VISUALS",
                             "y": y, "h": HEAD_H})
        y += HEAD_H + HEAD_GAP
        for kind, ident, label in VISUAL_ROWS:
            self.entries.append({"kind": kind, "id": ident, "label": label,
                                 "y": y, "h": ROW_H})
            y += ROW_H + ROW_GAP
        y += 10

        for title, actions in GROUPS:
            self.entries.append({"kind": "head", "title": title,
                                 "y": y, "h": HEAD_H})
            y += HEAD_H + HEAD_GAP
            for action in actions:
                self.entries.append({"kind": "row", "action": action,
                                     "y": y, "h": ROW_H})
                self.actions.append(action)
                y += ROW_H + ROW_GAP
            y += 10
        self.content_h = y

    def _max_scroll(self) -> float:
        return max(0.0, self.content_h - VIEW.h)

    def _clamp(self) -> None:
        self.scroll = max(0.0, min(self.scroll, self._max_scroll()))

    def _scroll_into_view(self, entry) -> None:
        top = entry["y"] - self.scroll
        bottom = top + entry["h"]
        if top < 0:
            self.scroll = entry["y"]
        elif bottom > VIEW.h:
            self.scroll = entry["y"] + entry["h"] - VIEW.h
        self._clamp()

    def _screen_rect(self, entry) -> pygame.Rect:
        return pygame.Rect(VIEW.x, VIEW.y + entry["y"] - self.scroll,
                           VIEW.w - 18, entry["h"])

    # ------------------------------------------------------------- actions
    def _start_wait(self, action: str) -> None:
        self.waiting = action

    def _back(self) -> None:
        from .main_menu import MainMenuScene
        self.game.scenes.change(MainMenuScene(self.game))

    # -------------------------------------------------------------- events
    def handle_event(self, event) -> None:
        cfg = self.game.config

        if self.waiting is not None:
            if event.type == pygame.KEYDOWN:
                cfg.set_key(self.waiting, event.key)
                self.waiting = None
            elif event.type == pygame.MOUSEBUTTONDOWN:
                # clicking anywhere else abandons the rebind
                self.waiting = None
                self.handle_event(event)
            return

        if event.type == pygame.MOUSEWHEEL:
            self.scroll -= event.y * SCROLL_STEP
            self._clamp()
            return

        if event.type == pygame.MOUSEMOTION:
            if self.dragging:
                self._drag_volume(event.pos[0])
            entry = self._entry_at(event.pos)
            self.hover_entry = entry
            self.hover = entry.get("action") if entry else None
            return

        if event.type == pygame.MOUSEBUTTONUP:
            self.dragging = None
            return

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.back.handle_event(event):
                return
            entry = self._entry_at(event.pos)
            if entry is None:
                return
            if entry["kind"] == "slider":
                self.dragging = "volume"
                self._drag_volume(event.pos[0])
                return
            if entry["kind"] == "toggle":
                self._toggle(entry["id"])
                return

            rect = self._screen_rect(entry)
            key_rect, trash_rect = self._controls(rect)
            action = entry["action"]
            if trash_rect.collidepoint(event.pos):
                cfg.clear_key(action)
            elif key_rect.collidepoint(event.pos):
                self._start_wait(action)
            else:
                self.focus = self.actions.index(action)
                self._start_wait(action)
            return

        if event.type == pygame.KEYDOWN:
            if event.key == cfg.key("cancel"):
                self._back()
            elif event.key == cfg.key("menu_up"):
                self.focus = max(0, self.focus - 1)
                self._scroll_into_view(self._entry(self.actions[self.focus]))
            elif event.key == cfg.key("menu_down"):
                self.focus = min(len(self.actions) - 1, self.focus + 1)
                self._scroll_into_view(self._entry(self.actions[self.focus]))
            elif (event.key == cfg.key("confirm")
                  or event.key == pygame.K_KP_ENTER):
                self._start_wait(self.actions[self.focus])

    def _entry(self, action: str) -> dict:
        for entry in self.entries:
            if entry["kind"] == "row" and entry["action"] == action:
                return entry
        return self.entries[0]

    def _entry_at(self, pos) -> dict | None:
        for entry in self.entries:
            if entry["kind"] == "head":
                continue
            if self._screen_rect(entry).collidepoint(pos):
                return entry
        return None

    def _action_at(self, pos) -> str | None:
        entry = self._entry_at(pos)
        return entry.get("action") if entry else None

    # ------------------------------------------------------- audio / fx
    def _slider_rect(self, entry) -> pygame.Rect:
        row = self._screen_rect(entry)
        return pygame.Rect(row.x + 330, row.y + 12, row.w - 470, ROW_H - 24)

    def _drag_volume(self, x: float) -> None:
        entry = next(e for e in self.entries if e.get("id") == "volume")
        track = self._slider_rect(entry)
        frac = (x - track.x) / max(track.w, 1)
        value = max(0.0, min(1.0, frac))
        self.game.config.volume = value
        self.game.config.save()
        self.game.audio.set_volume(value)

    def _toggle(self, ident: str) -> None:
        cfg = self.game.config
        if ident == "scanlines":
            cfg.scanlines = not cfg.scanlines
        elif ident == "particles":
            cfg.particles = not cfg.particles
        cfg.save()

    def _row_rect(self, action: str) -> pygame.Rect:
        return self._screen_rect(self._entry(action))

    @staticmethod
    def _controls(row: pygame.Rect):
        key = pygame.Rect(row.right - KEY_W - 52, row.y + 4, KEY_W, ROW_H - 8)
        trash = pygame.Rect(row.right - 44, row.y + 4, ROW_H - 8, ROW_H - 8)
        return key, trash

    # -------------------------------------------------------------- update
    def update(self, dt: float) -> None:
        pass

    # ---------------------------------------------------------------- draw
    def draw(self, surface) -> None:
        theme.title_text(surface, "SETTINGS", theme.BASE_W // 2, 44, 38)

        cfg = self.game.config
        prev = surface.get_clip()
        surface.set_clip(VIEW)
        for entry in self.entries:
            y = VIEW.y + entry["y"] - self.scroll
            if y > VIEW.bottom or y + entry["h"] < VIEW.y:
                continue
            if entry["kind"] == "head":
                theme.draw_text(surface, entry["title"], VIEW.x + 4, y + 4,
                                size=16, color=theme.MAGENTA)
                pygame.draw.line(surface, theme.BORDER,
                                 (VIEW.x + 200, y + 14), (VIEW.right - 24, y + 14))
                continue
            if entry["kind"] == "row":
                self._draw_row(surface, entry, y, cfg)
            elif entry["kind"] == "slider":
                self._draw_slider(surface, entry, y, cfg)
            elif entry["kind"] == "toggle":
                self._draw_toggle(surface, entry, y, cfg)
        surface.set_clip(prev)

        self._draw_scrollbar(surface)
        self.back.draw(surface)

        if self.waiting:
            theme.draw_text(surface,
                            "Press any key to bind it  ·  click elsewhere "
                            "to cancel",
                            theme.BASE_W // 2, VIEW.bottom + 14, 16,
                            color=theme.YELLOW, align="center")
        else:
            theme.draw_text(surface,
                            "Click a shortcut, then press a key  ·  wheel / "
                            "arrow keys scroll  ·  trash clears",
                            theme.BASE_W // 2, VIEW.bottom + 14, 16,
                            color=theme.DIM, align="center")
        theme.draw_text(surface,
                        f"{cfg.label('cancel')} = main menu  ·  "
                        f"{cfg.label('boost')} = boost during a song",
                        theme.BASE_W // 2, VIEW.bottom + 40, 16,
                        color=theme.DIM, align="center")

    def _tile(self, surface, rect, hovered, waiting=False) -> None:
        """CREATE-style row tile: dark fill, border only when hovered/focused."""
        if waiting:
            fill, border = theme.PANEL_LIGHT, theme.YELLOW
        elif hovered:
            fill, border = theme.PANEL, theme.CYAN
        else:
            fill, border = theme.PANEL, None
        theme.panel(surface, rect, fill=fill, border=border, radius=6)

    def _draw_row(self, surface, entry, y: int, cfg) -> None:
        action = entry["action"]
        row = pygame.Rect(VIEW.x, y, VIEW.w - 18, ROW_H)
        waiting = action == self.waiting
        hovered = action == self.focus_action() or action == self.hover
        self._tile(surface, row, hovered, waiting=waiting)

        theme.draw_text(surface, LABELS.get(action, action), row.x + 16,
                        row.y + 12, size=20, color=theme.TEXT)

        key_rect, trash_rect = self._controls(row)
        key_fill = theme.PANEL_LIGHT if waiting else theme.PANEL
        theme.panel(surface, key_rect, fill=key_fill,
                    border=theme.YELLOW if waiting else theme.BORDER,
                    radius=6)
        theme.draw_text(surface,
                        "PRESS A KEY..." if waiting else cfg.label(action),
                        key_rect.centerx, key_rect.y + 12,
                        size=17, color=theme.YELLOW if waiting else theme.WHITE,
                        align="center")

        tb = IconButton(trash_rect, lambda: None)
        tb.hovered = self.hover == action
        tb.draw(surface)

    def _draw_slider(self, surface, entry, y: int, cfg) -> None:
        row = pygame.Rect(VIEW.x, y, VIEW.w - 18, ROW_H)
        self._tile(surface, row, self.hover_entry is entry)
        theme.draw_text(surface, entry["label"], row.x + 16, row.y + 12,
                        size=20, color=theme.TEXT)

        track = self._slider_rect(entry)
        bar = pygame.Rect(track.x, track.centery - 4, track.w, 8)
        theme.alpha_rect(surface, bar, theme.BORDER, 242, radius=4)
        frac = max(0.0, min(1.0, cfg.volume))
        fill_w = int(track.w * frac)
        if fill_w > 0:
            theme.alpha_rect(surface, pygame.Rect(track.x, bar.y, fill_w, 8),
                             theme.CYAN, 255, radius=4)
        pygame.draw.circle(surface, theme.WHITE,
                           (track.x + fill_w, track.centery), 8)
        theme.draw_text(surface, f"{round(frac * 100)}%", row.right - 16,
                        row.y + 11, size=17, color=theme.CYAN, align="right")

    def _draw_toggle(self, surface, entry, y: int, cfg) -> None:
        row = pygame.Rect(VIEW.x, y, VIEW.w - 18, ROW_H)
        self._tile(surface, row, self.hover_entry is entry)
        theme.draw_text(surface, entry["label"], row.x + 16, row.y + 12,
                        size=20, color=theme.TEXT)

        on = cfg.scanlines if entry["id"] == "scanlines" else cfg.particles
        pill = pygame.Rect(row.right - 96, row.y + 11, 76, ROW_H - 22)
        theme.alpha_rect(surface, pill, theme.CYAN if on else theme.BORDER,
                         242, radius=pill.h // 2)
        knob_r = 9
        kx = pill.right - knob_r - 4 if on else pill.x + knob_r + 4
        pygame.draw.circle(surface, theme.WHITE if on else theme.LAVENDER,
                           (kx, pill.centery), knob_r)
        theme.draw_text(surface, "ON" if on else "OFF", pill.x - 14,
                        row.y + 12, size=16,
                        color=theme.CYAN if on else theme.DIM, align="right")

    def focus_action(self) -> str:
        return self.actions[self.focus] if self.actions else ""

    def _draw_scrollbar(self, surface) -> None:
        if self._max_scroll() <= 0:
            return
        track = pygame.Rect(VIEW.right - 12, VIEW.y + 2, 8, VIEW.h - 4)
        pygame.draw.rect(surface, theme.BORDER, track, border_radius=4)
        thumb_h = max(28, int(track.h * VIEW.h / self.content_h))
        frac = self.scroll / self._max_scroll()
        thumb_y = track.y + int((track.h - thumb_h) * frac)
        pygame.draw.rect(surface, theme.MAGENTA,
                         pygame.Rect(track.x, thumb_y, track.w, thumb_h),
                         border_radius=4)
