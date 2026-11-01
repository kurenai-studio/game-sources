"""Hints contextuales intradiegéticos: ícono + texto pequeño, sin pantallas ni pausas.

Reglas: cada hint aparece UNA SOLA VEZ por campaña, desaparece cuando el jugador hace lo que enseña (`done`) o a los
10 segundos, y nunca bloquea el juego (no consume eventos). Pueden anclarse a un punto del mundo (sobre la grilla, una
estructura o la chatarra) o, sin ancla, apilarse en el centro de la pantalla."""
import math

import pygame
from pygame.math import Vector2

import config as C

DURATION = 10.0
ICON_W = 76                      # ancho reservado al ícono (la tecla ESPACIO es la más ancha)


class Hint:
    def __init__(self, hint_id, text, icon, anchor=None, blink=False, ttl=DURATION):
        self.id = hint_id
        self.text = text
        self.icon = icon                 # wasd | click_left | click_right | e | space | r_click
        self.anchor = anchor             # None | Vector2 (mundo) | callable() -> Vector2 | None
        self.blink = blink
        self.ttl = ttl
        self.age = 0.0

    def world_pos(self):
        a = self.anchor() if callable(self.anchor) else self.anchor
        return None if a is None else Vector2(a)


def ammo_hints(hints, player):
    """Hints de munición del Acto 2+ (el Acto 1 tiene munición infinita)."""
    if player.infinite_ammo:
        return
    if player.shots_fired > 0:
        hints.show("ammo_limited", "Munición limitada - busca suministros", "click_left")
    if player.out_of_ammo:
        hints.show("no_ammo", "SIN MUNICIÓN - Golpea cuerpo a cuerpo", "click_left")
    elif player.ammo > 0:
        hints.done("no_ammo")
    if player.melee_swings > 0:
        hints.show("melee", f"Click para golpe defensivo ({player.melee_damage} daño)", "click_left")
        hints.done("no_ammo")


class HintManager:
    def __init__(self):
        self.shown = set()               # ids ya mostrados alguna vez (una sola vez por campaña)
        self.active = {}                 # id -> Hint

    def reset(self):
        self.shown.clear()
        self.active.clear()

    def show(self, hint_id, text, icon, anchor=None, blink=False, ttl=DURATION):
        """Muestra el hint si nunca se mostró. Devuelve True si arrancó ahora."""
        if hint_id in self.shown:
            return False
        self.shown.add(hint_id)
        self.active[hint_id] = Hint(hint_id, text, icon, anchor, blink, ttl)
        return True

    def done(self, hint_id):
        """El jugador ya hizo lo que el hint enseña: desaparece."""
        self.active.pop(hint_id, None)

    def clear_active(self):
        """Al cambiar de escena los hints en pantalla se retiran (los ya mostrados no vuelven)."""
        self.active.clear()

    def update(self, dt):
        for hid in list(self.active):
            h = self.active[hid]
            h.age += dt
            if h.age >= h.ttl:
                del self.active[hid]

    # --- dibujo ---
    @staticmethod
    def _key(surface, hud, rect, label, lit=False):
        pygame.draw.rect(surface, (50, 56, 76) if not lit else C.CYAN, rect, border_radius=3)
        pygame.draw.rect(surface, C.WHITE, rect, 1, border_radius=3)
        hud.text(surface, label, rect.center, "s", C.BLACK if lit else C.WHITE, center=True, shadow=False)

    def _mouse(self, surface, hud, pos, left=False, right=False):
        body = pygame.Rect(pos[0], pos[1], 20, 28)
        pygame.draw.rect(surface, (50, 56, 76), body, border_radius=9)
        if left:
            pygame.draw.rect(surface, C.CYAN, (body.x + 1, body.y + 1, 9, 12), border_top_left_radius=8)
        if right:
            pygame.draw.rect(surface, C.CYAN, (body.x + 10, body.y + 1, 9, 12), border_top_right_radius=8)
        pygame.draw.rect(surface, C.WHITE, body, 1, border_radius=9)
        pygame.draw.line(surface, C.WHITE, (body.centerx, body.y), (body.centerx, body.y + 13), 1)

    def draw_icon(self, surface, hud, icon, x, y, t):
        """Ícono procedural de unos 40x30 px con la esquina superior izquierda en (x, y)."""
        pulse = int(t * 3) % 2 == 0
        if icon == "wasd":
            self._key(surface, hud, pygame.Rect(x + 28, y, 13, 13), "W", pulse)
            for i, k in enumerate("ASD"):
                self._key(surface, hud, pygame.Rect(x + 14 + i * 14, y + 15, 13, 13), k, pulse)
        elif icon in ("click_left", "click_right"):
            self._mouse(surface, hud, (x + 24, y), left=icon == "click_left", right=icon == "click_right")
        elif icon == "e":
            self._key(surface, hud, pygame.Rect(x + 22, y + 2, 24, 24), "E", pulse)
        elif icon == "space":
            self._key(surface, hud, pygame.Rect(x, y + 6, 70, 18), "ESPACIO", pulse)
        elif icon == "r_click":
            self._key(surface, hud, pygame.Rect(x + 12, y + 2, 20, 24), "R", pulse)
            self._mouse(surface, hud, (x + 36, y), left=True)


    def draw(self, surface, hud, camera=None):
        t = pygame.time.get_ticks() / 1000.0
        stack_y = 128
        placed = []
        for h in self.active.values():
            if h.blink and int(h.age * 4) % 2 == 1:
                continue
            msg_w = hud._render("s", h.text, C.WHITE).get_width()
            w, hgt = msg_w + ICON_W + 20, 38
            anchor = h.world_pos()
            if anchor is not None and camera is not None:
                s = camera.to_screen(anchor)
                x = int(s.x) - w // 2
                y = int(s.y) - 64 - int(3 * math.sin(h.age * 4))
            else:
                x = C.WINDOW_WIDTH // 2 - w // 2
                y = stack_y
                stack_y += hgt + 8
            x = max(6, min(C.WINDOW_WIDTH - w - 6, x))
            y = max(88, min(C.WINDOW_HEIGHT - hgt - 90, y))          # no tapa la cabecera central
            if x < 322 and y < 172:
                x = 322                                              # ni el panel de estado de la esquina superior izquierda
            r = pygame.Rect(x, y, w, hgt)
            while any(r.colliderect(p) for p in placed) and r.bottom < C.WINDOW_HEIGHT - 90:
                r.y += hgt + 6                                       # los hints no se montan unos sobre otros
            placed.append(r.copy())
            hud.panel(surface, r, C.YELLOW)
            self.draw_icon(surface, hud, h.icon, r.x + 6, r.y + 4, t)
            hud.text(surface, h.text, (r.x + 6 + ICON_W, r.y + 11), "s", C.WHITE)
