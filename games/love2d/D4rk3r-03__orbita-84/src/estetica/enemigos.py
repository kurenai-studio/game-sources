#!/usr/bin/env python3
"""Muestras del segundo cuadro de animación para los enemigos que hoy están quietos.
El juego alterna el dibujo con su versión "_b" cuatro veces por segundo; aquí se proponen
dos versiones (A y B) para cada uno, del mismo tamaño que el dibujo actual.
Salida: img/enemigos/*.gif"""
import os

from PIL import Image

import generar
from efectos import DIB, a_imagen

SALIDA = os.path.join(generar.SALIDA, "enemigos")
CUADRO_MS = 250  # 4 cuadros por segundo, como animado() en main.lua

# nombre: (caso, (idea A, filas A), (idea B, filas B))
PROPUESTAS = {
    "avispa": ("Cabeza gris",
               ("Entorna los ojos", [".#####.", "#######", "##+#+##", ".#####.", "..###..", "...#..."]),
               ("El cuello se mece", [".#####.", "#######", "#++#++#", ".#####.", "..###..", "..#...."])),
    "caparazon": ("Triángulo belga",
                  ("Las luces se pasan al centro", [".......#", ".....###", "...#####", "#####+##", "...#####", ".....###", ".......#"]),
                  ("Puntas que destellan", [".......+", ".....###", "...##+##", "+#######", "...##+##", ".....###", ".......+"])),
    "dardo": ("Tic Tac",
              ("La luz late", [".#####.", "##+++##", ".#####."]),
              ("Se ladea", ["..####.", "#+++++#", ".####.."])),
    "espora": ("Orbe de Hessdalen",
               ("El núcleo se invierte", [".###.", "#+#+#", "#+++#", "#+#+#", ".###."]),
               ("Echa destellos", [".#.#.", "#+++#", ".+#+.", "#+++#", ".#.#."])),
    "lazo": ("Luces de Lubbock",
             ("Tonos invertidos", ["..+..", ".#+#.", "++#++", ".#+#.", "..+.."]),
             ("Gira en X", ["#...#", ".#+#.", "..+..", ".#+#.", "#...#"])),
    "medusa": ("Platillo de Arnold",
               ("Patas que se abren", ["..##..", ".#++#.", "######", "#....#"]),
               ("Luces en el borde", ["..##..", ".####.", "#+##+#", ".#..#."])),
    "minador": ("Cigarro",
                ("Ventanillas que corren", ["..#####..", ".#######.", "##+#+#+##", ".#######.", "..#####.."]),
                ("Abre las escotillas", ["..#####..", ".#######.", "#+#+#+#+#", ".#######.", "..#.#.#.."])),
    "orbitador": ("Círculo de cultivo",
                  ("La cruz gira", ["..###..", ".#...#.", "#.#.#.#", "#..+..#", "#.#.#.#", ".#...#.", "..###.."]),
                  ("El anillo gira", ["..#.#..", ".#...#.", "...#...", "#.#+#.#", "...#...", ".#...#.", "..#.#.."])),
    "platillo": ("Platillo de la portada",
                 ("Patas que titilan", ["..###..", ".#+++#.", "#######", "#.#.#.#"]),
                 ("Luces en el borde", ["..###..", ".#+++#.", "#+#+#+#", ".#.#.#."])),
    "torpedo": ("Torpedo del batiscafo",
                ("Estela más larga", ["++##"]),
                ("Hélice que corta", [".###"])),
    "torreta": ("Antena del Área 51",
                ("Los brazos se cierran", [".#.#.", ".###.", "..#..", "#####"]),
                ("Luz en la punta", ["#.+.#", ".###.", "..#..", "#####"])),
    "francotirador": ("Caballero Negro",
                      ("Pliega los paneles", [".#...#.", "##.#.##", "###+###", "##.#.##", ".#...#."]),
                      ("El centro se enciende", ["##...##", "##...##", "###+###", "##...##", "##...##"])),
    "roca": ("Meteorito",
             ("Rueda", [".##.", "##+#", "#+##", ".##."]),
             ("Grieta encendida", [".##.", "####", "#++#", ".##."])),
    "vaca": ("Vaca de la portada",
             ("Camina", ["#.###.", "######", "#....#"]),
             ("Patalea", ["#.###.", "######", "..##.."])),
}


def grilla(filas):
    return [[None if c == "." else c for c in f] for f in filas]


def lienzo(w, h):
    return [[None] * w for _ in range(h)]


def poner(g, filas, x, y):
    for j, f in enumerate(filas):
        for i, c in enumerate(f):
            if c != ".":
                g[y + j][x + i] = c


def ficha(filas, marco=13):
    """El dibujo centrado en un recuadro de marco x marco píxeles del LCD."""
    g = lienzo(marco, marco - 2)
    h, w = len(filas), len(filas[0])
    poner(g, filas, (marco - w) // 2, (marco - 2 - h) // 2)
    return g


def gif(cuadros, nombre, escala=12):
    imgs = [a_imagen(c, escala) for c in cuadros]
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=CUADRO_MS, loop=0, optimize=False, disposal=1)


def escena(opcion):
    """Los 14 juntos en la pantalla de 84x48, para verlos como en el juego."""
    orden = list(PROPUESTAS)
    cuadros = []
    for k in range(8):
        g = lienzo(84, 48)
        for i, n in enumerate(orden):
            col, fila = i % 5, i // 5
            filas = DIB[n] if (k % 2 == 0 or opcion == "hoy") else PROPUESTAS[n][1 if opcion == "a" else 2][1]
            w, h = len(filas[0]), len(filas)
            cx, cy = 9 + col * 16, 8 + fila * 15
            poner(g, filas, cx - w // 2, cy - h // 2)
        cuadros.append(g)
    imgs = [a_imagen(c, 6) for c in cuadros]
    imgs[0].save(os.path.join(SALIDA, "escena_%s.gif" % opcion), save_all=True, append_images=imgs[1:],
                 duration=CUADRO_MS, loop=0, optimize=False, disposal=1)


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    for n, (caso, a, b) in PROPUESTAS.items():
        hoy = DIB[n]
        for _, filas in (a, b):
            assert len(filas) == len(hoy) and all(len(f) == len(hoy[0]) for f in filas), n
        gif([ficha(hoy)] * 2, n + "_hoy")
        gif([ficha(hoy), ficha(a[1])], n + "_a")
        gif([ficha(hoy), ficha(b[1])], n + "_b")
    for o in ("hoy", "a", "b"):
        escena(o)
    print("enemigos listos")
