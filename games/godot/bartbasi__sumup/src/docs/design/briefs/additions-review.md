# Production review: the 2026-10-13 additions as built

From the senior-graphic-designer, 2026-10-13. Reviewed on the `additions` branch at ff167cf, against docs/DESIGN_SYSTEM.md and the mockups in docs/design/additions/. Every decision below is also recorded in DESIGN_SYSTEM.md (10.5 lists where).

## Verdicts

| Builder | Verdict | Brief |
|---|---|---|
| tile-board-artist | **Pass.** No fixes. | none needed |
| ui-motion-artist | **Pass with 1 fix.** | ui-motion-artist-additions-review.md |
| ui-systems-dev | **Pass with 2 fixes.** Fix 1 waits for one line in GDD AT-142. | ui-systems-dev-additions-review.md |

The additions look like the mockups at production quality in all three skins. The stars read as each skin's own idea (Gumdrop's candy pills, Slate's folio line, Nova's quiet status line), Free on the bar is clear in every look including disabled, the reading screens are calm and legible, and the content column fixes the Fold5 inner screen without touching phones.

## Checks run (branch folder, 2026-10-13)

| Command | Result |
|---|---|
| `godot --headless --path . --script res://tools/contrast_check.gd` | `PASS: 97 pairs checked in 3 skins, 0 failed.` The old "not yet in the skin resources" note is gone. |
| `godot --headless --path . --script res://tools/ramp_check.gd` | `PASS: 186 pairs checked, 0 failed.` |
| `godot --headless --path . --script res://tools/label_check.gd` | `PASS: 24 checks, 0 failed.` |
| `godot --headless --path . --script res://tests/run_tests.gd` | `Ran 950 tests in 60 files: 950 passed, 0 failed.` Exit code 0. |

---

## 1. tile-board-artist

Evidence: `%TEMP%\sumup_qa602\shots\` and `...\howto_new\`.

### 1.1 QA6-02: Gumdrop's rim and shine as one triangle array each

**Pass.**
- `cmp_bart_chain_zoom.png`, `cmp_64k_90.png` and the `before_*` / `after_*` pairs: I cannot tell before from after at 1x or zoomed. The 8 times diffs show only faint rings along the rim's edges, matching the 4 out of 255 you measured. The chained ring still sits outside the rim, and the shine keeps its round caps.
- 843 to 265 draw calls on Bart's late board, and a chained 128K from about 1,040 to 290 microseconds to draw in your A/B runs (`ab_old_1.txt`, `ab_new_1.txt`): exactly the kind of fix 1.5 asks for.
- The face size, the rim's cache key, is the same for every state of a tier 4 tile (chained, joinable and lifted tiles change only the face's position), so two special tiles in different states never rebuild the rim in turn. Good.
- **Your question on 1.5:** yes. 1.5 now allows one triangle array with its own antialias feather where many strokes would each cost a draw call, built once per size, and it says arrays may be built the first time they are needed at a size.

### 1.2 Tokens

**Pass.** test_skin_values passes, so the three resources hold exactly what the token files hold: the heading and reading roles, star_icon, reading_line_spacing, scroll_bar, star_earn and star_convert, touch_min and button_height 160, and Nova's orb_scale 0.89 and board_gap 22. The contrast check reads the new pairs from the resources.

### 1.3 One row boards (`rows_*.png`, `howto_new\*.png`)

**Pass**, in all three skins, from 1 x 2 to 1 x 5:
- *Gumdrop:* every tile pressed into its little tray with the chained ring, the rope showing in the gaps.
- *Slate:* frames inset on the slabs, the ruled line node to node, numbers top left and clear of the line.
- *Nova:* white chained rims, the beam in the gaps taking each orb's color.
Nothing assumes 5 x 8. test_one_row_boards covers 2 to 5 cells in every skin.

### 1.4 Nova at orb_scale 0.89 (`nova_before_*`, `nova_after_*`, `cmp_nova_*`)

**Pass.**
- The dashed targeting orbit, the joinable ring and the beam read as cleanly as at 0.88 (`cmp_nova_orbit.png`, `cmp_nova_board_joinable.png`).
- On Bart's late board (`cmp_nova_bart_chain.png`) the dark chained rims on the white holes still read.
- **The corona crosses (your note, my call):** accepted as built. Between two special orbs, the rays 15 degrees off the row meet in the gap as small crosses (`cmp_nova_rays.png`, `cmp_nova_bart_gap.png`). They read as a glint between two stars, they stay in the gap far from every number, and the alternatives are worse: turning the rays onto the row lines them up end to end into a dash that reads like a chain, and shortening them until they never meet (about 1.16 orb radii) leaves a corona too short to see. Recorded in 6.7.

---

## 2. ui-motion-artist

Pages: `docs/design/review/prod-ui-<skin>-<page>.png`.

| Page | Gumdrop | Slate | Nova |
|---|---|---|---|
| play | Pass | Pass | Pass |
| parts | Pass | Pass | Pass |
| stars | Pass | Pass | Pass |
| flight | **Fix 1** | Pass | **Fix 1** |

**Fix 1 (ui-motion-artist). The flying star is invisible while it crosses its own pill.** Breaks DESIGN_SYSTEM.md 3.6 ("the star earned effect plays from it", a moment the player must see), 4.7 and 6.7 (Star earned effect) and 7.5 (the star moment while the offer is open).
- Gumdrop's star is badge on a badge pill, Nova's spark is accent on an accent pill: the same color. By the 4.7 path (which I specified) the star slides along the pill before it swings up, so Gumdrop's is invisible for about the first 45% of its flight and Nova's for about 70% (in the 50% frame of `prod-ui-nova-flight.png` it cannot be found). While the offer is open the rising star spends most of its rise over the pill, so in both skins it is hardly seen at all.
- My spec's fault, not your build's: the path stays, and the star gets an edge in badge_ink (3.6).

Notes, no change needed:
- **The fits** match the spec: Gumdrop's star pill starts at 164 px and "1 free" ends near 480; Slate's group spans 604 to 920 with "1 FREE"; Nova's line spans 326 to 783.
- **The counter star's progress fill** reads in all three skins. At count 4 the third is a filled base under the outline band, quiet as it should be.
- **The free costs:** correct in every look, disabled included (Gumdrop disabled_ink without a lip, Slate and Nova struck through).
- **Slate's offer notice:** the badge bar covers about 5 px of the top row's labels, within the 7 px 7.5 accepts.
- **The new stars and flight pages:** accepted. The play page had no room, and a page per subject is easier to review.
- **Gumdrop's arrow head** (all three corners rounded by 1 unit, the shaft's round cap ending inside the head): approved as built, written into 4.7.
- **Nova's chevron and arrow fitted to icon_fit:** approved. That is the rule for every Nova icon; only the star fills its box like a glyph. Written into 6.7.

---

## 3. ui-systems-dev

Pages: `docs/design/review/prod-screens-<skin>-<page>.png`, and the `-fold-inner.png` pages at 1998 x 2400.

| Page | Gumdrop | Slate | Nova |
|---|---|---|---|
| first_launch | Pass | Pass | Pass |
| menu | Pass | Pass | Pass |
| play | Pass | Pass | Pass |
| pause | Pass | Pass | Pass |
| settings | Pass | Pass | Pass |
| offer | Pass | Pass | Pass |
| offer_free | Pass | Pass | Pass |
| end | Pass | Pass | Pass |
| howto | Pass | Pass | Pass |
| howto_end | Pass | Pass | Pass |
| about | Pass | Pass | Pass |
| license_game | Pass (Fix 2 applies) | Pass (Fix 2 applies) | Pass (Fix 2 applies) |
| license_godot | **Fix 1, Fix 2** | **Fix 1, Fix 2** | **Fix 1, Fix 2** |
| license_outfit | **Fix 1** | **Fix 1** | **Fix 1** |
| menu, pause, settings, offer, end, howto at 1998 x 2400 | Pass | Pass | Pass |

**Fix 1 (ui-systems-dev). Rule lines in the license texts.** Breaks DESIGN_SYSTEM.md 7.11 (text rules: every line readable, no stray stubs) and 7.14 (reflowed for the phone).
- OFL.txt puts its title between two lines of 59 dashes. Reflowed, the three lines join, and in Outfit the dashes are wider than the column: a full line of dashes, then a stub of dashes running into the title, then the same again (Gumdrop and Nova `license_outfit`). Slate escapes only because Segoe UI's dash is narrower; Roboto on a phone may not.
- Godot's texts have 37 such lines (80 dashes, equals signs or asterisks), so further down `license_godot` the same happens in every skin, and setext titles like "Introduction" over a line of equals signs run into their underline.
- The spec gap is mine: 7.14 now says a rule line ends a paragraph and is drawn as the skin's divider. It changes what AT-142 compares, so it **waits for the DM** to add one line to AT-142 (DESIGN_SYSTEM.md 10.5).

**Fix 2 (ui-systems-dev). Building a license view.** Breaks DESIGN_SYSTEM.md 1.5 (60 fps), 7.11 (the fade) and 7.14 (open quickly, scroll at 60 fps).
- Your question, whether the look is acceptable while Godot's view builds over 2.2 to 2.8 s: **yes**, the page growing below the first screenful and the indicator shrinking as it grows are fine.
- Not as it runs today, for two reasons:
  - The paragraphs start the frame after the header, so the view fades in onto an empty page and the first paragraphs pop in during the fade.
  - Frames of 29 to 57 ms on this desktop mean several times that on a mid range phone, during the fade and the reader's first scroll. Your 6 ms budget covers only making the labels, not the layout and drawing they cause.
- The conditions are in 7.14: the first screenful before the fade, the rest after it, and every frame within 16.7 ms on the desktop, counted over the whole frame.

Notes, no change needed:
- **Slate's hairline between the About brand block and "What it is":** approved as built; the masthead closes on a rule like a magazine page, and my mockup has it too. Written into 7.13.
- **The damaged file copy** ("This text could not be read in this copy of SumUp. Installing the game again should bring it back."): right as written. Plain, says what happened and what to do, no blame. Added to 7.10.
- **The measurements** are inside the spec and recorded:
  - content column 1,220, 1,221 and 1,269 px with no insets (2.8 expected about 1,220 and 1,270);
  - brand center 36.6 to 36.8% (35 to 42% asked);
  - How to play 1.41 to 1.56 screen heights (at most about two);
  - Pause 914, 963 and 992 px, Settings 1188, 1264 and 1308 px at touch size 160 (2.7).
- **The fold pages:** every panel, the HUD, the dock and the reading column sit in the content column. Gumdrop's cards line up with the tray, and Slate's and Nova's sheets end at the column's sides.
- **The How to play rows** match the mockups in every skin: real chained tiles, the arrow in ink_muted, and the result set apart (in Gumdrop it sits on the card, outside the tray).
- **Accepted as faithful to the sources:**
  - "PREAMBLE The goals of..." in the OFL reads as a run in heading, because the source has no blank line after it;
  - the MPL's asterisk box borders stay as text;
  - a URL can leave a short stub (`>.` after the GPL address in Slate and Nova).
