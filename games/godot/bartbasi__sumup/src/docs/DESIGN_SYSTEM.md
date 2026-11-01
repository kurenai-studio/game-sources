# SumUp Design System

Owner: senior-graphic-designer. Status: Phase 3. The production review decisions are recorded in place. The 2026-10-13 additions (How to play, About, stars and free boosters, the SumUp wordmark) are specified in place too; section 10 lists where. They are built, and the production review of the builds (docs/design/briefs/additions-review.md) is recorded in place as well (10.5). The 2026-10-14 splash screen, the Info guide that replaces How to play, and the source code line on About are specified in place too; section 11 lists where. The 2026-10-17 copyright line ("Copyright 2026 Play, Inc.") and the Buy me a coffee button are specified in place too; section 13 lists where. The 2026-10-21 unlimited numbers (longer tile labels and scores, colors by exponent up to 2^65535) are specified in place too; section 14 lists where and gives the measurements. The 2026-10-21 Buy me a coffee button on the play screen is in 7.15, and in Pause in 7.3.

This document specifies every visual value of the three built in skins: **Gumdrop** (the default), **Slate** and **Nova**. By Bart's decision the tile-board-artist writes the SkinData resources (src/skins/<id>/<id>.tres) from it, the ui-motion-artist builds the Themes, icons and motion helpers from it, and the senior-graphic-designer reviews both. Nobody invents a value: if one is missing, ask.

How the code reads skins (class names, methods, signals, file layout) is in docs/ARCHITECTURE.md. This document gives the token names, the values, and how each component looks and moves.

**Checked source.** Three scripts prove the values that ship. They load the SkinData resources (src/skins/<id>/<id>.tres) through SkinCatalog, label tiles with NumberFormat.tile_label, and the label check measures each skin in its own font (Outfit for Gumdrop and Nova, the system font for Slate):

```bash
godot --headless --path . --script res://tools/contrast_check.gd   # every number on its tile, every text pair: 4.5:1 or better
godot --headless --path . --script res://tools/ramp_check.gd       # neighboring tile colors look different (section 1.3)
godot --headless --path . --script res://tools/label_check.gd      # labels and scores fit, digits as large as 14.1 asks
```

The Phase 1 token files `tools/directions/<skin>/tokens.gd` still mirror this document for the prototypes, and the skin tests in tests/skins/ prove that every SkinData resource holds exactly those values.

The 2026-10-13 additions were checked with mockups built from the real Theme, HUD, board views and tile views, rendered to docs/design/additions/<skin>-<page>.png. The SkinData resources now hold every value they add (the skin tests prove it), so tools/additions/additions_spec.gd only serves the mockups:

```bash
godot --path . res://tools/additions/additions_capture.tscn    # 30 PNGs and the measurements quoted below; needs a window
```

If this document and a token file or a SkinData resource disagree, this document wins and the other is a bug.

## Contents

1. Principles
2. Canvas, units and layout
3. The skin token schema
4. Gumdrop (default)
5. Slate
6. Nova
7. Shared screen arrangements
8. Hard Stop 1 review fixes
9. Launcher icon
10. The 2026-10-13 additions
11. The 2026-10-14 splash screen and Info
12. The 2026-10-15 color cycle
13. The 2026-10-17 copyright line and Buy me a coffee
14. The 2026-10-21 unlimited numbers

---

## 1. Principles

### 1.1 Everything is made in code

Every visual is drawn in code: StyleBoxFlat, Theme resources, `_draw()`, gradients and meshes built in code, canvas_item shaders that work on the Compatibility renderer, and Tweens. The only files that are not code are the Outfit font and its license in src/design/fonts/ (docs/ASSETS.md), and the launcher icon PNGs, which a tool script draws (section 9).

### 1.2 The number is always shown

Every tile shows its label. Color is never the only signal. The label sits on the flat tile fill and nothing passes through the label's bounding box (a chain line, a ring, a glow, a shine, a highlight): the contrast check proves fill against number, so that pair must be what the eye sees. Where a line must pass under a number (Slate), a plate of the tile fill covers the whole label first.

### 1.3 Neighbors never look alike

Small tile clearing (GDD D-38) keeps about ten consecutive values on the board. The four values of the spawn window are the most common tiles, and a chain is built from equal and double values. So every ramp is **categorical**: each step jumps far round the hue wheel (about 144 degrees, a pentad step), tiles take the lightness at which their hue is most vivid, and tiers separate the hues that repeat. The ramp check holds the OKLab distance between tile fills to:

| Pair | Minimum OKLab distance |
|---|---|
| A value and its double | 0.17 |
| Two steps apart (times 4) | 0.12 |
| Three steps apart (times 8) | 0.09 |
| Any tile against the skin background | 0.15 |

For scale: 0.02 is about the smallest visible step, and the Hard Stop 1 complaints were all pairs at 0.07 to 0.12.

These minimums hold for every value from 2 to 2^62, through the color cycle above 131072 (3.3). Further apart than three steps two values may share a hue family, but never a fill: no two of any 13 consecutive values have the same fill.

### 1.4 Contrast

Every tile number on its fill, and every text color on its background, is at least 4.5:1 (WCAG 2 relative luminance). Text may only be drawn with a pair listed for its skin in section 4, 5 or 6. A new combination needs a new pair here and in the token file first.

### 1.5 Performance

Target 60 fps on a mid range Android phone with a full board.
- Redraw only when something changes.
- Build StyleBoxes, gradients and arrays once and reuse them: at setup, or the first time they are needed at a size, and never again until that size changes. No other allocation inside `_draw()` or `_process()`.
- No per tile shaders. Glows use one radial gradient texture made once and drawn tinted.
- No MSAA. Antialias with StyleBoxFlat `anti_aliasing = true` (corner_detail 12 or more for squircles) and `antialiased = true` on `draw_line`, `draw_polyline`, `draw_arc` and `draw_circle`.
- Count draw calls on a full late board. Where one shape is made of many strokes and each would cost its own call (Gumdrop's candy rim of 16 segments, its shine with two round caps), draw them as one triangle array with a color per point and an antialias feather of its own: a band fading to clear, matched to Godot's own (about 1.25 px, a quarter of it inside the edge and three quarters outside). Built once per size like any array. It must look the same as the antialiased strokes it replaces: QA6-02 measured at most 4 out of 255 difference on any pixel, with draw calls on Bart's late board down from 843 to 265.

### 1.6 Motion and input

A move's animation follows a fixed order, and input reopens (GDD D-35) when every tile is at rest on its cell. Decorative tails (Nova's glow bloom, the clear notice, the star earned effect) may keep running and never block input. See each skin's motion table for the timings.

---

## 2. Canvas, units and layout

### 2.1 Canvas and units

- The base canvas is **1080 by 2400 logical px**, portrait, stretch mode `canvas_items` with aspect `expand`. On a phone wider than 9:20 the logical canvas grows sideways (for example 1200 by 2400 on 18:9, 1350 by 2400 on 16:9) and everything scales by the phone's height over 2400.
- Every length in this document is in logical px on that canvas unless it says "fraction of the tile side" or dp.
- On a 360 dp wide 20:9 phone, 3 logical px are 1 dp.

### 2.2 Safe areas

- Read the safe area from the display (notch, punch hole, rounded corners, gesture or button bar). No text and no touch target sits outside it.
- Backgrounds, the board tray, the scrim and sheet panels extend under the insets to the screen edges.
- The HUD's top edge sits on the safe area's top. The booster bar's bottom edge sits on the safe area's bottom. A bottom sheet runs to the screen edge and pads its content by the bottom inset.

### 2.3 The play screen stack

From top to bottom: HUD (`hud_height`), `space_s`, board, `space_s`, booster bar (`bar_height`, which includes the hint row). The board takes the largest size that fits:
- Width: at most the canvas width less `board_margin` on each side.
- Height: the board's preferred height for that width, which must fit between the HUD and the bar. If it does not, the board shrinks evenly and stays centered.
- The board never stretches. Tiles stay square (orbs round).

Board preferred height for a tile side `t`:

| Skin | Board height | Board width |
|---|---|---|
| Gumdrop | 8t + 7 x `board_gap` + 2 x `board_padding` | 5t + 4 x `board_gap` + 2 x `board_padding` |
| Slate | 8t + 7 x `board_gap` | 5t + 4 x `board_gap` |
| Nova | 8 x pitch, orb diameter t = `orb_scale` x pitch | 5 x pitch |

### 2.4 Tile size targets (GDD A-1)

Full spec on 18:9 phones (360 by 720 dp) and taller: tiles at least 56 dp, 4 character digits at least 12 dp. 16:9 phones get smaller tiles with the same proportions. Worked out from the token heights in this document at 3x density, with a 24 dp status bar and a 24 dp gesture bar (20:9: a 40 dp status bar with a camera cutout and a 22 dp gesture bar):

| Phone | Gumdrop | Slate | Nova |
|---|---|---|---|
| 20:9, 360 x 800 dp | 60.5 dp | 63.5 dp | 58.9 dp |
| 18:9, 360 x 720 dp | 56.9 dp | 59.6 dp | 57.7 dp |
| Fold5 cover, 344 x 882 dp (QA6-05) | 57.9 dp | 60.7 dp | 56.3 dp |
| 16:9, 360 x 640 dp, gesture bar | 49.9 dp | 52.3 dp | 50.8 dp |
| 16:9, 360 x 640 dp, 48 dp button bar | 46.9 dp | 49.3 dp | 48.0 dp |

To get there, Gumdrop's HUD and dock were slimmed (section 8) and Nova's display size and ring buttons trimmed.

**Nova on the Fold5 cover screen (QA6-05, 2026-10-13).** That screen is 344 dp wide, narrower than the 360 dp A-1 assumes, so Nova's board is limited by width there and its orbs measured 55.7 dp. `orb_scale` went from 0.88 to 0.89 (`board_gap` from 24 to 22, the gap that leaves at the base width): the orbs are 1.1% larger on every phone and 56.3 dp on the cover screen. The pitch, the board's size and every layout stay the same; only the orbs grow into their gaps. The dashed targeting orbit (radius times 1.10) still stays inside the cell, and on the built board the orbits, the joinable ring and the beam read as cleanly as at 0.88 (2026-10-13 review). The Nova column above was worked out again at 0.89; Gumdrop and Slate on the cover screen are QA's measurements.

### 2.5 Tile labels (GDD D-31)

- Label rule (GDD 14.1, rewritten 2026-10-21): the full number up to 1024. From 2048 up, a number from 1 to 512 followed by a suffix in steps of 1024: K, M, B, T, Q (2K, 64K, 1M, 64Q), then two lowercase letters (1aa, 128aa, 512zz), then three (1aaa, 32kiv). At most 4 characters up to 512Q (2^59), 5 from 128aa (2^67), 6 from 128aaa (2^5827).
- Size: `tile_number_scale[min(length, 4) - 1]` times the tile side (Nova: the orb diameter), so a 5 or 6 character label starts from the 4 character size. The label never grows wider than `label_fit` times the side: a label that would, shrinks until it fits (SkinData.tile_font_size, unchanged). That shrink is what sizes every label with suffix letters; there is no new token. The sizes it gives, and why they are accepted, are in 14.1.
- Labels are data, not prose: never apply a case rule to them, in any skin, on a tile or in text ("2K" never becomes "2k", "64aa" never becomes "64AA", not even in Slate's capitals). The same holds for a cost, the merge preview, Best Tile, the highest tile, clear notice values and the letters of a score.
- Costs, the merge preview, Best Tile and the clear notice values use the tile label format (D-32). The score follows 2.6.

### 2.6 The score fits

The score (GDD 14.2, rewritten 2026-10-21) shows in full with commas up to 10 digits (9,999,999,999, 13 characters). Past that, whole groups of three digits are dropped and a suffix from the tile sequence says how many: 12,345,678K, 9,221,253,119B, 10,000,000aa. So a score has at most 14 characters with one capital, **15 with two lowercase letters** (9,999,999,999zz, the longest normal play reaches) and 16 with three (only from a score of 1,754 digits or more).

- It is set in the display role. When it is too wide for its slot, its size shrinks until it fits, never below `display_fit_min`. `display_fit_min` is now sized for 15 characters: every score of up to 15 characters fits every slot at that size or larger (measured in 14.2). Slate's goes from 96 to 76 for this (5.4).
- A 16 character score keeps shrinking below `display_fit_min` until it fits, exactly as the longer scores of a hand edited save did before (the QA6-10 rule, kept). No panel that shows a score (end of run, out of moves offer, splash) is ever wider than the content column.
- Up to 13 characters nothing changes.
- The Best score number (HUD, splash, end of run, offer) shrinks the same way to fit its place (14.2 lists each). It is in the body role, so it has no `display_fit_min`; Gumdrop's HUD Best pill has a floor of the label role size (4.7).
- The suffix letters are part of the number: same role, size, color and baseline as the digits, no gap, never cased.
- **Counting up (`score_count`).** The HUD sizes the score for its final text first, and the count keeps that size throughout, so the number never jumps in size while it runs. What counts:
  - When the score before and after the chain show the same suffix (or none), the shown digits count from the old shown digits to the new ones on `score_count`, each step formatted with commas and the suffix appended unchanged ("9,221,253,119B" rolls to "9,223,504,919B"). The shown digits are at most 10, so the count is a plain int and never touches the BigNum.
  - When the suffix changes (9,999,999,999 to 10,000,000K, or B to T), the new text shows at once, with no count. That happens about once in every thousandfold rise of the score, and a roll from "9,999,999,999" to "10,000,000K" would read as the score falling.
  - The count lands exactly on NumberFormat.score of the final BigNum, as today.

### 2.7 Touch

Every touch target is at least `touch_min` (160 px) on each side, even where the drawn shape is smaller. Tiles are larger than that on every supported phone.

**Why 160 (QA6-05, 2026-10-13).** The canvas scales by the phone's width or height, whichever is tighter, so a logical px is a different number of dp on each shape. 144 px gave 48 dp only on 20:9 phones at least 360 dp wide. Bart wants 48 dp or more on his Fold5 cover screen and on 18:9 phones:

| Phone | dp per px | 144 px (before) | 160 px (now) |
|---|---|---|---|
| 20:9, 360 x 800 dp | 0.333 | 48.0 dp | 53.3 dp |
| Fold5 cover, 904 x 2316 at 2.625 (344 dp wide) | 0.319 | 45.9 dp | 51.0 dp |
| 18:9, 360 x 720 dp | 0.300 | 43.2 dp | 48.0 dp |
| Fold5 inner, 1812 x 2176 at 2.625 | 0.345 | 49.8 dp | 55.3 dp |
| 16:9, 360 x 640 dp | 0.267 | 38.4 dp | 42.7 dp |

- 16:9 phones get 42.7 dp. Like their smaller tiles (GDD A-1), that is accepted; 48 dp there would take 180 px, which crowds every HUD for a shape few phones still have.
- A fixed px value is kept on purpose rather than a value worked out from each phone's density: every layout then stays the one this document measures.
- What grows with it: `touch_min` and `button_height` both go from 144 to 160 in every skin (4.5, 5.5, 6.5). Rows that open a screen are at least `touch_min` tall (7.11).
- Gumdrop's booster buttons take touch on the dock's whole face height, 174 px (52.2 dp at 18:9, 55.5 on the cover screen), and up to the middle of the gaps beside them, while they draw as before (4.7). Slate's columns (192 px) and Nova's ring slots (190 px) were already large enough.
- Nothing drawn changes size: HUD faces, rings, icons and toggles keep their sizes, and only their touch areas grow. `hud_height` and `bar_height` do not change, so the board and the 2.4 tile sizes do not change.
- Panels grow by 16 px per button row, and the offer panel by 16 px, under which the board may shrink a little while the offer is open (7.5). Measured on the built screens at 1080 x 2400: Pause 914 px (Gumdrop), 963 (Slate), 992 (Nova); Settings 1188, 1264 and 1308.
- On the old main menu the brand block's center stayed at 36.1 to 36.3% of the screen height in the mockups with 160 px buttons, and 36.6 to 36.8% on the built first launch screen, inside 35 to 42%. The splash that replaces it keeps the same range (7.2).

### 2.8 The content column on wide screens (QA6-08, 2026-10-13)

On a near square screen (the Fold5 inner screen, 1998 logical px wide) or a tablet, the board is limited by height and sits narrow in the middle, while panels and buttons stretched edge to edge (buttons about 1,850 px wide, record rows with their label and value at opposite screen edges). Everything now lives in one centered **content column**:
- *Width:* C = the smaller of the safe area's width and B + 2 x `board_margin`, where B is the width the board takes on the play screen for this screen and safe area (2.3). On phones the board is limited by width, so C is the whole width and nothing changes. On a wide screen C is the board plus its margins: on the Fold5 inner screen about 1,220 px for Gumdrop and Slate and 1,270 px for Nova (worked out from QA's measured tile sizes there).
- *Worked out once per screen size and skin,* from the HUD's height (never the offer panel's), so it does not jump when the offer opens or closes. Screens without a board (the splash, Info, About) use the same C, so every screen shares one width. B can be found from the skin's board view: `preferred_height(width)` is linear in the width, so two samples give the width whose height fills the space between HUD and bar.
- *Inside the column:* the HUD, the booster bar, the offer panel, every dialog panel (Pause, Settings, the confirmation, the end of run), the splash, and the reading screens with their header and scroll area. A Gumdrop card sits `board_margin` inside the column, so it lines up with the tray exactly. Slate's and Nova's sheets span the column (their open edge, hairline or rounded corners, ends at the column's sides) and still reach the screen's bottom edge.
- *Outside it:* the backdrop, the scrim and the cross-fade still fill the screen. Nova's star dust stays outside the column's text rects as before.
- This also lines the dock up with the tray on 18:9 phones, where the board is already a little narrower than the screen.

| Screen | Before | After |
|---|---|---|
| 20:9, 1080 px canvas | full width | the same (C = 1080) |
| 18:9, 1200 px canvas, Gumdrop | 1200 (card 1128, tray 1048) | C = 1120, card = tray = 1048 |
| Fold5 inner, 1998 px canvas | 1998 | about 1,220 (Gumdrop, Slate), 1,270 (Nova); built: 1,220, 1,221 and 1,269 with no insets |

---

## 3. The skin token schema

Every skin defines every shared name below. Anything else a skin needs is an **extra**, listed under "Extras" in its section. Production code reads tokens through the SkinData API that ARCHITECTURE.md defines (fill for a value, ink for a value, tier for a value, color, number, motion spec, font, font size, cased text, tile font size, score font size).

### 3.1 Identity

| Name | Meaning |
|---|---|
| id | gumdrop, slate or nova |
| display_name | shown in the skin picker: Gumdrop, Slate, Nova |
| font_family | outfit or system |

### 3.2 Palette roles

| Role | Meaning |
|---|---|
| bg | screen background |
| surface | cards, sheets, pills, dock |
| surface_raised | raised controls: secondary buttons, chips, booster buttons |
| line | hairlines, dividers, ring outlines |
| ink | main text on dark |
| ink_muted | labels and secondary text on dark |
| ink_dark | text on bright fills |
| accent | primary button, active booster, selected chip |
| accent_pressed | accent while pressed |
| disabled_ink | text and icons of a disabled control |
| chain | chain line and the mark on chained tiles |
| target | press feedback and the Swap selection in targeting |
| joinable | the joinable highlight (D-40) |
| scrim | overlay behind dialogs, with alpha |
| badge | fill of badges: hint, Suggested, New best, the clear notice |
| badge_ink | text on badge |

### 3.3 Tile ramp

| Name | Meaning |
|---|---|
| tile_fill[17], tile_ink[17] | fill and number color for 2, 4, 8 ... 131072 (ramp positions 0 to 16) |
| tile_cycle | the ramp positions, in order, that the values above 131072 walk round (the color cycle below) |
| tile_tier[17], beyond_tier | an integer per value; beyond_tier for every value above 131072; what a tier changes is per skin |

**The color cycle (2026-10-15, keyed by exponent since 2026-10-21).** A tile of value 2^k, whose exponent k is what the game now holds (ARCHITECTURE.md 17), takes the fill and the number color of ramp position p(k):

- p(k) = k - 1 for k from 1 to 17 (2 to 131072: the ramp as listed),
- p(k) = tile_cycle[(k - 18) mod n] for k from 18 to `max_exponent` (65535), where n is the length of the skin's tile_cycle.

The rule only ever needed k, never the value, so it holds unchanged past 2^62: the cycle keeps going round (Gumdrop about 4,368 times up to 2^65535). tools/ramp_check.gd and tools/contrast_check.gd check every exponent up to `max_exponent` once the skins take exponents (14.3).

So above 131072 the colors start again from the bottom of the ramp and repeat every n doublings. Fill and number always move together as a pair, so every number on every tile is a pair the contrast check already proves, and the cycle adds no new color.

| Skin | tile_cycle | n | Left out, and why |
|---|---|---|---|
| Gumdrop | 0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 | 15 | 2 lemon: 128K gold would sit three steps from it (0.087). 3 sky: it would sit four steps from 32K electric blue (0.042) |
| Slate | 0 to 16, the whole ramp | 17 | nothing |
| Nova | 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 | 16 | 1 yellow star: 64K supernova would sit three steps from it (0.081) |

The first values above the ramp, and where each cycle comes round again:

| Value | Gumdrop | Slate | Nova |
|---|---|---|---|
| 256K (2^18) | 0 mint | 0 forest slab | 0 red dwarf |
| 512K (2^19) | 1 lavender | 1 navy slab | 2 blue giant |
| 1M (2^20) | 4 coral | 2 oxblood slab | 3 aqua nebula |
| 2M (2^21) | 5 aqua | 3 teal slab | 4 magenta nebula |
| 4M (2^22) | 6 hot pink | 4 aubergine slab | 5 orange giant |
| 8M (2^23) | 7 lime | 5 bronze slab | 6 violet |
| 16M (2^24) | 8 periwinkle | 6 amber | 7 aurora green |
| last of the first round | 4B (2^32) 16 gold | 16B (2^34) 16 paper | 8B (2^33) 16 white hole |
| first of the next round | 8B (2^33) 0 mint | 32B (2^35) 0 forest slab | 16B (2^34) 0 red dwarf |

Why: small tile clearing (GDD D-38) keeps the values from the window floor H / 512 up to H on the board, 10 values, and the result of a long chain can stand up to a few steps above H until its clear has played. Before this rule one beyond color covered every value above 131072, so in a long run (H above 2^26) every tile on the board had the same fill (Bart, 2026-10-15). With a cycle of 15 to 17 no two of any 13 consecutive values share a fill, and every pair across the wrap meets the ramp check of 1.3 (tools/ramp_check.gd checks every value from 2 to 2^62).

**Color follows the cycle, size follows the value.**

- Everything that takes a tile's colors uses its ramp position p(k): fill, number, Gumdrop's lip, shine and burst dots, Slate's label plate, Nova's rim, rays, sparks, glow tint and beam glow, merge previews, the mini tiles of the clear notice, the Best tile and highest tile rows, the Info rows, and "tile:<value>" color references in text pairs. They all read fill_for and ink_for, so they follow the cycle with no rule of their own.
- Everything that says how big a tile is goes by the value, that is by k: the tier (tile_tier[k - 1] for k up to 17, beyond_tier above), the special treatment (k at least log2 of `special_from`), the label, and Nova's glow size and strength (6.7; by k from 1 to 17, held at the top above). So 256K has the colors of 2 but still looks like a big tile: Gumdrop's deep lip, shine and candy rim, Slate's inner frame, Nova's corona.
- Two rules used to pick a color by value and now go by ramp position: Slate's marks on light blocks and its special frame (5.7), and Nova's dark rim on the white hole (6.7).

**Retired:** beyond_fill and beyond_ink are no longer used. They are removed from SkinData, the three skin files and the token mirror. beyond_tier stays.

### 3.4 Type

| Name | Meaning |
|---|---|
| type roles | display (score), title, body (buttons, rows), label (small labels, costs), tile (numbers), heading (section headings on reading screens, 7.11), reading (paragraphs and long text, 7.11). Each has size (px; not for tile), weight (100 to 900), tracking (px between glyphs) and case (none, upper, lower) |
| tile_number_scale[4] | tile label size as a fraction of the tile side, for 1, 2, 3 and 4 characters; 5 and 6 characters start from the 4 character size (2.5) |
| label_fit | widest label, fraction of the tile side |
| display_fit_min | smallest size a score of up to 15 characters may shrink to (a 16 character score goes below it, see 2.6) |

**Names keep their capitals.** A case rule never touches the wordmark "SumUp", a person's or company's name, or a product or license name: "Made by Bart Basi" and "Copyright 2026 Play, Inc." sit in the body role (as written in every skin), and where a name sits in a lowercase label role (Nova's About rows) it is shown as written. Capitals (Slate) keep every letter and may apply.

Outfit is a variable font: weights are set on its `wght` axis by integer tag (the string key "wght" is ignored in Godot 4.7). The system font is a SystemFont asking for Roboto, then Segoe UI, then sans-serif. Phones then use Roboto and Windows uses Segoe UI; plain sans-serif alone gives Arial on Windows.

**Font metrics for placing text.** Components that place text by its letters rather than its line box use two font metrics, held once as named constants in src/design/ and checked against the real fonts by a test. They are not tokens.

| Metric | Value | Measured (Phase 3) |
|---|---|---|
| Cap height, share of the font size | 0.70 | 0.688 to 0.712 over every skin's display, body and label fonts |
| Comma depth below the baseline, share of the font size | 0.18, an upper bound | Outfit 0.126 (weight 300) to 0.172 (weight 900); Segoe UI 0.125 |

### 3.5 Shape, layout and sizes

| Name | Meaning |
|---|---|
| board_margin | screen side to board, at most |
| board_gap | between tiles |
| board_padding | board edge to the outer tiles (Gumdrop's tray padding) |
| tile_radius | corner radius, fraction of the tile side (0.5 is a circle) |
| preview_scale | merge preview tile, fraction of the board tile |
| special_from | lowest value with the special treatment |
| chain_width | width of the chain line |
| chain_ring | thickness of the mark on chained tiles |
| joinable_ring | thickness of the joinable highlight |
| target_ring | thickness of the press feedback |
| space_xs, space_s, space_m, space_l, space_xl | spacing scale |
| touch_min | smallest touch target side |
| radius_button, radius_card, radius_chip | corner radii, px |
| hairline | divider thickness |
| hud_height, bar_height, hint_height | play screen heights (bar_height includes the hint row) |
| button_height, row_height | buttons and settings rows |
| icon_booster, icon_hud, icon_stroke | icon sizes; stroke on the 24 unit icon grid |
| toggle_w, toggle_h, toggle_knob | sound toggle |
| notice_height | the clear notice pill (Slate: the HUD context row it takes over) |
| notice_tile_scale | mini tiles in the clear notice, share of notice_height |
| notice_strike | the strike line across those mini tiles |
| star_icon | the star of the HUD star counter, px box on the 24 unit grid |
| reading_line_spacing | px added between the lines of the reading role (the Label `line_spacing` constant) |
| scroll_bar | drawn width of the reading screens' scroll indicator |

### 3.6 Motion names

Each has a duration (seconds; for loops the period), a transition and an ease (Godot Tween values), plus extras named in the skin's table.

| Name | Used for |
|---|---|
| spawn | new tiles appearing |
| fall | tiles falling after a clear |
| chain_add, chain_remove | a tile joining or leaving the chain (backtrack) |
| joinable_in | the joinable highlight appearing and moving |
| merge_travel | chain tiles moving into the last tile |
| merge_pop | the result tile arriving |
| clear | small tiles clearing (D-38) |
| clear_notice | the notice that says which values cleared (AT-104); extras: hold, out |
| press | press feedback under the finger in targeting |
| button_press, button_release | every button |
| dialog_in, dialog_out | sheets and panels |
| screen_fade | moving between screens |
| target_pulse | loop on the active booster and Swap's selected tile; 0 means still |
| score_count | the score counting up |
| skin_switch | switching skins live in Settings |
| star_earn | a star earned: from the clear notice into the HUD star counter (Slate: the counter's flash) |
| star_convert | every third star: the counter's star turning into a free booster |

**The star moment (GDD D-45, D-46).** A move that earns stars shows the clear notice with "+n" and a star (4.7, 5.7, 6.7), and the star earned effect plays from it:
- It starts when the notice starts.
- The counter shows the new count when the effect lands. Each skin's timing lands it before input reopens (GDD D-45): Gumdrop 0.50 s after the notice starts, Nova 0.54 s, Slate at once.
- Several stars in one move: one flying star each, `stagger` apart; the count goes up by one at each landing (Slate: one flash with the final count).
- When a landing makes the count a multiple of 3, `star_convert` plays at once. A star of the same move that comes after it starts its own flight once the conversion ends.
- The effect is decorative: it never holds input, never blocks the board and plays no sound. It draws on the notice layer (7.1). While the offer has the HUD's place, the star rises and fades instead of flying, and the counter shows the end state when the HUD comes back (7.5).
- **The flying star has an edge (2026-10-13 review).** In Gumdrop and Nova the star is the reward color and so is the notice pill it starts on (badge in Gumdrop, accent in Nova), so without an edge it is invisible while it crosses the pill: about the first 45% of Gumdrop's flight and 70% of Nova's, and most of the rise while the offer is open. So the flying star, and the rising one, draw on top of an edge in badge_ink: the star's outline grown outward by the edge width, filled, under the star. It scales and fades with the star. On the pill it outlines the star crisply; on the dark backdrop it melts in, like Gumdrop's target_edge outlines and Nova's dark rim on the white hole. Gumdrop: `target_edge_width` (4 px at full size). Nova: `hairline` (2 px), between the star and its glow. Build the grown outline once per size, like the counter's band. Slate has no flight.
- A new star effect or notice finishes a running one at once: it jumps to its end state, then the new one starts.

**Exits.** `dialog_out` plays `dialog_in`'s extras backwards (back down `from_offset`, back to `from_scale`) and always ends at alpha 0, so an exit never ends visible.

**Clear notice exit.** The notice fades out over `clear_notice.out` on the skin's `screen_fade` curve, because Gumdrop's back curve would overshoot alpha. Slate uses `clear_notice`'s own curve both ways (5.7).

**Move sequence.** A committed chain plays:
1. Chain tiles `merge_travel` into the last tile.
2. `merge_pop` and `clear` together.
3. `fall` and `spawn` start together. New tiles start at the same moment as the falls, staggered by `spawn.stagger` per tile in fill order, and draw under the falling tiles, so a new tile seems to appear from behind the tile that drops away from its cell. Do not wait for the falls to land: over hundreds of moves that wait is felt.

The clear notice appears with the clear and holds on its own. Input reopens when every tile is at rest. From lift to input, a chain with no small tile clear takes about 0.75 s in Gumdrop, 0.45 s in Slate and 0.65 s in Nova.

**The chain line's tail** (the part from the last chain tile toward the finger, Gumdrop and Nova) ends at the finger, clamped to the board's rect (Gumdrop: the tray's outer edge). When the finger leaves the board the chain stays (AT-19), and the tail stops at the board's edge on the way to the finger.

**Booster effects.** No booster has motion of its own; each reuses the names above:
- *Hammer:* the smashed tile plays `clear`, then `fall` and `spawn` as after a chain.
- *Double:* the tile plays the skin's `merge_pop` look with its new value, then any small tile `clear`, `fall` and `spawn`.
- *Swap:* both tiles slide to each other's cell on `fall`'s duration and curve.
- *Shuffle and Undo:* each tile slides on `fall`'s duration and curve from the nearest old tile of the same value. A value with no old tile left spawns in (`spawn`). An old tile that nothing takes shrinks away on `clear`, without Gumdrop's burst.

**Effect lengths and input.** A board effect reports how long it holds input: until every tile is at rest on its cell. Decorative tails run on without holding input:
- Gumdrop's candy burst after a clear
- Nova's glow bloom after a merge, a Double or a spawn

So Nova's merge holds input for `merge_travel` only and its Double for none. Gumdrop's and Slate's merge pop moves or recolors the tile, so it holds input; it runs together with the clear.

**Targeting looks the same for every booster.** The press feedback and Swap's selection are the only targeting marks on the board. Ending targeting clears both.

---

## 4. Gumdrop (default)

Tactile candy. Chunky squircle tiles with a darker lip underneath, like keycaps or gummy sweets, on a deep plum night. Chains press tiles into the tray and string them on a white rope that shows in the gaps. Everything sits in soft rounded containers and moves with a springy bounce. Font: **Outfit**.

### 4.1 Palette

| Role | Hex | Use |
|---|---|---|
| bg | #150820 | deep plum |
| surface | #2B183D | pills, dock, cards, sheets |
| surface_raised | #3F2956 | booster buttons, secondary buttons, chips |
| line | #3F2956 | rounded divider, `hairline` thick |
| ink | #FFF7FC | |
| ink_muted | #D3BDE5 | |
| ink_dark | #1C0D2B | every tile number |
| accent | #FF63B2 | hot pink |
| accent_pressed | #EB4B9F | |
| disabled_ink | #A39AAE | |
| chain | #FFF7FC | rope and chained ring |
| target | #FFF7FC | press ring, drawn with a target_edge outline |
| joinable | #FFDC4F | lemon ring, drawn with a target_edge outline |
| scrim | #150820 at 78% (#150820C7) | |
| badge | #FFDC4F | lemon |
| badge_ink | #1C0D2B | |
| **Extras** | | |
| tray | #20112F | board tray |
| slot | #2A1A3A | empty cell while tiles fall |
| surface_lip | #090213 | lip under raised surfaces, the dock and cards |
| accent_lip | #A9246E | lip under accent buttons |
| badge_lip | #BF9007 | lip under badges |
| disabled_surface | #1D1625 | flat face of a disabled booster |
| target_edge | #1C0D2B | dark outer edge of the target and joinable rings |
| shine | #FFFFFF | shine on tier 3 tiles, at shine_alpha |

### 4.2 Tile ramp

Every number is #1C0D2B. Tier 1 is sorbet, tier 2 is candy, tier 3 is neon with a shine, and tier 4 is special with the candy rim. Chroma rises by tier, so the big tiles are the most vivid on the board.

Above 128K the colors come round again by the color cycle (3.3), from mint, while the tier stays 4: a 256K tile is mint with the deep lip, the shine and the candy rim.

| Value | Label | Name | Fill | Contrast | Tier |
|---|---|---|---|---|---|
| 2 | 2 | mint | #8FFFD0 | 15.22 | 1 |
| 4 | 4 | lavender | #B681EF | 6.46 | 1 |
| 8 | 8 | lemon | #FFE47D | 14.58 | 1 |
| 16 | 16 | sky | #5DAFF1 | 7.77 | 1 |
| 32 | 32 | coral | #F37069 | 6.42 | 1 |
| 64 | 64 | aqua | #32F3FC | 13.45 | 2 |
| 128 | 128 | hot pink | #F721B6 | 5.12 | 2 |
| 256 | 256 | lime | #AAFA2E | 14.38 | 2 |
| 512 | 512 | periwinkle | #6A88FA | 5.71 | 2 |
| 1024 | 1024 | tangerine | #FB8822 | 7.57 | 2 |
| 2048 | 2K | azure | #3BBEFE | 8.74 | 3 |
| 4096 | 4K | cherry | #FE4F6D | 5.74 | 3 |
| 8192 | 8K | spring green | #5EFF8F | 14.17 | 3 |
| 16384 | 16K | grape | #D056FF | 5.66 | 3 |
| 32768 | 32K | electric blue | #2FA9FF | 7.22 | 3 |
| 65536 | 64K | pearl | #FDF1FC | 16.78 | 4 |
| 131072 | 128K | gold | #F7C243 | 11.17 | 4 |
| above | 256K and up | the color cycle (3.3): 0, 1, 4 to 16, then again | as the position | as the position | 4 |

Closest pairs (ramp check, every value from 2 to 2^62 with the color cycle): neighbors 0.194, times 4 0.141, times 8 0.092. Up to 128K alone they were 0.206, 0.141 and 0.210. The closest now come from the cycle: 128K gold next to 256K mint (0.194), and mint three steps from aqua once lemon and sky are left out (0.092).

### 4.3 Text pairs

| Pair | Text on background | Ratio |
|---|---|---|
| Score and HUD numbers | ink on bg | 18.36 |
| HUD labels | ink_muted on bg | 11.20 |
| Pill, dock and card text | ink on surface | 15.35 |
| Pill, dock and card labels | ink_muted on surface | 9.36 |
| Booster cost, secondary buttons, chips | ink on surface_raised | 12.00 |
| Labels on raised surfaces | ink_muted on surface_raised | 7.32 |
| Booster cost, targeting | ink_dark on accent | 6.73 |
| Booster cost, disabled | disabled_ink on disabled_surface | 6.53 |
| Badges (hint, Suggested, New best, clear notice) | badge_ink on badge | 13.66 |
| Primary button, selected chip | ink_dark on accent | 6.73 |
| Primary button, pressed | ink_dark on accent_pressed | 5.29 |
| Text straight on the scrim (worst case over a pearl tile) | ink on scrim | 9.88 |
| **2026-10-13 additions** | | |
| Free cost and its star on a booster face, normal and pressed | badge on surface_raised | 9.38 |
| Star counter star on the star pill | badge on surface | 11.99 |
| Wordmark "Up" on the backdrop | accent on bg | 7.06 |
| **2026-10-14 splash** | | |
| Wordmark faces (7.2): ink on bg and accent on bg, the pairs above. Its lips sit under the faces and carry no text | | |

The additions also use these existing pairs: the star pill count (ink on surface), the free pill, the notice's "+n" and star (badge_ink on badge), headings and reading text on section cards (ink and ink_muted on surface), license text and the About brand block on the backdrop (ink and ink_muted on bg), pressed rows (ink and ink_muted on surface_raised), the arrow and chevron (ink_muted on surface or bg).

The 2026-10-17 Buy me a coffee button (7.2, 7.13) needs no new pair. Its label and cup icon are ink_muted, on:

| Where | Pair | Ratio |
|---|---|---|
| Splash, at rest | ink_muted on bg | 11.20 |
| Splash, pressed | ink_muted on surface_raised | 7.32 |
| About, on the section card, at rest | ink_muted on surface | 9.36 |
| About, on the section card, pressed | ink_muted on surface_raised | 7.32 |

### 4.4 Type (Outfit)

| Role | Size | Weight | Tracking | Case |
|---|---|---|---|---|
| display (score) | 120 | 900 | -1 | as written |
| title | 76 | 900 | 0 | as written |
| body | 46 | 700 | 0 | as written |
| label | 34 | 700 | +1 | as written |
| tile | 48%, 44%, 36%, 31% of the tile side for 1 to 4 characters | 900 | 0 | |
| heading | 54 | 900 | 0 | as written |
| reading | 42 | 500 | 0 | as written |

`label_fit` 0.88. `display_fit_min` 76. Outfit is tighter than the Segoe UI of the Phase 1 renders, so the display tracking went from -2 to -1 and the title and tile tracking from -1 to 0.

### 4.5 Shape and sizes

| Name | Value | | Name | Value |
|---|---|---|---|---|
| board_margin | 36 | | radius_button | 44 |
| board_gap | 16 | | radius_card | 60 |
| board_padding | 18 | | radius_chip | 40 |
| tile_radius | 0.30 | | hairline | 4 |
| preview_scale | 0.46 | | hud_height | 255 |
| special_from | 65536 | | bar_height | 272 |
| chain_width | 30 | | hint_height | 88 |
| chain_ring | 7 | | button_height | 160 (was 144, 2.7) |
| joinable_ring | 6 | | row_height | 144 |
| target_ring | 9 | | icon_booster | 84 |
| space_xs, s, m, l, xl | 12, 24, 36, 56, 88 | | icon_hud | 64 |
| touch_min | 160 (was 144, 2.7) | | icon_stroke | 3.5 |
| notice_height | 88 | | toggle_w, toggle_h, toggle_knob | 140, 76, 54 |
| notice_tile_scale | 0.6 | | notice_strike | 4 |
| star_icon | 56 | | reading_line_spacing | 10 |
| scroll_bar | 8 | | | |

**Extras:**
- Tray: `tray_radius` 60.
- Lip: `lip_darken` 0.34 (lip color = fill darkened by this). Depth by tier, as a fraction of the tile side: `lip_t1` 0.060, `lip_t2` 0.075, `lip_t3` 0.090, `lip_t4` 0.090. `lip_pressed` 0.020.
- Lift: `joinable_lift` 0.030, `target_lift` 0.040.
- Shine: `shine_alpha` 0.35, `shine_from_tier` 3, `shine_inset` 0.05, `shine_width` 0.045 (fractions of the tile side).
- Rings and rim: `preview_ring` 6, `target_edge_width` 4, `special_rim_width` 8, `special_rim_segments` 16.
- HUD and dock: `hud_top_row` 96, `hud_button_face` 96, `pill_height` 96, `pill_radius` 48, `dock_height` 184, `dock_radius` 64.
- Buttons: `button_lip` 10, `button_lip_pressed` 3, `active_raise` 6, `focus_width` 5, `focus_gap` 6.
- Toggle: `toggle_knob_lip` 5.
- Every other lip (badges and the clear notice, cards and sheets, the Best pill, the dock, the toggle track) is `button_lip` thick and part of the element's height.
- The pause button and every icon button are squircles: corner radius `tile_radius` times the face side, like a tile.

### 4.6 Motion: springy

| Name | Duration | Transition, ease | Extras |
|---|---|---|---|
| spawn | 0.24 | back, out | from_scale 0.2, stagger 0.03 |
| fall | 0.26 | back, out | squash 0.12 on landing |
| chain_add | 0.10 | quad, out | press_scale 0.94 |
| chain_remove | 0.10 | quad, out | |
| joinable_in | 0.12 | sine, out | |
| merge_travel | 0.18 | back, in | |
| merge_pop | 0.28 | elastic, out | peak_scale 1.22 |
| clear | 0.28 | back, in | burst_dots 6, burst_dot_size 0.07 (of the tile side), burst_reach 0.6 (of the tile side), burst_fade 0.36 s |
| clear_notice | 0.30 | back, out | from_scale 0.6, hold 1.6, out 0.20 |
| press | 0.08 | quad, out | |
| button_press | 0.08 | quad, out | press_scale 0.92 |
| button_release | 0.30 | back, out | |
| dialog_in | 0.42 | back, out | from_offset 240 (rises from below) |
| dialog_out | 0.20 | quad, in | |
| screen_fade | 0.22 | sine, in out | |
| target_pulse | 0.90 | sine, in out | wobble_degrees 4 |
| score_count | 0.50 | cubic, out | |
| skin_switch | 0.30 | sine, in out | |
| star_earn | 0.40 | sine, in out | delay 0.10, from_scale 0.4, stagger 0.10 |
| star_convert | 0.18 | back, in | from_scale 0.2, empty 0.12 |

A committed chain settles in about 0.75 s: travel 0.18, pop and clear 0.28, then fall and spawn together, about 0.3 with the stagger. Phase 3 trimmed the pop from 0.34 and the spawn from 0.30 so the default skin keeps a brisk rhythm over hundreds of moves.

### 4.7 Components

**Tile**
- Squircle, corner radius `tile_radius` of the side.
- The lip is the full tile shape in fill darkened by `lip_darken`. The top face, in the fill, is raised by the tier's lip depth, so the lip shows only along the bottom. The label is centered on the face.
- Tier 3 and 4 tiles get a shine: a quarter circle arc in shine at `shine_alpha`, round caps, following the face's top left corner. Its center is the corner's radius center, its radius is the corner radius less `shine_inset` of the side, and its width is `shine_width` of the side. It stays above the label box at every label length.

**Tile states**
- *Normal:* as above.
- *Chained:* pressed in. The lip shrinks to `lip_pressed`, the face moves down with it, the tile is scaled to `press_scale` 0.94, and a `chain_ring` ring in chain sits just outside the face. It stays this way while the tile is in the chain.
- *Joinable (D-40):* the tile lifts by `joinable_lift` (lip deeper, face higher) and gets a `joinable_ring` lemon ring with a `target_edge_width` target_edge outline outside it. The outline keeps the ring apart from a light neighboring tile; on the tray it nearly vanishes, and there the lemon ring reads on its own. It eases in over `joinable_in` and moves as the chain changes. Never on a chained tile.
- *Press feedback (D-43):* while a finger is down on a tile in targeting mode, the tile presses in (lip_pressed) and gets a `target_ring` ring in target with a target_edge outline. It means only "this is the tile under your finger".
- *Selected (Swap's first tile):* lifted by `target_lift` with the same double ring, wobbling by `wobble_degrees` on the `target_pulse` loop.
- *Special (64K up):* a candy rim round the face, `special_rim_width` wide, in `special_rim_segments` segments cycling the tier 1 and 2 fills (ramp positions 0 to 9, the same on every special tile).

**Board**
- A rounded tray in tray (`tray_radius`), `board_padding` inside, `board_gap` between tiles.
- An empty cell (while tiles fall) shows a flat squircle in slot.

**Chain line**
- A rope in chain, `chain_width` wide, round caps and joins, drawn **under** the tiles from center to center, so it shows in the gaps like beads on a string.
- It also runs from the last tile toward the finger, clamped to the tray (3.6).

**Merge preview**
- A mini tile of the result (`preview_scale` of the tile side, with its lip) and a `preview_ring` ring in chain.
- It sits centered on the gap crossing at the top left corner of the last chain tile, or the top right corner when that tile is in column 0. It covers only the rounded corners of the four tiles round the crossing, never a label.
- In row 0 that crossing is on the board's top edge, so the preview reaches above the tray. That is fine: it stays above the finger, the board does not clip it, and it stays well clear of the score.

**Merge, spawn and fall**
- Merge: chain tiles get sucked along the chain into the last tile (`merge_travel`, back ease in). The result pops to `peak_scale` and settles elastically (`merge_pop`).
- Spawn: tiles pop in from `from_scale` with a back ease, `stagger` per tile in fill order.
- Fall: back ease out, with a `squash` on landing (scale y 1 - squash, x 1 + squash / 2, then back). A tile stops on its cell and never sinks into the tile below: the back curve's overshoot is spent as the landing squash.

**Small tile clear (D-38)**
- Every cleared tile squashes and shrinks to nothing (`clear`, back ease in). The squash is the back curve's own dip, about 10% before it shrinks, so it needs no amount of its own.
- At the end it bursts into `burst_dots` candy dots in its own fill color, each `burst_dot_size` of the tile side across. They fly out `burst_reach` of the tile side on `clear`'s transition eased out, evenly spaced round the circle, and fade linearly over `burst_fade` seconds. The burst is a decorative tail: it starts when the clear ends and does not hold input (3.6).
- All cleared tiles clear together.

**Clear notice (AT-104)**
- A badge pill, `notice_height` tall, in badge with a badge_lip lip. It is centered horizontally on the board's top edge, overlapping the seam between HUD and board, so it never covers the rows the player works in.
- Content: a mini tile (`notice_tile_scale` of `notice_height`) of each value the notice names with a `notice_strike` px badge_ink strike line across it, corner to corner from bottom left to top right, then the text in the body role, badge_ink. Padding `space_s` left and right, items `space_xs` apart. In every skin the strike runs the same way.
- *Mini tile labels (2026-10-21, every skin):* a mini tile shows its label only when the label is 3 characters or fewer (for example 2, 512, 64K, 4aa). A longer label is not drawn: the tile is a color chip with its strike, because at this size a 4 to 6 character label is 2.6 to 4 dp tall and the strike runs through it (14.1). The text beside it always names the values.
- Which values (GDD D-45): every value that left the spawn window in this move, from the floor before the move up to half the new floor, whether or not a tile of it was on the board. The notice shows when the move removed tiles or earned a star; a floor rise that removed nothing and earned nothing shows none.
- Text: "No more 2s" for one value, "No more 2s or 4s" for two, "No more 2s to 8s" for three or more. Values use the tile label format ("No more 2Ks"). A value whose label ends in a lowercase letter takes no plural "s": "No more 64aa", "No more 128aa to 512aa" (7.10).
- **Stars earned:** when the move earned stars, the copy is followed by `space_s`, then "+1" (the number of stars) in the same role and badge_ink, a gap of 0.25 of the role's font size, then the star icon (filled) in badge_ink, its box the role's font size, centered on the copy's cap middle. The pill widens to fit; its padding stays. The star earned effect leaves from this star.
- Motion: it springs in (`clear_notice`, from `from_scale`), holds `hold` seconds, fades out over `out` on the `screen_fade` curve (3.6). It never blocks input.

**HUD (slimmed)**
- Top row, `hud_top_row` tall:
  - The pause button on the left: a raised squircle, face `hud_button_face`, an `icon_hud` icon, touch area `touch_min`.
  - A Best pill on the right: surface with a surface_lip lip, `pill_height` tall, `pill_radius` corners, sides padded by `space_s`; "Best" in label role ink_muted, the number in body role ink.
- Under it, the score, centered, in the display role, auto fitting (section 2.6). Its baseline sits so that its comma tail (comma depth, 3.4) ends `space_xs` above the top of the clear notice, which is centered on the board's top edge `space_s` under the HUD. The score never touches the notice, and it does not move when the notice shows.
- No caption above the score.

**Star counter (GDD D-45, D-46)**
- *Star pill:* in the top row, `space_s` right of the pause button's face but never inside the pause button's touch area: with `touch_min` 160 (2.7) it starts at the touch area's right edge, 164 px. Surface with a surface_lip lip, `pill_height` tall, `pill_radius` corners, its face centered on the pause face like the Best pill. Inside, padded `space_s`: the counter star (`star_icon` box, centered on the face), `space_xs`, then this run's star count in the body role, ink, on the Best pill's baseline rule. It shows "0" from the start of a run, which tells a new player that stars exist.
- *Free pill:* while at least one free booster is held, `space_xs` right of the star pill: badge with a badge_lip lip, `pill_height` tall, `pill_radius` corners, "1 free" (the number held) in the body role, badge_ink, padded `space_s`. It is gone while none is held.
- *Counter star:* the star icon's outline in badge, filled in badge from the bottom by the progress to the next free booster (count mod 3): nothing at 0, a third of its area at 1, two thirds at 2. On these shapes the fill line sits at 35% and 55% of the star's height above its lowest points (measured: 35.3% and 54.8%). The tile lip is not used here: the pill carries it.
- *Fit:* at the 1080 px canvas, the star pill spans 164 to 308 px and the free pill ends at 482 px ("1 free"), about 540 px with two digit counts (measured in the mockups). The Best pill starts at 764 px for "Best 96,520" and never left of 622 px (a 13 character best score), so the top row never crowds. A 15 character best score (2.6) would start the pill at about 530 px, into the free pill, so the Best number shrinks to fit: the pill's left edge stays at least `space_s` right of the free pill's end (the star pill's end when no free pill shows), its number shrinking from the body size, never below the label role size (34). With two digit star and free counts the worst 15 character best score fits at 40 px (14.2); best scores up to 13 characters keep the body size. The HUD's height does not change, so section 2.4 stands.

**Star earned effect (3.6)**
- A lemon star (the star icon in badge, filled, on a `target_edge_width` edge in badge_ink, 3.6) appears on the notice's star at `from_scale`, `delay` after the notice starts, and flies `star_earn` to the counter star, growing to full size.
- Its path is a quadratic curve from the notice's star to the counter star whose control point is (the counter star's x, the notice star's y): it slides out along the notice, then swings up past the left of the score instead of across it.
- It draws on the notice layer (7.1), above the board and the notice and below any dialog.
- On arrival the counter star pops like `merge_pop` (its duration, curve and `peak_scale`) and the count goes up by one.
- *Conversion (`star_convert`):* when the arrival makes the count a multiple of 3, the counter star shows full for the moment, a full lemon star travels from it to the free pill's place (shrinking to half size, `star_convert`), and the free pill pops in from `from_scale` like `merge_pop` (or, already shown, its number changes and it pops to `peak_scale`). Then the counter star's fill fades to empty over `empty` on the `screen_fade` curve.

**Booster bar**
- A floating dock, `dock_height` tall and `dock_radius` corners, in surface with a surface_lip lip. It sits `board_margin` from the sides of the content column (2.8; on phones, the screen), with five raised buttons inside.
- The `hint_height` row above it holds the hint pill.
- Each button: surface_raised face, `radius_button` corners, `button_lip` lip. The dock's own lip is part of `dock_height`. The dock pads its buttons by `space_xs` all round its face and spaces them `space_xs` apart. The five buttons share the width equally, and each button, face and lip, is `dock_height` less the dock lip less 2 x `space_xs` tall: a 140 face on a 10 lip. The icon (`icon_booster`) sits over the cost in the label role, as a tile label.
- *Touch area (QA6-05, 2.7):* each button takes touch on the dock face's whole height (174 px, more than `touch_min`) and across to the middle of the `space_xs` gaps beside it (the outer buttons to the dock's edge). The drawing does not change.
- Looks:
  - *Normal:* as above.
  - *Pressed:* scale `press_scale`, lip down to `button_lip_pressed`.
  - *Active (targeting):* accent face, accent_lip lip, raised `active_raise`; icon and cost in ink_dark; `target_pulse` wobble.
  - *Disabled:* flat (no lip), sitting lower, disabled_surface face, icon and cost in disabled_ink.
  - *Suggested (D-42, in the out of moves offer):* a "Suggested" badge pill (badge, badge_ink, label role) rests on the button: the bottom of its lip on the button's top edge, so it never covers the icon. It hides while any booster is active (targeting from the offer), in every skin, and comes back when the offer waits for a choice again.
  - *Free (D-46):* while a free booster is held, every booster's cost line shows the star icon (filled, box the label size, centered on the line's cap middle), a gap of 0.25 of the label size, then "Free" in the label role, the group centered where the cost was. Colors: badge when normal or pressed, ink_dark when active, disabled_ink when disabled (disabled boosters read Free too and keep their disabled look). The group is 120 px wide at most; the button face is 187.
- Hint: a badge pill in the hint row, for example "Tap a tile to smash it".

**Icons**
- Chunky candy pictograms: strokes `icon_stroke` on a 24 unit grid, round caps and joins, filled where it helps.
- Set: hammer, swap, shuffle, double (x2 drawn as strokes), undo, pause, settings, sound on, sound off, close, check, since 2026-10-13 star, chevron and arrow, and since 2026-10-17 coffee.
- *Star:* five points, one up. Center (12, 12.9), outer radius 11, inner radius 0.50 of the outer: a plump candy star. Points rounded with a 1.8 unit radius, valleys with 1.0. The filled star is the icon; the counter draws its outline band, 2.5 units wide, plus the progress fill (counter star above).
- *Chevron* (rows that open a screen): (9.5, 6) to (15.5, 12) to (9.5, 18), `icon_stroke`, round caps and join.
- *Arrow* (Info example rows and the splash's sum row): a shaft (4, 12) to (15, 12), `icon_stroke`, round caps, and a filled head with its tip at (21, 12) and its back corners at (14.5, 6.5) and (14.5, 17.5), all three corners rounded by 1 unit (the rounded tip ends near 20.5). The shaft's round cap ends inside the head. Approved as built (2026-10-13 review).
- *Coffee* (the Buy me a coffee button, 7.2 and 7.13, 2026-10-17): a candy mug, filled like the star.
  - Body: a filled shape from x 3 to 16, top edge y 10, bottom edge y 21.5, straight upright sides; top corners rounded by 1 unit, bottom corners by 4.
  - Handle: an arc, `icon_stroke`, round caps, center (16, 15.5), radius 3.25, from straight up round the right to straight down (-90 to 90 degrees), so both ends tuck into the body's right edge.
  - Steam: two strokes, `icon_stroke`, round caps, (7.5, 4) to (7.5, 6.5) and (11.5, 4) to (11.5, 6.5), centered over the body, their caps 1.75 units clear of its top.
  - It spans about x 3 to 21 and y 2.25 to 21.5.
- Colors: ink normally, ink_dark on accent, disabled_ink when disabled. The chevron, arrow and coffee draw in ink_muted.
- Reference: docs/design/additions/gumdrop-icons.png (the star empty, a third, two thirds and full, at 216 px, the counter size and the cost size; the chevron and arrow).

**Sound toggle**
- A pill track `toggle_w` by `toggle_h` with a surface_lip lip.
- Off: surface_raised track, ink knob (`toggle_knob`, with a `toggle_knob_lip` lip in surface_lip) on the left.
- On: accent track, knob on the right. The track keeps its surface_lip lip.
- It slides with button_release.

**Backdrop:** flat bg.

**Buttons, panels and chips**
- *Primary:* accent face, accent_lip lip, ink_dark text in the body role, `radius_button` corners, `button_height` tall. Pressed: accent_pressed.
- *Secondary:* surface_raised with surface_lip lip, ink text.
- *Chip:* surface_raised, `radius_chip` corners. Selected: accent with ink_dark text.
- *Card and sheet panel:* surface, `radius_card` corners, surface_lip lip, `space_m` padding.
- *Divider:* a `hairline` rounded line in line.
- *Focus:* a `focus_width` accent outline `focus_gap` outside the button.

---

## 5. Slate

Editorial and exact. Small values are dark slabs with the number in a bright tint of the same hue. From 128 up a tile is a solid block of color with a black number, so the big tiles are seen first. Sharp corners, hairline rules, left aligned type, numbers top left (clear of the thumb). Motion is fast cuts, nothing bounces. Font: **system font** (Roboto on Android).

### 5.1 Palette

| Role | Hex | Use |
|---|---|---|
| bg | #0B0C0E | near black |
| surface | #181A1C | sheets, chips |
| surface_raised | #212326 | pressed chips and buttons |
| line | #36383B | 2 px hairlines |
| ink | #F5F2E9 | paper white |
| ink_muted | #A1A5AB | |
| ink_dark | #0E0F12 | numbers on blocks, text on paper and accent |
| accent | #FA5D36 | signal vermilion |
| accent_pressed | #E14D28 | |
| disabled_ink | #7D8085 | |
| chain | #F5F2E9 | chain line, nodes, chained frame |
| target | #FA5D36 | corner brackets |
| joinable | #F5F2E9 | hollow node and thin frame |
| scrim | #0B0C0E at 82% (#0B0C0ED1) | |
| badge | #FA5D36 | hint bar, Suggested, New best, clear notice |
| badge_ink | #0E0F12 | |
| **Extras** | | |
| chain_edge | #0E0F12 | dark edge each side of the chain line |

### 5.2 Tile ramp

Tier 1 slabs (2 to 64) have a dark fill and a bright number of the same hue, lightness alternating between neighbors. Tier 2 blocks (128 to 16K) are solid color with a black number. Tier 3 (32K up) is a block with an inner hairline frame. Hues from 15 to 55 degrees are kept free for the vermilion accent, so brackets and the hint bar never sit on a tile of their own color.

Above 128K the colors come round again by the color cycle (3.3), from forest slab, while the tier stays 3. So a big tile can be a dark slab with the inner frame: slab or block goes by the color (positions 0 to 5 are slabs, 6 to 16 blocks), the frame by the value (5.7).

| Value | Label | Name | Fill | Number | Contrast | Tier |
|---|---|---|---|---|---|---|
| 2 | 2 | forest slab | #115D1C | #95F198 | 5.88 | 1 |
| 4 | 4 | navy slab | #1E327D | #C9D7F9 | 8.06 | 1 |
| 8 | 8 | oxblood slab | #7F1F26 | #F9CAC8 | 6.73 | 1 |
| 16 | 16 | teal slab | #156561 | #58F3EA | 5.03 | 1 |
| 32 | 32 | aubergine slab | #4F1F6C | #E5CCF9 | 8.22 | 1 |
| 64 | 64 | bronze slab | #6E4B0F | #F9D097 | 5.42 | 1 |
| 128 | 128 | amber | #F59E33 | #0E0F12 | 8.96 | 2 |
| 256 | 256 | cyan | #49F6FB | #0E0F12 | 14.47 | 2 |
| 512 | 512 | magenta | #F74AD8 | #0E0F12 | 6.32 | 2 |
| 1024 | 1024 | lime | #C2FC44 | #0E0F12 | 15.79 | 2 |
| 2048 | 2K | periwinkle | #9191F6 | #0E0F12 | 6.92 | 2 |
| 4096 | 4K | gold | #F9CB3D | #0E0F12 | 12.45 | 2 |
| 8192 | 8K | sky | #39C4F8 | #0E0F12 | 9.51 | 2 |
| 16384 | 16K | pink | #F75EA7 | #0E0F12 | 6.49 | 2 |
| 32768 | 32K | mint | #48FAB4 | #0E0F12 | 14.25 | 3 |
| 65536 | 64K | lilac | #AF83F6 | #0E0F12 | 6.75 | 3 |
| 131072 | 128K | paper | #F5F2E9 | #0E0F12 | 17.12 | 3 |
| above | 256K and up | the color cycle (3.3): 0 to 16, then again | as the position | as the position | as the position | 3 |

Closest pairs (ramp check, every value from 2 to 2^62 with the color cycle): neighbors 0.210, times 4 0.135, times 8 0.094, the same as up to 128K alone.

### 5.3 Text pairs

| Pair | Text on background | Ratio |
|---|---|---|
| Score and HUD numbers | ink on bg | 17.48 |
| Labels, secondary numbers, toggle OFF | ink_muted on bg | 7.91 |
| Signal label (OUT OF MOVES, RUN OVER) | accent on bg | 6.23 |
| Booster name and cost, disabled | disabled_ink on bg | 4.94 |
| Paper fill: active booster, selected chip, toggle ON | ink_dark on ink | 17.12 |
| Badges and the targeting hint bar | badge_ink on badge | 6.10 |
| Primary button | ink_dark on accent | 6.10 |
| Primary button, pressed | ink_dark on accent_pressed | 4.83 |
| Text on surface (sheets, chips, pressed rows) | ink on surface | 15.59 |
| Labels on surface | ink_muted on surface | 7.05 |
| Text on raised surface | ink on surface_raised | 14.07 |
| Labels on raised surface | ink_muted on surface_raised | 6.37 |
| **2026-10-13 additions** | | |
| Free cost and its star, pressed column | accent on surface | 5.55 |

The additions also use these existing pairs: the counter star, the free count, the Free cost and the wordmark "Up" (accent on bg), the counter's "STARS" caption and count, headings and reading text (ink_muted and ink on bg), the counter's paper flash (ink on bg), the notice's "+n" and star (badge_ink on badge), the disabled Free cost (disabled_ink on bg), pressed rows (ink and ink_muted on surface).

The 2026-10-17 Buy me a coffee button (7.2, 7.13) needs no new pair. Its label and cup icon are ink_muted, on:

| Where | Pair | Ratio |
|---|---|---|
| Splash and About, at rest | ink_muted on bg | 7.91 |
| Splash and About, pressed | ink_muted on surface | 7.05 |

The disabled pair also covers disabled buttons and chips: they have no fill, so their text sits on bg. A disabled control never sits on surface or surface_raised (disabled_ink reaches only 4.40 and 3.97 there).

### 5.4 Type (system font: Roboto on Android)

| Role | Size | Weight | Tracking | Case |
|---|---|---|---|---|
| display (score) | 184 | 700 | -4 | as written |
| title | 72 | 700 | -1 | as written |
| body | 44 | 500 | 0 | as written |
| label | 30 | 600 | +4 | CAPITALS |
| tile (top left) | 40%, 40%, 33%, 31% of the tile side for 1 to 4 characters | 700 | -1 | |
| heading | 30 | 700 | +4 | CAPITALS |
| reading | 42 | 400 | 0 | as written |

Slate's section heading is an editorial kicker, the HUD's "SCORE" caption made bold: small capitals in ink over the paragraph.

`label_fit` 0.78 (was 0.84): 1 minus twice `number_inset`, so the label keeps the same 0.11 margin on the right as on the left and never reaches the special frame at `special_inset` 0.06. Up to 2^49 only 128M, 256M and 512M shrink (to about 93%, digits 12.1 dp on the 59.6 dp tile at 18:9). `display_fit_min` 76 (96 until 2026-10-21: a 15 character score beside a 15 character BEST column fits at 79 px, 14.2). The display and title tracking eased from -6 and -2 to -4 and -1: Roboto sits slightly tighter than the Segoe UI of the Phase 1 renders.

### 5.5 Shape and sizes

| Name | Value | | Name | Value |
|---|---|---|---|---|
| board_margin | 44 | | radius_button | 4 |
| board_gap | 10 | | radius_card | 0 |
| board_padding | 0 | | radius_chip | 4 |
| tile_radius | 0.032 (6 px at 190 px) | | hairline | 2 |
| preview_scale | 0.59 (112 px) | | hud_height | 350 |
| special_from | 32768 | | bar_height | 192 |
| chain_width | 8 | | hint_height | 112 (the HUD context row) |
| chain_ring | 6 | | button_height | 160 (was 144, 2.7) |
| joinable_ring | 2 | | row_height | 148 |
| target_ring | 6 | | icon_booster | 66 |
| space_xs, s, m, l, xl | 8, 20, 40, 64, 104 | | icon_hud | 72 |
| touch_min | 160 (was 144, 2.7) | | icon_stroke | 2 |
| notice_height | 112 (the HUD context row) | | toggle_w, toggle_h, toggle_knob | 132, 64, 44 |
| notice_tile_scale | 0.5 | | notice_strike | 2 |
| star_icon | 36 | | reading_line_spacing | 14 |
| scroll_bar | 4 | | | |

**Extras:**
- Tile number: `number_inset` 0.11, `number_plate` 6.
- Chain line: `line_edge` 3, `node_size` 24.
- Joinable and selected: `joinable_node_stroke` 3 (the hollow node's stroke; `joinable_ring` is the frame), `selected_frame` 4.
- Brackets and frames: `target_bracket` 0.30, `special_inset` 0.06, `frame_inset` 0.03 (fractions of the tile side).
- Merge flash: `flash_cut` 0.05.
- Bar: `strip_height` 192.
- Toggle: `toggle_knob_inset` 10.
- Focus: `focus_width` 4, `focus_gap` 4.

### 5.6 Motion: fast and exact

| Name | Duration | Transition, ease | Extras |
|---|---|---|---|
| spawn | 0.14 | expo, out | from_scale_y 0 (wipes down from the top edge), stagger 0 |
| fall | 0.16 | quart, out | |
| chain_add, chain_remove | 0.06 | linear | |
| joinable_in | 0.06 | linear | |
| merge_travel | 0.12 | quart, in | |
| merge_pop | 0.16 | expo, out | flash 1.0 (the result shows paper, then cuts to its color below flash_cut) |
| clear | 0.14 | expo, in | |
| clear_notice | 0.12 | expo, out | hold 1.6, out 0.12 |
| press | 0.04 | linear | |
| button_press | 0.04 | linear | |
| button_release | 0.10 | quart, out | |
| dialog_in | 0.24 | expo, out | from_offset 32 (slides up 32 px), from_alpha 0; never scales |
| dialog_out | 0.12 | quart, in | |
| screen_fade | 0.12 | linear | |
| target_pulse | 0 | | no pulse: Slate holds still |
| score_count | 0.24 | quart, out | |
| skin_switch | 0.16 | linear | |
| star_earn | 0.16 | linear | the counter's paper flash; no flight |
| star_convert | 0.16 | linear | the free count's paper flash |

A committed chain settles in about 0.45 s.

### 5.7 Components

**Tile**
- Flat fill, corners `tile_radius`, no shadow, no gradient.
- The label sits top left, its cap top `number_inset` of the side from the top and left edges.

**Tile states**
- *Chained:* a `chain_ring` frame in chain whose outer edge sits `frame_inset` of the side inside the tile edge, plus a filled `node_size` square node in chain at the center. The band of tile fill outside the frame is what keeps an ink_dark frame visible on a light block; drawn at the very edge it melts into the dark gap.
- *Joinable (D-40):* a `joinable_ring` frame in joinable, inset `frame_inset` like the chain frame, plus a hollow `node_size` square at the center with a `joinable_node_stroke` stroke. It means "the line can come here".
- *Press feedback (D-43):* four corner brackets in target, `target_ring` thick, arms `target_bracket` of the side, hugging the outside of the tile edge with no offset.
- *Selected (Swap's first tile):* the same brackets plus a `selected_frame` frame in target just inside the edge (no inset, so it reads as one mark with the brackets). They hold still.
- *Marks on blocks:* paper vanishes on the light blocks. On a block (ramp position 6 to 16 by the color cycle, 3.3, whose number is ink_dark) the chained frame, the joinable frame and the hollow node draw in ink_dark instead of chain and joinable. On a slab (positions 0 to 5) they keep chain and joinable, also on a big tile above 128K that takes a slab color. This goes by the color, not the tier (2026-10-15; up to 128K it is the same split). Every node, filled or hollow, gets a `line_edge` outline in chain_edge, like the chain line, so it reads on any tile.
- *Special (32K up):* an inner hairline frame in the tile's number color (ink_for), `hairline` thick, inset `special_inset`. On a block that is ink_dark, as before; on a big tile above 128K with a slab color it is the slab's bright number, so the frame shows on the dark fill (2026-10-15).

**Board:** no tray and no background. An empty cell shows a `hairline` frame in line.

**Chain line**
- Drawn node to node in one piece, straight segments, square ends, no tail toward the finger.
- First a chain_edge line, `chain_width + 2 x line_edge` wide, then the chain line, `chain_width` wide. Square nodes sit on the chained tile centers.
- Draw order: fills, frames, line, nodes, label plates, numbers.

**Label plate (fixes "32" reading as crossed out)**
- On a chained tile, before its number, fill a rectangle of the tile's own fill color covering the whole label's ink box grown by `number_plate` px.
- The line disappears under the plate and never shows between glyphs.

**Merge preview**
- Not on the board.
- The HUD's context row reads "CHAIN 6" on the left and shows the result as a tile (`preview_scale` of the board tile, 112 px) on the right.

**Merge, spawn and fall**
- Merge: chain tiles slide into the last tile (`merge_travel`). The result shows a paper fill for a beat, then cuts to its own color (`merge_pop`).
- Spawn: tiles wipe down from their top edge, all at once.
- Fall: quart ease out, no bounce.

**Small tile clear (D-38)**
- Every cleared tile wipes up to nothing (scale y to 0, pivot at the top, `clear`).
- No particles.

**Clear notice (AT-104)**
- It takes the HUD's context row for its hold time: a full width bar in badge.
- Content: the values the notice names (4.7: every value that left the spawn window) as small tiles (`notice_tile_scale` of `notice_height`) with a `notice_strike` px badge_ink strike line, corner to corner from bottom left to top right, then the text in the label role, badge_ink, in capitals: "NO MORE 2s" (the words in capitals; the value and its plural "s" are never cased, 7.10). Padding `space_m` on the left, items `space_xs` apart.
- Stars earned: as 4.7, in the label role: "NO MORE 2s  +1" and the star, `space_s` after the copy.
- Motion: it cuts in and out with `clear_notice`, its own curve both ways.
- While the context row is busy (a chain being dragged, or a targeting hint), the notice waits until the row is free. Its hold counts only while it shows.

**HUD**
- Left aligned: "SCORE" in the label role over the score in display.
- On the right: the pause icon (no container, full touch area) and "BEST" over the best score in body. The icon sits at the top of its `touch_min` touch area, centered across it. While held, the whole touch area fills surface, drawn behind the HUD's text (ink and ink_muted on surface are listed pairs).
- A hairline under the header, then the context row (`hint_height`):
  - while dragging, "CHAIN n" and the preview tile;
  - in targeting, a full width badge bar, for example "HAMMER: TAP A TILE TO SMASH IT";
  - otherwise empty.

**Star counter (GDD D-45, D-46): the caption line**
- The line of the "SCORE" caption carries the counter on its right, like a folio line in a magazine. Its right edge is the left edge of the pause icon's touch area.
- From right to left: the count in the label role, ink; `space_xs`; the counter star (`star_icon`, centered on the caption's cap middle); `space_xs`; "STARS" in the label role, ink_muted.
- While at least one free booster is held, "1 FREE" (the number held) in the label role, accent, sits `space_m` left of "STARS".
- *Counter star:* outline in accent, filled in accent from the bottom by count mod 3 (a third, two thirds of its area; the fill line at 35% and 55% of its height), as 4.7.
- *Fit:* measured at the 1080 px canvas: the group spans 754 to 920 px, 604 to 920 px with "1 FREE" (the pause touch area starts at 920 with `touch_min` 160); "SCORE" ends near 165 px. The star (5 to 41 px) stays inside the 41 px caption line, so the score's digits keep their `space_xs` gap below. The context row stays free for the chain, the hint and the notice, so the count shows during every moment of play.

**Star earned effect (3.6)**
- No flight. When the notice cuts in, the counter shows the new count and draws its star full in paper (ink) for `star_earn`, then cuts to its accent progress look. Two stars in one move are one flash with the final count.
- *Conversion:* when the count reaches a multiple of 3, the free count appears (or changes) drawn in paper (ink) for `star_convert`, then cuts to accent.

**Booster bar**
- A full width strip, `strip_height` tall, with a hairline on top and hairlines between five equal columns.
- Each column: the icon, then the name and the cost in the label role.
- Looks:
  - *Pressed:* the column fills surface.
  - *Active:* the column fills ink (paper), content in ink_dark.
  - *Disabled:* content in disabled_ink, the cost struck through with a `hairline` line.
  - *Suggested:* a "SUGGESTED" badge (badge, badge_ink, label role) sits across the column's top hairline, centered on it. Its upper half reaches up to 8 px over the lower edge of the board's bottom row, where Slate draws nothing (numbers sit top left), and only while the offer waits for a choice: like every skin, it hides while any booster is active.
  - *Free (D-46):* the cost line shows the star (filled, box the label size, centered on the cap middle), a gap of 0.25 of the label size, then "FREE", left aligned where the cost was. Accent when normal or pressed, ink_dark when active, disabled_ink when disabled with the `hairline` strike across the whole group.

**Icons**
- Signage pictograms: straight segments and true circles, square caps, `icon_stroke` 2, no fills.
- Settings is three sliders. Pause is two upright bars.
- *Star:* five points, one up, sharp: center (12, 12.9), outer radius 11, inner radius 0.42 of the outer, no rounding. The filled star is the icon (a data mark, so it may fill like the chain nodes); the counter draws its outline band, 2 units wide with mitered points, plus the progress fill.
- *Chevron:* (9, 5) to (16, 12) to (9, 19), `icon_stroke`, square caps, mitered.
- *Arrow:* a shaft (3, 12) to (20, 12) and a chevron head (15, 7) to (20, 12) to (15, 17), `icon_stroke`, square caps.
- *Coffee* (2026-10-17): a straight sided cup, no fill, every stroke `icon_stroke`, square caps, mitered corners.
  - Rim: (2, 10) to (17, 10).
  - Body: (4, 10) to (4, 21) to (15, 21) to (15, 10).
  - Handle: (15, 12.5) to (20, 12.5) to (20, 17.5) to (15, 17.5).
  - Steam: (7.5, 3.5) to (7.5, 7) and (11.5, 3.5) to (11.5, 7).
- The chevron, arrow and coffee draw in ink_muted.
- Reference: docs/design/additions/slate-icons.png.

**Sound toggle (fixes "does not show whether it is on")**
- A rectangular track `toggle_w` by `toggle_h` with a square knob.
- On: the track fills ink (paper), the knob in ink_dark sits right, and "ON" in the label role, ink_dark, sits inside the track on the left.
- Off: the track is bg with a `hairline` line outline, the knob in ink_muted sits left, and "OFF" in ink_muted sits inside on the right.
- The word and the fill both change, so the state reads without color.

**Backdrop:** flat bg.

**Buttons, panels and chips**
- *Primary:* accent fill, ink_dark text, `radius_button` corners, text left aligned.
- *Secondary:* a `hairline` outline in ink, ink text, left aligned like the primary (7); pressed fills surface.
- *Disabled (buttons and chips):* a `hairline` outline in line, no fill, disabled_ink text, on bg only (5.3).
- *Chip:* surface; selected fills ink (paper) with ink_dark text.
- *Sheet panel:* bg with a `hairline` line on its open edge, square corners, `space_m` padding, rows split by hairlines.
- *Focus:* a `focus_width` accent outline `focus_gap` outside.

---

## 6. Nova

Tiles are stars. Round orbs float on deep space with no tray. Every value is a different kind of star: dark giants with white numbers and bright stars with dark numbers alternate, and each step jumps far round the hue wheel. The bigger the value, the wider its glow. A chain is a beam of light under the orbs. Light, airy type, lowercase labels, slow and fluid motion. Font: **Outfit**.

### 6.1 Palette

| Role | Hex | Use |
|---|---|---|
| bg | #040819 | deep space, edges and bottom |
| surface | #10162F | sheets |
| surface_raised | #1F2646 | rows and chips |
| line | #52628C | ring outlines, dividers |
| ink | #F7F9FF | |
| ink_muted | #ABB7D5 | |
| ink_dark | #060C20 | |
| accent | #49EAF2 | aurora cyan |
| accent_pressed | #17D0D8 | |
| disabled_ink | #848C9F | |
| chain | #FFFFFF | beam core, chained rim |
| target | #49EAF2 | dashed orbit |
| joinable | #FFFFFF | thin orbit |
| scrim | #040819 at 86% (#040819DB) | |
| badge | #49EAF2 | |
| badge_ink | #060C20 | |
| **Extras** | | |
| bg_glow | #181942 | lightest point of the backdrop glow |
| star | #FFFFFF | star dust |
| accent_violet | #9264EF | second aurora color for glows, never behind text |

### 6.2 Tile ramp

Tier 1 is 2 to 1K, tier 2 is 2K to 16K (wider glow), and tier 3 is 32K up (corona rays).

Above 128K the colors come round again by the color cycle (3.3), from red dwarf, while the tier stays 3 (corona rays) and the glow stays at its widest (6.7).

| Value | Label | Name | Fill | Number | Contrast | Tier |
|---|---|---|---|---|---|---|
| 2 | 2 | red dwarf | #D01D21 | #F7F9FF | 5.14 | 1 |
| 4 | 4 | yellow star | #FED33F | #060C20 | 13.51 | 1 |
| 8 | 8 | blue giant | #1957D2 | #F7F9FF | 5.98 | 1 |
| 16 | 16 | aqua nebula | #2AF0D5 | #060C20 | 13.43 | 1 |
| 32 | 32 | magenta nebula | #CA13B3 | #F7F9FF | 4.69 | 1 |
| 64 | 64 | orange giant | #FDA669 | #060C20 | 10.02 | 1 |
| 128 | 128 | violet | #693AD4 | #F7F9FF | 6.32 | 1 |
| 256 | 256 | aurora green | #9BF461 | #060C20 | 14.34 | 1 |
| 512 | 512 | crimson | #D31D4B | #F7F9FF | 4.93 | 1 |
| 1024 | 1024 | ice | #7ECFFD | #060C20 | 11.31 | 1 |
| 2048 | 2K | purple | #9129C8 | #F7F9FF | 5.95 | 2 |
| 4096 | 4K | gold | #F7E04F | #060C20 | 14.55 | 2 |
| 8192 | 8K | emerald | #0D7C59 | #F7F9FF | 4.93 | 2 |
| 16384 | 16K | rose | #FD8DC5 | #060C20 | 9.06 | 2 |
| 32768 | 32K | deep blue | #0A65AD | #F7F9FF | 5.74 | 3 |
| 65536 | 64K | supernova | #FEBC72 | #060C20 | 11.70 | 3 |
| 131072 | 128K | white hole | #FAFCFF | #060C20 | 18.90 | 3 |
| above | 256K and up | the color cycle (3.3): 0, 2 to 16, then again | as the position | as the position | as the position | 3 |

Closest pairs (ramp check, every value from 2 to 2^62 with the color cycle): neighbors 0.194, times 4 0.169, times 8 0.198. Up to 128K alone the closest times 8 pair was 0.258; now it is 128K white hole and 1M aqua nebula, across the wrap.

### 6.3 Text pairs

| Pair | Text on background | Ratio |
|---|---|---|
| Score, lightest part of the backdrop | ink on bg_glow | 15.88 |
| Labels, lightest part of the backdrop | ink_muted on bg_glow | 8.33 |
| Labels, darkest part of the backdrop | ink_muted on bg | 9.93 |
| Booster cost, targeting | accent on bg_glow | 11.41 |
| Booster cost, disabled | disabled_ink on bg_glow | 4.96 |
| Disabled button or chip on a sheet | disabled_ink on surface | 5.29 |
| Badges | badge_ink on badge | 13.26 |
| Primary button, selected chip | ink_dark on accent | 13.26 |
| Primary button, pressed | ink_dark on accent_pressed | 10.22 |
| Sheet and card text | ink on surface | 16.94 |
| Sheet and card labels | ink_muted on surface | 8.89 |
| Rows and chips | ink on surface_raised | 14.01 |
| Labels on rows and chips | ink_muted on surface_raised | 7.35 |
| Text over the scrim (worst case over a white hole) | ink on scrim | 13.45 |
| Labels over the scrim (worst case) | ink_muted on scrim | 7.06 |
| **2026-10-14 splash** | | |
| Wordmark "Up" on its own glow (7.2), worst case: bg_glow mixed with accent at 0.25 (#244D6E) | accent on the glow | 6.05 |
| Wordmark "Sum" where the glow reaches it, same worst case | ink on the glow | 8.42 |

The 2026-10-13 additions need no new pair. They use: the counter star, the free count, the Free cost and the wordmark "Up" (accent on bg_glow), the star count and reading text (ink_muted on bg_glow), headings, the About brand block and license text (ink on bg_glow), the notice's "+n" and star (badge_ink on badge), the disabled Free cost (disabled_ink on bg_glow), pressed rows (ink and ink_muted on surface_raised), the About row in Settings (ink and ink_muted on surface).

The 2026-10-17 Buy me a coffee button (7.2, 7.13) needs no new pair. Its label and cup icon are ink_muted, on:

| Where | Pair | Ratio |
|---|---|---|
| Splash and About, at rest, on the darkest backdrop (the splash's bottom on a phone) | ink_muted on bg | 9.93 |
| Splash and About, at rest, on the lightest backdrop (the glow reaches the splash's bottom on a wide screen) | ink_muted on bg_glow | 8.33 |
| Splash and About, pressed | ink_muted on surface_raised | 7.35 |

Disabled buttons and chips have no fill (a faint ring), so their text sits on whatever is under them: the backdrop (bg, bg_glow) or a sheet (surface). A disabled control never sits on surface_raised (disabled_ink reaches only 4.38 there).

### 6.4 Type (Outfit)

| Role | Size | Weight | Tracking | Case |
|---|---|---|---|---|
| display (score) | 148 | 300 | 0 | as written |
| title | 68 | 300 | 0 | as written |
| body | 44 | 400 | 0 | as written |
| label | 32 | 400 | +3 | lowercase |
| tile | 46%, 42%, 37%, 31.5% of the orb diameter for 1 to 4 characters | 600 | 0 | |
| heading | 50 | 300 | 0 | as written |
| reading | 42 | 400 | 0 | as written |

Reading text takes 400, not Nova's light 300: thin strokes glare in long light on dark text.

`label_fit` 0.82. `display_fit_min` 80. The display shrank from 160 to 148 to reach 56 dp at 18:9, and the title tracking went from +1 to 0, because Outfit Light is wider set than Segoe UI Light.

### 6.5 Shape and sizes

| Name | Value | | Name | Value |
|---|---|---|---|---|
| board_margin | 44 | | radius_button | 72 (pill) |
| board_gap | 22 (orb_scale 0.89 of the pitch; was 24 at 0.88, 2.4) | | radius_card | 64 (sheet top corners) |
| board_padding | 0 | | radius_chip | 72 |
| tile_radius | 0.5 (circle) | | hairline | 2 |
| preview_scale | 0.54 of the orb | | hud_height | 200 |
| special_from | 32768 | | bar_height | 254 |
| chain_width | 12 (beam core) | | hint_height | 64 |
| chain_ring | 8 | | button_height | 160 (was 144, 2.7) |
| joinable_ring | 3 | | row_height | 144 |
| target_ring | 4 | | icon_booster | 80 |
| space_xs, s, m, l, xl | 12, 28, 44, 72, 112 | | icon_hud | 72 |
| touch_min | 160 (was 144, 2.7) | | icon_stroke | 1.5 |
| notice_height | 80 | | toggle_w, toggle_h, toggle_knob | 124, 64, 40 |
| notice_tile_scale | 0.6 | | notice_strike | 2 |
| star_icon | 32 | | reading_line_spacing | 12 |
| scroll_bar | 4 | | | |

**Extras:**
- Orb and rim: `orb_scale` 0.89 (was 0.88, 2.4), `rim_width` 4, `rim_lighten` 0.35.
- Glow: `glow_alpha_low` 0.10, `glow_alpha_high` 0.55, `glow_spread_low` 1.12, `glow_spread_high` 1.55. Both scale linearly by the value's place from 2 to 131072 and stay at the top above it (6.7), not by the color cycle.
- Beam: `beam_glow_width` 44, `beam_glow_alpha` 0.28.
- Orbits: `orbit_offset` 0.10, `joinable_orbit` 0.05, `orbit_dashes` 24, `orbit_dash_fill` 0.55, `orbit_breath` 0.05, `orbit_turn` 0.08.
- Glow multipliers: `joinable_glow` 1.25, `chain_glow` 1.4, `target_glow` 1.5, `spawn_bloom` 0.6.
- Corona: `ray_count` 12, `ray_inner` 1.08, `ray_outer` 1.24, `ray_width` 3, `ray_lighten` 0.35, `ray_alpha` 0.6.
- Dark rim: `dark_rim_from` 131072. The chained rim draws in ink_dark on every tile that takes this value's colors, the white hole (ramp position 16): 128K, 8B (2^33), 512T (2^49). Since 2026-10-15 it no longer means "this value and up", because the color cycle puts other colors above it.
- Ring buttons: `ring_button` 136, `ring_width` 3.
- Disabled: `disabled_ring_alpha` 0.35, `disabled_ring_dashes` 16, `disabled_icon_alpha` 0.6.
- Star dust: `star_count` 70, `star_alpha_min` 0.08, `star_alpha_max` 0.35, `star_size_min` 1.5, `star_size_max` 3.5, `star_seed` 20261010, `star_clearance` 24.
- Backdrop glow: `backdrop_glow_x` 0.5, `backdrop_glow_y` 0.26, `backdrop_glow_radius` 0.95.
- HUD and icons: `hud_ring` 96, `icon_spark` 1.0, `icon_fit` 0.86, `icon_glow_alpha` 0.4.
- Active ring glow: `ring_glow_spread` 1.45, `ring_glow_alpha` 0.75.
- Focus: `focus_gap` 6.
- Toggle glow: `toggle_glow_spread` 1.9, `toggle_glow_alpha` 0.6.

### 6.6 Motion: fluid and calm

| Name | Duration | Transition, ease | Extras |
|---|---|---|---|
| spawn | 0.34 | sine, out | from_scale 0.55, from_alpha 0, stagger 0.04 |
| fall | 0.26 | cubic, out | |
| chain_add, chain_remove | 0.16 | sine, out | |
| joinable_in | 0.20 | sine, out | |
| merge_travel | 0.24 | cubic, in out | orbs glide along the beam path |
| merge_pop | 0.40 | sine, out | peak_glow 1.8; the glow tail does not block input |
| clear | 0.36 | sine, in | to_scale 0.4, sparks 8, spark_size 8 px, spark_reach 0.7 (of the orb diameter) |
| clear_notice | 0.40 | sine, out | from_offset 16 (rises 16 px), from_alpha 0, hold 1.8, out 0.30 |
| press | 0.10 | sine, out | |
| button_press | 0.10 | sine, out | press_scale 0.96 |
| button_release | 0.24 | sine, out | |
| dialog_in | 0.44 | sine, out | from_alpha 0, from_scale 0.96 |
| dialog_out | 0.28 | sine, in | |
| screen_fade | 0.36 | sine, in out | |
| target_pulse | 1.60 | sine, in out | alpha_low 0.45 |
| score_count | 0.60 | sine, out | |
| skin_switch | 0.40 | sine, in out | |
| star_earn | 0.44 | sine, in out | delay 0.10, from_alpha 0, stagger 0.08, peak_glow 1.8 |
| star_convert | 0.40 | sine, out | peak_glow 2.0, from_offset 8, empty 0.40 |

A committed chain settles in about 0.65 s; the bloom fades after.

### 6.7 Components

**Orb**
- A circle `orb_scale` of the cell pitch, flat fill. A `rim_width` rim in fill lightened by `rim_lighten` sits just inside the edge.
- The label is centered.
- The glow sits behind the orb in its fill color. Radius is the orb radius times a lerp from `glow_spread_low` to `glow_spread_high`; alpha a lerp from `glow_alpha_low` to `glow_alpha_high`. Both run by the value's place, min(k - 1, 16) for 2^k: from 0 (value 2) to 16 (131072 and every value above), so bigger values glow wider. Not by the color cycle: a 256K orb in red dwarf glows as wide as 128K.
- The glow is one radial gradient texture made once and drawn tinted.

**Orb states**
- *Chained:* a `chain_ring` rim in chain and glow times `chain_glow`. On the white hole (every tile with the colors of `dark_rim_from`, 6.5) the rim is ink_dark, because a white rim on a white orb vanishes.
- *Joinable (D-40):* a thin solid orbit in joinable, `joinable_ring` wide, at radius times (1 + `joinable_orbit`), and glow times `joinable_glow`. It eases in over `joinable_in`.
- *Press feedback (D-43):* a dashed orbit in target, `target_ring` wide, at radius times (1 + `orbit_offset`), `orbit_dashes` dashes, and glow times `target_glow`.
- *Selected (Swap's first tile):* the dashed orbit turning `orbit_turn` per loop and breathing by `orbit_breath` on `target_pulse`.
- *Special (32K up):* `ray_count` corona rays from `ray_inner` to `ray_outer` orb radii, `ray_width` wide, in the fill lightened by `ray_lighten`, at `ray_alpha`.
  - Between two special orbs side by side, the rays that sit 15 degrees off the row (or column) meet in the gap as small crosses. Accepted (2026-10-13 review, also at `orb_scale` 0.89, where they sit a little tighter): they read as a glint between two stars and stay in the gap, far from every number. Turning the rays onto the row would line them up end to end into a dash that reads like a chain, and shortening them until they never meet would leave a corona too short to see.

**Board:** no tray and no grid lines. The orbs float on the backdrop.

**Chain beam**
- Drawn under the orbs, center to center, round joins.
- A `beam_glow_width` glow at `beam_glow_alpha` that takes the chained orbs' fill colors along its length.
- A chain core, `chain_width` wide, on top of the glow.
- It also runs to the finger, clamped to the board (3.6).

**Merge preview**
- A small orb with its glow, `preview_scale` of the orb diameter.
- It sits on the gap crossing at the top left of the last chain orb (top right in column 0), clear of the four orbs round it.
- In row 0 that crossing is on the board's top edge, so the preview reaches above the board. That is fine: it stays above the finger, and the board does not clip it.

**Merge, spawn and fall**
- Merge: orbs glide along the beam path into the last orb (`merge_travel`). It blooms to `peak_glow` times its glow and settles (`merge_pop`).
- Spawn: from `from_scale` and transparent, with a bloom of `spawn_bloom` extra glow at the midpoint.
- Fall: cubic ease out.

**Small tile clear (D-38)**
- Every cleared orb dims and shrinks to `to_scale` (`clear`, sine in) while `sparks` sparks in its fill lightened by `ray_lighten`, `spark_size` px across, drift out `spark_reach` of the orb diameter and fade.
- The sparks draw under the orbs, so they show in the gaps and never cross a number.
- Its glow goes out with it.

**Clear notice (AT-104)**
- A badge pill, `notice_height` tall, centered on the board's top edge. Content and padding as Gumdrop (including which values it names and the stars earned part), with `notice_tile_scale` and `notice_strike`, and the text in the label role (lowercase): "no more 2s  +1" and the star.
- Motion: it fades in from `from_alpha` while rising `from_offset` px (`clear_notice`), holds, fades out over `out` on the `screen_fade` curve (3.6). It never blocks input.

**HUD**
- Centered: the score in the display role (light, auto fitting).
- Under it, "best 96,520" in the label role, ink_muted. Its letters start `space_xs` below the score's comma tail (comma depth, 3.4), not below the baseline, so the two never touch. Its baseline sits `space_xs` above the top of the clear notice (centered on the board's top edge, `space_s` under the HUD), so the notice never covers it. The score's digits then start about 11 px below the HUD top.
- The pause icon in a `hud_ring` ring at the top right.

**Star counter (GDD D-45, D-46): the best line**
- The best line becomes one quiet status line: "(star) 4    best 96,520    1 free". The best text stays centered exactly where it was.
- Left of it, ending `space_m` before the best text: the counter star (`star_icon`, centered on the line's cap middle), `space_xs`, the star count in the label role, ink_muted.
- Right of it, starting `space_m` after the best text, while at least one free booster is held: "1 free" (the number held) in the label role, accent.
- *Counter star:* outline in accent, filled in accent from the bottom by count mod 3 (a third, two thirds of its area; the fill line at 36% and 55% of its height), as 4.7. While it holds any fill, a soft accent glow sits behind it: the shared glow texture at `icon_glow_alpha`, radius 0.85 of `star_icon`.
- *Fit:* measured at the 1080 px canvas the line spans 326 to 783 px with "best 412,900" and "1 free". The star reaches 5 px above the letters' cap top, so it keeps 7 px from the score's comma tail. Nothing is placed in the top left: the pause ring keeps the corner to itself, and in the mockups a counter there read as a stray mark.

**Star earned effect (3.6)**
- A spark (the star icon, filled, in accent, `star_icon` box, on a `hairline` edge in badge_ink (3.6), with its glow) rises out of the notice's star `delay` after the notice starts. It fades in from `from_alpha` over the first quarter of `star_earn` and glides on the 4.7 curve to the counter star.
- On arrival the counter star's glow blooms to `peak_glow` times and settles over `merge_pop`'s duration and curve, and the count goes up by one.
- *Conversion:* the counter star blooms to `peak_glow` (`star_convert`). "1 free" fades in from alpha 0 while rising `from_offset` px (or, already shown, its number changes in place), and the star's fill fades to empty over `empty`.

**Booster bar**
- Five ring buttons in a row, no container: `ring_button` across, a `ring_width` ring in line, the icon inside.
- The cost sits under each ring in the label role. The `hint_height` row above holds the hint.
- Looks:
  - *Pressed:* scale `press_scale`, the ring brightens to ink.
  - *Active:* the ring fills accent, glowing accent and accent_violet (`ring_glow_spread`, `ring_glow_alpha`); icon ink_dark, cost accent; `target_pulse` breathing.
  - *Disabled (fixes "does not look disabled"):* the ring is dashed (`disabled_ring_dashes`, each dash `orbit_dash_fill` of its step) at `disabled_ring_alpha`, the icon is disabled_ink at `disabled_icon_alpha`, and the cost is disabled_ink struck through with a `hairline` line. No glow ever. Dashed ring, dim icon and struck cost together read as unavailable without color.
  - *Suggested:* a "suggested" badge rests on the ring: its bottom on the ring's top edge, so it never covers the icon. The ring breathes in accent on `target_pulse`. The badge hides while any booster is active (4.7).
  - *Free (D-46):* the cost line shows the star (filled, box the label size, centered on the cap middle), a gap of 0.25 of the label size, then "free", the group centered under the ring. Accent when normal, pressed or active; disabled_ink when disabled with the `hairline` strike across the whole group. No glow on the small star.
- Hint: centered ink_muted text in the label role, no panel.

**Icons**
- Thin and precise: `icon_stroke` 1.5 on the 24 unit grid, fitted to `icon_fit` of the icon box, round caps, a small spark dot (`icon_spark`) where it suits.
- Active icons are ink_dark (they sit on the accent ring) with a soft accent glow at `icon_glow_alpha`; the ring's own glow carries the light.
- *Star:* five points, one up, slender: center (12, 12.9), outer radius 11, inner radius 0.40 of the outer, points rounded 0.5 units, valleys 0.3. The filled star is the icon; the counter draws its outline band, `icon_stroke` wide, plus the progress fill. Not fitted to `icon_fit`: the star fills its box like a glyph.
- *Chevron:* (10, 6.5) to (15.5, 12) to (10, 17.5), round caps and join.
- *Arrow:* a shaft (5, 12) to (19.5, 12), a chevron head (15.5, 8) to (19.5, 12) to (15.5, 16), round caps, and a spark dot (`icon_spark`) at (2.5, 12), like a tail of light.
- *Coffee* (2026-10-17): an open cup with light rising from it, round caps and joins.
  - Body: one stroke from (5.5, 10) down to (5.5, 15.5), round the bottom on an arc of radius 5 centered at (10.5, 15.5) (lowest point (10.5, 20.5)), and up from (15.5, 15.5) to (15.5, 10). The top stays open.
  - Handle: an arc centered at (15.5, 13.5), radius 2.75, from straight up round the right to straight down (-90 to 90 degrees).
  - Steam: one stroke (9, 7.5) to (9, 4.5), and a spark dot (`icon_spark`) at (12.5, 5), like the arrow's tail of light.
- The chevron, the arrow and the coffee are fitted to `icon_fit` like every Nova icon; only the star fills its box (approved as built, 2026-10-13 review).
- The chevron, arrow and coffee draw in ink_muted.
- Reference: docs/design/additions/nova-icons.png.

**Sound toggle**
- A thin ring track `toggle_w` by `toggle_h` in line.
- Off: a disabled_ink knob on the left.
- On: an accent knob on the right with a glow (`toggle_glow_spread`, `toggle_glow_alpha`), and the track ring turns accent.

**Backdrop**
- A radial glow of bg_glow centered at (`backdrop_glow_x`, `backdrop_glow_y`) of the screen, radius `backdrop_glow_radius` of its width, fading to bg.
- On top, `star_count` star dust dots from the fixed `star_seed`.
- No star is drawn within `star_clearance` px of a rect that holds text (HUD, bar, panels, notice).

**Buttons, panels and chips**
- *Primary:* an accent pill, `radius_button`, ink_dark text. Pressed: accent_pressed.
- *Secondary:* a ring outline pill in line, ink text; pressed fills surface_raised.
- *Chip:* a surface_raised pill; selected fills accent.
- *Sheet panel:* surface, `radius_card` top corners, `space_m` padding.
- *Divider:* a `hairline` line in line.
- *Focus:* a ring in accent `focus_gap` outside.

---

## 7. Shared screen arrangements

Menus and dialogs keep one arrangement for every skin, drawn in each skin's style: its fonts, colors, buttons, panels and motion. In the tables, "panel" means the skin's dialog panel:
- **Gumdrop:** a lipped card, `board_margin` from the sides of the content column (2.8) and from the bottom.
- **Slate:** a sheet as wide as the content column, with a hairline on its open edge.
- **Nova:** a sheet as wide as the content column, with rounded top corners.

On phones the content column is the whole width, so Slate's and Nova's sheets run edge to edge as before. Every arrangement in this section is laid out inside the column (2.8).

Dialog panels anchor to the bottom of the safe area (thumb zone) and come in with `dialog_in` over the skin's scrim. The one exception is the out of moves offer, which takes the HUD's place so the board and the boosters stay visible. Android back closes the top dialog (or cancels targeting first, GDD 13.1).

The copy below is the design's working copy. Where the GDD fixes wording, the GDD wins.

**Alignment.**
- A panel title alone in its row is centered.
- A title that shares its row with something on the right (Settings' close button, the offer's score) is left aligned.
- Slate left aligns every title and text block.
- In Slate every button's text is left aligned, primary and secondary alike; chips center their text.

### 7.1 Play screen frame

- HUD, board and booster bar as in section 2.3, the HUD and the bar laid out in the content column (2.8), the board centered in it.
- The clear notice appears per skin (Gumdrop and Nova over the board's top edge, Slate in the HUD context row).
- **The notice layer (QA6-04, 2026-10-13).** The clear notice and the flying stars draw on a layer of the play screen, above the board and the offer panel and below every dialog. They are not children of the HUD, so they show whether the HUD or the offer panel holds the top of the screen. The HUD still builds, places and animates them.
- The merge preview appears per skin.
- No other overlay ever covers the board during play.

### 7.2 Splash screen (2026-10-14)

The splash replaces the main menu. It shows every time the app opens, and after a run ends (the end of run screen's second button goes here, 7.6). It is the game's front door, so it gets a real arrival: the "SumUp" wordmark drawn in each skin's own style, and under it a chain of the skin's own tiles that sums up: 2, 2, 4 and 8 make 16.

**Arrangement.** Over the backdrop, in the safe area and the content column (2.8), top to bottom:
1. The settings icon button, top right, as before (its face on `board_margin`).
2. The brand block, centered (Slate: left aligned, every part of it):
   - the wordmark (below);
   - Slate only: `space_s`, then the skin's divider (a `hairline` line in line) from margin to margin, a masthead rule;
   - `space_m`, then the **sum row** (below).
3. The records, `space_l` above the buttons, as on the old menu: "Best score" with the number, then a divider and "Best tile" with a mini tile (7.9) once a best tile exists. The Best score number fits its row (QA6-10, as built).
4. The buttons:
   - **Play** (primary), the full width less `board_margin` each side, `button_height` tall;
   - `space_s`;
   - **Info** and **About** (secondary) side by side in one row, sharing that width with `space_s` between them, each `button_height` tall.
   - Play is the one big target, with the two look-up screens under it in the thumb zone. Each half is about 490 px wide (163 dp at 20:9), far above `touch_min`. Slate left aligns the text in all three, as every Slate button (section 7, Alignment).
5. `space_xs`, then the **Buy me a coffee** button (2026-10-17, below), whose `touch_min` tall touch area sits on the bottom of the safe area. It is centered in the column (Slate: its content starts on the content's left edge, under the text of Info). It shows and takes input from the first frame, like the other buttons, and the entrance does not move it.

The free height between the settings button's touch area and the records splits **1 to 1** above and below the brand block (2026-10-17; it was 2 to 3). The coffee row takes 172 px (168 in Slate) out of the free height. Kept at 2 to 3, that would lift the brand block's center to 33.4 to 33.9% of the screen height once a best tile exists, below the 35 to 42% of the 2026-10-13 screens review. At 1 to 1 it stays where Bart approved it on his phone. Worked out from the built splash's own content height at 1080 x 2400 with a 120 / 66 px safe area:

| Skin | Center before (2 to 3, no coffee row), best tile shown | After (1 to 1, coffee row), best tile shown | After, no best tile yet |
|---|---|---|---|
| Gumdrop | 36.7% | 36.5% | 39.5% |
| Slate | 36.4% | 36.3% | 39.1% |
| Nova | 36.3% | 36.1% | 39.0% |

The build is measured against the 35 to 42% range. The two bands are now equal (about 310 to 325 px each at 1080 x 2400 with a best tile): the brand still floats high and the records and buttons still sit as one group in the thumb zone. The bands are not filled with anything. The backdrop's clear rects cover the brand block, the records, the three buttons, the coffee button and the settings button.

**Fit on every screen (2.4, 2.8).**
- *Width:* the canvas is never narrower than 1080 px (a narrower phone, such as the Fold5 cover screen, makes it taller instead), so the content inside the margins is at least 1008 px (Gumdrop) or 992 px (Slate, Nova), and the sum row (902 to 951 px) always fits at its full size. On the Fold5 inner screen and on 16:9 phones the column is wider, and the brand keeps its phone size, centered (Slate: on the column's left margin).
- *Height:* with the coffee row the splash content is about 1,420 to 1,590 px tall (worked out from the built splash: 1,569 to 1,589 px with a best tile), and the shortest supported safe area (16:9 with a 48 dp button bar) is about 2,130 px, so about 540 px stay free for the two spacers. The Fold5 cover screen is taller than 20:9 and has more room.
- *Fallback:* should the free height ever reach zero (a phone outside the 2.4 list), the sum row's tile side shrinks, never below 112 px, and the wordmark follows it, since it is fitted to the row. The records, the buttons and the coffee button never shrink, and the content height the fallback works from counts the coffee row (`space_xs` plus `touch_min`).

**The sum row.** The Info chain row (7.12) at a larger size: one line, everything vertically centered on it:
1. The chain 2, 2, 4, 8, drawn by the skin's own board view as a one row board, all four cells chained in order, no preview and no highlight (`SkinCatalog.make_board_view(skin)`, `setup(skin, 4, 1)`, `set_board`, `set_chain(cells, Vector2(-1, -1))`). So it shows the skin's real chained look and chain line: Gumdrop's rope in its little tray, Slate's ruled line with nodes and label plates, Nova's beam. Tiles 144 px (7.9): width 4 x 144 + 3 x `board_gap` + 2 x `board_padding` (Nova: 4 x 144 / `orb_scale`), height its `preferred_height(width)`.
2. `space_m`, the arrow icon (72 px box, 7.9, ink_muted), `space_m`.
3. The result 16: the skin's tile view (SkinTileView) at 144 px, resting.

Measured with the built board views: the row is 948 px wide in Gumdrop (tray 660 x 180), 902 in Slate (606 x 144) and 951 in Nova (647 x 162). Nothing in it takes input. 2 + 2 + 4 + 8 = 16 exactly, so the row is a true move and it says what the name says.

**The wordmark "SumUp".** One drawn control, the same wherever it appears (the splash and the About screen, 7.13). It replaces the two labels of the 2026-10-13 build.
- *Letters:* "Sum" and "Up", set with no gap in the display role's font, weight and tracking, drawn with `draw_string`. "Sum" in ink, "Up" in accent: the capital U marks the second word, and "Up" in the accent says the game is about going up. Never cased (3.4).
- *Size on the splash:* fitted so the wordmark's drawn width (per skin, below) equals the sum row's width: size = floor(display size x row width / drawn width at the display size), then 1 px smaller until it fits; never below the display size. With the measured rows that is 281 px (Gumdrop), 266 px (Slate, measured in Segoe UI on Windows; Roboto lands within a few px) and 280 px (Nova, counting its star). The cap height, about 0.70 of the size, then stands about 1.3 times the row's tiles.
- *Size on About:* the display role's size, not fitted (7.13).
- *Height:* the font's ascent plus descent at that size, plus Gumdrop's lip.
- *Drawn per skin,* each with an effect built from tokens it already has. None changes a text pair: the faces are ink and accent on the backdrop, pairs every skin lists (4.3, 5.3, 6.3), and Nova's glow has its own pair (6.3).

| Skin | Look |
|---|---|
| Gumdrop | Candy letters with a lip, like its tiles and buttons. Under each face a lip: the same text drawn again at every whole px offset from 1 to d below the face, then the face on top. d = round(0.06 x size): 17 px at 281, 7 px at the About size (120). Lip colors: "Sum" in ink_muted darkened by `lip_darken` (#8B7D97), "Up" in accent_lip (#A9246E). "Up" steps up: its baseline sits round(0.06 x size) above the baseline of "Sum", like a tile lifted for the joinable highlight. The drawn width is the two advances. |
| Slate | Flat and exact: the two words on one baseline, no effect at all. The masthead rule under it belongs to the splash's brand block, not to the wordmark (About already closes its brand block with a rule, 7.13). The drawn width is the two advances. |
| Nova | Light rising from "Up". Behind "Up", the shared glow texture (the one the orbs use, made once) drawn tinted accent, alpha 0.25 at its center, into Up's box (its advance width by the cap height, on the baseline) grown by 0.30 x size on every side. A star after it: the star icon, filled, in accent, its box 0.18 x size, its left edge 0.03 x size after Up's advance, its center on the cap top line (0.70 x size above the baseline), inside the glow, with no glow of its own. The drawn width is the two advances plus 0.21 x size for the star. |

- Built once per size; redrawn only when the skin or size changes (1.5).
- The drawn box includes Gumdrop's lip and Nova's star, so layout and the backdrop's clear rect see the whole wordmark.
- Nova's glow is light, not part of the drawn box: it may reach past the control's rect (by about 0.09 x size to the right of the star and a little above the box). Nothing clips it, and the clear rect stays the drawn box. Star dust under the glow's faint outer edge is accepted: the glow is near 0 there, and a speck at the edge of the light reads as a star near it, not as noise (2026-10-14 review).

**Arrival (entrance).** No new motion: the splash reuses each skin's tokens. It plays each time the splash is shown anew: when the app opens and after a run ends. It does not play when an overlay over the splash closes (Settings, Info, About). On a skin switch the splash is rebuilt at rest, without it (the `skin_switch` cross-fade carries that change).
1. At 0: the brand block (wordmark, Slate's rule, sum row) plays the skin's `dialog_in` with its extras (Motion.dialog_in): Gumdrop rises 240 px with its back ease, so the name springs up; Slate slides up 32 px from alpha 0; Nova fades in from 0.96 scale.
2. The sum row's board view starts empty (every cell 0): Gumdrop's tray shows its slots, Slate its hairline cell frames, Nova nothing. The arrow and the result tile start at alpha 0.
3. At half of `dialog_in`'s duration: the board view's `play_spawn` brings in 2, 2, 4 and 8, in chain order, with the skin's `spawn` and its `stagger`.
4. When `play_spawn` ends: `set_chain` with all four cells, at once (the chain line appears whole), and the arrow and the result fade in together over `screen_fade` (Motion.fade).

That ends near 0.76 s in Gumdrop, 0.38 s in Slate and 1.04 s in Nova. It is decoration: the records and the three buttons show and take input from the first frame, and a tap on Play during it leaves at once (the entrance stops with the splash). The backdrop's clear rects use the brand block's final rect, not its moving one.

**Copy.** Bart's PLAY, INFO and ABOUT, cased like every other button: the copy is "Play", "Info" and "About", set in the body role, which is as written in every skin. Slate sets capitals only in its label and heading roles (5.4), so its buttons read "Play" like its "New game" and "Resume", and Nova's read "Play", not lowercase. The same holds for Info in Pause and Home on the end of run screen, and for "Buy me a coffee" (body role, as written in every skin: never "BUY ME A COFFEE" in Slate, never "buy me a coffee" in Nova).

**The Buy me a coffee button (2026-10-17).** One quiet button, the same on the splash and in About (7.13). It must never compete with Play: no face, no outline, no accent, no lip, no glow, a muted label, and only as wide as its content.
- *Content, on one line, vertically centered:* the coffee icon (4.7, 5.7, 6.7) in a square box the body role's font size (46 px Gumdrop, 44 Slate, 44 Nova), centered on the label's cap middle; a gap of 0.25 of that font size (12, 11, 11 px); then "Buy me a coffee" in the body role, ink_muted (the Theme's MutedLabel). Icon and label are both ink_muted. Content width measured: 388 px (Gumdrop), 374 (Slate, Segoe UI), 363 (Nova).
- *Touch area:* `touch_min` (160 px) tall, and as wide as the content plus `space_s` on each side, so far wider than `touch_min`. The whole area is the target.
- *Look:* the Theme's RowButton look (7.11), the same as a row that opens a screen. At rest nothing is drawn behind it. Pressed, it fills behind its content, reaching `space_s` past it on both sides, over the whole touch height: surface_raised with `radius_chip` corners (Gumdrop, Nova) or surface with square corners (Slate). No scale, no lip, no bounce: it stays quieter than the buttons above it. Focus: the skin's focus look, as RowButton.
- *Never disabled.* No chevron: it does not open a screen in the game.
- *Tap:* the tap rule of a row that opens a screen (7.11): finger down and up on it, moving less than the 24 px deadzone, with no scroll in between. In About's scroll area a drag that starts on it scrolls the page. On the splash there is nothing to scroll, and the same rule holds.
- *What a tap does* (GDD 15.5): it hands one fixed https address, written once in the code, to the phone's system, which opens it in the browser. The address is never shown on screen. If the phone cannot open it, nothing happens and no message shows (GDD BC6). Every tap hands it off exactly once.
- *Its pairs* are listed per skin (4.3, 5.3, 6.3). None is new.

Android back on the splash quits after saving, as it did on the main menu.

- Reference: no mockup (Bart reviews the build on his phone). The 2026-10-13 menu mockups, docs/design/additions/<skin>-menu.png, show the old menu this replaces.

### 7.3 Pause

- Opened by the HUD's pause button or Android back during play.
- A panel with "Paused" (title), **Resume** (primary), **New game** (secondary), **Info** (secondary), **Settings** (secondary). Back resumes.
- Info (2026-10-14, in How to play's place) sits with Settings, the two that look things up, under the two that play. Settings stays last, where it was. Info opens over Pause (7.11), so the run stays paused. The panel's height does not change.
- **Buy me a coffee (2026-10-21, every skin).** The play screen has room for the coffee button only on some phones (7.15), so Pause carries it too, always:
  - *What:* the splash button exactly (7.2): cup icon and "Buy me a coffee" in ink_muted, no face at rest, the RowButton pressed fill, `touch_min` tall, as wide as its content plus `space_s` each side, centered in the panel, the same component, tap rule and hand off. Never a full width button: it stays the quietest thing on the panel.
  - *Where:* last, under Settings, `space_l` below the Settings button (56, 64, 72 px), not the `space_s` between Pause's buttons. It sits as far from Resume and New game as the panel allows, with the two look-up buttons between them, and the wider gap marks it as apart from the panel's actions. A tap meant for Resume or New game cannot reach it.
  - *Panel height:* grows by `space_l` plus 160 px: about 1,130 px (Gumdrop), 1,187 (Slate), 1,224 (Nova) at 1080 x 2400, still well inside every screen. Slate's and Nova's sheets pad it by the bottom inset as before (2.2).
  - *Pairs, none new:* at rest ink_muted on the panel (Gumdrop surface 9.36, Slate bg 7.91, Nova surface 8.89); pressed ink_muted on the RowButton fill (Gumdrop surface_raised 7.32, Slate surface 7.05, Nova surface_raised 7.35). All are listed in 4.3, 5.3 and 6.3 and checked by tools/contrast_check.gd.
  - *Leaving:* a tap opens the browser and the app goes to the background with the run already paused; coming back shows Pause as it was.
- Reference: docs/design/additions/<skin>-pause.png.

### 7.4 New game confirmation (D-34)

- A panel: "Start a new game?" (title), "This run ends here. Its score already counts in your records." (body, muted).
- Buttons: **New game** (primary), **Cancel** (secondary).

### 7.5 Out of moves offer (D-19, D-42)

- The HUD is replaced, in place, by an offer panel. One arrangement for every skin:
  - "Out of moves" (title; Slate uses its accent signal label in capitals), left aligned, with the current score at the right of the same row: the label "Score" over the number in the body role.
  - "Pick a booster to keep this run going." (body, muted).
  - A row with the suggested buy button (primary, for example "Shuffle for 4K") and **End run** (secondary), sharing the width.
- Gumdrop draws it on its lipped card. Slate and Nova draw it with no box, straight on the backdrop: their dialog panel is a bottom sheet, which does not suit a panel at the top.
- The board stays fully visible and may shrink to fit under the taller panel.
- The booster bar stays: every booster with its cost, usable ones in the normal look, the rest disabled.
- The suggested booster (D-42) shows the Suggested badge in the bar:
  - Shuffle if it is usable, otherwise Undo if it is usable. The primary button then buys that booster ("Undo for 2K").
  - If neither is usable, nothing is marked. The panel shows **End run** alone as a primary button, and the text reads "No rescue left. Pick a booster or end the run."
  - While a free booster is held (GDD D-46) Shuffle is always usable, so the offer always opens and marks it, and the buy button reads "Shuffle for free". The bar shows Free on every booster (4.7, 5.7, 6.7). The HUD's star counter is hidden with the HUD; the Free costs carry the news.
- Choosing Hammer, Swap or Double enters targeting. The panel stays, the bar shows the active look, and tapping the active booster returns to the offer.
- **The clear notice while the offer is open (QA6-04).** A booster used from the offer can clear tiles and earn stars (a Double that raises the floor, GDD CL2). The notice must show then too (D-38, D-45). It draws on the notice layer (7.1), in the same place in every skin: centered on the board's top edge, over the seam between the offer panel and the board.
  - *Gumdrop and Nova:* exactly as in play (4.7, 6.7).
  - *Slate:* its context row is gone with the HUD, so the notice becomes a badge bar sized to its content, `space_s` padding each side, the badge height of 7.8 (the label line plus `space_xs` above and below), square corners, centered on the board's top edge. Its lower half covers about the top 7 px of the top row's labels for the notice's hold, which is accepted for a rare moment.
  - *The star moment:* the counter is hidden with the HUD, so the star has nowhere to fly. In Gumdrop and Nova it leaves the notice's star as in play, with its badge_ink edge (3.6), rises `space_l` and fades out over `star_earn` (Gumdrop on its curve, Nova fading from full to 0). It spends most of the rise over the pill, which the edge makes visible; rising further would put it over the offer's buttons. Slate shows only the notice. The counter and the free count show the new values when the HUD comes back, with no effect. A free booster earned this way shows at once on the bar, where every cost turns Free.
  - If the move ends the offer (a rescue), the HUD comes back while the notice may still hold: the notice stays where it is until it ends, and never jumps into Slate's context row.

### 7.6 End of run (D-41)

- A panel over the scrim, the final board dimmed behind it.
- Content:
  - "Run over" (title; Slate: accent signal label).
  - The final score (display, auto fitting).
  - A **New best** badge if this run set the Best Score.
  - Rows, split by the skin's divider: "Best score" with the number, "Best tile" with a mini tile, "This run's highest tile" with a mini tile.
  - **New game** (primary) and **Home** (secondary), which goes to the splash (7.2, GDD D-47). Home replaces Main menu (2026-10-14); same button, same place.
- No stars row (2026-10-13). The star count is worked out from this run's highest tile (GDD D-45: 128K is always 7 stars), so a stars row would repeat the row above it in another unit. A fourth row would also make the panel taller over the dimmed board on 16:9 phones. The stars stay a play time signal; the highest tile is the run's record.

### 7.7 Settings

- A panel:
  - "Settings" (title) with a close icon button.
  - "Sound" row with the toggle.
  - A divider.
  - "Skin" (label role), then three skin choices side by side.
  - A divider, then the **About** row (2026-10-13): a row that opens a screen (7.11), `row_height` tall and never less than `touch_min` (2.7), "About" in the body role, ink, on the left, the chevron icon (`icon_hud` box, ink_muted) on the right edge of the content. The whole row is the touch target. Pressed, it fills behind its content: surface_raised with `radius_chip` corners (Gumdrop, Nova) or surface with square corners (Slate), reaching `space_s` past the content on both sides.
  - The version line (label role, muted, centered; Slate left): "SumUp", followed by the version from `application/config/version` when one is set, cased by the label role (Slate in capitals). It stays: the About screen shows the same version (GDD AT-141).
- Reference: docs/design/additions/<skin>-settings.png.
- **Each skin choice:**
  - A preview swatch in that skin's own bg (`radius_chip` of the current skin), holding tiles 2, 4 and 8 drawn by that skin's own tile component at 72 px.
  - Under it, a chip with the skin's name in that skin's font.
  - A swatch whose bg matches the panel gets a `hairline` edge in line.
  - The current skin's chip shows the selected look.
- Tapping a choice switches the whole game live: the screen cross-fades over `skin_switch` of the new skin, and the setting saves at once.

### 7.8 Badges

Every badge (the hint pill, Suggested, New best) is a pill in badge with badge_ink text in the label role. Its height is the label role's line height plus `space_xs` above and below, and its sides are padded by `space_s`. Gumdrop adds a badge_lip lip. Slate badges have square corners. Nova badges are full pills.

Gumdrop's free pill in the HUD is not a badge in this sense: it is a HUD pill (`pill_height`, body role) in the badge colors, so it lines up with the star and Best pills (4.7).

### 7.9 Fixed component constants

These numbers are the same in every skin and are not tokens. The components hold them as named constants:

| Constant | Value | Where |
|---|---|---|
| Splash sum row tiles (the old menu's decorative tiles were 160) | 144 px side, shrinking to 112 only if a screen has no room | 7.2 |
| Splash sum row arrow | 72 px icon box | 7.2 |
| Record row mini tiles (splash and end of run) | 96 px side (72 until 2026-10-21, 14.1); the rows stay `row_height` tall | 7.2, 7.6 |
| Skin choice preview tiles | 72 px side | 7.7 |
| Skin choice swatch padding | 0.22 of the preview tile side | 7.7 |
| Skin choice swatch hairline edge | 2 px | 7.7 |
| Icon design grid | 24 units, scaled to the icon box | 4.7, 5.7, 6.7 |
| Info example tiles | 112 px side | 7.12 |
| Info example arrow | 56 px icon box | 7.12 |
| Wordmark: Gumdrop lip depth and the step of "Up" | 0.06 of the wordmark size each, rounded | 7.2 |
| Wordmark: Nova glow | alpha 0.25; Up's box grown by 0.30 of the size | 7.2 |
| Wordmark: Nova star | box 0.18, gap 0.03, drawn width added 0.21 of the size; center on the cap top, 0.70 of the size above the baseline | 7.2 |
| Star in the notice and in a Free cost | box = the text role's font size; gap 0.25 of it | 4.7 |
| Coffee icon in the Buy me a coffee button | box = the body role's font size; gap 0.25 of it before the label | 7.2 |
| Reading screen scroll deadzone | 24 px (8 dp, Android's touch slop) | 7.11 |
| Scroll indicator, shortest | 96 px | 7.11 |

### 7.10 Copy for new strings

| Where | Copy |
|---|---|
| Clear notice | "No more {v}s" / "No more {a}s or {b}s" / "No more {low}s to {high}s" (Slate in capitals, Nova lowercase). Only the words are cased: a value and the plural "s" after it are never cased, in any skin (QA21-04, 2026-10-21). Slate reads "NO MORE 2s", "NO MORE 2Ks", "NO MORE 8Qs", "NO MORE 1024s OR 2Ks", "NO MORE 32Qs TO 128Qs"; a capital "S" against a capital suffix ("8QS") would read as a two letter suffix, which GDD 14.1 rules out. The plural "s" follows a value only when its label ends in a digit or a capital: "No more 64Qs", but "No more 64aa" and "No more 128aa to 512aa", because an "s" after a lowercase suffix reads as one more suffix letter ("1as" would read as the label 1as) |
| Suggested badge | "Suggested" |
| New best badge | "New best" |
| Targeting hints | "Tap a tile to smash it" (Hammer), "Tap two tiles to swap them" (Swap), "Tap a tile to double it" (Double) |
| Swap after the first tap | "Now tap the tile to swap with" |
| **2026-10-13 additions** | |
| Pause button (was "How to play", 2026-10-14) | "Info" |
| Wordmark (splash and About) | "SumUp" ("Sum" in ink, "Up" in accent; never cased) |
| Settings row | "About" |
| Clear notice, stars earned | "+{n}" followed by the star icon, after the notice copy (Slate and Nova cased like the copy; digits are not affected) |
| HUD star counter | the count as a number; Slate's caption "Stars" (capitals: "STARS") |
| HUD free boosters held | "{n} free" (Slate "1 FREE", Nova "1 free") |
| Booster cost while a free booster is held | "Free" after the star icon (Slate "FREE", Nova "free"), GDD D-46 |
| Offer buy button while a free booster is held | "{Booster} for free", for example "Shuffle for free" (GDD 13.9) |
| **2026-10-14 splash and Info** | |
| Splash buttons | "Play", "Info", "About" (body role, as written in every skin) |
| End of run, second button | "Home" (was "Main menu") |
| Info | screen title "Info"; the sixteen section titles and texts are GDD 21.2 (IN1 to IN16), word for word |
| About, source code line | "Source code: github.com/bartbasi/sumup" (plain text, not a link; never cased) |
| About, header | "About" |
| About, brand block | "SumUp"; "Version {version}" from `application/config/version` (the line is left out when no version is set); "Made by Bart Basi"; "Copyright 2026 Play, Inc." (exactly, with the comma and the period, never cased; 2026-10-17, was "Copyright 2026 Bart Basi") |
| About, section "What it is" | "SumUp is a number merge puzzle. Join touching tiles of the same number into bigger ones and see how high you can go." |
| About, section "Offline, no data" | "SumUp works fully offline. It collects no data, has no ads or accounts and asks for no permissions. The Buy me a coffee button only opens a web page in your phone's browser, and the game itself sends nothing." (the last sentence added 2026-10-17) |
| About, section "Licenses" | "SumUp is free software: you can share and change it under the GNU General Public License, version 3, with additional terms (see the SumUp license below). Any work based on SumUp keeps its attribution, and changed versions are marked as changed. SumUp comes with no warranty." |
| About, license rows (title, detail) | "SumUp", "GNU GPL version 3, added terms"; "Godot Engine", "MIT license and its parts"; "Outfit font", "SIL Open Font License 1.1" |
| License views, titles | "SumUp license", "Godot Engine", "Outfit font" |
| License views, headings | SumUp: "Notice", "GNU General Public License". Godot: "Godot Engine license", "Third party parts", "Android libraries", "License texts". Outfit: none |
| Godot parts | each copyright line as "Copyright {line}"; each license as "License: {name}" |
| **2026-10-17 Buy me a coffee** | |
| Splash and About button | "Buy me a coffee" (body role, as written in every skin) |
| Play screen button in the side gutter (7.15, QA21-05) | two lines, "Buy me" over "a coffee" (body role, as written in every skin); below the board it is the one line "Buy me a coffee" |
| About, section "Supporting SumUp" | heading "Supporting SumUp"; text, Bart's wording, exactly: "SumUp is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated." |
| License view, a file that cannot be read (missing, or not itself) | "This text could not be read in this copy of SumUp. Installing the game again should bring it back." In the reading role, in place of that file's paragraphs; the headings around it stay (approved as built, 2026-10-13 review) |

The About and license wording covers the legal notices the GPL asks for (a copyright notice, no warranty, that the user may share it under the license, and how to read the license). Bart approved it as written on 2026-10-13. On 2026-10-17 the attribution became "Copyright 2026 Play, Inc." (Bart), the support section was added with Bart's own text, and the "Offline, no data" section gained its last sentence (asked for by the DM; the sentence and the heading "Supporting SumUp" wait for Bart's look at the build).

### 7.11 Reading screens (Info, About, license texts)

One shared full screen frame for everything that is read rather than played. Not a dialog panel: the content is longer than a sheet, so it gets the whole screen and scrolls.

**Frame**
- Full screen and opaque: the skin's backdrop fills the screen. Nova keeps its glow but shows no star dust here: the clear rect is the whole screen, because dust between lines of text reads as specks.
- It opens over whatever opened it: Info over the splash or over Pause, About over the splash or over Settings, a license text over About. What is underneath stays exactly as it was, and closing returns to it.
- The header and the scroll area sit in the content column (2.8): on a wide screen the page is a centered column with the backdrop on both sides, and the scroll indicator sits in the column's right margin.
- It comes and goes with `screen_fade` (alpha 0 to 1 and back), never `dialog_in`: a full screen springing up from below would be heavy.
- Android back closes the top reading screen first (before Pause or Settings underneath). The close button does the same.

**Header** (fixed, does not scroll)
- Inside the safe area, `touch_min` tall.
- The title in the title role, ink, left aligned at `board_margin` (it shares its row with a button, section 7 Alignment), vertically centered.
- The close icon button on the right, inset like the splash's settings button (its face on `board_margin`).
- Slate: a `hairline` divider in line under the header, from margin to margin, like its HUD.

**Scroll area**
- From the header's bottom to the screen's bottom edge, under the gesture bar.
- A ScrollContainer: vertical only (`horizontal_scroll_mode` disabled), `vertical_scroll_mode` RESERVE (the indicator's room is always kept, so text never reflows when it appears), `scroll_deadzone` 24 px (8 dp, Android's touch slop, so a tap never jitters the page), `follow_focus` off. On Android Godot's ScrollContainer scrolls by touch drag with fling inertia; nothing else is needed. On Windows the mouse wheel scrolls.
- Content padding: `board_margin` on the left; on the right the indicator fills the `board_margin`; `space_s` at the top; `space_xl` plus the bottom inset at the end, so the last line clears the gesture bar.
- Every control inside lets drags through to the scroll area (`mouse_filter` pass or ignore), so a drag that starts anywhere, on a tile or a row, scrolls.

**Scroll indicator**
- The VScrollBar look, in each skin's Theme: the bar is `board_margin` wide and fills the right margin; no track and no arrows. The grabber draws `scroll_bar` wide in its middle: a pill (Gumdrop, Nova) or a square ended bar (Slate), in line; while dragged, ink_muted. At least 96 px long.
- It shows where the page is. Dragging the content is the way to scroll; the indicator is not meant as a control.

**Sections**
- The content is a column of sections, all left aligned in every skin (several lines of reading text are easier to read left aligned).
- *Gumdrop:* each section is a lipped card: surface, `radius_card` corners, a surface_lip lip `button_lip` thick, padded `space_m` (the lip added at the bottom). Cards stand `space_s` apart.
- *Slate:* no box. Each section has `space_m` above and below its content, and a `hairline` divider in line separates two sections, like its sheets.
- *Nova:* no box and no lines. Sections stand `space_l` apart on the backdrop.
- Inside a section, top to bottom: the heading (heading role, ink), `space_xs`, the text (reading role, ink_muted, with `reading_line_spacing`), and where there is one, `space_m` and the section's example or rows.

**Text rules**
- Every label wraps (word wrap, breaking a word only when it alone is wider than the line), and none sets a minimum width. Long names must wrap: in the mockups "Bullet Continuous Collision Detection and Physics Library" from Godot's parts list pushed the whole page wider than the screen until it did.
- Reading text runs about 47 to 52 characters a line at 42 px across the 1080 px canvas (936 px inside a Gumdrop card, 992 px elsewhere): the comfortable measure for a phone.

**Rows that open a screen** (About's license rows; also Settings' About row, 7.7)
- `row_height` tall and never less than `touch_min` (160 px, 2.7). On the left the title in the body role, ink, with an optional detail line under it in the label role, ink_muted (names keep their capitals, 3.4). On the right the chevron icon, `icon_hud` box, ink_muted. Rows in a list are split by the skin's divider.
- The whole row is the touch target. Pressed, it fills behind its content as in 7.7.
- Inside a scroll area a row opens only on a tap: finger down and up on the row, moving less than the 24 px deadzone, with no scroll in between. A drag that starts on a row scrolls the page and never opens it.
- The Theme gets a RowButton variation for the row, and a RowDetailLabel variation for the detail line.

**Theme variations** (every skin, built by UiKit.build_theme): HeadingLabel (heading role, ink), ReadingLabel (reading role, ink_muted, `line_spacing` = `reading_line_spacing`), SectionPanel (the section box above), RowButton, RowDetailLabel, and the ScrollContainer and VScrollBar looks. The heading and reading case rules are applied by the screens, like every case rule (section 7, ARCHITECTURE.md section 7).

### 7.12 Info (GDD D-44, rewritten 2026-10-14)

Info replaces How to play everywhere: one full guide to the game, in the reading screen frame of 7.11.

- Opened only by **Info** on the splash (7.2) or in Pause (7.3). Title "Info", in the title role as written in every skin (titles are not cased; Slate's capitals are its label and heading roles).
- Sixteen sections, IN1 to IN16 of GDD 21.2, in order, each title and text word for word, in the 7.11 section layout. The words are the GDD's; this section gives the look.
- It always opens scrolled to the top.

**Example rows.** Two kinds, both under the text after `space_m`, left aligned, one line, everything vertically centered on it. Tiles 112 px and the arrow 56 px (7.9).
- *Chain row* (a chain and its result): as before. The chain drawn by the skin's own board view as a one row board, so the tiles show the skin's real chained look and chain line: `SkinCatalog.make_board_view(skin)`, `setup(skin, n, 1)`, `set_board(values)`, `set_chain(all n cells in drag order, Vector2(-1, -1))`, no preview and no highlight. Width n x 112 + (n - 1) x `board_gap` + 2 x `board_padding` (Nova: n x 112 / `orb_scale`), height its `preferred_height(width)`. Then `space_m`, the arrow icon (ink_muted), `space_m`, and the result: the skin's tile view (SkinTileView) at 112 px, resting. It stands outside the chain's board and after the arrow, which sets it apart; in Gumdrop it also sits on the card, outside the tray.
- *Change row* (one tile that a booster changes, such as Double's 8 then 16): no board view and no chain. The tile before, the skin's tile view at 112 px, resting; `space_m`, the arrow, `space_m`; the tile after, the same way. With no chain line both tiles read as plain tiles, which is right: a booster acts on one tile, it does not chain it.
- The GDD gives the rows: IN1 (2, 2, 4 then 8), IN2 (2, 2, 2 then 4) and IN6 (1024, 1024 then 2K) are chain rows; IN12 (8 then 16, a Double) is a change row. A row with one tile before the arrow is always a change row.
- The rows are illustrations: nothing in them takes input, and a drag on them scrolls.
- The longest chain row the GDD uses (three tiles and the result) is 644 px in Gumdrop, far inside its 936 px card. A chain row may hold up to five tiles (900 px in Gumdrop).

**Booster sections.** A section about one booster leads with that booster's icon, so the player can match the text to the button on the bar:
- The section's content becomes two columns: on the left the booster icon (the bar's own icon for that booster, Hammer, Swap, Shuffle, Double or Undo), in an `icon_hud` box (Gumdrop 64, Slate 72, Nova 72), drawn in ink, with no button face, ring or glow; `space_s`; on the right the heading, the text and any example row, as in 7.11.
- The icon is vertically centered on the heading's first line.
- It is the icon in its normal look: Gumdrop's chunky candy strokes, Slate's signage strokes, Nova's thin strokes fitted to `icon_fit`. Ink on the section's background is a pair every skin lists (Gumdrop ink on surface, Slate ink on bg, Nova ink on bg_glow), and an icon carries no text.
- The text column is narrower by the icon and the gap (88 px in Gumdrop, 92 in Slate, 100 in Nova), about 43 to 49 characters a line: still a comfortable measure.
- Which sections: IN9 Hammer, IN10 Swap, IN11 Shuffle, IN12 Double and IN13 Undo, each with its own booster's icon. IN8 (Boosters, the overview) and every other section have no icon. IN12 has both its icon and its change row: the row sits in the right column under the text, like the text.

**A long page.** Info is several screen heights long (sixteen short sections, 469 words, four with a row: by a rough count about three screen heights at 1080 x 2400). The 7.11 frame holds for that length as it is:
- The ScrollContainer scrolls any length; the scroll indicator shrinks with the page (never under 96 px), so it shows how long the guide is.
- Build it whole before the fade in starts (it is a few dozen labels and four rows, nothing like a license text), and check that the fade runs within 16.7 ms a frame in the desktop window. If it ever does not, build it as 7.14 does: the first screenful before the fade, the rest after it.
- No contents list, no section links and no back-to-top control: the sections follow the order the player meets the rules, and a fling covers the page.
- No GDD length limit applies any more (the old "at most about two screens" was for How to play).

- Reference: no mockup for Info (Bart reviews the build). It looks like docs/design/additions/<skin>-howto.png, with the new title, more sections and the booster icons.

### 7.13 About

- Opened by **About** on the splash (7.2) or by the About row in Settings. Title "About". It shows (GDD AT-141): what the game is, the version, who made it, that it is offline and collects no data, the attribution, and the licenses.
- **Brand block**, on the backdrop in every skin (no card even in Gumdrop: it is the screen's masthead, like the splash's): the wordmark (7.2), drawn in the skin's style (Gumdrop's lip and step, Nova's glow and star) at the display role's size, not fitted; "Version 0.1" in the label role, ink_muted; `space_m`; "Made by Bart Basi" and "Copyright 2026 Play, Inc.", each in the body role, ink; then the source code line (below). The whole block is left aligned at the content's left edge in every skin, like the sections under it (approved as built, 2026-10-13 review).
- **Source code line (2026-10-14).** Right under "Copyright 2026 Play, Inc.", `space_m` below it, the last line of the brand block: "Source code: github.com/bartbasi/sumup" in the body role, ink_muted, left aligned like the rest of the block, in every skin. Plain text: no underline, no accent, no touch, not a link (the game has no network). Never cased, so Slate never sets the address in capitals and Nova never lowers "Source". On one line it measures 866 px (Gumdrop), 830 (Slate, Segoe UI) and 801 (Nova), inside the 1008 and 992 px text width, so it fits a 1080 px canvas. If it ever wraps, it breaks only at the space after "Source code:", never inside the address. Its pair is listed in every skin (ink_muted on bg; Nova on bg_glow). Nothing else in 7.10's approved About wording changes.
- **The attribution (2026-10-17: "Copyright 2026 Play, Inc.", exactly, with the comma and the period).** Measured on one line in the body role it is 525 px (Gumdrop), 493 (Slate, Segoe UI) and 486 (Nova), a few px narrower than the old "Copyright 2026 Bart Basi" (532, 495, 491) and far inside the 1008 and 992 px text width at 1080 px, so it stays on one line in every skin. Never cased: "Play, Inc." keeps its capitals in every skin (3.4).
- **The attribution's weight.** "Copyright 2026 Play, Inc." is a license term (NOTICE, term 1), so it is set like a statement, not like fine print: the body role in ink, the same weight as "Made by Bart Basi", never muted, never in a label role, never cased, never truncated. It sits in the first screenful on every supported phone (about 700 px down a 2400 px screen) and needs no scrolling to find.
- Then four sections (7.11): "What it is", "Offline, no data", "Supporting SumUp" (2026-10-17) and "Licenses", with the copy of 7.10. The Licenses section ends in three rows that open a screen (7.11), one per license, each with its title and detail line (7.10), split by dividers.
- **The support section (2026-10-17).** "Supporting SumUp" is an ordinary 7.11 section in each skin (Gumdrop's card, Slate's ruled section, Nova's open section), with nothing to set it apart: no accent, no badge, no icon by the heading, no larger type. It reads like the sections round it, a calm note rather than a pitch.
  - *Place:* after "Offline, no data" and before "Licenses". That keeps it below the brand block and the attribution, which stay in the first screenful exactly as before, and above the license rows and texts. It follows the sentence that says the button only opens the browser, so the two read together.
  - *Inside, top to bottom:* the heading (heading role, ink; Slate in capitals, "SUPPORTING SUMUP", as every Slate heading: 3.4 lets Slate's capitals apply to a name); `space_xs`; Bart's text in the reading role, ink_muted, with `reading_line_spacing`, word for word (7.10), never cased; `space_xs`; the Buy me a coffee button (7.2). The button's touch area adds about 50 px of its own room above and below its label, so the gap the eye sees from the text to the label is about 60 px.
  - *Alignment:* left aligned in every skin, like every section. The icon's left edge sits on the text's left edge; the pressed fill reaches `space_s` past it into the card's padding (Gumdrop, 36 px) or the page margin (Slate and Nova, 44 px), so it never touches the screen edge or the card edge.
  - Its pairs are listed per skin (4.3, 5.3, 6.3): Gumdrop's label sits on the section card (ink_muted on surface), Slate's and Nova's on the backdrop.
- *Slate:* the brand block counts as its first section, so a `hairline` divider in line closes it before "What it is", as between its other sections: the masthead ends on a rule, like a magazine page. Approved as built (2026-10-13 review; the mockup shows it too). Gumdrop and Nova put nothing between the brand block and the first section.
- Reference: docs/design/additions/<skin>-about.png.

### 7.14 License texts

One reading screen per license, opened from its About row. Title: "SumUp license", "Godot Engine" or "Outfit font".

- The text sits straight on the backdrop in every skin, no card: a card tens of thousands of px tall reads as no card at all. Paragraphs in the reading role, ink_muted, `space_s` apart; headings (7.10) in the heading role with `space_m` above.
- **SumUp license:** "Notice", then the text of NOTICE (the copyright notice, the additional terms and the third party note); then "GNU General Public License", then the text of COPYING. Both files ship in the app (the export already includes them).
- **Godot Engine:** "Godot Engine license", then `Engine.get_license_text()`. Then "Third party parts": for each entry of `Engine.get_copyright_info()`, its name in the body role, ink (wrapping), then for each part each copyright line as "Copyright {line}" and its license as "License: {name}", in the reading role. Then "Android libraries" (2026-10-23): the line "The Android version of SumUp also includes these libraries, which the Godot Engine's Android build adds." in the reading role, then each library the engine's Android build adds and `Engine.get_copyright_info()` does not list, as a part: AndroidX libraries (The Android Open Source Project), Kotlin standard library (JetBrains s.r.o. and Kotlin Programming Language contributors), kotlinx.coroutines (JetBrains s.r.o. and contributors) and JetBrains Java Annotations (JetBrains s.r.o.), each Apache-2.0, and LLVM libc++ (The LLVM Project contributors), Apache-2.0 WITH LLVM-exception. Then "License texts": for each entry of `Engine.get_license_info()`, its name in the body role, ink, then its text. The parts name their licenses (Expat, BSD-3-clause, Zlib and others); the license texts make the names readable in full, which the parts' licenses ask for.
- **Outfit font:** the text of src/design/fonts/OFL.txt.
- **Reflowed for the phone.** These texts are hard wrapped near 72 columns for a terminal. At a readable size a phone line holds about 50 characters, so each 72 column line would wrap into a long line and a short stub. So the text is reflowed: a blank line separates paragraphs; inside a paragraph every line break and every run of spaces becomes one space; nothing else changes, not a character. GDD AT-142 compares each view with its source this way, with whitespace normalized on both sides.
- **Rule lines (2026-10-13 review; waits for the AT-142 change in 10.5).** A rule line is a line that holds three or more of one character, `-`, `=` or `*`, and nothing else but spaces. The texts use them as separators and as underlines under titles: OFL.txt has 2 (around "SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007"), Godot's license texts 37 (29 of dashes, 4 of equals signs, 4 of asterisks), COPYING and NOTICE none. Reflowed as text they join the lines around them, and at the reading size a 59 or 80 character run of dashes is wider than the column, so it wraps into a full line of dashes and a stub (Gumdrop and Nova show a stub of dashes running into `SIL OPEN FONT LICENSE` today). So a rule line ends the paragraph before it, starts a new one after it, and is drawn as the skin's divider (a `hairline` line in line, across the text's width, `space_s` apart from the text like a paragraph) instead of as text. An underlined title such as "Introduction" then stands alone over a rule. Lines that hold other characters too (the asterisk box borders of the MPL text, "*  6. Disclaimer of Warranty  *") stay text.
- **Building the view (2026-10-13 review).** It has to open quickly and scroll at 60 fps: about 37 KB for the SumUp license and more for Godot's. Build it as one label per paragraph, in batches across frames when one frame is not enough, and never as one label of the whole text. While it builds:
  - The first screenful (the paragraphs that fill the scroll area's height) is built before the fade in starts, so the view never fades in onto an empty page and nothing pops in during the fade.
  - The rest builds only after the fade in has ended, so the fade runs at full frame rate.
  - Every frame stays within 16.7 ms in the desktop window, counted over the whole frame (layout and drawing too, not only the time spent making labels). The whole build may take longer; nobody reads the end of Godot's text in the first seconds.
  - The page grows below what the player sees and the scroll indicator shrinks as it grows. That is accepted: it never jumps the visible text.
- Reference: docs/design/additions/<skin>-license.png (Godot's view, whose text needs no file).

### 7.15 Buy me a coffee on the play screen (2026-10-21)

Bart asked for the Buy me a coffee button on the play screen too, never in the way of play. It goes only where the screen already has room that nothing uses; it never moves or shrinks the board, the HUD or the booster bar, and on a phone with no such room it is not shown.

**The button.** The splash button exactly (7.2): the cup icon and "Buy me a coffee" in ink_muted, no face at rest, the RowButton pressed fill, `touch_min` tall, content plus `space_s` each side wide (this one line form goes below the board; the side gutter takes the stacked form below), the same tap rule and hand off, the same component (src/ui/coffee_button.gd). Its color pairs are the splash's (4.3, 5.3, 6.3: ink_muted on bg at rest, on surface_raised or surface pressed); the play screen's backdrop is the splash's, so nothing new. Icon and label, not the icon alone: a lone cup is easy to read as "take a break", while the label says what it does, and the quiet muted look already keeps it from competing with play.

**Where, in this order** (worked out in GameScreen's layout, from the same rects it already places):
1. *Below the board.* The board sits centered in the region between HUD and bar (2.3), so on tall phones there is room between the board's bottom and the bar's top. Call that space D (the slack below the board plus the `space_s` gap above the bar). When D is at least `touch_min` + 2 x `space_s`, the button goes there, in its one line form: centered horizontally in the content column, its touch area centered vertically in D, so it sits the same distance from the board and from the bar, at least `space_s` from each. The drawn content (about 46 px tall) then sits optically centered between the board and the bar. Revised 2026-10-21 after the first build, which centered it in the slack alone and left only 19 px to the board in Gumdrop and Slate: the board side matters most, since that is where a tap meant for the bottom row lands. The space above the board is never used: the merge preview (Gumdrop, Nova), the clear notice and the flying star live there.
2. *Else, in the left side gutter, stacked* (QA21-05, 2026-10-21). On wide screens the content column leaves the backdrop on both sides (2.8). In the gutter the button takes its stacked form, below. It goes there when the gutter (the safe area's left edge to the column's left edge) is at least the stacked touch width (content plus `space_s` each side) plus 2 x `space_m`, so its touch area is at least `space_m` (36, 40, 44 px) clear of the safe edge and of the column. It is centered horizontally in the gutter and vertically on the booster bar's rect. It stays outside the column, so it can never overlap the board, the bar or the HUD.
3. *Else it is not shown.* No icon only form, no shrinking of anything else.

**The stacked form (gutter only).** The one line button needed 414 to 436 px, so on the Fold5 inner screen it fit by only 2 to 31 px, and lost its place in Gumdrop and Nova once the gesture hint was hidden (QA21-05). Stacked, it needs about half the width. Same component, same look, colors, tap rule and hand off; only the content is arranged in a column, everything centered horizontally:
- the cup icon, a square of the body role's font size, centered;
- a gap of `roundi(0.25 x body font size)` (the 7.9 icon gap, now vertical);
- "Buy me", then "a coffee" directly under it (two MutedLabels, body role, as written in every skin, each one line, centered, no extra spacing between them).
- Width: the widest of the icon and the two lines; the touch area reaches `space_s` past it on both sides, like the one line form. Height: the content's height, never less than `touch_min`; the touch area is the full height. Measured (tools/coffee_space.gd): content 168 x 174 px (Gumdrop), 158 x 175 (Slate, Segoe UI; Roboto is narrower), 156 x 167 (Nova); touch areas 216, 198 and 212 px wide, all taller and wider than `touch_min`. Every bar is taller than the button (272, 192, 254 px), so centered on the bar it stays inside the bar's height.
- The pressed fill covers the touch area, as in the one line form.
- The form follows the place at every layout: stacked in the gutter, one line below the board (a fold or unfold can move it between the two).

**Measured** (tools/coffee_space.gd, logical px). Fold5 numbers read from Bart's phone by adb on 2026-10-21: inner screen 1812 x 2176 px, cover 904 x 2316 px, density 420 (2.625), the cover's camera cutout inset 85 px. The phone does not report the gesture hint's own inset, so it is taken as 22 dp (58 px), as in 2.4, and the inner screen's status inset as the cover's 85 px. "No insets" is the bound for every case with smaller bars, immersive mode included: a taller safe area only narrows the gutter (the column follows the safe area's height, 2.8), so this is the worst case the gutter can meet.

| Phone and insets (physical px) | Canvas | D below the board: Gumdrop, Slate, Nova | Left gutter | Result |
|---|---|---|---|---|
| 20:9, 1080 x 2400 at 3.0, status 40 dp, gesture 22 dp | 1080 x 2400 | 43, 39, 86 | 0 | Not shown: the board fills the height, and 160 px would take tiles below 56 dp. With no insets D is 136, 132, 179: still not shown |
| Fold5 cover, top 85, gesture hint 58 | 1080 x 2767 | 234, 230, 277 | 0 | Below the board in every skin (208, 200, 216 needed); the touch area clears the board and the bar by 37, 35 and 59 px |
| Fold5 cover, top 85, hint hidden | 1080 x 2767 | 269, 265, 312 | 0 | Below the board; 54, 52 and 76 px clear |
| Fold5 inner, top 85, gesture hint 58 | 1999 x 2400 | 24, 20, 28 | 438, 438, 414 | In the gutter, stacked, in every skin (288, 278, 300 needed). Touch area 111, 120 and 101 px from the safe edge and from the column |
| Fold5 inner, top 85, hint hidden | 1999 x 2400 | 24, 20, 28 | 418, 418, 394 | In the gutter, stacked; 101, 110 and 91 px clear |
| Fold5 inner, no insets (the bound) | 1999 x 2400 | 24, 20, 28 | 389, 389, 365 | In the gutter, stacked; 87, 96 and 76 px clear |
| Fold5 inner, top 85, taskbar 48 dp (126) | 1999 x 2400 | 24, 20, 28 | 462, 462, 437 | In the gutter, stacked; 123, 132 and 113 px clear |
| 16:9, 1080 x 1920 at 3.0, status 24 dp, button bar 48 dp | 1350 x 2400 | 24, 20, 28 | 149, 149, 125 | Not shown |

So on the Fold5 inner screen the button shows in every skin with the hint shown or hidden and with the taskbar, at least 76 px (26 dp) clear on both sides, and the gutter has 65 to 111 px to spare over the rule even in the bound case. The earlier one line figures (margins of 9, 31 and 2 px with a 40 dp status bar) are replaced.

The rule is checked at layout time, so other shapes fall out of it: a taller phone gets it below the board, a tablet in the gutter, everything else nothing. Phones with smaller system bars than assumed get a little more slack.

**When it shows.** Only on the plain play screen. It is hidden (not just covered) while any of these is open: the out of moves offer, Pause and anything opened from it, targeting (a booster is active), the new game confirmation, the end of run screen. It comes back when they close. Showing and hiding fade on `screen_fade` (alpha only; it ignores input while hidden or fading out). It does not hide during a drag or a move animation: it cannot be reached from one (below).

**Never the tail of a drag.** It reacts only to a touch that went down on it and came up on it, moving less than the 24 px deadzone. A touch that went down on the board (a chain, a cancelled chain, a targeting tap) and is released over the button never triggers it, and neither does a second finger while the first is on the board. Godot gives the release to the control that took the press, which already gives this; GameScreen's tests prove it.

**Leaving the game.** A tap opens the address in the browser, which sends the app to the background like the home button: the run is saved and pauses as it already does on home (GDD 15.1). Nothing else changes.

**Backdrop.** Its rect joins the backdrop's clear rects (Nova's star dust stays off it), like the HUD and the bar.

---

## 8. Hard Stop 1 review fixes

| Review point | Change |
|---|---|
| Small values hard to tell apart (Nova 4 and 8, Nova 32 and 64, Slate 2, 4 and 8) | All three ramps rebuilt as categorical ramps (section 1.3). Each step jumps about 144 degrees round the hue wheel at the lightness where that hue is most vivid, and tiers separate repeats. Nova alternates dark and light orbs. Slate slabs use the hues that stay rich when dark, with alternating lightness. A new script, tools/ramp_check.gd, proves it. Closest neighbors are now 0.19 to 0.21, against 0.07 to 0.12 before. |
| Nova disabled booster not clearly disabled | Dashed ring at 35% alpha, icon at 60% alpha in disabled_ink, cost struck through, never a glow (6.7). |
| Gumdrop 512 to 2K darker than the small tiles | No dark jewel tones any more. Chroma rises by tier: sorbet 2 to 32, candy 64 to 1K, neon with a shine 2K to 32K, special 64K up. The lip grows by tier, so big tiles also stand taller (4.2, 4.7). |
| Slate chain line makes "32" read as crossed out | A label plate of the tile fill covers the whole label box on chained tiles, so the line never shows between glyphs (5.7). |
| Slate sound toggle does not show its state | ON and OFF words inside the track, plus fill and knob position (5.7). |
| Gumdrop below 56 dp at 18:9 | The score caption is dropped, the display goes from 136 to 120, the dock from 208 to 184, the hint row from 120 to 88, gaps from 18 to 16 and tray padding from 22 to 18. Gumdrop now measures 56.9 dp at 18:9 (2.4). |
| Nova below 56 dp at 18:9 (found in the same check) | Display 160 to 148, ring buttons 148 to 136, a 64 px hint row. Nova then measured 57.1 dp (57.7 dp since `orb_scale` 0.89, 2.4). |
| Touch targets at 44 dp on a 360 dp phone | `touch_min` raised from 132 to 144 px (48 dp), and on 2026-10-13 to 160 px (2.7). |

Shared since Phase 1:
- The token names follow one schema (section 3): ink_soft became ink_muted, and divider, rule and ring became line.
- Slate's 128 moved off the vermilion accent hues.
- The joinable highlight, press feedback, Swap selection, clear effect and notice, Suggested badge, pause icon and the shared screens are new.

---

## 9. Launcher icon

Drawn in code by **tools/launcher_icon.gd** (senior-graphic-designer). Run it from the repo root with `godot --path . res://tools/launcher_icon.tscn`. It runs with a window, saves the PNGs and quits.
- The rope, tiles, ring and labels are drawn with `_draw()` into a SubViewport at 4 times the output size with no antialiasing, and every 4 by 4 block is averaged into one pixel (16 samples per pixel, better than MSAA and the same on every renderer).
- The background glow is worked out per pixel.
- It also checks that the foreground stays inside the safe circle (9.2) and writes a review sheet to docs/design/review/launcher-icon-check.png (ignored by git).

### 9.1 Files

The tool writes these to **launcher/** at the repo root, and only this tool writes there. Godot's Android export takes them and scales them to every density itself:

| Export setting | File | Size | Content |
|---|---|---|---|
| launcher_icons/main_192x192 | main_192.png | 192 x 192 | legacy icon: the 72 dp the launcher shows (9.2), background and foreground composited, corners rounded at 22% of the side, transparent outside |
| launcher_icons/adaptive_foreground_432x432 | adaptive_foreground_432.png | 432 x 432 | the foreground layer on transparent |
| launcher_icons/adaptive_background_432x432 | adaptive_background_432.png | 432 x 432 | the background layer, full bleed, opaque |
| launcher_icons/adaptive_monochrome_432x432 | adaptive_monochrome_432.png | 432 x 432 | the foreground silhouettes in white on transparent, for Android 13 themed icons |

The same main_192.png can serve as the project icon. The files are generated, so regenerating them gives the same pixels: two runs write byte for byte identical files.

### 9.2 Geometry

Adaptive icons are 108 by 108 dp. The launcher shows the inner 72 dp (288 px) through a mask shape that always keeps the inner 66 dp circle. At 432 px, 4 px are 1 dp: the safe circle has a radius of 132 px around (216, 216), and everything that matters stays inside it. The tool measures it: the foreground reaches 131.1 px from the center, the monochrome layer 130.4 px.

### 9.3 Design: Gumdrop, the default skin

- **Background:** Gumdrop bg #150820, with a radial glow of surface #2B183D centered at (216, 196), radius 260, fading to bg with a smooth (smoothstep) falloff.
- **Foreground:** two Gumdrop 2 tiles about to merge, joined by the rope.
  - **Tiles:** mint #8FFFD0 faces, side 92, corner radius 0.30, lips 0.075 of the side in the fill darkened 34%. Drawn as in 4.7: the lip is the full 92 px tile shape, the face sits on top of it raised by the lip depth, so the lip shows along the tile's own bottom. Lip and face turn together.
  - **Placement:** tile A is centered at (160, 164) and turned -6 degrees (counter-clockwise); tile B is centered at (272, 268) and turned 5 degrees (clockwise). About 20 px of gap stays between them, and the farthest corner sits about 130 px from the center, inside the safe circle.
  - **Rope:** the white rope #FFF7FC, 24 wide, round caps, from A's center to B's center, drawn under both tiles so it shows in the gap.
  - **Label:** "2" on each tile in Outfit Black (900), 44 px (the 1 character tile label size), #1C0D2B. Its ink box is centered on the face and it turns with the tile.
  - **Ring:** tile B has the chained ring, 5 px #FFF7FC just outside its face, as in 4.7. B is not pressed in: both tiles keep the 0.075 lip.
- **Monochrome:** the two tile silhouettes (lip and face) and the rope in white, the labels cut out (transparent). No ring.
- **Legacy 192:** the 72 dp the launcher shows (the 288 px square around the center) with background and foreground composited, scaled to 192, corners rounded at 22%. So the legacy icon matches the adaptive icon as a launcher shows it, rather than shrinking the art into the 18 dp margins no launcher shows.

It reads as "two equal tiles join" at every launcher size, and its colors match the default skin. The tool reads every color from Gumdrop's SkinData, not from its own copies, and also takes the corner radius (`tile_radius`), the lip darkening (`lip_darken`), the tile font and the label size from it.

**The SumUp rename (2026-10-13).** The icon draws no name, only the two 2 tiles, the rope and the ring, so it needs no change: two equal tiles about to add up suits "SumUp" as well. The name under the icon on the phone is the app's name (`application/config/name`), not part of the image.

---

## 10. The 2026-10-13 additions

Bart added How to play, About, stars and free boosters to v1 on 2026-10-13, and renamed the game SumUp. The GDD rules are D-44 (How to play, section 21), D-45 (stars, 11.5) and D-46 (free boosters, 13.9). This section lists where the design lives and what it adds.

### 10.1 Where it is specified

| Addition | Sections |
|---|---|
| The star moment: timing, several stars, conversion | 3.6 |
| Clear notice: the values that left the window, "+n" and a star | 4.7, 5.7, 6.7 |
| HUD star counter and free boosters held | 4.7 (star pill and free pill), 5.7 (the caption line), 6.7 (the best line) |
| Star earned effect | 4.7, 5.7, 6.7 and the motion tables 4.6, 5.6, 6.6 |
| Free on the booster bar | 4.7, 5.7, 6.7 (Booster bar) |
| New icons: star, chevron, arrow | 4.7, 5.7, 6.7 (Icons) |
| Main menu: SumUp wordmark, How to play | 7.2 |
| Pause: How to play | 7.3 |
| Offer with a free booster | 7.5 |
| End of run: no stars row | 7.6 |
| Settings: About row | 7.7 |
| Reading screens, How to play, About, license texts | 7.11 to 7.14 |
| Copy | 7.10 |
| Launcher icon: no change | 9 |
| QA6-05, tap targets of 48 dp on the Fold5 cover and 18:9 phones, and Nova's orbs at 56 dp there | 2.4 (Nova), 2.7, 4.5, 4.7 (booster touch areas), 5.5, 6.5, 7.11 (rows) |
| QA6-08, the content column on wide screens | 2.8, 4.7 (dock), 7 (panels), 7.1, 7.2, 7.11 |
| QA6-04, the clear notice and the star moment while the offer is open | 3.6, 7.1 (the notice layer), 7.5 |

### 10.2 New tokens for the SkinData resources

Two shared values change in every skin: `touch_min` and `button_height`, from 144 to 160 (2.7). Nova also changes `orb_scale` from 0.88 to 0.89 and `board_gap` from 24 to 22 (2.4).

Every skin gets all of these (values in sections 4, 5 and 6; tools/directions/<id>/tokens.gd already holds them, and the mockups read them from there):

| Kind | Names |
|---|---|
| Type roles (3.4) | heading, reading |
| Numbers (3.5) | star_icon, reading_line_spacing, scroll_bar |
| Motion (3.6) | star_earn, star_convert, with the extras in each skin's table |
| Text pairs (4.3, 5.3) | Gumdrop: badge on surface_raised, badge on surface, accent on bg. Slate: accent on surface. Nova: none |

No new palette colors: the stars use each skin's reward color, badge (Gumdrop) or accent (Slate, Nova).

### 10.3 Lined up with the GDD

- The star count, not progress, is what the HUD shows (D-45: "the HUD shows this run's star count"). The progress to the next free booster, which the lead designer offered as optional, fits in all three skins at no cost in space: it is the fill of the counter's own star. So it is in.
- The free boosters held show whenever at least one is held (D-46), in the HUD, and every cost reads Free, disabled boosters too.
- The notice names the values that left the window and shows on a star move even when no tile was removed (D-45, AT-123).
- The count shows by the time input reopens (D-45); each skin's timing in 3.6 makes sure.
- How to play holds the seven sections word for word, three example rows of real tiles, the result set apart (D-44, AT-115); its length is within two screens.
- About shows the version, so the Settings version line stays (AT-141 compares them).
- The end of run screen gets no stars row; the lead designer suggested one, and 7.6 gives the reasons.

### 10.4 Points that were open (all closed on 2026-10-13)

- **License texts, AT-142.** Closed: the GDD's AT-142 now compares each view with its sources with whitespace normalized on both sides (every run of spaces and line breaks inside a paragraph counts as one space, blank lines mark paragraph breaks), as 7.14 asked. The rule lines of 7.14 need one more line in AT-142 (10.5).
- **Legal wording.** Closed: Bart approved the About and license copy in 7.10 as written.
- **Rename.** Closed: done by the DM. The one mention of numbersgame left, in the wordmark note of 7.2, is about the old name.
- **The Fold5 cover screen's camera hole (QA's Q2).** Closed: on Bart's Fold5 cover screen the camera hole does not cover the score, so nothing changes. The layout rule stands: the HUD's top sits on the safe area's top (2.2), so a phone that reports its hole as a top inset keeps the score clear of it.

### 10.5 The production review of the builds (2026-10-13)

The full review, page by page, is docs/design/briefs/additions-review.md; the fixes go to the builders in docs/design/briefs/<builder>-additions-review.md. Recorded in this document:

| Point | Decision | Section |
|---|---|---|
| Gumdrop's rim and shine as one triangle array each (QA6-02) | Approved; 1.5 reworded to allow it | 1.5 |
| Nova at `orb_scale` 0.89: orbits and joinable rings | Approved; they still read cleanly between the larger orbs | 2.4 |
| Nova's corona rays meeting in the gap between two special orbs | Accepted as a glint between two stars | 6.7 |
| The flying star is invisible on its own pill (Gumdrop lemon on lemon, Nova cyan on cyan) | Fix: an edge in badge_ink | 3.6, 4.7, 6.7, 7.5 |
| The star and Free samples on their own review pages (stars, flight) | Accepted: the play page had no room | |
| Gumdrop's arrow head; Nova's chevron and arrow fitted to `icon_fit` | Approved as built | 4.7, 6.7 |
| Slate's hairline between the About brand block and "What it is" | Approved as built | 7.13 |
| The copy for a license file that cannot be read | Approved as built | 7.10 |
| Rule lines of dashes in the license texts wrap into a line and a stub | Fix: drawn as the skin's divider. Needs AT-142 to say so (below) | 7.14 |
| The Godot license view building over 2.2 to 2.8 s with frames of 29 to 57 ms | The look while it builds is accepted, with three conditions: the first screenful before the fade, the rest after it, frames within 16.7 ms | 7.14 |
| Measured: content column 1,220, 1,221 and 1,269 px on the Fold5 inner screen; brand center 36.6 to 36.8%; How to play 1.41 to 1.56 screen heights; panel heights | Within the spec; recorded | 2.7, 2.8, 7.12 |

**Requested change to the GDD (AT-142, lead-game-designer through the DM).** Add to the unit comparison: "A rule line (a line of three or more of one character, `-`, `=` or `*`, and nothing else but spaces) splits paragraphs in both the view and the source. The view draws it as a divider; the comparison leaves it out, like the headings the view adds." With that line the completeness check (the same number of paragraphs) still holds, because the view and the source split at the same lines.

---

## 11. The 2026-10-14 splash screen and Info

Bart replaced the main menu with a splash screen on 2026-10-14 (GDD D-47), replaced How to play with the Info guide (D-44, rewritten), and added the source code line to About. No mockup round: Bart reviews the build on his phone.

### 11.1 Where it is specified

| Change | Sections |
|---|---|
| Splash: arrangement, fit, sum row, entrance | 7.2 |
| The wordmark drawn in each skin's style (splash and About) | 7.2, 7.13 |
| Nova's wordmark glow pair | 6.3 |
| Pause: Info in place of How to play | 7.3 |
| End of run: Home | 7.6 |
| Sizes | 7.9 |
| Copy | 7.10 |
| Info: example rows, booster icons, a long page | 7.11, 7.12 |
| About: the source code line | 7.13 |

No new tokens, colors, icons or motion names. The SkinData resources do not change. The wordmark uses existing tokens (display role, ink, ink_muted, accent, accent_lip, `lip_darken`, the glow texture, the star icon) and fixed shares of its own size, held as named constants like 7.9.

### 11.2 Who builds what

- **ui-motion-artist (src/design/):** the wordmark as one drawn control with its three skin looks and its fit (7.2), made by UiKit; it replaces the two label wordmark in src/ui/ui_parts.gd. No new icons, no Theme change: the splash and Info use the existing buttons, icons, divider, reading variations and Motion helpers.
- **ui-systems-dev (src/ui/, scenes/ui/):** the splash screen (layout, records, buttons, the entrance sequence with Motion.dialog_in, the board view's `play_spawn` and `set_chain`, and Motion.fade), its wiring in the App, Info (renamed from How to play, with change rows and the booster section icons), the About line, Pause's Info button, the end of run screen's Home button, and the copy.
- **tile-board-artist:** nothing. The board view and tile view are used through their existing API.
- **senior-graphic-designer:** the contrast check gains Nova's glow pair (6.3), and the review of the build.

## 12. The 2026-10-15 color cycle

In a long run Bart saw every tile turn the same near white (Gumdrop gold, Slate paper, Nova white hole), because one beyond color covered every value above 131072. Since 2026-10-15 those values walk round the skin's own ramp instead (3.3), so every value on the board has its own color again.

### 12.1 Where it is specified

| Change | Sections |
|---|---|
| The rule, tile_cycle per skin, the first values, color by cycle and size by value | 3.3 |
| The ramp check now covers every value from 2 to 2^62 | 1.3 |
| The "above" rows and closest pairs of each ramp | 4.2, 5.2, 6.2 |
| Slate: block marks by color, the special frame in the tile's number color | 5.2, 5.7 |
| Nova: the dark rim on every white hole, the glow by value | 6.2, 6.5, 6.7 |

No new colors and no new text pairs: every tile pair is a ramp pair the contrast check already proves.

### 12.2 Who builds what

- **tile-board-artist (src/skins/, tests/skins/):**
  - SkinData: a new `tile_cycle: PackedInt32Array`, checked by validate() (at least 13 entries, each 0 to 16, no repeats). fill_for and ink_for use p(k) of 3.3. beyond_fill and beyond_ink are removed. tier_for does not change.
  - The three .tres files: tile_cycle as in 3.3, beyond_fill and beyond_ink removed.
  - Slate painter: block or slab by ramp position (6 to 16 is a block), not by tier; the special frame in the tile's number color.
  - Nova painter: the dark rim on tiles whose ramp position is that of `dark_rim_from`, not on every value from it. The glow keeps its value based place.
  - Tests: test_skin_api and test_skin_values follow the new fields (tile_cycle against tools/directions/<id>/tokens.gd, the first values of 3.3, the dark rim and the Slate marks on a big slab colored tile).
- **senior-graphic-designer (tools/):** the token mirror (tile_cycle, beyond_fill and beyond_ink gone), ramp_check over 2 to 2^62 including that the skins' fill_for and ink_for follow the rule, contrast_check over every value up to 2^62, and the review of the build.
- **Everyone else:** nothing. Every other place that draws a tile reads fill_for and ink_for.

## 13. The 2026-10-17 copyright line and Buy me a coffee

Bart incorporated as Play, Inc., so the attribution in About reads "Copyright 2026 Play, Inc." exactly ("Made by Bart Basi" stays). The same day he added a quiet Buy me a coffee button at the bottom of the splash and a support section with the same button in About (GDD 15.5). No mockup round: Bart reviews the build on his phone.

### 13.1 Where it is specified

| Change | Sections |
|---|---|
| The attribution, its width, never cased | 3.4, 7.10, 7.13 |
| The splash: the coffee row, the 1 to 1 split, fit, clear rects | 7.2 |
| The Buy me a coffee button: content, touch, look, tap, behavior | 7.2 |
| The coffee icon in each skin | 4.7, 5.7, 6.7 |
| Its color pairs (none new) | 4.3, 5.3, 6.3 |
| Icon box and gap | 7.9 |
| Copy: the button, the support section, the added "Offline, no data" sentence | 7.10 |
| About: the support section and its place | 7.13 |

No new tokens, colors, type roles, Theme variations or motion names. The SkinData resources do not change. The button uses the existing RowButton look and MutedLabel, and every pair it needs is already listed and checked by tools/contrast_check.gd.

### 13.2 Who builds what

- **ui-motion-artist (src/design/):** the coffee icon in the three skins (4.7, 5.7, 6.7), added to SkinIcon's ICON_NAMES. Brief: docs/design/briefs/ui-systems-dev-coffee.md, section "For ui-motion-artist".
- **ui-systems-dev (src/ui/, tests/ui/):** the button on the splash and in About, the support section, the added sentence, the one address constant and its hand off, the attribution text, and the tests. Brief: docs/design/briefs/ui-systems-dev-coffee.md.
- **tile-board-artist:** nothing.
- **senior-graphic-designer:** the review of the build.

## 14. The 2026-10-21 unlimited numbers

Bart reached the 64 bit score limit in real play, so the score now has no fixed size and tiles keep doubling past 2^62, up to a far ceiling of 2^65535 (CLAUDE.md, 2026-10-21; ARCHITECTURE.md 17; GDD D-31, D-32, D-37). Visually that means longer tile labels (up to 5 characters in any real run, 6 near the ceiling), longer scores (15 characters in any real run, 16 near the ceiling) and colors keyed by exponent. Every number below is measured by tools/label_check.gd in each skin's own font, on the 1080 px canvas (the narrowest every phone gets, 2.1) and on each skin's smallest tile of 2.4.

### 14.1 Tile labels

**No new size rule.** Every label is sized by SkinData.tile_font_size as before: the size for its length (5 and 6 characters start from the 4 character size), shrunk until it is no wider than `label_fit` of the side. A smaller suffix (letters drawn below the digit size) was measured and rejected: even at 65% of the digit size it gains only about 2 dp on a 5 character label and still misses 12 dp, too little to pay for a second size on every tile. Raising `label_fit` is not possible either: Gumdrop's lip and corners, Slate's special frame and Nova's orb already set it.

Digit height of the worst label of each kind (the widest suffix letters, "mm" and "mmm"), in dp, on each skin's smallest full spec tile (Gumdrop 56.9, Slate 59.6, Nova 56.3 dp) and smallest 16:9 tile (46.9, 49.3, 48.0 dp):

| Labels | First reached | Gumdrop | Slate | Nova | 16:9: Gumdrop, Slate, Nova |
|---|---|---|---|---|---|
| up to 4 characters, no letter or one capital (2 to 512Q) | always | 12.6 | 12.1 | 12.4 | 10.5, 10.3, 10.6 |
| 3 characters, two letters (1aa) | 2^60 | 14.5 | 13.5 | 13.8 | 12.1, 11.2, 11.7 |
| 4 characters, two letters (16aa) | 2^64 | 11.9 | 11.0 | 11.0 | 9.8, 9.1, 9.4 |
| 5 characters, two letters (128aa) | 2^67 | 10.0 | 9.1 | 9.4 | 8.3, 7.7, 8.0 |
| 4 characters, three letters (1aaa) | 2^5820 | 10.7 | 9.8 | 10.1 | 8.8, 8.2, 8.4 |
| 5 characters, three letters (16aaa) | 2^5824 | 9.3 | 8.4 | 8.4 | 7.6, 7.0, 7.3 |
| 6 characters, three letters (128aaa) | 2^5827 | 8.1 | 7.2 | 7.5 | 6.7, 6.1, 6.3 |

Every label of every kind fits inside `label_fit` with no clipping, on both screen shapes, in all three skins.

**The rule the check holds (tools/label_check.gd):**
- No letter or one capital (every label up to 512Q): digits at least 12 dp on the full spec tile, and the same share of the side on 16:9 (2.4: the same proportions). As before; nothing changes for these labels.
- Two lowercase letters: digits at least 15% of the tile side on every phone (measured: 15% in Slate, 16% in Nova, 17% in Gumdrop for the worst 5 character label). That is 8.5 dp on a 56 dp tile.
- Three letters (from 2^5820, years of play past Bart's run): they fit; no size floor.

**This does not meet GDD 14.1 as written for every 4 character label.** GDD A-1 asks for 12 dp on labels of up to 4 characters, and the 4 character labels with letters (16aa to 64zz, 1aaa to 8zzz) reach only 9.8 to 11.9 dp at the worst pair "mm". The letters take the width the digits had. Meeting 12 dp would need a smaller label set or a larger tile, both outside this design. The recommendation, passed to the lead-game-designer through the DM: the 12 dp floor applies to labels with no suffix letters or one capital, which is every label up to 512Q, and labels with lowercase letters follow the 15% rule above. Until that is settled the label check holds the rule above.

**Casing.** Suffix letters are lowercase in every skin, on tiles and in text, Slate's capitals and Nova's lowercase included (2.5). In Slate a value inside capitals reads "NO MORE 128aa TO 512aa"; the lowercase is what tells a letter suffix from a word, so it stays. The plural "s" belongs to the value and is never cased either (QA21-04): "NO MORE 8Qs", "NO MORE 2Ks", "NO MORE 32Qs TO 128Qs", so a named suffix is always exactly one capital, as GDD 14.1 asks. The lowercase "s" is narrower than "S", so every Slate notice is as wide as before or narrower.

**Where else a label shows:**

| Place | Size | 5 character worst case | Decision |
|---|---|---|---|
| Record row mini tiles: Best tile on the splash, Best tile and this run's highest tile on the end of run | 96 px (was 72) | digits 5.7 dp (Gumdrop), 4.9 (Slate), 5.4 (Nova) | Grown, so a 5 character record reads as large as a 4 character one did at 72 px. The rows stay `row_height` tall (144 to 148 px), so no layout moves |
| Merge preview | `preview_scale` of the tile: 79, 105, 91 px | 4.5, 5.6, 4.9 dp | Kept. It is a glance during a drag, its color is the result's, and the result lands on the board at full size a moment later |
| Clear notice mini tiles | `notice_tile_scale` of `notice_height`: 53, 56, 48 px | 3.1, 3.0, 2.6 dp | Labels of 4 characters or more are not drawn (4.7; from the review of the build on 2026-10-21, where "128aa" was unreadable and the strike crossed it). The tile stays as a color chip with its strike; the notice's text names the same values in the body role ("No more 128aa to 512aa") |
| Info example tiles | 112 px | not reached | The Info rows use fixed small values |
| Booster costs (label role) | 34, 30, 32 px | widest 6 character cost "256mmm" 152, 150, 150 px | Fits the cost line's room (163, 158, 174 px) at full size; no shrink needed |
| Out of moves buy button ("Shuffle for 512aa") | body role | at most two characters longer than today's longest ("Shuffle for 512T") | Fits; the button spans the column |
| Clear notice text | body role | "No more 128aa to 512aa" is no longer than "No more 128Ks to 512Ks" | Fits as today. No plural "s" after a lowercase suffix (7.10) |

### 14.2 Scores

The longest score normal play reaches is 15 characters (10 digits, 3 commas, two letters). Its widest form in each font, "4,444,444,444mm" in Outfit and "1,111,111,111mm" in Segoe UI, fitted as the game fits it, in px:

| Place | Gumdrop | Slate | Nova |
|---|---|---|---|
| HUD score: slot | 1008 | 609 (left of a 15 character BEST column) | 776 |
| HUD score: 13, 15 and 16 characters fit at | 120, 116, 106 | 100, 79, 71 | 121, 95, 86 |
| `display_fit_min` | 76 | 76 (was 96) | 80 |
| HUD Best | The pill's number shrinks to fit beside the star and free pills: 40 px at worst, floor 34 (4.7) | BEST column 363 px in the body role, at full size | "best 4,444,444,444mm" 386 px, 259 px free each side for the counter and the free count |
| End of run score: slot, and 13, 15, 16 characters | 936: 120, 108, 98 | 912: 146, 115, 104 | 904: 141, 111, 101 |
| Record rows (splash, end of run with the New best badge, offer) | 391 px of 472 | 363 of 459 | 359 of 443 |

So every score of up to 15 characters fits every place at or above `display_fit_min`, and a 16 character score fits by shrinking further (2.6). Record rows keep the body size; their existing fit to the row (QA6-10) stays as the guard. The counting up rule is in 2.6.

### 14.3 Colors and the checks

- Colors are keyed by exponent (3.3) and continue to `max_exponent`. No new color and no new text pair: every tile pair is a ramp pair the contrast check already proves.
- Tokens that name a tile value keep their written value: `special_from` (65536, 32768, 32768), Nova's `dark_rim_from` (131072), and color references such as "tile:65536" in text pairs. They all lie inside the ramp, so the code compares exponents with their log2 (special when k is at least 16 in Gumdrop and 15 in Slate and Nova; the dark rim on ramp position 16). No .tres value changes for this.
- tools/number_api.gd lets the three checks follow the change in either order: they detect whether NumberFormat.tile_label and each skin's methods take a value or an exponent. Once both take exponents, the ramp and contrast checks cover every exponent up to `max_exponent`, and the label check every real label from 2^1 to 2^65535.

### 14.4 Where it is specified

| Change | Sections |
|---|---|
| The label rule, sizes for 5 and 6 characters, no casing | 2.5, 3.4, 14.1 |
| The score rule, `display_fit_min` for 15 characters, 16 characters, Best numbers, counting up | 2.6, 3.4, 14.2 |
| Slate `display_fit_min` 76 | 5.4 |
| Gumdrop's HUD Best pill fit | 4.7 |
| Record row mini tiles 96 px | 7.9 |
| The clear notice's plural, its mini tiles without long labels | 4.7, 7.10 |
| The plural "s" never cased, Slate included (QA21-04) | 5.7, 7.10, 14.1 |
| Colors by exponent | 3.3, 14.3 |

### 14.5 Who builds what

Brief: docs/design/briefs/unlimited-numbers.md.

- **tile-board-artist (src/skins/, tests/skins/):** the skin methods by exponent (ARCHITECTURE.md 17) with the color rule of 3.3, value tokens compared by exponent (14.3), Slate `display_fit_min` 76, and the tests.
- **ui-motion-artist (src/design/):** the count up of 2.6, Gumdrop's HUD Best pill fit (4.7), the clear notice plural (7.10) and its mini tiles without labels of 4 characters or more (4.7), and the HUDs and booster bars on BigNum and exponents.
- **ui-systems-dev (src/ui/, tests/ui/):** record row mini tiles at 96 px (7.9) on the splash and the end of run.
- **senior-graphic-designer:** tools/label_check.gd, ramp_check.gd and contrast_check.gd after each wave, and the review of the build.
