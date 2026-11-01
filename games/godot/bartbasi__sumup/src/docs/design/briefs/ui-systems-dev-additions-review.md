# Fixes: ui-systems-dev, the additions review

From the senior-graphic-designer. Verdict: **pass, with two fixes**, both in the license views. Main menu, Pause, Settings, the offer with a free booster, the end of run, How to play, About and the Fold5 inner screen pages all match DESIGN_SYSTEM.md and the mockups in every skin. Your measurements are inside the spec and now recorded in it. The whole review, page by page, is docs/design/briefs/additions-review.md.

Work in `C:\bart\sumup-work` (branch `additions`), never in `C:\bart\numbergame`.

Write paths, unchanged: src/ui/, scenes/ui/, tests/ui/, and docs/design/review/prod-screens-*.png.

## Read first

DESIGN_SYSTEM.md 7.14 (the new bullets "Rule lines" and "Building the view"), 7.10 (your copy for a missing text, now in the table), 7.13 (Slate's hairline after the brand block) and 10.5.

## Your points

- **Slate's hairline between the brand block and "What it is":** approved as built. The masthead closes on a rule, like Slate's sections, and the mockup has it too. Now in 7.13.
- **The copy for a damaged license file:** approved as written. Now in 7.10.
- **The Godot license view while it builds:** the look is accepted, the page growing below what the reader sees, with the conditions of fix 2.

## Fix 1: rule lines become dividers (only after the DM confirms the AT-142 change)

Spec: DESIGN_SYSTEM.md 7.14, "Rule lines". It changes what AT-142 compares, so the DM first adds one line to GDD AT-142 (DESIGN_SYSTEM.md 10.5 has the wording). If the DM does not confirm it, skip this fix.

1. A **rule line** is a line holding three or more of one character, `-`, `=` or `*`, and nothing else but spaces.
2. In the reflow, a rule line ends the paragraph before it and starts a new one after it.
3. It is drawn as the skin's divider (the Hairline variation) across the text's width, never as text. It stands in the column like a paragraph, `space_s` from its neighbors.
4. Examples:
   - OFL.txt: the title "SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007" stands alone between two dividers.
   - Godot's FreeType text: "Introduction" over a line of equals signs becomes "Introduction" over a divider.
   - Lines with other characters too stay text: the MPL's box borders such as `*  6. Disclaimer of Warranty  *`.
5. Today 59 or 80 dashes wrap into a full line of dashes and a stub. In Gumdrop and Nova the stub runs into the OFL title, and in every skin it happens again further down Godot's view.

Tests:
- the reflow cases above;
- AT-142 compared as the GDD's new line says (rule lines skipped on both sides, the paragraph counts still equal).

## Fix 2: building a license view

Spec: DESIGN_SYSTEM.md 7.14, "Building the view"; 1.5 (60 fps); 7.11 (the fade).

1. **The first screenful before the fade.** Build the paragraphs that fill the scroll area's height before the view starts to fade in.
   - Today the fade starts on an empty page and the first paragraphs pop in during it.
   - A frame or two of delay before the fade is fine.
2. **The rest after the fade.** Build nothing more until the fade in has ended, so the fade runs at full frame rate.
3. **Smooth frames.** While the rest builds, every frame stays within 16.7 ms in the desktop window, counted over the whole frame.
   - Today your 6 ms budget covers making the labels but not the layout and drawing they cause, so frames reach 29 to 57 ms.
   - A longer total build is fine.
   - If you cannot reach 16.7 ms, report what takes the time in those frames.
4. These rules hold for all three license views, not only Godot's.

Proof:
- A test that a license view starts its fade only once its first screenful is built, and builds nothing more during the fade.
- For each of the three views, in the desktop window as before:
  - the time to the first screenful;
  - the total build time;
  - the longest frame while building.

## Proof for both

- All tests pass: `godot --headless --path . --script res://tests/run_tests.gd`. Name the new and changed tests.
- Recapture, for each skin:
  - `prod-screens-<skin>-license_outfit.png` and `prod-screens-<skin>-license_godot.png`;
  - a new page `prod-screens-<skin>-license_godot_rules.png`, Godot's view scrolled to the FreeType text ("The FreeType Project LICENSE", "Introduction"), so the dividers can be judged.

  Report every path and any error lines.
