"""Modo Comandante (Acto 2, Base Central y Guerra de Asedio): el Operador no existe en el mapa.

Estas dos piezas ocupan su lugar para el código compartido (construcción, combate, Búnker) que pregunta por él."""
import pygame
from pygame.math import Vector2


class NoOperator:
    """El Operador no se pilota en las escenas de mando: el mixin de construcción solo necesita saber que no hay nadie en el
    mapa (sin sprite, sin colisión). No es la clase Operator."""
    build_mode = False

    def __init__(self):
        self.pos = Vector2(-10 ** 6, -10 ** 6)             # propios de cada escena (nunca compartidos entre instancias)
        self.rect = pygame.Rect(-10 ** 6, -10 ** 6, 0, 0)

    def alive(self):
        return True

    def queue_melee(self):
        pass


class Absent:
    """Lo que ven las funciones de combate en lugar del Operador: nadie (ni vivo, ni tocable)."""
    pos = Vector2(-10 ** 6, -10 ** 6)
    vision_bonus = 0

    def alive(self):
        return False
