# Fixes: tile-board-artist, Phase 3 production board and tile views

From the senior-graphic-designer. Verdict:
- **Gumdrop is approved as built.**
- **Slate and Nova are approved once the three fixes below are in.**

The boards look like the Phase 1 directions at production quality, and splitting tiles into their own canvas items, with effects that only change transforms, is the right call for 60 fps. Your 10 open points were well argued: I accept eight as built and change two (points 6 and 10). I also found one problem you did not list (fix 2).

DESIGN_SYSTEM.md records every decision; re-read sections 3.6, 4.7, 5.5, 5.7, 6.5, 6.6 and 6.7 first. I have already changed the token files tools/directions/slate/tokens.gd and tools/directions/nova/tokens.gd.

Your write paths are unchanged: src/skins/, scenes/skins/, tests/skins/, and docs/design/review/prod-board-*.png.

## Fixes

1. **Slate: inset the chained and joinable frames (your point 6).**
   - Read the new Slate number `frame_inset` (0.03 of the tile side).
   - Draw the chained frame and the joinable frame on the tile rect shrunk by `frame_inset * side`, on slabs and blocks alike. A band of tile fill then sits outside an ink_dark frame, so it shows on light blocks.
   - Swap's selected frame stays at the edge, next to its brackets.
   - Check that the label plate still clears the frame at the smallest tile you test.
2. **Nova: a visible chained rim on the white hole (new).**
   - In prod-board-nova-tiers.png the chained 128K looks the same as the normal one: a white rim on a white orb vanishes.
   - Read the new Nova number `dark_rim_from` (131072). For values from it up, draw the chained rim in ink_dark. Every other orb keeps the chain color.
   - The joinable orbit, the press orbit and Swap's selection orbit stay as they are; they read on the white hole's glow.
3. **Nova: sparks you can see (your point 10).**
   - `clear.spark_size` goes from 4 to 8 px.
   - Draw each spark in the orb's fill lightened by `ray_lighten` (as the corona rays are), not in the plain fill. Today a 2's dark red sparks are nearly invisible on deep space.
   - Keep them under the orbs, as you have them.
4. **Skin files.** Update the .tres files to match the token files:
   - slate.tres: `numbers` gets `frame_inset` 0.03.
   - nova.tres: `numbers` gets `dark_rim_from` 131072.0, and `motion.clear` gets `spark_size` 8.0 (was 4.0).

## Decisions on your 10 points

| # | Point | Decision |
|---|---|---|
| 1 | Motion for Double, Swap, Shuffle, Undo | Accepted as built. Recorded in 3.6, "Booster effects". |
| 2 | Nova's merge holds input for travel only, its Double for none; Gumdrop and Slate travel plus pop | Accepted. Recorded in 3.6, "Effect lengths and input". The controller already runs the pop together with the clear. |
| 3 | Gumdrop burst after the clear, clear's transition eased out, linear fade | Accepted. Recorded in 4.7. |
| 4 | Gumdrop clear squash from the back curve's dip (about 10%) | Accepted. No token needed. Recorded in 4.7. |
| 5 | Gumdrop fall stops on its cell; the overshoot becomes the landing squash | Accepted. Recorded in 4.7. |
| 6 | Slate frames on light blocks vanish | Changed: fix 1, new token `frame_inset`. |
| 7 | Gumdrop joinable outline invisible on the tray | Accepted as built. The outline exists to keep the lemon ring apart from light neighbor tiles; on the tray the ring reads on its own. Recorded in 4.7. |
| 8 | Preview on a row 0 tile reaches above the board | Accepted. It stays above the finger and clear of the score; the board must not clip it. Recorded in 4.7 and 6.7. |
| 9 | Same press feedback for every booster; ending targeting clears press and selection | Accepted. Recorded in 3.6. |
| 10 | Nova sparks very subtle | Changed: fix 3. |

## Proof

- All tests pass, including tests/skins/ after the .tres updates: `godot --headless --path . --script res://tests/run_tests.gd`.
- `contrast_check.gd`, `ramp_check.gd` and `label_check.gd` in tools/ all pass.
- Recapture the four review PNGs these fixes touch:
  - prod-board-slate-board.png
  - prod-board-slate-tiers.png
  - prod-board-nova-tiers.png
  - prod-board-nova-effects.png (pick a frame where the sparks are well out)

  Report the paths.
