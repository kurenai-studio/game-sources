# Brief: ui-motion-artist, the 2026-10-13 additions

From the senior-graphic-designer. Stars, free boosters and the reading screens need new interface pieces in all three skins: the HUD star counter, the star icon, the star earned effect, Free on the booster bar, and the theme pieces for How to play, About and the license texts. Three QA findings Bart chose to fix land here too: QA6-04 (the notice while the offer is open), QA6-05 (touch sizes) and QA6-08 (the content column).

Work in `C:\bart\sumup-work` (branch `additions`), never in `C:\bart\numbergame`.

## Read first

- CLAUDE.md: the 2026-10-13 decisions.
- docs/GDD.md:
  - 11.5 (D-45 stars), 13.9 (D-46 free boosters);
  - AT-117 to AT-139: the "Play" parts say what the player must see.
- docs/ARCHITECTURE.md:
  - section 4 (MoveResult.notice_values and stars_earned, BoosterStatus.free);
  - section 5 (GameSession.stars and free_held);
  - section 7, your contract.
- docs/DESIGN_SYSTEM.md:
  - 2.7 (touch, QA6-05) and 2.8 (the content column, QA6-08);
  - 3.4 (names keep their capitals), 3.5, 3.6 (the star moment);
  - 7.1 (the notice layer) and 7.5 (the notice while the offer is open, QA6-04);
  - in 4.7, 5.7 and 6.7: Clear notice, HUD, Star counter, Star earned effect, Booster bar (Free), Icons;
  - the motion tables 4.6, 5.6 and 6.6; the text pairs 4.3, 5.3 and 6.3;
  - 7.10 (copy), 7.11 (the reading screen theme pieces), 10.
- The mockups in docs/design/additions/:
  - <skin>-play_star.png (the star moment), <skin>-play_free.png (4 stars, 1 free, Free on the bar), <skin>-icons.png (the star at each progress, the chevron and arrow);
  - <skin>-howto.png, <skin>-about.png and <skin>-license.png (the reading screen looks).
  - They are drawn by tools/additions/ over the real HUD and bar. You may read that code for the star geometry (an outline band of one quad per edge, and a fill clipped from the bottom by area), but never preload anything from tools/ in src/: tools/ does not ship.

The new tokens (heading and reading roles, star_icon, reading_line_spacing, scroll_bar, star_earn, star_convert) reach the SkinData resources through the tile-board-artist's brief. Until they land, `skin.num()` reports them missing. Build against the names; the values are in DESIGN_SYSTEM.md and tools/directions/<id>/tokens.gd.

## Write paths

src/design/, scenes/design/, tests/design/, and docs/design/review/prod-ui-*.png.

## Contract changes (the DM confirms them in ARCHITECTURE.md section 7 before you start)

```gdscript
# SkinHud
## D-38 and D-45 clear notice (AT-104). values: the values the notice names (MoveResult.notice_values, not
## cleared_values). stars_earned > 0 adds "+n" and the star and plays the star earned effect into the counter.
## While the HUD is hidden (the offer has its place), the notice and the star take their offer placement
## (DESIGN_SYSTEM.md 7.5).
func show_clear_notice(values: PackedInt64Array, board_rect: Rect2, stars_earned: int = 0) -> void
## D-45, D-46: this run's star count and the free boosters held. Shown at once, with no effect, unless a star
## effect is running that will deliver exactly this count: then the effect ends on these values.
func set_stars(count: int, free_held: int) -> void
## QA6-04: the play screen's notice layer, a full screen Control above the board and the offer panel and
## below every dialog. The notice and the flying stars are its children, never the HUD's, so they show
## while the HUD is hidden. Without a layer the HUD draws them on itself, as today.
func set_notice_layer(layer: Control) -> void
```

- In one move, GameScreen calls `show_clear_notice` (from `move_resolved`) before `set_stars` (from `status_changed`), as ARCHITECTURE flow rule 2 orders them.
- Any `set_stars` that the running effect will not deliver (a new run, a load, a free booster used) ends the effect and shows the values at once.
- The Theme variations of 7.11 join the list in ARCHITECTURE section 7.
- SkinIcon.ICON_NAMES gains `star`, `chevron` and `arrow`.

## Tasks

1. **Icons** (4.7, 5.7, 6.7): `star`, `chevron` and `arrow` in each skin's icon class, on the 24 unit grid, with the geometry given there. The `star` icon is the full star. The counter's progress star (outline band plus a fill covering a third or two thirds of its area) is the HUD's own drawing; build its shapes once per size, never in `_draw()`.
2. **Clear notice** (src/design/shared/clear_notice.gd and each HUD):
   - the notice names the values it is given;
   - when stars were earned, "+n" and a filled star follow the copy (4.7);
   - it still never takes input.
3. **HUD star counter, per skin:**
   - Gumdrop: the star pill and the free pill in the top row.
   - Slate: the counter on the caption line, with "STARS" and "1 FREE".
   - Nova: the star and count, and the free count, on the best line, the best text staying centered.
   - Check the fits quoted in each section at 1080 px with a 13 character best score and a 2 digit count, and report them.
4. **Star earned effect and conversion, per skin:** the timing, path, landing, conversion and every rule in 3.6:
   - several stars in one move;
   - a landing that makes a multiple of 3;
   - a later notice finishing a running effect;
   - never holding input;
   - not waiting for the HUD to be visible.
   The count must show by the time input reopens: Gumdrop lands at 0.50 s, Nova at 0.54 s, Slate at once.
5. **Free on the booster bar:** when `BoosterStatus.free` is true, the cost line shows the star and Free (Slate FREE, Nova free), in each look's colors, disabled boosters included (4.7, 5.7, 6.7). Otherwise the cost shows as today.
6. **Reading screen theme pieces** (7.11), in every skin's Theme:
   - HeadingLabel and ReadingLabel (with `line_spacing` = `reading_line_spacing`);
   - SectionPanel (Gumdrop's lipped card, Slate's padding, Nova's nothing);
   - RowButton (flat; pressed fills behind its content, reaching `space_s` past it);
   - RowDetailLabel;
   - the ScrollContainer and VScrollBar looks: the bar `board_margin` wide, the grabber `scroll_bar` wide in its middle, at least 96 px, in line, ink_muted while dragged, no track, no arrows.
7. **Copy** (7.10) in src/design/shared/ui_copy.gd: "+{n}", "Free", "{n} free" and "Stars", cased by the skin's role rule.
8. **QA6-04, the notice while the offer is open (3.6, 7.1, 7.5).**
   - The notice and the flying stars live on the notice layer.
   - While the HUD is hidden:
     - Gumdrop and Nova place the notice as in play;
     - Slate's notice becomes a badge bar of the 7.8 badge height, sized to its content, centered on the board's top edge;
     - the star rises `space_l` from the notice's star and fades (Gumdrop, Nova); Slate shows only the notice.
   - When the HUD comes back, the counter shows its values with no effect, and a notice still holding stays where it is.
9. **QA6-05, touch (2.7).** `touch_min` becomes 160 through the tokens (the tile-board-artist's brief), and everything that reads it follows. Three things need your hands:
   - Gumdrop's star pill starts at the pause button's touch area's right edge (164 px), not inside it (4.7).
   - Gumdrop's booster buttons take touch on the dock face's whole height (174 px) and across to the middle of the gaps beside them, with no change to the drawing (4.7).
   - Your toggles and icon buttons keep their drawn sizes inside the larger touch area.
10. **QA6-08, the content column (2.8).** The play screen gives the HUD and the booster bar the column's rect, which can be narrower than the screen. Lay out from your own rect only: the dock sits `board_margin` inside it, Slate's strip and hairlines span it, and Nova's rings spread across it. Never read the viewport's width.

## Proof

- All tests pass: `godot --headless --path . --script res://tests/run_tests.gd`. New tests in tests/design/ cover, in all three skins:
  - every icon name draws;
  - `set_stars` shows the count and the free count, and hides the free count at 0;
  - the notice shows "+n" and a star only when stars were earned, and names the values it was given;
  - a status with `free` shows Free, disabled included;
  - a star effect ends on the values `set_stars` gave;
  - the counter and the effect never take input;
  - with a notice layer set and the HUD hidden, the notice still shows (visible in the tree), in its offer placement;
  - every booster button's touch area is at least `touch_min` on each side;
  - the HUD and bar lay out inside a rect narrower than the screen (for example 1,220 px wide inside a 1,998 px viewport).
  Name the tests in your report.
- `godot --headless --path . --script res://tools/contrast_check.gd` passes.
- Your review scenes (scenes/design/ui_<skin>_play.tscn) get three more bar and HUD samples:
  - count 0;
  - count 4 with 1 free, the bar all Free and Undo disabled;
  - the notice "No more 2s" with "+1".
  Capture all six review PNGs:

```bash
godot --path . res://tools/capture.tscn -- --scene res://scenes/design/ui_gumdrop_play.tscn --out docs/design/review/prod-ui-gumdrop-play.png
```

  and the same for `gumdrop_parts`, `slate_play`, `slate_parts`, `nova_play` and `nova_parts`. Add one frame of each skin's star effect mid flight (Slate: the flash), and report its path.

## Report

Files changed, the commands above with their results, the measured fits, and anything in the spec that did not fit your code.
