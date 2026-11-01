"""Three giant boss ships, multi-phase attack patterns, and defeat animation."""

import math

import pygame

from src.bullet import Bullet, aimed_bullet


BOSS_SPECS = {
    "alien_destroyer": {
        "name": "ALIEN DESTROYER",
        "base_health": 720,
        "radius": 72,
        "color": (184, 71, 179),
        "core": (255, 95, 140),
        "reward": 5000,
        "powerup": "laser",
        "movement": "sweep",
    },
    "galactic_warship": {
        "name": "GALACTIC WARSHIP",
        "base_health": 1080,
        "radius": 83,
        "color": (70, 126, 236),
        "core": (104, 239, 255),
        "reward": 8000,
        "powerup": "shield",
        "movement": "orbit",
    },
    "galaxy_overlord": {
        "name": "ULTIMATE GALAXY OVERLORD",
        "base_health": 1540,
        "radius": 94,
        "color": (199, 61, 93),
        "core": (255, 213, 91),
        "reward": 12000,
        "powerup": "triple",
        "movement": "hunt",
    },
}

BOSS_FOR_LEVEL = {
    5: "alien_destroyer",
    9: "galactic_warship",
    10: "galaxy_overlord",
}

BOSS_ATTACK_ORDERS = {
    "alien_destroyer": (0, 2, 1, 3, 4),
    "galactic_warship": (3, 1, 0, 2, 4),
    "galaxy_overlord": (1, 2, 3, 4, 0),
}


class Boss:
    """Boss with entrance, three escalating phases, and an animated defeat."""

    def __init__(self, width, level, difficulty_level=None):
        self.width = width
        self.level = level
        difficulty_level = difficulty_level or level
        self.boss_type = BOSS_FOR_LEVEL.get(level, "alien_destroyer")
        self.spec = BOSS_SPECS[self.boss_type]
        self.name = self.spec["name"]
        self.radius = self.spec["radius"]
        self.pos = pygame.Vector2(width / 2, -self.radius * 1.8)
        difficulty = 1 + max(0, difficulty_level - 3) * 0.095
        self.max_health = int(self.spec["base_health"] * difficulty)
        self.health = self.max_health
        self.age = 0.0
        self.attack_timer = 1.3
        self.attack_index = 0
        self.alive = True
        self.phase = 1
        self.entry_done = False
        self.is_dying = False
        self.death_timer = 0.0
        self.death_elapsed = 0.0
        self.phase_changed = False
        self._phase_announced = 1

    @property
    def phase_name(self):
        return ("I", "II", "III")[self.phase - 1]

    @property
    def reward(self):
        return self.spec["reward"] + self.level * 500

    @property
    def powerup_reward(self):
        return self.spec["powerup"]

    def update(self, dt, player_pos):
        self.phase_changed = False
        if self.is_dying:
            self.death_timer = max(0.0, self.death_timer - dt)
            self.death_elapsed += dt
            return []
        if not self.alive:
            return []

        self.age += dt
        if not self.entry_done:
            target_y = max(self.radius + 22, 126)
            self.pos.y = min(target_y, self.pos.y + (220 + self.level * 4) * dt)
            self.entry_done = self.pos.y >= target_y
        else:
            self._move(dt, player_pos)

        self._update_phase()
        self.attack_timer -= dt
        if not self.entry_done or self.attack_timer > 0:
            return []
        return self._attack(player_pos)

    def _move(self, dt, player_pos):
        center = self.width / 2
        travel = min(self.width * 0.32, 310)
        if self.spec["movement"] == "sweep":
            self.pos.x = center + math.sin(self.age * (0.66 + self.phase * 0.12)) * travel
            self.pos.y = 126 + math.sin(self.age * 1.35) * 12
        elif self.spec["movement"] == "orbit":
            self.pos.x = center + math.sin(self.age * (0.74 + self.phase * 0.1)) * travel
            self.pos.y = 132 + math.sin(self.age * 1.08) * 20
        else:
            desired_x = pygame.Vector2(player_pos).x * 0.22 + center * 0.78
            sway = math.sin(self.age * (1.0 + self.phase * 0.18)) * travel * 0.78
            target_x = max(self.radius, min(self.width - self.radius, desired_x + sway))
            self.pos.x += (target_x - self.pos.x) * min(1.0, dt * (0.75 + self.phase * 0.18))
            self.pos.y = 124 + math.sin(self.age * 1.65) * 23

    def _update_phase(self):
        ratio = max(0.0, self.health / self.max_health)
        previous_phase = self.phase
        if ratio <= 0.34:
            self.phase = 3
        elif ratio <= 0.68:
            self.phase = 2
        else:
            self.phase = 1
        self.phase_changed = self.phase > previous_phase
        self._phase_announced = max(self._phase_announced, self.phase)

    def _attack(self, player_pos):
        phase = self.phase
        speed = 250 + self.level * 9 + phase * 52
        shots = []
        pattern_slot = self.attack_index % (2 + phase)
        pattern = BOSS_ATTACK_ORDERS[self.boss_type][pattern_slot]
        self.attack_index += 1

        if pattern == 0:
            # A focused multi-cannon burst.
            count = 3 + phase
            for index in range(count):
                offset = (index - (count - 1) / 2) * 27
                shots.append(aimed_bullet(
                    self.pos.x + offset, self.pos.y + self.radius * 0.52,
                    player_pos, speed, self.spec["color"], 17 + phase * 3,
                ))
            self.attack_timer = max(0.42, 1.25 - phase * 0.19)
        elif pattern == 1:
            # A dense, widening fan.
            count = 5 + phase * 2
            for index in range(count):
                angle = (index - (count - 1) / 2) * (0.15 if phase < 3 else 0.13)
                shots.append(Bullet(
                    self.pos.x, self.pos.y + self.radius * 0.52,
                    math.sin(angle) * speed, math.cos(angle) * speed,
                    14 + phase * 3, self.spec["core"], 7 + phase, False,
                ))
            self.attack_timer = max(0.38, 1.35 - phase * 0.24)
        elif pattern == 2:
            # A fast, bright aimed laser bolt.
            laser = aimed_bullet(
                self.pos.x, self.pos.y + self.radius * 0.52, player_pos,
                speed * 2.5, (106, 244, 255), 27 + phase * 5,
            )
            laser.radius = 10 + phase
            laser.laser = True
            shots.append(laser)
            self.attack_timer = max(0.34, 1.05 - phase * 0.19)
        elif pattern == 3:
            # Homing-style aimed missiles; guidance is fixed at launch.
            for side in (-1, 1):
                shots.append(aimed_bullet(
                    self.pos.x + side * self.radius * 0.48,
                    self.pos.y + self.radius * 0.42, player_pos,
                    speed * 0.73, (255, 154, 82), 31 + phase * 5,
                ))
                shots[-1].missile = True
                shots[-1].radius = 9
            self.attack_timer = max(0.45, 1.55 - phase * 0.25)
        else:
            # Phase-three radial burst followed by a punishing aimed shot.
            count = 10 + phase * 2
            for index in range(count):
                angle = math.tau * index / count + self.age * 0.15
                shots.append(Bullet(
                    self.pos.x, self.pos.y + self.radius * 0.34,
                    math.cos(angle) * speed * 0.8,
                    math.sin(angle) * speed * 0.8,
                    20 + phase * 3, self.spec["core"], 8, False,
                ))
            shots.append(aimed_bullet(
                self.pos.x, self.pos.y + self.radius * 0.52, player_pos,
                speed * 1.35, (255, 85, 110), 34 + phase * 5,
            ))
            self.attack_timer = 1.65
        return shots

    def hit(self, damage):
        if not self.alive or damage <= 0:
            return False
        self.health = max(0, self.health - damage)
        if self.health == 0:
            self.alive = False
            self.is_dying = True
            self.death_timer = 2.35
            self.death_elapsed = 0.0
            return True
        self._update_phase()
        return False

    def draw(self, surface):
        x, y = round(self.pos.x), round(self.pos.y)
        pulse = 0.5 + 0.5 * math.sin(self.age * (4 + self.phase))
        hull = self.spec["color"]
        core = self.spec["core"]
        if self.is_dying:
            fade = max(0.0, min(1.0, self.death_timer / 0.7))
            hull = tuple(int(channel * fade) for channel in hull)
            core = tuple(int(channel * fade) for channel in core)
            if self.death_elapsed % 0.18 < 0.09:
                pygame.draw.circle(surface, (255, 235, 190),
                                   (x, y), int(self.radius * (1.0 + self.death_elapsed * 0.24)), 3)

        pygame.draw.ellipse(surface, (20, 15, 42),
                            (x - self.radius - 25, y - self.radius * 0.47,
                             self.radius * 2 + 50, self.radius * 1.45))
        if self.boss_type == "alien_destroyer":
            self._draw_destroyer(surface, x, y, hull, core, pulse)
        elif self.boss_type == "galactic_warship":
            self._draw_warship(surface, x, y, hull, core, pulse)
        else:
            self._draw_overlord(surface, x, y, hull, core, pulse)
        for side in (-1, 1):
            engine_x = x + side * int(self.radius * 0.72)
            pygame.draw.circle(
                surface, core, (engine_x, y + int(self.radius * 0.23)),
                5 + int(pulse * 3),
            )
            pygame.draw.circle(
                surface, (245, 249, 255), (engine_x, y + int(self.radius * 0.23)),
                2,
            )
        pygame.draw.line(surface, core, (x - 30, y + 28), (x + 30, y + 28), 2)
        for window in (-18, 0, 18):
            pygame.draw.circle(surface, (234, 244, 255),
                               (x + window, y - 25), 2 + int(pulse))

    def _draw_destroyer(self, surface, x, y, hull, core, pulse):
        r = self.radius
        pygame.draw.polygon(surface, (65, 34, 85), [
            (x - r - 28, y - 18), (x - r - 6, y - 38), (x - 37, y - 29),
            (x, y - 64), (x + 37, y - 29), (x + r + 6, y - 38),
            (x + r + 28, y - 18), (x + r + 4, y + 23), (x + 30, y + 34),
            (x, y + 58), (x - 30, y + 34), (x - r - 4, y + 23),
        ])
        pygame.draw.polygon(surface, hull, [
            (x - r - 18, y - 16), (x - 34, y - 28), (x, y - 51),
            (x + 34, y - 28), (x + r + 18, y - 16), (x + 33, y + 17),
            (x, y + 45), (x - 33, y + 17),
        ])
        for side in (-1, 1):
            pygame.draw.polygon(surface, core, [
                (x + side * 55, y - 14), (x + side * (r + 17), y - 23),
                (x + side * (r + 5), y + 10), (x + side * 47, y + 8),
            ])
        pygame.draw.polygon(surface, core, [
            (x, y - 36), (x + 19, y + 1), (x, y + 25), (x - 19, y + 1),
        ])
        pygame.draw.circle(surface, (255, 248, 215), (x, y + 1), 6 + int(pulse * 5))

    def _draw_warship(self, surface, x, y, hull, core, pulse):
        r = self.radius
        pygame.draw.polygon(surface, (38, 57, 98), [
            (x - r - 34, y - 19), (x - r - 18, y - 5), (x - r - 29, y + 21),
            (x - 44, y + 14), (x - 23, y + 40), (x + 23, y + 40),
            (x + 44, y + 14), (x + r + 29, y + 21), (x + r + 18, y - 5),
            (x + r + 34, y - 19), (x + 42, y - 34), (x, y - 55),
            (x - 42, y - 34),
        ])
        pygame.draw.polygon(surface, hull, [
            (x - r - 18, y - 17), (x - 42, y - 23), (x - 24, y - 41),
            (x, y - 48), (x + 24, y - 41), (x + 42, y - 23),
            (x + r + 18, y - 17), (x + r + 8, y + 10), (x + 31, y + 23),
            (x, y + 35), (x - 31, y + 23), (x - r - 8, y + 10),
        ])
        for side in (-1, 1):
            pygame.draw.circle(surface, core, (x + side * (r + 10), y + 3),
                               12 + int(pulse * 4))
            pygame.draw.line(surface, (205, 235, 255),
                             (x + side * 34, y - 12), (x + side * (r + 19), y - 12), 4)
        pygame.draw.polygon(surface, core, [
            (x, y - 34), (x + 19, y - 5), (x + 13, y + 20),
            (x, y + 30), (x - 13, y + 20), (x - 19, y - 5),
        ])
        pygame.draw.circle(surface, (235, 252, 255), (x, y + 1), 7 + int(pulse * 4))

    def _draw_overlord(self, surface, x, y, hull, core, pulse):
        r = self.radius
        pygame.draw.polygon(surface, (75, 29, 58), [
            (x - r - 34, y - 17), (x - r - 12, y - 39),
            (x - 47, y - 21), (x - 29, y - 52), (x, y - 65),
            (x + 29, y - 52), (x + 47, y - 21),
            (x + r + 12, y - 39), (x + r + 34, y - 17),
            (x + r + 10, y + 16), (x + 37, y + 28),
            (x + 20, y + 51), (x, y + 38), (x - 20, y + 51),
            (x - 37, y + 28), (x - r - 10, y + 16),
        ])
        pygame.draw.polygon(surface, hull, [
            (x - r - 21, y - 14), (x - 40, y - 29), (x - 24, y - 42),
            (x, y - 53), (x + 24, y - 42), (x + 40, y - 29),
            (x + r + 21, y - 14), (x + r, y + 12), (x + 29, y + 22),
            (x, y + 35), (x - 29, y + 22), (x - r, y + 12),
        ])
        for side in (-1, 1):
            pygame.draw.polygon(surface, core, [
                (x + side * 36, y - 22), (x + side * (r + 22), y - 19),
                (x + side * (r + 4), y + 7), (x + side * 31, y + 10),
            ])
            pygame.draw.circle(surface, (255, 240, 190),
                               (x + side * 57, y - 8), 5 + int(pulse * 3))
        pygame.draw.polygon(surface, core, [
            (x, y - 43), (x + 24, y - 5), (x + 15, y + 24),
            (x, y + 33), (x - 15, y + 24), (x - 24, y - 5),
        ])
        pygame.draw.circle(surface, (255, 255, 238), (x, y + 1), 9 + int(pulse * 5))

    def advance_death(self, dt):
        if not self.is_dying:
            return False
        self.death_timer = max(0.0, self.death_timer - dt)
        self.death_elapsed += dt
        return self.death_timer <= 0
