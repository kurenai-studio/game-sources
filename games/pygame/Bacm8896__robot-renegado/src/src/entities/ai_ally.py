import math

import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite


class AIAlly(GameSprite):
    """La IA consciente: dron flotante que acompaña al piloto (Acto 1) o custodia el núcleo (Acto 2)."""
    layer = 5
    casts_shadow = True
    shadow_lift = 14

    def __init__(self, pos):
        super().__init__()
        self.pos = Vector2(pos)
        self.mode = "follow"          # "follow" | "guard"
        self.t = 0.0
        self.messages = []            # [texto, ttl]
        self.image = pygame.Surface((28, 28), pygame.SRCALPHA)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def say(self, text, ttl=5.0, sender="AURA"):
        """Envía el mensaje a la consola de transmisión (si hay una) o lo guarda localmente."""
        if getattr(self, "dialogue", None) is not None:
            self.dialogue.say(sender, text, ttl)
            return
        self.messages.append([text, ttl])
        del self.messages[:-4]

    def _draw(self):
        img = self.image
        img.fill((0, 0, 0, 0))
        pulse = 0.5 + 0.5 * math.sin(self.t * 4)
        pygame.draw.circle(img, (*C.CYAN, int(40 + 40 * pulse)), (14, 14), 13)
        pygame.draw.circle(img, (10, 40, 45), (14, 14), 8)
        pygame.draw.circle(img, C.CYAN, (14, 14), 8, 2)
        pygame.draw.circle(img, C.WHITE, (14, 14), 3)
        ang = self.t * 3
        ox, oy = 14 + 11 * math.cos(ang), 14 + 11 * math.sin(ang)
        pygame.draw.circle(img, C.MAGENTA, (round(ox), round(oy)), 2)

    def update(self, dt, world):
        self.t += dt
        player, core = world.player, world.core
        if self.mode == "follow" and player is not None and player.alive():
            # (la regeneración de AURA la aplica el propio Operador: Player._regenerate, en cualquier modo y escena)
            anchor = player.pos + Vector2(math.cos(self.t * 1.5), math.sin(self.t * 1.5)) * 42
        elif core is not None and core.alive():
            anchor = core.pos + Vector2(math.cos(self.t * 0.8), math.sin(self.t * 0.8)) * 58
            core.repair(2.0 * dt)
        else:
            anchor = self.pos
        self.pos += (anchor - self.pos) * min(1.0, dt * 6)
        self.rect.center = (round(self.pos.x), round(self.pos.y + math.sin(self.t * 3) * 3))
        self._draw()
        for msg in self.messages:
            msg[1] -= dt
        self.messages = [m for m in self.messages if m[1] > 0]
