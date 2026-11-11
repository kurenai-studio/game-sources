# Phase 17 — Mouse controls (hover + click + drag-and-drop)

Phase 17 adds **mouse controls** as a layer on top of the existing controller/keyboard UX, without breaking the controller-first model.

Mouse works on:

- Title screen
- How to Play screen
- In-game UI (browsing, menus, targeting, prompts)

## What shipped

### Mouse mapping (parity with controller)

- **Hover**: moves the selection cursor
- **Left click**: confirm / open menu (A tap)
- **Left drag**: quick play via targeting; release confirms (A hold → release)
- **Right click**: back/cancel (B)
- **Middle click (hold)**: Inspect (X hold)
- **Wheel**: optional up/down navigation pulses (configurable)

### Drag-and-drop visuals

- While dragging and **not snapped**, the selected card floats under the cursor.
- Legal destinations show as **ghost outlines**.
- When snapped, the normal targeting preview is used.

### Cancel behavior + “leave source” latch

- Dropping off-target cancels.
- Dragging back onto the source and releasing cancels.
- A small latch prevents a drag from immediately snapping back to source the moment it starts.

### Autofocus vs mouse

- Autofocus “snap” rules pause while the mouse is the active input source, so hover selection doesn’t fight focus logic.
- Controller input clears the pause immediately (“controller wins”).
- The pause behavior stays stable across AI turn boundaries.

### Cleaner input contract

- Inputs are normalized into a canonical “actions” shape so UI code doesn’t need defensive null checks.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
