# Deferred proposal — UI input intents (decouple devices from UI logic)

This doc captures a **post‑Demo / Phase 50+** refactor idea: introduce an explicit “UI intent” layer so the UI step logic doesn’t care whether an action came from a controller button, keyboard mapping, or mouse click/drag.

The goal is to make `MC.ui.step` easier to reason about and reduce device-specific branching (“if mouse then…”) while preserving the current mouse UX (hover + real drag-and-drop).

## Motivation

We currently have a clean-ish layering:

- `MC.controls.pollGlobals()` reads raw TIC-80 inputs (`btn/btnp`, `mouse()`).
- `MC.controls.actions(st, raw, cfg)` synthesizes a canonical `actions` shape:
  - controller/keyboard buttons
  - mouse state
  - higher-level semantics (`a.tap`, `a.grabStart`, `x.inspectActive`, wheel→nav, etc.)
- `MC.ui.step(state, view, actions)` drives the UI state machine (browse/menu/targeting/prompt).

This is already pretty good — notably, **mouse LMB is treated as A**, RMB as B, MMB as X.

However, the UI still needs **device provenance** in a few key places:

- “Confirm” should behave differently if it came from the mouse (e.g. click must begin on an item; menu confirm may require pointer-in-destination).
- “GrabStart” should behave differently if it came from the mouse (dragStart must originate on a valid source item).
- Focus policy needs a reliable “last input kind” latch (mouse vs controller), and AI suppression should not accidentally clear it.
- Hover-pick and drag-and-drop necessarily require pointer coordinates, but we’d like those to be handled as *pointer intents* rather than scattered `actions.mouse.*` checks.

This phase introduced `MC.ui.mouse` as an adapter to concentrate mouse specifics, but the underlying tension remains: `MC.ui.step` operates on **physical actions** rather than **UI intents**.

## Goals

- **Make UI logic device-agnostic** for primary flows:
  - nav / confirm / cancel / inspect / grab-start / grab-release
- Keep pointer UX intact:
  - hover selection
  - DnD targeting snap + source cancel latch
- Preserve existing determinism + tests:
  - no runtime “fallbacks” (use canonical shapes + config sanity tests)
- Keep it incremental:
  - allow gradually migrating `MC.ui.step` to intent consumption without a big-bang rewrite.

## Non-goals

- Not a UX redesign.
- Not changing cmd profiles or engine commands.
- Not re-architecting `MC.ui.computeRowModels` overlays (separate refactor proposal).

## Proposed architecture

### Layering: actions → intents

Keep `MC.controls.actions` as the “physical synthesis” layer and add a new module:

- `MC.ui.intentFromActions(actions)` (name bikeshed: `MC.uiInput`, `MC.input`, `MC.intents`)

It returns a **canonical intent object** (stable shape; no optional fields):

```js
// Proposed canonical intent shape (example).
{
  nav: { up:false, down:false, left:false, right:false, source:"pad"|"wheel"|"" },

  confirm: {
    tap:false,         // A-tap or LMB click (non-drag)
    down:false,        // A-down or LMB down
    released:false,    // A-release or LMB release
    grabStart:false,   // hold-A enter or mouse dragStart
    grabActive:false,  // A-hold active or mouse drag active
    source:"pad"|"mouse"|""   // which source produced *this frame’s* confirm/grab edge
  },

  cancel: { pressed:false, source:"pad"|"mouse"|"" },     // B or RMB
  inspect: { active:false, source:"pad"|"mouse"|"" },     // X-hold or MMB-hold

  pointer: {
    avail:false,
    x:0, y:0,
    pressX:null, pressY:null,
    moved:false,
    scrollX:0, scrollY:0,
    left:{ down:false, pressed:false, released:false, tap:false },
    middle:{ down:false, pressed:false, released:false },
    right:{ down:false, pressed:false, released:false },
    dragging:false,
    dragStart:false
  },

  // Convenience summary for focus policy:
  used: { mouse:false, controller:false }
}
```

Key idea: `MC.ui.step` should primarily consume:

- `intent.nav.*`
- `intent.confirm.*`
- `intent.cancel.pressed`
- `intent.inspect.active`

…and only touch `intent.pointer.*` in the few places where pointer geometry matters (hover pick, DnD snapping, menu hover, etc.).

### Intent provenance (why we need it)

Some UI policies depend on *how* the intent happened:

- **Mouse click empty space should not confirm**:
  - `intent.confirm.tap === true` alone is not enough; we need `intent.confirm.source === "mouse"` to enforce press-hit gating.
- **Mouse dragStart must originate on a valid item**:
  - `intent.confirm.grabStart` is shared with hold-A; only mouse should require “press began on item” gating.

Centralizing provenance in intents keeps this device-knowledge out of the UI state machine.

### Focus policy becomes intent-driven

Replace ad-hoc “mouse used” checks with:

- `intent.used.mouse` / `intent.used.controller`

This cleanly handles:

- “controller wins immediately” (if controller used this frame, clear mouse latch)
- AI input suppression (absence of pointer avail shouldn’t clear the latch)

## Migration plan (incremental)

### Step 1 — add intent module + tests

- Add `src/26_ui_intents.js` (or similar) defining:
  - `MC.ui.intentEmpty()`
  - `MC.ui.intentFromActions(actions)`
- Add/extend config sanity tests if new knobs are introduced (avoid runtime fallbacks).

### Step 2 — thread intents through UI step (bridge mode)

Change `MC.ui.step(state, view, actions)` to:

- compute `intent = MC.ui.intentFromActions(actions)`
- keep existing behavior, but start swapping checks:
  - `actions.nav.up` → `intent.nav.up`
  - `actions.a.tap` → `intent.confirm.tap`
  - `actions.b.pressed` → `intent.cancel.pressed`
  - `actions.x.inspectActive` → `intent.inspect.active`

Initially keep `actions` around to minimize diff.

### Step 3 — consolidate pointer policies behind a single adapter

Evolve `MC.ui.mouse` into a more general `MC.ui.pointer` adapter:

- `MC.ui.pointer.shouldHoverPick(intent)`
- `MC.ui.pointer.pickAtPointer(view, computed, intent, predicate)`
- `MC.ui.pointer.applyTargeting(state, view, computed, intent)`
- `MC.ui.pointer.menuTick(view, intent)`

At this point, `MC.ui.step` uses “pointer” semantics without referencing “mouse”.

### Step 4 — remove direct `actions.*` usage from UI

Once fully migrated:

- `MC.ui.step` takes `intent` instead of `actions`, or:
  - keep the public signature but make `actions` strictly internal to `intentFromActions`.

### Step 5 — extend harness + tests

Tests currently patch `actions` into `MC.ui.step`. In an intent world:

- either patch `intent` directly, or
- keep the “actions patch merged into emptyActions()” pattern and let `intentFromActions` handle it.

## Trade-offs

### Pros

- UI logic becomes easier to read: “what the player intended” rather than “which device fired which bit”.
- Focus policy becomes robust and composable (latches driven by intent summary).
- Mouse-specific behavior stays centralized and audit-able.

### Cons / risks

- Another layer adds mental overhead if it isn’t clearly documented and tested.
- Provenance is subtle: a single frame can contain both mouse movement and controller tap. We must define deterministic precedence (“controller wins”, then “mouse used sets latch”, etc.).
- Avoid per-frame allocations if TIC-80 perf becomes sensitive (can reuse an intent object).

## Definition of done (if we implement)

- `MC.ui.step` contains near-zero device-specific checks (“mouse” should not appear outside the pointer adapter module).
- Focus policy uses intent summary, not raw `actions.mouse` probing.
- All tests pass; no runtime fallbacks introduced.

