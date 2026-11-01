# Forkline names

Art director, 2026-10-23. Phase 4. Bart approved this list on 2026-10-24. Code uses the ids.

## How this list was made

- It starts from the names in docs/design/RULES.md. The jobs stay exactly as RULES.md gives them.
- A name changes only where it does not fit a clear cozy silhouette, reads wrong to a player, or belongs to another game. Each change gives its reason.
- Ids are lowercase, `a` to `z`, `0` to `9` and `_`, start with a letter, and are at most 32 characters (contract 2.1). Display names are at most 24 characters.
- The theme slice used its own working names (Watch post, Bakehouse, Flour mill, Lookout, Firework loft, Lantern cottage, Nightling, Dasher, Mites). They are all retired. The slice's "Bakehouse" clashed with the boost tower "Bakery". The dome oven shape now belongs to the Bakery, where it fits.
- Spec order: spec 0 is the first path in the RULES.md tier table and spec 1 the second. `Silhouettes.draw_tower` and `data/stats/towers.json` must use the same order.

## Towers

| Id | Name | Job (RULES.md 5.1) | Silhouette | Change |
|---|---|---|---|---|
| `sling_post` | Sling Post | Quick small hits on one target, walkers and flyers | A plank cabin up on X-braced stilts with a steep peaked roof: a tall "A" | none |
| `pumpkin_catapult` | Pumpkin Catapult | Splash on groups of walkers | A low gabled shed with a long catapult arm rising to one side, a pumpkin in its cup | none |
| `lullaby_bell` | Lullaby Bell | Slows walkers in its ring | A small chapel with an open round arch on top, a big bell hanging in it, a crescent moon on the peak | none |
| `longbow_loft` | Longbow Loft | Long range, heavy arrows that ignore armor | The tallest: a stone column with battlements and a wide bow across the top: a "T" | none |
| `firework_tower` | Firework Tower | Anti air with splash, flyers only | A low cottage with a fan of three finned rockets on the roof: a spiky crown | none |
| `bakery` | Bakery | Makes towers around it attack faster | A wide beehive dome oven with a tall chimney to one side and a glowing mouth | none (takes the slice's dome oven shape) |

## Tier 3 specializations

| Tower | Spec | Id | Name | Silhouette piece | Change |
|---|---|---|---|---|---|
| Sling Post | 0 | `quickshot` | Quickshot | Double peaked roof: two cabins, an "M" on stilts | none |
| Sling Post | 1 | `stone_sling` | Stone Sling | A round boulder in a net on a beam above the roof | none |
| Pumpkin Catapult | 0 | `prize_pumpkin` | Prize Pumpkin | A huge pumpkin in a bigger cup | Was "Great Pumpkin". That is a famous cartoon character's name. A prize pumpkin from the village fair says "the big one" just as well, and it no longer shares "Great" with the bow path. |
| Pumpkin Catapult | 1 | `jam_pot` | Jam Pot | A round jam pot with a tied cloth lid in the cup, drips below | none |
| Lullaby Bell | 0 | `hush_bell` | Hush Bell | A wide, low onion dome over a bigger bell | none |
| Lullaby Bell | 1 | `night_bell` | Night Bell | A tall pointed spire with a star on the tip | none |
| Longbow Loft | 0 | `giant_bow` | Giant Bow | One huge bow, wider than the tower | Was "Great Bow". "Greatbow" is the name of a giant bow weapon class in a famous action game series, the same thing. |
| Longbow Loft | 1 | `triple_bow` | Triple Bow | Three small bows stacked in a fan | none |
| Firework Tower | 0 | `star_bloom` | Star Bloom | Five small rockets in a wide fan | Was "Starburst", the name of a famous slot game and a candy brand. A firework "bloom" is the burst opening like a flower. |
| Firework Tower | 1 | `skyrocket` | Skyrocket | One big rocket standing upright in a launch frame | none |
| Bakery | 0 | `grand_oven` | Grand Oven | Two tall chimneys | none |
| Bakery | 1 | `spice_kitchen` | Spice Kitchen | A pepper mill turret with a round knob in place of the chimney | none |

## Creatures

| Id | Name | Job (RULES.md 6.1) | Silhouette | Change |
|---|---|---|---|---|
| `scamp` | Scamp | Basic | A round fuzzy ball with two pointed ear tufts and big eyes | none |
| `pip` | Pip | Swarm, comes in crowds | A tiny bead with two antennae with glowing tips | none |
| `skitter` | Skitter | Very fast | A lean long-eared runner caught mid-leap | none |
| `flitter` | Flitter | Flyer | A round little body with two scalloped wings held up, like a small bat. Its shadow floats below it | none ("flittermouse" is an old word for a bat, which fits the shape) |
| `shellback` | Shellback | Armor | A wide dome shell with a small head peeking out | none |
| `bubbler` | Bubbler | Bubble blocks one hit | A squat round body holding a bubble wand up over its head | none |
| `puffball` | Puffball | Splits into 3 Puffs | A big scalloped cloud ball with a tiny sprout on top and short feet | none |
| `puff` | Puff | Only comes from a Puffball | A tiny cloud with three bumps on top and no feet | none |
| `mender` | Mender | Heals others | A creature under a wide mushroom cap, holding a leafy staff | none |
| `gatecrasher` | Gatecrasher | Breaks gates | A stocky bruiser with two big curled horns, head down | none |
| `dusk_moth` | Dusk Moth | Armored flyer | A moth with wide plated wings and feathered antennae. Its shadow floats below it | none |

## Bosses

| Id | Name | Region | Silhouette | Change |
|---|---|---|---|---|
| `grumblesack` | Grumblesack | 1 | A huge lumpy sack tied at the top, with a grumpy face and stubby feet | none |
| `ironshell` | Ironshell | 2 | A huge shell with three tall plates along its back | none |
| `moon_moth` | Moon Moth | 3 | A huge moth with long trailing tail streamers and crescent marks | none |
| `old_tusk` | Old Tusk | 4 | A big shaggy beast with two long tusks curving up from its snout | none |

## Regions

| Id | Name | Setting (RULES.md 12.1) | Change |
|---|---|---|---|
| `lantern_hill` | Lantern Hill | The village meadow at dusk | none |
| `millbrook` | Millbrook | River, mills and fords | Was "River, mills and bridges" (DM, 2026-10-27). No bridge is ever drawn on a Millbrook map, and the bridge is now region 6's feature. Level 2-4 is renamed "Two Fords" to match |
| `willow_fen` | Willow Fen | Marsh boardwalks and reeds | none |
| `moonspire_keep` | Moonspire Keep | The old castle town on the hilltop | none |

## For the game designer

- RULES.md needs three renames if this list is approved: Great Pumpkin to Prize Pumpkin, Great Bow to Giant Bow, Starburst to Star Bloom. Jobs and numbers do not change.
- The contract's examples use placeholder ids (`lantern`, `nightling`, `region_1`). The real data files should use the ids above.
- Watch item: "Puff" is both a creature and the word for how every creature vanishes ("puff into sparkles"). The shapes differ, so I kept it. If players mix them up in the playtest, "Puffling" is a spare name.

## Expansion: regions 5 to 8

Bart approved these names on 2026-10-27, with docs/design/EXPANSION.md and docs/art/EXPANSION_LOOK.md, including one change: the Snoozer is now the Yawner (`yawner`). Same rules as above: ids match `^[a-z][a-z0-9_]{0,31}$`, display names are at most 24 characters, and the jobs stay exactly as EXPANSION.md gives them. Spec order: spec 0 is the first path in each EXPANSION.md tier table and spec 1 the second.

### Towers

| Id | Name | Job (EXPANSION.md 4.1) | Silhouette | Change |
|---|---|---|---|---|
| `bramble_cottage` | Bramble Cottage | Thorns hit every walker in its ring, again and again, with no aim | A small cottage whose whole roof is a great tangle of thorny bramble, canes drooping to the ground on both sides: a wide bristly crown over a house | none |
| `scarecrow` | Scarecrow | Creatures in its ring take more damage from every hit | A field scarecrow on its post behind a small hut, arms spread in a patched coat, a lantern hanging from one hand: a cross over a house | none. Draw a field scarecrow on a post, never a walking straw man with a face like a famous film character |
| `snow_fort` | Snow Fort | Rolls a snowball down a straight line, and every walker in it is hit | A wide wall of warm cream snow bricks with round merlons, a glowing door, a flag at one end and a snowball resting on top | none |
| `moth_lantern` | Moth Lantern | Pulls flyers low, so every tower can hit them | A lamplighter's booth with a tall post that curls over at the top, a big lantern hanging from the curl: a question mark over a hut | none. The two moths are a small detail in the light, not part of the shape |

### Tier 3 specializations

| Tower | Spec | Id | Name | Silhouette piece | Change |
|---|---|---|---|---|---|
| Bramble Cottage | 0 | `wild_bramble` | Wild Bramble | A wider, spikier tangle with two canes looping over the top | none |
| Bramble Cottage | 1 | `holly_crown` | Holly Crown | A rounder holly bush crowned with five spiky holly leaves and red berries | none |
| Scarecrow | 0 | `tall_scarecrow` | Tall Scarecrow | Raised a little, with a hat half again as wide | none |
| Scarecrow | 1 | `crow_keeper` | Crow Keeper | A crow on each arm, one flapping | none |
| Snow Fort | 0 | `big_snowball` | Big Snowball | One huge snowball | none |
| Snow Fort | 1 | `flurry` | Flurry | A stack of six small snowballs | none (spare: "Snow Shower") |
| Moth Lantern | 0 | `beacon_lantern` | Beacon Lantern | One big lantern standing on a straight post | none |
| Moth Lantern | 1 | `lantern_garland` | Lantern Garland | Three small lanterns on a string draped from the curl to a short post | none |

### Creatures

| Id | Name | Job (EXPANSION.md 5.1) | Silhouette | Change |
|---|---|---|---|---|
| `mossbud` | Mossbud | Regrows its own health | A walking flower bud, round below and pointed with a curl at the tip, a frill of two leaves at its middle, moss spots below | none |
| `mistwisp` | Mistwisp | Hides the creatures on and beside its tile from aim | A small bean body with a tall spiral of mist rising from its head | none |
| `gleamer` | Gleamer | Dazzles: every tower in range aims at it | A plump body with a fan of five feathers raised behind it, each tipped with a round gleam | none |
| `sleepyhead` | Sleepyhead | Naps once, then gets up with half its health | A round body in a long floppy nightcap that bends back to a pompom, eyes half shut | none |
| `snowroller` | Snowroller | Grows as it walks | A small creature, arms out for balance, running on top of a big snowball. It grows up to 1.5 times its size | none |
| `yawner` | Yawner | Yawns: towers near it doze | A droopy creature with long hanging ears, its mouth open in a yawn, a thick patched quilt over its back trailing to the ground | Was "Snoozer". It read as a creature that sleeps, which is the Sleepyhead's job, and the two names are near synonyms in back to back regions. "Yawner" says what it does and matches its card and Snowsnore, which also yawns |
| `blinker` | Blinker | Blinks 2 tiles ahead | A small upright hopper with a big round head, two huge eyes bulging from its brow, long feet, and a thin tail ending in a four point sparkle | none. Never draw it as a small ghost |
| `hootling` | Hootling | Nothing near it can be slowed | A small owlish creature standing tall: a narrow egg body, folded wings, a heart-shaped top and a pale face | none |

### Bosses

| Id | Name | Region | Silhouette | Change |
|---|---|---|---|---|
| `burrowbelly` | Burrowbelly | 5 | A big round digger with a pot belly, a pointed snout and two huge spade paws held out wide, claws first | none |
| `old_hayrick` | Old Hayrick | 6 | A walking haystack with two twisted straw arms raised high, two eyes glowing under a straw fringe, and a small sheaf of seed heads on top | none |
| `snowsnore` | Snowsnore | 7 | A low, droopy-eared beast with a big snowball on its back like a snail's shell, icicles on its chin, eyes shut | none |
| `glimmertoad` | Glimmertoad | 8 | A huge, low, squat toad with two tall eye bumps, big folded haunches and glowing spots on its back | none |

### Regions

| Id | Name | Setting (EXPANSION.md 6.1) | Change |
|---|---|---|---|
| `hollow_lanes` | Hollow Lanes | Sunken lanes under arching hedgerows | none |
| `russet_orchards` | Russet Orchards | Autumn orchards, hay barns and cart bridges | none |
| `frostpine_ridge` | Frostpine Ridge | A snowy pine ridge with sled runs and ski huts | none |
| `starglen` | Starglen | A glade of glowing toadstools and hollow stumps | none |

### Map features

Map features have no ids. The level grid marks them with tile characters (EXPANSION.md 3.4 to 3.7), and players read them by shape.

| Tile | Name | Region | What it does | Look |
|---|---|---|---|---|
| `T` | Tunnel | 5 | Walkers inside are out of reach | A grassy mound over the road with a stone arch at each mouth. A tunnel is a straight run of 1 to 4 tiles, never a turn |
| `X` | Bridge | 6 | Two roads cross without joining | A plank deck with rails carries the east-west road over the north-south road |
| `^` `v` `<` `>` | Ice slide | 7 | Walkers go only the way the arrow points | Pale ice with a blue border and two big carved chevrons per tile |
| `P` `Q` | Hollow stump | 8 | Twin stumps join two far roads | A wide stump on the road with a carved crescent (`P`) or star (`Q`) |

### For the game designer

- EXPANSION.md uses "Snoozer" and `snoozer`. When its rules move into RULES.md and data/stats/, both become "Yawner" and `yawner`, everywhere, before any data file uses them. Its card line becomes "Every 4 seconds it yawns, and towers right beside it doze for 2 seconds." with no other change.
- Level 8-5 is "Stone Circle" (the DM accepted it, 2026-10-27). Its first name, "Starfall", is a plain word but also a well known spell name in a big online game. Stone Circle fits Starglen's standing stones.
- Level 2-4 is "Two Fords" (DM, 2026-10-27), since no bridge is drawn on a Millbrook map.
