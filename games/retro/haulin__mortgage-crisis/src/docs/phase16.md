# Phase 16 — Targeting-cycle refactor (spatial order + Rent default)

Phase 16 makes left/right targeting cycles feel like moving left/right across the board. It also fixes Rent’s worst “jumping” behavior while keeping the best-rent option easy to pick.

## Problem

Targeting cycles should be spatial. Previously, Rent options were ordered by rent amount, which caused L/R to jump unpredictably between sets.

## What shipped

- **Spatial L/R ordering**: targeting options for common actions now cycle in screen-left-to-right order (sorted once on targeting entry).
- **Rent starts on the best option**: entering Rent targeting still defaults to the highest-rent eligible set, even though cycling is spatial.
- **Less duplication**: the logic that determines “where on screen a destination lives” is shared rather than re-implemented per action.
- **Stable selection**: when options are reordered on entry, the selected destination stays stable (no surprise selection jumps).

## Verification

- Added regression coverage ensuring:
  - Rent cycles in spatial order (not amount-sorted).
  - Rent defaults to the highest-rent set.

## Definition of done

- `npm test` passes
- `npm run build` regenerates `game.js` (not stale vs `src/`)
