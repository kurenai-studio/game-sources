# Mehter: asset list and numbers

Licences and credits: [CREDITS.md](../CREDITS.md). Model scripts: `assets/src/`. Every asset is optional; the game falls back to the procedural world and synthesised sounds (see "Fallback" below).

## Assets

| File | Source | Licence | Size | Used for | Triangles | Fallback |
|---|---|---|---|---|---|---|
| `assets/models/band_figure.glb` | Built in Blender 5.2 from `assets/src/band_figure.py` | MIT (game) | 26 KB | Band body (kaftan), sash, head, tall börk (4 parts) | 332 (all 4 parts, one figure) | Box body, sphere head, cylinder fez, cylinder sash |
| `assets/models/band_instruments.glb` | Built in Blender 5.2 from `assets/src/band_instruments.py` | MIT (game) | 63 KB | Davul, kös, zurna, çevgen staff and jingle ring (5 parts) | 860 (all 5 parts) | Cylinders (the previous geometry) |
| `assets/textures/cobble.jpg` | Poly Haven, Cobblestone Floor 01 (diffuse, 512 px) | CC0 | 41 KB | Cobblestone road (12 x 72 m plane over the avenue, 3 x 18 repeats) | 2 (plane) | Flat purple avenue |
| `assets/sky/dusk.hdr` | Poly Haven, Cedar Bridge Sunset 2 (1k HDR) | CC0 | 1.6 MB | Image-based light on the High tier only; intensity fades with the dusk | - | Hemisphere light only (Low tier and any load failure) |
| `assets/sfx/ui-click.mp3` | Kenney Interface Sounds, click_001 (mono 22 kHz, 64 kbps) | CC0 | 1.5 KB | UI button and card clicks | - | Synthesised click (`sndClick`) |
| `assets/sfx/results-fanfare.mp3` | Kenney Music Jingles, 8-bit jingles_NES00 (mono 22 kHz, 64 kbps) | CC0 | 15 KB | Results screen after a cleared song | - | Synthesised crowd noise (`sndCheer`) |

Total shipped assets: about 1.75 MB (HDRI 1.6 MB, the rest about 0.15 MB). Budget: 3 MB.

Procedural, no file: crowd figures (tapered torso, round head, instanced arms) and plane trees (pale trunk, three leaf clumps per tree). Both are instanced and add 1 draw call (the arms).

Not done: Kenney crowd cheers (the interface and jingle packs checked have no crowd sound; the synthesised cheer is kept).

## What changed in the scene

- Band: every member keeps its instanced layout. Body, head and fez use the GLB geometry, and the sash is one new instanced mesh (gold, or cream for the mehterbaşı). The mehterbaşı's börk is 1.45x taller. All band meshes are scaled 1.5x about z = -15 so the band reads larger from the camera. The beat-synced bob and sway are unchanged.
- Road: the cobblestone plane sits over the purple avenue slab, under the red carpet.
- Crowd: arms added (instanced, 2 per figure) and a tapered torso instead of a box.
- Trees: plane trees with a pale trunk and three-clump canopy, same positions.
- Particles: the sparks and petals were drawn black because their colour buffer was never uploaded to the GPU. Fixed; they now show their colours.
- Sound: the synthesised music, hit sounds and audio-clock timing are unchanged. Only the UI clicks and the results fanfare use samples.
- Draw calls: +3 (sash, cobblestone plane, crowd arms).

## Numbers

Measured on the real GPU (Intel UHD Graphics, Direct3D11, ANGLE) with `mehter-check.mjs` (`?auto`, rAF over 2 s, after 4 s warm-up).

Quiet run (no other headless Chrome running), three rounds, same session, before = pre-asset build, after = current build:

| Build | rAF fps round 1 | round 2 | round 3 |
|---|---|---|---|
| Before (no assets) | 61.0 | 61.0 | 61.0 |
| After (all assets) | 61.0 | 61.0 | 61.0 |

The browser caps rAF at the display rate (about 61 here), so this run shows the build keeps the High tier at or above the 58 fps target, but it cannot show how much headroom is left.

Earlier runs, when another process was loading the GPU: before 38.0, 35.0; all assets 35.5, 43.0; `?noassets` 30.5, 36.5. The spread of about 10 fps comes from the other load, not from the build.

Play-state counters (`window.mehter.state()`, `?auto` at about 15 s, song 0):

| Build | Draw calls | Triangles |
|---|---|---|
| Before | 26 | 34,948 |
| After (all assets, round 2) | 29 | 60,070 |

Triangles rose by about 16,000 since the end of round 1 (44,258), mostly from the band models (31 instanced members), the crowd torsos and arms, and the plane tree canopies. Triangle count is the first thing to cut if an unloaded High run ever falls below 58.

Bot run (`?auto&sim=99999`, six songs, after round 2): all 907 notes of the last song perfect, grade S, 0 JS errors, with assets (`band`, `cobble`, `sfx`, `sky` loaded) and with `?noassets`. The S grade is in `localStorage` for all six songs.

## Fallback

- Every asset loads after the first frame. Each swaps in place when it arrives.
- A missing or failed GLB leaves the procedural band untouched (all nine geometries are collected before any swap).
- A missing texture leaves the flat avenue. A missing sound uses the synthesised fallback. A missing HDRI leaves the hemisphere light.
- `?noassets` skips all asset requests. `file://` falls back the same way.
- `window.mehter.state().assets` reports which assets loaded (`band`, `cobble`, `sfx`, `sky`).
