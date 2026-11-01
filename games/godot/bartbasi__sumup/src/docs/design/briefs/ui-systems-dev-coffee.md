# Brief: the copyright line and Buy me a coffee (ui-systems-dev, and one part for ui-motion-artist)

From: senior-graphic-designer, 2026-10-17. Launched by the DM.

## Read first

- CLAUDE.md, the two 2026-10-17 decisions near the end of "Decisions from Bart".
- docs/GDD.md section 15.5 (Buy me a coffee, BC1 to BC6), AT-141, AT-142, AT-155 to AT-158, TH22 and TH24.
- docs/DESIGN_SYSTEM.md: 7.2 (the splash, the 1 to 1 split and "The Buy me a coffee button"), 7.9, 7.10, 7.11 (rows and the tap rule), 7.13 (About, the attribution and the support section), and the icon bullets in 4.7, 5.7 and 6.7. Section 13 lists every place that changed.
- docs/ARCHITECTURE.md section 7 (UiKit, SkinIcon).

## Urgent: NOTICE already changed

The DM has already changed NOTICE to "Copyright 2026 Play, Inc.". src/ui/license_texts.gd still checks NOTICE for "Copyright 2026 Bart Basi" (`_CHECKS`), so today the SumUp license view shows the "could not be read" message. Fix this first (step 1).

## Files you may touch

- src/ui/screen_copy.gd, src/ui/license_texts.gd, src/ui/about_panel.gd, src/ui/splash_screen.gd, src/ui/ui_parts.gd, src/ui/app.gd (only if the hand off lives there), and one new script in src/ui/ for the button if you want one (preloaded, no `class_name`, so the contract does not change).
- tests/ui/ (the existing tests that name the old attribution, and the new tests below).
- scenes/ui/review/ for review pages, if you add any.

Nothing in src/design/: the coffee icon is ui-motion-artist's (the last section). Until it lands, `set_icon(&"coffee")` reports an unknown name and draws nothing; build and test everything else, and check the icon once both are in.

## What to build

### 1. The copyright line

- src/ui/screen_copy.gd: `COPYRIGHT` becomes "Copyright 2026 Play, Inc." exactly, with the comma and the period, never cased. `MADE_BY` stays "Made by Bart Basi".
- src/ui/license_texts.gd: the NOTICE check in `_CHECKS` looks for "Copyright 2026 Play, Inc.".
- src/ui/about_panel.gd: the header comment names "Copyright 2026 Play, Inc." and lists the four sections (step 4).
- tests/ui/test_reading_screens.gd (lines near 375, 384 and 431) and tests/ui/test_additions_flow.gd (near 242): every "Copyright 2026 Bart Basi" becomes "Copyright 2026 Play, Inc.". Keep the "Made by Bart Basi" checks.
- It fits one line in every skin at 1080 px: measured 525 px (Gumdrop), 493 (Slate, Segoe UI), 486 (Nova). Add it to the existing one line width check, like the source code line.

### 2. The address and the hand off

- One constant, written once: `const COFFEE_URL: String` in src/ui/screen_copy.gd, next to the source code line. The DM gives you the exact address (https://buymeacoffee.com/<handle>). Do not guess a handle: if you start before you have it, ask the DM and do not finish without it.
- One function hands it to the system, and both buttons call it: it calls `OS.shell_open(COFFEE_URL)` and treats any result other than OK as "could not open". On failure nothing happens: no message, no dialog, no log the player sees, and the screen stays as it was (GDD BC6). Never add anything to the address.
- Tests must never open a browser. Make the hand off replaceable for tests (TH24): for example a Callable on the App, or a static Callable in the button script, set to the real `OS.shell_open` call by default. A test swaps in a capture that records each address, counts the calls, and can report failure.
- Every tap hands off exactly once. No debounce, no "already opened" state (AT-157 counts one hand off per tap).
- The address is never shown on screen and never in a label. The GitHub source line in About stays plain text, `MOUSE_FILTER_IGNORE`, not a link, unchanged (BC5).
- Nothing else changes: no save, no run change, no pause logic of its own. Leaving for the browser is an ordinary app switch (GDD 15.5); the existing rules handle it.
- Please check on the phone what Godot does on Android when no app can open the address. If it throws or logs an error the player could see, say so in your report rather than hiding it with extra code.

### 3. The button (DESIGN_SYSTEM.md 7.2, "The Buy me a coffee button")

One control, built the same way on the splash and in About:
- The Theme's RowButton look: nothing drawn at rest; pressed, the RowButton pressed fill behind the content, reaching `space_s` past it on both sides, over the whole touch height. Build it like open_row.gd does (a PanelContainer that sets the RowButton normal or pressed box as its panel), or reuse that code, so it gets the same tap rule: down and up on it, moving less than the 24 px deadzone, with no scroll in between, and a drag that starts on it reaches the ScrollContainer.
- `touch_min` tall (`custom_minimum_size.y`), as wide as its content plus `space_s` each side. It shrinks to its content (never `SIZE_EXPAND_FILL`).
- Content, one line, vertically centered: a SkinIcon from `UiKit.make_icon(skin)` with `set_icon(&"coffee")` and `set_color(skin.color(&"ink_muted"))`, sized to a square of `skin.font_size(&"body")`; a gap of `roundi(0.25 * skin.font_size(&"body"))`; then a Label "Buy me a coffee" in MutedLabel (body role, ink_muted). Children ignore the mouse.
- Casing: the body role is as written in every skin, so it reads "Buy me a coffee" in all three. Go through `skin.cased(&"body", ...)` like the other buttons, which leaves it as written.
- Never disabled, no chevron, no scale on press, no motion of its own. Focus: the RowButton focus look.
- A node name tests can find: "Coffee".

### 4. The splash (7.2)

- Under the Info and About row: `space_xs`, then the button. Its touch area sits on the bottom of the safe area (it replaces the Info and About row there).
- Gumdrop and Nova: centered in the column. Slate: its content starts on the content's left edge (board_margin), under the text of Info.
- The split changes from 2 to 3 to **1 to 1**: `SPLIT_ABOVE_BRAND` and `SPLIT_BELOW_BRAND` both 1.0.
- `_content_height` adds the coffee row: `space_xs` + `touch_min`. The 112 px fallback then works as before.
- `_update_clear_rects` adds the button's rect, so Nova's star dust stays clear of it.
- It shows and takes input from the first frame; the entrance does not move or fade it.
- Report the brand block's center as a share of the screen height at 1080 x 2400 with a 120 / 66 px safe area, in each skin, with and without a best tile. Expected: 36.1 to 36.5% with a best tile, 39.0 to 39.5% without (7.2). It must stay inside 35 to 42%.

### 5. About (7.10, 7.13)

- The "Offline, no data" text gains a last sentence, so it reads exactly: "SumUp works fully offline. It collects no data, has no ads or accounts and asks for no permissions. The Buy me a coffee button only opens a web page in your phone's browser, and the game itself sends nothing."
- A new section after "Offline, no data" and before "Licenses": heading "Supporting SumUp"; text, Bart's wording, exactly: "SumUp is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated." (ReadingLabel, never cased); `space_xs`; the button, left aligned with the icon's left edge on the text's left edge. In Copy.ABOUT_SECTIONS this is one more entry; the panel adds the button under that section's text only.
- The heading follows the heading role like the others (Slate capitals: "SUPPORTING SUMUP").
- `info_text()` lists the new heading, the text and "Buy me a coffee" in page order.
- The brand block, the attribution and the source line do not move. The attribution stays in the first screenful (the existing AT-141 test must still pass unchanged apart from the text).
- The button appears nowhere else: not on the play screen, in Pause, the offer, the end of run screen, Settings itself or Info.

## Tests to add (tests/ui/)

Name them in your report. For example, a new tests/ui/test_coffee.gd:

1. `test_splash_has_the_coffee_button_in_every_skin`: for each skin, the splash holds one "Coffee" control after the Info and About row, reading "Buy me a coffee" exactly (not cased), at least `touch_min` tall and wide, with a SkinIcon set to coffee in ink_muted and a MutedLabel.
2. `test_about_has_the_coffee_button_in_every_skin`: the same for About, opened from the splash and from Settings; the button is inside the "Supporting SumUp" section, after its text.
3. `test_about_support_text_is_exact` (TH22, AT-156): About's text holds Bart's sentence group exactly as written above, character for character, in every skin, and the section sits after "Offline, no data" and before "Licenses".
4. `test_offline_sentence_is_exact`: the "Offline, no data" text equals the three sentence text above.
5. `test_coffee_tap_hands_off_the_constant_once` (TH24, AT-157): with the hand off captured, a tap on the splash button and a tap on the About button each make exactly one hand off; four taps each make four; every address equals `COFFEE_URL`, which starts with "https://buymeacoffee.com/" and holds a handle after it.
6. `test_coffee_tap_failure_changes_nothing` (BC6): with the capture reporting failure, a tap leaves the screen and the open overlays as they were and adds no node (no message).
7. `test_coffee_drag_does_not_hand_off`: in About, a press, a move past the 24 px deadzone, and a release on the button make no hand off.
8. `test_source_line_is_still_not_a_link` (BC5): the GitHub line is still plain text with `MOUSE_FILTER_IGNORE`; a tap on it makes no hand off.
9. `test_attribution_reads_play_inc` (AT-141): the attribution label's text equals "Copyright 2026 Play, Inc." exactly in every skin, is not cased, and fits one line at 1080 px.
10. `test_coffee_button_only_on_splash_and_about`: no "Coffee" node in the play screen, Pause, the offer, the end of run panel, Settings or Info.
11. The splash layout check: with the 1 to 1 split the brand center stays inside 35 to 42% at 1080 x 2400 in every skin (with and without a best tile), and on the 16:9 safe area the content still fits with the sum row at 144 px.

## Proof

- `godot --headless --path . --import`, then `godot --headless --path . --script res://tests/run_tests.gd` exits 0.
- The new and changed test names.
- The brand center numbers of step 4.
- Screenshots of the splash and of About scrolled to the support section in each skin, at 1080 x 2400 (capture as before with tools/capture.tscn), saved to docs/design/review/ with their paths in your report. I review them against 7.2 and 7.13.
- What Android does with no browser, if you could check it.

## For ui-motion-artist (src/design/): the coffee icon

The DM briefs this separately; it is listed here so both halves line up.

- Add `&"coffee"` to `SkinIcon.ICON_NAMES` (src/design/skin_icon.gd). docs/ARCHITECTURE.md section 7 lists the icon names; the DM adds coffee there (contract change, asked for in my report).
- Draw it in each skin's icon script on the 24 unit grid, exactly as DESIGN_SYSTEM.md gives it:
  - Gumdrop (4.7): a filled mug body, a handle arc and two steam strokes, `icon_stroke`, round caps.
  - Slate (5.7): rim, body and handle as mitered strokes, two steam strokes, square caps, no fill.
  - Nova (6.7): an open U cup on an arc, a handle arc, one steam stroke and a spark dot, fitted to `icon_fit`.
- Every look (normal, active, disabled) follows the skin's icon colors; the button itself always sets ink_muted with `set_color`.
- Build any arrays once per size (1.5). It is drawn small, at the body font size (44 to 46 px), so check it at that size as well as large.
- Add it to the icon review pages (docs/design/additions/<skin>-icons.png style, or a new page), at 216 px and at the body font size next to the label "Buy me a coffee", and report the paths.
- Tests in tests/design/: every skin draws coffee without an unknown name report, like the other icons.
