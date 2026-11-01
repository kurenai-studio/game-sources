# Brief: tile-board-artist, the 2026-10-13 additions

From the senior-graphic-designer. Small task: the skin resources get the new tokens, and the board view must work as a one row board for the How to play example rows.

Work in `C:\bart\sumup-work` (branch `additions`), never in `C:\bart\numbergame`.

## Read first

- CLAUDE.md (2026-10-13 decisions).
- docs/DESIGN_SYSTEM.md: 2.4 (Nova orb_scale 0.89), 2.7 (touch_min 160), 3.4, 3.5, 3.6 (new names and the star moment), 4.3 to 4.6, 5.3 to 5.6, 6.3 to 6.6 (the new values), 7.12 (example rows), 10.2 (the token list).
- tools/directions/<id>/tokens.gd: I have already added the new values there, so tests/skins/test_skin_values.gd fails today until the resources match. That is the hand over.

## Write paths

src/skins/, tests/skins/, scenes/skins/, and docs/design/review/prod-board-*.png.

## Tasks

1. **Schema (src/skins/skin.gd).** Add to the shared schema, so `validate()` asks for them in every skin:
   - TYPE_ROLES: `heading`, `reading`
   - SHARED_NUMBERS: `star_icon`, `reading_line_spacing`, `scroll_bar`
   - MOTION_NAMES: `star_earn`, `star_convert`
2. **The three resources (src/skins/<id>/<id>.tres).** Make them hold exactly what tools/directions/<id>/tokens.gd holds:
   - the two type roles;
   - the three numbers;
   - the two motions with their extras;
   - the new text pairs: Gumdrop 3, Slate 1, Nova none;
   - QA6-05 (DESIGN_SYSTEM.md 2.7): `touch_min` and `button_height` both from 144 to 160, in all three skins;
   - QA6-05 (DESIGN_SYSTEM.md 2.4), Nova only: `orb_scale` from 0.88 to 0.89 and `board_gap` from 24 to 22. The orbs grow 1.1% into their gaps, to 56.3 dp on the Fold5 cover screen, and the pitch and the board's size stay the same. Check in your review captures that the targeting orbit, the joinable orbit and the corona rays still read cleanly between the larger orbs.
   Same names, same order, nothing else changes.
3. **One row board views (DESIGN_SYSTEM.md 7.12).** How to play draws each example chain with your board view, used on its own:
   - `SkinCatalog.make_board_view(skin)`, `setup(skin, n, 1)` for n from 2 to 5
   - `set_board(values)`, `set_chain(all n cells in drag order, Vector2(-1, -1))`
   - no preview, no highlight, no input
   - sized so its tiles are 112 px: width n x 112 + (n - 1) x `board_gap` + 2 x `board_padding` (Nova: n x 112 / `orb_scale`), height `preferred_height(width)`

   The mockups in docs/design/additions/<skin>-howto.png already render 1 x 2 and 1 x 3 boards with today's code and showed no errors. Check that nothing assumes 5 x 8 (fill order, spawn stagger, preview placement, the Slate label plates, Nova's beam colors). Fix anything that does, and add a test in tests/skins/ that builds 1 x 2 to 1 x 5 boards in every skin, chains every cell and reports no errors.

## Proof

- All tests pass, test_skin_values included: `godot --headless --path . --script res://tests/run_tests.gd`. Name your new tests in the report.
- `godot --headless --path . --script res://tools/contrast_check.gd` passes. Its "Note: n pair(s) ... not yet in the skin resources" line is gone.
- `godot --headless --path . --script res://tools/ramp_check.gd` and `godot --headless --path . --script res://tools/label_check.gd` pass.
- `godot --path . res://tools/additions/additions_capture.tscn -- --page howto` writes 3 PNGs without errors. Report what you saw in the example rows.

## Report

Files changed, the commands above with their results, and anything in the spec that did not fit your code.
