# Deferred proposal — unify targeting geometry (slot + screenX)

This doc captures a **post‑MVP / Phase 50** refactor idea: unify “cmd destination → on‑screen position” logic so we don’t maintain the same geometry rules in multiple places.

It expands on the existing deferred bullet in `docs/plan.md` (“Consolidate UI slot/stack geometry helpers…”).

## Motivation

Phase 16 added **spatial L/R targeting-cycle ordering** driven by cmd profiles (`ui.screenXForCmd`) and introduced a shared helper:

- `MC.cmd.screenXForCmdDest(ctx, cmd)` in `src/54_cmd_profiles.js`

However, we still have **two parallel implementations** of destination geometry:

- **Overlay/preview placement** inside `MC.ui.computeRowModels()` (implemented in `src/67_ui_row_models.js`):
  - today, slot math is handled by `MC.ui.rowModels.ops.slotForCmd` and related helpers
- **Screen-space sorting X** via `MC.cmd.screenXForCmdDest` in `src/54_cmd_profiles.js`

They are consistent today, but any future change to stack layout, slot reservation, or destination semantics risks divergence.

## Goals

- **Single source of truth** for “destination cmd → slot”.
- Keep cartridge lean: **no new defensive runtime fallbacks**; rely on existing invariants + tests.
- **No UX change**: preserve current preview placement, ghost placement, ordering, and camera behavior.
- Keep layering understandable: the helper should live where it naturally belongs (UI/layout layer).

## Proposed design

### Core concept: “slot”

Define a canonical slot shape (already used implicitly in `computeRowModels`):

```js
// { row, x, y, stackKey, depth }
```

### New helper(s)

Hoist slot helpers from the row-model overlay module into a reusable UI helper:

- `MC.ui.slotForCmd(ctx, cmd, srcSlot)`
  - Inputs:
    - `ctx`: `{ computed, view, state }` (same shape used by cmd-profile hooks today)
    - `cmd`: engine cmd (`playProp`, `playHouse`, `bank`, `playRent`, `moveWild`, `source`, …)
    - `srcSlot`: optional slot for the “source” destination (used for overlays/cancel)
  - Output: slot or `null`
  - Internals:
    - use `MC.moves.destForCmd(cmd)` for destination semantics
    - use `ctx.computed.models[row].stacks[...]` and `newSetX` to find coordinates

Then implement screenX in terms of slot:

- `MC.ui.screenXForCmdDest(ctx, cmd)` (or keep the name and move the existing function)
  - returns `slot.x - ctx.view.camX[slot.row]`

### What moves where

- Move geometry responsibility out of `MC.cmd.*`:
  - `MC.cmd.screenXForCmdDest` becomes either:
    - a thin wrapper calling `MC.ui.screenXForCmdDest`, or
    - removed entirely once all profiles reference the UI helper.

Cmd profiles continue to be the “registry” of targeting behavior, but they don’t own geometry math.

## Migration plan (incremental, low risk)

### Step 1 — hoist without behavior change

- In `src/67_ui_row_models.js`, hoist the slot helpers into top-level UI helpers:
  - `MC.ui.slotForCmd(...)`
  - (optionally) `MC.ui.slotForDest(...)` if that reads cleaner
- Keep `MC.ui.computeRowModels()` calling the extracted helper (no logic change).

### Step 2 — rebase sorting on the same slot math

- Replace `MC.cmd.screenXForCmdDest` implementation with:
  - `return MC.ui.screenXForCmdDest(ctx, cmd);`
  - or call `MC.ui.slotForCmd(...)` directly.

This deletes the duplicated stack-key/depth math in `src/54_cmd_profiles.js`.

### Step 3 — simplify cmd profiles further

Once screenX is fully UI-owned:

- in `src/54_cmd_profiles.js`, profile `ui.screenXForCmd` can just reference `MC.ui.screenXForCmdDest`
  - (similar to how Phase 16 simplified the per-profile wrappers).

### Step 4 — tests to lock invariants

Add a test that asserts the extracted helper matches what the UI already renders:

- Construct a state + view + `computed = MC.ui.computeRowModels(state, view)`
- For a known cmd (e.g. Rent `setI=0`), call `MC.ui.slotForCmd({state, view, computed}, cmd, srcSlot)`
- Assert:
  - returned `row` matches expected row (table vs hand bank)
  - `stackKey` matches expected (`set:p0:set0`, `bank:p0:row4`, etc.)
  - `x` equals the x used in overlay focus/meta (or equals the known `stackX` result)

This ensures future layout edits can’t accidentally update one path but not the other.

## Non-goals / intentionally unchanged

- **Sly Deal cursor-mode targeting** remains cursor-driven:
  - it targets a specific opponent table item (`findItemForCmd`) and is not a “destination slot” cmd.
- No changes to nav cone scoring, focus policy, or hold-chain behavior.

## Risks + mitigations

- **Subtle off-by-one depth mistakes** (setTop vs setEnd, reserved ghost slot depth):
  - Mitigate by asserting slot coordinates against existing overlay placement in tests.
- **Coupling concerns** (cmd profiles depending on UI helpers):
  - Acceptable because `ui.screenXForCmd` is inherently UI-layer; the cmd profile registry merely points at it.

## Why this is worthwhile

- Removes “two sources of truth” for geometry.
- Makes future features safer:
  - new destination types (e.g. move-to-another-set costing a play) would automatically inherit consistent preview + ordering.
- Makes it easier to reason about targeting:
  - `destForCmd` → `slotForCmd` → (overlay + sorting) becomes an explicit pipeline.

