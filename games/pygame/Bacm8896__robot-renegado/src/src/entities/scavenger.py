import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import GameSprite

_TRI = [(11, 1), (21, 20), (1, 20)]


def _render(carrying):
    """Triángulo de 22 px de diseño, escalado a la medida actual (x0,83 = 18 px): colisión y dibujo a la vez."""
    img = pygame.Surface((22, 22), pygame.SRCALPHA)
    color = C.CYAN if carrying else C.RED
    pygame.draw.polygon(img, tuple(c // 4 for c in color), _TRI)
    pygame.draw.polygon(img, color, _TRI, 2)
    if carrying:
        pygame.draw.circle(img, C.YELLOW, (11, 14), 3)
    side = U.scaled(22)
    return pygame.transform.smoothscale(img, (side, side))


class ScavengerDrone(GameSprite):
    """Carroñero Hostil (no ataca). Máquina de estados por prioridades (UNITS.SCAVENGER):
      seek_scrap -> latching -> fleeing      1) va al botín (chatarra o núcleos) más cercano, se acopla y se lo lleva
      seek_pylon -> fleeing                  2) si no hay botín en el suelo: al pilón más cercano; al tocarlo, lo apaga
      fleeing                                3) huye por el borde del mapa más cercano; si sale, escapa con lo robado
    Si lo derriban antes de escapar suelta `stolen_scrap` más su drop base (`death_loot`)."""
    layer = 2
    casts_shadow = True
    shadow_lift = 12
    is_scavenger = True              # lo reconocen el Foco Vigía (detección) y las torretas (blanco prioritario)
    arena = pygame.Rect(0, 0, C.WINDOW_WIDTH, C.WINDOW_HEIGHT)      # limites del mapa; el estado lo ajusta

    def __init__(self, start_pos, target_pos=None, exit_point=None, pylon=None):
        super().__init__()
        spec = U.SCAVENGER
        self.pos = Vector2(start_pos)
        self.vel = Vector2(0, 0)
        self.speed = spec["speed"]
        self.armor = spec["armor"]
        self.hp = spec["hp"]
        self.dead = False
        self.detected_timer = 0.0        # > 0: un Foco Vigía lo tiene a la vista (revelado y marcado como prioritario)
        self.state = "seek_scrap"        # seek_scrap | latching | seek_pylon | fleeing
        self.goal = None                 # el botín (ScrapItem / CoreItem) o el pilón al que va
        self.hint = Vector2(target_pos) if target_pos is not None else None   # dónde cayó el botín que lo atrajo
        self.exit_point = Vector2(exit_point) if exit_point is not None else None
        self.stolen_scrap = 0            # chatarra robada (la suelta si lo derriban)
        self.cores_value = 0             # núcleos de plasma robados
        self.latch_timer = 0.0
        self.scan_timer = 0.0
        self.sabotaged = None            # el pilón que apagó
        self.on_death = None             # callback(drone)
        self.on_escape = None            # callback(drone): escapó con botín
        self.on_sabotage = None          # callback(drone, pilón): dejó un pilón sin energía
        if pylon is not None:            # orden directa de sabotaje
            self.state, self.goal = "seek_pylon", pylon
        self.image = _render(False)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    # --- compatibilidad con quien lee el botín ---
    @property
    def scrap_value(self):
        return self.stolen_scrap

    @scrap_value.setter
    def scrap_value(self, value):
        self.stolen_scrap = int(value)

    @property
    def detected(self):
        """¿Lo ve un Foco Vigía operativo? Revelado en la niebla y prioritario para las torretas enlazadas."""
        return self.detected_timer > 0

    @property
    def carrying_scrap(self):
        return self.stolen_scrap > 0

    @property
    def carrying(self):
        return self.stolen_scrap > 0 or self.cores_value > 0

    @property
    def pylon(self):
        return self.goal if self.state == "seek_pylon" else None

    def draw_overlay(self, surface, screen_rect, offset):
        """Detectado por un Foco Vigía: anillo rojo parpadeante y marca sobre el Carroñero."""
        if self.detected:
            c = screen_rect.center
            if int(pygame.time.get_ticks() / 150) % 2 == 0:
                pygame.draw.circle(surface, C.RED, c, 18, 2)
            pygame.draw.polygon(surface, C.RED, [(c[0], c[1] - 24), (c[0] - 5, c[1] - 32), (c[0] + 5, c[1] - 32)])

    # --- daño y botín ---
    def take_damage(self, amount, direction=None, armor_pierce=0):
        """Mismo contrato que Enemy.take_damage (las armas que perforan armadura también le pasan `armor_pierce`)."""
        if self.dead:
            return False
        self.hp -= max(0.0, amount - max(0, self.armor - armor_pierce))
        self.flash()
        if self.hp <= 0:
            self.dead = True
            self.kill()
            if self.on_death:
                self.on_death(self)
            return True
        return False

    def death_loot(self, rng=random):
        """Chatarra que suelta al caer: lo que robó más su drop base."""
        lo, hi = U.SCAVENGER["base_drop"]
        return self.stolen_scrap + rng.randint(lo, hi)

    # --- objetivos ---
    @staticmethod
    def _nearest(group, pos, valid=lambda s: True):
        best = [s for s in (group or ()) if s.alive() and valid(s)]
        return min(best, key=lambda s: s.pos.distance_squared_to(pos)) if best else None

    def _pick_loot(self, scraps_group, cores_group):
        """El botín más cercano del suelo (chatarra o núcleos), o None."""
        cands = [s for g in (scraps_group, cores_group) if g is not None for s in g if s.alive()]
        return min(cands, key=lambda s: s.pos.distance_squared_to(self.pos)) if cands else None

    def _pick_pylon(self, pylons):
        """El pilón más cercano; mejor uno que aún funcione (si ya están todos apagados, el más cercano)."""
        return (self._nearest(pylons, self.pos, lambda p: getattr(p, "disabled_timer", 0) <= 0)
                or self._nearest(pylons, self.pos))

    def _start_flee(self):
        """Huye por el borde más cercano a donde está ahora (80 px fuera del mapa)."""
        self.state = "fleeing"
        if self.exit_point is None:
            a, p = self.arena, self.pos
            gaps = {"l": p.x - a.left, "r": a.right - p.x, "t": p.y - a.top, "b": a.bottom - p.y}
            side = min(gaps, key=gaps.get)
            self.exit_point = {"l": Vector2(a.left - 80, p.y), "r": Vector2(a.right + 80, p.y),
                               "t": Vector2(p.x, a.top - 80), "b": Vector2(p.x, a.bottom + 80)}[side]

    def _move_toward(self, point, dt, speed):
        to = point - self.pos
        if to.length_squared() > 1:
            self.vel = to.normalize() * speed
            self.pos += self.vel * dt

    # --- máquina de estados ---
    def update(self, dt, scraps_group, cores_group=None, pylons=None):
        spec = U.SCAVENGER
        reach = spec["contact_radius"]
        self.detected_timer = max(0.0, self.detected_timer - dt)
        self.scan_timer -= dt
        if self.state in ("seek_scrap", "seek_pylon") and (self.scan_timer <= 0 or self.goal is None
                                                          or not self.goal.alive()):
            self.scan_timer = spec["rescan"]
            loot = self._pick_loot(scraps_group, cores_group)
            if loot is not None:                                        # 1) la chatarra manda
                self.state, self.goal = "seek_scrap", loot
            elif self.state == "seek_pylon" and self.goal is not None and self.goal.alive():
                pass                                                    # sigue con su pilón
            else:
                pylon = self._pick_pylon(pylons)
                if pylon is not None:                                   # 2) sin botín: sabotaje de la red
                    self.state, self.goal = "seek_pylon", pylon
                else:
                    self.goal = None
                    self._start_flee()                                  # nada que hacer: se retira
        if self.state == "seek_scrap":
            self._move_toward(self.goal.pos, dt, self.speed)
            if self.pos.distance_to(self.goal.pos) < reach:
                self.state, self.latch_timer = "latching", spec["latch_time"]     # se acopla al botín
        elif self.state == "latching":
            if self.goal is None or not self.goal.alive():
                self.state, self.scan_timer = "seek_scrap", 0.0         # alguien se lo llevó: busca otro
                self.goal = None
            else:
                self.latch_timer -= dt
                if self.latch_timer <= 0:
                    if getattr(self.goal, "is_core", False):
                        self.cores_value += self.goal.value
                    else:
                        self.stolen_scrap += self.goal.value
                    self.goal.kill()
                    self.goal = None
                    self.image = _render(True)
                    self._start_flee()                                  # 3) con el botín: huye
        elif self.state == "seek_pylon":
            self._move_toward(self.goal.pos, dt, self.speed)
            if self.pos.distance_to(self.goal.pos) < reach + 12 or self.rect.colliderect(self.goal.rect):
                self.goal.sabotage(spec["sabotage_time"])               # al contacto: apagado 8 s
                self.sabotaged = self.goal
                if self.on_sabotage:
                    self.on_sabotage(self, self.goal)
                self.goal = None
                self._start_flee()
        if self.state == "fleeing":
            self._move_toward(self.exit_point, dt, self.speed * spec["flee_mult"])
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            if self.pos.distance_to(self.exit_point) < 50 or not self.arena.colliderect(self.rect):
                if self.carrying and self.on_escape:
                    self.on_escape(self)
                self.dead = True
                self.kill()
        self.rect.center = (round(self.pos.x), round(self.pos.y))
