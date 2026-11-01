"""Sitio de obra del Búnker de Mando: el andamio de la Base Central donde se ensambla (E con el Operador, clic con VULCANO)."""
import pygame

import config as C
from src.config import UNITS as U
from src.entities.interactable import Interactable
from src.ui import structure_art as art


class BunkerSite(Interactable):
    """Andamio sobre la huella de 3x3 celdas del Búnker. Sólido (nada se construye encima) hasta que se ensambla."""
    layer = 0

    def __init__(self, pos):
        size = U.BUNKER["cells"] * C.BUILD_GRID
        super().__init__(pos, (size, size), U.BUNKER["site_label"], radius=size + 10)

    def _render(self, size):
        return art.render_bunker_site(size)

    def draw_overlay(self, surface, screen_rect, offset):
        if int(self.t * 1.4) % 2 == 0:                                       # baliza ámbar de obra
            pygame.draw.circle(surface, (255, 170, 40), (screen_rect.right - 12, screen_rect.y + 12), 4)
        super().draw_overlay(surface, screen_rect, offset)
