# Fixes: tile-board-artist, Phase 1 round 2

From the senior-graphic-designer. Strong work: the three boards read as three different games, and Gumdrop and Nova are close to final. This list is everything I need changed before the final capture. Where an item contradicts your original brief, this list wins. The interface I compose against stays exactly as it is.

Your write paths are unchanged (board_common/, gumdrop/board/, slate/board/, nova/board/, docs/design/review/board-*.png). I have already changed the token files; re-read them first.

## What changed in the tokens (no code needed, but check the result)

- Tile label sizes went up so labels meet the GDD readability rule (12 dp digits on a 56 dp tile): Gumdrop 4 characters 0.31, Slate 3 and 4 characters 0.33 and 0.31, Nova all four lengths 0.46, 0.42, 0.37, 0.315. `godot --headless --path . --script res://tools/label_check.gd` proves the sizes fit; your job is to make sure nothing in your drawing clips or crowds them.
- Nova `orb_scale` is now 0.88 (was 0.84), `preview_scale` 0.54 (was 0.66), and corona `ray_outer` 1.24 so rays stop short of the neighbors.
- Slate `target_bracket_width` is now 6.
- The mock now follows the GDD: costs, labels and scores changed in mock_state.gd. Nothing you draw should need a change for that.

## Fixes

1. **Gumdrop preview: drop the bubble.** It hides the whole tile above the chain end (the 1024 in the mock). Instead draw the result as a mini tile, `preview_scale` times the tile side, with its lip and a `preview_ring` px ring in `chain`, centered on the gap crossing at the top left corner of the last chain tile, or the top right corner when that tile is in column 0. It may cover the rounded corners of the four tiles round that crossing, never their numbers. Delete PREVIEW_PADDING, POINTER_HEIGHT, POINTER_WIDTH and BUBBLE_GAP.
2. **Nova preview: same placement rule** as Gumdrop (top left gap crossing, top right in column 0). At the new sizes it should sit clear of the four orbs; check it does not touch their rims.
3. **Slate chain line: stop cutting it.** Remove the cut logic and MAX_CUTS. Draw the line node to node in one piece. Draw no tail toward the finger; the line ends at the last node. Draw order: fills, frames, line, nodes, numbers. On chained tiles draw each number with an outline `number_knockout` px wide in that tile's fill color first (draw_string_outline), then the number on top. The line then stops cleanly at the glyph edge and the number keeps its exact contrast.
4. **Slate target brackets:** `target_bracket_width` px thick, hugging the outside of the tile edge with no offset, so they never reach the neighbor tile.
5. **Read every accepted proposed token from the tokens** with `tokens.num()` and delete the const:
   - gumdrop/board/tile_painter.gd: TARGET_EDGE_WIDTH to `target_edge_width`, SPECIAL_RIM_WIDTH to `special_rim_width`, SPECIAL_RIM_SEGMENTS to `special_rim_segments`
   - nova/board/board_view.gd: SPAWN_BLOOM to `spawn_bloom`
   - nova/board/tile_painter.gd: CHAIN_GLOW to `chain_glow`, TARGET_GLOW to `target_glow`, ORBIT_DASHES to `orbit_dashes`, ORBIT_DASH_FILL to `orbit_dash_fill`, ORBIT_BREATH to `orbit_breath`, ORBIT_TURN to `orbit_turn`, RAY_INNER to `ray_inner`, RAY_OUTER to `ray_outer`, RAY_WIDTH to `ray_width`, and the ray count to `ray_count`
   - slate/board/board_view.gd: FLASH_CUT_LEVEL to `flash_cut`

## Decisions on your open points

- Gumdrop chained tiles keep `press_scale` 0.94 while chained, on top of `lip_pressed`: yes, that is the intent.
- Gumdrop lighter top edge: leave it out.
- Labels on 48 px tiles in skin chips: no change needed. My settings screens use 72 px mini tiles with one character values only.
- The 18 proposed tokens: accepted and in the token files, except the four bubble values, which go away with fix 1.

## Proof

Same as your brief: contrast check and label check pass, the nine review PNGs recaptured without errors, and each demo runs 20 seconds without an error line. Look at the Slate mock and the two previews yourself before you report.
