"""The gameplay scene: input, simulation loop, effects, camera and drawing."""
import math
import random
import pygame

from . import controls
from . import settings as S
from .animation import PlayerAnimator
from .camera import Camera
from .level_manager import compute_rank, compute_score
from .menus import ButtonList, CompleteScene, MainMenuScene, Scene, SettingsScene
from .particles import AmbientFX, ParticleSystem
from .player import Intent
from .render import LevelRenderer, draw_selector
from .ui import Hud, draw_panel, draw_text

ROBOT_COLORS = {"x": S.C_RED, "b": S.C_CYAN}


class PlayScene(Scene):
    def __init__(self, game, index):
        self.game, self.index = game, index
        self.hud = Hud(game.fonts, game.anims)
        self.pause_menu = ButtonList(game, ["CONTINUAR", "REINICIAR FASE", "CONFIGURAÇÕES", "MENU PRINCIPAL"], top=240)
        self.rng = random.Random(9)
        self.paused = False
        self.selected = 0
        self.reset(fade=True)
        game.audio.play_music("game")

    # ------------------------------------------------------------------ (re)start
    def reset(self, fade=False):
        g = self.game
        self.level = g.levels.load(self.index)
        lv = self.level
        self.players = lv.create_players()
        self.animators = [PlayerAnimator(g.anims[p.kind], p) for p in self.players]
        self.camera = Camera(S.SCREEN_W, S.SCREEN_H, lv.pixel_w, lv.pixel_h)
        self.camera.snap(self.players[self.selected].box)
        self.particles = ParticleSystem()
        self.ambient = AmbientFX(lv.theme, S.SCREEN_W, S.SCREEN_H)
        self.background = g.get_background(lv.theme, self.index + 1)
        self.renderer = LevelRenderer(lv, g.fonts)
        self.state = "play"             # play | dying | victory
        self.state_timer = 0.0
        self.jump_pressed = [False, False]
        self.t = 0.0
        self.fade = 1.0 if fade else 0.6

    # ------------------------------------------------------------------ input
    def handle_event(self, e):
        g = self.game
        if self.paused:
            if e.type == pygame.KEYDOWN and e.key == controls.KEY_PAUSE:
                self.paused = False
                return
            i = self.pause_menu.handle_event(e)
            if i == 0:
                self.paused = False
            elif i == 1:
                self.paused = False
                self.reset()
            elif i == 2:
                g.change_scene(SettingsScene(g, self))
            elif i == 3:
                g.change_scene(MainMenuScene(g))
            return
        if e.type != pygame.KEYDOWN:
            return
        k = e.key
        if k == controls.KEY_PAUSE:
            self.paused = True
            self.pause_menu.selected = 0
        elif k == controls.KEY_RESTART:
            self.reset()
        elif k == controls.KEY_SWITCH:
            self.selected = 1 - self.selected
            g.audio.play("menu_move", 0.6)
        elif k in controls.KEY_SELECT:
            self.selected = controls.KEY_SELECT[k]
            g.audio.play("menu_move", 0.6)
        else:
            single = g.save.settings["control_mode"] == "single"
            for i, kind in enumerate(("x", "b")):
                if k == controls.BINDINGS[kind]["jump"]:
                    if single:
                        self.jump_pressed[self.selected] = True
                    else:
                        self.jump_pressed[i] = True

    def _intents(self):
        if self.state != "play":
            self.jump_pressed = [False, False]
            return [Intent(), Intent()]
        keys = pygame.key.get_pressed()
        raw = []
        for kind in ("x", "b"):
            b = controls.BINDINGS[kind]
            raw.append((keys[b["left"]], keys[b["right"]], keys[b["jump"]]))
        if self.game.save.settings["control_mode"] == "single":      # only the focused robot moves
            merged = tuple(any(r[j] for r in raw) for j in range(3))
            raw = [merged if i == self.selected else (False, False, False) for i in range(2)]
        out = []
        for i, (l, r, j) in enumerate(raw):
            out.append(Intent((1 if r else 0) - (1 if l else 0), self.jump_pressed[i], bool(j)))
        self.jump_pressed = [False, False]
        return out

    # ------------------------------------------------------------------ simulation
    def update(self, dt):
        if self.paused:
            return
        g, lv = self.game, self.level
        self.t += dt
        self.fade = max(0.0, self.fade - dt * 1.6)
        intents = self._intents()

        for ev in lv.update_mechanisms(dt, self.players):
            g.audio.play("switch" if ev.startswith("switch") else "door", 0.7)
        for p, it in zip(self.players, intents):
            p.update(dt, it, lv)
        for ev in lv.post_update(dt, self.players):
            self._on_level_event(ev)
        self._player_events()

        if self.state == "dying":
            self.state_timer += dt
            if self.state_timer >= S.DEATH_RESTART_DELAY:
                self.reset()
                return
        elif self.state == "victory":
            self.state_timer += dt
            if int(self.state_timer * 8) != int((self.state_timer - dt) * 8):
                self.particles.confetti(self.camera.x + self.rng.uniform(100, 900), self.camera.y + 80, 4)
            if self.state_timer >= S.VICTORY_DELAY:
                self._finish()
                return

        for a in self.animators:
            a.update(dt)
        self.particles.update(dt)
        self.ambient.update(dt)
        self.camera.update(self.players[self.selected].box, dt)
        self._ambient_pool_fx(dt)

    def _on_level_event(self, ev):
        g = self.game
        kind = ev[0]
        if kind == "crystal":
            _, p, c = ev
            self.particles.sparkle(c.x, c.y)
            g.audio.play("crystal")
        elif kind == "death":
            _, p, cause = ev
            self.particles.explosion(p.box.centerx, p.box.centery, ROBOT_COLORS[p.kind])
            if cause == "lava":
                self.particles.burst(p.box.centerx, p.box.bottom, (255, 140, 40), 16, 240, 5, 0.8, 500)
            elif cause == "water":
                self.particles.burst(p.box.centerx, p.box.bottom, (140, 210, 255), 16, 240, 5, 0.8, 500)
            self.camera.shake(7, 0.4)
            g.audio.play("death")
            if self.state == "play":
                self.state, self.state_timer = "dying", 0.0
        elif kind == "complete":
            for p in self.players:
                p.celebrate()
            g.audio.play("victory")
            self.state, self.state_timer = "victory", 0.0

    def _player_events(self):
        g = self.game
        for p in self.players:
            for ev in p.events:
                if ev == "jump":
                    g.audio.play("jump", 0.7)
                    self.particles.dust(p.box.centerx, p.box.bottom, 5)
                elif ev == "land":
                    g.audio.play("land", 0.8)
                    self.particles.dust(p.box.centerx, p.box.bottom, 9)
            p.events.clear()

    def _ambient_pool_fx(self, dt):
        cam = self.camera
        for pool in self.level.pools:
            x, y, w, h = pool.rect
            if x + w < cam.x or x > cam.x + S.SCREEN_W:
                continue
            if self.rng.random() < dt * 1.6 * (w / S.TILE):
                px = x + self.rng.uniform(4, w - 4)
                if pool.kind == "lava":
                    self.particles.ember(px, y + 8)
                else:
                    self.particles.bubble(px, y + 12)

    def _finish(self):
        g, lv = self.game, self.level
        rank = compute_rank(lv.time, lv.par_time, lv.crystals_collected, lv.total_crystals)
        score = compute_score(lv.time, lv.par_time, lv.crystals_collected, lv.total_crystals)
        new_best = g.save.record(self.index, lv.time, lv.crystals_collected, rank, score, g.levels.count)
        g.change_scene(CompleteScene(g, self.index, lv.time, lv.crystals_collected, lv.total_crystals,
                                     rank, score, new_best))

    # ------------------------------------------------------------------ drawing
    def draw(self, screen):
        ox, oy = self.camera.offset
        self.background.draw(screen, self.camera.x, self.t)
        self.ambient.draw(screen, self.camera.x)
        self.renderer.draw(screen, ox, oy, self.t, self.players)
        for a in self.animators:
            if a.player.alive or a.time < 0.8:
                a.draw(screen, ox, oy)
        if self.state == "play":
            draw_selector(screen, self.players[self.selected], ox, oy, self.t)
        self.particles.draw(screen, ox, oy)
        self.renderer.draw_lights(screen, ox, oy, self.t, self.players)
        screen.blit(self.game.vignette, (0, 0))

        intro = 0.0
        if self.t < 2.8:
            intro = min(1.0, self.t / 0.4, (2.8 - self.t) / 0.6)
        self.hud.draw(screen, self.level, self.players, self.selected, self.renderer.id_colors, max(0.0, intro))
        if self.state == "dying":
            msg = "Reiniciando..."
            draw_text(screen, self.game.fonts, msg, 26, S.C_WHITE, (S.SCREEN_W // 2, 110), "center")
        elif self.state == "victory":
            draw_text(screen, self.game.fonts, "NÍVEL COMPLETO!", 44, S.C_YELLOW, (S.SCREEN_W // 2, 130), "center")
        if self.fade > 0:
            veil = pygame.Surface((S.SCREEN_W, S.SCREEN_H))
            veil.fill((0, 0, 0))
            veil.set_alpha(int(255 * min(1.0, self.fade)))
            screen.blit(veil, (0, 0))
        if self.paused:
            dim = pygame.Surface((S.SCREEN_W, S.SCREEN_H), pygame.SRCALPHA)
            dim.fill((4, 8, 20, 170))
            screen.blit(dim, (0, 0))
            draw_panel(screen, (300, 130, 400, 400), (12, 20, 46), 235, S.C_UI_ACCENT, 22, 4)
            draw_text(screen, self.game.fonts, "PAUSADO", 44, S.C_WHITE, (S.SCREEN_W // 2, 180), "center")
            self.pause_menu.draw(screen, self.t)
