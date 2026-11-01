# Project prompt: Dreamrun

You are a senior game engineer. Build a 2D atmospheric puzzle-platformer in the style of Limbo/Inside.

## Concept
A child is trapped in a nightmare, chased by a monster. They run, solve environmental puzzles, and use tools/traps (levers, crates, rope, falling objects, electric/fire traps) to push the monster back. The final level is a boss fight; after winning, the character wakes up in a bedroom (end).

## Tech stack
- Godot 4.x (latest stable), GDScript only. All gameplay logic lives here.
- Go (1.22+) for an OPTIONAL companion backend in /server: REST API for cloud save (save slots as JSON) and telemetry events. Stdlib net/http, SQLite for storage. The game MUST run fully offline; backend calls are fire-and-forget with timeout and local fallback.
- Do not build a Go GDExtension.

## Art/feel requirements
- Monochrome/near-grayscale palette, silhouette characters, soft fog, light shafts, film grain + vignette shader, multi-layer parallax.
- 2D lighting: PointLight2D + LightOccluder2D, CanvasModulate for darkness.
- Character animation states: idle, walk, run, jump, fall, land, push, pull, climb, die. Animation feel (weight, anticipation) matters more than detail.

## Art pipeline (no external artist yet)
You cannot paint raster art, so generate all visuals in code/vector:
- Characters and monster: black silhouettes built from Polygon2D (or SVG imported as texture) with a Skeleton2D rig created by a GDScript tool/scene builder. Keep rigs data-driven (one resource per character) so an artist can replace them later.
- Animation: procedural first (walk/run cycle via sine + 2-bone IK for legs, spring-damped arms, squash/stretch on land, lean when running). Expose every tuning value as @export in one AnimationTuning resource so I can tweak by eye.
- Monster: segmented chain/tentacle driven by follow-the-leader or FABRIK, glowing eyes via PointLight2D, menace through scale and silence rather than detail.
- Environment: layered Polygon2D/SVG silhouettes, parallax, fog and light-shaft shaders, grain/vignette post-process.
- Hard rule: gameplay scripts must reference nodes by name/signals, not by art specifics, so replacing placeholder visuals with hand-made animation (Spine/AnimatedSprite2D) needs no gameplay change.
- After each visual change, tell me exactly what to look at in the editor and which tuning values to adjust; I will give feedback since you cannot see the result.

## Third-party assets
- Use free assets mainly for audio, music and background textures. Characters/monster stay procedural.
- Prefer CC0. CC-BY allowed only if recorded. Never use CC-NC/ND or unlicensed files.
- Suggested sources: freesound.org, Kenney.nl, OpenGameArt.org, ambientCG, Google Fonts (OFL).
- Download each asset into a fresh folder under /game/assets/_incoming/<name>, inspect it, then move only the files used into /game/assets/.
- Maintain /ASSETS.md: file, source URL, author, license, date, modifications. No asset enters the repo without a row.
- Do not run any script shipped inside a downloaded archive.
- If a site blocks automated download, stop and tell me the URL and the target path; I will download it manually.
- Audio: normalize and convert to .ogg; textures: convert to grayscale to match the monochrome style.

## Gameplay systems (build in this order)
1. Player controller: CharacterBody2D with coyote time, jump buffering, state machine.
2. Interactables: pushable crate (RigidBody2D), lever, pressure plate, door, rope/swing, climbable ledge.
3. Monster chase: scripted chase sections where the monster follows a path/speed; player dies on contact; instant checkpoint respawn (<1s).
4. Trap system: reusable trap nodes the player triggers to stop/kill/delay the monster.
5. Boss fight: 3-phase pattern-based, defeated by environment traps (no direct attack).
6. Wake-up ending cutscene (bedroom, bright warm lighting, contrast with earlier levels).
7. Audio manager: ambient layers, footsteps, monster proximity sound; no dialogue, no UI text during play.
8. Save system: local JSON first (user://), then optional sync to Go backend.

## Scope for milestone 1 (vertical slice)
1 chapter, 1 monster, 3 puzzles, 1 chase, 1 trap-based mini-boss, checkpoints, pause menu. Nothing more.

## Project structure
```
/game        Godot project (scenes/, scripts/, assets/, shaders/, levels/)
/server      Go backend (cmd/server, internal/save, internal/telemetry)
/docs        design notes (GDD.md, level-notes.md)
ASSETS.md    third-party asset ledger
CLAUDE.md    conventions and run/test commands
```

## Working rules
- First, write a plan: milestones, per-step definition of done, risks. Show it and wait for my approval before coding.
- Then implement milestone by milestone; each milestone must be runnable in Godot headless or via the editor, with a short "how to test" note.
- Smallest working solution; no speculative systems, no plugins unless necessary (ask first).
- Go: stdlib first, table-driven tests for handlers. GDScript: typed variables, signals over polling, one script per node responsibility.
- Do not commit or push unless I ask. Give git setup instructions and let me run them.
- Ask me before: adding any paid asset/plugin, changing the stack, or expanding scope.

## Start with
1. The plan.
2. Project skeleton with a procedural silhouette player that runs and jumps, in a test room with parallax, lighting and the grain shader.
3. Then environment and lighting, then the monster.
