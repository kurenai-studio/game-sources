# Peri Golf asset pass (arena round 3)

Optional CC0 assets under `assets/`, loaded after the first frame. The game stays fully playable without them
(`?noassets`, `file://`, offline, 404): every asset has a procedural fallback that is shown until the asset
arrives and is then swapped in place. Loaders (`GLTFLoader`, `RGBELoader`) come from the existing Three.js r170
import map. Sources, authors and licences: [`../CREDITS.md`](../CREDITS.md).

## Assets

| File | Source | Licence | Size KB | Used for | Tris | Fallback |
|---|---|---|---|---|---|---|
| `textures/tuff_detail.jpg` (512, grey) | Poly Haven *Sandstone Cracks* diffuse, low-contrast grey remap | CC0 | 44 | terraces, walls, stone pads, tunnels, chimneys, houses (`rock` material, box-projected UVs, 2.2 m tiles) and the terrain (`ground` material, 4.5 m tiles, fades to its mean grey beyond 10-32 m so the far field does not tile) | - | flat vertex colours |
| `textures/tuff_normal.jpg` (512) | Poly Haven *Sandstone Cracks* normal (GL) | CC0 | 57 | `rock` material relief, High tier only | - | none needed |
| `textures/grass_detail.jpg` (512, grey) | Poly Haven *Grass Ground* diffuse, low-contrast grey remap | CC0 | 36 | grass pads (`grass` material, 1.1 m tiles) | - | flat vertex colours |
| `textures/sand_detail.jpg` (512, grey) | Poly Haven *Aerial Sand* diffuse, low-contrast grey remap | CC0 | 31 | sand pads (`sand` material, 1.3 m tiles) | - | flat vertex colours |
| `sky/qwantani_dawn_puresky_512.hdr` (512x256 RGBE) | Poly Haven *Qwantani Dawn (Pure Sky)* 1k, downscaled | CC0 | 191 | PMREM `scene.environment` on High, rotated with the sun each hole; the sky itself stays the procedural tinted dome | - | hemisphere light only |
| `models/chimney_a.glb` | Blender, `assets/src/chimney_a.py` | MIT (game) | 20 | fairy chimney variant A, `InstancedMesh` (near + far field) | 256 | procedural chimney cones |
| `models/chimney_b.glb` | Blender, `assets/src/chimney_b.py` | MIT (game) | 21 | fairy chimney variant B (twin), instanced | 284 | procedural |
| `models/chimney_c.glb` | Blender, `assets/src/chimney_c.py` | MIT (game) | 22 | fairy chimney variant C (balcony), instanced | 268 | procedural |
| `models/cave_house.glb` | Blender, `assets/src/cave_house.py` | MIT (game) | 32 | cave houses, instanced | 400 | procedural box houses |
| `models/balloon.glb` | Blender, `assets/src/balloon.py` | MIT (game) | 37 | hot-air balloons: `envelope` (gore stripes, per-instance colour) + `basket` (basket, burner, ropes), 2 instanced meshes | 434 | procedural sphere + box |
| `models/pottery_wheel.glb` | Blender, `assets/src/pottery_wheel.py` | MIT (game) | 52 | hole 4: `wheel` (turns, pot radius 0.32 m as in the physics) + static `housing` | 812 | procedural disc + pot |
| `models/donkey.glb` | Blender, `assets/src/donkey.py` | MIT (game) | 74 | hole 8: `body` + `leg_fl/fr/bl/br` hinged at the hip (walk cycle) | 848 | procedural box donkey |
| `models/lantern.glb` | Blender, `assets/src/lantern.py` | MIT (game) | 26 | holes 7 and 12: swinging lantern, origin at the pivot, chain 1.28 m | 316 | procedural lantern |
| `sfx/putt.mp3` | Kenney impact-sounds `impactWood_light_000` | CC0 | 3 | ball hit (pitch follows power) | - | synth |
| `sfx/wall.mp3` | Kenney impact-sounds `impactWood_medium_000` | CC0 | 3 | wall bounce | - | synth |
| `sfx/obstacle.mp3` | Kenney impact-sounds `impactSoft_heavy_000` | CC0 | 5 | pot / door / donkey / lantern hit | - | synth |
| `sfx/cup.mp3` | Kenney impact-sounds `impactTin_medium_000` | CC0 | 2 | cup drop (the synth chime still follows) | - | synth |
| `sfx/click.mp3`, `sfx/back.mp3` | Kenney interface-sounds `click_001`, `back_001` | CC0 | 3 | UI buttons | - | synth |

Total shipped: **671 KB** (textures 168, HDR 191, models 284, sfx 16; budget 3 MB). Model scripts in `assets/src/`
(12 KB) rebuild every GLB with `python forge.py build <script> <out>`. Water keeps its synthesised splash; music,
pigeons, donkey bray and burner stay synthesised.

## How it is wired

- Materials come in two sets: Low = `MeshLambertMaterial` (as before) and High = `MeshStandardMaterial`
  (roughness 1, metalness 0) so the PMREM environment lights the scene. Meshes carry `userData.mk`
  (`rock`, `grass`, `sand`, `flat`, `smooth`, `water`, `lantern`, `wing`); quality changes swap the set.
- The course solid is split by surface (rock / grass / sand / flat) so each surface carries its own detail map,
  which makes grass and sand read as different friction zones.
- On High with the HDRI the renderer switches to ACES filmic tone mapping (exposure 1.05; the sky dome is
  `toneMapped: false` so its palette stays), the hemisphere light drops to 0.7x-0.5x and the sun to 0.8x-0.55x from
  hole 1 to 12 while the environment (intensity 0.22-0.24, rotated to the sun azimuth) fills in; the late sun colour is
  a warmer 0xffeccf and the sky dome gained a warm glow lobe around the sun. Without the HDRI (Low, `?noassets`)
  tone mapping stays off.
- Palette tweaks requested in review: grass is a warmer olive (0x70a048, tee marker 0x98c26c) with a stronger
  detail map; the terrain base is warmer (0xdfbd95) with large-scale warm/dark patches in its vertex colours; sand
  pads sit 4 mm proud of overlapping grass (visual only) so the separate sand mesh cannot z-fight.
- Low tier: no normal map, no environment (`scene.environment` is null), same pixel ratio and particle budget
  as before; it only gets the three diffuse detail maps.
- Chimneys and houses of the near scenery and the 140-chimney far field are three + one `InstancedMesh`es
  (up to 90 chimneys per variant, 60 houses), refilled per hole; the procedural far mesh is hidden when models are in.
- Sounds are fetched as array buffers, decoded once the `AudioContext` exists, played through the existing
  sfx gain bus; every call keeps its synth fallback.

## Measurements (Intel UHD 620, headless Chrome 1280x720, High tier)

| | Before | After |
|---|---|---|
| `capture.mjs` page rAF fps (`?auto`, 4 s warm-up) | 56.5 | 60.0 (56.0 in the first pass) |
| steady-state rAF fps in the screenshot runs (title, holes 1/2/4/5/6/8/12, phone) | 55.5-61 | 60-61.5 |
| draw calls (title / hole 2 / hole 4 / hole 8 / hole 12) | 13 / 12 / 13 / 13 / 15 | 16 / 16 / 19 / 22 / 20 |
| triangles on screen | 27-31k | 66-78k (instanced far field) |
| bot run, 12 holes (`?auto`) | 18 strokes, 0 errors | 18 strokes, 0 errors, same card with and without assets |
| `?noassets` | - | 12-14 calls, 0 errors, identical to the old build |

The before capture and the first after capture were taken while a second agent was working on the same laptop
(56 fps both); the final after capture reached 60.0 fps, and the screenshot runs sit at 60-61 fps before and after.

## Screenshots

`assets-before-*.png` / `assets-after-*.png` in this folder: title, hole 2 (Chimney Bend), hole 4 (pottery
wheel), hole 8 (donkey and vines), hole 12 (sunrise ridge with lanterns, water and balloons), phone (390x844, Low tier).
The after set was retaken after the review tuning round (tone mapping, olive grass, terrain fade).
