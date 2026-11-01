"""Game loop, screens, progression, collision handling and HUD."""

import math
import random

import pygame

from settings import (BACKGROUND, CYAN, DIFFICULTY_MULTIPLIERS, FPS, GOLD, MUTED,
                      PINK, TITLE, WHITE, SKINS)
from src.audio import Audio
from src.boss import Boss
from src.enemy import Enemy
from src.level import LEVELS, Level
from src.menu import Button
from src.particle import Starfield, burst
from src.player import Player
from src.powerup import PowerUp
from src.save_manager import SaveManager
from src.settings_menu import SettingsMenu


ACHIEVEMENT_INFO = {
    "first_kill": ("FIRST KILL", "Destroy your first enemy"),
    "hundred_kills": ("100 ENEMY KILLS", "Destroy 100 enemies"),
    "first_boss": ("FIRST BOSS DEFEATED", "Defeat a campaign boss"),
    "three_bosses": ("ALL THREE BOSSES", "Defeat every campaign boss"),
    "ten_levels": ("10 SECTORS CLEARED", "Complete all 10 sectors"),
    "no_damage": ("NO DAMAGE LEVEL", "Clear a sector without damage"),
    "high_scorer": ("HIGH SCORE CHAMPION", "Set a new pilot record"),
}


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption(TITLE)
        self.save = SaveManager()
        width, height = (int(value) for value in self.save.data["resolution"].split("x"))
        display_flags = pygame.FULLSCREEN if self.save.data["fullscreen"] else pygame.RESIZABLE
        self.screen = pygame.display.set_mode((width, height), display_flags)
        self.clock = pygame.time.Clock()
        self.width, self.height = self.screen.get_size()
        self.font = pygame.font.Font(None, 34)
        self.small = pygame.font.Font(None, 25)
        self.tiny = pygame.font.Font(None, 19)
        self.title_font = pygame.font.Font(None, 92)
        self.starfield = Starfield(self.width, self.height)
        self.audio = Audio()
        self.audio.set_volumes(
            self.save.data["music_volume"], self.save.data["sfx_volume"],
            self.save.data["master_volume"],
        )
        self.audio.set_music_enabled(self.save.data["music_enabled"])
        self.settings_menu = SettingsMenu()
        self.action_buttons = {}
        self.visible_action_buttons = set()
        self.pending_action = None
        self.pending_action_timer = 0.0
        self.exit_confirm_rect = pygame.Rect(0, 0, 0, 0)
        self.exit_cancel_rect = pygame.Rect(0, 0, 0, 0)
        self.exit_requested = False
        self.transition_alpha = 0
        self.transition_surface = pygame.Surface(self.screen.get_size())
        self.transition_surface.fill((0, 0, 0))
        self.nebula_cache = {}
        self.hud_health_ratio = 1.0
        self.level_damage_taken = False
        self.boss_rewarded = False
        self.pause_overlay_alpha = 0
        self.screen_name = "menu"
        self.previous_screen = "menu"
        self.time = 0.0
        self.menu_planet_y = 0.0
        self.buttons = []
        self._make_menu_buttons()
        self.particles = []
        self.player = None
        self.level = None
        self.level_number = 1
        self.selected_campaign_level = self.save.data["unlocked_level"]
        self.campaign_cards = {}
        self.campaign_launch_rect = pygame.Rect(0, 0, 0, 0)
        self.completion_campaign_rect = pygame.Rect(0, 0, 0, 0)
        self.level_intro_timer = 0.0
        self.campaign_credits_saved = 0
        self.enemies = []
        self.player_bullets = []
        self.enemy_bullets = []
        self.powerups = []
        self.boss = None
        self.last_score = 0
        self.notice = ""
        self.notice_timer = 0.0
        self.shake_timer = 0.0
        self.shake_strength = 0
        self.boss_death_burst_timer = 0.0

    def _make_menu_buttons(self):
        self.buttons = [
            Button("START GAME", "ships"),
            Button("SETTINGS", "settings"),
            Button("HOW TO PLAY", "howto"),
            Button("HIGH SCORES", "scores"),
            Button("EXIT", "exit"),
        ]

    def _set_screen(self, name):
        self.screen_name = name
        self.transition_alpha = 150
        if name == "paused":
            self.pause_overlay_alpha = 0
        if name == "playing":
            self.audio.set_music_mode("boss" if self.boss else "game")
        elif name == "victory":
            self.audio.set_music_mode("victory")
            self.audio.play("victory")
        elif name == "game_over":
            self.audio.set_music_mode("game_over")
            self.audio.play("game_over")
        elif name != "paused" and name != "confirm_exit":
            self.audio.set_music_mode("menu")
        self.audio.play("select")

    def start_game(self, level_number=1, preserve_player=False):
        if not 1 <= level_number <= self.save.data["unlocked_level"]:
            self.notice = "SECTOR LOCKED  •  COMPLETE PREVIOUS SECTORS FIRST"
            self.notice_timer = 2.5
            return False
        self.level_number = level_number
        self.level = Level(level_number)
        self.level_damage_taken = False
        self.boss_rewarded = False
        if not preserve_player or self.player is None:
            self.player = Player(self.width, self.height, self.save.data["ship_skin"])
            self.campaign_credits_saved = 0
        self.enemies = []
        self.player_bullets = []
        self.enemy_bullets = []
        self.powerups = []
        self.particles = []
        self.boss = None
        self.boss_death_burst_timer = 0.0
        self.level_intro_timer = 3.2
        self._set_screen("level_intro")
        self.audio.set_music_mode("game")
        if not preserve_player:
            self.save.data["games_played"] += 1
            self.save.save()
        return True

    def _resize(self, width, height):
        self.width, self.height = max(640, width), max(400, height)
        flags = pygame.FULLSCREEN if self.save.data["fullscreen"] else pygame.RESIZABLE
        self.screen = pygame.display.set_mode((self.width, self.height), flags)
        self.transition_surface = pygame.Surface((self.width, self.height))
        self.transition_surface.fill((0, 0, 0))
        self.nebula_cache.clear()
        self.starfield.resize(self.width, self.height)
        if self.player:
            self.player.resize(self.width, self.height)
        if self.boss:
            self.boss.width = self.width

    def _apply_display_settings(self):
        resolution = self.save.data["resolution"]
        width, height = (int(value) for value in resolution.split("x"))
        flags = pygame.FULLSCREEN if self.save.data["fullscreen"] else pygame.RESIZABLE
        self.screen = pygame.display.set_mode((width, height), flags)
        self.width, self.height = self.screen.get_size()
        self.transition_surface = pygame.Surface((self.width, self.height))
        self.transition_surface.fill((0, 0, 0))
        self.nebula_cache.clear()
        self.starfield.resize(self.width, self.height)
        if self.player:
            self.player.resize(self.width, self.height)
        if self.boss:
            self.boss.width = self.width

    def run(self):
        running = True
        while running:
            dt = min(self.clock.tick(FPS) / 1000.0, 1 / 30)
            self.time += dt
            self.transition_alpha = max(0, self.transition_alpha - int(dt * 900))
            if self.screen_name == "paused":
                self.pause_overlay_alpha = min(190, self.pause_overlay_alpha + int(dt * 900))
            mouse = pygame.mouse.get_pos()
            self.starfield.update(dt, 0.55 if self.screen_name != "playing" else 1.2)
            self.particles = [p for p in self.particles if p.update(dt)]
            self.notice_timer = max(0, self.notice_timer - dt)
            self.shake_timer = max(0.0, self.shake_timer - dt)
            for button in self.buttons:
                button.update(dt, mouse)
            for button in self.action_buttons.values():
                button.update(dt, mouse)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    if self.screen_name == "confirm_exit":
                        running = False
                    else:
                        self._set_screen("confirm_exit")
                elif event.type == pygame.VIDEORESIZE:
                    self._resize(event.w, event.h)
                elif event.type == pygame.KEYDOWN:
                    if not self._handle_key(event.key):
                        running = False
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    self._handle_click(event.pos)
            if self.exit_requested:
                running = False
            self._advance_pending_action(dt)
            if self.screen_name == "playing":
                self._update_game(dt)
            elif self.screen_name == "level_intro":
                self.level_intro_timer = max(0.0, self.level_intro_timer - dt)
                if self.level_intro_timer == 0:
                    self._set_screen("playing")
            self._draw()
            pygame.display.flip()
        self.save.save()
        pygame.quit()

    def _handle_key(self, key):
        self.pending_action = None
        if key == pygame.K_m:
            self.save.data["music_enabled"] = not self.save.data["music_enabled"]
            self.audio.set_music_enabled(self.save.data["music_enabled"])
            self.save.save()
            return True
        if key == pygame.K_ESCAPE:
            if self.screen_name == "confirm_exit":
                self._set_screen("menu")
            elif self.screen_name == "playing":
                self._set_screen("paused")
            elif self.screen_name == "paused":
                self._set_screen("playing")
            elif self.screen_name in ("settings", "howto", "scores", "ships"):
                self._set_screen("menu")
            elif self.screen_name == "campaign":
                self._set_screen("ships")
            elif self.screen_name == "level_intro":
                self.selected_campaign_level = self.save.data["unlocked_level"]
                self._set_screen("campaign")
            elif self.screen_name == "level_complete":
                self.selected_campaign_level = self.save.data["unlocked_level"]
                self._set_screen("campaign")
            elif self.screen_name in ("game_over", "victory"):
                self._set_screen("menu")
            return True
        if key == pygame.K_SPACE and self.screen_name == "playing":
            self._fire_player_weapon()
            return True
        if key in (pygame.K_RETURN, pygame.K_SPACE):
            if self.screen_name == "menu":
                self._set_screen("ships")
            elif self.screen_name == "ships":
                self.selected_campaign_level = self.save.data["unlocked_level"]
                self._set_screen("campaign")
            elif self.screen_name == "campaign":
                self.start_game(self.selected_campaign_level)
            elif self.screen_name == "level_intro":
                self.level_intro_timer = 0
                self._set_screen("playing")
            elif self.screen_name == "paused":
                self._set_screen("playing")
            elif self.screen_name == "confirm_exit":
                return False
            elif self.screen_name == "level_complete":
                self._advance_level()
            elif self.screen_name in ("game_over", "victory"):
                self._activate_action("restart" if self.screen_name == "game_over" else "replay")
            elif self.screen_name in ("settings", "howto", "scores"):
                self._set_screen("menu")
            return True
        if key == pygame.K_r and self.screen_name in ("paused", "game_over"):
            self._activate_action("restart")
            return True
        if key == pygame.K_n and self.screen_name in ("paused", "game_over", "victory"):
            self._activate_action("menu")
            return True
        if self.screen_name == "ships" and key in (pygame.K_LEFT, pygame.K_a):
            self.save.data["ship_skin"] = (self.save.data["ship_skin"] - 1) % len(SKINS)
            return True
        if self.screen_name == "ships" and key in (pygame.K_RIGHT, pygame.K_d):
            self.save.data["ship_skin"] = (self.save.data["ship_skin"] + 1) % len(SKINS)
            return True
        if self.screen_name == "campaign":
            columns = 2
            row, column = divmod(self.selected_campaign_level - 1, columns)
            if key in (pygame.K_LEFT, pygame.K_a):
                column = max(0, column - 1)
            elif key in (pygame.K_RIGHT, pygame.K_d):
                column = min(columns - 1, column + 1)
            elif key in (pygame.K_UP, pygame.K_w):
                row = max(0, row - 1)
            elif key in (pygame.K_DOWN, pygame.K_s):
                row = min(4, row + 1)
            selected = row * columns + column + 1
            if selected <= self.save.data["unlocked_level"]:
                self.selected_campaign_level = selected
            return True
        if self.screen_name == "playing" and key == pygame.K_q:
            self.player.switch_weapon()
        return True

    def _handle_click(self, position):
        if self.screen_name in ("paused", "game_over", "victory"):
            for action in self.visible_action_buttons:
                button = self.action_buttons[action]
                if button.clicked(position):
                    self._queue_action(button.action)
                    return
        if self.screen_name == "menu":
            for button in self.buttons:
                if button.clicked(position):
                    if button.action == "exit":
                        self._queue_action("exit")
                    else:
                        self._queue_action(button.action)
                    return
        elif self.screen_name == "ships":
            if position[0] < self.width / 2:
                self.save.data["ship_skin"] = (self.save.data["ship_skin"] - 1) % len(SKINS)
            else:
                self.save.data["ship_skin"] = (self.save.data["ship_skin"] + 1) % len(SKINS)
        elif self.screen_name == "campaign":
            for number, rect in self.campaign_cards.items():
                if rect.collidepoint(position):
                    if number <= self.save.data["unlocked_level"]:
                        self.selected_campaign_level = number
                    return
            if self.campaign_launch_rect.collidepoint(position):
                self.start_game(self.selected_campaign_level)
        elif self.screen_name == "settings":
            if self.settings_menu.handle_click(
                    position, self.save.data, self.width / 2):
                if self.settings_menu.last_changed in ("fullscreen", "resolution"):
                    self._apply_display_settings()
                self.audio.set_volumes(
                    self.save.data["music_volume"], self.save.data["sfx_volume"],
                    self.save.data["master_volume"],
                )
                self.audio.set_music_enabled(self.save.data["music_enabled"])
                self.save.save()
            elif position[1] > self.height - 100:
                self._set_screen("menu")
        elif self.screen_name in ("howto", "scores"):
            self._set_screen("menu")
        elif self.screen_name == "paused":
            self._set_screen("playing")
        elif self.screen_name == "level_complete":
            if self.completion_campaign_rect.collidepoint(position):
                self.selected_campaign_level = self.save.data["unlocked_level"]
                self._set_screen("campaign")
            else:
                self._advance_level()
        elif self.screen_name == "confirm_exit":
            if self.exit_cancel_rect.collidepoint(position):
                self.action_buttons["cancel_exit"].clicked(position)
                self._queue_action("cancel_exit")
            elif self.exit_confirm_rect.collidepoint(position):
                self.action_buttons["exit_confirm"].clicked(position)
                self._queue_action("exit_confirm")
            else:
                self._queue_action("cancel_exit")

    def _queue_action(self, action):
        self.pending_action = action
        self.pending_action_timer = 0.11

    def _advance_pending_action(self, dt):
        if self.pending_action is None:
            return
        self.pending_action_timer -= dt
        if self.pending_action_timer > 0:
            return
        action = self.pending_action
        self.pending_action = None
        if action == "exit":
            self._set_screen("confirm_exit")
        elif action in ("ships", "settings", "howto", "scores"):
            self._set_screen(action)
        else:
            self._activate_action(action)

    def _activate_action(self, action):
        if action == "resume":
            self._set_screen("playing")
        elif action == "restart":
            self.start_game(self.level_number)
        elif action == "replay":
            self.start_game(1)
        elif action == "menu":
            self._set_screen("menu")
        elif action == "exit_confirm":
            self.save.save()
            self.exit_requested = True
        elif action == "cancel_exit":
            self._set_screen("menu")
        return True

    def _advance_level(self):
        if self.level_number >= 10:
            self._set_screen("victory")
        else:
            self.start_game(self.level_number + 1, preserve_player=True)

    def _update_game(self, dt):
        keys = pygame.key.get_pressed()
        self.player.update(dt, keys)
        if keys[pygame.K_SPACE]:
            self._fire_player_weapon()

        score_tier = min(6, self.player.score // 2500)
        difficulty = DIFFICULTY_MULTIPLIERS[self.save.data["difficulty"]]
        kinds, boss_ready = self.level.update(dt, self.player.score, difficulty)
        positions = self.level.formation_positions(self.width, len(kinds))
        enemy_difficulty = max(
            1, round((self.level_number + score_tier) * difficulty)
        )
        for kind, (x, y) in zip(kinds, positions):
            self.enemies.append(Enemy(x, y, kind, enemy_difficulty))
        if boss_ready:
            self.boss = Boss(self.width, self.level_number, enemy_difficulty)
            self.boss_death_burst_timer = 0.0
            self.notice = f"BOSS WARNING  •  {self.boss.name}"
            self.notice_timer = 3.5
            self._trigger_screen_shake(7, 0.7)
            self.audio.set_music_mode("boss")
            self.audio.play("boss_warning")

        for enemy in self.enemies:
            self.enemy_bullets.extend(enemy.update(dt, self.player.pos, self.width,
                                                   enemy_difficulty, self.height))
        self.enemies = [enemy for enemy in self.enemies if enemy.alive]
        if self.boss and self.boss.alive:
            self.enemy_bullets.extend(self.boss.update(dt, self.player.pos))
            if self.boss.phase_changed:
                self.notice = f"{self.boss.name}  •  PHASE {self.boss.phase_name}"
                self.notice_timer = 2.2
                self._trigger_screen_shake(5, 0.45)
                self.audio.play("boss_phase")
        elif self.boss and self.boss.is_dying:
            previous_tick = int(self.boss.death_elapsed * 9)
            if self.boss.advance_death(dt):
                self.boss = None
                self.level.elapsed = max(self.level.elapsed, self.level.duration)
                self.audio.set_music_mode("game")
                self.notice = "BOSS DESTROYED  •  SECTOR SECURED"
                self.notice_timer = 2.5
            elif int(self.boss.death_elapsed * 9) != previous_tick:
                burst(self.particles, self.boss.pos.x + random.uniform(-55, 55),
                      self.boss.pos.y + random.uniform(-40, 40),
                      self.boss.spec["core"], 14, 1.5)
                self._trigger_screen_shake(4, 0.2)
        for bullet in self.player_bullets + self.enemy_bullets:
            bullet.update(dt, (self.width, self.height))
        self.player_bullets = [bullet for bullet in self.player_bullets if bullet.alive]
        self.enemy_bullets = [bullet for bullet in self.enemy_bullets if bullet.alive]

        for bullet in list(self.player_bullets):
            if (self.boss and self.boss.alive and
                    bullet.pos.distance_to(self.boss.pos) < self.boss.radius + bullet.radius):
                defeated = self.boss.hit(bullet.damage)
                if self.boss.phase_changed and self.boss.alive:
                    self.notice = f"{self.boss.name}  •  PHASE {self.boss.phase_name}"
                    self.notice_timer = 2.2
                    self._trigger_screen_shake(5, 0.45)
                    self.audio.play("boss_phase")
                if defeated:
                    self._boss_defeated()
                if bullet.explosive:
                    self._missile_splash(bullet.pos, self.boss)
                if not bullet.beam:
                    bullet.alive = False
                continue
            for enemy in self.enemies:
                if not enemy.alive:
                    continue
                if bullet.pos.distance_to(enemy.pos) < enemy.radius + bullet.radius:
                    defeated = enemy.hit(bullet.damage)
                    if not bullet.beam:
                        bullet.alive = False
                    if defeated:
                        self._enemy_defeated(enemy)
                    if bullet.explosive:
                        self._missile_splash(bullet.pos, enemy)
                    break

        for bullet in self.enemy_bullets:
            if bullet.pos.distance_to(self.player.pos) < self.player.radius + bullet.radius:
                if self.player.hit(19):
                    self.level_damage_taken = True
                    self.audio.play("collision")
                    burst(self.particles, self.player.pos.x, self.player.pos.y, (255, 90, 124), 7)
                bullet.alive = False
        for enemy in self.enemies:
            if (enemy.alive and
                    enemy.pos.distance_to(self.player.pos) < enemy.radius + self.player.radius):
                if self.player.hit(28):
                    self.level_damage_taken = True
                    self.audio.play("collision")
                enemy.alive = False
                burst(self.particles, enemy.pos.x, enemy.pos.y, enemy.color, 14)
        self.enemies = [enemy for enemy in self.enemies if enemy.alive]
        if (self.boss and self.boss.alive and
                self.boss.pos.distance_to(self.player.pos) < self.boss.radius + self.player.radius):
            if self.player.hit(35):
                self.level_damage_taken = True
                self.audio.play("collision")
                burst(self.particles, self.player.pos.x, self.player.pos.y,
                      (255, 90, 124), 12, 1.15)

        remaining_powerups = []
        for powerup in self.powerups:
            powerup.update(dt, self.width, self.height, self.particles)
            if powerup.pos.distance_to(self.player.pos) < self.player.radius + 17:
                self._collect_powerup(powerup)
            elif powerup.alive:
                remaining_powerups.append(powerup)
        self.powerups = remaining_powerups
        self.player_bullets = [bullet for bullet in self.player_bullets if bullet.alive]
        self.enemy_bullets = [bullet for bullet in self.enemy_bullets if bullet.alive]

        if self.player.health <= 0:
            self.player.lives -= 1
            if self.player.lives > 0:
                self.player.health = self.player.max_health
                self.player.invincible = 2.5
                self.player.pos.update(self.width / 2, self.height * 0.82)
            else:
                self._game_over()
        if (self.level.elapsed >= self.level.duration and not self.enemies and
                (not self.level.boss_level or (self.level.boss_spawned and not self.boss))):
            self._complete_level()

    def _fire_player_weapon(self):
        bullets = self.player.shoot()
        if bullets:
            self.player_bullets.extend(bullets)
            self.audio.play("shoot")

    def _enemy_defeated(self, enemy):
        if getattr(enemy, "score_awarded", False):
            return
        enemy.score_awarded = True
        gained = enemy.score_value * self.player.score_multiplier
        self.player.score += gained
        self.player.credits += max(1, gained // 100)
        self.player.kills += 1
        self.save.data["total_kills"] += 1
        if self.save.data["total_kills"] >= 1:
            self.save.unlock("first_kill")
        if self.save.data["total_kills"] >= 100:
            self.save.unlock("hundred_kills")
        if self.player.kills >= 50:
            self.save.unlock("ace_pilot")
        burst(self.particles, enemy.pos.x, enemy.pos.y, enemy.color, 12)
        self.audio.play("explosion")
        if len(self.powerups) < 6 and random.random() < 0.18:
            kind = PowerUp.random_kind(self.player.weapon_level)
            self.powerups.append(PowerUp(enemy.pos.x, enemy.pos.y, kind))
            burst(self.particles, enemy.pos.x, enemy.pos.y, self.powerups[-1].color, 5)

    def _collect_powerup(self, powerup):
        powerup.alive = False
        message = self.player.apply_powerup(powerup.kind)
        burst(self.particles, powerup.pos.x, powerup.pos.y, powerup.color, 16, 1.15)
        self.audio.play("powerup")
        if message:
            self.notice = f"{message}  •  PICKED UP"
            self.notice_timer = 2.4

    def _missile_splash(self, position, direct_hit):
        burst(self.particles, position.x, position.y, (255, 171, 83), 18, 1.2)
        for enemy in self.enemies:
            if enemy is not direct_hit and enemy.alive and enemy.pos.distance_to(position) < 72:
                if enemy.hit(2):
                    self._enemy_defeated(enemy)
        if self.boss and self.boss is not direct_hit and self.boss.alive:
            if self.boss.pos.distance_to(position) < 95 and self.boss.hit(2):
                self._boss_defeated()

    def _boss_defeated(self):
        if not self.boss or not self.boss.is_dying or self.boss_rewarded:
            return
        self.boss_rewarded = True
        self.player.score += 2500 * self.player.score_multiplier
        self.player.credits += 250
        self.save.unlock("boss_slayer")
        self.save.unlock("first_boss")
        bosses = self.save.data["bosses_defeated"]
        if self.boss.boss_type not in bosses:
            bosses.append(self.boss.boss_type)
        if len(bosses) == 3:
            self.save.unlock("three_bosses")
        self.player.score += self.boss.reward * self.player.score_multiplier
        self.boss_death_burst_timer = 0.0
        self._trigger_screen_shake(12, 1.1)
        burst(self.particles, self.boss.pos.x, self.boss.pos.y,
              self.boss.spec["core"], 90, 1.9)
        self.powerups.append(PowerUp(self.width / 2, self.boss.pos.y,
                                     self.boss.powerup_reward))
        self.audio.play("boss_defeat")
        self.audio.play("explosion")
        self.notice = f"{self.boss.name} DEFEATED  •  BONUS +{self.boss.reward:,}"
        self.notice_timer = 3.5

    def _trigger_screen_shake(self, strength, duration):
        self.shake_strength = max(self.shake_strength, strength)
        self.shake_timer = max(self.shake_timer, duration)

    def _complete_level(self):
        if self.level.complete:
            return
        self.level.mark_complete()
        if self.level_number == 1:
            self.save.unlock("first_sector")
        if self.level_number == 10:
            self.save.unlock("galaxy_savior")
        if not self.level_damage_taken:
            self.save.unlock("no_damage")
        self.player.score += self.level.reward()
        self.player.credits += self.level.credit_reward()
        self.last_score = self.player.score
        completed = set(self.save.data["completed_levels"])
        completed.add(self.level_number)
        self.save.data["completed_levels"] = sorted(completed)
        if len(self.save.data["completed_levels"]) == 10:
            self.save.unlock("ten_levels")
        self.save.data["best_level"] = max(self.save.data["best_level"], self.level_number)
        self.save.data["unlocked_level"] = min(
            10, max(self.save.data["unlocked_level"], self.level_number + 1)
        )
        new_credits = max(0, self.player.credits - self.campaign_credits_saved)
        self.save.data["credits"] += new_credits
        self.campaign_credits_saved = self.player.credits
        if self.player.score > self.save.data["high_score"]:
            self.save.data["high_score"] = self.player.score
            self.save.unlock("high_scorer")
        self.save.save()
        if self.level_number == 10:
            burst(self.particles, self.width / 2, self.height / 2,
                  (112, 224, 255), 110, 1.4)
            self._set_screen("victory")
        else:
            self._set_screen("level_complete")

    def _game_over(self):
        self.last_score = self.player.score
        burst(self.particles, self.player.pos.x, self.player.pos.y, (255, 91, 126), 42, 1.25)
        new_credits = max(0, self.player.credits - self.campaign_credits_saved)
        self.save.data["credits"] += new_credits
        self.campaign_credits_saved = self.player.credits
        if self.player.score > self.save.data["high_score"]:
            self.save.data["high_score"] = self.player.score
            self.save.unlock("high_scorer")
        self.save.save()
        self.selected_campaign_level = self.save.data["unlocked_level"]
        self._set_screen("game_over")

    def _draw(self):
        self.visible_action_buttons = set()
        show_level_backdrop = (
            self.level is not None and
            self.screen_name in ("level_intro", "playing", "paused", "level_complete", "victory")
        )
        if show_level_backdrop:
            self.screen.fill(self.level.background[0])
        else:
            self.screen.fill(BACKGROUND)
        self.starfield.draw(self.screen)
        self._draw_nebula()
        if self.screen_name == "menu":
            self._draw_menu()
        elif self.screen_name == "ships":
            self._draw_ships()
        elif self.screen_name == "campaign":
            self._draw_campaign()
        elif self.screen_name == "level_intro":
            self._draw_level_intro()
        elif self.screen_name == "howto":
            self._draw_howto()
        elif self.screen_name == "settings":
            self._draw_settings()
        elif self.screen_name == "scores":
            self._draw_scores()
        elif self.screen_name in ("playing", "paused"):
            self._draw_game()
            if self.screen_name == "paused":
                self._draw_overlay("PAUSED", "ENTER / ESC RESUME    •    R RESTART    •    N MENU")
        elif self.screen_name == "level_complete":
            self._draw_level_complete()
        elif self.screen_name == "game_over":
            self._draw_result("MISSION FAILED", "Your squadron is standing by for another sortie.")
        elif self.screen_name == "victory":
            self._draw_result("GALAXY SAVED", "Campaign complete. The frontier is safe.")
        elif self.screen_name == "confirm_exit":
            self._draw_exit_confirmation()
        if self.save.data["show_fps"]:
            fps_text = self.tiny.render(f"{self.clock.get_fps():.0f} FPS", True, MUTED)
            self.screen.blit(fps_text, (self.width - fps_text.get_width() - 12, self.height - 23))
        if self.transition_alpha:
            self.transition_surface.set_alpha(self.transition_alpha)
            self.screen.blit(self.transition_surface, (0, 0))

    def _draw_nebula(self):
        if self.level and self.screen_name in (
                "level_intro", "playing", "paused", "level_complete", "victory"):
            _, nebula, accent, motif = self.level.background
            layer = self._nebula_layer(
                ("level", self.level_number), (nebula, accent, self.level.background[0])
            )
            self.screen.blit(layer, (0, 0))
            self._draw_level_motif(motif, accent)
            return
        self.screen.blit(
            self._nebula_layer("menu", ((42, 33, 99), (24, 83, 120), (92, 40, 100))),
            (0, 0),
        )

    def _nebula_layer(self, key, colors):
        cache_key = (self.width, self.height, key)
        if cache_key not in self.nebula_cache:
            layer = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
            rng = random.Random(str(cache_key))
            for index in range(7):
                center_x = round(self.width * (0.08 + index * 0.14))
                center_y = round(self.height * (0.19 + (index % 3) * 0.27))
                radius_x = round(self.width * rng.uniform(0.13, 0.24))
                radius_y = round(self.height * rng.uniform(0.11, 0.22))
                color = colors[index % len(colors)]
                for layer_index in range(7, 0, -1):
                    factor = layer_index / 7
                    alpha = round((8 - layer_index) * 2.3)
                    rect = pygame.Rect(
                        center_x - round(radius_x * factor),
                        center_y - round(radius_y * factor),
                        round(radius_x * 2 * factor),
                        round(radius_y * 2 * factor),
                    )
                    pygame.draw.ellipse(layer, (*color, alpha), rect)
            self.nebula_cache[cache_key] = layer
            while len(self.nebula_cache) > 3:
                self.nebula_cache.pop(next(iter(self.nebula_cache)))
        return self.nebula_cache[cache_key]

    def _draw_level_motif(self, motif, color):
        if motif in ("asteroids", "meteors"):
            for index in range(12):
                x = int((index * 167 + self.time * (26 + index % 4 * 13)) % (self.width + 90) - 45)
                y = int((index * 113 + self.time * (38 + index % 3 * 17)) % self.height)
                radius = 4 + index % 9
                pygame.draw.polygon(self.screen, color, [
                    (x - radius, y - radius // 2), (x - radius // 2, y - radius),
                    (x + radius // 2, y - radius + 2), (x + radius, y),
                    (x + radius // 2, y + radius), (x - radius, y + radius // 2),
                ], 1)
        elif motif in ("fleet", "armada", "warzone"):
            for index in range(5):
                x = int((self.width * (0.1 + index * 0.2) + math.sin(self.time * .2 + index) * 14))
                y = int(self.height * (0.17 + (index % 2) * .1))
                pygame.draw.polygon(self.screen, color, [
                    (x, y - 12), (x + 20, y), (x, y + 6), (x - 20, y),
                ], 1)
        elif motif in ("rift", "domain", "final"):
            center = (int(self.width * .72), int(self.height * .45))
            for index in range(4):
                width = int(110 + index * 38 + math.sin(self.time + index) * 9)
                height = int(44 + index * 17)
                pygame.draw.ellipse(
                    self.screen, color,
                    (center[0] - width, center[1] - height,
                     width * 2, height * 2), 1,
                )
        elif motif == "nebula":
            for index in range(6):
                x = int((index * 223 + self.time * 8) % (self.width + 100) - 50)
                y = int(self.height * (.17 + (index % 3) * .31))
                pygame.draw.circle(self.screen, color, (x, y), 30 + index * 8, 1)

    def _draw_campaign(self):
        unlocked = self.save.data["unlocked_level"]
        completed = set(self.save.data["completed_levels"])
        self._header("CAMPAIGN SELECT", f"SECTORS CLEARED  {len(completed)} / 10")
        self.campaign_cards = {}
        card_width = min(430, self.width * 0.38)
        card_height = 44
        gap_x = 28
        start_x = self.width / 2 - card_width - gap_x / 2
        start_y = self.height * 0.29
        for index, definition in enumerate(LEVELS):
            number = index + 1
            row, column = divmod(index, 2)
            rect = pygame.Rect(
                round(start_x + column * (card_width + gap_x)),
                round(start_y + row * 46),
                round(card_width),
                card_height,
            )
            self.campaign_cards[number] = rect
            is_locked = number > unlocked
            is_selected = number == self.selected_campaign_level
            if is_locked:
                fill, border, label_color = (10, 13, 27), (42, 48, 68), (91, 101, 125)
            elif is_selected:
                fill, border, label_color = (18, 42, 69), CYAN, WHITE
            elif number in completed:
                fill, border, label_color = (14, 35, 44), (77, 156, 139), (173, 235, 214)
            else:
                fill, border, label_color = (13, 22, 45), (57, 78, 118), MUTED
            pygame.draw.rect(self.screen, fill, rect, border_radius=9)
            pygame.draw.rect(self.screen, border, rect, 2 if is_selected else 1, border_radius=9)
            state = "LOCKED" if is_locked else "CLEARED" if number in completed else "UNLOCKED"
            title = self.tiny.render(f"{number:02d}  {definition['title']}", True, label_color)
            status = self.tiny.render(state, True, border if not is_locked else label_color)
            self.screen.blit(title, (rect.x + 12, rect.y + 4))
            self.screen.blit(status, status.get_rect(right=rect.right - 10, bottom=rect.bottom - 4))
        self.campaign_launch_rect = pygame.Rect(
            self.width // 2 - 130, self.height - 52, 260, 36
        )
        pygame.draw.rect(self.screen, (14, 37, 62), self.campaign_launch_rect, border_radius=10)
        pygame.draw.rect(self.screen, CYAN, self.campaign_launch_rect, 2, border_radius=10)
        self._center_text(
            f"CONTINUE  •  SECTOR {self.selected_campaign_level:02d}",
            self.small, WHITE, self.campaign_launch_rect.center,
        )
        self._center_text(
            "ARROWS SELECT  •  ENTER LAUNCH  •  ESC BACK",
            self.tiny, MUTED, (self.width / 2, self.height - 8),
        )

    def _draw_level_intro(self):
        if not self.level:
            return
        pulse = 0.8 + 0.2 * math.sin(self.time * 4)
        self._center_text(
            f"SECTOR {self.level_number:02d}",
            self.small, CYAN, (self.width / 2, self.height * .25),
        )
        self._center_text(
            self.level.title, self.title_font, WHITE,
            (self.width / 2, self.height * .39),
        )
        self._center_text(
            self.level.subtitle, self.small, MUTED,
            (self.width / 2, self.height * .49),
        )
        self._center_text(
            self.level.challenge, self.small, GOLD,
            (self.width / 2, self.height * .59),
        )
        self._center_text(
            f"CAMPAIGN  {len(self.save.data['completed_levels'])} / 10 COMPLETE",
            self.tiny, CYAN, (self.width / 2, self.height * .69),
        )
        width = int(280 * pulse * (1 - min(1, self.level_intro_timer / 3.2) * .25))
        pygame.draw.rect(self.screen, CYAN,
                         (self.width // 2 - width // 2, int(self.height * .76), width, 3))
        self._center_text("ENTER  •  DEPLOY NOW", self.tiny, WHITE,
                          (self.width / 2, self.height * .82))

    def _draw_level_complete(self):
        self._draw_game()
        overlay = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
        overlay.fill((3, 5, 18, 205))
        self.screen.blit(overlay, (0, 0))
        self._center_text("SECTOR CLEARED", self.title_font, WHITE,
                          (self.width / 2, self.height * .32))
        self._center_text(
            f"{self.level.title}  •  REWARD +{self.level.reward():,} SCORE",
            self.small, GOLD, (self.width / 2, self.height * .44),
        )
        self._center_text(
            f"+{self.level.credit_reward():,} CREDITS  •  "
            f"CAMPAIGN {len(self.save.data['completed_levels'])} / 10",
            self.small, CYAN, (self.width / 2, self.height * .51),
        )
        next_level = self.level_number + 1
        self._center_text(
            f"NEXT  •  {LEVELS[next_level - 1]['title']}",
            self.font, WHITE, (self.width / 2, self.height * .62),
        )
        self._center_text("ENTER  •  CONTINUE CAMPAIGN",
                          self.tiny, CYAN, (self.width / 2, self.height * .72))
        self.completion_campaign_rect = pygame.Rect(
            self.width // 2 - 140, int(self.height * .79), 280, 40
        )
        pygame.draw.rect(self.screen, (14, 24, 48),
                         self.completion_campaign_rect, border_radius=9)
        pygame.draw.rect(self.screen, MUTED,
                         self.completion_campaign_rect, 1, border_radius=9)
        self._center_text("CAMPAIGN SELECT  •  ESC",
                          self.tiny, MUTED, self.completion_campaign_rect.center)

    def _draw_menu(self):
        cx = self.width // 2
        planets = (
            (0.82, 0.25, 58, (53, 65, 123), (108, 139, 218)),
            (0.14, 0.68, 23, (96, 55, 104), (207, 123, 164)),
            (0.91, 0.77, 14, (47, 105, 121), (92, 224, 217)),
        )
        for index, (px, py, radius, color, accent) in enumerate(planets):
            x = round(self.width * px + math.sin(self.time * (0.18 + index * 0.03)) * 13)
            y = round(self.height * py + math.sin(self.time * 0.31 + index) * 8)
            radius = round(radius * min(1.0, self.height / 560))
            pygame.draw.circle(self.screen, color, (x, y), radius)
            pygame.draw.arc(
                self.screen, accent,
                (x - radius - 7, round(y - radius * 0.35),
                 radius * 2 + 14, max(8, round(radius * 0.72))),
                0.1, math.pi - 0.1, 2,
            )
            pygame.draw.circle(self.screen, accent, (x, y), radius, 1)
            pygame.draw.circle(
                self.screen, (200, 223, 255),
                (x - radius // 3, y - radius // 3), max(1, radius // 10),
            )
        for index in range(3):
            ship_x = int((self.time * (37 + index * 13) + index * self.width / 3) %
                         (self.width + 100) - 50)
            ship_y = int(self.height * (0.70 + index * 0.09) +
                         math.sin(self.time * 1.2 + index * 2) * 9)
            direction = -1 if index == 1 else 1
            self._draw_menu_ship(ship_x, ship_y, 0.72 + index * 0.12, direction,
                                 ((75, 146, 202), (190, 92, 164), (79, 212, 207))[index])
        title_y = int(self.height * (0.18 if self.height < 500 else 0.20))
        title = self.title_font.render("GALAXY STRIKE", True, WHITE)
        title_rect = title.get_rect(center=(cx, title_y))
        glow = self.title_font.render("GALAXY STRIKE", True, (62, 187, 255))
        for offset in ((-2, 0), (2, 0), (0, -2), (0, 2)):
            self.screen.blit(glow, glow.get_rect(center=(cx + offset[0], title_y + offset[1])))
        self.screen.blit(title, title_rect)
        pygame.draw.line(
            self.screen, (59, 173, 222),
            (cx - title_rect.width // 3, title_rect.bottom + 5),
            (cx + title_rect.width // 3, title_rect.bottom + 5), 1,
        )
        glow = self.small.render("DEFEND THE FRONTIER  •  10-SECTOR CAMPAIGN", True, CYAN)
        self.screen.blit(glow, glow.get_rect(center=(cx, int(self.height * .30))))
        start_y = int(self.height * (0.40 if self.height < 500 else 0.42))
        step = min(57, max(42, (self.height * 0.83 - start_y) / max(1, len(self.buttons) - 1)))
        for index, button in enumerate(self.buttons):
            button.height = min(48, max(38, round(step - 3)))
            button.rect.height = button.height
            button.draw(self.screen, self.small, (cx, round(start_y + index * step)), self.time)
        if self.height >= 540:
            self._center_text(
                "WASD / ARROWS MOVE     •     SPACE FIRE     •     Q WEAPON     •     ESC PAUSE",
                self.tiny, MUTED, (cx, self.height - 35),
            )
        self._center_text("VERSION 1.0  |  PILOT RECORD SAVED LOCALLY",
                          self.tiny, (81, 100, 133), (cx, self.height - 15))

    def _draw_menu_ship(self, x, y, scale, direction, color):
        body = [
            (round(x + 17 * direction * scale), y),
            (round(x - 11 * direction * scale), round(y - 8 * scale)),
            (round(x - 5 * direction * scale), y),
            (round(x - 11 * direction * scale), round(y + 8 * scale)),
        ]
        tail = (round(x - 28 * direction * scale), y)
        pygame.draw.line(self.screen, color, tail, body[0], max(1, round(2 * scale)))
        pygame.draw.polygon(self.screen, color, body)
        pygame.draw.circle(self.screen, (224, 250, 255), body[0], max(1, round(2 * scale)))

    def _draw_ships(self):
        self._header("CHOOSE YOUR FIGHTER", "Select a ship skin for your next sortie")
        index = self.save.data["ship_skin"] % len(SKINS)
        skin = SKINS[index]
        x, y = self.width // 2, self.height // 2
        pygame.draw.circle(self.screen, (17, 48, 86), (x, y), 61, 1)
        pygame.draw.arc(self.screen, skin["main"], (x - 52, y - 20, 104, 40),
                        self.time * 0.3, self.time * 0.3 + math.pi * 1.6, 2)
        preview = Player(self.width, self.height, index)
        preview.pos.update(x, y)
        preview.engine_phase = self.time * 17
        preview.draw(self.screen)
        self._center_text(f"<    {skin['name']}    >", self.font, WHITE, (x, y + 115))
        self._center_text("A / D or arrow keys to browse", self.small, MUTED, (x, y + 155))
        self._center_text("ENTER  •  LAUNCH MISSION", self.small, CYAN, (x, y + 215))
        self._back_hint()

    def _draw_howto(self):
        self._header("FLIGHT MANUAL", "A few seconds in the manual. A lifetime in the stars.")
        lines = [
            ("MOVE", "WASD or arrows. Keep moving to evade enemy volleys."),
            ("FIRE / WEAPON", "Hold SPACE to fire; Q cycles unlocked weapons."),
            ("ENEMIES", "Scouts, interceptors, heavy ships, gunships and divers."),
            ("PICKUPS", "Touch drops for hull, lives, shields and weapon upgrades."),
            ("BOSSES", "Three multi-phase bosses guard sectors 5, 9 and 10."),
            ("CAMPAIGN", "Clear sectors in order. Progress and achievements save."),
            ("PAUSE", "ESC pauses. R restarts a sortie; N returns to the menu."),
            ("COCKPIT", "Adjust volume, display, FPS and difficulty in Settings."),
            ("HUD", "Track hull, lives, shield, weapons, credits and timed effects."),
            ("AUDIO", "M toggles music. Settings adjusts master, music and SFX."),
        ]
        start_y = self.height * 0.29
        step = min(39, max(23, (self.height * 0.81 - start_y) / (len(lines) - 1)))
        for index, (key, text) in enumerate(lines):
            y = start_y + index * step
            self.screen.blit(self.tiny.render(key, True, CYAN), (self.width * .16, y))
            self.screen.blit(self.tiny.render(text, True, WHITE), (self.width * .36, y))
        self._back_hint()

    def _draw_settings(self):
        self._header("SETTINGS", "Fine-tune your cockpit experience")
        self.settings_menu.draw(self.screen, self.small, self.save.data,
                                self.width / 2, self.height / 2 - 65)
        if self.height >= 520:
            self._center_text("CLICK A VALUE TO CHANGE IT", self.tiny, MUTED,
                              (self.width / 2, self.height - 42))
            self._back_hint()

    def _draw_scores(self):
        self._header("PILOT RECORD", "Career statistics and permanent achievements")
        stats = [
            ("HIGH SCORE", f"{self.save.data['high_score']:,}"),
            ("BEST SECTOR", f"{self.save.data['best_level']:02d} / 10"),
            ("MISSIONS FLOWN", str(self.save.data["games_played"])),
            ("CREDITS", f"{self.save.data['credits']:,}"),
            ("ENEMIES DESTROYED", str(self.save.data["total_kills"])),
        ]
        unlocked = set(self.save.data["achievements"])
        start_y = self.height * 0.40
        self.screen.blit(self.small.render("PILOT RECORD", True, CYAN),
                         (self.width * .12, self.height * .32))
        stat_step = min(47, max(30, (self.height * .87 - start_y) / 4))
        for index, (label, value) in enumerate(stats):
            y = start_y + index * stat_step
            self.screen.blit(self.tiny.render(label, True, MUTED), (self.width * .12, y))
            value_surface = self.small.render(value, True, CYAN)
            self.screen.blit(value_surface, value_surface.get_rect(topright=(self.width * .47, y)))
        self.screen.blit(self.small.render("ACHIEVEMENTS", True, CYAN),
                         (self.width * .55, self.height * .32))
        achievement_step = min(32, max(22, (self.height * .86 - start_y) / 7))
        for index, (achievement, (name, description)) in enumerate(ACHIEVEMENT_INFO.items()):
            y = start_y + index * achievement_step
            earned = achievement in unlocked
            label = f"{'★' if earned else '◇'}  {name}"
            color = GOLD if earned else (91, 104, 128)
            self.screen.blit(self.tiny.render(label, True, color), (self.width * .55, y))
            desc_color = MUTED if earned else (72, 81, 101)
            self.screen.blit(self.tiny.render(description, True, desc_color),
                             (self.width * .55, y + 15))
        self._back_hint()

    def _draw_game(self):
        if self.shake_timer > 0:
            destination = self.screen
            shaken_scene = pygame.Surface(destination.get_size())
            shaken_scene.blit(destination, (0, 0))
            self.screen = shaken_scene
            self._draw_game_scene()
            self.screen = destination
            strength = self.shake_strength * min(1.0, self.shake_timer / 0.3)
            offset_x = random.randint(-int(strength), int(strength))
            offset_y = random.randint(-int(strength), int(strength))
            destination.blit(shaken_scene, (offset_x, offset_y))
            self.shake_strength *= 0.88
            if self.shake_timer <= 0.02:
                self.shake_strength = 0
        else:
            self._draw_game_scene()

    def _draw_game_scene(self):
        if not self.player:
            return
        for powerup in self.powerups:
            powerup.draw(self.screen)
        for enemy in self.enemies:
            enemy.draw(self.screen)
        if self.boss:
            self.boss.draw(self.screen)
            bar_width = min(660, self.width * 0.62)
            x = (self.width - bar_width) / 2
            y = 24
            pygame.draw.rect(self.screen, (9, 12, 30),
                             (x - 12, y - 9, bar_width + 24, 48), border_radius=9)
            pygame.draw.rect(self.screen, (46, 26, 55),
                             (x, y + 18, bar_width, 15), border_radius=7)
            health_ratio = max(0, self.boss.health) / self.boss.max_health
            pygame.draw.rect(self.screen, self.boss.spec["color"],
                             (x, y + 18, int(bar_width * health_ratio), 15),
                             border_radius=7)
            self._center_text(
                f"{self.boss.name}  •  PHASE {self.boss.phase_name}  •  "
                f"{max(0, self.boss.health):,} / {self.boss.max_health:,}",
                self.tiny, WHITE, (self.width / 2, y + 2),
            )
        for bullet in self.player_bullets + self.enemy_bullets:
            bullet.draw(self.screen)
        for particle in self.particles:
            particle.draw(self.screen)
        self.player.draw(self.screen)
        self._draw_hud()
        if self.notice_timer > 0:
            self._center_text(self.notice, self.small, GOLD,
                              (self.width / 2, self.height * .35))

    def _draw_hud(self):
        panel = pygame.Rect(18, 16, 282, 208)
        pygame.draw.rect(self.screen, (10, 17, 38), panel, border_radius=12)
        pygame.draw.rect(self.screen, (48, 68, 107), panel, 1, border_radius=12)
        self.screen.blit(self.tiny.render(f"SECTOR {self.level_number:02d}  •  {self.level.title}",
                                          True, CYAN), (31, 27))
        completed_count = len(self.save.data["completed_levels"])
        campaign_text = self.tiny.render(
            f"CAMPAIGN  {completed_count:02d}/10", True, CYAN
        )
        self.screen.blit(
            campaign_text,
            campaign_text.get_rect(topright=(self.width - 24, 21)),
        )
        progress_rect = pygame.Rect(self.width - 164, 40, 140, 5)
        pygame.draw.rect(self.screen, (36, 48, 73), progress_rect, border_radius=3)
        pygame.draw.rect(
            self.screen, CYAN,
            (progress_rect.x, progress_rect.y,
             int(progress_rect.width * completed_count / 10), progress_rect.height),
            border_radius=3,
        )
        self.screen.blit(self.small.render(f"{self.player.score:,}", True, WHITE), (31, 47))
        self.screen.blit(self.tiny.render("SCORE", True, MUTED), (31, 77))
        self.screen.blit(self.tiny.render("HULL", True, MUTED), (125, 77))
        self.screen.blit(self.tiny.render("LIVES", True, MUTED), (220, 77))
        self.screen.blit(self.tiny.render(f"×{self.player.lives}", True, GOLD), (225, 94))
        self.screen.blit(self.tiny.render(f"CR {self.player.credits:,}", True, GOLD), (31, 94))
        pygame.draw.rect(self.screen, (39, 49, 76), (124, 52, 142, 8), border_radius=4)
        health_ratio = max(0.0, min(1.0, self.player.health / self.player.max_health))
        self.hud_health_ratio += (health_ratio - self.hud_health_ratio) * 0.28
        health_color = (85, 235, 164) if health_ratio > 0.35 else PINK
        if health_ratio <= 0.35 and int(self.time * 7) % 2:
            health_color = (255, 166, 178)
        pygame.draw.rect(self.screen, health_color,
                         (124, 52, int(142 * self.hud_health_ratio), 8), border_radius=4)
        weapon_names = {
            "single": "SINGLE", "double": "DOUBLE", "triple": "TRIPLE",
            "rapid": "RAPID", "laser": "LASER", "beam": "LASER",
            "missile": "MISSILE",
        }
        weapon_label = weapon_names.get(self.player.weapon_mode, "SINGLE")
        weapon_text = f"WEAPON  {weapon_label}"
        if self.player.weapon_timer > 0:
            weapon_text += f"  {self.player.weapon_timer:.0f}s"
        self.screen.blit(self.tiny.render(weapon_text, True, CYAN), (31, 112))
        self.screen.blit(self.tiny.render("Q SWITCH", True, MUTED), (198, 112))
        shield_label = (
            f"SHIELD {self.player.shield:.0f}s" if self.player.shield > 0
            else "SHIELD OFF"
        )
        shield_color = (92, 191, 255) if self.player.shield > 0 else MUTED
        self.screen.blit(self.tiny.render(shield_label, True, shield_color), (31, 132))
        active_powerups = []
        timed_effects = (
            ("SHIELD", self.player.shield, (92, 191, 255)),
            ("RAPID", self.player.rapid_timer, (255, 166, 93)),
            ("LASER", self.player.weapon_timer if self.player.weapon_mode == "laser" else 0,
             (98, 248, 239)),
            ("SCORE x2", self.player.multiplier_timer, GOLD),
            ("DAMAGE", self.player.damage_timer, PINK),
            ("INVULN", self.player.invincible if self.player.invincible > 1 else 0, WHITE),
        )
        for label, duration, color in timed_effects:
            if duration > 0:
                active_powerups.append((f"{label} {duration:.0f}s", color))
        for index, (label, color) in enumerate(active_powerups):
            column = index % 2
            row = index // 2
            self.screen.blit(self.tiny.render(label, True, color),
                             (31 + column * 128, 151 + row * 17))

    def _draw_overlay(self, title, subtitle):
        overlay = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
        overlay_alpha = self.pause_overlay_alpha if title == "PAUSED" else 205
        overlay.fill((3, 5, 18, overlay_alpha))
        self.screen.blit(overlay, (0, 0))
        if title == "PAUSED":
            self._center_text(title, self.title_font, WHITE,
                              (self.width / 2, self.height * .37))
            self._center_text(subtitle, self.tiny, CYAN,
                              (self.width / 2, self.height * .49))
            self._draw_action_button("RESUME", "resume", (self.width / 2, self.height * .64))
            self._draw_action_button("RESTART SORTIE", "restart",
                                     (self.width / 2, self.height * .76))
            self._draw_action_button("MAIN MENU", "menu", (self.width / 2, self.height * .88))
        else:
            self._center_text(title, self.title_font, WHITE, (self.width / 2, self.height * .32))
            self._center_text(subtitle, self.small, CYAN, (self.width / 2, self.height * .44))

    def _draw_result(self, title, subtitle):
        self._draw_overlay(title, subtitle)
        for particle in self.particles:
            particle.draw(self.screen)
        self._center_text(f"FINAL SCORE  {self.last_score:,}", self.font, GOLD,
                          (self.width / 2, self.height * .56))
        if self.screen_name == "game_over":
            self._draw_action_button("RETRY SORTIE", "restart",
                                     (self.width / 2, self.height * .71))
        else:
            self._draw_action_button("REPLAY CAMPAIGN", "replay",
                                     (self.width / 2, self.height * .71))
        self._draw_action_button("MAIN MENU", "menu", (self.width / 2, self.height * .83))

    def _draw_exit_confirmation(self):
        overlay = pygame.Surface((self.width, self.height), pygame.SRCALPHA)
        overlay.fill((2, 5, 16, 215))
        self.screen.blit(overlay, (0, 0))
        panel = pygame.Rect(self.width // 2 - 230, self.height // 2 - 105, 460, 210)
        pygame.draw.rect(self.screen, (9, 17, 39), panel, border_radius=18)
        pygame.draw.rect(self.screen, (67, 117, 168), panel, 1, border_radius=18)
        self._center_text("LEAVE THE FRONTIER?", self.font, WHITE,
                          (self.width / 2, panel.y + 48))
        self._center_text("Your progress is saved locally.", self.small, MUTED,
                          (self.width / 2, panel.y + 91))
        self.exit_confirm_rect = self._draw_action_button(
            "EXIT GAME", "exit_confirm", (self.width / 2 - 105, panel.y + 157), 185, 42,
        )
        self.exit_cancel_rect = self._draw_action_button(
            "KEEP PLAYING", "cancel_exit", (self.width / 2 + 105, panel.y + 157), 185, 42,
        )

    def _draw_action_button(self, label, action, center, width=260, height=42):
        button = self.action_buttons.get(action)
        if button is None or button.label != label:
            button = Button(label, action, width=width, height=height)
            self.action_buttons[action] = button
        button.width, button.height = width, height
        button.rect.size = (width, height)
        button.draw(self.screen, self.small, center, self.time)
        self.visible_action_buttons.add(action)
        return button.rect

    def _header(self, title, subtitle):
        self._center_text(title, self.title_font, WHITE, (self.width / 2, self.height * .19))
        self._center_text(subtitle, self.small, CYAN, (self.width / 2, self.height * .27))

    def _back_hint(self):
        self._center_text("ENTER / ESC  •  BACK", self.tiny, MUTED, (self.width / 2, self.height - 40))

    def _center_text(self, text, font, color, center):
        surface = font.render(text, True, color)
        self.screen.blit(surface, surface.get_rect(center=(int(center[0]), int(center[1]))))
