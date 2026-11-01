# Direction 3: Nova

> Phase 1 record of the direction as Bart saw it at Hard Stop 1. The shipping values, including the ramp and sizing changes from the Hard Stop 1 review, are in docs/DESIGN_SYSTEM.md.

**Tiles are stars.** Merging is fusion.

Screens: nova-board.png, nova-targeting.png, nova-gameover.png, nova-settings.png in this folder.

## Concept

Round orbs float on deep space with no tray and no grid lines. Their color follows star temperature: small values burn red and orange, mid values run through gold and white into ice blue and deep blue, and from 2K up they become nebula colors. The bigger the value, the wider its glow, so size of light is a second signal next to the number. A chain is a beam of light that runs under the orbs and takes on their colors. On merge the orbs glide along the beam into the last one, which blooms. Type is light and airy, labels are lowercase, and every movement is a slow, smooth glide.

## Layout (1080 by 2400)

- Score centered at the top in a thin, very large numeral, with "best 96,520" small and lowercase under it. Settings is a thin icon in a ring, top right.
- Orbs float straight on the backdrop: a soft violet glow in the upper middle fading to deep space, with a little fixed star dust.
- Boosters are five ring buttons in a row with no container, each with its cost underneath as a tile label (2K). The active one fills with aurora cyan light, its cost turns cyan, a lowercase hint floats above the rings, and a dashed cyan orbit circles the targeted orb.
- Chain preview: a small orb of the result floats in the gap at the top left of the last orb in the chain, clear of its neighbors.
- Game over (the no moves offer): "Out of moves" in light type floats where the score was, with the score under it, a cyan "Shuffle for 4K" pill and an "End run" ring button. The board stays fully visible below and the rings offer every booster.
- Settings slides up as a dark sheet with rounded top corners over the dimmed game.
- Star dust never sits under text.

## Palette

| Token | Hex | Use |
|---|---|---|
| bg | #040819 | deep space, edges and bottom |
| bg_glow | #181942 | lightest point of the backdrop glow |
| star | #FFFFFF | star dust, at most 35% alpha |
| surface | #10162F | settings sheet |
| surface_raised | #1F2646 | rows and chips on the sheet |
| ring | #52628C | ring button outlines, dividers |
| ink | #F7F9FF | main text |
| ink_muted | #ABB7D5 | labels |
| ink_dark | #060C20 | text on bright fills |
| accent | #49EAF2 | aurora cyan: primary button, active booster |
| accent_pressed | #17D0D8 | |
| accent_violet | #9264EF | second aurora color for glows, never behind text |
| disabled_ink | #848C9F | booster you cannot afford |
| chain | #FFFFFF | beam core; the beam glow takes the orb colors |
| target | #49EAF2 | orbit ring on the targeted orb |
| scrim | #040819 at 86% | over the game behind the settings sheet |

## Tile ramp

| Value | Fill | Number | | Value | Fill | Number |
|---|---|---|---|---|---|---|
| 2 red dwarf | #D02D27 | #F7F9FF | | 2K magenta | #BD0DB7 | #F7F9FF |
| 4 flame | #F4741E | #060C20 | | 4K rose | #FE9AC2 | #060C20 |
| 8 amber | #FCAA2B | #060C20 | | 8K aqua | #49E9E0 | #060C20 |
| 16 gold | #F9DF5C | #060C20 | | 16K emerald | #007D51 | #F7F9FF |
| 32 white star | #FDF6D8 | #060C20 | | 32K aurora green | #84DE70 | #060C20 |
| 64 ice | #9FE3FE | #060C20 | | 64K supernova | #FFE0AD | #060C20 |
| 128 sky | #40BEFD | #060C20 | | 128K white hole | #FBFCFE | #060C20 |
| 256 azure | #0B66D6 | #F7F9FF | | above 128K | #FBFCFE | #060C20 |
| 512 indigo | #413DD2 | #F7F9FF | | | | |
| 1024 violet | #7D24D3 | #F7F9FF | | | | |

Glow grows with value: alpha 10% and 1.12 times the orb radius at 2, up to 55% and 1.55 times at 128K. From 32K up each orb also gets corona rays. Lowest tile contrast: 2 at 4.88:1.

## Type

System font (Roboto on Android, Segoe UI on Windows), light for big numbers, semibold on orbs, lowercase labels. See fonts.md for the same board in Outfit.

| Role | Size | Weight | Tracking | Case |
|---|---|---|---|---|
| display (score) | 160 | 300 light | 0 | as written |
| title | 68 | 300 | +1 | as written |
| body | 44 | 400 | 0 | as written |
| label | 32 | 400 | +3 | lowercase |
| tile number | 46% of orb for 1 character, 42% for 2, 37% for 3, 31.5% for 4 | 600 | 0 | |

## Shape

Orb diameter 88% of the cell pitch, 4 px rim in the fill lightened 35%. From 32K, 12 corona rays from 1.08 to 1.24 orb radii. Chain beam: 12 px white core over a 44 px glow at 28%. Chained orbs get an 8 px white rim. Target: a dashed cyan orbit ring 10% outside the orb. Ring buttons 148 px across with a 3 px ring. Settings sheet radius 64 px. Chain preview: an orb 54% of the orb diameter. On a 360 x 800 dp phone the orbs measure 58 dp.

## Motion

Fluid and calm, with sine and cubic curves. Orbs fade and grow in from 55% (0.38 s, 50 ms stagger) with a small bloom of light. A tile joins the chain as its rim lights up (0.16 s). On merge the orbs glide along the beam into the last orb (0.28 s) and it blooms to 1.8 times its glow, then settles (0.48 s). Falls ease out over 0.30 s. The target orbit breathes on a 1.6 s loop. Dialogs fade and settle from 96% scale (0.50 s).
