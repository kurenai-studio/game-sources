# Slowblue — Implementation Notes

## How to read this file

This is an engineering log, written in order as the game was built, and it keeps the failed
hypotheses next to the ones that worked because the reasons a thing was rejected cannot be
reconstructed later. Two kinds of section live here, and they age differently.

* **Current reference**, kept true as the tree changes: [Files created](#files-created) (the
  inventory), [How the mechanic is built](#how-the-mechanic-is-built-and-why),
  [Where to tune](#where-to-tune) and [Deliberate compromises](#deliberate-compromises-not-oversights).
  If one disagrees with the code, the code wins and this file has a bug.
* **History**, kept as written: [the tuning decisions](#tuning-decisions-that-came-from-measurement-not-taste)
  and the numbered passes after them (decisions 1-52). A number there is the number *then*;
  a paragraph since overtaken carries a **Superseded** note, and decision numbers are
  addresses (`tuning.ts`, `Medium.ts` and `Renderer.ts` cite them), so none is renumbered.

The current state lives elsewhere: [README.md](README.md) is the short version of the game and
[docs/GAME.md](docs/GAME.md) the long one, [docs/DEVELOPING.md](docs/DEVELOPING.md) is how to
run, test, measure and ship it, [docs/DESIGN-ASCENT.md](docs/DESIGN-ASCENT.md) is the seven-act circuit,
[docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md) the measured length of the campaign (432
sections, 144 authored minutes, act I frozen at ten), and [CLAUDE.md](CLAUDE.md) the working
rules. Two facts from them frame everything below: the web is the only target (the
Capacitor/iOS shell built in August is gone), and there is no settings screen - the audio
mixer is a drawer opened from a corner button, and the continuous-circuit mode and the profile
wipe live on the map.

## Contents

* [Where this started](#where-this-started)
* [Repository audit (start state)](#repository-audit-start-state)
* [Files created](#files-created) - the inventory, as of 2026-11-02
  ([config and tooling](#config--tooling), [simulation](#simulation-headless-no-dom),
  [presentation and platform](#presentation--platform),
  [tests, e2e and tools](#tests-e2e-and-tools))
* [How the mechanic is built (and why)](#how-the-mechanic-is-built-and-why)
* [Where to tune](#where-to-tune)
* [Tuning decisions that came from measurement, not taste](#tuning-decisions-that-came-from-measurement-not-taste) (1-10)
* [The second pass: from prototype to finished game](#the-second-pass-from-prototype-to-finished-game) (11-20)
* [The third pass: from endless course to campaign](#the-third-pass-from-endless-course-to-campaign) (21-37)
* [The fourth pass: the thing under the game](#the-fourth-pass-the-thing-under-the-game) (38-52)
  * [Act II health at the current defaults](#act-ii-health-at-the-current-defaults)
  * [Design health at the current defaults](#design-health-at-the-current-defaults)
* [The admin surface: examining a thing instead of playing to it](#the-admin-surface-examining-a-thing-instead-of-playing-to-it)
* [The map: the one thing the game said and never showed](#the-map-the-one-thing-the-game-said-and-never-showed)
* [Deliberate compromises (not oversights)](#deliberate-compromises-not-oversights)
* [Measured performance](#measured-performance)
* [The seven acts had one rhythm and one reward](#the-seven-acts-had-one-rhythm-and-one-reward)
* [What is still open](#what-is-still-open)

## Where this started

This started as a falsification prototype for one hypothesis: **steering water, not fish,
is a good game.** The hypothesis survived, so the second half of this document is the
record of turning it into a finished one — content that changes through one ascent, a shell
around the run, sound, an install target, and the rebalance all of that forced.

The structure of the record is unchanged: every balance number below came out of
`npm run sweep`, and the failed hypotheses are kept alongside the ones that worked.

## Repository audit (start state)

The working directory was **empty**: no files, no `package.json`, no README, and
`git status` reported *"not a git repository"*. There was therefore no existing stack,
architecture or convention to build on, and **no existing file was modified or deleted** —
everything listed below is new. Nothing was committed, pushed or deployed.

Stack chosen per the brief's default: Vite + TypeScript (strict) + Canvas 2D, minimal
dependencies, runs straight from a mobile browser. This is a prototype decision, not a
production technology choice.

> **Superseded: this section describes the first day, not the tree.** The prototype choice
> turned out to be the product: TypeScript + Vite + Canvas 2D is still the whole stack, with
> **zero runtime dependencies** (a rule now, in [CLAUDE.md](CLAUDE.md)), and the repository
> is under git, public, and published as an installable PWA on GitHub Pages. The tree has
> grown from the files below to 89 TypeScript modules under `src/`, 72 unit-test files in
> `tests/` (plus 8 shared helpers), 13 Playwright specs in `e2e/` and 14 files in `tools/`.
> The inventory in the next section has been brought up to date; the paragraph above is left
> as the record of where it began.

## Files created

This is the inventory of the tree as of 2026-11-02, grouped by what a file is *for*. It
started as the list of what the first session created; files added since are in the same
tables, and files that no longer exist have been removed from them (the two worth a mention
are `src/sim/Lift.ts` and `src/render/Thermal.ts`, which decision 45 deleted). Where a
description says what a file does, it was written from the file's own header comment.

### Config / tooling
| File | Purpose |
| --- | --- |
| `package.json` | Scripts (`dev`, `build`, `deploy`, `preview`, `lint`, `typecheck`, `test`, `e2e`, `screens`, `verify`, `sweep`, `icons`), dev deps only - **zero runtime dependencies**, which is a rule |
| `tsconfig.json` | `strict`, `noUnusedLocals/Parameters`, `exactOptionalPropertyTypes`, `verbatimModuleSyntax`; covers `src`, `tests`, `e2e`, `tools` and the configs |
| `vite.config.ts` | Dev server on `0.0.0.0:5173` (so a phone on the LAN can open it); `BASE_PATH` for a project page; hidden sourcemaps; a build plugin that writes the hashed asset list into the service worker's precache and fails the build if it cannot |
| `vitest.config.ts` | Node environment, `tests/**/*.test.ts` only, with a long per-test timeout because the playability probes fly whole campaigns synchronously |
| `vitest.sweep.config.ts` | Separate runner for `tools/**/*.sweep.ts` (`npm run sweep`), 15-minute timeout, so minutes-long experiments stay out of `npm test` |
| `playwright.config.ts` | 390x844 Chromium with touch at device scale factor 3, one worker, against the production build on `SLOWBLUE_E2E_PORT` (default 4173) with `--strictPort` |
| `eslint.config.js` | Flat config, `typescript-eslint` recommended + `consistent-type-imports` |
| `index.html` | `viewport-fit=cover`, `user-scalable=no`, safe-area probe, the shell's CSS. `touch-action: none` is on the canvas and **deliberately absent from `<body>`** - it intersects down the ancestor chain and killed scrolling in the shell |
| `brand.html` | Dev-only bench for the studio ident (`/brand.html` under `npm run dev`); never part of a production bundle |
| `.claude/launch.json` | Dev-server and preview definitions for the in-editor browser |
| `.github/` issue and pull-request templates, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE` | The public-repository furniture (MIT); there is deliberately no workflow under `.github/` |

### Simulation (headless, no DOM)
| File | Purpose |
| --- | --- |
| `src/core/math.ts` | `clamp`, `lerp`, `smoothstep`, `limitScale` (allocation-free vector clamp) |
| `src/core/rng.ts` | `Rng` (mulberry32) + `hashSeed`; seedable, forkable, reproducible |
| `src/core/GameLoop.ts` | Fixed-timestep accumulator, render `alpha`, FPS/slow-frame stats, `accumulateSteps` for tests |
| `src/core/storage.ts` | The one wrapper every persisted value goes through; a denied `localStorage` degrades, never throws |
| `src/config/tuning.ts` | `Tuning` type (45 numbers), `DEFAULT_TUNING`, slider limits, `sanitizeTuning` |
| `src/sim/FlowField.ts` | Grid velocity field: Gaussian impulse deposit, speed clamp, decay (optionally non-linear in speed), Jacobi diffusion, bilinear sampling, whole-cell world scrolling |
| `src/sim/AmbientFlow.ts` | The ocean's own current: curl of a two-octave stream function, divergence-free, analytic, seeded, tapered at the walls |
| `src/sim/CurrentField.ts` | Standing currents the course owns: exactly divergence-free vortices, sampled not simulated |
| `src/sim/LayeredFlow.ts` | Act III's medium: the upper air as deep horizontal layers moving at different speeds and in opposite directions, which is what actually carries a spore |
| `src/sim/PotentialField.ts` | Act IV's "stroke": with no medium left to push, a stroke lays a gravity well and the carried life falls around it |
| `src/sim/Medium.ts` | The medium as one number set - coupling, flow half-life, laid-flow speed cap, migration, held-cruise - so an act changes the medium rather than the code; water resolves to the exact fields act I always read |
| `src/sim/Breath.ts` | The 11-second breath (5.45 a minute) every bed and picture moves at, with rests at both ends and a longer out-breath |
| `src/sim/Agent.ts` | Agent record (pos, vel, prev-pos for interpolation, faction, species, variation, anchor) |
| `src/sim/SpatialHash.ts` | Uniform-grid neighbour index, buckets reused between rebuilds |
| `src/sim/SwarmSimulation.ts` | Boids (sep/ali/coh) + medium drag + predictive avoidance + walls + deterministic wander |
| `src/sim/ObstacleSystem.ts` | Course generation and the authored-script builders for every act's archetypes, circle collision, predictive avoidance, progress; the seeded generator (gate / rock / narrows / drift / vortex / predator) survives only for the sweeps |
| `src/sim/RescueSystem.ts` | Pods and required rings, sustained-contact detection, merge into the main shoal, missed-pod accounting |
| `src/sim/PredatorSystem.ts` | Hunters (shark, raptor, ember): pursuit, patrol, strike cooldown, and the low water coupling that makes them heavy |
| `src/sim/RunState.ts` | Run counters, score, the streak multiplier, failure reasons, `MIN_SHOAL` and its 40 % floor |
| `src/sim/Failure.ts` | What going wrong means, per act: put the station back and charge for it (a budget of restarts, then the act begins again), end the run, or never fail (act VII's last water); plus the strand line and grace |
| `src/sim/World.ts` | Orchestration: camera, gesture to medium injection, collisions, pods, hazards, zones, failure, events |
| `src/config/levels.ts` | The campaign's grammar: `Act`, `Level`, `SectionSpec`, `RingSpec`, `MotionSpec`, and act I's authored water course (six stations) |
| `src/config/ascent.ts` | Act II, the air: six stations of cloud, rebuilt around the one verb (decision 45) |
| `src/config/thinning.ts` | Act III, the thinning: spores, seeds and ice nuclei in the layered upper air |
| `src/config/orbit.ts` | Act IV, orbit: the act where a stroke lays potential instead of momentum |
| `src/config/reentry.ts` | Act V, the fallback: the first act that falls, and where the input changes under the hand |
| `src/config/rain.ts` | Act VI, the rain: rings gather scattered droplets back together |
| `src/config/homecoming.ts` | Act VII, the homecoming: the same water as act I met going the other way, authored end to end |
| `src/config/campaign.ts` | The seven acts in order, as a circuit; `CAMPAIGN`, `ACT_COUNT`, `TOTAL_STATIONS` |
| `src/config/zones.ts` | The palette and pool of every station's water, air or vacuum, across all seven acts - which archetypes each may build, and how much light the medium carries |
| `src/config/settings.ts` | Persisted preferences, sanitised on load: the audio mixer (ten tracks), mute, language, continuous-circuit mode. Quality, haptics, HUD, calm, reduced-motion and high-contrast switches were removed and are dropped from old saves |
| `src/meta/Profile.ts` | Personal bests, lifetime totals and the per-act record of stations cleared (storage version 3) - the only progression the game has |
| `src/meta/Campaign.ts` | The three facts that survive the gap between acts - where you are, what you carry, what it was worth - and the station checkpoint; headless on purpose |
| `src/meta/Circuit.ts` | The circuit drawn as a transit line: forty-two stops on one closed route, in box units, pure and DOM-free |
| `src/meta/Habitat.ts` | What lives in each band of the map's world (water, air, vacuum): the smallest marks that name the medium |

### Presentation / platform
| File | Purpose |
| --- | --- |
| `src/render/Renderer.ts` | Canvas2D, no WebGL and no post-processing: the per-act backdrop dispatch, light shafts, caustics, parallax silt, zone-tinted background, tracers, wake, rocks and clouds, distance haze, pods, hunters, vortices, the carried life, additive effects, shake, vignette, HUD, hint, debug overlays |
| `src/render/Paint.ts` | Zone palettes pre-parsed to numbers, the per-frame crossfade, and the colour helpers (`mix`, `brighten`, `temper`) |
| `src/render/Strata.ts` | The planes a picture is made of: a table of depth planes per station, because a full-frame bloom was built, hated and reverted (CLAUDE.md: no post-processing) |
| `src/render/FishShapes.ts` | The five kinds of fish (dart, disc, needle, fan, ray), seen from above, and the travelling wave that makes them swim |
| `src/render/Flock.ts` | The birds of act II: wing planform sampled root to tip, a bounded-rate heading and a constant per-bird wingbeat rate (decisions 45-52) |
| `src/render/Carriers.ts` | The five carriers with no body plan (acts III to VII): spores, motes, droplets and the rest of what the gold is held in, and the campaign's one secret |
| `src/render/Motif.ts` | What a station *is*, in one table per act: its backdrop, its wash, and the material its rock is made of |
| `src/render/Backdrop.ts` | The water each level is played in - canyon walls, void, current, rise, light line, surface - at two or more parallax planes each |
| `src/render/Sky.ts`, `Upper.ts` | The air each station is flown in: act II's six backdrops, and `Upper.ts`, which is `Sky.ts` one atmosphere further out, for act III's six |
| `src/render/SkyParts.ts` | The four cloud/sky primitives acts II and III share, so the seam at 11 km cannot show |
| `src/render/Orbit.ts`, `Reentry.ts`, `Rain.ts`, `Homecoming.ts` | The backdrops of acts IV to VII (orbit has no sky at all; re-entry makes the planet the floor; rain arrives at the ground; the homecoming puts the light behind you) |
| `src/render/Decor.ts` | The life that is not in the way: weed, jellies, bubbles, shards, and something very large passing behind everything |
| `src/render/Stone.ts` | Collision circles to one silhouette per connected mass (convex hull for rock, star-shaped union for cloud), plus the crest every rock is lit along |
| `src/render/RockPaint.ts` | How that silhouette becomes stone or cloud: occlusion, per-mass lighting, sediment bands, rim light, and the level's own fringe |
| `src/render/Whirl.ts` | A standing current drawn from the field it samples: sheared filaments, entrained motes at the true local angular speed |
| `src/render/Hunter.ts`, `Raptor.ts`, `Ember.ts` | The three threats: the shark (stiffens as it commits), the falcon (folds into a teardrop) and act V's burning piece of the vehicle, which is not alive |
| `src/render/Banner.ts` | The station banner: the only text painted on the canvas, as a pure function of a view so it can be tested |
| `src/render/Films.ts` | Which film each act ends on, so the next act's first frame arrives inside the previous act's ending rather than after it |
| `src/render/Surfacing.ts`, `Release.ts`, `Karman.ts`, `Overview.ts`, `Nucleus.ts`, `Estuary.ts`, `Circle.ts` | The closing films, in play order: act I's breach into sky, act II's view of the atmosphere from outside it, the Karman line (the stroke that does nothing), the camera turning at the top of the circuit, the gold condensing back out of the fire, the estuary where the water becomes life again, and the last sentence that dissolves the trench floor into act I's first frame |
| `src/input/InputController.ts` | Pointer events to medium momentum, coalesced-event replay, multi-touch, stroke-speed callback for audio |
| `src/ui/Shell.ts` | Title, pause, results, the circuit map and the in-run audio drawer as real DOM buttons - focusable, screen-readable, hidden outright during a run |
| `src/audio/AudioEngine.ts` | Every sound in the game, synthesised: eight beds across the seven acts, stroke whoosh, gate, rescue, re-form, impact, strike, zone, fail, record, and the ending cues |
| `src/audio/Beds.ts` | Which bed an act plays, what its six layers are called, and how its chord, high layer and bell are voiced |
| `src/audio/Scale.ts` | The one set of pitches the game may play, and the rule that every physically derived voice is snapped to it |
| `src/audio/Rescues.ts` | The game's one reward, per act: the interval, the swell, and the act's own material converging on the ring |
| `src/audio/Bubbles.ts`, `Raindrops.ts`, `Riffle.ts` | Minnaert resonance at three scales: the deep sea, rain on water, and a mountain stream |
| `src/audio/Wings.ts`, `Crystals.ts`, `Void.ts`, `Plasma.ts`, `Snow.ts` | The other five media's voices - a flock, ice and shear, breath and whistlers, the sheath and its shocks, marine snow |
| `src/audio/Whale.ts` | Whale song as a phrase (glides, then a long silence), the water's rare distant voice |
| `src/i18n/strings.ts` | The English string tables; `resolveLang` returns English for every setting, because the game ships in English only |
| `src/platform/Haptics.ts` | Every buzz the game has, named, in one cue table behind one driver seam (`navigator.vibrate` on the web; iOS Safari never implemented it, so there it is a no-op) |
| `src/platform/pwa.ts` | Service-worker registration, production builds only |
| `src/brand/digital-tulpa/` | The studio ident played before the title (`index.ts`, `ident.css`, `mark.svg`, its own `README.md`); dependency-free and copyable into another project |
| `src/debug/DebugPanel.ts` | Live sliders for every tuning number, overlays, seed replay, config import/export, telemetry export, frame-scaler pins, `localStorage` persistence |
| `src/debug/AdminPanel.ts` | The admin surface: any act and station, any single authored section, and every sound in the engine - each on its own, one click |
| `src/telemetry/LocalTelemetry.ts` | Local-only run records + JSON export. **No network code exists in this project.** |
| `src/main.ts` | Boot, the attract/playing/paused/over machine and the campaign, resize/DPR/safe-area, visibility, the frame-rate quality ladder, hit-stop, haptic cues, the `window.__slowblue` test hook |
| `public/manifest.webmanifest`, `public/sw.js`, `public/icon*.png`, `public/icon.svg` | Installable, offline-capable app shell |
| `tools/make-icons.mjs` | PNG icon generator: a CRC table, `node:zlib`, and no image dependencies |
| `tools/deploy.sh` | `npm run deploy`: builds with `BASE_PATH` and replaces the `gh-pages` branch with one orphan commit; the deploy is a command, not a workflow |

### Tests, e2e and tools
Unit tests run under `npm test` (vitest, node, no DOM). Specs under `e2e/` drive a production
build in Chromium. `tools/*.sweep.ts` are the measuring instruments behind `npm run sweep`
and are never part of `npm test`.

**Shared test helpers (not tests)**

| File | Purpose |
| --- | --- |
| `tests/helpers.ts` | Inert tuning (all forces off) so one force can be isolated per test |
| `tests/canvas.ts` | A canvas that records instead of painting: outlines, arcs, composite modes, and a check that nothing drawn was a non-finite number |
| `tests/bot.ts` | Scripted stand-in players (`passive`, aim bot with style knobs, splitter, `rush` and `brake` hands) + run harness |
| `tests/course.ts` | The corridor sweep, shared by every act's safety net: a reachable set of x positions carried down the course |
| `tests/opening.ts` | The first-ninety-seconds measurement that `tools/onboarding.sweep.ts` reports and `tests/onboarding.test.ts` defends |
| `tests/allocation.ts` | The allocation probe, in-process (the same instrument `e2e/measure.spec.ts` runs over the real bundle) |
| `tests/audiobed.ts` | A Web Audio stub just complete enough to build the engine's graph, so `AudioEngine` can be tested at all |
| `tests/oklab.ts` | The colour instrument: OkLab/OkLCh, because every other frame measurement reduces a pixel to luminance first |

**Simulation and rules**

| File | Purpose |
| --- | --- |
| `tests/core.test.ts` | Fixed timestep, RNG determinism, math |
| `tests/promotion.test.ts` | The loop on a display that is not 60 Hz: 30, 90 and 120 Hz panels and a tab returning with a second of debt |
| `tests/flowfield.test.ts` | Impulse deposit, falloff, half-life decay, diffusion, bilinear sampling, scrolling |
| `tests/spatialhash.test.ts` | Neighbour queries, cell boundaries, negative coords, no leakage between rebuilds |
| `tests/swarm.test.ts` | Separation/alignment/cohesion, faction isolation, water drag, braking, speed limits, determinism |
| `tests/obstacles.test.ts` | Section cycle, spacing, determinism, passable gaps, collision, avoidance, progress |
| `tests/rescue.test.ts` | Merge on sustained contact, no merge when too few / too brief, contact decay, missed pods |
| `tests/world.test.ts` | Lifecycle, camera monotonicity, attrition without ending, both failure modes, full reset + seed replay, growth cost |
| `tests/ambient.test.ts` | Ocean current: determinism, peak speed, divergence-free interior, no flow into walls; plus the non-linear water decay |
| `tests/currents.test.ts` | Standing currents: tangential only, divergence-free, zero at the eye and the rim, scaling, pruning |
| `tests/predators.test.ts` | Hunters: pursuit, strike cooldown, spawn grace, wall clamp, determinism; and the shoal's flight response |
| `tests/medium.test.ts` | The `Medium` abstraction's hard promise: water resolves to the exact tuning fields act I always read |
| `tests/breath.test.ts` | The breath is 11 s, rests at both ends, and the out-breath is longer than the in-breath |
| `tests/zones.test.ts` | Zone ordering, which archetype each zone may build, per-zone content, palette parsing and blending, and the monotone darkening of the ascent |
| `tests/runstate.test.ts` | The streak: what advances it, what breaks it, what it is worth, and that a clean run beats a sloppy one |
| `tests/tuning.test.ts` | The audio "harmonically pitched" clause as a number: every note-length voice in all eight beds lands on the scale (`src/audio/Scale.ts`) while textures stay free |
| `tests/persistence.test.ts` | Storage that degrades instead of throwing, settings/profile sanitising, i18n table parity |
| `tests/playability.test.ts` | Skill-tier probe, gesture-style differentiation, "rescue is a choice", split tactic, both failure endings |
| `tests/ablation.test.ts` | What it costs to outrun the medium in the three acts that fall, answering the report "I can descend far faster than the world and never die": the charge for rushing, the heat that lets go again, and every climbing act left exactly as it was |
| `tests/culling.test.ts` | Nothing leaves the frame by being switched off: rocks and currents are dropped past the glass, not on it |
| `tests/allocation.test.ts` | The zero-GC clause as a guard: bytes per frame in an open station and in the busiest one |
| `tests/response.test.ts` | The cheap half of `e2e/response.spec.ts`: no event type may exist that neither the glass nor the mixer names |
| `tests/pointer.test.ts` | The pointer edge cases a phone produces: a second finger, a cancelled touch, a touch never lifted, a run ending under a finger |
| `tests/haptics.test.ts` | The haptic cue table is the only way the game buzzes: every cue described in both vocabularies, the same array handed to the driver every time (no allocation), no cue the game never fires |

**Campaign: the acts and the rules across them**

| File | Purpose |
| --- | --- |
| `tests/levels.test.ts` | Act I's safety net: the corridor sweep over its authored course (the sweep itself is in `tests/course.ts`) |
| `tests/ascent.test.ts` | Act II's safety net: a flyable corridor down the whole act, every obstacle cloud, no ring walled off, more rings and narrower gaps the higher it goes |
| `tests/thinning.test.ts` | Act III's safety net, and the two claims that make it a different act rather than a different colour |
| `tests/orbit.test.ts` | Act IV's safety net: a stroke lays potential, the act cannot end a campaign, there is no medium |
| `tests/reentry.test.ts` | Act V's safety net: the first act that falls, and the input that changes under the hand |
| `tests/descent.test.ts` | Acts VI and VII together, and the campaign as a whole: hazards thin out, the last stations cannot be lost, authored spacings are summed rather than assumed |
| `tests/direction.test.ts` | The course runs both ways: the falling acts tested against a mirror of act I |
| `tests/motion.test.ts` | The second axis (`MotionSpec`): a gap may breathe, a mass may walk, and nothing in it makes a station unflyable |
| `tests/geometry.test.ts` | The four invariants that belong to no single act, true of all seven courses at once |
| `tests/stations.test.ts` | The rules a station obeys, campaign-wide, measured on act V and now held for six acts (act I exempt from two on purpose) |
| `tests/campaign.test.ts` | The campaign probe: a competent stand-in player can be on the line while the water moves, the ocean pushes and the dashed rings demand to be held |
| `tests/circuit.test.ts` | `CampaignController`: where you are, what you carry, what it has been worth, across seven acts |
| `tests/checkpoint.test.ts` | A cleared station stays cleared: the save and the resume at station boundaries |
| `tests/ember.test.ts` | Act V's threat, and the campaign claim it exists to fix (every hunter used to be in acts I and II) |
| `tests/onboarding.test.ts` | The shape of the first ninety seconds, defended with budgets rounded outward from what the sweep printed |
| `tests/admin.test.ts` | Starting a run mid-script: the right section first, in the right station and medium, in either act, and section zero still the default |

**Drawing**

| File | Purpose |
| --- | --- |
| `tests/fish.test.ts` | The fish outline against a recording stand-in for a canvas: nose in front, body width preserved while it bends, nose still while the tail sweeps, one distinct aspect ratio per species, and a rescued pod keeping its kind through a merge |
| `tests/flock.test.ts` | The bird silhouette, wingbeat and heading: mostly wing, a beat is a span that foreshortens, no frame moves the drawn span or heading faster than a bounded rate |
| `tests/carriers.test.ts` | The five carriers with no body plan are five different things and draw clean |
| `tests/stone.test.ts` | Masses merge, the crest faces up the course, its normals are unit and on the silhouette, and every material of every level paints clean at three quality levels |
| `tests/motifs.test.ts` | The motif table is act-aware: an air gate is no longer painted as the water level with the same index |
| `tests/whirl.test.ts` | The drawn current against `CurrentField` itself: `omega * r` is the tangential speed the shoal will feel, calm at the eye and the rim, shear monotone inward |
| `tests/hunter.test.ts` | The predator outline: snout in front, widest at the pectorals, a lunate tail, a body that flexes cruising and stiffens on a strike |
| `tests/surfacing.test.ts` | The first ending's clock: phase order, no air before the breach, holds on its last frame, and finite geometry from the first frame to the last |
| `tests/release.test.ts`, `tests/overview.test.ts`, `tests/films.test.ts` | The closing films run whole at 60 Hz: nothing drawn until the act is finished, phases in order, finite geometry, the last frame held; and every act has its own ending |
| `tests/sky.test.ts`, `tests/homecoming.test.ts` | The backdrops held to one contract: nothing non-finite, something drawn at every point of a station (air in `sky`, act VII in `homecoming`) |
| `tests/strata.test.ts` | The plane doctrine as tests: a table of forty-two entries cannot be edited by someone who has not read the paragraph above it |
| `tests/decor.test.ts` | Nothing marine above the weather: decor themes per medium |
| `tests/banner.test.ts` | The station banner as a pure function of a view |
| `tests/palette.test.ts` | The palette as a system, in OkLCh across forty-two stations (report in `tools/palette.sweep.ts`) |
| `tests/atlas.test.ts` | The shape of the circuit, asserted: it closes, the way home mirrors the way out, and up is up (act IV across the top) |
| `tests/habitat.test.ts` | The world behind the route on the map: the three promises that furniture makes |

**Audio**

| File | Purpose |
| --- | --- |
| `tests/audioengine.test.ts` | What the bed actually deals, per act, against a stubbed `AudioContext` |
| `tests/beds.test.ts` | The bed table: no act falls through an unowned `else` into the water's sound |
| `tests/loops.test.ts` | Click-free clause: the one looping buffer and the per-frame parameters the engine pushes |
| `tests/bubbles.test.ts`, `tests/raindrops.test.ts`, `tests/riffle.test.ts` | Minnaert resonance at three scales, and that the three results are unmistakable for each other |
| `tests/wings.test.ts`, `tests/crystals.test.ts`, `tests/void.test.ts`, `tests/plasma.test.ts`, `tests/snow.test.ts`, `tests/whale.test.ts` | The other voices: each keeps the one property that makes it that thing (a wing is derived from its span; the sheath is silent before the air; snow is still falling when its envelope ends; a whale glides, then is silent) |
| `tests/rescues.test.ts` | The per-act rescue reward: every bed has one, no two acts share it, act I is exactly where it was, act IV keeps its silence, every degree stays on the scale |

**End-to-end specs (`npm run e2e`, Chromium at 390x844)**

| File | Purpose |
| --- | --- |
| `e2e/helpers.ts` | Boots the game *through the shell*, the way a player does; owns the rule about when the tracked screenshots may be rewritten |
| `e2e/sourcemap.ts` | The smallest source-map reader that can name an allocation site in the minified bundle |
| `e2e/smoke.spec.ts` | Mobile viewport: load, title to run handover, drag to water to shoal, no scroll, restart, pause/resume/quit, the in-game mixer, audio settings and personal best across a reload, CDP touch, local-only telemetry, installable manifest, the dev door touching no record |
| `e2e/runtime.spec.ts` | Sustained frame rate under the real rAF loop, including deep in the run with hunters and standing currents up; the one-shot idle hint; the three-finger door to the panels; the quality-ladder pins; the clock stopping when the page loses focus |
| `e2e/campaign.spec.ts` | The circuit driven through the real shell: the whole campaign end to end, act select, station checkpoint across a reload, the restart budget, the last water that cannot be lost |
| `e2e/acts.spec.ts` | Every station of all seven acts and every movement of the seven endings, shot and asserted to be a non-flat picture |
| `e2e/capture.spec.ts` | Renders and saves the numbered documentation frames in `docs/screens/` - only when asked for (`npm run screens`); the rest of the time it is the smoke test for mid-run rendering |
| `e2e/chrome.spec.ts` | The shell measured on the glass: every screen readable, every control hittable, the pinned primary clearing the cutout |
| `e2e/shell.spec.ts` | What is left after the settings screen: the mute button and the map's mode and wipe are reachable |
| `e2e/safearea.spec.ts` | Whether anything the player must touch or read sits under an emulated notch or home indicator |
| `e2e/response.spec.ts` | What answers an event, and how loudly: every event of the union on both the glass and the mixer |
| `e2e/unlock.spec.ts` | The audio unlock handshake: silent until touched, restored on return, survives every touch for a session |
| `e2e/intro.spec.ts` | The studio ident owns startup, a key or a touch skips it without starting a run underneath, and it plays in full under reduced motion |
| `e2e/motion.spec.ts` | A moving rock is drawn where it collides; act V's fragments arrive from behind |
| `e2e/measure.spec.ts` | The evidence suite: launch budget cold and warm, allocation in the busiest frame, offline install and second launch, retina edge sharpness |

**Tools (`tools/`)**

| File | Purpose |
| --- | --- |
| `tools/experiment.ts` | Sweep harness: runs every play style under a tuning override and prints a comparison table |
| `tools/water.sweep.ts` | Standing design-health check for act I (`npm run sweep`) |
| `tools/air.sweep.ts`, `thin.sweep.ts`, `space.sweep.ts`, `descent.sweep.ts` | The same instruments for act II, act III, acts IV and V, and acts VI and VII with the length of the whole circuit |
| `tools/finish.sweep.ts` | Can a competent hand actually finish an act inside its own clock |
| `tools/length.sweep.ts` | How hard an act is on a scale that survives the act getting longer (half an hour to run) |
| `tools/stations.sweep.ts` | What every station is made of, as arithmetic - the one instrument that does not run the simulation |
| `tools/rush.sweep.ts` | How much faster than the world a hand can go, and what that costs (`SLOWBLUE_ACT=reentry` for one act) |
| `tools/onboarding.sweep.ts` | What the first ninety seconds show, and when |
| `tools/palette.sweep.ts` | The colour arc across forty-two stations, in OkLCh |
| `tools/deploy.sh`, `tools/make-icons.mjs` | Listed under platform above |

## How the mechanic is built (and why)

**Water is the only control channel.** `InputController` turns each pointer segment into
`World.injectStroke`, which deposits Gaussian velocity blobs along the segment into
`FlowField`. One speed→shape mapping produces every "gesture":

```
u        = clamp(fingerSpeed / 1400, 0, 1)
strength = flowStrength * (0.35 + 1.75 * u)     // fast = stronger
radius   = flowRadius   * (1.55 - 0.85 * u)     // fast = narrower
```

There is **no gesture recogniser**. Vortices, braking and curved sweeps all fall out of the
same rule: a circular finger path lays tangential momentum, which *is* a vortex; a stroke
against the shoal's motion *is* braking.

**Fish never chase the finger.** In `SwarmSimulation.step` the coupling term is
`acc += (waterVelocity - velocity) * flowCoupling` — drag relative to the water. Combined
with alignment this produces the silk moment: the shoal bends as one sheet
(`docs/screens/02-first-drag.png`).

**Determinism** is a hard requirement (seed replay, unit tests, the headless probe): fixed
`1/60` timestep, seeded `Rng`, and a positional/phase-based wander instead of per-frame
random calls.

**The field scrolls with the water, not the screen.** `FlowField.shiftTo` moves the grid in
whole cells as the camera advances, so a current you laid stays where you laid it.

**The ocean has its own current.** `World.water` is the single water sampler: the player's
grid plus `AmbientFlow`. The swarm cannot tell whose water is pushing it, and the tracer
particles show the sum, so the ocean is legible before it moves you. This was not
decoration - see decision 5 below.

**Growth, attrition and splitting all cost something.** A rescue demands a *fraction* of the
shoal inside the ring; a bigger shoal is heavier (`inertiaPerAgent`); a rock strike panics its
neighbours and widens the shoal; and a shoal that has lost 60% of its starting size is over.
Each of these replaced a version where the corresponding action was free. (The 40 % floor is
still `MIN_SHOAL_FRACTION`; what *happens* when it is crossed is now the per-act policy in
`Failure.ts`, not an unconditional game over.)

**Depth is the only progression.** `zones.ts` says which archetypes the generator may build
and what the water looks like; nothing else in the game knows a zone exists. The first zone
is a fixed `gate → rock → narrows` cycle, because it is the tutorial and a tutorial must not
shuffle. Everything the player earns across runs is one file of personal bests.

> **Superseded in two ways.** Since decision 21 the shipped course is authored, not
> generated: each act's file under `src/config/` is a hand-written list of sections, and the
> seeded generator described here survives only for the sweeps. And "depth" became the whole
> circuit - seven acts, forty-two stations, 432 sections and 144 authored minutes
> ([docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md)) - with a per-act record of stations cleared
> (`Profile` v3) on top of the personal bests. Failure is no longer one rule either: see
> `src/sim/Failure.ts`, where a lost station is put back and charged for, twice, before the
> act begins again.

**The two hazards that are not rock.** A *standing vortex* is an obstacle made of the same
substance the player steers with — the only way past is to spend water on it. It is the
analytic curl of a radial profile, so it is exactly divergence-free and needs no solver, and
because it goes through the same `World.water` sampler as everything else, the tracer
particles draw it for free: the hazard is visible in the water before it touches the shoal.
A *hunter* is the one thing that hunts back, and the one thing the player cannot touch: water
drags it at a third of the coupling a fish feels, so shoving one off its line costs a
committed stroke rather than a flick. Its threat radius is always drawn, because hiding the
range of the thing that eats you turns a readable hazard into a slot machine.

**The shell is DOM, not canvas.** Everything in the game is drawn, because the game is one
continuous picture of water. Everything around it is a real `<button>`, because a
canvas-drawn button has no focus ring, no screen reader, no keyboard and no text scaling.
The two never overlap: the shell's screens are `display: none` during a run, so they can
never eat a gesture, and the HUD is suppressed whenever a shell screen is up. (The pause and
mixer buttons are the exception by design: two small corner controls that no stroke needs.)

**All audio is synthesised.** No asset ships. A prototype that has to open over a LAN cannot
spend a megabyte before the first frame, and every cue is parameterised by what caused it —
a stroke's pitch follows the finger's speed, a gate's interval climbs with the streak, a
loss gets duller the more severe it was. The engine is inert until a real user gesture opens
the `AudioContext`, and a no-op wherever `AudioContext` does not exist (Node, the sweeps).

## Where to tune

* **`src/config/tuning.ts` — `DEFAULT_TUNING`**: every feel value (45 numbers). Nothing else
  hardcodes one. The media (`src/sim/Medium.ts`) override the handful that differ in air,
  the upper atmosphere, vacuum and rain; water resolves to these defaults digit for digit.
* **Debug panel** (`?debug=1`, in a dev build and in a shipped one alike; `d` toggles it):
  live sliders for every tuning number, field/hash/stats overlays, FPS and frame percentiles,
  the frame-rate ladder's pins, seed replay, config import/export, defaults reset, 0.25x and
  pause, telemetry export. Values persist in `localStorage`.
* **Admin surface** (`?admin=1`, always on in `npm run dev`, and on a phone by holding three
  fingers still for a second and a half off-run): any act, station or single section, and
  every sound. It is the tool for *looking* at a thing rather than tuning it.
* **Highest-leverage parameters** (measured, see below): `flowCoupling`, `flowStrength`,
  `perceptionRadius` + `cohesion`, `pressureRamp`, `inertiaPerAgent`, `predatorCoupling`,
  and, since decision 37, `migrationSpeed`.
* **Speed→shape mapping**: `World.injectStroke` (the `0.35 + 1.75 * u` / `1.55 - 0.85 * u` pair).
* **Course**: the authored lists in `src/config/` (one file per act, `levels.ts` for act I
  and the grammar) and the builders in `ObstacleSystem`; `SECTION_SPACING` (820) is only the
  default spacing - a section carries its own. What a station is made of is measured by
  `tools/stations.sweep.ts`, and the rules it must obey are `tests/stations.test.ts`.
* **What the generator builds how deep** (sweeps only): `ZONES` in `src/config/zones.ts`
  (`fromSection` + `pool`); the same file carries every authored station's palette.
* **Rescue difficulty**: `CONTACT_AGENTS` (8), `CONTACT_HOLD` in `RescueSystem.ts`.
* **Scoring and the streak**: `GATE_POINTS` / `RESCUE_POINTS` / `REFORM_POINTS`,
  `STREAK_TOLERANCE`, `COHESION_LIMIT`, `STREAK_STEP`, `STREAK_CAP` in `RunState.ts`.
* **Failure thresholds**: `MIN_SHOAL` and `MIN_SHOAL_FRACTION` (`RunState.ts`); the strand
  line and grace (`strandLine` 0.94, `strandGrace` 0.7) and the restart budget in the
  `FailurePolicy` of `src/sim/Failure.ts`.
* **Picture budget**: `QUALITY_RUNGS` in `src/main.ts`, the five-rung ladder the frame-rate
  scaler walks (down at 45 fps after 2.5 s, back up at 58 after 8 s). There is no quality
  setting; the ladder is the setting.
* **Length and difficulty of an act**: do not hand-tune; read
  [docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md) and run `tools/length.sweep.ts` and
  `tools/rush.sweep.ts`.

## Tuning decisions that came from measurement, not taste

`npm run sweep` reproduces the health table; `npm test` asserts the conclusions.

1. **`perceptionRadius` 44 → 58, `cohesion` 1.1 → 1.35.** A four-variant headless sweep under
   an identical scripted player: mean shoal spread 59.9 → 48.5 px, individuals lost 98.6 →
   85.2, rescued 52.4 → 77.8. The tighter shoal is not cosmetic — fewer stragglers get culled.
2. **`pressureRamp` added (default 1.6).** Without escalating camera drift, the competent bot
   hit the 120 s harness cap in 4 of 5 seeds — a skilled player would never fail. Sweep of
   ramp ∈ {0, 0.8, 1.6, 2.4, 3.2}: at 1.6 runs land in the brief's 30–90 s window, every run
   ends for a reason, and the skill gap stays wide. At 3.2 the gap collapses — pressure starts
   drowning skill.
3. **Difficulty ramp lengthened** from 8 to 12 sections, so gaps narrow across a longer arc.
4. **Glow pass changed from scaled triangles to centred discs.** The scaled-triangle glow
   extended behind each agent and read as a drop shadow / double image on device.
5. **The ocean got its own current (`ambientStrength` 55).** The first verdict's main defect
   was "one dominant strategy". Two hypotheses were tested and **falsified** before the real
   cause was found:
   - *Non-linear turbulent water decay* would make a hard flick a short precise tool. Swept
     `flowMaxSpeed` × `flowTurbulence` (16 combinations): turbulence made the flick style
     strictly **worse** (score ratio vs the soft style fell from 0.76 to 0.26–0.57). Rejected;
     the knob is kept, defaulted to 0, because it is a legitimate lever once other things move.
   - *More diffusion and alignment* would let a narrow stab drag the whole shoal. Swept 12
     combinations: the ratio moved 0.52 → 0.56 at best. Rejected as noise.

   The actual cause was structural, not physical: **with still water and everything visible far
   ahead, acting early strictly dominates acting late.** No water tuning can fix that. An
   ambient current invalidates a stale plan, which is what makes late correction a skill. At 55
   it tripled seed-to-seed score variation (0.09 → 0.28) — i.e. the ocean, not just the course,
   now decides how a run goes. This also reframed the defect: a bot that reacts late is a
   *handicap*, not a strategy. An expert beating it is correct design. The real strategy axes
   are routes, which is what decisions 6–8 address.
6. **A rescue now demands a fraction of the shoal (`rescueRadius` 62, `rescueFraction` 0.28).**
   The damning measurement: the bot that deliberately chased pods collected **fewer** of them
   (75.6) than the bot that ignored them entirely (83.4). A flat 6-agent threshold was
   trivially satisfied by a scattered shoal drifting past, so growth had no decision attached.
   Swept ring radius × required fraction (9 combinations); at 62/0.28 deliberate play collects
   **2.2×** as many and scores 1.1–1.3× — a real trade rather than a free lunch or a trap. At
   48/0.28 it became 39× and mandatory, which is just a different kind of no-choice.
7. **Rock sections got a pod in each side channel, plus a split-and-reform bonus.** "The shoal
   can be split" was true but paid nothing, so it was an accident rather than a tactic. The
   channels are ~0.5W apart — wider than a healthy shoal — so one body reaches one pod and a
   split body reaches both. Measured: the scripted splitter went from 0.10 to **0.52** of the
   safe line's score, with 1.0–1.4 credited re-forms per run.
8. **Attrition given teeth: panic on impact + a relative failure floor.** Previously *every*
   scripted style died only by being left behind, because a smaller shoal is lighter and
   therefore turns *better* — losing fish made the game easier and "the shoal fell apart" was
   unreachable. Now a strike scatters its neighbours (`PANIC_RADIUS` 34, `PANIC_KICK` 55) so
   carelessness compounds, and the run ends below 40% of the *starting* shoal (keyed to the
   start, not the peak, so rescues are pure buffer and never raise your own bar). Result: both
   endings occur and are tied to play style — careless flicking and botched splits fall apart,
   everything else gets left behind. The panic cascade also **widened** the skill gap from
   1.9–2.3× to 2.4–3.2×.
9. **Tracer particles became trails (`TRAIL` 9).** A one-frame segment is ~0.9 px at ambient
   speeds, so the ocean's current was completely invisible on screen. Straight short ticks then
   read as *rain*, so the trail is 9 points with a tapered two-pass stroke and per-tracer
   brightness.
10. **The narrows funnel was a row of beads.** Found by looking at it: 7 blobs per wall at
    r=17.5 sat ~47 px apart, leaving 12 px gaps the shoal could swim straight through. Step
    count is now derived from the radius. Guarded by a flood-fill test that asserts every
    section has a route through *and* actually obstructs — a scan-line test cannot do this,
    because the funnel has legitimate dead-end channels either side.

### The second pass: from prototype to finished game

11. **Clearing a narrows was worth nothing, silently.** Found while writing a zone test, not
    by playing. Sections are pruned once they are behind the camera, and the rule was keyed
    to `maxY` — the rearmost point of the geometry. But three of the six archetypes reach
    *behind* their own scoring line: a narrows funnel by 240 px, a chicane by 200 px. The
    prune line sits about 196 px behind the centroid at the moment it crosses, so those
    sections were dropped from the list one step *before* the crossing that should have
    counted them. Every funnel a player ever cleared paid zero. Reordering credit before
    pruning was not enough — the drop happened a step earlier — so `prune` is now keyed to
    `lineY`, which keeps exactly as much geometry as the section needs and not a pixel more.
    A blanket "keep everything longer" was tried first and rejected: it leaves rocks alive
    behind the shoal, quietly culling stragglers that used to swim free. Measured effect on
    the competent bot: **4.0 → 6.0 gates per run** at identical play. Regression test in
    `tests/world.test.ts` asserts the precondition, not just the outcome.
12. **The streak multiplier was priced on damage, and did nothing.** The first version broke
    the streak on any four individuals lost between gates. Measured, that made careful and
    careless play indistinguishable — a competent run bleeds ~10 individuals per section and
    almost all of them are *stragglers culled off the back*, not rock strikes, so the
    multiplier reset at every gate for everyone. Excluding culls made it reachable but still
    undiscriminating: the panicky bot scored 2136 against the careful bot's 2194, because
    neither hits much rock. What actually separates them is **shape** — mean spread 64 against
    115. So the streak is now priced on cohesion (`COHESION_LIMIT` 100) as well as damage,
    which is the skill the whole game is about. Careful play went from 1.03× the panicky
    bot's score to **1.34×**, and the best streaks separated 5/4/2 against 1/1/0.
13. **The pressure ramp made three quarters of the game unreachable.** At `pressureRamp` 1.6
    the camera out-runs a competent shoal at about 5000 px — section 6. With four zones in
    the course, that meant nobody would ever see a hunter or a standing vortex. Two things
    moved: the ramp to **1.15**, and the zone boundaries in to sections 4 / 9 / 16. The
    steering bot now finishes in the second zone and a strong line reaches the third, with
    run length still inside the brief's 30–90 s window (49 s, nothing hitting the harness cap).
14. **A re-form bonus is a reward for losing control, unless you say where.** A panicking
    shoal sits near the split threshold all run, so it crossed and re-crossed by accident on
    funnels and chicanes: the panic-flicker was banking as many re-form bonuses as the bot
    that split deliberately. Widening the spread thresholds (112/78 → 128/66) killed the
    accident *and* the tactic — the deliberate splitter dropped to 0.2 re-forms per run.
    Restricting **where** a split counts, to archetypes with a central mass and a channel
    either side, left the verb intact and took the accident away: splitter 0.6 → 2.0
    re-forms, panic-flicker down to 0.4.
15. **Rescue over-paid once every section counted.** With funnels finally scoring, the
    pod-chasing bot reached 1.56× the score of the bot that ignored pods — past the 1.45
    ceiling the design sets for "growth is a trade, not the answer". `RESCUE_POINTS` 25 → 16
    and `GATE_POINTS` 120 → 170 price a detour against progress instead of on top of it:
    **1.31×**, with the pod bot still collecting 2.7× as many.
16. **The measuring instrument was wrong about multi-row sections.** The scripted aim bot
    steered toward `section.lineY` — the *scoring* line — which is only the same thing as
    "the next wall" for the flat archetypes. Against a chicane it aimed past the wall in
    front of it and swam into it, which made every multi-row section look unplayable in the
    sweep and nearly caused a real design change to fix a bot bug. It now aims at the nearest
    blob row ahead, the way a person looks at the next wall. Same for the split bot, which
    was prising the shoal apart at a fixed ±110 px instead of at the channels the pods mark:
    24 rock deaths a run against the careful bot's 9, dying at 19 s. Aimed at the actual
    channels it reaches 44 s and 2.0 re-forms. **Neither of these was a game change** — but
    both would have been mistaken for one.

17. **The picture was shapes on a gradient.** A refinement pass, in order of what it
    actually bought: **additive compositing** for everything that emits light (shoal
    glow, pod rings, every effect, the wake, the caustics) — the single biggest change,
    and free, because it is the same fills with a different `globalCompositeOperation`;
    **three parallax depth bands** of drifting silt instead of one; **light shafts**
    anchored at a tenth of the camera's rate; a **top-lit rock rim**, offset two pixels
    toward the surface so the light in this game has a direction; **distance haze** at
    the top of the screen so the course fades up out of the dark instead of switching
    on at the edge; a **forked-tail dart** for the fish instead of a triangle, with the
    glow as an ellipse along the heading rather than a disc — the disc read as a coin
    behind each fish; and the shoal split into **two tints**, because a hundred
    identical darts read as a stamped pattern rather than a crowd.

    Two of these were wrong on the first attempt and had to be looked at:
    - The shafts were hard-edged quads with a *vertical* gradient. On a dark background
      that reads as architecture — flat polygons with straight sides. They are now
      filled with a **horizontal** gradient inside a sheared transform, so a shaft has
      no sides at all: brightest along its own axis, gone before the edge.
    - The silt halo was drawn around every blob at `r + 8`. A gate is a chain of r≈17
      beads, so the halos merged and the whole wall became one smooth capsule. It is now
      only drawn around masses with `r >= 26`, at `r + 6` and half the opacity.
18. **The atmosphere is not free, and the Low setting now means it.** Measured under the
    real loop: **120 → 86 FPS** headless after the first pass. Wide additive strokes are
    pure fill rate, so the caustics went from five bands × three passes to four × two,
    and the shafts from four to two — **92 FPS**. What remains is honest cost, not
    waste. The `Low` quality setting drops the vignette, the distance haze and half the
    caustics outright, on top of the DPR cap and the halved particle counts, so the
    cheapest mode is genuinely cheap rather than slightly cheaper.

    > **Superseded:** there is no quality setting any more. It was `auto` / `high` / `low`,
    > and `high` was strictly worse than `auto`. The frame-rate scaler in `main.ts` walks a
    > five-rung ladder (`QUALITY_RUNGS`) that thins the drawing twice before it touches the
    > resolution, steps down at 45 fps and back up at 58, and the bottom rungs are what `Low`
    > used to do in one jump. The measurements above still describe what the expensive
    > layers cost.

19. **The fish were triangles, which is the shape you draw when the camera is nowhere.**
    This camera is directly over the water, so a fish is now a spindle seen from above:
    a blunt or pointed snout, two pectoral fins, and a tail behind it. The outline is
    built around a spine carrying a **travelling wave** - `sin(beat - s * lag)` with the
    amplitude going as `s^1.5`, so the nose is still and the tail does the work - and
    the beat frequency rises with the individual's speed. It runs on the simulation
    clock, so it stops dead when the game is paused, and it costs no state at all: the
    whole animation is a function of `(swarm time, agent phase, speed)`.

    Two attempts got the proportions wrong in a way only a screenshot showed. First the
    tail fork and the fins were sized against the *body width* multiplier rather than
    the body's actual half-width, so both stuck out about twice as far as the fish was
    wide and the shoal read as a field of spiky kites. Then the body was 8px long and
    4.4px wide - a 1.8:1 rhombus, not a fish. At 9.5 × 2.6 it is 3.6:1 and reads.

20. **A rescued pod stays a different kind of fish.** `Agent.species` is set at spawn and
    survives the merge into the main shoal, so the shoal you finish with is visibly the
    one you assembled rather than a hundred copies of what you started with - and "the
    long thin ones came from the ring I held at the second rock" is a memory the game
    gets for one integer. The five kinds differ in **silhouette** first and tint second,
    because colour alone disappears the moment the zone palette moves. Pods cycle through
    the four non-starting kinds by pod id, so a replay of the same seed deals the same
    fish.

    | kind | silhouette |
    | --- | --- |
    | `dart` | the shoal you start with: slim, pointed, forked tail |
    | `disc` | stubby, blunt-nosed, broad pectoral fins |
    | `needle` | very long and thin, fast tail |
    | `fan` | broad sweeping tail fin |
    | `ray` | wider than it is long, no tail fin at all - a whip |

    The ray needed one thing the fish did not: it has no spine worth bending, and swims
    by flapping. From directly above a wing beat is a *width* that swells and narrows,
    so `flap` modulates the half-width profile rather than offsetting the spine. The
    test pins that difference down - the ray's flank-to-flank span beats, every fish's
    is constant to within a rounding error while its spine bends. Measuring that as
    `max |across|` does not work: a flexing spine slides the whole outline sideways, so
    the outermost point moves even on a body that never changes width.

### The third pass: from endless course to campaign

21. **The generator could not stop shipping obstacles nobody could fly.** The endless course
    was six archetypes parameterised by a seed and a difficulty ramp, and two of them place
    geometry *inside the line the next one asks for* - a chicane drops a loose boulder 92 px
    past its own gap, which on the wrong seed is the only water through the following row.
    The flood-fill test in `tests/obstacles.test.ts` never caught it because a route existing
    is not the same claim as a route being flyable: the fill can turn a corner in zero
    pixels and a shoal cannot. The fix is not a better generator, it is authorship:
    `src/config/levels.ts` is a hand-written list of sections, and the generator stays only
    for the sweeps, which need water nobody has tuned. The boulder and the off-line bait pod
    are both gone from the authored builders.

22. **"Is it flyable" is a claim about geometry, so it is now a test.** `tests/levels.test.ts`
    carries a set of reachable x positions down the entire campaign, dilating it every 20 px
    by how far a shoal can move sideways in that time and intersecting it with the water that
    is actually open. The numbers are pessimistic on purpose - 100 px/s forward, 45 px/s
    lateral, against a cruise speed of 118 and a laid current that beats 45 comfortably - so
    a level that passes has margin rather than a solution. The same sweep answers the second
    question: a required ring is only accepted if the reachable set intersects it *at the y
    where it sits*, which is what "a ring you cannot get to" actually means.

23. **A mandatory ring and a forced camera drift were asking for opposite things.** Dashed
    rings ending the run is the design the campaign is built on, and the first version simply
    added the failure. Measured, it killed the scripted player by `sweptAway` on every seed:
    the ring asks you to stop and hold a body of fish still for half a second, while the
    drift that punishes stalling keeps running. `World.ringEase` drops the forced drift to
    0.3× while the shoal is within 300 px of an unheld required ring. Levels cleared by the
    competent bot went **2.4 → 2.6** and, more to the point, the deaths stopped being about
    the clock. It is also the better game: the one place that demands stillness is now the
    one place where time relaxes.

24. **The probe had to be told the rings exist, and then told they are not a detour.** The
    aim bot steered for gaps only, so it lost every run to a ring it never looked at - the
    instrument was measuring a game nobody was playing. With ring-steering added it clears
    two and a half levels. The second measurement is the interesting one: a bot that merely
    *ignores* rings still holds 5-17 of them per run, because a required ring is placed on
    the line the section already asks for. So "a missed ring ends the run" cannot be
    falsified by neglect, only by refusal - `dodgeRings` steers deliberately away, and dies
    of `ringMissed` on all five seeds within 12 seconds. Both bots are kept.

25. **Pressure is per level now, not per run.** The endless ramp made the sixth level hard
    because of how long you had been playing rather than because of what was in it, and it
    punished a player who took the first level slowly. `pressure` resets at every level and
    caps at 0.55 there; each level carries its own `pace`, `roughness` and `swirl` instead.
    Across the whole campaign pace moves 0.72 → 1.0 - the game is not supposed to get faster,
    it is supposed to ask for more precision. What escalates is gap width (the narrowest gap
    per level goes 0.40 → 0.26 of the play field, from a 0.58 opener), how many rings are
    mandatory (4 → 5 of the 6-7 per level) and what else is in the water: nothing, then a
    chicane, then standing currents, then hunters.

26. **The presentation was tuned for an arcade game.** Three things carried that and all
    three are dialled back rather than removed: shake peaked at 13 px on a phone held at
    arm's length (now 5.5, decaying half a second slower), the palette crossfade ran at
    0.55/s where the change is catchable (now 0.28), and every sound had a millisecond
    attack. In the audio the attack floor is now 40 ms - nothing in the game can click - and
    everything except the sub drone goes through a generated 5.5 s convolution tail. The bed
    is a four-note open chord (no third, so it cannot suggest a mood) with three amplitude
    LFOs at 0.037, 0.053 and 0.071 Hz; the rates share no factor, so the sum does not repeat
    inside a session. The one held voice is the ring shimmer, which rises with how full the
    ring is - letting the shoal drift out of a ring is audible before it is visible.

27. **Decorative life, at a tenth of the contrast of anything that matters.** `Decor.ts` is
    generated in bands like the course, draws no fills and owns no colour - it borrows the
    zone palette, so it is always *in* the water rather than on it. Rooted kinds hug the
    edges; only the transparent drifting kinds cross the middle where the shoal lives. The
    first pass drew seagrass as five parallel quadratics of equal length, which on screen is
    a hatch mark: it read as a scratch on the glass. Blades now fan from one root, differ in
    length and end in a curl. Cost, measured on the deep-run e2e with the whole campaign
    built, three hunters and seven standing currents live: **82 fps** on the harness, i.e.
    still frame-capped rather than decor-bound.

28. **The rock was three flat circles, and looked like three flat circles.** The union of
    blobs was filled once for the rim and once for the body, which gives a silhouette and
    nothing else. Every attempt to add interior detail per blob failed the same way: a
    stroked crest arc on each circle turns a fifty-circle gate wall into vertebrae, because
    the arcs of covered blobs still draw. The fix is that *every* pass is a union fill of
    the same circle list at a different radius and offset - `Renderer.blobPass` - so
    internal seams can never appear. A rock is now six fills: silt halo, a dark lip one
    pixel down, a lit crest two pixels up, the body gradient, and two terraces inside the
    big masses only. The bevel is the whole trick: fill the mass bright and slightly high,
    then fill the body over it, and what survives is a lit top edge. The first version of
    the crest ran at 0.9 alpha over a brightened rim and read as neon piping, which a
    screenshot caught and no test could have.

29. **The line that flashed across the screen at every cleared section is gone.** So is the
    red one for a broken streak. Both were scoreboard grammar - a rule drawn *over* the
    water to announce that a number changed - in a game whose whole presentation argument
    is that nothing should interrupt the picture. What replaced them is continuous: a
    hairline rail at the right edge with a tick per section, a fill that grows with the
    water rather than jumping in sixths, and a head dot at the shoal's position in the
    level. `World.levelProgress` had to become continuous for it (it stepped once per
    section, which is fine for a difficulty ramp and useless for a progress indicator). A
    broken streak now cools the rail for half a second instead of drawing anything. The
    percentage is deliberately not printed: a number would be read, and reading is the one
    thing the rest of the screen is arranged to avoid.

30. **Something passes behind the water, rarely.** A leviathan in the upper levels,
    at a 10-14 % chance per 620 px band - so it is
    something you might see once in a level and might miss entirely, which is the only way
    an event you cannot interact with stays worth having. It is far-layer only, so it is
    always behind the rock and can never be mistaken for a hazard. Canvas2D has no
    cheap blur, so the softness is faked the way distance actually works: the leviathan is
    filled with a radial gradient that never reaches its own edge, so there is no edge to
    resolve. At the small decor's 0.055 alpha it was invisible against the background
    gradient; it runs at about three times that.

31. **The campaign is an ascent, and the surface is the revelation.** The six authored
    levels now begin at 6000 m and move through 4000, 2500, 1000 and 200 m before ending at
    0 m. This is not carried by labels alone: palettes brighten monotonically from
    violet-black to sunlit cyan; canyon walls give way to empty water, current, life and
    rays; the audio bed sheds depth instead of accumulating it; and the old per-level rail
    is now one bottom-to-top mission spine with six nodes that never resets. In station VI
    the water ceiling approaches as a refracted horizontal line. Clearing its final section
    sweeps daylight down the frame and opens a broad surface ripple before the results shell
    appears. Completion therefore has a picture of its own, not just different copy.

32. **The rock had a silhouette and no surface.** Union-filling the blobs (decision 28) fixed
    the seams and left the masses reading as holes cut in the water: a dark shape with no
    light on its edge is not a solid, it is an absence. The fix is that `Stone.ts` now returns
    a **crest** with every mass — the contiguous run of hull edges whose outward normal faces
    up the course, resampled every 15 px with its normal. Convexity is what makes this cheap
    and safe: the edge normals of a convex outline rotate monotonically, so the up-facing
    edges are always one unbroken arc, and it is computed once per mass (masses are cached for
    the life of a run) rather than per frame. Everything else follows from having that arc:
    a rim light along it, growth planted on it pointing along its own normals, an occlusion
    pass under the mass and a per-mass gradient rather than one gradient stretched across the
    whole screen. Per-blob decoration is still banned for decision 28's reason; the crest is
    derived from the *hull*, so a fifty-bead gate wall gets exactly one lit edge. Materials are
    per level (`Motif.material/fringe/strata/sheen`): unlit fractured obsidian with a mineral
    seam on the trench floor, bare basalt in the black water, scoured stone trailing silt in
    the current, coral crust, new growth, and finally warm sunlit stone with weed on it. The
    `sheen` numbers climb 0.42 → 1.3 across the campaign, so the ascent is legible from the
    rock alone with the palette ignored.

33. **A vortex was a spiral drawn over the water. It is now the water.** Two Archimedean arms
    of constant curvature, constant width and a hard start and stop read as a pencil doodle on
    the ocean — correct about the spin and wrong about everything else. `Whirl.ts` derives
    every element from `CurrentField`'s own profile (`v = strength · sin(pi·d/R)`, tangential):
    the light collects in a ring at half the radius because that is where the water is
    fastest; the filaments are wound by the *shear* (`sin(pi·u)/u`, large at the eye and zero
    at the rim), so they curl tight in the middle and hang straight at the edge the way real
    eddies do; and a dozen entrained motes orbit at the true local angular speed with a trail
    length equal to the distance they cover in a tenth of a second. `tests/whirl.test.ts`
    asserts that against the simulation directly — `omega(d) · d` is the speed the shoal will
    actually feel — so the marker cannot drift away from the hazard it marks. The eye and the
    rim are still drawn, because where the current stops mattering is information the player
    is owed.

34. **The hunter was a hazard marker with a fin.** A six-point wedge inside a red disc reads as
    "danger, radius 88 px", not as an animal, in a game whose entire pitch is that the ocean is
    a place. It is now a top-down pelagic predator: pointed snout, widest at the pectorals, a
    narrow peduncle, a lunate tail with a long upper lobe, a dorsal seen edge-on as a slim lens
    on the spine, three gill slits, and countershading across the flank. It flexes as it swims
    on the same travelling-wave idea as the fish, at a third of their amplitude — and it
    *stiffens* as it commits, because the last metre of a strike is a straight line. Red was
    doing the work of shape and is now spent only where the player has to react: a dashed arc
    at the distance a strike actually lands (1.9 × size, just outside `BITE_REACH`), a warm rim
    the instant it commits, and the eye. The dread wash under it went the other way entirely —
    fear in water is not a light coming on, it is the room closing, so the wash and the screen
    vignette are now a *darkening* with almost no red left in them.

35. **The ending was a wipe. It is now four sentences long.** Clearing the last section used to
    sweep daylight down the frame in 1.9 s and hand over to the results dialog — a transition,
    where arrival is the one thing six thousand metres of climbing has been promising.
    `Surfacing.ts` runs *lift* (the pressure comes off, the refracted net of the surface
    resolves overhead), *ascent* (the ceiling comes down to meet the shoal, shafts converging
    on the crossing point), *breach* (bloom, spray on parabolas, the first horizontal rings in
    the game) and *sky* (sun, haze, a sea in perspective with glitter on the swell, and the
    shoal breaking clear of it in slow arcs). Three details it needed:
    the sequence draws on the **renderer's own clock**, because `run.time` stops the instant a
    run ends and the whole ending happens after the last step; the results dialog waits
    `SURFACE_SKY_AT + 2.6 s` instead of 2.2 s, because the wait *is* the reward; and the
    closing title is deferred until there is air to put it over and re-inked dark, since a
    white heading on a bright sky is a heading nobody reads. Sound got the one thing the rest
    of the game never does — `AudioEngine.surface()` sweeps a filter *upward* and resolves,
    cued at the breach rather than at the event. Reduced motion kept the film and dropped the
    spray, the leapers and the drift; low quality dropped the net and the spray.
    (Superseded: the reduced-motion switch is gone, so the spray and the leapers are always
    part of the film, and the quality cuts follow the frame-rate ladder described under
    decision 18 rather than a setting.)

36. **Every level's water got a second plane.** The backdrops were one plane of decoration each
    — a painted cloth at a fixed distance — so the levels looked like pictures of places rather
    than places. Each one now moves at two or more rates, and the detail carrying the level's
    name sits on the plane nearest the camera: two cliffs per side in the trench, traced
    through their points as curves instead of facets, with embers climbing out of the vents;
    bioluminescence that swells and goes out over seconds in the black water, plus one distant
    pulse that never comes closer; three depths of ribbon and a shear front in the current;
    the campaign's first light-from-above in the rise; dust in the last of the light at the
    light line; and a caustic web under the surface, which is the one thing in the game that
    only exists because there is air up there. The shared shaft helper is the same fix applied
    six times: a light column filled with a *horizontal* gradient has no sides, so it is light
    in water rather than a glass panel.

37. **The ocean could not kill anybody, because the shoal swam at the speed of the ocean.**
    The forced drift is supposed to be the clock: stall, and the water leaves you behind.
    Measured, it never did. A shoal with *no input at all* made 50-58 px/s up the course,
    the drift at station I is 49 px/s, and the camera's monotone follow then locked onto
    the shoal - so the strand line could only ever reach a shoal that was physically
    blocked by rock. `sweptAway` existed for passive players and for nobody else, and the
    sweep showed it: a *handicapped* panic-flick style scored 2010 against a careful
    style's 2047, i.e. 1.02x, because sloppiness cost nothing the ocean could collect on.

    The cause was one line: the migration term aimed at `cruiseSpeed`, which is the speed
    every boids term aims at - alignment, cohesion and separation all use it as their
    target magnitude, so it could not be lowered without changing what a shoal *is*. It is
    now its own number, `Tuning.migrationSpeed`, and the search for it was run over six
    values (5 seeds, 6 styles each):

    | migrationSpeed | passive dies | steering secs / gates | steering ÷ panic-flick |
    | --- | --- | --- | --- |
    | 118 (= cruise, before) | 12.6 s | 47.3 s / 5.4 | **1.02** |
    | 105 | 12.3 s | 43.3 s / 4.6 | 1.21 |
    | 95 | 11.9 s | 36.1 s / 3.4 | 1.16 |
    | 85 | 11.2 s | 38.7 s / 3.8 | 1.32 |
    | **75 (shipped)** | 10.4 s | 39.4 s / 4.2 | **1.53** |
    | 62 | 9.3 s | 36.1 s / 3.2 | 2.06 |

    62 separates the styles best and is too mean: the careful style loses a fifth of its
    run, and with it the probe's *other* discrimination - at 62 the careful and the
    late-sharp styles clear 3.2 and 1.0 sections, which collapses "gesture style changes
    the outcome measurably" to a 0.6-section difference. 75 keeps a competent run
    at ~39 s with four sections cleared, kills a neglected one in ~35 s of campaign water,
    and restores the thing the whole probe exists to check - `tests/playability.test.ts`'s
    skill-tier assertion passes again. A shoal now makes about 45 px/s unaided against a
    drift of 49 (station I) to 105 px/s (station VI, fully pressured), so *the water the
    player lays is what keeps them on screen*, which is the sentence the game opens with.

    The warning had to move with it. The red flash at the bottom of the screen used to
    start at the strand line, two thirds of a second before the run ends - a verdict, not
    a warning. It now begins as a dark, warm shade rising from the bottom edge when the
    shoal sinks past four fifths of the screen, and only turns red once the water is
    actually taking them.

### The fourth pass: the thing under the game

(38 is the shoal-size and spacing sweep already cited from `tuning.ts`; it has not been
written up here yet.)

(39 is not missing by accident. The numbers here are addresses — `tuning.ts` cites 37
and 38, `Medium.ts` cites 50, `Renderer.ts` cites 51 — so a withdrawn entry leaves its
number behind rather than moving everything after it. The breath it introduced is still
in the game, and `src/sim/Breath.ts` documents itself.)

40. **Every sound in the game arrived at the exact centre of the head.** Which is the one
    thing no sound in a body of water ever does. `connectTrack` now takes a pan, and the
    dry signal goes through a `StereoPannerNode` while the wet send stays centred — one
    fixed room that everything happens inside, which is also how distance actually sounds.
    A stroke comes from where the finger is, a loss from where the fish died, a ring's
    three bowls open outward from the ring, and the held shimmer keeps a panner of its own
    so it tracks the ring the player is working. No `StereoPannerNode` (old WebKit) means
    mono, which is a degradation and not a failure.

    Two voices are new, and both exist to reward a hand rather than to report an event:

    - **The silk.** A second, much quieter layer on every stroke, in the 2.6–5.2 kHz band
      that whispered and brushed sounds live in, whose level goes as `(1 - speed)²`. It is
      inaudible on a flick and it is the loudest thing about a stroke drawn slowly across
      the glass. The player is rewarded for the hand this game wants them to have, by the
      one channel that can do it without a number on screen.
    - **The hush.** A swell under a closing filter, panned hard to one side and flipping
      side on every play. The off-centre position is the whole of what makes it work: a
      hush in the middle of the stereo image is a hiss, and the same hush at 80% left is
      somebody breathing out next to you. It used to be cued on the *turn* of the breath
      rather than on its depth, and an out-breath and a sound starting on the same instant
      was the entrainment cue it existed for; that trigger went with the mode that gated
      it, and the voice is now auditioned from the admin surface.

    One latent bug fell out of writing this: `World.ringEase` survived a `reset`, so a
    restart of "the same water" could open with the eased drift the previous run's last
    ring left behind. Measured on the playability probe, the numbers do not move.

41. **The water was a rumble, and a rumble is pressure.** The bed's largest layer was brown
    noise under a 300 Hz lowpass at 0.42 — an honest description of forty metres of ocean
    and the wrong sound entirely, because broadband low noise is not calming, it is *weight*.
    What actually settles somebody is small volumes of air leaving water — a spring, an
    aquarium, a kettle before it boils — and that sound is not noise at all. It is a stream
    of individual, pitched, very short events.

    So the water is now bubbles, and a bubble is a bubble: **Minnaert resonance**,
    `f0 = 3.26 / r` with r in metres. `src/audio/Bubbles.ts` takes a radius and returns the
    pitch, the length, the upward sweep and the loudness, which means **nothing in the
    water sound picks a frequency**. You pick a radius — a physical thing a level can have
    an opinion about — and everything else follows. `bubbleRadius` biases size by depth, so
    the trench floor gets the big low ones and the shallows get small bright ones: measured
    over the whole range, median pitch moves 450 Hz at 6000 m to 700 Hz at the surface, and
    that is the ascent audible in the water with the palette ignored. The decay and the
    sweep are tuned rather than derived (a real bubble's damping is a three-term model) and
    are marked as such where they appear.

    Three layers where there was one: a *body* (the old lowpassed noise at a third of its
    level and half its corner — almost inaudible, and correct), a quiet *flow* band an
    octave and a half up whose centre drifts, and the *bubbles*, which carry the sound.
    Each bubble goes into the shared room at a 0.9 send, which is what turns a countable
    stream of blips into one body of water: every bubble is still in the room when the next
    three arrive.

    Three things had to be measured rather than guessed:

    - **The rate.** Simulated over a minute at each end of the campaign. The failure modes
      either side are both real: around one a second it is a *dripping tap*, which makes
      people tense rather than calm because each event is separate enough to be counted;
      past five or six it is an aquarium pump. The shipped constants hold the audible rate
      between 2.0/s (deep, inhaling) and 3.5/s (surface, exhaling). Depth was originally
      scaling the rate by 0.6 as well as the size, which put the deep stations straight
      into the dripping tap; it scales it by 0.78 now, because size was already carrying
      depth.
    - **The attack.** This is the one voice allowed under the engine's 40 ms attack floor,
      and the exception is the same reasoning rather than a hole in it: that floor exists so
      nothing *clicks* and was written for the event cues, whose job is to be noticed. A
      bubble's whole life is 20–200 ms, so a 40 ms attack on one is not a soft bubble, it is
      no bubble. Rendered 6 s of the real stream through an `OfflineAudioContext`: peak
      0.030, nothing clipped, and **maximum sample-to-sample step 0.0025** — two orders of
      magnitude below the peak, i.e. there is no transient in it at all.
    - **The clock, which was wrong.** Counting oscillator constructions on the live loop gave
      8.8 bubbles a second against a design of 3.3. The cause was not the scheduler: the
      renderer's `frameDt` is `fixedDt` *plus* the frame cost, so it is about 2× real time
      at 60 fps and 3× at 120 — and both the breath and the bubble stream were being
      advanced by it. Every *other* consumer of `frameDt` is a decay or a fade that was
      tuned against it, so it stays; the two things that claim a rate in seconds now take a
      `performance.now()` delta. Re-measured on the same loop: **2.9/s**. The breath is
      also now computed once in `main` and pushed to both the bed and the renderer, because
      the picture and the sound have to be in phase and two clocks cannot be.

> **Superseded by decision 45.** The thermals, the gravity and the lift field described
> in 42–44 were removed: they gave act II a second verb, and this project has one. The
> record is kept because the measurements in it are real and the mistake is instructive -
> an act can measure healthy all the way to the end and still be the wrong game.
> `src/sim/Lift.ts`, `src/render/Thermal.ts`, `tests/air.test.ts` and `tests/thermal.test.ts`
> are gone with them; `tools/air.sweep.ts` stayed and now measures act II with act I's own
> scripted players. Where 42-44 name those files or `liftScale`, read them as history.

42. **The ascent begins: `Medium`, `Lift`, and one air station (phase 0 of
    docs/DESIGN-ASCENT.md).** The medium is now data (`src/sim/Medium.ts`): coupling,
    flow half-life, laid-flow speed cap, gravity, migration drive/force, and what a
    stroke deposits. Water resolves to the exact tuning fields act I always read, and the
    acceptance rule of the phase held: after the whole refactor the water sweep table is
    **digit-for-digit identical** to the pre-refactor baseline, and all of act I's tests
    pass unchanged. Air is the same simulation with six numbers swapped and a `LiftField`
    added to the one water sampler — which is why thermals cost no render code: the
    tracers draw them.

    A thermal (`src/sim/Lift.ts`) is a stream function, so the field is exactly
    divergence-free: a core updraft (inner third), a sinking rim whose integral cancels
    the core (which is also what makes the column end exactly at its radius), a vertical
    fade, and the horizontal entrainment at base and top falling out of incompressibility
    rather than being authored. The memo asked for a −60 rim against a +220 core; on a
    phone-wide screen that cannot cancel, so the rim is −strength/2 and the sweep owns it.

    Three of the memo's starting numbers died on the bench, all in `tools/air.sweep.ts`:

    - **Still-air sink is 66 px/s, not ~90.** The two-drag estimate ignores the boids
      terms, which brake a falling flock. Raising gravity until the *measured* sink hit 90
      (g=185) collapsed the straight line entirely — 0 of 11 seeds finished and H2 blew
      out to 3.7–5×. Gravity stays 135; `tests/air.test.ts` asserts the measured number.
    - **Pumping height by hand had to be priced by a cap, not by decay.** With the water's
      420 px/s ceiling on laid flow, continuous pumping climbed almost as fast as riding
      (H2 1.07, thermals decorative) and no gravity × half-life cell moved it. The air's
      own ceiling (`airFlowMaxSpeed` 240) is the number that separates the lines; at 200
      the ladder's crossings stopped being crossable at all.
    - **Rings on the riding line live at hover points, or nowhere.** A ring inside a live
      core is unholdable (fighting it fed a third of the flock to the rim); a ring in the
      ladder's overlap zones sits in 350+ px/s of combined lift. The two survivors sit in
      a top fade at 0.3–0.75 of core strength, where the ride slows to a stop on its own —
      and the station's third such ring was cut rather than forced.

    Air health at the shipped numbers, 11 seeds (`npm run sweep`): the climb line
    finishes the station on **11/11** seeds in 73 s losing 8.3 individuals; the straight
    pumped line stays viable at 10/11 in 86 s but pays 24.1; the act I water policy
    (wait, then correct) dies on every seed, as does doing nothing (8.5 s — gravity is
    the clock now, no forced drift, `pace: 0`). **H2 climb/straight = 1.15**, inside the
    1.1–1.3 band the memo demands; H1 (climb over passive) is ~100×. The gravity ×
    half-life grid that rejected the alternatives is in the sweep for re-running.

    Plumbing that came with it: levels are grouped into acts (`Act` in
    `config/levels.ts`, the air act in `config/ascent.ts`), `World` and `ObstacleSystem`
    take an act and default to act I, the corridor flood fill moved to `tests/course.ts`
    and runs over both acts, and `?act=air` is a dev door — the shell still wears act I's
    banners and depth meter, which is phase 1's work, not phase 0's.

43. **Act II, whole: six stations of air, and four things the design memo had wrong.**
    Phase 1 of docs/DESIGN-ASCENT.md. The act ships complete - `config/ascent.ts` (six
    stations, the wave tops to the tropopause), `render/Flock.ts` (birds), `render/Sky.ts`
    (six backdrops), `audio/Wings.ts` (the air's sound), four air palettes, the falcon,
    and an altimeter. Act I is untouched: **the water sweep table is still digit-for-digit
    identical to the pre-ascent baseline**, which is the same acceptance rule phase 0 set.

    The parts that came out as designed are the ones derived from something physical.
    **`Wings.ts`** is `Bubbles.ts` one medium up and obeys the same rule - nothing picks a
    frequency. You pick a wing span; an allometric line gives the beat rate (`4.0/span^0.9`
    puts a 1.2 m gull at 3.4 beats/s), the tip covers two spans a cycle, the boundary layer
    is 3% of the chord, and Strouhal on *that* gives the noise band: ~200 Hz for the biggest
    wing here, ~860 for the smallest. Two consequences worth the trouble: the whoosh pitch
    works out to a fixed multiple of the beat rate, so a flock is in tune with its own
    rhythm without anything tuning it; and a wing is broadband where a bubble was a
    resonator, so the medium changing forced the *synthesis* to change with it.
    **`Flock.ts`** inverts `FishShapes`' spine-and-wave for a body that is mostly wing, and
    reuses the ray's one real observation - from directly overhead a wingbeat is a span that
    foreshortens. The flock **beats on the inhale and glides on the exhale**, which is the
    most visible place the 11 s breath touches the game and is a bird fact rather than an
    effect; `Wings` quiets the stream on the same half of the cycle.

    Four things the memo asserted did not survive contact with the probes.

    - **"A thermal is a core with a −60 rim against a +220 core."** The cancellation that
      makes a column compact fixes the rim at `c/(1−c)` of the core, so a core a third of
      the radius wide buys a rim *half* the core's strength - packed into the two thirds of
      the radius a flock actually occupies. Because a bird that sags out of the core gets
      less lift and sags further, that is a positive feedback: measured, the flock strung
      out over 900 px vertically on a body 90 px across, shed its tail, re-formed, and did
      it again every station. `CORE` is a fifth now, which is both the memo's ratio and what
      a real thermal looks like - the compensating downdraught is spread far wider than the
      core it balances. The skill is still centring on a narrow core; the punishment for
      missing is a soft sink instead of being pulled to pieces.
    - **"Consecutive columns need only be within a hard stroke of each other."** A handover
      is a *lateral* crossing as well as a climb, and a flock crossing 190 px sideways is
      sinking at 66 px/s the whole way. Twenty-three pixels short of the next core ended a
      run: the moment it left the old column it lost the height it needed to enter the new
      one, and there is no way back down a ladder. Consecutive cores now genuinely
      **overlap**, by 60 px or more, and the ladder zig-zags between two lanes half the
      field apart so no two rungs ever stack.
    - **"Growth is the score."** It is, but not at the water's price. `inertiaPerAgent` is
      **added mass** - the fluid a body drags with it - and air is about a thousandth of
      water's density, so the water's value in air is a factor-of-800 modelling error. At
      the water's value a grown flock's boids terms were divided by 1.3 while gravity was
      not, cohesion lost to weight, and the lift field amplified the result. Air pays a
      tenth. Act II's *rings* are also small - six birds against act I's eight to fourteen -
      because a thermal is a fixed size and a flock that has outgrown the core is standing
      in its own sinking rim. The air putting a ceiling on how much life it will carry is
      the mechanical version of what act III opens with.
    - **"The air is thin, so a stroke does little."** True, and not sufficient: what
      matters is what a stroke does *relative to a thermal*. At the water's speed ceiling a
      player could hand-pump a climb of 86 px/s against a thermal's 115, so the scripted
      line that ignored every column out-scored the one that rode them - the thermals were
      a tax with a picture on it. `airFlowMaxSpeed` (215, from a four-point grid) is the act's
      premise as a number.

    Two smaller ones fell out of the same measurements. A **sinking column's rim lifts** -
    what goes down comes up around it - so a wide sink quietly inflated the hover ring
    behind it (199 px/s where 122 was wanted); sinks are narrow now, and never between the
    two lanes, because in the middle one was a toll on every crossing rather than a hazard.
    And the **straggler cull** is a water mechanic: with no forced drift and a medium whose
    lift varies by position, a flock strings out for reasons that are the act's subject
    rather than the player's mistake, so air is four times more forgiving about individuals
    while the *body* falling out of frame still ends the run.

    The one genuinely new thing in the simulation is the **falcon**: the same hunter with
    its patrol turned through ninety degrees. It enters from behind the flock and overtakes,
    which makes it the first hazard in the game you cannot see by looking where you are
    going - every threat in act I arrived from the direction the shoal was already facing.

### Act II health at the current defaults

*As measured when decision 45 rebuilt the act (it sits here because 43-44 above are its
prehistory). It describes act II at six stations of about ten minutes, before the campaign
was rebuilt to its present length; for today's numbers run the sweeps named in
[docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md).*

`npm run sweep`, 11 seeds, six stations, **act I's own scripted players**:

| style | secs | height | gates | resc | lost | spread | score |
| --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 25 | 1 073 | 1.0 | 9 | 0 | 51 | 491 |
| early soft (safe line) | 215 | 19 758 | 22.3 | 175 | 139 | 102 | 12 752 |
| greedy (rescue line) | 89 | 7 132 | 8.3 | 66 | 23 | 91 | 4 154 |
| splitter (split line) | 57 | 3 997 | 4.6 | 36 | 14 | 112 | 2 461 |
| late sharp (handicap) | 174 | 16 177 | 18.0 | 141 | 112 | 117 | 8 756 |
| panic flick (handicap) | 55 | 3 982 | 3.9 | 33 | 16 | 105 | 1 960 |

**Skill multiplier 22x over doing nothing**, against the water sweep's 17.9x, and 5.5x over
the best handicapped style against the water's 1.53x. Thinner air is a different game, not
a mushier one - and unlike the first act II, it is a different game *of the same kind*.

**Open, and measured**: the greedy line scores **0.39** of the safe line, which is the exact
inverse of act I's still-red probe (1.99 the other way). In a windier medium a detour off the
line costs ground the drift immediately takes, so a policy that chases every ring
unconditionally is a handicap rather than a strategy. The rings are still worth taking when
a run is going well - the safe line collects 175 of them - but "chase everything" is not the
optimum it is in water. Both of these are the same open question from opposite ends: what a
carried individual is worth against a cleared section. It wants one scoring sweep, not two.

44. **Act II, looked at: seven ways the air was still wearing the water's clothes.** The
    first playable pass of the act shipped mechanically sound and was rejected on sight -
    the report, in order: the birds read badly, the water's sounds play in the air, solid
    rock hangs in the sky, a whale sings in a storm cloud, and finishing the act plays the
    *water's* ending, copy included ("you broke through the waterline", eleven kilometres
    up). Every one of these traced to one of two root causes: a table that was not
    act-aware, or a default that silently meant "water". None of them was a balance
    problem, so the sim numbers did not move and the sweeps were left untouched.

    - **The birds were chevrons.** `sweep` 0.12-0.62 put a wingtip more than a body
      length behind the shoulder, and straight-segment tracing at eleven pixels made
      every bird a white arrowhead - the flock read as a field of cursor glyphs. The
      sweeps now sit in 0.08-0.38 (the falcon keeps the maximum: a threat may look like
      one), the leading edge bows forward and the trailing edge carries the chord as one
      quadratic each, and each species gets a second fill: **dark outer primaries** -
      the gull's field mark, and most of what separates "birds" from "white shapes" at
      flock distance. Same batch discipline as the fish; the two-tint phase split was
      dropped for birds because both tints clamp to white anyway.
    - **`motifForSection` indexed the water table unconditionally**, so an air gate was
      painted as the water level with the same index - a slab of scoured midnight basalt
      in the cloud belt. The `material: 'cloud'` path existed and no real frame ever
      reached it. It now takes the act key; `tests/motifs.test.ts` pins the regression.
    - **Cloud got a real paint path**: no strata, no fractures, no polished dome; a soft
      cool under-shadow instead of near-black (the shade of a cumulus is sky through
      vapour, and a near-black drop under a bright mass turns the sky into a cave); a
      shaded flat base; and jag 0.06-0.11 across the four cloud stations, because a
      smooth capsule painted white is a dirigible. A new `Motif.daylight` field unwinds
      the underwater darkening for the air's true stone (sea stack, headland) - a rock at
      noon is not a hole in the daylight. Water motifs carry 0 and paint digit-for-digit
      as before.
    - **The thermals were invisible.** Phase 0's "the tracers draw them" is enough for a
      hazard and not for the act's whole resource. `render/Thermal.ts` is `Whirl.ts` one
      medium up: a sided-nowhere radial glow the width of the core, motes riding at the
      field's own speed for their radius (streak = distance covered in a tenth of a
      second - the whirl's honesty rule), rim sink drawn cold, and a sink column is the
      same code upside down with no glow. `LIFT_CORE`/`LIFT_RIM` are exported so the
      drawing cannot drift from the field; `tests/thermal.test.ts` holds core motes to
      the core.
    - **The bed was underwater at altitude.** `setDepth(1 - ascent)` in air meant the
      drone opened the act at hadal darkness; air now pushes depth 0 and `altitude01`
      carries the evolution. The whale was scheduled unconditionally - the single most
      wrong sound the game ever played - and is now the water's voice only; the air's
      rare distant voice is **thunder** (three staggered low swells, no crack, deep into
      the room), gated to the altitude band that has weather in it (the rain and the
      storm), on the whale's mixer track - renamed "Distant voices", which is what the
      slot now is. The air also gets **gusts** (Poisson, on the exhale - the same half
      of the breath the water gave its bubbles, occupied by the medium instead of the
      carried life), a stroke that moves *air* (higher, shorter, breathier - the one
      sound the player makes sixty times a minute had to change with the medium), and a
      hush that is a glide-swish rather than bubbles.
    - **The act got its own ending.** `render/Release.ts`, four movements on the
      renderer's clock, deterministic, mirroring `Surfacing.ts` structurally and
      inverting it emotionally: *thin* (the blue runs out, stars resolve), *still* (the
      flock locks its wings - the first true stillness in an act about staying inside
      moving air), *let go* (a stream of pod-gold motes rises out of the flock and keeps
      rising: what the rings gave is what goes on without a wing under it - DESIGN-ASCENT
      §8's handover, drawn), *night* (the hold: stars, the lit anvil below, the climbing
      line - which is also act III's first frame). `AudioEngine.release()` is the sound
      of less: three high bells climbing with long tails, a sweep that thins to nothing,
      and the wingbeat stream damped underneath. The shell's completion and fell-behind
      copy branch per act (`ResultView.air`), because "the current pulled away from you"
      is not a sentence the sky can say.
    - **Odds and ends the medium check caught**: underwater caustic bands drawn over the
      sky (skipped in air - the surface is below you), and the stroke wake hardcoded to
      water-blue (now the zone's tracer colour).

    What did *not* move: every tuning number, every level file number, H1/H2, and the
    open items above (H2 scoring, act length, the greedy-rescue probe - still red at the
    same 1.8856 with and without this pass, verified by stashing). This was the pass
    where the air stopped being the water with the colours changed, and it was almost
    entirely a rendering, audio and copy pass.

45. **Act II was a different game, and it has been rebuilt as this one.**

    The first playable act II was mechanically sound, thoroughly measured, and rejected on
    sight for a list of reasons that all turned out to be one reason. The report: the birds
    read badly, the obstacles were the water's walls with a pale coat on them, a shark was
    hunting at eleven kilometres, the thermals were a second game bolted to the side of the
    first, and the ending was a diagram of a handover rather than a reward for eighty
    kilometres of flying.

    The root cause is worth stating plainly, because it is the kind of mistake that
    measures well all the way to the end: **act II had its own verb.** Slowblue has exactly one
    - *steer the medium, and the life in it follows* - and phase 1 replaced it with *find
    the resource*. Every probe in `tools/air.sweep.ts` was written to measure the new verb,
    so every probe said the act was healthy. It was healthy. It was not this game.

    So the thermals are gone: `Lift.ts`, `Thermal.ts`, `gravity`, `liftScale` and both of
    the act's bespoke scripted players are deleted rather than disabled. Air is now the
    water's physics with the water's density taken out - lighter grip (`airCoupling` 2.5
    against the water's 3.4), a gust that outlives the hand that laid it
    (`airFlowHalfLife` 1.7 against 1.05, the one place air is the more generous medium),
    a higher ceiling on laid speed, a tenth of the growth cost, and a forced drift making
    the clock in both acts. **The acceptance rule was that act I's scripted players fly
    act II with nothing added and nothing explained**, and they do; that is the whole
    argument, and the sweep table above is its evidence.

    Four things came out of the rebuild that were not obvious before it.

    - **`airMigrationSpeed` had to go *down*, which is decision 37 one medium up.** A bird
      flies faster than a fish, so it started at 92 against the water's 75, and that is
      true and irrelevant: a body of life that makes way faster than the drift carrying
      the camera can never be left behind. Measured, a flock with *no input at all*
      survived 96 seconds, cleared five sections and collected forty birds from rings it
      merely drifted through. At 48 doing nothing is over in twenty-five seconds and the
      skill multiplier is 22x. Wings keep a flock from falling behind; the wind is what
      carries it.
    - **Cloud does not make rock's shapes, and it does not make rock's silhouette
      either.** Six air-only archetypes replace the water's six (`bank`, `tower`, `pass`,
      `wisps`, `rotor`, `raptor`), built from puffs whose radius and sag come from a
      position hash instead of a chain of identical beads. More importantly `Stone.ts`
      grew a second silhouette: a rock is the **convex hull** of its circles, and a cumulus
      is their **union**, sampled radially. Convexity is exactly the property a cloud does
      not have - run one through the hull and you get a smooth lozenge - and a star-shaped
      polygon buys the lumps back, can never fall inside a collision circle, and comes out
      already sorted by angle, which is what makes the lit crest as cheap as the convex
      one. `RockPaint` then paints the lobes as one union fill of the same circles shrunk
      and dropped, which is the only way to get interior detail on a blob mass without the
      seams decision 28 was written about.
    - **The birds were the planform, not the tint.** `Flock.ts` is rewritten around the
      thing that actually carries a bird's silhouette from above: the wing's leading edge
      and its chord, each sampled at five stations, exactly as `FishShapes` samples a
      profile down a spine. The difference between a shearwater, an albatross, a buzzard
      and a swift then falls out of two rows of numbers. Two bugs were found by looking:
      the body was twice as fat as a fish of the same length (a bird is a fuselage with
      wings on it - 1.55 px of half-width, not 2.7), and the wingtips were **cancelling**.
      A whole species is one `fill()`, Canvas2D fills nonzero, and mirroring a quad by
      negating its across coordinates reverses its winding - so any two birds close enough
      to overlap punched each other's dark primaries out. On a flock that is not an edge
      case, it is the normal state. The mirrored side is emitted in reverse now.
    - **A raptor commits by folding, and that is the whole reason it is a separate file.**
      `Raptor.ts` is not `Hunter.ts` with feathers: a shark commits by going *rigid*,
      which is subtle to draw, while a falcon pulls its wings in until it is a teardrop
      with a beak. So `lunge` interpolates between two planforms rather than tinting one -
      the player reads the commitment from the silhouette at flock distance, before any
      warning colour arrives - and the threat field is its **shadow** rather than the
      water's darkening, because that is what a bird underneath one actually gets.

    Two smaller corrections fell out of looking at real frames. Cloud is lit with the
    crest's wide dim halo and **not** its thin bright core, because a hairline on a cumulus
    is a polished pebble (found on a lenticular over the squall). And the flock's additive
    glow is at a third strength in air: underwater a soft additive smear reads as light in
    the medium, and against a bright sky the same fill has a visible edge, so every bird
    acquired a sticker behind it.

46. **The ending is the atmosphere, seen from outside it.**

    Act I ends by giving the player the thing the act was about: a sky. The first act II
    ending withheld the equivalent - it faded the blue out, held on a dark frame and let
    some motes go. `Release.ts` is rewritten around the payoff the act had actually spent
    eighty kilometres earning: **from the top of the atmosphere you can finally see the
    atmosphere.** Five movements - the wind stopping, the air running out with the stars
    resolving in order of brightness, the curve of the planet drawing itself across the
    frame with the whole sky resolved into one bright band a few pixels thick, the sun
    clearing the limb with a single slow sweep of light that catches each bird's wing as it
    passes, and then the hold, where the carried life rises out of the flock and keeps
    going. Everything the game has ever happened in, at once, thinner than the flock is
    wide.

    Three details it needed. The limb's air band is **one radial gradient centred on the
    planet's own centre**, which is what a limb *is* and costs one fill instead of a stack
    of strips. The film is fourteen seconds against the old eight, and the results dialog
    waits for all of it, because the wait is the reward. And `AudioEngine.release()` was
    written as pure subtraction - correct about the tropopause, wrong about this ending,
    which is the light coming *back*: it is now the widest, quietest thing the engine can
    make, a low open fifth swelling under four bowls that climb an octave and a half with
    tails long enough to overlap into one chord.

47. **The ascent gets darker, and it is asserted rather than described.** The six air
    palettes now darken monotonically from the wave tops to the mesopause, which is
    physics rather than mood - sky is blue because there is air overhead to scatter
    sunlight in it, and by 25 km there is about a fortieth of it left. The last two
    stations are real places (nacreous cloud in the stratosphere lit from under the
    horizon; noctilucent cloud at 82 km, the highest cloud there is), which is also what
    lets "every obstacle is cloud" hold all the way to the top instead of running out of
    weather. `tests/zones.test.ts` holds the monotonicity, because a palette table is
    exactly the kind of thing a later edit brightens one entry of without noticing.

    One entry pulls against the rule and is authored anyway: the anvil is written darker
    than the squall below it, when coming out of the top of a storm genuinely feels like
    arriving in the light. The ascent's argument wins, and it wins honestly - at 11 km the
    sky overhead really is several stops darker than anything at 4 km, and the bright thing
    in that frame is below you and getting further away.

48. **The birds again: what "lifelike" turned out to mean.** Decision 45 rebuilt the
    flock around the planform and it was still rejected on sight - the report was that
    the wing ends should not be a different colour, that a bird should be one silhouette,
    and that they should *flap as they fly*. Every one of those turned out to be a
    different symptom of the same three mistakes, and all three were found by drawing the
    thing and looking at it rather than by reasoning about it.

    - **Half the beat was frozen.** Decision 45 drove the whole wingbeat from one
      asymmetric fold - `max(0, -sin)` - on the correct observation that a wing is held
      out through the power stroke and folds on the recovery. Rendered as eight frames of
      one cycle, that gives *four pixel-identical frames*, a fold, and four identical
      frames again. It is a switch, not an animal, and it is the exact failure
      `FishShapes` was written to avoid: a wave with no travel in it. A beat needs **two**
      motions - a continuous fore-and-aft sweep of the hand that never stops moving, and
      the asymmetric fold on top of it. One alone is a rubber band or a windscreen wiper.
    - **The fold was twice too deep**, which the first fix made worse. At 0.6 the wing
      lost two thirds of its span on every recovery and the bird became an arrowhead once
      a beat. Seen from directly above a real upstroke costs about a quarter of the span;
      the rest of what the eye reads as a beat is the hand sweeping back, so that term is
      now the larger of the two and the flap amplitudes are roughly halved.
    - **The proportions were a cross.** This was the big one, and it is a measurement
      rather than a taste: a bird seen from above is **about two and a half times wider
      than it is long** - a shearwater is 90 cm across and 35 cm bill to tail, a buzzard
      120 against 52 - and its wing meets the body over roughly *half* the body's length.
      The table had the span at about 1.4x the length and the wing root at a fifth of it,
      with a neck in front and a spike behind, so the silhouette was a stick with a short
      bar across it. Spans went up by half, the wing root chord roughly doubled, and
      `TAIL_BASE` was moved so the trailing edge of the wing root lands exactly on it -
      which is what a bird's secondaries actually do. There is no bare body between wing
      and tail on a real bird and there is none here now.

    Two smaller ones came with them. The `lead` and `chord` rows now have a visible
    **wrist** in them - three nearly-flat numbers for the arm, then a run for the hand -
    because a smoothly-swept wing with no kink is a paper aeroplane. And the wingbeat's
    *rate* is now varied per individual as well as its phase: `variation` is a narrow
    0.92-1.08 and had to be widened four-fold before it read, but a flock where every bird
    beats at the same tempo is a flock with a metronome in it.

49. **The flock changes colour halfway up the act, and it is the same sentence as the
    palette.** Taking the dark wingtips out removed the thing that was doing the
    contrast work - a pale bird whose wings end dark is legible against a bright sky
    precisely *because* of the second colour - so something had to replace it, and
    "one silhouette, one colour" ruled out putting it back.

    What replaced it is the honest answer: **a bird against a bright sky is dark.** That
    is what the word means. So `shoal` is dark for the three stations flown under
    daylight and pale for the three flown above it, where the sky is black and the birds
    are the only thing the sun is still on. The flip happens coming out of the top of the
    anvil and crossfades with the rest of the palette, so it plays as a moment rather
    than as a switch: below the weather you watch the flock against the light, above it
    the flock *is* the light.

    Two consequences fell out. The **additive glow is gone in air** - a shoal is a light
    source in a dark medium and a smear under it is honest, while a silhouette that glows
    is a sticker - which also means act II's flock is now literally one fill per species.
    And **high contrast had to learn which way to push**: act I could simply brighten,
    because a pale shoal on dark water always wants to go further up, and `Renderer.contrast`
    now asks which side of the background a thing is already on. The squall is the tightest
    frame in the act (a dark flock against a dark sky) and its sky was lifted and its flock
    pushed down until the two clear 3:1.
    (Superseded in part: the high-contrast switch was removed with the rest of the display
    switches - see `src/config/settings.ts` - and `Renderer.contrast` with it. What stayed is
    the palette work: the flock flips from dark to pale halfway up the act.)

50. **The wings vibrated, and the bug was older than the birds.**

    Reported in one line - *"the wings vibrate badly, it is not smooth"* (translated from the original report) - and it was
    not a smoothing problem. Both batched animal renderers computed their animation
    phase as

    ```
    beat = clock * TAU * (base + speed / k) * species.beat + agent.phase * 2
    ```

    which reads perfectly sensibly: *it beats faster when it is working harder.* But
    `clock` is unbounded, so the rate is multiplied by a number that only grows - and a
    rate that moves therefore **rewrites the entire accumulated phase, retroactively,
    every time it moves.** `speed` is an agent's instantaneous velocity magnitude, which
    the boids wander term alone jiggles by a few px/s every step. Twenty seconds into a
    run that was worth about **three radians of phase per frame**: half a wingbeat, in a
    random direction, sixty times a second.

    The shoal has had this since the fish were first animated, and it survived because a
    randomly-flicking *tail* on a twelve-pixel fish reads as a fish wiggling. On a bird
    the phase drives the *span* - the silhouette's largest dimension - so the same defect
    is the whole animal snapping to a new width every frame, and it is unmissable.

    The rate is now constant per individual (species times a body-size term, which is a
    thing that does not change), and "beats harder when working harder" is kept as
    **amplitude**, which is bounded and cannot accumulate: a one-percent wobble in
    amplitude is invisible, a one-percent wobble in rate is a strobe. `beatPhase` is a
    named exported function for exactly this reason, and `tests/flock.test.ts` pins the
    consequence in the terms it was reported in - walk two hundred frames deep into a run
    and no single frame may move the drawn span by more than a quarter of the beat's own
    swing. It also pins the *shape* of the guarantee one level down: equal clock steps
    give equal phase steps, for ever, so nothing per-frame can be smuggled back into the
    rate later.

    Two smaller things went with it. The tempo term was **inverted** - a bigger wing beats
    more slowly, which is the same allometric line `Wings.ts` picks its frequencies off,
    so the flock's picture and its sound now disagree about nothing. And `roll` got a
    deadzone: the wander term swings a heading by about 0.008 rad a step, and without a
    floor that noise reached the span through the banking term and shimmered the wingtips
    on its own.

    Act I's fix is the same two lines and it moves nothing measurable: **the water sweep
    table is still digit-for-digit identical**, because a phase is not a force.

51. **The held birds spun on the spot, and the flock was a quarter too big.**

    Two reports, one root cause between them and one plain miss.

    **A slow bird must not be pointed at its own velocity.** An individual waiting
    inside a ring is `anchored`: the simulation pulls it toward a fixed point with
    `want = min(cruise * 0.45, distance * 2.2)`, so the moment it arrives that term goes
    to nothing and what is left of its velocity is almost entirely the wander noise. Its
    *magnitude* is meaningless and its **direction is noise** - measured live, a held
    agent's velocity heading moves by up to **1.03 radians in a single frame**. The
    renderer pointed the widest silhouette in the game at it. That is the reported
    jitter, and the same noise reached `roll`, which is why the wingbeats appeared to
    jump as well: a random cross product flickered the banking term across its whole
    range, and banking scales the span by nearly half.

    Below a walking pace the heading is now a slow deterministic wheel, blended into the
    velocity as the individual actually starts to travel, and `roll` is scaled by the
    same `drive` term. The wheel is not a fudge: a bird cannot hover, and what one
    holding station does is circle. `bearing` is exported and tested for the same reason
    `beatPhase` is - the invariant is easy to state, easy to break silently, and
    impossible to see in a still.

    The fish are left alone. They have the same shape of code and it has never shown,
    because a narrow body pointed at noise reads as a fish wriggling; act I is also the
    part of this game that was already right.

    **And the flock was simply too big**, twice over - it took two passes to accept how
    much smaller than a shoal a flock has to be drawn. Decision 48 raised the spans by
    half to fix the proportions and nobody re-checked what that did to the *area*: a bird
    is two and a half times wider than it is long where a fish is a third as wide, so at
    the same nominal length a flock covers roughly **seven times** the screen a shoal
    does. Sized by footprint rather than by length, a bird lands at about 19 x 8 px
    against a fish's 12.5 x 3.4 - shorter on its longest axis than a fish and still the
    more visible of the two - and act II gets back the thing it is about, which is an
    object being steered through weather rather than a mass that hides it.

52. **The third pass at the same report, and the first one that fixed the cause: a bird
    cannot turn in a frame.**

    Reported a third time, and precisely - *"at rest, and the birds
    that are shut in the ring: they turn left and right, they vibrate and jump about"*
    (translated from the original report). Decisions
    50 and 51 had each taken a real bug out of this loop and neither had touched what the
    player kept seeing, which is the sign that both were treating symptoms.

    The common shape of all three: **the drawn heading was a pure function of the current
    frame's velocity.** Decision 51 blended a slow bird's velocity into a deterministic
    wheel and that is correct as far as it goes, but the blend is complete by
    `TRAVEL_SPEED` - 42 px/s - and the birds in the report are *faster than that*. Every
    boids term aims at `cruiseSpeed`, so an individual caged in a rescue ring schools at
    the full 118 px/s inside a cage about sixty pixels across: it crosses its own prison in
    half a second, hits the wall, and reverses. Measured live on station II, a held bird's
    velocity direction moved by up to **3.05 radians in a single frame** - a full
    about-face - with a mean of 0.06. That velocity is not noise, which is why decision
    51's hold blend correctly declined to suppress it. It is a real, fast, genuinely
    reversing motion, and pointing the widest silhouette in the game straight at it is a
    bird flipping end for end sixty times a second.

    So the heading stopped being a function and became **state**. `steerBearing` keeps a
    per-bird angle, chases `bearing`'s target through a low-pass, and clamps the result to
    a yaw rate - 0.8 rad/s holding station, rising with real speed so a flock scattering
    from a raptor still reads as panic. A bird now physically cannot turn faster than a
    bird turns, whatever its velocity does. Measured on the same station, the drawn
    heading's worst frame-to-frame step fell from 3.05 rad to under 0.06.

    Three things fell out of it once the heading had inertia:

      - **`roll` is now read off the steered heading's own yaw rate**, which is clamped by
        construction, so the banking term cannot flicker the span - deleting the last of
        decision 51's per-step displacement cross product and its deadzone-on-noise patch.
      - **The drawn body length and beat effort are low-passed too.** Both read `speed`
        raw, and per-frame noise in a *drawn dimension* is the whole complaint - the same
        error as decision 50's, one term over.
      - **A held individual schools at 0.55 of cruise** (`Medium.heldCruise`), because the
        renderer should not have to hide a simulation that has caged animals sprinting.
        This is the one sim-side change, it is a property of the medium rather than a
        global, and **water keeps 1** - act I's numbers are defended digit-for-digit, and a
        narrow body milling hard reads as a shoal being caged, which was always right.

    The lesson is the one decision 50 half-learned: **anything that feeds a silhouette's
    largest dimension needs a bounded rate of change, not a correct instantaneous value.**
    Phase, heading, roll and size are all now rate-limited or accumulator-free, and the
    three tests in `tests/flock.test.ts` pin the heading in the terms it was reported in -
    thrash the velocity through a full reversal every few frames and no frame may turn the
    body more than a twentieth of a radian.

### Design health at the current defaults

*As measured at the end of the fourth pass, on act I's six stations before the rebuild that
lengthened six of the seven acts. Act I is the one act that was frozen at ten minutes, so
this table is the closest to what still describes it; `npm run sweep` prints the current one.*

`npm run sweep`, 5 seeds, scripted players:

| style | secs | gates | lost | rescued | re-forms | spread | score | endings |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passive | 10.4 | 0.0 | 0 | 0 | 0.0 | 47.0 | 243 | swept ×5 |
| early soft (safe line) | 39.4 | 4.2 | 46 | 13 | 0.2 | 67.2 | 1699 | swept ×5 |
| greedy soft (rescue line) | 61.3 | 7.4 | 77 | 50 | 1.0 | 70.3 | 3373 | swept ×5 |
| splitter (split line) | 45.2 | 4.6 | 79 | 22 | **1.6** | 82.1 | 2217 | **depleted ×4**, swept ×1 |
| late sharp (handicap) | 22.5 | 1.0 | 41 | 7 | 0.2 | 122.8 | 615 | swept ×5 |
| panic flick (handicap) | 28.4 | 2.2 | 45 | 13 | 0.6 | 103.7 | 1109 | swept ×4, depleted ×1 |

Skill multiplier 7.0× over doing nothing, and **1.53×** of the best handicapped style — the
number that decision 12 exists to defend, and the one decision 37 was written to restore
(it had fallen to 1.02×, i.e. sloppiness was free). Run length 39 s with nothing hitting the
harness cap. The split line is still a genuinely different shape of run: it scores above the
safe line and dies of attrition four times in five. Seed-to-seed score variation 0.58, i.e.
which water you are dealt matters more than it did as a prototype.

**Open, and measured:** the greedy rescue line scores 1.99× the safe line, against the 1.45×
ceiling `tests/playability.test.ts` asserts, so that one probe is red. It was already red at
1.73× before decision 37 and is not caused by it — a rescue-heavy run simply banks a much
bigger shoal than the scoring curve expects. Fixing it is a scoring change (what a rescued
individual is worth against what a cleared section is worth) and wants its own sweep.

> **Resolved by moving the claim, not by changing the score.** The 1.45x ceiling was being
> asserted against *generated* water, where pods are scattered along the route and a detour is
> nearly free. It now lives on the authored campaign, where it holds (`tests/playability.test.ts`,
> "the 1.45 ceiling"), and the generated-water reading (about 1.89x) stayed as the canary for
> act I's physics: the test is called "keeps act I bit-identical", and its header explains
> why it must not move.

### The admin surface: examining a thing instead of playing to it

The tuning panel answers *what does this number feel like*. Two acts of authored content
made a second question unanswerable by playing: **what is this one piece, on its own?**
Twelve stations sit behind a run that has to be flown from the trench floor to reach them,
and seven of the bed's voices are on Poisson clocks that deal a whale once a minute — so
the last station of act II had been seen a handful of times, and the whale had never been
listened to twice in a row. Neither is a balance problem; both are inspection problems, and
inspection is a tool.

> **Scale since then.** The panel was built when there were two acts. It now lists all seven
> (`CAMPAIGN_ACTS`, forty-two stations), and on a phone, where there is no address bar, it
> opens by holding three fingers still for a second and a half off-run.

`src/debug/AdminPanel.ts` is behind `?admin=1` (always on in `npm run dev`, and verified
absent from the production bundle unless asked for). Its whole claim on the simulation is
**one number**: `ObstacleSystem.reset` takes the script index to start building from, so a
run started at section N is the run that would have arrived at section N — the section is
simply the first thing in the water, at the place section 0 would have been. Everything
downstream already derives from the section list rather than from a counter: the station
index, the palette, the zone, the medium, the banner and the rail all come out right with
nothing told about the jump. `tests/admin.test.ts` holds exactly that, in both acts.

Three things fell out of building it, and all three are corrections rather than features:

* **The renderer's first frame was still act I's.** `syncRun` read the `LEVELS` globals
  while every later frame read `world.act`, which no shipped run could expose (act I is
  the only act it starts) and which paints an air station in trench colours the moment one
  is opened directly. Now it reads the world's act, like everything else.
* **The act became a property of the world rather than of the boot.** `World.setAct` swaps
  it between runs, so the admin surface plays act II out of the same world — one world, one
  input controller, one renderer, no second boot path to keep in sync.
* **A jumped run does not touch the profile.** Dropping into the fifth station and
  finishing it is not a campaign flown, so `main` skips `ProfileStore.record` for it. The
  results screen still shows what happened — seeing the thing is the point — and the
  personal bests stay something the player earned.

`AudioEngine.preview` is the same idea one layer down: every *event* is already a public
method because something in the game fires it, so the one door that was missing is into
the bed, which schedules itself. It plays each voice with the parameters the scheduler
would have used, at the panel's own depth and altitude, and nothing in the game calls it.
While the sound tab is up, `main` stops pushing the medium, the depth and the ring hold at
the engine every frame — a slider on the far side of a sixty-times-a-second write is not a
slider — and the clock under the sheet is frozen, because a run should not die behind a
panel that is being read.

### The map: the one thing the game said and never showed

> **Superseded in its picture, not in its record.** The dial described below was the second
> of five drawings of the circuit (act list, dial, cross-section, platforms, and finally the
> one that ships: a transit line, forty-two stops on one closed route, with a wider stop where
> one act hands over to the next, and `meta/Habitat.ts` putting the sea, the air and the
> vacuum behind it). The reasons it gives for rejecting the list and the altitude chart still
> hold, and so does everything under **The record** - `Profile` v3 is the current storage
> version. What changed is the geometry (`src/meta/Circuit.ts`'s own header is the current
> account), the test that holds it (`tests/atlas.test.ts`; `tests/ring.test.ts` no longer
> exists), and the title screen, where the tally now rides on a journey card that is itself the
> door to the map, not on the `THE CIRCUIT · 24/42` button named below.

The title screen has always read *seven acts, one circuit, from the floor of the trench
back to it*, and for the whole of the campaign's life nothing in the build ever drew it.
What existed was an act list: seven names in a column, which is the one arrangement that
makes a round trip look like a ladder. It could not answer the two questions a player who
puts a seven-act game down for a week actually has — *what have I finished* and *what is
left* — and the second of those it could not answer even in principle, because nothing was
stored that knew.

So the screen is a dial, and every part of it is the campaign's own shape.

**The picture.** `src/meta/Circuit.ts` places all forty-two authored stations around one
closed ring, evenly: one station is one forty-second of the way round, so twelve stations
look like exactly as much of the journey as they are. The acts are seven bands of it, each
covering its own stations and the half-steps either side, less half a gap at each end so
that seven arcs read as seven. It is pure and DOM-free on purpose: `Shell` draws SVG out
of it, and `tests/ring.test.ts` (now `tests/atlas.test.ts`) reads the same turns, so "the circuit closes" is asserted
rather than looked at.

The first version of this drew altitude instead — a profile that rose through four acts,
turned over at 460 km on a signed power curve and came back down. It was true and it was a
*chart*: two dashed reference lines, two axis labels, and a shape that has to be read
before it can be seen. A campaign screen wants to say where you are, how much is behind
you and what is next, in that order, before anything is read. The loop says all three at
once, and it says without arguing the one thing the profile had to argue: that the end
joins the beginning.

Altitude survives it for free. The campaign climbs monotonically for four acts and falls
for three, so placing the stations in play order puts the trench at the bottom of the
circle and orbit at the top without the ring ever being told what a metre is — which is
why act IV hangs at the top of the dial, and why `tests/ring.test.ts` (now `tests/atlas.test.ts`) asserts that it
does. The claim holds exactly as long as the campaign stays one out-and-back, so it is
written down as a test rather than as a comment.

**The two layers.** The picture is SVG; the seven act markers on top of it are HTML
buttons, because a shape with a click handler is not a button — no focus ring, no pressed
state, no keyboard, nothing for a screen reader. They stay aligned because neither owns
the geometry: `Circuit.ts` places everything in turns, the SVG converts a turn into a
point in its own box, and the buttons convert the same point into a percentage of the same
box. The markers ride *outside* the ring rather than on it, because a marker on the line
covers two of the stations under it, and on the act the player is in one of those is the
bright point that says where they are.

Pressing a marker selects; it does not start. That is new, and it is the price of the
ring: seven markers on a circle are seven small targets, and a small target that starts a
run on first touch is a small target that ends someone's circuit by accident. The middle
of the dial carries the selected act — numeral, name, verb, six dots — and one button
under the ring plays it.

**The record.** `unlockedAct` answers where a player has been; nothing answered what they
had finished. Profile **v3** adds a per-act high-water mark of stations cleared, written
from `run.level` — the *furthest station reached*, not a count of clears, because acts III
and up restart a station rather than ending a run and a count would let one act re-earn the
same ground. Two things it has to get right, and they pull in opposite directions:

* **It may not overstate.** Capped at the act's own length, clamped on read, keyed by act
  key rather than index so that reordering the campaign — which `config/campaign.ts` is
  explicitly allowed to do — moves a player's record with the act instead of quietly
  reassigning it to another one. `clearedIn` guards `NaN` explicitly, because `clamp` does
  not: `NaN` compares false against both ends and comes out the other side still `NaN`,
  which would have put `r="NaN"` on every mark in the picture.
* **It may not throw away what an older save already proved.** The migration is an
  inference, and a defensible one rather than a generous one: `unlockedAct` can only ever be
  raised by `CampaignController.advance` — the act *finishing* — because act select offers
  nothing above it. So a v2 profile naming act V finished acts I to IV, and the map says so.
  A closed circuit fills the record outright. A v1 profile never left act I, and `bestLevel`
  is exactly how many of its stations it cleared — a reading that is only safe while
  `unlockedAct` is zero, since from v2 on that field is a maximum across every act and act
  V's six stations are not act I's.

Three things it deliberately is not:

* **Not a level select.** Playing enters the circuit at the selected act from its first
  station, exactly as the list it replaced did. The six stations the selected act names are
  placed and inert. The campaign checkpoints at station boundaries, but a checkpoint is
  where a circuit resumes: a station is a place you have been rather than one you can be
  dropped into out of order.
* **Not a spoiler.** Acts nobody has reached draw their band on the ring, because the title
  screen already promises the circuit in words; they stay unlit, and their stations stay
  unnamed, because the promise is not the visit.
* **Not on the title screen.** The tally rides on the button that opens the map —
  `THE CIRCUIT · 24/42` — rather than on a line under it. The button appears as soon as there is
  any journey to look at, which is a change: it used to wait for act II, so the one screen
  that says where you are stayed hidden for the whole of the longest act.

One correction fell out of building it. `Shell.render` focused the first button on **every**
render, not only on entering a screen, which is invisible while every control is a
navigation button and immediately wrong the moment one of them is a disclosure: pressing
the station-list chevron answered by throwing focus to the top of the screen, so a keyboard
user could open a list and not close it. Renders that a control triggered on itself now
hand focus back to that control (`data-focus`), and everything else is unchanged.

## Deliberate compromises (not oversights)

* **No fluid dynamics.** Decay + one Jacobi diffusion pass, no pressure projection or
  self-advection. Momentum is not conserved; it does not need to be.
* **The ambient current is not a simulation either.** It is the analytic curl of a stream
  function, so it is exactly divergence-free (no tracer sinks) without any solver. It does not
  interact with the player's currents at all — they are summed, not coupled.
* **The ambient field stops being divergence-free within 0.16 × width of a wall.** The
  wall-normal component is tapered to zero so the ocean cannot pin the shoal into a corner.
  Doing this exactly (windowing the stream function instead) injects a ~70 px/s vertical jet
  along the walls, which plays far worse than the tiny divergence does.
* **A hunter is not a fluid body.** It is dragged by the same water sampler as a fish, with a
  lower coupling and a hard positional clamp at the walls. Pinning one against a wall with a
  current is legitimate play; losing it off-screen would be a hazard that vanished.
* **A standing vortex does not interact with the player's currents.** They are summed, not
  coupled — the same compromise the ambient field makes, for the same reason.
* **`window.__slowblue` is exposed in production builds.** The e2e suite and on-device poking need
  it, and the web is the only target, so there is no store release to strip it from: it
  ships. It reads and steps state; it reaches nothing, because there is no network code.
* **`advance(seconds)` on that hook** steps and draws outside the rAF loop. It exists because
  the loop correctly parks itself when the tab is hidden, which makes headless capture
  impossible otherwise. Not a gameplay path.
* **Resize rebuilds the flow grid**, discarding in-flight currents. Everything else with an X
  is rescaled by the same ratio, so a rotation or a collapsing URL bar keeps the run intact
  instead of flinging the shoal into a wall — but the water you had laid is gone.
* **The service worker is stale-while-revalidate over everything same-origin.** Vite
  fingerprints its assets, so a stale hashed file is never the wrong file; only the HTML can
  go stale, and it is revalidated on every load.
* **The icons are generated, not designed.** `tools/make-icons.mjs` is a PNG encoder and a
  scanline rasteriser in about 300 lines, because a game with zero runtime dependencies
  should not pull in an image library to draw six squares.
* **Rocks are unions of circles.** Cheap exact collision and cheap predictive avoidance,
  and they still silhouette as organic rock.
* **Avoidance is radial only.** Tangential "clever" dodging looked better but made the shoal
  unpredictable, which is directly against the design goal.
* **Attrition is not symmetric.** In water, individuals dragged >140 px behind the camera are
  culled (`Medium.stragglerMargin`; the other media have their own, from 110 px to 520).
  This is what makes hard flicks expensive (they leave a comet tail) — intended, and the
  cause of the tail visible in `docs/screens/03-rock.png`.
* **The game ships in English only**: `resolveLang` resolves every setting to `en` and
  there is no picker. Inside a run there is still almost no text: a count, a score, a depth,
  and the name of the station you just entered.
* **Playwright runs Chromium, not WebKit.** WebKit was not present in the local browser cache
  and one test drives raw CDP touch events. Mobile Safari is still a support target and needs
  a real-device pass.
* **Telemetry is not research data.** Local `localStorage` + manual JSON export. No network.

## Measured performance

> **Read this section as a record of how the numbers were taken, not as today's numbers.** It
> was measured on act I and act II at their first length, in the first weeks, on Apple
> Silicon in headless Chromium; the campaign has since been rebuilt, the picture has gained
> planes and films, and the quality setting it mentions has become a ladder (see the
> **Superseded** note under decision 18). What still gates performance today:
> `e2e/runtime.spec.ts` (a 30 fps floor in headless Chromium, at the surface and deep in a run
> with hunters and standing currents up), `e2e/measure.spec.ts` (launch budget, allocation per
> frame, offline install) and `tests/allocation.test.ts` (zero GC in the hot path). **Real
> frame rates on a real phone are still not measured here**; the debug panel's pin row exists
> to take that reading.

Chromium, 390×844 CSS at DPR 2 (750×1624 backbuffer), Apple Silicon, in-page timing over
180 steps after a 60-step warm-up:

| Agents | Sim step | Share of a 16.7 ms frame |
| --- | --- | --- |
| 100 | 0.257 ms | ~1.5 % |
| 200 | 0.426 ms | ~2.6 % |
| 350 | 0.957 ms | ~5.7 % |
| 500 | 1.778 ms | ~10.7 % |

Ambient current sampling costs **44 ns per sample** — at 500 agents and 60 Hz that is 1.3 ms of
CPU *per second*, so adding the ocean was effectively free.

Canvas draw calls are queued asynchronously, so the paint/composite cost is **not** captured
by this method — the sim number is trustworthy, the render number is not.

Adding the two new hazards cost nothing measurable: a hunter is one linear scan over the
agent list per step, and a vortex is a bounding-box reject plus one `sin()` for the few
samples inside it. Under the real animation loop (`e2e/runtime.spec.ts`, headless Chromium,
100 agents) the game held **120 FPS** both at the surface and with **7 hunters and 5
standing vortices** live at once.

The graphics pass did cost something, and the number is worth stating plainly: the same
measurement fell to **86 FPS**, and sits at **88–92 FPS** after trimming the caustics and
the light shafts, with the top-down fish outline (about fourteen points each instead of
six, plus two fins) accounting for the last couple of frames per second.

The art pass of decisions 32-36 - lit rock, entrained vortices, animal predators, two-plane
backdrops - cost nothing measurable on top of that: the same spec now reports **94 FPS** at
the surface and **90 FPS** deep in the run with 3 hunters and 7 standing currents live. The
reason is that almost all of it is edges rather than area: crests, filaments and fringes are
thin strokes over paths that were already being built, while the two genuinely expensive
things (the clipped dome inside a mass and the caustic nets) are gated behind
`quality > 0.6` and skipped outright on Low. That is entirely
fill rate and path building — wide additive strokes, full-screen gradient fills, and more
points per agent — not simulation. It is still comfortably clear of the 30 FPS floor the e2e
suite enforces, and the bottom of the quality ladder (once the `Low` setting) removes the expensive
layers rather than merely shrinking them.

That loop number is *not* a phone number: headless compositing is cheap and there is no
thermal ceiling. **Real FPS must still be read from the debug panel on a real device** —
that measurement has not been taken. Neighbour cost grows super-linearly (5× agents →
8.5× time) because a denser shoal means more agents per perception query; there is still
ample headroom at 500.

Guards in place: DPR capped at 2 and stepped down automatically after 2.5 s below 45 FPS
(then, as of the ladder, back up at 58 after 8 s; there is no explicit Low setting any more),
loop stopped entirely on `visibilitychange`, backlog dropped after a stall, buckets and
vectors reused in the hot loop, palettes parsed once at module load rather than per frame.

## The seven acts had one rhythm and one reward

The report was that the acts play as one act with the background changed, and the
first diagnosis was wrong: it blamed the archetypes. Reading the seven level files
says otherwise. The alphabets *are* per-act and were defended deliberately —
`config/levels.ts` states the rule - in the comment above the section alphabets - as "a
mapping of *demands* rather than of silhouettes" and repeats it in four tables. What was genuinely identical was
underneath them:

* **One metronome.** `SECTION_SPACING` is 820 and, across all seven config files,
  six sections deviated from the 760–960 band. Whatever the shapes, the world
  arrived at one tempo everywhere.
* **One reward.** Of the campaign's ~100 obstacle sections, **92 carried a single
  compulsory ring at the section's own centre x, 185–265 px behind it.** Byte for
  byte the same grammar in all seven acts.
* **Seven copies of one helper.** `breath()` — four lines, `spacing: 900`, one
  optional ring — was pasted into every act file, so every station's rest was
  every other station's rest.

Both levers were already per-section fields, so the fix cost no engine code: see
DESIGN-ASCENT §12 for the per-act table. The constraint that made it a design
problem rather than a free-for-all is that **each act keeps its ten minutes** — an
act's duration is its summed spacing over its mean pace, and `tests/descent.test.ts`
now sums the *authored* spacings instead of assuming a flat 845 px, which is both
honest and the only form of that check that can still fail.

Three archetypes were added and roughly ten proposed ones were cut after an
adversarial pass found them to be reskins (`weir` = `gate`, `belt` = `arc`) or
demands this simulation does not have (a "shave the scree gradient" archetype is
neutralised by the swarm's own summed avoidance out to 66 px; a "brake and hold an
angle" corridor is built on a brake the game does not have, since forward speed is
a forced camera drift). What survived: **`street`** (act II — two lines of cloud
running *along* the course, the one thing on the whole course that is not an
aperture), and **`drape`** and **`bloom`** for act VII, which had no alphabet at all
and was authored end to end out of act I's rock.

Act I is not in any of it. It is frozen, and a rhythm needs something regular to be
heard against.

> **Superseded in scale.** Every count in this section is the campaign *before* the length
> rebuild: roughly a hundred obstacle sections, one 820 px metronome, and "each act keeps its
> ten minutes". [docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md) reopened that last constraint
> on purpose and measured the result: 432 sections and 144 authored minutes, six acts of
> about twenty-two minutes and act I still frozen at ten, with `tools/stations.sweep.ts`
> printing the current table so nobody maintains one by hand. The diagnosis above (one rhythm,
> one reward, one pasted helper) is the part that stayed true and the reason the rebuild
> authored per-act rhythm in the first place.

## What is still open

* **No real-device pass.** Mobile Safari, thermal throttling and actual touch latency are
  all untested. This is the single largest remaining unknown, and nothing in this document
  substitutes for it.
* **Nobody has played the rebuilt campaign.** Six of the seven acts were rebuilt to the length
  recipe and verified by tests and sweeps, which answer *can this be flown* and *does it obey
  the rules*, not whether act III still feels like patience or act II is still the act this
  repo is proudest of. The hunter and the vortex are likewise balanced against scripted players
  only. [docs/DESIGN-LENGTH.md](docs/DESIGN-LENGTH.md) §12 is the watch list, in the order a
  playthrough meets it.
* **`window.__slowblue` ships.** That is a decision now, not a gap: see the compromise above.
