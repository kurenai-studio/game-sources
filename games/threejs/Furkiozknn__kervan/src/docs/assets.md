# Kervan assets

Everything here is optional. The game loads it asynchronously after the first frame and swaps it into the meshes
that already exist; until then, and whenever a file cannot load (`file://`, offline, 404) or with `?noassets`, the
procedural models and synthesised sounds stay. Licences and authors: [CREDITS.md](../CREDITS.md).

## Files

| File | Source | Licence | KB | Where it is used | Triangles |
|---|---|---|---:|---|---:|
| `models/camel.glb` | built here (`src/camel.py`) | MIT (game) | 36.5 | pack camel: body, nodding head (new instanced mesh), one leg used 4x, load tinted per good | 826 |
| `models/riders.glb` | built here (`src/riders.py`) | MIT | 43.2 | caravan leader (horse + rider + kaftan tinted by owner), guards | 1014 |
| `models/han.glb` | built here (`src/han.py`) | MIT | 81.7 | caravanserai parts per level: portal, hall, arcades, mescit; towers, crenels, dome, banners, flag | 2444 |
| `models/bazaar.glb` | built here (`src/bazaar.py`) | MIT | 45.8 | market corner with striped stalls in every city | 1248 |
| `models/bursa.glb` | built here | MIT | 74.4 | Ulu Cami (20 domes, 2 minarets), Yesil Turbe | 2374 |
| `models/izmir.glb` | built here | MIT | 54.5 | lighthouse, clock tower, two harbour warehouses | 1648 |
| `models/konya.glb` | built here | MIT | 47.2 | Mevlana lodge, fluted Green Dome, minaret, sebil | 1448 |
| `models/aksaray.glb` | built here | MIT | 22.6 | leaning brick minaret (Egri Minare) | 682 |
| `models/goreme.glb` | built here | MIT | 30.7 | three fairy-chimney variants, scaled per spot | 860 |
| `models/kayseri.glb` | built here | MIT | 77.1 | basalt citadel with gate and keep, Doner Kumbet | 2512 |
| `models/urfa.glb` | built here | MIT | 37.5 | castle hill with twin columns, Balikligol with arcade and minaret | 1056 |
| `textures/terrain_detail.jpg` | Poly Haven (3 maps, packed R/G/B) | CC0 | 159.4 | grey detail on the terrain: sand, steppe, rock (High only) | |
| `textures/parchment.webp` | ambientCG Paper006 | CC0 | 46.2 | paper grain on the glass panels | |
| `sky/qwantani_late_afternoon_512.hdr` | Poly Haven, 1k downscaled to 512x256 | CC0 | 278.6 | reflections on the water (full) and the salt lake (18 %, roughness 0.75, keeps its cream tone), fades with the day cycle (High only) | |
| `sfx/coins_sell.mp3`, `coins_buy.mp3` | Kenney RPG Audio | CC0 | 10.7 | selling; quiet coins after a purchase | |
| `sfx/cloth_1-2.mp3`, `leather_1-2.mp3` | Kenney RPG Audio | CC0 | 16.9 | goods loaded onto the camels (buy), camel bought | |
| `sfx/click.mp3` | Kenney Interface Sounds | CC0 | 0.9 | UI clicks | |
| `sfx/step_1-3.mp3`, `step_snow_1-2.mp3` | Kenney Impact Sounds | CC0 | 26.4 | soft camel steps, snow steps in winter | |

**Total shipped: 1,090 KB** (budget 3 MB). Models carry no normals or UVs (`src/slim_glb.py`); flat normals are
recomputed at load. All models are merged into existing meshes or swapped into the existing InstancedMeshes; the only
new draw call is the instanced camel head.

## Tiers and fallbacks

| | High | Low (`?low`, phones) | `?noassets` / load failure |
|---|---|---|---|
| models | yes | no (procedural, Low must not get heavier) | procedural |
| terrain detail, HDRI | yes | no | no |
| sounds, parchment | yes | yes | synth / plain glass |

Houses, trees and the bazaar spots are identical in every path (the loaded landmarks consume the same random numbers
as the procedural ones), so nothing jumps when the models arrive.

## Measurements (Intel UHD 620, headless Chrome on the real GPU, 1280x720)

| | before | after |
|---|---|---|
| `capture.mjs ?auto` page rAF fps (10 s warmup) | 59.5 | 61.0 |
| start view, draw calls / triangles | 19-21 / 74k | 20-25 / 106-116k |
| year 1 day 127, 7 caravans, zoomed in (dist 60): fps / calls / tris | 59.5 / 24 / 79k (`?noassets`) | 60.3 / 25 / 138k |
| same, zoomed out (dist 200) | 60.3 / 27 / 82k | 60.5 / 29 / 144k |
| Low tier fps / calls / tris | | 60.7 / 24 / 66k (no models) |
| asset load time (all files, local server) | | about 0.6 s |

The fps is capped by vsync at 60. The "before" late-game column is `?noassets`, which is the procedural game plus the
three plain bazaar stalls. A first version of the camel and riders (1400 + 1500 triangles) dropped the zoomed late-game
view to 52 fps; they were cut to 826 + 1014 triangles.

Bot checks after the change: `?auto` (seed 3) wins on day 212 with assets and with `?noassets`, 0 JS errors; the
headless balance run (12 seeds) is unchanged: the smart bot wins on days 158-211, the careless bot goes bankrupt on
days 15-25.

## Rebuilding

- Models: `assets/src/build.ps1` (asset-forge `build`, then `slim_glb.py`), run inside the heavy lock.
- Textures: `assets/src/textures.ps1 -Src <folder with the downloaded diffuse maps>` (ffmpeg high-pass and channel pack).
- HDRI: `forge.py ph-hdri qwantani_late_afternoon_puresky`, then `ffmpeg -i <1k>.hdr -vf scale=512:256:flags=area -c:v hdr`.
- Sounds: `forge.py kenney <pack> --pick ...`, then `forge.py sfx <in.ogg> <out.mp3>`.

Screenshots: `docs/assets-before-*.png` and `docs/assets-after-*.png` (same views; the phone view is the Low tier).
