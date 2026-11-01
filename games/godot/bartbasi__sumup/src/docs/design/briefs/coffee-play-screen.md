# Brief: Buy me a coffee on the play screen and in Pause (ui-systems-dev)

From: senior-graphic-designer, 2026-10-21. Launched by the DM after the unlimited numbers work, in the same install.

## Read first

- CLAUDE.md, the 2026-10-21 decision on the play screen coffee button.
- docs/DESIGN_SYSTEM.md 7.15 (this change), 7.2 (the button itself), 2.3 and 2.8 (the play screen layout and the content column).
- docs/GDD.md 15.5 (Buy me a coffee), once the lead-game-designer has updated it for the play screen.

## Who

Only ui-systems-dev. The space is GameScreen's (below the board, or the gutter outside the content column), not the HUD's or the bar's, so ui-motion-artist has nothing to do. The button component (src/ui/coffee_button.gd) is reused unchanged.

## Files you may touch

- src/ui/game_screen.gd.
- tests/ui/ (a new test file for this, and existing GameScreen layout tests if they count children).

## What to build

1. **One CoffeeButton on GameScreen,** made like the splash one, above the backdrop and under every dialog, the offer and the notice layer.
2. **Place it in layout_in,** after the board is placed, from the rects layout_in already has (7.15):
   - D = the bar's top less the board's bottom. If D is at least `touch_min` + 2 x `space_s`: the touch area is centered horizontally in the column and vertically in D, so it is equally far from the board and the bar (revised after the first build, which centered it in the slack only; DESIGN_SYSTEM 7.15);
   - else, gutter = the column's left edge less the safe area's left edge. If it is at least the button's own minimum width plus 2 x `space_s`: the touch area is centered horizontally in the left gutter and vertically on the bar's rect;
   - else: not placed, hidden.
   Nothing else in the layout moves. Add its rect to the backdrop's clear rects when it shows.
3. **Hidden** while the offer is open, while Pause (and anything opened over it) is open, while targeting is on, while the new game confirmation or the end of run screen is open. Shown again when they close, if it has a place. Show and hide with `Motion.fade` (`screen_fade`); while hidden or fading out, `mouse_filter` is IGNORE.
4. **Taps:** the button's existing tap rule. Do not add anything that would let a release that began elsewhere count.
5. **The tap's effect** is the existing hand off (`hand_off`), nothing more. The app going to the background is handled by the existing lifecycle code.

## Tests (with the capture opener of TH24, never a real browser)

- Layout, all three skins, layout_in with hand made rects for the four phones of 7.15 (canvas and safe area as tools/coffee_space.gd prints them):
  - 1080 x 2400 (safe y 120 to 2334): hidden.
  - Fold5 cover (1080 x 2767, safe y 125 to 2698): below the board; its touch rect is centered between the board's bottom and the bar's top, at least `space_s` from each, and does not intersect the board, bar or HUD rects.
  - Fold5 inner (1999 x 2400, safe y 116 to 2336): in the left gutter, entirely left of the column, vertically centered on the bar.
  - 16:9 (1350 x 2400, safe y 90 to 2220): hidden.
- Visibility: hidden with the offer open, in targeting, with Pause open, with the end of run screen; shown again after each closes (on a shape where it has a place).
- Drag tail: a press on a board tile, motion onto the button, release on the button: no hand off. A press and release on the button: exactly one hand off. A second touch on the button while a first touch holds a chain: no hand off.
- Layout does not move: the board, HUD and bar rects are the same with and without the button for every case above.

## Done when

- `godot --headless --path . --script res://tests/run_tests.gd` exits 0.
- Screenshots at the Fold5 cover and inner sizes (1080 x 2767 and 1999 x 2400 canvases) in each skin, with the button placed, and one at 1080 x 2400 showing it absent. Put the paths in your report. The senior-graphic-designer reviews them against 7.15.

## Part 2: the row in Pause (Bart approved, 2026-10-21)

Read docs/DESIGN_SYSTEM.md 7.3 ("Buy me a coffee").

### Files you may touch

- src/ui/pause_panel.gd (and its scene in scenes/ui/ if the content is built there).
- tests/ui/.

### What to build

- One CoffeeButton at the end of Pause's content, under Settings, `space_l` below it (a spacer, not the `space_s` between the buttons), centered, only as wide as its content. Same component, tap rule and hand off as the splash.
- Nothing else in Pause moves; Back still resumes.

### Tests

- In all three skins: the coffee button is the last control in Pause, its top is `space_l` below Settings' bottom, it is narrower than the Settings button, and its rect does not intersect Resume's, New game's, Info's or Settings'.
- A tap hands off exactly once (capture opener, TH24); a press on Settings released over the coffee button does not.
- The Pause panel still fits the content column at 1080 x 2400 and at the 16:9 shape of 7.15.

### Done when

- run_tests.gd exits 0, and screenshots of Pause in each skin at 1080 x 2400 are in your report.
