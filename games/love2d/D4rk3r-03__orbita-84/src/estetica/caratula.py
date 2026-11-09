#!/usr/bin/env python3
"""Carátula de 640x480 para la consola (PortMaster / EmulationStation).
Una pantalla de celular viejo dentro de un marco oscuro, con la nave, la nodriza
abduciendo una vaca, jefes de los expedientes y un sello de CLASIFICADO.
Los dibujos se leen de juego/datos.lua para que coincidan con el juego.
Uso (desde estetica/): python3 caratula.py  ->  img/caratula.png"""
import math
import os
import random
import subprocess

from PIL import Image

from generar import CHICAS, GORDAS, FONDO, TINTA, mezcla, VACA

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)

W, H, ESCALA = 160, 120, 4
COLORES = {
    "#": TINTA,
    "+": mezcla(0.45),
    "-": mezcla(0.22),
    "L": FONDO,             # fondo de la pantalla
    "M": (24, 34, 30),      # marco
    "m": (44, 60, 52),      # borde claro del marco
    "t": (150, 178, 160),   # letras del marco
}
LCD = (8, 8, 144, 86)  # x, y, ancho, alto de la pantalla


def dibujos():
    lua = ('package.path="juego/?.lua;"..package.path local D=require("datos") '
           'for n,f in pairs(D.dibujos) do print(n.."|"..table.concat(f,",")) end')
    salida = subprocess.run(["luajit", "-e", lua], cwd=RAIZ, capture_output=True, text=True, check=True).stdout
    return {n: f.split(",") for n, f in (l.split("|", 1) for l in salida.splitlines())}


class Lienzo:
    def __init__(self):
        self.px = [["M"] * W for _ in range(H)]

    def punto(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < W and 0 <= y < H:
            self.px[y][x] = c

    def en_lcd(self, x, y, c):
        lx, ly, lw, lh = LCD
        if lx <= x < lx + lw and ly <= y < ly + lh:
            self.punto(x, y, c)

    def dibujo(self, filas, x, y, solo=None):
        for j, f in enumerate(filas):
            for i, c in enumerate(f):
                if c != ".":
                    self.en_lcd(x + i, y + j, solo or c)

    def texto(self, t, x, y, c):
        for k, letra in enumerate(t):
            for j, f in enumerate(CHICAS.get(letra, CHICAS[" "])):
                for i, ch in enumerate(f):
                    if ch == "#":
                        self.punto(x + k * 4 + i, y + j, c)

    def gordo(self, t, x, y, escala):
        for k, letra in enumerate(t):
            filas = ["".join(ch * escala for ch in f) for f in GORDAS[letra] for _ in range(escala)]
            gx = x + k * (6 * escala + escala)
            self.dibujo(filas, gx + escala, y + escala, "+")
            self.dibujo(filas, gx, y, "#")


def armar():
    S = dibujos()
    c = Lienzo()
    lx, ly, lw, lh = LCD
    # marco con un borde claro y la pantalla con esquinas redondeadas
    for x in range(lx - 2, lx + lw + 2):
        c.punto(x, ly - 2, "m"); c.punto(x, ly + lh + 1, "m")
    for y in range(ly - 2, ly + lh + 2):
        c.punto(lx - 2, y, "m"); c.punto(lx + lw + 1, y, "m")
    for y in range(ly, ly + lh):
        for x in range(lx, lx + lw):
            c.punto(x, y, "L")
    for (x, y) in ((lx, ly), (lx + lw - 1, ly), (lx, ly + lh - 1), (lx + lw - 1, ly + lh - 1)):
        c.punto(x, y, "M")

    suelo = ly + lh - 9
    # cielo: estrellas, planeta con anillo y montes lejanos
    r = random.Random(84)
    for _ in range(40):
        c.en_lcd(lx + r.randrange(lw), ly + r.randrange(lh - 14), "-")
    px_, py_ = lx + 16, ly + 14
    for k in range(48):
        a = k / 48 * 2 * math.pi
        c.en_lcd(px_ + math.cos(a) * 6, py_ + math.sin(a) * 6, "-")
    for k in range(60):
        a = k / 60 * 2 * math.pi
        x, y = px_ + math.cos(a) * 12, py_ + math.sin(a) * 2.4
        if not (math.sin(a) < 0 and abs(x - px_) < 6):
            c.en_lcd(x, y, "-")
    for x in range(lx, lx + lw):
        h = 5 + 3 * math.sin(x * 0.09) + 2 * math.sin(x * 0.23 + 1)
        c.en_lcd(x, suelo - 2 - h, "-")
        if x % 3 == 0:
            c.en_lcd(x, suelo - h, "-")

    # suelo: a la izquierda el mar, en el medio tierra, a la derecha la placa de hielo
    for x in range(lx, lx + lw):
        rel = x - lx
        if rel < 44:
            c.en_lcd(x, suelo + 1, "#")
            if (rel + 3) % 9 in (3, 4):
                c.en_lcd(x, suelo, "#")
            for y in range(suelo + 4, ly + lh, 3):
                if (x * 7 + y * 5) % 13 < 2:
                    c.en_lcd(x, y, "-")
        elif rel < 104:
            c.en_lcd(x, suelo + 1, "#")
            for y in range(suelo + 3, ly + lh, 2):
                if (x + y) % 4 == 0:
                    c.en_lcd(x, y, "+")
        else:
            c.en_lcd(x, suelo + 1, "#")
            for y in range(suelo + 3, suelo + 6):
                if not ((x - y * 2) % 19 == 0):
                    c.en_lcd(x, y, "+")
            c.en_lcd(x, suelo + 6 if (x * 7) % 5 else suelo + 5, "#")
            if (x * 7) % 11 == 0:
                c.en_lcd(x, suelo + 7, "+")

    # jefes de los expedientes, cada uno en su terreno
    shag = S["shag"]
    c.dibujo(shag[:4], lx + 12, suelo - 3)            # asoma del mar
    c.dibujo(shag[4:], lx + 12, suelo + 1, "+")       # lo hundido en tono medio
    c.dibujo(S["piramide"], lx + 62, suelo - 10)
    gig = S["gigante_visor"]
    c.dibujo(gig[:7], lx + 116, suelo - 6)
    c.dibujo(gig[7:], lx + 116, suelo + 1, "+")

    # título
    c.gordo("ORBITA", lx + (lw - 6 * 14 + 2) // 2, ly + 5, 2)
    c.gordo("84", lx + (lw - 2 * 21 + 3) // 2 - 6, ly + 22, 3)

    # nodriza (platillo de Roswell) abduciendo una vaca con su haz
    ux, uy = lx + 112, ly + 22
    c.dibujo(S["jefe"], ux, uy)
    for j in range(1, 26):
        y = uy + 9 + j
        medio = 3 + j * 0.45
        for x in range(int(ux + 8 - medio), int(ux + 9 + medio)):
            if (x + y) % 2 == 0 or j % 4 == 0:
                c.en_lcd(x, y, "-")
    c.dibujo(VACA, ux + 6, uy + 24)

    # la nave y sus balas contra una escuadrilla
    c.dibujo(S["nave"], lx + 10, ly + 52)
    c.punto(lx + 8, ly + 54, "#"); c.punto(lx + 9, ly + 54, "#")
    for bx in (20, 32, 44):
        c.dibujo(["###"], lx + bx, ly + 54)
    c.dibujo(S["medusa"], lx + 60, ly + 49)
    c.dibujo(S["dardo"], lx + 74, ly + 58)
    c.dibujo(S["caparazon"], lx + 88, ly + 50)
    c.dibujo(S["explosion1"], lx + 52, ly + 53)

    # rótulo del marco
    c.texto("9 EXPEDIENTES OVNI", lx, ly + lh + 6, "t")
    c.texto("D4RK3R-03", lx, ly + lh + 15, "t")
    return c


def sello():
    """Sello rojo de CLASIFICADO, hecho con las letras del juego y un poco gastado."""
    texto = "CLASIFICADO"
    w, h = len(texto) * 4 + 5, 11
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rojo = (205, 70, 55, 235)
    r = random.Random(7)
    for x in range(w):
        for y in (0, 1, h - 2, h - 1):
            if r.random() > 0.08:
                img.putpixel((x, y), rojo)
    for y in range(h):
        for x in (0, 1, w - 2, w - 1):
            if r.random() > 0.08:
                img.putpixel((x, y), rojo)
    for k, letra in enumerate(texto):
        for j, f in enumerate(CHICAS[letra]):
            for i, ch in enumerate(f):
                if ch == "#":
                    img.putpixel((3 + k * 4 + i, 3 + j), rojo)
    img = img.resize((w * ESCALA, h * ESCALA), Image.NEAREST)
    return img.rotate(6, resample=Image.NEAREST, expand=True)


def guardar(c, ruta):
    img = Image.new("RGB", (W * ESCALA, H * ESCALA))
    lx, ly, lw, lh = LCD
    for y in range(H):
        for x in range(W):
            color = COLORES[c.px[y][x]]
            dentro = lx <= x < lx + lw and ly <= y < ly + lh
            for dy in range(ESCALA):
                for dx in range(ESCALA):
                    # rejilla fina de la pantalla, como un LCD de verdad
                    if dentro and (dx == ESCALA - 1 or dy == ESCALA - 1):
                        img.putpixel((x * ESCALA + dx, y * ESCALA + dy), tuple(int(v * 0.94) for v in color))
                    else:
                        img.putpixel((x * ESCALA + dx, y * ESCALA + dy), color)
    s = sello()
    # abajo a la derecha, montado sobre el borde de la pantalla
    img.paste(s, (W * ESCALA - s.width - 22, H * ESCALA - s.height - 14), s)
    img.save(ruta)


if __name__ == "__main__":
    os.makedirs(os.path.join(AQUI, "img"), exist_ok=True)
    guardar(armar(), os.path.join(AQUI, "img", "caratula.png"))
    print("caratula lista")
