# Algomind — Depth Look Plan (2.5D board, new theme and UI)

> **Status:** direction approved by the owner on 2026-10-31; no code, tokens, or screens have changed yet. The concept is in [design/depth/](design/depth/) (light and dark, listed in [design/SCREENS.md](design/SCREENS.md)). The visual rules are in [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md), section 14.
> **Related:** the patrol mechanic and the 20-world ladder are in [README_WORLD_RESTRUCTURE_PLAN.md](README_WORLD_RESTRUCTURE_PLAN.md) and [README_GAME_RULES.md](README_GAME_RULES.md), section 3.9.

## 1. Why

The board was flat white squares with a small triangle, and the interface was flat too, so a solved run looked almost the same as a failed one and the game felt plain and boring. Two attempts were made as renders:

1. **A 2.5D board inside the flat interface** ([design/3d/](design/3d/), made by `scripts/concept-3d/render.mjs`). The owner judged it did not look good: a lit board pasted into a flat poster, two styles fighting. Kept only for its camera findings (section 2).
2. **A whole-app depth look** ([design/depth/](design/depth/), made by `scripts/concept-3d/depth.mjs`). The owner judged it much better. This is the plan.

## 2. What the renders showed

### Camera

Same 5x5 board, four cameras ([design/3d/compare-camera-light.png](design/3d/compare-camera-light.png)):

| Camera                  | Result                                                                       |
| ----------------------- | ---------------------------------------------------------------------------- |
| Flat tilt               | Biggest cells, only front faces show, weak 3D feel                           |
| Tilt with perspective   | Best balance; side faces show, cells stay large. **Chosen for small boards** |
| Angled with perspective | Most depth, but cells about 20 percent smaller                               |
| Isometric               | Smallest cells, and cubes hide the cell behind them. **Rejected**            |

### Large boards

World 8 has boards up to 12x10. A fixed 62 degree camera shrinks the back rows until the goal and automaton are hard to read, while the current top-down view stays clear. An **adaptive camera** fixes it: about 62 degrees with perspective up to 6 cells, easing to about 80 degrees with almost no perspective by 12 cells ([design/depth/compare-large-board-light.png](design/depth/compare-large-board-light.png)). The rule is `cameraFor` in `scripts/concept-3d/depth-board.mjs`.

### Depth concept: problems found and how they were resolved

| Problem                                            | Resolution                                                                                                          |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| The collision was not visible on the failed screen | The cell is hazard-striped, the guard outlined, and the guard timeline marks the failing step with an X             |
| Empty band under a 6x5 board                       | A "stop by step" strip for patrol levels; levels without a patrol let the board use the full height                 |
| Dark floor too close to the plate                  | Floor and plate tokens changed (proposal)                                                                           |
| World thumbnails too small                         | Larger, each showing the world's idea                                                                               |
| Turn icons hard to tell apart                      | Bent arrows, mirrored, different from the straight Move arrow                                                       |
| Large boards unchecked in the new theme            | Tested at 9x7 and 12x10 with the adaptive camera                                                                    |
| Soft shadows and gradients unproven in Godot       | Tested in Godot 4.7.2, Compatibility renderer, macOS: gradient, soft shadows, and lips with `_draw()` and no shader |

Still true from the first concept: tall blocks hide cells (so walls stay low, about 0.6 of a cell), and the top-down view is still the best for reading a very large board.

## 3. Options

| Option                                                      | What it is                                                                      | Verdict                                                                                                  |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **A. 2.5D drawn in 2D** (`_draw()` with projected polygons) | The way the game draws today; each cell is a few polygons through a projection. | **Chosen.** No 3D engine, no renderer change, works in the browser build, and the simulator is untouched |
| B. Real 3D (`SubViewport`, `Node3D`, meshes, a light)       | Models, a camera, real lighting                                                 | Only if A is not enough later; more assets, performance risk                                             |
| C. Isometric                                                | Rotated 30 to 45 degree view                                                    | Rejected (section 2)                                                                                     |

## 4. Design

The full rules are in [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md), section 14. In short:

- **Keep:** the chamfered tile, the tape, the one signal yellow, the condensed type, the wordmark, both themes, color never the only signal, the voice rules, and reduce motion.
- **Change:** keys with a lip and a soft shadow, a recessed tape, a board plate, a soft ground gradient, face shading, an adaptive camera, low walls, hazard-striped failure cells, and (with world 13) the patrol guard, its route, and the "stop by step" strip.
- **Tokens:** new base tokens (now in `packages/design-tokens/tokens.json`, key `depth`; section 14 of the visual design doc lists them); the generator derives face shades and the shadow color, and contrast tests cover them.
- **Dashboard:** stays flat; its board editor and preview stay top-down.

## 5. Phases

Sizes are relative; there are no dates. During the migration both looks exist behind a setting (Look: Flat or Depth); Flat stays the default until Depth is approved on a device.

### Phase 1 — Tokens and key kit (M) — built 2026-10-31, device test pending

- Add the depth tokens to `packages/design-tokens`; the generator derives the shades and shadow color for the Godot palette and the web CSS; extend the contrast tests; `make tokens` and `make tokens-check` green.
- In the game: a key drawer in `UiKit` (face, lip, soft shadow from stacked polygons, chamfer), a recessed trough, and a ground gradient with `draw_polygon` vertex colors.
- Measure draw calls and frame time on a phone before building more on it.
- **Exit:** a test screen with keys and a trough, in both themes, looked at on a real Android device.

**Phase 1 as built:** the depth tokens are in `packages/design-tokens/tokens.json` (key `depth`), the generator derives the shades and writes `apps/game/scripts/generated/depth_palette.gd` (the web is unchanged), with 26 new token tests (contrast, derived shades, the docs table). `DepthKit` draws the gradient, keys (tile, signal, ink, pressed), soft shadows, and the trough; `DepthKitSample` shows them (`--screen=depth_kit` in `make game-shots`). The Look setting is not added yet: nothing consumes it until the board and screens use the kit (phases 2 and 3). Looked at in 6 real game renders (3 sizes, both themes) on a Mac; **not** run on a phone, and the draw cost is unmeasured.

### Phase 2 — The board (M) — built 2026-10-31, device test pending

- `BoardView25D` reading the same state as `BoardView` (position, facing, trail, marks, hit cell, boards), with the adaptive camera, plate, tiles, low walls, goal pad, trail markers, breadcrumbs, `visit_all`, and the multi-board tabs.
- Tests for the projection and the camera rule (pure functions, GUT). The simulation tests do not change.
- **Exit:** `make game-shots` for a small, a medium, and the 12x10 board, in both themes and three sizes, looked at and listed; a device run for frame rate.

**Phase 2 as built:** `BoardProjection` (the camera and projection, pure), `BoardFloorLayer` (the plate, floor, trail, goal, breadcrumbs, and wall shadows, redrawn only when the state changes), and `BoardView25D` (a subclass of `BoardView` that draws the walls and the automaton far to near, so the play screen and its animator drive it unchanged). `BoardViews.make(look)` picks the board; the Look setting (`flat` by default, local to the device and never synced) is read by the play screen and the menu; `--look=depth` selects it in `make game-shots`. 13 new GUT tests (camera, fit, painter order, visible faces, the setting, the factory, a smoke test on a small level, a sweep, a breadcrumb level, and the biggest board).

Seen in real game renders ([design/SCREENS.md](design/SCREENS.md)): small and 12x10 boards, a sweep level, breadcrumbs, a failed run, both themes, 390x844 and 360x640. **Findings:**

- The depth board sits inside the flat interface, which is the mismatch the owner disliked. It is hidden behind the Look setting (off by default) until phase 3.
- On the 12x10 board the automaton and the goal are about 20 px at 390 wide and about 14 px at 360 wide, smaller than the flat view, because the board sits in a square and a wide board leaves the height unused. Phase 3 gives the board the screen's free height; check the sizes again then.
- There is no toggle in the Settings screen yet; nothing is saved by `set_look` until that screen calls the store.
- Draw cost is unmeasured: the floor layer is cached, but a moving automaton redraws the walls each frame (up to about 60 on the biggest board).

### Phase 3 — The screens (M) — built 2026-10-31, device test pending

- Play (tape, palette, actions, result), menu, world map (with the thumbnails and a progress view that works for 20 worlds), result, settings, sign-in, and the notice screens, in the depth look.
- **Exit:** all screens in both themes and three sizes, looked at; the palette labels no longer shrink below a readable size (regroup or scroll instead).

**Phase 3 as built:** the shared pieces now take the look, so every screen follows without its own copy. `Palette.apply(dark, depth)` gives the names the two palettes share (ink, ground, floor, strip, mute, signal, wall, trail, and so on) their depth values, generated from the tokens (`ground` is the top of the gradient). `UiLook.depth` (set by `AppState.apply_theme`) tells the pieces that differ in shape. `TileDraw.tile` draws a flat fill and outline or a key and returns the content rect; it serves the four tape tile kinds, the stat tiles, the result badge, the wordmark, the world and level tiles, the hint panel, the coach bar, the leaderboard row and the badge row. `TileButton` becomes a key (pressed keys sink; disabled and locked keys are opaque, sunk, and muted). The screen ground is the gradient, the tape and the text fields are recessed, and the play screen gives the board the free width and height. A STYLE row (flat or depth) in Settings saves the choice, and **depth is the default** (also for a save made before the setting existed; the owner asked to see it, so it was brought forward from phase 5 without a device test, and a player can switch back to flat), and `make game-shots` renders 17 depth screens at the three sizes in both themes (`ONLY=depth sh tools/screenshots.sh`). 21 new GUT tests and 4 new token tests.

Two things the checks found: `Dictionary.merged` does not overwrite unless told to (the generated override was inert at first), and a disabled key drawn at half opacity let the controls under it show through, so disabled keys are opaque now.

**Not restyled yet (still flat shapes in depth colors):** the pause panel's own frame, the loop and `IF` group brackets on the tape (2 px outlines, kept on purpose), the dashed empty slot, and the small stars and icons. **Not done:** the web, a device run, and the draw-cost measurement (phase 6 and the TODO).

### Phase 4 — Motion and sound (M) — motion built 2026-10-31, device test pending

- Step as an eased move across projected cells, a turn as a short pivot, a bump on a wall, a rise on the goal; the tape slides under the read-head; key press and release. Each at most 250 ms (the result screen is the exception), driven by the simulation trace, and instant with reduce motion.
- **Exit:** a recorded run per speed; durations checked; reduce motion checked.

**Phase 4 as built (depth look only; sound and haptics were already in the game):** the slide between cells eases (sine, in and out); the automaton lifts about 0.14 of a cell halfway between two cells (`BoardView25D.lift_at`, computed from its position, so there is no extra state); the wedge turns toward a new facing (a quarter turn in 0.1 s); the goal pad rises 0.12 of a cell in 0.2 s when the automaton stands on it and sinks when it leaves; a key sinks onto its lip and springs back in 0.06 s (`DepthKit.key_sunk`; the lip and shadow stay put while the face moves). Every duration is within the 250 ms limit. **Reduce motion** is one shared flag, `UiLook.animate` (set from the setting by `AppState.apply_theme`): with it off, the wedge, the pad, and the keys change at once, and the animator already skips the slide. **Nothing runs while idle:** a button or the board runs frame callbacks only while something is moving, and stops when it settles (Godot turns `_process` on by default when a node is ready, so both turn it off in `_ready`; a test checks an idle button runs no frames). The key base was also corrected: the lip stays on the base while the face sinks onto it. 9 new GUT tests.

Not done: a bump squash on a blocked move beyond the existing nudge, a hop or sound for the pad, the tape tiles pressing, and a recorded run per speed. Motion cannot be judged from a still image; it needs a look on a device.

### Phase 5 — Make Depth the default (S)

- Depth became the default on 2026-10-31, before the device test (the owner wanted to see it). If the device test shows it is too slow or hard to read, change `Settings.LOOK_DEFAULT` back to flat. Keep Flat as a setting for low-end devices and for accessibility (open decision, section 6).
- **Exit:** screenshots of every screen that shows a board; docs and README status updated.

### Phase 6 — The web (S to M) — public site built 2026-10-31, not yet reviewed on a phone

- The public site takes the depth tokens and look (landing, download, how to play); `/play` gets the new look from the game build; the dashboard stays flat.
- **Exit:** the pages checked in both themes, mobile and desktop, and with JavaScript disabled.

**Phase 6 as built (the public site only; the dashboard is untouched and flat):** the depth tokens are generated into `apps/web/src/app/depth-tokens.css`, scoped to `.look-depth` (shared names overridden, depth-only names and derived shades added, Tailwind color names for them), and the public layout wraps the pages in `.look-depth`: a soft gradient ground and every tile of the page is a key. `Key` (`components/ui/key.tsx`) is the wrapper that shows the lip and the shadow (a `drop-shadow` cannot follow a `clip-path`, so it cannot sit on the chamfered face); a pressed key sinks. It serves the buttons, the wordmark, the menu and theme buttons, the world and install numbers, the frames and the closing band. The drawn screens take a `look` prop (`"flat"` default, `"depth"` on the public pages): `TileGraphic` and `ButtonGraphic` draw keys, `TapeGraphic` a recessed trough, and the board is `DepthBoardGraphic`, a port of the game's projection (`lib/board-projection.ts`), so the site shows the same board as the game. `BoardView` crops its view box to the drawing. Checked in Chrome at 390, 360 and 1280 wide in both themes and with JavaScript disabled, and the admin sign-in is unchanged.

The share image (`lib/og.tsx`) was redrawn in the depth look from generated colors (`depth-colors.generated.ts`) with keys and a recessed tape. Not done: the browser-play frame around the game (`/play`) still has its own flat chamfered frame (not seen with a build present); there are no unit tests for the web projection (the web has no test runner; the same geometry is tested in the game); not looked at on a phone; the first-paint cost of the shadows is unmeasured.

### Phase 7 — Patrol visuals (with the restructure plan, phase 3)

**Built for world 13:** the guard is a diamond with a ring and a dot (flat) or a diamond block with a ring (depth), its route a thin line with a dot on each cell, and a caught guard turns signal yellow. Not built: the stop-by-step strip, the numbered stops and the hazard-striped failure cell.

- The guard, its route, the "stop by step" strip, and the hazard-striped failure cell, built with world 13, in the depth look from the start.
- Tiles for the later worlds (doors, keys, switches, ice, conveyors, teleporters) are designed in the depth look before they are built.

### Phase 8 — Optional: real 3D (L)

- Only if option A is not enough. Prototype in a branch, measure on a device, and compare with A first.

### Order with the world restructure

Phases 1 to 3 touch the game's UI code and run in parallel with restructure phase 1 (data only). Phases 1 and 2 must be done before restructure phase 3 (the patrol world), so patrols are built once in the new view.

## 6. Decisions still open

1. **Keep a Flat setting permanently** (low-end devices, accessibility) or remove it after the migration.
2. **Shadow cost threshold.** What frame time on a mid-range Android phone is acceptable; the answer comes from the phase 1 measurement.
3. **Web.** Whether the public site adopts the depth look in the same release as the game.

## 7. Risks

| Risk                                               | Mitigation                                                                                     |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Stacked-polygon shadows are too slow on a phone    | Measure in phase 1; redraw only on change; fewer layers; a pre-baked texture for static pieces |
| Large boards get hard to read                      | The adaptive camera; test 12x10 at 360 px wide in phase 2; fall back to top-down above a size  |
| Tall pieces hide cells                             | Low walls, markers on top, an outline for a hidden automaton, the Flat setting                 |
| Both looks drift apart                             | Both read the same state; one set of tests for the state, one for the projection               |
| The identity is lost                               | The tile, the tape, the yellow, and the type stay; only depth is added                         |
| It looks good in a render and feels bad on a phone | Device test before the default changes; no performance claim without it                        |
| Work grows too large                               | Phases are independent; Flat stays the default until Depth is approved                         |

## 8. Not verified

The concept images are drawings made in HTML, not screenshots of the game. The Godot test ran on one Mac (Metal, Compatibility renderer) and drew a test scene, not the game. Android, the browser build, frame rate, battery, touch behavior, and the real cost of the shadows are not tested. Colors and shapes are a first pass and will change in review.
