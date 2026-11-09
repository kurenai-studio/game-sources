#!/usr/bin/env python3
"""Propuestas para el marcador de arriba (vidas, especial, poderes y puntaje) y para la sonda
en tierra y el tiempo perdido. Usa los dibujos reales de juego/datos.lua.
Salida: img/hud/*.png y *.gif"""
import os

from PIL import Image

import generar
from generar import Pantalla, estrellas
from efectos import DIB, a_imagen

SALIDA = os.path.join(generar.SALIDA, "hud")
os.makedirs(SALIDA, exist_ok=True)
TECHO = 7


def chip(p, icono, x, y=0):
    """el poder guardado en negativo: un bloque en tinta con el ícono recortado"""
    for j in range(5):
        for i in range(5):
            p.punto(x + i, y + j, "#")
    for j, f in enumerate(DIB["icono_" + icono]):
        for i, c in enumerate(f):
            if c != ".":
                p.px[y + j][x + 1 + i] = None


def barra_jefe(p, x=42, vida=0.6):
    filas = round(24 * vida)
    for i in range(6):
        alto = max(0, min(4, filas - i * 4))
        if alto:
            for j in range(alto):
                p.punto(x + i * 3, 4 - 1 - j)
                p.punto(x + i * 3 + 1, 4 - 1 - j)
        else:
            p.punto(x + i * 3, 3, "+")
            p.punto(x + i * 3 + 1, 3, "+")


def linea(p):
    for x in range(84):
        p.punto(x, 5)


# ---------------------------------------------------------------- marcadores

def ranura(p, icono, x, etiqueta=True):
    """el poder guardado: una Y en tono medio y el ícono entre dos rayas en tono medio"""
    if etiqueta:
        p.texto("Y", x, 0, "+")
        x += 4
    for j in range(5):
        p.punto(x, j, "+")
        p.punto(x + 6, j, "+")
    if icono:
        p.dibujo(DIB["icono_" + icono], x + 2, 0)
    return x + 7


def activos(p, e, x):
    for i, a in enumerate(e["activos"]):
        p.dibujo(DIB["icono_" + a], x + i * 4, 0)


def hoy(p, e):
    for i in range(e["vidas"]):
        p.dibujo(DIB["vida"], i * 4, 1)
    for i in range(e["rayos"]):
        p.dibujo(DIB[e["especial"]], 22 + i * 4, 0)
    if e["jefe"]:
        barra_jefe(p)
    else:
        activos(p, e, 44)
    if e["guardado"]:
        p.dibujo(DIB["icono_" + e["guardado"]], 60, 0)
    p.texto(e["puntos"], 64, 0)
    linea(p)


def propuesta_a(p, e):
    """A: contadores. Corazón y rayo con su número; la ranura del poder justo después."""
    p.dibujo(DIB["vida"], 0, 1)
    p.texto(str(e["vidas"]), 4, 0)
    p.dibujo(DIB[e["especial"]], 10, 0)
    p.texto(str(e["rayos"]), 14, 0)
    ranura(p, e["guardado"], 21)
    if e["jefe"]:
        barra_jefe(p)
    else:
        activos(p, e, 38)
    p.texto(e["puntos"], 64, 0)
    linea(p)


def propuesta_b(p, e):
    """B: el poder primero. La ranura en la esquina izquierda, lejos del puntaje; después
    vidas y rayos con su número."""
    x = ranura(p, e["guardado"], 0, etiqueta=False)
    p.dibujo(DIB["vida"], x + 3, 1)
    p.texto(str(e["vidas"]), x + 7, 0)
    p.dibujo(DIB[e["especial"]], x + 13, 0)
    p.texto(str(e["rayos"]), x + 17, 0)
    if e["jefe"]:
        barra_jefe(p)
    else:
        activos(p, e, 36)
    p.texto(e["puntos"], 64, 0)
    linea(p)


def propuesta_c(p, e):
    """C: íconos como hoy, pero los rayos con número y la ranura al centro; la barra del jefe
    corre un poco a la derecha."""
    for i in range(e["vidas"]):
        p.dibujo(DIB["vida"], i * 4, 1)
    p.dibujo(DIB[e["especial"]], 21, 0)
    p.texto(str(e["rayos"]), 25, 0)
    ranura(p, e["guardado"], 30)
    if e["jefe"]:
        barra_jefe(p, 45)
    else:
        activos(p, e, 47)
    p.texto(e["puntos"], 64, 0)
    linea(p)


PROPUESTAS = [("hoy", hoy), ("a", propuesta_a), ("b", propuesta_b), ("c", propuesta_c)]


def escena(marcador, jefe):
    p = Pantalla()
    estrellas(p, 12, 4)
    p.dibujo(DIB["nave"], 6, 24)
    p.dibujo(DIB["sonda"], 8, 19)
    for x in (16, 24, 32):
        p.punto(x, 26)
    if jefe:
        p.dibujo(DIB["jefe"], 56, 19)
        for (x, y) in [(50, 22), (46, 26), (48, 30)]:
            p.punto(x, y)
            p.punto(x + 1, y)
    else:
        p.dibujo(DIB["chispa"], 60, 14)
        p.dibujo(DIB["dardo"], 54, 30)
    marcador(p, {"vidas": 3, "rayos": 2, "especial": "rayo", "activos": ["sonda"], "guardado": "escudo",
                 "puntos": "01250", "jefe": jefe})
    return p


def tira(p, escala=12):
    """solo la franja del marcador, en grande"""
    filas = p.px[:7]
    return a_imagen(filas, escala)


# ---------------------------------------------------------------- sonda en tierra

def suelo(p, y=43):
    for x in range(84):
        for j in range(y, 48):
            p.punto(x, j, "-")


def escena_tierra():
    p = Pantalla()
    estrellas(p, 8, 7)
    suelo(p)
    p.dibujo(DIB["oruga"], 6, 37)
    p.dibujo(DIB["rodante"], 52, 38)
    p.dibujo(DIB["pincho"], 70, 40)
    p.dibujo(DIB["planeador"], 60, 14)
    propuesta_a(p, {"vidas": 3, "rayos": 2, "especial": "rayo", "activos": ["sonda"], "guardado": None, "puntos": "00840", "jefe": False})
    return p


def punteado(p, x0, y0, x1, y1, cada=2):
    n = max(abs(x1 - x0), abs(y1 - y0))
    for k in range(0, n, cada):
        p.punto(round(x0 + (x1 - x0) * k / n), round(y0 + (y1 - y0) * k / n), "+")


def sonda_hoy():
    p = escena_tierra()
    p.dibujo(DIB["sonda"], 8, 31)
    for x in (16, 26, 36, 46, 66, 76):
        p.punto(x, 32)
    return p


def sonda_apunta():
    """A: dispara cada 0,6 s al enemigo más cercano, en línea recta"""
    p = escena_tierra()
    p.dibujo(DIB["sonda"], 8, 31)
    punteado(p, 12, 32, 52, 40)
    for k in (0.35, 0.7):
        p.punto(round(12 + 40 * k), round(32 + 8 * k))
    return p


def sonda_cohete():
    """B: cada 1 s suelta un cohete chico que sube y busca, como los de la oruga"""
    p = escena_tierra()
    p.dibujo(DIB["sonda"], 8, 31)
    for (x, y) in [(12, 28), (16, 24), (22, 22), (30, 22), (38, 25), (45, 30), (50, 35)]:
        p.punto(x, y, "+")
    p.dibujo(DIB["cohete"], 48, 33)
    return p


def sonda_torreta():
    """C: baja al suelo delante de la oruga y dispara recto, a ras del piso"""
    p = escena_tierra()
    p.dibujo(DIB["sonda"], 20, 40)
    for x in (27, 35, 43):
        p.punto(x, 41)
    return p


# ---------------------------------------------------------------- tiempo perdido

def escena_tiempo(estela, esquinas, resto):
    p = Pantalla()
    estrellas(p, 12, 9)
    p.dibujo(DIB["nave"], 8, 24)
    balas = [(40, 20, -3, 1), (46, 28, -3, 0), (52, 34, -3, -1), (58, 24, -3, 0)]
    for (x, y, dx, dy) in balas:
        if estela:
            for k in (1, 2):
                p.punto(x - dx * k, y - dy * k, "+")
        p.punto(x, y)
        p.punto(x + 1, y)
    for (nombre, x, y) in [("chispa", 64, 12), ("dardo", 68, 30)]:
        if estela:
            p.dibujo(DIB[nombre], x + 3, y, "+")
        p.dibujo(DIB[nombre], x, y)
    propuesta_a(p, {"vidas": 3, "rayos": 2, "especial": "rayo", "activos": ["tiempo"], "guardado": None, "puntos": "01250", "jefe": False})
    # barra de lo que queda bajo la línea del marcador
    for x in range(0, round(84 * resto), 2):
        p.punto(x, 6, "+")
    if esquinas:
        largo = 3 + round(6 * resto)
        for (cx, cy, sx, sy) in [(0, TECHO, 1, 1), (83, TECHO, -1, 1), (0, 47, 1, -1), (83, 47, -1, -1)]:
            for k in range(largo):
                p.punto(cx + sx * k, cy, "+")
                p.punto(cx, cy + sy * k, "+")
    return p


if __name__ == "__main__":
    for nombre, f in [("sonda_hoy", sonda_hoy), ("sonda_a", sonda_apunta), ("sonda_b", sonda_cohete), ("sonda_c", sonda_torreta)]:
        a_imagen(f().px, 6).save(os.path.join(SALIDA, nombre + ".png"))
    a_imagen(escena_tiempo(False, False, 0.7).px, 6).save(os.path.join(SALIDA, "tiempo_hoy.png"))
    a_imagen(escena_tiempo(True, False, 0.7).px, 6).save(os.path.join(SALIDA, "tiempo_a.png"))
    a_imagen(escena_tiempo(True, True, 0.7).px, 6).save(os.path.join(SALIDA, "tiempo_b.png"))

    for nombre, f in PROPUESTAS:
        for jefe in (False, True):
            p = escena(f, jefe)
            sufijo = "_jefe" if jefe else ""
            a_imagen(p.px, 6).save(os.path.join(SALIDA, f"{nombre}{sufijo}.png"))
            tira(p).save(os.path.join(SALIDA, f"tira_{nombre}{sufijo}.png"))
    print("listo:", SALIDA)
