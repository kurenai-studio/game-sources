"""Sprites procedurales de entidades y objetos de escenario: Ariete blindado y compuertas de búnker."""
import math
import random
from functools import lru_cache

import pygame

CARBON = (40, 44, 52)
CARBON_LIGHT = (70, 76, 88)
STEEL = (112, 120, 134)
STEEL_LIGHT = (168, 176, 190)
STEEL_DARK = (26, 28, 34)


def _arc_points(cx, cy, r, a0, a1, steps=14):
    return [(cx + math.cos(math.radians(a0 + (a1 - a0) * i / steps)) * r,
             cy + math.sin(math.radians(a0 + (a1 - a0) * i / steps)) * r) for i in range(steps + 1)]


@lru_cache(maxsize=None)
def _ariete(s):
    """Ariete mirando a la derecha: chasis angular de carbono, escudo frontal en arco de doble capa, orugas ranuradas
    a ambos lados y reactor trasero brillante (el punto débil donde el crítico hace x3)."""
    img = pygame.Surface((s, s), pygame.SRCALPHA)
    u = s / 100.0

    def p(x, y):
        return (round(x * u), round(y * u))
    # orugas laterales (arriba y abajo): banda oscura ranurada con ruedas en los extremos
    for y0 in (6, 74):
        pygame.draw.rect(img, STEEL_DARK, (*p(8, y0), round(80 * u), round(20 * u)), border_radius=max(2, round(7 * u)))
        for x in range(12, 86, 5):
            pygame.draw.line(img, (62, 66, 76), p(x, y0 + 2), p(x, y0 + 18), max(1, round(2 * u)))
        pygame.draw.rect(img, (84, 90, 102), (*p(8, y0), round(80 * u), round(20 * u)), 1, border_radius=max(2, round(7 * u)))
        for wx in (16, 80):
            pygame.draw.circle(img, CARBON_LIGHT, p(wx, y0 + 10), max(2, round(7 * u)))
            pygame.draw.circle(img, STEEL_DARK, p(wx, y0 + 10), max(1, round(3 * u)))
    # chasis trapezoidal: estrecho atrás, ancho adelante
    hull = [p(6, 30), p(70, 20), p(70, 80), p(6, 70)]
    pygame.draw.polygon(img, CARBON, hull)
    pygame.draw.polygon(img, CARBON_LIGHT, hull, max(1, round(2 * u)))
    pygame.draw.line(img, (92, 98, 112), p(14, 34), p(66, 26), max(1, round(2 * u)))       # filo iluminado superior
    for x in (26, 40, 54):                                                                  # paneles y remaches
        pygame.draw.line(img, STEEL_DARK, p(x, 30 - (x - 6) // 12 * 1), p(x, 70 + (x - 6) // 12 * 1), 1)
        pygame.draw.circle(img, STEEL, p(x + 3, 38), max(1, round(1.5 * u)))
        pygame.draw.circle(img, STEEL, p(x + 3, 62), max(1, round(1.5 * u)))
    # escudo frontal: placa curva masiva en dos capas (exterior de acero y refuerzo interior) con marcas de desgaste
    cx, cy = 58, 50
    outer = _arc_points(cx, cy, 42, -72, 72)
    mid = _arc_points(cx, cy, 31, 72, -72)
    pygame.draw.polygon(img, STEEL, [p(*q) for q in outer] + [p(*q) for q in mid])
    inner_out = _arc_points(cx, cy, 31, -72, 72)
    inner_in = _arc_points(cx, cy, 22, 72, -72)
    pygame.draw.polygon(img, (82, 88, 100), [p(*q) for q in inner_out] + [p(*q) for q in inner_in])
    pygame.draw.lines(img, STEEL_LIGHT, False, [p(*q) for q in outer], max(1, round(2 * u)))      # borde exterior brillante
    pygame.draw.lines(img, STEEL_DARK, False, [p(*q) for q in mid], 1)
    pygame.draw.lines(img, STEEL_DARK, False, [p(*q) for q in inner_in], 1)
    for a in (-48, -16, 16, 48):                                                              # juntas radiales
        x0, y0 = cx + math.cos(math.radians(a)) * 22, cy + math.sin(math.radians(a)) * 22
        x1, y1 = cx + math.cos(math.radians(a)) * 42, cy + math.sin(math.radians(a)) * 42
        pygame.draw.line(img, STEEL_DARK, p(x0, y0), p(x1, y1), 1)
    for (x0, y0, x1, y1) in ((88, 40, 97, 43), (91, 58, 98, 54), (84, 30, 90, 33), (86, 68, 92, 66)):   # arañazos y abolladuras
        pygame.draw.line(img, (60, 64, 74), p(x0, y0), p(x1, y1), 1)
    for a in (-60, -30, 0, 30, 60):                                                           # remaches del escudo
        pygame.draw.circle(img, STEEL_LIGHT, p(cx + math.cos(math.radians(a)) * 37, cy + math.sin(math.radians(a)) * 37),
                           max(1, round(1.4 * u)))
    # reactor trasero: núcleo de energía cian con anillo magenta (punto débil)
    rx, ry, rr = 17, 50, 11
    pygame.draw.circle(img, STEEL_DARK, p(rx, ry), round((rr + 4) * u))
    pygame.draw.circle(img, (200, 40, 190), p(rx, ry), round((rr + 2) * u), max(1, round(2 * u)))
    pygame.draw.circle(img, (0, 120, 140), p(rx, ry), round(rr * u))
    pygame.draw.circle(img, (0, 225, 255), p(rx, ry), round(rr * 0.68 * u))
    pygame.draw.circle(img, (230, 255, 255), p(rx, ry), max(1, round(rr * 0.3 * u)))
    return img


def render_ariete(size):
    return _ariete(int(size)).copy()


# ------------------------------------------------------------------ compuertas ----
HATCH_LAMP = {"locked": (255, 50, 50), "unlocked": (60, 255, 120), "open": (60, 255, 120)}   # rojo bloqueada / verde operativa


def _worn_hazard(img, rect, rng, width=4):
    """Franjas diagonales amarillo/negro desgastadas dentro de `rect` (bordes de las hojas de la compuerta)."""
    rect = pygame.Rect(rect)
    if rect.w < 2 or rect.h < 2:
        return
    layer = pygame.Surface(rect.size, pygame.SRCALPHA)
    layer.fill((16, 16, 18, 255))
    for x in range(-rect.h, rect.w + rect.h, 2 * width):
        pygame.draw.polygon(layer, (200, 166, 24, 255), [(x, rect.h), (x + width, rect.h), (x + width + rect.h, 0), (x + rect.h, 0)])
    for _ in range(rect.w * rect.h // 9):                                                   # pintura saltada
        layer.set_at((rng.randrange(rect.w), rng.randrange(rect.h)), (30, 30, 34, 255))
    img.blit(layer, rect)


@lru_cache(maxsize=None)
def _hatch(w, h, state):
    """Compuerta estanca pesada encajada en el marco del muro: marco de acero atornillado, dos hojas de placas con nervios y
    remaches que se juntan en una junta central con franjas de advertencia, volante de cierre y faro de estado (rojo
    bloqueada / verde operativa). Abierta: las hojas se pliegan en el marco y queda el hueco. Se dibuja en vertical y se
    gira 90 grados si la puerta es horizontal. state: locked | unlocked | open."""
    sw, lh = min(w, h), max(w, h)
    rng = random.Random(sw * 131 + lh * 7)
    lamp = HATCH_LAMP[state]
    img = pygame.Surface((sw, lh), pygame.SRCALPHA)
    img.fill((30, 32, 38))
    pygame.draw.rect(img, (96, 102, 116), img.get_rect(), 1)
    pygame.draw.line(img, STEEL_LIGHT, (1, 1), (sw - 3, 1))
    pygame.draw.line(img, STEEL_LIGHT, (1, 1), (1, lh - 3))
    pygame.draw.line(img, STEEL_DARK, (1, lh - 2), (sw - 2, lh - 2))
    pygame.draw.line(img, STEEL_DARK, (sw - 2, 1), (sw - 2, lh - 2))
    b = max(3, sw // 6)                                                                      # grosor del marco lateral
    head, foot = max(8, lh // 10), max(4, lh // 16)
    inner = pygame.Rect(b, head, sw - 2 * b, lh - head - foot)
    for y in range(head + 4, lh - foot - 2, 9):                                              # remaches del marco
        for x in (b // 2, sw - b // 2 - 1):
            pygame.draw.circle(img, (140, 146, 160), (x, y), 1)
    for x in range(b + 3, sw - b - 2, 8):                                                    # cabezal y pie con tornillos
        pygame.draw.circle(img, (120, 126, 140), (x, head - 3), 1)
        pygame.draw.circle(img, (120, 126, 140), (x, lh - foot + 1), 1)
    pygame.draw.rect(img, (14, 16, 20), inner.inflate(2, 2), 1)                              # hueco del marco
    if state == "open":
        pygame.draw.rect(img, (6, 10, 12), inner)                                            # hueco libre
        for y in range(inner.top + 8, inner.bottom - 6, 6):                                  # rieles de la puerta en el suelo
            pygame.draw.line(img, (16, 22, 26), (inner.left, y), (inner.right - 1, y))
        slab = max(4, inner.h // 9)
        for r in (pygame.Rect(inner.x, inner.y, inner.w, slab), pygame.Rect(inner.x, inner.bottom - slab, inner.w, slab)):
            pygame.draw.rect(img, (66, 72, 84), r)                                           # hojas plegadas en el marco
            pygame.draw.line(img, (118, 126, 142), r.topleft, (r.right - 1, r.top))
        _worn_hazard(img, (inner.x, inner.y + slab, inner.w, 3), rng, 3)
        _worn_hazard(img, (inner.x, inner.bottom - slab - 3, inner.w, 3), rng, 3)
        pygame.draw.rect(img, lamp, inner, 1)
    else:
        mid = inner.centery
        for leaf in (pygame.Rect(inner.x, inner.y, inner.w, mid - inner.y - 1),
                     pygame.Rect(inner.x, mid + 1, inner.w, inner.bottom - mid - 1)):
            pygame.draw.rect(img, (62, 68, 80), leaf)
            for y in range(leaf.top + 1, leaf.bottom - 1, 3):                                # acero cepillado
                pygame.draw.line(img, (74, 80, 94) if (y // 3) % 2 else (54, 59, 70), (leaf.left + 1, y), (leaf.right - 2, y))
            panel = leaf.inflate(-6, -6)                                                     # placa reforzada con nervio
            if panel.w > 4 and panel.h > 4:
                pygame.draw.rect(img, (46, 50, 60), panel, 1)
                pygame.draw.line(img, (104, 112, 128), (panel.left + 1, panel.top), (panel.right - 2, panel.top))
            pygame.draw.line(img, (118, 126, 142), (leaf.left, leaf.top), (leaf.right - 1, leaf.top))
            pygame.draw.line(img, (28, 30, 36), (leaf.left, leaf.bottom - 1), (leaf.right - 1, leaf.bottom - 1))
            for cx in (leaf.left + 3, leaf.right - 4):                                       # remaches de las esquinas
                for cy in (leaf.top + 3, leaf.bottom - 4):
                    pygame.draw.circle(img, STEEL_LIGHT, (cx, cy), 1)
        band = 4
        _worn_hazard(img, (inner.x, mid - 2 - band, inner.w, band), rng, 3)                  # junta con franjas de advertencia
        _worn_hazard(img, (inner.x, mid + 2, inner.w, band), rng, 3)
        pygame.draw.line(img, (8, 8, 10), (inner.left, mid - 1), (inner.right - 1, mid - 1))
        pygame.draw.line(img, (8, 8, 10), (inner.left, mid), (inner.right - 1, mid))
        r = max(3, min(inner.w // 2 - 2, 7))                                                 # volante de cierre
        wheel = (110, 44, 44) if state == "locked" else (40, 104, 62)
        pygame.draw.circle(img, (20, 22, 26), (sw // 2, mid), r + 1)
        pygame.draw.circle(img, wheel, (sw // 2, mid), r)
        pygame.draw.circle(img, (20, 22, 26), (sw // 2, mid), max(1, r - 2), 1)
        pygame.draw.line(img, (190, 196, 206), (sw // 2 - r + 1, mid), (sw // 2 + r - 1, mid))
        pygame.draw.line(img, (190, 196, 206), (sw // 2, mid - r + 1), (sw // 2, mid + r - 1))
    lx = sw // 2                                                                             # faro superior de estado
    pygame.draw.rect(img, (20, 22, 26), (lx - 6, 0, 12, 7))
    pygame.draw.rect(img, (84, 90, 104), (lx - 6, 0, 12, 7), 1)
    pygame.draw.rect(img, lamp, (lx - 4, 1, 8, 4))
    pygame.draw.rect(img, tuple(min(255, c + 90) for c in lamp), (lx - 2, 2, 3, 2))
    if w > h:
        img = pygame.transform.rotate(img, 90)
    return img


def render_hatch(size, state):
    return _hatch(int(size[0]), int(size[1]), state).copy()


def draw_hatch_glow(surface, screen_rect, state, t):
    """Resplandor pulsante del faro de estado (rojo rápido si está bloqueada, verde lento si es operativa)."""
    color = HATCH_LAMP[state]
    k = 0.55 + 0.45 * math.sin(t * (6 if state == "locked" else 3))
    r = 10
    glow = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
    pygame.draw.circle(glow, (*color, int(80 * k)), (r, r), r)
    centre = (screen_rect.centerx, screen_rect.top + 3) if screen_rect.h >= screen_rect.w \
        else (screen_rect.left + 3, screen_rect.centery)
    surface.blit(glow, glow.get_rect(center=centre))


# -------------------------------------------------------- Estación del Exotraje ----
@lru_cache(maxsize=None)
def _exo_station(w, h, used):
    """Cabina de soporte vertical del exotraje: marco blindado ancho con pistones hidráulicos a los lados, cápsula de cristal
    con la silueta del traje y cables conectados (stand-by). `used`: cápsula abierta y desacoplada, vacía, con las puertas
    abiertas y los cables sueltos."""
    img = pygame.Surface((w, h), pygame.SRCALPHA)
    frame = pygame.Rect(0, 0, w, h)
    pygame.draw.rect(img, (34, 36, 44), frame, border_radius=6)
    pygame.draw.rect(img, (100, 106, 120), frame, 2, border_radius=6)
    pygame.draw.line(img, STEEL_LIGHT, (6, 1), (w - 7, 1))
    pygame.draw.rect(img, (22, 24, 30), (2, h - 10, w - 4, 8), border_radius=2)             # placa base
    for x in range(6, w - 4, 8):
        pygame.draw.circle(img, (120, 126, 140), (x, h - 6), 1)
    pygame.draw.rect(img, (26, 28, 34), (6, 2, w - 12, 9), border_radius=2)                 # cabezal con el faro
    pygame.draw.rect(img, (84, 90, 104), (6, 2, w - 12, 9), 1, border_radius=2)
    pygame.draw.rect(img, (14, 16, 20), (w // 2 - 6, 3, 12, 7))
    top, bottom = 14, h - 13
    for side in (0, 1):                                                                       # pistones laterales
        x = 3 if side == 0 else w - 10
        pygame.draw.rect(img, (20, 22, 26), (x, top, 7, bottom - top))
        pygame.draw.rect(img, (104, 110, 124), (x + 1, top + 1, 5, (bottom - top) // 2))
        pygame.draw.line(img, (180, 186, 198), (x + 2, top + 2), (x + 2, top + (bottom - top) // 2 - 2))
        ext = 15 if used else 6                                                               # vástago: extendido al desacoplar
        pygame.draw.rect(img, (196, 202, 212), (x + 2, top + (bottom - top) // 2, 3, ext))
        for k in range(3):                                                                    # anillos hidráulicos
            pygame.draw.line(img, (60, 64, 76), (x, top + 5 + k * 7), (x + 6, top + 5 + k * 7))
    cap = pygame.Rect(15, 14, w - 30, h - 28)                                                 # cápsula
    if not used:
        glass = pygame.Surface(cap.size, pygame.SRCALPHA)
        for y in range(cap.h):                                                                # cristal con degradado vertical
            k = y / cap.h
            glass.fill((int(10 - 6 * k), int(46 - 26 * k), int(56 - 30 * k), 255), (0, y, cap.w, 1))
        cx = cap.w // 2
        suit = (52, 74, 88)
        pygame.draw.circle(glass, suit, (cx, 8), 5)                                           # casco
        pygame.draw.rect(glass, (0, 200, 220), (cx - 2, 7, 5, 2))                             # visor
        pygame.draw.polygon(glass, suit, [(cx - 8, 15), (cx + 8, 15), (cx + 5, 33), (cx - 5, 33)])    # torso
        pygame.draw.line(glass, suit, (cx - 8, 16), (cx - 11, 32), 3)                         # brazos
        pygame.draw.line(glass, suit, (cx + 8, 16), (cx + 11, 32), 3)
        pygame.draw.line(glass, suit, (cx - 3, 33), (cx - 4, cap.h - 3), 3)                   # piernas
        pygame.draw.line(glass, suit, (cx + 3, 33), (cx + 4, cap.h - 3), 3)
        pygame.draw.line(glass, (0, 160, 180), (cx - 8, 15), (cx + 8, 15))                    # filo cian del hombro
        pygame.draw.polygon(glass, (255, 255, 255, 38), [(2, 0), (9, 0), (3, cap.h), (0, cap.h)])   # reflejo diagonal
        img.blit(glass, cap)
    else:
        pygame.draw.rect(img, (6, 8, 10), cap)                                                # cuna vacía
        for y in (cap.top + 9, cap.top + 24):
            pygame.draw.rect(img, (44, 48, 58), (cap.left + 2, y, cap.w - 4, 3))              # abrazaderas abiertas
        pygame.draw.ellipse(img, (22, 26, 32), (cap.left + 3, cap.bottom - 7, cap.w - 6, 5))
        for sx, tip in ((1, -1), (-1, 1)):                                                    # puertas abiertas hacia fuera
            x0 = cap.left if sx == 1 else cap.right
            pts = [(x0, cap.top), (x0 - sx * 6, cap.top + 3), (x0 - sx * 6, cap.bottom - 3), (x0, cap.bottom)]
            pygame.draw.polygon(img, (74, 80, 94), pts)
            pygame.draw.polygon(img, (130, 138, 154), pts, 1)
    pygame.draw.rect(img, (150, 158, 172), cap, 2, border_radius=3)                           # bisel de la cápsula
    for bx, by in ((cap.left + 2, cap.top + 2), (cap.right - 3, cap.top + 2), (cap.left + 2, cap.bottom - 3), (cap.right - 3, cap.bottom - 3)):
        pygame.draw.circle(img, STEEL_LIGHT, (bx, by), 1)
    cable, shine = (14, 14, 18), (62, 66, 80)
    if not used:                                                                              # cables conectados al traje
        for x0, x1 in ((20, cap.left + cap.w // 2 - 7), (w - 21, cap.left + cap.w // 2 + 7)):
            pts = [(x0, 8), (x0 + (3 if x0 < w // 2 else -3), 16), (x1, 26)]
            pygame.draw.lines(img, cable, False, pts, 4)
            pygame.draw.lines(img, shine, False, pts, 1)
            pygame.draw.rect(img, (212, 178, 24), (x1 - 2, 25, 5, 4))                         # conector al hombro
        pygame.draw.lines(img, cable, False, [(w // 2, h - 10), (w // 2, h - 16), (w // 2 - 2, h - 22)], 4)
        pygame.draw.rect(img, (0, 190, 210), (w // 2 - 4, h - 24, 5, 3))
    else:                                                                                     # cables sueltos
        pygame.draw.lines(img, cable, False, [(20, 8), (14, 20), (17, 32), (13, 42)], 4)
        pygame.draw.lines(img, shine, False, [(20, 8), (14, 20), (17, 32), (13, 42)], 1)
        pygame.draw.circle(img, (236, 150, 60), (13, 43), 2)                                  # extremo pelado
        pygame.draw.lines(img, cable, False, [(w - 21, 8), (w - 15, 22), (w - 18, 36)], 4)
        pygame.draw.lines(img, shine, False, [(w - 21, 8), (w - 15, 22), (w - 18, 36)], 1)
        pygame.draw.circle(img, (236, 150, 60), (w - 18, 37), 2)
        pygame.draw.lines(img, cable, False, [(w // 2, h - 10), (w // 2 + 8, h - 5), (w // 2 + 16, h - 6)], 4)   # cable en el suelo
        pygame.draw.rect(img, (0, 190, 210), (w // 2 + 15, h - 8, 4, 3))
    return img


def render_exo_station(size, used):
    return _exo_station(int(size[0]), int(size[1]), bool(used)).copy()


def draw_exo_lamp(surface, screen_rect, used, t):
    """Luz de stand-by del cabezal: ámbar pulsante con el traje en la cabina; apagada (rojo tenue) al desacoplarlo."""
    cx, cy = screen_rect.centerx, screen_rect.top + 6
    if used:
        color, k = (160, 40, 40), 0.35 + 0.25 * (math.sin(t * 2) > 0.8)
    else:
        color, k = (255, 190, 50), 0.6 + 0.4 * math.sin(t * 3)
    glow = pygame.Surface((24, 24), pygame.SRCALPHA)
    pygame.draw.circle(glow, (*color, int(90 * k)), (12, 12), 12)
    pygame.draw.circle(glow, (*color, int(255 * k)), (12, 12), 3)
    surface.blit(glow, glow.get_rect(center=(cx, cy)))


def draw_exo_burst(surface, screen_rect, p):
    """Ráfaga de vapor y chispas al desacoplar el traje (`p` 0 -> 1 a lo largo del efecto)."""
    rng = random.Random(7)
    for i in range(10):                                                                       # vapor desde los pistones y el cabezal
        side = (-1, 1, 0)[i % 3]
        ox = screen_rect.centerx + side * (screen_rect.w // 2 - 6)
        oy = screen_rect.top + screen_rect.h * (0.35 if side else 0.1)
        drift = rng.uniform(0.4, 1.0) * (side or rng.choice((-1, 1)))
        rise = rng.uniform(26, 52)
        delay = rng.uniform(0.0, 0.25)
        q = max(0.0, min(1.0, (p - delay) / (1 - delay)))
        if q <= 0:
            continue
        r = 3 + 9 * q
        puff = pygame.Surface((int(r * 2) + 2, int(r * 2) + 2), pygame.SRCALPHA)
        pygame.draw.circle(puff, (214, 224, 234, int(150 * (1 - q))), (puff.get_width() // 2, puff.get_height() // 2), int(r))
        surface.blit(puff, puff.get_rect(center=(ox + drift * 18 * q, oy - rise * q)))
    if p < 0.55:                                                                              # chispas
        for i in range(14):
            ang = math.radians(rng.uniform(200, 340))
            speed = rng.uniform(40, 110)
            q = p / 0.55
            x = screen_rect.centerx + rng.uniform(-10, 10) + math.cos(ang) * speed * q * 0.5
            y = screen_rect.top + screen_rect.h * 0.25 + math.sin(ang) * speed * q * 0.5 + 60 * q * q
            tail = (x - math.cos(ang) * 5, y - math.sin(ang) * 5 - 2)
            pygame.draw.line(surface, (255, 220, 90) if i % 2 else (255, 150, 50), (x, y), tail, 2 if q < 0.3 else 1)


# --------------------------------------------------------- brecha del Dash ----
def render_chasm(w, h, pad, seed):
    """Foso real: el suelo se corta con bordes fracturados e irregulares y el fondo es un degradado de gris oscuro a negro,
    con vigas y ferrallas dobladas que asoman por los costados. Devuelve (imagen de (w + 2 pad) x h, puntas de ferralla).
    La caja de colisión es el rectángulo central w x h; los bordes irregulares sobresalen unos píxeles."""
    rng = random.Random(seed)
    W = w + 2 * pad
    ys = list(range(0, h + 1, 8))
    left = [pad + rng.randint(-6, 6) for _ in ys]
    right = [pad + w + rng.randint(-6, 6) for _ in ys]
    left[0] = left[-1] = pad
    right[0] = right[-1] = pad + w
    poly = [(x, y) for x, y in zip(left, ys)] + [(x, y) for x, y in reversed(list(zip(right, ys)))]
    mask = pygame.Surface((W, h), pygame.SRCALPHA)
    pygame.draw.polygon(mask, (255, 255, 255, 255), poly)
    grad = pygame.Surface((W, h), pygame.SRCALPHA)
    mid = pad + w / 2
    for x in range(W):                                                                        # degradado hacia el centro (negro)
        k = min(1.0, abs(x - mid) / (w / 2 + 3))
        k = k ** 1.4
        grad.fill((int(2 + 40 * k), int(2 + 40 * k), int(4 + 50 * k), 255), (x, 0, 1, h))
    for y in range(h):                                                                        # y se aviva un poco hacia los muros
        edge = min(y, h - 1 - y)
        if edge < 8:
            grad.fill((14, 14, 18, 0), (0, y, W, 1), special_flags=pygame.BLEND_RGBA_ADD)
    grad.blit(mask, (0, 0), special_flags=pygame.BLEND_RGBA_MULT)
    img = grad
    for inset, alpha in ((5, 70), (10, 40)):                                                  # cornisas desmoronadas dentro del foso
        for pts in ([(x + inset, y) for x, y in zip(left, ys)], [(x - inset, y) for x, y in zip(right, ys)]):
            pygame.draw.lines(img, (70, 70, 84, alpha), False, pts, 1)
    for side_pts, sgn in ((list(zip(left, ys)), -1), (list(zip(right, ys)), 1)):              # labio del suelo y grietas
        pygame.draw.lines(img, (22, 22, 28, 255), False, side_pts, 3)
        pygame.draw.lines(img, (126, 120, 112, 255), False, [(x + sgn * 2, y) for x, y in side_pts], 1)
        for _ in range(7):
            i = rng.randrange(1, len(side_pts) - 1)
            x, y = side_pts[i]
            L = rng.randint(6, 12)
            pts = [(x + sgn * 2, y), (x + sgn * (2 + L // 2), y + rng.randint(-3, 3)), (x + sgn * (2 + L), y + rng.randint(-5, 5))]
            pygame.draw.lines(img, (8, 8, 12, 255), False, pts, 1)
    tips = []
    rust, rust_hi = (138, 82, 46), (206, 134, 84)
    for yy, sgn in ((h * 0.22, -1), (h * 0.7, -1), (h * 0.42, 1)):                           # ferrallas dobladas desde los costados
        i = max(1, min(len(ys) - 2, int(yy // 8)))
        x0 = (left if sgn < 0 else right)[i]
        y0 = ys[i]
        d = -sgn
        pts = [(x0, y0), (x0 + d * 7, y0 + 3), (x0 + d * 11, y0 - 3), (x0 + d * 16, y0 + 2), (x0 + d * 18, y0 + 7)]
        pygame.draw.lines(img, (20, 12, 8, 255), False, [(x, y + 1) for x, y in pts], 3)
        pygame.draw.lines(img, rust, False, pts, 2)
        pygame.draw.lines(img, rust_hi, False, pts[:3], 1)
        tips.append(pts[-1])
    k_ = min(len(ys) - 2, len(ys) // 2 + 2)
    x0, y0 = right[k_], ys[k_]                                     # viga en I retorcida (derecha)
    beam = [(x0, y0), (x0 - 9, y0 + 5), (x0 - 18, y0 + 3), (x0 - 24, y0 + 11)]
    pygame.draw.lines(img, (14, 16, 20, 255), False, [(x, y + 2) for x, y in beam], 6)
    pygame.draw.lines(img, (92, 98, 112, 255), False, beam, 4)
    pygame.draw.lines(img, (160, 168, 184, 255), False, beam, 1)
    tips.append(beam[-1])
    for x in (pad + w // 2 - 7, pad + w // 2 + 9):                                            # ferralla que asoma de los muros N y S
        pygame.draw.lines(img, rust, False, [(x, 0), (x + 2, 6), (x - 2, 10)], 2)
        pygame.draw.lines(img, rust, False, [(x + 3, h - 1), (x + 1, h - 7), (x + 5, h - 11)], 2)
    return img, tips


# ------------------------------------------------------- Tanque (Ariete Ligero) ----
def _uscale(size):
    u = size / 100.0

    def p(x, y):
        return (round(x * u), round(y * u))
    return u, p


@lru_cache(maxsize=None)
def _tank_chassis(s):
    """Chasis del Tanque mirando a la derecha: casco angular de blindaje pesado, orugas mecánicas laterales con ruedas y
    eslabones, glacis frontal en cuña y, atrás, la rejilla del radiador con un núcleo rectangular (el punto débil). El
    pulso ámbar del núcleo lo añade `render_tank_core_glow` (se anima aparte)."""
    img = pygame.Surface((s, s), pygame.SRCALPHA)
    u, p = _uscale(s)
    for y0 in (3, 77):                                                                       # orugas
        track = pygame.Rect(*p(8, y0), round(84 * u), round(20 * u))
        pygame.draw.rect(img, (22, 24, 30), track, border_radius=max(2, round(6 * u)))
        for x in range(12, 90, 5):
            pygame.draw.line(img, (58, 62, 74), p(x, y0 + 2), p(x, y0 + 18), max(1, round(2 * u)))
        pygame.draw.rect(img, (96, 102, 118), track, 1, border_radius=max(2, round(6 * u)))
        for wx in (17, 50, 83):
            pygame.draw.circle(img, (74, 80, 94), p(wx, y0 + 10), max(2, round(7 * u)))
            pygame.draw.circle(img, (26, 28, 34), p(wx, y0 + 10), max(1, round(3 * u)))
    hull = [p(4, 30), p(15, 21), p(64, 21), p(95, 36), p(95, 64), p(64, 79), p(15, 79), p(4, 70)]
    pygame.draw.polygon(img, (46, 50, 60), hull)                                              # casco angular
    pygame.draw.polygon(img, (104, 112, 128), hull, max(1, round(2 * u)))
    glacis = [p(64, 21), p(95, 36), p(95, 64), p(64, 79)]
    pygame.draw.polygon(img, (74, 80, 94), glacis)                                            # glacis frontal en cuña
    pygame.draw.lines(img, (158, 166, 182), False, [p(64, 21), p(95, 36), p(95, 64), p(64, 79)], max(1, round(2 * u)))
    for y in (34, 50, 66):
        pygame.draw.line(img, (28, 30, 38), p(70, y), p(90, y), 1)                           # juntas del glacis
    for x in (34, 48):                                                                        # paneles y remaches del casco
        pygame.draw.line(img, (30, 32, 40), p(x, 24), p(x, 76), 1)
        for y in (28, 72):
            pygame.draw.circle(img, (140, 148, 164), p(x + 3, y), max(1, round(1.4 * u)))
    grille = pygame.Rect(*p(6, 33), round(26 * u), round(34 * u))                             # rejilla del radiador
    pygame.draw.rect(img, (14, 16, 20), grille)
    for y in range(35, 66, 4):
        pygame.draw.line(img, (84, 90, 104), p(7, y), p(31, y), 1)
    pygame.draw.rect(img, (130, 138, 154), grille, 1)
    core = pygame.Rect(*p(12, 42), round(14 * u), round(16 * u))                              # núcleo rectangular
    pygame.draw.rect(img, (84, 44, 10), core)
    pygame.draw.rect(img, (30, 20, 8), core, 1)
    for ey in (28, 72):                                                                       # escapes
        pygame.draw.circle(img, (20, 22, 26), p(8, ey), max(2, round(3 * u)))
    return img


def render_tank_chassis(size):
    return _tank_chassis(int(size)).copy()


@lru_cache(maxsize=None)
def _tank_core_glow(s):
    """Resplandor ámbar del núcleo del radiador (superficie translúcida del tamaño del chasis, para pulsar con set_alpha)."""
    img = pygame.Surface((s, s), pygame.SRCALPHA)
    u, p = _uscale(s)
    cx, cy = p(19, 50)
    for r, a in ((16, 40), (11, 70), (7, 110)):                                               # halo
        pygame.draw.circle(img, (255, 150, 30, a), (cx, cy), max(2, round(r * u)))
    core = pygame.Rect(*p(12, 42), round(14 * u), round(16 * u))
    pygame.draw.rect(img, (255, 170, 40, 235), core)
    pygame.draw.rect(img, (255, 236, 150, 255), core.inflate(-round(6 * u), -round(8 * u)))
    for y in range(35, 66, 4):                                                                # luz entre las lamas de la rejilla
        pygame.draw.line(img, (255, 150, 30, 130), p(8, y), p(30, y), 1)
    return img


def render_tank_core_glow(size):
    return _tank_core_glow(int(size)).copy()


@lru_cache(maxsize=None)
def _tank_turret(s):
    """Torreta giratoria (cañón a la derecha), independiente del chasis: cúpula angular, escotilla, mirilla y cañón."""
    img = pygame.Surface((s, s), pygame.SRCALPHA)
    u, p = _uscale(s)
    pygame.draw.rect(img, (24, 26, 32), (*p(50, 44), round(46 * u), round(12 * u)))           # cañón
    pygame.draw.rect(img, (88, 94, 108), (*p(50, 45), round(46 * u), round(4 * u)))
    pygame.draw.rect(img, (40, 44, 52), (*p(88, 41), round(10 * u), round(18 * u)))           # freno de boca
    pygame.draw.rect(img, (120, 128, 144), (*p(88, 41), round(10 * u), round(18 * u)), 1)
    cx, cy, r = 46, 50, 25
    octo = [p(cx + math.cos(math.radians(a)) * r, cy + math.sin(math.radians(a)) * r) for a in range(22, 382, 45)]
    pygame.draw.polygon(img, (66, 72, 86), octo)
    pygame.draw.polygon(img, (150, 158, 174), octo, max(1, round(2 * u)))
    pygame.draw.polygon(img, (84, 90, 106), [p(cx + math.cos(math.radians(a)) * 15, cy + math.sin(math.radians(a)) * 15)
                                             for a in range(22, 382, 45)])
    pygame.draw.circle(img, (30, 32, 40), p(cx - 4, cy), max(2, round(6 * u)))                # escotilla
    pygame.draw.circle(img, (120, 128, 144), p(cx - 4, cy), max(2, round(6 * u)), 1)
    pygame.draw.rect(img, (255, 80, 60), (*p(62, 46), round(5 * u), max(1, round(2 * u))))     # mirilla
    pygame.draw.line(img, (150, 158, 174), p(cx - 14, cy - 18), p(cx - 20, cy - 34), 1)       # antena
    return img


def render_tank_turret(size):
    return _tank_turret(int(size)).copy()


# ----------------------------------------------------- consola de enlace (AURA) ----
# Cables gruesos de la consola hacia el suelo: ruta de puntos relativa al centro de la consola. Los pinta el mapa en el suelo
# y el pulso de datos los recorre al pulsar E.
LINK_CABLES = (
    ((-14, 30), (-14, 50), (-44, 62), (-96, 62)),
    ((14, 30), (14, 58), (64, 58), (104, 40), (124, 30)),
    ((0, 32), (0, 76), (0, 118)),
)


@lru_cache(maxsize=None)
def _link_console(w, h):
    """Consola táctica de enlace: bastidor de rack con pantalla, hilera de LEDs (los anima el overlay), panel de mandos y
    cables gruesos que salen por la base hacia el suelo."""
    img = pygame.Surface((w, h), pygame.SRCALPHA)
    base = pygame.Rect(2, h - 12, w - 4, 11)
    pygame.draw.rect(img, (22, 24, 30), base, border_radius=2)
    pygame.draw.rect(img, (84, 90, 104), base, 1, border_radius=2)
    rack = pygame.Rect(0, 0, w, h - 10)
    pygame.draw.rect(img, (30, 34, 44), rack, border_radius=4)
    pygame.draw.rect(img, (96, 106, 126), rack, 2, border_radius=4)
    pygame.draw.line(img, (170, 180, 198), (4, 1), (w - 5, 1))
    screen = pygame.Rect(6, 6, w - 12, int((h - 10) * 0.42))
    pygame.draw.rect(img, (4, 10, 14), screen)                                                # pantalla (la onda va en el overlay)
    pygame.draw.rect(img, (0, 150, 170), screen, 1)
    led_y = screen.bottom + 5
    for row in range(2):
        for i in range(5):
            r = pygame.Rect(8 + i * ((w - 16) // 5), led_y + row * 7, 6, 4)                  # alojamientos de LED
            pygame.draw.rect(img, (14, 16, 20), r)
            pygame.draw.rect(img, (70, 76, 90), r, 1)
    panel = pygame.Rect(6, led_y + 17, w - 12, h - 10 - (led_y + 17) - 5)
    pygame.draw.rect(img, (20, 22, 28), panel)
    pygame.draw.rect(img, (62, 68, 82), panel, 1)
    for i in range(3):                                                                        # deslizadores
        x = panel.x + 5 + i * 11
        pygame.draw.line(img, (50, 54, 66), (x, panel.y + 3), (x, panel.bottom - 3), 2)
        pygame.draw.rect(img, (160, 168, 184), (x - 2, panel.y + 5 + (i * 3) % 6, 5, 3))
    for k in range(3):                                                                        # rejilla de ventilación
        pygame.draw.line(img, (50, 54, 66), (panel.right - 18, panel.y + 4 + k * 3), (panel.right - 5, panel.y + 4 + k * 3))
    for sx in (3, w - 5):                                                                     # tornillos
        for sy in (4, h - 18):
            pygame.draw.circle(img, (140, 148, 164), (sx, sy), 1)
    for cx in (w // 2 - 14, w // 2, w // 2 + 14):                                             # cables que salen por la base
        pygame.draw.rect(img, (12, 12, 16), (cx - 3, h - 14, 6, 14))
        pygame.draw.line(img, (62, 66, 80), (cx - 1, h - 13), (cx - 1, h - 1))
    return img


def render_link_console(size):
    return _link_console(int(size[0]), int(size[1])).copy()


def _cable_point(path, k):
    """Punto situado a la fracción k (0-1) de la longitud de una ruta de cable."""
    seg = [(path[i], path[i + 1], math.dist(path[i], path[i + 1])) for i in range(len(path) - 1)]
    target = k * sum(d for _, _, d in seg)
    for a, b, d in seg:
        if target <= d:
            f = target / d if d else 0.0
            return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
        target -= d
    return path[-1]


def draw_link_console(surface, rect, t, online, sync):
    """Capa animada de la consola: forma de onda de audio cian en la pantalla, LEDs parpadeantes y, al enlazar (`sync` 1 -> 0),
    el destello de sincronización y un pulso de datos que recorre los cables. `online`: consola operativa o ya enlazada."""
    screen = pygame.Rect(rect.x + 7, rect.y + 7, rect.w - 14, int((rect.h - 10) * 0.42) - 2)
    n = screen.w
    amp = (0.42 + 0.5 * sync) if online else 0.06
    pts = []
    for i in range(n):
        x = i / n
        v = (math.sin(x * 14 + t * 6) * 0.55 + math.sin(x * 33 - t * 9) * 0.3 + math.sin(x * 5 + t * 2.1) * 0.35)
        v *= math.sin(math.pi * x) ** 0.6 if online else 1.0                                   # envolvente: más viva al centro
        pts.append((screen.x + i, screen.centery + int(v * amp * screen.h * 0.5)))
    if len(pts) > 1:
        pygame.draw.lines(surface, (0, 90, 110), False, [(x, y + 1) for x, y in pts], 3)      # halo
        pygame.draw.lines(surface, (0, 235, 255) if online else (0, 110, 120), False, pts, 1)
    pygame.draw.line(surface, (0, 60, 70), (screen.x, screen.centery), (screen.right - 1, screen.centery))
    led_y = rect.y + 6 + int((rect.h - 10) * 0.42) + 5
    cols = ((60, 255, 120), (0, 225, 255), (255, 190, 50), (255, 60, 60))
    for row in range(2):
        for i in range(5):
            on = (int(t * 3 + i * 1.7 + row * 2.3) % 3 != 0) if online else (int(t * 1.5 + i) % 4 == 0 and i % 2 == 0)
            color = cols[(i + row) % 3] if online else cols[3]
            r = pygame.Rect(rect.x + 8 + i * ((rect.w - 16) // 5), led_y + row * 7, 6, 4)
            pygame.draw.rect(surface, color if on else _dim(color), r)
            if on:
                halo = pygame.Surface((14, 12), pygame.SRCALPHA)
                pygame.draw.ellipse(halo, (*color, 40), halo.get_rect().inflate(-4, -4))
                surface.blit(halo, halo.get_rect(center=r.center))
    if sync > 0:
        flash = pygame.Surface(rect.size, pygame.SRCALPHA)                                    # destello de sincronización
        flash.fill((200, 250, 255, int(190 * sync * sync)))
        surface.blit(flash, rect)
        ring = rect.inflate(int(70 * (1 - sync)), int(70 * (1 - sync)))
        pygame.draw.rect(surface, (0, 235, 255), ring, 2, border_radius=6)
        for path in LINK_CABLES:                                                              # pulso de datos por los cables
            for lag in (0.0, 0.18, 0.36):
                k = (1.0 - sync) * 1.5 - lag
                if 0.0 <= k <= 1.0:
                    x, y = _cable_point(path, k)
                    c = (rect.centerx + x, rect.centery + y)
                    glow = pygame.Surface((22, 22), pygame.SRCALPHA)
                    pygame.draw.circle(glow, (0, 235, 255, 70), (11, 11), 7)
                    pygame.draw.circle(glow, (230, 255, 255, 255), (11, 11), 2)
                    surface.blit(glow, glow.get_rect(center=(round(c[0]), round(c[1]))))


def _dim(color):
    return tuple(c // 5 for c in color)


# --------------------------------------------------- esclusa de contención ----
@lru_cache(maxsize=None)
def _airlock(w, h, state):
    """Esclusa de contención pesada: marco blindado, dos pistones hidráulicos laterales, dos hojas con nervios que se juntan
    en una junta con pernos de cierre y franjas de advertencia, y faro de estado (rojo bloqueada / verde despresurizada).
    Se dibuja en horizontal y se gira 90 grados si es vertical. Abierta, las hojas se recogen junto a los pistones."""
    lw, sh = max(w, h), min(w, h)
    rng = random.Random(lw * 17 + sh)
    lamp = HATCH_LAMP["open" if state == "open" else "locked"]
    img = pygame.Surface((lw, sh), pygame.SRCALPHA)
    img.fill((26, 28, 34))
    pygame.draw.rect(img, (100, 108, 124), img.get_rect(), 1)
    pygame.draw.line(img, STEEL_LIGHT, (1, 1), (lw - 3, 1))
    pygame.draw.line(img, STEEL_DARK, (1, sh - 2), (lw - 2, sh - 2))
    pw = max(8, lw // 8)
    ext = 3 if state == "open" else 9                                                          # vástago: se recoge al abrir
    for side in (0, 1):                                                                       # pistones laterales
        x = 2 if side == 0 else lw - pw - 2
        pygame.draw.rect(img, (18, 20, 24), (x, 3, pw, sh - 6))
        pygame.draw.rect(img, (98, 104, 118), (x + 1, 4, pw - 2, sh - 8))
        pygame.draw.line(img, (176, 184, 198), (x + 2, 5), (x + 2, sh - 6))
        for k in range(3):                                                                    # anillos
            yy = 8 + k * ((sh - 16) // 3)
            pygame.draw.line(img, (52, 56, 68), (x, yy), (x + pw - 1, yy), 2)
        rod_x = x + pw if side == 0 else x - ext
        pygame.draw.rect(img, (200, 206, 216), (rod_x, sh // 2 - 3, ext, 6))
        pygame.draw.rect(img, (24, 26, 30), (rod_x, sh // 2 - 3, ext, 6), 1)
    door = pygame.Rect(pw + 4 + ext, 5, lw - 2 * (pw + 4 + ext), sh - 10)
    mid = door.centerx
    if state == "open":
        pygame.draw.rect(img, (6, 10, 12), pygame.Rect(pw + 6, 5, lw - 2 * (pw + 6), sh - 10))   # hueco libre
        gap = pygame.Rect(pw + 6, 5, lw - 2 * (pw + 6), sh - 10)
        for y in range(gap.top + 3, gap.bottom - 2, 5):
            pygame.draw.line(img, (14, 22, 24), (gap.left, y), (gap.right - 1, y))
        for r in (pygame.Rect(gap.x, gap.y, 5, gap.h), pygame.Rect(gap.right - 5, gap.y, 5, gap.h)):
            pygame.draw.rect(img, (70, 76, 90), r)                                            # hojas recogidas
        pygame.draw.rect(img, lamp, gap, 1)
    else:
        for leaf in (pygame.Rect(door.x, door.y, door.w // 2 - 1, door.h), pygame.Rect(mid + 1, door.y, door.w // 2 - 1, door.h)):
            pygame.draw.rect(img, (60, 66, 78), leaf)
            for x in range(leaf.left + 1, leaf.right - 1, 3):                                 # acero cepillado
                pygame.draw.line(img, (72, 78, 92) if (x // 3) % 2 else (52, 57, 68), (x, leaf.top + 1), (x, leaf.bottom - 2))
            pygame.draw.rect(img, (44, 48, 58), leaf.inflate(-6, -6), 1)
            pygame.draw.line(img, (112, 120, 136), leaf.topleft, (leaf.right - 1, leaf.top))
            for cx in (leaf.left + 3, leaf.right - 4):
                for cy in (leaf.top + 3, leaf.bottom - 4):
                    pygame.draw.circle(img, STEEL_LIGHT, (cx, cy), 1)
        _worn_hazard(img, (mid - 7, door.y, 14, door.h), rng, 3)                              # junta con franjas de advertencia
        pygame.draw.line(img, (8, 8, 10), (mid - 1, door.top), (mid - 1, door.bottom - 1))
        pygame.draw.line(img, (8, 8, 10), (mid, door.top), (mid, door.bottom - 1))
        for by in (door.top + 4, door.centery, door.bottom - 5):                              # pernos de cierre
            pygame.draw.rect(img, (170, 176, 190), (mid - 5, by - 1, 10, 3))
            pygame.draw.rect(img, (20, 22, 26), (mid - 5, by - 1, 10, 3), 1)
    lx = lw // 2                                                                              # faro de estado
    pygame.draw.rect(img, (18, 20, 24), (lx - 7, 0, 14, 6))
    pygame.draw.rect(img, (90, 96, 110), (lx - 7, 0, 14, 6), 1)
    pygame.draw.rect(img, lamp, (lx - 5, 1, 10, 4))
    pygame.draw.rect(img, tuple(min(255, c + 90) for c in lamp), (lx - 2, 2, 4, 2))
    if h > w:
        img = pygame.transform.rotate(img, 90)
    return img


AIRLOCK_STEPS = 10                                                                            # fotogramas de la apertura (caché)


@lru_cache(maxsize=None)
def _airlock_opening(w, h, step):
    """Apertura hidráulica: las hojas se repliegan hacia los pistones (que se recogen) y dejan ver la luz del exterior.
    step 0 = cerrada (idéntica a `locked`), AIRLOCK_STEPS = hojas recogidas; el faro ya está en verde."""
    lw, sh = max(w, h), min(w, h)
    p = step / AIRLOCK_STEPS
    img = _airlock(lw, sh, "locked").copy()
    pw = max(8, lw // 8)
    door = pygame.Rect(pw + 4 + 9, 5, lw - 2 * (pw + 13), sh - 10)                            # hueco de las hojas cerradas
    gap = pygame.Rect(pw + 6, 5, lw - 2 * (pw + 6), sh - 10)                                  # hueco con las hojas recogidas
    pygame.draw.rect(img, (26, 28, 34), (pw + 2, 5, door.x - pw - 2, sh - 10))                  # borra el vástago extendido
    pygame.draw.rect(img, (26, 28, 34), (door.right, 5, lw - pw - 2 - door.right, sh - 10))
    half = door.w // 2 - 1
    lw_leaf = round(half + (5 - half) * p)                                                    # ancho de cada hoja
    lx = round(door.x + (gap.x - door.x) * p)                                                 # borde exterior de la hoja izquierda
    rx = round(door.right + (gap.right - door.right) * p)                                     # borde exterior de la hoja derecha
    left = pygame.Rect(lx, door.y, lw_leaf, door.h)
    right = pygame.Rect(rx - lw_leaf, door.y, lw_leaf, door.h)
    span = pygame.Rect(left.right, door.y, max(0, right.x - left.right), door.h)
    if span.w > 0:                                                                            # el exterior asoma entre las hojas
        for x in range(span.left, span.right):
            k = 1 - abs(x - span.centerx) / max(1, span.w / 2)
            col = tuple(int(a + (b - a) * k * (0.45 + 0.55 * p)) for a, b in zip((28, 44, 50), (206, 236, 242)))
            pygame.draw.line(img, col, (x, span.top), (x, span.bottom - 1))
    for leaf, inner_right in ((left, True), (right, False)):
        pygame.draw.rect(img, (60, 66, 78), leaf)
        for x in range(leaf.left + 1, leaf.right - 1, 3):
            pygame.draw.line(img, (72, 78, 92) if (x // 3) % 2 else (52, 57, 68), (x, leaf.top + 1), (x, leaf.bottom - 2))
        pygame.draw.line(img, (112, 120, 136), leaf.topleft, (leaf.right - 1, leaf.top))
        edge = pygame.Rect(leaf.right - 4 if inner_right else leaf.left, leaf.top, 4, leaf.h)    # canto con franjas de advertencia
        _worn_hazard(img, edge, random.Random(5 + step), 2)
        pygame.draw.line(img, (8, 8, 10), (edge.left if inner_right else edge.right - 1, leaf.top),
                         (edge.left if inner_right else edge.right - 1, leaf.bottom - 1))
    ext = 9 - round(6 * p)                                                                    # los pistones empujan las hojas
    for side in (0, 1):
        x = 2 if side == 0 else lw - pw - 2
        rod_x = x + pw if side == 0 else x - ext
        pygame.draw.rect(img, (200, 206, 216), (rod_x, sh // 2 - 3, ext, 6))
        pygame.draw.rect(img, (24, 26, 30), (rod_x, sh // 2 - 3, ext, 6), 1)
    lamp = HATCH_LAMP["open"]
    lx0 = lw // 2
    pygame.draw.rect(img, lamp, (lx0 - 5, 1, 10, 4))
    pygame.draw.rect(img, tuple(min(255, c + 90) for c in lamp), (lx0 - 2, 2, 4, 2))
    if h > w:
        img = pygame.transform.rotate(img, 90)
    return img


def render_airlock(size, state, step=0):
    """state: locked | open | opening (con `step` 1..AIRLOCK_STEPS-1)."""
    if state == "opening":
        return _airlock_opening(int(size[0]), int(size[1]), max(0, min(AIRLOCK_STEPS, step))).copy()
    return _airlock(int(size[0]), int(size[1]), state).copy()


def draw_airlock_glow(surface, screen_rect, state, t):
    """Resplandor del faro de la esclusa: arriba al centro si es horizontal, a la izquierda si es vertical."""
    color = HATCH_LAMP[state]
    k = 0.55 + 0.45 * math.sin(t * (6 if state == "locked" else 3))
    glow = pygame.Surface((20, 20), pygame.SRCALPHA)
    pygame.draw.circle(glow, (*color, int(80 * k)), (10, 10), 10)
    centre = (screen_rect.centerx, screen_rect.top + 3) if screen_rect.w >= screen_rect.h         else (screen_rect.left + 3, screen_rect.centery)
    surface.blit(glow, glow.get_rect(center=centre))


def draw_airlock_vent(surface, screen_rect, p):
    """Vapor de la despresurización: bocanadas que salen por los pistones laterales (`p` 0 -> 1)."""
    rng = random.Random(11)
    horizontal = screen_rect.w >= screen_rect.h
    for i in range(12):
        side = -1 if i % 2 == 0 else 1
        delay = rng.uniform(0.0, 0.3)
        q = max(0.0, min(1.0, (p - delay) / (1 - delay)))
        if q <= 0:
            continue
        if horizontal:
            ox, oy = screen_rect.centerx + side * (screen_rect.w // 2 - 8), screen_rect.centery + rng.uniform(-8, 8)
            px, py = ox + side * rng.uniform(8, 26) * q, oy + rng.uniform(-22, 22) * q
        else:
            ox, oy = screen_rect.centerx + rng.uniform(-8, 8), screen_rect.centery + side * (screen_rect.h // 2 - 8)
            px, py = ox + rng.uniform(-22, 22) * q, oy + side * rng.uniform(8, 26) * q
        r = 3 + 9 * q
        puff = pygame.Surface((int(r * 2) + 2, int(r * 2) + 2), pygame.SRCALPHA)
        pygame.draw.circle(puff, (214, 226, 236, int(160 * (1 - q))), (puff.get_width() // 2, puff.get_height() // 2), int(r))
        surface.blit(puff, puff.get_rect(center=(px, py)))


# ------------------------------------------------------------------- terminal ----
@lru_cache(maxsize=None)
def _terminal(w, h, color):
    """Consola táctica 2.5D: soporte trapezoidal, panel con borde de neón, pantalla con degradado radial y puntos
    holográficos, línea de interfaz curva e indicadores laterales."""
    img = pygame.Surface((w, h), pygame.SRCALPHA)
    base_top = int(h * 0.74)
    pygame.draw.polygon(img, (46, 48, 56), [(int(w * 0.18), base_top), (int(w * 0.82), base_top),
                                            (int(w * 0.66), h - 1), (int(w * 0.34), h - 1)])
    pygame.draw.polygon(img, (96, 100, 112), [(int(w * 0.18), base_top), (int(w * 0.82), base_top),
                                              (int(w * 0.66), h - 1), (int(w * 0.34), h - 1)], 1)
    panel = pygame.Rect(0, 0, w, base_top + 2)
    pygame.draw.rect(img, (12, 16, 24), panel, border_radius=3)
    pygame.draw.rect(img, color, panel, 2, border_radius=3)
    screen = panel.inflate(-12, -10)
    screen.y = panel.y + 5
    glow = pygame.Surface(screen.size)
    cx, cy = screen.w // 2, screen.h // 2
    glow.fill(tuple(c // 8 for c in color))
    for r in range(max(screen.w, screen.h) // 2, 0, -2):                                   # degradado radial desde el centro
        k = 1 - r / (max(screen.w, screen.h) / 2)
        pygame.draw.ellipse(glow, tuple(int(10 + (c // 2.4 - 10) * k) for c in color),
                            (cx - r * 1.2, cy - r * 0.8, r * 2.4, r * 1.6))
    img.blit(glow, screen)
    for x in range(screen.left + 2, screen.right - 1, 4):                                  # píxeles holográficos
        for y in range(screen.top + 2, screen.bottom - 1, 4):
            if (x * 7 + y * 13) % 5 < 2:
                img.set_at((x, y), tuple(min(255, c // 2 + 60) for c in color))
    pygame.draw.arc(img, color, (screen.left + 2, screen.bottom - 12, screen.w - 4, 20), 0.25, math.pi - 0.25, 2)   # interfaz curva
    for sx in (3, w - 6):                                                                  # indicadores laterales
        for k in range(3):
            pygame.draw.rect(img, color if k % 2 == 0 else (80, 86, 98), (sx, 8 + k * 5, 3, 3))
    return img


def render_terminal(size, color):
    return _terminal(int(size[0]), int(size[1]), tuple(color)).copy()


def draw_terminal_glow(surface, screen_rect, strength):
    """Brillo verde de la pantalla al interactuar (`strength` 1 -> 0)."""
    inner = screen_rect.inflate(-10, -int(screen_rect.h * 0.4))
    inner.y = screen_rect.y + 5
    glow = pygame.Surface(inner.size, pygame.SRCALPHA)
    glow.fill((60, 255, 120, int(150 * strength)))
    surface.blit(glow, inner)
    halo = pygame.Surface((screen_rect.w + 20, screen_rect.h + 20), pygame.SRCALPHA)
    pygame.draw.rect(halo, (60, 255, 120, int(60 * strength)), halo.get_rect(), border_radius=8)
    surface.blit(halo, (screen_rect.x - 10, screen_rect.y - 10))
