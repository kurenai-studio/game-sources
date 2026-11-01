# Brief: unlimited numbers, the visual changes (tile-board-artist, ui-motion-artist, ui-systems-dev)

From: senior-graphic-designer, 2026-10-21. Launched by the DM in Wave 3 of ARCHITECTURE.md 17, after core (BigNum, exponents, NumberFormat) is committed.

This brief covers only what each of you changes visually. Converting your area to exponents and BigNum is in ARCHITECTURE.md 17 and the DM's own brief for your wave; do both in one pass.

## Read first (everyone)

- CLAUDE.md, the 2026-10-21 decision near the end of "Decisions from Bart".
- docs/ARCHITECTURE.md section 17.
- docs/GDD.md 14.1 (D-31, the suffix sequence: K, M, B, T, Q, then lowercase aa to zz without l and o, then three letters) and 14.2 (D-32, the score rule).
- docs/DESIGN_SYSTEM.md section 14 (it lists every changed section and gives the measurements), and 2.5, 2.6, 3.3.

## Rules for everyone

- A tile label, a cost, the merge preview, Best Tile, the highest tile, a clear notice value and the letters of a score are never cased, in any skin: no `cased()`, no `to_upper()`, no `to_lower()` on them, also when they sit inside a cased sentence. Case only the words around them, the way UiCopy.clear_notice already does (2.5).
- Score letters are part of the number: same role, size, color and baseline, no gap.
- No new tokens, no new colors, no new text pairs, no new Theme variations.

## For tile-board-artist

### Files you may touch

- src/skins/skin.gd, src/skins/common/*.gd, src/skins/<id>/*.gd, src/skins/slate/slate.tres.
- tests/skins/.

### What to build

1. **Colors by exponent (3.3).** fill_for, ink_for, color_position and tier_for take the exponent k. p(k) = k - 1 for k from 1 to 17, then tile_cycle[(k - 18) mod n] up to 65535. tier_for: tile_tier[k - 1] up to 17, beyond_tier above. Plain int math; never build 2^k.
2. **Value tokens stay as written (14.3).** `special_from`, Nova's `dark_rim_from` and "tile:<value>" color references keep their values in the .tres files. Compare by exponent: a tile is special when k is at least log2(special_from) (Gumdrop 16, Slate and Nova 15); Nova's dark rim goes on ramp position color_position(17). Resolve "tile:65536" by converting the value to its exponent. Nova's glow scales by k from 1 to 17 and stays at the top above.
3. **Labels (2.5).** tile_font_size does not change: labels of 5 and 6 characters take the 4 character scale and shrink to `label_fit`, as the code already does. Check that nothing else assumes at most 4 characters (array sizes, caches keyed by length). TileLabels gets its text from NumberFormat.tile_label(k).
4. **Slate `display_fit_min` 76** (was 96) in src/skins/slate/slate.tres (5.4). The token mirror tools/directions/slate/tokens.gd already says 76, so tests/skins/test_skin_values.gd fails until you change the resource.
5. **Tests:** fill_for and ink_for at k = 18, 62, 63, 64, 1000 and 65535 give tile_cycle[(k - 18) mod n]; special at k 15 and 16 per skin; the dark rim on k = 17, 33 and 49 and not on 50; a 5 character label ("512aa") and a 6 character label ("128aaa") at the 56.9 dp tile (170.7 px) are no wider than `label_fit` of the side.

### Done when

- `godot --headless --path . --script res://tests/run_tests.gd` exits 0.
- These pass, with the results in your report (run them yourself; they detect the exponent API on their own):
  - `godot --headless --path . --script res://tools/contrast_check.gd` (every exponent to 65535)
  - `godot --headless --path . --script res://tools/ramp_check.gd` (every exponent to 65535)
  - `godot --headless --path . --script res://tools/label_check.gd` (every real label from 2^1 to 2^65535; it passes only once Slate's `display_fit_min` is 76)

## For ui-motion-artist

### Files you may touch

- src/design/motion.gd, src/design/shared/ui_copy.gd, src/design/shared/clear_notice.gd, src/design/shared/hud_base.gd, src/design/gumdrop/gumdrop_hud.gd, src/design/slate/slate_hud.gd, src/design/nova/nova_hud.gd, src/design/shared/booster_button_base.gd.
- tests/design/.

### What to build

1. **Count up (2.6).** `Motion.count_up(label, skin, from, to)` takes BigNums. Let a = NumberFormat.score(from) and b = NumberFormat.score(to), each split into its digits (commas removed) and its suffix (the trailing letters, maybe none).
   - Same suffix: tween an int from a's digits to b's digits on `score_count`; each step shows the int with commas, then the suffix unchanged. At most 10 digits, so it is a plain int.
   - Different suffix: set b at once, no tween.
   - Always end exactly on b. Put the comma formatting for the int in one helper; do not reimplement NumberFormat's suffix logic, only split its output.
2. **HUD score fit (2.6).** `_fit_score_size` keeps its shape: down to `display_fit_min`, then below it only when even that does not fit (now only for 16 character scores). Update its comment: `display_fit_min` is made for 15 characters, not 13.
3. **Gumdrop's Best pill (4.7).** The Best number shrinks from the body size until the pill's left edge is at least `space_s` right of the free pill's end (the star pill's end when no free pill shows), never below the label role size. Measured: a worst 15 character best score fits at 40 px with two digit star and free counts. Up to 13 characters nothing changes. Slate's BEST column and Nova's best line need no change (14.2).
4. **The clear notice plural (7.10).** In UiCopy.clear_notice the "s" after a value is written only when the value's label ends in a digit or a capital: "No more 64Qs", "No more 64aa", "No more 128aa to 512aa". Keep the templates; drop the "s" per value. Values are never cased (Slate "NO MORE 128aa TO 512aa").
5. **Clear notice mini tiles (4.7, added after reviewing your build).** In src/design/shared/clear_notice.gd a mini tile draws its label only when the label is 3 characters or fewer; for 4 characters or more it is a color chip with its strike and no label. Same in all three skins. Test: a notice for 2^67 to 2^69 draws no labels on its mini tiles; one for 2 and 4 draws "2" and "4".
6. **Costs.** booster_button_base takes the cost exponent and shows NumberFormat.tile_label of it. The widest cost, "256mmm", fits every skin's cost line at full size (14.1); no shrink needed.
7. **Tests:** count_up with the same suffix ("9,221,253,119B" to "9,223,504,919B": text keeps the B and ends exact), across a suffix change (jumps), and with none (as today); the notice copy for "64Q", "64aa" and a range "128aa" to "512aa" in all three skins; Gumdrop's Best pill with "9,999,999,999zz" and "1 free" stays clear of the free pill and its number at or above the label size; every HUD with a 15 character score stays at or above `display_fit_min`, and with a 16 character score fits its slot.

### Done when

- run_tests.gd exits 0, and `godot --headless --path . --script res://tools/label_check.gd` passes (after the tile-board-artist's Slate change).
- Review pages or screenshots (any of your own scenes/design/review/ pages) showing each skin's HUD with "9,221,253,119B" and with "9,999,999,999zz", the best score the same, and a booster bar with a "256aa" cost, at 1080 x 2400. Put the PNG paths in your report.

## For ui-systems-dev

### Files you may touch

- src/ui/splash_screen.gd, src/ui/end_panel.gd.
- tests/ui/.

### What to build

1. **Record row mini tiles 96 px** (7.9, was 72): `MINI_TILE` in splash_screen.gd (Best tile) and end_panel.gd (Best tile and this run's highest tile). The rows keep their `row_height` minimum, so nothing else moves. The settings skin preview tiles stay 72 px.
2. **Scores in rows.** Your record rows, the end of run score and the offer's score row already fit their numbers (QA6-10); keep that, fed by NumberFormat.score of the BigNum. Measured, a 15 character Best score fits every row at the body size and the end of run score stays above `display_fit_min` (14.2); a 16 character score shrinks to fit.
3. **Tests:** the mini tiles are 96 px on the splash and the end of run; the splash, the end of run and the offer with a 15 character score ("9,999,999,999zz") and with Bart's "9,221,253,119B" are no wider than the content column, at 1080 px, in all three skins; a "512aa" Best tile and highest tile fit their mini tiles.

### Done when

- run_tests.gd exits 0.
- Screenshots of the splash and the end of run in each skin with a best score of "9,999,999,999zz" and a best tile of 512aa, at 1080 x 2400. Put the paths in your report.

## Review

The senior-graphic-designer reviews every part against DESIGN_SYSTEM.md 2.5, 2.6, 3.3 and 14 once all three of you are in, and runs the three tools.
