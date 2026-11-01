# Fixes: tile-board-artist, round 2 (from the screens review)

From the senior-graphic-designer. These come from reviewing the production screens and the move timing. They are separate from round 1 (tile-board-artist-prod-fixes.md); finish round 1 first.

I have already changed the token file tools/directions/gumdrop/tokens.gd. DESIGN_SYSTEM.md 3.6, 4.6, 4.7 and 6.7 are updated; re-read them first.

Write paths: yours as in your task brief (src/skins/, scenes/skins/, tests/skins/, docs/design/review/prod-board-*.png).

## Fixes

1. **New tiles draw under falling tiles.**
   - The board-input-dev will start `play_spawn` at the same moment as `play_fall`, no longer after the falls land (3.6). For about a tenth of a second a new tile then grows in a cell that a falling tile is just leaving.
   - Draw spawning tiles under falling tiles, so the new tile seems to appear from behind the tile that drops away.
   - Your draw ranks already order tiles; give a spawning tile a lower rank than any falling tile until its spawn ends.
   - The DM lands this together with the board-input-dev's change.
2. **Clamp the chain tail to the board.**
   - The tail from the last chain tile toward the finger follows the finger off the board today, over the HUD or the bar.
   - Clamp the tail's end point to the board's rect: Gumdrop to the tray's outer edge, Nova to the board view's rect. Slate draws no tail.
   - The chain itself stays when the finger leaves the board (AT-19); only the drawn tail stops at the edge.
3. **Gumdrop timing.** gumdrop.tres `motion` changes:
   - `merge_pop.duration` 0.34 becomes 0.28 (equal to the clear, so the pop and clear stage is 0.28)
   - `spawn.duration` 0.30 becomes 0.24

   Together with fix 1 a chain settles in about 0.76 s instead of 1.11 s. No other value changes.

## Proof

- All tests pass, including tests/skins/ against the updated token file: `godot --headless --path . --script res://tests/run_tests.gd`.
- `contrast_check.gd`, `ramp_check.gd` and `label_check.gd` in tools/ pass.
- Recapture prod-board-gumdrop-effects.png, with its spawn row taken from a fall and spawn that overlap. Add one frame where a falling tile is just leaving a cell that a new tile is entering.
- Recapture prod-board-gumdrop-board.png with the finger outside the tray, showing the clamped tail.
