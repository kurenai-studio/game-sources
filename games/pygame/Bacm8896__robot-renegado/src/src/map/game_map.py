import random

import pygame
from pygame.math import Vector2

import config as C
from src.ui import terrain_art as terrain


class Camera:
    """Cámara centrada en el objetivo, limitada a los bordes del mapa, con screen shake."""

    def __init__(self, view_w, view_h):
        self.view = Vector2(view_w, view_h)
        self.offset = Vector2()
        self.shake_timer = 0.0
        self.shake_offset = (0, 0)
        self.returning = False            # tras la pausa táctica: vuelve suavemente al Operador

    # --- screen shake: desplaza el lienzo 2-4 px al azar durante 0.08 s ---
    def shake(self, duration=C.SHAKE_DURATION):
        self.shake_timer = duration

    def tick(self, dt):
        if self.shake_timer > 0:
            self.shake_timer -= dt
            lo, hi = C.SHAKE_MAGNITUDE
            self.shake_offset = (random.choice((-1, 1)) * random.randint(lo, hi),
                                 random.choice((-1, 1)) * random.randint(lo, hi))
        else:
            self.shake_offset = (0, 0)

    def apply_shake(self, surface):
        """Desplaza lo ya dibujado (mundo); el HUD se dibuja después y no tiembla."""
        if self.shake_offset != (0, 0):
            snapshot = surface.copy()
            surface.fill(C.BG_COLOR)
            surface.blit(snapshot, self.shake_offset)

    def _clamp(self, off, map_size):
        return Vector2(max(0, min(map_size[0] - self.view.x, off.x)), max(0, min(map_size[1] - self.view.y, off.y)))

    def update(self, target_pos, map_size, dt=None):
        """Sigue al objetivo. Con `dt` y tras una pausa táctica regresa suavemente (sin saltos); si no, lo encuadra."""
        want = self._clamp(Vector2(target_pos) - self.view / 2, map_size)
        if self.returning and dt is not None:
            delta = want - self.offset
            if delta.length() < 3:
                self.offset, self.returning = want, False
            else:
                self.offset += delta * min(1.0, dt * 7.0)
        else:
            self.offset, self.returning = want, False

    # --- cámara táctica (pausa): desacoplada del Operador ---
    EDGE_MARGIN = 14                      # px del borde de la ventana que desplazan la cámara

    def tactical_update(self, dt, keys, mouse_pos, map_size):
        """WASD / flechas y el cursor en el borde de la pantalla desplazan la cámara (pausa táctica y Base Central)."""
        pan = Vector2(keys[pygame.K_d] - keys[pygame.K_a] + keys[pygame.K_RIGHT] - keys[pygame.K_LEFT],
                      keys[pygame.K_s] - keys[pygame.K_w] + keys[pygame.K_DOWN] - keys[pygame.K_UP])
        mx, my = mouse_pos
        if mx <= self.EDGE_MARGIN:
            pan.x -= 1
        elif mx >= self.view.x - self.EDGE_MARGIN - 1:
            pan.x += 1
        if my <= self.EDGE_MARGIN:
            pan.y -= 1
        elif my >= self.view.y - self.EDGE_MARGIN - 1:
            pan.y += 1
        self.returning = False
        if pan.length_squared() > 0:
            self.offset = self._clamp(self.offset + pan.normalize() * C.CAMERA_PAN_SPEED * dt, map_size)

    def drag(self, rel, map_size):
        """Clic central arrastrado: mueve el mapa con el cursor."""
        self.returning = False
        self.offset = self._clamp(self.offset - Vector2(rel), map_size)

    def apply(self, rect):
        return rect.move(-round(self.offset.x), -round(self.offset.y))

    def to_world(self, screen_pos):
        return Vector2(screen_pos) + self.offset

    def to_screen(self, world_pos):
        return Vector2(world_pos) - self.offset

    def draw_group(self, surface, *groups):
        view = surface.get_rect().inflate(160, 160)
        sprites = [s for g in groups for s in g]
        visible = [s for s in sorted(sprites, key=lambda s: getattr(s, "layer", 1)) if view.colliderect(self.apply(s.rect))]
        for spr in visible:                                          # sombras de contacto: todas debajo de todos los sprites
            if getattr(spr, "casts_shadow", False):
                terrain.draw_contact_shadow(surface, self.apply(spr.rect), getattr(spr, "shadow_lift", 0))
        for spr in visible:
            spr.draw(surface, self.offset)


class GameMap:
    """Mapa del Acto 2: terreno abierto con la base a la izquierda y la Fundición Renegada a la derecha."""

    def __init__(self, width, height, seed=None):
        self.size = (width, height)
        self.rect = pygame.Rect(0, 0, width, height)
        self.rng = random.Random(seed)
        self.background = pygame.Surface(self.size)
        self.cc_pos = Vector2(width / 2, height / 2)
        self.foundry_pos = None

    @classmethod
    def arena(cls, width, height, cc_pos=None, foundry_pos=None, seed=None):
        m = cls(width, height, seed)
        m.cc_pos = Vector2(cc_pos) if cc_pos is not None else Vector2(width / 2, height / 2)
        m.foundry_pos = Vector2(foundry_pos) if foundry_pos is not None else None
        m._render_arena()
        return m

    def _grid(self, surf, step, color):
        w, h = surf.get_size()
        for x in range(0, w, step):
            pygame.draw.line(surf, color, (x, 0), (x, h))
        for y in range(0, h, step):
            pygame.draw.line(surf, color, (0, y), (w, y))

    def _render_arena(self):
        bg = self.background
        bg.fill(C.BG_COLOR)
        terrain.paint_floor(bg, (18, 21, 31), random.Random(7), ruined=True)   # baldosas agrietadas, grasa y hollín (como el Acto 1)
        cx, cy = round(self.cc_pos.x), round(self.cc_pos.y)
        for r in (110, 220, 330):
            pygame.draw.circle(bg, (24, 38, 56), (cx, cy), r, 1)
        zone = pygame.Rect(cx - 140, cy - 140, 280, 280)
        terrain.paint_hazard_frame(bg, zone, random.Random(11))        # zona del Núcleo
        terrain.paint_bunker_surround(bg, zone, (cx, cy), random.Random(13))   # rejillas, cables, placas y triángulos de alerta
        keep = [zone.inflate(160, 160)]                                # los cascotes no invaden la base ni la Fundición
        if self.foundry_pos is not None:
            keep.append(pygame.Rect(0, 0, 760, 760).move(round(self.foundry_pos.x) - 380, round(self.foundry_pos.y) - 380))
        terrain.paint_debris_field(bg, (18, 21, 31), random.Random(17), keep)
        cell = 40                                                      # óxido, cables rotos y escombros transitables por todo el mapa
        wall = [[False] * (self.size[0] // cell + 1) for _ in range(self.size[1] // cell + 1)]
        avoid = {(x // cell, y // cell) for r in keep for x in range(r.left, r.right, cell) for y in range(r.top, r.bottom, cell)}
        terrain.paint_floor_decor(bg, wall, cell, random.Random(19), (18, 21, 31), avoid)
        if self.foundry_pos is not None:          # terreno de la Fundición Renegada
            fx, fy = round(self.foundry_pos.x), round(self.foundry_pos.y)
            zone = pygame.Surface((760, 760), pygame.SRCALPHA)
            pygame.draw.circle(zone, (255, 50, 50, 22), (380, 380), 380)
            bg.blit(zone, (fx - 380, fy - 380))
            for r in (190, 270, 350):
                pygame.draw.circle(bg, (56, 16, 26), (fx, fy), r, 1)
            font = pygame.font.SysFont("consolas", 22, bold=True)
            bg.blit(font.render("FUNDICIÓN RENEGADA", True, (150, 40, 55)), (fx - 120, fy + 380 - 30))
        pygame.draw.rect(bg, (90, 15, 30), bg.get_rect(), 4)
        font = pygame.font.SysFont("consolas", 22, bold=True)
        bg.blit(font.render("BASE · CENTRO DE CONTROL", True, (0, 120, 100)), (cx - 130, cy + 340))

    def draw_background(self, surface, camera):
        surface.blit(self.background, (0, 0),
                     pygame.Rect(round(camera.offset.x), round(camera.offset.y),
                                 surface.get_width(), surface.get_height()))
