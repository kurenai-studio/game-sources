#!/usr/bin/env python3
"""Muestras del "Expediente Agua": un nivel sobre el mar y uno bajo el agua.
Regla: tinta = se puede tocar; tono medio '+' = bajo el agua (ni te toca ni lo tocas); suave '-' = fondo."""
import math
import random

from generar import Pantalla, guardar_dibujo, marcador, NAVE, E

SUP = 32  # línea del agua en el nivel de superficie

# --------------------------------------------------------------- dibujos nuevos
A = {}
A["orbe_shag"] = [
    "..###..",
    ".#+++#.",
    "#######",
    ".#.#.#.",
]
A["buzo"] = [
    ".###.",
    "#+++#",
    ".###.",
    "#####",
    "#.#.#",
    ".#.#.",
]
A["torbellino"] = [
    "#########",
    ".##+++##.",
    "..##+##..",
    "...###...",
]
A["cilindro"] = [
    "...##....",
    ".#######.",
    "#+#+#+###",
    ".#######.",
]
A["batiscafo"] = [
    "...#...",
    "..####.",
    "#######",
    "#+#+###",
    "..####.",
]
A["j_shag"] = [
    "......#######......",
    "....##+++++++##....",
    "..##+++#+#+#+++##..",
    "###################",
    "#.#.#.#.#.#.#.#.#.#",
    "..###############..",
]
A["j_piramide"] = [
    "........#........",
    ".......###.......",
    "......##+##......",
    ".....###+###.....",
    "....##+#+#+##....",
    "...###########...",
    "..##+++###+++##..",
    ".###############.",
    "#################",
]
AVENGER = [
    "......#.........",
    "..############..",
    "######++++######",
    "......####......",
]
BURBUJA = [".#.", "#.#", ".#."]


def cielo(p, semilla, hasta):
    r = random.Random(semilla)
    for _ in range(10):
        p.punto(r.randrange(84), r.randrange(8, hasta), "-")


def mar(p, fase=0):
    """Línea del agua en tinta (es el piso: no se puede bajar) y reflejos suaves debajo."""
    for x in range(84):
        p.punto(x, SUP)
        if (x + fase) % 9 in (3, 4):
            p.punto(x, SUP - 1)
    for y in range(SUP + 3, 48, 3):
        for x in range(84):
            if (x * 7 + y * 5 + fase) % 13 < 2:
                p.punto(x, y, "-")


def dibujo_partido(p, filas, x, y):
    """Lo que queda sobre el agua va en tinta; lo sumergido, en tono medio."""
    for j, f in enumerate(filas):
        for i, c in enumerate(f):
            if c != ".":
                p.punto(x + i, y + j, c if y + j < SUP else "+")


# ---------------------------------------------------------------- escenas


def superficie():
    p = Pantalla()
    cielo(p, 5, SUP - 2)
    p.circulo(70, 13, 4, "-")
    marcador(p, puntos="01230")
    mar(p)
    for y in (35, 38, 41):  # reflejo de la luna
        for x in range(67, 74, 2):
            p.punto(x, y, "-")
    # sombras bajo el agua: avisan dónde va a salir algo
    p.dibujo(A["buzo"], 27, 38, "+")
    p.dibujo(A["orbe_shag"], 50, 41, "+")
    # la nave y sus balas
    p.dibujo(NAVE, 5, 15)
    p.dibujo(["###"], 15, 17)
    p.dibujo(["###"], 24, 17)
    # orbe saltando: estela suave y gotas en tono medio donde salió
    for k in range(9):
        t = k / 8
        p.punto(33 + t * 6, SUP - 1 - math.sin(t * math.pi / 2) * 16, "-")
    for gx, gy in ((31, 30), (33, 29), (36, 30), (38, 31)):
        p.punto(gx, gy, "+")
    p.dibujo(A["orbe_shag"], 38, 11)
    # buzo asomando y disparando burbujas hacia arriba
    dibujo_partido(p, A["buzo"], 58, SUP - 3)
    p.dibujo(BURBUJA, 59, 21)
    p.dibujo(["#"], 60, 15)
    # Tic Tac sobre el agua revuelta
    p.dibujo(E["tictac"][1], 68, 22)
    for k in range(20):
        a = k / 20 * 2 * math.pi
        p.punto(round(71 + math.cos(a) * 6), round(SUP + 2 + math.sin(a) * 1.5), "+")
    # torbellino: tira de la nave hacia abajo
    for x in range(42, 51):
        p.px[SUP][x] = None
    p.dibujo(A["torbellino"], 42, SUP)
    return p


def jefe_shag(arriba):
    p = Pantalla()
    cielo(p, 11, SUP - 2)
    marcador(p, puntos="02750")
    mar(p, 4)
    p.dibujo(NAVE, 6, 18)
    if arriba:
        # emergió: se le puede pegar
        dibujo_partido(p, A["j_shag"], 52, SUP - 4)
        p.dibujo(["###"], 16, 20)
        p.dibujo(["###"], 30, 20)
        p.dibujo(BURBUJA, 44, 22)
        p.dibujo(BURBUJA, 40, 15)
        for gx, gy in ((50, 27), (52, 25), (71, 25), (73, 27)):
            p.punto(gx, gy, "+")
    else:
        # sumergido: solo se ve su sombra y una columna de burbujas que avisa por dónde sube
        p.dibujo(A["j_shag"], 46, 38, "+")
        for k, y in enumerate(range(SUP - 2, 8, -5)):
            p.dibujo(BURBUJA, 54 + (k % 2) * 2, y, "+")
        p.centrado("SE HUNDE!", 26, "+")
    return p


def submarino():
    p = Pantalla()
    marcador(p, vidas=2, rayos=1, puntos="03410")
    # superficie lejana y rayos de luz, todo suave
    for x in range(84):
        if x % 4 < 2:
            p.punto(x, 8, "-")
    for k in range(4):
        for j in range(14):
            p.punto(10 + k * 20 + j // 2, 9 + j, "-")
    # lecho marino: borde en tinta (choca) y relleno medio, como el terreno del juego
    fondo = [44 - round(2 * math.sin(x * 0.15) + 1.5 * math.sin(x * 0.37)) for x in range(84)]
    for x, y in enumerate(fondo):
        p.punto(x, y)
        for yy in range(y + 1, 48):
            p.punto(x, yy, "+")
    # algas y el avión hundido del Vuelo 19, en tono suave
    for ax in (6, 22, 37, 78):
        for j in range(8):
            p.punto(ax + (j // 2) % 2, fondo[ax] - 1 - j, "-")
    p.dibujo(AVENGER, 50, fondo[58] - 4, "-")
    # juego
    p.dibujo(A["batiscafo"], 8, 22)
    p.dibujo(["####"], 18, 24)
    p.dibujo(["####"], 28, 24)
    p.dibujo(A["cilindro"], 52, 15)
    p.dibujo(A["buzo"], 40, 29)
    p.dibujo(["###"], 34, 31)
    p.dibujo(A["orbe_shag"], 66, 24)
    for bx, by in ((44, 22), (47, 17), (62, 35), (64, 30)):
        p.dibujo(BURBUJA, bx, by, "+")
    return p


def jefe_piramide():
    p = Pantalla()
    marcador(p, vidas=2, rayos=1, puntos="04900")
    for x in range(84):
        if x % 4 < 2:
            p.punto(x, 8, "-")
    for x in range(84):
        p.punto(x, 44)
        for yy in range(45, 48):
            p.punto(x, yy, "+")
    p.dibujo(A["j_piramide"], 58, 35)
    # anillos de luz que salen de la punta (ataque)
    for r in (5, 9):
        for k in range(r * 6):
            a = k / (r * 6) * 2 * math.pi
            if math.sin(a) < 0.3:
                p.punto(round(66 + math.cos(a) * r), round(35 + math.sin(a) * r * 0.6), "#")
    p.dibujo(A["batiscafo"], 10, 24)
    p.dibujo(["####"], 20, 26)
    p.dibujo(["####"], 32, 27)
    return p


def cartel(nivel, caso, aviso):
    p = Pantalla()
    marcador(p, puntos="00000")
    p.rect(4, 12, 76, 25)
    p.centrado(nivel, 15)
    p.centrado(caso, 23, "+")
    p.centrado(aviso, 30)
    return p


if __name__ == "__main__":
    import os
    os.makedirs("img/agua", exist_ok=True)
    for nombre, filas in A.items():
        guardar_dibujo("agua/" + nombre, filas)
    superficie().guardar("agua/escena_superficie")
    jefe_shag(True).guardar("agua/jefe_arriba")
    jefe_shag(False).guardar("agua/jefe_abajo")
    submarino().guardar("agua/escena_submarino")
    jefe_piramide().guardar("agua/jefe_piramide")
    cartel("NIVEL 7", "SHAG HARBOUR 1967", "AL MAR!").guardar("agua/cartel_7")
    cartel("NIVEL 8", "BERMUDAS 1945", "A FONDO!").guardar("agua/cartel_8")
    print("agua lista")
