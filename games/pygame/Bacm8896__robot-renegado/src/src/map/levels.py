"""Mapas de los sub-actos 1.1 a 1.4: cuadrículas de 40 px construidas por código.

Los muros se pintan una sola vez en el fondo; los sprites `Obstacle` solo aportan la colisión.
Los objetos dinámicos (escotilla, tubería rota, baliza...) los añade la escena a partir de los marcadores."""
import random
from collections import deque

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities.obstacle import Obstacle
from src.ui import entity_art, terrain_art as terrain

CELL = C.LEVEL_CELL

STYLES = {
    "urban": dict(kind="urban", floor=(14, 16, 26), grid=(20, 24, 38), wall=(40, 38, 40), edge=(120, 98, 70), accent=C.CYAN),
    "warehouse": dict(kind="warehouse", floor=(20, 18, 20), grid=(30, 26, 28), wall=(46, 40, 36), edge=(150, 96, 44),
                      accent=C.ORANGE),
    "bunker": dict(kind="bunker", floor=(10, 20, 24), grid=(16, 32, 36), wall=(34, 40, 44), edge=(0, 130, 112), accent=C.CYAN),
}


class Level:
    def __init__(self, cols, rows, style):
        self.cols, self.rows, self.style = cols, rows, style
        self.size = (cols * CELL, rows * CELL)
        self.wall = [[True] * cols for _ in range(rows)]
        self.markers = {}
        self.solids = pygame.sprite.Group()
        self.wall_cells = set()
        self.rooms = []                      # salas (pygame.Rect en celdas); vacío en los mapas sin salas
        self.barricades = []                 # barricadas de chatarra (pygame.Rect en celdas), pintadas sobre sus celdas de muro
        self.background = None
        self._mini = None
        self._mini_cache = {}

    # --- construccion ---
    def carve(self, c0, r0, c1, r1):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                self.wall[r][c] = False

    def fill(self, c0, r0, c1, r1):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                self.wall[r][c] = True

    def mark(self, name, c, r, w=1, h=1):
        """Marcador: centro del bloque de w x h celdas que empieza en (c, r)."""
        self.markers.setdefault(name, []).append(Vector2((c + w / 2) * CELL, (r + h / 2) * CELL))

    def marker(self, name, index=0):
        return Vector2(self.markers[name][index])

    def cell_rect(self, c, r, w=1, h=1):
        return pygame.Rect(c * CELL, r * CELL, w * CELL, h * CELL)

    # --- consultas ---
    def reachable(self, start_pos, extra_blocked=()):
        """Celdas de suelo alcanzables desde una posición del mundo (BFS 4-vecinos).
        `extra_blocked`: celdas adicionales infranqueables (p. ej. muros construidos por el jugador)."""
        start = (int(start_pos.x // CELL), int(start_pos.y // CELL))
        seen, queue = {start}, deque([start])
        while queue:
            c, r = queue.popleft()
            for n in ((c + 1, r), (c - 1, r), (c, r + 1), (c, r - 1)):
                if (0 <= n[0] < self.cols and 0 <= n[1] < self.rows and n not in seen
                        and not self.wall[n[1]][n[0]] and n not in extra_blocked):
                    seen.add(n)
                    queue.append(n)
        return seen

    def is_reachable(self, start_pos, target_pos):
        cells = self.reachable(start_pos)
        return (int(target_pos.x // CELL), int(target_pos.y // CELL)) in cells

    def line_clear(self, p, q, radius=18):
        """¿Se puede ir en línea recta de p a q (ancho 2*radius) sin rozar muros?"""
        p, q = Vector2(p), Vector2(q)
        length = p.distance_to(q)
        if length < 1:
            return True
        u = (q - p) / length
        side = Vector2(-u.y, u.x)
        t = 0.0
        while t <= length:
            for lateral in (-radius, 0.0, radius):
                pt = p + u * t + side * lateral
                c, r = int(pt.x // CELL), int(pt.y // CELL)
                if not (0 <= c < self.cols and 0 <= r < self.rows) or self.wall[r][c]:
                    return False
            t += CELL * 0.4
        return True

    def waypoints(self, a, b, radius=18):
        """Ruta de a a b como puntos de paso con tramos rectos libres (camino mínimo por celdas y luego tirando de la
        cuerda). Si no hay camino, va directo al destino."""
        def cell(v):
            return (max(0, min(self.cols - 1, int(v.x // CELL))), max(0, min(self.rows - 1, int(v.y // CELL))))
        a, b = Vector2(a), Vector2(b)
        start, goal = cell(a), cell(b)
        parent, queue = {start: None}, deque([start])
        while queue and goal not in parent:
            c, r = queue.popleft()
            for n in ((c + 1, r), (c - 1, r), (c, r + 1), (c, r - 1)):
                if 0 <= n[0] < self.cols and 0 <= n[1] < self.rows and n not in parent and not self.wall[n[1]][n[0]]:
                    parent[n] = (c, r)
                    queue.append(n)
        if goal not in parent:
            return [b]
        cells = []
        node = goal
        while node is not None:
            cells.append(node)
            node = parent[node]
        pts = [Vector2((c + 0.5) * CELL, (r + 0.5) * CELL) for c, r in reversed(cells)]
        pts[0] = a
        pts[-1] = b
        out, i = [], 0
        while i < len(pts) - 1:
            j = len(pts) - 1
            while j > i + 1 and not self.line_clear(pts[i], pts[j], radius):
                j -= 1
            out.append(pts[j])
            i = j
        return out

    def radar_image(self, size):
        """Mapa táctico escalado para el radar de AURA (con caché)."""
        if size not in self._mini_cache:
            self._mini_cache[size] = pygame.transform.smoothscale(self._mini, size)
        return self._mini_cache[size]

    # --- cierre: fusiona muros, crea colisiones y pinta el fondo ---
    def _wall_rects(self):
        opened, rects = {}, []
        for r in range(self.rows):
            runs, c = set(), 0
            while c < self.cols:
                if self.wall[r][c]:
                    start = c
                    while c < self.cols and self.wall[r][c]:
                        c += 1
                    runs.add((start, c - 1))
                else:
                    c += 1
            for key in list(opened):
                if key not in runs:
                    rects.append((key[0], key[1], opened[key][0], opened[key][1]))
                    del opened[key]
            for key in runs:
                if key in opened:
                    opened[key][1] = r
                else:
                    opened[key] = [r, r]
        rects.extend((k[0], k[1], v[0], v[1]) for k, v in opened.items())
        return rects

    def room_rect(self, pos):
        """Rectángulo en píxeles de la sala que contiene `pos` (o None si está en un pasillo)."""
        for room in self.rooms:
            rect = pygame.Rect(room.x * CELL, room.y * CELL, room.w * CELL, room.h * CELL)
            if rect.collidepoint(pos.x, pos.y):
                return rect
        return None

    def finish(self, seed=1, ruined=False, floor_extra=None):
        """`ruined`: complejo industrial en ruinas (1.1): suelo con baldosas agrietadas y manchadas, cascotes en las
        esquinas y sombra proyectada de 16 px al pie de cada muro. `floor_extra(bg, rng)`: decoración extra del suelo,
        que se pinta antes que los muros para que estos la tapen."""
        rng = random.Random(seed)
        st = STYLES[self.style]
        w, h = self.size
        bg = pygame.Surface((w, h))
        terrain.paint_floor(bg, st["floor"], rng, ruined=ruined)     # placas de acero con bisel, pernos, manchas y desgaste
        if ruined:
            terrain.paint_rubble(bg, self.wall, CELL, rng, st["floor"])
        if floor_extra is not None:
            floor_extra(bg, rng)
        self._mini = pygame.Surface((self.cols * 4, self.rows * 4))
        self._mini.fill((8, 12, 20))
        for c0, c1, r0, r1 in self._wall_rects():
            rect = pygame.Rect(c0 * CELL, r0 * CELL, (c1 - c0 + 1) * CELL, (r1 - r0 + 1) * CELL)
            self.solids.add(Obstacle(rect))
            terrain.paint_block(bg, rect, st, rng)           # bloque industrial de escombros y vigas
            pygame.draw.rect(self._mini, (70, 84, 110), (c0 * 4, r0 * 4, (c1 - c0 + 1) * 4, (r1 - r0 + 1) * 4))
        if ruined:
            terrain.paint_wall_shadows(bg, self.wall, CELL)
        self.wall_cells = {(c, r) for r in range(self.rows) for c in range(self.cols) if self.wall[r][c]}
        self.background = bg
        return self


# =============================================================================
# 1.1 La Frecuencia Fantasma: refugio -> callejones -> plaza del primer contacto -> umbral del Almacén 4
# =============================================================================
def build_level_1_1():
    L = Level(52, 30, "urban")
    L.carve(2, 22, 9, 26)                                   # refugio cerrado
    L.mark("start", 5, 24)
    L.mark("locker", 2, 22, 2, 2)                           # Estación del Exotraje: cabina contra el muro norte
    L.carve(10, 24, 10, 25)                                 # hueco de la escotilla
    L.mark("hatch", 10, 24, 1, 2)
    L.carve(11, 24, 24, 25)                                 # callejón con la tubería rota
    L.mark("barrier", 17, 24, 1, 2)
    L.carve(25, 19, 34, 27)                                 # plaza del primer contacto
    for c, r in [(28, 22), (28, 23), (31, 20), (32, 20), (30, 25), (31, 25), (26, 26)]:
        L.fill(c, r, c, r)                                  # coberturas
    L.mark("scout1", 32, 22)
    L.mark("reinforce", 29, 12)
    L.mark("reinforce", 30, 12)
    L.carve(29, 8, 30, 18)                                  # callejón norte
    L.carve(29, 8, 46, 9)                                   # calle hacia el hangar
    for c, r in [(36, 8), (41, 9)]:
        L.fill(c, r, c, r)                                  # escombros
    L.carve(47, 4, 50, 12)                                  # hangar del Almacén 4
    L.mark("beacon", 46, 8, 1, 2)
    L.finish(seed=11, ruined=True)
    rng = random.Random(1101)
    bay = L.cell_rect(2, 22, 2, 2)                          # franjas de advertencia en el suelo frente a la cabina
    terrain.paint_hazard_strip(L.background, (bay.x, bay.bottom + 4, bay.w, 22), rng)
    chasm = L.cell_rect(17, 24, 1, 2)                       # y en el borde del piso antes de la brecha del Dash
    terrain.paint_hazard_strip(L.background, (chasm.x - 22, chasm.y, 12, chasm.h), rng, width=6)
    terrain.paint_hazard_strip(L.background, (chasm.right + 10, chasm.y, 12, chasm.h), rng, width=6)
    return L


# =============================================================================
# 1.2 Infiltración en el Almacén 4: laberinto de contenedores, patrullas y sala de servidores
# =============================================================================
def build_level_1_2():
    L = Level(52, 30, "warehouse")
    L.carve(2, 24, 7, 27)
    L.mark("start", 4, 26)
    L.carve(8, 25, 30, 26)                                  # pasillo 1
    for c, r in [(14, 25), (20, 26), (26, 25)]:
        L.fill(c, r, c, r)                                  # contenedores en zig-zag (embudos)
    L.carve(30, 21, 35, 27)                                 # cámara A
    L.fill(33, 26, 34, 26)
    L.mark("patrol_a", 33, 22)
    L.mark("patrol_a", 34, 24)
    L.carve(33, 12, 34, 20)                                 # pasillo 2
    L.carve(12, 11, 34, 12)                                 # pasillo 3
    for c, r in [(28, 11), (20, 12), (16, 11)]:
        L.fill(c, r, c, r)
    L.carve(6, 8, 12, 14)                                   # cámara B
    L.mark("patrol_b", 8, 9)
    L.mark("patrol_b", 9, 13)
    L.carve(8, 3, 9, 7)                                     # pasillo 4
    L.carve(8, 3, 27, 4)                                    # pasillo 5
    for c, r in [(14, 3), (20, 4)]:
        L.fill(c, r, c, r)
    L.carve(28, 1, 34, 7)                                   # cámara C
    L.mark("patrol_c", 31, 2)
    L.mark("patrol_c", 33, 6)
    L.carve(35, 3, 37, 4)                                   # entrada a la sala de servidores
    L.carve(38, 1, 49, 10)                                  # sala de servidores
    L.fill(43, 3, 43, 4)
    L.fill(43, 8, 43, 9)                                    # pilares: cobertura; dejan libre la línea de embestida
    L.mark("ram", 45, 6)
    L.mark("aura", 48, 2)
    L.mark("console", 46, 2)
    L.carve(47, 11, 48, 13)                                 # antecámara de la esclusa de salida (bajo la sala)
    L.mark("exit_gate", 47, 11, 2, 1)
    L.finish(seed=12, ruined=True)
    rng = random.Random(1202)
    con = L.marker("console")                               # cables gruesos de la consola hacia el suelo y hacia AURA
    for path, core in zip(entity_art.LINK_CABLES, ((0, 190, 170), (212, 178, 24), (0, 190, 170))):
        terrain.paint_cable(L.background, [(round(con.x + dx), round(con.y + dy)) for dx, dy in path], core)
    gate = L.cell_rect(47, 11, 2, 1)                        # franjas de advertencia ante la esclusa
    terrain.paint_hazard_strip(L.background, (gate.x, gate.y - 26, gate.w, 22), rng)
    return L


# =============================================================================
# 1.3 El Tránsito de la Plaza: plaza con 2 accesos (embudos) y la escotilla del búnker
# =============================================================================
def build_level_1_3():
    L = Level(46, 28, "urban")
    L.carve(14, 8, 31, 20)                                  # plaza
    for c, r in [(18, 12), (19, 12), (26, 16), (27, 16), (20, 17), (25, 11)]:
        L.fill(c, r, c, r)
    L.carve(2, 13, 13, 14)                                  # callejón oeste
    L.carve(32, 13, 43, 14)                                 # callejón este
    L.carve(20, 4, 25, 7)                                   # nicho de la escotilla
    L.mark("hatch", 22, 4, 2, 1)
    L.mark("supply", 22, 9, 2, 2)                           # condensadores de AURA (fuente de energía)
    L.mark("start", 22, 17)
    L.mark("spawn_w", 3, 13, 1, 2)
    L.mark("spawn_e", 42, 13, 1, 2)
    L.mouths = [L.cell_rect(12, 13, 2, 2), L.cell_rect(32, 13, 2, 2)]      # accesos a cerrar
    core = L.marker("supply")

    def base_floor(bg, rng):
        """Como la Base Central: anillos alrededor del Reactor, marco de franjas y suelo de búnker con cables."""
        cx, cy = round(core.x), round(core.y)
        for r in (110, 220, 330):
            pygame.draw.circle(bg, (24, 38, 56), (cx, cy), r, 1)
        zone = pygame.Rect(cx - 100, cy - 100, 200, 200)
        terrain.paint_hazard_frame(bg, zone, random.Random(11))
        terrain.paint_bunker_surround(bg, zone, (cx, cy), random.Random(13))
    L.finish(seed=13, ruined=True, floor_extra=base_floor)  # baldosas agrietadas y sombra de muros, con la zona del Reactor
    hatch = L.cell_rect(22, 4, 2, 1)                        # franjas de peligro en el suelo, frente a la esclusa de superficie
    terrain.paint_hazard_strip(L.background, (hatch.x, hatch.bottom + 4, hatch.w, 22), random.Random(1303))
    return L


# =============================================================================
# Incursión: complejo industrial en ruinas con salas cerradas, pasillos y barricadas de chatarra
# =============================================================================
def _far(p, q, cells):
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 >= cells * cells


# Rejilla de 4 x 3 salas sobre el mapa de 60 x 36 celdas (cada sala deja 2 celdas de muro a cada lado de su región)
_ROOM_X = (2, 16, 30, 44, 58)
_ROOM_Y = (2, 13, 24, 34)


def _room_in(rng, x0, x1, y0, y1):
    w, h = rng.randint(8, x1 - x0 - 4), rng.randint(6, y1 - y0 - 4)
    return pygame.Rect(rng.randint(x0 + 2, x1 - w - 2), rng.randint(y0 + 2, y1 - h - 2), w, h)


def _carve_h(L, y, x0, x1):
    L.carve(min(x0, x1), y, max(x0, x1), y + 1)           # pasillos de 2 celdas de ancho


def _carve_v(L, x, y0, y1):
    L.carve(x, min(y0, y1), x + 1, max(y0, y1))


def _link_rooms(L, a, b, rng, vertical):
    """Pasillo en Z entre dos salas vecinas (a: izquierda o arriba). Devuelve sus tramos rectos (eje, fijo, desde, hasta)."""
    if not vertical:
        mx = rng.randint(a.right, b.x - 2)                 # el tramo central cae en el muro que separa las salas
        _carve_h(L, a.centery, a.centerx, mx + 1)
        _carve_v(L, mx, a.centery, b.centery + 1)
        _carve_h(L, b.centery, mx, b.centerx)
        return [("h", a.centery, a.right, mx + 1), ("h", b.centery, mx, b.x - 1)]
    my = rng.randint(a.bottom, b.y - 2)
    _carve_v(L, a.centerx, a.centery, my + 1)
    _carve_h(L, my, a.centerx, b.centerx + 1)
    _carve_v(L, b.centerx, my, b.centery)
    return [("v", a.centerx, a.bottom, my + 1), ("v", b.centerx, my, b.y - 1)]


def _barricade_corridor(L, spans, rng):
    """Barricada de chatarra en un tramo recto de pasillo (o en la puerta de una sala): ocupa una de sus 2 celdas de ancho
    y deja la otra libre."""
    out = []
    for axis, fixed, p0, p1 in spans:
        lo, hi = sorted((p0, p1))
        if rng.random() > 0.7:
            continue
        mid = (lo + hi) // 2
        for p in sorted(range(lo, hi + 1), key=lambda q: abs(q - mid)):
            side = [(p, fixed + k) if axis == "h" else (fixed + k, p) for k in (-1, 0, 1, 2)]
            if not all(0 <= c < L.cols and 0 <= r < L.rows for c, r in side):
                continue
            # pasillo recto de 2 celdas con muro a ambos lados
            if [L.wall[r][c] for c, r in side] == [True, False, False, True]:
                c, r = side[rng.randint(1, 2)]
                L.fill(c, r, c, r)
                out.append(pygame.Rect(c, r, 1, 1))
                break
    return out


def _room_piles(L, rooms, protected, rng):
    """Montones de chatarra de cobertura dentro de las salas, lejos de los objetivos y de las paredes."""
    out = []
    for room in rooms:
        for _ in range(rng.randint(1, 3)):
            w, h = rng.choice(((1, 1), (2, 1), (1, 2), (2, 2)))
            inner = room.inflate(-4, -4)
            if inner.w < w or inner.h < h:
                continue
            c, r = rng.randint(inner.x, inner.right - w), rng.randint(inner.y, inner.bottom - h)
            if any(abs(c + w / 2 - p[0]) < 3 + w / 2 and abs(r + h / 2 - p[1]) < 3 + h / 2 for p in protected):
                continue
            if any(pile.inflate(2, 2).colliderect(pygame.Rect(c, r, w, h)) for pile in out):
                continue
            L.fill(c, r, c + w - 1, r + h - 1)
            out.append(pygame.Rect(c, r, w, h))
    return out


def _pick_sites(rng, candidates, count):
    """`count` salas de `candidates` bien separadas entre sí (13 celdas; 10 si no hay forma)."""
    for sep in (13, 10):
        for _ in range(300):
            pick = rng.sample(candidates, count)
            centers = [room.center for room in pick]
            if all(_far(a, b, sep) for i, a in enumerate(centers) for b in centers[i + 1:]):
                return pick
    return None


def build_incursion_level(seed=None, level=1, kind="eco"):
    """Mapa exterior generado al azar: 12 salas cerradas unidas por pasillos, con barricadas de chatarra y suelo decorado.
    Garantiza que el inicio, los depósitos, los puntos de plasma y la extracción estén conectados. `kind="tech"`
    (Infiltración Tecnológica): en lugar de depósitos y plasma, una sola cámara fuerte ("vault") en una sala lejana."""
    cols, rows = C.INCURSION_COLS, C.INCURSION_ROWS
    rng = random.Random(seed)
    tech = kind == "tech"
    wanted = 1 if tech else C.INCURSION_DEPOSITS + 1 + (1 if level >= 2 else 0)   # depósitos + alijo de plasma (+ extractor)
    protected = []
    for attempt in range(40):
        L = Level(cols, rows, "urban")
        grid = {(gx, gy): _room_in(rng, _ROOM_X[gx], _ROOM_X[gx + 1], _ROOM_Y[gy], _ROOM_Y[gy + 1])
                for gx in range(4) for gy in range(3)}
        for room in grid.values():
            L.carve(room.x, room.y, room.right - 1, room.bottom - 1)
        L.rooms = list(grid.values())
        # pasillos: un árbol que conecta todo (Kruskal) más algunos bucles para poder rodear y flanquear
        edges = [((gx, gy), (gx + 1, gy), False) for gx in range(3) for gy in range(3)] + \
                [((gx, gy), (gx, gy + 1), True) for gx in range(4) for gy in range(2)]
        rng.shuffle(edges)
        parent = {k: k for k in grid}

        def find(k):
            while parent[k] != k:
                parent[k] = parent[parent[k]]
                k = parent[k]
            return k
        spans = []
        for a, b, vertical in edges:
            joined = find(a) != find(b)
            if joined or rng.random() < 0.3:
                parent[find(a)] = find(b)
                spans += _link_rooms(L, grid[a], grid[b], rng, vertical)
        start_room, extract_room = grid[(0, 2)], grid[(3, 0)]
        candidates = [room for key, room in grid.items()
                      if key not in ((0, 2), (3, 0)) and _far(room.center, start_room.center, 16)
                      and _far(room.center, extract_room.center, 10)]
        if len(candidates) < wanted:
            continue
        sites = _pick_sites(rng, candidates, wanted)
        if sites is None:
            continue
        L.mark("start", *start_room.center)
        L.mark("extract", *extract_room.center)
        names = (["vault"] if tech else ["deposit"] * C.INCURSION_DEPOSITS + ["plasma_cache"]
                 + (["plasma_extractor"] if level >= 2 else []))
        for name, room in zip(names, sites):
            L.mark(name, *room.center)
        protected = [room.center for room in [start_room, extract_room] + sites]
        L.barricades = _barricade_corridor(L, spans, rng)
        if attempt < 39:                                     # coberturas en las salas (la última tentativa sale sin ellas)
            L.barricades += _room_piles(L, list(grid.values()), protected, rng)
        origin = L.marker("start")
        if all(L.is_reachable(origin, L.marker(name, i)) for name in ("extract", "deposit", "plasma_cache", "plasma_extractor", "vault")
               for i in range(len(L.markers.get(name, [])))):
            break
    near = {(c + dc, r + dr) for c, r in protected for dc in range(-2, 3) for dr in range(-2, 3)}
    L.finish(seed=seed if seed is not None else 0, ruined=True,
             floor_extra=lambda bg, r: terrain.paint_floor_decor(bg, L.wall, CELL, r, STYLES["urban"]["floor"], near))
    L.kind = kind
    if tech:                                                 # la cámara fuerte, marcada en el suelo con un marco de peligro
        vault = pygame.Rect(0, 0, 220, 220)
        vault.center = (round(L.marker("vault").x), round(L.marker("vault").y))
        terrain.paint_hazard_frame(L.background, vault, random.Random((seed or 0) + 29), width=10, warn=(200, 64, 64))
    pile_rng = random.Random((seed or 0) + 17)
    for rect in L.barricades:                                # barricadas de chatarra sobre las celdas de muro
        terrain.paint_barricade(L.background, (rect.x * CELL, rect.y * CELL, rect.w * CELL, rect.h * CELL), pile_rng,
                                STYLES["urban"]["floor"])
    return L


# =============================================================================
# 1.4 El Búnker Olvidado: base central subterránea
# =============================================================================
def build_level_1_4():
    L = Level(40, 22, "bunker")
    L.carve(2, 4, 37, 17)
    for c0, r0, c1, r1 in [(10, 4, 10, 8), (10, 13, 10, 17), (28, 4, 28, 8), (28, 13, 28, 17)]:
        L.fill(c0, r0, c1, r1)
    L.mark("start", 4, 10)
    L.mark("terminal", 19, 10)
    L.mark("core", 33, 10, 2, 2)
    for r in (13, 14, 15):
        L.mark("demo_wall", 14, r)
    L.mark("exit", 36, 10)
    L.mark("rescue_n", 20, 5)               # alijo de rescate 1 (zona norte)
    L.mark("rescue_s", 20, 16)              # alijo de rescate 2 (zona sur)
    return L.finish(seed=14)


# =============================================================================
# Paso D · Guerra de Asedio: 3000 x 2000 px, Base a la izquierda y Fortaleza a la derecha con una Tierra de Nadie en medio
# =============================================================================
def build_siege_level(seed=None):
    """Mapa de asedio generado al azar. Tres barreras verticales de escombros densos (120 px de espesor) con 1-2 pasos cada una
    (200-280 px) forman los cuellos de botella; entre ellas hay coberturas y 2-3 nodos de plasma ("plasma_node"). Marcadores:
    player_base, fortress, plasma_node. Garantiza que la Fortaleza y todos los nodos sean alcanzables desde la Base. Atributos
    extra: `passes` (rectángulos de los pasos), `barriers` (rectángulos de las barreras) y `kind` = "siege"."""
    cfg = U.SIEGE
    cols, rows = cfg["map"][0] // CELL, cfg["map"][1] // CELL
    rng = random.Random(seed)
    for attempt in range(30):
        L = Level(cols, rows, "urban")
        L.carve(0, 0, cols - 1, rows - 1)
        mid = rows // 2
        pr, fr = (mid + rng.randint(-cfg["base_dy"], cfg["base_dy"]) for _ in range(2))
        L.mark("player_base", cfg["player_base_x"], pr)
        L.mark("fortress", cfg["fortress_x"], fr)
        barriers, passes = [], []
        for bx in cfg["barrier_x"]:
            c0 = bx // CELL + rng.randint(-cfg["barrier_jitter"], cfg["barrier_jitter"])
            c1 = c0 + cfg["barrier_cells"] - 1
            L.fill(c0, 0, c1, rows - 1)
            gaps = []
            for _ in range(rng.randint(*cfg["gaps_per_barrier"])):
                for _try in range(30):
                    w = rng.randint(*cfg["gap_cells"])
                    r0 = rng.randint(3, rows - w - 3)
                    if all(abs(r0 - g0) > max(w, gw) + 4 for g0, gw in gaps):
                        gaps.append((r0, w))
                        break
            if not gaps:
                gaps.append((mid - 3, 6))
            for r0, w in gaps:
                L.carve(c0, r0, c1, r0 + w - 1)
                passes.append(pygame.Rect(c0 * CELL, r0 * CELL, cfg["barrier_cells"] * CELL, w * CELL))
            barriers.append(pygame.Rect(c0 * CELL, 0, cfg["barrier_cells"] * CELL, rows * CELL))
        # tramos de Tierra de Nadie: de la base a la 1ª barrera, entre barreras y de la última a la fortaleza
        edges = [cfg["player_base_x"] + 6] + [x for b in barriers for x in (b.x // CELL - 2, b.right // CELL + 1)] + [cfg["fortress_x"] - 6]
        lanes = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2)]
        protected = [(cfg["player_base_x"], pr), (cfg["fortress_x"], fr)]
        piles = []
        for _ in range(cfg["cover_piles"]):                        # coberturas: montones de escombros de 1x1 a 2x2
            lo, hi = rng.choice(lanes)
            w, h = rng.choice(((1, 1), (2, 1), (1, 2), (2, 2)))
            c, r = rng.randint(lo, max(lo, hi - w)), rng.randint(3, rows - h - 4)
            if all(abs(c - p[0]) > 7 or abs(r - p[1]) > 7 for p in protected):
                L.fill(c, r, c + w - 1, r + h - 1)
                piles.append(pygame.Rect(c, r, w, h))
        nodes = []                                                 # nodos de plasma disputables, en los tramos centrales
        for k in range(rng.randint(*cfg["plasma_nodes"])):
            lo, hi = lanes[1 + k % (len(lanes) - 1)] if len(lanes) > 1 else lanes[0]
            for _try in range(60):
                c, r = rng.randint(lo, hi), rng.randint(5, rows - 6)
                free = all(not L.wall[rr][cc] for rr in range(r - 2, r + 3) for cc in range(c - 2, c + 3))
                if free and all(abs(c - n[0]) + abs(r - n[1]) > 10 for n in nodes):
                    nodes.append((c, r))
                    L.mark("plasma_node", c, r)
                    break
        origin = L.marker("player_base")
        if (len(nodes) >= cfg["plasma_nodes"][0] and L.is_reachable(origin, L.marker("fortress"))
                and all(L.is_reachable(origin, p) for p in L.markers["plasma_node"])):
            break
    near = {(c + dc, r + dr) for c, r in protected + nodes for dc in range(-3, 4) for dr in range(-3, 4)}

    def decor(bg, r):                                              # terreno decorado persistente (se pinta una sola vez)
        terrain.paint_floor_decor(bg, L.wall, CELL, r, STYLES["urban"]["floor"], near)
        terrain.paint_debris_field(bg, STYLES["urban"]["floor"], r, avoid=[pygame.Rect(0, 0, 480, 2000)], per_area=90000)
        for gap in passes:                                         # escombros densos (transitables) en la boca de cada paso
            for _ in range(gap.h // 24):
                x = gap.centerx + r.choice((-1, 1)) * r.randint(70, 190)
                y = r.randint(gap.y + 12, gap.bottom - 12)
                terrain._rubble_pile(bg, x, y, r, STYLES["urban"]["floor"], r.randint(3, 5), 14)
    L.finish(seed=seed if seed is not None else 0, ruined=True, floor_extra=decor)
    for name, size, warn in (("player_base", 260, (212, 178, 24)), ("fortress", 380, (200, 64, 64))):
        frame = pygame.Rect(0, 0, size, size)
        frame.center = (round(L.marker(name).x), round(L.marker(name).y))
        terrain.paint_hazard_frame(L.background, frame, random.Random((seed or 0) + size), width=12, warn=warn)
    pile_rng = random.Random((seed or 0) + 41)
    for pile in piles:                                             # coberturas de chatarra sobre sus celdas de muro
        terrain.paint_barricade(L.background, (pile.x * CELL, pile.y * CELL, pile.w * CELL, pile.h * CELL), pile_rng,
                                STYLES["urban"]["floor"])
    L.kind = "siege"
    L.passes, L.barriers = passes, barriers
    return L
