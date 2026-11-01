"""Navegación reactiva: campo de flujo (Dijkstra) hacia un objetivo (Centro de Control o el jugador).

Las celdas con estructuras del jugador se pueden "atravesar" a un coste alto: si existe un hueco en las
murallas los enemigos lo rodean (embudos / killzones); si la ruta está totalmente bloqueada, atacan el muro.
Los muros de nivel (`hard`) son impenetrables. El campo solo se recalcula cuando algo cambia (una
estructura se construye o destruye, o el objetivo cambia de celda).
"""
import heapq
import math

from pygame.math import Vector2

import config as C

_DIRS = ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1))


class FlowField:
    def __init__(self, width, height, cell=C.BUILD_GRID, wall_cost=C.PATH_WALL_COST, hard=None):
        self.cell = cell
        self.cols, self.rows = width // cell, height // cell
        self.wall_cost = wall_cost
        self.hard = set(hard) if hard else set()      # celdas impenetrables (muros del nivel)
        self.dist = {}
        self.blocked = set()                          # estructuras del jugador + muros del nivel
        self.goal = set()
        self.dirty = True
        self._goal_cell = None

    def mark_dirty(self):
        self.dirty = True

    def retarget(self, goal_sprite):
        """Objetivo móvil (el jugador): solo recalcula al cambiar de celda."""
        cell = self._cell_of(goal_sprite.pos)
        if cell != self._goal_cell:
            self._goal_cell = cell
            self.dirty = True

    def _cells(self, rect):
        c = self.cell
        return [(cx, cy)
                for cx in range(rect.left // c, (rect.right - 1) // c + 1)
                for cy in range(rect.top // c, (rect.bottom - 1) // c + 1)
                if 0 <= cx < self.cols and 0 <= cy < self.rows]

    def _cell_of(self, pos):
        return (max(0, min(self.cols - 1, int(pos.x // self.cell))),
                max(0, min(self.rows - 1, int(pos.y // self.cell))))

    def _diagonal_ok(self, cx, cy, dx, dy):
        return (cx + dx, cy) not in self.blocked and (cx, cy + dy) not in self.blocked

    def update(self, structures, goal_sprite):
        """Recalcula el campo solo si algo cambió."""
        if not self.dirty:
            return
        self.blocked = set(self.hard)
        for s in structures:
            self.blocked.update(self._cells(s.rect))
        self.goal = set(self._cells(goal_sprite.rect))
        dist = {c: 0.0 for c in self.goal}
        heap = [(0.0, c) for c in self.goal]
        heapq.heapify(heap)
        while heap:
            d, (cx, cy) = heapq.heappop(heap)
            if d > dist.get((cx, cy), math.inf):
                continue
            for dx, dy in _DIRS:
                n = (cx + dx, cy + dy)
                if not (0 <= n[0] < self.cols and 0 <= n[1] < self.rows) or n in self.hard:
                    continue
                diagonal = dx != 0 and dy != 0
                if diagonal and not self._diagonal_ok(cx, cy, dx, dy):
                    continue
                step = (self.wall_cost if n in self.blocked and n not in self.goal else 1.0)
                nd = d + step * (1.414 if diagonal else 1.0)
                if nd < dist.get(n, math.inf):
                    dist[n] = nd
                    heapq.heappush(heap, (nd, n))
        self.dist = dist
        self.dirty = False

    def _clear_line(self, pos, direction, length, radius):
        """¿Cabe el enemigo (ancho 2*radius) por la recta hasta el objetivo sin rozar estructuras?"""
        side = Vector2(-direction.y, direction.x)
        t = 0.0
        while t < length:
            for lateral in (-radius, 0.0, radius):
                cell = self._cell_of(pos + direction * t + side * lateral)
                if cell in self.blocked and cell not in self.goal:
                    return False
            t += self.cell * 0.4
        return True

    def has_clear_shot(self, a, b):
        """¿Hay tiro directo entre dos puntos? Solo lo impiden los muros de nivel (`hard`): las estructuras del
        jugador no, porque los disparos las golpean (y eso es lo que se quiere)."""
        if not self.hard:
            return True
        a, b = Vector2(a), Vector2(b)
        length = a.distance_to(b)
        if length < 1:
            return True
        direction = (b - a) / length
        t = 0.0
        while t < length:
            if self._cell_of(a + direction * t) in self.hard:
                return False
            t += self.cell * 0.4
        return True

    def has_line_of_sight(self, a, b, radius=0.0):
        """Línea de visión entre dos puntos del mundo (sin muros ni estructuras por medio)."""
        delta = Vector2(b) - Vector2(a)
        length = delta.length()
        if length < 1:
            return True
        return self._clear_line(Vector2(a), delta / length, length, radius)

    def heading(self, pos, target, radius=0.0):
        """Vector unitario de avance: recta si el camino está libre; si no, sigue el campo de flujo."""
        return self.route(pos, target, radius)[0]

    def _downhill(self, cell):
        """Celda vecina con menor distancia al objetivo (None si ninguna mejora: objetivo o mínimo local)."""
        cx, cy = cell
        best, best_d = None, self.dist.get(cell, math.inf)
        for dx, dy in _DIRS:
            n = (cx + dx, cy + dy)
            if dx != 0 and dy != 0 and not self._diagonal_ok(cx, cy, dx, dy):
                continue
            d = self.dist.get(n, math.inf)
            if d < best_d:
                best, best_d = n, d
        return best

    def route(self, pos, target, radius=0.0, lookahead=4):
        """(rumbo unitario, ¿recta libre?). Con la recta al objetivo libre (línea de visión con el ancho del enemigo) va
        directo; si no, sigue la bajada del campo de flujo y apunta a la celda más lejana de las `lookahead` siguientes
        que se ve sin rozar muros: dobla las esquinas en curva en lugar de ir de centro en centro."""
        pos = Vector2(pos)
        delta = Vector2(target) - pos
        length = delta.length()
        if length < 1:
            return Vector2(), True
        direction = delta / length
        if self._clear_line(pos, direction, length, radius):
            return direction, True
        path, cell = [], self._cell_of(pos)
        for _ in range(max(1, lookahead)):
            cell = self._downhill(cell)
            if cell is None:
                break
            path.append(cell)
        if not path:
            return direction, False
        aim = None
        for c in path:
            center = Vector2((c[0] + 0.5) * self.cell, (c[1] + 0.5) * self.cell)
            v = center - pos
            dist = v.length()
            if dist < 1:
                continue
            if aim is None or self._clear_line(pos, v / dist, dist, radius):
                aim = v / dist
            else:
                break
        return (aim if aim is not None else direction), False
