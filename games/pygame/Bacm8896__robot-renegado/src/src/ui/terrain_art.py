"""Arte procedural del entorno: baldosas de suelo, manchas, franjas de advertencia, bloques industriales y sombras.

Todo se pinta una sola vez en el fondo del mapa (o se cachea como superficie pequeña), así que el coste por
fotograma es nulo salvo las sombras de contacto, que son blits de superficies cacheadas."""
import math
import random
from functools import lru_cache

import pygame

TILE = 40
_STEEL_HI = (1.55, 1.5, 1.45)          # multiplicadores del bisel claro (arriba/izquierda)
_STEEL_LO = (0.55, 0.55, 0.6)          # y del oscuro (abajo/derecha)


def _mul(color, k):
    return tuple(max(0, min(255, int(c * f))) for c, f in zip(color, k))


def _shift(color, d):
    return tuple(max(0, min(255, c + d)) for c in color)


# ------------------------------------------------------------------ suelo ----
@lru_cache(maxsize=None)
def floor_tile(base, variant):
    """Placa de acero/hormigón oscuro de 40x40: bisel sutil, junta y pernos; 4 variantes con desgaste distinto."""
    rng = random.Random(variant * 7919 + sum(base))
    plate = _shift(base, 6 + variant % 2 * 3)
    img = pygame.Surface((TILE, TILE))
    img.fill(plate)
    for _ in range(26):                                                    # grano: motas de brillo muy leves
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        img.set_at((x, y), _shift(plate, rng.choice((-5, -3, 3, 4))))
    hi, lo = _mul(plate, _STEEL_HI), _mul(plate, _STEEL_LO)
    pygame.draw.line(img, hi, (1, 1), (TILE - 3, 1))                       # bisel superior e izquierdo
    pygame.draw.line(img, hi, (1, 1), (1, TILE - 3))
    pygame.draw.line(img, lo, (2, TILE - 2), (TILE - 2, TILE - 2))         # inferior y derecho
    pygame.draw.line(img, lo, (TILE - 2, 2), (TILE - 2, TILE - 2))
    pygame.draw.rect(img, _mul(base, (0.6, 0.6, 0.65)), img.get_rect(), 1)   # junta entre placas
    bolt, bolt_hi = _mul(plate, (0.5, 0.5, 0.55)), _mul(plate, (1.9, 1.9, 1.9))
    for bx, by in ((5, 5), (TILE - 6, 5), (5, TILE - 6), (TILE - 6, TILE - 6)):   # pernos en las esquinas
        pygame.draw.circle(img, bolt, (bx + 1, by + 1), 2)
        pygame.draw.circle(img, _shift(plate, 12), (bx, by), 2)
        img.set_at((bx - 1, by - 1), bolt_hi)
    if variant == 1:                                                       # rejilla de ventilación
        for y in range(14, 27, 3):
            pygame.draw.line(img, _mul(plate, (0.45, 0.45, 0.5)), (11, y), (28, y))
            pygame.draw.line(img, hi, (11, y + 1), (28, y + 1))
    elif variant == 2:                                                     # arañazos
        for _ in range(3):
            x, y = rng.randint(6, 30), rng.randint(6, 30)
            pygame.draw.line(img, _shift(plate, 11), (x, y), (x + rng.randint(-8, 8), y + rng.randint(-5, 5)))
    elif variant == 3:                                                     # placa de remaches centrales
        for dx in (-6, 0, 6):
            pygame.draw.circle(img, bolt, (TILE // 2 + dx, TILE // 2), 1)
    if variant in (5, 6):                                                  # mancha oscura de aceite / hollín
        _soot_stain(img, rng)
    if variant in (4, 6):                                                  # baldosa agrietada
        _cracks(img, plate, rng)
    return img


def _cracks(img, plate, rng):
    """Grietas de caminante aleatorio desde un borde, con bifurcaciones y un filo claro desplazado un píxel."""
    dark, light = _mul(plate, (0.32, 0.32, 0.36)), _shift(plate, 16)
    for branch in range(rng.choice((2, 3))):
        side = rng.randrange(4)
        t = rng.randint(6, TILE - 7)
        x, y = {0: (t, 1), 1: (TILE - 2, t), 2: (t, TILE - 2), 3: (1, t)}[side]
        heading = {0: 90, 1: 180, 2: 270, 3: 0}[side] + rng.randint(-35, 35)
        pts = [(x, y)]
        for _ in range(rng.randint(4, 7)):
            heading += rng.randint(-40, 40)
            step = rng.randint(4, 8)
            x += math.cos(math.radians(heading)) * step
            y += math.sin(math.radians(heading)) * step
            pts.append((max(1, min(TILE - 2, x)), max(1, min(TILE - 2, y))))
        pygame.draw.lines(img, light, False, [(px + 1, py + 1) for px, py in pts], 1)
        pygame.draw.lines(img, dark, False, pts, 1)
        if branch == 0 and len(pts) > 3:                                   # la grieta principal se bifurca
            bx, by = pts[2]
            h2 = heading + rng.choice((-70, 70))
            pygame.draw.line(img, dark, (bx, by), (bx + math.cos(math.radians(h2)) * 8, by + math.sin(math.radians(h2)) * 8))


def _soot_stain(img, rng):
    """Mancha irregular de aceite o hollín: elipses translúcidas superpuestas y un reflejo azulado en las de aceite."""
    stain = pygame.Surface((TILE, TILE), pygame.SRCALPHA)
    cx, cy = rng.randint(12, TILE - 12), rng.randint(12, TILE - 12)
    for k in range(5):
        rx, ry = rng.randint(7, 15) * (1 - k * 0.15), rng.randint(5, 11) * (1 - k * 0.15)
        pygame.draw.ellipse(stain, (0, 0, 0, 56), (cx - rx + rng.randint(-3, 3), cy - ry + rng.randint(-3, 3), rx * 2, ry * 2))
    if rng.random() < 0.5:
        pygame.draw.ellipse(stain, (30, 80, 110, 26), (cx - 5, cy - 3, 10, 6))
    img.blit(stain, (0, 0))


def paint_floor(bg, base, rng, density=1.0, ruined=False):
    """Cubre `bg` con placas, manchas de aceite/desgaste y arañazos. `base`: color del suelo del estilo.
    `ruined`: complejo industrial en ruinas: alterna placas lisas con agrietadas y manchadas, y suma hollín a gran escala."""
    w, h = bg.get_size()
    base = tuple(base)
    variants = (0, 0, 0, 1, 2, 3, 4, 4, 5, 6) if ruined else (0, 0, 0, 0, 1, 2, 3)
    for y in range(0, h, TILE):
        for x in range(0, w, TILE):
            bg.blit(floor_tile(base, rng.choice(variants)), (x, y))                  # la mayoría de placas son lisas
    if ruined:
        density *= 1.7
    stains = pygame.Surface((w, h), pygame.SRCALPHA)
    for _ in range(int(w * h / 70000 * density)):                          # manchas de aceite y quemaduras
        cx, cy = rng.randrange(w), rng.randrange(h)
        rx, ry = rng.randint(14, 46), rng.randint(9, 28)
        for k in range(4):
            f = 1 - k * 0.22
            pygame.draw.ellipse(stains, (0, 0, 0, 16), (cx - rx * f, cy - ry * f, rx * 2 * f, ry * 2 * f))
        if rng.random() < 0.35:                                            # irisación azulada del aceite
            pygame.draw.ellipse(stains, (20, 60, 90, 14), (cx - rx * 0.4, cy - ry * 0.4, rx * 0.8, ry * 0.8))
    for _ in range(int(w * h / 26000 * density)):                          # líneas de desgaste claras
        x, y = rng.randrange(w), rng.randrange(h)
        pygame.draw.line(stains, (255, 255, 255, 9), (x, y), (x + rng.randint(-26, 26), y + rng.randint(-6, 6)))
    if ruined:                                                             # hollín: manchas grandes y quemaduras
        for _ in range(int(w * h / 90000)):
            cx, cy = rng.randrange(w), rng.randrange(h)
            rx, ry = rng.randint(30, 70), rng.randint(18, 40)
            for k in range(5):
                f = 1 - k * 0.18
                pygame.draw.ellipse(stains, (6, 4, 4, 18), (cx - rx * f, cy - ry * f, rx * 2 * f, ry * 2 * f))
    bg.blit(stains, (0, 0))


def paint_rubble(bg, wall, cell, rng, base):
    """Cascotes de hormigón en las esquinas interiores del suelo (donde se juntan dos muros) y algunos sueltos al pie de
    los muros. `wall[r][c]` = True si la celda es muro."""
    rows, cols = len(wall), len(wall[0])

    def solid(c, r):
        return not (0 <= c < cols and 0 <= r < rows) or wall[r][c]
    for r in range(rows):
        for c in range(cols):
            if wall[r][c]:
                continue
            x0, y0 = c * cell, r * cell
            for sy, sx in ((-1, -1), (-1, 1), (1, -1), (1, 1)):
                if solid(c, r + sy) and solid(c + sx, r):                  # esquina interior: monton de cascotes
                    cx = x0 + (6 if sx < 0 else cell - 6)
                    cy = y0 + (6 if sy < 0 else cell - 6)
                    _rubble_pile(bg, cx, cy, rng, base, rng.randint(4, 7), 15)
            edges = [(dx, dy) for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)) if solid(c + dx, r + dy)]
            if edges and rng.random() < 0.07:                              # algún cascote suelto al pie del muro
                dx, dy = rng.choice(edges)
                cx = x0 + cell // 2 + dx * 15 + rng.randint(-9, 9) * (1 - abs(dx))
                cy = y0 + cell // 2 + dy * 15 + rng.randint(-9, 9) * (1 - abs(dy))
                _rubble_pile(bg, cx, cy, rng, base, rng.randint(1, 3), 7)


def paint_debris_field(bg, base, rng, avoid=(), per_area=150000):
    """Montones de cascotes dispersos en terreno abierto (sin muros que los generen), fuera de las zonas `avoid`.
    Solo decoración: se pintan en el fondo, sin colisión."""
    w, h = bg.get_size()
    avoid = [pygame.Rect(r) for r in avoid]
    for _ in range(w * h // per_area):
        cx, cy = rng.randrange(40, w - 40), rng.randrange(40, h - 40)
        n = rng.randint(2, 5)
        if any(r.collidepoint(cx, cy) for r in avoid):
            continue
        _rubble_pile(bg, cx, cy, rng, base, n, 12)


_SCRAP_TONES = ((128, 66, 32), (104, 52, 28), (92, 94, 104), (70, 72, 80), (150, 112, 40), (60, 56, 58))


def _plate(cx, cy, w, h, angle):
    """Esquinas de una plancha w x h centrada en (cx, cy) y girada `angle` radianes."""
    ca, sa = math.cos(angle), math.sin(angle)
    return [(cx + dx * ca - dy * sa, cy + dx * sa + dy * ca)
            for dx, dy in ((-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2))]


def paint_barricade(bg, rect, rng, base):
    """Barricada de chatarra: planchas oxidadas, vigas y chapa de advertencia amontonadas sobre `rect` (celdas de muro: la
    colisión ya la pone el bloque de debajo). Se pinta una sola vez en el fondo."""
    rect = pygame.Rect(rect)
    bg.set_clip(rect)
    pygame.draw.rect(bg, _mul(base, (0.4, 0.4, 0.45)), rect)
    for _ in range(max(7, rect.w * rect.h // 150)):
        cx, cy = rng.randint(rect.x + 3, rect.right - 3), rng.randint(rect.y + 3, rect.bottom - 3)
        pts = _plate(cx, cy, rng.randint(14, 32), rng.randint(5, 11), rng.uniform(0, math.pi))
        tone = rng.choice(_SCRAP_TONES)
        pygame.draw.polygon(bg, _mul(tone, (0.35, 0.35, 0.4)), [(px + 2, py + 3) for px, py in pts])    # sombra de la plancha
        pygame.draw.polygon(bg, tone, pts)
        pygame.draw.lines(bg, _shift(tone, 36), False, pts[:3], 1)                                      # bisel claro arriba/izquierda
        pygame.draw.lines(bg, _shift(tone, -34), False, [pts[2], pts[3], pts[0]], 1)
        if rng.random() < 0.35:
            pygame.draw.circle(bg, _shift(tone, -40), (round(cx), round(cy)), 1)                        # remache
    for _ in range(max(2, rect.w * rect.h // 700)):                                                     # vigas que sobresalen
        x, y = rng.randint(rect.x, rect.right), rng.randint(rect.y, rect.bottom)
        a = rng.uniform(0, math.tau)
        end = (x + math.cos(a) * rng.randint(10, 18), y + math.sin(a) * rng.randint(10, 18))
        pygame.draw.line(bg, (28, 28, 32), (x, y + 2), (end[0], end[1] + 2), 3)
        pygame.draw.line(bg, (96, 98, 108), (x, y), end, 2)
    bg.set_clip(None)
    pygame.draw.rect(bg, _mul(base, (0.3, 0.3, 0.35)), rect, 1)


def paint_broken_cable(bg, x, y, rng):
    """Cable roto en el suelo: dos tramos con un hueco en medio y los hilos de cobre deshilachados en los extremos."""
    heading = rng.uniform(0, math.tau)
    pts = [(x, y)]
    for _ in range(3):
        heading += rng.uniform(-0.8, 0.8)
        step = rng.randint(14, 26)
        pts.append((pts[-1][0] + math.cos(heading) * step, pts[-1][1] + math.sin(heading) * step))
    core = rng.choice(((190, 90, 40), (60, 70, 96), (190, 160, 34), (150, 44, 44)))
    for seg in (pts[:2], pts[2:]):
        pygame.draw.lines(bg, (6, 6, 9), False, [(px, py + 2) for px, py in seg], 6)
        pygame.draw.lines(bg, (16, 16, 20), False, seg, 5)
        pygame.draw.lines(bg, core, False, seg, 2)
    for end, away in ((pts[1], pts[0]), (pts[2], pts[3])):                                              # hilos sueltos
        base_a = math.atan2(end[1] - away[1], end[0] - away[0])
        for _ in range(3):
            a = base_a + rng.uniform(-0.7, 0.7)
            pygame.draw.line(bg, (200, 120, 56), end, (end[0] + math.cos(a) * 7, end[1] + math.sin(a) * 7), 1)


def paint_floor_decor(bg, wall, cell, rng, base, avoid=()):
    """Decoración transitable del suelo (sin colisión): manchas de óxido con regueros, cables rotos y escombros sueltos.
    Solo en celdas de suelo y fuera de las celdas `avoid` (alrededor de los objetivos, para que se lean bien)."""
    rows, cols = len(wall), len(wall[0])
    avoid = set(avoid)
    rust = pygame.Surface(bg.get_size(), pygame.SRCALPHA)
    cables, debris = [], []
    for r in range(rows):
        for c in range(cols):
            if wall[r][c] or (c, r) in avoid:
                continue
            x, y = c * cell + rng.randint(8, cell - 8), r * cell + rng.randint(8, cell - 8)
            roll = rng.random()
            if roll < 0.08:                                                    # mancha de óxido
                rx, ry = rng.randint(10, 22), rng.randint(7, 14)
                for k in range(3):
                    f = 1 - k * 0.28
                    pygame.draw.ellipse(rust, (136, 66, 26, 44 + k * 14), (x - rx * f, y - ry * f, rx * 2 * f, ry * 2 * f))
                for _ in range(rng.randint(1, 3)):                              # regueros
                    sx = x + rng.randint(-rx // 2, rx // 2)
                    pygame.draw.line(rust, (110, 52, 22, 60), (sx, y), (sx + rng.randint(-2, 2), y + rng.randint(8, 18)), 1)
            elif roll < 0.11:
                cables.append((x, y))
            elif roll < 0.17:
                debris.append((x, y))
    bg.blit(rust, (0, 0))
    for x, y in cables:
        paint_broken_cable(bg, x, y, rng)
    for x, y in debris:
        _rubble_pile(bg, x, y, rng, base, rng.randint(2, 4), 9)


def _rubble_pile(bg, cx, cy, rng, base, count, spread):
    for _ in range(count):
        x, y = cx + rng.randint(-spread, spread), cy + rng.randint(-spread, spread)
        size = rng.randint(4, 10)
        pts = [(x + math.cos(a) * size * rng.uniform(0.6, 1.1), y + math.sin(a) * size * rng.uniform(0.5, 0.9))
               for a in sorted(rng.uniform(0, math.tau) for _ in range(rng.randint(5, 6)))]
        tone = _shift(base, rng.randint(62, 98))
        pygame.draw.polygon(bg, _mul(base, (0.45, 0.45, 0.5)), [(px + 1, py + 2) for px, py in pts])    # sombra del cascote
        pygame.draw.polygon(bg, tone, pts)
        pygame.draw.lines(bg, _shift(tone, 26), False, pts[:3], 1)          # cara superior iluminada
        pygame.draw.lines(bg, _shift(tone, -34), False, pts[3:], 1)


@lru_cache(maxsize=None)
def _wall_shadow_strip(width, depth, strength):
    """Franja vertical de sombra proyectada: opaca junto al muro y desvaneciéndose hacia el suelo."""
    img = pygame.Surface((width, depth), pygame.SRCALPHA)
    for i in range(depth):
        k = (1 - i / depth) ** 1.7
        img.fill((0, 0, 0, int(strength * k)), (0, i, width, 1))
    return img


def paint_wall_shadows(bg, wall, cell, depth=16, strength=215):
    """Sombra proyectada (~16 px) sobre el suelo, en la base de cada muro que tiene suelo justo debajo: separa la pared del
    pasillo y le da volumen."""
    rows, cols = len(wall), len(wall[0])
    strip = _wall_shadow_strip(cell, depth, strength)
    for r in range(rows - 1):
        for c in range(cols):
            if wall[r][c] and not wall[r + 1][c]:
                bg.blit(strip, (c * cell, (r + 1) * cell))


def paint_cable(bg, points, core=(0, 190, 170)):
    """Cable grueso por el suelo: funda oscura, núcleo de color y un filo de brillo."""
    pygame.draw.lines(bg, (6, 6, 9), False, [(x, y + 2) for x, y in points], 8)
    pygame.draw.lines(bg, (16, 16, 20), False, points, 7)
    pygame.draw.lines(bg, core, False, points, 3)
    pygame.draw.lines(bg, tuple(min(255, c + 90) for c in core), False, points, 1)
    for x, y in (points[0], points[-1]):
        pygame.draw.circle(bg, (60, 64, 78), (x, y), 5)
        pygame.draw.circle(bg, (14, 14, 18), (x, y), 5, 1)


def paint_hazard_strip(bg, rect, rng, width=9, warn=(196, 164, 26)):
    """Franjas diagonales amarillas y negras desgastadas (pintura saltada y arañazos) sobre el suelo."""
    rect = pygame.Rect(rect)
    layer = pygame.Surface(rect.size, pygame.SRCALPHA)
    layer.fill((14, 14, 16, 255))
    span = max(rect.w, rect.h)
    for x in range(-span, span * 2, 2 * width):
        pygame.draw.polygon(layer, (*warn, 255), [(x, rect.h), (x + width, rect.h), (x + width + rect.h, 0), (x + rect.h, 0)])
    wear = pygame.Surface(rect.size, pygame.SRCALPHA)
    for _ in range(rect.w * rect.h // 9):                                  # pintura desconchada
        wear.set_at((rng.randrange(rect.w), rng.randrange(rect.h)), (0, 0, 0, rng.randint(70, 210)))
    for _ in range(max(4, rect.w * rect.h // 300)):                        # rozaduras y mugre
        x, y = rng.randrange(rect.w), rng.randrange(rect.h)
        pygame.draw.line(wear, (0, 0, 0, 120), (x, y), (x + rng.randint(-10, 10), y + rng.randint(-4, 4)), 2)
    layer.blit(wear, (0, 0), special_flags=pygame.BLEND_RGBA_SUB)
    layer.set_alpha(None)
    grime = pygame.Surface(rect.size, pygame.SRCALPHA)
    grime.fill((0, 0, 0, 40))
    layer.blit(grime, (0, 0))
    bg.blit(layer, rect)
    pygame.draw.rect(bg, (10, 10, 12), rect, 1)


def paint_hazard_frame(bg, rect, rng, width=12, warn=(212, 178, 24)):
    """Marco de franjas amarillas y negras desgastadas (zona del Núcleo)."""
    rect = pygame.Rect(rect)
    layer = pygame.Surface(rect.size, pygame.SRCALPHA)
    for x in range(-rect.h, rect.w + rect.h, 2 * width):
        pygame.draw.polygon(layer, (*warn, 255), [(x, rect.h), (x + width, rect.h), (x + width + rect.h, 0), (x + rect.h, 0)])
    mask = pygame.Surface(rect.size, pygame.SRCALPHA)
    mask.fill((0, 0, 0, 0))
    pygame.draw.rect(mask, (255, 255, 255, 255), mask.get_rect(), width)
    black = pygame.Surface(rect.size, pygame.SRCALPHA)
    black.fill((12, 12, 14, 255))
    black.blit(layer, (0, 0))
    black.blit(mask, (0, 0), special_flags=pygame.BLEND_RGBA_MULT)          # solo el marco
    wear = pygame.Surface(rect.size, pygame.SRCALPHA)
    for _ in range(rect.w * rect.h // 160):                                # pintura desconchada: huecos al azar
        wear.set_at((rng.randrange(rect.w), rng.randrange(rect.h)), (0, 0, 0, rng.randint(80, 200)))
    for _ in range(18):
        x, y = rng.randrange(rect.w), rng.randrange(rect.h)
        pygame.draw.line(wear, (0, 0, 0, 150), (x, y), (x + rng.randint(-14, 14), y + rng.randint(-4, 4)), 2)
    black.blit(wear, (0, 0), special_flags=pygame.BLEND_RGBA_SUB)
    bg.blit(black, rect)
    pygame.draw.rect(bg, (10, 10, 12), rect, 1)
    pygame.draw.rect(bg, (10, 10, 12), rect.inflate(-2 * width, -2 * width), 1)


# ------------------------------------------------------ interior del búnker ----
def paint_bunker_surround(bg, frame, core_pos, rng):
    """Suelo interior del búnker alrededor del marco de advertencia: placas soldadas superpuestas, rejillas de
    ventilación cruzadas, cables conductores cian/amarillos hacia el Centro de Control y triángulos de alerta."""
    frame = pygame.Rect(frame)
    band = frame.inflate(120, 120)
    for _ in range(14):                                                    # placas soldadas superpuestas
        pw, ph = rng.randint(40, 84), rng.randint(26, 52)
        side = rng.randrange(4)
        x = rng.randint(band.left, band.right - pw)
        y = rng.randint(band.top, band.top + 48) if side == 0 else rng.randint(band.bottom - 48 - ph, band.bottom - ph) \
            if side == 1 else rng.randint(band.top, band.bottom - ph)
        if side == 2:
            x = rng.randint(band.left, band.left + 40)
        elif side == 3:
            x = rng.randint(band.right - 40 - pw, band.right - pw)
        r = pygame.Rect(x, y, pw, ph)
        if r.colliderect(frame):
            continue
        pygame.draw.rect(bg, (34, 38, 48), r)
        pygame.draw.rect(bg, (56, 62, 76), r, 1)
        pygame.draw.line(bg, (74, 82, 98), r.topleft, (r.right - 1, r.top))
        for wx in range(r.left + 4, r.right - 3, 5):                       # cordón de soldadura en el borde
            pygame.draw.line(bg, (96, 104, 120), (wx, r.bottom - 3), (wx + 2, r.bottom - 3))
    spots = [(frame.left - 70, frame.centery - 60), (frame.right + 22, frame.centery + 20),
             (frame.centerx - 80, frame.top - 62), (frame.centerx + 30, frame.bottom + 24),
             (frame.left - 66, frame.top - 40), (frame.right + 18, frame.bottom + 8)]
    for sx, sy in spots:                                                   # rejillas de ventilación cruzadas
        g = pygame.Rect(sx, sy, 48, 32)
        pygame.draw.rect(bg, (16, 18, 24), g)
        for gx in range(g.left + 3, g.right - 2, 5):
            pygame.draw.line(bg, (120, 128, 144), (gx, g.top + 2), (gx, g.bottom - 3))
        for gy in range(g.top + 3, g.bottom - 2, 5):
            pygame.draw.line(bg, (90, 98, 114), (g.left + 2, gy), (g.right - 3, gy))
        pygame.draw.rect(bg, (140, 148, 164), g, 2)
    cx, cy = core_pos
    for k, (ex, ey) in enumerate(((frame.left - 130, cy - 30), (frame.right + 130, cy + 40), (cx - 40, frame.top - 130),
                                  (cx + 50, frame.bottom + 130))):          # cables conductores hacia el Centro de Control
        pts = [(ex, ey), ((ex + cx) // 2, ey), ((ex + cx) // 2, cy + (14 if k % 2 else -14)), (cx, cy + (14 if k % 2 else -14))] \
            if k < 2 else [(ex, ey), (ex, (ey + cy) // 2), (cx + (14 if k % 2 else -14), (ey + cy) // 2), (cx + (14 if k % 2 else -14), cy)]
        pygame.draw.lines(bg, (8, 10, 14), False, pts, 6)
        pygame.draw.lines(bg, (0, 190, 170) if k % 2 == 0 else (212, 178, 24), False, pts, 3)
        pygame.draw.lines(bg, (150, 255, 240) if k % 2 == 0 else (255, 236, 130), False, pts, 1)
    tri = 24
    for sx, sy, flip in ((frame.left - 34, frame.top - 34, 1), (frame.right + 10, frame.top - 34, 1),
                         (frame.left - 34, frame.bottom + 10, -1), (frame.right + 10, frame.bottom + 10, -1)):
        pts = [(sx, sy + tri), (sx + tri, sy + tri), (sx + tri // 2, sy)] if flip == 1 else \
            [(sx, sy), (sx + tri, sy), (sx + tri // 2, sy + tri)]
        pygame.draw.polygon(bg, (212, 178, 24), pts)
        pygame.draw.polygon(bg, (12, 12, 14), pts, 3)
        ty = sy + (tri * 0.62 if flip == 1 else tri * 0.30)
        pygame.draw.line(bg, (12, 12, 14), (sx + tri // 2, ty - 6), (sx + tri // 2, ty + 1), 2)
        pygame.draw.circle(bg, (12, 12, 14), (sx + tri // 2, round(ty + 5)), 1)


# ----------------------------------------------------- bloques industriales ----
def paint_block(bg, rect, st, rng):
    """Obstáculo intransitable: bloque de escombros y vigas, con luz desde arriba (borde superior claro) y sombra proyectada."""
    rect = pygame.Rect(rect)
    base, edge = st["wall"], st["edge"]
    shadow = pygame.Surface((rect.w + 8, rect.h + 8), pygame.SRCALPHA)       # sombra proyectada sobre el suelo
    shadow.fill((0, 0, 0, 0))
    pygame.draw.rect(shadow, (0, 0, 0, 90), (4, 6, rect.w, rect.h))
    bg.blit(shadow, (rect.x, rect.y))
    dark = _mul(base, (0.8, 0.8, 0.85))
    pygame.draw.rect(bg, dark, rect)
    for _ in range(max(6, rect.w * rect.h // 420)):                          # losas y cascotes de distinto tono
        cw, ch = rng.randint(5, 16), rng.randint(4, 11)
        cx, cy = rng.randint(rect.left, max(rect.left, rect.right - cw)), rng.randint(rect.top, max(rect.top, rect.bottom - ch))
        tone = _shift(base, rng.randint(-10, 14))
        chunk = pygame.Rect(cx, cy, cw, ch).clip(rect)
        pygame.draw.rect(bg, tone, chunk)
        pygame.draw.line(bg, _shift(tone, 16), chunk.topleft, (chunk.right - 1, chunk.top))   # cara superior iluminada
        pygame.draw.line(bg, _shift(tone, -16), (chunk.left, chunk.bottom - 1), (chunk.right - 1, chunk.bottom - 1))
    beam = _mul(base, (1.7, 1.7, 1.75))
    beam_dark = _mul(base, (0.55, 0.55, 0.6))
    for y in range(rect.top + 14, rect.bottom - 6, 42):                       # vigas horizontales en I con remaches
        pygame.draw.rect(bg, beam_dark, (rect.left + 2, y, rect.w - 4, 8))
        pygame.draw.rect(bg, beam, (rect.left + 2, y, rect.w - 4, 3))
        pygame.draw.rect(bg, _mul(base, (1.0, 1.0, 1.05)), (rect.left + 2, y + 3, rect.w - 4, 2))
        for x in range(rect.left + 8, rect.right - 6, 18):
            pygame.draw.circle(bg, beam, (x, y + 6), 1)
    for x in range(rect.left + 5, rect.right - 6, 80):                        # pilares verticales
        pygame.draw.rect(bg, beam_dark, (x, rect.top + 2, 6, rect.h - 4))
        pygame.draw.line(bg, beam, (x, rect.top + 2), (x, rect.bottom - 4))
    _style_details(bg, rect, st, rng)
    top = pygame.Surface((rect.w, 7), pygame.SRCALPHA)                       # sombreado superior: luz cenital
    for i in range(7):
        top.fill((255, 255, 255, 46 - i * 6), (0, i, rect.w, 1))
    bg.blit(top, rect.topleft)
    bottom = pygame.Surface((rect.w, 6), pygame.SRCALPHA)
    for i in range(6):
        bottom.fill((0, 0, 0, 20 + i * 12), (0, i, rect.w, 1))
    bg.blit(bottom, (rect.left, rect.bottom - 6))
    pygame.draw.line(bg, edge, (rect.left, rect.top), (rect.right - 1, rect.top), 2)        # filo de neón arriba
    pygame.draw.line(bg, _mul(edge, (0.45, 0.45, 0.5)), (rect.left, rect.top), (rect.left, rect.bottom - 1))
    pygame.draw.line(bg, _mul(edge, (0.3, 0.3, 0.35)), (rect.right - 1, rect.top), (rect.right - 1, rect.bottom - 1))
    pygame.draw.line(bg, _mul(edge, (0.25, 0.25, 0.3)), (rect.left, rect.bottom - 1), (rect.right - 1, rect.bottom - 1))


def _style_details(bg, rect, st, rng):
    """Detalle sobrio y monocromo (sin ventanas de colores): costuras de panel y remaches del mismo tono del muro."""
    seam = _mul(st["wall"], (0.55, 0.55, 0.6))
    rivet = _mul(st["wall"], (1.6, 1.6, 1.65))
    for x in range(rect.left + 40, rect.right - 8, 80):
        pygame.draw.line(bg, seam, (x, rect.top + 3), (x, rect.bottom - 5))
    for x in range(rect.left + 8, rect.right - 6, 40):
        for y in range(rect.top + 8, rect.bottom - 6, 40):
            pygame.draw.circle(bg, rivet, (x, y), 1)


# --------------------------------------------------------- sombras de contacto ----
@lru_cache(maxsize=None)
def shadow_surface(w, h, alpha):
    """Elipse translúcida y suave (anillos concéntricos) para apoyar un sprite en el suelo."""
    img = pygame.Surface((w, h), pygame.SRCALPHA)
    for i in range(5):
        k = 1 - i * 0.16
        rw, rh = max(2, int(w * k)), max(2, int(h * k))
        pygame.draw.ellipse(img, (0, 0, 0, alpha // 4 + i * (alpha // 6)), ((w - rw) // 2, (h - rh) // 2, rw, rh))
    return img


def draw_contact_shadow(surface, screen_rect, lift=0):
    """Sombra bajo `screen_rect`. Los voladores (`lift` > 0) proyectan una sombra más pequeña, tenue y desplazada."""
    w = max(10, int(screen_rect.w * (0.95 if lift == 0 else 0.7)))
    h = max(6, int(screen_rect.h * 0.30))
    alpha = 150 if lift == 0 else 90
    sh = shadow_surface(w // 2 * 2, h // 2 * 2, alpha)
    surface.blit(sh, sh.get_rect(center=(screen_rect.centerx + 1, screen_rect.bottom - h // 2 + 3 + lift)))
