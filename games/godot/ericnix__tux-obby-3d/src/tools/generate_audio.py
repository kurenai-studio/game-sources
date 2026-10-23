#!/usr/bin/env python3
"""Gera a trilha e os efeitos sonoros do Tux Obby 3D.

Tudo e sintetizado aqui, sem samples externos.
Execute: python3 tools/generate_audio.py
"""
import math
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def note(name: str) -> float:
    """Converte nomes como C4, F#3, Bb2 para frequencia."""
    names = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5,
             "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
    pitch = name[:-1]
    octave = int(name[-1])
    midi = 12 * (octave + 1) + names[pitch]
    return 440.0 * 2 ** ((midi - 69) / 12)


def adsr(n: int, attack=0.005, decay=0.1, sustain=0.6, release=0.2) -> np.ndarray:
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    r = max(1, int(release * SR))
    s = max(0, n - a - d - r)
    env = np.concatenate([
        np.linspace(0, 1, a),
        np.linspace(1, sustain, d),
        np.full(s, sustain),
        np.linspace(sustain, 0, r),
    ])
    if len(env) < n:
        env = np.pad(env, (0, n - len(env)))
    return env[:n]


def tone(freq, dur, kind="sine", attack=0.005, sustain=0.7, release=0.1, detune=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    if kind == "sine":
        w = np.sin(2 * np.pi * freq * t)
        if detune:
            w = 0.65 * w + 0.35 * np.sin(2 * np.pi * freq * (1 + detune) * t)
    elif kind == "triangle":
        w = 2 * np.abs(2 * ((t * freq) % 1) - 1) - 1
    elif kind == "square":
        w = np.sign(np.sin(2 * np.pi * freq * t)) * 0.6
        w += 0.4 * np.sin(2 * np.pi * freq * 2 * t)
    elif kind == "saw":
        w = 2 * ((t * freq) % 1) - 1
    else:
        raise ValueError(kind)
    return w * adsr(n, attack, dur * 0.25, sustain, release)


def sweep(f0, f1, dur, kind="sine", curve=2.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    freqs = f0 + (f1 - f0) * (t / dur) ** curve
    phase = 2 * np.pi * np.cumsum(freqs) / SR
    w = np.sin(phase) if kind == "sine" else np.sign(np.sin(phase))
    return w * np.exp(-t * (4.0 / dur))


def noise(dur, lowpass=0.2, decay=8.0):
    n = int(dur * SR)
    w = rng.normal(0, 1, n)
    # lowpass simples (media movel)
    k = max(1, int(lowpass * 100))
    w = np.convolve(w, np.ones(k) / k, mode="same")
    t = np.arange(n) / SR
    return w * np.exp(-t * decay)


def bell(freq, dur, gain=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    w = np.sin(2 * np.pi * freq * t) * np.exp(-t * 4.5)
    w += 0.4 * np.sin(2 * np.pi * freq * 2.01 * t) * np.exp(-t * 7)
    w += 0.2 * np.sin(2 * np.pi * freq * 3.02 * t) * np.exp(-t * 10)
    return w * gain


def mix_at(track, sound, at, gain=1.0):
    start = int(at * SR)
    end = min(len(track), start + len(sound))
    if start >= len(track):
        return
    track[start:end] += sound[: end - start] * gain


def stack(*sounds):
    """Soma sons de duracoes diferentes alinhados no inicio."""
    n = max(len(s) for s in sounds)
    out = np.zeros(n)
    for s in sounds:
        out[: len(s)] += s
    return out


def normalize(track, peak=0.85):
    m = np.max(np.abs(track))
    if m > 0:
        track *= peak / m
    return track


def save(name, data, stereo=True):
    data = normalize(np.asarray(data, dtype=np.float64))
    if stereo:
        left = data
        right = np.roll(data, int(0.004 * SR)) * 0.85
        out = np.stack([left, right], axis=1)
    else:
        out = data[:, None]
    pcm = np.clip(out * 32767, -32768, 32767).astype(np.int16)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(2 if stereo else 1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print(f"  {name:24s} {len(data) / SR:5.2f}s")


# ---------------------------------------------------------------- efeitos
print("Efeitos sonoros:")
save("jump.wav", stack(sweep(430, 780, 0.16) * 0.8, tone(note("A5"), 0.08, "triangle", release=0.05) * 0.2), stereo=False)
save("double_jump.wav", stack(sweep(620, 1240, 0.22), bell(note("E6"), 0.18, 0.25)), stereo=False)
save("bounce.wav", stack(sweep(160, 620, 0.34, curve=1.2), bell(note("A4"), 0.2, 0.35)), stereo=False)
save("land.wav", stack(noise(0.14, 0.35, 18) * 0.55, sweep(130, 55, 0.12) * 0.5), stereo=False)
save("death.wav", stack(
     sweep(520, 90, 0.55, "saw", 1.4) * 0.55,
     sweep(390, 60, 0.65, "square", 1.5) * 0.18,
     noise(0.35, 0.5, 9) * 0.22))
checkpoint = np.zeros(int(1.2 * SR))
for i, n in enumerate(["C5", "E5", "G5", "C6"]):
    mix_at(checkpoint, bell(note(n), 0.9, 0.6), i * 0.09)
save("checkpoint.wav", checkpoint)
save("fish.wav", stack(bell(note("B5"), 0.18, 0.7), np.concatenate([np.zeros(int(0.05 * SR)), bell(note("E6"), 0.25, 0.7)])), stereo=False)
save("click.wav", tone(note("A5"), 0.05, "triangle", release=0.03) * 0.6, stereo=False)

# vitoria: fanfarra
win = np.zeros(int(2.8 * SR))
for i, n in enumerate(["C5", "E5", "G5", "C6"]):
    mix_at(win, bell(note(n), 0.8, 0.5), i * 0.13)
for i, n in enumerate(["C4", "G4", "C5"]):
    mix_at(win, tone(note(n), 1.4, "triangle", sustain=0.4, release=0.5) * 0.35, 0.58 + i * 0.02)
mix_at(win, bell(note("E6"), 1.8, 0.5), 0.62)
mix_at(win, bell(note("G6"), 1.8, 0.35), 0.65)
mix_at(win, noise(0.8, 0.1, 3) * 0.15, 0.55)
save("win.wav", win)


# ---------------------------------------------------------------- musica
print("Trilha:")
BPM = 112
BEAT = 60 / BPM
BAR = 4 * BEAT
BARS = 16
length = BARS * BAR
track = np.zeros(int(length * SR) + SR)

chords = [
    ("Am", ["A3", "C4", "E4"]), ("F", ["F3", "A3", "C4"]),
    ("C", ["C4", "E4", "G4"]), ("G", ["G3", "B3", "D4"]),
    ("Am", ["A3", "C4", "E4"]), ("F", ["F3", "A3", "C4"]),
    ("C", ["C4", "E4", "G4"]), ("G", ["G3", "B3", "D4"]),
    ("Am", ["A3", "C4", "E4"]), ("F", ["F3", "A3", "C4"]),
    ("C", ["C4", "E4", "G4"]), ("G", ["G3", "B3", "D4"]),
    ("F", ["F3", "A3", "C4"]), ("G", ["G3", "B3", "D4"]),
    ("Am", ["A3", "C4", "E4"]), ("E", ["E3", "G#3", "B3"]),
]
bass_roots = {"Am": "A2", "F": "F2", "C": "C3", "G": "G2", "E": "E2"}

melody = [
    ("E5", 0.0, 0.5), ("A5", 0.5, 0.5), ("C6", 1.0, 0.75), ("B5", 1.75, 0.25),
    ("A5", 2.0, 1.0), ("G5", 3.0, 0.5), ("E5", 3.5, 0.5),
    ("F5", 4.0, 0.5), ("A5", 4.5, 0.5), ("C6", 5.0, 1.0), ("D6", 6.0, 0.5), ("C6", 6.5, 0.5),
    ("B5", 8.0, 0.5), ("G5", 8.5, 0.5), ("E5", 9.0, 1.0), ("G5", 10.0, 0.5), ("A5", 10.5, 0.5),
    ("B5", 12.0, 0.75), ("D6", 12.75, 0.25), ("G6", 13.0, 1.0), ("E6", 14.0, 0.5), ("D6", 14.5, 0.5),
    ("C6", 16.0, 1.0), ("A5", 17.0, 0.5), ("E5", 17.5, 0.5),
    ("A5", 18.0, 0.75), ("G5", 18.75, 0.25), ("E5", 19.0, 1.0),
    ("F5", 20.0, 0.5), ("A5", 20.5, 0.5), ("C6", 21.0, 1.0), ("A5", 22.0, 0.5), ("F5", 22.5, 0.5),
    ("G5", 24.0, 0.5), ("B5", 24.5, 0.5), ("D6", 25.0, 1.0), ("B5", 26.0, 0.5), ("G5", 26.5, 0.5),
    ("A5", 28.0, 0.75), ("E5", 28.75, 0.25), ("C6", 29.0, 1.0), ("B5", 30.0, 0.5), ("A5", 30.5, 0.5),
]

for bar in range(BARS):
    t0 = bar * BAR
    name, chord = chords[bar]

    # baixo em oitavas
    root = note(bass_roots[name])
    for beat in range(4):
        for half in range(2):
            at = t0 + beat * BEAT + half * BEAT / 2
            f = root if half == 0 else root * 2
            mix_at(track, tone(f, BEAT / 2 * 0.95, "triangle", sustain=0.5, release=0.05) * 0.5, at)

    # acordes curtos nos contratempos
    for beat in [0.5, 1.5, 2.5, 3.5]:
        for n in chord:
            mix_at(track, tone(note(n), 0.16, "square", sustain=0.25, release=0.08) * 0.07, t0 + beat * BEAT)

    # arpejo em semicolcheias, so a partir do compasso 2
    if bar >= 2:
        for i in range(16):
            n = chord[i % 3]
            octave = 1 if (i % 6) in (4, 5) else 0
            freq = note(n) * (2 ** octave)
            at = t0 + i * BEAT / 4
            mix_at(track, tone(freq, 0.12, "triangle", sustain=0.15, release=0.04) * 0.10, at)

    # bateria
    for beat in range(4):
        at = t0 + beat * BEAT
        mix_at(track, sweep(120, 42, 0.16, curve=0.5) * 0.8, at)
        if beat % 2 == 1:
            mix_at(track, noise(0.16, 0.12, 12) * 0.45, at)
        mix_at(track, noise(0.05, 0.02, 30) * 0.15, at + BEAT / 2)

# melodia
for n, start, dur in melody:
    mix_at(track, tone(note(n), dur * 0.95, "square", attack=0.008, sustain=0.5, release=0.1) * 0.16, start)
    mix_at(track, bell(note(n), dur * 0.9, 0.10), start)

# pequeno eco para dar espaco
echo = np.zeros_like(track)
delay = int(BEAT / 2 * SR)
echo[delay:] = track[:-delay] * 0.16
track = track + echo
save("music.wav", track[: int(length * SR)])
print("Pronto! Arquivos em", OUT)
