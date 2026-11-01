"""Desvanecimiento temporal de textos del HUD (Base Central): visibles `hold` segundos y luego un fade-out de `fade`."""
import pygame

import config as C


class FadeTimer:
    """Reloj de visibilidad: alpha 255 durante `hold` s, baja a 0 en `fade` s. `reset()` lo vuelve a mostrar entero."""

    def __init__(self, hold=C.HUD_FADE_HOLD, fade=C.HUD_FADE_TIME):
        self.hold, self.fade = hold, fade
        self.t = 0.0

    def reset(self):
        self.t = 0.0

    def update(self, dt):
        self.t = min(self.t + dt, self.hold + self.fade)

    @property
    def alpha(self):
        if self.t <= self.hold:
            return 255
        if self.fade <= 0:
            return 0
        return max(0, round(255 * (1.0 - (self.t - self.hold) / self.fade)))

    @property
    def visible(self):
        return self.alpha > 0


def layer(size):
    """Capa transparente (alpha por píxel) donde se dibuja lo que luego se desvanece."""
    return pygame.Surface(size, pygame.SRCALPHA)


def blit_faded(target, surf, pos, alpha):
    """Pega `surf` en `target` con opacidad global `alpha` (0-255). Funciona con o sin alpha por píxel: trabaja sobre
    una copia, así la superficie original (p. ej. una caché) no cambia."""
    if alpha <= 0:
        return
    if alpha >= 255:
        target.blit(surf, pos)
        return
    faded = surf.copy()
    faded.set_alpha(alpha)
    target.blit(faded, pos)
