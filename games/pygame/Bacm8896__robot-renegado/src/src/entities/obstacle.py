"""Obstáculos de nivel: muros indestructibles y la tubería rota que solo se salva con Dash."""
import random

import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite
from src.ui import entity_art


class Obstacle(GameSprite):
    """Muro de nivel indestructible. Se pinta en el fondo del mapa; el sprite solo aporta la colisión."""
    layer = 1
    dash_passable = False

    def __init__(self, rect):
        super().__init__()
        self.rect = pygame.Rect(rect)
        self.pos = Vector2(self.rect.center)

    def take_damage(self, amount):
        return False

    def draw(self, surface, offset=None):
        pass


class DashBarrier(Obstacle):
    """Brecha del Dash: un foso que corta el pasillo. La caja de colisión (`rect`) bloquea el paso y solo se cruza con un Dash
    (durante el dash se atraviesa); el dibujo es un abismo de bordes fracturados que sobresale unos píxeles de esa caja."""
    layer = 2
    dash_passable = True
    PAD = 12                                             # px de borde irregular a cada lado de la caja de colisión

    def __init__(self, rect):
        super().__init__(rect)
        self.t = 0.0
        self._rng = random.Random(self.rect.x * 31 + self.rect.y)
        self.image, self.tips = entity_art.render_chasm(self.rect.w, self.rect.h, self.PAD, self.rect.x * 31 + self.rect.y)

    def update(self, dt):
        self.t += dt

    def draw(self, surface, offset=None):
        # a diferencia de los muros, esta sí se dibuja; la imagen es más ancha que la caja de colisión
        off = Vector2() if offset is None else offset
        r = self.rect.move(-round(off.x) - self.PAD, -round(off.y))
        surface.blit(self.image, r)
        if int(self.t * 8) % 3 != 0:                     # chispas eléctricas intermitentes en las puntas de las ferrallas
            for tx, ty in self.tips:
                x, y = r.left + tx, r.top + ty
                pygame.draw.line(surface, C.YELLOW, (x, y), (x + self._rng.randint(-5, 5), y - self._rng.randint(3, 9)), 1)
