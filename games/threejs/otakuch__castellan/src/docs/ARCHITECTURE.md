# Architecture

Notes for anyone opening the source. The short version: it is one closure, split into
ordered fragments, with a strict separation between *what the ground is*, *what has been
built on it*, and *who is walking about on it*.

---

## The build model

`build.mjs` concatenates `src/js/*.js` in filename order into `src/shell.html` at the
`/* @@BUNDLE@@ */` marker. There is no bundler and no module graph.

This means **the numeric prefixes are load-bearing**. Fragment 04 creates the terrain mesh,
so anything it touches must exist by then — which is why the texture atlas is fragment 03 and
not somewhere more logical. Two bugs during development came from exactly this: a `TEX`
reference that ran before `const TEX = {}` was evaluated, and a `dressWater` call that ran
before the canvas helpers existed. If you get *"Cannot access X before initialization"*, you
have put a fragment in the wrong place, not written bad code.

Run `npm run check` before committing. It balances braces across the bundle and verifies the
closure opens and closes.

---

## Fragments

| File | What lives there |
|---|---|
| `00-preamble` | the three.js guard and the opening of the closure |
| `01-helpers` | maths, the geometry and material caches, `box`/`cyl`/`cone` |
| `02-renderer-quality` | renderer, camera, quality tiers, device detection, shader-log policy |
| `03-surfaces` | the procedural texture atlas and the triplanar material patch |
| `04-terrain` | noise, `ground()`, the edit layer, the sculpting brush |
| `05-sky-water` | the sky shader, the PMREM environment map, the water shader |
| `06-materials` | the shared material set |
| `07-facing-arrows` | the ground arrows that show which way a piece faces |
| `08-build-registry` | `placed[]`, `build()`, `place()`, disposal |
| `09-architecture` | `lathe`, `batter`, `archWall`, `gable`, and the tower/wall/gate/keep |
| `10-pieces` | every other piece maker, `PIECES`, `MAKERS` |
| `12-scenery` | the forest: density field, acceptance sampling, instancing |
| `13-index-build` | reading `placed[]` into `idx`, the patrol graph, wall crossing tests |
| `14-ecs` | `EntityManager`, `ComponentManager`, `System`, `World` |
| `15-bodies` | figure and animal meshes, and how a population is derived from a build |
| `16-steering` | `seek`, `routeTo` |
| `17-systems` | routines, paths, grazing, patrol, flight, carts, gait, sync |
| `18-atmosphere` | wind, hearth smoke, the sky/day cycle |
| `19-world-wiring` | system registration order |
| `20-build-tools` | picking, the ghost, placement, sculpting, undo |
| `21-standard-plan` | the preset castle |
| `22-interface` | tabs, palette, census, the holding report, all the panels' handlers |
| `23-frame` | the frame loop, adaptive quality, keyboard camera |
| `24-music` | the synthesiser |
| `25-panels` | draggable, foldable, dismissible panels and the dock |
| `26-chronicle` | the generated legend and the running chronicle |
| `27-welcome` / `28-start` | the gate screen and boot |

(There is no `11`. It was the old scenery fragment and the gap is left deliberately, so the
numbers in this table keep matching the filenames.)

---

## The ground is one function

```js
ground(x, z) === baseGround(x, z) + editAt(x, z)
```

`baseGround` is a seeded fbm field with a second ridge octave, calmed toward the middle so
the site is buildable, plus an optional mount and moat. `editAt` bilinearly samples a
`Float32Array` with one cell per terrain vertex — the player's hand-cutting.

**Everything** reads this: the mesh, the water test, every agent's foot, the ghost preview,
piece foundations. Nothing keeps its own idea of the height. When a sculpt stroke ends,
`rebuildAll()` re-runs every placed piece's maker against the new ground, and the scenery
reseats, so nothing is left hanging in the air.

Terrain normals are analytic — central differences of `ground()` — rather than
`computeVertexNormals`, which is what makes partial patch updates during a brush stroke cheap.

---

## The piece model

A placed piece is a record, not a mesh:

```js
{ key, x, z, rot, flip, scale, a, b, group, meta }
```

`build(rec)` calls the maker and attaches the result. Because a record is enough to
reconstruct a piece, sculpting, the relief slider and the water level can all simply rebuild
everything.

`meta` is the contract between architecture and simulation. A cottage publishes a `door`; a
gatehouse publishes `front`, `mid` and `back`; a field publishes `spots`; a tower publishes
`top` and a `torch`. The simulation never looks at geometry — only at `meta`. That is why
scaling a piece requires `scaleMeta()` to move the door, the arrow and the smoke outward by
the same factor: otherwise a bigger cottage would have its door in the wall.

---

## The simulation

Components are plain records in per-type `Map`s. Queries are cached and invalidated whenever
the entity set changes. Systems run in a fixed order once a frame:

```
Clock → Routine → Path → Graze → Sentry → Flight → Cart → Labour → Gait → Sync
      → Wind → Hearth → Sky
```

Systems marked `always` (Wind, Hearth, Sky, Clock) tick with real time; the rest receive a
simulation delta that is zero when the day is held or you are in build mode. That is how
holding the day freezes the people while the banners keep moving.

The clock is a **singleton component with getters onto the interface's own variables**, so
there is exactly one hour in the program and no synchronisation to get wrong.

Routines run on a *working hour*, not the clock hour: `workHour()` maps the season's dawn and
dusk onto a nominal 06:00–19:30, so a winter day compresses everyone's schedule without a
single routine being rewritten.

---

## Routing

Two rules, both cheap:

- **Water.** `seek()` tests the candidate step; if it lands below the water line and not on a
  bridge, the agent turns instead of moving.
- **Walls.** `routeTo()` tests whether the straight line to the destination crosses any wall
  segment. If it does and a gatehouse exists, it inserts the gatehouse's front, middle and
  back as waypoints.

There is no navmesh and no grid. Consequences fall out of the geometry: a moat with no bridge
strands people, walls with no gatehouse are walked through, and a closed circuit funnels
everyone to one road.

The wall patrol is a small graph — wall endpoints within four units are the same node — and
guards random-walk it, so a closed circuit gets walked continuously and a dead end gets paced.

---

## Rendering

- `MeshStandardMaterial` everywhere, ACES tone mapping, physical light units (`LX = π`).
- Triplanar mapping via `onBeforeCompile`, with `customProgramCacheKey` so variants are not
  recompiled per material.
- Height is packed into the texture's alpha and turned into a normal perturbation with
  screen-space derivatives — no normal maps are stored.
- The sky shader also renders into a PMREM environment map every fourteen seconds, which is
  what stops metallic surfaces reading as black.
- Repeated geometry is `InstancedMesh`; the whole forest is seven draw calls.
- Quality tiers scale pixel ratio, shadow map size, population, scenery and smoke. Terrain
  resolution is fixed at load, because resizing the grid would invalidate the edit layer.

---

## Things that are deliberately not here

- **No persistence.** Layout, builds and terrain reset on reload. `localStorage` is
  unavailable in the environment this was first written for.
- **No navmesh, no pathfinding.** See above.
- **No post-processing chain.** Tone mapping and the environment map do the work instead;
  adding `EffectComposer` would mean pulling in three's addons.
- **No audio files.** All four instruments are synthesised.
