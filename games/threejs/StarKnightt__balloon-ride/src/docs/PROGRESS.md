# Balloon Ride — progress log

Read `docs/BRIEF.md` first. Newest entries go at the bottom.

---

## Phase 1 — skills, research, refs, scaffold, reused environment, capture harness (2026-11-03)

### Skills installed → `.claude/skills/` (28 skill folders)
Cloned into scratch, each SKILL.md read, only folders containing a SKILL.md copied. Nothing from them was executed, and the clones are deleted.
- **cloudai-x/threejs-skills** @0e18186 (13): threejs-animation, -asset-pipeline, -fundamentals, -geometry, -interaction, -lighting, -loaders, -materials, -performance, -postprocessing, -react-three-fiber, -shaders, -textures.
- **dgreenheck/webgpu-claude-skill** @af2319b (1): webgpu-threejs-tsl.
- **majidmanzarpour/threejs-game-skills** @8286774 (9): threejs-3d-generator, -aaa-graphics-builder, -audio-generator, -debug-profiler, -game-director, -game-ui-designer, -gameplay-systems, -image-generator, -qa-release.
  - Caveat: the 3d / audio / image generators call paid APIs (Tripo, ElevenLabs, Gemini) and download assets. The brief forbids shipped downloaded audio and textures, so do not use them for game assets.
- **From the skills.sh search** (terrain / clouds / shaders): **scottstts/Threejs-Awesome-Graphics-Agent-Skills** @53eb5a2, MIT (5): threejs-procedural-fields (terrain / biome fields), threejs-volumetric-clouds, threejs-atmosphere-aerial-perspective, threejs-procedural-vegetation, threejs-procedural-architecture. Its other 19 skills were not installed. These folders carry example assets, about 40 MB in total.
- **Run `/reload-skills`** (or restart Claude Code) so these show up. A subagent cannot do that itself.

### Research → `docs/research.md`
- §a covers balloon flight: the FAA 4 s standard burn every 25–40 s, burner lag, the parachute vent, 1–4 m/s climbs, wind veering with altitude (Albuquerque box), dawn/dusk flights. It ends with a physics tuning table.
- §b covers terrain, village and clouds in three.js. It ends with a decision list (6 km tiled heightfield + LOD, instanced props, merged village blocks, painted cloud sprites at 3 heights, uber-shader haze).
- §c covers calm and wonder research (ART / soft fascination, awe, Ulrich, nature sound, colour arousal, fractal fluency), with design ideas for each.

### Reference photos → `refs/` (git-ignored, critics only)
11 Wikimedia Commons photos (~2 MB), each opened and checked. Licences and URLs are in `refs/SOURCES.md`. They cover golden-light aerials over villages, fields and a lake, sunrise mass ascensions, and a sunset silhouette.

### Scaffold
pnpm, three 0.186.1, @types/three 0.186, typescript 7.0.2, vite 8.3.5, playwright 1.64.1. Base `./`, dev 5441 / preview 5440 strictPort. `index.html` holds only `<canvas id="game">` plus an inline SVG favicon (no text).

### Files
- `src/main.ts` boots the scene (new).
- `src/core/tier.ts` holds the quality tier (new, replaces BR platform TIER). Also `core/rng.ts`, `core/input.ts`.
- `src/render/` holds materials, todUniforms, cloudPaint, post, paint, mrtSplit, precompile, lightpasses, leafAtlas, gpucaps.
- `src/world/` holds sky, skyDome, timeofday, geo.
- `src/flora/` holds glsl, trees.
- `src/sound/` holds dsp, kit, air. They are not wired up yet.
- `src/capture/gpucheck.ts` (not wired up yet).
- `scripts/shoot.mjs` and `scripts/lib/harness.mjs`.
- `docs/research.md`, `docs/REUSE.md` (the full reuse table, with reasons) and `refs/SOURCES.md`.

### What the scene is now
- The full Bay Ride look: sky dome, painted cumulus, distant ridges all round, toon uber-shader, Kuwahara paint, ink, bloom, warm grade, SMAA/CAS, adaptive res.
- A flat 14 km green ground plane (`M.ground` paint) with height-aware haze.
- 5 small test groves of reused trees near the origin, casting sun shadows.
- Golden is the default time. Wind (`G.uWindDir`) points east. Scale changes for the 6 km world: cloud field ×2.5, ridges ×3.6, fog ×0.4, `uFogH` 220 m, camera far 16 km / near 0.5, ink fade scaled with altitude.

### `window.__game` API (exact)
```ts
__game.ready: Promise<void>                 // programs compiled + 4 frames drawn
__game.setCamera(pos: [x,y,z], target: [x,y,z]): void   // world metres, y up
__game.setTime(name: string, instant = true): boolean   // sunrise|golden|sunset|blue (also goldenhour, bluehour, dusk, morning, dawn)
__game.pause(on = true): void               // freeze/run the clock
__game.setClock(seconds: number): void
__game.frames(n: number): Promise<void>     // resolves after n more rendered frames
__game.presets: readonly ["sunrise","golden","sunset","blue"]
__game.time: Preset                         // current preset (getter)
__game.stats(): { calls, tris, programs, scale }
__game.renderer(): string                   // UNMASKED_RENDERER_WEBGL
```
URL params:
- `?time=` (or `?tod=`): sunrise | golden | sunset | blue.
- `?seed=`: grove layout.
- `?t=<s>`: frozen clock at s seconds.
- `?capture=1`: preserveDrawingBuffer.
- `?gpu`: logs the adapter.
- `?mobile=0|1`, `?tier=k:v,...`.
- Bay Ride's `?res=`, `?paint=`, `?kuwahara=0`, `?msaa=`, `?mrt1`.

### `scripts/shoot.mjs`
`node scripts/shoot.mjs <name> [--time=golden,sunrise,...] [--spots=ground,50m] [--seed=1] [--t=12] [--url=...] [--nobuild] [--allow-software]`
1. Runs `pnpm build` as an attached child at below-normal priority. `--nobuild` skips it.
2. Serves `dist/` in-process with vite preview on 5440 (`--url` uses your own server).
3. Launches installed Chrome headless (bundled Chromium as fallback) with the brief's GPU flags.
4. Prints the WebGL renderer and aborts on swiftshader / llvmpipe / software / basic render.
5. Opens `?time=..&seed=..&t=12&capture=1` and waits for `__game.ready`.
6. For each spot: `setCamera`, wait 8 frames, write `shots/<name>/<spot>[_<time>].png` at 1600x900.
7. Shader compile/link errors are fatal at once. Any other console error, warning or page error fails the run at the end.
8. Teardown (browser, preview server, build child) runs on exit, SIGINT, SIGTERM, uncaughtException and unhandledRejection (`lib/harness.mjs`).

Spots (the village will sit at the origin):

| Spot | Camera position (x, y, z) | Looking at |
|---|---|---|
| ground | (-150, 1.7, 230) | (0, 9, 0) |
| 50m | (-220, 50, 300) | origin |
| 200m | (-500, 200, 650) | origin |
| 500m | (-900, 500, 1200) | origin |
| down | (0, 300, 0) | straight down |
| basket | (-102, 250, 102) | origin, 60° down |

### Run results
- `pnpm build` passes.
- `node scripts/shoot.mjs p1` passes on `ANGLE (NVIDIA GeForce RTX 4060 … Direct3D11)`, with zero console errors. Ready in ~1.5 s, 13 draw calls, 0.24 M tris, 34 programs.
- `shots/p1/` holds all 6 spots × 4 times.
- Golden reads warm amber with cream painted cumulus. Sunset is pink-violet with lavender clouds, sunrise is teal with white cumulus, and blue hour has stars and a pink horizon band.

### Known issues / next
- Ground in golden reads olive (the warm key on green). The real terrain pass needs its own patchwork palette.
- The sky band ~15–30° up at golden is a greyish teal/amber mix, as in Bay Ride. It may want a cleaner gradient against the refs.
- Clouds are vertical camera-parallel cards around the origin at 140–475 m base height. From high up or looking down they read edge-on or are absent. The planned layered / rise-through clouds are new work (research §b, decision 5).
- The ridge rings start ~3 km out, the flat ground runs to 7 km, and there is no heightfield yet.
- The sun shadow map covers only ±160 m around the view focus, so from 500 m most ground has no shadows. It needs a cascade or altitude-scaled extent when the village exists.
- The sound modules are copied but not wired. There are no controls, balloon or HUD yet (as planned).
- `.claude/skills` is ~44 MB (example assets in the scottstts skills).

---

## Phase 2 — the world seen from the balloon (2026-11-03)

### What was built (all new code in `src/world/` unless noted)
- **`layout.ts`**: every hand-placed feature in world metres (x east, z south, y up, water at y = 0).
  - Map ±3000 (6 km). The heightfield and field map run to ±4000 (`GRID_HALF`), and a coarse far ring runs to ±11000.
  - Features: village centre (0,0) r 240, green, church, windmill hill (-390,-400), bridge (2,132), lake (700,-660), farm sites.
  - River and road control polylines go off every map edge.
  - Helpers: `SegIndex` (bucketed nearest-segment queries), `riverIndex` / `roadIndex`, `lakeDist`, `lakeShore`, `greenDist`.
- **`noise.ts`**: integer-hash value noise and fbm (deterministic).
- **`heightfield.ts`**: a 1281² grid at 6.25 m spacing.
  - Rolling fbm downs with rounded ridges.
  - A broad river floodplain (chamfer distance field).
  - A levelled village shelf, the windmill hill and the lake hollow.
  - The river channel and lake basin are carved below y = 0, and dry land never drops below +2.6 m. One flat water surface therefore shows exactly where the land dips.
  - `groundHeight(x,z)` uses the same triangle split as the mesh.
- **`parcels.ts`**: the patchwork fields.
  - Farm regions: a Voronoi of a jittered 560 m grid, with exact half-plane clipping.
  - Each region is cut recursively along its own slowly turning grain into fields: 6.7k parcels of big pastures, arable and narrow strips.
  - Crops: pasture, mown hay, wheat, barley, rapeseed, lavender, plough, stubble and young crop, plus woods, orchard and village.
  - Each parcel has a row direction and stock (sheep/cows). Shared edges carry the hedge flags.
- **`groundmap.ts`**: the field map, painted with Canvas 2D (4096², 2048 on the phone tier).
  - A (sRGB): parcel colours, headlands, lawns and gardens, yards, the green, the reed fringe, and hedge lines (the hedges' far LOD).
  - B: the road mask, blurred so the shader can rebuild a crisp edge at any zoom; mown and furrow amounts.
  - C: row angle and tramlines.
- **`src/render/landMaterials.ts`** (factory: COMMON/OUT/`toon()`/`applyFog()`, G and time-of-day uniforms).
  - `terrainMaterial()`:
    - field colour, with mown bands, furrows, tramlines and flecks all band-limited by fwidth and pixel footprint;
    - crisp dusty roads with verges, banks and slope earth;
    - a painted hill-shading ramp and a little vibrance against the warm key;
    - a procedural patchwork beyond the map.
  - `waterMaterial()`:
    - a deep teal body by real depth;
    - a painted sky reflection, with the planar mirror kept only where it shows objects;
    - footprint-faded ripples, glints, a pale shoreline lip and sun glitter.
- **`terrain.ts`**:
  - The heightfield goes to the GPU as an R32F texture.
  - 10×10 chunks share one patch geometry per LOD (steps 1/2/4/8, switching at 520/1300/2800 m). They are CPU-culled per chunk and instanced, so the land costs 4 draw calls. Skirts hide LOD cracks.
  - A far ring (125 m cells) carries the floodplain on.
  - The water is one merged flat mesh at y = 0 over every wet grid cell. Dry ground sits at least 2.6 m above it, so nothing z-fights.
- **`village.ts`**: `planVillage()` (data) and `buildVillage()` (meshes).
  - Cottages along every street and round the green: terraced near the heart, detached further out.
    - Pitched tiled roofs with eaves, gable overhangs and ridge caps; chimneys; some lower annexes.
    - Windows, doors and plinths are painted in the shader.
  - Fenced back gardens (lawn plus veg rows), and clumped trees in the gaps behind the streets.
  - The church: nave, chancel, tower with belfry slots, spire and gilded finial.
  - The windmill: tower, reefing stage, cap, and lattice sails turning at 0.45 rad/s.
  - The stone arch bridge: lofted deck, spandrels, arch soffit, parapets.
  - 12 farmsteads, each with a farmhouse, barn, shed, yard and groves.
  - 119 buildings in total: about 83 cottages plus 36 farm buildings.
  - All static geometry is one merged mesh with a near LOD and a far LOD (prism roofs, no chimneys), switched at 1.6 km.
- **`src/render/materials.ts`**:
  - Uber branch 3 is now clay/slate tiles, and branch 4 is a cottage wall with painted windows, door and night glow (`M.tile`, `M.wall` in geo.ts).
  - The shadow normal offset scales with the texel size.
- **`vegetation.ts`**: about 152k trees and 123k hedge pieces.
  - They live in 400 m tiles and are refilled into 14 InstancedMeshes only when the view changes.
  - Each form (broadleaf, poplar, conifer, bush) has one prototype in three LODs:
    - the reused Bay Ride card crowns (`flora/trees.ts`), under 210 m, capped at 520;
    - blob crowns, under 950 m;
    - faceted lumps, under 4.6 km.
  - The reused foliage shader (`flora/glsl.ts`) is now instancing-aware. It shades the near and mid LODs.
  - The far lumps and the hedges use the inked uber foliage, so woods and hedge lines read dark from altitude.
  - Placement:
    - dense woods, with conifers on high ground, ragged edges and a bush fringe;
    - hedgerows with the odd hedge tree;
    - river-bank and lake-shore groves;
    - orchards in rows;
    - lone field trees;
    - the village's own trees.
- **`life.ts`**:
  - 1123 sheep and 250 cows (brown, black, cream, ginger) in 72 pastures near the village. They drift slowly, updated on the CPU every other frame, each facing the way it drifts.
  - A horse hay cart and three cars move up and down the roads.
  - Chimney smoke: about 55% of chimneys smoke, 14 soft lit puffs each, rising and leaning downwind (computed in the vertex shader).
  - Two flocks of birds (40) wheel 70–95 m up. The uber's butterfly branch beats their wings.
- **`world.ts`**: `buildWorld(seed)` / `update(camera, t)`.
- **`main.ts`**:
  - The world replaces the flat ground and test groves.
  - The sun shadow map is 4096 and grows with altitude (`SunShadow.setHalf`, 160 → 900 m). Its focus sits on the real ground.
  - One half-resolution `PlanarReflection` at y = 0 serves both the river and the lake.
  - The `sky.ts` ridges moved out to 5.2–8.4 km, beyond the heightfield.
- **Scripts**:
  - `shoot.mjs`: the `ground` spot is now terrain-relative. There are extra spots `river` and `lake` (not in the default set), and extra stats are printed per spot.
  - New `scripts/probe.mjs "<expr>" [--shot=file]`: evaluates an expression in the built page, with the GPU asserted and full teardown.

### API added
```ts
__game.groundHeight(x, z): number   // terrain height (m); river/lake beds are below WATER_Y = 0
__game.stats()  // + parcels, houses, trees, hedges, cards, blobs, lumps, hedgeNear, hedgeFar, sheep, cows
__game.scene, __game.camera          // debug access for capture scripts
```
`?seed=` now seeds the world layout (heights, parcels, crops, village, flora, life). Shots use seed 1.

### Perf
**Measured under GPU contention**: the user was gaming during the whole phase, so these numbers are not trustworthy, and nothing was tuned on them. 1600×900, desktop tier, RTX 4060.

| Spot | Draw calls | Triangles | Frame time (run 1) | Frame time (run 2) |
|---|---|---|---|---|
| 200 m | 34 | 2.39 M | 12.9 ms (78 fps) | 19.5 ms (51 fps) |
| 500 m | 31 | 1.72 M | 9.8 ms (102 fps) | 14.1 ms (71 fps) |
| 50 m | 33 | 2.63 M | 13.0 ms (77 fps) | — |
| down (300 m) | 21 | 0.89 M | 5.5 ms (181 fps) | — |

- Draw calls and triangles are for the colour pass. Each frame also draws a normal pass, the shadow map and the reflection.
- Boot to ready takes about 4.7 s. World generation is about 1.5–2 s of that, on the main thread.

### Gauntlet
- `pnpm build` passes.
- `node scripts/shoot.mjs p2 --time=golden,sunrise,sunset,blue` writes 24 frames plus `river.png` and `lake.png` to `shots/p2/`.
- Every run printed `ANGLE (NVIDIA GeForce RTX 4060 … D3D11)` and logged no shader or console errors.
- About 8 shoot rounds of iteration. What changed:
  - hexagonal Voronoi fields → regional strip farming;
  - flat land → triple the relief, plus hill shading;
  - a river that read as a sand road → water;
  - a grey lake (gold and teal mixing) → blue;
  - an empty village core → trees and a working green ring;
  - mismatched card/blob palettes → one palette;
  - the noisy far tree count → cut;
  - dotted smoke → soft.

### Known issues / next
- **Perf:** unverified without contention. If it falls short of 90 fps at 1080p, the levers are:
  - the blob LOD distance (950 m);
  - the lump count (about 40k at 200 m);
  - the reflection pass, which draws blob trees;
  - the shadow map, which draws the near hedges and blobs.
- **No hill shadows:** the terrain casts none. Its height comes from a texture, and the shared shadow override material can't displace it.
- **Busy distance:** from 2–4 km the patchwork and tree lumps get busy before the haze takes over. Stronger far haze may help.
- **Tree tint:** blob trees in the foliage material barely take the sunset and blue-hour tint; they stay bright green.
- **Simple shapes:** houses are box-plus-roof volumes with painted windows, and the far LOD drops chimneys. Cows are blocky.
- **Fences:** garden fences are solid board strips that read as dark lines from altitude.
- **Clouds:** the Phase 1 clouds still sit at 140–475 m around the origin. Rise-through cloud layers are still to do.
- **Boot:** world generation runs on the main thread (about 2 s). It could move to a worker.

---

## Phase 2b — critic fixes for the world (2026-11-03)

This phase answers every item in `docs/critic/p2-world.md`. The item-by-item answer is in `docs/critic/p2-world-response.md`, and the new frames are in `shots/p2b/`.

### New files
- **`src/world/villageplan.ts`** holds the village as pure data on a 2 m occupancy grid.
  - The market square sits on the crossroads, with a cross, pump and stalls.
  - The green has moved to (-112, -82).
  - Joined terraces line the heart, with semis and detached houses further out.
  - Each house has a back garden plot of its own width, with an extension, a shed or greenhouse, and small trees.
  - Hedges and drystone walls bound the plots.
  - The churchyard has walls, a lychgate, a path, yews and graves.
  - The land behind the streets is filled with orchards, paddocks, allotments, barn yards, copses and meadows.
  - There are 4 barns per farmstead.
  - It exports `planVillage`, `HouseSpec`, `Rect`, `PaintOp`, `Bound` and `Prop`.
- **`src/world/villagemap.ts`** holds the village detail map.
  - It is a 3072² colour canvas (1536² on the phone tier) plus a 1024² coverage mask over ±400 m.
  - It paints the gardens, yards, square, green, churchyard and paths, and crisp lanes with verges and wheel tracks or a grass crown.
  - The terrain shader samples it through `LAND.uMapV`, `uMapVM` and `uMapVRect`, and it also suppresses the field-map road there.

### Changed files
- **`village.ts`** now holds only the meshes.
  - The near mesh carries the props, a two-tone bridge aligned to the road, and a lake jetty.
  - A new `village bounds` mesh (mask -1, no ink) carries the hedges, walls and graves.
  - The church and the windmill are separate meshes with a distance scale bias.
- **`layout.ts`**:
  - a meandering river with varying width;
  - a new `GREEN` position;
  - new `SQUARE`.
- **Look:**
  - the golden sky, fog, sun and clouds are retuned in `timeofday.ts`;
  - `applyFog` gets a sun-side warm / far-side lilac haze and eased-in optical depth;
  - sun shadows fade out at blue hour;
  - leaf crowns cast dappled shadow holes (`shadowDepthMaterial`);
  - the grade is more neutral and the paper grain lighter;
  - the ink fades and warms with distance.
- **Terrain shader:**
  - the detail map;
  - brush strokes, tussocks and colour drifts;
  - darker mud banks.
- **Water:**
  - a warm low-sky reflection;
  - warped ripples with no tiling;
  - a darker band under the banks, with no pale lip.
- **`groundmap.ts`**:
  - a lake mud strand and broken reed beds;
  - gravel bars on the river's inner bends;
  - lighter hedge lines;
  - `noRoad` polygons (the old `extraRoads` parameter is gone).
- **`vegetation.ts`**:
  - a varied tint spread;
  - no trees on the windmill hill;
  - hedge gates;
  - willow and alder river banks;
  - lake reeds and shore clumps;
  - per-tree `tint` taken from the plan.
- **`life.ts`**:
  - smoke that rises before it bends, pale and sunlit;
  - sheep with legs;
  - mostly cream and black cows.
  - `parcels.ts` now puts sheep in more pastures and paints a bald, pale mill hill.
- **`sky.ts`**:
  - clouds are higher, and their tone steps are softer (`cloudPaint.ts`);
  - the mountains are lilac;
  - the near ridges are painted hazy.
- **`scripts/shoot.mjs`**: new extra spot `vlow` (-90, 75, 95) → (15, 0, -25), low over the village heart.
- **Line endings:** all `src/` and `scripts/` files are now LF.

### Stats
- 482 buildings, up from 119.
- 23–37 draw calls.
- Ready in about 5.5 s.
- Frame times may have been taken under GPU contention, so treat them as unverified: `down` 7.9 ms, 500 m 11.5 ms, 200 m 17.5 ms, `vlow` 21.2 ms.

### Still open (partly fixed)
- **Lake:** it still reads pale blue-grey rather than peach from 170 m, and the reeds are weak at distance.
- **Ground spot:** the eye-level foreground grass is still plain. Real grass blades near the camera may be the next lever.
- **Horizon:** a hazy ridge band still stands on it.
- **Country roads:** they have no worn centre.
- **Market stalls:** they read as small dark marks from above.
- **Sunset trees:** blob trees stay bright green at sunset (an older known issue).

---

## Phase 3 — balloon, flight, wind, cloud layers, other balloons, cameras (2026-11-03)

### Part A: world blockers from `docs/critic/p2-world-r2.md`
- **N1, ridge discs:**
  - The near ridge bands no longer carry tree-mass blobs. The blobs sat a few metres apart at 5 km and z-fought there (24-bit depth only resolves ~3 m at that range), so they showed as see-through dark discs.
  - Each band is now one opaque silhouette.
  - In the uber `distant` branch (19), the lower ~170 m of each band mixes into the land's `applyFog()` at the same distance, with a brushed edge. The foot of the band melts into the terrain haze and the fog strip is gone.
  - `sky.far` (ridges and horizon cards) now follows the camera in x/z, since the balloon can drift kilometres.
- **N2, ink through clouds:**
  - The painted clouds (`cloudPaint.ts`), the new cloud layers, the cirrus and the whiteout write their coverage into the normal target's mask. This uses a new per-material `userData.normalBlend` (`mrtSplit.ts`, `CLOUD_NORMAL_BLEND`: mask = dst·(1−a) − a).
  - Where a cloud covers something, the mask ends up negative, so no outline is drawn through the cloud.
  - The horizon strata now sit inside the ridge ring (at most 4.9 km out), so no ridge top cuts a strip flat.
- **Nice-to-haves:**
  - Chimney smoke: 30 faint, overlapping puffs per chimney that fade early, so each chimney gives one soft wisp.
  - Water: it mirrors the warm low sky toward the sun with a saturation lift, and less of the cool body shows through.
  - Lake reed beds: denser and taller.

### Balloon model: `tools/balloon.py` → `public/models/balloon.glb` (806 KB, no Draco)
- Scripted in Blender 5.1 through the MCP tools, in its own scene `BalloonBuild`. The user's `Scene` was not touched and is the active scene again.
- To re-run it: `exec(open(r"F:/balloon-ride/tools/balloon.py").read())`.
- **Envelope:**
  - 20 gores on an inverted-pear profile: mouth r 1.45 m at 5 m, widest r 7.5 m at ~14.5 m, flattened crown at 20.5 m.
  - The cloth bulges between the load tapes, which show as darker columns on every seam.
  - The stripes follow the gores: red / cream / teal / cream.
  - A gold equator band with dark-red trims, a dark-red mouth band and a cream crown.
- **Other parts:**
  - a scoop skirt (longer at the back);
  - 16 flying wires to the frame corners;
  - a square burner frame on 4 suede-sleeved uprights;
  - twin burner cans with coils, nozzles and a valve block;
  - a 1.2 m wicker basket (tapered, inner walls, floor), with a leather rim and skids.
- Each part is its own mesh and material, coloured with face-corner vertex colours. The origin is the centre of the basket floor.
- **In game (`src/flight/balloon.ts`):** GLTFLoader, then `prep()` to the uber layout. Each part maps to a surface, an outline group and an ink mask:
  - envelope: cloth / boat id (warm shade, ink thins with distance);
  - basket: the new **`M.wicker` (29)** branch, an over-under weave in object space that fades before it aliases;
  - wires: no ink.
- **Variants:** 5 palettes (`PALETTES`), applied at runtime by remapping each vertex colour to the nearest palette slot.

### Flight (`src/flight/`)

**`physics.ts` `Flight`** is a heat model with a lag. The constants live in `PHYS`:

| Constant | Value |
|---|---|
| burnRate | +0.10 /s |
| ventRate | −0.08 /s |
| cooling | τ 25 s toward restHeat −0.06 (settles at a 0.36 m/s sink) |
| lift lag | τ 5 s (2 s while venting) |
| velocity inertia | τ 3 s |
| liftGain | 6 m/s per unit of heat |
| climb / sink | tanh-soft 4.2 / 3.6 m/s, hard +5 / −4 m/s |
| ceiling | burner fades over 800–1150 m, hard ceiling 1200 m |
| ground | cushion below 10 m, touchdown at most 0.3 m/s; the basket stays down until lift returns |
| sway | pendulum, 7 s period, at most 1.5°, kicked by the burner and by wind changes |
| yaw | slow turn, under 1 °/s |
| start | (−520, 120, 140) |

Probe results:
- A 4 s burn from level flight peaks at 1.33 m/s climb about 13 s later, then settles back into a slow sink.
- A 30 s burn from the ground reaches 3.5 m/s.

**`wind.ts`**
- Layers:
  - low (below 150 m): east, 2.5 m/s;
  - mid: north-east, 4 m/s;
  - high (above 400 m): north, 6 m/s.
- Heading and speed blend over ±40 m at each layer boundary (smoothstep).
- Gusts: ±10 % in speed and ±8° in heading, from noise with 11–33 s periods.
- Map edge: beyond 2.2 km from the centre the heading turns toward home, fully by 3 km. The player never sees this.

**Other modules**
- **`ride.ts`:** ties everything together each frame. While the burner is on, the new uber uniform `G.uGlow` (shaded by `glowLight()`) casts a flickering warm light on the envelope's inside, the skirt, the frame and the basket.
- **`Flame` (in `balloon.ts`):** two additive lathe tongues, blue at the root, gold in the core and orange at the tip. They flicker and swell from a 0.16 m pilot light to a ~2.3 m full burn.
- **`others.ts`:**
  - 5 balloons (palettes 1–5) at 80 / 210 / 330 / 480 / 700 m, starting 450–2000 m from the player.
  - Each drifts with its own layer's wind and bobs gently.
  - The 210 m balloon burns for 3.5 s every 22 s.
  - A balloon more than 3.2 km from the player slips round to the far side, 2 km out.
- **`windfx.ts`:** 260 dandelion tufts and sun-catching motes in a 72 m box that wraps round the camera. Each one drifts with the wind of its own altitude, plus some swirl, so a climb or a sink streams them past.
- **`cameras.ts`:**
  - **chase:** orbits the envelope centre at 52 m. Drag orbits (smoothed), the wheel zooms between 30 and 95 m, and the camera stays above the ground.
  - **basket (V):** the eye stands at the middle of the side it faces, shifted toward one corner so that corner's upright and wires frame the view, and the rim sits at the bottom. As the look turns down, the eye leans out over the rim. Near plane 0.06, fov 68.
  - **free:** used by `setCamera`.
- **`controls.ts`:** keys, the hint and the touch buttons.
- **`audio.ts`:** a synthesised burner roar and vent hiss. They start on the first user gesture.

### Cloud layers (`src/world/cloudlayers.ts`)
- **Low puffs:** 70 clouds, base 250–330 m, 22–32 lumps each.
- **Mid cumulus:** 34 clouds, base ~600 m, 26–36 lumps each.
- **Geometry:** real 3D heaps of noise-bumped icosphere lumps, one instanced draw call per layer, pressed flat at the base.
- **Painted shading:**
  - normals blended toward the cloud's overall envelope;
  - a cool lilac shade one step below the palette's low tone;
  - each bump's underside in shade, with shaded seams between bumps;
  - a warm bounce on the shaded flanks and the base;
  - a rim light on the outer silhouette;
  - a soft edge (alpha to coverage) on the outer outline only.
- **Drift:** each layer moves with its own wind and wraps round the camera (period 8–9 km).
- **Cirrus:** 26 combed streaks at 1700 m.
- **Whiteout:** inside a cloud the view fills with a soft, drifting white (`Clouds.whiteout`) that clears as you come out the other side.
- **Cloud shadows:** the 24 nearest clouds cast shadows on the terrain along the sun direction (`LAND.uCloudSh`). They are soft ellipses, stretched long when the sun is low, and they fade out at dusk.

### Controls
| Input | Action |
|---|---|
| Space (hold) | burner (touch: right button) |
| S or ↓ (hold) | vent (touch: left button) |
| V | switch between basket view and chase view |
| T | next time of day |
| H | toggle a tiny controls hint (bottom left, hidden by default) |
| mouse or touch drag | orbit (chase) or look around (basket) |
| wheel | zoom |

### API added to `window.__game`
```ts
__game.flight.place(x, y, z)            // basket floor at world xyz, level flight, cameras snap
__game.flight.alt(m, x?, z?)            // m above ground
__game.flight.yaw(deg)                  // basket heading
__game.flight.state()                   // { pos, vel, heat, lift, agl, grounded, burner, yaw, view, whiteout }
__game.flight.burner(on | null)         // force the burner (null = keys)
__game.flight.view("chase" | "basket" | "free")
__game.flight.chase(yawDeg?, pitchDeg?, dist?)  /  chaseToward(x, z, pitchDeg?, dist?)
__game.flight.look(yawDeg, pitchDeg)    /  lookToward(x, z, pitchDeg)   // basket view
__game.flight.nearestCloud(layer, x, z) // { x, z, base, top, w } as drawn now
__game.flight.others() / resetOthers(x, z)
__game.flight.physics, __game.flight.wind  // PHYS, WIND_LAYERS
__game.ride                             // debug: the Ride (flight, clouds, cams, ...)
__game.setCamera(...)                   // now also switches to the free view
```

### `scripts/shoot.mjs`
- A spot is either a fixed camera or a page script that flies the real balloon.
- Default spots:
  - `ground`: on the ground, looking up at the balloon 50 m up.
  - `50m`, `200m`, `500m`: chase view toward the village.
  - `down`: basket view, straight down from 300 m.
  - `basket`: the V view at 250 m.
  - `cloud`: just above a low puff.
  - `burner`: looking up into the mouth at full burn.
- Extra spots: `incloud`, `river`, `vlow`, `lake`.

### Gauntlet
- `pnpm build` passes.
- `node scripts/shoot.mjs p3` passes on `ANGLE (NVIDIA GeForce RTX 4060 … D3D11)`, with no console or shader errors.
- 5 shoot rounds. Fixes per round:
  - Basket view: an upright stood in the middle of the frame. The eye now sits at the middle of a side, and the basket yaws.
  - Clouds: they were flat cream blobs. They now have a lilac shade and shaded seams between bumps, and the haze on them is gentler.
  - Basket weave: a vertex-colour chequerboard, replaced by the wicker shader.
  - Skirt: a black box, now dark red, and it takes the flame's glow.
  - Flame: a white glare, now blue, gold and orange.
  - River: read as a pale road, now reads as water.
  - Water at sunset: hot pink, toned down.
- **Perf** (may have been measured under GPU contention, so not tuned from):
  - 37–77 draw calls and 1.8–4.1 M triangles, of which the cloud lumps (icosphere detail 2) are about 0.9 M.
  - Ready in about 5.5 s.

### Known issues / next
- **Cloud silhouettes:** close up, the icosphere facets still show. A near/far lump LOD would fix this and also save about 0.6 M triangles.
- **Cloud shadows:** the ellipses are approximate, and only the terrain receives them. Trees, houses and water do not.
- **Envelope teal:** reads sage under the warm key light.
- **Not started:** cinematic C mode and `record.mjs`.

---

## Phase 4 — critic p3 fixes, audio, time of day, hint, mobile, cinematic, recording (2026-11-03)

### Part A: blockers from `docs/critic/p3.md`
- **C1 (far cumulus cut flat on the ridges):** those were the painted backdrop cards (`sky.ts`), whose flat bases sat on the horizon from altitude. The card meshes now rise with the camera (`Sky.follow`, `0.95 × (camY − 30)`), so they keep the place on the sky they were laid out for from the ground.
- **C2 (faceted cotton balls / flat cut-outs):** `cloudlayers.ts` rewritten. Each lobe is a **ray-traced sphere impostor** on a camera-facing quad (perfectly smooth at any distance), clipped by the cloud's wavy base plane (a flat, mottled lilac underside seen from below), with a ragged soft rim a few pixels wide (`fwidth`-based), `gl_FragDepth` at the true surface. Lobes are blended back to front (CPU sort each frame, culled behind the camera), so billows melt into each other instead of meeting along creases. More, smaller lobes (low 34–46, mid 52–68). Lit cream tops, lavender shade, billow-underside shade and soft seams, warm bounce, rim.
- **C3 (in-cloud veil):** the whiteout is a per-pixel view-ray fog: luminous white, warmer toward the sun, brighter overhead, with slowly drifting 3D-noise density. Fully opaque once inside (nothing shows through); clears as you pop out above.
- **D1/D2 (festival):** five patterns painted per triangle from the envelope's gore/height coordinates (`balloon.ts PATTERNS`): blue/yellow chevrons, rainbow gores, red/white gores, green with gold diamonds, purple/orange spiral. `others.ts` lays them out in a fan ahead of the view at 300 / 520 / 800 / 1150 / 1600 m, at heights relative to the player, with a soft leash (they wander but keep company). `__game.flight.resetOthers()` re-fans them for the current view (all shoot spots call it).
- **E1 (`down` rim like a roof):** in-game padded suede rim roll (quilted pillows, ink) and coiled handling ropes (`rigging()` in `balloon.ts`); the down view's eye sits just past the rim near a corner, so the rim corner, inner wall and rope coil frame the bottom of the shot.
- **E2 (basket view):** eye well inside the basket (both corner uprights frame the view), default pitch −24°, fov 72; new wicker shader (continuous round cane weavers bulging over stakes, no brick joints), honey-brown tone. The burner frame itself sits ~65° overhead and only shows when you look up.
- **L1 (river road-coloured in `down`):** steep views reflect the saturated zenith sky over the teal body (`waterMaterial`), saturation lift 1.3 → 1.15 (also tames the pink sunset river).
- Nice-to-haves: matte envelope (cloth branch for the envelope: rim 0.22, hard terminator), truer teal (`PLAYER_PALETTE`), basket weave.

### Part B
- **Audio** (`flight/audio.ts`, `sound/voices.ts`; birds copied from Summer Cycle, wind is the reused `air.ts`): pulsing burner roar (brown + band noise, 6.7 / 2.3 Hz flutter), ignition whoosh, falling tail; vent hiss; wind rising with altitude and speed; chirps/trills/warbles low over the fields, skylarks, sparse at height; rounds on a ring of six church bells (bell partials, doublet beats, long decay, reverb) every 70–140 s within ~2.3 km of the village; quiet wicker creaks. Master 0.55, starts on the first gesture, **M** mutes.
- **Time of day:** T cross-fade is now 3 s. Sunrise has valley mist (`uMist`, in `applyFog`: low ground, soft banks, thicker with distance). Blue hour: stars, lit windows, burner glow on the skirt.
- **H hint:** small italic serif, translucent pill, bottom-left, hidden by default (above the burner button on touch).
- **Mobile:** burner (flame) bottom-left, vent bottom-right, small V (eye) button above the vent; hold to act, drag elsewhere to look; safe-area insets; phone tier: DPR cap 1.75, `TIER.flora` 0.55 (tree/hedge distances and card cap), 1024 shadows. `scripts/mobile.mjs <name>` emulates iPhone 13 portrait + landscape, holds the burner (asserts the flame lights): `shots/p4/mobile_portrait.png`, `mobile_landscape.png`.
- **Cinematic (C)** (`flight/cinematic.ts`): 50 s, centripetal Catmull-Rom camera and target curves through 8 key shots, timed by a monotone cubic (eased at both ends). Close on the roaring burner → pull back → round behind the balloon to reveal the village, river and festival → out over the golden fields → wide. Balloon flies a scripted drift east with a ~100 m climb; burner bursts at 0–6.5, 23.5–27.2, 39.5–42 s; the flame level is a pure function of time. C again exits (flying on from there, chase view). `?cinematic=1&time=golden` starts it at boot. API: `__game.cinematic.{start(), stop(), duration, running, seek(s)}`; `seek` switches to on-demand frames and draws exactly the frame at s with a 1/60 s step.
- **`scripts/record.mjs`:** builds (unless `--nobuild`), serves, headless Chrome with the GPU flags + assertion, `?cinematic=1&time=golden&t=12&res=1`, seek per frame, CDP JPEG → ffmpeg stdin (`h264_nvenc -preset p5 -cq 19 -b:v 0 -pix_fmt yuv420p`, 1920x1080, 60 fps) → `recordings/balloon-ride-cinematic.mp4`. ffmpeg is attached at below-normal priority and owned by teardown (partial output deleted on failure). No frame folder.

### Known issues / next
- Sunset river still leans pink; mid cumulus seen from just below at sunset are a muddy mauve.
- Cloud lobe sorting is per lobe on the CPU (~6k lobes); fine on desktop, untested on real phones.
- Audio is not in the recording (optional; would need an OfflineAudioContext render).
- Recording run: 3000 frames, 50.0 s, 1920x1080, 60/1 fps (ffprobe), 45 ms/frame, 134 s, 246 MB at cq 19.

---

## Phase 5: final fixes, re-record and ship (2026-11-03)

### Part A: the blockers from `docs/critic/p4-final.md`
Full write-up: `docs/critic/p4-final-response.md`. New frames are in `shots/p5/`.

| Blocker | Fix |
|---|---|
| **B1** (`down` had no clouds) | A new `low wisps` layer (base 140–185 m, 90 scud puffs, most with one or two smaller companions). The `down` spot searches the frozen clock (deterministic) for a wisp under the basket and a shadow in view. Cloud shadows now have a fixed ~30 m painted edge and a deeper cool shade; before, big shadows were smeared over hundreds of metres and invisible. |
| **B2** (blurry flat-based slabs) | Lobes are spheres on top and squashed half-ellipsoids below (rounded bottoms, no cut plane). The rim is pixel-based (no 6 %-of-radius blur). The distance fade is a shrink with opaque alpha. Haze is lighter. The 500 m spot pitches 16° (mid cumulus whole, not sliced). The cinematic ends at 420 m, above the low puffs. |
| **B3** (flat sunrise puff) | A painter's key swings aside when the sun is behind the viewer. The sunrise mid and low cloud tones are a real step darker. |
| **B4** (glossy blue backdrop, pink blotches) | `cloudPaint.ts` night factor: no warm underside band or silver lining, a weak rim, matte tones, cool dusk haze, never brighter than the sky behind. |
| **B5** ("windmill" starburst) | It was a dandelion tuft (`windfx.ts`) about 1 m from the lens. The fluff now fades in from 5 to 11 m and nearly vanishes at night. The windmill was fine. |

### Part B: the recording
`recordings/balloon-ride-cinematic.mp4` is h264 (h264_nvenc, cq 19), 1920x1080, 60/1 fps, 3000 frames, 50.0 s, 246.6 MB. The frames at 2, 20 and 48 s were viewed, then deleted. The 48 s frame now looks down on a shaded puff over the village.

### Part C: ship
- **OG image:** a new `og` spot in `shoot.mjs` (1200x630, golden hour, the balloon over the village, the river and the fields) also copies itself to `public/og.png`. `SIZES` gives a spot its own viewport.
- **`index.html`:** title, meta description, og:* and twitter:* tags (absolute og:image URL), plus the existing SVG favicon.
- **Repo files:** `README.md`, `LICENSE` (MIT, copied from Bay Ride), `.gitignore`, `.github/workflows/deploy.yml` (pnpm, Node 22, upload-pages-artifact from dist, deploy-pages), and `pnpm record`.
- **Not committed:** node_modules, dist, refs, shots, recordings/*.mp4, scratch files, .claude/settings.local.json.

### Perf (golden, 1600x900)
- 50–107 draw calls and 0.4–3.9 M triangles.
- The wisps add a few thousand impostor lobes to the per-frame CPU sort.

### Deploy
- **Repo:** https://github.com/StarKnightt/balloon-ride (public, branch `main`). Topics: threejs, webgl, game, hot-air-balloon. The homepage is set to the Pages URL.
- **Pages:** the source is GitHub Actions (`deploy.yml`). Run 41618304058 succeeded.
  - These return 200: https://starknightt.github.io/balloon-ride/, `/og.png` (1200x630 PNG) and `/models/balloon.glb`.
- **Live check:** the live URL was loaded in headless Chrome with the GPU flags (renderer `ANGLE (NVIDIA GeForce RTX 4060 … D3D11)`).
  - It boots to `__game.ready`.
  - The page title is "Balloon Ride".
  - `models/balloon.glb` loads with a 200 through the relative base path.
  - There are 0 console errors or warnings and no failed requests.
- **Manual step left:** GitHub has no API for the repo social preview. Upload `public/og.png` once in Settings → Social preview.
- **Actions notice (not an error):** some actions (checkout, setup-node, pnpm/action-setup) still target the deprecated Node 20 runtime, and GitHub forces them onto Node 24.

---

## Phase 6: R1 from `docs/critic/p5-final.md` (2026-11-03)

### R1: the pillow cloud over the cinematic reveal
- **Cause:** at c20 and c23 the "pillow" was a low wisp (base 140–185 m) only 20–90 m from the lens, plus a low puff about 350–450 m away.
- **Path kept clear:** `Clouds.keepOffPath()` (in `cloudlayers.ts`) runs once when the cinematic starts (`main.ts` `toggleCinematic`).
  - It samples the camera path every 0.5 s over 10–30 s, at the clock times those frames will play.
  - Any cloud that would come within 450 m of the lens while inside the frustum sits out the whole flight. That means no draw, no shadow and no whiteout.
  - Clouds are chosen once, so nothing pops mid-shot. Leaving the cinematic clears the list.
  - The far puffs and backdrop stay, so the sky is still layered.
- **Near clouds are never featureless:** the lobe shader gets a `near` factor (1 below 250 m, fading out by 1400 m). Close to the lens:
  - lobe normals take over from the envelope normal;
  - the cauliflower seams and lobe undersides are deeper;
  - each lobe gets its own tone;
  - the lower body and the base get brushed shade patches;
  - the shade is painted with lilac washes, lobe by lobe. Without them the shading bands clamped the breakup away in the shade.
  - Result: the near puff at c48 now shows separate billows, crescents and shaded undersides all the way down.

### Nice-to-have: ink lines through a cloud in `mobile_landscape`
- **Cause:** the phone tier draws the scene in one two-target pass (`singlePass`), so the clouds' normal-target blend never applied. That blend drives the ink mask negative where a cloud covers.
- **Fix:** on that tier, the materials that carry `userData.normalBlend` adopt it as their own blend. Colour alpha is never read.
- **Also changed:**
  - The clouds' mask now goes negative from about 1/3 coverage.
  - Distance fading is a shrink (alpha is `min(1, f*12)`, it was `f*3`).

### Verified
- **Recording:** `node scripts/record.mjs` wrote `recordings/balloon-ride-cinematic.mp4` (h264 NVENC, 1920x1080, 60/1, 50.0 s).
  - The frames at 15, 18, 20, 23 and 25 s were viewed, then deleted.
  - The village, the river, the bridge and the festival balloons are clear, with puffs and banks only far off.
- **`shots/p6`:** the down, 50m, 200m, 500m and basket frames still show houses, fields, roads, the river and layered clouds.
- **`mobile_landscape`:** the top-right cloud is opaque, with no lines through it.
- **GPU:** RTX 4060 (D3D11) was asserted on every run.
- **Deploy:** commit 4f71216 was pushed to main. The push did not start a Pages run, so it was dispatched by hand: run 41620829973 succeeded.
  - https://starknightt.github.io/balloon-ride/ returns 200.
  - The live page was loaded headless on the GPU (RTX 4060, D3D11). It boots to `__game.ready`, `keepOffPath` is present, and there are 0 console errors and 0 failed requests.

---

## Phase 7: the pilot (2026-11-03)

### The character
- **New, original pilot** (`tools/pilot.py`, run in Blender through the MCP: `exec(open(r"F:/balloon-ride/tools/pilot.py").read())`; set `PILOT_EXPORT = False` first to build without exporting). A young balloon pilot, about 1.65 m: ginger bob with a scalloped fringe and soft locks, brass goggles with teal lenses pushed up on her hair, brown leather flying jacket with a cream fleece collar and dark knit cuffs and hem, a long red scarf with cream stripes (neck wrap, knot, a short front end and a long back tail), mitten hands with a separate thumb, navy trousers and boots (hidden by the basket).
- **Face:** a 512 px texture painted in the script (numpy), projected onto the front of the head: tall dark-brown eyes with a warm low glow, two catch lights and a fine upper lash line, soft brows, rosy blush, four freckles on each cheek, a small nose stroke and a smile. Proportions and the treatment (simple eyes, blush, toon bands, warm ink) follow Summer Cycle's rider and Bay Ride's heroine; no mesh, rig or face was copied.
- **Mesh:** lofted tubes with a Catmull-Clark level applied, about 15.1k triangles, 10 meshes, one material each (face, skin, hair, jacket, trousers, scarf, goggles, lever), vertex colours for albedo. The burner's blast-valve lever (a T handle hanging from the valve block) is part of the GLB, on its own bone.
- **Rig:** root, hips, spine, chest, neck, head, and on each side shoulder, upper arm, forearm, hand, thigh and shin. There is a 5-bone scarf chain and the lever bone. The weights are scripted per part, each part on its own allowed bones with blends at the joints, and the parts are then joined. The arms run on IK: `ik_R` rides on the lever and `ik_L` rests on the front rim, with poles. The hands copy the targets' rotation, and the exporter samples the result.
- **Clips (30 fps):**
  - `idle` (4 s loop): breathing, a small sway, the head looking about, the right hand on the lever and the left resting on the front rim.
  - `lookOver` (6 s): the right hand goes to the rim, she leans on it and looks down over the edge, looks left and right, then comes back.
  - `burner`: the pull runs 0–0.4 s, the hold loops 0.4–2.4 s, and the release runs to 2.87 s. The lever rotates 13° and her head tilts up toward the flame.
  - The scarf waves in every clip on a 2 s period, so the clips loop seamlessly.
- Every clip was checked with Blender's `look` against an imported reference basket (`REF_*` objects in the `PilotBuild` scene, never exported).
- **`public/models/pilot.glb`:** 732 KB, skinned (24 joints), 3 animations, the face PNG embedded.

### In game (`src/flight/pilot.ts`, wired in `ride.ts`)
- The GLB root sits at the balloon model's origin (her armature at basket (0.14, 0.05, 0.08) m, facing the model's +Z), so it is added straight to the player's balloon model. The rim (1.12 m) meets her waist.
- **Materials:** the uber toon with skinning (SKIN_VS).
  - Skin (ID 18) and hair (ID 14) use the RIDER variant, for the moonlit night shading.
  - Jacket (22), trousers (23), scarf (24) and goggles (13) use the plain uber, so they take the burner glow.
  - The lever uses the frame's metal and ink.
  - The face is a small new shader: the skin toon with the face texture masked to the bind-pose front, with herShade and the burner glow.
  - She gets her own copy of `uGlow` at 0.35 of the balloon's. At full strength her collar and face blew out under the nozzles. The face gets 1.8× that after dusk.
  - Character IDs give her the warm brown ink. Shadows and reflections come from the layers.
- **AnimationMixer** on game time, so frozen captures are deterministic.
  - `idle` plays by default.
  - Burner held (Space or the touch button, read through `flight.burner`): pull, then hold (looped), then release on letting go, with cross-fades.
  - `lookOver` plays every 14–26 s of idle, and after 1.2 s in the V view when it pitches below −43° (9 s cooldown).
  - The flame and roar still follow the input only.
- **V basket view:** only `forearm_R`, `hand_R` and the lever are drawn, so her head and body never block the eye. The third-person and cinematic views show all of her.
- **API:** `__game.pilot.pose(clip, s)` freezes her on a clip (`idle`, `lookOver`, `burner`, `pull`, `hold`, `release`). `pose(null)` resumes the live state machine. `clips()` and `tris()` are also available.
- **Unchanged:** the world, the balloon, the clouds, the other balloons, the cameras, time of day, the mobile UI and audio.

### Shots (`shots/p7`)
- New spots, added to the default set:
  - `pilot`: a close three-quarter view, golden hour, idle with her hand up on the lever.
  - `pilot_burner`: mid-hold on the lever with the burner firing.
  - `pilot_look`: from outside the basket just below the rim, leaning on it and peering over.
- These spots yaw the basket 150° so her front takes the sun.
- The shoot harness now resets the pilot (`pose(null)`) before every spot.
- **Old spots:** `basket` and `down` match p6 apart from the pilot (hidden in the V view). The chase spots show her as a small figure in the basket.
- `pnpm build` passes. `node scripts/shoot.mjs p7` ran on the RTX 4060 (D3D11) with no console or shader errors.
- **Live state machine:** checked in the page (unpaused). It ran idle → pull → hold, then release → idle on letting go, then lookOver in the V view looking down, then back to pull on the burner.

### GitHub Pages trigger (found this phase)
- **Not the cause:**
  - Actions is enabled (`allowed_actions: all`).
  - The workflow is `active`.
  - The YAML is valid (`on: push: branches: [main]`, ASCII, no BOM).
  - Pages is set to build from GitHub Actions.
  - There are no rulesets.
  - No commit message contains `[skip ci]`.
- **What happened:** the three pushes (10:20, 10:34 and 10:38 UTC) appear in the repo activity, by StarKnightt. None of them produced a `github-actions` check suite, although the Vercel, Netlify and other apps did get suites. Actions never registered the push trigger for this workflow: it was created in the same push that created the repo and the branch.
- **Fix:** the workflow was re-registered (`gh workflow disable` then `gh workflow enable`, id 405556422). This cannot be confirmed until the next push to main. If that push still starts no run, the fallback is a trivial edit to `deploy.yml` in that push, which makes GitHub re-index the triggers.
- Nothing was committed or pushed this phase.

### Next
- The critic compares the pilot against the Summer Cycle and Bay Ride character frames.
- After PASS: rebuild, redeploy, and re-record the cinematic with her in it.

### Pilot fix pass (critic `docs/critic/p7-pilot.md` FAIL → `docs/critic/p7-pilot-response.md`)
- **Elbow:**
  - The right sleeve is now one dense tapered tube, split 7 cm past the elbow with shared custom
    normals (`forearm_R` stays separate for the V view).
  - New `elbow_L/R` helper deform bones (half the forearm's rotation) carry a 16 cm smoothstep band of
    the sleeve.
  - The poles are animated (`POLE_R_REST` → `POLE_R_UP`).
- **Poses:**
  - **Idle:** both hands on the front rim's leather roll.
  - **Burner** (3.3 s): reach 0–0.45 s, pull the lever 10 cm down (the rod slides through a fixed
    bushing) to 0.7 s, hold loop 0.7–2.7 s, release to 3.3 s. Chin up to the nozzle, the left hand
    bears on the rim.
  - `pilot.ts` subclips are now 21/81 frames. In the V view her forearm and hand show only while the
    arm is up on the lever.
- **Glow:**
  - The face shader's burner light is a soft-clamped orange wash in one toon band, and only a little
    of it lifts the shade.
  - Her cloned uber materials get `toneGlow`: the emission is soft-clamped per brightest channel, and
    the shade is lifted at 15%. This is local to her materials; `materials.ts` is untouched.
  - The head is now a 48x28 sphere (the face "seam" was faceting under the toon step).
- **Collar:** its own `collar` mesh/material (ink id 13), warm cream `#d4b588`, a flat band turning
  into two lapels.
- **Cheap extras:** a waist and flared hem, tapered arms, warmer scarf stripes.
- **Model:** `pilot.glb` is 948 KB, about 20.7k polygons.
- **Shots:** `pilot_burner` is reframed from her right and below, with the flame in frame.
- **Checks:**
  - `pnpm build` passes.
  - `shots/p7b` ran on the RTX 4060 (D3D11). `basket`, `down` and `burner` are pixel-identical to
    p7. The chase spots differ only round her tiny figure.
  - The cinematic was re-recorded.
- **Cinematic opening (`cinematic.ts`, approved):**
  - 0–8 s is a close basket shot laid over the path: it holds to 2.5 s, then eases into the path by 8 s.
  - From 8 s on the path is identical. The 10/20/40 s frames match the previous recording to encode
    noise.
  - She pulls the lever under the flame from the first frame.
  - Re-recorded: 50 s, 1080p60, NVENC.
- Nothing was committed or pushed.
