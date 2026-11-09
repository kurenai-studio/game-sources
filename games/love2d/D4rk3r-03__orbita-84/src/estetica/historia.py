#!/usr/bin/env python3
"""Muestras de la historia de Órbita 84: prólogo, carteles de nivel con su informe, la pantalla
del mapa de Betty Hill entre niveles y el final. Tono serio. Usa la fuente de 3x5 del juego
(leída de juego/datos.lua), que no tiene tildes: los textos van sin acento como en el juego.

Historia: 1984. Un programa secreto revisa diez casos con las mismas luces. Dos expedientes
(Bélgica 1990 y Phoenix 1997) llegaron con fecha que todavía no pasó. Cada jefe vencido deja
una pieza de un mapa; en Los Hill se entiende que es el mapa que dibujó Betty Hill. Completo, no
muestra de dónde vienen sino por dónde entran: la pirámide de las Bermudas. Al cruzarla, los
informes de 1990 y 1997 resultan llevar la firma del piloto."""
import os
import re

import generar
from generar import Pantalla, estrellas

AQUI = os.path.dirname(os.path.abspath(__file__))

# la fuente del juego, tal cual
LETRAS = {" ": ["...", "...", "...", "...", "..."]}
_fuente = open(os.path.join(AQUI, "..", "juego", "datos.lua"), encoding="utf-8").read()
_bloque = _fuente[_fuente.index("D.letras = {") + len("D.letras = {"):]
_bloque = _bloque[: _bloque.index("\n}\n")]
for clave, filas in re.findall(r'(\w|\["[^"]+"\])\s*=\s*\{([^}]*)\}', _bloque):
    clave = clave.strip('[]"')
    LETRAS[clave] = re.findall(r'"([.#+]+)"', filas)


def texto(p, t, y, tono="#"):
    x = (84 - (len(t) * 4 - 1)) // 2
    for k, c in enumerate(t):
        p.dibujo(LETRAS.get(c, LETRAS[" "]), x + k * 4, y, tono)


def cuadro(p, lineas, centro=27):
    """Cartel como el del juego: marco en tinta, la línea marcada con '+' va en tono medio."""
    alto = 7 * len(lineas) + 3
    arriba = centro - alto // 2
    ancho = max([60] + [len(t) * 4 + 5 for t, _ in lineas])
    izq = (84 - ancho) // 2
    for y in range(arriba, arriba + alto):
        for x in range(izq, izq + ancho):
            p.px[y][x] = None
    p.rect(izq, arriba, ancho, alto)
    for i, (t, tono) in enumerate(lineas):
        texto(p, t, arriba + 2 + 7 * i, tono)


# ------------------------------------------------------------------ guion
NIVELES = [
    # (caso, modo, informe, aviso del juego)
    ("ROSWELL 1947", "aire", "ALGO CAYO DEL CIELO", None),
    ("BELGICA 1990", "aire", "ESTE AUN NO OCURRE", None),
    ("PHOENIX 1997", "tierra", "LLEGO ANTES DE HORA", "A TIERRA!"),
    ("HANGAR 18", "cueva", "VIENEN POR LO SUYO", None),
    ("LOS HILL 1961", "cueva", "ELLA DIBUJO UN MAPA", None),
    ("SHAG HARBOUR 1967", "mar", "SE HUNDIO SIN RUIDO", "AL MAR!"),
    ("BAIKAL 1982", "hielo", "VIVE BAJO EL HIELO", "AL HIELO!"),
    ("GOLFO NUEVO 1960", "mar de noche", "LA ARMADA LOS VIO", "A OSCURAS!"),
    ("LUBBOCK 1951", "aire", "SE PONEN EN FILA", None),
    ("BERMUDAS 1945", "submarino", "EL VUELO 19 CRUZO", "A FONDO!"),
]

PROLOGO = [
    [("1984", "#"), ("PROGRAMA SECRETO", "+"), ("DIEZ CASOS", "#"), ("LAS MISMAS LUCES", "#")],
    [("DOS EXPEDIENTES", "#"), ("TIENEN FECHA", "#"), ("QUE AUN NO LLEGA", "+")],
]

# pantalla del mapa: después de cada jefe, una pieza más (frase de abajo)
TRAS_JEFE = [
    "UNA LUZ. NADA MAS",
    "OTRA. MUY LEJOS",
    "TRES PUNTOS",
    "NO ESTAN AL AZAR",
    "ES UN MAPA",
    "FALTAN CINCO",
    "SE ACERCAN",
    "CASI COMPLETO",
    "ES POR DONDE ENTRAN",
    "LA PUERTA SE CIERRA",
]

FINAL = [
    [("LA PUERTA SE CIERRA", "#")],
    [("LOS INFORMES", "#"), ("DE 1990 Y 1997", "#"), ("LLEVAN TU FIRMA", "+")],
    [("FIN DEL EXPEDIENTE", "#")],
]
VUELTA = [("NIVEL 1", "#"), ("ROSWELL 1947", "+"), ("LAS LUCES VUELVEN", "#"), ("VUELTA 2", "#")]

# ------------------------------------------------------------------ mapa de Betty Hill
# las estrellas del mapa (como en el fondo del nivel de los Hill); las dos grandes son
# Zeta Reticuli y se prenden al final, al cruzar la puerta
MAPA = [(0, 8, True), (3, 10, True), (11, 3), (13, 10), (9, 15), (19, 6), (21, 12), (27, 2), (29, 9), (26, 15), (16, 0)]
LINEAS = [(1, 3), (1, 4), (2, 5), (2, 4), (3, 6), (4, 7), (6, 8), (7, 9), (7, 10), (3, 11), (6, 7)]
# qué estrella prende cada jefe (índices de MAPA desde 1); el último prende las dos grandes
PIEZAS = [[11], [8], [3], [6], [9], [4], [7], [10], [5], [1, 2]]


def punto_mapa(i):
    x, y = MAPA[i - 1][0], MAPA[i - 1][1]
    return 12 + round(x * 2.05), 11 + round(y * 1.75)


def pantalla_mapa(despues_de):
    """Mapa tras vencer al jefe del nivel `despues_de` (1..10)."""
    p = Pantalla()
    estrellas(p, 10, 7)
    texto(p, "PIEZA %d DE 10" % despues_de, 1)
    for x in range(84):
        p.punto(x, 7)
    prendidas = {i for n in range(despues_de) for i in PIEZAS[n]}
    nueva = set(PIEZAS[despues_de - 1])
    # desde Los Hill (nivel 5) se entiende que es un mapa: aparecen las líneas en tono medio;
    # entre estrellas ya prendidas, punteadas en tinta
    if despues_de >= 5:
        for a, b in LINEAS:
            (x1, y1), (x2, y2) = punto_mapa(a), punto_mapa(b)
            pasos = max(abs(x2 - x1), abs(y2 - y1))
            ambas = a in prendidas and b in prendidas
            for k in range(1, pasos):
                if k % 2 == 0:
                    p.punto(x1 + (x2 - x1) * k / pasos, y1 + (y2 - y1) * k / pasos, "#" if ambas else "+")
    for i, e in enumerate(MAPA, start=1):
        x, y = punto_mapa(i)
        if i in prendidas:
            grande = len(e) > 2
            p.punto(x, y)
            if grande or i in nueva:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    p.punto(x + dx, y + dy, "#" if grande else "+")
            if i in nueva:
                # la recién ganada lleva la mira de radar de las mejoras
                for dx, dy in ((-3, -3), (-2, -3), (-3, -2), (3, -3), (2, -3), (3, -2),
                               (-3, 3), (-2, 3), (-3, 2), (3, 3), (2, 3), (3, 2)):
                    p.punto(x + dx, y + dy)
        elif despues_de >= 5:
            p.punto(x, y, "+")
    texto(p, TRAS_JEFE[despues_de - 1], 42, "#")
    return p


def cartel(n):
    caso, _, informe, aviso = NIVELES[n - 1]
    p = Pantalla()
    estrellas(p, 14, n)
    generar.marcador(p, 3, 2, "00000")
    lineas = [("NIVEL %d" % n, "#"), (caso, "+"), (informe, "#")]
    if aviso:
        lineas.append((aviso, "#"))
    cuadro(p, lineas)
    return p


def pantalla_texto(lineas, semilla=1):
    p = Pantalla()
    estrellas(p, 12, semilla)
    cuadro(p, lineas, 25)
    return p


if __name__ == "__main__":
    d = "historia/"
    os.makedirs(os.path.join(generar.SALIDA, d), exist_ok=True)
    for i, lineas in enumerate(PROLOGO, start=1):
        pantalla_texto(lineas, i).guardar(d + "prologo_%d" % i)
    for n in range(1, 11):
        cartel(n).guardar(d + "cartel_%02d" % n)
        pantalla_mapa(n).guardar(d + "mapa_%02d" % n)
    for i, lineas in enumerate(FINAL, start=1):
        pantalla_texto(lineas, 20 + i).guardar(d + "final_%d" % i)
    cuadro(p := Pantalla(), VUELTA)
    p.guardar(d + "vuelta_2")
    print("historia lista")
