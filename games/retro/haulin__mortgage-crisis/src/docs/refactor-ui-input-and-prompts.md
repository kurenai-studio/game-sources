# Deferred refactor — UI input modality + prompt helpers

This doc captures a **follow-up refactor** motivated by a cluster of UI bugfixes around:

- mouse vs controller hint consistency
- “autofocus pause” latching for mouse usage
- prompt flows (especially `respondAction`, `placeReceived`, `replaceWindow`)
- “resync after cursor move” (compute models + cameras + focus anchor snapshot)

The bugfixes worked, but several landed as **ad-hoc local patches**. This proposal consolidates them into small, reusable helpers so future changes don’t reintroduce duplication or subtle 1‑frame focus glitches.

## Motivation (symptoms we saw)

- **Different layers used different sources of truth** for input modality:
  - prompt toast text used `view.ux.autoFocusPausedByMouse`
  - targeting overlay help used `view.targeting.hintMode`
- **Prompt center buttons** (Step/Reset/Next/End/Menu) were handled inconsistently across prompt kinds.
- **Cursor snap without anchor refresh** caused a *1‑frame flash* (snap → next tick focus preservation restores prior anchor).
- Cursor-mode targeting during mouse usage could look “sticky” because cursor highlight is a strong selection signal.

## Goals

- **One place** to determine “what input mode are we in?” (mouse vs controller).
- **One helper** for “cursor moved, now recompute+camera+anchor”.
- **One helper** to handle prompt-time center-row buttons consistently (debug buttons allowed, End often disallowed with prompt-specific message).
- Keep existing behavior (only change UX where explicitly intended).
- No runtime fallbacks; lean code; covered by tests.

## Proposed refactors

### 1) Introduce `resyncAfterCursorMove` (single source of truth)

Create a helper used whenever the UI *intentionally* moves the cursor and wants that to “stick”:

- recompute: `MC.ui.computeRowModels(state, view)`
- update cameras: `MC.ui.updateCameras(state, view, computed)`
- snapshot anchor: `MC.ui.focus.snapshot(state, view, computed)`

**Where it belongs**: `src/65_ui.js` near `MC.ui.step` (local helper) or `MC.ui` namespace if shared across modules.

**Use cases**:

- prompt “snap back” behaviors (e.g. replaceWindow invalid selection)
- any future “snap to default target” prompt behaviors
- any “redirect selection” rules that must not be undone by `focus.preserve()` next tick

### 2) Unify prompt center-button handling

Prompts should all behave the same regarding center-row buttons:

- **Debug buttons**: Step/Reset/Next are allowed (when present/enabled)
- **End**: typically disallowed in forced-response prompts, with prompt-specific error text
- **Main menu**: allowed (global escape) when present

Instead of repeating per-prompt logic blocks, add a helper:

```
handlePromptCenterButton(sel, { endErrorText, allowEnd })
  -> intent | null
```

Then each prompt only needs to define its “End is disallowed” message.

### 3) Make input modality explicit and reusable

Right now, input modality is implied by:

- `view.ux.autoFocusPausedByMouse` (a latch driven by mouse activity)
- and ad-hoc assignments to `view.targeting.hintMode`

Propose a single derived function:

```
uxInputMode(view) -> "mouse" | "controller"
```

Then:

- prompt toast strings use `uxInputMode(view)`
- targeting overlay help uses a single “sync hint mode” function
- cursor-mode targeting can decide whether to sync cursor highlight based on `uxInputMode(view)`

### 4) (Optional) Convert cursor-mode targeting to interaction-mode strategies

Instead of embedding `isDragging/isSnapped` conditionals inside the cursor-mode overlay pass, encode it as explicit strategies:

- `cursorIdle`
- `cursorDragUnsnap`
- `cursorDragSnap`

This reduces “if soup” and keeps policy changes localized without drifting into per-kind duplication.

## Implementation checklist (suggested order)

1) Add `resyncAfterCursorMove` helper and convert all “snap+recompute+camera+snapshot” callsites.
2) Add `handlePromptCenterButton` helper and convert prompt branches.
3) Add `uxInputMode(view)` helper and use it from prompt toasts + targeting hint sync.
4) Add/adjust tests to lock behavior:
   - “snap should stick” (no 1‑frame flash)
   - “debug Next works during respondAction prompt”
   - “targeting hints follow last input mode”

## Testing / safety

After any `src/` change:

- `npm test`
- `npm run build` (keeps `game.js` in sync with `src/`)

