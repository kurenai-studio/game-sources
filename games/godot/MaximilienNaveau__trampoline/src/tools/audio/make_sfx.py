"""Build the candidate sound effects into assets/audio/sfx/ (mono 44.1 kHz wav).

Physical sounds (the trampoline "boing", wooden tiles) are synthesised from
scratch with numpy; musical cues are played by the same guitar/bass/clarinet
band as the music (see arrange.py). Run from `nix develop .#audio`:

    python3 tools/audio/make_sfx.py             # -> assets/audio/sfx/
    python3 tools/audio/make_sfx.py --out DIR   # elsewhere (`nix build .#audio`)
"""

import argparse
import os

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

from arrange import Note, build_stinger

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")
SR = 44100
rng = np.random.default_rng(7)


def _time(seconds):
    return np.arange(int(seconds * SR)) / SR


def _tone(freq, t):
    """A sine whose frequency may vary over time (freq is an array or a number)."""
    return np.sin(2 * np.pi * np.cumsum(np.broadcast_to(freq, t.shape)) / SR)


def _noise(t, low, high):
    sos = butter(2, [low, high], btype="band", fs=SR, output="sos")
    return sosfilt(sos, rng.standard_normal(t.size))


def _modes(t, partials):
    """Struck wood: damped sines, partials = [(Hz, decay seconds, gain)]."""
    return sum(g * np.exp(-t / d) * _tone(f, t) for f, d, g in partials)


def _save(name, signal, peak_db=-1.0):
    fade = min(len(signal), int(0.01 * SR))
    signal = signal.copy()
    signal[-fade:] *= np.linspace(1, 0, fade)  # no click at the very end
    signal *= 10 ** (peak_db / 20) / np.abs(signal).max()
    wavfile.write(os.path.join(out, name), SR, (signal * 32767).astype(np.int16))
    print(name)


def boing(base=260.0, seconds=0.6):
    """The trampoline: a quick upward sweep, then a spring wobbling to rest."""
    t = _time(seconds)
    sweep = 1 - np.exp(-t / 0.035)  # 0 -> 1 in the first ~0.1 s
    wobble = 0.3 * np.sin(2 * np.pi * 9 * t) * np.exp(-t / 0.18)
    freq = base * (0.45 + 0.55 * sweep) * (1 + wobble)
    body = (_tone(freq, t) + 0.3 * _tone(2 * freq, t)) * np.exp(-t / (seconds / 4))
    thump = np.sin(2 * np.pi * 70 * t) * np.exp(-t / 0.04)  # the mat being hit
    attack = np.minimum(1, t / 0.004)
    return attack * (body + 0.8 * thump)


def tile_pick():
    t = _time(0.08)
    click = _modes(t, [(1900, 0.012, 1.0), (2750, 0.008, 0.6), (4100, 0.004, 0.3)])
    return click + 0.4 * _noise(t, 2000, 8000) * np.exp(-t / 0.003)


def tile_drop():
    t = _time(0.18)
    knock = _modes(t, [(520, 0.045, 1.0), (1180, 0.025, 0.6), (2100, 0.012, 0.35)])
    return knock + 0.5 * _noise(t, 300, 4000) * np.exp(-t / 0.005)


def tile_flip():
    t = _time(0.16)
    sos = butter(2, [1500, 5000], btype="band", fs=SR, output="sos")
    swish = sosfilt(sos, rng.standard_normal(t.size)) * np.sin(np.pi * np.minimum(t / 0.08, 1)) ** 2
    landing = np.zeros_like(t)
    knock = _modes(_time(0.08), [(900, 0.02, 1.0), (1700, 0.012, 0.5)])
    at = int(0.08 * SR)
    landing[at:at + knock.size] = knock[: t.size - at]
    return 0.5 * swish + landing


def _strum(beat, pitches, velocity=80, length=1.0, up=False):
    order = list(reversed(pitches)) if up else pitches
    return [Note(beat, length, p, velocity, 1, i * 14) for i, p in enumerate(order)]


def stingers():
    """(file name, notes, tempo): short cues played by the band."""
    g, b, c = 0, 2, 3  # lead guitar, bass, clarinet channels
    return [
        # Word accepted: a bright arpeggio up a C major chord.
        ("word_valid.wav", [Note(i * 0.25, 1.5 - i * 0.25, p, 90, g) for i, p in enumerate((72, 76, 79, 84))]
         + [Note(0, 1.5, 48, 85, b)], 140),
        # Word refused: the bass slides down a semitone, guitar shrugs.
        ("word_invalid.wav", [Note(0, 0.45, 45, 100, b), Note(0.5, 1.2, 44, 100, b)]
         + _strum(0.5, [56, 59, 62, 65], 55, 0.3), 120),
        # A row reaches 9 cells: one confident strum and its bounce.
        ("line_complete.wav", _strum(0, [55, 60, 64, 69, 74], 95, 1.5) + _strum(0.75, [64, 69, 74], 60, 0.8, up=True)
         + [Note(0, 2, 36, 95, b)], 132),
        # 9-letter word in one move: clarinet run up to a C6/9 chord.
        ("word_bonus.wav", [Note(i * 0.25, 0.25, p, 85, c) for i, p in enumerate((67, 69, 71, 72, 74, 76, 79))]
         + [Note(1.75, 1.75, 84, 95, c)] + _strum(1.75, [55, 60, 64, 69, 74], 95, 1.75)
         + [Note(1.75, 2, 36, 100, b)], 140),
        # End of the game: guitar run down over G7, walking bass, landing on C6.
        ("game_end.wav", [Note(i * 0.5, 0.5, p, 88, g) for i, p in enumerate((77, 76, 74, 71, 67, 65))]
         + [Note(3, 3, 72, 92, g)]
         + _strum(0, [55, 59, 62, 65], 55, 0.3) + _strum(1, [55, 59, 62, 65], 70, 0.3)
         + _strum(2, [55, 59, 62, 65], 55, 0.3) + _strum(3, [55, 60, 64, 69], 90, 3)
         + [Note(i, 1, p, 92, b) for i, p in enumerate((43, 45, 47))] + [Note(3, 3, 36, 100, b)], 126),
    ]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=OUT, help="output folder")
    out = parser.parse_args().out
    os.makedirs(out, exist_ok=True)
    _save("bounce.wav", boing())
    _save("bounce_small.wav", boing(base=390.0, seconds=0.35), peak_db=-4.0)
    _save("tile_pick.wav", tile_pick(), peak_db=-6.0)
    _save("tile_drop.wav", tile_drop(), peak_db=-4.0)
    _save("tile_flip.wav", tile_flip(), peak_db=-5.0)
    for name, notes, tempo in stingers():
        build_stinger(notes, tempo, os.path.join(out, name))
        print(name)
