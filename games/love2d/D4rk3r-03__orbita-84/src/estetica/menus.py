#!/usr/bin/env python3
"""Muestras de menús para Órbita 84: un solo marco para todos los menús, en tres estilos.
A · Carpeta: pestaña llena con el título en negativo, como la carpeta de un expediente.
B · Ficha: caja con franja de título en negativo y el pie separado por una línea punteada.
C · Mira de radar: solo las esquinas, como el marco de las mejoras; título con regla en tono medio.
En los tres, las opciones llevan el cursor '>' y la elegida va en tinta; las otras en tono medio.
Usa la fuente de 3x5 del juego (sin tildes)."""
import os

import generar
from generar import Pantalla, estrellas, NAVE
from historia import LETRAS

ESTILOS = {
    "carpeta": "A · Carpeta",
    "ficha": "B · Ficha",
    "radar": "C · Mira de radar",
}


def ancho_texto(t):
    return len(t) * 4 - 1


def letras(p, t, x, y, tono="#"):
    for k, c in enumerate(t):
        p.dibujo(LETRAS.get(c, LETRAS[" "]), x + k * 4, y, tono)


def negativo(p, t, x, y):
    """Texto en color de fondo sobre una franja de tinta (ya dibujada)."""
    for k, c in enumerate(t):
        for j, f in enumerate(LETRAS.get(c, LETRAS[" "])):
            for i, ch in enumerate(f):
                if ch != ".":
                    p.px[y + j][x + k * 4 + i] = None


def centrar(t):
    return (84 - ancho_texto(t)) // 2


def limpiar(p, x, y, w, h):
    for j in range(max(0, y), min(48, y + h)):
        for i in range(max(0, x), min(84, x + w)):
            p.px[j][i] = None


def lleno(p, x, y, w, h, tono="#"):
    for j in range(y, y + h):
        for i in range(x, x + w):
            p.punto(i, j, tono)


# ------------------------------------------------------------------ cuerpo
# cada elemento: ("txt", texto, tono) | ("op", texto, elegida) | ("hueco", alto)
#                | ("grande", cifra) | ("iniciales", letras, cual) | ("sello", texto)
#                | ("fila", texto, elegida)  (fila del modo prueba, con < > si está elegida)
def alto_de(e):
    return {"hueco": e[1] if e[0] == "hueco" else 0, "grande": 17, "iniciales": 9, "sello": 10, "fila": 6}.get(e[0], 7)


def poner_cuerpo(p, cuerpo, y):
    ops = [e[1] for e in cuerpo if e[0] == "op"]
    x_op = centrar(max(ops, key=len)) + 3 if ops else 0
    for e in cuerpo:
        tipo = e[0]
        if tipo == "txt":
            letras(p, e[1], centrar(e[1]), y, e[2])
        elif tipo == "op":
            if e[2]:
                letras(p, ">", x_op - 7, y)
            letras(p, e[1], x_op, y, "#" if e[2] else "+")
        elif tipo == "fila":
            t = ("< " + e[1] + " >") if e[2] else e[1]
            letras(p, t, centrar(t), y, "#" if e[2] else "+")
        elif tipo == "grande":
            filas = LETRAS[e[1]]
            x = 42 - 4
            for j, f in enumerate(filas):
                for i, ch in enumerate(f):
                    if ch != ".":
                        lleno(p, x + i * 3, y + j * 3, 3, 3)
        elif tipo == "iniciales":
            for i, c in enumerate(e[1]):
                x = 30 + i * 9
                letras(p, c, x + 2, y)
                if i == e[2]:
                    for k in range(5):
                        p.punto(x + 1 + k, y + 6)
        elif tipo == "sello":
            w = ancho_texto(e[1]) + 6
            x = (84 - w) // 2
            p.rect(x, y, w, 9)
            p.rect(x + 1, y + 1, w - 2, 7, "+")
            letras(p, e[1], x + 3, y + 2)
        y += alto_de(e)


# ------------------------------------------------------------------ marcos
def menu(p, estilo, titulo, cuerpo, pie=None, ancho=68, centro=None):
    alto_cuerpo = sum(alto_de(e) for e in cuerpo)
    cabeza = {"carpeta": 10, "ficha": 10, "radar": 11}[estilo]
    alto = cabeza + alto_cuerpo + (8 if pie else 0) + 2
    izq = (84 - ancho) // 2
    arriba = (centro if centro is not None else 24) - alto // 2
    arriba = max(0, min(48 - alto, arriba))
    abajo = arriba + alto - 1
    if estilo == "carpeta":
        tw = ancho_texto(titulo) + 6
        limpiar(p, izq, arriba, tw, 7)
        limpiar(p, izq, arriba + 6, ancho, alto - 6)
        lleno(p, izq, arriba, tw, 7)
        negativo(p, titulo, izq + 3, arriba + 1)
        p.rect(izq, arriba + 6, ancho, alto - 6)
        # el número de expediente en la esquina, como el rótulo de la carpeta
        if tw + 14 <= ancho:
            letras(p, "84", izq + ancho - 9, arriba, "+")
    elif estilo == "ficha":
        limpiar(p, izq, arriba, ancho, alto)
        p.rect(izq, arriba, ancho, alto)
        lleno(p, izq, arriba, ancho, 8)
        negativo(p, titulo, centrar(titulo), arriba + 2)
    else:
        limpiar(p, izq, arriba, ancho, alto)
        for (cx, cy, dx, dy) in ((izq, arriba, 1, 1), (izq + ancho - 1, arriba, -1, 1),
                                 (izq, abajo, 1, -1), (izq + ancho - 1, abajo, -1, -1)):
            for k in range(4):
                p.punto(cx + dx * k, cy)
                p.punto(cx, cy + dy * k)
        letras(p, titulo, centrar(titulo), arriba + 2)
        for x in range(centrar(titulo) - 2, centrar(titulo) + ancho_texto(titulo) + 2):
            if x % 2 == 0:
                p.punto(x, arriba + 8, "+")
    poner_cuerpo(p, cuerpo, arriba + cabeza)
    if pie:
        y = abajo - 7
        if estilo == "ficha":
            for x in range(izq + 2, izq + ancho - 2):
                if x % 2 == 0:
                    p.punto(x, y - 2, "+")
        letras(p, pie, centrar(pie), y)


# ------------------------------------------------------------------ fondos
def fondo_juego(semilla=7):
    """Lo que se ve detrás de la pausa: marcador, nave, enemigos y el fondo suave."""
    p = Pantalla()
    estrellas(p, 18, semilla)
    for x in range(0, 84, 3):
        p.punto(x, 44, "-")
    generar.marcador(p, 3, 2, "03420")
    letras(p, "N7", 53 - 4, 0, "+")
    p.dibujo(NAVE, 4, 24)
    p.dibujo([".###.", "#+#+#", ".###."], 70, 14)
    p.dibujo([".###.", "#+#+#", ".###."], 64, 34)
    return p


def fondo_quieto(semilla=3):
    p = Pantalla()
    estrellas(p, 14, semilla)
    return p


# ------------------------------------------------------------------ menús
def pausa(estilo):
    p = fondo_juego()
    menu(p, estilo, "PAUSA", [
        ("txt", "NIVEL 7 VUELTA 2", "#"),
        ("txt", "BAIKAL 1982", "+"),
        ("hueco", 1),
        ("op", "SEGUIR", True),
        ("op", "SALIR", False),
    ], centro=27)
    return p


def prueba(estilo):
    # se ven cuatro filas a la vez; las flechas de tono medio avisan que hay más
    p = fondo_quieto(5)
    menu(p, estilo, "MODO PRUEBA", [
        ("fila", "VUELTA 2", False),
        ("fila", "DANO: SI", False),
        ("fila", "CHOQUES: SI", True),
        ("fila", "LENTO: 1/2", False),
    ], pie="START JUGAR", ancho=76)
    return p


def ronda(estilo):
    p = fondo_quieto(8)
    menu(p, estilo, "RONDA 1 COMPLETA", [
        ("txt", "18450", "#"),
        ("txt", "OTRA MAS DIFICIL?", "+"),
        ("hueco", 2),
        ("op", "SEGUIR", True),
        ("op", "TERMINAR", False),
    ], ancho=76)
    return p


def iniciales(estilo):
    p = fondo_quieto(11)
    menu(p, estilo, "NUEVO RECORD", [
        ("txt", "15000", "#"),
        ("txt", "TUS INICIALES", "+"),
        ("iniciales", "DRK", 1),
    ], pie="START GUARDA")
    return p


def cumplida(estilo):
    p = fondo_quieto(13)
    menu(p, estilo, "MISION CUMPLIDA", [
        ("txt", "18450", "#"),
        ("txt", "PUESTO 1 DE 5", "+"),
        ("hueco", 1),
        ("sello", "CASO CERRADO"),
    ], ancho=72)
    return p


def continuar(estilo):
    p = fondo_juego(9)
    menu(p, estilo, "CONTINUAR?", [
        ("grande", "7"),
    ], pie="START SIGUE", ancho=56, centro=27)
    return p


PANTALLAS = [
    ("pausa", "Pausa", pausa),
    ("prueba", "Modo prueba", prueba),
    ("ronda", "Ronda completa", ronda),
    ("iniciales", "Nuevo récord", iniciales),
    ("cumplida", "Misión cumplida", cumplida),
    ("continuar", "Continuar", continuar),
]

if __name__ == "__main__":
    d = "menus/"
    os.makedirs(os.path.join(generar.SALIDA, d), exist_ok=True)
    for clave, _, hacer in PANTALLAS:
        for estilo in ESTILOS:
            hacer(estilo).guardar(d + clave + "_" + estilo)
    print("menus listos")
