"""Renders Scoundrel's synthesized audio into assets/audio/.

    python audio-source/render.py

The sound effects go to assets/audio/sfx/ as WAV; the music, the cues and the
torch loop to assets/audio/music/ and assets/audio/ambience/ as OGG Vorbis.

Deterministic: every file is seeded by its own name, so an unchanged recipe
re-renders to the same audio, and check.py can prove the committed files are
what the recipes produce. A WAV comes out byte for byte the same. An OGG does
not - libsndfile gives every Ogg stream a random serial number - but its
decoded audio does, so an OGG is only rewritten when its audio has changed,
and otherwise left alone rather than churned.

A file listed in audio-source/replaced.txt has been replaced by a sourced
sound (see docs/audio.md, Sourcing) and is never rendered over.
"""

import io
import sys
import wave
from pathlib import Path

import numpy as np
import soundfile

import music
import recipes
import synth

ROOT = Path(__file__).resolve().parent.parent
AUDIO_DIR = ROOT / "assets" / "audio"
SFX_DIR = AUDIO_DIR / "sfx"
REPLACED_LIST = Path(__file__).resolve().parent / "replaced.txt"
OGG_QUALITY = 0.3
"""soundfile's compression_level for Vorbis: 0 is the best quality, 1 the smallest."""


def replaced():
    """File names (without extension) that are no longer ours to render."""
    if not REPLACED_LIST.exists():
        return set()
    names = set()
    for line in REPLACED_LIST.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            names.add(line)
    return names


def wav_bytes(signal):
    """A canonical 16-bit mono WAV at synth.SR: a bare RIFF header, fmt and data, nothing else."""
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(synth.SR)
        out.writeframes(synth.to_pcm16(signal))
    return buffer.getvalue()


def render_sfx():
    """Every sound effect that is still ours, as {name: wav bytes}."""
    skip = replaced()
    return {job.name: wav_bytes(recipes.render(job)) for job in recipes.jobs() if job.name not in skip}


OGG_BLOCK = 16384
"""Frames per write. libsndfile's Vorbis encoder overflows the stack (a silent exit 127
on Windows) when handed a minute of stereo in one write; a second at a time is fine."""


def ogg_bytes(signal):
    """OGG Vorbis at synth.SR, mono or stereo as the signal is, fed in blocks."""
    buffer = io.BytesIO()
    channels = 1 if signal.ndim == 1 else signal.shape[1]
    with soundfile.SoundFile(buffer, "w", synth.SR, channels, format="OGG", subtype="VORBIS",
                             compression_level=OGG_QUALITY) as out:
        for start in range(0, len(signal), OGG_BLOCK):
            out.write(signal[start:start + OGG_BLOCK])
    return buffer.getvalue()


def decode(data):
    """An OGG's audio, as floats."""
    signal, _ = soundfile.read(io.BytesIO(data))
    return signal


def render_streams():
    """Every stream that is still ours, as {name: finished float signal}."""
    skip = replaced()
    return {name: music.render(name) for name in music.STREAMS if name not in skip}


def stream_path(name):
    return AUDIO_DIR / f"{name}.ogg"


def stream_strays():
    """Files in the streams' folders that no stream makes."""
    expected = {stream_path(name) for name in music.STREAMS}
    folders = {stream_path(name).parent for name in music.STREAMS}
    return sorted(str(p.relative_to(AUDIO_DIR)) for folder in folders if folder.exists()
                  for p in folder.iterdir() if p not in expected)


def main():
    SFX_DIR.mkdir(parents=True, exist_ok=True)
    rendered = render_sfx()
    for name, data in rendered.items():
        (SFX_DIR / f"{name}.wav").write_bytes(data)
    expected = {job.name for job in recipes.jobs()}
    strays = sorted(p.name for p in SFX_DIR.iterdir() if p.stem not in expected or p.suffix != ".wav")
    print(f"rendered {len(rendered)} sound effects into {SFX_DIR.relative_to(ROOT)}"
          f" ({len(expected) - len(rendered)} replaced, left alone)")

    written = unchanged = 0
    for name, signal in render_streams().items():
        path = stream_path(name)
        data = ogg_bytes(signal)
        if path.exists() and np.array_equal(decode(path.read_bytes()), decode(data)):
            unchanged += 1
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        written += 1
    print(f"streams: {written} written, {unchanged} unchanged (same audio, so not rewritten),"
          f" {len(music.STREAMS) - written - unchanged} replaced")
    strays += stream_strays()

    if strays:
        # Not deleted: a stray may be someone's sourced sound. Everything in assets/ ships,
        # so AudioAssetsTest fails until it is dealt with.
        print("files here that no recipe makes (they will ship!):", ", ".join(strays))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
