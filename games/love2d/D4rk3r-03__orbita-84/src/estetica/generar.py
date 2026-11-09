#!/usr/bin/env python3
"""Muestras de la estética "Expediente 84" para Órbita 84.
'#' = tinta, '+' = tono medio, '.' = vacío. Todo en la paleta VERDE del juego."""
import os
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, "img")
os.makedirs(SALIDA, exist_ok=True)

FONDO = (199, 240, 217)
TINTA = (66, 82, 61)


def mezcla(c):
    return tuple(round(FONDO[i] + (TINTA[i] - FONDO[i]) * c) for i in range(3))


MEDIO = mezcla(0.45)
SUAVE = mezcla(0.22)
TONOS = {"#": TINTA, "+": MEDIO, "-": SUAVE}

# ---------------------------------------------------------------- dibujos
E = {}  # enemigos: nombre -> (caso, filas)

E["foo"] = ("Foo fighter — bolas de luz, 1944", [
    "..#..",
    ".###.",
    "##+##",
    ".###.",
    "..#..",
])
E["arnold"] = ("Platillo de Arnold — 1947, 'como un plato rebotando en el agua'", [
    "..##..",
    ".#++#.",
    "######",
    ".#..#.",
])
E["tictac"] = ("Tic Tac — portaaviones Nimitz, 2004", [
    ".#####.",
    "#+++++#",
    ".#####.",
])
E["diamante"] = ("Diamante en llamas — caso Cash-Landrum, 1980", [
    "...#...",
    "..###..",
    ".##+##.",
    "..###..",
    "...#...",
    "..#.#..",
])
E["triangulo"] = ("Triángulo belga — ola ovni de Bélgica, 1989", [
    ".......#",
    ".....###",
    "...##+##",
    "#+######",
    "...##+##",
    ".....###",
    ".......#",
])
E["phoenix"] = ("V de Phoenix — luces de Phoenix, 1997", [
    "#.....#",
    "##...##",
    ".##+##.",
    "..###..",
])
E["hessdalen"] = ("Orbe de Hessdalen — Noruega, se divide en dos", [
    ".###.",
    "#+++#",
    "#+#+#",
    "#+++#",
    ".###.",
])
E["gris"] = ("Cabeza gris — el visitante de los Hill, 1961", [
    ".#####.",
    "#######",
    "#++#++#",
    ".#####.",
    "..###..",
    "...#...",
])
E["lubbock"] = ("Luces de Lubbock — formación en arco, 1951", [
    "..#..",
    ".#+#.",
    "#+++#",
    ".#+#.",
    "..#..",
])
E["circulo"] = ("Círculo de cultivo — gira y suelta la rueda de balas", [
    "..###..",
    ".#...#.",
    "#..#..#",
    "#.#+#.#",
    "#..#..#",
    ".#...#.",
    "..###..",
])
E["cigarro"] = ("Cigarro — ovni alargado que deja minas", [
    "..#####..",
    ".#######.",
    "#+#+#+#+#",
    ".#######.",
    "..#####..",
])
E["caballero"] = ("Caballero Negro — el satélite de la leyenda", [
    "##...##",
    "##.#.##",
    "#######",
    "##.#.##",
    "##...##",
])
E["radar"] = ("Antena del Área 51 — torreta en el suelo", [
    "#...#",
    ".###.",
    "..#..",
    "#####",
])
E["grisito"] = ("Pequeño gris — salta por el suelo", [
    ".###.",
    "#+#+#",
    ".###.",
    "..#..",
    ".#.#.",
])
E["valla"] = ("Valla del Área 51 — no se rompe, hay que saltarla", [
    "#.#.#",
    "#####",
    "#.#.#",
])

# ------------------------------------------------ jefes (generados con formas)


def lienzo(w, h):
    return [["."] * w for _ in range(h)]


def a_filas(m):
    return ["".join(f) for f in m]


def roswell():
    filas = [
        ".......###.......",
        ".....#+++++#.....",
        "....#+++++++#....",
        "..#############..",
        ".##+##+##+##+##+.",
        "#################",
        ".###############.",
        "...##.......##...",
        "..##.........##..",
    ]
    return filas


def triangulo_negro():
    w, h = 18, 13
    m = lienzo(w, h)
    c = h // 2
    for y in range(h):
        borde = round(abs(y - c) * (w - 1) / c)  # punta a la izquierda
        for x in range(borde, w):
            m[y][x] = "#"
    # luces en las tres puntas y la del centro
    for (x, y) in [(1, c), (w - 2, 1), (w - 2, h - 2)]:
        m[y][x] = "+"
    for (x, y) in [(10, c - 1), (11, c - 1), (10, c), (11, c), (10, c + 1), (11, c + 1)]:
        m[y][x] = "+"
    return a_filas(m)


def cabeza_gris(abierta):
    w, h = 15, 17
    m = lienzo(w, h)
    cx = 7
    for y in range(h):
        # cráneo ancho arriba, mentón en punta
        if y <= 8:
            ancho = 7 if y >= 2 else (5 if y == 1 else 3)
        else:
            ancho = max(1, 7 - (y - 8))
        for x in range(cx - ancho, cx + ancho + 1):
            m[y][x] = "#"
    # ojos grandes almendrados e inclinados: huecos (abiertos) o una raya (cerrados)
    ojo = [(1, 6), (2, 6), (3, 6), (1, 7), (2, 7), (3, 7), (4, 7), (2, 8), (3, 8), (4, 8), (5, 8), (4, 9), (5, 9)]
    for (x, y) in ojo:
        marca = "." if abierta else ("+" if y == 8 else "#")
        m[y][x] = marca
        m[y][w - 1 - x] = marca
    m[13][cx - 1] = "+"
    m[13][cx] = "+"
    m[13][cx + 1] = "+"
    return a_filas(m)


def phoenix_jefe():
    w, h = 23, 9
    m = lienzo(w, h)
    c = w // 2
    for x in range(w):
        y = round(abs(x - c) * (h - 3) / c)
        for yy in range(y, min(h, y + 3)):
            m[yy][x] = "#"
    # luces a lo largo del borde de abajo
    for x in range(1, w, 3):
        y = round(abs(x - c) * (h - 3) / c) + 1
        m[y][x] = "+"
    return a_filas(m)


def insignia_socorro():
    w = h = 15
    m = lienzo(w, h)
    c = 7
    for y in range(h):
        for x in range(w):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if 6.2 <= d <= 7.3:
                m[y][x] = "#"
            elif d < 6.2:
                m[y][x] = "+"
    # insignia de Socorro: arco, línea vertical y barra
    import math
    for k in range(25):
        a = math.pi + k / 24 * math.pi
        m[round(6 + math.sin(a) * 3)][round(c + math.cos(a) * 3.6)] = "#"
    for y in range(5, 11):
        m[y][c] = "#"
    for x in range(5, 10):
        m[11][x] = "#"
    return a_filas(m)


def tren():
    cabeza = [
        "..###..",
        ".#+++#.",
        "#######",
        ".#.#.#.",
    ]
    cuerpo = [
        ".###.",
        "#+++#",
        "#+#+#",
        "#+++#",
        ".###.",
    ]
    return cabeza, cuerpo


J = {
    "j_roswell": ("Nivel 1 — El platillo de Roswell", roswell()),
    "j_triangulo": ("Nivel 2 — El Triángulo Negro (embiste)", triangulo_negro()),
    "j_phoenix": ("Nivel 3 — La V de Phoenix, sobre la ciudad (solo la alcanzan los cohetes)", phoenix_jefe()),
    "j_gris_abierto": ("Nivel 4 — El Gris: abierto recibe daño", cabeza_gris(True)),
    "j_gris_cerrado": ("Nivel 4 — El Gris: con los ojos cerrados no le haces nada", cabeza_gris(False)),
    "j_socorro": ("Nivel 6 — La insignia de Socorro, en el Hangar 18", insignia_socorro()),
}

# ------------------------------------------------------------ letras gordas
GORDAS = {
    "O": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
    "R": ["#####.", "##..##", "##..##", "#####.", "##.##.", "##..##", "##..##"],
    "B": ["#####.", "##..##", "##..##", "#####.", "##..##", "##..##", "#####."],
    "I": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "######"],
    "T": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "..##.."],
    "A": [".####.", "##..##", "##..##", "######", "##..##", "##..##", "##..##"],
    "8": [".####.", "##..##", "##..##", ".####.", "##..##", "##..##", ".####."],
    "4": ["##..##", "##..##", "##..##", "######", "....##", "....##", "....##"],
    " ": ["......"] * 7,
}
CHICAS = {  # las letras de 3x5 que ya usa el juego (solo las de las muestras)
    "A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", ".#."],
    "L": ["#..", "#..", "#..", "#..", "###"], "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"], "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#.#", "#.#", "###", "###", "#.#"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "Z": ["###", "..#", ".#.", "#..", "###"], "G": [".##", "#..", "#.#", "#.#", ".##"],
    "0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
    "4": ["#.#", "#.#", "###", "..#", "..#"], "7": ["###", "..#", ".#.", ".#.", ".#."],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
    "5": ["###", "#..", "##.", "..#", "##."], "6": [".##", "#..", "###", "#.#", "###"],
    ":": ["...", ".#.", "...", ".#.", "..."], "-": ["...", "...", "###", "...", "..."],
    " ": ["..."] * 5, "!": [".#.", ".#.", ".#.", "...", ".#."],
}

# ------------------------------------------------------------ pantalla


class Pantalla:
    def __init__(self, w=84, h=48):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def punto(self, x, y, tono="#"):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = tono

    def dibujo(self, filas, x, y, solo=None):
        for j, f in enumerate(filas):
            for i, c in enumerate(f):
                if c != ".":
                    self.punto(x + i, y + j, solo or c)

    def texto(self, t, x, y, tono="#", tabla=CHICAS, paso=4):
        for k, c in enumerate(t):
            self.dibujo(tabla.get(c, tabla[" "]), x + k * paso, y, tono)

    def ancho(self, t, paso=4):
        return len(t) * paso - 1

    def centrado(self, t, y, tono="#"):
        self.texto(t, (self.w - self.ancho(t)) // 2, y, tono)

    def gordo(self, t, x, y, sombra=True, escala=1):
        for k, c in enumerate(t):
            filas = GORDAS[c]
            if escala > 1:
                filas = ["".join(ch * escala for ch in f) for f in filas for _ in range(escala)]
            gx = x + k * (6 * escala + escala)
            if sombra:
                self.dibujo(filas, gx + 1, y + 1, "+")
            self.dibujo(filas, gx, y, "#")

    def rect(self, x, y, w, h, tono="#"):
        for i in range(w):
            self.punto(x + i, y, tono)
            self.punto(x + i, y + h - 1, tono)
        for j in range(h):
            self.punto(x, y + j, tono)
            self.punto(x + w - 1, y + j, tono)

    def circulo(self, cx, cy, r, tono="-", pasos=None):
        import math
        pasos = pasos or int(r * 8)
        for k in range(pasos):
            a = k / pasos * 2 * math.pi
            self.punto(round(cx + math.cos(a) * r), round(cy + math.sin(a) * r), tono)

    def guardar(self, nombre, escala=8, rejilla=True):
        guardar_matriz(self.px, nombre, escala, rejilla)


def guardar_matriz(px, nombre, escala=8, rejilla=True, margen=0):
    h, w = len(px), len(px[0])
    img = Image.new("RGB", ((w + margen * 2) * escala, (h + margen * 2) * escala), FONDO)
    d = ImageDraw.Draw(img)
    hueco = 1 if rejilla and escala >= 6 else 0
    for y in range(h):
        for x in range(w):
            c = px[y][x]
            color = TONOS[c] if c else mezcla(0.04)
            x0, y0 = (x + margen) * escala, (y + margen) * escala
            d.rectangle([x0, y0, x0 + escala - 1 - hueco, y0 + escala - 1 - hueco], fill=color)
    img.save(os.path.join(SALIDA, nombre + ".png"))


def guardar_dibujo(nombre, filas, escala=10):
    px = [[(c if c != "." else None) for c in f] for f in filas]
    guardar_matriz(px, nombre, escala, True, margen=1)


# ------------------------------------------------------------ marcador


def marcador(p, vidas=3, rayos=2, puntos="00450"):
    corazon = ["#.#", "###", ".#."]
    relampago = ["..#", ".#.", "###", ".#.", "#.."]
    for i in range(vidas):
        p.dibujo(corazon, i * 4, 1)
    for i in range(rayos):
        p.dibujo(relampago, 22 + i * 4, 0)
    p.texto(puntos, 64, 0)
    for x in range(84):
        p.punto(x, 5)


def estrellas(p, n=14, semilla=3, tono="-"):
    import random
    r = random.Random(semilla)
    for _ in range(n):
        p.punto(r.randrange(84), r.randrange(8, 48), tono)


# ----------------------------------------------------- portadas (3 opciones)

NAVE = ["##.....", ".###...", "#######", ".###...", "##....."]
VACA = ["#.###.", "######", ".#..#."]


def portada_a():
    """Abducción: letras gordas con sombra, platillo con rayo tractor llevándose una vaca."""
    p = Pantalla()
    estrellas(p, 10, 5)
    p.gordo("ORBITA", 21, 2)
    p.gordo("84", 28, 11, escala=2)
    # platillo arriba a la derecha y su rayo en tono suave
    plat = ["..###..", ".#+++#.", "#######", ".#.#.#."]
    p.dibujo(plat, 72, 12)
    for y in range(16, 41):
        ancho = (y - 16) // 4
        for x in range(75 - ancho, 76 + ancho + 1):
            p.punto(x, y, "-")
    p.dibujo(VACA, 73, 33)
    p.dibujo(NAVE, 4, 30)
    p.centrado("PULSA START", 42)
    return p


def portada_b():
    """Recreativa: marco de cartel de arcade, título en una línea, persecución debajo."""
    p = Pantalla()
    for x in range(84):
        p.punto(x, 0, "#" if x % 2 == 0 else "+")
        p.punto(x, 47, "#" if x % 2 == 1 else "+")
    for y in range(48):
        p.punto(0, y, "#" if y % 2 == 0 else "+")
        p.punto(83, y, "#" if y % 2 == 1 else "+")
    p.gordo("ORBITA 84", 11, 4)
    for x in range(8, 76):
        p.punto(x, 14, "+")
    p.dibujo(NAVE, 14, 21)
    for x in range(23, 41, 4):
        p.punto(x, 23)
        p.punto(x + 1, 23)
    p.dibujo(roswell(), 52, 18)
    p.centrado("PULSA START", 33)
    p.centrado("MEJOR DKR 5035", 40, "+")
    return p


def portada_c():
    """Radar clasificado: título a la izquierda, radar con ecos de ovnis, sello."""
    p = Pantalla()
    for r in (6, 11, 16):
        p.circulo(62, 24, r, "-")
    for k in range(17):
        p.punto(62 + k * 0.94, 24 - k * 0.34, "+")
    for x in range(46, 79):
        p.punto(x, 24, "-")
    for y in range(8, 41):
        p.punto(62, y, "-")
    p.dibujo(["#.#", ".#.", "#.#"], 70, 18)
    p.dibujo(["..#..", ".###.", "#####"], 52, 29)
    p.dibujo(["#", "#"], 66, 33)
    p.gordo("ORBITA", 2, 6, sombra=True)
    p.gordo("84", 2, 17, sombra=True, escala=2)
    p.rect(1, 36, 45, 9)
    p.texto("CLASIFICADO", 3, 38)
    return p


# ------------------------------------------------- escena de juego de ejemplo


def escena():
    p = Pantalla()
    estrellas(p, 12, 9)
    # planeta lejano en tono suave
    p.circulo(70, 24, 7, "-")
    marcador(p)
    p.dibujo(NAVE, 6, 22)
    p.dibujo(["###"], 16, 24)
    p.dibujo(["###"], 26, 24)
    p.dibujo(E["foo"][1], 40, 12)
    p.dibujo(E["foo"][1], 48, 15)
    p.dibujo(E["arnold"][1], 56, 30)
    p.dibujo(E["tictac"][1], 46, 24)
    p.dibujo(E["diamante"][1], 66, 10)
    p.dibujo(E["gris"][1], 70, 36)
    p.dibujo(["##", "##"], 36, 34)
    p.dibujo(["##", "##"], 30, 37)
    # cartel del nivel con el nombre del caso
    return p


def cartel_nivel():
    p = Pantalla()
    estrellas(p, 12, 4)
    marcador(p, puntos="00000")
    for x in range(10, 74):
        for y in range(15, 34):
            p.px[y][x] = None
    p.rect(10, 15, 64, 19)
    p.centrado("NIVEL 1", 18)
    p.centrado("ROSWELL 1947", 26, "+")
    p.dibujo(NAVE, 4, 38)
    return p


if __name__ == "__main__":
    for nombre, (caso, filas) in E.items():
        guardar_dibujo("e_" + nombre, filas)
    for nombre, (caso, filas) in J.items():
        guardar_dibujo(nombre, filas, escala=8)
    cab, cue = tren()
    guardar_dibujo("j_tren_cabeza", cab)
    guardar_dibujo("j_tren_cuerpo", cue)
    portada_a().guardar("portada_a")
    portada_b().guardar("portada_b")
    portada_c().guardar("portada_c")
    escena().guardar("escena")
    cartel_nivel().guardar("cartel")
    print("listo:", len(os.listdir(SALIDA)), "imágenes")


# ------------------------------------------------ propuestas de nave (7x5)
NAVES = {
    "n_actual": ("La de hoy", NAVE),
    "n_cabina": ("Con cabina", [
        "##.....",
        ".##+...",
        "#######",
        ".###...",
        "##.....",
    ]),
    "n_delta": ("Delta 84", [
        "##.....",
        "####...",
        "##+####",
        "####...",
        "##.....",
    ]),
    "n_interceptor": ("Interceptor", [
        "###....",
        ".#####.",
        "..#+###",
        ".#####.",
        "###....",
    ]),
}


def escena_naves():
    p = Pantalla()
    estrellas(p, 12, 21)
    marcador(p)
    for k, (nombre, (titulo, filas)) in enumerate(NAVES.items()):
        y = 9 + k * 10
        p.dibujo(filas, 6, y)
        p.dibujo(["###"], 16, y + 2)
        p.dibujo(E["foo"][1], 30, y)
        p.texto(["HOY", "CABINA", "DELTA", "INTERC"][k], 52, y, "+")
    return p


if __name__ == "__main__":
    for nombre, (titulo, filas) in NAVES.items():
        guardar_dibujo(nombre, filas, escala=14)
    escena_naves().guardar("naves")
    print("naves listas")
