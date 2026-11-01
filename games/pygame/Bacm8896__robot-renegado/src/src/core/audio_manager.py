"""AudioManager: efectos (SFX) y música con volúmenes independientes, en modo híbrido y sin fallar nunca.

- Archivos reales: si existe `assets/audio/sfx/<nombre>.wav|.ogg` (o `assets/audio/music/<pista>.ogg|.mp3|.wav`), se usa.
- Si no, el efecto se sintetiza al vuelo (ondas de 16 bits con `array`, sin dependencias extra) para que el juego nunca
  quede mudo por un asset que falta.
- Canales reservados para que unos sonidos no corten a otros: disparo (0), interfaz y texto (1), impactos (2) y la pista
  de música sintetizada (3). El resto de efectos usa cualquier canal libre del mixer.
- Modo silencioso (dummy): sin dispositivo de audio, con el mixer roto, con el vídeo `dummy` (pruebas/CI) o con
  `RR_AUDIO=off`, `play` no suena ni lanza excepciones. Todas las peticiones quedan en `history` (también en silencio),
  así las pruebas comprueban qué eventos dispararon sonido.

Uso: `from src.core.audio_manager import audio` y `audio.play("rifle")`, `audio.play_music("menu")`,
`audio.set_sfx_volume(0.6)`, `audio.set_music_volume(0.3)`."""
import array
import collections
import logging
import math
import os
import random
import time

import pygame

import config as C

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets", "audio")
SFX_DIR, MUSIC_DIR = os.path.join(ROOT, "sfx"), os.path.join(ROOT, "music")
CH_FIRE, CH_UI, CH_IMPACT, CH_MUSIC = 0, 1, 2, 3
RESERVED = 4
log = logging.getLogger(__name__)

# nombre -> (canal, separación mínima entre dos reproducciones en s, volumen relativo)
SOUNDS = {
    "rifle": ("fire", 0.04, 0.45),             # disparo del Operador (Player.shoot)
    "dash": ("pool", 0.08, 0.55),              # activación del Dash
    "medkit": ("pool", 0.2, 0.7),              # [H] botiquín: inyección y bloque recuperado
    "hit": ("impact", 0.09, 0.6),              # impacto recibido por el Operador
    "block_break": ("pool", 0.25, 0.8),        # un bloque de vida se vacía del todo
    "build_mode": ("ui", 0.1, 0.5),            # [ESPACIO] Modo Construcción / pausa táctica
    "build_mode_off": ("ui", 0.1, 0.45),
    "place": ("pool", 0.05, 0.6),              # estructura colocada (o terminada por VULCANO)
    "pylon_link": ("pool", 0.1, 0.55),         # pilón conectado a la red
    "text_aura": ("ui", 0.05, 0.22),           # teletipo de los diálogos
    "text_vulcano": ("ui", 0.05, 0.22),
    "text_sistema": ("ui", 0.05, 0.16),
    "core_shot": ("impact", 0.1, 0.45),        # cañón centinela del Centro de Control (defensa propia)
    "crit": ("impact", 0.12, 0.7),             # golpe crítico al punto débil del Ariete Ligero
    "ricochet": ("impact", 0.09, 0.5),
    "error": ("ui", 0.3, 0.5),                 # aviso de interfaz
    "order": ("ui", 0.12, 0.5),                # orden táctica a los drones seleccionados (mover / foco de ataque)
}


# ------------------------------------------------------------------ síntesis
def tone(duration, partials, decay, noise=0.0, seed=1, sweep=0.0, square=False, attack=0.004, rate=RATE):
    """Onda de 16 bits mono: suma de parciales (freq, amplitud) con envolvente exponencial. `sweep`: la frecuencia varía
    ese factor a lo largo del sonido (+ sube, - baja); `square`: timbre de onda cuadrada (blips de texto)."""
    rng = random.Random(seed)
    n = int(rate * duration)
    buf = array.array("h")
    norm = sum(a for _, a in partials) + noise or 1.0
    phase = [0.0] * len(partials)
    for i in range(n):
        t = i / rate
        env = math.exp(-decay * t) * min(1.0, t / attack if attack > 0 else 1.0)
        k = 1.0 + sweep * (i / n)
        v = 0.0
        for j, (f, a) in enumerate(partials):
            phase[j] += 2 * math.pi * f * k / rate
            s = math.sin(phase[j])
            v += a * ((1.0 if s >= 0 else -1.0) if square else s)
        if noise:
            v += noise * (rng.random() * 2 - 1)
        buf.append(int(max(-1.0, min(1.0, v / norm * env)) * 32000))
    return buf


def ambient_pad(duration=8.0, root=55.0, rate=RATE):
    """Pista de respaldo: colchón grave y suave (raíz, quinta y octava) que respira despacio y empalma sin corte."""
    n = int(rate * duration)
    buf = array.array("h")
    freqs = (root, root * 1.5, root * 2.0, root * 3.0)
    amps = (0.5, 0.3, 0.25, 0.08)
    for i in range(n):
        t = i / rate
        breath = 0.6 + 0.4 * math.sin(2 * math.pi * t / duration)          # un ciclo entero: el bucle no salta
        v = sum(a * math.sin(2 * math.pi * f * t) for f, a in zip(freqs, amps))
        buf.append(int(v / sum(amps) * breath * 9000))
    return buf


RECIPES = {
    "rifle": lambda r: tone(0.08, ((900, 0.5), (1800, 0.25)), 48, noise=0.9, seed=11, sweep=-0.4, rate=r),
    "dash": lambda r: tone(0.22, ((260, 0.4),), 14, noise=0.8, seed=12, sweep=1.4, attack=0.03, rate=r),
    "medkit": lambda r: tone(0.34, ((660, 0.5), (990, 0.35), (1320, 0.2)), 7, noise=0.05, seed=13, sweep=0.5, attack=0.02, rate=r),
    "hit": lambda r: tone(0.14, ((120, 0.8), (240, 0.3)), 26, noise=0.5, seed=14, sweep=-0.3, rate=r),
    "block_break": lambda r: tone(0.36, ((90, 0.7), (180, 0.4), (1300, 0.25)), 10, noise=0.6, seed=15, sweep=-0.5, rate=r),
    "build_mode": lambda r: tone(0.16, ((520, 0.5), (780, 0.4)), 16, seed=16, sweep=0.6, square=True, rate=r),
    "build_mode_off": lambda r: tone(0.16, ((780, 0.5), (520, 0.4)), 16, seed=17, sweep=-0.4, square=True, rate=r),
    "place": lambda r: tone(0.15, ((160, 0.7), (320, 0.3)), 22, noise=0.35, seed=18, rate=r),
    "pylon_link": lambda r: tone(0.3, ((440, 0.4), (880, 0.35), (1760, 0.15)), 9, noise=0.15, seed=19, sweep=0.8, rate=r),
    "text_aura": lambda r: tone(0.03, ((1450, 1.0),), 60, seed=20, square=True, rate=r),
    "text_vulcano": lambda r: tone(0.035, ((520, 1.0),), 50, seed=21, square=True, rate=r),
    "text_sistema": lambda r: tone(0.025, ((980, 1.0),), 70, seed=22, square=True, rate=r),
    "core_shot": lambda r: tone(0.12, ((620, 0.6), (1240, 0.3)), 30, noise=0.3, seed=23, sweep=-0.5, rate=r),
    "crit": lambda r: tone(0.28, ((180, 0.9), (740, 0.6), (1480, 0.4), (2210, 0.25)), 14, noise=0.5, seed=3, rate=r),
    "ricochet": lambda r: tone(0.1, ((2400, 0.7), (3600, 0.4)), 40, noise=0.2, seed=5, rate=r),
    "order": lambda r: tone(0.14, ((660, 0.5), (990, 0.35)), 18, seed=24, sweep=0.3, square=True, rate=r),
    "error": lambda r: tone(0.22, ((140, 0.8), (210, 0.5)), 8, noise=0.1, seed=7, rate=r),
}


# ------------------------------------------------------------------ gestor
class AudioManager:
    def __init__(self):
        self._ready = None               # None: aún sin intentar · True: suena · False: modo silencioso
        self.channels = 1
        self.rate = RATE                 # frecuencia real del mixer: la síntesis la respeta (si no, todo sonaría agudo)
        self.sfx_volume = C.AUDIO_SFX_VOLUME
        self.music_volume = C.AUDIO_MUSIC_VOLUME
        self.history = collections.deque(maxlen=400)     # [(instante, nombre)] de todo lo pedido (también en silencio)
        self.sources = {}                # nombre -> "file" | "synth" (de dónde salió cada efecto cargado)
        self.music_track = None
        self.music_source = None         # "file" | "synth" | None
        self._cache = {}
        self._last = {}
        self._reserved = {}

    # --- inicialización resistente ---
    @property
    def enabled(self):
        if self._ready is None:
            self._ready = self._init()
        return self._ready

    def _init(self):
        try:
            if os.environ.get("RR_AUDIO", "").lower() in ("0", "off", "no") or pygame.display.get_driver() == "dummy":
                return False                                     # pruebas / CI / sin ventana real: modo silencioso
            if not pygame.mixer.get_init():
                pygame.mixer.init(frequency=RATE, size=-16, channels=2)
            info = pygame.mixer.get_init()
            if info is None:
                return False
            self.rate, self.channels = info[0], info[2]
            pygame.mixer.set_num_channels(max(16, pygame.mixer.get_num_channels()))
            pygame.mixer.set_reserved(RESERVED)
            self._reserved = {"fire": pygame.mixer.Channel(CH_FIRE), "ui": pygame.mixer.Channel(CH_UI),
                              "impact": pygame.mixer.Channel(CH_IMPACT), "music": pygame.mixer.Channel(CH_MUSIC)}
            return True
        except (pygame.error, NotImplementedError, OSError) as exc:
            log.info("audio desactivado (modo silencioso): %s", exc)
            return False

    def disable(self):
        """Fuerza el modo silencioso (sin tocar el mixer)."""
        self._ready = False

    # --- volúmenes ---
    def set_sfx_volume(self, value):
        self.sfx_volume = max(0.0, min(1.0, float(value)))

    def set_music_volume(self, value):
        self.music_volume = max(0.0, min(1.0, float(value)))
        if self.enabled:
            try:
                pygame.mixer.music.set_volume(self.music_volume)
                self._reserved["music"].set_volume(self.music_volume)
            except pygame.error:
                pass

    # --- carga ---
    @staticmethod
    def _find(folder, name, exts):
        for ext in exts:
            path = os.path.join(folder, name + ext)
            if os.path.isfile(path):
                return path
        return None

    def _to_sound(self, buf):
        if self.channels == 2:                                   # el mixer estéreo pide muestras intercaladas L/R
            stereo = array.array("h")
            for s in buf:
                stereo.append(s)
                stereo.append(s)
            buf = stereo
        return pygame.mixer.Sound(buffer=buf.tobytes())

    def _sound(self, name):
        snd = self._cache.get(name)
        if snd is not None:
            return snd
        path = self._find(SFX_DIR, name, (".wav", ".ogg"))
        if path is not None:
            try:
                snd = pygame.mixer.Sound(path)
                self.sources[name] = "file"
            except pygame.error as exc:
                log.warning("no se pudo cargar %s (%s): se sintetiza", path, exc)
        if snd is None:
            snd = self._to_sound(RECIPES[name](self.rate))
            self.sources[name] = "synth"
        self._cache[name] = snd
        return snd

    def synth(self, name):
        """Muestras sintetizadas de un efecto a la frecuencia del mixer (para pruebas y para el respaldo)."""
        return RECIPES[name](self.rate)

    # --- efectos ---
    def play(self, name):
        """Reproduce el efecto `name` en su canal. Devuelve True si sonó (False en silencio, por la separación mínima o
        si el nombre no existe). Nunca lanza excepciones."""
        spec = SOUNDS.get(name)
        if spec is None:
            return False
        now = time.monotonic()
        self.history.append((now, name))
        if not self.enabled:
            return False
        channel, gap, vol = spec
        if now - self._last.get(name, -1.0) < gap:
            return False
        self._last[name] = now
        try:
            snd = self._sound(name)
            snd.set_volume(vol * self.sfx_volume)
            ch = self._reserved.get(channel)
            if ch is None or (channel == "impact" and ch.get_busy()):
                ch = pygame.mixer.find_channel()                   # el canal propio está ocupado: uno libre del resto
            if ch is None:
                return False
            ch.play(snd)
        except pygame.error:
            return False
        return True

    def played(self, name, since=0.0):
        """¿Se pidió `name` desde el instante `since`? (también cuenta en modo silencioso)."""
        return any(n == name and t >= since for t, n in self.history)

    # --- música ---
    def play_music(self, track, fade_ms=800):
        """Pista `track` en bucle: el archivo de assets/audio/music si existe; si no, un colchón ambiental sintetizado."""
        if not self.enabled:
            self.music_track, self.music_source = track, None
            return False
        try:
            self.stop_music(fade_ms=0)
            self.music_track = track
            path = self._find(MUSIC_DIR, track, (".ogg", ".mp3", ".wav"))
            if path is not None:
                pygame.mixer.music.load(path)
                pygame.mixer.music.set_volume(self.music_volume)
                pygame.mixer.music.play(-1, fade_ms=fade_ms)
                self.music_source = "file"
                return True
            key = ("music", track)
            snd = self._cache.get(key)
            if snd is None:
                snd = self._cache[key] = self._to_sound(ambient_pad(root=55.0 if track != "menu" else 49.0, rate=self.rate))
            ch = self._reserved["music"]
            ch.set_volume(self.music_volume)
            ch.play(snd, loops=-1, fade_ms=fade_ms)
            self.music_source = "synth"
            return True
        except pygame.error as exc:
            log.warning("música desactivada: %s", exc)
            self.music_source = None
            return False

    def stop_music(self, fade_ms=600):
        self.music_track = self.music_source = None
        if not self.enabled:
            return
        try:
            if fade_ms:
                pygame.mixer.music.fadeout(fade_ms)
                self._reserved["music"].fadeout(fade_ms)
            else:
                pygame.mixer.music.stop()
                self._reserved["music"].stop()
        except pygame.error:
            pass


audio = AudioManager()
