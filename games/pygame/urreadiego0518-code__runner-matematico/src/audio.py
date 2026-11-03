"""Música y efectos de sonido generados por código.

No hace falta ningún archivo de audio: las ondas se sintetizan al arrancar y
se cargan en el mezclador de pygame. Si el equipo no tiene salida de audio el
juego sigue funcionando igual (todo queda en modo silencioso).
"""

import array
import math

import pygame

SR = 22050          # frecuencia de muestreo (Hz)
_FORMATO = -16      # 16 bits con signo
_CANALES = 1        # mono

_disponible = False
_musica_activa = True
_musica = None
_musicas = {}
_pista_actual = None
_sonidos = {}

# -----------------------------------------------------------------------------
#  Síntesis básica
# -----------------------------------------------------------------------------
_INDICE_NOTA = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
                "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def frecuencia(nombre):
    """'A4' -> 440.0 Hz, 'C5' -> 523.25 Hz..."""
    letra, octava = nombre[:-1], int(nombre[-1])
    semitonos = _INDICE_NOTA[letra] + 12 * (octava - 4) - 9
    return 440.0 * 2 ** (semitonos / 12.0)


def _onda(freq, dur, vol, forma="cuadrada", caida=4.0):
    """Una nota con envolvente de ataque rápido y caída exponencial."""
    n = max(1, int(SR * dur))
    salida = [0.0] * n
    ataque = max(1, int(SR * 0.006))
    for i in range(n):
        t = i / SR
        fase = (freq * t) % 1.0
        if forma == "cuadrada":
            v = 1.0 if fase < 0.5 else -1.0
        elif forma == "triangulo":
            v = 4.0 * abs(fase - 0.5) - 1.0
        elif forma == "seno":
            v = math.sin(2.0 * math.pi * fase)
        else:                                   # sierra
            v = 2.0 * fase - 1.0
        env = min(1.0, i / ataque) * math.exp(-t * caida / dur)
        salida[i] = v * env * vol
    return salida


def _barrido(f0, f1, dur, vol, forma="cuadrada"):
    """Nota que sube o baja de frecuencia (para saltos y choques)."""
    n = max(1, int(SR * dur))
    salida = [0.0] * n
    fase = 0.0
    for i in range(n):
        p = i / max(1, n - 1)
        fase += (f0 + (f1 - f0) * p) / SR
        f = fase % 1.0
        if forma == "cuadrada":
            v = 1.0 if f < 0.5 else -1.0
        elif forma == "triangulo":
            v = 4.0 * abs(f - 0.5) - 1.0
        else:
            v = 2.0 * f - 1.0
        salida[i] = v * vol * (1.0 - p) ** 1.5
    return salida


def _mezclar(destino, origen, inicio=0):
    for i, v in enumerate(origen):
        j = inicio + i
        if j >= len(destino):
            break
        destino[j] += v


def _secuencia(notas, vol, forma="cuadrada", caida=4.0):
    """Une una lista de (nota, duración) en una sola onda."""
    total = sum(d for _, d in notas)
    buf = [0.0] * max(1, int(SR * total))
    pos = 0
    for nombre, dur in notas:
        if nombre:
            _mezclar(buf, _onda(frecuencia(nombre), dur, vol, forma, caida), pos)
        pos += int(SR * dur)
    return buf


def _a_sonido(muestras):
    """Convierte una lista de flotantes [-1, 1] en un pygame.mixer.Sound."""
    datos = array.array("h", (int(max(-1.0, min(1.0, m)) * 32000) for m in muestras))
    return pygame.mixer.Sound(buffer=datos.tobytes())


# -----------------------------------------------------------------------------
#  Piezas concretas
# -----------------------------------------------------------------------------
def _generar_musica():
    """Bucle alegre de 4 compases (8 bits, sin archivos externos)."""
    corchea = 60.0 / 132 / 2            # 132 BPM -> 0.227 s

    melodia = ["C5", "E5", "G5", "E5", "C5", "E5", "G5", "A5",
               "G5", "E5", "C5", "E5", "D5", "E5", "G5", "E5",
               "F5", "A5", "C6", "A5", "F5", "A5", "C6", "D6",
               "C6", "G5", "E5", "G5", "C5", "E5", "G5", "C6"]
    bajo = [("C3", 4), ("G3", 4), ("A2", 4), ("E3", 4),
            ("F2", 4), ("C3", 4), ("G2", 4), ("D3", 4)]

    total = int(SR * corchea * len(melodia))
    buf = [0.0] * total

    for i, nombre in enumerate(melodia):
        onda = _onda(frecuencia(nombre), corchea * 0.9, 0.16, "cuadrada", 5.0)
        _mezclar(buf, onda, int(i * corchea * SR))

    pos = 0
    for nombre, corcheas in bajo:
        onda = _onda(frecuencia(nombre), corcheas * corchea * 0.95, 0.20, "triangulo", 2.0)
        _mezclar(buf, onda, pos)
        pos += int(corcheas * corchea * SR)

    return buf


def _generar_musica_menu():
    """Tema de menú: más lento y misterioso (La menor), distinto al del juego."""
    negra = 60.0 / 100                      # 100 BPM -> 0.6 s por negra
    melodia = ["A4", "C5", "E5", "A5",
               "G4", "B4", "D5", "G5",
               "F4", "A4", "C5", "F5",
               "E4", "G#4", "B4", "E5"]
    bajo = [("A2", 4), ("G2", 4), ("F2", 4), ("E2", 4)]

    total = int(SR * negra * len(melodia))
    buf = [0.0] * total

    for i, nombre in enumerate(melodia):
        onda = _onda(frecuencia(nombre), negra * 0.92, 0.15, "triangulo", 3.0)
        _mezclar(buf, onda, int(i * negra * SR))
        # Capa de seno una octava arriba: da el aire "fantasmal"
        brillo = _onda(frecuencia(nombre) * 2, negra * 0.8, 0.04, "seno", 4.0)
        _mezclar(buf, brillo, int(i * negra * SR))

    pos = 0
    for nombre, negras in bajo:
        onda = _onda(frecuencia(nombre), negras * negra * 0.96, 0.18, "triangulo", 2.0)
        _mezclar(buf, onda, pos)
        pos += int(negras * negra * SR)

    return buf


def _generar_efectos():
    efectos = {}

    efectos["salto"] = _barrido(520, 900, 0.13, 0.30)
    efectos["punto"] = _secuencia([("E6", 0.05), ("A6", 0.05)], 0.22, "triangulo")
    efectos["choque"] = _barrido(320, 70, 0.30, 0.35, "sierra")

    # Vida extra: arpegio ascendente y brillante, inconfundible.
    arpegio = [("C5", 0.075), ("E5", 0.075), ("G5", 0.075),
               ("C6", 0.075), ("E6", 0.13)]
    vida = _secuencia(arpegio, 0.26, "triangulo", 5.0)
    brillo = _secuencia(arpegio, 0.10, "seno", 3.0)
    for i, v in enumerate(brillo):
        vida[i] += v
    efectos["vida"] = vida

    # Vida con el máximo lleno: mismo arpegio, final distinto.
    efectos["vida_llena"] = _secuencia(
        [("C5", 0.07), ("G5", 0.07), ("C6", 0.07), ("G6", 0.16)],
        0.24, "triangulo", 5.0)

    efectos["game_over"] = _secuencia(
        [("G4", 0.16), ("E4", 0.16), ("C4", 0.16), ("C3", 0.42)],
        0.26, "triangulo", 2.2)

    efectos["blip"] = _secuencia([("E5", 0.045)], 0.18, "triangulo")

    # --- Bonus: letras, fórmula completa y subida de nivel ---
    # Letra recogida: dos notas cortas, suaves, para no tapar la música.
    efectos["letra"] = _secuencia([("G5", 0.05), ("D6", 0.08)], 0.18, "triangulo")

    # Fórmula completada: fanfarria corta y clara.
    efectos["formula"] = _secuencia(
        [("C5", 0.09), ("E5", 0.09), ("G5", 0.09), ("C6", 0.09),
         ("E6", 0.30)], 0.22, "cuadrada", 3.5)

    # Subida de nivel (cada 10.000 puntos): barrido ascendente con cuerpo.
    nivel = _secuencia([("C4", 0.07), ("G4", 0.07), ("C5", 0.07),
                        ("G5", 0.07), ("C6", 0.20)], 0.24, "triangulo", 3.0)
    _mezclar(nivel, _barrido(300, 1200, 0.45, 0.10, "sierra"), 0)
    efectos["nivel"] = nivel

    return {nombre: _a_sonido(onda) for nombre, onda in efectos.items()}


# -----------------------------------------------------------------------------
#  API pública
# -----------------------------------------------------------------------------
def iniciar():
    """Inicializa el mezclador y prepara música y efectos. Nunca lanza error."""
    global _disponible, _musica, _pista_actual
    if _disponible:
        return True
    try:
        if pygame.mixer.get_init() is None:
            pygame.mixer.init(frequency=SR, size=_FORMATO,
                              channels=_CANALES, buffer=512)
        pygame.mixer.set_num_channels(8)
        _sonidos.update(_generar_efectos())
        _musicas["juego"] = _a_sonido(_generar_musica())
        _musicas["menu"] = _a_sonido(_generar_musica_menu())
        for pista in _musicas.values():
            pista.set_volume(0.5)
        _musica = _musicas["menu"]
        _pista_actual = "menu"
        _disponible = True
        if _musica_activa:
            _musica.play(loops=-1)
    except Exception:
        _disponible = False
    return _disponible


def musica(pista="juego"):
    """Cambia la música de fondo ('menu' o 'juego'). No reinicia si ya suena."""
    global _musica, _pista_actual
    if pista == _pista_actual:
        return _pista_actual
    _pista_actual = pista
    if not _disponible:
        return _pista_actual
    nueva = _musicas.get(pista)
    if nueva is None:
        return _pista_actual
    try:
        if _musica is not None and _musica is not nueva:
            _musica.stop()
        _musica = nueva
        if _musica_activa:
            nueva.play(loops=-1)
    except Exception:
        pass
    return _pista_actual


def sonar(nombre):
    """Reproduce un efecto. Si no hay audio, no hace nada."""
    if not _disponible:
        return
    efecto = _sonidos.get(nombre)
    if efecto is not None:
        try:
            efecto.play()
        except Exception:
            pass


def alternar_musica():
    """Enciende/apaga la música. Devuelve True si queda encendida."""
    global _musica_activa
    _musica_activa = not _musica_activa
    if _disponible and _musica is not None:
        try:
            if _musica_activa:
                _musica.play(loops=-1)
            else:
                _musica.stop()
        except Exception:
            pass
    return _musica_activa


def musica_activa():
    return _musica_activa


def disponible():
    return _disponible
