"""Fundición Renegada: perímetro defensivo (torretas y muros) y núcleo que hay que demoler."""
import itertools
import math

import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite
from src.entities.projectile import Projectile
from src.mechanics import combat
from src.ui import structure_art as art


class HostileStructure(GameSprite):
    layer = 1
    casts_shadow = True
    color = C.RED
    hostile = True

    def __init__(self, pos, hp, size):
        super().__init__()
        self.pos = Vector2(pos)
        self.hp = self.max_hp = hp
        self.image = self._render(size)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    def _render(self, size):
        raise NotImplementedError

    def take_damage(self, amount, direction=None):
        self.hp -= amount
        self.flash()
        if self.hp <= 0:
            self.kill()
            combat.FX.request_shake()
            return True
        return False

    def update(self, dt, world):
        pass

    def draw_dynamic(self, surface, screen_rect, offset):
        pass

    def draw_overlay(self, surface, screen_rect, offset):
        self.draw_dynamic(surface, screen_rect, offset)
        if self.hp < self.max_hp:
            bar = pygame.Rect(screen_rect.left, screen_rect.top - 8, screen_rect.w, 5)
            pygame.draw.rect(surface, (40, 0, 0), bar)
            pygame.draw.rect(surface, C.RED, (bar.x, bar.y, int(bar.w * self.hp / self.max_hp), 5))


class FoundryWall(HostileStructure):
    def __init__(self, pos):
        super().__init__(pos, C.FOUNDRY_WALL_HP, (C.BUILD_GRID, C.BUILD_GRID))

    def _render(self, size):
        return art.render_wall(size, "hostile")


class FoundryTurret(HostileStructure):
    """Torreta enemiga: dispara al jugador, drones y estructuras aliadas dentro de su alcance."""

    def __init__(self, pos):
        super().__init__(pos, C.FOUNDRY_TURRET_HP, (C.BUILD_GRID, C.BUILD_GRID))
        self.fire_timer = 0.0
        self.angle = 0.0

    def _render(self, size):
        return art.render_tower_base(size, "hostile")

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_turret_head(surface, screen_rect.center, self.angle, "hostile", True, art.now())

    def update(self, dt, world):
        self.fire_timer -= dt
        best, best_d = None, C.FOUNDRY_TURRET_RANGE ** 2
        player = [world.player] if world.player is not None and world.player.alive() else []
        for t in itertools.chain(player, world.drones, world.structures):
            d = self.pos.distance_squared_to(t.pos)
            if d < best_d:
                best, best_d = t, d
        if best is None:
            return
        direction = best.pos - self.pos
        ang = math.degrees(math.atan2(direction.y, direction.x))
        self.angle = ang
        if self.fire_timer <= 0 and direction.length_squared() > 0:
            world.enemy_bullets.add(Projectile(self.pos, direction, C.FOUNDRY_TURRET_DAMAGE, "enemy", lifetime=1.2))
            self.fire_timer = C.FOUNDRY_TURRET_DELAY


class FoundryCore(HostileStructure):
    """Núcleo de la Fundición: blindado mientras quede alguna torreta del perímetro en pie."""

    def __init__(self, pos, perimeter):
        self.perimeter = perimeter                 # grupo de torretas que lo protegen
        super().__init__(pos, C.FOUNDRY_HP_CORE, (80, 80))

    @property
    def shielded(self):
        return len(self.perimeter) > 0

    def _render(self, size):
        return art.render_core(size, "hostile")

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_energy_core(surface, screen_rect.center, "hostile", art.now(), 26)

    def take_damage(self, amount, direction=None):
        if self.shielded:
            return False                           # blindaje: hay que destruir el perímetro primero
        return super().take_damage(amount, direction)

    def draw_overlay(self, surface, screen_rect, offset):
        super().draw_overlay(surface, screen_rect, offset)
        if self.shielded:
            pygame.draw.circle(surface, C.MAGENTA, screen_rect.center, 52, 2)


def build_foundry(center, world):
    """Levanta la Fundición alrededor de `center` y devuelve su núcleo."""
    center = Vector2(center)
    turrets = pygame.sprite.Group()
    parts = []
    for i in range(C.FOUNDRY_TURRETS):
        a = math.tau * i / C.FOUNDRY_TURRETS + math.pi / 6
        t = FoundryTurret(center + Vector2(math.cos(a), math.sin(a)) * 190)
        turrets.add(t)
        parts.append(t)
    for deg in range(-80, 81, 20):                # arco de muros mirando hacia la base
        a = math.radians(180 + deg)
        p = center + Vector2(math.cos(a), math.sin(a)) * 270
        g = C.BUILD_GRID
        parts.append(FoundryWall(Vector2(round(p.x / g) * g, round(p.y / g) * g)))
    core = FoundryCore(center, turrets)
    parts.append(core)
    for s in parts:
        world.hostile.add(s)
        world.solids.add(s)
        world.all_sprites.add(s)
    return core
