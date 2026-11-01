# audio-source — Scoundrel's synthesized audio

Every sound the game plays — the effects, the music and cues, the torch — is **rendered here by
Python** and committed under `assets/audio/`. The game only ever loads the rendered files. They
began as placeholders to be replaced; after three listening rounds the user kept them all. The reference for what ships
is [`docs/audio.md`](../docs/audio.md); the plan and its progress are in
[`docs/superpowers/plans/2026-09-24-audio.md`](../docs/superpowers/plans/2026-09-24-audio.md).

```bash
python -m pip install --user -r audio-source/requirements.txt   # numpy + soundfile, pinned
python audio-source/render.py     # writes assets/audio/sfx/*.wav
python audio-source/check.py      # measures them; non-zero exit on any failure
python audio-source/audition.py   # builds audio-source/build/audition.html to listen to
```

| File | What it is |
|---|---|
| `synth.py` | The building blocks, numpy only: oscillators, struck-object (modal) synthesis, bubbles, plucked strings, hand-written filters, saturation, the lo-fi stage, and loudness measurement |
| `recipes.py` | One recipe per sound. Each docstring says what the sound is *meant* to be, because it was written without being heard |
| `music.py` | The placeholder music (menu and run loops), the win and death cues, and the torch's crackle loop. The note data is in the file. Loops are seamless by construction: anything ringing past the end is folded back onto the start, and anything sustained completes whole cycles per loop |
| `render.py` | Renders every recipe to a 16-bit mono 44.1 kHz WAV, and every stream to OGG Vorbis. An OGG is only rewritten when its decoded audio changed, because its bytes differ on every run (a random Ogg serial number) |
| `check.py` | The measurements that stand in for ears: format, peak ≤ −1 dBFS, attack within 5 ms, silent tail, no DC, length, loudness on target, versions that aren't near-copies, and the committed files matching a fresh render. It also reports brightness by weight |
| `audition.py` | The listening page: every file, plus scenes played the way the game will play them, with the game's rules read from the Java source |
| `replaced.txt` | Files replaced by a sourced sound, which `render.py` must never overwrite |

**Rules:**

- **Deterministic.** Each file is seeded by its own name, and the versions are pinned, so an
  unchanged recipe re-renders to the same bytes. `check.py` fails if the committed files and a
  fresh render differ.
- **The file names are the contract** with the game (`com.tomer.scoundrel.audio.Sound`).
  `AudioAssetsTest` holds `assets/audio/sfx/` to that enum, and `check.py` holds it to these
  recipes.
- **Nothing but shipped audio goes under `assets/`.** The audition page and scratch renders go
  in `build/` (gitignored).
- **The lo-fi stage** is the "crunchy" in crunchy lo-fi: sample-and-hold down to a lower rate
  (the aliasing is the crunch), mild bit-crushing, then a low-pass so the result is warm rather
  than fizzy. Its settings, like every recipe's numbers, are starting values tuned by ear in the
  listening rounds.
