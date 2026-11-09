#!/usr/bin/env python3
"""Muestras del nivel de Golfo Nuevo (Argentina, 1960): de noche, la Armada barre el golfo
con reflectores buscando "submarinos fantasma" y les tira cargas de profundidad.
Regla de siempre: tinta = se toca; tono medio '+' = bajo el agua y a oscuras (ni te toca ni
lo tocas); suave '-' = fondo. La noche es una trama suave; los reflectores son conos limpios."""
import math
import random
import sys

import generar
from generar import Pantalla, guardar_dibujo, marcador, NAVE

# con "invertido" la pantalla entera se da vuelta, como el nivel de noche de los celulares de
# antes: fondo oscuro y lo jugable claro. Los papeles de los tonos son los mismos.
INVERTIDO = "invertido" in sys.argv
if INVERTIDO:
    generar.FONDO, generar.TINTA = generar.TINTA, generar.FONDO
    generar.TONOS.update({"#": generar.TINTA, "+": generar.mezcla(0.45), "-": generar.mezcla(0.3)})

AGUA = 31  # línea del agua

# --------------------------------------------------------------- dibujos nuevos
G = {}
# el submarino fantasma: largo, con torre, sin bandera ni número
G["fantasma"] = [
    "........###.........",
    "........#+#.........",
    ".......#####........",
    "..################..",
    ".#+#+#+#+#+#+#+#+##.",
    "##################..",
]
G["periscopio"] = [
    "##",
    ".#",
    ".#",
    ".#",
]
G["carga"] = [
    ".#.",
    "###",
    "#+#",
    "###",
]
G["buque"] = [  # silueta de la corbeta en el horizonte (va en suave)
    "......#.........",
    "......##........",
    "....######......",
    "..###########...",
    "################",
]
G["cilindro"] = [
    "...##....",
    ".#######.",
    "#+#+#+###",
    ".#######.",
]


def noche(p, semilla=1, conos=()):
    """Cielo y mar de noche: una trama suave pareja; dentro de cada cono de reflector, limpio.
    Invertido, la noche ya es el fondo oscuro: el cielo queda vacío y el haz se ve en suave."""
    if INVERTIDO:
        for y in range(6, 48):
            for x in range(84):
                if en_cono(x, y, conos) and (x * 3 + y) % 7 != 0:
                    p.punto(x, y, "-")
        r = random.Random(semilla)
        for _ in range(12):
            p.punto(r.randrange(84), r.randrange(7, AGUA - 8), "-")
        return
    for y in range(6, 48):
        for x in range(84):
            if not en_cono(x, y, conos):
                p.punto(x, y, "-")
            elif (x * 3 + y) % 7 == 0 and y > 8:
                p.punto(x, y, "-")  # polvo en el haz
    r = random.Random(semilla)
    for _ in range(8):  # estrellas: huecos claros en la trama
        x, y = r.randrange(84), r.randrange(7, AGUA - 8)
        p.px[y][x] = None


def en_cono(x, y, conos):
    """Cono de luz que sale de (ox, oy) hacia (dx, AGUA o más abajo), con su ancho."""
    for ox, oy, dx, dy, ancho in conos:
        if (dy - oy) == 0:
            continue
        t = (y - oy) / (dy - oy)
        if 0 <= t <= 1.25:
            cx = ox + (dx - ox) * t
            if abs(x - cx) <= 0.5 + ancho * t:
                return True
    return False


def mar(p, conos=()):
    """Línea del agua en tinta (las olas brillan donde pega la luz) y bajo ella el agua oscura."""
    for x in range(84):
        if en_cono(x, AGUA, conos) or x % 4 != 3:
            p.punto(x, AGUA)
    for x in range(0, 84, 7):
        p.punto(x + 2, AGUA + 3, "-")


def buques(p):
    p.dibujo(G["buque"], 52, AGUA - 5, "+")
    p.dibujo(G["buque"], 8, AGUA - 5, "+")


def silueta(p, filas, x, y, conos):
    """Algo bajo el agua: entero en tinta si el cono lo toca (se puede tocar), si no en tono medio."""
    tocado = any(en_cono(x + i, y + j, conos) for j, f in enumerate(filas) for i, c in enumerate(f) if c != ".")
    for j, f in enumerate(filas):
        for i, c in enumerate(f):
            if c != ".":
                p.punto(x + i, y + j, c if tocado else "+")


def escena_reflectores():
    """Opción A: sobre el agua; el reflector revela al cilindro que va hundido."""
    conos = [(60, AGUA - 3, 30, 47, 5)]
    p = Pantalla()
    noche(p, 1, conos)
    marcador(p, puntos="06120")
    buques(p)
    mar(p, conos)
    # el cilindro iluminado (tinta: se le puede disparar) y otro a oscuras (tono medio)
    silueta(p, G["cilindro"], 32, AGUA + 6, conos)
    silueta(p, G["cilindro"], 66, AGUA + 9, conos)
    p.dibujo(NAVE, 8, AGUA - 9)
    p.dibujo(["###"], 18, AGUA - 7)
    # torpedo que baja hacia el cilindro iluminado
    p.dibujo(["#", "#"], 30, AGUA + 2)
    return p


def escena_cargas():
    """Opción B: bajo el agua en batiscafo; desde arriba caen cargas de profundidad."""
    p = Pantalla()
    for y in range(6, 48):  # todo es agua oscura
        for x in range(84):
            if (x + y) % 2 == 0 and y > 9 and not INVERTIDO:
                p.punto(x, y, "-")
    marcador(p, vidas=2, puntos="06480")
    for x in range(84):  # la superficie, arriba de todo
        p.punto(x, 9, "-" if x % 3 else "+")
    p.dibujo(G["buque"], 40, 5, "+")
    # dos cargas cayendo; su aviso es una columna punteada hasta donde van a reventar
    for cx, cy, revienta in ((28, 16, 34), (58, 12, 26)):
        p.dibujo(G["carga"], cx, cy)
        for y in range(cy + 5, revienta, 2):
            p.punto(cx + 1, y, "+")
        p.rect(cx - 2, revienta - 1, 7, 5, "+")
    # batiscafo del jugador y un cilindro cruzando
    p.dibujo(["...#...", "..####.", "#######", "#+#+###", "..####."], 8, 30)
    p.dibujo(["##"], 17, 32)
    p.dibujo(G["cilindro"], 64, 38)
    # fondo del golfo
    for x in range(84):
        h = 2 + int(1.5 * math.sin(x * 0.23) + math.sin(x * 0.07))
        for y in range(48 - h, 48):
            p.punto(x, y, "#" if y == 48 - h else "-")
    return p


def jefe(iluminado):
    """El fantasma asoma el periscopio; solo recibe daño mientras lo alumbra un reflector."""
    conos = [(60, AGUA - 3, 60, 47, 6)] if iluminado else [(16, AGUA - 3, 10, 47, 6)]
    p = Pantalla()
    noche(p, 3, conos)
    marcador(p, puntos="08930")
    buques(p)
    mar(p, conos)
    silueta(p, G["fantasma"], 50, AGUA + 5, conos)
    p.dibujo(G["periscopio"], 58, AGUA - 3)
    p.dibujo(NAVE, 8, AGUA - 10)
    if iluminado:
        p.dibujo(["###"], 22, AGUA - 8)
        p.dibujo(["#", "#"], 50, AGUA + 1)
        p.centrado("ALUMBRADO!", 9)
    else:
        # a oscuras dispara desde el periscopio y es intocable
        for k, (bx, by) in enumerate(((50, 22), (42, 19), (34, 17))):
            p.dibujo(["##", "##"], bx, by)
    return p


def jefe_dos():
    """Fase 2: eran dos (como en los informes de 1960); el reflector alumbra a uno a la vez."""
    conos = [(24, AGUA - 3, 18, 47, 6)]
    p = Pantalla()
    noche(p, 5, conos)
    marcador(p, puntos="09410")
    buques(p)
    mar(p, conos)
    silueta(p, G["fantasma"], 6, AGUA + 9, conos)
    silueta(p, G["fantasma"], 56, AGUA + 4, conos)
    p.dibujo(NAVE, 40, AGUA - 12)
    # carga de profundidad que tira la Armada: revienta en el agua y sube un géiser
    p.dibujo(G["carga"], 62, AGUA - 10)
    for y in range(AGUA - 5, AGUA + 1, 2):
        p.punto(63, y, "+")
    return p


def cartel():
    p = Pantalla()
    noche(p, 7)
    marcador(p, puntos="00000")
    for y in range(12, 37):
        for x in range(4, 80):
            p.px[y][x] = None
    p.rect(4, 12, 76, 25)
    p.centrado("NIVEL 10", 15)
    p.centrado("GOLFO NUEVO 1960", 23, "+")
    p.centrado("A OSCURAS!", 30)
    return p


if __name__ == "__main__":
    import os
    d = "golfo_inv/" if INVERTIDO else "golfo/"
    os.makedirs("img/" + d, exist_ok=True)
    for nombre, filas in G.items():
        guardar_dibujo(d + nombre, filas)
    escena_reflectores().guardar(d + "escena_reflectores")
    escena_cargas().guardar(d + "escena_cargas")
    jefe(False).guardar(d + "jefe_oscuras")
    jefe(True).guardar(d + "jefe_alumbrado")
    jefe_dos().guardar(d + "jefe_dos")
    cartel().guardar(d + "cartel_10")
    print("golfo lista", "(invertido)" if INVERTIDO else "")
