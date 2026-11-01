# Direction 2: Slate

> Phase 1 record of the direction as Bart saw it at Hard Stop 1. The shipping values, including the ramp and sizing changes from the Hard Stop 1 review, are in docs/DESIGN_SYSTEM.md.

**Editorial and exact.** The numbers are the design.

Screens: slate-board.png, slate-targeting.png, slate-gameover.png, slate-settings.png in this folder, and the same four with -outfit for the font comparison.

## Concept

Slate treats the board like a page of a well set newspaper. Small values are dark slate slabs with the number set in a bright color of the same hue; from 128 up a tile lights into a solid block of color with a black number. So the board is calm where the small tiles are and loud exactly where your big tiles are, and you see them first. Corners are almost square, the grid is tight, and regions are split by hairline rules instead of boxes. Numbers sit in the top left corner of each tile, where your thumb does not cover them while you drag. Type is left aligned, with small labels in tracked capitals. Motion is fast and exact: wipes and cuts, nothing bounces.

## Layout (1080 by 2400)

- Header, left aligned: "SCORE" in small capitals over a very large score. On the right a settings icon (three sliders) and "BEST" over the best score.
- Under a hairline, a context row: while dragging it reads "CHAIN 6" with the result as a small tile on the right; in targeting mode it turns into a vermilion bar, "HAMMER: TAP A TILE TO SMASH IT".
- Board almost edge to edge, 44 px from the screen sides, with 10 px gaps and no tray.
- Booster strip, 192 px tall, under a hairline: five equal columns split by vertical hairlines, each with icon, name and cost (as a tile label, 2K). The active booster column fills with paper white. A booster you cannot use has its cost struck through.
- Game over (the no moves offer) takes the header: "OUT OF MOVES" in signal vermilion over the score, best on the right, a hairline, then "Shuffle for 4K" and "End run" side by side. The board stays fully visible below and the strip offers every booster.
- Settings is a sheet of ruled rows that drops from the top over the dimmed board.

## Palette

| Token | Hex | Use |
|---|---|---|
| bg | #0B0C0E | screen background, near black |
| surface | #181A1C | pressed rows and buttons, chip background |
| rule | #36383B | hairlines |
| ink | #F5F2E9 | paper white: text, chain line, active booster fill |
| ink_muted | #A1A5AB | labels, secondary numbers |
| ink_dark | #0E0F12 | text on paper and on color blocks |
| accent | #FA5D36 | signal vermilion: primary button, hint bar, target brackets |
| accent_pressed | #E14D28 | |
| disabled_ink | #7D8085 | booster you cannot afford, cost struck through |
| chain | #F5F2E9 | chain line, nodes, frame on chained tiles |
| chain_edge | #0E0F12 | dark edge on the chain line |
| target | #FA5D36 | corner brackets on the targeted tile |
| scrim | #0B0C0E at 82% | over the board under the settings sheet |

## Tile ramp

One continuous walk around the color wheel. Slabs for 2 to 64, solid blocks from 128.

| Value | Fill | Number | | Value | Fill | Number |
|---|---|---|---|---|---|---|
| 2 green slab | #18460C | #A5EE95 | | 2K mint | #52F0BE | #0E0F12 |
| 4 teal slab | #004447 | #7AEDF3 | | 4K cyan | #41D9F8 | #0E0F12 |
| 8 blue slab | #003C6C | #BADBFE | | 8K periwinkle | #95B6FE | #0E0F12 |
| 16 indigo slab | #3F2D68 | #DAD0FE | | 16K lilac | #D1A9FF | #0E0F12 |
| 32 plum slab | #59224F | #FEC1F0 | | 32K pink | #FD95DC | #0E0F12 |
| 64 oxblood slab | #641F26 | #FEC8C8 | | 64K rose | #FFB3B8 | #0E0F12 |
| 128 coral | #FE9975 | #0E0F12 | | 128K paper | #F5F2E9 | #0E0F12 |
| 256 orange | #FFB66C | #0E0F12 | | above 128K | #F5F2E9 | #0E0F12 |
| 512 yellow | #FFDC4F | #0E0F12 | | | | |
| 1024 lime | #B3EE55 | #0E0F12 | | | | |

From 32K up each block also gets an inner hairline frame. Lowest tile contrast: 8 at 7.86:1.

## Type

System font (Roboto on Android, Segoe UI on Windows), grotesk feel, everything left aligned. See fonts.md for the Outfit comparison.

| Role | Size | Weight | Tracking | Case |
|---|---|---|---|---|
| display (score) | 184 | 700 bold | -6 | as written |
| title | 72 | 700 | -2 | as written |
| body | 44 | 500 | 0 | as written |
| label | 30 | 600 | +4 | CAPITALS |
| tile number, top left | 40% of tile for 1 or 2 characters, 33% for 3, 31% for 4 | 700 | -1 | |

## Shape

Tile corners 6 px. Gaps 10 px. Number inset 11% of the tile side from the top left. Chain line 8 px with a 3 px dark edge and square 24 px nodes, node to node with no tail. It runs under the numbers: on chained tiles each number has a 4 px outline in its tile color, so the line stops cleanly at the glyph. Chained tiles get a 6 px paper frame inside the edge. Target: four 6 px vermilion corner brackets hugging the tile. Buttons radius 4 px. Hairlines 2 px. On a 360 x 800 dp phone the tiles measure 63.5 dp, the largest of the three, because Slate's chrome is the thinnest.

## Motion

Fast, exact cuts with ease out curves and no overshoot. New tiles wipe down from their top edge in 0.14 s, all at once. Falls take 0.16 s. A tile joins the chain in 0.06 s. On merge the chain slides into the last tile (0.12 s) and the result flashes paper white, then cuts to its color (0.16 s). Sheets slide 32 px down from above and fade in (0.24 s), with no scaling. The target brackets hold still.
