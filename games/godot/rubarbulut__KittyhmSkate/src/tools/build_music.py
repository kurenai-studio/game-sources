"""Compose/render the original 128 BPM prototype track. Requires numpy.

No samples or commercial songs: kick, snare, hats, bass and leads are synthesized.
The checked-in WAV is playable without Python or numpy.
"""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
BPM = 128
BEAT = 60 / BPM
DURATION = 96 * BEAT
ROOT = Path(__file__).resolve().parents[1]
rng = np.random.default_rng(261103)
mix = np.zeros((round((DURATION + 0.25) * RATE), 2), dtype=np.float64)


def add(sound, beat, gain=1.0, pan=0.0):
    start = round(beat * BEAT * RATE)
    if start < 0 or start >= len(mix):
        return
    length = min(len(sound), len(mix) - start)
    mix[start:start+length, 0] += sound[:length] * gain * (1 - pan * 0.4)
    mix[start:start+length, 1] += sound[:length] * gain * (1 + pan * 0.4)


def time_axis(seconds):
    return np.arange(round(seconds * RATE)) / RATE


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def tone(midi, duration, kind="lead"):
    t = time_axis(duration)
    f = frequency(midi)
    attack = np.minimum(t / 0.005, 1)
    release = np.minimum((duration - t) / 0.045, 1)
    if kind == "bass":
        wave_shape = np.sin(2*np.pi*f*t) + 0.25*np.sin(4*np.pi*f*t) + 0.12*np.sin(6*np.pi*f*t)
        env = attack * release * np.exp(-t*6)
    elif kind == "pad":
        wave_shape = np.sin(2*np.pi*f*t) + 0.35*np.sin(2*np.pi*f*1.002*t)
        env = np.minimum(t/0.12, 1) * np.minimum((duration-t)/0.3, 1)
    else:
        # Band-limited-ish hollow square lead, with a short plucky envelope.
        wave_shape = sum(np.sin(2*np.pi*f*h*t)/h for h in [1, 3, 5, 7]) / 1.5
        env = attack * release * np.exp(-t*5)
    return wave_shape * env


t = time_axis(0.34)
kick = np.sin(2*np.pi*(48*t + 110*0.023*(1-np.exp(-t/0.023)))) * np.exp(-t*14)
kick += rng.normal(0, 0.09, len(t)) * np.exp(-t*160)
t = time_axis(0.19)
noise = rng.uniform(-1, 1, len(t))
snare = (noise - np.roll(noise, 1)*0.55)*np.exp(-t*24)*0.38
snare += np.sin(2*np.pi*185*t)*np.exp(-t*30)*0.22
t = time_axis(0.065)
noise = rng.uniform(-1, 1, len(t))
hat = (noise-np.roll(noise, 1))*np.exp(-t*75)*0.12

roots = [38, 34, 41, 36]  # Dm / Bb / F / C
melody = [74, 77, 81, 77, 72, 77, 79, 76, 74, 77, 84, 81, 79, 76, 72, 69]

for beat in range(96):
    root = roots[(beat//8) % 4]
    outro = beat >= 88
    drop = 48 <= beat < 80
    add(kick, beat, 0.64 if not outro else 0.35)
    if beat >= 4 and beat % 2 == 1 and not outro:
        add(snare, beat, 0.55)
    if beat >= 4:
        add(hat, beat + 0.5, 0.55, 0.35)
        if beat >= 8 and not outro:
            add(hat, beat, 0.30, -0.35)
    if beat >= 8:
        add(tone(root, BEAT*0.7, "bass"), beat, 0.27)
        if not outro and beat % 4 != 3:
            add(tone(root+12, BEAT*0.25, "bass"), beat+0.75, 0.13)
    if beat % 8 == 0:
        for note in [root+24, root+27+(1 if root in [34, 41, 36] else 0), root+31]:
            add(tone(note, BEAT*7.7, "pad"), beat, 0.031, -0.2)
    if 8 <= beat < 88 and beat % 8 != 7:
        note = melody[(beat-8) % len(melody)]
        add(tone(note, BEAT*0.65), beat, 0.095 if not drop else 0.15, -0.12)
        add(tone(note, BEAT*0.65), beat+0.75, 0.025, 0.7)
        if drop and beat % 4 == 2:
            add(tone(note+12, BEAT*0.35), beat+0.5, 0.09, 0.25)
    if 40 <= beat < 48:
        add(snare, beat+0.5, 0.12 + (beat-40)*0.02)

# A short, bright cymbal announces the dimension shift.
t = time_axis(1.8)
noise = rng.uniform(-1, 1, len(t))
add((noise-np.roll(noise,1))*np.exp(-t*4),48,0.12)
mix = mix[:round(DURATION*RATE)]
mix *= np.minimum(np.arange(len(mix))/RATE/0.025, 1)[:,None]
mix *= np.minimum((len(mix)-1-np.arange(len(mix)))/RATE/0.9, 1)[:,None]
mix = np.tanh(mix*1.4)
mix *= 0.87 / np.max(np.abs(mix))
pcm = (mix*32767).astype("<i2")
output = ROOT / "assets/audio/alley_shift.wav"
output.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(output), "wb") as wav:
    wav.setnchannels(2)
    wav.setsampwidth(2)
    wav.setframerate(RATE)
    wav.writeframes(pcm.tobytes())
print(f"Rendered {output.name}: {DURATION:.2f}s, {BPM} BPM, original stereo synthesis")
