# Phase 03 — First playable

**Lane:** code · **Owner:** `game-presentation` · **Depends on:** 02 · **Target:** day 3

## Before you start

**Read, in this order:**

1. `CLAUDE.md` — the web-target pitfalls, which apply from this phase onwards.
2. `docs/planning/12-architecture.md` — the contracts section, since `game` may only read through `WorldView`.
3. `docs/planning/10-mvp-initial-values.md` — resolution, scaling and controls.

**Do not re-decide:** logical resolution 480×270 with a 208 px playfield, integer scaling with nearest-neighbour, and a relative rather than positional mouse.

**Working reference:** `spikes/web-viability/` renders at this exact resolution with integer scaling and a checkerboard that exposes any distortion. Reuse the approach; the code is throwaway.

**Blocked by the art lane:** sprite sizes must be fixed before hitboxes are written. That is synchronisation point 1 in the overview.

## Goal

The first moment where a ship moves on screen and something can hit it. Desktop only, placeholder art, no content pipeline yet — the point is to close the loop from input to pixels.

Desktop comes before web even though web is the shipping target: it is the shortest path to something playable, and the core is identical either way.

## Preconditions

Phase 02 accepted. Sprite sizes fixed by the visual direction, since hitboxes depend on them.

## Tasks

1. **Desktop launcher.** LWJGL3, window at an integer multiple of 480×270.
2. **Input adapter.** Keyboard and mouse into an `InputFrame` per tick. The mouse is **relative**, not positional, which is what makes cancelling possible; pointer capture is needed and is still unverified on web.
3. **Renderer.** Reads through `WorldView` with the visitor, so no object is allocated per entity per frame. `SpriteBatch`, one texture atlas, nearest-neighbour.
4. **Viewport.** Logical 480×270, integer scaling, letterbox. The playfield is centred and 208 px wide; the margins are where the HUD will go.
5. **Placeholder art.** Generated in code or minimal, but with correct sizes and the palette the visual direction chose — placeholders whose silhouettes lie about size force hitbox rework later.
6. **`assets/startup-logo.png`.** Add it now, even though it only matters on web. Forgetting it produces a crash that never mentions the logo.

## Acceptance criteria

- `./gradlew :desktop:run` opens the game and the ship responds to keyboard and mouse.
- Moving mouse right and pressing left at once leaves the ship still.
- The window scales at ×2, ×3 and ×4 with no blurring and no fractional scaling.
- A checkerboard test texture shows no distortion at any window size.
- Nothing in `game` reads or writes ECS components directly.
- The render loop allocates nothing per frame — verified with a profiler or an allocation counter.

## Risks

**Pointer capture on web is unverified.** It is needed for the relative mouse. If it turns out to be intrusive in the browser, the fallback is a positional mouse, and then keyboard and mouse compete instead of cancelling. That would change a decided rule, so raise it rather than deciding alone.

**Per-frame allocation is silent.** It does not fail a test; it shows up as stutter under load once there are hundreds of entities.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
