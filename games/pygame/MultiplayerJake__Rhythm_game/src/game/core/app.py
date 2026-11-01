"""Game core: window, main loop, service wiring, screen-space scaling.

The whole game is authored against a 1280x720 design surface which is
scaled uniformly (letterboxed) onto a borderless window the size of the
desktop. This behaves like fullscreen but never minimizes when focus is
lost (file dialogs, alt-tab). Mouse events are converted back into
design-space coordinates before they reach the active scene.
"""

from __future__ import annotations

import os
import sys

import pygame

from ..services.audio import AudioEngine
from ..services.levels import LevelLibrary
from ..services.save_system import SaveSystem
from .config import Config
from .scene_manager import SceneManager
from ..ui import theme
from ..ui.effects import Backdrop


class Game:
    def __init__(self):
        pygame.init()
        try:
            pygame.mixer.init(44100, -16, 2, 512)
        except pygame.error as exc:
            print(f"[audio] mixer init failed: {exc}")
            pygame.quit()
            raise SystemExit(1)

        os.makedirs("music_levels", exist_ok=True)

        self.config = Config()
        self.save = SaveSystem()
        self.levels = LevelLibrary()
        self.audio = AudioEngine()
        self.audio.set_volume(self.config.volume)

        # borderless windowed fullscreen: same look as native fullscreen,
        # but alt-tab / file dialogs no longer minimize the game
        info = pygame.display.Info()
        self.screen = pygame.display.set_mode((info.current_w, info.current_h),
                                              pygame.NOFRAME)
        self.base = pygame.Surface((theme.BASE_W, theme.BASE_H))
        pygame.display.set_caption("Rhythm Fest")

        self.scenes = SceneManager()
        self.clock = pygame.time.Clock()
        self.running = True
        self.backdrop = Backdrop()

        self._scale = 1.0
        self._offset = (0, 0)
        self._compute_transform()

        from ..scenes.main_menu import MainMenuScene
        self.scenes.change(MainMenuScene(self))

    # ------------------------------------------------------------- scaling
    def _compute_transform(self) -> None:
        w, h = self.screen.get_size()
        scale = min(w / theme.BASE_W, h / theme.BASE_H)
        self._scale = scale
        self._offset = ((w - theme.BASE_W * scale) // 2,
                        (h - theme.BASE_H * scale) // 2)

    def _to_design(self, pos):
        x, y = pos
        ox, oy = self._offset
        return ((x - ox) / self._scale, (y - oy) / self._scale)

    # --------------------------------------------------------------- loop
    def run(self) -> None:
        while self.running:
            dt = self.clock.tick(60) / 1000.0
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                    continue
                if event.type in (pygame.MOUSEMOTION, pygame.MOUSEBUTTONDOWN,
                                  pygame.MOUSEBUTTONUP):
                    event = pygame.event.Event(
                        event.type,
                        {**event.dict, "pos": self._to_design(event.pos)},
                    )
                self.scenes.handle_event(event)

            self.scenes.update(dt)
            self.base.fill(theme.BG)
            self.backdrop.draw(self.base, dt,
                               particles=self.config.particles)
            self.scenes.draw(self.base)
            if self.config.scanlines:
                theme.scanlines(self.base)

            self.screen.fill((0, 0, 0))
            scaled = pygame.transform.smoothscale(
                self.base,
                (int(theme.BASE_W * self._scale),
                 int(theme.BASE_H * self._scale)),
            )
            self.screen.blit(scaled, self._offset)
            pygame.display.flip()
        self.shutdown()

    def quit(self) -> None:
        self.running = False

    def shutdown(self) -> None:
        try:
            self.audio.stop()
        finally:
            pygame.mixer.quit()
            pygame.quit()
