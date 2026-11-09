"""The Game: owns the window, the main loop, the profile and the current scene."""

import random

import pygame

from app import config
from app.audio.music import intensity_for
from app.audio.player import AudioPlayer
from app.core.settings import Settings
from app.core.storage import SaveFile
from app.core.world import RunRules, World
from app.meta import APP_NAME
from app.progression.profile import Profile, RunResult
from app.render.arena import build_arena_background, build_vignette
from app.render.text import HintRow
from app.scenes.base import Scene
from app.scenes.game_over import GameOverScene
from app.scenes.guide import GuideScene
from app.scenes.main_menu import MainMenuScene
from app.scenes.pause import PauseScene
from app.scenes.play import PlayScene
from app.scenes.settings import SettingsScene
from app.scenes.shop import ShopScene
from app.theme.accessibility import A11Y
from app.theme.palette import PALETTE, apply_colors
from app.ui.hud import Hud
from app.ui.widgets import set_ui_sound
from app.util.keys import key_label


class Game:
    """Creates the window and runs a frame-rate independent main loop.

    Each frame: handle input -> update by ``dt`` seconds -> draw, all passed on
    to the current ``scene``. A run lives in a ``World``; the ``Profile``
    (coins, upgrades, best time) and the ``Settings`` outlive runs and share
    one save file. Every run is banked exactly
    once, however it ends: hit, restarted, left for the menu, or the window
    closed. ``save_path`` lets tests use their own save file, and ``music=False``
    skips composing the soundtrack (tests don't need it).
    """

    def __init__(self, save_path=None, music: bool = True) -> None:
        pygame.mixer.pre_init(config.AUDIO_RATE, -16, 1, 512)   # before pygame.init: mono 16-bit, low delay
        pygame.init()
        self.screen = pygame.display.set_mode((config.SCREEN_WIDTH, config.SCREEN_HEIGHT))
        pygame.display.set_caption(APP_NAME)
        self.clock = pygame.time.Clock()
        self.hud = Hud()
        self.world_layer = pygame.Surface((config.SCREEN_WIDTH, config.SCREEN_HEIGHT)).convert()
        self.shake = 0.0                            # px; decays every frame
        save_file = SaveFile(save_path)
        self.profile = Profile(save_file)
        self.settings = Settings(save_file)
        self.apply_settings()                       # colors first: the background is drawn with them
        self.settings.on_change = self.apply_settings
        self.audio = AudioPlayer(self.settings, music)     # effects now (~0.5 s); music in another process
        set_ui_sound(self.audio.ui)
        self.world = self.new_world()
        self.result: RunResult | None = None        # what the last banked run was worth
        self.in_run = False                         # a run has started and is not banked yet
        self.scene: Scene = MainMenuScene(self)
        self.running = True
        self.drawn_scene: Scene | None = None          # the scene drawn last frame
        self.fade_from: pygame.Surface | None = None   # its last frame, fading out after a scene change
        self.fade_time = 0.0

    def apply_settings(self) -> None:
        """Push the display settings into the palette and the accessibility flags (after every change)."""
        o = self.settings.options
        apply_colors(o["color_mode"], {"player": o["color_player"], "bolt": o["color_bolt"],
                                       "laser": o["color_laser"]}, o["accent"])
        A11Y.outlines = o["threat_outlines"] or o["color_mode"] == "high_contrast"
        A11Y.reduce_flashing = o["reduce_flashing"]
        A11Y.reduced_motion = o["reduced_motion"]
        self.background = build_arena_background(config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
        self.red_vignette = build_vignette(config.SCREEN_WIDTH, config.SCREEN_HEIGHT, PALETTE.danger, 210)

    def add_shake(self, amount: float) -> None:
        """Shake the arena (not the HUD), unless shake is off or motion is reduced."""
        if self.settings.options["screen_shake"] and not A11Y.reduced_motion:
            self.shake = max(self.shake, amount)

    def shake_offset(self) -> tuple[int, int]:
        a = self.shake
        if a < 0.3:
            return 0, 0
        return round(random.uniform(-a, a)), round(random.uniform(-a, a))

    def new_world(self) -> World:
        """A run with the stats the current upgrades give, the player's key bindings and
        gameplay settings. Gameplay settings are fixed for the run once it starts."""
        o = self.settings.options
        rules = RunRules(start_danger=o["start_danger"] / 100, game_speed=o["game_speed"] / 100,
                         laser_warning=o["laser_warning"] / 100, lasers=o["lasers"])
        return World(self.profile.stats(), self.settings.keybinds, rules)

    # --- Navigation (called by scenes) --------------------------------------------------------
    def start_run(self) -> None:
        self.bank_run()
        self.world = self.new_world()
        self.audio.play("ready")                   # "GO!" follows from the World a moment later
        self.result = None
        self.in_run = True
        self.scene = PlayScene(self)

    def pause(self) -> None:
        if isinstance(self.scene, PlayScene):
            self.scene = PauseScene(self, self.scene)

    def end_run(self) -> None:
        """The player was hit: bank the run and show what it was worth."""
        self.bank_run()
        self.scene = GameOverScene(self)

    def open_main_menu(self) -> None:
        self.bank_run()
        self.scene = MainMenuScene(self)

    def open_shop(self) -> None:
        """The shop returns to whichever screen opened it."""
        self.scene = ShopScene(self, back=self.scene)

    def open_settings(self) -> None:
        self.scene = SettingsScene(self, back=self.scene)

    def open_guide(self) -> None:
        self.scene = GuideScene(self, back=self.scene)

    def quit(self) -> None:
        self.bank_run()
        self.running = False

    def bank_run(self) -> None:
        """Add the current run's coins and time to the profile (saves the file). Safe to call twice."""
        if self.in_run:
            self.in_run = False
            self.result = self.profile.record_run(self.world.survival_time, self.world.coins_picked,
                                                  self.world.rules.counts_for_best)

    # --- Main loop ----------------------------------------------------------------------
    def run(self) -> None:
        while self.running:
            # Clamp dt so a stall (e.g. dragging the window) can't make things jump.
            dt = min(self.clock.tick(config.FPS) / 1000.0, config.MAX_FRAME_DT)
            self.handle_events()
            self.update(dt)
            self.draw()
            pygame.display.flip()
        self.audio.close()                         # stop the music composer if it is still working
        pygame.quit()

    def handle_events(self) -> None:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.quit()
            elif event.type == pygame.WINDOWFOCUSLOST:
                self.scene.on_focus_lost()
            else:
                self.scene.handle_event(event)

    def update(self, dt: float) -> None:
        self.scene.update(dt)
        self.fade_time = max(0.0, self.fade_time - dt)
        self.shake = max(0.0, self.shake - self.shake * config.SHAKE_DECAY * dt - dt)
        self.update_music(dt)

    def update_music(self, dt: float) -> None:
        """Menus play the calm level; a run follows its danger (or a steady level if adaptive music
        is off); pause and the game over card keep the run's music, quieter."""
        mode = self.scene.music
        if mode == "menu":
            intensity = 0
        elif self.settings.options["adaptive_music"]:
            intensity = intensity_for(self.world.danger)
        else:
            intensity = 2
        self.audio.update(dt, intensity, ducked=mode == "ducked")

    # --- Drawing ------------------------------------------------------------------------
    def draw(self) -> None:
        """The scene, and for a moment after the scene changes, the last frame of the old one fading out
        over it, so screens ease in instead of popping."""
        if self.scene is not self.drawn_scene:
            if self.drawn_scene is not None:
                # The screen still holds the old scene's frame. A plain surface (no per-pixel alpha) keeps
                # fading it cheap; a straight copy of the screen would be several times slower to blend.
                if self.fade_from is None:
                    self.fade_from = pygame.Surface(self.screen.get_size())
                self.fade_from.blit(self.screen, (0, 0))
                self.fade_time = config.SCENE_FADE_TIME
            self.drawn_scene = self.scene
        self.scene.draw(self.screen)
        if self.fade_time > 0 and self.fade_from is not None:
            # Starts below fully opaque, so the new screen shows from the first frame. (It also keeps clear of
            # alpha 255, which pygame blends many times slower than any other value.)
            self.fade_from.set_alpha(round(220 * self.fade_time / config.SCENE_FADE_TIME))
            self.screen.blit(self.fade_from, (0, 0))

    def draw_world(self, surface: pygame.Surface) -> None:
        """The arena, the run and the HUD: drawn by play, and behind the pause and game over cards.
        The arena goes on its own layer so screen shake moves it while the HUD stays put."""
        layer = self.world_layer
        layer.blit(self.background, (0, 0))
        self.world.draw(layer, show_path=self.settings.options["show_path"])
        surface.fill(PALETTE.background)
        surface.blit(layer, self.shake_offset())
        o = self.settings.options
        fps = self.clock.get_fps() if o["show_fps"] else None
        hints = self.control_hints() if o["show_hints"] else None
        wallet = self.profile.coins - (self.result.coins if self.result else 0)    # as it was before this run
        mouse = pygame.mouse.get_pos() if isinstance(self.scene, PlayScene) else None   # tooltips only in play
        self.hud.draw(surface, self.world, fps, hints, self.profile.best_time, wallet, mouse)

    def control_hints(self) -> list[HintRow]:
        """The controls cheat-sheet, built from the player's own bindings."""
        s = self.settings
        key = {action: key_label(name) for action, name in s.keybinds.items()}
        mouse = "RMB" if s.move_button == 3 else "LMB"
        return [[([mouse], "Move"), ([key["pause"]], "Pause")],
                [([key["shield"], key["wall"], key["dash"]], "Abilities"), ([key["sprint"], key["blink"]], "Utility"),
                 ([key["powerup"]], "Power-up")]]
