"""Arte y efectos de los recogibles del suelo (chatarra, núcleos de plasma, aleación, cajas de munición).

Todos los sprites se dibujan una sola vez y se cachean (variantes, destello, pulso, parpadeo): el coste por frame
es un blit por recogible. Los efectos puramente visuales (glow, vaivén, estela) viven en `PickupSprite.draw`,
así que `rect`, `pos` y la lógica de recogida/inventario no cambian.
"""
import math
import random

import pygame
from pygame.math import Vector2

from src.entities import GameSprite

_ZERO = Vector2()
_rng = random.Random()               # RNG propio: no altera la secuencia aleatoria del juego (ni de los tests)

DIM_ALPHA = 90                       # parpadeo previo a desaparecer
SHINE_FRAMES = 8
SHINE_TIME = 0.5                     # segundos que tarda el destello en barrer el sprite
TRAIL_LIFE = 0.35
TRAIL_MAX = 12

_CACHE = {}


def _cached(key, build):
    surf = _CACHE.get(key)
    if surf is None:
        surf = _CACHE[key] = build()
    return surf


def _surf(size):
    return pygame.Surface((size, size), pygame.SRCALPHA)


# ------------------------------------------------------------------ piezas de chatarra
def _plate(img, pts, base=(120, 126, 134)):
    """Placa metálica abollada: bisel claro arriba/izquierda, hendidura y mancha de óxido."""
    pygame.draw.polygon(img, base, pts)
    pygame.draw.polygon(img, (52, 56, 64), pts, 1)
    pygame.draw.line(img, (196, 202, 210), pts[0], pts[1], 1)
    pygame.draw.line(img, (170, 176, 184), pts[0], pts[-1], 1)
    cx = sum(p[0] for p in pts) // len(pts)
    cy = sum(p[1] for p in pts) // len(pts)
    pygame.draw.line(img, (78, 84, 92), (cx - 4, cy - 1), (cx + 3, cy + 3), 2)       # abolladura
    pygame.draw.line(img, (166, 172, 180), (cx - 4, cy), (cx + 3, cy + 4), 1)
    pygame.draw.circle(img, (128, 76, 44), (cx + 3, cy - 3), 2)                      # óxido
    pygame.draw.circle(img, (96, 58, 34), (cx - 5, cy + 3), 1)


def _coil(img, c, r):
    """Bobina de cable de cobre rojizo con la punta suelta."""
    cols = [(86, 34, 20), (170, 80, 50), (208, 116, 72), (150, 62, 38), (196, 98, 60)]
    for i, col in enumerate(cols[: max(2, r // 2 + 1)]):
        w, h = 2 * (r - i), round(1.5 * (r - i))
        pygame.draw.ellipse(img, col, (c[0] - (r - i), c[1] - h // 2, w, h))
    pygame.draw.ellipse(img, (40, 20, 14), (c[0] - 1, c[1] - 1, 3, 2))
    pygame.draw.line(img, (236, 154, 108), (c[0] - r + 2, c[1] - 2), (c[0] - 1, c[1] - r // 2 - 1), 1)   # brillo
    pygame.draw.lines(img, (190, 90, 54), False,
                      [(c[0] + r - 1, c[1] + 1), (c[0] + r + 2, c[1] + 4), (c[0] + r, c[1] + 8)], 1)


def _nut(img, c, r):
    """Tuerca hexagonal oxidada."""
    pts = [(c[0] + round(r * math.cos(math.radians(60 * i))), c[1] + round(r * math.sin(math.radians(60 * i))))
           for i in range(6)]
    pygame.draw.polygon(img, (146, 82, 42), pts)
    pygame.draw.polygon(img, (82, 44, 24), pts, 1)
    pygame.draw.circle(img, (28, 20, 16), c, max(1, round(r * 0.45)))
    pygame.draw.line(img, (204, 136, 84), pts[4], pts[5], 1)
    img.set_at((c[0] + r // 2, c[1] + r // 2), (90, 48, 26))


def _bolt(img, a, b):
    """Perno oxidado: vástago con rosca y cabeza."""
    pygame.draw.line(img, (118, 96, 74), a, b, 3)
    pygame.draw.line(img, (168, 140, 108), a, b, 1)
    pygame.draw.circle(img, (140, 84, 46), a, 3)
    pygame.draw.circle(img, (74, 42, 24), a, 3, 1)


def _scrap_base(variant):
    img = _surf(34)
    pygame.draw.ellipse(img, (0, 0, 0, 70), (3, 24, 28, 9))                          # sombra de contacto
    if variant == 0:
        _plate(img, [(3, 14), (20, 10), (24, 22), (6, 27)])
        _coil(img, (24, 11), 7)
        _nut(img, (24, 25), 5)
        _bolt(img, (9, 7), (13, 12))
    elif variant == 1:
        _plate(img, [(4, 8), (18, 6), (21, 16), (6, 18)], (110, 116, 126))
        _plate(img, [(10, 17), (28, 14), (31, 26), (13, 29)])
        _coil(img, (25, 8), 5)
        _nut(img, (6, 26), 4)
        _bolt(img, (7, 22), (7, 28))
    else:
        _plate(img, [(8, 20), (28, 17), (30, 27), (10, 30)], (126, 132, 140))
        _coil(img, (15, 13), 8)
        _nut(img, (28, 9), 4)
        _nut(img, (5, 26), 3)
        _bolt(img, (22, 6), (27, 13))
    return img


# ------------------------------------------------------------------ destello especular
def _apply_shine(img, base, k, alpha=150, width=7):
    """Banda diagonal blanca que barra el sprite (solo sobre sus píxeles opacos)."""
    w, h = base.get_size()
    band = pygame.Surface((w, h), pygame.SRCALPHA)
    s = -width + (w + h + 2 * width) * (k + 0.5) / SHINE_FRAMES
    for y in range(h):
        for x in range(w):
            d = abs((x + y) - s)
            if d < width:
                band.set_at((x, y), (255, 255, 255, int(alpha * (1 - d / width))))
    mask = pygame.mask.from_surface(base, 10).to_surface(setcolor=(255, 255, 255, 255), unsetcolor=(0, 0, 0, 0))
    band.blit(mask, (0, 0), special_flags=pygame.BLEND_RGBA_MULT)
    img.blit(band, (0, 0))


def shine_index(t, offset=0.0, period=2.0):
    """Frame del destello (−1 = sin destello): barre durante SHINE_TIME s cada `period` s."""
    ph = (t + offset) % period
    return -1 if ph >= SHINE_TIME else min(SHINE_FRAMES - 1, int(ph / SHINE_TIME * SHINE_FRAMES))


def _finish(base, shine, dim):
    img = base.copy()
    if shine >= 0:
        _apply_shine(img, base, shine)
    if dim:
        img.fill((255, 255, 255, DIM_ALPHA), special_flags=pygame.BLEND_RGBA_MULT)
    return img


def scrap_frame(variant, shine=-1, dim=False):
    return _cached(("scrap", variant, shine, dim),
                   lambda: _finish(_cached(("scrap_base", variant), lambda: _scrap_base(variant)), shine, dim))


# ------------------------------------------------------------------ núcleo de plasma
PULSE_LEVELS = 8


def _core_base(level, extra):
    img = _surf(34)
    k = level / (PULSE_LEVELS - 1)
    pygame.draw.rect(img, (22, 26, 34), (11, 12, 12, 10))                            # contacto interior oscuro
    glass = (0, int(150 + 60 * k), int(210 + 40 * k))
    pygame.draw.rect(img, (0, 64, 100), (11, 11, 12, 12), border_radius=3)           # cristal central
    pygame.draw.ellipse(img, glass, (12, 12, 10, 10))
    r = 2 + round(2 * k)
    pygame.draw.circle(img, (int(120 + 100 * k), 250, 255), (17, 17), r)             # núcleo de plasma
    pygame.draw.line(img, (210, 250, 255), (13, 12), (20, 12), 1)                    # reflejo del cristal
    for x0 in (4, 22):                                                               # blindaje oscuro de los extremos
        pygame.draw.rect(img, (40, 46, 56), (x0, 10, 8, 14), border_radius=3)
        pygame.draw.rect(img, (16, 20, 26), (x0, 10, 8, 14), 1, border_radius=3)
        pygame.draw.line(img, (104, 114, 128), (x0 + 2, 11), (x0 + 5, 11), 1)
        pygame.draw.line(img, (70, 78, 92), (x0 + 1, 17), (x0 + 6, 17), 1)
        pygame.draw.circle(img, (150, 160, 174), (x0 + 4, 14), 1)
        pygame.draw.circle(img, (150, 160, 174), (x0 + 4, 20), 1)
    for i in range(extra):                                                           # varios núcleos juntos: puntos extra
        pygame.draw.circle(img, (150, 245, 255), (6 + i * 5, 29), 2)
    return img


def core_frame(level, extra=0, dim=False):
    return _cached(("core", level, extra, dim),
                   lambda: _finish(_cached(("core_base", level, extra), lambda: _core_base(level, extra)), -1, dim))


def core_glow(level):
    """Halo cian translúcido de ~20 px de radio sobre el suelo."""
    def build():
        img = pygame.Surface((40, 40), pygame.SRCALPHA)
        peak = 34 + 44 * level / (PULSE_LEVELS - 1)
        for r in range(20, 0, -1):
            pygame.draw.circle(img, (0, 200, 255, int(peak * (1 - r / 20) ** 1.3)), (20, 20), r)
        return img
    return _cached(("core_glow", level), build)


# ------------------------------------------------------------------ aleación militar
def _brush(img, rect, light, dark, seed):
    """Acero cepillado: líneas horizontales finas alternadas con vetas claras."""
    rng = random.Random(seed)
    x0, y0, w, h = rect
    for y in range(y0, y0 + h):
        pygame.draw.line(img, light if (y - y0) % 2 == 0 else dark, (x0, y), (x0 + w - 1, y))
    for _ in range(max(2, w // 5)):
        y = rng.randrange(y0, y0 + h)
        x = rng.randrange(x0, x0 + w - 4)
        pygame.draw.line(img, (170, 178, 188), (x, y), (x + rng.randint(2, 5), y))


def _slab(img, x, y, w, h, top_h, seed):
    """Lingote en perspectiva: cara superior, frontal cepillada y lateral oscuro."""
    top = [(x + top_h, y), (x + w + top_h, y), (x + w, y + top_h), (x, y + top_h)]
    pygame.draw.polygon(img, (150, 158, 168), top)
    pygame.draw.polygon(img, (96, 104, 114), [(x + w, y + top_h), (x + w + top_h, y), (x + w + top_h, y + h - 1),
                                                (x + w, y + top_h + h - 1)])
    _brush(img, (x, y + top_h, w, h), (104, 112, 122), (84, 92, 102), seed)
    pygame.draw.polygon(img, (30, 34, 40), top, 1)
    pygame.draw.rect(img, (30, 34, 40), (x, y + top_h, w, h), 1)
    pygame.draw.line(img, (248, 250, 255), top[0], top[1], 1)                        # reflejo cromado en los bordes
    pygame.draw.line(img, (226, 232, 240), top[0], top[3], 1)
    pygame.draw.line(img, (236, 240, 248), (x + 1, y + top_h + 1), (x + 1, y + top_h + h - 2), 1)
    pygame.draw.line(img, (120, 128, 138), (x + w, y + top_h), (x + w + top_h, y), 1)


def _alloy_base():
    img = _surf(34)
    pygame.draw.ellipse(img, (0, 0, 0, 80), (1, 25, 32, 8))
    _slab(img, 2, 15, 25, 8, 5, 1)                                                   # lingote inferior
    _slab(img, 4, 4, 22, 7, 5, 2)                                                    # lingote superior
    for x in range(2, 27):                                                           # franja amarilla de advertencia
        for y in range(25, 29):
            pygame.draw.rect(img, (244, 200, 24) if ((x + y) // 3) % 2 == 0 else (24, 24, 24), (x, y, 1, 1))
    pygame.draw.rect(img, (30, 34, 40), (2, 25, 25, 4), 1)
    pygame.draw.rect(img, (46, 50, 58), (13, 9, 4, 20))                              # fleje con precinto industrial
    pygame.draw.rect(img, (22, 24, 30), (13, 9, 4, 20), 1)
    pygame.draw.circle(img, (210, 212, 218), (15, 19), 2)                            # sello de plomo
    pygame.draw.circle(img, (90, 94, 102), (15, 19), 2, 1)
    for gx, gy in ((5, 5), (30, 9)):                                                 # destellos cromados puntuales
        pygame.draw.line(img, (255, 255, 255), (gx - 2, gy), (gx + 2, gy), 1)
        pygame.draw.line(img, (255, 255, 255), (gx, gy - 2), (gx, gy + 2), 1)
    return img


def alloy_frame(shine=-1, dim=False):
    return _cached(("alloy", shine, dim),
                   lambda: _finish(_cached(("alloy_base",), _alloy_base), shine, dim))


# ------------------------------------------------------------------ caja de munición
LED_LEVELS = 4


def _ammo_base(led):
    img = _surf(30)
    pygame.draw.rect(img, (78, 88, 44), (2, 6, 26, 21), border_radius=3)             # contenedor hermético
    pygame.draw.rect(img, (100, 112, 58), (2, 6, 26, 6), border_radius=3)            # tapa
    pygame.draw.line(img, (36, 42, 24), (3, 12), (26, 12), 1)                        # junta de la tapa
    pygame.draw.rect(img, (34, 40, 22), (2, 6, 26, 21), 1, border_radius=3)
    pygame.draw.line(img, (140, 154, 82), (4, 7), (25, 7), 1)                        # brillo del borde
    pygame.draw.rect(img, (50, 54, 58), (11, 3, 8, 3))                               # asa
    for x in (6, 17):                                                                # cierres
        pygame.draw.rect(img, (150, 156, 162), (x, 10, 5, 4))
        pygame.draw.rect(img, (50, 54, 58), (x, 10, 5, 4), 1)
    for i in range(3):                                                               # relieve de cartuchos
        x = 7 + i * 6
        pygame.draw.rect(img, (62, 72, 34), (x, 18, 4, 7))                           # casquillo hundido
        pygame.draw.line(img, (128, 142, 72), (x, 18), (x, 24), 1)                   # luz a la izquierda
        pygame.draw.line(img, (40, 46, 26), (x + 3, 18), (x + 3, 24), 1)             # sombra a la derecha
        pygame.draw.rect(img, (190, 150, 60), (x + 1, 15, 2, 3))                     # punta de bala
        img.set_at((x + 1, 15), (240, 206, 110))
    k = led / (LED_LEVELS - 1)
    pygame.draw.circle(img, (20, 28, 18), (24, 20), 3)                               # LED indicador frontal
    pygame.draw.circle(img, (int(20 + 80 * k), int(110 + 145 * k), int(40 + 80 * k)), (24, 20), 2)
    if led == LED_LEVELS - 1:
        img.set_at((23, 19), (230, 255, 230))
        pygame.draw.circle(img, (80, 255, 120, 70), (24, 20), 5, 1)
    return img


def _medkit_base(led):
    img = _surf(30)
    pygame.draw.ellipse(img, (0, 0, 0, 80), (2, 24, 26, 6))                         # sombra de contacto
    pygame.draw.rect(img, (214, 218, 222), (3, 7, 24, 19), border_radius=4)          # maletín blanco
    pygame.draw.rect(img, (236, 240, 244), (3, 7, 24, 6), border_radius=4)           # tapa con brillo
    pygame.draw.line(img, (150, 156, 162), (4, 13), (25, 13), 1)                     # junta de la tapa
    pygame.draw.rect(img, (110, 116, 124), (3, 7, 24, 19), 1, border_radius=4)
    pygame.draw.rect(img, (70, 74, 80), (11, 4, 8, 3))                               # asa
    pygame.draw.rect(img, (206, 34, 40), (13, 14, 4, 10))                            # cruz roja
    pygame.draw.rect(img, (206, 34, 40), (10, 17, 10, 4))
    pygame.draw.line(img, (250, 110, 110), (13, 14), (13, 23), 1)                    # luz en la cruz
    k = led / (LED_LEVELS - 1)
    pygame.draw.circle(img, (60, 20, 20), (23, 10), 2)                               # LED de estado que late
    pygame.draw.circle(img, (int(120 + 135 * k), int(30 + 60 * k), int(30 + 60 * k)), (23, 10), 1)
    return img


def medkit_frame(led, dim=False):
    return _cached(("medkit", led, dim),
                   lambda: _finish(_cached(("medkit_base", led), lambda: _medkit_base(led)), -1, dim))


def ammo_frame(led, dim=False):
    return _cached(("ammo", led, dim),
                   lambda: _finish(_cached(("ammo_base", led), lambda: _ammo_base(led)), -1, dim))


# ------------------------------------------------------------------ estela de micropartículas
def _dot(color, level):
    def build():
        img = pygame.Surface((5, 5), pygame.SRCALPHA)
        r = 2 if level == 2 else 1
        pygame.draw.circle(img, (*color, (60, 120, 200)[level]), (2, 2), r)
        return img
    return _cached(("dot", color, level), build)


# ------------------------------------------------------------------ base de los recogibles
class PickupSprite(GameSprite):
    """Recogible del suelo con estela al ser atraído, glow y vaivén opcionales (solo visuales)."""
    layer = 0
    trail_color = (255, 255, 255)
    bob_amp = 0                       # px de vaivén vertical (onda senoidal)
    bob_speed = 3.0
    t = 0.0

    def _fx_init(self):
        self._trail = []              # [x, y, edad]

    def _fx_step(self, dt, magnetized):
        trail = self._trail
        for p in trail:
            p[2] += dt
        if trail and trail[0][2] >= TRAIL_LIFE:
            trail[:] = [p for p in trail if p[2] < TRAIL_LIFE]
        if magnetized and len(trail) < TRAIL_MAX and _rng.random() < 0.75:
            trail.append([self.pos.x + _rng.uniform(-3, 3), self.pos.y + _rng.uniform(-3, 3), 0.0])

    def glow_surface(self):
        return None

    def bob(self):
        return round(self.bob_amp * math.sin(self.t * self.bob_speed)) if self.bob_amp else 0

    def draw(self, surface, offset=None):
        offset = _ZERO if offset is None else offset
        ox, oy = round(offset.x), round(offset.y)
        for x, y, age in self._trail:
            lvl = min(2, int((1 - age / TRAIL_LIFE) * 3))
            surface.blit(_dot(self.trail_color, lvl), (round(x) - ox - 2, round(y) - oy - 2))
        r = self.rect.move(-ox, -oy)
        glow = self.glow_surface()
        if glow is not None:
            surface.blit(glow, glow.get_rect(center=r.center))
        surface.blit(self.image, r.move(0, self.bob()))


# ------------------------------------------------------------------ componentes del chasis de AURA ----
PART_NAMES = ("Cabeza", "Torso", "Brazo izquierdo", "Brazo derecho", "Pierna izquierda", "Pierna derecha")
_ST, _ST_DK, _ST_LT, _CY = (92, 100, 118), (34, 38, 48), (178, 188, 204), (0, 230, 255)


def _limb(img, a, b, w, col=_ST):
    pygame.draw.line(img, _ST_DK, a, b, w + 2)
    pygame.draw.line(img, col, a, b, w)
    pygame.draw.line(img, _ST_LT, (a[0] - 1, a[1]), (b[0] - 1, b[1]), 1)


def _joint(img, c, r):
    pygame.draw.circle(img, _ST_DK, c, r + 1)
    pygame.draw.circle(img, (120, 130, 148), c, r)
    pygame.draw.circle(img, _CY, c, max(1, r // 2))


def _part_base(index):
    """Pieza del cuerpo de combate de AURA (36x36): cabeza, torso, brazos y piernas de acero con acentos cian."""
    img = _surf(36)
    side = index % 2 == 1                                   # los pares impares son el espejo (derecha)
    if index == 0:                                          # cabeza: casco, visor luminoso, antena y mandíbula
        pygame.draw.rect(img, _ST_DK, (14, 25, 8, 5))
        pygame.draw.ellipse(img, _ST_DK, (8, 5, 20, 20))
        pygame.draw.ellipse(img, _ST, (9, 6, 18, 18))
        pygame.draw.ellipse(img, _ST_LT, (11, 7, 8, 5))
        pygame.draw.rect(img, (10, 14, 20), (11, 13, 14, 6), border_radius=2)
        pygame.draw.rect(img, _CY, (12, 15, 12, 2))
        pygame.draw.rect(img, _ST_DK, (12, 21, 12, 4))
        pygame.draw.line(img, _ST_LT, (18, 6), (18, 1), 1)
        pygame.draw.circle(img, (255, 60, 220), (18, 1), 2)
    elif index == 1:                                        # torso: peto con reactor y hombreras
        pygame.draw.polygon(img, _ST_DK, [(6, 6), (30, 6), (27, 29), (9, 29)])
        pygame.draw.polygon(img, _ST, [(8, 7), (28, 7), (25, 27), (11, 27)])
        pygame.draw.polygon(img, _ST_LT, [(8, 7), (28, 7), (27, 10), (9, 10)])
        pygame.draw.circle(img, (10, 14, 20), (18, 16), 6)
        pygame.draw.circle(img, _CY, (18, 16), 4)
        pygame.draw.circle(img, (220, 255, 255), (18, 16), 2)
        for y in (22, 25):
            pygame.draw.line(img, _ST_DK, (12, y), (24, y), 1)
        for x in (5, 31):
            _joint(img, (x, 9), 3)
    else:
        if index in (2, 3):                                 # brazo: hombro, bíceps, codo, antebrazo y garra
            _joint(img, (11, 7), 4)
            _limb(img, (11, 8), (16, 19), 6)
            _joint(img, (16, 19), 3)
            _limb(img, (16, 20), (25, 29), 5)
            pygame.draw.polygon(img, _ST_DK, [(23, 28), (30, 28), (31, 33), (25, 33)])
            pygame.draw.line(img, _CY, (26, 31), (30, 31), 1)
        else:                                               # pierna: cadera, muslo, rodilla, espinilla y pie
            _joint(img, (15, 6), 4)
            _limb(img, (15, 8), (16, 18), 7)
            _joint(img, (16, 19), 4)
            _limb(img, (16, 21), (15, 29), 6)
            pygame.draw.rect(img, _ST_DK, (9, 28, 14, 5), border_radius=2)
            pygame.draw.rect(img, _ST, (10, 28, 12, 3))
            pygame.draw.line(img, _ST_LT, (10, 28), (21, 28), 1)
        if side:
            img = pygame.transform.flip(img, True, False)
    mask = pygame.mask.from_surface(img)                    # contorno oscuro para que se lea sobre cualquier suelo
    shadow = mask.to_surface(setcolor=(8, 8, 12, 255), unsetcolor=(0, 0, 0, 0))
    out = _surf(36)
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        out.blit(shadow, (dx, dy))
    out.blit(img, (0, 0))
    return out


PART_SIZE = 48                                               # las piezas se dibujan a 48 px: se leen mejor en el mapa


def part_frame(index, shine=-1):
    def build():
        frame = _finish(_cached(("part_base", index), lambda: _part_base(index)), shine, False)
        return pygame.transform.scale(frame, (PART_SIZE, PART_SIZE))
    return _cached(("part", index, shine), build)


def part_glow(level):
    """Halo magenta pulsante de la pieza (radio ~30 px)."""
    def build():
        img = pygame.Surface((60, 60), pygame.SRCALPHA)
        peak = 40 + 50 * level / (PULSE_LEVELS - 1)
        for r in range(30, 0, -1):
            pygame.draw.circle(img, (200, 60, 255, int(peak * (1 - r / 30) ** 1.2)), (30, 30), r)
        return img
    return _cached(("part_glow", level), build)
