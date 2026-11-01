# Forkline expansion: regions 5 to 8

Owner: game designer. 2026-10-27. Approved by Bart on 2026-10-27.

Revised the same day after the architect's review against the code, with the DM's decisions: mist covers tiles (5.2), the nap is its own status that sets health when it starts (3.3, 5.2), run packs show each new creature as if new (9.3), and tiers have their own data (9.1). Also pinned: the Snow Fort's line (4.5), the Moth Lantern's lure details (4.6), when the Bramble pulses (4.3), wake and growth details (5.2), the tick order (5.5), tunnels on run maps and run map grounds (3.4, 9.3), and what keeps older saves loading (11.2).

Bart approved this file, as revised, together with docs/art/EXPANSION_LOOK.md. It was updated the same day for his answers and the art director's look:

- The Snoozer is renamed Yawner, id `yawner`, everywhere (Bart). Its job and numbers do not change.
- The daily follows content tiers, option A of 9.4 (Bart). A tier 0 daily is exactly today's daily.
- Regions 2 to 4 (Millbrook, Willow Fen and Moonspire Keep) get their own ground colors and scenery too (Bart). That is art only: play does not change. Lantern Hill keeps today's meadow, and so does a run map with no feature (9.3).
- The art director's silhouettes, grounds and status marks replace my starting ideas (2, 3.7, 4.3 to 4.6, 5.4, 10): dusk blue snow on Frostpine Ridge, toadstools that glow warm peach in Starglen, and no buildings on map cells.
- Level 8-5 is now Stone Circle, the art director's spare name. The art director left that choice to Bart or me (10).
- 3.4 now says what "at most 6" counts, tunnel tiles, and that a tunnel is a straight run with no bend (DM).

docs/design/RULES.md now holds every rule and number of this file, and everyone builds from it. Where the two differ, RULES.md wins. This file keeps the reasons. data/stats/ follows once the contract defines the new fields. Every number here is a starting target for the balance bots, as the first numbers of RULES.md were.

Bart's decision, 2026-10-27: four more campaign regions of six levels each, with more complex pathing, new creatures, new towers and new features. Version 1 launches with all 48 levels. The pace stays as in regions 1 to 4: one new tower per region with two tier 3 paths, two new creatures per region, one boss per region, and one new map feature per region that makes routing more interesting. New towers and creatures join the roguelite and the daily once the player has unlocked them in the campaign.

"RULES 7.3" means section 7.3 of RULES.md. "The contract" means docs/ARCHITECTURE.md.

## Contents

1. Summary
2. Regions 5 to 8
3. Map features
4. New towers
5. New creatures and bosses
6. Campaign plan
7. Stars and unlocks
8. Twists
9. Roguelite and daily
10. Names
11. Engineering impact
12. Bart's answers
13. Suggestions beyond the task

## 1. Summary

| Region | Name | Map feature | Tower | Creatures | Boss |
|---|---|---|---|---|---|
| 5 | Hollow Lanes | Tunnels: walkers inside are out of reach | Bramble Cottage: thorns hit every walker around it | Mossbud (regrows), Mistwisp (hides others from aim) | Burrowbelly |
| 6 | Russet Orchards | Bridges: two roads cross without joining | Scarecrow: creatures in its ring take more damage | Gleamer (draws every tower's aim), Sleepyhead (gets up once) | Old Hayrick |
| 7 | Frostpine Ridge | Ice slides: one-way roads | Snow Fort: hits every walker in a straight line | Snowroller (grows as it walks), Yawner (makes towers doze) | Snowsnore |
| 8 | Starglen | Hollow stumps: twin stumps join two far roads | Moth Lantern: pulls flyers low so every tower can hit them | Blinker (jumps ahead), Hootling (nothing near it can be slowed) | Glimmertoad |

Each region follows the shape of regions 2 to 4: the map feature comes first, on a level with nothing else new. Then the tower, then one creature per level, a level with nothing new, and the boss.

Goals for the expansion:

- More complex pathing comes from rules, not bigger maps. Maps stay 7 columns by 8 to 13 rows, roads one tile wide, four ways only (RULES 3.1, 3.3).
- Every new map rule shows on the map during the build phase, by shape, never by color alone. The route line always shows where walkers will go.
- Each new tower has one job no current tower has. Each new creature has one job no other creature has.
- The shortest open route rule (RULES 7.3) stays the only routing rule. The features change which steps exist, never how a walker picks one.
- No new randomness. Combat stays deterministic.
- The performance budget holds: no new creature adds bodies to the map, except two boss batches.
- Bart's decision at hard stop A stands: no mid-wave gate switch (3.1).

## 2. Regions 5 to 8

All four stay in the cozy storybook dusk of the village and its surroundings. Creatures are mischievous night creatures that pop into sparkles. No blood, nothing scary beyond a gentle storybook shiver, rating Everyone. Each region gets its own ground colors and scenery so it looks different at a glance, while keeping the theme's rules: warm is ours, cool is theirs, ink outlines on everything that matters (docs/art/THEME.md). The art director's grounds are in docs/art/EXPANSION_LOOK.md 3. Only towers are buildings on map cells: barns, sheds and huts stand in the backdrop above the map, so nothing is mistaken for a tower.

Regions 2 to 4 get their own grounds too (Bart, 2026-10-27). That is art only: their maps, waves and rules do not change. Lantern Hill keeps today's meadow.

### 2.1 Region 5: Hollow Lanes (`hollow_lanes`)

- Setting: old sunken lanes between tall hedgerows at the edge of the village. Berry bushes, mossy banks, and grassy mounds where the lanes run under the hedges.
- Look: deep hedge green ground, sandy lanes with a dark bank along both sides so they look sunken, hedges with blackberries and red haws, and round mossy mounds over the tunnels.
- Plays as: hide and seek. Tunnels hide walkers from your towers, the Mistwisp hides its friends from aim, and the boss digs under the road. The answers are gates that keep walkers out of the tunnels, and towers that need no aim.
- Brings: tunnels, the Bramble Cottage, the Mossbud, the Mistwisp, and Burrowbelly.

### 2.2 Region 6: Russet Orchards (`russet_orchards`)

- Setting: autumn orchards on the slopes below the village. Apple trees, hay barns, cider sheds, and cart tracks that cross on wooden bridges.
- Look: a darker amber brown stubble ground, with the amber and russet in the scenery: apple trees with red apples, round hay bales, fallen leaves, and plank bridges with rails. The barns and cider sheds stand in the backdrop.
- Plays as: loops and crossings. Roads cross over each other, so one spot can watch the same road twice. Its creatures are tough in new ways: one draws every shot, one gets up again. The Scarecrow makes every hit count for more.
- Brings: bridges, the Scarecrow, the Gleamer, the Sleepyhead, and Old Hayrick.

### 2.3 Region 7: Frostpine Ridge (`frostpine_ridge`)

- Setting: the snowy pine ridge above the village in winter. Sled runs, ski huts with warm windows, and pine trees heavy with snow.
- Look: snow at dusk, a soft blue with moonlit drifts, snowy pines and snow-capped rocks, packed-snow lanes in a warm cream so roads still read as roads, and ice slides with big carved chevrons. The ski huts stand in the backdrop.
- Plays as: one-way flows. Ice slides let walkers go only one way, so a gate can send them around a whole loop. The Snowroller grows with every tile it walks, which turns "make the road long" into a real trade.
- Brings: ice slides, the Snow Fort, the Snowroller, the Yawner, and Snowsnore.

### 2.4 Region 8: Starglen (`starglen`)

- Setting: a deep glade in the old wood beyond the hills, lit by glowing toadstools, standing stones and starlight. Hollow stumps stand in pairs: walk into one, come out of its twin.
- Look: deep violet moss, grey standing stones with moss, toadstool rings that glow warm peach, and a few small cream motes. Nothing on the ground glows cool, so the cool creatures still stand out.
- Plays as: magic shortcuts and the final exam. Twin stumps join far parts of the map, Blinkers jump ahead, Hootlings stop slows, and the Moth Lantern finally lets ground towers fight flyers.
- Brings: hollow stumps, the Moth Lantern, the Blinker, the Hootling, and Glimmertoad, the final boss.

## 3. Map features

### 3.1 What I weighed

| Candidate | Verdict | Why |
|---|---|---|
| Tunnels: walkers inside are out of reach | Picked, region 5 | Routing does not change at all, so it is the gentlest start. It gives gates a new reason: keep walkers off the tunnel road and on the open road past your towers. |
| Bridges: two roads cross without joining | Picked, region 6 | The only way to make figure eights and loops on a 7 wide grid with one tile roads. One spot can see the same road twice. |
| One-way roads: ice slides | Picked, region 7 | A gate can send walkers around a whole loop with no way back. Refusals and routes get more interesting, and the route line explains them. |
| Paired portals: hollow stumps | Picked, region 8 | Joins far parts of the map, so a route can double back up the map. The hardest to read, so it comes last, once the player trusts the route line. |
| A second base | Not picked | "Exactly one base" runs through flyers, targeting, route lines and the art. It costs a lot and adds less than a fork: gates already choose between the two ends of a road. |
| Switch tiles | Not picked | A switch the player sets in a build phase is a gate with two sockets, which adds little. A switch that creatures trip changes routes during a wave, which breaks "plan in the calm, then watch". |
| Roads that open and close by wave (tides) | Not picked | Routes would change between two waves with no build phase between them after an early call, and the refusal check would have to look ahead. |
| A limited mid-wave gate switch | Not picked | Bart decided at hard stop A: no mid-wave gate switch (CLAUDE.md). The reasons in RULES 19.2 still hold: it turns a calm puzzle into reflex play on a one-thumb screen, and it weakens the Gatecrasher and Old Tusk. |

### 3.2 The shortest open route with the new features

Once approved, this replaces RULES 7.3. Points 1 to 6 change. Everything else in RULES 7 stays.

1. Road tiles are nodes. A bridge tile is two nodes: its north-south road and its east-west road.
2. A step joins two neighbor nodes, north, south, east or west. On a bridge, the north-south node joins only its north and south neighbors, and the east-west node only its east and west neighbors.
3. An ice slide tile has one way out: the way its arrow points. No step goes onto an ice slide tile against its arrow, that is, from the tile its arrow points to.
4. Twin stumps are joined by one more step, both ways.
5. A node is open unless a closed gate stands on it. The distance of an open node is the fewest steps from it to the base along open nodes, using only the steps above. The base has distance 0.
6. A walker standing on a node center picks its next node from the open nodes one step away whose distance is exactly one less than its own. Tie break: south, west, east, north, then the stump step.
7. Unchanged: a walker decides only at tile centers, its first step is from its entrance tile center, breakers walk the same steps as if no gates were placed (RULES 7.7), and a placement is refused when any entrance would have no open route (RULES 7.4). Gates never close during a wave, so a walker always keeps a route.

All four features are fixed parts of the map, with no timer and no chance, so the same inputs still give the same result. Players never need these points in words: the route line always shows the result.

### 3.3 Out of reach

Tunnels, stumps and Burrowbelly's digging share one status.

- A creature that is out of reach cannot be aimed at or hit by any tower. Splash, Bramble rings and Snow Fort lines skip it. Bells and Scarecrows do not reach it.
- A slow or fright it already holds keeps running down as usual.
- Creatures' own effects still work: a Mender still heals it, a Mossbud still regrows, and a Mistwisp out of reach still hides the creatures on and beside its tile.
- It still costs lives at the base, and its wave is not cleared while it is on the map.
- A flyer is never out of reach because of a map feature.
- A nap (the Sleepyhead's and Old Hayrick's) is not this status. It is its own, stricter status (5.2): a napping creature does not move, and heals and regrowth do not reach it either.

### 3.4 Region 5: tunnels

- **Map.** New tile `T`: a road tile under a grassy mound. A tunnel is a straight run of 1 to 4 tunnel tiles, all in one row or all in one column, with no bend, because the mound art reads as straight runs (DM, 2026-10-27). No tunnel tile is a fork or a bend: each tunnel tile has exactly two road neighbors, on opposite sides, in the line of its tunnel. A map has at most 6 tunnel tiles. A tunnel tile is never a gate socket, entrance, base or build spot. No tunnel tile is next to a socket, so a breaker never breaks a gate from inside a tunnel.
- **Routing.** No change. Tunnel tiles are ordinary road and count as steps.
- **Reach.** A walker whose center is inside a tunnel tile is out of reach (3.3).
- **Gates and refusal.** No change.
- **Route line.** Drawn as usual but under the mound, so it goes into one mouth and comes out of the other. Walkers fade out at one mouth and come back at the other.
- **Flyers** fly over tunnels. **Breakers** walk through as usual. A release that begins in a tunnel puts its creatures in the tunnel, out of reach until they walk out.
- **Why it is fun.** A tunnel shortens the road your towers can use, so gates gain a new reason: close the tunnel road and walkers must take the open lane past your towers. A spot that sees a tunnel mouth becomes precious.
- **Why it reads on a phone.** A mound with an arched mouth at each end is a familiar picture. Creatures vanish under it and come out the other side. Nothing new to tap.
- **Level guide.** Tunnels hold at most a quarter of the steps of any entrance's shortest route with no gates. On 5-1 the hint points at the socket that closes the tunnel road. The rule that no tunnel tile is next to a socket holds on every run map too: tests check it on every stack of segments (9.3), since a tunnel in one segment can meet a socket across a seam.

### 3.5 Region 6: bridges

- **Map.** New tile `X`: a bridge where two roads cross. Its four neighbors are road. It is never a socket, entrance, base or spot, and never on the map edge. The east-west road goes over on a plank bridge, and the north-south road passes under. No rule depends on which is on top. At most 3 bridges per map, with at least one plain road tile between two bridges.
- **Routing (3.2).** A walker on a bridge goes straight across. One that comes in from the north leaves to the south, and so on. It never turns there. It turns back along its own road only when a gate breaks and the new shortest route lies behind it (RULES 7.8).
- **Reach.** A creature on a bridge tile is in reach of every tower, on either road. Targeting uses the distance of the node it is on.
- **Gates and refusal.** No change. A gate next to a bridge closes that one arm.
- **Route line.** A line that crosses a bridge goes over the deck or under it. Under the deck it is cut by the bridge, so over and under read by shape. A route may cross itself at a bridge.
- **Flyers** fly over. **Breakers** cross bridges like any walker.
- **Why it is fun.** Crossings are the only way to make figure eights and loops on a 7 wide grid. A spot beside a bridge sees two roads, and a gate can send walkers over the bridge and back under it, past the same towers twice.
- **Why it reads on a phone.** A plank bridge over a road is clear at 48 dp. Creatures on the deck walk across it, creatures below walk under it.
- **Level guide.** Every bridge lies on the shortest route of some gate placement, so it always matters.

### 3.6 Region 7: ice slides

- **Map.** New tiles `^`, `v`, `<` and `>`: an ice slide tile whose arrow points north, south, west or east. The tile its arrow points to is road. A slide tile is never a socket, entrance, base or spot. Slides come in straight runs of 2 or more tiles, so they read as slides, not stray arrows.
- **Routing (3.2).** A walker on a slide tile leaves it only the way its arrow points. No walker steps onto a slide tile from the tile its arrow points to. A walker may join a slide from its side.
- **Gates and refusal.** The words do not change: a placement is refused when any entrance would have no open route. Slides make it more interesting, because a road can look connected and still be closed when the only way left runs up a slide. The crossed-out gate and "That would close every road." explain it, and the route line shows why other placements work.
- **Route line.** No change. Its arrows already point the way, and on a slide they agree with the chevrons.
- **Flyers** fly over. **Breakers'** routes follow the slides too. Released walkers finish their releaser's step, which always goes the slide's way.
- **Why it is fun.** One-way loops. A gate can send walkers onto a slide that carries them around a loop past the same towers, with no way to cut back. A slide can also make a short road the long way round, which matters against the Snowroller.
- **Why it reads on a phone.** Big chevrons carved in the ice point the way, and the route line's arrows match them.
- **Level guide.** With no gates placed, every entrance reaches the base. Use slides for loops and detours, never as dead ends.

### 3.7 Region 8: hollow stumps

- **Map.** New tiles `P` and `Q`: hollow stumps. Each letter appears exactly twice on a map or not at all, and the two stumps of a letter are twins. At most 2 pairs per map. A stump is a road tile with its usual road neighbors. It is never a socket, entrance, base or spot. Twins are never next to each other.
- **Routing (3.2).** Twins are joined by one step, both ways. A walker on a stump takes that step or a usual one, whichever its shortest route needs.
- **Walking through.** The stump step takes the time of one step at the walker's speed. For that whole step the walker is out of reach (3.3). It stands at the stump it entered until the step is done, then appears at its twin's center. A release that begins during the step begins at the stump it entered, and its walkers take the same step.
- **Gates and refusal.** No change. A stump never holds a gate, but a gate on the road beside a stump closes that way in.
- **Route line.** It runs into a stump and starts again at its twin. Twins carry the same carved symbol, a crescent for `P` and a five point star for `Q`, so pairs read by shape. When a walker steps through, a few sparkles show at the stump it entered.
- **Flyers** fly over stumps. **Breakers** use stump steps like any walker. Targeting counts the stump step as one step, as routing does.
- **Why it is fun.** Twins join far parts of the map. A route can jump back up the map past the same towers, or skip your best stretch. The player cannot close a stump, but can close the roads into it, and choosing which way in to close is the puzzle.
- **Why it reads on a phone.** Two matching stumps with matching symbols, walkers popping into one and out of the other, and a route line that jumps between them.
- **Level guide.** On most maps the stump step is the shortcut the gates must close. Each pair lies on some gate placement's shortest route.

### 3.8 Features after their region

A feature stays in the game after its region. Each region's levels use its own feature. Levels 5 and 6 of regions 6, 7 and 8 may also use one earlier feature, never two, so the last levels mix ideas without a new rule.

## 4. New towers

### 4.1 The four towers (RULES 5.1 format)

| Tower | Id | Its one job | Hits | The right answer for | Weak against |
|---|---|---|---|---|---|
| Bramble Cottage | `bramble_cottage` | Thorns hit every walker in its ring, again and again, with no aim | Walkers | Roads that wrap around a spot, loops and bridges, Mistwisp groups, a Gleamer's escort | Armor (except Holly Crown), flyers, roads that only pass by |
| Scarecrow | `scarecrow` | Creatures in its ring take more damage from every hit | Walkers (Crow Keeper: flyers too) | Bosses, Mossbuds, Gleamers, Sleepyheads, late waves where many towers aim at one stretch | Early waves, spread-out spots. It never defeats anything alone |
| Snow Fort | `snow_fort` | Rolls a snowball down a straight line, and every walker in it is hit | Walkers | Long straight roads and slides that run toward it, armored columns, creatures hidden behind a Mistwisp or a Gleamer | Bends, roads that cross its line, flyers |
| Moth Lantern | `moth_lantern` | Pulls flyers low, so every tower can hit them | Flyers | Flocks and flying bosses whose line passes over ground towers | Walkers. Flight lines far from other towers |

Why no current tower does these jobs:

- **Bramble Cottage.** Every attacking tower today aims at one creature, and splash is centered on that aimed target. The Bramble aims at nothing, so hiding and dazzling do not touch it, and its worth comes from how much road wraps around its spot.
- **Scarecrow.** No tower weakens creatures. A Bakery makes the towers beside it faster. A Scarecrow makes creatures softer for every tower that reaches its ring, wherever those towers stand.
- **Snow Fort.** Splash is round and short. The line is long and narrow, so the shape of the map decides its worth.
- **Moth Lantern.** Only Sling Posts and Fireworks can hit flyers today. Nothing lets the rest of the board help.

### 4.2 Rules for all four

- The Bramble Cottage, Snow Fort and Moth Lantern are attacking towers. Reload timers, Bakery boosts, run perks and the tick order work as RULES 5.2 and 8 say. The Snow Fort and Moth Lantern have targeting modes. The Bramble has none, because it aims at nothing.
- The Scarecrow is a ring tower like the Lullaby Bell: no reload, no targeting, no damage. Bakeries never boost it, and it never boosts anything.
- Bramble pulses, Snow Fort lines and Moth Lantern shots are hits: a bubble blocks one, armor counts unless the path ignores it, and a fright adds to it.
- Refunds, upgrades and the before and after numbers follow RULES 4.6 and 9.5. Every price is a multiple of 10.

### 4.3 Bramble Cottage

A cottage under a crown of thorns. Every second, its thorns scratch every walker in its ring. Cannot hit flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Ring | Extra |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Bramble Cottage | `bramble_cottage` | 120 | 120 | 4 | 1.0 | 1.0 | 1.5 | none |
| 2 | Bramble Cottage | `bramble_cottage` | 130 | 250 | 7 | 1.0 | 1.0 | 1.5 | none |
| 3 | Wild Bramble | `wild_bramble` | 230 | 480 | 10 | 1.0 | 1.0 | 2.0 | none |
| 3 | Holly Crown | `holly_crown` | 230 | 480 | 12 | 1.0 | 1.0 | 1.5 | Ignores armor |

These are the first numbers. The region 5 tuning of 2026-10-29 doubled its damage and widened its rings (docs/design/TUNING_R5.md). RULES 5.12 holds the current numbers.

- When its timer is 0 or less and at least one creature it can hit is in its ring, it pulses: every creature it can hit whose center is within the ring takes the hit. Then its reload starts, as for any tower (RULES 5.2). With nothing it can hit in its ring, its timer waits at 0, so it never saves up a pulse.
- The creatures it can hit are walkers and low flyers (4.6). Hidden ones (5.2, Mistwisp) count. Out of reach (3.3) and napping (5.2) creatures do not.
- A ring of 1.5 covers the eight tiles around it, diagonals included, like the Bakery's reach.
- Wild Bramble: a wider ring for a spot that sees two roads. Holly Crown: sharp holly that ignores armor, for Shellbacks and Yawners at a bend.
- Render and audio: the looks are the art director's (docs/art/EXPANSION_LOOK.md 2): a cottage whose roof is a great tangle of thorny bramble, then a wilder tangle or a holly bush at tier 3. Its shot is a ring of thorns that pulses out to the ring's edge. A short dry rustle on `fired`.

### 4.4 Scarecrow

A straw scarecrow with a lantern on its post. Creatures in its ring get frightened and take more damage from every hit. Deals no damage.

| Tier | Name | Id | Price | Total spent | Fright | Ring | Affects |
|---|---|---|---|---|---|---|---|
| 1 | Scarecrow | `scarecrow` | 100 | 100 | 15% | 2.0 | Walkers |
| 2 | Scarecrow | `scarecrow` | 100 | 200 | 25% | 2.5 | Walkers |
| 3 | Tall Scarecrow | `tall_scarecrow` | 190 | 390 | 40% | 2.5 | Walkers |
| 3 | Crow Keeper | `crow_keeper` | 190 | 390 | 25% | 3.0 | Walkers and flyers |

- Every tick, each creature of the right kind in its ring gets its fright with 1.0 s left, so the fright lingers 1.0 s after a creature leaves the ring, as a Bell's slow does.
- Damage taken by a frightened creature = (hit damage minus armor, at least 1) times (100 + fright) / 100, rounded half up. Example: a Stone Sling (20) hits a Shellback (armor 4) with 25% fright: 16 becomes 20.
- A creature holds one fright at a time. A higher fright replaces it. An equal one keeps the longer time. Frights never add up (as slows, RULES 8.5).
- Bosses are frightened too. A bubble still blocks the whole hit.
- Tall Scarecrow: the strongest fright. Crow Keeper: a wider ring that frightens flyers too.
- Render and audio: the looks are the art director's (docs/art/EXPANSION_LOOK.md 2): a field scarecrow on its post behind a small hut, never a walking straw man, with a wider hat as Tall Scarecrow and a crow on each arm as Crow Keeper. A frightened creature shows two small zigzag shiver lines on each side, a shape, not a color. No battle sound beyond built, upgraded and sold, like the Bell.

### 4.5 Snow Fort

A round fort of snow bricks. It rolls a big snowball in a straight line, and every walker in its path is hit. Cannot hit flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Line width | Damage per s per walker hit |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Snow Fort | `snow_fort` | 140 | 140 | 16 | 3.0 | 0.3 | 3.0 | 0.8 | 5.3 |
| 2 | Snow Fort | `snow_fort` | 150 | 290 | 28 | 3.0 | 0.3 | 3.5 | 0.8 | 9.3 |
| 3 | Big Snowball | `big_snowball` | 260 | 550 | 64 | 3.5 | 0.3 | 4.0 | 1.0 | 18.3 |
| 3 | Flurry | `flurry` | 260 | 550 | 24 | 1.5 | 0.7 | 3.5 | 0.8 | 16.0 |

- It picks a target in range by its targeting mode, like any attacking tower.
- The line is a straight segment. It starts at the tower's center, runs through the target's center, and goes on until it is as long as the tower's range, or until it reaches the map's edge, whichever comes first. Every creature it can hit whose center is within half the line width of that segment is hit, the target included. The contract sets the integer math.
- The creatures it can hit are walkers and low flyers (4.6), not out of reach (3.3) and not napping (5.2). A hidden walker can be hit by the line, though it can never be its target.
- The line ignores roads. A line that crosses grass and another road hits walkers on both.
- Only a low flyer can be at the tower's own center. If the target is there, the shot hits that target alone.
- Big Snowball: one huge, wider snowball for armored columns and bosses. Flurry: quick snowballs, twice as often, for long crowds.
- Render and audio: the looks are the art director's (docs/art/EXPANSION_LOOK.md 2): a wall of warm cream snow bricks with a flag and a snowball on top, then one huge snowball or a stack of six small ones at tier 3. Our snow is warm cream and the creatures' is blue-white, so the fort's snowball never shares a color with a Snowroller's. The snowball rolls along the line with a short snow trail. A soft rolling thump on `fired`.

### 4.6 Moth Lantern

A tall lantern on a curled post. Its light lures flyers low, where every tower can reach them. Cannot hit walkers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Targets per shot | Low for (s) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Moth Lantern | `moth_lantern` | 110 | 110 | 4 | 1.0 | 1.0 | 3.0 | 1 | 2.0 |
| 2 | Moth Lantern | `moth_lantern` | 110 | 220 | 6 | 1.0 | 1.0 | 3.5 | 1 | 3.0 |
| 3 | Beacon Lantern | `beacon_lantern` | 200 | 420 | 8 | 1.0 | 1.0 | 4.5 | 1 | 4.0 |
| 3 | Lantern Garland | `lantern_garland` | 200 | 420 | 6 | 1.0 | 1.0 | 3.5 | 3 | 3.0 |

- It hits flyers only. Each flyer it hits is low for the time in the table. A new lure keeps the longer time.
- It aims at flyers that are not low first, in its targeting mode's order. Only when every flyer in range is already low does it aim at a low one.
- The Lantern Garland picks up to 3 different flyers: first every flyer in range that is not low, in its mode's order, then, with targets to spare, low flyers in the same order. With fewer flyers in range than targets, the spare targets go unused, as a Triple Bow's do.
- A lure is part of the hit. A bubble that blocks the hit blocks the lure too: the flyer stays high, and only the bubble pops (RULES 8.3).
- A lure counts at once. Towers that act later in the same tick, in spot order (RULES 3.4), can already aim at the lured flyer as if it were a walker.
- A low flyer still flies its straight line, still ignores roads and gates, and still counts as a flyer for every other rule. But every tower can aim at it and hit it as if it were a walker: Catapult splash, Longbow arrows, Bramble rings and Snow Fort lines reach it, every Bell slows it and every Scarecrow frightens it. Sling Posts and Fireworks hit it as before.
- Bosses can be lured: the Moon Moth, and the flyers any boss releases.
- Beacon Lantern: reaches far and holds flyers low longer. Lantern Garland: lures three flyers with each shot, for flocks.
- Render and audio: the looks are the art director's (docs/art/EXPANSION_LOOK.md 2): a lamplighter's booth with a tall curled post and a big lantern, then one big lantern on a straight post or a string of small lanterns at tier 3. Two tiny cream moths are a detail in the light, not part of the shape. A soft beam to each flyer it hits. A low flyer flies just above its shadow, with a pale ring at the shadow. A soft glassy chime on `fired`.

### 4.7 One-line tower cards (RULES 5.9 format)

| Tower or path | Line |
|---|---|
| Bramble Cottage | Thorns scratch every walker in its ring each second. Armor blunts them. |
| Scarecrow | Creatures in its ring take more damage from every hit. Deals no damage. |
| Snow Fort | Rolls a snowball in a straight line. Every walker in its path is hit. |
| Moth Lantern | Lures flyers low, so every tower can hit them. Can't hit walkers. |
| Wild Bramble | A wider ring of thorns. |
| Holly Crown | Sharp holly that ignores armor. |
| Tall Scarecrow | Frightens harder: 40% more damage. |
| Crow Keeper | A wider ring that frightens flyers too. |
| Big Snowball | One huge snowball, wider and longer. |
| Flurry | Quick snowballs, twice as often. |
| Beacon Lantern | Reaches far and holds flyers low longer. |
| Lantern Garland | Lures three flyers at once. |

Plurals, for "Build no ...": Bramble Cottages, Scarecrows, Snow Forts, Moth Lanterns.

### 4.8 Why no tower is best everywhere (RULES 5.10)

The same rough model as RULES 5.10: useful damage per second for every 100 gold, tier 1, strength 100, a steady stream of one creature. The Bramble and the Snow Fort depend on the shape of the road, so each gets two rows. For the Bramble, "passing" is a straight road beside its spot (about 2.2 tiles of road in its ring) and "wrapped" a road that bends around its spot on two sides (about 3.5 tiles). For the Snow Fort, "across" is a road that crosses its line (about 0.8 tiles in the line) and "aligned" a straight road that runs down its line (about 2.5 tiles).

| Tower | Road shape | Scamp | Pip | Skitter | Shellback |
|---|---|---|---|---|---|
| Sling Post | any (RULES 5.10) | 11.4 | 10.5 | 12.0 | 4.0 |
| Pumpkin Catapult | any (RULES 5.10) | 5.6 | 21.9 | 4.2 | 4.2 |
| Longbow Loft | any (RULES 5.10) | 10.7 | 5.6 | 8.0 | 8.0 |
| Bramble Cottage | passing | 7.5 | 20.7 | 4.7 | 1.8 |
| Bramble Cottage | wrapped | 11.7 | 32.4 | 7.3 | 2.8 |
| Snow Fort | across | 3.0 | 8.5 | 1.9 | 2.2 |
| Snow Fort | aligned | 9.5 | 26.4 | 5.9 | 6.8 |

What the table shows:

- In a plain placement neither new attacker tops a column. Each needs the map read right, which is the point: the Bramble where the road wraps around its spot, the Snow Fort where a straight road runs down its line.
- The Bramble is a crowd tower only where the road wraps around it. On a road that only passes by, the Catapult is better against crowds and the Sling Post against single walkers. Armor stops it, except as a Holly Crown.
- The Snow Fort is poor across a road. Down an aligned road it is about the Catapult's equal on crowds and, after the Longbow, the best tier 1 buy against an armored column. Big Snowball takes armored columns at tier 3.
- The Scarecrow and the Moth Lantern deal no damage worth counting. Like the Bell and the Bakery, the bots judge them on real maps: the Scarecrow's fright is worth more the more towers aim into its ring, and the Lantern is worth what the ground towers under a flight line can add.
- One watch item: the Bramble's Pip numbers are chip damage. Four a second for two or three seconds pops no Pip on its own, but it could crowd the Catapult's job at a tight bend. If the bots find that, the lever is tier 1 damage, 4 down to 3.
- The bots found the opposite (2026-10-29): the Bramble was weak in the campaign and a trap in runs, so its damage doubled and its rings widened (docs/design/TUNING_R5.md). RULES 5.10 has its current rows and the new watch item.

### 4.9 Pairs players can discover (RULES 5.11 additions)

| Pair | Why it works |
|---|---|
| Bramble Cottage and Lullaby Bell | Drowsy walkers stay in the thorns longer, so each one takes more pulses. |
| Bramble Cottage and a bridge or a slide loop | A spot beside a bridge or inside a loop has road on more sides, and walkers pass it twice. |
| Bramble Cottage and Pumpkin Catapult | Thorns soften the crowd at the bend, and the next pumpkin pops it. |
| Scarecrow and Giant Bow | The bigger the hit, the more the fright adds. Bosses melt. |
| Scarecrow and Bakery | One makes towers fire faster, the other makes every hit count for more. The two add up. |
| Snow Fort and gates | A gate can turn the route onto a long straight road that runs toward the fort. |
| Snow Fort against Mistwisps and Gleamers | The line aims at what it can see and rolls on through the creatures behind it. |
| Moth Lantern and Pumpkin Catapult | A lured flock sinks into the splash. |
| Moth Lantern and Giant Bow | A lured Moon Moth meets the biggest arrow in the game. |
| Moth Lantern and Lullaby Bell | A lured flyer counts as a walker for Bells, so any Bell slows it. |

## 5. New creatures and bosses

### 5.1 Creature numbers (RULES 6.1 format)

Numbers at strength 100. Strength scales health, regrow amounts and bounty (RULES 6.4). Armor, speed and lives never scale.

| Creature | Id | Health | Armor | Speed | Moves | Lives lost | Bounty | Special |
|---|---|---|---|---|---|---|---|---|
| Mossbud | `mossbud` | 80 | 0 | 0.8 | Walks | 1 | 10 | Regrows 4 health every 1.0 s (5.2). |
| Mistwisp | `mistwisp` | 50 | 0 | 1.0 | Walks | 1 | 10 | Creatures on its tile or the four tiles next to it cannot be aimed at (5.2). |
| Gleamer | `gleamer` | 160 | 0 | 0.8 | Walks | 2 | 18 | Dazzles: every tower in range aims at it (5.2). |
| Sleepyhead | `sleepyhead` | 90 | 0 | 0.9 | Walks | 1 | 12 | Naps once for 2.0 s, then wakes with half its max health (5.2). |
| Snowroller | `snowroller` | 40 | 0 | 1.0 | Walks | 1 | 8 | Grows 10% of its starting max health each tile, up to 3 times (5.2). |
| Yawner | `yawner` | 110 | 2 | 0.7 | Walks | 2 | 15 | Every 4.0 s, towers within 1.5 tiles doze for 2.0 s (5.2). |
| Blinker | `blinker` | 60 | 0 | 0.9 | Walks | 1 | 9 | Every 3.0 s, it blinks 2 tiles ahead (5.2). |
| Hootling | `hootling` | 80 | 1 | 0.9 | Walks | 1 | 11 | No creature within 1.5 tiles of it can be slowed (5.2). |

That makes 18 creature types and 8 bosses, plus the Puff. No two share a job: the Mossbud heals only itself (the Mender heals others), the Mistwisp protects others from aim (the Bubbler protects itself from one hit), the Sleepyhead gets up again (the Puffball splits), the Blinker jumps (the Skitter runs), and the Gleamer, Snowroller, Yawner and Hootling do things no creature does today.

All eight walk. Flyers keep coming in every region (Flitters, Dusk Moths and boss releases), so gates are never a complete answer. A new flyer type would add little next to the Moth Lantern, which changes how every flyer is fought.

### 5.2 Special rules

**Regrow (Mossbud).** Every 1.0 s, starting 1.0 s after it appears, it gains 4 health, scaled by strength, up to its max health. It regrows out of reach too. A Mender still heals it as well.

**Mist (Mistwisp).**
- Mist covers tiles. A creature on a Mistwisp's tile, or on one of the four tiles next to it (north, south, east and west), is hidden. No tower can aim at a hidden creature. A creature's tile is the tile its center is in, so a flyer over those tiles is hidden too.
- Splash, Bramble rings and Snow Fort lines still hit hidden creatures, and Bells and Scarecrows still reach them. Only aiming stops.
- A Mistwisp is never hidden, even beside another Mistwisp. A Mistwisp that is out of reach still hides (3.3).
- Hiding is worked out at the start of the towers step each tick, from the tiles the Mistwisps stand on then.

**Dazzle (Gleamer, Old Hayrick).**
- Every tower that can aim at a dazzling creature in its range aims at it, whatever its targeting mode. With several in range, the tower's mode picks among them.
- A tower with more than one target per shot (Triple Bow, Lantern Garland, and in runs Twin Pebbles and Volley) puts its first target on a dazzling creature and picks the rest by its mode.
- A hidden creature cannot be aimed at, so a hidden Gleamer dazzles nothing.
- Splash, lines and pulses still reach the creatures around it. That is the answer.

**Nap (Sleepyhead, Old Hayrick).** Napping is its own status, stricter than out of reach (3.3).
- The first time its health falls to 0 or less, it is not popped. In the defeats step of that tick, its health is set to the value it will wake with, half its max health, rounded half up, and it starts napping for 2.0 s (Old Hayrick 3.0 s). Any slow or fright it held ends.
- While napping it does not move. No tower can aim at it or hit it: splash, Bramble rings and Snow Fort lines skip it, and Bells and Scarecrows do not reach it. No heal reaches it, and it does not regrow or blink. A napping Old Hayrick cannot be aimed at, so it dazzles nothing.
- When the nap ends, in the timers step, it wakes and walks on with that health.
- The next time its health falls to 0 or less, it pops for good, pays its bounty and counts as defeated.
- A nap is not a defeat: no bounty and no release. A napping creature keeps its wave running, and its bounty counts toward the early call bonus like any creature on the map (RULES 4.9).
- The creature panel says "Napping" and the time left. Its health shows the value it will wake with.

**Grow (Snowroller, Snowsnore).**
- Each time a Snowroller reaches a tile center after its entrance's, its max health and its health both rise by 10% of its starting max health, rounded half up. Its max health never goes above 3 times its starting max health: a rise that would pass that cap adds only what fits, to both, and after that it stops growing. Snowsnore grows by 2% each tile, capped at 1.5 times.
- Starting max health is its max health when it appears, after strength and any Twist or risk card.
- The wave health ceiling of the saves (contract 5.6) counts each grower at its cap: 3 times its starting max health for a Snowroller, 1.5 times for Snowsnore.
- Its drawing grows with it, up to 1.5 times its size, so growth reads by shape.

**Yawn (Yawner, Snowsnore).**
- 4.0 s after a Yawner appears, and every 4.0 s after that, it yawns: every attacking tower whose center is within 1.5 tiles of the Yawner's center dozes for 2.0 s.
- A dozing tower does not fire, and its reload timer does not run down. A new doze keeps the longer time.
- In the timers step, doze timers run down first and new yawns land after. So a new doze already stops that tick's towers step and lasts its full time.
- Bells, Scarecrows and Bakeries never doze.
- It yawns out of reach too: under a mound, it still makes the towers beside the mound doze.

**Blink (Blinker, Glimmertoad).**
- 3.0 s after a Blinker appears, and every 3.0 s after that, it blinks: in the movement step it first moves 2 tiles further along its route at once, then walks on as usual. It decides at every tile center on the way, as RULES 7.3 says. A stump step counts as one tile.
- A blink that would pass the base ends there, and the creature gets through.
- A slow never shortens a blink. A napping creature never blinks.

**Wake (Hootling, Glimmertoad).**
- Awake is worked out once a tick, in the timers step. Every creature whose center is within 1.5 tiles of a Hootling's center, the Hootling included, is awake for that tick, and any slow it holds ends. Glimmertoad does the same within 2.0 tiles.
- An awake creature gets no slow during that tick, from a Bell, a Jam Pot or anything else.
- So a breaker near a Hootling breaks gates at full speed.
- Wake changes slows only. Frights and lures still work.
- Creatures that wake get an at-once bound in saves, like the healers' (5.8).

### 5.3 Bosses (RULES 6.3 format)

| Boss | Id | Region | Health | Armor | Speed | Moves | Lives lost | Bounty | Special |
|---|---|---|---|---|---|---|---|---|---|
| Burrowbelly | `burrowbelly` | 5 | 3200 | 2 | 0.4 | Walks | 20 | 300 | Digs under for 2.0 s every 8.0 s. Comes up with 2 Mistwisps. |
| Old Hayrick | `old_hayrick` | 6 | 2600 | 0 | 0.4 | Walks | 20 | 300 | Dazzles. Popped once, it naps 3.0 s and gets up with half its health. |
| Snowsnore | `snowsnore` | 7 | 3400 | 3 | 0.35 | Walks | 20 | 350 | Grows as it walks, up to 1.5 times. Every 6.0 s, towers within 2.0 tiles doze for 3.0 s. |
| Glimmertoad | `glimmertoad` | 8 | 3600 | 4 | 0.35 | Walks | 20 | 400 | Hops 3 tiles ahead every 6.0 s. Cannot be slowed. At half health, 6 Flitters fly out. |

Exact rules:

- **Burrowbelly.** 6.0 s after it appears, and every 8.0 s after that, it digs under for 2.0 s. Under the ground it keeps walking its route and is out of reach (3.3). Each time it comes up, that is 8.0 s after it appears and every 8.0 s after that, 2 Mistwisps appear at its spot, 0.3 s apart, and walk on from there. This is a summon, as Grumblesack's. The Mistwisps hide it from aim as they come out on its tile. They walk faster than it, so they soon move ahead and hide the creatures in front of it instead. Rings, lines and splash carry the fight.
- **Old Hayrick.** It dazzles (5.2). It naps once, as a Sleepyhead does (5.2), for 3.0 s: its health is set to half its max health when the nap starts, and it gets up with that. It pays its bounty only when popped for good. Its escort walks on while every tower aims at it.
- **Snowsnore.** It grows by 2% of its starting max health at each tile center, up to 1.5 times. 6.0 s after it appears, and every 6.0 s after that, it yawns: every attacking tower within 2.0 tiles dozes for 3.0 s.
- **Glimmertoad.** 6.0 s after it appears, and every 6.0 s after that, it hops 3 tiles ahead along its route, as a blink does. No creature within 2.0 tiles of it can be slowed, itself included. The first time its health falls to 50% or below, 6 Flitters appear at its spot, 0.3 s apart, starting on the next tick. This is a release, as Old Tusk's, and happens even if the same hit defeats it.
- A boss that reaches the base costs 20 lives (RULES 6.3). RULES 6.3 says every boss can be slowed. Glimmertoad is the one exception, and its card says so.

Starting boss wave strengths, as the campaign's boss waves set their own (RULES 12.3): 5-6 at 80 (2560 health), 6-6 at 75 (1950, then 975 more after its nap), 7-6 at 70 (2380, growing to 3570), 8-6 at 75 (2700). The level designer tunes them with the bots.

### 5.4 Statuses and stacking

| Status | Who | Shown as, never by color alone | Stacks? |
|---|---|---|---|
| Out of reach | In a tunnel or stump, Burrowbelly under the ground | Hidden under the mound, a few sparkles at the stump it entered, a moving dirt mound with claw tips | On or off |
| Hidden | On or next to a Mistwisp's tile | The Mistwisp's own curl, small, above the creature's head | On or off, worked out at the start of the towers step |
| Napping | Sleepyhead, Old Hayrick | Lying on its side with a small crescent moon above, not the drowsy "z z". The panel says "Napping" | Once per creature. Its own status, stricter than out of reach |
| Frightened | Near a Scarecrow | Two small zigzag shiver lines on each side | One fright. The strongest wins |
| Low | Lured flyer | Flying just above its shadow, with a pale ring at the shadow | One. The longest wins |
| Awake | Near a Hootling or Glimmertoad | A small open eye above it | On or off, worked out once a tick in the timers step |
| Dozing | Towers near a yawn | One big "z" over the tower, unlike a slowed creature's smaller "z z" | One doze. The longest wins |

The marks are the art director's (docs/art/EXPANSION_LOOK.md 5).

Regrow and a Mender's heal both apply, each on its own (RULES 8.7).

### 5.5 Tick order additions (RULES 8.1)

1. Spawns: no change. Burrowbelly's Mistwisps come as summons, Glimmertoad's Flitters as a release.
2. Timers: everything RULES 8.1 lists, plus, in this order: regrows; naps that end (the creature wakes); digging that starts or ends; doze timers run down, then yawns that are due give new dozes; lure and fright timers run down. Last, wake: creatures in a Hootling's or Glimmertoad's reach are awake for this tick, and their slows end.
3. Rings: Bells give slows, never to an awake creature, and Scarecrows give frights.
4. Movement: each creature in id order. If its blink or hop is due, it blinks first, then walks its usual step for the tick. Stump steps and growth at tile centers happen as it walks.
5. Towers: hidden creatures are worked out first. Dozing towers skip their turn. Dazzle comes into targeting. Pulses, lines and lures land at once, like every hit, and a lure already counts for the towers that act after it.
6. Defeats: a Sleepyhead or Old Hayrick at 0 health or less for the first time is not defeated. Its health is set to its wake value and its nap starts (5.2).
7. Wave checks: no change. A napping or out-of-reach creature keeps its wave running.

### 5.6 One-line creature cards (RULES 6.6 format)

| Creature | Line |
|---|---|
| Mossbud | Regrows a little health every second. Big hits beat it. Slows give it time. |
| Mistwisp | Creatures on its tile or beside it can't be aimed at. Splash still hits them. |
| Gleamer | Every tower that can reach it aims at it. Others slip past. |
| Sleepyhead | Popped once, it naps for 2 seconds, then gets up with half its health. |
| Snowroller | Grows with every tile it walks, up to 3 times its health. Pop it early. |
| Yawner | Every 4 seconds it yawns, and towers right beside it doze for 2 seconds. |
| Blinker | Every 3 seconds it blinks 2 tiles ahead along the road. |
| Hootling | Its hoots keep everything near it awake. Nothing near it can be slowed. |
| Burrowbelly | Digs under for 2 seconds every 8. Comes up with 2 Mistwisps. |
| Old Hayrick | Every tower aims at it. Popped once, it naps 3 seconds and gets up again. |
| Snowsnore | Grows as it walks. Every 6 seconds it yawns and towers near it doze. |
| Glimmertoad | Hops ahead every 6 seconds. Can't be slowed. At half health, Flitters fly out. |

### 5.7 What each one counters and rewards

| Creature | It punishes | It rewards |
|---|---|---|
| Mossbud | Chip damage and long slows, which give it time to regrow | Big hits, Strong aim, Scarecrows |
| Mistwisp | Builds of single-target towers | Splash, Bramble rings, Snow Fort lines, and popping the wisp first |
| Gleamer | Builds where every tower aims, because its escort walks free | Splash, lines and rings, towers with several targets, Scarecrows to drop it fast |
| Sleepyhead | Defenses packed at one end of the road | Towers spread down the road, splash where it wakes |
| Snowroller | Long roads made by gates and loops | Towers near the entrance, shorter routes, early hits |
| Yawner | Clusters right beside the road, Bakery clusters | Towers set back from the road: Longbows, Snow Forts, Catapults |
| Blinker | One choke point | Towers that cover long stretches |
| Hootling | Bell and Jam Pot builds | Damage over control, and popping the Hootling first |
| Burrowbelly | Aiming alone, because its Mistwisps hide it | Bramble rings and splash beside its road |
| Old Hayrick | Single-target defenses, because its escort walks free | Splash and lines on the escort, Scarecrows and big hits on the boss |
| Snowsnore | Towers right by its road, long gate detours | Range, early hits, Snow Forts from afar |
| Glimmertoad | Bells, and one choke point | Damage spread along its route, Moth Lanterns for its Flitters |

### 5.8 Performance

- No new creature adds bodies to the map, except Burrowbelly's Mistwisps (2 every 8 s) and Glimmertoad's 6 Flitters, once.
- The new work per tick is small and local. Mist marks at most 5 tiles per Mistwisp, and then hiding is a look-up by tile. Wake checks the creatures within 1.5 tiles of each Hootling (2.0 for Glimmertoad), with the sim's per-cell buckets. Yawns are rare. A pulse or a line checks the creatures in one tower's reach. Regrow, nap, growth and blink are per-creature timers.
- The Fold5 already showed a 99th percentile tick near 2 ms at 78 live creatures (docs/render/perf-fold5-2026-10-26.md). So in regions 5 to 8: aim for 80 or fewer creatures per wave, as RULES 12.5 does, put at most 6 Hootlings in any wave, and measure the most crowded new wave on the phone before release.
- A pulse and a rolling snowball are each one drawn shot, so the 96 shot cap holds.
- Saves: creatures that wake get an at-once bound like the healers' (contract 5.6). Mist needs none, because it only marks tiles. Burrowbelly counts as a summoner. The wave health ceiling counts growers at their cap (5.2).

## 6. Campaign plan

### 6.1 Regions (RULES 12.1 format)

| Region | Name | Id | Setting | Towers it brings | Creatures it brings | Boss | Map feature |
|---|---|---|---|---|---|---|---|
| 5 | Hollow Lanes | `hollow_lanes` | Sunken lanes under arching hedgerows | Bramble Cottage | Mossbud, Mistwisp | Burrowbelly | Tunnels |
| 6 | Russet Orchards | `russet_orchards` | Autumn orchards, hay barns and cart bridges | Scarecrow | Gleamer, Sleepyhead | Old Hayrick | Bridges |
| 7 | Frostpine Ridge | `frostpine_ridge` | A snowy pine ridge with sled runs and ski huts | Snow Fort | Snowroller, Yawner | Snowsnore | Ice slides |
| 8 | Starglen | `starglen` | A glade of glowing toadstools and hollow stumps | Moth Lantern | Blinker, Hootling | Glimmertoad | Hollow stumps |

### 6.2 Unlock order (RULES 12.2 format)

Each line is one new thing, in the order the player meets it.

| Level | New |
|---|---|
| 5-1 | Tunnels |
| 5-2 | Bramble Cottage |
| 5-3 | Mossbud |
| 5-4 | Mistwisp |
| 5-5 | Nothing new |
| 5-6 | Burrowbelly |
| 6-1 | Bridges |
| 6-2 | Scarecrow |
| 6-3 | Gleamer |
| 6-4 | Sleepyhead |
| 6-5 | Nothing new |
| 6-6 | Old Hayrick |
| 7-1 | Ice slides |
| 7-2 | Snow Fort |
| 7-3 | Snowroller |
| 7-4 | Yawner |
| 7-5 | Nothing new |
| 7-6 | Snowsnore |
| 8-1 | Hollow stumps |
| 8-2 | Moth Lantern |
| 8-3 | Blinker |
| 8-4 | Hootling |
| 8-5 | Nothing new |
| 8-6 | Glimmertoad |

- As RULES 12.2 says, a level offers every tower brought up to it: 7 kinds from 5-2, 8 from 6-2, 9 from 7-2 and all 10 from 8-2.
- Each region's first level brings only its map feature and has one entrance, so the feature is its only new idea. The level's hint and highlight teach it, as 1-2 taught gates.

### 6.3 Levels (RULES 12.3 format)

"First wave" is the wave where the new creature first comes, alone. Sockets are suggestions for the level designer. Every level has 12 waves, with the boss in wave 12 on the boss levels. Lives are 20 on Normal and 40 on Relaxed, as today. Relaxed gold is 1.5 times Normal, rounded up to a multiple of 10 (RULES 11).

Region 5, Hollow Lanes:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 5-1 | Under the Hedges | Walkers in a tunnel are out of reach. Gate them out of it. | Tunnels | none | 2 (5) | 12 | 230 | 700 | 1050 |
| 5-2 | Bramble Bend | Thorns hit everything around them. Build where the road wraps. | Bramble Cottage | none | 2 (5) | 12 | 235 | 750 | 1130 |
| 5-3 | Mossy Hollow | Big hits beat regrowth. Slows only give it time. | Mossbud | 2 | 2 (5) | 12 | 240 | 750 | 1130 |
| 5-4 | Mist Lane | Hidden creatures need splash, rings or lines. | Mistwisp | 3 | 3 (6) | 12 | 245 | 800 | 1200 |
| 5-5 | Badger Hill | Two entrances, a tunnel on each road. | none | none | 3 (6) | 12 | 250 | 800 | 1200 |
| 5-6 | Burrowbelly | A boss you cannot always reach, hidden by mist. | Burrowbelly | 12 | 3 (6) | 12 | 255 | 850 | 1280 |

Region 6, Russet Orchards:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 6-1 | Cart Bridge | Walkers cross a bridge straight. A loop passes your towers twice. | Bridges | none | 2 (5) | 12 | 245 | 750 | 1130 |
| 6-2 | Scarecrow Field | Frightened creatures take more from every hit. | Scarecrow | none | 2 (5) | 12 | 250 | 800 | 1200 |
| 6-3 | Glowing Rows | Every tower aims at a Gleamer. Splash the rest. | Gleamer | 2 | 3 (6) | 12 | 255 | 800 | 1200 |
| 6-4 | Nodding Orchard | Sleepers get up again. Keep towers down the road. | Sleepyhead | 3 | 3 (6) | 12 | 260 | 850 | 1280 |
| 6-5 | Cider Barns | Two entrances and two bridges. | none | none | 3 (6) | 12 | 265 | 850 | 1280 |
| 6-6 | Old Hayrick | A boss that draws every shot and gets up once. | Old Hayrick | 12 | 3 (6) | 12 | 270 | 900 | 1350 |

Region 7, Frostpine Ridge:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 7-1 | Sled Runs | Slides go one way. A gate can send walkers around a loop. | Ice slides | none | 2 (5) | 12 | 255 | 800 | 1200 |
| 7-2 | Snow Fort Hill | A line hits every walker on a straight road. | Snow Fort | none | 2 (5) | 12 | 260 | 850 | 1280 |
| 7-3 | Rolling Slope | Some creatures grow on long roads. Pop them early. | Snowroller | 2 | 3 (6) | 12 | 265 | 850 | 1280 |
| 7-4 | Drowsy Huts | Towers beside the road doze. Range stays awake. | Yawner | 3 | 3 (6) | 12 | 270 | 900 | 1350 |
| 7-5 | Icicle Pass | Slides and a tunnel together. | none | none | 3 (7) | 12 | 275 | 900 | 1350 |
| 7-6 | Snowsnore | A boss that grows and puts towers to sleep. | Snowsnore | 12 | 3 (7) | 12 | 280 | 950 | 1430 |

Region 8, Starglen:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 8-1 | Twin Stumps | Twin stumps join far roads. Close the way in. | Hollow stumps | none | 2 (5) | 12 | 265 | 850 | 1280 |
| 8-2 | Lantern Glade | Lure flyers low and the whole board can hit them. | Moth Lantern | none | 3 (6) | 12 | 270 | 900 | 1350 |
| 8-3 | Blinking Path | Blinkers skip choke points. Cover long stretches. | Blinker | 2 | 3 (6) | 12 | 275 | 900 | 1350 |
| 8-4 | Hoot Glen | Hootlings stop slows. Pop them first. | Hootling | 3 | 3 (7) | 12 | 280 | 950 | 1430 |
| 8-5 | Stone Circle | Everything at once, with a bridge from region 6. | none | none | 3 (7) | 12 | 290 | 950 | 1430 |
| 8-6 | Glimmertoad | The final boss hops, cannot be slowed and lets flyers out. | Glimmertoad | 12 | 3 (7) | 12 | 300 | 1000 | 1500 |

Per region:

| Region | Map rows | Build spots | Entrances | Gates | Target minutes at 1x |
|---|---|---|---|---|---|
| 5 | 10 to 13 | 9 to 11 | 1, then 2 from 5-5 | 2 to 3 | 6 to 9 |
| 6 | 10 to 13 | 10 to 12 | 1 on 6-1, then 2 | 2 to 3 | 6 to 9 |
| 7 | 10 to 13 | 10 to 12 | 1 on 7-1, then 2 | 2 to 3 | 6 to 9 |
| 8 | 10 to 13 | 11 to 12 | 1 on 8-1, then 2, 3 on 8-5 | 2 to 3 | 6 to 9 |

- Strength rises slowly, 230 to 300, because the new difficulty comes from new ideas, not bigger numbers. As in regions 2 to 4, most waves set their own strength below the level's. Pip waves stay at 115 or less where a tier 2 Catapult should pop a Pip in one hit (RULES 12.5). Boss waves set their own (5.3).
- Difficulty targets, as RULES 12.5 sets for later regions: about 85% of thoughtful first tries win each region's first level, falling to about 65% on its boss level.
- Every level must pass the checks of RULES 12.6, the same bars as regions 2 to 4.

Typical gaps for the new creatures (RULES 12.5 additions):

| Creature | Gap (s) |
|---|---|
| Mossbud | 1.0 to 1.5 |
| Mistwisp | 2.0 to 4.0, as a group that starts inside another group's time, so the wisps walk among them |
| Gleamer | 2.0 to 4.0, at the front of a group |
| Sleepyhead | 1.0 to 1.5 |
| Snowroller | 0.5 to 1.0 |
| Yawner | 2.0 to 4.0 |
| Blinker | 0.8 to 1.2 |
| Hootling | Spawn it just after the group it should keep awake, like the Mender |

### 6.4 Level cards: star 3, hint and highlight (RULES 12.4 format)

Star 2 stays "Keep 15 lives." on every level. Each star 3 rule is a starting target that the bots confirm (RULES 12.6). Most limit spending, which RULES 12.5 found is what makes the mix matter. No two levels in a row share a rule, and no level's Twist repeats its star 3. Every hint is at most 80 characters.

| Level | Star 3 | Hint | Highlight |
|---|---|---|---|
| 5-1 | Have at most 6 towers. | Creatures in a tunnel are out of reach. Close the tunnel road with a gate. | The socket that closes the tunnel road |
| 5-2 | No tower above tier 2. | Bramble Cottages scratch every walker around them. Build where roads bend. | A spot the road wraps around |
| 5-3 | Build no Lullaby Bells. | Mossbuds regrow. Big hits beat them. Slows only give them time. | The spot beside the longest stretch |
| 5-4 | Have at most 7 towers. | Mistwisps hide creatures near them. Pop the wisp, or use rings and splash. | A spot the road wraps around |
| 5-5 | Use at most 3 kinds of tower. | none | none |
| 5-6 | Have at most 8 towers. | Burrowbelly digs under, then comes up with Mistwisps. Keep Brambles near. | A spot beside its longest open stretch |
| 6-1 | Use at most 1 gate. | At a bridge one road crosses over another. Walkers go straight across. | The socket that sends walkers over the bridge and back under it |
| 6-2 | Have at most 6 towers. | Creatures near a Scarecrow take more damage. Put it where your towers aim. | A spot whose ring covers the road that most spots reach |
| 6-3 | Build no Longbow Lofts. | Every tower aims at a Gleamer. Splash and rings still hit the rest. | A spot beside the road for a Catapult |
| 6-4 | No tower above tier 2. | Sleepyheads nap once and get up. Keep towers further down the road. | A spot further down the road |
| 6-5 | Call 6 waves early. | none | none |
| 6-6 | Lose no lives. | Old Hayrick draws every shot and gets up once. Splash its escort. | A spot beside its longest stretch |
| 7-1 | Have at most 6 towers. | Ice slides only go the way their arrows point. Watch the line. | The socket that sends walkers around the slide loop |
| 7-2 | Build no Pumpkin Catapults. | Snow Forts roll snowballs in a line. Build them at the end of a long road. | A spot at the end of a long straight road |
| 7-3 | Use no gates. | Snowrollers grow with every tile. Pop them early or keep their road short. | A spot near the entrance |
| 7-4 | Have at most 7 towers. | Yawners make towers beside them doze. Towers set back stay awake. | A spot two tiles from the road |
| 7-5 | No tower above tier 2. | none | none |
| 7-6 | Use at most 3 kinds of tower. | Snowsnore grows as it walks and yawns towers asleep. Hit it early. | A spot near the entrance |
| 8-1 | Have at most 6 towers. | Hollow stumps come in twins. Walkers that step into one come out of the other. | The socket on the road into a stump |
| 8-2 | Build no Sling Posts. | Moth Lanterns pull flyers low. Then every tower can hit them. | A spot under the flight line beside the ground towers' spots |
| 8-3 | No tower above tier 2. | Blinkers jump ahead every 3 seconds. Cover long stretches, not one spot. | A spot that sees a long stretch |
| 8-4 | Build no Lullaby Bells. | Hootlings keep everything near them awake. Nothing near one can be slowed. | A spot beside the road for big hitters |
| 8-5 | Use at most 3 kinds of tower. | none | none |
| 8-6 | Lose no lives. | Glimmertoad hops ahead and can't be slowed. Lure its Flitters low. | A spot under the flight line beside its route |

Why some of these:

- **7-3, "Use no gates."** Gates usually make the road long. Against Snowrollers a long road feeds them, so the star asks the player to win on the short road, near the entrance. It is the region's lesson in one line.
- **8-2, "Build no Sling Posts."** As on the flyer levels of region 3 (TUNING_CAMPAIGN.md 1.1), it asks for the region's new answer: Moth Lanterns, or Fireworks, with ground towers under the flight line.
- **5-3 and 8-4, "Build no Lullaby Bells."** Bells help Mossbuds regrow and do nothing near a Hootling, so the star points away from them. Every other tower stays usable.
- **6-6 and 8-6, "Lose no lives."** In regions 1 and 3 this rule let one tower type buy its way through (RULES 12.5). These are boss levels with flyers and a boss that needs several kinds of tower, so it may hold here. If the bots find a lone tower earning it, the fallback is "Have at most 8 towers."

## 7. Stars and unlocks

| Unlock | Needs |
|---|---|
| Region 5 | Level 4-6 cleared and 24 stars |
| Region 6 | Level 5-6 cleared and 30 stars |
| Region 7 | Level 6-6 cleared and 36 stars |
| Region 8 | Level 7-6 cleared and 42 stars |
| Regions 2 to 4, the roguelite and daily, Twists | Unchanged (RULES 16): 6, 12 and 18 stars; 12 stars; 3 stars on the level |
| New content in runs and the daily | Each region's content after its boss level is cleared (9.1) |

rules.json `region_stars` becomes `[0, 6, 12, 18, 24, 30, 36, 42]`. That is 8 values, the most the contract allows today (2.6).

No grind walls. The argument of RULES 16 still holds: every cleared level gives at least 1 star, on Normal or Relaxed, and clearing every level of a region once gives exactly 6 stars. So clearing regions 1 to 4 once gives exactly the 24 stars region 5 needs, and so on up to 42 for region 8. A one-star player reaches the end of the campaign. Relaxed is always there, and second and third stars open only Twists and some roguelite cards, which are variety.

No current threshold moves. The card unlocks at 24, 36, 48, 60 and 72 stars stay. With 144 stars in the game instead of 72, they now come sooner in the whole journey: Pip Parade at 72 stars no longer needs every star of regions 1 to 4. They add variety, never power, so I keep them as they are. Doubling them would make players who already earned them wait again.

## 8. Twists (RULES 13 format)

Every Twist uses an effect type the game already has (contract 2.8), so no new effect type is needed. Each fits its level's lesson and none repeats the level's star 3. Card text is at most 80 characters.

| Level | Twist | The one rule changed | Card text | Effect |
|---|---|---|---|---|
| 5-1 | One Gate | The level gives 1 gate instead of 2. | You get 1 gate instead of 2. | `set_gates` 1 |
| 5-2 | No Catapults | The Pumpkin Catapult cannot be built. | Pumpkin Catapults cannot be built. | `ban_tower` `pumpkin_catapult` |
| 5-3 | Tier 2 Cap | No tower can go above tier 2. | No tower can go above tier 2. | `tier_cap` 2 |
| 5-4 | No Sling Posts | The Sling Post cannot be built. | Sling Posts cannot be built. | `ban_tower` `sling_post` |
| 5-5 | Five Lives | Start with 5 lives. | Start with 5 lives, or 10 on Relaxed. | `set_lives` 5 |
| 5-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. | `count_pct` 200, last wave |
| 6-1 | Stuck Gates | Both gates start placed on sockets the level sets. They cannot be moved or removed. | Both gates are stuck on their sockets for the whole level. | `fixed_gates`, two cells |
| 6-2 | No Bells | The Lullaby Bell cannot be built. | Lullaby Bells cannot be built. | `ban_tower` `lullaby_bell` |
| 6-3 | Twice the Wings | Every group of flyers has twice as many. | Twice as many flyers in every wave. | `count_pct` 200, flyers |
| 6-4 | No Selling | Towers cannot be sold. | Towers cannot be sold. | `no_selling` |
| 6-5 | Thin Purse | Start with half the gold, rounded down to a multiple of 10. | Start with half the gold. | `start_gold_pct` 50 |
| 6-6 | Double Trouble | As 5-6. | The final wave is twice as big, with two bosses. | `count_pct` 200, last wave |
| 7-1 | No Gates | The level gives 0 gates. | You get no gates. | `set_gates` 0 |
| 7-2 | No Longbows | The Longbow Loft cannot be built. | Longbow Lofts cannot be built. | `ban_tower` `longbow_loft` |
| 7-3 | Hurry | Every creature moves 20% faster. | Every creature moves 20% faster. | `speed_pct` 120 |
| 7-4 | Thick Shells | Every creature has 2 more armor. | Every creature has 2 more armor. | `armor_add` 2 |
| 7-5 | Bubble Night | Every creature carries a bubble. | Every creature carries a bubble that comes back 2 seconds after it pops. | `all_bubbles` |
| 7-6 | Double Trouble | As 5-6. | The final wave is twice as big, with two bosses. | `count_pct` 200, last wave |
| 8-1 | One Gate | The level gives 1 gate instead of 2. | You get 1 gate instead of 2. | `set_gates` 1 |
| 8-2 | No Fireworks | The Firework Tower cannot be built. | Firework Towers cannot be built. | `ban_tower` `firework_tower` |
| 8-3 | No Bells | The Lullaby Bell cannot be built. | Lullaby Bells cannot be built. | `ban_tower` `lullaby_bell` |
| 8-4 | Twice the Wings | Every group of flyers has twice as many. | Twice as many flyers in every wave. | `count_pct` 200, flyers |
| 8-5 | Five Lives | Start with 5 lives. | Start with 5 lives, or 10 on Relaxed. | `set_lives` 5 |
| 8-6 | Double Trouble | As 5-6. | The final wave is twice as big, with two bosses. | `count_pct` 200, last wave |

Why some of these fit:

- **5-1 One Gate and 8-1 One Gate.** The feature levels: with one gate, the choice of which tunnel road or which way into a stump to close is the whole puzzle.
- **6-1 Stuck Gates.** The level sets the gates so walkers must loop over the bridge and back under it. The player builds around a loop they did not choose.
- **7-1 No Gates.** The slides alone decide the route.
- **5-4 No Sling Posts.** Mist stops aim, so the player leans on rings, lines and splash. Since the region 5 tuning (2026-10-29) this ban is 5-4's third star, and its Twist is No Gates (`set_gates` 0): the walkers then take the short middle road through both tunnels, under the mist (docs/design/TUNING_R5.md, RULES 13).
- **8-2 No Fireworks.** Flyers fall to Moth Lanterns and the ground towers, or to Sling Posts.
- **Double Trouble** on three boss levels, as in regions 1, 3 and 4. Two Burrowbellies summon 4 Mistwisps at a time, inside the 8 summoner bound. Two Glimmertoads release 12 Flitters, inside the spawn bound.

RULES 13 still applies: a Twist unlocks with 3 stars on its level, has no stars, and the bots must win it on Normal.

## 9. Roguelite and daily

### 9.1 When new content joins: content tiers

- New content joins runs and the daily one region at a time, when that region's boss level is cleared, on Normal or Relaxed.
- Tiers have their own data. run.json gets a `tiers` list of 4 tiers. Each names its boss level and the towers, creatures, bosses and grid characters it adds. Tier 0 is everything in today's game and needs no entry.

| Tier | Boss level | Towers | Creatures | Bosses | Grid characters |
|---|---|---|---|---|---|
| 1 | `r5_l6` | `bramble_cottage` | `mossbud`, `mistwisp` | `burrowbelly` | `T` |
| 2 | `r6_l6` | `scarecrow` | `gleamer`, `sleepyhead` | `old_hayrick` | `X` |
| 3 | `r7_l6` | `snow_fort` | `snowroller`, `yawner` | `snowsnore` | `^`, `v`, `<`, `>` |
| 4 | `r8_l6` | `moth_lantern` | `blinker`, `hootling` | `glimmertoad` | `P`, `Q` |

- The player's tier is the number of listed boss levels cleared, 0 to 4. It comes from the level records, so progress.json needs no new field.
- Everything else takes its tier from these lists. A card's tier is its tower's tier, and a card with no tower is tier 0. A pack's tier is the highest tier among its creatures and its boss, counting the creatures they summon, split into or release. A segment's tier is the highest tier among its grid characters. Anything not listed is tier 0.
- A run uses only things whose tier is at most the run's tier. A run keeps the tier it started with, saved with the run.
- A tier 0 run equals today's run exactly. Things of tiers 1 to 4 are left out of every list before any pick, and the picks walk the lists in file order as now (contract 3.4). So the same seed gives today's boss, map, packs, waves and offers, and a tier 0 daily is today's daily on every date. Tests pin this.
- Why per region and not per level: run packs and segments are hand-built, and each mixes several new things. Joining per level would give the bots 21 states to check instead of 5. A player who has met a tower in the campaign waits at most four levels to see it in runs.

### 9.2 Cards

- Four tower cards, `tower_bramble_cottage`, `tower_scarecrow`, `tower_snow_fort` and `tower_moth_lantern`, like the five base tower cards (RULES 14.5).
- Four base perks, one per new tower, each once per run. They use stats the cards already use (contract 2.8), so no new effect type:

| Card | Tower | Effect | Effect data |
|---|---|---|---|
| Thorn Tips | Bramble Cottage | Deals 2 more damage per hit. | `tower_add` damage 2 |
| Big Hat | Scarecrow | Its ring reaches 0.5 tiles further. | `tower_add` reach 50 |
| Packed Snow | Snow Fort | Deals 6 more damage per hit. | `tower_add` damage 6 |
| Bright Wick | Moth Lantern | Reaches 1 tile further. | `tower_add` reach 100 |

- The four new perks are base perks of their tier, not unlockable perks: their `unlock` is `{}`, and their tier comes from their tower (9.1). Once their tier is in the run, RULES 14.4 treats them exactly as the other base perks, so an unlocked perk waits until no base perk, old or new, is eligible.
- A card joins a run's pool only when its tier is at most the run's tier. Everything else in RULES 14.4 stays: the weights, the first slot while the run has fewer than 3 kinds of tower, and the rule for unlocked perks.
- The daily's pool is every card whose tier is at most the daily's tier, unlocked or not, as today's daily uses every card (RULES 15).
- No new gate, economy or risk cards.

### 9.3 Waves and maps

- New creatures join these run bands: Mossbud and Sleepyhead in band 2, Gleamer, Snowroller and Blinker in band 3, Mistwisp and Yawner in band 4, Hootling in band 5.
- Each region adds packs that use its creatures, at least one in each band from its creatures' bands on, plus two band 6 packs for its boss. A pack is eligible only when its tier (9.1) is at most the run's tier. Every band keeps its 4 or more packs of today, so tier 0 runs keep today's packs.
- **New creatures in packs.** Every pack shows each tier 1 to 4 creature it uses as if it were new. That creature comes in the first group of the first wave of the pack that has it, no group of that wave starts before it, and a wave shows at most one such creature. Today's rule for creatures the run has not shown yet (RULES 14.3) still holds, and no wave shows two creatures as new, counting both kinds. Tests check every choice of packs at every tier. Why: the player has met these creatures in the campaign, but a run can bring them in any band, so each pack brings them in gently, at the front where the player sees them first.
- Each region adds two or three middle segments with its feature, using the ports of today's segments, so every top and bottom still fits. A segment holds at most one feature, in its middle three rows, and its top and bottom rows stay plain road. A segment is eligible only when its tier is at most the run's tier. Every stack still meets RULES 14.2: 11 or 12 spots, 2 to 5 sockets and the Bakery spot. No tunnel tile is next to a socket on any stack, across the seams between segments too (3.4). Tests check every stack at every tier.
- **The ground of a run map.** A run map takes the ground of the region whose feature it holds: Hollow Lanes for tunnels, Russet Orchards for bridges, Frostpine Ridge for slides, Starglen for stumps. A map with no feature keeps today's meadow, Lantern Hill's ground. Regions 2 to 4 have grounds of their own now (2), but no feature, so a run map never takes theirs. Since a segment holds at most one feature and only middles hold features, a map never has two.
- The seed picks among the eligible segments, packs and bosses exactly as now (contract 3.4). So the same seed and the same tier always give the same run.

### 9.4 The daily

Today the daily is the same run on every phone, because it uses every card (RULES 15). Content that joins by progress breaks that, so these were the choices. Bart chose A on 2026-10-27: the daily follows content tiers, and a tier 0 daily is exactly today's.

| Option | Same run on every phone? | New content in the daily? | Cost |
|---|---|---|---|
| A. Tiers (my recommendation, Bart's choice) | Yes, for every player at the same tier. All new players share tier 0, and everyone who finishes the campaign shares tier 4 | Yes, once earned | The daily record and run saves keep the tier. The bots check the daily at all five tiers |
| B. Base content only | Yes, always | Never | None |
| C. Everything for everyone | Yes, always | Yes, even before the campaign brings it, with first sight cards, as runs show v1 content today | None, but it goes against "once unlocked in the campaign" |

Why A: with no network and no leaderboards, "the same daily" matters only when two players compare. A keeps the daily the same for players at the same stage and still rewards progress. The daily card names its regions, for example "Regions 1 to 6", so two friends see why their runs differ.

Rules for A, now in RULES 14.9 and 15:

- The daily's tier is the player's tier when they start that day's first daily. It holds for the whole day: the daily record stores it with the day's best, and a daily in progress keeps it in its save. A tier earned later that day joins tomorrow's daily, so the day's best always compares the same run.
- The seed is still the date. The daily uses only things whose tier is at most its tier (9.1), and its pool is every card of those tiers, unlocked or not (9.2). Always Normal.
- A tier 0 daily is exactly today's daily for that date (9.1).

### 9.5 Balance risks

- **Draft dilution.** At tier 4, 9 tower cards share the tower weight instead of 5, and 10 base perks come before any unlocked perk instead of 6. Each tower is offered less often and unlocked perks wait longer. The bots check RULES 14.8 at tier 0 and tier 4. The regions 6 and 7 pass (2026-10-29) found the bots losing more runs at tiers 2 and 3 because they take nearly every tower card and build every kind, not because the new content is harder. The bots now keep two habits from tier 2 on, and RULES 14.8 reads a missed bar a second time with the newer tower cards out of the pool (docs/design/TUNING_R67.md).
- **The Yawner on run maps.** Every run map has a Bakery spot with 3 neighbors (RULES 14.2), exactly what a Yawner punishes. Keep Yawners in band 4, a few per wave.
- **The Moth Lantern against Moon Moth packs.** A run with Lanterns and Giant Bows may find the Moon Moth easier. The per-pack boss bar (RULES 14.8) catches it.
- **Run length.** Gleamers, Sleepyheads and Mossbuds add hidden health, so waves may run longer. Watch the 12 to 16 minute bar.
- **The card experiment.** Each new perk must move the win rate by 5 points or less (RULES 14.8).
- **Test cost.** Run reports run at least tiers 0 and 4, and the daily check runs all five tiers.

## 10. Names

Ids follow docs/art/NAMES.md and contract 2.1: lowercase `a` to `z`, `0` to `9` and `_`, starting with a letter, at most 32 characters. Display names are at most 24 characters. None is another game's name or a famous character as far as I know. Two choices were made for that reason: "Gleamer" instead of "Dazzler", a famous comic book character, and "Mossbud" instead of names close to another game's moss creatures. The art director checked every name and silhouette after me (docs/art/EXPANSION_LOOK.md 1 and 2), and Bart approved the result on 2026-10-27. The names are in docs/art/NAMES.md too. The silhouettes below are the art director's, in short. EXPANSION_LOOK.md 2 is their source.

| Kind | Id | Name | Silhouette |
|---|---|---|---|
| Region | `hollow_lanes` | Hollow Lanes | |
| Region | `russet_orchards` | Russet Orchards | |
| Region | `frostpine_ridge` | Frostpine Ridge | |
| Region | `starglen` | Starglen | |
| Tower | `bramble_cottage` | Bramble Cottage | A small cottage whose whole roof is a great tangle of thorny bramble |
| Path 0 | `wild_bramble` | Wild Bramble | A wider, spikier tangle with two canes looping over the top |
| Path 1 | `holly_crown` | Holly Crown | A rounder holly bush crowned with spiky holly leaves and red berries |
| Tower | `scarecrow` | Scarecrow | A field scarecrow on its post behind a small hut, arms spread, a lantern hanging from one hand |
| Path 0 | `tall_scarecrow` | Tall Scarecrow | Raised a little, with a hat half again as wide |
| Path 1 | `crow_keeper` | Crow Keeper | A crow on each arm, one flapping |
| Tower | `snow_fort` | Snow Fort | A wide wall of warm cream snow bricks with a glowing door, a flag and a snowball on top |
| Path 0 | `big_snowball` | Big Snowball | One huge snowball |
| Path 1 | `flurry` | Flurry | A stack of six small snowballs |
| Tower | `moth_lantern` | Moth Lantern | A lamplighter's booth with a tall curled post and a big lantern. Two tiny moths in the light are a detail, not part of the shape |
| Path 0 | `beacon_lantern` | Beacon Lantern | One big lantern on a straight post |
| Path 1 | `lantern_garland` | Lantern Garland | Three small lanterns on a string |
| Creature | `mossbud` | Mossbud | A walking flower bud with a curled tip and a frill of two leaves |
| Creature | `mistwisp` | Mistwisp | A small bean body with a tall spiral of mist rising from its head |
| Creature | `gleamer` | Gleamer | A plump body with a fan of five feathers raised behind it, each tipped with a round gleam |
| Creature | `sleepyhead` | Sleepyhead | A round body in a long floppy nightcap, eyes half shut |
| Creature | `snowroller` | Snowroller | A small creature running on top of the big snowball it rolls |
| Creature | `yawner` | Yawner | A droopy creature with long ears, mouth open in a yawn, a patched quilt over its back |
| Creature | `blinker` | Blinker | A small upright hopper with a big round head and two huge eyes, never a small ghost |
| Creature | `hootling` | Hootling | A small owlish creature standing tall, with a heart-shaped top and a pale face |
| Boss | `burrowbelly` | Burrowbelly | A big round digger with a pot belly, a pointed snout and two huge spade paws |
| Boss | `old_hayrick` | Old Hayrick | A walking haystack with two straw arms raised high and a small sheaf on top |
| Boss | `snowsnore` | Snowsnore | A low droopy-eared beast with a big snowball on its back, like a snail's shell |
| Boss | `glimmertoad` | Glimmertoad | A huge, low, squat toad with tall eye bumps and glowing spots on its back |
| Card | `tower_bramble_cottage`, `tower_scarecrow`, `tower_snow_fort`, `tower_moth_lantern` | (tower cards take the tower's name) | |
| Card | `thorn_tips`, `big_hat`, `packed_snow`, `bright_wick` | Thorn Tips, Big Hat, Packed Snow, Bright Wick | |
| Levels | `r5_l1` to `r8_l6` | The level names in 6.3 | |

Map features need no ids. Their tiles are grid characters (3.4 to 3.7), and players read them as tunnel, bridge, ice slide and hollow stump. Plurals for "Build no ..." are in 4.7.

Names I watched, and how they ended:

- **Scarecrow** is a plain word, but it is also the name of well-known characters in a classic children's story and in comic books. The art director kept it: draw a field scarecrow on a post, never a walking straw man.
- **Hootling.** "Hoot" is a plain word, but owl creatures in other games use it too. I think the name is far enough apart, and the art director kept it.
- **The Yawner** was the Snoozer. Next to the Sleepyhead it read as a second creature that sleeps, in the next region, so the art director renamed it, and Bart agreed. "Yawner" says what it does and matches its card and Snowsnore, which yawns too.
- **Stone Circle**, level 8-5. Its first name is a plain word, but also a well known spell name in a big online game, and the name of a well known children's learning app. The art director offered Stone Circle as a spare, for Bart or me to choose. I chose it: it fits Starglen's standing stones.
- The art director's other watch notes (Flurry, Blinker, Glimmertoad, and Bramble Cottage next to Hollow Lanes) are in docs/art/EXPANSION_LOOK.md 1. All of those names stay.

## 11. Engineering impact

Short lists, so the architect can plan the contract changes. Nothing here is decided until the architect writes it into the contract.

### 11.1 Contract changes (architect)

1. Grid characters `T`, `X`, `^`, `v`, `<`, `>`, `P` and `Q`, with the placement checks of 3.4 to 3.7 (2.3).
2. A level's `towers` list grows from at most 6 to at most 10 (2.4).
3. towers.json: an attack that hits every creature it can hit in reach, with no aim (Bramble), a line width (Snow Fort, whose line is a segment from the tower through its target, cut at the map's edge), a lure time (Moth Lantern), and a fourth kind for the Scarecrow with its fright percent and 1.0 s linger (2.6).
4. enemies.json: regrow, mist (it covers the wisp's tile and the four next to it, so it needs no reach), dazzle, nap time, growth percent and its cap, yawn (every, reach, doze time), blink (every, tiles), wake reach, and digging (first, every, how long). Release checks: Burrowbelly summons Mistwisps, which hide but never heal (2.6).
5. Routing on nodes, not cells: two nodes on a bridge, slide directions, stump steps. `RoadMap.distances` and `route()` change shape, and route lines need over and under at bridges, under at tunnels and a jump at stumps (section 4).
6. Battle queries: the new statuses in `enemy_numbers` (hidden, out of reach, napping, frightened, low, awake, grown max health) and dozing in `tower_numbers`. New events, for example `burrowed`, `surfaced`, `napped`, `woke`, `blinked` and `yawned` (3.1).
7. Runs: run.json `tiers` (9.1), a content tier in `RunSession.start`, `RunData` filters for cards, packs, segments and bosses by tier, the pack rule of 9.3, and the daily's tier (2.9 to 2.11, 3.4).
8. Theme: `MapArt` takes the region, for its ground colors and scenery, in all 8 regions. Lantern Hill keeps today's meadow, regions 2 to 8 each get their own ground (Bart chose 2 to 4 on 2026-10-27), and a run map takes the ground of its feature, or the meadow when it has none (9.3) (3.9).
9. Save ceilings for the new timers, an at-once bound for creatures that wake, and growers counted at their cap in the wave health ceiling (5.6).

### 11.2 Per area

| Area | Needs |
|---|---|
| Sim | Routing on the node graph. The out of reach status. Bramble pulses, Snow Fort lines (squared distance from a point to a segment, integers only), lures and low flyers in every tower's targeting, frights in the damage step. Every creature rule of 5.2 and boss rule of 5.3, in the tick order of 5.5. Save and restore of every new timer. Tests for every rule, determinism, and snapshot and restore on levels with each new thing. The perf test with Mistwisps and Hootlings in the crowd. |
| Theme | 4 towers at tier 1, tier 2 and both paths, 8 creatures and 4 bosses, distinct by shape under the silhouette test. A ground palette and scenery for each of regions 2 to 8, with contrast checks, keeping warm for ours and cool for theirs. Feature tiles: the tunnel mound, the plank bridge, slide chevrons, stumps with a crescent and a star. The status marks of 5.4. |
| Render | Region grounds. Walkers hidden in tunnels and stumps. Route lines over and under bridges and through stumps. Shots: the thorn pulse, the rolling snowball, the lantern beam. A pulse or a line is one drawn shot, however many creatures it hits, so the 96 shot cap holds. Growth scaling, blink and hop sparkles, the dirt mound, the yawn ring and the nap pose. A Fold5 measurement of the most crowded new wave. |
| Audio | A `fired` sound for the Bramble Cottage, Snow Fort and Moth Lantern and their paths. A sound or a deliberate silence for each new event. No new music needed. |
| UI | A build panel that fits up to 10 towers on the cover screen at 48 dp, in two rows or a scroll. Tower panels for pulses, lines, lures and frights. Creature panels with the new statuses. LevelSelect with 8 regions. The Info screen with the new towers, creatures, bosses and the four map features. The daily card names its regions. |
| Levels | 24 levels with their Twists, and 8 regions in campaign.json. Tests for the feature rules of 3.4 to 3.7, slides that still reach the base with no gates, stump pairs, no tunnel beside a socket (on every level and across the seams of every run stack), the star 3 table and the Twists. New run segments and packs by tier, packs that show each tier creature as if new (9.3), and the new creature rule at every tier. |
| Balance bots | The plain mixed recipe for regions 5 to 8 (below). Lone searches for the Bramble Cottage and the Snow Fort. The Moth Lantern skipped where walkers cost 6 lives or more, like the Firework. The Scarecrow counted as support, like the Bell. Run reports at tiers 0 and 4, the daily at all five. The largest wave and the tick time on every new level. |
| Saves | progress.json: no change, since new level and seen ids fit its 512 entry caps. Saved games: new battle fields, each optional with a safe default, so a game saved before the update still loads. Run and daily saves: `tier`, 0 to 4, missing means 0. daily.json: `tier` for the day's record, missing means 0. rules.json, a data file: `region_stars` with 8 values. Older saves: this plan changes no number of today's towers, creatures or rules. No reload time of a current tower, and no heal, summon, break or bubble time of a current creature in regions 1 to 4, gets shorter. So the timers in a mid-wave save made by today's build stay inside the ranges the load checks allow, and it keeps loading after the update. |

Proposed plain mixed recipe for regions 5 to 8 (RULES 12.6), for the balance analyst to confirm: the attacking towers in turn become Sling Post, Pumpkin Catapult, Longbow Loft, Bramble Cottage, Snow Fort, then Firework Tower and Moth Lantern on levels whose waves bring flyers. One Scarecrow joins the Bell and the Bakery, on the fifth spot in the spot order, or the sixth if the Bakery has the fifth. Road seen counts only road tiles outside tunnels. Tier 3 takes each attacking tower's first path, as today, and the Scarecrow stays at tier 2 with the Bell and the Bakery. RULES 12.6 now holds it.

## 12. Bart's answers

Bart answered on 2026-10-27, when he approved this file:

1. **The daily** follows content tiers (option A of 9.4). Every player at the same stage shares the same daily, and a tier 0 daily is exactly today's. The daily card names its regions so friends see why runs differ.
2. **The Snoozer** is renamed Yawner, as the art director proposed.
3. **Regions 2 to 4** get their own ground colors and scenery too. Play does not change.
4. **Still no mid-wave gate switch.**

For the record, not questions:

- **When new content joins runs.** One region at a time, when the region's boss level is cleared (9.1). That is how this plan reads "once the player has unlocked them in the campaign". It keeps the bots to 5 states instead of 21, and a player waits at most four levels to see a tower in runs.
- **Card unlock thresholds** stay at 24 to 72 stars (section 7).
- **The limited mid-wave gate switch** stays out. Bart chose no mid-wave gate switch at hard stop A, and nothing in this plan needs one.

## 13. Suggestions beyond the task

1. A music loop per region, or the battle loop with a different lead instrument per region. Today one battle loop plays everywhere.
2. If players find the stumps or slides confusing in a playtest, a one-time info card for each map feature, like the creature cards. The hint and the highlight should be enough, so I left it out.
3. Unlockable second perks for the four new towers, in a later update, if tier 4 runs feel samey.
