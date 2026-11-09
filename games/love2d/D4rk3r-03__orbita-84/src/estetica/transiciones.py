#!/usr/bin/env python3
"""Muestras de transiciones entre pantallas de Órbita 84. Usa capturas reales del juego
(capturas/*.png, 588x336 = 84x48 a 7x), convertidas otra vez a sus píxeles y tonos, y arma
GIFs con cada estilo de cambio de pantalla. Todo dura menos de medio segundo.
Salida: img/transiciones/*.gif"""
import math
import os

from PIL import Image

import generar
from efectos import a_imagen

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(generar.SALIDA, "transiciones")
W, H = 84, 48


def leer(nombre):
    """Una captura del juego vuelta a la grilla: None fondo, '-' suave, '+' medio, '#' tinta."""
    im = Image.open(os.path.join(AQUI, "..", "capturas", nombre + ".png")).convert("RGB")
    lum = lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
    fondo, tinta = lum((249, 211, 132)), lum((91, 51, 15))
    g = []
    for y in range(H):
        fila = []
        for x in range(W):
            t = (fondo - lum(im.getpixel((x * 7 + 3, y * 7 + 3)))) / (fondo - tinta)
            fila.append("#" if t > 0.7 else "+" if t > 0.38 else "-" if t > 0.08 else None)
        g.append(fila)
    return g


def vacia(c=None):
    return [[c] * W for _ in range(H)]


def copia(g):
    return [list(f) for f in g]


BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


# cada estilo devuelve los cuadros intermedios entre la pantalla a y la b
def corte(a, b):
    return []


def persiana(a, b):
    """A · Persiana: franjas de tinta que se cierran cada 6 filas y se abren sobre la otra."""
    out = []
    for k in range(1, 7):
        g = copia(a)
        for y in range(H):
            if y % 6 < k:
                g[y] = ["#"] * W
        out.append(g)
    for k in range(5, -1, -1):
        g = copia(b)
        for y in range(H):
            if y % 6 < k:
                g[y] = ["#"] * W
        out.append(g)
    return out


def iris(a, b):
    """B · Iris: un círculo que se cierra sobre la pantalla y se abre en la siguiente,
    centrado en la nave (el foco de la acción)."""
    cx, cy = 10, 26
    out = []
    radios = [70, 52, 36, 22, 10, 3, 0]
    for r in radios:
        g = copia(a)
        for y in range(H):
            for x in range(W):
                if math.hypot(x - cx, (y - cy) * 1.2) > r:
                    g[y][x] = "#"
        out.append(g)
    for r in radios[::-1][1:]:
        g = copia(b)
        for y in range(H):
            for x in range(W):
                if math.hypot(x - cx, (y - cy) * 1.2) > r:
                    g[y][x] = "#"
        out.append(g)
    return out


def radar(a, b):
    """C · Barrido de radar: una línea gira desde el centro; detrás deja la pantalla nueva
    con una estela en tono medio, como la pantalla de un radar."""
    cx, cy = W / 2, H / 2
    out = []
    pasos = 11
    for k in range(1, pasos + 1):
        g = copia(a)
        lim = k / pasos * 2 * math.pi
        for y in range(H):
            for x in range(W):
                ang = (math.atan2(y - cy, x - cx) + math.pi / 2) % (2 * math.pi)
                if ang < lim:
                    g[y][x] = b[y][x]
                    if lim - ang < 0.35 and g[y][x] is None:
                        g[y][x] = "+" if (x + y) % 2 == 0 else None
        # la línea del barrido
        for r in range(0, 60):
            x = round(cx + math.cos(lim - math.pi / 2) * r)
            y = round(cy + math.sin(lim - math.pi / 2) * r)
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = "#"
        out.append(g)
    return out


def damero(a, b):
    """D · Damero: los píxeles se encienden en un patrón ordenado de 4x4 hasta llenar la
    pantalla y se apagan igual sobre la siguiente, como un LCD que cambia de imagen."""
    out = []
    for k in (3, 6, 9, 12, 16):
        g = copia(a)
        for y in range(H):
            for x in range(W):
                if BAYER[y % 4][x % 4] < k:
                    g[y][x] = "#"
        out.append(g)
    for k in (12, 9, 6, 3):
        g = copia(b)
        for y in range(H):
            for x in range(W):
                if BAYER[y % 4][x % 4] < k:
                    g[y][x] = "#"
        out.append(g)
    return out




def carpeta(a, b):
    """E · Carpeta: dos tapas de tinta entran desde los lados y se juntan con el «84» en el
    lomo, como si se cerrara el expediente; luego se abren sobre la pantalla nueva."""
    out = []
    def tapas(base, abierto):
        g = copia(base)
        for y in range(H):
            for x in range(W):
                if x < W / 2 - abierto or x >= W / 2 + abierto:
                    g[y][x] = "#"
        if abierto <= 0:
            for x in range(W):
                if x % 2 == 0:
                    g[H // 2 - 6][x] = "+"
                    g[H // 2 + 6][x] = "+"
            for j, f in enumerate(["###.#.#", "#.#.#.#", "###.###", "#.#...#", "###...#"]):
                for i, c in enumerate(f):
                    if c == "#":
                        g[H // 2 - 2 + j][W // 2 - 3 + i] = None
        return g
    for ab in (32, 22, 12, 4, 0):
        out.append(tapas(a, ab))
    out.append(tapas(a, 0))
    out.append(tapas(a, 0))
    for ab in (4, 12, 22, 32):
        out.append(tapas(b, ab))
    return out


def apagado(a, b):
    """F · Tele que se apaga: la pantalla se aplasta en una línea, queda un punto y la
    siguiente se abre desde esa línea."""
    out = []
    def aplastar(base, alto):
        g = vacia()
        mitad = H // 2
        if alto <= 0:
            return g
        for y in range(H):
            d = abs(y - mitad)
            if d <= alto / 2:
                src = int(mitad + (y - mitad) * H / max(alto, 1))
                if 0 <= src < H:
                    g[y] = list(base[src])
        return g
    for alto in (34, 20, 10, 4, 1):
        g = aplastar(a, alto)
        if alto == 1:
            g[H // 2] = ["#"] * W
        out.append(g)
    p = vacia()
    for x in range(W // 2 - 3, W // 2 + 4):
        p[H // 2][x] = "#"
    out.append(p)
    q = vacia()
    q[H // 2][W // 2] = "#"
    out.append(q)
    for alto in (1, 4, 12, 26, 40):
        g = aplastar(b, alto)
        if alto == 1:
            g[H // 2] = ["#"] * W
        out.append(g)
    return out


ESTILOS = {"hoy": corte, "persiana": persiana, "iris": iris, "radar": radar,
           "damero": damero, "carpeta": carpeta, "apagado": apagado}
PARES = {"nivel_mapa": ("nivel1_roswell", "mapa_hill"), "portada_prologo": ("portada_abduccion", "prologo")}


def gif(cuadros, nombre, ms=45):
    imgs = [a_imagen(c, 6) for c in cuadros]
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=ms, loop=0)


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    for par, (na, nb) in PARES.items():
        a, b = leer(na), leer(nb)
        for nombre, f in ESTILOS.items():
            medio = f(a, b)
            cuadros = [a] * 14 + medio + [b] * 18 + (f(b, a)) + [a] * 4
            gif(cuadros, "%s_%s" % (nombre, par))
    print("transiciones listas")
