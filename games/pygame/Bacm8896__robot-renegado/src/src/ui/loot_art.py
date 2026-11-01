"""Arte procedural del botín y las salidas: alijos (cajas blindadas), depósitos de chatarra y plataformas de extracción.

Todo se dibuja una vez y se cachea (`lru_cache`); por fotograma solo hay blits de superficies cacheadas y primitivas
sueltas (destellos, anillos), sin crear `Surface` nuevas."""
import math
import random
from functools import lru_cache

import pygame

STEEL = (96, 102, 114)
STEEL_DARK = (30, 33, 40)
STEEL_LIGHT = (170, 178, 192)
HAZARD = (196, 164, 26)

ACCENT = {"scrap": (212, 178, 24), "plasma": (0, 214, 244), "supply": (74, 206, 112), "module": (214, 96, 255)}
_SCRAP_TONES = ((128, 66, 32), (104, 52, 28), (92, 94, 104), (70, 72, 80), (150, 112, 40), (60, 56, 58))
PAD_FRAMES = 16


def _mul(color, k):
    return tuple(max(0, min(255, int(c * k))) for c in color)


def _plate(cx, cy, w, h, angle):
    ca, sa = math.cos(angle), math.sin(angle)
    return [(cx + dx * ca - dy * sa, cy + dx * sa + dy * ca)
            for dx, dy in ((-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2))]


# ------------------------------------------------------------------ alijos ----
def _hazard_band(img, rect, color):
    """Franja diagonal de advertencia (acento/negro) recortada a `rect`."""
    img.set_clip(rect)
    pygame.draw.rect(img, (14, 14, 16), rect)
    for x in range(rect.x - rect.h, rect.right, 8):
        pygame.draw.polygon(img, color, [(x, rect.bottom), (x + 4, rect.bottom), (x + 4 + rect.h, rect.y), (x + rect.h, rect.y)])
    img.set_clip(None)


@lru_cache(maxsize=None)
def _crate(w, h, kind, opened):
    """Caja blindada 2.5D con luz arriba-izquierda: tapa biselada, correas, esquineros, franja de advertencia y el emblema
    del contenido (lingotes, núcleo de plasma o cruz de suministros). Abierta: tapa levantada y el interior vacío."""
    accent = ACCENT[kind]
    head = 7                                                     # hueco superior para la tapa levantada
    img = pygame.Surface((w, h + head), pygame.SRCALPHA)
    body = pygame.Rect(1, head + 2, w - 2, h - 3)
    th = int(body.h * 0.46)
    top, front = pygame.Rect(body.x, body.y, body.w, th), pygame.Rect(body.x, body.y + th, body.w, body.h - th)
    pygame.draw.rect(img, (46, 50, 58), front)                   # cara frontal
    for x in range(front.x + 5, front.right - 3, 8):             # nervios de refuerzo
        pygame.draw.line(img, (36, 39, 46), (x, front.y + 1), (x, front.bottom - 7))
        pygame.draw.line(img, (62, 67, 78), (x + 1, front.y + 1), (x + 1, front.bottom - 7))
    _hazard_band(img, pygame.Rect(front.x + 2, front.bottom - 6, front.w - 4, 4), accent)
    if opened:
        pygame.draw.rect(img, (10, 12, 16), top)                 # interior oscuro y vacío
        pygame.draw.rect(img, (24, 27, 33), top.inflate(-6, -4))
        rng = random.Random(w * 31 + h)
        for _ in range(3):                                       # restos sueltos en el fondo
            pygame.draw.circle(img, _mul(rng.choice(_SCRAP_TONES), 0.6), (rng.randint(top.x + 6, top.right - 6), rng.randint(top.y + 4, top.bottom - 3)), 1)
        lid = [(body.x + 2, body.y), (body.right - 2, body.y), (body.right - 5, 1), (body.x + 5, 1)]
        pygame.draw.polygon(img, (84, 90, 102), lid)             # tapa levantada hacia atrás
        pygame.draw.polygon(img, STEEL_DARK, lid, 1)
        pygame.draw.line(img, STEEL_LIGHT, lid[3], lid[2], 1)
    else:
        pygame.draw.rect(img, (84, 90, 102), top)                # tapa
        pygame.draw.rect(img, (112, 119, 132), (top.x, top.y, top.w, 1))                # bisel claro arriba
        pygame.draw.rect(img, (112, 119, 132), (top.x, top.y, 1, top.h))
        pygame.draw.rect(img, (58, 63, 74), top.inflate(-8, -6), 1)                      # panel hundido
        latch = pygame.Rect(0, 0, 9, 5)
        latch.center = (top.centerx, top.bottom - 3)
        pygame.draw.rect(img, STEEL_DARK, latch.inflate(2, 2))
        pygame.draw.rect(img, accent, latch)
        if kind in ("plasma", "module"):                         # ventana por la que se ve el núcleo / el módulo
            win = pygame.Rect(top.x + 8, top.y + 3, top.w - 16, 4)
            pygame.draw.rect(img, _mul(accent, 0.3), win)
            pygame.draw.rect(img, accent, win.inflate(-4, -2))
    for sx in (body.x + int(body.w * 0.2), body.right - int(body.w * 0.2) - 4):          # correas
        pygame.draw.rect(img, (28, 31, 37), (sx, body.y, 4, body.h))
        pygame.draw.rect(img, (70, 76, 88), (sx, body.y, 1, body.h))
        pygame.draw.circle(img, STEEL_LIGHT, (sx + 2, body.y + 3), 1)
        pygame.draw.circle(img, STEEL_LIGHT, (sx + 2, front.y + 3), 1)
    cx, cy = front.centerx, front.y + (front.h - 6) // 2 + 1                             # emblema en la cara frontal
    if not opened or kind != "plasma":
        _emblem(img, kind, cx, cy, accent, dim=opened)
    for corner in ((body.x, body.y), (body.right - 3, body.y), (body.x, body.bottom - 3), (body.right - 3, body.bottom - 3)):
        pygame.draw.rect(img, STEEL_LIGHT, (*corner, 3, 3))                              # esquineros
    pygame.draw.rect(img, STEEL_DARK, body, 1)
    return img


def _emblem(img, kind, cx, cy, accent, dim=False):
    color = _mul(accent, 0.45) if dim else accent
    if kind == "scrap":                                          # tres lingotes apilados
        for i, (dx, dy) in enumerate(((-4, 1), (4, 1), (0, -3))):
            pygame.draw.polygon(img, _mul(color, 1.0 - i * 0.12),
                                [(cx + dx - 4, cy + dy + 2), (cx + dx + 4, cy + dy + 2), (cx + dx + 3, cy + dy - 1), (cx + dx - 3, cy + dy - 1)])
    elif kind == "plasma":                                       # rombo de núcleo
        pygame.draw.polygon(img, STEEL_DARK, [(cx, cy - 5), (cx + 5, cy), (cx, cy + 5), (cx - 5, cy)])
        pygame.draw.polygon(img, color, [(cx, cy - 4), (cx + 4, cy), (cx, cy + 4), (cx - 4, cy)])
        pygame.draw.circle(img, (230, 252, 255) if not dim else color, (cx, cy), 1)
    elif kind == "module":                                       # chip del Módulo de Mando
        pygame.draw.rect(img, STEEL_DARK, (cx - 5, cy - 5, 11, 11))
        pygame.draw.rect(img, color, (cx - 4, cy - 4, 9, 9), 1)
        pygame.draw.rect(img, color, (cx - 2, cy - 2, 5, 5))
        for d in (-3, 0, 3):
            pygame.draw.line(img, color, (cx + d, cy - 7), (cx + d, cy - 5))
            pygame.draw.line(img, color, (cx + d, cy + 6), (cx + d, cy + 8))
    else:                                                        # cruz de suministros
        pygame.draw.rect(img, color, (cx - 1, cy - 4, 3, 9))
        pygame.draw.rect(img, color, (cx - 4, cy - 1, 9, 3))


def render_crate(size, kind, opened=False):
    return _crate(int(size[0]), int(size[1]), kind, bool(opened)).copy()


@lru_cache(maxsize=None)
def _glow(radius, color, level):
    """Halo radial para mezclar en aditivo (`BLEND_ADD`); `level` 1-5 es su intensidad."""
    img = pygame.Surface((radius * 2, radius * 2))
    k = level / 5.0
    for r in range(radius, 0, -2):
        f = (1 - r / radius) ** 1.6 * 0.5 * k
        pygame.draw.circle(img, tuple(int(c * f) for c in color), (radius, radius), r)
    return img


def draw_glow(surface, center, radius, color, strength):
    """Halo aditivo cacheado; `strength` 0..1 se cuantiza en 5 niveles."""
    level = int(round(max(0.0, min(1.0, strength)) * 5))
    if level:
        surface.blit(_glow(radius, tuple(color), level), (center[0] - radius, center[1] - radius), special_flags=pygame.BLEND_ADD)


def draw_open_burst(surface, center, p, color):
    """Chispas y anillo al abrir un alijo (`p` 0 -> 1): solo primitivas, sin superficies."""
    if p >= 1:
        return
    for i in range(10):
        a = i * math.tau / 10 + 0.3
        r0, r1 = 6 + 26 * p, 10 + 34 * p
        pygame.draw.line(surface, color, (center[0] + math.cos(a) * r0, center[1] + math.sin(a) * r0 * 0.8),
                         (center[0] + math.cos(a) * r1, center[1] + math.sin(a) * r1 * 0.8), 2 if p < 0.5 else 1)
    pygame.draw.circle(surface, color, center, int(8 + 26 * p), 2 if p < 0.6 else 1)


# --------------------------------------------------------------- depósitos ----
DEPOSIT_VARIANTS = 8


@lru_cache(maxsize=None)
def _deposit(size, variant, depleted):
    """Montón de chatarra: planchas oxidadas, tuberías, engranajes y trozos de metal brillante sobre una base de grasa.
    Agotado: solo quedan restos oscuros aplastados."""
    s = size
    img = pygame.Surface((s, s), pygame.SRCALPHA)
    rng = random.Random(variant * 7717 + 11)
    pygame.draw.ellipse(img, (0, 0, 0, 96), (s * 0.05, s * 0.5, s * 0.9, s * 0.42))             # sombra y mancha de grasa
    pygame.draw.ellipse(img, (6, 6, 8, 70), (s * 0.14, s * 0.56, s * 0.72, s * 0.3))
    pieces = []
    count = 6 if depleted else 26
    for _ in range(count):
        a, d = rng.uniform(0, math.tau), math.sqrt(rng.random())
        x, y = s / 2 + math.cos(a) * d * s * 0.3, s * 0.6 + math.sin(a) * d * s * 0.17
        lift = 0 if depleted else (1 - d) * s * 0.24                                                # el centro hace montículo
        pieces.append((y, x, y - lift, rng.choice(("plate", "plate", "pipe", "gear", "ore")), rng.uniform(0, math.pi)))
    for _, x, y, kind, ang in sorted(pieces):
        if depleted:
            tone = _mul(rng.choice(_SCRAP_TONES), 0.45)
        else:
            tone = rng.choice(_SCRAP_TONES)
        if kind == "plate" or depleted:
            pts = _plate(x, y, rng.randint(10, 20), rng.randint(4, 8), ang)
            pygame.draw.polygon(img, _mul(tone, 0.35), [(px + 1, py + 2) for px, py in pts])
            pygame.draw.polygon(img, tone, pts)
            pygame.draw.lines(img, _mul(tone, 1.5), False, pts[:3], 1)
        elif kind == "pipe":
            ex, ey = x + math.cos(ang) * 9, y + math.sin(ang) * 9
            pygame.draw.line(img, (20, 22, 26), (x - math.cos(ang) * 9, y - math.sin(ang) * 9 + 2), (ex, ey + 2), 5)
            pygame.draw.line(img, (118, 124, 138), (x - math.cos(ang) * 9, y - math.sin(ang) * 9), (ex, ey), 4)
            pygame.draw.line(img, (190, 196, 208), (x - math.cos(ang) * 9, y - math.sin(ang) * 9 - 1), (ex, ey - 1), 1)
        elif kind == "gear":
            pygame.draw.circle(img, (22, 24, 28), (round(x), round(y) + 1), 6)
            for t in range(8):
                ta = t * math.tau / 8
                pygame.draw.circle(img, (130, 98, 40), (round(x + math.cos(ta) * 6), round(y + math.sin(ta) * 6)), 2)
            pygame.draw.circle(img, (150, 112, 44), (round(x), round(y)), 5)
            pygame.draw.circle(img, (30, 26, 18), (round(x), round(y)), 2)
        else:                                                                                      # trozo de metal brillante
            pts = [(x, y - 5), (x + 5, y), (x, y + 5), (x - 5, y)]
            pygame.draw.polygon(img, (110, 96, 18), [(px + 1, py + 2) for px, py in pts])
            pygame.draw.polygon(img, (222, 190, 40), pts)
            pygame.draw.polygon(img, (255, 238, 150), [(x, y - 5), (x + 5, y), (x, y)])
    return img


def deposit_glints(variant):
    """Posiciones (en fracción de `size`) de los destellos del depósito, estables por variante."""
    rng = random.Random(variant * 977 + 5)
    return [(rng.uniform(0.28, 0.72), rng.uniform(0.3, 0.62)) for _ in range(3)]


def render_deposit(size, variant, depleted=False):
    return _deposit(int(size), variant % DEPOSIT_VARIANTS, bool(depleted)).copy()


def draw_glint(surface, x, y, k):
    """Destello en cruz de 4 puntas (`k` 0 -> 1 -> 0)."""
    r = int(1 + 4 * k)
    c = (255, 244, 190)
    pygame.draw.line(surface, c, (x - r, y), (x + r, y))
    pygame.draw.line(surface, c, (x, y - r), (x, y + r))


# -------------------------------------------------------------- plataformas ----
@lru_cache(maxsize=None)
def _pad(radius, color, emblem, frame):
    """Plataforma de extracción vista desde arriba: anillo de acero con franjas de advertencia y pernos, placa oscura,
    chevrones que se desplazan hacia el centro, emblema y un barrido luminoso que gira. 16 fotogramas cacheados."""
    d = radius * 2 + 20
    img = pygame.Surface((d, d), pygame.SRCALPHA)
    c = (d // 2, d // 2)
    ph = math.tau * frame / PAD_FRAMES
    pulse = 0.5 + 0.5 * math.sin(ph)
    pygame.draw.circle(img, (0, 0, 0, 90), (c[0], c[1] + 4), radius + 4)                         # sombra
    pygame.draw.circle(img, (20, 24, 30), c, radius)                                              # placa
    for i, f in enumerate((0.9, 0.7, 0.5)):
        pygame.draw.circle(img, (24 + i * 3, 29 + i * 3, 36 + i * 3), c, int(radius * f), 1)
    pygame.draw.circle(img, (74, 80, 92), c, radius, 8)                                           # anillo de acero
    pygame.draw.circle(img, STEEL_DARK, c, radius, 1)
    pygame.draw.circle(img, STEEL_DARK, c, radius - 7, 1)
    steps = 24
    for i in range(0, steps, 2):                                                                  # franjas de advertencia
        a0, a1 = i * math.tau / steps, (i + 1) * math.tau / steps
        r0, r1 = radius - 6, radius - 1
        pygame.draw.polygon(img, HAZARD, [(c[0] + math.cos(a) * r, c[1] + math.sin(a) * r)
                                          for a, r in ((a0, r0), (a1, r0), (a1, r1), (a0, r1))])
    for i in range(8):                                                                            # pernos
        a = i * math.tau / 8 + math.pi / 8
        pygame.draw.circle(img, STEEL_LIGHT, (round(c[0] + math.cos(a) * (radius - 3.5)), round(c[1] + math.sin(a) * (radius - 3.5))), 1)
    glow = pygame.Surface((d, d), pygame.SRCALPHA)
    pygame.draw.circle(glow, (*color, int(40 + 40 * pulse)), c, int(radius * 0.84))             # resplandor interior
    for k in range(3):                                                                            # barrido giratorio con estela
        a = ph + k * -0.35
        pts = [c] + [(c[0] + math.cos(a + t * 0.3) * radius * 0.84, c[1] + math.sin(a + t * 0.3) * radius * 0.84) for t in range(4)]
        pygame.draw.polygon(glow, (*color, 70 - k * 22), pts)
    img.blit(glow, (0, 0))
    pygame.draw.circle(img, (*color, int(150 + 100 * pulse)), c, int(radius * 0.84), 2)           # aro de estado
    shift = (frame % 8) / 8 * radius * 0.12
    for q in range(4):                                                                            # chevrones hacia el centro
        a = q * math.pi / 2
        ux, uy = math.cos(a), math.sin(a)
        px, py = -uy, ux
        for step in (0, 1):
            dist = radius * (0.74 - step * 0.12) - shift
            tip = (c[0] + ux * (dist - 6), c[1] + uy * (dist - 6))
            pts = [(c[0] + ux * dist + px * 8, c[1] + uy * dist + py * 8), tip, (c[0] + ux * dist - px * 8, c[1] + uy * dist - py * 8)]
            pygame.draw.lines(img, color, False, pts, 2)
    e = radius * 0.3                                                                              # emblema central
    pygame.draw.circle(img, (12, 14, 18), c, int(e + 5))
    pygame.draw.circle(img, color, c, int(e + 5), 1)
    if emblem == "diamond":
        pts = [(c[0], c[1] - e), (c[0] + e * 0.75, c[1]), (c[0], c[1] + e), (c[0] - e * 0.75, c[1])]
    else:
        pts = [(c[0], c[1] - e), (c[0] + e * 0.8, c[1] + e * 0.6), (c[0], c[1] + e * 0.2), (c[0] - e * 0.8, c[1] + e * 0.6)]
    pygame.draw.polygon(img, tuple(int(v * (0.55 + 0.45 * pulse)) for v in color), pts)
    pygame.draw.polygon(img, (235, 245, 250), pts, 1)
    return img


def pad_frame(radius, color, emblem, frame):
    """Fotograma `frame` de la plataforma (cacheado: no lo modifiques, trabaja sobre una copia)."""
    return _pad(int(radius), tuple(color), emblem, frame % PAD_FRAMES)
