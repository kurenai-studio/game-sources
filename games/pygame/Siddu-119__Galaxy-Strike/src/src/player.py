"""Player ship, weapons, movement and temporary upgrades."""

import math

import pygame

from settings import PLAYER_RADIUS, PLAYER_SPEED, SKINS
from src.bullet import Bullet
from src.powerup import POWERUP_DURATIONS


SHIP_SIDE_EXTENT = 19
SHIP_TOP_EXTENT = 24
ENGINE_FLAME_EXTENT = 40


class Player:
    def __init__(self, width, height, skin=0):
        self.width, self.height = width, height
        self.pos = pygame.Vector2(width / 2, height * 0.82)
        self.radius = PLAYER_RADIUS
        self.health = 100
        self.max_health = 100
        self.lives = 3
        self.skin = skin % len(SKINS)
        self.weapon_level = 1
        self.unlocked_weapons = ["single"]
        self.selected_weapon = "single"
        self.weapon_mode = "single"
        self.weapon_timer = 0.0
        self.fire_cooldown = 0.0
        self.invincible = 0.0
        self.shield = 0.0
        self.rapid_timer = 0.0
        self.damage_timer = 0.0
        self.score_multiplier = 1
        self.multiplier_timer = 0.0
        self.engine_phase = 0.0
        self.score = 0
        self.credits = 0
        self.kills = 0

    def resize(self, width, height):
        self.width, self.height = width, height
        self._keep_ship_in_bounds()

    def _keep_ship_in_bounds(self):
        self.pos.x = max(SHIP_SIDE_EXTENT, min(self.width - SHIP_SIDE_EXTENT, self.pos.x))
        self.pos.y = max(SHIP_TOP_EXTENT, min(self.height - ENGINE_FLAME_EXTENT, self.pos.y))

    def update(self, dt, keys):
        direction = pygame.Vector2(
            int(keys[pygame.K_d] or keys[pygame.K_RIGHT]) -
            int(keys[pygame.K_a] or keys[pygame.K_LEFT]),
            int(keys[pygame.K_s] or keys[pygame.K_DOWN]) -
            int(keys[pygame.K_w] or keys[pygame.K_UP]),
        )
        if direction.length_squared():
            direction = direction.normalize()
        self.pos += direction * PLAYER_SPEED * dt
        self._keep_ship_in_bounds()
        self.engine_phase += dt * 17
        self.fire_cooldown = max(0, self.fire_cooldown - dt)
        self.invincible = max(0, self.invincible - dt)
        self.shield = max(0, self.shield - dt)
        self.weapon_timer = max(0, self.weapon_timer - dt)
        self.rapid_timer = max(0, self.rapid_timer - dt)
        self.damage_timer = max(0, self.damage_timer - dt)
        self.multiplier_timer = max(0, self.multiplier_timer - dt)
        if self.rapid_timer == 0 and self.weapon_mode == "rapid":
            self.weapon_mode = self.selected_weapon
        if self.weapon_timer == 0:
            self.weapon_mode = "rapid" if self.rapid_timer > 0 else self.selected_weapon
        if self.multiplier_timer == 0:
            self.score_multiplier = 1

    def shoot(self):
        if self.fire_cooldown > 0:
            return []
        if self.weapon_mode == "missile":
            self.fire_cooldown = 0.58
        elif self.weapon_mode == "rapid":
            self.fire_cooldown = 0.075
        elif self.weapon_mode in ("laser", "beam"):
            self.fire_cooldown = 0.18
        else:
            self.fire_cooldown = 0.22
        if self.rapid_timer > 0 and self.weapon_mode != "rapid":
            self.fire_cooldown = max(0.06, self.fire_cooldown * 0.45)
        color = (255, 107, 161) if self.damage_timer else (73, 235, 255)
        damage = 2 if self.damage_timer else 1
        x, y = self.pos
        if self.weapon_mode in ("laser", "beam"):
            return [Bullet(x, y - 24, 0, -900, damage * 3, (145, 247, 255), 8,
                           True, True)]
        if self.weapon_mode == "missile":
            return [Bullet(x, y - 24, 0, -470, damage * 3, (255, 154, 82), 8,
                           True, explosive=True)]
        if self.weapon_mode == "rapid":
            return [Bullet(x, y - 24, 0, -720, damage, (116, 255, 182), 4)]
        if self.weapon_mode == "triple":
            return [Bullet(x - 12, y - 5, -135, -600, damage, color),
                    Bullet(x, y - 24, 0, -680, damage, color),
                    Bullet(x + 12, y - 5, 135, -600, damage, color)]
        if self.weapon_mode == "double":
            return [Bullet(x - 12, y - 5, 0, -660, damage, color),
                    Bullet(x + 12, y - 5, 0, -660, damage, color)]
        return [Bullet(x, y - 24, 0, -680, damage, color)]

    def switch_weapon(self):
        if len(self.unlocked_weapons) < 2:
            return self.weapon_mode
        try:
            current_index = self.unlocked_weapons.index(self.selected_weapon)
        except ValueError:
            current_index = -1
        self.selected_weapon = self.unlocked_weapons[
            (current_index + 1) % len(self.unlocked_weapons)
        ]
        self.weapon_mode = self.selected_weapon
        self.weapon_timer = 0.0
        self.rapid_timer = 0.0
        return self.weapon_mode

    def _set_temporary_weapon(self, mode, duration):
        self.weapon_mode = mode
        self.weapon_timer = duration

    def hit(self, damage=20):
        if self.invincible > 0:
            return False
        if self.shield <= 0:
            self.health -= damage
        self.invincible = 0.8
        return True

    def apply_powerup(self, kind):
        if kind == "health":
            restored = min(35, self.max_health - self.health)
            self.health += restored
            return f"+{restored} HULL" if restored else "HULL FULL"
        elif kind == "shield":
            self.shield = POWERUP_DURATIONS["shield"]
            return f"SHIELD {self.shield:.0f}s"
        elif kind == "life":
            if self.lives < 9:
                self.lives += 1
                return "+1 LIFE"
            return "LIVES FULL"
        elif kind == "rapid":
            self.rapid_timer = POWERUP_DURATIONS["rapid"]
            self._set_temporary_weapon("rapid", self.rapid_timer)
            return f"RAPID FIRE {self.rapid_timer:.0f}s"
        elif kind in ("double", "triple"):
            self._unlock_shot_weapon(kind)
            return f"{kind.upper()} SHOT UNLOCKED"
        elif kind == "damage":
            self.damage_timer = POWERUP_DURATIONS["damage"]
            return f"DOUBLE DAMAGE {self.damage_timer:.0f}s"
        elif kind == "weapon":
            unlock = "triple" if self.weapon_level >= 2 else "double"
            self._unlock_shot_weapon(unlock)
            return f"{unlock.upper()} SHOT UNLOCKED"
        elif kind in ("beam", "laser"):
            self._set_temporary_weapon("laser", POWERUP_DURATIONS["laser"])
            return f"LASER {self.weapon_timer:.0f}s"
        elif kind == "missile":
            self._set_temporary_weapon("missile", POWERUP_DURATIONS["missile"])
            return f"MISSILE {self.weapon_timer:.0f}s"
        elif kind == "multiplier":
            self.score_multiplier = 2
            self.multiplier_timer = POWERUP_DURATIONS["multiplier"]
            return f"SCORE x2 {self.multiplier_timer:.0f}s"
        elif kind == "invincible":
            self.invincible = POWERUP_DURATIONS["invincible"]
            return f"INVINCIBLE {self.invincible:.0f}s"
        return None

    def _unlock_shot_weapon(self, weapon):
        if weapon == "double":
            self.weapon_level = max(2, self.weapon_level)
            weapons = ("double",)
        else:
            self.weapon_level = 3
            weapons = ("double", "triple")
        for unlocked in weapons:
            if unlocked not in self.unlocked_weapons:
                self.unlocked_weapons.append(unlocked)
        self.selected_weapon = weapon
        self.weapon_mode = weapon
        self.weapon_timer = 0.0
        self.rapid_timer = 0.0

    def draw(self, surface):
        x, y = int(self.pos.x), int(self.pos.y)
        skin = SKINS[self.skin]
        if self.invincible > 0 and int(self.invincible * 14) % 2:
            return
        flame = 11 + int((math.sin(self.engine_phase) + 1) * 7)
        pygame.draw.circle(surface, (28, 132, 205), (x, y + 22), 9 + flame // 3)
        pygame.draw.polygon(surface, (255, 117, 61),
                            [(x - 8, y + 13), (x, y + flame + 15), (x + 8, y + 13)])
        pygame.draw.polygon(surface, (255, 226, 130),
                            [(x - 4, y + 13), (x, y + flame + 4), (x + 4, y + 13)])
        pygame.draw.polygon(surface, (30, 102, 156),
                            [(x - 19, y + 8), (x - 11, y - 9), (x - 5, y + 8),
                             (x, y + 15), (x + 5, y + 8), (x + 11, y - 9), (x + 19, y + 8),
                             (x + 11, y + 15), (x - 11, y + 15)])
        pygame.draw.polygon(surface, skin["main"],
                            [(x - 17, y + 6), (x - 9, y - 5), (x - 5, y + 9),
                             (x - 9, y + 12)])
        pygame.draw.polygon(surface, skin["main"],
                            [(x + 17, y + 6), (x + 9, y - 5), (x + 5, y + 9),
                             (x + 9, y + 12)])
        pygame.draw.polygon(surface, skin["main"],
                            [(x, y - 24), (x + 8, y - 4), (x + 7, y + 13),
                             (x, y + 19), (x - 7, y + 13), (x - 8, y - 4)])
        pygame.draw.polygon(surface, skin["trim"],
                            [(x, y - 17), (x + 4, y - 5), (x, y + 2), (x - 4, y - 5)])
        pygame.draw.line(surface, skin["trim"], (x, y + 3), (x, y + 14), 2)
        pygame.draw.circle(surface, (238, 251, 255), (x, y - 8), 2)
        pygame.draw.line(surface, skin["main"], (x - 13, y + 8), (x - 7, y + 11), 2)
        pygame.draw.line(surface, skin["main"], (x + 13, y + 8), (x + 7, y + 11), 2)
        if self.shield > 0:
            pulse = int(2 * (0.5 + 0.5 * math.sin(self.engine_phase * 0.28)))
            pygame.draw.circle(surface, (73, 185, 255), (x, y), 29 + pulse, 2)
            pygame.draw.circle(surface, (90, 177, 255), (x, y), 34 + pulse, 1)
            pygame.draw.arc(surface, (190, 238, 255), (x - 30, y - 30, 60, 60),
                            self.engine_phase * 0.18, self.engine_phase * 0.18 + 1.8, 2)
