# Mehter asset pass: progress checkpoint

## Round 1 (done, verified)
- Band models: `assets/models/band_figure.glb` (body, sash, head, tall börk), `assets/models/band_instruments.glb` (davul, kös, zurna, çevgen staff, çevgen ring). Source in `assets/src/`.
- Cobblestone road: `assets/textures/cobble.jpg`.
- Sounds: `assets/sfx/ui-click.mp3`, `assets/sfx/results-fanfare.mp3` (Kenney CC0). Music and hit sounds untouched.
- `?noassets`, import map entry for `three/addons/`, `window.mehter.state().assets`.

## Round 2 (in progress)
Done in code (`index.html`):
- Black dots fixed: particle colour buffer was never uploaded (`tickPool` now sets `color.needsUpdate`). Sparks and petals show their colours (screenshot checked).
- Band larger on screen: all band InstancedMeshes scaled 1.5x about z = -15 (`BAND_SCALE`). Rows keep their place. Still modest: figures sit behind the drums at 1280x720.
- Crowd: tapered torso, round head, two instanced arms per figure (`cArm`, +1 draw call).
- Plane trees: pale tall trunk, three leaf clumps per tree (instanced, detail 0).
- Dusk HDRI: `assets/sky/dusk.hdr` (Poly Haven, Cedar Bridge Sunset 2, 1k, 1.6 MB). Loaded on High only (`loadSky`), used as `scene.environment`, intensity fades with the sky darkening. Effect on the picture is subtle; not measured separately.
- `CREDITS.md` has the HDRI entry.

Not done:
- Kenney crowd cheers: the interface and jingle packs I checked have no crowd sound. Synth cheer kept.
- Step animation beyond the existing beat bob and sway.

Half-edited files: none. `node --check` passes after the last edit.

Quiet fps run (done): before and after both 61.0 in three rounds (rAF is capped near 61 here). Bot runs with and without assets: 907/907 S, 0 errors.
`docs/assets.md` updated with the new assets and numbers. Final after screenshot: `docs/assets-after-gameplay-r2.png`.

## Next steps
- Band still reads small at 1280x720 (figures sit behind the drums). Further options: camera closer, or drop the drum height.
- Kenney crowd cheer: no suitable sample found yet.

## Last measured numbers
- Round 1 uncontended (`?auto`): before 61.0; after without band GLB 57.5.
- Round 1 under load: before 38.0, 35.0; after 35.5, 43.0; `?noassets` 30.5, 36.5.
- Round 2 play-state: 29 draw calls, 60,070 triangles (assets on).
- Bot run after round 2 (before BAND_SCALE 1.5 change): 907/907 S, 0 errors, with and without assets.
- Shipped assets: about 1.75 MB (HDRI 1.6 MB, other assets 0.15 MB).
