# Balloon Ride — shared brief for every agent

Read this whole file before doing anything. `docs/PROGRESS.md` is the running log: read it first and add to it when you finish.

## The game
A calm hot air balloon ride over a hand-painted countryside at golden hour. Stylized like Ghibli / Makoto Shinkai (toon-shaded, warm light, fluffy painted clouds, outlines, painterly grade). Not photoreal. No combat, no score, no objectives. Float, rise, drift, look down.

Tech: Three.js + Vite + TypeScript, **pnpm only**. Project root `F:\balloon-ride`. Build: `pnpm build` (`tsc --noEmit && vite build`). Vite `base: "./"` (GitHub Pages under /balloon-ride/).

## Hard rules
1. **Reuse the old environment code.** Source projects: `F:\summer-cycle` and `F:\bay-ride` (Bay Ride is newer, prefer it). COPY modules into `src/` here and adapt. **Never edit, build, or write anything inside those two folders.** Do NOT copy characters, bike, boat, riders, gameplay, HUD/hints/intro text. Do not model people. The basket is empty.
2. **GPU, asserted.** Every headless/headed Playwright run launches Chromium with `--use-angle=d3d11 --use-gl=angle --enable-gpu --enable-gpu-rasterization --ignore-gpu-blocklist --force_high_performance_gpu`, then queries `WEBGL_debug_renderer_info` and prints the renderer every run. Abort (after teardown) if it matches /swiftshader|llvmpipe|software|basic render/i. Never use `--enable-unsafe-swiftshader`, `--disable-gpu`, `--use-gl=swiftshader`. Shader compile/link errors are fatal in captures (listen to console for `THREE.WebGLProgram` / errors). App code: `new THREE.WebGLRenderer({ powerPreference: 'high-performance' })`.
3. **Clean up every process on every exit path.** Install SIGINT/SIGTERM/uncaughtException/unhandledRejection teardown that closes browser + server and `process.exit`s, before the first run. No `start /B`, no `nohup`, no detached children. Close every dev/preview server and browser you start. Never kill processes you didn't start. Before you report, confirm nothing you started is still running.
4. **Be gentle with the machine** (RTX 4060, Ryzen 7600X, 32 GB). Don't max CPU/GPU. Long CPU work at reduced priority. Headed test windows go on the **second monitor**: `--window-position=1920,0` (DISPLAY2 is portrait 1080x1920 at x=1920). Default to headless.
4b. **The user may be gaming (GPU contention).** If renders/tests are slow, time out or flaky, wait and retry the same run. Never change code, lower quality, add fallbacks or loosen the GPU check because of it. Label perf numbers taken under contention and don't optimise from them.
5. No downloaded audio or textures shipped in the game. Sounds synthesized in code. Geometry is code or our own Blender exports (`public/models/*.glb`).
6. **Screen text:** none except a tiny controls hint toggled with H (hidden by default). Nothing in the top-right corner. Touch buttons on mobile are allowed (bottom corners).
7. Subagents are run one at a time. Do not spawn your own subagents.

## Features
- Balloon: Blender-scripted model (envelope with gore panels + stripes, wicker basket, ropes, burner frame), exported to `public/models/balloon.glb`. Toon-shaded in game through the reused material factory.
- Controls: Space hold = burner (rise, flame, roar). S hold = vent (sink). Mouse drag = look. V = toggle third-person (default, behind/above) / look-down-from-basket view. T = cycle time of day: sunrise → golden hour (default) → sunset → blue hour. H = hint. C = cinematic camera.
- No steering: wind layers by altitude (low < ~150 m drifts east, mid 150–400 m north-east, high > 400 m north; smooth blend). Wind shown by drifting particles / cloud motion, never text.
- Physics feel: real balloons climb/sink ~1–3 m/s (max ~5), burner effect has a lag of several seconds (envelope heat), equilibrium hover, ground contact gentle. Calm.
- 4–6 other colourful balloons at different heights in the distance, drifting with their layer's wind.
- **The look-down view is the whole game.** From 100–600 m it must read like a hand-painted miniature world: village with tiny houses (varied roof colours, chimneys, gardens), a church tower and/or windmill, winding roads, a river with a stone bridge, patchwork fields in greens and golds, hedgerows, tree clusters, orchards, a lake reflecting the sky, sheep/cows as dots, a moving cart/car on a road, chimney smoke, birds below, clouds at several layers including some you rise through, atmospheric perspective (warm haze). LOD + instancing so it's smooth at every altitude.
- Cinematic mode (C): scripted camera — close on the balloon with burner firing, pull back to reveal the village, glide over the fields at golden hour. `scripts/record.mjs` records it to 1080p60 MP4 (40–60 s) in `recordings/` using h264_nvenc.
- Mobile: touch buttons for burner + vent, drag to look.
- URL params for capture: `?shot=<name>` style fixed cameras, `?time=sunrise|golden|sunset|blue`, `?seed`. Expose `window.__game` for scripts (set altitude, camera, time, pause).

## Phase 7 (user request, after first ship): the pilot
This replaces the earlier "no people / empty basket" rule, for this one character only.
- An original stylized Ghibli-style pilot in the basket, modelled + rigged in Blender by script, exported to `public/models/pilot.glb`. Simple, charming, not a realistic human. Scarf, goggles pushed up on the head, one hand on the burner. Style should match the characters in Summer Cycle / Bay Ride (soft shapes, toon-shaded, ink outline), but it must be a NEW character: do not copy their rider or heroine models, rigs or faces.
- Animations in Blender (exported as glTF clips): idle with the scarf blowing in the wind, looking over the edge, firing the burner (pull lever; played when Space is held). Blend between them in game with an AnimationMixer.
- **Don't change anything else that already passed** (world, balloon, clouds, other balloons, cameras, time of day, mobile UI, audio). Basket view may show the pilot's arm/hand.
- Gauntlet: critic compares the pilot against Summer Cycle and Bay Ride character style frames, then fix until PASS. Then rebuild, redeploy, and re-record the cinematic MP4 with the pilot in it.

## Capture spots (used after every system)
`scripts/shoot.mjs` renders 1600x900 PNGs into `shots/<system>/`: `ground` (eye level near the village), `50m`, `200m`, `500m`, `down` (straight down from ~300 m), plus `basket` (V view at 250 m). Deterministic: fixed time, fixed seed, wait for load + a few frames.

## Gauntlet
After each system: shoot frames → critic subagent compares against `refs/` (real golden-hour balloon-flight photos) and Summer Cycle style frames (`F:\summer-cycle\shots`, `F:\summer-cycle\refs\user_village_field.jpg`, `F:\summer-cycle\media`) → critic writes `docs/critic/<system>.md` with concrete problems and PASS/FAIL → fix → re-shoot until PASS.
