# Brief: ui-systems-dev, the 2026-10-13 additions (arrangement points)

From the senior-graphic-designer. You build the panels; these are the arrangement points they must follow. Three QA findings Bart chose to fix land here too: QA6-04 (the notice while the offer is open, point 12), QA6-05 (touch sizes, point 13) and QA6-08 (the content column, point 14). The look of every piece comes from the skin's Theme and components (the ui-motion-artist's brief) and the tile and board views (the tile-board-artist's brief). As always, no literal color, size or timing in src/ui/.

Work in `C:\bart\sumup-work` (branch `additions`), never in `C:\bart\numbergame`.

## Read first

- CLAUDE.md: the 2026-10-13 decisions.
- docs/GDD.md:
  - section 21 (D-44 How to play), 11.5 (D-45), 13.9 (D-46);
  - AT-112 to AT-116 and AT-140 to AT-142.
- docs/ARCHITECTURE.md:
  - section 11: HowToPlayPanel, AboutPanel, the new signals, flow rules 4, 10, 11 and 12;
  - section 7, for the HUD calls the DM confirms from the ui-motion-artist's brief.
- docs/DESIGN_SYSTEM.md:
  - 2.7 (touch, QA6-05) and 2.8 (the content column, QA6-08);
  - 3.4 (names keep their capitals), 3.6 (the star moment);
  - 7 (the panel definitions), 7.1 (the notice layer, QA6-04);
  - 7.2, 7.3, 7.5, 7.6, 7.7, 7.9, 7.10 (copy);
  - 7.11 to 7.14 (reading screens, How to play, About, license texts).
- The mockups in docs/design/additions/<skin>-<page>.png: menu, pause, settings, howto, howto_end, about and license. They are the reference for each arrangement. They were built in tools/additions/additions_page.gd. You may read it, but never preload tools/ code in src/: tools/ does not ship.

## Write paths

src/ui/, scenes/ui/, tests/ui/, and docs/design/review/prod-screens-*.png.

## Arrangement points

1. **Main menu (7.2).**
   - The wordmark "SumUp" is two labels, "Sum" in ink and "Up" in accent, in DisplayLabel, no gap.
   - Its size: the wordmark's advance width equals the decorative tile row's width (4 x 160 + 3 x `space_s`). That is floor(display size x row width / width at the display size), then 1 px smaller until it fits, never below the display size. Measured: Gumdrop 211, Slate 208, Nova 227.
   - New game (primary), then `space_s`, then How to play (secondary), full width; How to play on the bottom of the safe area.
   - The 2 to 3 split stays.
   - The clear rects cover all three buttons.
   - Report the brand block's center from the first launch page (it must stay between 35 and 42%; the mockups give 36.1 to 36.3%).
2. **Pause (7.3).** Resume, New game, How to play, Settings. How to play opens over Pause; Pause stays open under it.
3. **Settings (7.7).**
   - After the skin choices: a divider, then the About row, then the version line as today.
   - The About row: `row_height` tall and at least `touch_min`, "About" in the body role on the left, the chevron icon (`icon_hud` box, ink_muted) on the right; the whole row is the target.
4. **Offer (7.5).** While a free booster is held, the buy button reads "Shuffle for free" (status `free`).
5. **End of run (7.6).** No stars row. ARCHITECTURE section 16 lists "the end of run stars" for wave C: I recommend against it (7.6 gives the reasons). Build none unless the DM tells you Bart wants one.
6. **Play screen.**
   - Show the clear notice when `stars_earned > 0` or `cleared_small` is not empty (ARCHITECTURE section 4), with `notice_values` and `stars_earned`.
   - Call `set_stars(session.stars(), session.free_held())` on `status_changed`, and also after building or rebuilding the HUD (setup, apply_skin, a resumed run), so the counter never shows a stale value.
   - Use the HUD calls exactly as the DM writes them into ARCHITECTURE section 7.
7. **Reading screens (7.11), shared by How to play, About and the license texts.**
   - Full screen and opaque, over what opened them. In and out with `screen_fade`, never `dialog_in`.
   - Nova: the backdrop's clear rect is the whole screen (no star dust behind text).
   - The header: the title (TitleLabel, left at `board_margin`) and the close icon button, `touch_min` tall, inside the safe area. Slate adds the Hairline under it.
   - The ScrollContainer:
     - from the header down to the screen's bottom edge;
     - horizontal scroll disabled, `vertical_scroll_mode` RESERVE, `scroll_deadzone` 24, `follow_focus` off;
     - content padded `board_margin` on the left, 0 on the right (the indicator fills that margin), `space_s` on top, `space_xl` plus the bottom inset at the end.
   - Every control inside passes drags through to the scroll area.
   - Sections in the SectionPanel variation:
     - Gumdrop cards `space_s` apart;
     - Slate split by the Hairline, no gap;
     - Nova `space_l` apart.
   - Inside a section: HeadingLabel, `space_xs`, ReadingLabel, then where there is one `space_m` and the example or rows. Everything left aligned in every skin.
   - Apply the heading role's case rule to headings (Slate capitals).
   - Every label wraps (`AUTOWRAP_WORD_SMART`) and none sets a minimum width. A long Godot part name widened the whole page in the mockups until it wrapped.
   - Rows that open a screen (RowButton) open only on a tap: finger down and up within the 24 px deadzone and no scroll in between. A drag that starts on a row scrolls.
   - Android back closes the top reading screen first (ARCHITECTURE flow 10).
8. **How to play (7.12).**
   - Seven sections, HP1 to HP7, word for word from GDD 21.2.
   - HP1, HP2 and HP5 end in an example row. On one line, vertically centered, left aligned:
     - the chain as a one row board view: `SkinCatalog.make_board_view(skin)`, `setup(skin, n, 1)`, `set_board`, `set_chain(all cells, Vector2(-1, -1))`, sized for 112 px tiles as 7.12 gives;
     - `space_m`, the skin's `arrow` icon (56 px, ink_muted), `space_m`;
     - the result as a SkinTileView at 112 px.
   - Nothing in the row takes input.
   - Report the content height in screen heights per skin (the mockups give 1.41 to 1.56).
9. **About (7.13).**
   - The brand block on the backdrop, in every skin:
     - the two tone wordmark at the display size, not fitted;
     - "Version {version}" (CaptionLabel), the same version as the Settings line;
     - `space_m`;
     - "Made by Bart Basi" and "Copyright 2026 Play, Inc." (2026-10-17, was "Copyright 2026 Bart Basi"), each in BodyLabel.
   - The attribution is never cased, muted, shrunk or truncated, and must be visible without scrolling.
   - Then the sections "What it is", "Offline, no data" and "Licenses", with the 7.10 copy.
   - The Licenses section ends in three two line RowButtons, split by the Hairline. The detail line is RowDetailLabel: Slate capitals; Nova keeps the names' capitals (3.4).
10. **License texts (7.14).**
    - On the backdrop, no card: paragraphs in ReadingLabel, `space_s` apart; headings in HeadingLabel with `space_m` above.
    - SumUp: "Notice" with NOTICE, then "GNU General Public License" with COPYING.
    - Godot: "Godot Engine license" with `Engine.get_license_text()`, then "Third party parts", then "License texts".
      - Each part: the name in BodyLabel (wrapping), "Copyright {line}" for each line, "License: {name}".
      - The license texts come from `Engine.get_license_info()`.
    - Outfit: OFL.txt.
    - **Reflow:** blank lines split paragraphs; inside a paragraph every line break and run of spaces becomes one space; nothing else changes. GDD AT-142 says "character for character" today. Until the DM settles it (DESIGN_SYSTEM.md 10.4), test the shown text against the source with whitespace normalized, and say so in your report.
    - One label per paragraph, built in batches across frames if one frame is not enough; never one label for the whole text. Report the time to open each view on Windows.
11. **Copy (7.10)** in src/ui/screen_copy.gd: every new string. The How to play text is the GDD's, word for word.
12. **QA6-04, the notice layer (7.1, 7.5).**
    - GameScreen keeps one full screen Control as the notice layer: above the board and the offer panel, below every dialog panel.
    - It gives the layer to the HUD with `set_notice_layer` (as the DM writes it into ARCHITECTURE section 7), and again after every `apply_skin`.
    - Keep calling the HUD's clear notice while the offer is open (today the notice is invisible because the hidden HUD is its parent). The HUD picks the offer placement itself.
13. **QA6-05, touch (2.7).**
    - `touch_min` and `button_height` become 160 through the tokens. Everything you build from them follows: icon buttons, the Settings header, buttons, the sound row.
    - Rows that open a screen (About in Settings, the license rows) are at least `touch_min` tall.
    - Report each panel's height at 1080 x 2400 before and after.
14. **QA6-08, the content column (2.8).**
    - One shared helper in src/ui/ works out the column width C for the current viewport, safe area and skin: the smaller of the safe width and B + 2 x `board_margin`, where B is the board's width on the play screen. B comes from the skin's board view: `preferred_height(width)` is linear in the width, so two samples give the width whose height fills the space between HUD and bar. Work it out from the HUD's height, never the offer's.
    - GameScreen puts the HUD, the booster bar and the offer panel in the column, centered, and centers the board in it.
    - The dialog base lays every panel in the column: Gumdrop's card `board_margin` inside it, Slate's and Nova's sheets as wide as it. Scrim and backdrop still fill the screen.
    - The main menu and the reading screens (header and ScrollContainer) sit in the same column.
    - Nova's backdrop clear rects follow the column's text rects.
    - Re-check after a live resize (fold and unfold), as QA did: the column follows the new size.
    - Add review pages at 1998 x 2400 (the Fold5 inner screen) for pause, settings, offer, end, menu and howto in each skin, captured with `--size 1998x2400`, and report the column width you measured per skin. DESIGN_SYSTEM.md 2.8 expects about 1,220 (Gumdrop, Slate) and 1,270 (Nova).

## Proof

- All tests pass: `godot --headless --path . --script res://tests/run_tests.gd`, with new tests for:
  - TH21 (the How to play content equals GDD 21.2);
  - TH22 (the About text holds "Copyright 2026 Play, Inc." exactly (2026-10-17), and each license text matches its source as above);
  - back order and row taps (a drag on a row does not open it);
  - the menu, Pause and Settings arrangements.
  Name the tests.
- Add review pages to scenes/ui/review/ for each skin: howto, howto_end, about, license_game, license_godot, license_outfit, plus the updated menu, pause, settings and offer (free held). Capture them, for example:

```bash
godot --path . res://tools/capture.tscn -- --scene res://scenes/ui/review/review_gumdrop_howto.tscn --out docs/design/review/prod-screens-gumdrop-howto.png
```

  Report every path and any error lines. Then I review the screens against the mockups.

## Report

Files changed, the commands above with their results, the measurements asked for, and anything in the spec that did not fit the contract.
