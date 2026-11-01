"""Generate a demo level: a simple 120 BPM beep track + matching chart.

    python tools/create_demo_level.py

Creates ``music_levels/music_Demo_Beat.wav`` and ``Demo_Beat.json`` so the
game is playable out of the box for a smoke test.
"""

from __future__ import annotations

import math
import os
import struct
import sys
import wave

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

RATE = 44100
BPM = 120
BEAT_MS = 60000.0 / BPM
SECONDS = 20


def tone(freq, ms, volume=0.4):
    n = int(RATE * ms / 1000.0)
    out = bytearray()
    for i in range(n):
        # quick attack/decay envelope to avoid clicks
        env = min(1.0, i / (RATE * 0.01)) * max(0.0, 1 - (i / n) ** 2)
        sample = int(32767 * volume * env * math.sin(2 * math.pi * freq * i / RATE))
        out += struct.pack("<h", sample)
    return bytes(out)


def build_audio():
    total = int(RATE * SECONDS)
    buf = bytearray(b"\x00\x00" * total)

    def place(freq, at_ms, ms):
        start = int(RATE * at_ms / 1000.0)
        clip = tone(freq, ms)
        buf[start:start + len(clip)] = clip

    beats = int(SECONDS * 1000 / BEAT_MS)
    for b in range(beats):
        at = b * BEAT_MS
        freq = 880 if b % 4 == 0 else 440
        place(freq, at, 120)
    return bytes(buf)


def build_chart():
    # a straightforward pattern on the beat grid, with a few sustains and boosts
    lanes = [0, 1, 2, 3]
    notes = []
    beats = int(SECONDS * 1000 / BEAT_MS)
    for b in range(2, beats - 1):
        at = b * BEAT_MS
        lane = lanes[b % 4]
        boost = (b % 8 == 3)
        if b % 6 == 0:
            notes.append({"lane": lane, "time": at, "end": at + BEAT_MS * 2,
                          "boost": boost})
        else:
            notes.append({"lane": lane, "time": at, "end": None, "boost": boost})
    return notes


def main():
    root = "music_levels"
    os.makedirs(root, exist_ok=True)
    audio = os.path.join(root, "music_Demo_Beat.wav")
    chart = os.path.join(root, "Demo_Beat.json")

    with wave.open(audio, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(build_audio())

    from game.services.levels import LevelLibrary
    lib = LevelLibrary(root)
    info = lib.get("Demo_Beat") if os.path.exists(chart) else None
    notes = build_chart()
    payload = {"name": "Demo Beat", "audio": "music_Demo_Beat.wav", "notes": notes}
    import json
    with open(chart, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)

    print(f"wrote {audio} ({os.path.getsize(audio) // 1024} KB)")
    print(f"wrote {chart} ({len(notes)} notes)")


if __name__ == "__main__":
    main()
