"""Audio manager.

Looks for files in assets/sounds/<name>.(wav|ogg|mp3) and assets/music/<name>.(ogg|mp3|wav).
When a file is missing it falls back to a tiny built-in synthesiser, so the game always has
sound; and if no audio device exists at all, every call silently does nothing.

Sound names: jump land crystal switch door death victory menu_move menu_select
Music names: menu game
"""
import array
import math
import os
import random
import pygame
from . import settings as S

RATE = 22050
EXTS = (".ogg", ".wav", ".mp3")


def _wave(kind, phase):
    if kind == "square":
        return 1.0 if math.sin(phase) >= 0 else -1.0
    if kind == "tri":
        return 2.0 / math.pi * math.asin(math.sin(phase))
    if kind == "noise":
        return random.uniform(-1, 1)
    return math.sin(phase)


def _tone(segments, vol=0.4):
    """segments: list of (f0, f1, seconds, wave). Returns 16-bit mono samples."""
    out = array.array("h")
    for f0, f1, dur, kind in segments:
        n = int(RATE * dur)
        phase = 0.0
        for i in range(n):
            f = f0 + (f1 - f0) * i / max(1, n - 1)
            phase += 2 * math.pi * f / RATE
            env = min(1.0, i / 120.0) * (1.0 - i / float(n)) ** 1.5
            out.append(int(_wave(kind, phase) * env * vol * 32767))
    return out


SYNTH = {
    "jump": [(260, 560, 0.14, "square")],
    "land": [(120, 50, 0.08, "noise")],
    "crystal": [(880, 880, 0.06, "sine"), (1320, 1320, 0.14, "sine")],
    "switch": [(300, 300, 0.05, "square"), (600, 600, 0.08, "square")],
    "door": [(200, 90, 0.35, "tri")],
    "death": [(500, 70, 0.55, "square")],
    "victory": [(523, 523, 0.12, "square"), (659, 659, 0.12, "square"), (784, 784, 0.12, "square"), (1047, 1047, 0.35, "square")],
    "menu_move": [(440, 440, 0.04, "sine")],
    "menu_select": [(520, 780, 0.12, "square")],
}


def _music_loop(kind):
    """A small chiptune loop (arpeggio + bass), ~8 s."""
    bpm = 120 if kind == "game" else 96
    step = 60.0 / bpm / 2
    chords = [(220.0, 261.6, 329.6), (174.6, 220.0, 261.6), (196.0, 246.9, 293.7), (164.8, 207.7, 246.9)]
    out = array.array("h")
    for chord in chords:
        for k in range(8):
            f = chord[[0, 1, 2, 1][k % 4]] * (2 if k >= 4 and kind == "game" else 1)
            n = int(RATE * step)
            for i in range(n):
                t = i / RATE
                env = (1.0 - i / float(n)) ** 1.2
                lead = 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0
                bass = 2.0 / math.pi * math.asin(math.sin(2 * math.pi * chord[0] / 2 * t))
                out.append(int((lead * env * 0.10 + bass * 0.22) * 32767))
    return out


class Audio:
    def __init__(self, settings):
        self.settings = settings
        self.enabled = False
        self.sounds = {}
        self.music_sound = {}
        self.music_channel = None
        self.current_music = None
        self.channels = 1
        try:
            pygame.mixer.init(frequency=RATE, size=-16, channels=1, buffer=512)
            info = pygame.mixer.get_init()
            if info:
                self.channels = info[2]
                self.enabled = True
        except pygame.error:
            self.enabled = False

    # --------------------------------------------------------------- helpers
    def _find(self, folder, name):
        for ext in EXTS:
            p = os.path.join(S.ASSETS_DIR, folder, name + ext)
            if os.path.isfile(p):
                return p
        return None

    def _from_samples(self, samples):
        if self.channels == 2:
            stereo = array.array("h")
            for s in samples:
                stereo.append(s)
                stereo.append(s)
            samples = stereo
        return pygame.mixer.Sound(buffer=samples.tobytes())

    def _get_sound(self, name):
        if name in self.sounds:
            return self.sounds[name]
        snd = None
        try:
            path = self._find("sounds", name)
            if path:
                snd = pygame.mixer.Sound(path)
            elif name in SYNTH:
                snd = self._from_samples(_tone(SYNTH[name]))
        except (pygame.error, OSError):
            snd = None
        self.sounds[name] = snd
        return snd

    # --------------------------------------------------------------- public API
    def play(self, name, volume=1.0):
        if not self.enabled:
            return
        snd = self._get_sound(name)
        if snd:
            snd.set_volume(max(0.0, min(1.0, self.settings["sfx_volume"] * volume)))
            snd.play()

    def play_music(self, name):
        if not self.enabled or name == self.current_music:
            return
        self.stop_music()
        self.current_music = name
        try:
            path = self._find("music", name)
            if path:
                pygame.mixer.music.load(path)
                pygame.mixer.music.set_volume(self.settings["music_volume"])
                pygame.mixer.music.play(-1)
                return
            if name not in self.music_sound:
                self.music_sound[name] = self._from_samples(_music_loop(name))
            self.music_channel = self.music_sound[name].play(loops=-1)
            self.apply_volumes()
        except (pygame.error, OSError):
            pass

    def stop_music(self):
        if not self.enabled:
            return
        try:
            pygame.mixer.music.stop()
            for s in self.music_sound.values():
                s.stop()
        except pygame.error:
            pass
        self.current_music = None

    def apply_volumes(self):
        """Call after the user changes the volume sliders."""
        if not self.enabled:
            return
        v = max(0.0, min(1.0, self.settings["music_volume"]))
        try:
            pygame.mixer.music.set_volume(v)
            for s in self.music_sound.values():
                s.set_volume(v)
        except pygame.error:
            pass
