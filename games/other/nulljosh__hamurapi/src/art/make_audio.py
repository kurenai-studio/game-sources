"""Writes the music loop and every sound effect. Run: uv run --with numpy art/make_audio.py (needs ffmpeg)
No samples, no recordings: every sound is arithmetic. Output goes to app/App/Audio and web/play/audio as mp3.

The music is a slow lo-fi loop in A minor at 84 beats a minute: kalimba over jazzy chords, a soft pad, a round bass,
a quiet beat, and an ocarina that takes the tune in the second half. The effects are tuned to the same key."""
import os, subprocess, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SR = 44100
NOTE = {n: 440 * 2 ** ((i - 57) / 12) for i, n in enumerate(f"{k}{o}" for o in range(8) for k in ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"))}
rng = np.random.default_rng(1968)

def t(secs): return np.arange(int(secs * SR)) / SR
def fade(x, a=0.005, r=0.03):
    n = len(x); env = np.ones(n)
    ia, ir = min(n, max(1, int(a * SR))), min(n, max(1, int(r * SR)))
    env[:ia] = np.linspace(0, 1, ia); env[-ir:] *= np.linspace(1, 0, ir)
    return x * env
def lowpass(x, hz, order=4):
    """A gentle roll-off done in the frequency domain, so there is no filter to tune."""
    spec = np.fft.rfft(x, axis=0); f = np.fft.rfftfreq(len(x), 1 / SR)
    gain = 1 / np.sqrt(1 + (f / hz) ** (2 * order))
    return np.fft.irfft(spec * (gain[:, None] if x.ndim == 2 else gain), n=len(x), axis=0)
def highpass(x, hz, order=2): return x - lowpass(x, hz, order)

# ---- instruments
def kalimba(hz, secs, vel=1.0):
    x = t(secs)
    body = np.sin(2 * np.pi * hz * x + 1.6 * np.exp(-x * 9) * np.sin(2 * np.pi * hz * 2 * x)) * np.exp(-x * 3.2)  # a little FM in the attack
    tine = 0.20 * np.sin(2 * np.pi * hz * 5.4 * x) * np.exp(-x * 30)  # the bright tick of the tine
    return fade(body + tine, 0.002, 0.08) * vel
def pad(freqs, secs, spread):
    x = t(secs); out = 0
    for i, hz in enumerate(freqs):  # each note is three slightly detuned sines, so the chord shimmers
        out = out + sum(np.sin(2 * np.pi * hz * d * x + i + spread) for d in (1 - 0.003 - 0.001 * spread, 1.0, 1.004 + 0.001 * spread)) / 3
    return fade(out / len(freqs) * (0.9 + 0.1 * np.sin(2 * np.pi * 0.2 * x)), 0.7, 0.9)
def bass(hz, secs):
    x = t(secs); return fade(np.tanh(1.6 * (np.sin(2 * np.pi * hz * x) + 0.25 * np.sin(4 * np.pi * hz * x))) * np.exp(-x * 1.1), 0.01, 0.08)
def ocarina(hz, secs):
    x = t(secs); vib = hz * (1 + 0.005 * np.sin(2 * np.pi * 5.2 * x) * np.minimum(1, x / 0.3))
    ph = 2 * np.pi * np.cumsum(vib) / SR
    dry = fade(np.sin(ph) + 0.12 * np.sin(2 * ph), 0.05, 0.12)
    late = np.interp(x - 0.012 - 0.004 * np.sin(2 * np.pi * 1.8 * x), x, dry, left=0)  # a slow chorus: a second player a hair behind
    return 0.6 * dry + 0.4 * late
def kick(secs=0.28):
    x = t(secs); return fade(np.sin(2 * np.pi * (48 * x + 70 / 22 * (1 - np.exp(-22 * x)))) * np.exp(-x * 11), 0.002, 0.05)
def shaker(secs=0.07):
    n = np.diff(rng.uniform(-1, 1, int(secs * SR)), prepend=0)  # differencing leaves the hiss
    return fade(n * np.exp(-t(secs) * 55), 0.004, 0.02)
def rim(secs=0.05):
    x = t(secs); return fade((np.sin(2 * np.pi * 1700 * x) + 0.5 * np.sin(2 * np.pi * 2650 * x)) * np.exp(-x * 90), 0.001, 0.01)

# ---- mixing
def place(total, parts):
    """Lays (start seconds, sound, volume, pan -1..1) on a stereo strip."""
    out = np.zeros((int(total * SR) + 1, 2))
    for at, snd, vol, pan in parts:
        i = int(at * SR); n = min(len(snd), len(out) - i)
        if i >= 0 and n > 0:
            out[i:i + n, 0] += snd[:n] * vol * np.sqrt((1 - pan) / 2) * 1.414
            out[i:i + n, 1] += snd[:n] * vol * np.sqrt((1 + pan) / 2) * 1.414
    return out
def comb(x, delay, gain):
    y = x.copy()
    for k in range(delay, len(x), delay): y[k:k + delay] += gain * y[k - delay:k][: len(y[k:k + delay])]
    return y
def room(x):
    """A small room: four feedback delays of unrelated lengths per ear, with the mud below 200 Hz taken out."""
    out = np.zeros_like(x)
    for ch in (0, 1):
        out[:, ch] = sum(comb(x[:, ch], int(SR * d * (1 + 0.035 * ch)), 0.72) for d in (0.0297, 0.0371, 0.0411, 0.0437)) / 4
    return highpass(out, 200)

def music():
    beat = 60 / 84; e = beat / 2; bar = 4 * beat; swing = 0.12 * beat; length = 16 * bar
    A = [("A2", ["A3", "C4", "E4", "G4"]), ("F2", ["A3", "C4", "E4", "F4"]), ("C3", ["G3", "B3", "C4", "E4"]), ("G2", ["G3", "A3", "B3", "D4"])]
    B = [("F2", ["A3", "C4", "E4", "F4"]), ("G2", ["G3", "A3", "B3", "D4"]), ("E2", ["G3", "B3", "D4", "E4"]), ("A2", ["G3", "A3", "C4", "E4"]),
         ("F2", ["A3", "C4", "E4", "F4"]), ("G2", ["G3", "A3", "B3", "D4"]), ("C3", ["G3", "B3", "C4", "E4"]), ("G2", ["G3", "A3", "B3", "D4"])]
    bars = A + A + B  # eight bars to settle in, eight that lift, then round again
    # The tune for the second half, written against the chords under it: (note, beats), two bars to a line.
    tune = [("A4", 1), ("C5", 1), ("E5", 1.5), ("D5", .5), ("D5", 1), ("B4", 1), ("G4", 2),
            ("G4", 1), ("B4", 1), ("E5", 2), ("E5", 1), ("D5", .5), ("C5", .5), ("A4", 2),
            ("A4", 1), ("C5", 1), ("F5", 1.5), ("E5", .5), ("D5", 2), ("G5", 2),
            ("E5", 1.5), ("D5", .5), ("C5", 1), ("G4", 1), ("B4", 1), ("D5", 1), ("E5", 2)]
    # A small answer on the kalimba in bars 5 to 8, so the first half has a voice of its own.
    answer = [(4, 2.5, "E5"), (4, 3.5, "G5"), (5, 2.5, "E5"), (5, 3, "C5"), (6, 2.5, "G5"), (6, 3.5, "E5"), (7, 2, "D5"), (7, 3, "B4")]
    drums, low, mid, sends, kicks = [], [], [], [], []
    for i, (root, notes) in enumerate(bars):
        at = i * bar; second = i >= 8
        for side in (-1, 1):  # the pad is two takes, one a shade flat and left, one a shade sharp and right
            sends.append((at, pad([NOTE[n] for n in notes], bar + 0.6, side * 0.5), 0.11 if second else 0.15, side * 0.7))
        low.append((at, bass(NOTE[root], beat * 2.5), 0.50, 0)); low.append((at + beat * 2.5, bass(NOTE[root] * (1.5 if i % 4 == 3 else 1), beat * 1.2), 0.30, 0))
        up = [NOTE[n] * 2 for n in notes]
        for k, step in enumerate((0, 2, 3, 2, 1, 2, 3, 1) if i % 2 == 0 else (0, 1, 2, 3, 2, 1, 3, 2)):  # the kalimba walks the chord
            if (i < 2 and k % 2) or (second and k in (3, 7)): continue  # sparse at the top of the loop, and it leaves room for the tune
            late = (swing if k % 2 else 0) + rng.uniform(-0.007, 0.007)
            sends.append((at + k * e + late, kalimba(up[step], 1.4, 0.7 + 0.3 * rng.random()), 0.19 if not second else 0.15, -0.35 if k % 2 else 0.35))
        if i >= 2:
            for k in (0, 2):
                kicks.append(at + k * beat); drums.append((at + k * beat, kick(), 0.55, 0))
            for k in (1, 3): drums.append((at + k * beat + rng.uniform(-0.004, 0.004), rim(), 0.10, 0.25))
            for k in range(8):
                if k % 2: drums.append((at + k * e + swing, shaker(), 0.07 + 0.05 * (k % 4 == 3), -0.3))
    for bar_i, at_beat, name in answer:
        sends.append((bar_i * bar + at_beat * beat + swing, kalimba(NOTE[name], 1.6, 0.9), 0.20, 0.5))
    at = 8 * bar
    for name, beats in tune:
        sends.append((at, ocarina(NOTE[name], beats * beat * 0.95), 0.15, 0.15)); at += beats * beat

    twice = lambda parts: parts + [(a + length, s, v, p) for a, s, v, p in parts]  # render two rounds and keep the second,
    n = int(length * SR)                                                           # so the room is already ringing at the seam
    lows, mids, hits = place(2 * length, twice(low)), place(2 * length, twice(sends)), place(2 * length, twice(drums))
    duck = np.ones(len(lows))  # the bass and the chords step back a little each time the kick lands
    for k in kicks + [k + length for k in kicks]:
        i = int(k * SR); x = np.arange(min(int(0.5 * SR), len(duck) - i)) / SR
        duck[i:i + len(x)] *= 1 - 0.38 * np.exp(-x / 0.13) * (1 - np.exp(-x / 0.012))
    full = hits + (lows + mids) * duck[:, None] + room(mids) * 0.5
    out = full[n:2 * n]
    # tape: a slow, slight waver in pitch (27 turns a loop, so it meets itself at the seam) and a soft top end
    x = np.arange(n) / SR
    wow = x + 0.0007 * np.sin(2 * np.pi * 27 / length * x)
    out = np.stack([np.interp(wow, x, out[:, ch], period=length) for ch in (0, 1)], axis=1)
    out = lowpass(out, 9000)
    crackle = np.zeros(n)  # a few quiet ticks of dust, and a breath of hiss
    for i in rng.integers(0, n - 200, int(length * 2.5)): crackle[i:i + 40] += rng.uniform(0.3, 1) * np.exp(-np.arange(40) / 6) * rng.choice([-1, 1])
    dust = (crackle * 0.012 + rng.normal(0, 0.0012, n))[:, None]
    out = out / np.sqrt(np.mean(out ** 2)) * 10 ** (-17 / 20)  # about -17 dB on average: under the effects, easy on the ear
    return np.tanh(out * 1.15) / 1.15 + dust

# ---- effects, all in A minor so they sit on the music
def seq(notes, gap, secs=0.5, vol=0.5):
    out = np.zeros(int((gap * len(notes) + secs) * SR) + 1)
    for i, n in enumerate(notes):
        k = kalimba(NOTE[n], secs); j = int(i * gap * SR); out[j:j + len(k)] += k * vol
    return out
def layer(total, parts):
    out = np.zeros(int(total * SR) + 1)
    for at, snd, vol in parts:
        i = int(at * SR); n = min(len(snd), len(out) - i); out[i:i + n] += snd[:n] * vol
    return out

def sounds():
    squeak = lambda hz: fade(np.sin(2 * np.pi * (hz + 9000 * t(0.05)) * t(0.05)) * 0.5, 0.002, 0.01)
    scurry = layer(1.1, [(i * 0.07 + rng.uniform(0, 0.015), rim(0.04), 0.3) for i in range(12)] + [(0.15 + i * 0.3, squeak(2300 + 250 * i), 0.3) for i in range(3)])
    x = t(2.4)  # a low A against the note a half step up: unease, in key
    plague = fade((np.sin(2 * np.pi * 55 * x) + np.sin(2 * np.pi * 58.27 * x) + 0.25 * rng.uniform(-1, 1, len(x)) * np.exp(-x)) * np.sin(np.pi * x / 2.4) ** 2 * 0.5, 0.2, 0.5)
    x = t(1.8)
    gong = fade(sum(np.sin(2 * np.pi * f * x) * a * np.exp(-x * d) for f, a, d in ((110, 1, 1.6), (164.8, 0.5, 2.2), (247, 0.35, 3), (330, 0.2, 4))) * 0.4, 0.004, 0.3)
    thud = layer(0.5, [(0, kick(0.4), 1), (0, rim(0.03), 0.15)])
    return {
        "tap": layer(0.12, [(0, rim(0.03), 0.35), (0, kalimba(NOTE["E6"], 0.1), 0.25)]),
        "harvest": seq(["A4", "C5", "E5", "A5"], 0.09, 0.7, 0.4),
        "poor": seq(["E4", "D4"], 0.22, 0.9, 0.45),
        "rats": scurry,
        "starve": layer(2.2, [(0, seq(["A3", "G3", "E3"], 0.34, 1.3, 0.5), 1), (1.0, thud, 0.35)]),
        "arrive": seq(["E5", "A5"], 0.12, 0.6, 0.35),
        "plague": plague,
        "omen": gong,
        "win": layer(2.4, [(0, seq(["A4", "A4", "E5"], 0.16, 0.5, 0.45), 1), (0.5, kalimba(NOTE["A5"], 1.8), 0.45), (0.5, kalimba(NOTE["E5"], 1.8), 0.3), (0.5, kalimba(NOTE["C#5"], 1.8), 0.25)]),
        "lose": layer(2.6, [(0, seq(["E5", "D5", "C5", "A4"], 0.3, 1.0, 0.45), 1), (1.2, thud, 0.7)]),
    }

def save(name, x):
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
        x = x + room(x) * 0.25  # the effects stand in the same room as the music
        x = x / np.max(np.abs(x)) * 0.8
    x = np.clip(x, -1, 1)
    tmp = os.path.join(ROOT, "art", name + ".wav")
    with wave.open(tmp, "wb") as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR); f.writeframes((x * 32767).astype("<i2").tobytes())
    for d in ("app/App/Audio", "web/play/audio"):
        os.makedirs(os.path.join(ROOT, d), exist_ok=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libmp3lame", "-b:a", "128k" if name == "music" else "96k",
                        os.path.join(ROOT, d, name + ".mp3")], check=True)
    os.remove(tmp)

if __name__ == "__main__":
    save("music", music())
    fx = sounds()
    for name, x in fx.items(): save(name, x)
    print("music +", len(fx), "sounds")
