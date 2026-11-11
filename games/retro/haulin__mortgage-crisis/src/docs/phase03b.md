# Phase 03b — Center row rework + seed/debug cleanup

Phase 03 shipped the 5-row renderer + navigation, but the center row (Row 3) and debug plumbing were still “prototype-y”:

- Render-mode debug text overlapped the opponent hand (Row 1).
- Center row used placeholder labeled boxes (deck/discard/banks).
- It was too easy to think changing `seedBase` affected Debug/Render, when Debug had its own seed value.

Phase 03b fixes those issues while keeping rendering **read-only** (rules/commands still own all state changes).

## Goals

- Rework Row 3 into a real **Deck/Discard + selection preview** center HUD.
- Improve **card backs** (opponent hand + deck) using a fast sprite-based back.
- Unify **seed usage**: Debug/Render resets use the same seed source as the rest of the codebase (the configurable base seed).
- Keep Phase 03 invariants: **row bands stay locked**, navigation + camera stay deterministic, tests remain green.

## What Phase 03b implements

### Render screen cleanup

- Render mode no longer prints the top-left status overlay (which was overlapping Row 1).
- Render mode HUD hint is minimal: **`Y:Mode`** only.
- Debug info (seed/scenario/etc.) remains in the DebugText screen.

### Updates vs Phase 03 (polish pass)

- Mode switching is now **2-mode** (DebugText ↔ Render). The old Boot/“Build OK” screen is removed from the cycle.
- Render mode restores a small **`Phase 03 Render`** title in the center row.
- DebugText mode shows the **currently selected item** (defId + uid, or Deck/Discard) to make debugging faster.

### Row 3 (center) selectables

- Row 3 selectables are **Deck** and **Discard** only (banks are selected directly via bank cards in hand rows).
- Both piles render as compact **vertical stacks**:
  - 0–2 outline-only under-layers for depth (2px offsets)
  - a top card:
    - Deck = card back
    - Discard = top discard card face (or empty outline when empty)
  - pile counts rendered via digit sprites (bottom-right of the top card)
  - depth outlines use a black shadow outline plus alternating grey outlines for readability

### Center preview (dev-first)

Whenever something is selected, the center preview shows:

- A mini-card render
- Title (`def.name`)
- Description (`def.desc`) in small font (supports `\n` line breaks)

Debug-only reveal behavior (gated by config):

- Selecting an opponent hand back reveals the underlying card in the preview.
- Selecting the deck reveals the top-of-deck card in the preview.

### Data + scenarios to support the UI

- Card defs now include a `desc` string for all cards (used by the preview).
- Scenarios seed discard to make discard rendering easy to verify:
  - `wildBasic`: discard has **3** cards (depth demo)
  - `houseBasic`: discard has **1** card (no-depth demo)

## Tweak points (single source of truth)

All Phase 03b tweak knobs live in configuration:

- base seed used by Debug/Render resets
- debug flag gating “reveal” behavior in preview
- render knobs for center-row geometry, pile styling, and card-back sprite IDs

## Definition of Done

- `npm test` passes.
- In TIC-80 Render mode:
  - Row 3 shows Deck/Discard stacks with counts
  - Preview updates as selection changes
  - No debug text overlaps the opponent hand row
  - Changing `seedBase` actually changes default deals (in Debug/Render)

