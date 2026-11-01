"""Fortaleza enemiga evolutiva del asedio (Paso D): una EnemyBase que mejora con el reloj de amenaza.

Fase I: núcleo de 1200 HP y 2 torretas ligeras (sin escudo). Fase II: generador de escudo y 2 torretas pesadas (centinelas: con el
generador y una centinela en pie, el núcleo es invulnerable). Fase III: Factoría, de la que dependen las marchas de Tanques.
Las mejoras se construyen con tiempo de obra (andamio visible) y una pieza destruida NO reaparece al instante: se reconstruye tras
un retardo que se acorta con la fase."""
import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import GameSprite
from src.entities.enemy_base import EnemyBase, _hostile_tint
from src.entities.foundry import HostileStructure
from src.ui import structure_art as art

G = C.BUILD_GRID
TRACKED_ROLES = ("turret", "sentinel", "generator", "factory")


class EnemyFactory(HostileStructure):
    """Factoría enemiga (fase III): mientras está en pie salen las marchas de Tanques. Al caer avisa a su base."""
    kind = "fabrica"
    role = "factory"

    def __init__(self, pos, base):
        self.base = base
        self.spec = {"hp": base.cfg["factory_hp"]}
        size = base.cfg["factory_size"]
        super().__init__(pos, base.cfg["factory_hp"], (size, size))

    def _render(self, size):
        return _hostile_tint(art.render_factory(size))

    def kill(self):
        was_alive = self.alive()
        super().kill()
        if was_alive and self.base is not None:
            self.base.on_building_lost(self)


class EnemySite(GameSprite):
    """Obra enemiga en curso: andamio rojo translúcido con su barra de avance. No se puede dañar; ocupa su sitio."""
    layer = 1

    def __init__(self, kind, role, pos, size, ready_at, duration):
        super().__init__()
        self.kind, self.role, self.size = kind, role, size
        self.pos = Vector2(pos)
        self.ready_at, self.duration = ready_at, max(0.001, duration)
        self.time_left = duration
        if kind == "fabrica":
            img = _hostile_tint(art.render_factory(size))
        elif kind == "generador":
            img = _hostile_tint(art.render_generator(size))
        else:
            img = art.render_tower_base(size, "hostile")
        self.image = img.copy()
        self.image.set_alpha(110)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    @property
    def fraction(self):
        return max(0.0, min(1.0, 1.0 - self.time_left / self.duration))

    def draw_overlay(self, surface, screen_rect, offset):
        r = screen_rect.inflate(2, 2)
        pygame.draw.rect(surface, (255, 70, 70), r, 2)
        bar = pygame.Rect(screen_rect.x, screen_rect.bottom + 4, screen_rect.w, 5)
        pygame.draw.rect(surface, (30, 10, 10), bar)
        pygame.draw.rect(surface, (255, 90, 90), (bar.x, bar.y, int(bar.w * self.fraction), bar.h))
        pygame.draw.rect(surface, C.WHITE, bar, 1)


class EnemyFortress(EnemyBase):
    def __init__(self, pos, world, cfg=None):
        self.cfg = cfg or U.THREAT_CLOCK["fortress"]
        super().__init__(pos, "easy", world, garrison=False)
        self.core.hp = self.core.max_hp = self.cfg["core_hp"]
        self.build_priority = []                  # sin construcciones al azar: evoluciona con el reloj (extractores y reparación siguen)
        self.time = 0.0
        self.phase = 0
        self.sites = []
        self.factory = None
        self.rebuilt = 0                          # piezas reconstruidas tras ser destruidas
        self.apply_phase(1, instant=True)

    # --- evolución ---
    def apply_phase(self, phase, instant=False):
        """Encarga las piezas de la fase (con tiempo de obra, salvo la fase I, que nace montada)."""
        self.phase = max(self.phase, phase)
        for kind, role, offset in self.cfg[f"phase_{phase}"]:
            self._order(kind, role, offset, 0.0 if instant else self.cfg["build_time"])

    def _order(self, kind, role, offset, delay):
        size = (self.cfg["factory_size"],) * 2 if kind == "fabrica" else (G, G)
        pos = self._garrison_spot(offset, size)                    # sitio libre, reservado ya
        if delay <= 0:
            self._finish(kind, role, pos)
            return
        site = EnemySite(kind, role, pos, size, self.time + delay, delay)
        self.sites.append(site)
        self.world.all_sprites.add(site)
        self.world.solids.add(site)

    def _finish(self, kind, role, pos):
        if kind == "fabrica":
            b = EnemyFactory(pos, self)
            self.factory = b
        else:
            b = self._make_building(kind, pos, role)
        self.buildings.append(b)
        self._add(b)
        return b

    def update(self, dt, player_position=None):
        super().update(dt, player_position)
        if self.destroyed:
            return
        self.time += dt
        for site in list(self.sites):
            site.time_left = max(0.0, site.ready_at - self.time)
            if self.time >= site.ready_at:
                self._drop_site(site)
                self._finish(site.kind, site.role, Vector2(site.pos))

    def _drop_site(self, site):
        if site in self.sites:
            self.sites.remove(site)
        self.world.solids.remove(site)
        site.kill()

    # --- reacciones ---
    def on_building_lost(self, building):
        tracked = getattr(building, "role", None) in TRACKED_ROLES
        super().on_building_lost(building)
        if self.destroyed or not tracked:
            return
        if building is self.factory:
            self.factory = None
        delay = self.cfg["rebuild_delay"][max(1, min(3, self.phase))]
        offset = building.pos - self.pos
        self._order(building.kind, building.role, (offset.x, offset.y), delay)       # vuelve tras un retardo, no al instante
        self.rebuilt += 1

    def on_core_destroyed(self):
        for site in list(self.sites):
            self._drop_site(site)
        super().on_core_destroyed()

    # --- consultas ---
    @property
    def shielded(self):
        return self.core.shielded

    def structures_alive(self):
        return [b for b in self.buildings if b.alive()]
