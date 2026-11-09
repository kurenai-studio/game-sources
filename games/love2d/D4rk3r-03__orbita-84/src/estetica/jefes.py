#!/usr/bin/env python3
"""Bocetos de jefes nuevos para Órbita 84: el ojo de los Hill, la nodriza de Phoenix (el fénix),
la serpiente de Lubbock y el núcleo del Hangar 18. Dos propuestas por jefe, cada una con sus
cuadros de animación. Mismas reglas que el juego: '#' tinta (se toca), '+' tono medio (detalle).
Los tamaños quedan cerca de los de hoy para no romper el balance.
Salida: img/jefes/*.gif y el texto de cada dibujo listo para datos.lua (jefes.txt)."""
import math
import os

from efectos import a_imagen, base, copia, NAVE, DIB, guardar_gif
import generar

SALIDA = os.path.join(generar.SALIDA, "jefes")


class Lienzo:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.c = [["."] * w for _ in range(h)]

    def p(self, x, y, t="#"):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.c[y][x] = t

    def filas(self):
        return ["".join(f) for f in self.c]

    def circulo(self, cx, cy, r, t="#", lleno=False, grosor=1.0):
        for y in range(self.h):
            for x in range(self.w):
                d = math.hypot(x - cx, y - cy)
                if (lleno and d <= r + 0.3) or (not lleno and r - grosor + 0.3 < d <= r + 0.3):
                    self.c[y][x] = t


def espejo(filas):
    """Completa la mitad derecha copiando la izquierda (para dibujos simétricos)."""
    out = []
    for f in filas:
        n = len(f)
        izq = f[: (n + 1) // 2]
        out.append(izq + izq[: n // 2][::-1])
    return out


# ================================================================== OJO (Los Hill 1961)
def poner(base, parche, x0, y0, solo_dentro=None):
    f = [list(r) for r in base]
    for j, r in enumerate(parche):
        for i, ch in enumerate(r):
            y, x = y0 + j, x0 + i
            if ch != "." and 0 <= y < len(f) and 0 <= x < len(f[0]):
                if solo_dentro is None or solo_dentro(x, y):
                    f[y][x] = ch
    return ["".join(r) for r in f]


OJO_A_BORDE = [
    ".......#######.......",
    "....###.......###....",
    "..##.............##..",
    ".#.................#.",
    "#...................#",
    "#...................#",
    "#...................#",
    "#...................#",
    "#...................#",
    ".#.................#.",
    "..##.............##..",
    "....###.......###....",
    ".......#######.......",
]
OJO_A_IRIS = [
    "..#####..",
    ".#+++++#.",
    "#++###++#",
    "#++.##++#",
    "#++###++#",
    ".#+++++#.",
    "..#####..",
]


def _dentro_ojo(x, y):
    fila = OJO_A_BORDE[y]
    hay = [i for i, c in enumerate(fila) if c == "#"]
    return hay and hay[0] < x < hay[-1] and 0 < y < len(OJO_A_BORDE) - 1


def ojo_a(mira=0, parpado=0):
    """A · El ojo que vigila: un ojo de 21x13 con borde grueso arriba (el párpado). El iris
    mira hacia la nave (mira -1 arriba, 0 centro, 1 abajo) y el párpado baja (0, 1 a medias,
    2 cerrado, con las pestañas en tono medio)."""
    f = OJO_A_BORDE
    # párpado grueso: la línea de arriba doble
    f = poner(f, ["#######"], 7, 1)
    f = poner(f, ["###", "", "", ""], 4, 2)
    f = poner(f, ["###"], 14, 2)
    if parpado < 2:
        f = poner(f, OJO_A_IRIS, 5, 3 + mira, _dentro_ojo)
    hasta = {0: 0, 1: 5, 2: 7}[parpado]
    for y in range(1, hasta + 1):
        f = [("".join("#" if (yy == y and _dentro_ojo(x, yy)) else c for x, c in enumerate(r))) for yy, r in enumerate(f)]
    if parpado == 2:
        f = poner(f, ["+.+.+.+.+.+.+"], 4, 8, _dentro_ojo)
    return f


OJO_B = [
    ".....#######.....",
    "...###########...",
    "..####+++######..",
    ".#####++########.",
    ".###############.",
    "#################",
    "#++++#######++++#",
    "#++++++###++++++#",
    "##++++++#++++++##",
    ".###++++#++++###.",
    ".#####++#++#####.",
    "..#############..",
    "...###########...",
    "....####+####....",
    ".....#######.....",
    "......#####......",
    ".......###.......",
]


def ojo_b(mira=0, parpado=0):
    """B · El gris: la cabeza del visitante que describieron los Hill (17x17), toda en tinta,
    con dos ojos almendrados e inclinados en tono medio y una pupila con brillo que sigue a la
    nave. Al parpadear los ojos se cierran en una línea."""
    f = list(OJO_B)
    if parpado == 2:
        f = poner(f, ["#####", "######"], 1, 6)
        f = poner(f, ["######", "#####"], 10, 6)
        f = poner(f, ["#"], 8, 8)
        f = poner(f, ["###"], 9, 9)
        f = poner(f, ["###"], 5, 9)
        f = poner(f, [".#++++##", "", ""], 1, 8)
        f[8] = "##+++++###+++++##"
        f[9] = ".###############."
        f[10] = ".###############."
        return f
    if parpado == 1:
        f = poner(f, ["####", "######"], 1, 6)
        f = poner(f, ["####", "######"], 12, 6)
        f = poner(f, ["######"], 10, 7)
    y = 8 + mira
    f = poner(f, ["#."], 3, y)
    f = poner(f, ["#."], 12, y)
    return f


# ================================================================== FÉNIX (Phoenix 1997)
# las luces se marcan con 'o' y con un número de grupo (de la punta hacia afuera); en el LCD
# una luz es un hueco claro en la masa oscura: encendida '.', apagada '+'
FENIX_A = [  # mitad izquierda + centro; la derecha es espejo
    "...........###",
    ".........##++0",
    ".......###+###",
    ".....###1##...",
    "....##+##.....",
    "...##2#.......",
    "..##+#........",
    ".##3#.........",
    "##+#..........",
    "#4#...........",
]
FENIX_B = [
    "............##",
    "..........####",
    "........######",
    "......#####0#.",
    "....#####1#...",
    "..#####2#.....",
    "#####3#.......",
    "###4#.........",
    "##.#..........",
]


def _luces(mitad, luz, grupos=5):
    f = [r + r[:-1][::-1] for r in mitad]
    out = []
    for r in f:
        s = ""
        for c in r:
            if c.isdigit():
                s += "." if (int(c) - luz) % grupos in (0, 1) else "+"
            else:
                s += c
        out.append(s)
    return out


def fenix_a(luz=0):
    """A · El bumerán: alas en V de tres píxeles con la quilla en tono medio. Las luces son
    huecos claros en la masa oscura y corren de la punta a las alas."""
    return _luces(FENIX_A, luz)


def fenix_b(luz=0):
    """B · La masa: una V maciza, más pesada, con las luces en el borde de atrás que se
    encienden en cadena. Se lee como una sombra enorme con luces, como la de Phoenix."""
    return _luces(FENIX_B, luz)


# ================================================================== SERPIENTE (Lubbock 1951)
def serpiente_a_cabeza(boca=0):
    """A · La formación: la cabeza es una V chica de luces (como las luces de Lubbock), que
    apunta a la nave; la punta se abre al disparar."""
    f = [
        "......####.",
        "....###++#.",
        "..###+#..##",
        "###++#.....",
        "..###+#..##",
        "....###++#.",
        "......####.",
    ]
    if boca:
        f = [
            "......####.",
            "....###++#.",
            "..###+#..##",
            "+#+.##.....",
            "..###+#..##",
            "....###++#.",
            "......####.",
        ]
    return f


def serpiente_a_cuerpo(fase=0):
    """Cada luz del tren: un rombo con halo que late en ola."""
    return [
        ["..#..", ".#+#.", "#+#+#", ".#+#.", "..#.."],
        ["..#..", ".###.", "##+##", ".###.", "..#.."],
    ][fase % 2]


def serpiente_b_cabeza(boca=0):
    """B · El dragón: cabeza con fauces que se abren al disparar, ojo en tono medio y cresta."""
    if not boca:
        return [
            "..#.#.#....",
            ".#######...",
            "##+++++##..",
            "#++#+++++##",
            "#++++++++#.",
            "##++++++##.",
            ".########..",
        ]
    return [
        "..#.#.#....",
        ".#######...",
        "##+++++##..",
        "#++#+++###.",
        "#+++##.....",
        "##+++###...",
        ".#######...",
    ]


def serpiente_b_cuerpo(fase=0):
    """Vértebras con una aleta que sube y baja."""
    return [
        [".#.#.", "#####", "#+#+#", "#####", ".#.#."],
        ["..#..", "#####", "#+#+#", "#####", "..#.."],
    ][fase % 2]


# ================================================================== NÚCLEO (Hangar 18)
NUCLEO_ANILLO = [
    ".....#####.....",
    "...##.....##...",
    "..#.........#..",
    ".#.+.......+.#.",
    ".#...........#.",
    "#.............#",
    "#.............#",
    "#.............#",
    "#.............#",
    "#.............#",
    ".#...........#.",
    ".#.+.......+.#.",
    "..#.........#..",
    "...##.....##...",
    ".....#####.....",
]
# aspas en molinete: en cruz y en equis, de dos píxeles de grueso
ASPAS = [
    [(7, y) for y in range(2, 6)] + [(8, y) for y in range(2, 6)]
    + [(6, y) for y in range(9, 13)] + [(7, y) for y in range(9, 13)]
    + [(x, 6) for x in range(9, 13)] + [(x, 7) for x in range(9, 13)]
    + [(x, 7) for x in range(2, 6)] + [(x, 8) for x in range(2, 6)],
    [(9 + k, 5 - k) for k in range(3)] + [(10 + k, 5 - k) for k in range(3)]
    + [(9 + k, 9 + k) for k in range(3)] + [(9 + k, 10 + k) for k in range(3)]
    + [(5 - k, 9 + k) for k in range(3)] + [(4 - k, 9 + k) for k in range(3)]
    + [(5 - k, 5 - k) for k in range(3)] + [(5 - k, 4 - k) for k in range(3)],
]


def nucleo_a(giro=0):
    """A · El reactor: anillo con cuatro aspas en molinete que giran (cruz y equis) y un
    centro de 3x3 que late entre tinta y tono medio."""
    f = [list(r) for r in NUCLEO_ANILLO]
    for x, y in ASPAS[giro % 2]:
        f[y][x] = "#"
    for y in range(6, 9):
        for x in range(6, 9):
            f[y][x] = "#"
    f[7][7] = "+" if giro % 4 < 2 else "#"
    if giro % 4 >= 2:
        for x, y in ((7, 6), (6, 7), (8, 7), (7, 8)):
            f[y][x] = "+"
    return ["".join(r) for r in f]


def nucleo_b(giro=0):
    """B · El motor recuperado: carcasa de 17x15 con remaches, aletas a los lados y una ventana
    redonda con la turbina que gira (tres cuadros)."""
    w, h = 17, 15
    L = Lienzo(w, h)
    for x in range(2, 15):
        L.p(x, 0)
        L.p(x, 14)
    for y in range(15):
        L.p(2, y)
        L.p(14, y)
    for x, y in ((4, 2), (12, 2), (4, 12), (12, 12)):
        L.p(x, y, "+")
    # aletas
    for y in range(3, 12, 2):
        L.p(0, y)
        L.p(1, y)
        L.p(15, y)
        L.p(16, y)
    # ventana y turbina
    L.circulo(8, 7, 5, "#")
    for k in range(3):
        a = giro * math.pi / 4.5 + k * 2 * math.pi / 3
        for r in (1, 2, 3):
            L.p(8 + math.cos(a) * r, 7 + math.sin(a) * r, "+" if r == 3 else "#")
    L.p(8, 7, "#")
    return L.filas()


# ================================================================== pantallas
def animar(cuadros, nombre, escala=10, ms=160):
    from PIL import Image
    w = max(len(c[0]) for c in cuadros)
    h = max(len(c) for c in cuadros)
    imgs = []
    for c in cuadros:
        p = generar.Pantalla(w + 4, h + 4)
        p.dibujo(c, 2 + (w - len(c[0])) // 2, 2 + (h - len(c)) // 2)
        imgs.append(a_imagen(p.px, escala))
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=ms, loop=0)


def serpiente_cuadros(cabeza, cuerpo, n=8):
    """La cabeza con cuatro anillos detrás, en ola, en un recuadro de 40x14."""
    out = []
    for k in range(n):
        L = Lienzo(40, 15)
        cab = cabeza(1 if k % 4 == 3 else 0)
        for j, f in enumerate(cab):
            for i, ch in enumerate(f):
                if ch != ".":
                    L.p(1 + i, 4 + j, ch)
        for s in range(4):
            dy = round(2 * math.sin((k + s * 1.5) * 0.8))
            cu = cuerpo((k + s) % 2)
            for j, f in enumerate(cu):
                for i, ch in enumerate(f):
                    if ch != ".":
                        L.p(13 + s * 6 + i, 5 + dy + j, ch)
        out.append(L.filas())
    return out


def en_escena(cuadros, x, y, nombre, ms=160):
    """El boceto a tamaño real dentro de la pantalla del juego, frente a la nave."""
    fondo = base(7)
    fondo.dibujo(NAVE, 6, 24)
    out = []
    for c in cuadros:
        p = copia(fondo)
        p.dibujo(c, x, y)
        out.append(p)
    imgs = [a_imagen(c.px) for c in out]
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=ms, loop=0)


BOCETOS = {
    "ojo_hoy": [DIB["ojo_abierto"]] * 5 + [DIB["ojo_cerrado"]],
    "ojo_a": [ojo_a(0), ojo_a(-1), ojo_a(-1), ojo_a(1), ojo_a(0, 1), ojo_a(0, 2)],
    "ojo_b": [ojo_b(0), ojo_b(-1), ojo_b(-1), ojo_b(1), ojo_b(0, 1), ojo_b(0, 2)],
    "fenix_hoy": [DIB["nodriza"], DIB["nodriza_b"]],
    "fenix_a": [fenix_a(k) for k in range(4)],
    "fenix_b": [fenix_b(k) for k in range(3)],
    "nucleo_hoy": [DIB["nucleo"]],
    "nucleo_a": [nucleo_a(k) for k in range(4)],
    "nucleo_b": [nucleo_b(k) for k in range(3)],
}
LUGAR = {"ojo": (60, 15), "fenix": (54, 7), "nucleo": (62, 18)}

if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    texto = []
    for nombre, cuadros in BOCETOS.items():
        animar(cuadros, nombre)
        x, y = LUGAR[nombre.split("_")[0]]
        en_escena(cuadros, x, y, "escena_" + nombre)
        if not nombre.endswith("hoy"):
            texto.append("== %s (%dx%d, %d cuadros)" % (nombre, len(cuadros[0][0]), len(cuadros[0]), len(cuadros)))
            for f in cuadros[0]:
                texto.append("   " + f)
    serp = {
        "serpiente_hoy": serpiente_cuadros(lambda b: DIB["serpiente_cabeza"], lambda f: DIB["serpiente_cuerpo"]),
        "serpiente_a": serpiente_cuadros(serpiente_a_cabeza, serpiente_a_cuerpo),
        "serpiente_b": serpiente_cuadros(serpiente_b_cabeza, serpiente_b_cuerpo),
    }
    for nombre, cuadros in serp.items():
        animar(cuadros, nombre)
        en_escena(cuadros, 42, 16, "escena_" + nombre)
    open(os.path.join(SALIDA, "jefes.txt"), "w").write("\n".join(texto) + "\n")
    print("\n".join(texto))


# ================================================================== segunda vuelta: ojo y núcleo con vibra de jefe
# Al usuario le gustaron el ojo que vigila y el reactor, pero no se sentían jefes. Se mantiene
# el centro que eligió y se le suma masa: blindaje, piezas que se mueven y más tamaño.
def lienzo_de(w, h):
    return [["."] * w for _ in range(h)]


def pegar(f, filas, x0, y0, solo_tinta=False):
    for j, r in enumerate(filas):
        for i, ch in enumerate(r):
            y, x = y0 + j, x0 + i
            if ch != "." and 0 <= y < len(f) and 0 <= x < len(f[0]):
                f[y][x] = ch


def texto_de(f):
    return ["".join(r) for r in f]


def _ojo_hueco(f, cx, cy, rx, ry, mira, parpado):
    """Recorta en la masa un ojo almendrado claro con iris en tono medio y pupila en tinta."""
    for y in range(len(f)):
        for x in range(len(f[0])):
            u = (x - cx) / rx
            if abs(u) < 1 and abs(y - cy) <= ry * (1 - u * u) ** 0.75:
                cerrado = (parpado == 1 and y < cy) or parpado == 2
                if cerrado:
                    f[y][x] = "#"
                    continue
                d = math.hypot(x - (cx - 1), y - (cy + mira))
                f[y][x] = "#" if d <= 1.5 else ("+" if d <= 3.3 else ".")
    if parpado == 2:
        for x in range(int(cx - rx) + 2, int(cx + rx) - 1, 2):
            f[cy][x] = "+"
    elif mira is not None:
        f[cy + mira - 1][cx - 2] = "."


def ojo_acorazado(k=0, mira=None, parpado=None):
    """A · El ojo en la carne (27x21): una masa oscura con un ojo claro recortado al centro que
    sigue a la nave, cuatro púas arriba y tentáculos gruesos abajo que se mecen."""
    w, h = 27, 21
    f = lienzo_de(w, h)
    cx, cy = 13, 9
    for y in range(h):
        for x in range(w):
            if ((x - cx) / 13.2) ** 2 + ((y - cy) / 8.4) ** 2 <= 1:
                f[y][x] = "#"
    # venas en tono medio
    for x, y in ((3, 6), (4, 5), (5, 4), (22, 4), (23, 5), (24, 6), (4, 12), (5, 13), (22, 13), (23, 12)):
        f[y][x] = "+"
    for x in (5, 10, 16, 21):
        for d in range(3):
            yy = [1, 0, 0, 1][(5, 10, 16, 21).index(x)] - d + 1
            if 0 <= yy < h:
                f[yy][x] = "#"
    # tentáculos de dos píxeles
    for n, x0 in enumerate((6, 10, 16, 20)):
        for y in range(16, h):
            dx = round(math.sin((y - 16) * 0.8 + k * 0.8 + n * 1.7) * 1.3)
            for g in (0, 1):
                if 0 <= x0 + dx + g < w:
                    f[y][x0 + dx + g] = "#" if y < h - 1 else "+"
    if mira is None:
        mira = [0, -1, -1, 0, 1, 1, 0, 0][k % 8]
    if parpado is None:
        parpado = 1 if k % 8 == 6 else (2 if k % 8 == 7 else 0)
    _ojo_hueco(f, cx, cy, 8.6, 4.6, mira, parpado)
    return texto_de(f)


def ojo_coronado(k=0):
    """B · El ojo acorazado (27x21): un casco macizo de placas con remaches en tono medio,
    una visera con tres púas y el ojo claro en la ranura; dos cañones a los costados."""
    w, h = 27, 21
    f = lienzo_de(w, h)
    cx, cy = 13, 10
    for y in range(h):
        ancho = 12 if 3 <= y <= 15 else (10 if y < 3 else 12 - (y - 15) * 2)
        if y < 2:
            ancho = 7 + y * 2
        for x in range(cx - ancho, cx + ancho + 1):
            if 0 <= x < w:
                f[y][x] = "#"
    # junturas y remaches
    for y in (4, 16):
        for x in range(3, 24, 2):
            f[y][x] = "+"
    for x in (2, 24):
        for y in range(5, 15, 3):
            f[y][x] = "+"
    # púas de la visera
    for x in (8, 13, 18):
        f[0][x] = "#"
    f[0][13] = "#"
    # cañones laterales que asoman
    for y in (8, 12):
        f[y][0] = "#"
        f[y + 1][0] = "#"
    mira = [0, -1, -1, 0, 1, 1, 0, 0][k % 8]
    parpado = 1 if k % 8 == 6 else (2 if k % 8 == 7 else 0)
    _ojo_hueco(f, cx, cy, 9.5, 4.2, mira, parpado)
    return texto_de(f)


def _disco(f, cx, cy, r):
    for y in range(len(f)):
        for x in range(len(f[0])):
            if math.hypot(x - cx, y - cy) <= r + 0.3:
                f[y][x] = "#"


def _aspas_claras(f, cx, cy, k, r0=2.6, r1=7.2):
    """Cuatro aspas en molinete recortadas en claro; giran 22,5° por cuadro."""
    for y in range(len(f)):
        for x in range(len(f[0])):
            d = math.hypot(x - cx, y - cy)
            if r0 < d < r1:
                a = (math.atan2(y - cy, x - cx) - k * math.pi / 8 - (d - r0) * 0.12) % (math.pi / 2)
                if a < 0.42:
                    f[y][x] = "."


def reactor_armado(k=0):
    """A · El reactor macizo (21x21): un disco oscuro con cuatro aspas claras que giran, un
    anillo de remaches en tono medio y el centro que late."""
    w = h = 21
    f = lienzo_de(w, h)
    c = 10
    _disco(f, c, c, 10)
    _aspas_claras(f, c, c, k)
    for i in range(12):
        a = i * math.pi / 6
        f[round(c + math.sin(a) * 8.6)][round(c + math.cos(a) * 8.6)] = "+"
    for y in range(c - 1, c + 2):
        for x in range(c - 1, c + 2):
            f[y][x] = "#"
    f[c][c] = "+" if k % 2 else "#"
    return texto_de(f)


def reactor_tenazas(k=0):
    """B · El reactor armado (29x23): el reactor macizo montado entre dos módulos con cañones
    hacia la nave y pistones arriba y abajo que bombean."""
    w, h = 29, 23
    f = lienzo_de(w, h)
    pegar(f, reactor_armado(k), 4, 1)
    golpe = k % 2
    # módulos laterales macizos
    for y in range(5, 18):
        for x in list(range(0, 4)) + list(range(25, 29)):
            f[y][x] = "#"
    for y in range(6, 18, 3):
        f[y][2] = "+"
        f[y][26] = "+"
    # cañones hacia la izquierda
    for y0 in (7, 14):
        f[y0][0] = f[y0 + 1][0] = "."
        f[y0][1] = "+"
    # pistones
    for x0 in (11, 17):
        for y in range(0, 2 - golpe):
            f[y][x0] = f[y][x0 + 1] = "#"
        for y in range(h - 2 + golpe, h):
            f[y][x0] = f[y][x0 + 1] = "#"
    return texto_de(f)


SEGUNDA = {
    "ojo_acorazado": [ojo_acorazado(k) for k in range(8)],
    "ojo_coronado": [ojo_coronado(k) for k in range(8)],
    "reactor_armado": [reactor_armado(k) for k in range(4)],
    "reactor_tenazas": [reactor_tenazas(k) for k in range(4)],
}


def segunda_vuelta():
    for nombre, cuadros in SEGUNDA.items():
        animar(cuadros, nombre, 9, 180)
        w, h = len(cuadros[0][0]), len(cuadros[0])
        en_escena(cuadros, 84 - w - 3, 27 - h // 2, "escena_" + nombre, 180)


if __name__ == "__main__":
    segunda_vuelta()
