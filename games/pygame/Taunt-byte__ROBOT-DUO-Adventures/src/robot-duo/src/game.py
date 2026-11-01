"""Application shell: window, main loop, scene switching, shared resources."""
import sys
import pygame

from . import settings as S
from .animation import AnimationSet
from .audio import Audio
from .background import Background
from .level_manager import LevelManager, SaveData
from .menus import MainMenuScene
from .play import PlayScene
from .ui import Fonts, make_vignette


class Game:
    def __init__(self):
        pygame.mixer.pre_init(22050, -16, 1, 512)
        pygame.init()
        pygame.display.set_caption(S.GAME_TITLE)
        self.save = SaveData.load()
        self.screen = None
        self.apply_fullscreen(first=True)
        self.clock = pygame.time.Clock()
        self.running = True

        self.fonts = Fonts()
        self.audio = Audio(self.save.settings)
        self.levels = LevelManager()
        if self.levels.count == 0:
            raise SystemExit("No level files found in %s" % S.LEVELS_DIR)

        # sprites are rendered once; the "hero" set is the large version used on menus
        self.anims = {k: AnimationSet(k) for k in ("x", "b")}
        self.hero = {k: AnimationSet(k, scale=3, states=("idle", "victory")) for k in ("x", "b")}
        self.vignette = make_vignette(S.SCREEN_W, S.SCREEN_H)
        self._bg_cache = {}

        self.scene = None
        self.change_scene(MainMenuScene(self))

    # ------------------------------------------------------------------ helpers
    def apply_fullscreen(self, first=False):
        flags = pygame.SCALED
        if self.save.settings["fullscreen"]:
            flags |= pygame.FULLSCREEN
        try:
            self.screen = pygame.display.set_mode((S.SCREEN_W, S.SCREEN_H), flags)
        except pygame.error:
            self.screen = pygame.display.set_mode((S.SCREEN_W, S.SCREEN_H))

    def get_background(self, theme, seed):
        key = (theme, seed)
        if key not in self._bg_cache:
            self._bg_cache[key] = Background(theme, seed)
        return self._bg_cache[key]

    def change_scene(self, scene):
        self.scene = scene

    def start_level(self, index):
        index = max(0, min(index, self.levels.count - 1))
        self.change_scene(PlayScene(self, index))

    # ------------------------------------------------------------------ main loop
    def run(self):
        while self.running:
            dt = min(self.clock.tick(S.FPS) / 1000.0, S.MAX_DT)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN and event.key == pygame.K_F11:
                    self.save.settings["fullscreen"] = not self.save.settings["fullscreen"]
                    self.apply_fullscreen()
                else:
                    self.scene.handle_event(event)
            self.scene.update(dt)
            self.scene.draw(self.screen)
            pygame.display.flip()
        self.save.save()
        pygame.quit()
