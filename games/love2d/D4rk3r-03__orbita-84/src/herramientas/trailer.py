#!/usr/bin/env python3
"""Tráiler de Órbita 84 para YouTube e itch.io: tomas reales del juego (modo captura que se
juega solo), carteles con las letras del juego y el sonido de pitidos rehecho a partir de los
sonidos que el juego anota mientras graba (video/sonidos.txt).

Uso:  python3 herramientas/trailer.py [es|en ...]
Salida: trailer/orbita84-trailer-<idioma>.mp4 (1920x1080, 30 cuadros)."""
import math
import os
import re
import shutil
import subprocess
import sys
import wave
import array

from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JUEGO = os.path.join(RAIZ, "juego")
DATOS = os.path.expanduser("~/.var/app/org.love2d.love2d/data/love/orbita84")
TMP = os.path.join(RAIZ, "trailer", "tmp")
FPS = 30
W, H = 84, 48
ESCALA = 20
SALIDA_W, SALIDA_H = 1920, 1080

_fuente = open(os.path.join(JUEGO, "datos.lua"), encoding="utf-8").read()


def _tabla(nombre):
    """Lee D.letras o D.gordas de datos.lua: { letra: [filas] }."""
    i = _fuente.index("D.%s = {" % nombre) + len("D.%s = {" % nombre)
    j = _fuente.index("\n}", i)
    out = {}
    for m in re.finditer(r'(?:\["(.)"\]|(\w))\s*=\s*\{([^}]*)\}', _fuente[i:j]):
        out[m.group(1) or m.group(2)] = re.findall(r'"([^"]*)"', m.group(3))
    return out


LETRAS, GORDAS = _tabla("letras"), _tabla("gordas")
_p = re.search(r'nombre = "VERDE", fondo = \{ ([\d., ]+) \}, tinta = \{ ([\d., ]+) \}, marco = \{ ([\d., ]+) \}', _fuente)
FONDO, TINTA, MARCO = [tuple(round(float(v) * 255) for v in g.split(",")) for g in _p.groups()]


def mezcla(c):
    return tuple(round(FONDO[i] + (TINTA[i] - FONDO[i]) * c) for i in range(3))


MEDIO = mezcla(0.45)

# ---------------------------------------------------------------- textos
TEXTOS = {
    "es": {
        "presenta": ["D4RK3R", "PRESENTA"],
        "roswell": ["1947", "ALGO CAYO", "DEL CIELO"],
        "diez": ["DIEZ CASOS", "DIEZ JEFES"],
        "mapa": ["LAS LUCES", "DIBUJAN", "UN MAPA"],
        "por": "POR D4RK3R",
        "juega": ["JUEGA GRATIS", "", "DARKER03.ITCH.IO"],
    },
    "en": {
        "presenta": ["D4RK3R", "PRESENTS"],
        "roswell": ["1947", "SOMETHING FELL", "FROM THE SKY"],
        "diez": ["TEN CASE FILES", "TEN BOSSES"],
        "mapa": ["THE LIGHTS", "DRAW", "A MAP"],
        "por": "BY D4RK3R",
        "juega": ["PLAY FREE", "", "DARKER03.ITCH.IO"],
    },
}
# (nivel, caso) para los cortes rápidos: un cartel corto y su jefe
CASOS = [(3, "PHOENIX 1997"), (4, "HANGAR 18"), (5, "LOS HILL 1961"), (6, "SHAG HARBOUR 1967"),
         (7, "BAIKAL 1982"), (8, "GOLFO NUEVO 1960"), (9, "LUBBOCK 1951"), (10, "BERMUDAS 1945")]
# algunos cortes muestran además un poder: (desde, hasta, variables del modo captura)
CON_PODER = {
    3: (14.0, 16.4, {"ORBITA_PODER": "sonda", "ORBITA_USAR": 13.5}),     # la sonda lanza cohetes en tierra
    4: (14.4, 16.8, {"ORBITA_PODER": "tiempo", "ORBITA_USAR": 14.2}),    # tiempo perdido: estelas y esquinas
    10: (15.2, 17.6, {"ORBITA_LLENO": 1, "ORBITA_FASE": 3}),             # el obús lleno contra los anillos
}


# ---------------------------------------------------------------- grabar tomas del juego
def grabar(nombre, desde, hasta, idioma, **env):
    """Graba una toma con el modo captura y la deja en TMP/<nombre>/ como grilla de 84x48."""
    carpeta = os.path.join(TMP, idioma + "_" + nombre)
    if os.path.exists(os.path.join(carpeta, "listo")):
        return carpeta
    shutil.rmtree(os.path.join(DATOS, "video"), ignore_errors=True)
    e = dict(os.environ, ORBITA_CAPTURA="1", ORBITA_VIDEO="1", ORBITA_VIDEO_DESDE=str(desde),
             ORBITA_VIDEO_HASTA=str(hasta), ORBITA_IDIOMA=idioma, **{k: str(v) for k, v in env.items()})
    subprocess.run(["timeout", "120", "flatpak", "run", "--user", "--filesystem=" + JUEGO,
                    "org.love2d.love2d", JUEGO], env=e, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    origen = os.path.join(DATOS, "video")
    cuadros = sorted(f for f in os.listdir(origen) if f.endswith(".png"))
    if not cuadros:
        sys.exit("la toma %s no grabó cuadros" % nombre)
    shutil.rmtree(carpeta, ignore_errors=True)
    os.makedirs(carpeta)
    for i, f in enumerate(cuadros):
        im = Image.open(os.path.join(origen, f)).convert("RGB")
        # la pantalla está a 7x en (26, 72); se toma el centro de cada píxel del juego
        g = Image.new("RGB", (W, H))
        px = g.load()
        for y in range(H):
            for x in range(W):
                px[x, y] = im.getpixel((26 + x * 7 + 3, 72 + y * 7 + 3))
        g.save(os.path.join(carpeta, "%05d.png" % (i + 1)))
    if os.path.exists(os.path.join(origen, "sonidos.txt")):
        shutil.copy(os.path.join(origen, "sonidos.txt"), carpeta)
    open(os.path.join(carpeta, "listo"), "w").write(str(len(cuadros)))
    print("toma %s %s: %d cuadros" % (idioma, nombre, len(cuadros)))
    return carpeta


def toma(carpeta):
    """Cuadros (imágenes 84x48) y sonidos [(cuadro, nombre)] de una toma grabada."""
    n = int(open(os.path.join(carpeta, "listo")).read())
    cuadros = [Image.open(os.path.join(carpeta, "%05d.png" % (i + 1))).convert("RGB") for i in range(n)]
    sonidos = []
    ruta = os.path.join(carpeta, "sonidos.txt")
    if os.path.exists(ruta):
        for linea in open(ruta):
            c, nombre = linea.split()
            sonidos.append((int(c) - 1, nombre))
    return cuadros, sonidos


# ---------------------------------------------------------------- carteles
def lienzo():
    return Image.new("RGB", (W, H), FONDO)


def texto(im, cadena, y, color=TINTA):
    d = ImageDraw.Draw(im)
    x0 = (W - (len(cadena) * 4 - 1)) // 2
    for i, ch in enumerate(cadena):
        filas = LETRAS.get(ch)
        if not filas:
            continue
        for fy, f in enumerate(filas):
            for fx, c in enumerate(f):
                if c == "#":
                    d.point((x0 + i * 4 + fx, y + fy), fill=color)


def gordo(im, cadena, y, escala=1):
    d = ImageDraw.Draw(im)
    paso = 7 * escala
    ancho = len(cadena) * paso - escala
    x0 = (W - ancho) // 2
    for capa, color in ((1, MEDIO), (0, TINTA)):
        for i, ch in enumerate(cadena):
            for fy, f in enumerate(GORDAS.get(ch, [])):
                for fx, c in enumerate(f):
                    if c == "#":
                        x, yy = x0 + i * paso + fx * escala + capa, y + fy * escala + capa
                        d.rectangle([x, yy, x + escala - 1, yy + escala - 1], fill=color)


def marco_lcd(im):
    d = ImageDraw.Draw(im)
    for x in range(0, W, 2):
        d.point((x, 1), fill=MEDIO)
        d.point((x, H - 2), fill=MEDIO)


def cartel(lineas, segundos):
    im = lienzo()
    marco_lcd(im)
    alto = len(lineas) * 7 - 2
    y = (H - alto) // 2
    for i, l in enumerate(lineas):
        texto(im, l, y + i * 7)
    return [im] * round(segundos * FPS)


def cartel_caso(caso, segundos):
    im = lienzo()
    d = ImageDraw.Draw(im)
    # ficha de expediente: franja en negativo con el nombre del caso
    d.rectangle([4, 18, W - 5, 28], fill=TINTA)
    texto(im, caso, 21, FONDO)
    texto(im, "EXPEDIENTE", 11, MEDIO)
    return [im] * round(segundos * FPS)


def cartel_titulo(firma, segundos):
    im = lienzo()
    gordo(im, "ORBITA", 6)
    gordo(im, "84", 15, 2)
    texto(im, firma, 38, MEDIO)
    return [im] * round(segundos * FPS)


# ---------------------------------------------------------------- persiana entre partes
def persiana(a, b):
    """La transición del juego: franjas de tinta cada 6 filas que cierran sobre a y abren b."""
    out = []
    for k in list(range(1, 7)) + list(range(5, -1, -1)):
        base = (a if len(out) < 6 else b).copy()
        d = ImageDraw.Draw(base)
        for y in range(0, H, 6):
            if k > 0:
                d.rectangle([0, y, W - 1, y + k - 1], fill=TINTA)
        out.append(base)
    return out


# ---------------------------------------------------------------- sonido (igual que main.lua)
MUESTRAS = 22050


def pitido(notas, dur, tipo=None):
    por = int(MUESTRAS * dur)
    out = []
    import random
    r = random.Random(4)
    for f in notas:
        for n in range(por):
            if tipo == "ruido":
                v = (r.random() * 2 - 1) * (1 - n / por)
            elif f == 0:
                v = 0
            else:
                v = 1 if (n * f / MUESTRAS) % 1 < 0.5 else -1
            out.append(v * 0.18)
    return out


SEMITONO = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}


def frecuencia(nota):
    if nota == "-":
        return 0
    m = re.match(r"^([A-G])(#?)(\d)$", nota)
    n = SEMITONO[m.group(1)] + (1 if m.group(2) else 0) + (int(m.group(3)) - 4) * 12
    return 440 * 2 ** (n / 12)


def _melodia_def(nombre):
    i = _fuente.index("D.melodias = {")
    bloque = _fuente[i:_fuente.index("\n}", i)]
    m = re.search(nombre + r"\s*=\s*\{\s*tempo = (\d+),\s*notas = ((?:\"[^\"]*\"\s*(?:\.\.)?\s*)+),?\s*\}", bloque)
    return int(m.group(1)), "".join(re.findall(r'"([^"]*)"', m.group(2)))


def melodia(nombre, volumen=0.12):
    tempo, notas = _melodia_def(nombre)
    corchea = 60 / tempo / 2
    out = []
    for nota, d in re.findall(r"([\w#\-]+):(\d+)", notas):
        f, largo = frecuencia(nota), int(MUESTRAS * corchea * int(d))
        for n in range(largo):
            out.append((volumen if (n * f / MUESTRAS) % 1 < 0.5 else -volumen) if f > 0 and n < largo * 0.85 else 0)
    return out


SONIDOS = {
    "disparo": pitido([1760], 0.03), "rayo": pitido([880, 1320, 1760, 2349], 0.04),
    "pulso": pitido([2349, 1760, 1175, 880, 587], 0.035), "golpe": pitido([440], 0.03),
    "explosion": pitido([1], 0.18, "ruido"), "mejora": pitido([1047, 1319, 1568, 2093], 0.05),
    "dano": pitido([330, 220, 147], 0.08), "jefe": pitido([440, 0, 440, 0, 440, 0, 330], 0.1),
    "victoria": melodia("victoria"), "inicio": melodia("nivel"),
    "fin": pitido([392, 330, 262, 196], 0.15), "menu": pitido([1319], 0.04),
    "rebote": pitido([2637], 0.02), "embestida": pitido([196, 220, 247, 262], 0.05),
    "salto": pitido([523, 659, 784], 0.025),
    "tic": pitido([2093], 0.015), "tac": pitido([1568], 0.015),
}
TITULO = melodia("titulo")


# ---------------------------------------------------------------- armado
def armar(idioma):
    t = TEXTOS[idioma]
    partes = []  # (cuadros, sonidos)

    def agregar(cuadros, sonidos=()):
        partes.append((cuadros, list(sonidos)))

    def tomar(nombre, desde, hasta, **env):
        c, s = toma(grabar(nombre, desde, hasta, idioma, **env))
        agregar(c, s)

    agregar(cartel(t["presenta"], 2.0))
    tomar("portada", 0.2, 3.4, ORBITA_PORTADA=1)
    tomar("menu", 0.3, 1.5, ORBITA_PANTALLA="menu", ORBITA_HOJA="principal")
    tomar("menu_nave", 0.3, 1.5, ORBITA_PANTALLA="menu", ORBITA_HOJA="nave")
    agregar(cartel(t["roswell"], 1.8))
    tomar("nivel1", 4.0, 7.6, ORBITA_NIVEL=1, ORBITA_PODER="escudo")
    tomar("jefe1", 14.0, 17.0, ORBITA_NIVEL=1)
    agregar(cartel(t["diez"], 1.6))
    for nivel, caso in CASOS:
        agregar(cartel_caso(caso, 1.0))
        desde, hasta, extra = CON_PODER.get(nivel, (14.0, 16.4, {}))
        tomar("jefe%d" % nivel, desde, hasta, ORBITA_NIVEL=nivel, **extra)
    agregar(cartel(t["mapa"], 1.6))
    tomar("mapa", 0.3, 1.9, ORBITA_PANTALLA="mapa", ORBITA_PIEZA=10)
    agregar(cartel_titulo(t["por"], 2.6))
    agregar(cartel(t["juega"], 2.8))

    # una sola lista de cuadros, con la persiana entre parte y parte
    cuadros, eventos = [], []
    for i, (c, s) in enumerate(partes):
        base = len(cuadros)
        if i > 0:
            trans = persiana(cuadros[-1], c[0])
            # la persiana cierra sobre los últimos cuadros de la parte anterior
            cuadros[-6:] = trans[:6]
            cuadros += trans[6:]
            base = len(cuadros) - 6
            c = c[6:] if len(c) > 12 else c
        cuadros += c
        for cuadro, nombre in s:
            if nombre in SONIDOS:
                eventos.append((base + cuadro, nombre))
    total = len(cuadros)
    print("%s: %d cuadros (%.1f s)" % (idioma, total, total / FPS))

    # audio: la melodía del título de fondo, más los sonidos del juego en su cuadro
    largo = int(total / FPS * MUESTRAS) + MUESTRAS
    mezcla_audio = [0.0] * largo
    i = 0
    while i < largo:
        for k, v in enumerate(TITULO):
            if i + k >= largo:
                break
            mezcla_audio[i + k] += v * 0.55
        i += len(TITULO)
    ultimo = {}
    for cuadro, nombre in sorted(eventos):
        inicio = int(cuadro / FPS * MUESTRAS)
        if ultimo.get(nombre) == cuadro:
            continue
        ultimo[nombre] = cuadro
        for k, v in enumerate(SONIDOS[nombre]):
            if inicio + k < largo:
                mezcla_audio[inicio + k] += v * 0.8
    # se apaga en el último segundo
    fin = int(total / FPS * MUESTRAS)
    for k in range(max(0, fin - MUESTRAS), largo):
        mezcla_audio[k] *= max(0.0, (fin - k) / MUESTRAS)
    carpeta = os.path.join(TMP, "salida_" + idioma)
    shutil.rmtree(carpeta, ignore_errors=True)
    os.makedirs(carpeta)
    with wave.open(os.path.join(carpeta, "audio.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(MUESTRAS)
        w.writeframes(array.array("h", (int(max(-1, min(1, v)) * 32000) for v in mezcla_audio)).tobytes())

    # imagen: la pantalla a 20x con su rejilla de LCD, sobre el marco de la consola
    rejilla = Image.new("RGBA", (W * ESCALA, H * ESCALA), (0, 0, 0, 0))
    d = ImageDraw.Draw(rejilla)
    linea = FONDO + (90,)
    for x in range(1, W):
        d.line([(x * ESCALA, 0), (x * ESCALA, H * ESCALA)], fill=linea)
    for y in range(1, H):
        d.line([(0, y * ESCALA), (W * ESCALA, y * ESCALA)], fill=linea)
    ox, oy = (SALIDA_W - W * ESCALA) // 2, (SALIDA_H - H * ESCALA) // 2
    for n, c in enumerate(cuadros):
        g = c.resize((W * ESCALA, H * ESCALA), Image.NEAREST).convert("RGBA")
        g.alpha_composite(rejilla)
        lienzo_salida = Image.new("RGB", (SALIDA_W, SALIDA_H), MARCO)
        lienzo_salida.paste(g.convert("RGB"), (ox, oy))
        lienzo_salida.save(os.path.join(carpeta, "%05d.png" % (n + 1)))
    destino = os.path.join(RAIZ, "trailer", "orbita84-trailer-%s.mp4" % idioma)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", str(FPS), "-i",
                    os.path.join(carpeta, "%05d.png"), "-i", os.path.join(carpeta, "audio.wav"),
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "slow", "-crf", "16",
                    "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-shortest", "-movflags", "+faststart",
                    destino], check=True)
    shutil.rmtree(carpeta, ignore_errors=True)
    print("listo:", destino)


if __name__ == "__main__":
    idiomas = sys.argv[1:] or ["es", "en"]
    os.makedirs(TMP, exist_ok=True)
    # se graba con la paleta verde (la del juego al arrancar) y se devuelven los ajustes
    ajustes = os.path.join(DATOS, "ajustes.txt")
    copia = open(ajustes).read() if os.path.exists(ajustes) else None
    try:
        lineas = [l for l in (copia or "").splitlines() if not l.startswith(("paleta=", "silencio=", "idioma="))]
        open(ajustes, "w").write("\n".join(["paleta=1", "silencio=1"] + lineas) + "\n")
        for idioma in idiomas:
            armar(idioma)
    finally:
        if copia is not None:
            open(ajustes, "w").write(copia)
