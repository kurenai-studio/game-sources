"""Synthesizes the placeholder sound effects into assets/sounds (16-bit mono WAV).

    python tools/gen_sounds.py
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sounds")
RATE = 22050


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    k = 0.9 / peak
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32767)) for s in samples))


def env(t, attack, decay):
    if t < attack:
        return t / attack
    return math.exp(-(t - attack) / decay)


def synth(dur, fn):
    rng = random.Random(1)
    return [fn(i / RATE, rng) for i in range(int(dur * RATE))]


class LowPass:
    def __init__(self, k):
        self.k, self.y = k, 0.0

    def __call__(self, x):
        self.y += self.k * (x - self.y)
        return self.y


def hit(dur, freq0, freq1, noise_amt, lp):
    f = LowPass(lp)
    phase = [0.0]

    def fn(t, rng):
        fr = freq1 + (freq0 - freq1) * math.exp(-t * 30)
        phase[0] += fr / RATE
        tone = math.sin(phase[0] * math.tau)
        n = f(rng.uniform(-1, 1))
        return (tone * (1 - noise_amt) + n * noise_amt * 3) * env(t, 0.002, dur / 4)
    return synth(dur, fn)


def whoosh():
    f = LowPass(0.05)

    def fn(t, rng):
        f.k = 0.02 + 0.25 * math.sin(math.pi * t / 0.16)
        return f(rng.uniform(-1, 1)) * math.sin(math.pi * min(1, t / 0.16))
    return synth(0.16, fn)


def block():
    phase = [0.0]

    def fn(t, rng):
        phase[0] += 1400 / RATE
        return (math.sin(phase[0] * math.tau) * 0.6 + rng.uniform(-1, 1) * 0.4) * env(t, 0.001, 0.025)
    return synth(0.12, fn)


def sweep(dur, f0, f1, wave_fn, decay):
    phase = [0.0]

    def fn(t, rng):
        fr = f0 + (f1 - f0) * (t / dur)
        phase[0] += fr / RATE
        return wave_fn(phase[0]) * env(t, 0.005, decay)
    return synth(dur, fn)


def square(p):
    return 1.0 if (p % 1.0) < 0.5 else -1.0


def tri(p):
    return 4 * abs((p % 1.0) - 0.5) - 1


def fireball():
    f = LowPass(0.2)
    phase = [0.0]

    def fn(t, rng):
        fr = 220 + 380 * math.exp(-t * 6)
        phase[0] += fr / RATE
        return (tri(phase[0]) * 0.5 + f(rng.uniform(-1, 1)) * 1.2) * env(t, 0.02, 0.18)
    return synth(0.45, fn)


def ko():
    phase = [0.0]

    def fn(t, rng):
        fr = 330 * math.exp(-t * 1.3)
        phase[0] += fr / RATE
        return (square(phase[0]) * 0.4 + tri(phase[0] * 0.5) * 0.6) * env(t, 0.01, 0.5)
    return synth(1.1, fn)


def fanfare():
    notes = [(523, 0.0), (659, 0.09), (784, 0.18), (1046, 0.27)]

    def fn(t, rng):
        s = 0.0
        for fr, st in notes:
            if t >= st:
                s += square(fr * (t - st)) * 0.25 * env(t - st, 0.005, 0.12 if st < 0.27 else 0.3)
        return s
    return synth(0.8, fn)


def blip(freq, dur):
    return sweep(dur, freq, freq * 1.5, square, dur / 2)


def main():
    write("hit_light", hit(0.14, 520, 150, 0.55, 0.35))
    write("hit_heavy", hit(0.28, 320, 60, 0.6, 0.18))
    write("block", block())
    write("whoosh", whoosh())
    write("jump", sweep(0.12, 200, 520, tri, 0.06))
    write("thud", hit(0.3, 140, 40, 0.5, 0.08))
    write("fireball", fireball())
    write("ko", ko())
    write("fight", fanfare())
    write("select", blip(660, 0.06))
    write("confirm", blip(880, 0.14))
    print("sounds written to", OUT)


if __name__ == "__main__":
    main()
