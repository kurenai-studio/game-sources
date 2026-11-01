"""Sitio de obra (blueprint): la orden de construcción que VULCANO ejecuta en la Base Central."""
import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite


class ConstructionSite(GameSprite):
    """Andamio translúcido con el aspecto de la estructura. VULCANO lo ensambla a su tasa de trabajo (HP/s) pagando la
    chatarra a medida que avanza; los núcleos (si los pide) se pagan al ordenar la obra. Al llegar a 100% pasa a ser la
    estructura real con toda su vida."""
    layer = 1

    def __init__(self, btype, pos, ghost, scrap_cost, core_cost, energy, total_hp, deposit=None):
        super().__init__()
        self.btype = btype
        self.pos = Vector2(pos)
        self.deposit = deposit
        self.scrap_cost, self.core_cost, self.energy = int(scrap_cost), int(core_cost), energy
        self.total = float(total_hp)               # HP que hay que ensamblar (la vida de la estructura terminada)
        self.progress = 0.0
        self.paid = 0                              # chatarra ya consumida (se reembolsa si se cancela la obra)
        self.waiting = False                       # sin chatarra para seguir
        self.t = 0.0
        self.image = ghost
        self.rect = ghost.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    @property
    def fraction(self):
        return min(1.0, self.progress / self.total)

    @property
    def done(self):
        return self.progress >= self.total - 1e-6

    def _paid_at(self, progress):
        return round(self.scrap_cost * min(1.0, progress / self.total))

    def can_progress(self, resources, work=C.VULCANO_REPAIR_RATE / 60):
        """¿Alcanza la chatarra para el siguiente tramo de obra?"""
        return self._paid_at(self.progress + work) - self.paid <= resources.metal

    def advance(self, dt, rate, resources):
        """Ensambla hasta `rate * dt` HP cobrando la chatarra correspondiente. Devuelve "building", "waiting" (falta chatarra)
        o "done" (estructura completa)."""
        self.t += dt
        new = min(self.total, self.progress + rate * dt)
        need = self._paid_at(new) - self.paid
        if need > resources.metal:
            self.waiting = True
            return "waiting"
        self.waiting = False
        if need > 0:
            resources.spend_metal(need)
            self.paid += need
        self.progress = new
        return "done" if self.done else "building"

    def draw_overlay(self, surface, screen_rect, offset):
        """Contorno de obra que corre (cian; ámbar si espera chatarra) y barra de avance."""
        color = (255, 170, 40) if self.waiting else (0, 225, 255)
        r = screen_rect.inflate(2, 2)
        step, phase = 8, int(self.t * 20 + pygame.time.get_ticks() / 90) % 8
        for x in range(r.x - phase, r.right, step * 2):
            pygame.draw.line(surface, color, (max(r.x, x), r.y), (min(r.right, x + step), r.y), 2)
            pygame.draw.line(surface, color, (max(r.x, x), r.bottom), (min(r.right, x + step), r.bottom), 2)
        for y in range(r.y - phase, r.bottom, step * 2):
            pygame.draw.line(surface, color, (r.x, max(r.y, y)), (r.x, min(r.bottom, y + step)), 2)
            pygame.draw.line(surface, color, (r.right, max(r.y, y)), (r.right, min(r.bottom, y + step)), 2)
        bar = pygame.Rect(screen_rect.x, screen_rect.bottom + 4, screen_rect.w, 5)
        pygame.draw.rect(surface, (14, 20, 26), bar)
        pygame.draw.rect(surface, (255, 170, 40) if self.waiting else C.GREEN, (bar.x, bar.y, int(bar.w * self.fraction), bar.h))
        pygame.draw.rect(surface, C.WHITE, bar, 1)
