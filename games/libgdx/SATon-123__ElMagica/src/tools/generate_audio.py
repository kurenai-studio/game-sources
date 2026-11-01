"""Create ElMagica's original small synth soundtrack and effects using only Python."""
import math
from pathlib import Path
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
ROOT.mkdir(parents=True, exist_ok=True)


def write(name, samples):
    folder = ROOT / ("music" if name in {"menu", "combat", "boss"} else "sfx")
    folder.mkdir(exist_ok=True)
    with wave.open(str(folder / (name + ".wav")), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, value)) * 32767)) for value in samples))


def note(number):
    return 440 * 2 ** ((number - 69) / 12)


def music(name, beat, battle, boss=False):
    # D minor arpeggios, four chords, and a soft bass pulse.
    chords = [(50, 53, 57, 62), (46, 50, 53, 58), (48, 52, 55, 60), (45, 48, 52, 57)]
    melody = [0, 2, 1, 3, 2, 1, 3, 2]
    samples = []
    for i in range(round(64 * beat * RATE)):
        time = i / RATE
        step = int(time / beat)
        phase = time % beat
        chord = chords[(step // 16) % 4]
        frequency = note(chord[melody[step % 8]] + 12)
        attack = min(1, phase / 0.015)
        envelope = attack * math.exp(-phase * (6 if battle else 4))
        lead = math.sin(2 * math.pi * frequency * time) + 0.2 * math.sin(4 * math.pi * frequency * time)
        if boss:
            lead += 0.25 * math.sin(6 * math.pi * frequency * time)
        bass = math.sin(2 * math.pi * note(chord[0] - 12) * time) * math.exp(-phase * 3)
        pad = sum(math.sin(2 * math.pi * note(n) * time) for n in chord) / 4
        kick_phase = time % (beat * 2)
        kick = math.sin(2 * math.pi * (70 * kick_phase + 2 * (1 - math.exp(-kick_phase * 25)))) * math.exp(-kick_phase * 20)
        value = lead * envelope * 0.11 + bass * 0.09 + pad * 0.04 + kick * (0.08 if battle else 0.025)
        if boss:
            pulse = time % (beat / 2)
            value += math.sin(2 * math.pi * note(chord[0] - 12) * time) * math.exp(-pulse * 22) * 0.07
            value += math.sin(2 * math.pi * note(chord[1] + 12) * time) * 0.025
        # Fade both loop edges to silence to avoid clicks.
        value *= min(1, time / 0.08, (64 * beat - time) / 0.08)
        samples.append(value)
    write(name, samples)


def effect(name, duration, start, end, noise=0, notes=None):
    randomizer = random.Random(7)
    samples = []
    phase = 0
    for i in range(round(duration * RATE)):
        time = i / RATE
        progress = time / duration
        frequency = start + (end - start) * progress
        if notes:
            frequency = note(notes[min(len(notes) - 1, int(progress * len(notes)))])
        phase += 2 * math.pi * frequency / RATE
        value = math.sin(phase) * 0.65 + math.sin(phase * 2) * 0.15 + randomizer.uniform(-1, 1) * noise
        envelope = min(1, time / 0.006) * (1 - progress) ** 2
        samples.append(value * envelope * 0.35)
    write(name, samples)


music("menu", 0.72, False)
music("combat", 0.32, True)
music("boss", 0.24, True, True)
effect("shoot", 0.12, 900, 240, 0.1)
effect("hit", 0.10, 180, 65, 0.6)
effect("hurt", 0.18, 170, 75, 0.25)
effect("death", 0.65, 200, 45, 0.1)
effect("pickup", 0.18, 850, 1300)
effect("buy", 0.32, 0, 0, notes=[74, 77, 81])
effect("boss_cue", 0.40, 90, 45, 0.4)
effect("enemy_shot", 0.16, 460, 130, 0.2)
effect("click", 0.045, 700, 500)
effect("floor", 0.48, 0, 0, notes=[62, 65, 69, 74])
effect("dodge", 0.15, 1200, 500, 0.2)
print("Created 3 music loops and 11 sound effects in", ROOT)
