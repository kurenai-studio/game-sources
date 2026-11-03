# 3D stack: Crimsonland (personal web version)

- Archetype: C game (one-screen top-down arcade shooter)
- Track: WebGPU (three 0.187.0, WebGPURenderer, TSL, RenderPipeline), automatic WebGL2 fallback.
  Why: new vanilla project, no WebGL-only library needed; all custom shaders are TSL.
- Framework: vanilla JS + Vite. No React, no ECS, no physics engine.
- Libraries: three 0.187.0, lil-gui 0.21 (?debug only), @fontsource teko / jetbrains-mono (self-hosted).
- Not used, on purpose: Rapier (circle collisions on a uniform grid scale better for 500+ bodies);
  Howler (all audio is synthesised with WebAudio, no asset files).
- Assets: none. Terrain, creatures, particles, icons and sound are all procedural.

## Look
- Preset: CINEMATIC. ACES tone map, low key light with long shadows, cool/warm split, bloom on HDR
  (threshold), vignette, film grain, chromatic aberration on damage.
- Signature: persistent ground layer. Blood, scorch, casings, footprints and corpses are baked
  into a render target and never go away. Wet blood stays glossy and has a raised rim.
- Reference: Crimsonland (top-down horde, perks, weapon drops, blood-soaked ground). Gameplay formula
  follows the original; models, textures, icons and audio are original and procedural.

## Perf budget
- 60 fps desktop / 30+ fps phone, 500 live enemies, 3000 particles.
- Measured at 2880x1800 with 419 enemies on an Apple GPU: 6 ms median, 16 ms p95. The two-joint skeleton doubled
  this from 3 ms, so the worst frames are at budget; adaptive pixel ratio covers slower machines.
- < 60 draw calls per frame, < 1.5M triangles including shadow pass.
- No per-frame allocations in sim or view code. Typed arrays and swap-remove pools.
- Adaptive pixel ratio when frame time misses budget.

## Devices
Desktop mouse + keyboard (primary), gamepad, modern phones with twin virtual sticks.

## Balance
Tune against the human bot (`?autoplay=human`). Survival median is about 2:40 on a new profile, 3:05 unlocked;
missions climb to ~50% on boss missions. Run `?selftest` after changing content (src/dev/selftest.js).
The perfect bot hid every early-game problem, so its numbers are not evidence of anything.

## Decisions
- Interview skipped: request plus reference fixes scope (one-screen arcade). Defaults taken:
  desktop + modern phones, vanilla, procedural assets, CINEMATIC look.
- Title: Crimsonland, at the owner's request (constant in src/config.js).
- Release: MIT, public repo, GitHub Pages via Actions. Relative Vite base so the build runs under any path.
