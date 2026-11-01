"""Nodos de chatarra agotables y extractores."""
import math

import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite
from src.entities.building import Building
from src.entities.interactable import Interactable
from src.ui import loot_art, structure_art as art


class ScrapDeposit(GameSprite):
    """Montículo estático con metal finito (300)."""
    layer = 0
    SIZE = 56

    def __init__(self, pos):
        super().__init__()
        self.pos = Vector2(pos)
        self.total_metal = C.DEPOSIT_METAL
        self.extractor = None
        self.variant = int(self.pos.x * 3 + self.pos.y * 7) % loot_art.DEPOSIT_VARIANTS
        self.image = self._render()
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    @property
    def depleted(self):
        return self.total_metal <= 0

    def _render(self):
        return loot_art.render_deposit(self.SIZE, self.variant, self.depleted)

    def take_metal(self, amount):
        taken = min(amount, self.total_metal)
        self.total_metal -= taken
        if taken and self.depleted:                       # se agota: solo quedan los restos
            self.image = self._render()
        return taken

    def draw(self, surface, offset=None):
        super().draw(surface, offset)

    def draw_overlay(self, surface, screen_rect, offset):
        if self.depleted:
            return
        now = pygame.time.get_ticks() / 1000.0                   # destellos del metal que aún queda
        for i, (fx, fy) in enumerate(loot_art.deposit_glints(self.variant)):
            k = (now * 0.9 + i / 3.0 + self.variant * 0.13) % 1.0
            if k < 0.25:
                loot_art.draw_glint(surface, screen_rect.x + int(fx * self.SIZE), screen_rect.y + int(fy * self.SIZE),
                                    math.sin(k / 0.25 * math.pi))
        if self.total_metal < C.DEPOSIT_METAL:
            bar = pygame.Rect(screen_rect.left, screen_rect.bottom + 2, screen_rect.w, 4)
            pygame.draw.rect(surface, (40, 36, 0), bar)
            pygame.draw.rect(surface, C.YELLOW, (bar.x, bar.y, int(bar.w * self.total_metal / C.DEPOSIT_METAL), 4))


class Extractor(Building):
    """Se coloca sobre un ScrapDeposit. Energizado: +5 metal cada 1,2 s (x2,5) hasta agotar el depósito. Una barra bajo
    el extractor muestra el ciclo de extracción y un anillo amarillo pulsa cada vez que entrega chatarra."""
    PULSE_TIME = 0.45                       # s que dura el anillo de entrega

    def __init__(self, pos, deposit):
        super().__init__("extractor", pos)
        self.deposit = deposit
        deposit.extractor = self
        self.timer = 0.0
        self.pending_income = 0
        self.pulse = 0.0                    # cuenta atrás del anillo de entrega

    @property
    def active(self):
        return self.is_powered and self.energized and not self.deposit.depleted

    def _render(self):
        return art.render_extractor(Building.SIZES["extractor"])

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_drill(surface, screen_rect.center, "mining", art.now(), self.active)

    def update(self, dt, enemies_group, bullets_group):
        super().update(dt, enemies_group, bullets_group)
        self.pulse = max(0.0, self.pulse - dt)
        if self.active:
            self.timer += dt
            if self.timer >= C.EXTRACTOR_INTERVAL:
                self.timer -= C.EXTRACTOR_INTERVAL
                self.pending_income += self.deposit.take_metal(C.EXTRACTOR_INCOME)
                self.pulse = self.PULSE_TIME

    def collect_income(self):
        got, self.pending_income = self.pending_income, 0
        return got

    def draw_overlay(self, surface, screen_rect, offset):
        super().draw_overlay(surface, screen_rect, offset)
        if self.deposit.depleted:
            pygame.draw.line(surface, C.DARK_GRAY, screen_rect.topleft, screen_rect.bottomright, 2)
        elif self.active:                                                    # barra de llenado del ciclo de extracción
            bar = pygame.Rect(screen_rect.left, screen_rect.bottom + 9, screen_rect.w, 5)
            pygame.draw.rect(surface, (14, 26, 10), bar)
            pygame.draw.rect(surface, C.GREEN, (bar.x, bar.y, int(bar.w * min(1.0, self.timer / C.EXTRACTOR_INTERVAL)), bar.h))
            pygame.draw.rect(surface, C.WHITE, bar, 1)
        if self.pulse > 0:                                                   # anillo que se expande al entregar chatarra
            k = 1 - self.pulse / self.PULSE_TIME
            pygame.draw.circle(surface, C.YELLOW, screen_rect.center, int(14 + 30 * k), 3 if k < 0.5 else 2)

    def kill(self):
        self.deposit.extractor = None
        super().kill()

    def dismantle(self):
        self.deposit.extractor = None
        super().dismantle()


class MiningDrill(Interactable):
    """Taladro temporal de la Op 2 (Saqueo de Yacimiento): E lo pone en marcha y perfora mientras resiste las oleadas.
    En marcha está en `world.structures` (los renegados lo atacan); debajo, su vida y el avance de la perforación."""
    casts_shadow = True

    def __init__(self, pos, hp):
        self.hp = self.max_hp = hp
        self.active = False
        self.progress = 0.0                                                  # 0..1 de la perforación
        super().__init__(pos, Building.SIZES["extractor"], "Activar taladro")

    def _render(self, size):
        return art.render_extractor(size)

    def take_damage(self, amount, *_, **__):
        if self.hp <= 0:
            return False
        self.hp = max(0.0, self.hp - amount)
        self.flash()
        if self.hp <= 0:
            self.kill()                                                      # destruido: la escena da la operación por fallida
            return True
        return False

    def draw_overlay(self, surface, screen_rect, offset):
        art.draw_drill(surface, screen_rect.center, "mining", art.now(), self.active)
        if self.active:
            for i, (frac, color) in enumerate(((self.hp / self.max_hp, C.GREEN), (self.progress, C.YELLOW))):
                bar = pygame.Rect(screen_rect.left, screen_rect.bottom + 6 + i * 8, screen_rect.w, 5)
                pygame.draw.rect(surface, (14, 20, 14), bar)
                pygame.draw.rect(surface, color, (bar.x, bar.y, int(bar.w * frac), bar.h))
                pygame.draw.rect(surface, C.WHITE, bar, 1)
        super().draw_overlay(surface, screen_rect, offset)
