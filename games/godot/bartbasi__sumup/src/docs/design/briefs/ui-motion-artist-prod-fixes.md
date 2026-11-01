# Fixes: ui-motion-artist, Phase 3 production interface layer

From the senior-graphic-designer. Verdict: **approved for Gumdrop, Slate and Nova**, with the four fixes below. The three skins read as three clear interface languages, every capture follows DESIGN_SYSTEM.md closely, and your 14 open points were well reasoned: I accept all of them, two with a small change (points 4 and 13). DESIGN_SYSTEM.md now records every decision; re-read sections 3.4, 3.6, 4.5, 4.7, 5.3, 5.7, 6.3 and 6.7 before you start.

Your write paths are unchanged: src/design/, scenes/design/, tests/design/, and docs/design/review/prod-ui-*.png.

## Fixes

1. **Gumdrop HUD: keep the score clear of the clear notice.**
   - Measured in prod-ui-gumdrop-play.png: the comma tail of "41,286" ends at y 306 and the notice starts at y 307. They touch.
   - Place the score's baseline so that its comma tail (COMMA_DEPTH times the fitted display size) ends `space_xs` above the notice top. The notice top is `hud_height + space_s - notice_height / 2`, the same rule your Nova HUD already uses. At the full display size this lifts the score by about 13 px.
   - The score stays put whether or not a notice shows.
   - Spec: DESIGN_SYSTEM.md 4.7, HUD.
2. **The Suggested badge hides while any booster is active, in every skin.**
   - Today Gumdrop and Nova hide it while a hint shows (your point 4). Slate keeps it, because its hint lives in the HUD. So in targeting from the offer, Slate's badge sits over 8 px of the board's bottom row while the player taps tiles, and it would cover the lower press brackets of a bottom row tile.
   - Put the rule in the shared bar: the badges hide while any shown BoosterStatus has `active` true, and come back when none has.
   - Add a test that covers all three skins.
   - Spec: 4.7, 5.7, 6.7.
3. **One home for the font metrics, checked against the real fonts.**
   - CAP_HEIGHT (0.70) is defined in four files and COMMA_DEPTH (0.18) in one, and fix 1 needs COMMA_DEPTH in Gumdrop too.
   - Define both once in src/design/shared/ and use that everywhere.
   - Add a test in tests/design/ that measures each skin's display, body and label fonts from the glyph outlines (`TextServer.font_get_glyph_contours`, the way tools/label_check.gd measures digits). It checks two things:
     - the cap height of "H" is within 0.02 of CAP_HEIGHT
     - the bottom of "," is no deeper than COMMA_DEPTH
   - What I measured: cap height 0.688 to 0.712; comma 0.125 (Segoe UI) to 0.172 (Outfit 900).
   - Spec: 3.4.
4. **Review scene (captures only).**
   - (a) Leave `space_s` between the two toggles. Gumdrop's tracks touch today, so neither can be judged on its own.
   - (b) Add the icon rows and the icon button row to the backdrop's clear rects. In prod-ui-nova-parts.png, stray star dust sits beside the shuffle, close and sound off icons and reads like icon debris.
   - (c) Add a fourth bar sample to every play page, "targeting from the offer: hammer active, shuffle suggested". It must show no Suggested badge (fix 2).

## Decisions on your 14 points

| # | Point | Decision |
|---|---|---|
| 1 | Nova "best" under the comma tail; score about 11 px below the HUD top | Accepted. Recorded in 6.7. |
| 2 | Gumdrop dock lip inside dock_height; button 140 face on a 10 lip | Accepted. The 4.7 formula was wrong and is corrected. |
| 3 | Suggested badge rests on the button or ring top edge (Gumdrop, Nova) | Accepted. Recorded in 4.7 and 6.7. |
| 4 | Gumdrop and Nova hide Suggested while a hint shows | Accepted, widened: hide while any booster is active, in every skin (fix 2). |
| 5 | Slate's badge straddles the hairline, 8 px over the bottom row | Accepted for the offer, where Slate draws nothing there. Hidden in targeting by fix 2. Recorded in 5.7. |
| 6 | dialog_out reverses dialog_in's extras and fades to 0 | Accepted. Recorded in 3.6. |
| 7 | Notice fade out on screen_fade's curve (Gumdrop, Nova); Slate on clear_notice's | Accepted. Recorded in 3.6, 4.7, 5.7, 6.7. |
| 8 | Slate's notice waits while the context row is busy; hold runs only while shown | Accepted. Recorded in 5.7. |
| 9 | Diagonal strike, bottom left to top right | Accepted for every skin. Recorded in 4.7 and 5.7. |
| 10 | Your picked values | All six accepted: lips `button_lip` thick (4.5); squircles `tile_radius` times the face (4.5); Nova disabled dash share `orbit_dash_fill` (6.7); Nova active icon ink_dark with an accent glow (6.7); Gumdrop toggle track keeps its lip when on (4.7); Slate disabled is a hairline outline in line (5.7). |
| 11 | Slate pause at the top of its touch area; held fill behind the HUD text | Accepted. Recorded in 5.7. |
| 12 | Nova disabled button on a sheet (disabled_ink on surface) | Added as a text pair, 5.29:1 (6.3). Rule for both flat skins: disabled controls keep no fill. They may sit on Slate bg, or on Nova bg, bg_glow or surface. Never on Slate surface (4.40) or Nova surface_raised (4.38). Your components need no change. |
| 13 | Font metric constants 0.70 and 0.18 | Accepted as constants, defined once and tested (fix 3). |
| 14 | Theme variations IconButton, BadgePanel, BadgeLabel, SignalLabel, HintLabel; UiKit.make_icon_button | Accepted. They match the looks in 4.7, 5.7, 6.7 and 7.8. No change. |

## Proof

- All design tests pass, including the new ones for fixes 2 and 3: `godot --headless --path . --script res://tests/run_tests.gd`. Name the new tests in your report.
- `godot --headless --path . --script res://tools/contrast_check.gd` passes.
- Recapture all six review PNGs, with no error lines:

```bash
godot --path . res://tools/capture.tscn -- --scene res://scenes/design/ui_gumdrop_play.tscn --out docs/design/review/prod-ui-gumdrop-play.png
```

  and the same for `gumdrop_parts`, `slate_play`, `slate_parts`, `nova_play` and `nova_parts`.
- In the new gumdrop play capture, report the gap in px between the lowest score pixel and the top of the notice. It must be at least `space_xs` (12).
