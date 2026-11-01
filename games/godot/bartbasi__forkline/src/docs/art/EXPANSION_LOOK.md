# Forkline expansion: the look of regions 5 to 8

Art director, 2026-10-27. Written next to docs/design/EXPANSION.md. Bart approved it as shown on 2026-10-27, with the Snoozer renamed Yawner. The names are now in NAMES.md. Bart also chose that regions 2 to 4 get their own grounds and scenery while play stays the same. That part ("Regions 2 to 4" in section 3) is new, from the same day, and waits for his review. The cast (section 2) and the status marks (section 5) are in src/theme/ since build step A2 (`Silhouettes`, `Palette`). Since build step A3 the 8 grounds, their scenery and the four map features are there too (`MapArt`, with the internal `SceneryArt` and `FeatureArt`, and `Palette`).

The concept art is drawn in code by throwaway scripts that use the same `InkPen` style as src/theme/. The scripts are not committed. The pictures are in `%TEMP%\forkline_expansion\`:

| File | What it shows |
|---|---|
| 1_towers.png | The four new towers at tier 1, tier 2 and both tier 3 paths, in color and in one flat color, each on its region's ground |
| 2_creatures.png | The eight new creatures in color, flat and at true size, and a Snowroller grown to 1.5 times |
| 3_bosses.png | The four new bosses in color and flat |
| 4_whole_cast_flat.png | All 10 towers, 19 creatures and 8 bosses in one flat color |
| 5_map_features.png, 5_map_features_gray.png | Tunnel, bridge, ice slide and stumps with route lines, in color and in grayscale |
| 6_regions.png, 6_regions_deuteranope.png | A 7 x 7 patch of each new region and of Lantern Hill, with towers, creatures, gates and routes; the same as a deuteranope sees it |
| 7_true_size_cover.png | Each region at true size on the Fold5 cover (one cell 129 px), and at one pixel per dp (one cell 48 px) |
| 8_status_marks.png | The marks for the new statuses |
| 9_all_regions.png, 9_all_regions_deuteranope.png | All 8 region grounds side by side, each a 7 x 7 patch with its own era's towers, creatures, a gate and route lines, and its swatches; the same as a deuteranope sees it |
| 9_true_size_regions_2_to_4.png | Millbrook, Willow Fen and Moonspire Keep at true size on the Fold5 cover (one cell 129 px) and at one pixel per dp (one cell 48 px) |

## 1. Names

Checked the way NAMES.md was: does it fit a clear cozy silhouette, does it read right to a player, does it belong to another game, a famous character, a brand or a product, and does it keep the id rules. Every id below matches `^[a-z][a-z0-9_]{0,31}$`, checked by the script, and every display name is 24 characters or fewer.

### One change

| Was | Proposed | Id | Why |
|---|---|---|---|
| Snoozer | Yawner | `yawner` | "Snoozer" reads as a creature that sleeps, which is the Sleepyhead's job. Its job is to make towers doze with a yawn. "Snoozer" and "Sleepyhead" are near synonyms for two different jobs in back to back regions, so players would mix them up. "Yawner" says what it does, matches its card ("Every 4 seconds it yawns ...") and matches Snowsnore, which also yawns. |

### Kept, with a watch note

| Name | Note |
|---|---|
| Flurry | A plain English word, and it reads right: lots of light snowballs. It is also the name of a well known mobile analytics kit and a skill name in some big games. As a common word it is like Skyrocket, so I kept it. Spare: "Snow Shower". |
| Blinker | A plain word (a turn signal, and it blinks). It is one letter from "Blinky", a famous arcade ghost. The creature looks nothing like it, so I kept it. Do not draw it as a small ghost. |
| Glimmertoad | Fine as a name. "Glimmer" sounds like "Gleamer", but Glimmertoad does not dazzle. Its card says what it does. Kept. |
| Scarecrow | A common folk object. Draw a field scarecrow on a post, never a walking straw man with a face like a famous film character. |
| Bramble Cottage, Hollow Lanes | Together they sit near a well known picture book series about mice living in a hedgerow. The names differ and the look must too: no animals in clothes, no homes inside tree trunks or hedges. |
| Starfall (level 8-5) | A plain word, but also a well known spell name in a big online game. Level 8-5 is now "Stone Circle", my spare, which fits Starglen's standing stones (the DM accepted it, 2026-10-27). |

All other names are kept as proposed: Hollow Lanes, Russet Orchards, Frostpine Ridge, Starglen; Bramble Cottage, Wild Bramble, Holly Crown, Scarecrow, Tall Scarecrow, Crow Keeper, Snow Fort, Big Snowball, Moth Lantern, Beacon Lantern, Lantern Garland; Mossbud, Mistwisp, Gleamer, Sleepyhead, Snowroller, Hootling; Burrowbelly, Old Hayrick, Snowsnore; the card ids and names Thorn Tips, Big Hat, Packed Snow, Bright Wick. I found none of them used by another game, character, brand or product, as far as I know.

### Silhouette ideas from EXPANSION.md 10 that I changed

| Who | The idea | Changed to | Why |
|---|---|---|---|
| Gleamer | A star on its belly | A fan of five feathers raised behind it, each with a round gleam | A star on the belly is the mark of a famous picture book's creatures. A raised fan also says "look at me", which is its job. |
| Old Hayrick | A haystack in a straw hat | A haystack with two straw arms raised high and a small sheaf on top | A straw hat would echo the Scarecrow tower in the same region, ours against theirs. The arms also make the shape clearly different from Grumblesack. |
| Mistwisp | A teardrop with a curling tail | A small bean body with a tall curl of mist on its head | Teardrop shapes clashed with the Mossbud. The curl is its shape, and the same curl, small, marks the creatures it hides. |
| Snowroller | A snowball with feet and a face | A little creature running on top of the snowball it rolls | A plain ball with feet was too close to Scamp, Puff and Puffball. The rider reads as "rolls a snowball", and the snowball growing reads as its job. |
| Snowsnore | A shaggy snow beast | A low droopy-eared beast with a big snowball on its back, like a snail's shell | A shaggy beast was too close to Old Tusk. The snowball ties it to the Snowroller. |
| Moth Lantern | Two moths on the tower | Two tiny cream moths as a detail in the light, not part of the shape | Moths are creature shapes. On our tower they stay small, warm and out of the silhouette. |

## 2. Silhouettes

Same rules as THEME.md. Every tower is a lantern-lit building with one signature shape. Each tier adds a stone step, and tier 3 swaps the signature piece while the building stays. Every creature has one body shape. All are warm for ours and cool for theirs, with one ink outline.

### Towers

| Tower | Signature shape (tier 1) | Path A | Path B |
|---|---|---|---|
| Bramble Cottage | A small cottage whose whole roof is a great tangle of thorny bramble, canes drooping to the ground on both sides: a wide bristly crown over a house | Wild Bramble: a wider, spikier tangle with two canes looping over the top | Holly Crown: a rounder holly bush crowned with five spiky holly leaves and red berries |
| Scarecrow | A scarecrow on its post behind a small hut, arms spread in a patched coat, a lantern hanging from one hand: a cross over a house | Tall Scarecrow: raised a little, with a hat half again as wide | Crow Keeper: a crow on each arm, one flapping |
| Snow Fort | A wide wall of warm cream snow bricks with round merlons, a glowing door, a flag at one end and a snowball resting on top | Big Snowball: one huge snowball | Flurry: a stack of six small snowballs |
| Moth Lantern | A lamplighter's booth with a tall post that curls over at the top, a big lantern hanging from the curl: a question mark over a hut | Beacon Lantern: one big lantern standing on a straight post | Lantern Garland: three small lanterns on a string draped from the curl to a short post |

Our snow is warm cream (`SNOW_WARM`). The creatures' snow is blue-white (`CREATURE_SNOWBALL`). So a Snow Fort's snowball and a Snowroller's never share a color.

### Creatures

| Creature | Signature shape |
|---|---|
| Mossbud | A walking flower bud, round below and pointed with a curl at the tip, a frill of two leaves at its middle, moss spots below |
| Mistwisp | A small bean body with a tall spiral of mist rising from its head |
| Gleamer | A plump body with a fan of five feathers raised behind it, each tipped with a round gleam |
| Sleepyhead | A round body in a long floppy nightcap that bends back to a pompom, eyes half shut |
| Snowroller | A small creature, arms out for balance, running on top of a big snowball, a little spray of snow behind. The render scales it up to 1.5 times as it grows. |
| Yawner | A droopy creature with long hanging ears, its mouth open in a yawn, a thick patched quilt over its back trailing to the ground with tassels |
| Blinker | A small upright hopper with a big round head, two huge eyes bulging from its brow, long feet, and a thin tail ending in a four point sparkle |
| Hootling | A small owlish creature standing tall: a narrow egg body, folded wings, a heart-shaped top and a pale face |

### Bosses

| Boss | Signature shape |
|---|---|
| Burrowbelly | A big round digger with a pot belly, a pointed snout and two huge spade paws held out wide, claws first |
| Old Hayrick | A walking haystack with two twisted straw arms raised high, two eyes glowing under a straw fringe, and a small sheaf of seed heads on top |
| Snowsnore | A low, droopy-eared beast with a big snowball on its back like a snail's shell, icicles on its chin, eyes shut |
| Glimmertoad | A huge, low, squat toad with two tall eye bumps, big folded haunches and glowing spots on its back |

### Checked by the script

Same method and limits as tests/theme/test_silhouettes.gd (flat drawings, 40 x 40 masks, intersection over union):

- Every new tower look stays inside its box: within 0.54 of the cell each side, at most 0.86 above the cell center. Every new creature and boss stays inside its box in all 4 frames.
- Closest pairs with a new shape. The test fails at 0.80. The closest pair in the game today is 0.72. No new pair goes above 0.71.

| Towers | | Creatures | | Bosses | |
|---|---|---|---|---|---|
| Bakery and Snow Fort | 0.66 | Gleamer and Sleepyhead | 0.71 | Grumblesack and Burrowbelly | 0.71 |
| Firework Tower and Snow Fort | 0.64 | Mistwisp and Hootling | 0.71 | Ironshell and Burrowbelly | 0.71 |
| Firework Tower and Bramble Cottage | 0.59 | Scamp and Sleepyhead | 0.69 | Old Tusk and Burrowbelly | 0.70 |
| Lullaby Bell and Scarecrow | 0.58 | Mossbud and Hootling | 0.68 | Ironshell and Snowsnore | 0.70 |

- The four looks of each new tower differ (test bar 0.97): Bramble Cottage 0.74, Scarecrow 0.85, Snow Fort 0.93, Moth Lantern 0.72. Snow Fort's tier 1 and tier 2 are the closest pair, because only the step changes, as with every tower.

## 3. Regions

### The rule for every ground

Each new ground keeps about the luminance of Lantern Hill's meadow, so the road, build spots, outlines and route lines keep the contrast they have today. A region looks different by hue and by scenery, never by changing what stands out. Roads stay a light warm sand in every region, so creatures and route lines read the same everywhere.

Two more rules:

- **No buildings inside the map.** Only towers are buildings. Barns, cider sheds and ski huts belong in the backdrop above the map, not on ground cells, so nothing is mistaken for a tower.
- **Nothing glows cool on the ground.** Creatures are cool with glowing pale eyes. So Starglen's toadstools glow warm peach, not teal as EXPANSION.md 2.4 suggests, and its star motes are small dots, never the four point sparkles creatures puff into.

### The four regions

| Region | Ground | Road | Scenery away from roads | Near roads (small and flat only) |
|---|---|---|---|---|
| 5 Hollow Lanes | Deep hedge green `#41592f`, light `#587340`, dark `#33482a` | Sand `#e6c793`, earth bank edge `#76563a`, and a dark bank `#2b3b24` along both sides so the lanes look sunken | Hedge clumps with blackberries and red haws, round trees | Ferns, primroses, haws |
| 6 Russet Orchards | Autumn stubble, amber brown `#655531`, light `#7d6c3b`, dark `#51442a` | Cart track `#e8c99a`, edge `#85603e` | Apple trees with olive-gold crowns and red apples, round hay bales | Fallen russet and amber leaves, apples |
| 7 Frostpine Ridge | Snow at dusk, blue `#4d5f86`, moonlit drifts `#667aa3`, dark `#3d4c70` | Packed snow, warm cream `#efdfc4`, edge `#8a7764` | Snowy pines, snow-capped rocks | Low drifts |
| 8 Starglen | Deep violet moss `#55456a`, light `#716290`, dark `#3f3252` | Pale stone path `#e2cfb2`, edge `#7f6a62` | Standing stones with moss, toadstool rings glowing warm peach | Ferns, a few cream motes |

Two departures from EXPANSION.md 2, both for contrast:

- **Frostpine snow is dusk blue, not blue-white.** A light ground cannot hold a light road: cream on near-white fails 3:1. Snow at dusk is blue in a picture book, and the moonlit drifts and white snow caps keep it reading as snow.
- **Russet Orchards' amber and russet are in the scenery.** The ground is a darker amber brown stubble. A bright warm ground would fight the warm towers and the road.

### Contrast

WCAG 2, from the script. Graphic pairs need 3:1, text 4.5:1. Lantern Hill as it is today, for comparison.

| Pair | Lantern Hill | Hollow Lanes | Russet Orchards | Frostpine Ridge | Starglen |
|---|---|---|---|---|---|
| ROAD on GROUND | 3.91 | 4.81 | 4.57 | 4.86 | 5.64 |
| ROAD on GROUND_LIGHT | 3.08 * | 3.29 | 3.25 | 3.28 | 3.58 |
| ROAD_EDGE on ROAD | 3.04 | 4.10 | 3.54 | 3.27 | 3.33 |
| INK_LINE on ROAD (outlines on the road) | 9.79 | 10.35 | 10.59 | 12.80 | 11.02 |
| INK_LINE on GROUND_LIGHT (outlines on the lightest ground) | 3.31 | 3.15 | 3.26 | 3.90 | 3.08 |
| PAD on GROUND (empty build spot) | 3.96 | 4.61 | 4.28 | 3.76 | 5.07 |
| PLASTER on GROUND (cottage walls) | 5.23 | 6.09 | 5.67 | 4.98 | 6.71 |
| ROUTE on GROUND (flyer's dotted line) | 6.08 | 7.07 | 6.58 | 5.78 | 7.80 |
| TIMBER on ROAD (open gate) | 4.73 | 5.00 | 5.11 | 6.18 | 5.32 |
| TEXT_LIGHT on GROUND (text, if a region color ever sits behind text) | 5.67 | 6.60 | 6.14 | 5.39 | 7.27 |

\* Since step A3. It was 2.96, the one place Lantern Hill was under 3:1, where the road crosses a light grass patch. Step A3 made `MEADOW_LIGHT` a little darker, `#507458` (3.08:1), and the border `#856143`, the same as regions 2 to 4 (ROAD_EDGE on ROAD 3.23:1). Lantern Hill's other ratios in this table are from before; INK_LINE on GROUND_LIGHT is now 3.18. Both changes are hard to see: a color difference of 1.3 and 1.9.

Feature pairs:

| Pair | Ratio |
|---|---|
| INK_LINE on MOUND (tunnel mound outline) | 4.64 |
| THICKET on STONE (dark tunnel mouth in its stone arch) | 7.12 |
| WOOD on ROAD (bridge deck on the road below) | 3.22 |
| INK_LINE on WOOD (deck outline) | 3.29 |
| ICE on GROUND (slide on snow) | 5.12 |
| ICE_EDGE on ICE (slide border) | 3.29 |
| ICE_DEEP on ICE (carved chevrons) | 4.10 |
| INK_LINE on ICE (outlines on a slide) | 13.48 |
| BARK on ROAD (stump on the path), on the road of every region | 3.18 or more |
| INK_LINE on BARK (stump outline) | 3.08 |
| MOON on BARK (crescent and star on a stump) | 4.84 |

Step A3 made `BARK` a little darker than the concept, `#8c603e` instead of `#9a6a45`. The concept passed only on Starglen's road (3.05), but a run map can put stumps on the grounds of regions 5 to 7 too, where it was 2.87 to 2.93. The deck pair WOOD on ROAD holds on the roads of regions 5 to 8 (3.15 to 3.89), the only grounds a bridge can stand on: regions 1 to 4 have no features, and a run map with a feature takes the ground of one of regions 5 to 8. tests/theme/test_grounds.gd checks every pair in this section and the next on each ground where it can show, in normal vision and as a deuteranope sees it.

Flyers fly over the ground, so the ground decides how they stand out. Today's pairs are not 3:1 either: flyers read by their shadow, eyes and outline. For comparison, CREATURE_FLY on the ground is 2.59 on Lantern Hill, and 3.01, 2.80, 2.46 and 3.32 on regions 5 to 8. Frostpine is the one ground a little below today, by 0.13.

Text: no text sits on the map ground. Map labels have an ink outline (TEXT_LIGHT on INK_LINE 14.20), and entrance letters sit on a cream sign (TEXT_DARK on CARD 12.59). Those pairs do not change with the region, so text contrast still passes everywhere.

### Regions 2 to 4

Bart chose on 2026-10-27 that Millbrook, Willow Fen and Moonspire Keep get their own ground colors and scenery. Play does not change. Lantern Hill stays as it is. The rules above hold: each ground keeps about the meadow's luminance, roads stay light warm sand, no buildings inside the map, nothing glows cool on the ground, and THEME.md's warm for ours, cool for theirs and ink outlines.

The pictures are 9_all_regions.png, its deuteranope view, and 9_true_size_regions_2_to_4.png (see the list at the top).

| Region | Ground | Road | Scenery away from roads | Near roads (small and flat only) |
|---|---|---|---|---|
| 2 Millbrook | Water meadow teal `#2d6168`, light `#38757d`, dark `#26535a` | Today's sand `#e2c18e` and pebbles, border `#856143` | Millponds: a dark pool `#24506a` in a darker grass bank, two ripple arcs `#a3cad6`, kingcups `#f2c14e`. Tall narrow poplars `#24483c` and `#356550`. Alder clumps | Water mint tufts, kingcups, meadowsweet `#f3e6d0` |
| 3 Willow Fen | Misty sage grey `#505c57`, light `#616e68`, dark `#444e4a` | The same road and border laid as a boardwalk: two thin seams `#c4a06c` run along the road, no pebbles | Weeping willows `#617556` and `#93a67c` with long open fronds. Peat pools `#29332b` with lily pads `#7f9a55` and a cream flower `#f3d9c4`. Reed clumps `#c3a565` with cattail heads `#6e4b33` | Sedge tufts, marsh marigolds `#f2b544` |
| 4 Moonspire Keep | Old rose stone `#634749`, light `#866164`, dark `#553c3e` | The same road and border | Broken lengths of old wall in `STONE` with ivy `#557a4a`. Clipped yew cones `#2b4636` and `#3b5e47`. Rose bushes `#f0a58f` | Old flagstones `#765759` set flat in the turf, rose petals, tufts |

The castle town, the mills and the river's big bridge are buildings, so they stay off the map, like Russet Orchards' barns. On the map, the town shows in its walls, flagstones and clipped yews.

#### Apart from every other region

Each ground takes a hue no other region uses: teal water meadow, grey-green fen, rose stone. The scenery also differs from regions 5 to 8: Millbrook's dark rippled ponds are nothing like Frostpine's pale ice, Willow Fen's willows and reeds nothing like Hollow Lanes' hedges, and Moonspire's low, wide broken walls nothing like Starglen's tall single standing stones.

Measured as color difference (CIEDE2000, where about 10 is plainly different side by side), the closest pairs of all 8 grounds:

| Pair | Normal vision | Deuteranope |
|---|---|---|
| Lantern Hill and Hollow Lanes (both approved) | 7.8 | 7.7 |
| Millbrook and Willow Fen | 10.9 | 10.2 |
| Lantern Hill and Willow Fen | 11.6 | 6.2 |
| Frostpine Ridge and Starglen (both approved) | 13.5 | 6.8 |
| Lantern Hill and Millbrook | 14.6 | 16.9 |

Every new ground is at least 10.9 from every other ground.

#### Rules special to regions 2 to 4

- **No moons, stars or lanterns in scenery.** A crescent is the stump `P`, the Lullaby Bell and the nap mark. A star is the stump `Q`. Lanterns belong to towers and gates.
- **No mist in the fen.** A curl of mist is the Mistwisp's hidden mark.
- **Water is dark, with arcs.** Ripples are short arcs, never pale dots, which read as eyes. Water never has chevrons, which mean an ice slide.
- **No millstones and no flour sacks.** A round grey stone on grass looks like an empty build spot, and a tied sack looks like the Grumblesack.
- **Walls are broken, with a sloping top.** No merlons, which belong to the Longbow Loft and the Snow Fort.
- **The willow is open strands, not a solid dome.** A solid green dome with a fringe read as a bell, next to the Lullaby Bell. I redrew it with a round crown over a visible trunk and separate hanging fronds.
- **Tall things only away from roads.** Willows, reeds, poplars, yews and walls only grow on ground cells with no road beside them, as on every map today.

#### Millbrook, the region 6 bridge and gates

Millbrook's setting is "river, mills and fords" (DM, 2026-10-27; it was "bridges"), and level 2-4 is "Two Fords". On the map its water is millponds and pools, each inside one ground cell. No water ever touches a road, so no road ever needs a bridge, and no bridge of any kind is drawn on a Millbrook map cell. The river's old stone bridge stays off the map with the mill.

So on the map, three wooden or crossing things can never be mixed up:

| Thing | Where | Look |
|---|---|---|
| The bridge feature (`X`) | Only on an `X` tile: a road tile with a road crossing it. Used in regions 6 to 8 and on run maps, on those regions' grounds (EXPANSION.md 9.3), never on Millbrook's teal ground | A whole-cell plank deck seen from above, boards across it, rails and posts on both long sides, stone feet. One route line runs over it, the other is cut under it |
| A gate | Only on a socket (`G`) | A narrow plank across the road between two lantern posts. An open socket shows a dashed ring, a ghost gate and two stone stubs |
| Willow Fen's boardwalk | Every road in region 3 | Two thin, faint seams that run along the road, never across it. No rails, posts or lanterns. A gate's plank and a deck's boards both lie across the road, so a seam never looks like either |

#### Contrast

WCAG 2, from the script. Every graphic pair passes 3:1 and the text pair 4.5:1, in normal vision and again with both colors as a deuteranope sees them (Machado, Oliveira and Fernandes 2009, full strength).

| Pair | Lantern Hill | Millbrook | Willow Fen | Moonspire Keep |
|---|---|---|---|---|
| ROAD on GROUND | 3.91 | 4.06 | 4.07 | 4.85 |
| ROAD on GROUND_LIGHT | 3.08 * | 3.06 | 3.11 | 3.14 |
| ROAD_EDGE on ROAD | 3.04 | 3.23 | 3.23 | 3.23 |
| INK_LINE on ROAD | 9.79 | 9.79 | 9.79 | 9.79 |
| INK_LINE on GROUND_LIGHT | 3.31 | 3.20 | 3.15 | 3.12 |
| PAD on GROUND | 3.96 | 4.11 | 4.12 | 4.91 |
| PLASTER on GROUND | 5.23 | 5.43 | 5.45 | 6.49 |
| ROUTE on GROUND | 6.08 | 6.31 | 6.33 | 7.54 |
| TIMBER on ROAD | 4.73 | 4.73 | 4.73 | 4.73 |
| TEXT_LIGHT on GROUND (text) | 5.67 | 5.88 | 5.91 | 7.03 |

\* As above: since step A3 Lantern Hill passes too. Its old road border was 2.99:1 for a deuteranope. That is why regions 2 to 4, and now Lantern Hill, use a slightly darker border, `#856143` (3.23:1, and 3.19:1 for a deuteranope). Regions 5 to 8 pass both in both views.

Flyers over the ground (for comparison, as above): CREATURE_FLY is 2.69 on Millbrook, 2.70 on Willow Fen and 3.21 on Moonspire Keep, all above Lantern Hill's 2.59. Over Millbrook's ponds it is 3.34 and over the fen's peat pools 5.07, so the water never hides a flyer.

#### For color blind players

In the deuteranope picture, roads, borders, outlines, build spots, gates, route lines and every creature and tower still read on all 8 grounds. The grounds themselves do not all stay apart: Lantern Hill, Willow Fen and Moonspire Keep all look olive grey (4.3 to 6.2 apart), and Millbrook's teal looks slate blue, close to Starglen (6.1). There the regions differ by scenery: ponds and poplars, willows and reeds, walls and yews. That is fine because the region is never a game signal.

### Tokens

Per region: `GROUND`, `GROUND_LIGHT`, `GROUND_DARK`, `ROAD`, `ROAD_EDGE`, `ROAD_DOT`, plus the scenery colors above. Regions 2 to 4 share `ROAD` and `ROAD_DOT` with Lantern Hill and use the border `#856143`. Features: `MOUND #6c9150`, `MOUND_LIGHT #86a964`; `ICE #d3eaf6`, `ICE_EDGE #5e7fae`, `ICE_DEEP #4f6fa0`; `BARK #8c603e` (see the feature pairs above), `BARK_TOP #d9bf98`. Ours: `THATCH #d2a35a`, `SNOW_WARM #f6efe2`, `HOLLY #4f7d4c`, `CROW #4f3f46`. Theirs: one or two cool fills per new creature, all periwinkle, mint, lilac, slate, teal or blue-white. Since step A2 the cast's tokens are in `Palette`: ours as above plus `SNOW_WARM_SHADE`, theirs as `CREATURE_*` and `BOSS_*` (for example `CREATURE_MOSS`, `BOSS_TOAD`), and `DIRT #856143` for the dug mound. Each body fill is checked against its ink outline at 3:1, except `CROW`: the Crow Keeper's two crows are dark on purpose and read by shape. Since step A3 the region and feature tokens are in `Palette` too. Lantern Hill keeps its names (`MEADOW`, `MEADOW_LIGHT`, `MEADOW_DARK`, `ROAD`, `ROAD_EDGE`, `ROAD_DOT`). The other grounds take a prefix: `MILLBROOK_`, `FEN_`, `KEEP_`, `LANES_`, `ORCHARD_`, `FROST_`, `GLEN_` (for example `FEN_GROUND`, `FROST_ROAD`, `GLEN_STONE`). `Palette.ground_token(region, role)` gives the name for a role, so regions 2 to 4 get Lantern Hill's road. The features' tokens have no prefix: `MOUND`, `ICE`, `BARK` and so on.

## 4. Map features

| Feature | Look | Reads by shape |
|---|---|---|
| Tunnel (`T`) | A grassy mound over the run of tunnel tiles, lighter than the ground, with an ink outline and tufts. The near mouth is a stone arch with a dark opening. The far mouth is a dark slot under the mound's lip. A run going across shows a dark oval mouth in a stone ring at each end. A tunnel is always a straight run of 1 to 4 tiles, never a turn, so its two mouths face each other. | Arches and a hump over the road. The route line goes under the mound and out of the other mouth. |
| Bridge (`X`) | The east-west road crosses on a plank deck as wide as the road's border and longer than the cell, with a rail and posts on both long sides and stone feet at both ends. The north-south road runs underneath and gets a soft shadow below the deck. | The deck cuts the under-route line; the over-route line runs on top of the deck. |
| Ice slide (`^ v < >`) | The road becomes pale ice with a blue border, with two big carved chevrons per tile, as wide as the road, pointing the way. | Chevrons peek out on both sides of the route line and point the same way as its arrows. |
| Hollow stumps (`P`, `Q`) | A wide short stump standing on the road: bark sides, a pale ringed top with a dark hollow, roots, and a big carved crescent (`P`) or five point star (`Q`) on its front in moon cream with a soft glow. | The pair matches by symbol shape, and a crescent never looks like a star. When a walker steps through, a few sparkles show at the stump it entered. |

The grayscale picture shows all four still read with no color at all.

## 5. Marks for the new statuses

| Status | Mark id | Mark |
|---|---|---|
| Hidden (near a Mistwisp) | `hidden` | The Mistwisp's own curl, small, above the head. It teaches the link. |
| Napping | `napping` | Lying on its side with a small crescent moon above. The render lays the creature down |
| Frightened | `fright` | Two small zigzag shiver lines on each side |
| Low (lured flyer) | `low` | It flies just above its shadow, with a pale ring at the shadow |
| Awake (near a Hootling) | `awake` | A small open eye above |
| Dozing tower | `doze` | One big "z" at the tower's top right, inside the tower's box, so it differs from a slowed creature's smaller "z z" |
| Dug under (Burrowbelly) | `dug` | A moving dirt mound with claw tips showing, in place of the creature |
| In a stump | none | A few sparkles around the stump it entered, drawn by the render |

The marks are `Silhouettes.MARKS` and `Silhouettes.draw_mark()` (contract 14.9). The `doze` z sits a little lower than in the concept picture, so it stays inside the tower's box and never reaches past the top of the map.

## 6. Hard to draw readably, and risks

1. **Draw order for bridges and tunnels.** Mounds, decks and stumps need their own layer above the route lines. A walker under a deck must be drawn below the deck, and one on the deck above it. So the render must know whether a walker on a bridge tile is on the over node or the under node. That is a contract question (EXPANSION.md 11.1, point 5 and 6).
2. **A bridge against a closed gate.** Both are wooden boards across a road. The deck spans the whole cell, has rails, carries no lanterns and never sits on a socket, while a gate is narrow with two lantern posts. It reads apart at true size, but watch it on the phone, especially with a gate beside a bridge.
3. **Twin stumps far apart.** Players match them by symbol only. With two pairs on a map, the crescent and star must stay big; at one pixel per dp they still read, but only just. If playtests show trouble, a dotted link between twins during the build phase would help (a suggestion, not in the brief).
4. **Mist in a crowd.** A curl over every hidden creature can clutter a crowded road. The cap of 6 Mistwisps per wave keeps it in check; the render should draw the mark small.
5. **Growth.** A Snowroller at 1.5 times and Snowsnore at 1.5 times are big. Snowsnore at full size covers most of a cell and a half. Fine on the road, but tight next to towers on narrow maps.
6. **Regions for color blind players.** For a deuteranope, Lantern Hill, Hollow Lanes and Russet Orchards all look olive brown (6_regions_deuteranope.png), and so do Willow Fen and Moonspire Keep (9_all_regions_deuteranope.png). Roads, outlines and features still read. The regions then differ by scenery and features, not by ground color. That is acceptable, because the region is never a game signal.
7. **Regions 2 to 4.** Bart chose on 2026-10-27 to give them their own grounds (section 3, "Regions 2 to 4"). The risk there: the fen's boardwalk seams are faint at one pixel per dp, so on a small phone its roads may just look like sand. That is harmless to play.
8. **Ten towers on the build panel.** All ten tier 1 silhouettes are distinct in one flat color (4_whole_cast_flat.png). At card size on the cover screen the Bramble Cottage, Firework Tower and Snow Fort are the three busiest; watch them on the phone.
9. **Burrowbelly's claws** read a little like spikes in the flat drawing. It still reads as a digger in color; watch it in the playtest.
10. **Originality.** Every shape is drawn for Forkline from simple primitives: a bud, a curl of mist, a feather fan, a nightcap, a rider on a snowball, a quilt, a hopper, an owl, a mole, a haystack, a snail-like beast, a toad. No game, film or book character is copied, and none of the names show on screen next to another work's look.
