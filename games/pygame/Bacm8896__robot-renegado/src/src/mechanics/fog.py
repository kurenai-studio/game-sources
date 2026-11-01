"""Niebla de guerra por celdas: lo explorado queda tenue y solo se ve con nitidez lo cercano al Operador."""
import math

import pygame
from pygame.math import Vector2


class FogOfWar:
    HIDDEN_ALPHA = 238          # sin explorar
    MEMORY_ALPHA = 150          # explorado pero fuera de la vista actual
    MINI_FLOOR = (22, 30, 50)   # minimapa: suelo explorado (tenue)
    MINI_WALL = (54, 64, 90)    # minimapa: pared explorada (tenue); lo no visitado queda en negro estricto

    def __init__(self, cols, rows, cell, radius, walls=None):
        """`walls`: celdas (col, fila) de muro. Si se dan, bloquean la visión: no se ve ni se explora a través de ellas."""
        self.cols, self.rows, self.cell, self.radius = cols, rows, cell, radius
        self.walls = walls
        self.explored = bytearray(cols * rows)
        self.version = 0                      # cambia cada vez que se explora alguna celda nueva
        self.center = Vector2(-10 ** 6, -10 ** 6)
        r = math.ceil(radius / cell)
        self._offsets = [(dx, dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1) if dx * dx + dy * dy <= r * r]
        self._visible = set()                 # índices de las celdas que el Operador ve ahora mismo
        self._small = None
        self._cell = (None, None)             # celda del Operador en el último marcado
        self._cache = (None, None)            # (clave, superficie de niebla ya escalada)
        self._mini = None                     # minimapa: 1 px por celda
        self._mini_done = bytearray(cols * rows)
        self._mini_version = -1
        self._mini_scaled = (None, None)      # ((versión, tamaño), superficie escalada)

    def _sees(self, c0, r0, c1, r1):
        """¿Hay línea de visión entre dos celdas? Los muros intermedios la cortan (el muro de destino sí se ve)."""
        if self.walls is None:
            return True
        dx, dy = abs(c1 - c0), abs(r1 - r0)
        sx, sy = (1 if c1 > c0 else -1), (1 if r1 > r0 else -1)
        err, x, y = dx - dy, c0, r0
        while (x, y) != (c1, r1):
            if (x, y) != (c0, r0) and (x, y) in self.walls:
                return False
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x += sx
            if e2 < dx:
                err += dx
                y += sy
        return True

    def update(self, pos):
        """Marca como explorado lo que el Operador ve (círculo de visión sin atravesar muros), solo al cambiar de celda."""
        self.center = Vector2(pos)
        cx, cy = int(pos.x // self.cell), int(pos.y // self.cell)
        if (cx, cy) == self._cell:
            return
        self._cell = (cx, cy)
        visible, new = set(), 0
        for dx, dy in self._offsets:
            x, y = cx + dx, cy + dy
            if 0 <= x < self.cols and 0 <= y < self.rows and self._sees(cx, cy, x, y):
                i = y * self.cols + x
                visible.add(i)
                if not self.explored[i]:
                    self.explored[i] = 1
                    new += 1
        self._visible = visible
        if new:
            self.version += 1

    def is_visible(self, pos):
        """¿Ve el Operador este punto? Dentro del radio y, si hay muros, sin ninguno de por medio."""
        if self.center.distance_to(pos) > self.radius:
            return False
        if self.walls is None:
            return True
        return self._sees(self._cell[0], self._cell[1], int(pos.x // self.cell), int(pos.y // self.cell))

    def is_explored(self, pos):
        x, y = int(pos.x // self.cell), int(pos.y // self.cell)
        return 0 <= x < self.cols and 0 <= y < self.rows and bool(self.explored[y * self.cols + x])

    def explored_count(self):
        return sum(self.explored)

    def minimap(self, size):
        """Capa del minimapa a `size` px: negro estricto en lo no visitado y, en tono tenue, el suelo y las paredes ya
        explorados. Solo se rehace cuando se explora algo nuevo."""
        if self._mini is None:
            self._mini = pygame.Surface((self.cols, self.rows))
            self._mini.fill((0, 0, 0))
        if self._mini_version != self.version:
            walls, cols = self.walls or (), self.cols
            for i, seen in enumerate(self.explored):
                if seen and not self._mini_done[i]:
                    self._mini_done[i] = 1
                    wall = (i % cols, i // cols) in walls
                    self._mini.set_at((i % cols, i // cols), self.MINI_WALL if wall else self.MINI_FLOOR)
            self._mini_version = self.version
        key = (self.version, tuple(size))
        if self._mini_scaled[0] != key:
            self._mini_scaled = (key, pygame.transform.scale(self._mini, size))
        return self._mini_scaled[1]

    def draw(self, surface, camera):
        """Capa de niebla: una superficie pequeña (1 px por celda) escalada a la pantalla."""
        cell = self.cell
        view_cols = int(camera.view.x // cell) + 2
        view_rows = int(camera.view.y // cell) + 2
        c0, r0 = int(camera.offset.x // cell), int(camera.offset.y // cell)
        # La niebla solo cambia al cruzar de celda (o al desplazar la vista una celda): se cachea el resultado
        key = (c0, r0, self._cell)          # lo explorado solo cambia cuando cambia la celda del Operador
        if self._cache[0] != key:
            if self._small is None or self._small.get_size() != (view_cols, view_rows):
                self._small = pygame.Surface((view_cols, view_rows), pygame.SRCALPHA)
            small = self._small
            soft_start = self.radius * 0.72
            cx0, cy0 = (self._cell[0] + 0.5) * cell, (self._cell[1] + 0.5) * cell
            for y in range(view_rows):
                row = (r0 + y) * self.cols
                for x in range(view_cols):
                    cx, cy = c0 + x, r0 + y
                    if not (0 <= cx < self.cols and 0 <= cy < self.rows) or not self.explored[row + cx]:
                        alpha = self.HIDDEN_ALPHA
                    elif row + cx not in self._visible:              # recordado, pero fuera de la vista (p. ej. tras un muro)
                        alpha = self.MEMORY_ALPHA
                    else:
                        dist = math.hypot((cx + 0.5) * cell - cx0, (cy + 0.5) * cell - cy0)
                        if dist <= soft_start:
                            alpha = 0
                        elif dist >= self.radius:
                            alpha = self.MEMORY_ALPHA
                        else:                                        # borde suave de la visión
                            alpha = int(self.MEMORY_ALPHA * (dist - soft_start) / (self.radius - soft_start))
                    small.set_at((x, y), (4, 6, 14, alpha))
            self._cache = (key, pygame.transform.smoothscale(small, (view_cols * cell, view_rows * cell)))
        surface.blit(self._cache[1], (c0 * cell - round(camera.offset.x), r0 * cell - round(camera.offset.y)))


class MapFog:
    """Niebla persistente del Acto 2 (celdas de 40 px): todo empieza negro y lo que revelan el Operador, los Drones
    Exploradores y la propia base queda descubierto para siempre (vista principal y minimapa)."""
    HIDDEN_ALPHA = 225

    def __init__(self, width, height, cell=40):
        self.cell = cell
        self.cols, self.rows = width // cell + 1, height // cell + 1
        self.revealed = bytearray(self.cols * self.rows)
        self.version = 0                         # cambia cada vez que se descubre alguna celda nueva
        self._offsets = {}
        self._small = None
        self._small_version = -1
        self._view_cache = (None, None)

    # --- revelar / consultar ---
    def reveal_fog(self, x, y, radius):
        """Descubre el círculo de `radius` px alrededor de (x, y). Devuelve cuántas celdas nuevas descubrió."""
        r = int(radius // self.cell) + 1
        offs = self._offsets.get(r)
        if offs is None:
            offs = self._offsets[r] = [(dx, dy) for dy in range(-r, r + 1) for dx in range(-r, r + 1)]
        cx, cy = int(x // self.cell), int(y // self.cell)
        new, r2 = 0, radius * radius
        for dx, dy in offs:
            gx, gy = cx + dx, cy + dy
            if 0 <= gx < self.cols and 0 <= gy < self.rows:
                ddx, ddy = (gx + 0.5) * self.cell - x, (gy + 0.5) * self.cell - y
                i = gy * self.cols + gx
                if ddx * ddx + ddy * ddy <= r2 and not self.revealed[i]:
                    self.revealed[i] = 1
                    new += 1
        if new:
            self.version += 1
        return new

    def is_revealed(self, x, y=None):
        if y is None:                            # acepta un Vector2 o (x, y)
            x, y = x[0], x[1]
        gx, gy = int(x // self.cell), int(y // self.cell)
        return 0 <= gx < self.cols and 0 <= gy < self.rows and bool(self.revealed[gy * self.cols + gx])

    def revealed_fraction(self):
        return sum(self.revealed) / len(self.revealed)

    # --- persistencia (viaja con la base entre 2.1 y 2.2 y en los checkpoints) ---
    def dump(self):
        return bytes(self.revealed)

    def load(self, data):
        if data and len(data) == len(self.revealed):
            self.revealed = bytearray(data)
            self.version += 1

    # --- dibujo ---
    def small_surface(self):
        """1 px por celda: transparente lo descubierto, oscuro lo oculto (se rehace solo si cambió algo)."""
        if self._small_version != self.version:
            if self._small is None:
                self._small = pygame.Surface((self.cols, self.rows), pygame.SRCALPHA)
            small = self._small
            small.fill((3, 5, 12, self.HIDDEN_ALPHA))
            for i, v in enumerate(self.revealed):
                if v:
                    small.set_at((i % self.cols, i // self.cols), (0, 0, 0, 0))
            self._small_version = self.version
        return self._small

    def draw(self, surface, camera):
        """Capa de niebla sobre la vista principal (borde suave al escalar)."""
        cell = self.cell
        c0, r0 = int(camera.offset.x // cell), int(camera.offset.y // cell)
        vc, vr = int(camera.view.x // cell) + 2, int(camera.view.y // cell) + 2
        key = (c0, r0, self.version)
        if self._view_cache[0] != key:
            small = self.small_surface()
            area = pygame.Rect(c0, r0, vc, vr).clip(small.get_rect())
            spans = []                                                  # tramos de celdas ocultas por fila (+1 de borde)
            for y in range(r0, r0 + vr):
                row_hidden = [not (0 <= y < self.rows and 0 <= x < self.cols and self.revealed[y * self.cols + x])
                              for x in range(c0, c0 + vc)]
                x = 0
                while x < vc:
                    if row_hidden[x]:
                        start = x
                        while x < vc and row_hidden[x]:
                            x += 1
                        a, b = max(0, start - 1), min(vc, x + 1)
                        spans.append(pygame.Rect(a * cell, (y - r0) * cell, (b - a) * cell, cell))
                    x += 1
            layer = None
            if spans:
                piece = pygame.Surface((vc, vr), pygame.SRCALPHA)
                piece.fill((3, 5, 12, self.HIDDEN_ALPHA))
                piece.blit(small, (area.x - c0, area.y - r0), area, special_flags=pygame.BLEND_RGBA_MIN)   # copia el alfa 0
                layer = pygame.transform.smoothscale(piece, (vc * cell, vr * cell))
            self._view_cache = (key, (layer, spans))
        layer, spans = self._view_cache[1]
        if layer is not None:                    # solo se pintan los tramos con niebla: lo descubierto no cuesta nada
            ox, oy = c0 * cell - round(camera.offset.x), r0 * cell - round(camera.offset.y)
            for span in spans:
                surface.blit(layer, (ox + span.x, oy + span.y), span)

