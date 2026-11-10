"""Makes HotDog Sports Day's sound effects into assets/audio/sfx/.

Most are real instruments from the Versilian Community Sample Library (CC0,
fetched into tools/recordings/vcsl/ by tools/fetch_recordings.py): a bounce
on the beat is a kalimba note with a woodblock under it, the count-in is the
woodblock, the finish bell a glockenspiel. The rest (a whoosh, a splash, the
sizzle of a hot streak, the crowd's applause) are made from filtered noise.
Everything is finished gently: no sharp start, the harsh top end rounded off,
a modest loudness, so the taps sit inside the music rather than on top of it.

Run:  python tools/gen_audio.py [name name ...]
Needs numpy and scipy. Writes 44.1 kHz 16-bit mono WAVs, and
assets/audio/sfx/CREDITS.md.
"""
import math
import re
import sys
import zlib
from functools import lru_cache
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio" / "sfx"
VCSL = Path(__file__).resolve().parent / "recordings" / "vcsl"
NOTE_PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

SOUNDS = {}


def sfx(name, about):
    def wrap(fn):
        SOUNDS[name] = (fn, about)
        return fn
    return wrap


def sec(s):
    return int(round(s * SR))


def rng(*parts):
    return np.random.default_rng(zlib.crc32(repr(parts).encode()))


def midi_hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def note(name):
    i = 1
    while i < len(name) and name[i] in "#b":
        i += 1
    return 12 * (int(name[i:]) + 1) + NOTE_PC[name[0]] + sum(1 if c == "#" else -1 for c in name[1:i])


# -- shaping ----------------------------------------------------------------------

def fade(x, a=0.003, r=0.05):
    x = x.copy()
    na, nr = min(len(x), sec(a)), min(len(x), sec(r))
    if na:
        x[:na] *= 0.5 - 0.5 * np.cos(np.pi * np.arange(na) / na)
    if nr:
        x[-nr:] *= 0.5 + 0.5 * np.cos(np.pi * np.arange(nr) / nr)
    return x


def lowpass(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def highpass(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bandpass(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def env(n, attack=0.002, tau=0.15):
    t = np.arange(n) / SR
    e = np.exp(-t / tau)
    na = max(1, sec(attack))
    e[:na] *= np.linspace(0, 1, na)
    return e


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, t, n=None):
    """x delayed by t seconds."""
    pad = np.zeros(sec(t))
    y = np.concatenate([pad, x])
    if n:
        y = np.concatenate([y, np.zeros(max(0, n - len(y)))])[:n]
    return y


def finish(x, peak=0.7, top=9000):
    """The house finish: round off the top, take out any DC, gentle level."""
    x = lowpass(x, top, 2)
    x = x - np.mean(x)
    x = fade(x, 0.002, 0.02)
    pk = np.max(np.abs(x)) or 1.0
    return x / pk * peak


# -- real instruments ---------------------------------------------------------------

REAL = {"kalimba": ("kalimba", 12), "marimba": ("marimba", 12), "glockenspiel": ("glockenspiel", 12),
        "harp": ("harp", 0), "hand_chimes": ("hand_chimes", 12), "piano": ("piano", 12)}


def _name_midi(name):
    m = re.search(r"(?<![A-Za-z])([A-G])(#|b)?(-?\d)(?!\d)", name.replace("_main", "").replace("MBira3_pluck_Main_", ""))
    if not m:
        return None
    pc = NOTE_PC[m.group(1)] + (1 if m.group(2) == "#" else -1 if m.group(2) == "b" else 0)
    return 12 * (int(m.group(3)) + 1) + pc


def load_wav(path):
    sr, y = wavfile.read(path)
    x = y.astype(float)
    if x.ndim > 1:
        x = x.mean(axis=1)
    x /= float(np.iinfo(y.dtype).max) if np.issubdtype(y.dtype, np.integer) else 1.0
    if sr != SR:
        x = signal.resample_poly(x, SR, sr)
    return x


def _onset(x):
    pk = np.max(np.abs(x)) or 1.0
    on = max(0, int(np.argmax(np.abs(x) > 0.02 * pk)) - sec(0.002))
    return x[on:] / pk


@lru_cache(maxsize=None)
def bank(inst):
    folder, offset = REAL[inst]
    out = []
    d = VCSL / folder
    for path in sorted(d.glob("*.wav")) if d.is_dir() else []:
        nominal = _name_midi(path.name)
        if nominal is None:
            continue
        out.append((nominal + offset, _onset(load_wav(path) - 0.0)))
    return out


def play(inst, midi, length=0.8, tau=0.35):
    """A recorded note, retuned to `midi`, shortened gently to `length`."""
    b = bank(inst)
    if not b:
        f = midi_hz(midi)
        n = sec(length)
        t = np.arange(n) / SR
        return np.sin(2 * np.pi * f * t) * env(n, 0.002, tau * 0.6)
    pitch, x = min(b, key=lambda p: abs(p[0] - midi))
    ratio = 2 ** ((midi - pitch) / 12.0)
    n_src = int(sec(length) * ratio) + 8
    src = x[:n_src]
    idx = np.arange(0, len(src) - 1, ratio)
    y = np.interp(idx, np.arange(len(src)), src)[:sec(length)]
    y = y * np.exp(-np.arange(len(y)) / SR / tau) ** 0.35
    return fade(y, 0.001, min(0.12, length * 0.3))


def woodblock(kind="mp", n=0):
    files = sorted((VCSL / "woodblock").glob("*%s*.wav" % kind)) if (VCSL / "woodblock").is_dir() else []
    if not files:
        r = rng("wb", kind, n)
        m = sec(0.12)
        t = np.arange(m) / SR
        return (np.sin(2 * np.pi * 1100 * t) + 0.3 * r.standard_normal(m)) * env(m, 0.0005, 0.02)
    x = _onset(load_wav(files[n % len(files)]))
    return fade(x[:sec(0.25)], 0.0005, 0.08)


def noise(seconds, *seed):
    return rng(*seed).standard_normal(sec(seconds))


# -- the sounds ----------------------------------------------------------------------

@sfx("bounce_perfect", "A bounce right on the beat: a kalimba C6 over a light woodblock tick (VCSL, CC0)")
def _():
    return [finish(mix(play("kalimba", note("C6"), 0.5, 0.25) * 0.9, woodblock("pp", k) * 0.35 + 0.0), 0.62)
            for k in range(3)]


@sfx("bounce_good", "A good bounce: a kalimba G5, softer (VCSL, CC0)")
def _():
    return [finish(mix(play("kalimba", note("G5"), 0.45, 0.22) * 0.8, woodblock("pp", k) * 0.3), 0.5)
            for k in range(3)]


@sfx("bounce_ok", "An ok bounce: just the woodblock, quietly (VCSL, CC0)")
def _():
    return [finish(woodblock("pp", k), 0.32) for k in range(3)]


@sfx("bounce_miss", "A missed landing: a soft low marimba thud (VCSL, CC0)")
def _():
    return [finish(lowpass(play("marimba", note("F2"), 0.35, 0.12), 900), 0.4)]


@sfx("bounce_fumble", "A tap off the beat: a kalimba note that wobbles down (VCSL, CC0)")
def _():
    x = play("kalimba", note("E5"), 0.5, 0.2)
    t = np.arange(len(x)) / SR
    bend = 2 ** (-(t * 6.0 + 0.4 * np.sin(t * 40)) / 12.0)
    idx = np.cumsum(bend)
    idx = idx[idx < len(x) - 1]
    y = np.interp(idx, np.arange(len(x)), x)
    return [finish(y, 0.45)]


@sfx("tick", "The count-in: a woodblock (VCSL, CC0)")
def _():
    return [finish(woodblock("f", 0), 0.55)]


@sfx("gun", "The start: two woodblocks clapped together, with a puff (VCSL, CC0)")
def _():
    x = mix(woodblock("ff", 0) * 1.0, at(woodblock("f", 1) * 0.6, 0.012),
            lowpass(noise(0.25, "gun") * env(sec(0.25), 0.001, 0.05), 2500) * 0.5)
    return [finish(x, 0.75)]


@sfx("click", "A button: a quiet woodblock tick (VCSL, CC0)")
def _():
    return [finish(woodblock("pp", k), 0.28) for k in range(2)]


@sfx("boing_big", "A big bounce: a cartoon spring, soft (synthesised)")
def _():
    n = sec(0.42)
    t = np.arange(n) / SR
    f = 180 + 260 * (1 - np.exp(-t * 14)) + 22 * np.sin(2 * np.pi * 18 * t) * np.exp(-t * 4)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = (np.sin(ph) + 0.25 * np.sin(2 * ph)) * env(n, 0.004, 0.16)
    return [finish(x, 0.45, 5000)]


@sfx("squash", "Squashing down to jump: a soft squish (synthesised)")
def _():
    n = sec(0.22)
    x = bandpass(noise(0.22, "squash"), 300, 1800) * env(n, 0.01, 0.07)
    t = np.arange(n) / SR
    x += np.sin(2 * np.pi * (120 - 60 * t) * t) * env(n, 0.005, 0.08) * 0.6
    return [finish(x, 0.4, 4000)]


@sfx("whoosh", "Taking off: air rushing past (synthesised)")
def _():
    n = sec(0.5)
    t = np.arange(n) / SR
    x = noise(0.5, "whoosh")
    lo = 400 + 1800 * np.sin(np.pi * t / 0.5)
    y = np.zeros(n)
    for i in range(0, n, 512):
        seg = x[i:i + 512 + 64]
        b, a = signal.butter(2, [max(80, lo[i] * 0.6) / (SR / 2), min(SR / 2 - 100, lo[i] * 1.4) / (SR / 2)], "band")
        y[i:i + 512] = signal.lfilter(b, a, seg)[:len(y[i:i + 512])]
    y *= np.sin(np.pi * t / 0.5) ** 1.5
    return [finish(y, 0.4, 6000)]


@sfx("sand", "Landing in the sand pit: a soft gritty thump (synthesised)")
def _():
    n = sec(0.55)
    r = rng("sand")
    grains = np.zeros(n)
    for k in range(260):
        i = int(abs(r.normal(0, 0.12)) * SR)
        if i < n:
            grains[i] += r.uniform(0.2, 1.0) * (1 if r.random() < 0.5 else -1)
    x = bandpass(grains, 600, 5000) * 0.8
    thump = lowpass(noise(0.3, "thump"), 220) * env(sec(0.3), 0.002, 0.06) * 3.0
    return [finish(mix(x, thump), 0.6)]


@sfx("clonk", "Knocking a hurdle or the bar: a hollow wooden clonk (VCSL marimba and woodblock, CC0)")
def _():
    x = mix(play("marimba", note("C3"), 0.5, 0.15) * 0.7, woodblock("f", 2) * 0.7)
    return [finish(x, 0.6)]


@sfx("flump", "Landing on the high-jump mat (synthesised)")
def _():
    n = sec(0.4)
    x = lowpass(noise(0.4, "flump"), 400) * env(n, 0.003, 0.09) * 2.0
    return [finish(x, 0.6, 3000)]


@sfx("swish", "A trick in the air: a swish and a glint (synthesised, glockenspiel VCSL CC0)")
def _():
    n = sec(0.3)
    t = np.arange(n) / SR
    x = highpass(noise(0.3, "swish"), 1500) * np.sin(np.pi * t / 0.3) ** 2 * 0.5
    g = play("glockenspiel", note("E6"), 0.3, 0.2) * 0.3
    return [finish(mix(x, at(g, 0.05)), 0.4)]


@sfx("splash", "Going into the water (synthesised)")
def _():
    n = sec(1.1)
    r = rng("splash")
    x = noise(1.1, "splash")
    body = bandpass(x, 300, 4000) * env(n, 0.004, 0.25)
    drops = np.zeros(n)
    for k in range(40):
        i = sec(0.15 + abs(r.normal(0, 0.35)))
        if i < n - sec(0.05):
            f = r.uniform(900, 2400)
            m = sec(0.04)
            t = np.arange(m) / SR
            drops[i:i + m] += np.sin(2 * np.pi * f * (1 + t * 8) * t) * env(m, 0.001, 0.012) * r.uniform(0.1, 0.4)
    return [finish(mix(body, drops), 0.6, 7000)]


@sfx("sizzle", "On a hot streak: a sausage sizzling in the pan (synthesised)")
def _():
    n = sec(0.9)
    r = rng("sizzle")
    x = np.zeros(n)
    for k in range(900):
        i = r.integers(0, n - 50)
        x[i] += r.uniform(-1, 1)
    x = highpass(x, 2500)
    t = np.arange(n) / SR
    x *= np.minimum(1, t / 0.05) * np.exp(-t / 0.5)
    return [finish(x, 0.35, 10000)]


@sfx("cheer", "The crowd claps (synthesised applause)")
def _():
    n = sec(1.6)
    r = rng("cheer")
    x = np.zeros(n)
    for k in range(700):
        i = int(r.uniform(0, 1.3) * SR)
        m = sec(0.012)
        if i + m < n:
            x[i:i + m] += bandpass(r.standard_normal(m), 800, 4000) * r.uniform(0.2, 1.0)
    t = np.arange(n) / SR
    x *= np.minimum(1, t / 0.1) * np.exp(-np.maximum(0, t - 0.6) / 0.4)
    return [finish(x, 0.4)]


@sfx("finish", "Crossing the line first: a glockenspiel arpeggio (VCSL, CC0)")
def _():
    notes = ["C5", "E5", "G5", "C6"]
    x = mix(*[at(play("glockenspiel", note(nm), 0.9, 0.5) * 0.7, k * 0.09) for k, nm in enumerate(notes)])
    return [finish(x, 0.55)]


@sfx("fanfare", "A record or a medal: hand chimes and glockenspiel (VCSL, CC0)")
def _():
    seq = [("C5", 0.0), ("E5", 0.14), ("G5", 0.28), ("C6", 0.42), ("G5", 0.62), ("C6", 0.76)]
    x = mix(*[at(mix(play("hand_chimes", note(nm), 1.4, 0.8) * 0.6, play("glockenspiel", note(nm), 1.0, 0.4) * 0.3), t)
              for nm, t in seq])
    return [finish(x, 0.6)]


@sfx("tag", "A relay changeover: two quick kalimba notes, up (VCSL, CC0)")
def _():
    x = mix(play("kalimba", note("G5"), 0.3, 0.15) * 0.8, at(play("kalimba", note("D6"), 0.4, 0.2) * 0.8, 0.07),
            woodblock("f", 1) * 0.4)
    return [finish(x, 0.55)]


@sfx("wobble", "A false start or a foul: a wobbly kalimba (VCSL, CC0)")
def _():
    x = play("kalimba", note("A4"), 0.7, 0.3)
    t = np.arange(len(x)) / SR
    bend = 2 ** ((-t * 5.0 + 0.6 * np.sin(t * 30)) / 12.0)
    idx = np.cumsum(bend)
    idx = idx[idx < len(x) - 1]
    return [finish(np.interp(idx, np.arange(len(x)), x), 0.5)]


def write(name, takes):
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob(name + "_*.wav"):
        old.unlink()
    for i, x in enumerate(takes):
        y = np.clip(x, -1, 1)
        assert np.isfinite(y).all(), name
        wavfile.write(OUT / ("%s_%d.wav" % (name, i)), SR, (y * 32767).astype(np.int16))


def main(names):
    if not (VCSL / "kalimba").is_dir():
        print("note: no recordings in tools/recordings/vcsl (python tools/fetch_recordings.py); synthesising stand-ins")
    lines = ["# Sound effects", "", "Made by tools/gen_audio.py. Real instruments are from the Versilian Community "
             "Sample Library (CC0, https://github.com/sgossner/VCSL).", ""]
    for name, (fn, about) in SOUNDS.items():
        if names and name not in names:
            lines.append("- `%s`: %s" % (name, about))
            continue
        takes = fn()
        write(name, takes)
        lines.append("- `%s`: %s" % (name, about))
        print("%-16s %d take(s), %.2fs" % (name, len(takes), max(len(t) for t in takes) / SR))
    (OUT / "CREDITS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main(sys.argv[1:])
