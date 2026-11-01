"""The Zone Map: Zones as nodes, paths between them, and profile actions."""
from __future__ import annotations

import pygame

from ...persistence import progress, report
from .. import theme
from ..app import SIZE, Scene
from ..widgets import Button, Row

MAP = pygame.Rect(40, 110, SIZE[0] - 80, SIZE[1] - 210)
SPEEDS = (0.5, 1.0, 2.0)
ACTIONS_Y = SIZE[1] - 72      # the row of profile actions; messages sit just above it


def _reason(error: OSError) -> str:
    """Why a file couldn't be written, in words a student can pass on."""
    if isinstance(error, PermissionError):
        return "the folder is locked, or this PC doesn't allow saving there."
    if isinstance(error, (FileExistsError, NotADirectoryError)):
        return "something that isn't a folder is in the way."
    if isinstance(error, FileNotFoundError):
        return "that folder or drive isn't available, or its name is too long."
    if error.strerror:
        return f"{error.strerror}."
    return "something went wrong while saving the file."


class ZoneMapScene(Scene):
    def __init__(self, app):
        super().__init__(app)
        self.message_colour = theme.GOOD
        self._build()

    def _pos(self, zone):
        return (int(MAP.x + zone.map_pos[0] * MAP.w), int(MAP.y + zone.map_pos[1] * MAP.h))

    def _build(self):
        results = self.app.results()
        self.buttons = []
        for z in self.app.zones:
            x, y = self._pos(z)
            w = max(220, theme.font(20).size(z.name)[0] + 40)
            open_ = progress.zone_unlocked(z, self.app.zones, results)
            self.buttons.append(Button(z.name, pygame.Rect(x - w // 2, y - 24, w, 48),
                                       lambda z=z: self.app.open_zone(z), enabled=open_, accent=z.color))
        row = Row(40, ACTIONS_Y)
        lang = self.app.profile.language
        self.buttons += [
            row.add("Export Progress Report", self._export, accent=theme.GOOD),
            row.add(f"Code: {'Java' if lang == 'java' else 'Python'}", self._toggle_language),
            row.add(f"Speed: {self.app.profile.speed:g}x", self._cycle_speed),
            row.add("Achievements", self._achievements),
            row.add("Switch Profile", self._switch),
        ]

    def _export(self):
        folder = self.app.report_dir or report.default_folder()
        try:
            path = report.export(self.app.profile, self.app.results(), self.app.zones, folder)
        except OSError as e:
            self.message = (f"Your Progress Report couldn't be saved in {folder}: {_reason(e)} "
                            "Try again, or show this message to your instructor.")
            self.message_colour = theme.BAD
            return
        self.message = f"Saved {path}. Attach this file to your Google Classroom assignment."
        self.message_colour = theme.GOOD

    def _toggle_language(self):
        p = self.app.profile
        p.language = "python" if p.language == "java" else "java"
        self.app.store.update_profile(p)
        self._build()

    def _cycle_speed(self):
        p = self.app.profile
        later = [s for s in SPEEDS if s > p.speed]
        p.speed = min(later) if later else SPEEDS[0]
        self.app.store.update_profile(p)
        self._build()

    def _achievements(self):
        from .achievements import AchievementsScene
        self.app.go(AchievementsScene(self.app))

    def _switch(self):
        from .profiles import ProfileScene
        self.app.profile = None
        self.app.go(ProfileScene(self.app))

    def draw(self, surf):
        p = self.app.profile
        theme.draw_text(surf, "The Datasphere", (40, 24), 34, bold=True)
        theme.draw_text(surf, f"{p.name}  ·  {p.student_id}", (40, 68), 18, theme.MUTED)
        results = self.app.results()
        by_id = {z.id: z for z in self.app.zones}
        for z in self.app.zones:
            for r in z.requires:
                if r in by_id:
                    pygame.draw.line(surf, theme.PANEL_EDGE, self._pos(by_id[r]), self._pos(z), 4)
        super().draw(surf)
        for z in self.app.zones:
            got, total = progress.zone_stars(z, results)
            x, y = self._pos(z)
            if progress.zone_unlocked(z, self.app.zones, results):
                theme.stars(surf, (x - 34, y + 41), 1, size=16, total=1)
                theme.draw_text(surf, f"{got} / {total}", (x + 8, y + 30), 17, theme.STAR, center=True)
            else:
                theme.draw_text(surf, "locked", (x, y + 30), 17, theme.DISABLED, center=True)
        theme.draw_text(surf, "More Zones open as they are built.", (SIZE[0] - 40 - 320, 68), 17, theme.MUTED)
        if self.message:
            f, width = theme.font(17), SIZE[0] - 80
            height = len(theme.wrap(self.message, f, width)) * f.get_linesize()
            theme.draw_text(surf, self.message, (40, ACTIONS_Y - 10 - height), 17, self.message_colour, width=width)
