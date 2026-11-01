"""A Lesson: narrated beats that animate the model with the Code Mirror in sync."""
from __future__ import annotations

import pygame

from ...models import complexity, make
from .. import theme
from ..anim import StepPlayer
from ..app import SIZE, Scene
from ..code_panel import CodePanel
from ..fx import Effects
from ..renderers import make_renderer
from ..widgets import Button

VIZ = pygame.Rect(30, 120, 820, 400)
CODE = pygame.Rect(870, 120, 380, 400)
COMPARED = ["array", "linked_list", "stack", "queue"]


class LessonScene(Scene):
    def __init__(self, app, zone):
        super().__init__(app)
        self.zone = zone
        self.lesson = zone.lesson
        self.model = make(self.lesson.structure, self.lesson.initial)
        self.renderer = make_renderer(self.lesson.structure, VIZ, app.profile.speed)
        self.renderer.sync(self.model)
        self.player = StepPlayer(app.profile.speed)
        self.code_panel = CodePanel(CODE, app.profile.language)
        self.index = -1
        self.fx = Effects()
        self._next()

    def _next(self):
        if self.index + 1 >= len(self.lesson.beats):
            return
        self.index += 1
        beat = self.lesson.beats[self.index]
        if beat.structure:                               # a Nexus Lesson compares structures in turn
            self.model = make(beat.structure, beat.initial)
            self.renderer = make_renderer(beat.structure, VIZ, self.app.profile.speed)
            self.renderer.sync(self.model)
        if beat.big_o:
            self.code_panel.show_table(complexity.table(COMPARED, {op: 1 for op in beat.big_o}), "Big-O compared")
        for line in beat.do:
            for move in self.model.parse(line):
                self.code_panel.show_for(self.model.structure, move.op, beat.code)
                self.player.play(self.model.apply(move))
                self.renderer.sync(self.model)
        for line in beat.do:
            if line.startswith("visit"):
                self.fx.ripple(self.renderer.center_of(int(line.split()[1])), theme.ACTIVE, radius=70)
        last = self.index == len(self.lesson.beats) - 1
        bar = SIZE[1] - 72
        self.buttons = [Button("Back", pygame.Rect(40, bar, 140, 44), lambda: self.app.open_zone(self.zone))]
        if last:
            self.buttons.append(Button("Finish Lesson", pygame.Rect(SIZE[0] - 240, bar, 200, 44),
                                       lambda: self.app.open_zone(self.zone), accent=theme.GOOD))
        else:
            self.buttons.append(Button("Next", pygame.Rect(SIZE[0] - 180, bar, 140, 44), self._next,
                                       accent=self.zone.color))

    def on_event(self, event):
        if event.type == pygame.KEYDOWN and event.key in (pygame.K_SPACE, pygame.K_RIGHT):
            self._next()

    def update(self, dt):
        self.player.update(dt)
        self.renderer.on_step(self.player.current)
        self.renderer.update(dt)
        self.code_panel.update(dt)
        self.fx.update(dt)

    def draw(self, surf):
        theme.draw_text(surf, f"{self.zone.name} · Lesson", (40, 26), 30, self.zone.color, bold=True)
        theme.draw_text(surf, f"{self.index + 1} / {len(self.lesson.beats)}", (40, 70), 18, theme.MUTED)
        theme.panel(surf, VIZ)
        self.renderer.draw(surf, self.player.highlights())
        step = self.player.current
        self.code_panel.draw(surf, step.kind if step else None)
        box = pygame.Rect(30, 535, SIZE[0] - 60, 90)
        theme.panel(surf, box)
        y = theme.draw_text(surf, self.lesson.beats[self.index].say, (box.x + 18, box.y + 14), 21,
                            width=box.w - 36)
        if step and step.text:
            theme.draw_text(surf, step.text, (box.x + 18, y + 4), 17, theme.ACTIVE)
        super().draw(surf)
        self.fx.draw(surf)
