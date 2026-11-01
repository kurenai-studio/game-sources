# Asset provenance

Original project art/audio owned by ninefournine is licensed under CC BY 4.0.
Generator and renderer software implementations are licensed under MIT.
See [LICENSING.md](LICENSING.md) for scope and attribution requirements.

| Material | Source | License / provenance |
| --- | --- | --- |
| Five vehicle PNG sprites | `scripts/generate_art.py`, explicit pixel rows/palettes and stdlib PNG writer | Original art: CC BY 4.0; generator code: MIT |
| Pixel glyphs and cargo icons | `game/art.lua` | Original art: CC BY 4.0; rendering code: MIT |
| District imagery and city/effects | `game/maps/*.lua`, `game/render.lua` | Original visual artwork: CC BY 4.0; map/game/rendering implementations: MIT |
| Night Shift score, chase layer, ambience and event sounds | `scripts/generate_audio.py`, oscillator/noise synthesis and authored score | Original audio: CC BY 4.0; generator code: MIT |
| Small HUD font | LÖVE's built-in font via `newFont` | External runtime-provided, governed by upstream terms; no font file copied |

The inspected generator sources contain no downloads of source images or
samples. Runtime assets are tracked PNG/WAV/OGG files; no TTF/OTF, external
engine binary or third-party asset pack is bundled. Audio technical measurements
remain in `assets/audio/technical_checks.json`; those measurements do not
establish a completed listening/mix review.

The source/generators were created with AI programming assistance. That
assistance is disclosed in credits and should be accurately reflected in
the itch.io AI Disclosure fields. External software retains its own licenses.
