#!/usr/bin/env python3
"""Tercera vuelta de jefes de Órbita 84: el fénix de Phoenix más imponente y propuestas para
los cuatro que no se habían revisado (coloso de Roswell, tenaza belga, Shag Harbour y el
fantasma del Golfo Nuevo). Misma regla de antes: masa en tinta, lo llamativo recortado en
claro, partes que se mueven.
Salida: img/jefes2/*.gif y jefes2.txt con los dibujos."""
import math
import os

from PIL import Image

import generar
from efectos import a_imagen, base, copia, NAVE, DIB

# la columna "Hoy" muestra los jefes como estaban antes de esta vuelta (respaldo)
_viejo = os.path.expanduser("~/Respaldos/ORBITA-84/antes-jefes3/juego/datos.lua")
ANTES = dict(DIB)
if os.path.exists(_viejo):
    import re as _re
    for _m in _re.finditer(r'(\w+)\s*=\s*\{\s*((?:"[^"]*"\s*,?\s*(?:--[^\n]*\n)?\s*)+)\}', open(_viejo, encoding="utf-8").read()):
        ANTES[_m.group(1)] = _re.findall(r'"([^"]*)"', _m.group(2))

SALIDA = os.path.join(generar.SALIDA, "jefes2")


def lienzo(w, h, c="."):
    return [[c] * w for _ in range(h)]


def texto(f):
    return ["".join(r) for r in f]


def pegar(f, filas, x0, y0):
    for j, r in enumerate(filas):
        for i, ch in enumerate(r):
            y, x = y0 + j, x0 + i
            if ch != " " and 0 <= y < len(f) and 0 <= x < len(f[0]):
                f[y][x] = ch


def p(f, x, y, ch):
    if 0 <= y < len(f) and 0 <= x < len(f[0]):
        f[y][x] = ch


def espejo(filas):
    """Las filas son la mitad izquierda más la columna del centro; se completa la derecha."""
    return [r + r[:-1][::-1] for r in filas]


# ================================================================== FÉNIX (Phoenix 1997)
def _ala(w, h, grosor, macizo_centro):
    """Una V invertida maciza: el vértice arriba al centro y las alas bajando hacia los lados."""
    f = lienzo(w, h)
    c = w // 2
    for x in range(w):
        d = abs(x - c)
        yt = round(d * (h - grosor) / c)
        fondo = yt + grosor
        if d <= macizo_centro:
            fondo = max(fondo, h - 3 - d // 2)
        for y in range(yt, min(h, fondo)):
            f[y][x] = "#"
    return f, c


FENIX_MITAD = [  # mitad izquierda + columna del centro (18 de ancho)
    "...............###",
    ".............#####",
    "...........####+##",
    ".........#######..",
    ".......###########",
    ".....#############",
    "...########..#####",
    ".########.....####",
    "#######........###",
    "#####...........##",
    "###...............",
]
LUCES_FENIX = [(3, 11), (5, 7), (7, 3)]  # (fila, columna) en la mitad izquierda, del centro a la punta


def fenix_bumeran(k=0):
    """A · El bumerán macizo (35x11): alas gruesas, un casco que baja al centro con un ojo
    claro, y luces recortadas en claro que corren del centro hacia las puntas."""
    f = [list(r) for r in espejo(FENIX_MITAD)]
    w = len(f[0])
    for i, (y, x) in enumerate(LUCES_FENIX):
        luz = "." if k % 4 == i else "+"
        f[y][x] = luz
        f[y][w - 1 - x] = luz
    if k % 2:
        f[3][17] = "+"
    return texto(f)


def fenix_nodriza(k=0):
    """B · La nodriza (37x12): un triángulo lleno que tapa medio cielo; abajo una fila de
    luces claras que titilan y una compuerta al centro que se abre cuando suelta algo."""
    w, h = 37, 12
    f = lienzo(w, h)
    c = w // 2
    for y in range(h):
        d = round((y + 1) * c / (h - 2))
        for x in range(max(0, c - d), min(w, c + d + 1)):
            if y < h - 2:
                f[y][x] = "#"
    # el borde de abajo dentado
    for x in range(1, w - 1, 2):
        p(f, x, h - 2, "#")
    # luces bajo el borde
    for i, x in enumerate(range(4, w - 4, 4)):
        p(f, x, h - 4, "." if (i + k) % 3 == 0 else "+")
    # cúpula clara arriba
    for x in range(c - 1, c + 2):
        p(f, x, 3, ".")
    p(f, c, 2, "+")
    # compuerta: cerrada, entreabierta, abierta
    ab = (0, 1, 2, 1)[k % 4]
    for x in range(c - ab, c + ab + 1):
        for y in range(h - 5, h - 2):
            p(f, x, y, "." if ab else "#")
    if ab:
        p(f, c, h - 1, "#")
    return texto(f)


def fenix_motores(k=0):
    """C · El ala con motores (35x13): el bumerán macizo con dos góndolas colgando de las
    puntas que echan fuego en tono medio."""
    f = [list(r) for r in fenix_bumeran(k)] + [list("." * 35) for _ in range(2)]
    for x0 in (0, 30):
        for y in range(7, 11):
            for x in range(x0, x0 + 5):
                f[y][x] = "#"
        f[8][x0 + 2] = "." if k % 2 == 0 else "+"
        f[11][x0 + 1] = f[11][x0 + 3] = "+"
        if k % 2:
            f[12][x0 + 2] = "+"
        else:
            f[11][x0 + 2] = "+"
    return texto(f)


COLOSO_MITAD = [
    "........####",
    "......######",
    ".....##.##.#",
    "....########",
    "..##########",
    ".###########",
    "############",
    ".###########",
    "...#########",
    ".....#######",
    "......##..+#",
]


def coloso_macizo(k=0):
    """A · El platillo macizo (23x11): disco grueso, cúpula con ventanas claras y una fila de
    luces que corre por el borde."""
    f = [list(r) for r in espejo(COLOSO_MITAD)]
    for i, x in enumerate(range(1, 23, 3)):
        f[6][x] = "." if i % 4 == k % 4 else "+"
    return texto(f)


def coloso_canon(k=0):
    """B · El platillo con cañón (23x11): el mismo disco con un cañón que asoma hacia la nave
    y retrocede al disparar; la cúpula se enciende cuando va a tirar."""
    f = [list(r) for r in coloso_macizo(k)]
    atras = 1 if k % 4 == 3 else 0
    for x in range(0, 6):
        f[9][x] = "#" if x >= atras else "."
    f[9][atras] = "+"
    f[10][4] = f[10][5] = "#"
    if k % 4 == 2:
        for x in range(7, 16):
            if f[2][x] == ".":
                f[2][x] = "+"
    return texto(f)


PILOTO_MITAD = [
    "........####",
    "......##....",
    ".....#....##",
    "....#....###",
    "....#....+##",
    "..##########",
    ".###########",
    "############",
    ".###########",
    "...#########",
    ".....##...##",
]


def coloso_piloto(k=0):
    """C · El piloto (23x11): la cúpula es un vidrio claro y adentro se ve la cabeza del gris
    de Roswell, que parpadea; las luces del borde corren."""
    f = [list(r) for r in espejo(PILOTO_MITAD)]
    for i, x in enumerate(range(1, 23, 3)):
        f[7][x] = "." if i % 4 == k % 4 else "+"
    if k % 4 == 3:
        f[4][9] = f[4][13] = "#"
    return texto(f)


def coloso_restos(k=0):
    """D · Los restos (23x13): el platillo estrellado de Roswell, con una grieta clara que
    lo cruza, chispas en tono medio y humo que sale de la herida."""
    f = [list("." * 23) for _ in range(2)] + [list(r) for r in coloso_macizo(k)]
    for x, y in ((14, 5), (15, 6), (15, 7), (16, 8), (17, 8), (17, 9), (18, 10)):
        f[y][x] = "."
    chispa = ((16, 7), (18, 9), (15, 5))[k % 3]
    f[chispa[1]][chispa[0]] = "+"
    for j, x in enumerate((15, 16, 17)):
        y = (j + k) % 3
        f[y][x] = "+"
        if y + 1 < 3:
            f[y + 1][x] = "+"
    return texto(f)


DOBLE_MITAD = [
    "........####",
    "......##.#.#",
    ".....#######",
    "...#########",
    ".###########",
    "...#########",
    ".....#######",
    "..##########",
    "############",
    ".###########",
    "....########",
    ".......##.+#",
]


def coloso_doble(k=0):
    """E · El doble disco (23x12): dos platillos encimados con sus filas de luces girando
    en sentidos contrarios, como un trompo."""
    f = [list(r) for r in espejo(DOBLE_MITAD)]
    for x in range(1, 22):
        if f[4][x] == "#" and (x + k) % 3 == 0:
            f[4][x] = "+"
    for x in range(0, 23):
        if (x - k) % 3 == 0:
            f[8][x] = "." if (x - k) % 6 == 0 else "+"
    return texto(f)


def _triangulo(w, h):
    f = lienzo(w, h)
    m = h // 2
    for y in range(h):
        d = abs(y - m)
        for x in range(round(d * (w - 1) / m), w):
            f[y][x] = "#"
    return f


def tenaza_maciza(k=0):
    """A · El triángulo macizo (20x15): punta hacia la nave, tres luces grandes recortadas en
    las esquinas que se encienden por turno, y la luz del centro que late."""
    w, h = 20, 15
    f = _triangulo(w, h)
    esquinas = [[(3, 7), (4, 7)], [(16, 2), (17, 2), (16, 3), (17, 3)], [(16, 11), (17, 11), (16, 12), (17, 12)]]
    for i, puntos in enumerate(esquinas):
        for x, y in puntos:
            f[y][x] = "." if k % 3 == i else "+"
    c = "." if k % 2 == 0 else "+"
    for y in (6, 7, 8):
        for x in (11, 12):
            f[y][x] = c
    return texto(f)


def tenaza_pinzas(k=0):
    """B · La tenaza (24x15): el triángulo con dos pinzas al frente que se abren y se cierran;
    las luces de las esquinas van recortadas en claro."""
    w, h = 24, 15
    f = lienzo(w, h)
    pegar(f, tenaza_maciza(k), 4, 0)
    ab = (0, 1, 2, 1)[k % 4]
    for y0, diente in ((5 - ab, 1), (9 + ab, -1)):
        for x in range(0, 11):
            for y in (y0, y0 - diente):
                if f[y][x] == "." and (y == y0 or x > 1):
                    f[y][x] = "#"
        f[y0 + diente][0] = f[y0 + diente][1] = "#"
    return texto(f)


def shag_casco(k=0):
    """A · El casco hundido (23x8): una cúpula maciza con cuatro ventanas claras que se
    encienden en fila, como las luces que vieron caer al agua."""
    mitad = [
        "......######",
        "....########",
        "..##########",
        ".###########",
        "############",
        "############",
        ".#.#.#.#.#.#",
        "............",
    ]
    f = [list(r) for r in espejo(mitad)]
    for i, x in enumerate((4, 8, 14, 18)):
        luz = "." if i == k % 4 else "+"
        p(f, x, 3, luz)
        p(f, x + 1, 3, luz)
    # gotas que caen
    for x in range(1, 23, 2):
        if (x + k) % 4 == 0:
            p(f, x, 7, "+")
    return texto(f)


def shag_quilla(k=0):
    """B · La quilla de luces (23x9): el objeto de lado, una media luna maciza con una fila de
    luces claras abajo que se apagan una por una y una antena arriba."""
    mitad = [
        "..........#.",
        ".........###",
        "......######",
        "...#########",
        ".###########",
        "############",
        ".###########",
        "...#########",
        "......######",
    ]
    f = [list(r) for r in espejo(mitad)]
    for i, x in enumerate(range(3, 21, 3)):
        p(f, x, 5, "." if (i + k) % 3 else "+")
    p(f, 11, 0, "." if k % 2 else "#")
    return texto(f)


# ================================================================== FANTASMA (Golfo Nuevo 1960)
def fantasma_macizo(k=0):
    """A · El submarino macizo (24x8): casco grueso, torreta con periscopio, ojos de buey claros
    y una hélice atrás que gira."""
    filas = [
        "..........#.............",
        ".........##.............",
        "........####............",
        "..##################....",
        ".####################.#.",
        "######################.#",
        ".####################.#.",
        "...################.....",
    ]
    f = [list(r) for r in filas]
    for x in (4, 8, 12, 16):
        f[5][x] = "."
    f[3][10] = "+"
    if k % 2:
        f[4][22], f[6][22], f[5][23], f[5][22] = ".", ".", ".", "+"
        f[3][22], f[7][22] = "#", "#"
    return texto(f)


def fantasma_raya(k=0):
    """B · El objeto sin forma (24x8): un casco ancho como raya, con dos ojos claros al frente
    y aletas que ondulan."""
    filas = [
        "........########........",
        "....################....",
        "..####################..",
        ".##..##############.###.",
        "######################.#",
        ".####################.#.",
        "....##############......",
        "........######..........",
    ]
    f = [list(r[:24]) for r in filas]
    if k % 2:
        f[0] = list("....####......####......")
        f[7] = list("......##########........")
    return texto(f)


# ================================================================== pantallas
PROPUESTAS = [
    # (jefe, caso, lugar en la pantalla (x, y), [(clave, título, idea, cuadros)])
    ("fenix", "Luces de Phoenix 1997", None, [
        ("hoy", "Hoy", "Una V de líneas finas, 27x9.", [ANTES["nodriza" + s] for s in ("", "_b", "_c", "_d", "_e")]),
        ("a", "A · El bumerán macizo", "Alas gruesas, casco al centro y siete luces claras que corren a las puntas. 35x11.", [fenix_bumeran(k) for k in range(4)]),
        ("b", "B · La nodriza", "Un triángulo lleno que tapa medio cielo, luces abajo y una compuerta que se abre al soltar. 37x12.", [fenix_nodriza(k) for k in range(4)]),
        ("c", "C · El ala con motores", "La V maciza con góndolas que echan fuego en las puntas y un ojo grande al centro. 35x12.", [fenix_motores(k) for k in range(4)]),
    ]),
    ("coloso", "Roswell 1947", None, [
        ("hoy", "Hoy", "Platillo de 17x9.", [ANTES["jefe"]]),
        ("a", "A · El platillo macizo", "Disco grueso, cúpula con ventanas y luces que corren por el borde. 23x11.", [coloso_macizo(k) for k in range(4)]),
        ("b", "B · Con cañón", "El mismo disco con un cañón que retrocede al disparar. 23x11.", [coloso_canon(k) for k in range(4)]),
        ("c", "C · El piloto", "La cúpula es un vidrio claro y adentro se ve la cabeza del gris, que parpadea. 23x11.", [coloso_piloto(k) for k in range(4)]),
        ("d", "D · Los restos", "El platillo estrellado: una grieta clara, chispas y humo que sale de la herida. 23x13.", [coloso_restos(k) for k in range(6)]),
        ("e", "E · El doble disco", "Dos platillos encimados con luces que giran en sentidos contrarios. 23x12.", [coloso_doble(k) for k in range(6)]),
    ]),
    ("tenaza", "Triángulo belga 1990", None, [
        ("hoy", "Hoy", "Triángulo de 18x13.", [ANTES["tenaza"]]),
        ("a", "A · El triángulo macizo", "Tres luces grandes en las esquinas y la luz del centro que late. 20x15.", [tenaza_maciza(k) for k in range(4)]),
        ("b", "B · La tenaza", "El triángulo con dos pinzas al frente que se abren y cierran antes de embestir. 24x15.", [tenaza_pinzas(k) for k in range(4)]),
    ]),
    ("shag", "Shag Harbour 1967", None, [
        ("hoy", "Hoy", "Casco de 19x6.", [ANTES["shag"], ANTES["shag_b"]]),
        ("a", "A · El casco hundido", "Cúpula maciza con cuatro ventanas que se encienden en fila. 23x8.", [shag_casco(k) for k in range(4)]),
        ("b", "B · La quilla de luces", "Media luna de lado con luces abajo y una antena. 23x9.", [shag_quilla(k) for k in range(3)]),
    ]),
    ("fantasma", "Golfo Nuevo 1960", None, [
        ("hoy", "Hoy", "Submarino de 20x6.", [ANTES["fantasma"]]),
        ("a", "A · El submarino macizo", "Casco grueso, torreta con periscopio, ojos de buey y hélice que gira. 24x8.", [fantasma_macizo(k) for k in range(2)]),
        ("b", "B · El objeto sin forma", "Un casco ancho como raya, con ojos al frente y aletas que ondulan. 24x8.", [fantasma_raya(k) for k in range(2)]),
    ]),
]


def animar(cuadros, nombre, escala=9, ms=200):
    w = max(len(c[0]) for c in cuadros)
    h = max(len(c) for c in cuadros)
    imgs = []
    for c in cuadros:
        q = generar.Pantalla(w + 4, h + 4)
        q.dibujo(c, 2 + (w - len(c[0])) // 2, 2 + (h - len(c)) // 2)
        imgs.append(a_imagen(q.px, escala))
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=ms, loop=0, optimize=False, disposal=1)


def en_escena(cuadros, jefe, nombre, ms=200):
    """El boceto a tamaño real en la pantalla, donde pelea ese jefe."""
    fondo = base(7)
    w, h = len(cuadros[0][0]), len(cuadros[0])
    if jefe == "fenix":
        x, y = (84 - w) // 2, 6
        fondo.dibujo(NAVE, 20, 40)
    elif jefe in ("shag", "fantasma"):
        x, y = 84 - w - 4, 33 - h // 2
        fondo.dibujo(NAVE, 6, 22)
        for xx in range(84):
            if xx % 2 == 0:
                fondo.px[31][xx] = "+"
    else:
        x, y = 84 - w - 4, 26 - h // 2
        fondo.dibujo(NAVE, 6, 24)
    out = []
    for c in cuadros:
        q = copia(fondo)
        q.dibujo(c, x, y)
        out.append(q)
    imgs = [a_imagen(c.px) for c in out]
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=ms, loop=0, optimize=False, disposal=1)


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    txt = []
    for jefe, caso, _, ops in PROPUESTAS:
        for clave, titulo, idea, cuadros in ops:
            nombre = "%s_%s" % (jefe, clave)
            animar(cuadros, nombre)
            en_escena(cuadros, jefe, "escena_" + nombre)
            if clave != "hoy":
                txt.append("== %s (%dx%d, %d cuadros)" % (nombre, len(cuadros[0][0]), len(cuadros[0]), len(cuadros)))
                for k, c in enumerate(cuadros):
                    txt += ["  -- cuadro %d" % k] + ["   " + r for r in c]
    open(os.path.join(SALIDA, "jefes2.txt"), "w").write("\n".join(txt) + "\n")
    print("jefes listos")
