"""Nodo de plasma de la Tierra de Nadie: se captura con drones aliados cerca (y sin enemigos), con reserva FINITA de Núcleos.

Da 1 Núcleo al capturarse y un goteo hasta `drip_cores` más (máximo 3 por nodo); agotado, pasa a dar un flujo modesto de chatarra.
Un tope por campaña (`campaign_cap`, CampaignRun.siege_cores_earned) impide farmear Núcleos reintentando el asedio."""
import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import GameSprite
from src.ui import loot_art

OWNER_COLOR = {"neutral": (130, 160, 170), "player": (0, 220, 255), "enemy": (235, 70, 70)}


class PlasmaNode(GameSprite):
    layer = 0
    PAD_RADIUS = 46

    def __init__(self, pos, index=0, cfg=None):
        super().__init__()
        self.cfg = cfg or U.PLASMA_NODE
        self.pos = Vector2(pos)
        self.index = index
        self.owner = "neutral"
        self.progress = 0.0                         # -1 (enemigo) .. +1 (jugador)
        self.cores_given = 0                        # Núcleos de la reserva ya repartidos (1 + goteo)
        self.drip_timer = 0.0
        self.scrap_timer = 0.0
        self.t = 0.0
        self._frame = None
        self.image = loot_art.pad_frame(self.PAD_RADIUS, OWNER_COLOR["neutral"], "diamond", 0)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    @property
    def reserve(self):
        """Núcleos máximos de este nodo en toda la partida."""
        return self.cfg["first_cores"] + self.cfg["drip_cores"]

    @property
    def depleted(self):
        return self.cores_given >= self.reserve

    def _count_near(self, group, alive_only=True):
        r2 = self.cfg["radius"] ** 2
        return sum(1 for s in group if s.alive() and s.pos.distance_squared_to(self.pos) <= r2)

    def _grant(self, res, run, n):
        """Entrega `n` Núcleos respetando el tope de la campaña; el nodo se agota igual."""
        left = max(0, self.cfg["campaign_cap"] - run.siege_cores_earned)
        give = min(n, left)
        if give:
            res.add_cores(give)
            run.siege_cores_earned += give
        self.cores_given += n
        return give

    def update(self, dt, world, res, run):
        """Captura, goteo de Núcleos y, con la reserva agotada, flujo de chatarra. Devuelve los Núcleos entregados este paso."""
        self.t += dt
        allies = self._count_near([d for d in world.drones if hasattr(d, "home")])
        foes = self._count_near(world.enemies)
        rate = dt / self.cfg["capture_time"]
        gave = 0
        if allies and not foes:
            self.progress = min(1.0, self.progress + rate)
            if self.progress >= 1.0 and self.owner != "player":
                self.owner = "player"
                if self.cores_given == 0:
                    gave += self._grant(res, run, self.cfg["first_cores"])
        elif foes and not allies:
            self.progress = max(-1.0, self.progress - rate)
            if self.progress <= -1.0:
                self.owner = "enemy"
        if self.owner == "player":
            if not self.depleted:
                self.drip_timer += dt
                if self.drip_timer >= self.cfg["drip_interval"]:
                    self.drip_timer = 0.0
                    gave += self._grant(res, run, 1)
            else:
                self.scrap_timer += dt
                if self.scrap_timer >= self.cfg["scrap_interval"]:
                    self.scrap_timer = 0.0
                    res.add_metal(self.cfg["scrap_trickle"])
        frame = int(self.t * 8) % loot_art.PAD_FRAMES
        if frame != self._frame:
            self._frame = frame
            color = OWNER_COLOR[self.owner]
            if self.depleted:
                color = tuple(c // 2 for c in color)
            self.image = loot_art.pad_frame(self.PAD_RADIUS, color, "diamond", frame)
        return gave

    def draw_overlay(self, surface, screen_rect, offset):
        pygame.draw.circle(surface, OWNER_COLOR[self.owner], screen_rect.center, self.cfg["radius"], 1)
        if 0 < abs(self.progress) < 1:
            ring = pygame.Rect(0, 0, self.PAD_RADIUS * 2 - 6, self.PAD_RADIUS * 2 - 6)
            ring.center = screen_rect.center
            pygame.draw.arc(surface, C.WHITE, ring, 1.5708, 1.5708 + 6.2832 * abs(self.progress), 5)
