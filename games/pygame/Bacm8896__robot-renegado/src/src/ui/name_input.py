"""Caja de texto en pantalla para escribir un nombre: letras y números (máx. 12), Retroceso borra, ENTER confirma y el
cursor parpadea. La usan AURA (el Operador le dice su nombre en el 1.2) y el menú «Continuar» (escribir un perfil)."""
import time

import pygame

import config as C
from src.mechanics.save_manager import MAX_NAME


class NameInput:
    def __init__(self, title="", prompt="", max_len=MAX_NAME, text=""):
        self.title, self.prompt = title, prompt
        self.max_len = max_len
        self.text = text[:max_len]
        self.done = False
        self._t0 = time.monotonic()

    def handle_event(self, event):
        """Devuelve True si el evento era para la caja (y la caja lo consumió). ENTER marca `done`."""
        if event.type != pygame.KEYDOWN:
            return False
        if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
            self.done = True
        elif event.key == pygame.K_BACKSPACE:
            self.text = self.text[:-1]
        else:
            ch = getattr(event, "unicode", "") or ""
            if len(ch) == 1 and ch.isalnum() and len(self.text) < self.max_len:
                self.text += ch
        self._t0 = time.monotonic()                     # el cursor se ve fijo mientras se escribe
        return True

    @property
    def cursor_on(self):
        return int((time.monotonic() - self._t0) * 2) % 2 == 0     # parpadea 2 veces por segundo

    def draw(self, surface, hud, center=None, dim=True):
        cx, cy = center or (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT // 2 - 40)
        if dim:
            shade = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
            shade.fill((0, 0, 0, 150))
            surface.blit(shade, (0, 0))
        panel = pygame.Rect(0, 0, 560, 170)
        panel.center = (cx, cy)
        hud.panel(surface, panel, C.CYAN)
        if self.title:
            hud.text(surface, self.title, (cx, panel.y + 14), "m", C.CYAN, center=True)
        if self.prompt:
            hud.text(surface, self.prompt, (cx, panel.y + 44), "s", C.WHITE, center=True)
        box = pygame.Rect(0, 0, 380, 44)
        box.center = (cx, panel.y + 96)
        pygame.draw.rect(surface, (8, 14, 22), box)
        pygame.draw.rect(surface, C.CYAN, box, 2)
        r = hud.text(surface, self.text, (box.x + 14, box.y + 10), "m", C.WHITE, shadow=False)
        if self.cursor_on:
            x = (r.right + 3) if self.text else box.x + 14
            pygame.draw.line(surface, C.CYAN, (x, box.y + 9), (x, box.bottom - 9), 2)
        hud.text(surface, f"{len(self.text)}/{self.max_len} · letras y números · Retroceso borra · ENTER confirma",
                 (cx, panel.bottom - 26), "s", C.DARK_GRAY, center=True)
