"""Escenario del Acto 2: el mapa clásico (Fundición, Nivel de Alerta) o uno de los mapas de CAMPAIGN_MAPS.

`Scenario(key)` reúne todo lo que antes eran constantes del Acto 2 (tamaño, posición del Centro de Control, Fundición,
puertas de aparición y calendario de oleadas) para que el Acto 2 y la Base Central lean lo mismo y añadir un mapa sea solo
editar UNITS.CAMPAIGN_MAPS."""
import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.mechanics.wave import WaveGenerator


class Scenario:
    def __init__(self, key=None):
        self.key = key if key in U.CAMPAIGN_MAPS else None
        self.cfg = U.CAMPAIGN_MAPS.get(self.key)
        self.classic = self.cfg is None
        if self.classic:                                   # el Acto 2 de siempre
            self.name = "Asalto a la Fundición (clásico)"
            self.difficulty = None
            self.w, self.h = C.ACT2_W, C.ACT2_H
            self.cc_pos = Vector2(C.ACT2_CC_POS)
            self.foundry_pos = Vector2(C.ACT2_FOUNDRY_POS)
            self.spawn_zone = pygame.Rect(C.ACT2_SPAWN_ZONE)
            self.base_slots = []                           # las fija el Nivel de Alerta (UNITS.ENEMY_BASES)
            self.plan = None
            self.generator = None
            self.endless = False
            self.break_time = C.BREAK_TIME
            self.total_duration = None
            self.rewards = []
            self.deposit_offsets = list(C.ACT2_DEPOSIT_OFFSETS)
            return
        cfg = self.cfg
        self.name = cfg["name"]
        self.difficulty = cfg["difficulty"]
        self.w, self.h = cfg["map_size"]
        self.cc_pos = Vector2(cfg["player_base"])
        self.foundry_pos = Vector2(cfg["foundry_pos"]) if cfg.get("foundry") else None
        self.spawn_zone = (pygame.Rect(self.foundry_pos.x - 280, self.foundry_pos.y - 270, 130, 540)
                           if self.foundry_pos is not None else None)
        self.base_slots = [(Vector2(s["x"], s["y"]), s["id"]) for s in cfg["enemy_spawn_positions"]]
        self.generator = WaveGenerator(cfg)                # oleadas escaladas en bucle
        self.plan = self.generator.plan
        self.endless = self.foundry_pos is None   # sin Fundición no hay fase de asalto
        self.break_time = cfg["break_time"]
        self.total_duration = cfg["total_duration"]
        self.rewards = list(cfg["rewards"])
        # depósitos de la base y, en los mapas de campaña, los exteriores (incentivan expandir pilones y defensas)
        self.deposit_offsets = list(C.ACT2_DEPOSIT_OFFSETS) + [tuple(o) for o in cfg.get("outer_deposits", ())]

    @property
    def size(self):
        return (self.w, self.h)

    @property
    def has_foundry(self):
        return self.foundry_pos is not None

    def base_zones(self, bases):
        """Rectángulos de aparición bajo cada base enemiga viva (los refuerzos salen de sus puertas)."""
        return [pygame.Rect(int(b.pos.x) - 110, int(b.pos.y) + 80, 220, 50) for b in bases if not b.destroyed]


def scenario_of(res):
    """Escenario elegido en el menú de campaña (el clásico si no hay ninguno)."""
    return Scenario(getattr(res, "campaign_map", None))
