# Brief: the stacked coffee button in the side gutter (ui-systems-dev, QA21-05)

From: senior-graphic-designer, 2026-10-21. Launched by the DM.

## The problem

On the Fold5 inner screen the play screen's Buy me a coffee button goes in the left gutter, but in its one line form it needs 436 px (Gumdrop), 414 (Slate) and 419 (Nova), and the gutter is only 389 to 462 px depending on the system bars. With the gesture hint hidden (Bart can turn it off) Gumdrop and Nova lose the button, and with the hint shown Nova keeps it by 2 px. Bart wants it fixed.

## The decision

In the gutter the button takes a **stacked form**: the cup icon on top, then "Buy me" over "a coffee", all centered. It needs about half the width (touch areas 216, 198, 212 px), and the gutter rule now asks for `space_m` of clear room on both sides of the touch area. On the Fold5 inner screen it then shows in every skin with the hint shown, hidden, or the taskbar shown, at least 76 px clear on both sides. The below the board form, the order of the places, and every hide rule stay exactly as they are.

## Read first

- CLAUDE.md, the 2026-10-21 coffee decision.
- docs/DESIGN_SYSTEM.md 7.15 (rewritten today: "Where, in this order", "The stacked form", "Measured"), 7.10 (the new "Play screen button in the side gutter" row), 7.9 (icon gap).
- docs/reviews/qa-2026-10-21.md, QA21-05.
- tools/coffee_space.gd (my measuring tool; its output is the table in 7.15).

## Files you may touch

- src/ui/coffee_button.gd, src/ui/game_screen.gd, src/ui/screen_copy.gd.
- tests/ui/test_coffee_play_screen.gd, tests/ui/test_coffee.gd.
- scenes/ui/review/ (the play_fold_inner review scenes, if they need the new insets).

Nothing else. No contract change: the button script stays preloaded with no `class_name`.

## What to build

### 1. Copy (src/ui/screen_copy.gd)

Two constants next to `COFFEE`: "Buy me" and "a coffee" (for example `COFFEE_TOP` and `COFFEE_BOTTOM`). Body role, as written in every skin, through `skin.cased(&"body", ...)` like `COFFEE`.

### 2. The stacked form (src/ui/coffee_button.gd)

- A way to switch form, for example `set_stacked(on: bool)` and `is_stacked() -> bool`. Default: one line, so the splash and About are unchanged. Setting the form it already has does nothing (no rebuild, no `minimum_size_changed`), so a layout can call it every time without a loop.
- Stacked content, a VBoxContainer centered in the button, everything centered horizontally, children ignore the mouse:
  - the same SkinIcon (coffee, ink_muted), a square of `skin.font_size(&"body")`;
  - a gap of `roundi(0.25 * skin.font_size(&"body"))` (the same ICON_GAP, now vertical);
  - a MutedLabel "Buy me" and a MutedLabel "a coffee", each one line, `HORIZONTAL_ALIGNMENT_CENTER`, no separation between the two.
- Size: width the widest of the icon and the two labels; height the content height (icon + gap + two label heights), never less than `touch_min`. `content_size()` must give this for the stacked form from the font, before the button is in the tree, as it does now for one line: width `max(font_px, text width "Buy me", text width "a coffee")`, height `max(touch_min, font_px + gap + 2 * font.get_height(font_px))`. Expected about 168 x 174 (Gumdrop), 158 x 175 (Slate with Segoe UI), 156 x 167 (Nova).
- Touch area and pressed fill: as today, `space_s` past the content on both sides, over the full height. The tap rule, the hand off and the look do not change.
- A test hook for the two labels (for example `labels() -> Array[Label]`), next to `label()`.

### 3. Placement (src/ui/game_screen.gd, `_place_coffee`)

1. Below the board: unchanged (D at least `touch_min` + 2 x `space_s`), in the **one line** form.
2. Else the gutter, in the **stacked** form, when `gutter >= stacked width + 2 * space_s + 2 * space_m` (the touch area at least `space_m` from the safe edge and from the column). Centered horizontally in the gutter, vertically on the bar's rect, as today.
3. Else nowhere (form left as it was).

The form follows the place at every layout, so a fold or unfold moves it between the two. Update the doc comment on `_place_coffee` and the class header to match 7.15. The clear rects for Nova's backdrop already use the button's rect grown by `space_s`; check they still cover the stacked button.

## Tests (tests/ui/)

### Phone rows

In test_coffee_play_screen.gd, give the phones their safe insets in **physical px** (divide by the canvas scale for logical px), using the numbers read from Bart's phone (7.15):

| Row | px | density | top px | bottom px | Place |
|---|---|---|---|---|---|
| 20:9 1080 x 2400 | 1080 x 2400 | 3.0 | 120 | 66 | NONE |
| Fold5 cover, hint shown | 904 x 2316 | 2.625 | 85 | 58 | BELOW_BOARD |
| Fold5 inner, hint shown | 1812 x 2176 | 2.625 | 85 | 58 | GUTTER |
| 16:9 with button bar | 1080 x 1920 | 3.0 | 72 | 144 | NONE |
| Fold5 cover, hint hidden | 904 x 2316 | 2.625 | 85 | 0 | BELOW_BOARD |
| Fold5 inner, hint hidden | 1812 x 2176 | 2.625 | 85 | 0 | GUTTER |
| Fold5 inner, no insets | 1812 x 2176 | 2.625 | 0 | 0 | GUTTER |

Keep the first four in that order so COVER and INNER keep their indexes for the resize tests. The Fold5 inner logical canvas is 1998.5 x 2400 (scale 2176 / 2400); 85 px top is 93.75 logical px, 58 px bottom is 63.97.

### Changes to `test_at_155_placement_on_the_four_phones_in_every_skin` (rename it to "on every phone")

- Below the board, touch height still equals `touch_min`; the expected gaps to the board and the bar become 37.1, 35.2, 58.7 px (Gumdrop, Slate, Nova) with the hint shown and 54.4, 52.5, 76.0 with it hidden, within 0.6 px; the button is in the one line form.
- In the gutter: the button is stacked; its touch height is at least `touch_min` and equals the button's height; its touch width is at least `touch_min`; the rest of the checks stay (left of the column, right of the safe edge, centered in the gutter and on the bar, off the board, the bar and the HUD, inside the safe area).

### New test: `test_qa21_05_fold5_inner_gutter_has_room_in_every_skin`

At the Fold5 inner logical size (1998.5 x 2400), for every skin, with the two inset cases Bart can have: top 85 px with the gesture hint (bottom 58 px) and with the hint hidden (bottom 0), plus the no insets bound (0, 0):
- the place is GUTTER and the button shows;
- it is stacked, its two labels read "Buy me" and "a coffee" exactly (not cased, every skin), and the icon is coffee in ink_muted;
- the clearance from the touch area to the safe area's left edge and from the touch area to the column's left edge are each at least 24 px (expected, within 2 px: hint shown 111, 120, 101; hint hidden 101, 110, 91; no insets 87, 96, 76, for Gumdrop, Slate, Nova);
- the board, HUD and bar rects equal `_layout_before` for that case (nothing moved).

### Other tests

- `test_placement_follows_a_live_resize` and `test_a_skin_switch_keeps_one_button`: add a check that the form follows the place (stacked in the gutter, one line below the board) after each resize and switch.
- test_coffee.gd: the splash and About buttons are still the one line form reading "Buy me a coffee" (`is_stacked()` false).
- A test that calling the form setter with the current form does not emit `minimum_size_changed`.

## Proof

- `godot --headless --path . --import`, then `godot --headless --path . --script res://tests/run_tests.gd` exits 0. Name the new and changed tests.
- The gutter widths and clearances the new test prints, per skin and inset case. They should match 7.15 within 2 px (Slate measures with Segoe UI on Windows).
- Screenshots of the play screen at the Fold5 inner shape in each skin, with the hint shown: `godot --path . res://tools/capture.tscn -- --scene res://scenes/ui/review/review_<skin>_play_fold_inner.tscn --size 1999x2400 --safe 94,64 --out docs/design/review/qa21-05-<skin>-fold-inner.png`, and one with `--safe 94,0` per skin (`-hint-hidden` in the name). Report the paths; I review them against 7.15.
