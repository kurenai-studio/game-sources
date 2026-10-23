#!/usr/bin/env python3
"""Tiny 8-bit style sound effects synthesiser for Pixel TD."""
import os, wave, struct, math, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sfx')
os.makedirs(OUT, exist_ok=True)
rnd = random.Random(1)


def save(name, samples, vol=0.5):
    with wave.open(os.path.join(OUT, name + '.wav'), 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * vol)) * 32000)) for s in samples))


def env(i, n, a=0.01, r=None):
    t = i / SR
    dur = n / SR
    e = min(1.0, t / a) if a > 0 else 1.0
    e *= (1 - i / n) ** (r if r else 1.5)
    return e


def square(f, t, duty=0.5):
    return 1.0 if (f * t) % 1.0 < duty else -1.0


def tone(freqs, dur, kind='square', duty=0.5, slide=0.0, decay=1.5):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        seg = min(len(freqs) - 1, int(i / n * len(freqs)))
        f = freqs[seg] * (1 + slide * i / n)
        if kind == 'square':
            v = square(f, t, duty)
        elif kind == 'tri':
            v = 4 * abs((f * t) % 1 - 0.5) - 1
        else:
            v = math.sin(2 * math.pi * f * t)
        out.append(v * env(i, n, 0.003, decay))
    return out


def noise(dur, decay=2.0, lp=0.5, step=1):
    n = int(SR * dur)
    out, last, cur = [], 0.0, 0.0
    for i in range(n):
        if i % step == 0:
            cur = rnd.uniform(-1, 1)
        last = last + (cur - last) * lp
        out.append(last * env(i, n, 0.002, decay))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


save('shot', mix(noise(0.08, 3, 0.9, 2), tone([900, 500], 0.06, 'square', 0.25, -0.5, 3)), 0.25)
save('slash', [s for s in noise(0.14, 1.2, 0.35)], 0.45)
save('flame', noise(0.18, 0.8, 0.12, 3), 0.35)
save('spray', noise(0.16, 1.2, 0.45, 1), 0.22)
save('hit', tone([220], 0.04, 'square', 0.5, -0.6, 2), 0.15)
save('pop', mix(tone([520, 780], 0.08, 'square', 0.5, 0.3, 2), noise(0.05, 3, 0.6)), 0.25)
save('boss_die', mix(noise(0.9, 1.2, 0.15, 4), tone([110, 82, 65], 0.8, 'square', 0.5, -0.3, 1.2)), 0.45)
save('place', tone([330, 494, 660], 0.15, 'square', 0.5, 0, 1.2), 0.25)
save('click', tone([1200], 0.03, 'square', 0.5, -0.3, 2), 0.2)
save('upgrade', tone([523, 659, 784, 1046], 0.3, 'square', 0.25, 0, 1.0), 0.25)
save('sell', tone([1046, 1318], 0.14, 'square', 0.5, 0, 1.5), 0.22)
save('wave', tone([392, 523, 659], 0.36, 'tri', 0.5, 0, 0.8), 0.45)
save('leak', tone([160, 120], 0.25, 'square', 0.5, -0.3, 1.0), 0.3)
save('heal', tone([660, 880], 0.15, 'sine', 0.5, 0.2, 1.5), 0.25)
save('win', tone([523, 659, 784, 659, 784, 1046], 1.1, 'square', 0.5, 0, 0.6), 0.25)
save('lose', tone([392, 330, 262, 196], 1.2, 'tri', 0.5, -0.1, 0.6), 0.45)
save('unlock', mix(tone([523, 784, 1046, 1568], 0.8, 'square', 0.25, 0, 0.8),
                   tone([262, 392, 523, 784], 0.8, 'tri', 0.5, 0, 0.8)), 0.25)
save('error', tone([180, 140], 0.15, 'square', 0.5, 0, 1.0), 0.2)
save('boom', mix(noise(0.45, 1.5, 0.18, 3), tone([90, 60], 0.35, 'square', 0.5, -0.4, 1.5)), 0.45)
save('honk', tone([440, 370], 0.18, 'square', 0.35, 0, 0.8), 0.18)
save('snipe', mix(noise(0.05, 4, 0.95, 1), tone([1400, 300], 0.05, 'square', 0.5, -0.8, 3),
                  noise(0.35, 2.2, 0.08, 4)), 0.4)
save('rattle', mix(*[[0.0] * int(SR * 0.05 * k) + tone([700 + 90 * k], 0.04, 'square', 0.3, -0.4, 2) for k in range(4)]), 0.18)
print('sfx ok')
