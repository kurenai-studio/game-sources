"""The App owns the window, the Store, the loaded Zones and the current scene."""
from __future__ import annotations

from pathlib import Path

import pygame

from ..persistence.store import Profile, Store
from ..puzzles.schema import Puzzle, Zone
from . import theme
from .fx import Fade

SIZE = (1280, 720)


class Scene:
    def __init__(self, app: "App"):
        self.app = app
        self.buttons = []
        self.fields = []
        self.message = ""

    def handle(self, event) -> None:
        for w in [*self.fields, *self.buttons]:
            if w.handle(event):
                return
        self.on_event(event)

    def on_event(self, event) -> None:
        pass

    def update(self, dt: float) -> None:
        pass

    def draw(self, surf) -> None:
        for f in self.fields:
            f.draw(surf)
        for b in self.buttons:
            b.draw(surf)


class App:
    def __init__(self, store: Store, zones: list[Zone], screen=None, report_dir: Path | None = None):
        self.store = store
        self.zones = zones
        self.screen = screen
        self.report_dir = report_dir
        self.profile: Profile | None = None
        self.running = True
        self.fade = Fade()
        from .scenes.profiles import ProfileScene
        self.scene: Scene = ProfileScene(self)

    # ---- navigation ------------------------------------------------------
    def go(self, scene: Scene) -> None:
        self.scene = scene
        self.fade.start()

    def sign_in(self, profile: Profile) -> None:
        self.profile = profile
        self.open_map()

    def open_map(self) -> None:
        from .scenes.zone_map import ZoneMapScene
        self.go(ZoneMapScene(self))

    def open_zone(self, zone: Zone) -> None:
        from .scenes.zone import ZoneScene
        self.go(ZoneScene(self, zone))

    def open_lesson(self, zone: Zone) -> None:
        from .scenes.lesson import LessonScene
        self.go(LessonScene(self, zone))

    def open_puzzle(self, zone: Zone, puzzle: Puzzle) -> None:
        from .scenes.puzzle import PuzzleScene
        self.go(PuzzleScene(self, zone, puzzle))

    def results(self):
        return self.store.results(self.profile.id) if self.profile else {}

    # ---- loop --------------------------------------------------------------
    def handle(self, event) -> None:
        if event.type == pygame.QUIT:
            self.running = False
            return
        self.scene.handle(event)

    def update(self, dt: float) -> None:
        self.scene.update(dt)
        self.fade.update(dt)

    def draw(self) -> None:
        self.screen.fill(theme.BG)
        self.scene.draw(self.screen)
        self.fade.draw(self.screen, theme.BG)

    def run(self) -> None:
        clock = pygame.time.Clock()
        pygame.key.start_text_input()
        while self.running:
            dt = clock.tick(60) / 1000
            for event in pygame.event.get():
                self.handle(event)
            self.update(dt)
            self.draw()
            pygame.display.flip()
