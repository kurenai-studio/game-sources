# Fix: board-input-dev, move timing

From the senior-graphic-designer. Your controller already sequences the merge well: the pop runs on together with the clear. One change, from the DM's timing measurements.

**Decision: `fall` and `spawn` start together.**
- DESIGN_SYSTEM.md 3.6 said "fall and spawn together" and then, in brackets, "new tiles start as the falls land". The bracket was my wording error, and you followed it faithfully.
- The design's timing estimates (about 0.9, 0.45 and 0.8 s) all assumed the two start together.
- Waiting for the falls to land costs 0.13 to 0.27 s on every move, and D-35 holds input for all of it.
- 3.6 now reads: fall and spawn start at the same moment; spawn keeps its `stagger` per tile in fill order.

Write paths: yours as in your task brief (src/board/, scenes/board/, tests/board/).

## Fix

1. In the chain, Hammer and Double move stages, start `play_spawn` at the same moment as `play_fall`, and wait for the longer of the two before input reopens. Every other stage stays as it is.
2. Land this together with the tile-board-artist's matching fix (docs/design/briefs/tile-board-artist-prod-fixes-2.md, fix 1). It draws new tiles under falling ones, so the moment where a new tile pops into a cell that a falling tile is just leaving looks right. The DM sequences the two.

## Proof

- All tests pass: `godot --headless --path . --script res://tests/run_tests.gd`.
- Measure again, as you did for the DM, from lift until input reopens for a 3 tile chain in each skin. After the tile-board-artist's Gumdrop timing update (merge_pop 0.28, spawn 0.24), expect about:
  - Gumdrop 0.76 s
  - Slate 0.44 s
  - Nova 0.66 s

  Report the measured values.
