# Fixes: ui-systems-dev, Phase 3 production screens

From the senior-graphic-designer. Verdict: **approved for all three skins, with two fixes.**

The screens follow DESIGN_SYSTEM.md section 7 closely: pause, settings, the offer in both forms, the end of run, the confirmation and the play frame all read well in all three skins. Your 8 choices were sound and I accept all of them as built. DESIGN_SYSTEM.md section 7 now records every decision; re-read 7 (Alignment), 7.2, 7.5, 7.7 and 7.9 first.

Write paths: yours as in your task brief (src/ui/, scenes/ui/, tests/ui/, and docs/design/review/prod-screens-*.png).

## Fixes

1. **Main menu layout (7.2). The DM is right that it is bottom heavy.** Today one small block (title role wordmark, 112 px tiles, records) sits between two equal spacers. It lands just below the middle under an empty top half. Change it to:
   - **Brand block:** the wordmark in the **display role**, auto fitted to the width inside `board_margin` with `skin.score_font_size(text, width)` (it never drops below `display_fit_min`). `space_m` below it, the tile row at **160 px** tiles (7.9; was 112), `space_s` apart. Centered; Slate left aligns both.
   - **Records:** move them out of the brand block, so they sit `space_l` above the New game button. Records and button make one group in the thumb zone.
   - **Spacers:** between the settings button's row and the records, split the free height **2 to 3** above and below the brand block (stretch ratios 2 and 3). The brand then sits near the upper golden section.
   - Keep the backdrop's clear rects covering the brand block, the records and both buttons, so Nova's star dust stays off them.
2. **Slate: left align every button's text.**
   - Today Slate's primary buttons are left aligned, but the secondary buttons (New game and Settings in pause, End run in the offer, Main menu at the end of run, Cancel in the confirmation) center their text.
   - Every Slate button left aligns its text, primary and secondary (7, Alignment; 5.7). The ui-motion-artist's review sheet already shows them that way.
   - Chips keep centered text.

## Decisions on your 8 choices

| # | Choice | Decision |
|---|---|---|
| 1 | Record row mini tiles 72 px | Accepted. Now in the 7.9 table. |
| 2 | Best tile row hidden on the main menu until a tile exists | Accepted. Written into 7.2. |
| 3 | One offer arrangement: title with the score beside it, then the text, then the buttons | Accepted. Written into 7.5. |
| 4 | Slate and Nova offer with no box | Accepted. Their dialog panel is a bottom sheet, which does not suit a panel at the top. Written into 7.5. |
| 5 | Slate left aligns the menu's tile row and records too | Accepted. Written into 7.2. |
| 6 | Panel titles centered except in Slate | Accepted, with the rule you already follow made explicit: a title that shares its row with something on the right (Settings' close button, the offer's score) is left aligned. Section 7, Alignment. |
| 7 | Version line "SumUp" (numbersgame before the 2026-10-13 rename) plus `application/config/version` when set; Slate in capitals | Accepted. Written into 7.7. |
| 8 | The settings button's face width from `hud_button_face` (Gumdrop), `hud_ring` (Nova), else `icon_hud` | Accepted as built for v1. A shared `icon_button_face` token would repeat values that already exist and touch three areas for no visible change. If a fourth skin is ever added, fold the two into one shared token then. |

## Proof

- All tests pass: `godot --headless --path . --script res://tests/run_tests.gd`.
- Recapture the three menu pages and the Slate pause, offer, offer_none, end and confirm pages into docs/design/review/prod-screens-*.png, with no error lines.
- Also capture the real app on first launch (Gumdrop, empty records) like the DM's p4_main_launch.png, and report its path. In it the brand block's center must sit between 35% and 42% of the screen height. Report the number.
