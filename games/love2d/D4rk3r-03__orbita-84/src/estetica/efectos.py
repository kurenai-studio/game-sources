#!/usr/bin/env python3
"""Muestras animadas de Órbita 84: explosiones (tres estilos y la muerte de un jefe), ideas para
el escudo de los jefes y la galería de los sprites de jefe como están hoy.
Los dibujos se leen de juego/datos.lua, así que las muestras usan los sprites reales.
Salida: img/efectos/*.gif y *.png"""
import math
import os
import random
import re

from PIL import Image, ImageDraw

import generar
from generar import Pantalla, estrellas, NAVE, TONOS, mezcla

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(generar.SALIDA, "efectos")

_fuente = open(os.path.join(AQUI, "..", "juego", "datos.lua"), encoding="utf-8").read()
DIB = {}
for _m in re.finditer(r'(\w+)\s*=\s*\{\s*((?:"[^"]*"\s*,?\s*(?:--[^\n]*\n)?\s*)+)\}', _fuente):
    DIB[_m.group(1)] = re.findall(r'"([^"]*)"', _m.group(2))

ESCALA = 6


def a_imagen(px, escala=ESCALA):
    h, w = len(px), len(px[0])
    img = Image.new("RGB", (w * escala, h * escala), generar.FONDO)
    d = ImageDraw.Draw(img)
    for y in range(h):
        for x in range(w):
            c = px[y][x]
            col = TONOS[c] if c else mezcla(0.04)
            x0, y0 = x * escala, y * escala
            d.rectangle([x0, y0, x0 + escala - 2, y0 + escala - 2], fill=col)
    return img


def guardar_gif(cuadros, nombre, ms=60):
    imgs = [a_imagen(c.px) for c in cuadros]
    imgs[0].save(os.path.join(SALIDA, nombre + ".gif"), save_all=True, append_images=imgs[1:],
                 duration=ms, loop=0, optimize=False, disposal=1)


def base(semilla=4, marcador=True):
    p = Pantalla()
    estrellas(p, 16, semilla)
    if marcador:
        generar.marcador(p, 3, 2, "03420")
    return p


def copia(p):
    q = Pantalla()
    q.px = [list(f) for f in p.px]
    return q


def tam(nombre):
    d = DIB[nombre]
    return len(d[0]), len(d)


# ================================================================== explosiones
# A · Chispa: un destello que se abre en estrella y se apaga en cuatro puntas
CHISPA = [
    ["...", ".#.", "..."],
    [".#.", "###", ".#."],
    ["...#...", ".#...#.", "..###..", "#.###.#", "..###..", ".#...#.", "...#..."],
    ["..#.#..", ".......", "#.....#", ".......", "#.....#", ".......", "..#.#.."],
    ["#.....#", ".......", ".......", "...+...", ".......", ".......", "#.....#"],
]
# B · Destello y humo: anillo en tinta y un humo en tono medio que sube y se deshace
HUMO = [
    [".###.", "#####", "#####", "#####", ".###."],
    [".###.", "#...#", "#...#", "#...#", ".###."],
    ["..#.#..", ".#...#.", "#.....#", ".......", "#.....#", ".#...#.", "..#.#.."],
    ["..+.+..", ".+...+.", ".......", "...+...", ".......", ".+...+.", "..+.+.."],
    [".......", "..+.+..", ".+++++.", "..+++..", ".......", ".......", "......."],
    [".......", "..+....", ".++.+..", "...+...", ".......", ".......", "......."],
    [".......", "....+..", "..+....", ".......", ".......", ".......", "......."],
]



def rombo(r, tono="#", salto=1):
    """Anillo en forma de rombo de radio r (distancia de Manhattan)."""
    n = 2 * r + 1
    f = [["."] * n for _ in range(n)]
    for y in range(n):
        for x in range(n):
            if abs(x - r) + abs(y - r) == r and (x - r) % salto == 0:
                f[y][x] = tono
    return ["".join(x) for x in f]


def juntar(*capas):
    """Superpone dibujos centrados (el primero manda el tamaño máximo)."""
    n = max(len(c) for c in capas)
    out = [["."] * n for _ in range(n)]
    for c in capas:
        o = (n - len(c)) // 2
        for y, fila in enumerate(c):
            for x, ch in enumerate(fila):
                if ch != ".":
                    out[o + y][o + x] = ch
    return ["".join(f) for f in out]


# D · Cruz: ocho rayos que crecen, se despegan del centro y se apagan en las puntas
CRUZ = [
    [".#.", "###", ".#."],
    ["#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#"],
    ["#...#...#", ".........", "..#.#.#..", ".........", "#.#...#.#", ".........", "..#.#.#..", ".........", "#...#...#"],
    ["+...+...+", ".........", ".........", ".........", "+.......+", ".........", ".........", ".........", "+...+...+"],
]
# E · Onda: un rombo que se abre como onda de choque, con un eco en tono medio detrás
ONDA = [
    juntar(["###", "###", "###"]),
    juntar(rombo(2), ["#"]),
    juntar(rombo(3), rombo(1, "+")),
    juntar(rombo(4, "#", 2), rombo(2, "+")),
    juntar(rombo(5, "+", 2), rombo(3, "+", 2)),
]
# F · Chispa y humo: el destello de A y el humo de B
CHISPA_HUMO = CHISPA[:3] + HUMO[3:]
# G · Disolución: una bola maciza que se deshace en damero, como un LCD que se apaga
DISUELVE = [
    [".###.", "#####", "#####", "#####", ".###."],
    ["..###..", ".#####.", "#######", "#######", "#######", ".#####.", "..###.."],
    ["..#.#..", ".#.#.#.", "#.#.#.#", ".#.#.#.", "#.#.#.#", ".#.#.#.", "..#.#.."],
    ["..+....", ".+...+.", "..+.+..", ".+...+.", "+.+...+", "...+...", "..+...."],
    [".......", "...+...", ".......", ".+...+.", ".......", "...+...", "......."],
]
ESTILOS_EXPLOSION = {"chispa": CHISPA, "humo": HUMO, "cruz": CRUZ, "onda": ONDA,
                     "chispa_humo": CHISPA_HUMO, "disuelve": DISUELVE}


def poner_centrado(p, filas, cx, cy):
    w, h = len(filas[0]), len(filas)
    p.dibujo(filas, cx - w // 2, cy - h // 2)


class Esquirlas:
    """C · Esquirlas: el enemigo se rompe en sus propios píxeles, que salen volando y caen;
    al final quedan en tono medio (ya no golpean) y se apagan."""

    def __init__(self, nombre, x, y, fuerza=26, semilla=1):
        r = random.Random(semilla)
        d = DIB[nombre]
        w, h = len(d[0]), len(d)
        cx, cy = x + w / 2, y + h / 2
        self.p = []
        for j, f in enumerate(d):
            for i, c in enumerate(f):
                if c != ".":
                    px, py = x + i, y + j
                    a = math.atan2(py - cy + r.uniform(-.5, .5), px - cx + r.uniform(-.5, .5))
                    v = fuerza * r.uniform(0.5, 1.1)
                    self.p.append([px, py, math.cos(a) * v, math.sin(a) * v - 8, r.uniform(0.35, 0.6)])

    def paso(self, p, t, dt=0.06):
        for e in self.p:
            if t > e[4] + 0.25:
                continue
            p.punto(e[0], e[1], "#" if t < e[4] else "+")
            e[0] += e[2] * dt
            e[1] += e[3] * dt
            e[3] += 60 * dt
            e[2] *= 0.9


def escena_explosion(estilo):
    """Tres enemigos que la nave revienta uno tras otro."""
    fondo = base(6)
    fondo.dibujo(NAVE, 4, 24)
    blancos = [("chispa", 30, 14), ("rombo", 50, 30), ("platillo", 66, 18)]
    cuadros = []
    rotos = {}
    cuadros_por = 9
    total = cuadros_por * 3 + 10
    for k in range(total):
        p = copia(fondo)
        for n, (nombre, x, y) in enumerate(blancos):
            inicio = n * cuadros_por
            w, h = tam(nombre)
            cx, cy = x + w // 2, y + h // 2
            if k < inicio:
                p.dibujo(DIB[nombre], x, y)
                # el tiro que va hacia él
                if k >= inicio - 4:
                    bx = 12 + int((x - 12) * (k - inicio + 4) / 4)
                    p.dibujo(["###"], bx, cy)
                continue
            f = k - inicio
            if estilo in ESTILOS_EXPLOSION:
                cuadros_e = ESTILOS_EXPLOSION[estilo]
                if f < len(cuadros_e):
                    sube = (1 if f >= 4 else 0) + (1 if f >= 5 else 0) if "humo" in estilo else 0
                    poner_centrado(p, cuadros_e[f], cx, cy - sube)
            else:
                if n not in rotos:
                    rotos[n] = Esquirlas(nombre, x, y, semilla=n + 3)
                if f == 0:
                    poner_centrado(p, [".#.", "###", ".#."], cx, cy)
                rotos[n].paso(p, f * 0.06)
        cuadros.append(p)
    return cuadros


def hoy_explosion():
    fondo = base(6)
    fondo.dibujo(NAVE, 4, 24)
    blancos = [("chispa", 30, 14), ("rombo", 50, 30), ("platillo", 66, 18)]
    cuadros = []
    for k in range(37):
        p = copia(fondo)
        for n, (nombre, x, y) in enumerate(blancos):
            inicio = n * 9
            w, h = tam(nombre)
            cx, cy = x + w // 2, y + h // 2
            if k < inicio:
                p.dibujo(DIB[nombre], x, y)
                if k >= inicio - 4:
                    bx = 12 + int((x - 12) * (k - inicio + 4) / 4)
                    p.dibujo(["###"], bx, cy)
            elif k - inicio < 6:
                poner_centrado(p, DIB["explosion1" if k - inicio < 3 else "explosion2"], cx, cy)
        cuadros.append(p)
    return cuadros


def agrandar(filas):
    return ["".join(c * 2 for c in f) for f in filas for _ in range(2)]


def muerte_retro(nombre="jefe", x=58, y=19, cadena=CHISPA_HUMO, final=ONDA):
    """Muerte de jefe: tiembla y le revientan explosiones encima, la pantalla se invierte un
    cuadro y queda un estallido grande (al doble de tamaño) con humo."""
    fondo = base(9)
    fondo.dibujo(NAVE, 6, 24)
    w, h = tam(nombre)
    r = random.Random(5)
    estallidos = [(r.randrange(w), r.randrange(h), k * 2) for k in range(9)]
    cuadros = []
    for k in range(44):
        p = copia(fondo)
        if k < 22:
            dx = (k % 2) * 2 - 1
            p.dibujo(DIB[nombre], x + dx, y)
            for (ex, ey, t0) in estallidos:
                f = k - t0
                if 0 <= f < len(cadena):
                    poner_centrado(p, cadena[f], x + ex, y + ey)
        elif k == 22:
            p.px = [["#" if c is None else None for c in fila] for fila in p.px]
        else:
            f = (k - 23) // 2
            if f < len(final):
                poner_centrado(p, agrandar(final[f]), x + w // 2, y + h // 2)
            f2 = k - 27
            if 0 <= f2 < len(HUMO) - 3:
                for ox in (-6, 6):
                    poner_centrado(p, HUMO[3 + f2], x + w // 2 + ox, y + h // 2 - f2)
        cuadros.append(p)
    return cuadros


def muerte_jefe(nombre="jefe", x=58, y=19):
    """Muerte de jefe: tiembla y le revientan chispas encima; un destello invierte la pantalla
    un cuadro y el sprite se rompe en esquirlas grandes."""
    fondo = base(9)
    fondo.dibujo(NAVE, 6, 24)
    w, h = tam(nombre)
    r = random.Random(5)
    estallidos = [(r.randrange(w), r.randrange(h), k * 2) for k in range(9)]
    roto = None
    cuadros = []
    for k in range(48):
        p = copia(fondo)
        if k < 20:
            dx = (k % 2) * 2 - 1
            p.dibujo(DIB[nombre], x + dx, y)
            for (ex, ey, t0) in estallidos:
                f = k - t0
                if 0 <= f < len(CHISPA):
                    poner_centrado(p, CHISPA[f], x + ex, y + ey)
        elif k == 20:
            # destello: un cuadro con la pantalla en negativo
            p.px = [["#" if c is None else None for c in fila] for fila in p.px]
        else:
            if roto is None:
                roto = Esquirlas(nombre, x, y, fuerza=34, semilla=8)
                for e in roto.p:
                    e[4] += 0.3
            f = k - 21
            if f < 6:
                poner_centrado(p, HUMO[min(f, 2)] if f < 3 else CHISPA[3], x + w // 2, y + h // 2)
            roto.paso(p, f * 0.06)
        cuadros.append(p)
    return cuadros


# ================================================================== escudo de jefe
def puntos_sprite(nombre):
    d = DIB[nombre]
    return {(i, j) for j, f in enumerate(d) for i, c in enumerate(f) if c != "."}


def dilatar(pts, r):
    out = set()
    for (x, y) in pts:
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                if max(abs(dx), abs(dy)) <= r:
                    out.add((x + dx, y + dy))
    return out


def contorno(nombre, separacion=2):
    """Los píxeles a `separacion` del sprite: un borde que sigue su forma."""
    pts = puntos_sprite(nombre)
    return sorted(dilatar(pts, separacion) - dilatar(pts, separacion - 1))


def escudo(p, estilo, nombre, x, y, t, rebote):
    w, h = tam(nombre)
    cx, cy = w / 2 - 0.5, h / 2 - 0.5
    if estilo == "hoy":
        bx, by, bw, bh = x - 2, y - 2, w + 4, h + 4
        if rebote:
            p.rect(bx, by, bw, bh)
            p.rect(bx - 1, by - 1, bw + 2, bh + 2)
        else:
            c = t % 4
            for xx in range(bx + c, bx + bw, 4):
                for k in range(2):
                    p.punto(xx + k, by)
                    p.punto(bx + bw - 1 - (xx - bx) - k, by + bh - 1)
            for yy in range(by + c, by + bh, 4):
                for k in range(2):
                    p.punto(bx + bw - 1, yy + k)
                    p.punto(bx, by + bh - 1 - (yy - by) - k)
        return
    if estilo in ("contorno", "medio"):
        tono = "#" if estilo == "contorno" else "+"
        for (i, j) in contorno(nombre):
            if rebote:
                p.punto(x + i, y + j, "#")
                continue
            # trazos que dan la vuelta alrededor del jefe
            a = (math.atan2(j - cy, (i - cx) * 0.6) / (2 * math.pi)) * 18
            if (math.floor(a + t * 0.8)) % 3 != 0:
                p.punto(x + i, y + j, tono)
        if rebote and estilo == "medio":
            for (i, j) in contorno(nombre, 3):
                if (i + j) % 2 == 0:
                    p.punto(x + i, y + j, "+")
        return
    if estilo == "burbuja":
        rx, ry = w / 2 + 3.5, h / 2 + 3.5
        n = int((rx + ry) * 3)
        for k in range(n):
            a = k / n * 2 * math.pi
            px, py = round(x + cx + math.cos(a) * rx), round(y + cy + math.sin(a) * ry)
            if rebote or (k + t) % 4 < 2:
                p.punto(px, py, "#" if rebote or (k + t) % 8 < 2 else "+")
        return


def escena_escudo(estilo, nombre, x, y):
    fondo = base(3)
    fondo.dibujo(NAVE, 6, 24)
    w, h = tam(nombre)
    cuadros = []
    for k in range(32):
        p = copia(fondo)
        p.dibujo(DIB[nombre], x, y)
        # un tiro que rebota en el escudo
        tiro = k % 16
        rebote = tiro in (8, 9)
        golpe_x = x - 3
        if tiro < 8:
            p.dibujo(["###"], 14 + int((golpe_x - 17) * tiro / 8), y + h // 2)
        elif tiro < 14:
            p.punto(golpe_x - (tiro - 8) * 2, y + h // 2 - (tiro - 8), "#")
            p.punto(golpe_x - (tiro - 8) * 2, y + h // 2 + (tiro - 8), "#")
        escudo(p, estilo, nombre, x, y, k, rebote)
        cuadros.append(p)
    return cuadros


ESCUDO_JEFES = [  # (nombre, x, y) en la pantalla de 84x48
    ("jefe", 60, 19),
    ("nodriza", 56, 14),
    ("ojo_abierto", 62, 16),
    ("tenaza", 60, 17),
]
ESCUDOS = ["hoy", "contorno", "medio", "burbuja"]

# ================================================================== galería de jefes
GALERIA = [
    ("ROSWELL 1947", "Coloso", ["jefe"]),
    ("BELGICA 1990", "Tenaza", ["tenaza"]),
    ("PHOENIX 1997", "Nodriza", ["nodriza", "nodriza_b"]),
    ("HANGAR 18", "Núcleo", ["nucleo"]),
    ("LOS HILL 1961", "Ojo", ["ojo_abierto", "ojo_cerrado"]),
    ("SHAG HARBOUR 1967", "Shag", ["shag", "shag_b"]),
    ("BAIKAL 1982", "Gigante", ["gigante", "gigante_visor"]),
    ("GOLFO NUEVO 1960", "Fantasma", ["fantasma"]),
    ("LUBBOCK 1951", "Serpiente", ["serpiente_cabeza", "serpiente_cuerpo"]),
    ("BERMUDAS 1945", "Pirámide", ["piramide", "piramide_abierta"]),
]


def galeria(cuadros):
    """Cada jefe al centro de un recuadro de 30x20, con sus cuadros alternando."""
    out = []
    for k in range(8):
        p = Pantalla(30, 20)
        nombre = cuadros[(k // 4) % len(cuadros)] if len(cuadros) > 1 and "cuerpo" not in cuadros[-1] else cuadros[0]
        w, h = tam(nombre)
        if "cuerpo" in cuadros[-1]:
            p.dibujo(DIB[nombre], 2, (20 - h) // 2)
            cw, ch = tam(cuadros[-1])
            for n in range(3):
                p.dibujo(DIB[cuadros[-1]], 2 + w + 1 + n * 6, (20 - ch) // 2 + (1 if (n + k // 2) % 2 else -1))
        else:
            p.dibujo(DIB[nombre], (30 - w) // 2, (20 - h) // 2)
        out.append(p)
    return out


if __name__ == "__main__":
    os.makedirs(SALIDA, exist_ok=True)
    guardar_gif(hoy_explosion(), "explosion_hoy")
    for e in ("chispa", "humo", "esquirlas", "cruz", "onda", "chispa_humo", "disuelve"):
        guardar_gif(escena_explosion(e), "explosion_" + e)
    guardar_gif(muerte_jefe(), "muerte_jefe", 70)
    guardar_gif(muerte_jefe("nodriza", 54, 14), "muerte_nodriza", 70)
    guardar_gif(muerte_retro(), "muerte_retro_onda", 70)
    guardar_gif(muerte_retro("nodriza", 54, 14, CRUZ, CRUZ), "muerte_retro_cruz", 70)
    guardar_gif(muerte_retro("gigante", 60, 30, CHISPA, DISUELVE), "muerte_retro_disuelve", 70)
    for nombre, x, y in ESCUDO_JEFES:
        for e in ESCUDOS:
            guardar_gif(escena_escudo(e, nombre, x, y), "escudo_%s_%s" % (e, nombre), 70)
    for caso, _, cuadros in GALERIA:
        g = galeria(cuadros)
        imgs = [a_imagen(c.px, 10) for c in g]
        imgs[0].save(os.path.join(SALIDA, "jefe_%s.gif" % cuadros[0]), save_all=True,
                     append_images=imgs[1:], duration=250, loop=0)
    print("efectos listos")
