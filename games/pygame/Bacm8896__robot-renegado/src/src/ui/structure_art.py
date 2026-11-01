"""Arte procedural de las estructuras (torreta, muro, núcleo, pilón, extractor; el generador solo lo usa la IA enemiga).

Acero oscuro con bisel, pernos y franjas de advertencia, más acentos de neón: cian para las estructuras del
jugador y rojo/naranja para la Fundición Renegada (misma estética que el Operador y los enemigos).

Cada estructura se compone de dos capas:
  - una base estática (`render_*`), cacheada: es la `image` del sprite y su máscara de impacto;
  - una capa dinámica (`draw_*`), dibujada en cada fotograma: cañón que gira, núcleos que pulsan, taladro...
"""
import math
import random
from functools import lru_cache

import pygame

import config as C

STEEL_DARK = (20, 23, 33)
STEEL = (42, 47, 62)
STEEL_MID = (58, 64, 82)
STEEL_LIGHT = (98, 107, 130)
RIVET = (132, 140, 160)

PALETTES = {
    "ally": {"accent": C.CYAN, "glow": (0, 225, 255), "core": (200, 255, 255), "warn": C.YELLOW},
    "hostile": {"accent": C.RED, "glow": (255, 70, 40), "core": (255, 220, 170), "warn": C.ORANGE},
    "mining": {"accent": C.GREEN, "glow": (60, 255, 120), "core": (210, 255, 220), "warn": C.YELLOW},
    "balista": {"accent": C.ORANGE, "glow": (255, 170, 50), "core": (255, 240, 200), "warn": C.YELLOW},
    "tesla": {"accent": (0, 255, 200), "glow": (0, 255, 220), "core": (220, 255, 255), "warn": C.YELLOW},
    "flame": {"accent": (255, 107, 26), "glow": (255, 120, 40), "core": (255, 230, 160), "warn": C.ORANGE},
    "light": {"accent": (204, 51, 51), "glow": (255, 90, 80), "core": (255, 220, 200), "warn": C.YELLOW},
    "heavy": {"accent": (107, 142, 35), "glow": (170, 220, 80), "core": (235, 255, 200), "warn": C.YELLOW},
    "rail": {"accent": (192, 192, 192), "glow": (120, 180, 255), "core": (230, 240, 255), "warn": C.YELLOW},
    "wall2": {"accent": (210, 215, 235), "glow": (220, 225, 255), "core": (255, 255, 255), "warn": (255, 160, 40)},
    "wall3": {"accent": (255, 232, 70), "glow": (255, 240, 120), "core": (255, 255, 220), "warn": (255, 232, 70)},
    "plasma": {"accent": (255, 160, 30), "glow": (255, 170, 40), "core": (255, 240, 190), "warn": C.YELLOW},
    "foco": {"accent": (180, 255, 120), "glow": (170, 255, 110), "core": (235, 255, 220), "warn": C.YELLOW},
}
HEAD_SIZE = 48
ROT_STEP = 6                                   # grados por paso de la caché de cañones


def now():
    return pygame.time.get_ticks() / 1000.0


# ---------------------------------------------------------------- utilidades ----
def _gradient(img, top, bottom):
    w, h = img.get_size()
    for y in range(h):
        k = y / max(1, h - 1)
        pygame.draw.line(img, tuple(round(top[i] + (bottom[i] - top[i]) * k) for i in range(3)), (0, y), (w, y))


def _bevel(img, rect, light=STEEL_LIGHT, dark=STEEL_DARK, width=2):
    r = pygame.Rect(rect)
    for i in range(width):
        pygame.draw.line(img, light, (r.left + i, r.top + i), (r.right - 1 - i, r.top + i))
        pygame.draw.line(img, light, (r.left + i, r.top + i), (r.left + i, r.bottom - 1 - i))
        pygame.draw.line(img, dark, (r.left + i, r.bottom - 1 - i), (r.right - 1 - i, r.bottom - 1 - i))
        pygame.draw.line(img, dark, (r.right - 1 - i, r.top + i), (r.right - 1 - i, r.bottom - 1 - i))


def _bolt(img, pos, r=2):
    x, y = round(pos[0]), round(pos[1])
    pygame.draw.circle(img, STEEL_DARK, (x + 1, y + 1), r)
    pygame.draw.circle(img, RIVET, (x, y), r)
    pygame.draw.circle(img, (210, 216, 230), (x - 1, y - 1), max(1, r - 2))


def _hazard(img, rect, warn):
    """Franja de advertencia: diagonales de color y negro, recortada al rectángulo."""
    r = pygame.Rect(rect)
    strip = pygame.Surface(r.size, pygame.SRCALPHA)
    strip.fill((14, 14, 18))
    h = r.h
    for x in range(-h, r.w + h, 12):
        pygame.draw.polygon(strip, warn, [(x, h), (x + 6, h), (x + 6 + h, 0), (x + h, 0)])
    img.blit(strip, r)
    pygame.draw.rect(img, STEEL_DARK, r, 1)


def _glow_surface(radius, color, peak):
    """Resplandor radial (alfa decreciente); se dibuja con BLEND_ADD para que brille."""
    s = pygame.Surface((radius * 2, radius * 2))                  # opaca y premultiplicada: BLEND_ADD ignora el alfa
    for i in range(radius, 0, -1):
        k = (1 - i / radius) ** 1.6 * peak / 255
        pygame.draw.circle(s, tuple(int(v * k) for v in color), (radius, radius), i)
    return s


@lru_cache(maxsize=None)
def _glow(radius, color, peak):
    return _glow_surface(radius, color, peak)


def _lift(color, d):
    return tuple(max(0, min(255, c + d)) for c in color)


def _hex(center, radius, rot=math.pi / 6):
    return [(center[0] + radius * math.cos(rot + i * math.pi / 3),
             center[1] + radius * math.sin(rot + i * math.pi / 3)) for i in range(6)]


# ------------------------------------------------------------------- muro ----
@lru_cache(maxsize=None)
def _wall(size, pal, level=1):
    """Chapa soldada: cordones de soldadura horizontales y remaches (nivel 1); refuerzos angulares en las esquinas, más
    remaches y tono más oscuro (nivel 2); bobina eléctrica superior y borde cian (nivel 3). Siempre con borde superior
    iluminado y cara frontal en sombra (2.5D)."""
    p = PALETTES[pal]
    w, h = size
    plate = {1: (106, 106, 106), 2: (90, 90, 90), 3: (88, 94, 96)}[level]
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, _lift(plate, 20), _lift(plate, -22))
    _bevel(img, img.get_rect(), light=_lift(plate, 62), dark=_lift(plate, -62), width=2)
    pygame.draw.rect(img, p["accent"] if level >= 3 else _lift(plate, -48), img.get_rect(), 1)
    for y in (h // 3, 2 * h // 3):                                              # cordones de soldadura
        pygame.draw.line(img, _lift(plate, -42), (4, y + 1), (w - 5, y + 1))
        for x in range(5, w - 6, 4):
            pygame.draw.line(img, _lift(plate, 52), (x, y), (x + 2, y))
    for bx, by in ((5, 5), (w - 6, 5), (5, h - 6), (w - 6, h - 6)):             # remaches esquineros
        _bolt(img, (bx, by))
    if level >= 2:                                                              # refuerzo angular + más remaches
        dark = (44, 44, 50)
        for (cx, cy, sx, sy) in ((2, 2, 1, 1), (w - 3, 2, -1, 1), (2, h - 3, 1, -1), (w - 3, h - 3, -1, -1)):
            pygame.draw.polygon(img, dark, [(cx, cy), (cx + 11 * sx, cy), (cx, cy + 11 * sy)])
            pygame.draw.polygon(img, _lift(dark, 40), [(cx, cy), (cx + 11 * sx, cy), (cx, cy + 11 * sy)], 1)
        for x in (w // 4, w // 2, 3 * w // 4):
            _bolt(img, (x, 5), 1)
            _bolt(img, (x, h - 6), 1)
        for y in (h // 2 - 3, h // 2 + 3):
            _bolt(img, (5, y), 1)
            _bolt(img, (w - 6, y), 1)
    if level >= 3:                                                              # bobina eléctrica superior
        cx = w // 2
        coil = [(cx - 7, 17), (cx + 7, 17), (cx, 3)]
        pygame.draw.polygon(img, (8, 38, 40), coil)
        for k, y in enumerate(range(15, 5, -3)):
            half = 6 - k * 1.4
            pygame.draw.line(img, p["accent"], (cx - half, y), (cx + half, y))
        pygame.draw.polygon(img, p["accent"], coil, 1)
        pygame.draw.circle(img, p["core"], (cx, 4), 2)
    pygame.draw.line(img, (218, 226, 242), (2, 1), (w - 3, 1), 2)               # borde superior iluminado (luz cenital)
    pygame.draw.line(img, _lift(plate, 52), (2, 3), (w - 3, 3))
    shade = pygame.Surface((w, 5), pygame.SRCALPHA)                              # cara frontal en sombra: volumen 2.5D
    shade.fill((0, 0, 0, 95))
    img.blit(shade, (0, h - 5))
    return img


def render_wall(size, pal="ally", level=1):
    return _wall(tuple(size), pal, level).copy()


def draw_wall_sparks(surface, rect, t, seed):
    """Muro Electrificado: aura verde/cian y chispas cian que aparecen y desaparecen alrededor."""
    glow = _glow(26, (0, 255, 200), 80)
    surface.blit(glow, glow.get_rect(center=rect.center), special_flags=pygame.BLEND_ADD)
    step = int(t * 6)
    for i in range(3):
        if (step + seed + i * 2) % 4 < 2:                                       # parpadeo periódico
            a = math.radians((seed * 37 + step * 53 + i * 97) % 360)
            x = rect.centerx + max(-rect.w // 2, min(rect.w // 2, math.cos(a) * rect.w * 0.7))
            y = rect.centery + max(-rect.h // 2, min(rect.h // 2, math.sin(a) * rect.h * 0.7))
            pygame.draw.circle(surface, (0, 255, 200), (round(x), round(y)), 2)
            pygame.draw.circle(surface, (210, 255, 255), (round(x), round(y)), 1)


# ---------------------------------------------------------------- compuerta ----
@lru_cache(maxsize=None)
def _gate(size, is_open):
    """Compuerta Blindada (1x2 celdas): marco de acero con dos hojas que se juntan en el centro (cerrada, con franja de
    advertencia en la junta) o se retraen a los extremos dejando un pasillo con brillo cian (abierta)."""
    w, h = size
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, STEEL_MID, STEEL_DARK)
    _bevel(img, img.get_rect(), width=2)
    inner = pygame.Rect(5, 5, w - 10, h - 10)
    pygame.draw.rect(img, (8, 10, 16), inner)
    leaf_h = inner.h // 2 - 1 if not is_open else inner.h // 6
    top = pygame.Rect(inner.x, inner.y, inner.w, leaf_h)
    bot = pygame.Rect(inner.x, inner.bottom - leaf_h, inner.w, leaf_h)
    for leaf in (top, bot):
        _gradient_rect(img, leaf, (96, 100, 138), (58, 62, 94))
        _bevel(img, leaf, light=(150, 154, 196), dark=STEEL_DARK, width=1)
        for k in range(leaf.x + 6, leaf.right - 4, 10):                              # nervaduras de refuerzo
            pygame.draw.line(img, (44, 48, 76), (k, leaf.y + 3), (k, leaf.bottom - 4), 1)
    if is_open:
        pygame.draw.rect(img, (0, 70, 80), (inner.x, top.bottom, inner.w, bot.y - top.bottom))   # pasillo abierto
        for x in (inner.x + 3, inner.right - 4):
            pygame.draw.line(img, (0, 225, 255), (x, top.bottom + 2), (x, bot.y - 3), 1)
    else:
        seam = pygame.Rect(inner.x, inner.centery - 4, inner.w, 8)
        _hazard(img, seam, (255, 190, 40))
    for bx, by in ((4, 4), (w - 5, 4), (4, h - 5), (w - 5, h - 5)):
        _bolt(img, (bx, by), 2)
    return img


def render_gate(size, is_open=False):
    return _gate(tuple(size), bool(is_open)).copy()


def draw_gate_lights(surface, rect, is_open, t):
    """Pilotos de los extremos: verdes fijos con la compuerta abierta, ámbar intermitente cerrada."""
    on = is_open or int(t * 2) % 2 == 0
    color = (60, 255, 120) if is_open else (255, 170, 40)
    for y in (rect.top + 7, rect.bottom - 7):
        pygame.draw.circle(surface, (20, 20, 24), (rect.centerx, y), 4)
        pygame.draw.circle(surface, color if on else (70, 50, 20), (rect.centerx, y), 3)


def _gradient_rect(img, rect, top, bottom):
    r = pygame.Rect(rect)
    for y in range(r.h):
        k = y / max(1, r.h - 1)
        pygame.draw.line(img, tuple(round(top[i] + (bottom[i] - top[i]) * k) for i in range(3)),
                         (r.x, r.y + y), (r.right - 1, r.y + y))


# ---------------------------------------------------------------- torreta ----
@lru_cache(maxsize=None)
def _tower_base(size, pal):
    """Plataforma cuadrada con el anillo de base de cada torreta (rojo la Ligera, verde militar la Pesada...)."""
    p = PALETTES[pal]
    w, h = size
    c = (w // 2, h // 2)
    radius = 16 if pal in ("light", "hostile", "ally", "flame") else 18
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, STEEL_MID, STEEL)
    _bevel(img, img.get_rect(), width=2)
    pygame.draw.circle(img, STEEL_DARK, (c[0] + 1, c[1] + 1), radius + 1)
    pygame.draw.circle(img, p["accent"], c, radius)                             # anillo de base
    body = (74, 74, 74) if radius == 16 else (58, 58, 58)
    pygame.draw.circle(img, body, c, radius - 4)                                # cuerpo cilíndrico visto desde arriba
    pygame.draw.circle(img, _lift(body, 34), c, radius - 4, 2)
    for bx, by in ((5, 5), (w - 6, 5), (5, h - 6), (w - 6, h - 6)):
        _bolt(img, (bx, by))
    return img


def render_tower_base(size, pal="ally"):
    return _tower_base(tuple(size), pal).copy()


_GOLD = (212, 175, 55)


@lru_cache(maxsize=None)
def _tower_head(step, pal, kind):
    """Cúpula y armamento mirando a la derecha, girados `step * ROT_STEP` grados (caché).
    kind: tower (cañón único), minigun (carcasa del gatling; los cañones se dibujan animados), flame (boquilla ancha y
    piloto), balista (cañón robusto), railgun (doble riel y bobina dorada) o tesla (bobina central)."""
    p = PALETTES[pal]
    s = HEAD_SIZE
    img = pygame.Surface((s, s), pygame.SRCALPHA)
    c = s // 2
    gun, gun_hi = (112, 112, 116), (160, 160, 166)
    if kind == "balista":
        pygame.draw.rect(img, STEEL_DARK, (c, c - 6, 24, 12))
        pygame.draw.rect(img, (70, 70, 74), (c, c - 5, 23, 10))
        pygame.draw.rect(img, gun_hi, (c, c - 5, 23, 2))
        for x in (c + 6, c + 14):
            pygame.draw.rect(img, p["accent"], (x, c - 6, 3, 12))                # bandas verde militar
        pygame.draw.rect(img, STEEL_DARK, (c + 22, c - 7, 3, 14))                # freno de boca
    elif kind == "railgun":
        for dy in (-6, 3):                                                       # doble riel plateado
            pygame.draw.rect(img, STEEL_DARK, (c + 1, c + dy - 1, 27, 5))
            pygame.draw.rect(img, p["accent"], (c + 2, c + dy, 26, 3))
        for x in (c + 8, c + 14, c + 20):                                        # bobina de carga dorada (espiral)
            pygame.draw.line(img, _GOLD, (x, c - 7), (x + 3, c + 7), 2)
        pygame.draw.rect(img, STEEL_DARK, (c + 26, c - 7, 3, 14))
    elif kind == "tesla":
        pygame.draw.circle(img, STEEL_DARK, (c, c), 12)                          # bobina central de gran tamaño
        for r, col in ((11, (0, 150, 150)), (8, (0, 255, 255)), (5, (0, 110, 120))):
            pygame.draw.circle(img, col, (c, c), r, 2)
        pygame.draw.circle(img, (210, 255, 255), (c, c), 3)
    elif kind == "flame":
        pygame.draw.rect(img, STEEL_DARK, (c - 13, c - 7, 12, 14))               # depósito de combustible
        pygame.draw.rect(img, (84, 84, 88), (c - 12, c - 6, 10, 12))
        pygame.draw.rect(img, p["accent"], (c - 12, c - 1, 10, 3))
        cone = [(c + 1, c - 3), (c + 19, c - 10), (c + 19, c + 10), (c + 1, c + 3)]   # boquilla ancha, cono abierto
        pygame.draw.polygon(img, STEEL_DARK, cone)
        pygame.draw.polygon(img, p["accent"], cone, 2)
        pygame.draw.polygon(img, p["accent"], [(c + 9, c - 2), (c + 16, c), (c + 9, c + 2)])   # llama piloto
    elif kind == "minigun":
        pygame.draw.rect(img, STEEL_DARK, (c, c - 8, 14, 16))                    # carcasa del tambor
        pygame.draw.rect(img, (90, 90, 94), (c, c - 7, 13, 14))
        pygame.draw.rect(img, _GOLD, (c + 28, c - 8, 3, 16))                     # abrazadera dorada en la boca
        pygame.draw.rect(img, _GOLD, (c + 6, c - 8, 2, 16))
    else:
        pygame.draw.rect(img, STEEL_DARK, (c, c - 4, 24, 8))                     # cañón único
        pygame.draw.rect(img, gun, (c, c - 3, 23, 6))
        pygame.draw.rect(img, gun_hi, (c, c - 3, 23, 2))
        pygame.draw.rect(img, STEEL_DARK, (c + 21, c - 5, 3, 10))
    if kind != "tesla":
        pygame.draw.circle(img, STEEL_DARK, (c + 1, c + 1), 10)                  # cúpula
        pygame.draw.circle(img, (96, 96, 100), (c, c), 10)
        pygame.draw.circle(img, (150, 150, 156), (c - 2, c - 2), 7, 2)
        pygame.draw.circle(img, p["accent"], (c, c), 3)
    return pygame.transform.rotate(img, -step * ROT_STEP)


def draw_turret_head(surface, center, angle_deg, pal, active, t, kind="tower", spin=0.0, flash=0.0):
    """Cúpula y armamento girados hacia el objetivo, más la animación de cada tipo: tambor del Minigun (`spin`), anillos
    y chispas de la Tesla, llama piloto del Lanzallamas y destello de la bobina del Railgun (`flash` > 0 al disparar)."""
    step = round(angle_deg / ROT_STEP) % (360 // ROT_STEP)
    head = _tower_head(step, pal, kind)
    surface.blit(head, head.get_rect(center=center))
    p = PALETTES[pal]
    d = pygame.math.Vector2(math.cos(math.radians(angle_deg)), math.sin(math.radians(angle_deg)))
    perp = pygame.math.Vector2(-d.y, d.x)
    ctr = pygame.math.Vector2(center)
    if kind == "minigun":                                                        # 6 cañones radiales girando
        for i in sorted(range(6), key=lambda k: math.cos(spin + k * math.pi / 3)):
            a = spin + i * math.pi / 3
            depth = math.cos(a)
            off = math.sin(a) * 5
            col = _GOLD if depth >= 0 else (120, 98, 30)
            pygame.draw.line(surface, col, ctr + d * 7 + perp * off, ctr + d * 28 + perp * off, 2 if depth >= 0 else 1)
        if flash > 0:
            pygame.draw.circle(surface, (255, 230, 140), ctr + d * 31, 4)
    elif kind == "railgun" and flash > 0:                                        # destello azul en la bobina
        for x in (8, 14, 20):
            q = ctr + d * x
            pygame.draw.circle(surface, (70, 150, 255), (round(q.x), round(q.y)), 5)
            pygame.draw.circle(surface, (220, 240, 255), (round(q.x), round(q.y)), 2)
    elif kind == "flame":                                                        # la llama piloto parpadea
        tip = ctr + d * 12
        s_ = 3 + int(t * 14) % 3
        pygame.draw.polygon(surface, (255, 150, 40), [tip + d * s_, tip + perp * 2, tip - perp * 2])
    elif kind == "tesla" and active:                                             # anillos contrarrotantes y chispas
        for r, rate in ((14, 0.9), (19, -1.2)):
            base = t * rate
            rect = pygame.Rect(0, 0, r * 2, r * 2)
            rect.center = (round(ctr.x), round(ctr.y))
            for k in range(3):
                pygame.draw.arc(surface, (0, 255, 255), rect, base + k * 2.1, base + k * 2.1 + 1.1, 2)
        step_t = int(t * 5)
        for i in range(3):
            if (step_t + i) % 3 == 0:
                a = step_t * 2.399 + i * 2.1
                q = ctr + pygame.math.Vector2(math.cos(a), math.sin(a)) * 22
                pygame.draw.circle(surface, (0, 255, 255), (round(q.x), round(q.y)), 2)
    led = p["glow"] if active else (60, 30, 34)
    if active:
        k = 0.65 + 0.35 * math.sin(t * 5)
        led = tuple(int(v * k) for v in led)
    pygame.draw.circle(surface, led, center, 3)


def draw_flame(surface, center, angle_deg, cone_deg, reach, t):
    """Chorro del lanzallamas: llamas que se abren en abanico frente a la tobera."""
    half = math.radians(cone_deg / 2)
    ang = math.radians(angle_deg)
    for i in range(14):
        k = (i * 0.137 + t * 3.1) % 1.0
        spread = (((i * 7919) % 100) / 100.0 - 0.5) * 2 * half
        dist = 14 + k * (reach - 14)
        x = center[0] + math.cos(ang + spread) * dist
        y = center[1] + math.sin(ang + spread) * dist
        r = max(1, int(2 + 5 * k))
        col = (255, int(220 - 150 * k), int(80 - 70 * k))
        pygame.draw.circle(surface, col, (round(x), round(y)), r)


def draw_breaking(surface, rect, remaining, blinks):
    """Muro rompiéndose: parpadea en rojo `blinks` veces mientras se agota `remaining` (1 -> 0)."""
    phase = int((1.0 - max(0.0, min(1.0, remaining))) * blinks * 2)
    if phase % 2 == 0:
        glow = pygame.Surface(rect.size, pygame.SRCALPHA)
        glow.fill((255, 40, 40, 170))
        surface.blit(glow, rect)
        pygame.draw.rect(surface, (255, 90, 90), rect, 2)
    else:
        pygame.draw.line(surface, (255, 60, 60), rect.topleft, rect.bottomright, 2)     # grieta
        pygame.draw.line(surface, (255, 60, 60), rect.topright, rect.bottomleft, 2)


@lru_cache(maxsize=None)
def _foco(size, pal):
    """Base cuadrada oscura del Foco Vigía con el eje de la antena parabólica."""
    w, h = size
    c = (w // 2, h // 2)
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, (66, 66, 66), (50, 50, 50))
    _bevel(img, img.get_rect(), light=(104, 104, 108), dark=(24, 24, 26), width=2)
    pygame.draw.circle(img, (26, 26, 28), c, 9)
    pygame.draw.circle(img, (100, 100, 106), c, 9, 1)
    for bx, by in ((5, 5), (w - 6, 5), (5, h - 6), (w - 6, h - 6)):
        _bolt(img, (bx, by))
    return img


def render_foco(size, pal="foco"):
    return _foco(tuple(size), pal).copy()


def draw_foco_sweep(surface, center, t, powered):
    """Antena parabólica (semicírculo cian) que gira despacio y pulso cian que irradia desde la base."""
    cx, cy = center
    if not powered:
        pygame.draw.arc(surface, (90, 96, 104), pygame.Rect(cx - 12, cy - 12, 24, 24), 0.5, 3.64, 3)
        pygame.draw.circle(surface, (90, 26, 34), center, 3)
        return
    a = t * 0.8
    rect = pygame.Rect(cx - 12, cy - 12, 24, 24)
    pygame.draw.arc(surface, (0, 255, 255), rect, -a - math.pi / 2, -a + math.pi / 2, 3)
    pygame.draw.line(surface, (200, 255, 255), center, (cx + math.cos(a) * 7, cy + math.sin(a) * 7), 2)
    pygame.draw.circle(surface, (0, 255, 255), center, 3)
    k = (t % 1.6) / 1.6                                                          # pulso radiante
    pulse = pygame.Surface((44, 44), pygame.SRCALPHA)
    pygame.draw.circle(pulse, (0, 255, 255, int(150 * (1 - k))), (22, 22), int(6 + 15 * k), 2)
    surface.blit(pulse, pulse.get_rect(center=center))


# ---------------------------------------------------- núcleo y generador ----
@lru_cache(maxsize=None)
def _core(size, pal):
    p = PALETTES[pal]
    w, h = size
    c = (w / 2, h / 2)
    r = min(w, h) / 2 - 1
    img = pygame.Surface(size, pygame.SRCALPHA)
    pygame.draw.polygon(img, STEEL_DARK, _hex(c, r))
    pygame.draw.polygon(img, STEEL, _hex(c, r - 3))
    pygame.draw.polygon(img, STEEL_MID, _hex(c, r - 3), 2)
    pygame.draw.polygon(img, p["accent"], _hex(c, r), 2)
    pygame.draw.polygon(img, STEEL_DARK, _hex(c, r * 0.68))
    pygame.draw.polygon(img, STEEL_LIGHT, _hex(c, r * 0.68), 1)
    for vx, vy in _hex(c, r - 6):                                               # pernos en los vértices
        _bolt(img, (vx, vy))
    for i in range(6):                                                          # conductos hacia el núcleo
        a = math.pi / 6 + i * math.pi / 3 + math.pi / 6
        p1 = (c[0] + math.cos(a) * r * 0.36, c[1] + math.sin(a) * r * 0.36)
        p2 = (c[0] + math.cos(a) * r * 0.66, c[1] + math.sin(a) * r * 0.66)
        pygame.draw.line(img, STEEL_LIGHT, p1, p2, 3)
        pygame.draw.line(img, STEEL_DARK, p1, p2, 1)
    pygame.draw.circle(img, (6, 10, 14), (round(c[0]), round(c[1])), round(r * 0.36))
    pygame.draw.circle(img, p["accent"], (round(c[0]), round(c[1])), round(r * 0.36), 2)
    return img


def render_core(size, pal="ally"):
    return _core(tuple(size), pal).copy()


# ------------------------------------------- Reactor Central (núcleo del 1.3) ----
_REACTOR_VENTS = (-8, 8)                                    # x de las dos salidas de vapor/humo respecto al centro
_REACTOR_VENT_Y = -29


@lru_cache(maxsize=None)
def _reactor(size):
    """Reactor industrial pesado: chasis anclado con pernos gruesos, dos bobinas de cobre laterales, conductos de
    refrigeración arriba y abajo y una cámara cilíndrica central (su luz se dibuja aparte, en `draw_reactor`)."""
    w, h = size
    cx, cy = w // 2, h // 2
    img = pygame.Surface(size, pygame.SRCALPHA)
    body = pygame.Rect(0, 0, w, h)
    pygame.draw.rect(img, (14, 16, 22), body, border_radius=7)
    pygame.draw.rect(img, (46, 52, 66), body.inflate(-4, -4), border_radius=5)
    _bevel(img, body.inflate(-6, -6))
    for bx, by in ((6, 6), (w - 7, 6), (6, h - 7), (w - 7, h - 7)):                  # anclajes al suelo
        pygame.draw.circle(img, (12, 14, 18), (bx + 1, by + 1), 4)
        pygame.draw.circle(img, (112, 120, 138), (bx, by), 3)
        pygame.draw.line(img, (30, 34, 44), (bx - 2, by), (bx + 2, by), 1)
        img.set_at((bx - 1, by - 1), (210, 218, 232))
    for x0 in (3, w - 14):                                                           # bobinas laterales de cobre
        pygame.draw.rect(img, (16, 14, 14), (x0, 17, 11, 30), border_radius=3)
        for y in range(19, 45, 3):
            pygame.draw.line(img, (150, 70, 42), (x0 + 1, y), (x0 + 9, y))
            pygame.draw.line(img, (212, 128, 84), (x0 + 1, y), (x0 + 3, y))
            pygame.draw.line(img, (84, 38, 24), (x0 + 1, y + 1), (x0 + 9, y + 1))
        pygame.draw.rect(img, (110, 116, 130), (x0, 17, 11, 30), 1, border_radius=3)
        pygame.draw.rect(img, (70, 76, 90), (x0 + 3, 13, 5, 5))                      # borne de la bobina
        pygame.draw.rect(img, (170, 178, 192), (x0 + 4, 12, 3, 2))
    for px in (21, 37):                                                              # conductos gruesos de refrigeración
        for y0, y1 in ((3, 20), (44, 61)):
            pygame.draw.rect(img, (14, 16, 20), (px - 1, y0, 8, y1 - y0))
            pygame.draw.rect(img, (74, 82, 98), (px, y0, 6, y1 - y0))
            pygame.draw.line(img, (150, 160, 180), (px + 1, y0), (px + 1, y1 - 1))
            pygame.draw.line(img, (40, 46, 58), (px + 5, y0), (px + 5, y1 - 1))
            for fy in (y0 + 3, y1 - 5):                                              # bridas
                pygame.draw.rect(img, (112, 120, 138), (px - 2, fy, 10, 3))
                pygame.draw.rect(img, (24, 26, 32), (px - 2, fy, 10, 3), 1)
    for vx in _REACTOR_VENTS:                                                        # rejillas de salida de vapor
        pygame.draw.rect(img, (8, 9, 12), (cx + vx - 3, 1, 6, 3))
    for x in range(cx - 10, cx + 11, 4):                                             # franja de advertencia inferior
        pygame.draw.polygon(img, (206, 170, 24), [(x, h - 3), (x + 2, h - 3), (x + 4, h - 7), (x + 2, h - 7)])
    for lx in (10, w - 11):                                                          # alojamientos de las luces de emergencia
        pygame.draw.circle(img, (12, 14, 18), (lx, 10), 4)
        pygame.draw.circle(img, (70, 30, 30), (lx, 10), 3)
    pygame.draw.circle(img, (12, 14, 18), (cx, cy), 18)                              # cámara cilíndrica central
    pygame.draw.circle(img, (118, 126, 144), (cx, cy), 17, 2)
    pygame.draw.circle(img, (46, 52, 66), (cx, cy), 15, 1)
    pygame.draw.circle(img, (6, 12, 16), (cx, cy), 13)
    for a in range(0, 360, 45):                                                      # tornillos del aro
        ang = math.radians(a + 22)
        img.set_at((round(cx + math.cos(ang) * 16), round(cy + math.sin(ang) * 16)), (190, 198, 212))
    return img


def render_reactor(size):
    return _reactor(tuple(size)).copy()


@lru_cache(maxsize=None)
def _puff(radius, color, alpha):
    img = pygame.Surface((radius * 2 + 2, radius * 2 + 2), pygame.SRCALPHA)
    pygame.draw.circle(img, (*color, alpha), (radius + 1, radius + 1), radius)
    pygame.draw.circle(img, (*color, alpha // 2), (radius + 1, radius + 1), max(1, radius // 2))
    return img


def _blit_puffs(surface, center, color, q, count, rise, max_r, peak, seed, loop):
    """Bocanadas que suben desde cada salida: la fase avanza 0->1 (crecen, se aclaran y desaparecen).
    `loop`: columna continua (humo); si no, una sola emisión que avanza con `q`."""
    for vi, vx in enumerate(_REACTOR_VENTS):
        for i in range(count):
            s = (q + i / count) % 1.0 if loop else q - i * 0.1
            if not 0 < s < 1:
                continue
            r = 3 + round((max_r - 3) * s)
            alpha = int(peak * (1 - s)) // 10 * 10
            if alpha <= 0:
                continue
            x = center[0] + vx + math.sin(seed + i * 2.1 + vi * 1.3 + s * 3) * (3 + 4 * s)
            y = center[1] + _REACTOR_VENT_Y - s * rise
            p = _puff(r, color, alpha)
            surface.blit(p, p.get_rect(center=(round(x), round(y))))


def draw_reactor(surface, center, t, frac):
    """Capa dinámica del Reactor Central según su vida (`frac` = hp/max_hp):
    alta: pulso estable y vapor suave periódico · <50%: chispas en las bobinas y luz interna intermitente ·
    <25%: luz de emergencia roja pulsante y columnas de humo oscuro."""
    cx, cy = center
    low, crit = frac < 0.5, frac < 0.25
    pulse = 0.5 + 0.5 * math.sin(t * 2.2)
    flick = 1.0
    if low:                                                                          # parpadeo intermitente de la luz interna
        flick = (0.18, 0.55, 1.0, 1.0)[((int(t * 11) * 2654435761) >> 7) & 3]
    color = (255, 56, 44) if crit else (0, 225, 255)
    if crit:
        pulse = 0.5 + 0.5 * math.sin(t * 6.5)
    level = round(pulse * 6 * flick)
    body = _puff(13, color, int((40 + 10 * level) * flick) // 5 * 5)                 # cámara translúcida
    surface.blit(body, body.get_rect(center=center))
    glow = _glow(20 + level * 2, color, 200)
    surface.blit(glow, glow.get_rect(center=center), special_flags=pygame.BLEND_ADD)
    core = _glow(7, (255, 200, 190) if crit else (210, 255, 255), 255)
    surface.blit(core, core.get_rect(center=center), special_flags=pygame.BLEND_ADD)
    if not low:                                                                      # vapor suave cada ~4,5 s
        phase = t % 4.5
        if phase < 1.8:
            _blit_puffs(surface, center, (214, 226, 236), phase / 1.8 * 1.35, 4, 28, 10, 120, 0.0, False)
    else:                                                                            # chispas en las bobinas laterales
        key = int(t * 16)
        for side in (-1, 1):
            rng = random.Random(key * 7 + side)
            if rng.random() < 0.6:
                ox, oy = cx + side * 21, cy - 19
                for _ in range(rng.randint(2, 3)):
                    ex, ey = ox + rng.randint(-6, 6), oy + rng.randint(-8, 2)
                    pygame.draw.line(surface, (255, 236, 150), (ox, oy), (ex, ey), 1)
                    pygame.draw.circle(surface, (255, 255, 255), (ex, ey), 1)
    if crit:
        _blit_puffs(surface, center, (26, 26, 30), t * 0.45, 5, 52, 13, 170, 0.7, True)   # columnas de humo oscuro
        k = 0.5 + 0.5 * math.sin(t * 7)
        lamp = _glow(12, (255, 40, 30), int(120 + 135 * k))
        for dx in (-22, 21):                                                         # luces de emergencia
            surface.blit(lamp, lamp.get_rect(center=(cx + dx, cy - 22)), special_flags=pygame.BLEND_ADD)
            pygame.draw.circle(surface, (255, int(60 + 120 * k), 50), (cx + dx, cy - 22), 3)


@lru_cache(maxsize=None)
def _generator(size, pal):
    """Generador industrial: caja oscura con dos turbinas laterales y acentos amarillos."""
    w, h = size
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, (74, 74, 78), (46, 46, 50))
    _bevel(img, img.get_rect(), width=2)
    pygame.draw.rect(img, (255, 204, 0), img.get_rect(), 1)
    for cx in (10, w - 11):                                                      # alojamientos de turbina
        pygame.draw.circle(img, (20, 20, 22), (cx, h // 2), 8)
        pygame.draw.circle(img, (130, 130, 136), (cx, h // 2), 8, 2)
    pygame.draw.rect(img, (28, 28, 30), (w // 2 - 4, 8, 8, h - 16))              # panel central
    _hazard(img, (w // 2 - 4, h - 12, 8, 4), (255, 204, 0))
    _hazard(img, (w // 2 - 4, 8, 8, 4), (255, 204, 0))
    for bx, by in ((4, 4), (w - 5, 4), (4, h - 5), (w - 5, h - 5)):
        _bolt(img, (bx, by), 1)
    return img


def render_generator(size, pal="ally"):
    return _generator(tuple(size), pal).copy()


def draw_generator_turbines(surface, center, t, flash=0.0):
    """Turbinas que giran (aspas amarillas) y piloto que parpadea (`flash` > 0: destello fuerte, sin uso en el juego)."""
    cx, cy = center
    for dx, sign in ((-10, 1), (10, -1)):
        for i in range(3):
            a = t * 7 * sign + i * math.tau / 3
            pygame.draw.line(surface, (255, 204, 0), (cx + dx, cy),
                             (cx + dx + math.cos(a) * 6, cy + math.sin(a) * 6), 2)
        pygame.draw.circle(surface, (50, 50, 54), (cx + dx, cy), 2)
    if flash > 0 or pygame.time.get_ticks() % 1000 < 500:
        pygame.draw.circle(surface, (255, 220, 60), (cx, cy), 2)
        if flash > 0:
            glow = _glow(20, (255, 210, 40), 220)
            surface.blit(glow, glow.get_rect(center=center), special_flags=pygame.BLEND_ADD)


def draw_energy_core(surface, center, pal, t, radius, powered=True, orbit=True):
    """Núcleo de energía pulsante (resplandor aditivo) con chispas orbitando."""
    p = PALETTES[pal]
    if not powered:
        pygame.draw.circle(surface, (40, 20, 26), center, max(2, radius // 3))
        return
    pulse = 0.5 + 0.5 * math.sin(t * 3.0)
    level = round(pulse * 6)                                                    # niveles discretos -> caché
    rad = int(radius * (0.85 + 0.35 * level / 6))
    glow = _glow(rad * 2, p["glow"], 220)
    surface.blit(glow, glow.get_rect(center=center), special_flags=pygame.BLEND_ADD)
    core_r = max(2, round(radius * (0.30 + 0.10 * pulse)))
    pygame.draw.circle(surface, p["glow"], center, core_r + 1)
    pygame.draw.circle(surface, p["core"], center, core_r)
    if orbit:
        for i in range(3):
            a = t * 2.2 + i * math.tau / 3
            pos = (center[0] + math.cos(a) * radius * 0.62, center[1] + math.sin(a) * radius * 0.62)
            pygame.draw.circle(surface, p["core"], (round(pos[0]), round(pos[1])), 2)


# ------------------------------------------------------------------ pilón ----
@lru_cache(maxsize=None)
def _pylon(size, pal):
    """Torre hexagonal gris oscuro con 6 líneas de energía cian que irradian en la base."""
    w, h = size
    c = (w // 2, h // 2)
    img = pygame.Surface(size, pygame.SRCALPHA)
    pts = _hex(c, 17, rot=0)
    pygame.draw.polygon(img, (30, 30, 32), pts)
    pygame.draw.polygon(img, (58, 58, 58), _hex(c, 15, rot=0))
    pygame.draw.polygon(img, (104, 104, 108), _hex(c, 15, rot=0), 1)
    for i in range(6):                                                           # líneas de energía radiantes
        a = i * math.pi / 3 + math.pi / 6
        pygame.draw.line(img, (0, 190, 170), (c[0] + math.cos(a) * 7, c[1] + math.sin(a) * 7),
                         (c[0] + math.cos(a) * 15, c[1] + math.sin(a) * 15), 1)
    for vx, vy in pts[::2]:
        _bolt(img, (c[0] + (vx - c[0]) * 0.8, c[1] + (vy - c[1]) * 0.8), 1)
    pygame.draw.circle(img, (30, 30, 32), (c[0], c[1] + 2), 6)
    return img


def render_pylon(size, pal="ally"):
    return _pylon(tuple(size), pal).copy()


def draw_pylon_top(surface, center, pal, t, powered):
    """Antena puntiaguda (triángulo largo cian) que parpadea en la punta cuando el pilón está energizado."""
    cx, cy = center
    col = (0, 255, 200) if powered else (90, 26, 34)
    tri = [(cx, cy - 17), (cx - 4, cy + 2), (cx + 4, cy + 2)]
    pygame.draw.polygon(surface, tuple(v // 3 for v in col), tri)
    pygame.draw.polygon(surface, col, tri, 1)
    pygame.draw.line(surface, col, (cx, cy - 15), (cx, cy), 1)
    if powered and pygame.time.get_ticks() % 1000 < 500:
        glow = _glow(11, (0, 255, 220), 230)
        surface.blit(glow, glow.get_rect(center=(cx, cy - 16)), special_flags=pygame.BLEND_ADD)
        pygame.draw.circle(surface, (230, 255, 255), (cx, cy - 16), 2)


def draw_arc(surface, a, b, t, color, seed=0, bright=True):
    """Arco eléctrico entre dos puntos: polilínea con temblor y un pulso de energía que viaja."""
    a = pygame.math.Vector2(a)
    b = pygame.math.Vector2(b)
    d = b - a
    dist = d.length()
    if dist < 4:
        return
    n = max(3, int(dist // 14))
    perp = pygame.math.Vector2(-d.y, d.x) / dist
    pts = [a]
    for i in range(1, n):
        k = i / n
        jitter = math.sin(t * 17 + seed * 1.7 + i * 2.3) * 4 + math.sin(t * 29 + i * 5.1 + seed) * 2
        pts.append(a + d * k + perp * jitter)
    pts.append(b)
    if bright:
        pygame.draw.lines(surface, tuple(v // 3 for v in color), False, pts, 4)    # halo
    pygame.draw.lines(surface, color, False, pts, 2 if bright else 1)
    if bright:
        k = (t * 0.9 + seed * 0.37) % 1.0
        head = a + d * k
        pygame.draw.circle(surface, (225, 255, 255), (round(head.x), round(head.y)), 3)


# -------------------------------------------------------------- extractor ----
@lru_cache(maxsize=None)
def _extractor(size, pal):
    p = PALETTES[pal]
    w, h = size
    c = (w // 2, h // 2)
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, STEEL_MID, STEEL)
    _bevel(img, img.get_rect(), width=2)
    pygame.draw.rect(img, p["accent"], img.get_rect(), 1)
    pygame.draw.circle(img, STEEL_DARK, c, 14)
    pygame.draw.circle(img, STEEL_LIGHT, c, 14, 2)
    pygame.draw.circle(img, (6, 10, 14), c, 11)
    _hazard(img, (4, 4, 14, 4), p["warn"])
    _hazard(img, (w - 18, h - 8, 14, 4), p["warn"])
    for bx, by in ((w - 6, 5), (5, h - 5)):
        _bolt(img, (bx, by), 2)
    return img


def render_extractor(size, pal="mining"):
    return _extractor(tuple(size), pal).copy()


def draw_drill(surface, center, pal, t, spinning):
    p = PALETTES[pal]
    base = t * 9 if spinning else 0.4
    for i in range(3):
        a = base + i * math.tau / 3
        tip = (center[0] + math.cos(a) * 10, center[1] + math.sin(a) * 10)
        pygame.draw.line(surface, STEEL_LIGHT, center, tip, 3)
        pygame.draw.line(surface, p["accent"] if spinning else STEEL, center, tip, 1)
    pygame.draw.circle(surface, p["glow"] if spinning else STEEL_MID, center, 3)
    pygame.draw.circle(surface, STEEL_DARK, center, 3, 1)


# ------------------------------------------------------ fábrica de drones ----
_FACTORY_CYAN, _FACTORY_PURPLE = (50, 180, 255), (200, 100, 255)


@lru_cache(maxsize=None)
def _factory(size):
    """Nave industrial de 2x2: tejado de placas, ventiladores, compuerta de hangar púrpura y plataforma de despegue cian."""
    w, h = size
    img = pygame.Surface(size, pygame.SRCALPHA)
    _gradient(img, (70, 76, 92), (40, 44, 56))
    _bevel(img, img.get_rect(), width=3)
    pygame.draw.rect(img, _FACTORY_CYAN, img.get_rect(), 1)
    for x in (w // 3, 2 * w // 3):                                               # juntas del tejado
        pygame.draw.line(img, (30, 34, 44), (x, 4), (x, h // 2 - 4))
    for cx in (16, w - 17):                                                      # ventiladores
        pygame.draw.circle(img, (20, 22, 28), (cx, 17), 9)
        pygame.draw.circle(img, (120, 126, 140), (cx, 17), 9, 1)
        for a in range(3):
            ang = a * 2.094
            pygame.draw.line(img, (90, 96, 110), (cx, 17), (cx + math.cos(ang) * 7, 17 + math.sin(ang) * 7), 2)
    door = pygame.Rect(w // 2 - 22, h - 34, 44, 28)                              # compuerta del hangar
    pygame.draw.rect(img, (26, 16, 36), door)
    for y in range(door.top + 3, door.bottom - 1, 4):
        pygame.draw.line(img, (110, 60, 150), (door.left + 2, y), (door.right - 3, y))
    pygame.draw.rect(img, _FACTORY_PURPLE, door, 2)
    pygame.draw.circle(img, (12, 30, 44), (w // 2, h // 2 - 8), 13)              # plataforma de despegue
    pygame.draw.circle(img, _FACTORY_CYAN, (w // 2, h // 2 - 8), 13, 2)
    pygame.draw.line(img, _FACTORY_CYAN, (w // 2 - 6, h // 2 - 8), (w // 2 + 6, h // 2 - 8), 1)
    pygame.draw.line(img, _FACTORY_CYAN, (w // 2, h // 2 - 14), (w // 2, h // 2 - 2), 1)
    _hazard(img, (6, h - 10, 18, 5), C.YELLOW)
    _hazard(img, (w - 24, h - 10, 18, 5), C.YELLOW)
    for bx, by in ((5, 5), (w - 6, 5), (5, h - 6), (w - 6, h - 6)):
        _bolt(img, (bx, by))
    return img


def render_factory(size):
    return _factory(tuple(size)).copy()


_DRONE_COLORS = {"recon": (100, 200, 255), "attack": (255, 100, 100), "bomber": (255, 170, 60), "trooper": (120, 255, 130)}


def draw_factory_status(surface, rect, t, build_left_frac, progress, current, queued, active):
    """Andamio y barra de ensamblaje; después, barra de fabricación con el color del dron y puntos de la cola."""
    if build_left_frac > 0:                                                      # en construcción: franjas que avanzan
        scaff = pygame.Surface(rect.size, pygame.SRCALPHA)
        for x in range(-rect.h, rect.w + rect.h, 14):
            off = int(t * 20) % 14
            pygame.draw.line(scaff, (255, 210, 60, 70), (x + off, rect.h), (x + off + rect.h, 0), 4)
        surface.blit(scaff, rect)
        bar = pygame.Rect(rect.left + 6, rect.bottom - 8, rect.w - 12, 5)
        pygame.draw.rect(surface, (30, 30, 30), bar)
        pygame.draw.rect(surface, C.YELLOW, (bar.x, bar.y, int(bar.w * (1 - build_left_frac)), bar.h))
        return
    pad = (rect.centerx, rect.centery - 8)
    if current is not None:
        color = _DRONE_COLORS.get(current, C.WHITE)
        if active:
            pulse = 0.5 + 0.5 * math.sin(t * 6)
            pygame.draw.circle(surface, color, pad, 5 + int(3 * pulse))
        bar = pygame.Rect(rect.left, rect.top - 11, rect.w, 6)                    # mini-barra de fabricación sobre la Fábrica
        pygame.draw.rect(surface, (30, 30, 30), bar)
        pygame.draw.rect(surface, color if active else (90, 90, 90), (bar.x, bar.y, int(bar.w * max(0.0, min(1.0, progress))), bar.h))
        pygame.draw.rect(surface, C.WHITE if active else C.RED, bar, 1)            # marco rojo: parada sin energía
    for i in range(queued):                                                      # cola de producción
        pygame.draw.circle(surface, C.WHITE, (rect.left + 10 + i * 8, rect.top + 12), 2)


# ------------------------------------------------- fantasma de colocación ----
_GHOST_PAL = {"tower": "light", "balista": "heavy"}


def _ghost_base(btype, size):
    if btype == "wall":
        return render_wall(size)
    if btype == "compuerta":
        return render_gate(size, False)
    if btype in _GHOST_PAL:
        img = render_tower_base(size, _GHOST_PAL[btype])
        draw_turret_head(img, (size[0] // 2, size[1] // 2), 0, _GHOST_PAL[btype], True, 0, btype)
        return img
    maker = {"pylon": render_pylon, "extractor": render_extractor,
             "foco": render_foco, "fabrica": render_factory}.get(btype)
    return maker(size) if maker is not None else None


@lru_cache(maxsize=None)
def ghost_image(btype, size, color):
    """Silueta tridimensional translúcida de la estructura (bloque con su cara frontal y borde de color)."""
    base = _ghost_base(btype, size)
    if base is None:
        return None
    w, h = size
    out = pygame.Surface((w, h + 4), pygame.SRCALPHA)
    side = base.copy()                                                         # cara inferior: copia oscurecida bajo el bloque
    side.fill((60, 60, 60, 255), special_flags=pygame.BLEND_RGBA_MULT)
    side.fill((color[0] // 4, color[1] // 4, color[2] // 4, 0), special_flags=pygame.BLEND_RGBA_ADD)
    side.set_alpha(110)
    out.blit(side, (0, 4))
    top = base.copy()
    top.fill((color[0] // 3, color[1] // 3, color[2] // 3, 0), special_flags=pygame.BLEND_RGBA_ADD)
    top.set_alpha(175)
    out.blit(top, (0, 0))
    outline = pygame.mask.from_surface(base).outline()
    if len(outline) > 2:
        pygame.draw.lines(out, (*color, 255), True, outline, 2)
    return out


# ------------------------------------------------------------- Búnker de Mando ----
@lru_cache(maxsize=None)
def _bunker(w, h):
    """Búnker de hormigón con losa superior biselada, placas de acero, antena y una puerta blindada con luz cian."""
    img = pygame.Surface((w, h), pygame.SRCALPHA)
    body = pygame.Rect(4, 10, w - 8, h - 16)
    pygame.draw.rect(img, (0, 0, 0, 90), body.move(3, 5), border_radius=6)
    pygame.draw.rect(img, (54, 58, 66), body, border_radius=5)
    top = pygame.Rect(body.x, body.y, body.w, body.h // 2 - 2)
    pygame.draw.rect(img, (78, 84, 96), top, border_radius=5)                            # losa superior
    pygame.draw.line(img, (120, 128, 144), (top.x + 4, top.y + 1), (top.right - 4, top.y + 1))
    pygame.draw.line(img, (36, 38, 46), (top.x + 3, top.bottom), (top.right - 3, top.bottom), 2)
    for x in range(top.x + 14, top.right - 8, 20):                                       # juntas de las placas
        pygame.draw.line(img, (50, 54, 62), (x, top.y + 4), (x, top.bottom - 3))
    for vx in (top.x + 12, top.right - 24):                                              # rejillas de ventilación
        for k in range(3):
            pygame.draw.line(img, (28, 30, 36), (vx, top.y + 12 + k * 4), (vx + 12, top.y + 12 + k * 4))
    door = pygame.Rect(0, 0, w // 3, h // 3)
    door.midbottom = (w // 2, body.bottom - 3)
    pygame.draw.rect(img, (18, 20, 26), door, border_radius=3)
    pygame.draw.rect(img, (110, 118, 134), door, 2, border_radius=3)
    pygame.draw.rect(img, (0, 150, 190), door.inflate(-12, -14).move(0, -3), border_radius=2)   # ventanilla de la puerta
    pygame.draw.line(img, (0, 230, 255), (door.centerx, door.y + 4), (door.centerx, door.bottom - 3))
    for k in range(6):                                                                   # franja de advertencia al pie
        x0 = body.x + 8 + k * ((body.w - 16) // 6)
        pygame.draw.polygon(img, (206, 172, 26), [(x0, body.bottom - 1), (x0 + 8, body.bottom - 1), (x0 + 12, body.bottom - 7), (x0 + 4, body.bottom - 7)])
    pygame.draw.line(img, (150, 156, 170), (body.right - 14, body.y), (body.right - 14, 1), 2)      # antena
    pygame.draw.circle(img, (200, 60, 60), (body.right - 14, 2), 2)
    for cx, cy in ((body.x + 5, body.y + 5), (body.right - 6, body.y + 5), (body.x + 5, body.bottom - 6), (body.right - 6, body.bottom - 6)):
        pygame.draw.circle(img, (150, 156, 170), (cx, cy), 2)                            # pernos
    pygame.draw.rect(img, (20, 22, 28), body, 2, border_radius=5)
    return img


def render_bunker(size):
    return _bunker(int(size[0]), int(size[1])).copy()


def draw_bunker_lamp(surface, rect, t):
    """Luz de la antena del Búnker: parpadea en rojo."""
    if int(t * 1.6) % 2 == 0:
        pygame.draw.circle(surface, (255, 80, 80), (rect.right - 18, rect.y + 2), 3)


@lru_cache(maxsize=None)
def _bunker_site(w, h):
    """Sitio de obra: andamio sobre la huella 3x3 con marco de peligro, postes en las esquinas, vigas en cruz y materiales."""
    img = pygame.Surface((w, h), pygame.SRCALPHA)
    pygame.draw.rect(img, (14, 16, 22, 200), (0, 0, w, h), border_radius=4)
    rng = random.Random(w * 13 + h)
    for _ in range(14):                                                                  # losa a medio hacer: grietas y manchas
        x, y = rng.randint(6, w - 12), rng.randint(6, h - 12)
        pygame.draw.rect(img, (28, 31, 38, 220), (x, y, rng.randint(10, 22), rng.randint(6, 12)))
    seg = 12
    for i in range(0, w, seg):                                                           # marco de franjas amarillo/negro
        c = (206, 172, 26) if (i // seg) % 2 == 0 else (16, 16, 18)
        pygame.draw.rect(img, c, (i, 0, seg, 6))
        pygame.draw.rect(img, c, (i, h - 6, seg, 6))
    for i in range(0, h, seg):
        c = (206, 172, 26) if (i // seg) % 2 == 0 else (16, 16, 18)
        pygame.draw.rect(img, c, (0, i, 6, seg))
        pygame.draw.rect(img, c, (w - 6, i, 6, seg))
    for a, b in (((8, 8), (w - 8, h - 8)), ((w - 8, 8), (8, h - 8))):                    # vigas en cruz
        pygame.draw.line(img, (20, 22, 28), (a[0], a[1] + 2), (b[0], b[1] + 2), 5)
        pygame.draw.line(img, (150, 108, 52), a, b, 3)
        pygame.draw.line(img, (190, 150, 90), (a[0], a[1] - 1), (b[0], b[1] - 1), 1)
    for cx, cy in ((8, 8), (w - 9, 8), (8, h - 9), (w - 9, h - 9)):                      # postes del andamio
        pygame.draw.rect(img, (20, 22, 28), (cx - 4, cy - 4, 9, 9))
        pygame.draw.rect(img, (140, 146, 160), (cx - 3, cy - 3, 7, 7))
    for k in range(3):                                                                   # tablones apilados
        pygame.draw.rect(img, (110, 78, 44), (w // 2 - 22, h // 2 + 8 + k * 5, 44, 4))
        pygame.draw.rect(img, (160, 120, 70), (w // 2 - 22, h // 2 + 8 + k * 5, 44, 1))
    return img


def render_bunker_site(size):
    return _bunker_site(int(size[0]), int(size[1])).copy()
