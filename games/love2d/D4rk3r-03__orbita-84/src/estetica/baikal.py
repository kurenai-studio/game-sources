#!/usr/bin/env python3
"""Muestras del nivel del lago Baikal (1982): lago helado con nadadores plateados.
Regla de siempre: tinta = se toca; tono medio '+' = bajo el hielo (ni te toca ni lo tocas); suave '-' = fondo."""
import math
import random

from generar import Pantalla, guardar_dibujo, marcador, NAVE

HIELO = 37  # borde de arriba de la capa de hielo

# --------------------------------------------------------------- dibujos nuevos
B = {}
B["buzo_plateado"] = [
    ".###.",
    "#+#+#",
    ".###.",
    "#####",
    "#.#.#",
    ".#.#.",
]
B["luz_hielo"] = [
    "..#..",
    ".#+#.",
    "#+++#",
    ".#+#.",
    "..#..",
]
B["oruga"] = [
    "..#.......",
    ".####.....",
    "##########",
    "#########.",
    "#.#.#.#.#.",
    ".#.#.#.#..",
]
# jefe: el gigante plateado de tres metros asoma por un agujero grande
B["gigante"] = [
    "......#####......",
    "....##+++++##....",
    "...#+++++++++#...",
    "...#+#######+#...",
    "...#+#.....#+#...",
    "...#+#######+#...",
    "....##+++++##....",
    "..#############..",
    ".###+#######+###.",
    "####+#######+####",
    "##.#+#######+#.##",
]
B["gigante_visor"] = [
    "......#####......",
    "....##+++++##....",
    "...#+++++++++#...",
    "...#+#######+#...",
    "...#+#+#+#+#+#...",
    "...#+#######+#...",
    "....##+++++##....",
    "..#############..",
    ".###+#######+###.",
    "####+#######+####",
    "##.#+#######+#.##",
]
BLOQUE = ["###", "#+#", "###"]


def cielo(p, semilla):
    """Nieve que cae y montes de Siberia al fondo, todo suave."""
    r = random.Random(semilla)
    for _ in range(22):
        p.punto(r.randrange(84), r.randrange(7, HIELO - 1), "-")
    for x in range(84):
        h = 6 + 3 * math.sin(x * 0.11) + 2 * math.sin(x * 0.29 + 1)
        y = int(HIELO - 2 - h)
        p.punto(x, y, "-")
        if x % 3 == 0:
            p.punto(x, y + 2, "-")


def hielo(p, agujeros=(), grietas=()):
    """Capa de hielo: borde en tinta (es el piso), cuerpo en tono medio con burbujas
    congeladas (huecos claros), y agua oscura debajo."""
    r = random.Random(9)
    tapado = set()
    for ax, aw in agujeros:
        tapado.update(range(ax, ax + aw))
    for x in range(84):
        if x in tapado:
            continue
        p.punto(x, HIELO)
        for y in range(HIELO + 1, HIELO + 4):
            p.punto(x, y, "+")
    for _ in range(14):  # burbujas de metano atrapadas en el hielo
        bx, by = r.randrange(84), r.randrange(HIELO + 1, HIELO + 4)
        if bx not in tapado:
            p.px[by][bx] = None
    for x in range(84):
        if x in tapado:
            # agua que se mueve dentro del agujero
            if x % 2 == 0:
                p.punto(x, HIELO + 2, "+")
            continue
    for y in range(HIELO + 6, 48, 3):
        for x in range(84):
            if (x * 5 + y * 3) % 11 == 0:
                p.punto(x, y, "-")
    for ax, aw in agujeros:  # bordes del agujero en tinta
        for y in range(HIELO, HIELO + 4):
            p.punto(ax - 1, y)
            p.punto(ax + aw, y)
    for gx, largo in grietas:  # grieta: el borde se levanta y el hielo se raja
        p.px[HIELO][gx] = None
        p.punto(gx - 1, HIELO - 1)
        p.punto(gx + 1, HIELO - 1)
        p.punto(gx + 2, HIELO - 2)
        for k in range(1, largo + 1):
            for d in (-k, k):
                x = gx + d
                y = HIELO + (k % 3)
                if 0 <= y < 48:
                    p.px[y][x] = "#"


def escena_vuelo():
    p = Pantalla()
    cielo(p, 2)
    marcador(p, puntos="05210")
    hielo(p, agujeros=[(56, 7)], grietas=[(30, 3)])
    # bajo el hielo: sombras de los nadadores
    p.dibujo(B["buzo_plateado"], 28, 41, "+")
    p.dibujo(B["buzo_plateado"], 70, 42, "+")
    # nave y balas
    p.dibujo(NAVE, 6, 18)
    p.dibujo(["###"], 16, 20)
    p.dibujo(["###"], 26, 20)
    # buzo saliendo por el agujero, con trozos de hielo volando
    p.dibujo(B["buzo_plateado"], 57, HIELO - 5)
    for bx, by in ((53, 29), (63, 27), (55, 24)):
        p.dibujo(["##", "##"], bx, by)
    # luz que sube desde el hielo dejando una columna punteada
    p.dibujo(B["luz_hielo"], 42, 12)
    for y in range(18, HIELO, 2):
        p.punto(44, y, "+")
    return p


def escena_oruga():
    p = Pantalla()
    cielo(p, 4)
    marcador(p, vidas=2, puntos="05640")
    hielo(p, agujeros=[(36, 8)], grietas=[(66, 3)])
    # la oruga patina: rayas detrás muestran que sigue de largo
    p.dibujo(B["oruga"], 18, HIELO - 6)
    for k in range(3):
        p.punto(14 - k * 3, HIELO - 2, "+")
        p.punto(15 - k * 3, HIELO - 2, "+")
    # cohete hacia arriba y bomba que agrieta el hielo
    p.dibujo([".#.", "###", "#.#"], 20, 20)
    p.dibujo(["#", "#"], 52, 26)
    # buzo asomando por el agujero
    p.dibujo(B["buzo_plateado"], 38, HIELO - 3)
    p.dibujo(["#"], 40, 28)
    p.dibujo(["#"], 41, 24)
    # sombra bajo el hielo
    p.dibujo(B["buzo_plateado"], 64, 42, "+")
    return p


def jefe_gigante(visor_abierto):
    p = Pantalla()
    cielo(p, 7)
    marcador(p, puntos="07450")
    hielo(p, agujeros=[(52, 21)])
    p.dibujo(B["gigante_visor" if visor_abierto else "gigante"], 54, HIELO - 8)
    if visor_abierto:
        # rayo del visor y la nave a su altura
        p.dibujo(NAVE, 8, 26)
        p.dibujo(["###"], 20, 28)
        p.dibujo(["###"], 34, 28)
        for x in range(36, 56, 3):
            p.punto(x, 30, "#")
    else:
        # lanza bloques de hielo en arco
        p.dibujo(NAVE, 8, 16)
        for k, (bx, by) in enumerate(((44, 18), (34, 14), (24, 16))):
            p.dibujo(BLOQUE, bx, by)
        for k in range(10):
            t = k / 9
            p.punto(52 - t * 26, 22 - math.sin(t * math.pi) * 9, "-")
    return p


def jefe_bajo_hielo():
    p = Pantalla()
    cielo(p, 8)
    marcador(p, puntos="07450")
    hielo(p, agujeros=[(52, 21)], grietas=[(22, 4)])
    # el agujero se cierra con hielo nuevo (tono medio) y el gigante nada debajo
    p.dibujo(B["gigante"], 14, HIELO + 1, "+")
    p.dibujo(NAVE, 30, 18)
    p.centrado("SE ESCONDE!", 26, "+")
    return p


def cartel():
    p = Pantalla()
    marcador(p, puntos="00000")
    p.rect(4, 12, 76, 25)
    p.centrado("NIVEL 9", 15)
    p.centrado("BAIKAL 1982", 23, "+")
    p.centrado("AL HIELO!", 30)
    return p


if __name__ == "__main__":
    import os
    os.makedirs("img/baikal", exist_ok=True)
    for nombre, filas in B.items():
        guardar_dibujo("baikal/" + nombre, filas)
    escena_vuelo().guardar("baikal/escena_vuelo")
    escena_oruga().guardar("baikal/escena_oruga")
    jefe_gigante(False).guardar("baikal/jefe_bloques")
    jefe_gigante(True).guardar("baikal/jefe_visor")
    jefe_bajo_hielo().guardar("baikal/jefe_bajo")
    cartel().guardar("baikal/cartel_9")
    print("baikal lista")
