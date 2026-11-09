#!/usr/bin/env python3
"""Tres estilos de hielo para el nivel del Baikal. Misma escena en los tres:
oruga, un agujero con trozos flotando, una grieta y un nadador bajo el hielo."""
import math
import random

from generar import Pantalla, marcador
from baikal import B, cielo

TOPE = 36  # borde de arriba del hielo
AGUJERO = (44, 9)
GRIETA = 70


def base(p, semilla):
    cielo(p, semilla)
    marcador(p, puntos="05210")
    # agua bajo el hielo
    for y in range(TOPE + 8, 48, 3):
        for x in range(84):
            if (x * 5 + y * 3) % 11 == 0:
                p.punto(x, y, "-")


def hueco(x):
    return AGUJERO[0] <= x < AGUJERO[0] + AGUJERO[1]


def agujero_comun(p, grosor):
    ax, aw = AGUJERO
    # agua que se mueve y trozos de hielo flotando
    for x in range(ax, ax + aw):
        if x % 2 == 0:
            p.punto(x, TOPE + 2, "+")
    p.dibujo(["##", "++"], ax + 1, TOPE + 1)
    p.dibujo(["###", "+++"], ax + 5, TOPE + 1)
    # bordes rotos: escalones irregulares
    for k, dy in enumerate((0, 1, 1, 2, 3, 3, 4)):
        if dy < grosor:
            p.punto(ax - 1, TOPE + dy)
            p.punto(ax + aw, TOPE + min(grosor - 1, (dy + 1)))


def reflejo(p, filas, x, desde, hasta, tono=None):
    """Reflejo de la oruga en el hielo: el dibujo dado vuelta, sin pintar (brillo)
    o en el tono indicado, solo dentro de las filas del hielo."""
    for j, f in enumerate(reversed(filas)):
        y = desde + j
        if y > hasta:
            break
        for i, c in enumerate(f):
            if c != "." and (i + j) % 2 == 0:
                if tono:
                    p.punto(x + i, y, tono)
                else:
                    p.px[y][x + i] = None


def escena(estilo):
    p = Pantalla()
    base(p, 3)
    if estilo == "placa":
        placa(p)
    else:
        claro(p)
    # sombra bajo el hielo, oruga y grieta
    p.dibujo(B["buzo_plateado"], GRIETA - 2, 43, "+")
    p.dibujo(B["oruga"], 12, TOPE - 6)
    if estilo == "placa":
        reflejo(p, B["oruga"], 12, TOPE + 1, TOPE + 4)
    else:
        reflejo(p, B["oruga"], 12, TOPE + 2, TOPE + 5, "-")
    p.punto(GRIETA - 1, TOPE - 1)
    p.punto(GRIETA + 1, TOPE - 1)
    p.punto(GRIETA + 2, TOPE - 2)
    for k in range(1, 4):
        p.px[TOPE + k % 4][GRIETA - k] = "#"
        p.px[TOPE + (k + 1) % 4][GRIETA + k] = "#"
    return p


def placa(p):
    """A: placa de hielo brillante. Borde de arriba en tinta, fila de brillo, cuerpo en
    tono medio con destellos en diagonal, borde de abajo en tinta mellado y carámbanos."""
    for x in range(84):
        if hueco(x):
            continue
        p.punto(x, TOPE)
        for y in range(TOPE + 2, TOPE + 5):
            p.punto(x, y, "+")
        # borde de abajo mellado: la placa flota sobre el agua
        p.punto(x, TOPE + 5 if (x * 7) % 5 else TOPE + 4)
        if (x * 7) % 11 == 0:
            p.punto(x, TOPE + 6, "+")
            p.punto(x, TOPE + 7, "+")
        elif (x * 3) % 7 == 0:
            p.punto(x, TOPE + 6, "+")
    # destellos: rayitas en diagonal sin pintar
    for sx in (5, 27, 52, 63, 79):
        for k in range(3):
            if not hueco(sx + k):
                p.px[TOPE + 4 - k][sx + k] = None
    # brillo de la fila de arriba solo a trozos
    for x in range(84):
        if not hueco(x) and (x // 6) % 3 == 2:
            p.punto(x, TOPE + 1, "+")
    # chispa sobre el hielo
    p.dibujo([".#.", "#.#", ".#."], 33, TOPE - 4)
    agujero_comun(p, 6)


def claro(p):
    """B: el hielo transparente del Baikal. Borde doble arriba y borde abajo en tinta;
    por dentro casi vacío, con grietas finas y columnas de burbujas congeladas."""
    for x in range(84):
        if hueco(x):
            continue
        p.punto(x, TOPE)
        p.punto(x, TOPE + 1, "+")
        p.punto(x, TOPE + 6)
    r = random.Random(11)
    for cx in (4, 26, 58, 78):
        x, y = cx, TOPE + 2
        for _ in range(6):
            if not hueco(x) and y < TOPE + 6:
                p.punto(x, y, "+")
            x += r.choice((-1, 1))
            y += r.choice((0, 1))
    for bx in (34, 66):
        for y in (TOPE + 2, TOPE + 4):
            p.dibujo([".+.", "+.+", ".+."], bx + (y % 2), y - 1)
    agujero_comun(p, 7)


def zoom(p, x0, y0, w, h):
    q = Pantalla(w, h)
    for y in range(h):
        for x in range(w):
            q.px[y][x] = p.px[y0 + y][x0 + x]
    return q


if __name__ == "__main__":
    import os
    os.makedirs("img/hielo", exist_ok=True)
    for estilo in ("placa", "claro"):
        p = escena(estilo)
        p.guardar("hielo/" + estilo)
        zoom(p, 30, 28, 48, 18).guardar("hielo/" + estilo + "_cerca", escala=14)
    print("hielo listo")
