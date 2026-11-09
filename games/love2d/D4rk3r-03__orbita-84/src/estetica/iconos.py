#!/usr/bin/env python3
"""Muestras de íconos para Órbita 84: las mejoras que se recogen y lo que se ve en el marcador.
La idea es una sola familia: cada poder tiene un glifo de 3x5 que es el mismo en el marcador y
dentro de la mejora que flota; lo que cambia entre las propuestas es el marco de la mejora.
Regla de siempre: todo lo que se recoge va en tinta ('#'); el tono medio '+' solo de adorno
de fondo o de lo que no se toca."""
import os

import generar
from generar import Pantalla, guardar_dibujo, NAVE, estrellas

# ------------------------------------------------------------------ hoy
HOY_MEJORAS = {
    "triple": ["#####", "#...#", "#.###", "#...#", "#####"],
    "rayo": ["#####", "#.#.#", "##.##", "#.#.#", "#####"],
    "escudo": ["#####", "#.#.#", "#...#", "##.##", "#####"],
    "vida": ["#####", "##.##", "#...#", "##.##", "#####"],
}
HOY_MARCADOR = {
    "vida": ["#.#", "###", ".#."],
    "rayo": ["..#", ".#.", "###", ".#.", "#.."],
    "pulso": ["...", ".#.", "#.#", ".#.", "..."],
}

# ------------------------------------------------------------------ glifos (3x5)
# los de hoy, retocados para que no se parezcan entre sí, y los poderes nuevos
GLIFOS = {
    "vida": ("VIDA", "corazón", ["...", "#.#", "###", ".#.", "..."]),
    "triple": ("TRIPLE", "tres tiros, como las balas del juego", ["##.", "...", "###", "...", "##."]),
    "rayo": ("RAYO", "relámpago", ["..#", ".#.", "###", ".#.", "#.."]),
    "pulso": ("PULSO", "onda que se abre", ["...", ".#.", "#.#", ".#.", "..."]),
    "escudo": ("ESCUDO", "escudo macizo con punta", ["#.#", "###", "###", "###", ".#."]),
    "tiempo": ("TIEMPO PERDIDO", "reloj de arena: todo va lento 3 s", ["###", "#.#", ".#.", "#.#", "###"]),
    "bengala": ("BENGALAS", "chispa: señuelos que atraen las balas", ["#.#", ".#.", "###", ".#.", "#.#"]),
    "sonda": ("SONDA", "satélite con paneles que dispara contigo", ["...", "#.#", "###", "#.#", "..."]),
    "tractor": ("HAZ TRACTOR", "cono de luz: atrae mejoras y se traga balas", [".#.", ".#.", "#.#", "#.#", "#.#"]),
    "carga": ("CARGADO", "tiro gordo que atraviesa", ["...", "##.", "###", "##.", "..."]),
}
ORDEN = ["vida", "triple", "rayo", "pulso", "escudo", "tiempo", "bengala", "sonda", "tractor", "carga"]


def con_marco(marco, glifo, dx=2, dy=1):
    filas = [list(f) for f in marco]
    for j, f in enumerate(glifo):
        for i, c in enumerate(f):
            if c != ".":
                filas[dy + j][dx + i] = c
    return ["".join(f) for f in filas]


# ------------------------------------------------------------------ marcos
MARCOS = {
    "capsula": ("A · Cápsula", "Un marco redondeado de 7x7, como una píldora de arcade.", [
        ".#####.",
        "#.....#",
        "#.....#",
        "#.....#",
        "#.....#",
        "#.....#",
        ".#####.",
    ], 2, 1),
    "carpeta": ("B · Carpeta", "Una carpeta de expediente con su pestaña: cada mejora es un archivo.", [
        "###....",
        "#######",
        "#.....#",
        "#.....#",
        "#.....#",
        "#.....#",
        "#.....#",
        "#######",
    ], 2, 2),
    "radar": ("C · Mira de radar", "Solo las cuatro esquinas, como la mira que fija un blanco o el marco de una foto de prueba.", [
        "##...##",
        "#.....#",
        ".......",
        ".......",
        ".......",
        "#.....#",
        "##...##",
    ], 2, 1),
}


def mejora(estilo, nombre):
    _, _, marco, dx, dy = MARCOS[estilo]
    return con_marco(marco, GLIFOS[nombre][2], dx, dy)


# ------------------------------------------------------------------ pantallas
def marcador_nuevo(p, especial="rayo", cuantos=3, vidas=3, nivel="N4", puntos="03420"):
    for i in range(vidas):
        p.dibujo(GLIFOS["vida"][2][1:4], i * 4, 1)
    for i in range(cuantos):
        p.dibujo(GLIFOS[especial][2], 22 + i * 4, 0)
    p.texto(nivel, 53 - len(nivel) * 2, 0, "+")
    p.texto(puntos, 64, 0)
    for x in range(84):
        p.punto(x, 5)


def escena(estilo):
    """Una oleada con tres mejoras flotando: así se distinguen entre balas y enemigos."""
    p = Pantalla()
    estrellas(p, 16, 4)
    marcador_nuevo(p, "rayo", 3)
    p.dibujo(NAVE, 6, 24)
    for x in (16, 24, 32):
        p.dibujo(["###"], x, 26)
    for (nombre, x, y) in (("triple", 30, 11), ("escudo", 52, 30), ("tiempo", 70, 17)):
        p.dibujo(mejora(estilo, nombre), x, y)
    # un par de enemigos y balas para comparar
    p.dibujo([".###.", "#+#+#", ".###."], 62, 36)
    p.dibujo(["##", "##"], 44, 20)
    p.dibujo(["##", "##"], 56, 13)
    return p


def escena_hoy():
    p = Pantalla()
    estrellas(p, 16, 4)
    generar.marcador(p, 3, 3, "03420")
    p.dibujo(NAVE, 6, 24)
    for x in (16, 24, 32):
        p.dibujo(["###"], x, 26)
    p.dibujo(HOY_MEJORAS["triple"], 31, 12)
    p.dibujo(HOY_MEJORAS["escudo"], 53, 31)
    p.dibujo(HOY_MEJORAS["vida"], 71, 18)
    p.dibujo([".###.", "#+#+#", ".###."], 62, 36)
    p.dibujo(["##", "##"], 44, 20)
    p.dibujo(["##", "##"], 56, 13)
    return p


def marcadores():
    """El marcador con cada especial: los de hoy (rayo, pulso) y cómo se verían los nuevos."""
    p = Pantalla(84, 6 * 5 + 4)
    for k, esp in enumerate(("rayo", "pulso", "tiempo", "bengala", "sonda")):
        sub = Pantalla()
        marcador_nuevo(sub, esp, 3, 3, "N" + str(k + 3))
        for y in range(6):
            p.px[k * 7 + y] = list(sub.px[y])
    return p


if __name__ == "__main__":
    d = "iconos/"
    os.makedirs(os.path.join(generar.SALIDA, d), exist_ok=True)
    for nombre, filas in HOY_MEJORAS.items():
        guardar_dibujo(d + "hoy_" + nombre, filas)
    for nombre, filas in HOY_MARCADOR.items():
        guardar_dibujo(d + "hoymarc_" + nombre, filas)
    for nombre in ORDEN:
        guardar_dibujo(d + "glifo_" + nombre, GLIFOS[nombre][2])
        for estilo in MARCOS:
            guardar_dibujo(d + estilo + "_" + nombre, mejora(estilo, nombre))
    escena_hoy().guardar(d + "escena_hoy")
    for estilo in MARCOS:
        escena(estilo).guardar(d + "escena_" + estilo)
    marcadores().guardar(d + "marcadores")
    print("iconos listos")
