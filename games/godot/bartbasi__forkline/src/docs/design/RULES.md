# Forkline rules, version 1

Approved by Bart at hard stop A, 2026-10-23, and grown to 8 regions with the expansion he approved on 2026-10-27. Owner: game designer.

Phase 4 additions, 2026-10-23. No number changed. Added: the Puff's card line and the word "pop" (6.6), tower plurals (5.9), and the answers to the contract's open points: pausing on a size change (4.7), leaving and coming back (4.10), early calls in runs (4.9, 14.4), where released creatures appear (6.2, 6.3), Gateless Night (14.5) and Iron Gate (7.6, 14.6).

Clarifications, 2026-10-23, after the sim was built. No number changed. Settled: a level or run is won only when no wave is left running (4.1, 8.1, 14.1); an upgrade or a reload card never leaves a reload timer above the new reload time (4.6, 5.2); a refund never pays back more than was paid (4.6); and a Bell that slows flyers slows every flyer, the Moon Moth included (5.5, 5.11, 6.3, 6.5, 14.6).

Region 1 tuning, 2026-10-24, after the first balance report. The plan and its evidence are in docs/design/TUNING_R1.md. Changed numbers: Pumpkin Catapult tier 1 range 3.0 to 2.5, tier 2 splash 0.75 to 1.25, Prize Pumpkin splash 1.25 to 1.5, Jam Pot splash 1.0 to 1.25 (5.4); Pip health 12 to 21 and bounty 2 to 3 (6.1). Changed text: the Pip's card line (6.6). Changed plan: region 1 waves, star 3 rules and level 1-6's strength (12.3, 12.4). New: difficulty targets in place of the old wave size guide (12.5). The 5.10 tables are recomputed.

Phase 7 alignment, 2026-10-24 (task G1), after hard stop B and the contract revision of that day. No number changed, here or in data/stats/.

- From Bart's hard stop B approvals: a saved game resumes at 1x (4.8). A third star capped at tier 1 reads "Upgrade no towers." (10.3, 12.4). Level 1-5 is "Wings at Dusk" (12.3). The approved fun review items that touch the rules: star lines in Pause and warnings before a tap that loses star 3 (10.6), new hints on 1-2 and 1-3 with 1-3 now highlighting a spot (9.6, 12.4), and a line on the loss panel that points to Relaxed (11).
- Approved wording changed to match the contract, for the DM to tell Bart:
  - 9.1: in portrait the wave preview opens in a build phase only when it fits under the map. Otherwise the build phase starts with it folded into its one line strip, which still shows each group's creature, count and entrance. Landscape is unchanged.
  - 14.4: no risk card once wave 17 has started. It was "none in the draft after wave 17", which let a risk card reach the boss wave after an early call of wave 17.
  - 3.1 and 14.2: the bottom row of a 13 row map is scenery only.
  - 9.2: a creature met on the map before its card has opened pauses the game and opens its card.
  - 14.6: Piggy Bank pays after the clear bonus, on all the gold held. An unlocked card joins from the next run on.
- Made precise, with nothing approved changed: Bubble Night's bubbles come back as a Bubbler's do (13). What Twist and risk card effects reach, and that count changes never touch Puffs or added groups (6.4, 13, 14.5). A tower fires at most once a tick (5.2). A Puffball's first Puff comes on the next tick (6.2, 8.1). The largest wave counts Puffs but not boss summons, which the bots measure (12.5). Route lines and the preview show a waiting risk card (7.5, 9.1). The call button highlight (9.6). Targets per shot in the tower panel (9.3). "Reach wave N" (14.6). Risk rewards, added groups and card floors (14.5, 14.6). Segments, packs and draft details (14.2 to 14.4). The daily's date check (15).
- New: a card text for every Twist (13), a guide of 4 groups or fewer a wave (12.5), and the balance checks with the plain mixed recipe for every region (12.6).
- One Twist changed, the same day. Level 1-3's Twist is now Tier 2 Cap, `tier_cap` 2, card text "No tower can go above tier 2.", the same as 3-5's (13). It replaces No Upgrades, which the bots could not win on Normal with tier 1 towers (TUNING_R1.md S4). The DM chose it on 2026-10-24, on the game designer's advice. The level data and contract 2.8 already use it. It changes the Twist list approved at hard stop A, so it is for the DM to tell Bart.

Region 2 tuning, 2026-10-24 (task G2), after the region 2 balance report. The plan and its evidence are in docs/design/TUNING_R2.md. Changed numbers: Ironshell's armor 6 to 10 (6.3) and its card line (6.6), with the 5.10 Ironshell columns recomputed and a note there that Bells help single-target towers too. Changed plan: level 2-2's star 3 is now "Use no gates." and level 3-2's is "Have at most 6 towers." (12.4); level 3-1 keeps one entrance, and the boss waves' strengths are listed (12.3). New: three guides for building waves (12.5), the search minimum and two shortcuts for the "No super tower" check (12.6), and starting a new run or daily over a saved one (4.10, 14.7). The region 2 wave changes are in TUNING_R2.md. Items 2-2's star 3, Ironshell's armor, 3-2's star 3 and 3-1's entrance change what Bart approved, so they are for the DM to tell Bart.

Run tuning, 2026-10-25 (task G3), after the first run and daily report. The plan and its evidence are in docs/design/TUNING_RUNS.md. Changed rules: lives never rise above the starting lives (4.4), so on Normal a run's boss must be beaten (6.3, 14.1); wave 18's strength comes from its boss pack (6.4, 14.1, 14.3). Changed numbers: run maps hold 11 or 12 build spots and a Bakery spot that reaches 3 others (14.2); Tea Break's text, Sharp Pebbles 1 more damage instead of 2, Hurry Night 50% faster for 60 gold, Gateless Night 60 gold (14.5); Pip Parade 16 Pips for 120 gold, and Volley's arrows deal 25% less damage instead of 40% (14.6). New: the targets for the balance bots (14.8) and the daily's bar (15). Proposed, and chosen by Bart the same day: a new run length (1, 14.1, 14.8). Every item here changes what Bart approved, so all are for the DM to tell Bart. data/stats/ does not change.

Campaign tuning, 2026-10-25 (task G4), after the campaign pass of all 24 levels and every Twist (docs/balance/campaign-2026-10-25.md). The plan and its evidence are in docs/design/TUNING_CAMPAIGN.md. Changed plan: the third stars of 3-1, 3-2, 3-3 and 3-6, and the hints of 2-3, 3-4 and 4-1 (12.4), with a line on region 3 in the guide to third stars (12.5). Level 3-6's waves 5 and 9 bring fewer Pips, so the plain recipe wins on Relaxed with no gates (TUNING_CAMPAIGN.md). Changed checks: on a level whose third star bans a tower, the search for all three stars uses the other towers, the banned tower needs no lone search, and a Twist that a short search does not win gets two long ones (12.6). The third stars and hints change what Bart approved, so they are for the DM to tell Bart. No number changes, here or in data/stats/.

Run tuning, 2026-10-26 (task G5), after the second run and daily report (docs/balance/runs-2026-10-26.md). The plan and its evidence are in docs/design/TUNING_RUNS.md section 9. Changed rule: an unlocked tower perk is offered only while no base tower perk can be offered (14.4, 14.6), so unlocking cards no longer makes the base perks rarer. Changed numbers: Frost Chime's ring 0.25 tiles shorter instead of 0.5, Volley's arrows 15% less damage instead of 25%, and Long Fuse 0.25 s slower instead of 0.5 s (14.6). The bars of 14.8 do not change. Both items change what Bart approved, so they are for the DM to tell Bart. data/stats/ does not change.

Expansion, 2026-10-27. Bart asked for four more regions of six levels each, and approved docs/design/EXPANSION.md, as revised after the architect's review, and docs/art/EXPANSION_LOOK.md the same day. With them came his answers: the Snoozer is renamed Yawner (`yawner`); the daily follows content tiers, and a tier 0 daily is exactly the daily of regions 1 to 4 (14.9, 15); regions 2 to 4 get their own grounds too, which is art only (12.1). This file now holds the whole game, 8 regions and 48 levels:

- New: map features (3.5 to 3.9), four towers (5.12 to 5.15), eight creatures and four bosses (6.1 to 6.3), statuses (8.8) and content tiers for runs and the daily (14.9).
- Changed to hold them: the pillars (1), words and rounding (2), grid heights, tile kinds and roads (3.1 to 3.3), build spots (3.4), the tower list, tower rules, the Night Bell's line, the Bakery, cards, model and pairs (5.1, 5.2, 5.5, 5.8 to 5.11), creature rules, strength, flyers and cards (6.2 to 6.6), the shortest open route on nodes in place of the old 7.3, route lines and route changes (7.5, 7.8), the tick order (8.1), targeting, damage, splash, slows and boosts (8.2 to 8.6), stacking (8.7), what panels and marks show (9.3 to 9.5, 9.7), the tower limit (10.3), the campaign (12.1 to 12.6), Twists (13), runs and the daily (14.1 to 14.6, 14.8, 15), progression (16) and the brief coverage (18).
- No number of a tower, creature or rule of regions 1 to 4 changes. Every new number is a starting target for its region's balance pass.
- Two names change, for the DM to tell Bart. Level 8-5 is "Stone Circle": the art director offered it as a spare and left the choice to Bart or the game designer (EXPANSION.md 10). Level 2-4 is "Two Fords", on the DM's word, after the art director noted that no bridge is ever drawn on a Millbrook map, while the bridge is now region 6's feature.
- data/stats/ follows once the contract defines the new fields. The reasons behind the new rules stay in EXPANSION.md.

Clarifications, 2026-10-27, after the DM's nap ruling in docs/ARCHITECTURE.md 14.5. No number changed. A napping creature does not yawn, break a gate, summon or release either. Its break and summon timers pause until it wakes, and a release begun before the nap still finishes (6.2, 8.8). No creature in the game naps and does any of these, so play does not change. Also made precise, as the sim already plays it: after waiting at 0, a tower's next reload is one tick shorter than a full one (5.2).

Region 5 data, 2026-10-28 (task E5.1). No number changed. data/stats/ now holds region 5's tower, creatures and boss, and rules.json the star counts of all eight regions (16). Made precise, as the sim already plays it: every doze ends when a build phase begins (6.2). Two card lines are clearer, for the DM to tell Bart (6.6): the Mistwisp's no longer reads as if it hides itself, and Burrowbelly's says it is out of reach while dug under.

Region 6 data, 2026-10-28 (task E6.1). No number changed. data/stats/ now holds region 6's tower, creatures and boss. Made precise: the run packs of every tier start in band 3 (14.3). The old words asked for tier 1 and tier 2 packs in band 2, where the rule on new creatures leaves no room, as the level designer found in E5.1. Region 5's packs already start in band 3. A Bramble Cottage's range row reads "Ring", which the DM accepted (9.3). Burrowbelly's two band 6 packs, built in E5.1, join the table of 14.3. The Scarecrow's card line and the 6-2 hint now say "Walkers", not "Creatures", because only the Crow Keeper frightens flyers that a Moth Lantern has not lured low (5.9, 12.4). That is for the DM to tell Bart.

Region 7 data, 2026-10-28 (task E7.1a). No number changed. data/stats/ now holds region 7's tower, creatures and boss. Made precise, as the game already shows it: once a Snowroller or Snowsnore has grown, its panel also gives the max health it started with (9.4). Region 7's band 3 packs can use only the Snowroller, since the Yawner joins in band 4 (14.3). Old Hayrick's two band 6 packs, built in E6.1, join the table of 14.3, and 6.3 now says its escort walks on in a run, because a campaign boss wave brings no escort (12.5). The guide for building waves now names the late Pip crowd at strength 160 to 210, which levels of regions 3, 4 and 6 already use (12.3, 12.5). It also settles three region 6 calls from the level designer's E6.1 report (12.4). Level 6-1's third star is now "No tower above tier 2." in place of "Use at most 1 gate." Level 6-4 keeps its third star and gets a late Pip crowd in the region 6 tuning. Level 6-6's hint no longer tells the player to splash Old Hayrick's escort, which it does not have there. The 7-2 hint says "a straight road" instead of "a long road", because a Snow Fort's line needs a road that runs straight at it, and road past its range adds nothing. The third star of 6-1 and the hints of 6-6 and 7-2 change what Bart approved, so they are for the DM to tell Bart.

Region 5 tuning, 2026-10-29 (task E5.3), after the region 5 balance report (docs/balance/region5-2026-10-28.md). The plan and its evidence are in docs/design/TUNING_R5.md. Changed numbers: the Bramble Cottage hits harder at every tier (tier 1 from 4 to 10, the others twice as hard) and its rings are wider (5.12), with its rows of the 5.10 model recomputed. The boss waves of Burrowbelly's two run packs change strength (14.3). Changed plan: the third stars of 5-1, 5-3, 5-4 and 5-6 (12.4), with a line on region 5 in the guide to third stars (12.5), and level 5-4's Twist, now No Gates (13). The level designer's changes to region 5's run segments and packs are in TUNING_R5.md. The Bramble Cottage's numbers, the four third stars and the 5-4 Twist change what Bart approved, so they are for the DM to tell Bart. They go ahead now under the DM's rule of 2026-10-28 (CLAUDE.md).

Region 8 data, 2026-10-29 (task E8.1a). No number of a tower, creature or rule changed. data/stats/ now holds region 8's tower, creatures and boss, the last of the expansion. Snowsnore's two band 6 packs, built in E7.1, join the table of 14.3. Made precise for the packs of tier 4: region 8's band 3 and band 4 packs can use only the Blinker, since the Hootling joins in band 5 (14.3). Glimmertoad's card line now says that 6 Flitters fly out, as every other boss's line gives the count of what it lets out (6.6). Glimmertoad's boss wave on 8-6 starts at strength 50 (1800 health) instead of 75 (2700): a probe on real run maps found that a defense deals it less than half the damage it deals Old Tusk, and on a stand-in 8-6 (7-6's map and waves) the plain recipe won at no gate placement with it at 75 and at 28 of 47 with it at 50 (12.3). The card line and the starting strength change what Bart approved, so they are for the DM to tell Bart.

Regions 6 and 7 tuning, 2026-10-29 (tasks E6.3 and E7.3), after the regions 6 and 7 balance report (docs/balance/region6-7-2026-10-29.md). The plan and its evidence are in docs/design/TUNING_R67.md. No number of a tower, creature or rule changes, and data/stats/ does not change. Changed plan: levels 6-4 and 7-4 get a late Pip crowd in wave 5 and keep their third stars (12.4, 12.5). Old Hayrick's two run boss waves are stronger (14.3), and the first waves of the run packs b3_sleepy_rows and b3_snowballs are lighter (TUNING_R67.md). Made precise: each region's pass checks its own content tier against the same bars, the bots keep two habits of a thoughtful player from tier 2 on, and a bar missed on the hard side gets a second reading with the newer tower cards out of the pool (14.8). The Bramble Cottage watch item now measures need, not share, and the cottage stays as it is (5.10). The waves of 6-4 and 7-4 and Old Hayrick's run strength change what Bart approved, so they are for the DM to tell Bart. They go ahead now under the DM's rule of 2026-10-28 (CLAUDE.md).

Region 8 tuning, 2026-10-30 (task E8.3, with the 5-6 follow-up of E5.5), after the regions 5 and 8 balance report (docs/balance/region5-8-2026-10-30.md). The plan and its evidence are in docs/design/TUNING_R8.md. No number of a tower, creature or rule changes, and data/stats/ does not change. Changed plan: level 5-6's third star is now "Build no Sling Posts." (12.4). On 8-6, Glimmertoad comes at strength 55 (1980 health) instead of 50, wave 9 brings 5 Dusk Moths instead of 3, and in Double Trouble the second Glimmertoad comes 12.0 s after the first instead of 1.0 s (12.3, 12.4, 12.5, 13). Glimmertoad's two run packs join the table of 14.3 with their boss waves at 50, down from 80 and 70, and the last wave of the run pack b4_blinking_watch brings 3 Dusk Moths instead of 4, both as first numbers for the final pass (TUNING_R8.md). Made precise: on a level whose third star is a tower limit or a kinds limit, the "All three stars" check may take two more searches of 6000 builds before it calls the star out of reach (12.6), and a boss group's gap matters only in Double Trouble (12.5). The guide to third stars gains a line on 5-6 and 8-6 (12.5). The third star of 5-6, the waves of 8-6 and the run packs change what Bart approved, so they are for the DM to tell Bart. They go ahead under the DM's rule of 2026-10-28 (CLAUDE.md).

Final balance pass, 2026-10-30 (task G7), after the final balance report (docs/balance/final-2026-10-30.md). The plan and its evidence are in docs/design/TUNING_FINAL.md. No number of a tower, creature or rule changes, and data/stats/ does not change. Changed plan: the last wave of 3-5 brings 33 Pips instead of 32, and its third star stays (12.4). Changed checks: on a level whose third star caps tower tiers, the "All three stars" check may take two more searches of 6000 builds before it calls the star out of reach, as for tower and kinds limits (12.6). From tier 2 on, the run bars on how often runs are won and lost are read with the tower cards of tiers 2 to 4 and their perks out of the pool, floor and ceiling, and the first reading, the pool as the player has it, is reported beside them and is not a bar (14.8). Glimmertoad's two run packs stay at 50 (14.3). The 3-5 wave changes what Bart approved, so it is for the DM to tell Bart. It goes ahead under the DM's rule of 2026-10-28 (CLAUDE.md).

Names follow docs/art/NAMES.md, which Bart approved at hard stop B and which holds the names of regions 5 to 8 that he approved on 2026-10-27. The tables in 5.1, 5.3 to 5.8, 5.12 to 5.15, 6.1, 6.3 and 12.1 give each tower, tier 3 path, creature, boss and region its id from that list, so the data files have one source. In each tower's tier table, the first tier 3 row is spec 0 and the second is spec 1.

This file holds every game rule and number for version 1. The sim engineer, level designer, roguelite engineer, balance analyst and UI engineer build from it. If something here is unclear or seems to conflict with docs/ARCHITECTURE.md, ask the DM. Do not guess.

The numbers are starting values. The balance bots tune them, and every change comes back into this file through the game designer. data/stats/ holds this file's tower, creature and core rule numbers, with the names, plurals and card lines, as data in the contract's units (milliseconds, and hundredths of a tile). This file and those files change together, in the same step. The one exception is the expansion of 2026-10-27: its numbers join data/stats/ one region at a time, in each region's loop (contract section 13). Regions 5, 6 and 7 joined on 2026-10-28, and region 8 on 2026-10-29, so data/stats/ now holds every tower, creature and boss of the game. Section 17 answers the assumptions in the first draft of docs/ARCHITECTURE.md. Section 19 is written for Bart. It holds no rules, and nobody builds from it.

## Contents

1. Design pillars
2. Words, units and rounding
3. The map
4. Core loop
5. Towers
6. Creatures
7. Gates and routes
8. How combat resolves
9. Information on screen
10. Stars
11. Relaxed difficulty
12. Campaign
13. Twists
14. Roguelite mode
15. Daily challenge
16. Progression
17. Answers to the architecture assumptions
18. Brief section 3 coverage
19. For Bart at hard stop A

## 1. Design pillars

These come from brief section 2. Each rule below serves at least one of them.

| Pillar | Where the rules use it |
|---|---|
| Real choices keep players coming back, most of all the moment two towers click together | Ten towers with clear counters (5.1), two tier 3 paths each, pairs to discover (5.11), star challenges (10.3) |
| Players hate ads and pay to win | Everything is earned by playing (16). Unlocks add variety, never power (14.6) |
| Hand-built levels beat generated ones | Every campaign map and wave is hand-built (12). Runs join hand-built segments and hand-built wave packs (14) |
| Clarity over count, no super tower | Every number is shown (9). Combat has no randomness (8.1). No tower is best everywhere (5.10) |
| No ambushes | Wave preview before every wave (9.1). One new thing per wave, each with an info card (9.2, 12.5) |
| Short sessions | Levels take 5 to 10 minutes (12.5). Runs take about 12 to 16 minutes at 1x, about 15 to 20 of real play with card picks (14.1). Pause at any moment (4.7) |
| Path control without fiddly mazes | A few gates on hand-built forks (7), and from region 5 on, map features that change which roads join (3.5) |
| Roguelite runs drive replay | Short seeded runs with card drafts (14) and a daily run (15) |
| Cozy and bright for everyone | Gentle names and one-line cards (5.9, 6.6). Defeated creatures pop into sparkles. No blood |

## 2. Words, units and rounding

| Word | Meaning |
|---|---|
| Tile | One square of the map grid. All distances are in tiles. |
| Creature | Any enemy. A walker or a flyer. |
| Walker | A creature that follows roads. |
| Flyer | A creature that flies straight to the base. It ignores roads and gates. |
| Tower | Anything the player builds on a build spot. |
| Attacking tower | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower, Bramble Cottage, Snow Fort, Moth Lantern. Bells, Scarecrows and Bakeries do not attack. |
| Build spot | A tile where one tower can stand. |
| Gate socket | A road tile where a gate can go. |
| Entrance | Where creatures appear. Marked A, B, C, D on the map. Level data numbers them 1 to 4. |
| Base | The road tile creatures try to reach. |
| Map feature | A tunnel, bridge, ice slide or hollow stump. Regions 5 to 8 bring one each (3.5). |
| Wave | One numbered set of creatures. It is made of groups. |
| Group | One creature type, a count, an entrance, a start time and a gap between creatures. |
| Build phase | The calm time before each wave. Nothing moves. |
| Wave phase | The time while any wave is on the map. |
| Strength | A whole percent on each wave. 100 means the base numbers in this file (6.4). |

Units:

- Distances are in tiles, measured in a straight line between centers.
- Speeds are in tiles per second.
- Times are in seconds. Every time in this file is a multiple of 0.1 s, so it is a whole number of ticks.
- The sim's tick length is set in docs/ARCHITECTURE.md (its first draft uses 50 ms). All rules here are written in seconds.

Rounding:

- Round half up to a whole number for health, heal and regrow amounts and gold scaled by strength (bounties, clear bonuses, risk card rewards), and for percent changes to gold or damage. Example: 52.5 becomes 53.
- Refunds round down.
- The early call bonus rounds up.
- Health and bounty are never below 1.
- Speeds, positions, slows and attack rates follow the contract's integer math in fine sub-units. Any rounding there is far below what a player can see.

## 3. The map

### 3.1 Grid

- A map is 7 tiles wide and 8 to 13 tiles tall. Row 0 is the top row. Rows count down the screen. Columns count left to right.
- South means one row down, north one row up, west one column left, east one column right.
- Why 7 wide: the Fold5 cover screen is 344 dp wide. Seven tiles keep each tile at about 49 dp there, so every build spot and gate socket is a 48 dp touch target (contract section 7.4).
- Heights: region 1 maps are 8 to 11 rows, so the first maps are small and easy to read. Regions 2 to 8 use 10 to 13 rows. Run maps are 13 rows (14.2).
- On a 13 row map the bottom row is scenery only: no road, build spot, gate socket, entrance or base. On the Fold5 cover screen the folded wave preview covers part of that row (9.1). Maps of 8 to 12 rows have no such rule.
- Every range and speed in this file assumes a 7-wide grid, and all of them are in tiles.
- The landscape layout shows the same grid. Grid directions never change with the screen.

### 3.2 Tile kinds

| Kind | Rule |
|---|---|
| Road | Walkers move on road tiles. |
| Build spot | Holds one tower. Never a road tile. |
| Gate socket | A road tile where a gate can go. Never an entrance, the base or a map feature (3.5). |
| Entrance | A road tile on the map edge where creatures appear, walkers and flyers alike. A level has 1 to 4. |
| Base | One road tile. A walker that reaches its center has got through. |
| Tunnel | A road tile under a grassy mound. Walkers inside it are out of reach (3.6). |
| Bridge | A road tile where two roads cross without joining (3.7). |
| Ice slide | A road tile that walkers cross one way only (3.8). |
| Hollow stump | A road tile joined to its twin stump by one step (3.9). |
| Scenery | Everything else. Nothing happens there. |

### 3.3 Roads

- Roads are one tile wide.
- Road tiles connect north, south, east and west. Never diagonally. Map features change some of these joins: the two roads of a bridge never join, an ice slide goes one way, and twin stumps are joined (7.3).
- Roads may fork and join again. That is the point of every map.
- With no gates placed, every entrance must reach the base.
- Creatures never block each other. Any number can share a tile.

### 3.4 Build spots

- One tower per spot.
- Spot order is cell order: row by row from the top, left to right within a row. Towers act in that order every tick (8.1).
- Limited spots are part of the puzzle. Suggested counts:

| Region | Build spots per level |
|---|---|
| 1 | 5 to 7 |
| 2 | 7 to 9 |
| 3 | 8 to 10 |
| 4 | 9 to 11 |
| 5 | 9 to 11 |
| 6 | 10 to 12 |
| 7 | 10 to 12 |
| 8 | 11 to 12 |

### 3.5 Map features

From region 5 on, maps hold map features. Each of regions 5 to 8 brings one (12.1, 12.2).

| Feature | Grid characters | Region | What it does |
|---|---|---|---|
| Tunnel | `T` | 5 | Walkers inside are out of reach (3.6). |
| Bridge | `X` | 6 | Two roads cross without joining (3.7). |
| Ice slide | `^`, `v`, `<`, `>` | 7 | A one-way road (3.8). |
| Hollow stumps | `P`, `Q` | 8 | Twin stumps join two far roads (3.9). |

- Every feature is a fixed part of the map, with no timer and no chance, so the same inputs still give the same result.
- Every feature shows on the map by its shape, never by color alone. The route line always shows where walkers will go (7.5).
- The shortest open route (7.3) stays the only routing rule. Features change which steps exist, never how a walker picks one.
- A feature tile is never a gate socket, entrance, base or build spot.
- Flyers fly over every feature, and a feature never puts a flyer out of reach (8.8).
- A feature stays in the game after its region. Each region's levels use its own feature. Levels 5 and 6 of regions 6, 7 and 8 may also use one earlier feature, never two, so the last levels mix ideas without a new rule.
- Run maps hold features too (14.2).
- The grid characters are those of the level files (contract 2.3).

### 3.6 Tunnels

- A tunnel tile is a road tile under a grassy mound. Tunnel tiles next to each other, north, south, east or west, belong to the same tunnel. A tunnel is a straight run of 1 to 4 tunnel tiles, all in one row or all in one column, with no bend, so its mound reads as one straight hump. A map has at most 6 tunnel tiles.
- No tunnel tile is a fork or a bend: each tunnel tile has exactly two road neighbors, on opposite sides, in the line of its tunnel.
- No tunnel tile is next to a gate socket, north, south, east or west, so a breaker never breaks a gate from inside a tunnel.
- Routing does not change. Tunnel tiles are ordinary road and count as steps.
- A walker whose center is inside a tunnel tile is out of reach (8.8).
- Gates and refusal do not change.
- The route line runs under the mound, into one mouth and out of the other (7.5). Walkers fade out at one mouth and come back at the other.
- Breakers walk through as usual. A release that begins in a tunnel puts its creatures in the tunnel, out of reach until they walk out.
- Level guide: tunnels hold at most a quarter of the steps of any entrance's shortest route with no gates.

### 3.7 Bridges

- A bridge tile is where two roads cross. Its four neighbors are road, so it is never on the map edge. A map has at most 3 bridges, with at least one plain road tile between two bridges.
- The east-west road goes over on a plank bridge, and the north-south road passes under. No rule depends on which is on top.
- Routing (7.3): a bridge tile is two nodes, one for each road. A walker on a bridge goes straight across: one that comes in from the north leaves to the south, and so on. It never turns there. It turns back along its own road only when a gate breaks and the new shortest route lies behind it (7.8).
- A creature on a bridge tile is in reach of every tower, on either road. Targeting uses the distance of the node it is on (8.2).
- Gates and refusal do not change. A gate next to a bridge closes that one arm.
- A route line that crosses a bridge goes over the deck or under it. Under the deck it is cut by the bridge, so over and under read by shape. A route may cross itself at a bridge (7.5).
- Breakers cross bridges like any walker.
- Level guide: every bridge lies on the shortest route of some gate placement, so it always matters.

### 3.8 Ice slides

- An ice slide tile has an arrow that points north (`^`), south (`v`), west (`<`) or east (`>`). The tile its arrow points to is road.
- Slides come in straight runs of 2 or more tiles, every arrow pointing along the run, so they read as slides, not stray arrows.
- Routing (7.3): a walker on a slide tile leaves it only the way its arrow points. No walker steps onto a slide tile from the tile its arrow points to. A walker may join a slide from its side.
- Gates and refusal: the words do not change (7.4). Slides make it more interesting, because a road can look connected and still be closed when the only way left runs up a slide. The crossed-out gate and "That would close every road." explain it, and the route line shows why other placements work.
- The route line does not change. Its arrows already point the way, and on a slide they agree with the slide's carved chevrons.
- Breakers' routes follow the slides too. A released walker finishes its releaser's step, which always goes the slide's way.
- Level guide: with no gates placed, every entrance reaches the base (3.3). Use slides for loops and detours, never as dead ends.

### 3.9 Hollow stumps

- Hollow stumps come in twins. A map holds each letter, `P` and `Q`, exactly twice or not at all, and the two stumps of a letter are twins. A map has at most 2 pairs. A stump is a road tile with its usual road neighbors. Twins are never next to each other.
- Twins carry the same carved symbol, a crescent for `P` and a five point star for `Q`, so pairs read by shape.
- Routing (7.3): twins are joined by one step, both ways. A walker on a stump takes that step or a usual one, whichever its shortest route needs.
- Walking through: the stump step takes the time of one step at the walker's speed. For that whole step the walker is out of reach (8.8). It stands at the stump it entered until the step is done, then appears at its twin's center. A release that begins during the step begins at the stump it entered, and its walkers take the same step.
- Gates and refusal do not change. A stump never holds a gate, but a gate on the road beside a stump closes that way in.
- The route line runs into a stump and starts again at its twin (7.5).
- Breakers use stump steps like any walker. Targeting counts the stump step as one step, as routing does (8.2).
- Level guide: on most maps the stump step is the shortcut the gates must close. Each pair lies on some gate placement's shortest route.

## 4. Core loop

### 4.1 Level flow

1. The level starts in a build phase with the starting gold and lives.
2. The player starts the next wave. A wave phase begins.
3. Creatures come down the roads and fly toward the base. Each one that reaches the base costs lives.
4. When every creature of every started wave is gone, defeated or through, and nothing is left to spawn:
   - If the final wave has started and lives are above 0, the level is won.
   - Otherwise a new build phase begins.
5. If lives reach 0 or less at any moment, the level is lost at once.

Clearing the final wave is not enough on its own. After an early call (4.9), an older wave can still be on the map when the final wave is cleared. Then the level is won only when that older wave is gone too. The tick order (8.1) and runs (14.1) use this same rule.

### 4.2 Build phase

- No time passes. Nothing moves. There is no timer.
- The player can build, upgrade, sell, change targeting, place, move and remove gates, read the wave preview and tap anything for its numbers.
- It ends only when the player starts the next wave.

### 4.3 Wave phase

- The game runs in real time at the chosen speed.
- The player can build, upgrade, sell, change targeting, tap anything for its numbers, and call the next wave early.
- Gates cannot be touched (7.6).

### 4.4 Lives

| | Normal | Relaxed |
|---|---|---|
| Starting lives, campaign and runs | 20 | 40 |

- A creature that reaches the base costs its lives number (6.1). Most cost 1. Bosses cost 20.
- At 0 lives or fewer, the level or run is lost at once, even in the middle of a wave.
- Lives never rise above the starting lives. Nothing adds lives in the campaign. In runs, Tea Break does, up to the starting lives (14.5).

### 4.5 Gold

| Source | Amount |
|---|---|
| Starting gold | Set per level (12.3) and per run (14.1). |
| Bounty | Paid when a tower defeats a creature. Base bounty (6.1) times strength / 100, rounded half up, at least 1. A creature that reaches the base pays nothing. |
| Wave clear bonus | Paid when the last creature of a wave is gone, defeated or through. (20 + 5 times the wave number) times strength / 100, rounded half up. Wave 1 at strength 100 pays 25. Wave 10 at strength 150 pays 105. |
| Early call bonus | 4.9. |
| Selling | 4.6. |

- There is no other income in the campaign. Runs add card effects (14.5).
- There is no gold cap a player can reach. The sim holds gold at 1,000,000,000, the most a save holds.

### 4.6 Building, upgrading and selling

Building:

- Tap an empty build spot, pick a tower, see its range and cost, confirm.
- The player needs the full cost in gold.
- A new tower can fire at once.

Upgrading:

- Every tower has three tiers. Tier 1 is the build. Tier 2 is one upgrade.
- At tier 3 the player picks one of two specializations. The choice is permanent for that tower. Selling the tower is the only way to choose again.
- Every upgrade shows its cost and its before and after numbers before the player confirms (9.5).
- An upgrade changes the tower's numbers at once, even during a wave. What happens to its reload timer is in 5.2.

Selling:

- Selling removes the tower at once.
- Each purchase on a tower (the build and each upgrade) is remembered with the phase it was made in.
- Refund = the full price paid for every purchase on that tower made in the current build phase, plus 70% of the price paid for every other purchase on it, rounded down.
- A purchase made during a wave phase, even while paused, never refunds in full.
- Refunds always use the price paid. If a run card changes prices later (Bargain, 14.6), a sale still pays back from what was actually paid.
- Selling never makes a profit. In runs, Fair Trade raises the 70% to 90% (14.5). No card or rule ever raises it above 100%.

Examples:

- A Sling Post built in this build phase and sold before the wave starts refunds 100.
- A Sling Post built before wave 3 and upgraded to tier 2 during wave 3 refunds 70% of 210, which is 147, whenever it is sold.
- A tower built before wave 2 and upgraded in the build phase before wave 4, then sold in that same build phase, refunds 70% of the build plus the full upgrade price.

All prices are multiples of 10, so 70% is always a whole number.

### 4.7 Pause

- The player can pause at any moment. The sim freezes at once.
- While paused the player can build, upgrade, sell, change targeting, tap anything for its numbers and read the wave preview.
- Calling the next wave works while paused. The wave starts on the same tick, so nothing moves until play resumes.
- Gates stay locked if the game is paused during a wave.
- Opening the Pause menu also pauses.
- Leaving the app during a wave pauses it (4.10).
- Any change of the window's size during a wave pauses the game: folding or unfolding the phone, split screen, or a pop-up window. Bart chose this for folding at hard stop A, and every other size change follows the same rule. The player resumes when ready. In a build phase nothing moves, so a size change there only changes the layout.

### 4.8 Speeds

- Speeds are 1x, 2x and 3x. They change only how fast sim time passes. The same inputs give the same results at every speed.
- Every level and run starts at 1x. The chosen speed then stays until the player changes it.
- A saved game also resumes at 1x, from the Continue card or any other way back in (Bart, hard stop B).

### 4.9 Calling the next wave early

- During a wave phase, the player can call the next wave once the newest started wave has spawned all of its groups. Puffs and boss summons do not count for this.
- There must be a next wave. The final wave can be called early too, but nothing after it.
- At most 2 waves can be on the map at once. While 2 are running, the next wave cannot be called. This keeps the biggest crowd inside the performance budget.
- The early call bonus is half the bounty of every creature from the newest wave still on the map at that moment, rounded up. Puffs and summons count as part of their wave.
- The call button shows the bonus and updates live. It shrinks as those creatures fall.
- The called wave starts at once. Each wave still pays its own clear bonus.
- Starting a wave from a build phase is not an early call and pays no bonus.
- In a run, the next wave also cannot be called while a card draft is owed (14.4).

### 4.10 Leaving and coming back

- Leaving the app saves the game at that exact moment, even mid-wave (Bart, hard stop A). Coming back resumes it paused, on the Pause menu.
- One game can be saved per mode: one campaign level or Twist, one roguelite run and one daily run. One never ends another. The Continue card resumes the most recent one. The saved level's card, the Roguelite button and the Daily button each resume their own.
- Starting a different campaign level or Twist while one is saved first asks the player. If they confirm, the saved game ends as if it were abandoned from Pause, so nothing is recorded. If they cancel, nothing changes.
- Starting a new roguelite run while one is saved, or a new daily while a daily is saved, also asks first. If they confirm, the saved run ends as if it were abandoned from Pause: it counts as lost at its current wave (14.7), and it records what any ended run records: its unlock counters (14.6), and for a daily its result for the day's best and the streak (15). So starting over never hides a loss. If they cancel, nothing changes.

## 5. Towers

### 5.1 The ten towers

Regions 1 to 4 bring the first six, in 5.3 to 5.8. Regions 5 to 8 bring one each, in 5.12 to 5.15 (12.1).

| Tower | Id | Its one job | Hits | The right answer for | Weak against |
|---|---|---|---|---|---|
| Sling Post | `sling_post` | Quick small hits on one target | Walkers and flyers | Bubblers, Skitters, early waves, a backup against flyers | Armor (Shellback, Dusk Moth, Ironshell), big crowds |
| Pumpkin Catapult | `pumpkin_catapult` | Splash on groups | Walkers | Pips, Puffs, packed or drowsy groups | Flyers, Bubblers, fast spread-out walkers, single big targets |
| Lullaby Bell | `lullaby_bell` | Slows walkers in its ring | Walkers (Night Bell: flyers too) | Skitters, Gatecrashers, bosses, making splash hit more | Flyers, builds with no splash. It never defeats anything alone |
| Longbow Loft | `longbow_loft` | Long range, heavy arrows that ignore armor | Walkers | Shellbacks, Gatecrashers, Menders, armored bosses, covering two roads from one spot | Bubblers, Pips and Puffs (wasted arrows), flyers |
| Firework Tower | `firework_tower` | Anti air with splash | Flyers | Flitter flocks, Dusk Moths, the Moon Moth | Every walker. It cannot hit them |
| Bakery | `bakery` | Makes the towers around it attack faster | Nothing | Tight clusters of spots, late waves, bosses | Spread-out spots, early waves when gold is short, Bells (it cannot boost them) |
| Bramble Cottage | `bramble_cottage` | Thorns hit every walker in its ring, again and again, with no aim | Walkers | Roads that wrap around a spot, loops and bridges, Mistwisp groups, a Gleamer's escort | Armor (except Holly Crown), flyers, spots with little road near them |
| Scarecrow | `scarecrow` | Creatures in its ring take more damage from every hit | Walkers (Crow Keeper: flyers too) | Bosses, Mossbuds, Gleamers, Sleepyheads, late waves where many towers aim at one stretch | Early waves, spread-out spots. It never defeats anything alone |
| Snow Fort | `snow_fort` | Rolls a snowball down a straight line, and every walker in it is hit | Walkers | Long straight roads and slides that run toward it, armored columns, creatures hidden behind a Mistwisp or a Gleamer | Bends, roads that cross its line, flyers |
| Moth Lantern | `moth_lantern` | Pulls flyers low, so every tower can hit them | Flyers | Flocks and flying bosses whose line passes over ground towers | Walkers. Flight lines far from other towers |

A flyer that a Moth Lantern has lured low can be hit by every tower, as if it were a walker (5.15). So where this file says a tower cannot hit flyers, it means flyers that are not lured low.

### 5.2 Rules for all towers

- A creature is in range when the distance from the tower's center to the creature's center is no more than the range.
- An attack hits on the tick it fires. Attacks never miss. Projectiles are only drawn. The render may hold a hit's flash or puff until the drawn projectile arrives, but the sim never waits.
- Every attacking tower has a reload timer. Each tick the timer goes down by the tick length times the tower's rate multiplier (1, or more with a Bakery boost). When the timer is 0 or less and a target is in range, the tower fires and adds its reload time to the timer, keeping any leftover. When the timer is 0 or less and no target is in range, the timer is set to 0 and waits there, so a tower never saves up shots. This keeps every rate exact at any tick length.
- A tower that was waiting at 0, a new tower too (4.6), still runs its timer down on the tick it fires and keeps that leftover, so its next reload is one tick shorter than a full one. Example: with a reload of 1.0 s, which is 20 ticks of 0.05 s, it fires again 19 ticks later, then every 20.
- A tower fires at most once a tick. If a shot still leaves the timer below 0, the timer is set to 0. That can only happen when a boost takes more off the timer in one tick than the whole reload time, and no number in this file allows it: the shortest reload is 0.2 s, and the biggest boost takes 0.07 s off in one tick. So a tower never banks shots, and between ticks its timer is always from 0 up to its reload time.
- Upgrading keeps the reload timer running, but never above the new reload time. If more is left on the timer than the new reload time, the timer drops to the new reload time. Otherwise it is unchanged. So an upgraded tower never waits longer for its next shot than its new numbers say, and an upgrade never gives a free shot.
- Example: a tier 2 Pumpkin Catapult has 1.8 s left on its timer. Upgraded to a Jam Pot (reload 1.5 s), its timer drops to 1.5 s. Upgraded to a Prize Pumpkin (reload 2.5 s) instead, it keeps 1.8 s.
- A run card that changes reload times (Steady Aim, Heavy Pumpkins, Long Fuse) follows the same rule for every tower it changes, at the moment it is taken.
- The rate shown on screen is the rate multiplier divided by the reload time, to one decimal.
- Damage is always a whole number.
- A dozing tower (6.2, Yawn) does not fire, and its reload timer does not run down.
- Bramble pulses, Snow Fort lines and Moth Lantern shots are hits like any other: a bubble blocks one, armor counts unless the tower ignores it, and a fright adds to it (8.3).
- The Bramble Cottage is an attacking tower that aims at nothing, so it has no targeting mode (5.12). The Lullaby Bell, the Scarecrow and the Bakery have no reload timer and no targeting.

### 5.3 Sling Post

Quick pebbles at one target. Hits walkers and flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Damage per s |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Sling Post | `sling_post` | 100 | 100 | 6 | 0.5 | 2.0 | 2.5 | 12 |
| 2 | Sling Post | `sling_post` | 110 | 210 | 8 | 0.4 | 2.5 | 3.0 | 20 |
| 3 | Quickshot | `quickshot` | 200 | 410 | 8 | 0.2 | 5.0 | 3.0 | 40 |
| 3 | Stone Sling | `stone_sling` | 200 | 410 | 20 | 0.5 | 2.0 | 3.0 | 40 |

- Quickshot: many small hits. Best against bubbles and crowds of weak creatures. Armor blunts it badly.
- Stone Sling: fewer, bigger hits that get through armor. Hits armored flyers too.

### 5.4 Pumpkin Catapult

Lobs pumpkins that splash every walker near the target. Cannot hit flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Splash radius | Extra |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Pumpkin Catapult | `pumpkin_catapult` | 120 | 120 | 14 | 2.0 | 0.5 | 2.5 | 0.75 | none |
| 2 | Pumpkin Catapult | `pumpkin_catapult` | 130 | 250 | 24 | 2.0 | 0.5 | 3.0 | 1.25 | none |
| 3 | Prize Pumpkin | `prize_pumpkin` | 230 | 480 | 50 | 2.5 | 0.4 | 3.5 | 1.5 | none |
| 3 | Jam Pot | `jam_pot` | 230 | 480 | 24 | 1.5 | 0.7 | 3.0 | 1.25 | Every walker it damages is slowed 40% for 3.0 s |

- Tier 1 reaches as far as a tier 1 Sling Post, so on single walkers the Sling Post is the better buy. Tier 2 reaches further and splashes much wider: the answer to crowds.
- Prize Pumpkin: raw splash. Better against fast or spread-out groups and armored groups.
- Jam Pot: control. Its slow makes every other tower in the area better. It fires often enough that every other shot gets past a Bubbler's bubble.

### 5.5 Lullaby Bell

Makes walkers in its ring drowsy and slow. Deals no damage. Has no reload and no targeting.

| Tier | Name | Id | Price | Total spent | Slow | Range | Affects |
|---|---|---|---|---|---|---|---|
| 1 | Lullaby Bell | `lullaby_bell` | 90 | 90 | 35% | 2.0 | Walkers |
| 2 | Lullaby Bell | `lullaby_bell` | 90 | 180 | 45% | 2.5 | Walkers |
| 3 | Hush Bell | `hush_bell` | 170 | 350 | 60% | 2.5 | Walkers |
| 3 | Night Bell | `night_bell` | 170 | 350 | 45% | 3.0 | Walkers and flyers |

- The slow lingers 1.0 s after a creature leaves the ring (8.5).
- A slowed Gatecrasher also breaks gates slower by the same percent (7.7).
- Hush Bell: the strongest slow in the game.
- Night Bell: a wider ring, and the only path that slows flyers that are not lured low (5.15). In runs, the Frost Chime card lets every Lullaby Bell slow flyers (14.6).

### 5.6 Longbow Loft

Long range. Heavy arrows ignore armor. Slow to reload. Cannot hit flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Targets per shot | Damage per s |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Longbow Loft | `longbow_loft` | 150 | 150 | 40 | 2.5 | 0.4 | 4.0 | 1 | 16 |
| 2 | Longbow Loft | `longbow_loft` | 160 | 310 | 70 | 2.5 | 0.4 | 4.5 | 1 | 28 |
| 3 | Giant Bow | `giant_bow` | 280 | 590 | 180 | 3.0 | 0.3 | 5.0 | 1 | 60 |
| 3 | Triple Bow | `triple_bow` | 280 | 590 | 70 | 2.5 | 0.4 | 4.5 | 3 | 28 per target |

- Every tier ignores armor.
- Giant Bow: one giant arrow. The boss killer.
- Triple Bow: three arrows at three different targets. Best against armored groups.

### 5.7 Firework Tower

Bursts that hit every flyer near the target. Cannot hit walkers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Splash radius | Extra |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Firework Tower | `firework_tower` | 110 | 110 | 12 | 1.0 | 1.0 | 3.0 | 0.75 | none |
| 2 | Firework Tower | `firework_tower` | 120 | 230 | 20 | 1.0 | 1.0 | 3.5 | 0.75 | none |
| 3 | Star Bloom | `star_bloom` | 210 | 440 | 30 | 1.0 | 1.0 | 3.5 | 1.25 | none |
| 3 | Skyrocket | `skyrocket` | 210 | 440 | 90 | 1.5 | 0.7 | 4.0 | none | One target. Ignores armor |

- Splash from a Firework Tower hits flyers only.
- Star Bloom: huge bursts for big flocks.
- Skyrocket: one heavy rocket for armored flyers and the Moon Moth.

### 5.8 Bakery

Bakes treats that make the towers around it attack faster. Does not attack. Has no targeting.

| Tier | Name | Id | Price | Total spent | Boost to towers it reaches | Reach |
|---|---|---|---|---|---|---|
| 1 | Bakery | `bakery` | 130 | 130 | Attack rate +15% | 1.5 |
| 2 | Bakery | `bakery` | 140 | 270 | Attack rate +25% | 1.5 |
| 3 | Grand Oven | `grand_oven` | 240 | 510 | Attack rate +40% | 1.5 |
| 3 | Spice Kitchen | `spice_kitchen` | 240 | 510 | Attack rate +25% and +2 damage per hit | 1.5 |

- Reach 1.5 covers the eight tiles around the Bakery, diagonals included. It boosts the attacking towers on those tiles.
- It never boosts Bells, Scarecrows, other Bakeries or itself.
- Grand Oven: the most speed. Best next to big hitters such as Giant Bows and Prize Pumpkins.
- Spice Kitchen: the +2 damage counts before armor, so it lets quick small hitters such as Quickshots chew through armor.
- Boost rules are in 8.6.

### 5.9 One-line tower cards

These lines appear on the info card the first time a tower is available, and on the build menu.

| Tower or path | Line |
|---|---|
| Sling Post | Quick pebbles at one target. Hits flyers too. Armor blunts it. |
| Pumpkin Catapult | Pumpkins splash every walker near the target. Can't hit flyers. |
| Lullaby Bell | Walkers in its ring get drowsy and slow. Deals no damage. |
| Longbow Loft | Long range. Heavy arrows ignore armor. Can't hit flyers. |
| Firework Tower | Bursts hit every flyer near the target. Can't hit walkers. |
| Bakery | Towers around it attack faster. Doesn't attack. |
| Quickshot | Fires twice as fast. |
| Stone Sling | Big stones that get through armor. |
| Prize Pumpkin | Huge pumpkins, wider splash. |
| Jam Pot | Sticky jam slows every walker it splashes. |
| Hush Bell | Deeper sleep: the strongest slow. |
| Night Bell | A wider ring that reaches flyers too. |
| Giant Bow | One giant arrow. Bosses beware. |
| Triple Bow | Three arrows at three targets. |
| Star Bloom | Huge bursts for big flocks. |
| Skyrocket | One heavy rocket that ignores armor. |
| Grand Oven | Even faster towers around it. |
| Spice Kitchen | Faster towers that also hit 2 harder. |
| Bramble Cottage | Thorns scratch every walker in its ring each second. Armor blunts them. |
| Scarecrow | Walkers in its ring take more damage from every hit. Deals no damage. |
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

Plurals, for the star 3 line "Build no ..." (10.3): Sling Posts, Pumpkin Catapults, Lullaby Bells, Longbow Lofts, Firework Towers, Bakeries, Bramble Cottages, Scarecrows, Snow Forts, Moth Lanterns.

### 5.10 Why no tower is best everywhere

Method. These tables come from a rough model, not from the bots. They show useful damage per second for every 100 gold spent, against a steady stream of one creature type, with wasted damage on kills counted and no support towers. Creature spacing: Pips 0.3 s apart, Flitters 0.4 s, Skitters 0.8 s, Scamps 1.0 s, Bubblers and Menders 1.2 s, Shellbacks 1.5 s, Dusk Moths 2.0 s, Gatecrashers 3.0 s, Puffs in their threes. Boss columns use one huge target. The best value in each column is in bold. The model counts splash on both sides of the target, as in a long stream. In a short pack a tower aiming First hits the front, so splash finds creatures on one side only, and the model overrates splash there. The balance bots on real maps have the final word (docs/design/TUNING_R1.md). Recomputed on 2026-10-24 with the region 1 tuning numbers. The Ironshell columns were recomputed the same day for its armor 10 (docs/design/TUNING_R2.md).

Tier 1 at strength 100:

| Tower | Scamp | Pip | Skitter | Flitter | Shellback | Bubbler | Puff | Mender | Gatecrasher | Dusk Moth | Ironshell | Moon Moth | Old Tusk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Sling Post | **11.4** | 10.5 | **12.0** | 12.0 | 4.0 | **8.3** | 12.0 | **10.0** | 8.0 | 2.0 | 2.0 | 6.0 | 4.0 |
| Pumpkin Catapult | 5.6 | **21.9** | 4.2 | 0 | 4.2 | 0 | **15.0** | 4.9 | 4.8 | 0 | 1.7 | 0 | 4.2 |
| Longbow Loft | 10.7 | 5.6 | 8.0 | 0 | **8.0** | 0 | 3.2 | 9.3 | **10.7** | 0 | **10.7** | 0 | **10.7** |
| Firework Tower | 0 | 0 | 0 | **27.3** | 0 | 0 | 0 | 0 | 0 | **6.1** | 0 | **8.2** | 0 |

Tier 3 at strength 220:

| Tower | Scamp | Pip | Skitter | Flitter | Shellback | Bubbler | Puff | Mender | Gatecrasher | Dusk Moth | Ironshell | Moon Moth | Old Tusk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Quickshot | 9.8 | 9.3 | 8.9 | 8.9 | 4.8 | **8.6** | **7.9** | 8.5 | 7.3 | 3.7 | 1.2 | 6.1 | 4.9 |
| Stone Sling | 8.6 | 7.5 | 8.0 | 8.0 | 7.4 | 6.7 | 6.3 | 8.3 | 8.6 | 7.2 | 4.9 | 8.3 | 7.8 |
| Prize Pumpkin | **11.0** | **34.5** | 2.8 | 0 | 9.9 | 0 | 6.5 | 9.6 | 3.7 | 0 | 3.3 | 0 | 3.8 |
| Jam Pot | 9.2 | 22.4 | 3.1 | 0 | 8.2 | 4.6 | 5.4 | 9.2 | 3.1 | 0 | 1.9 | 0 | 2.8 |
| Giant Bow | 5.0 | 2.6 | 3.7 | 0 | 5.6 | 0 | 1.5 | 8.7 | 9.9 | 0 | **10.2** | 0 | **10.2** |
| Triple Bow | 8.9 | 9.4 | **13.4** | 0 | **13.4** | 0 | 5.3 | **10.4** | **11.9** | 0 | 4.7 | 0 | 4.7 |
| Star Bloom | 0 | 0 | 0 | **25.0** | 0 | 0 | 0 | 0 | 0 | 5.5 | 0 | 6.1 | 0 |
| Skyrocket | 0 | 0 | 0 | 10.0 | 0 | 0 | 0 | 0 | 0 | **13.3** | 0 | **13.6** | 0 |

What the tables show:

- Every attacking tower is best against something, and none is best against everything.
- The Sling Post is the best tier 1 tower against single walkers, and it is the only tower that hurts Bubblers well. It falls to about a third of its value against armor. A Pip takes four tier 1 pebbles or three Quickshot pebbles but only one tier 2 pumpkin, so crowds belong to splash. The first bot report found the Sling Post doing every job in region 1; this split is the fix.
- The Stone Sling tops no column, but it is second best against the Dusk Moth and every armored boss, and it is the only tower that is good against both armored walkers and armored flyers. The Jam Pot's value is its slow, which the tables cannot show (see below).
- Each tier 3 pair splits cleanly: Quickshot against bubbles and crowds, Stone Sling against armor; Prize Pumpkin for damage, Jam Pot for control; Giant Bow against bosses, Triple Bow against armored groups; Star Bloom against flocks, Skyrocket against armored flyers.

The support towers, from the same rough model with the phase 4 numbers (before the region 1 tuning), using a straight road past five spots in a row:

- Bell with splash. Ten Shellbacks at strength 200. Five tier 2 Catapults let 7 through. Four tier 2 Catapults and a tier 2 Bell let 4 through. With a Hush Bell, 3. Drowsy walkers bunch up, so splash hits more of them.
- Bell without splash. With five tier 2 Sling Posts, 7 Shellbacks got through, and swapping one Sling Post for a Bell did not help. Against 24 Scamps at strength 200, five tier 2 Sling Posts let none through. Four and a Hush Bell let 7 through. A Bell is a poor pick in a build of single-target towers. The region 2 bots found the opposite on real maps: a Bell gives every tower in its ring more time, so it let a lone Sling Post hold crowds it could not hold alone (TUNING_R2.md).
- Bakery. Sixteen Shellbacks at strength 200 past a cluster of four Quickshots. A fifth Quickshot let 9 through. A Grand Oven in the middle let 7 through. A Spice Kitchen let none through.
- Jam Pot against Prize Pumpkin, each at the point where one build starts to leak: against 30 Scamps the Jam Pot build let 0 through and the Prize Pumpkin build 9. Against 12 Shellbacks, 1 against 4. Against 16 fast Skitters, 9 against 3. Against 40 Pips, 4 against 3.

The four towers of regions 5 to 8, from the same rough model (docs/design/EXPANSION.md 4.8): tier 1 at strength 100, a steady stream of one creature. The Bramble Cottage and the Snow Fort depend on the shape of the road, so each gets two rows. For the Bramble, "passing" is a straight road beside its spot (about 3.5 tiles of road in its tier 1 ring of 2.0) and "wrapped" a road that bends around its spot, an L whose corner touches the spot's corner (about 5.5 tiles). For the Snow Fort, "across" is a road that crosses its line (about 0.8 tiles in the line) and "aligned" a straight road that runs down its line (about 2.5 tiles).

| Tower | Road shape | Scamp | Pip | Skitter | Shellback |
|---|---|---|---|---|---|
| Sling Post | any | 11.4 | 10.5 | 12.0 | 4.0 |
| Pumpkin Catapult | any | 5.6 | 21.9 | 4.2 | 4.2 |
| Longbow Loft | any | 10.7 | 5.6 | 8.0 | 8.0 |
| Bramble Cottage | passing | 28.9 | 58.3 | 18.0 | 16.5 |
| Bramble Cottage | wrapped | 33.3 | 58.3 | 28.5 | 26.0 |
| Snow Fort | across | 3.0 | 8.5 | 1.9 | 2.2 |
| Snow Fort | aligned | 9.5 | 26.4 | 5.9 | 6.8 |

What this table shows:

- Each new attacking tower needs the map read right, which is the point: the Bramble where the road runs close to its spot or wraps around it, the Snow Fort where a straight road runs down its line.
- The model overrates the Bramble Cottage. It counts every pulse on every walker in the ring as useful, but a pulse that pops nothing helps only when another tower finishes the walker, and a crowd crosses the ring in a few seconds. At its first numbers (4 damage, ring 1.5) the model put it at the Catapult's level against Pips, yet on real maps the bots found it weak: it stood in 18% of the three-star builds on the region 5 levels that offer it, and its run card cost the run bots 23 points (docs/design/TUNING_R5.md). So its numbers come from the bots, not from this table. What decides its worth is the damage one walker takes while it crosses the ring. At tier 1, on a straight road beside the spot, a Scamp now takes about 35 of its 40 health (before: 9), and a Pip is popped (before: 7 of its 21). Armor still blunts it, except as a Holly Crown, and a Mossbud regrows 4 of the 10 damage of each tier 1 pulse.
- The Snow Fort is poor across a road. Down an aligned road it is about the Catapult's equal on crowds and, after the Longbow, the best tier 1 buy against an armored column. Big Snowball takes armored columns at tier 3.
- The Scarecrow and the Moth Lantern deal no damage worth counting. Like the Bell and the Bakery, the bots judge them on real maps: the Scarecrow's fright is worth more the more towers aim into its ring, and the Lantern is worth what the ground towers under a flight line can add.
- One watch item: the new numbers make the Bramble region 5's staple. It stood in nearly every three-star build that the searches found on 5-2 to 5-6, often as a Holly Crown where armored walkers come (docs/design/TUNING_R5.md). In region 5 that is the plan: its answers are towers that need no aim. Regions 6 and 7 showed the same share: 98% to 100% of the three-star builds on 8 of their 12 levels. But searches that left the cottage out still found 455 to 1370 three-star builds in 3000 on each of those levels, and on 3 of them the third star caps towers at tier 2, where no Holly Crown can stand. So the share shows a cheap tower that suits roads with bridges and loops, not a tower the player needs, and its numbers stay (docs/design/TUNING_R67.md). From now on the watch item measures need, not share: if a search without the cottage finds fewer than a quarter as many three-star builds as a search with every tower, on two or more levels of one region, the first lever is the Holly Crown's damage, 24 down to 20 to match the Wild Bramble's, and the next is tier 1 damage, 10 down to 8. Runs are measured before either changes.

### 5.11 Pairs players can discover

These pairings are designed in. They are the moments the brief calls out.

| Pair | Why it works |
|---|---|
| Lullaby Bell and Pumpkin Catapult | Drowsy walkers bunch up, so each pumpkin hits more of them. |
| Sling Post and Longbow Loft against Bubblers | Quick pebbles pop the bubble. The heavy arrow lands before it comes back. |
| Spice Kitchen and Quickshots | The +2 damage counts before armor, so quick hits get through shells. |
| Grand Oven and Giant Bows | The biggest hits, more often. Bosses melt. |
| Gates and the Longbow Loft | A gate bends the road back past one long-range spot several times. |
| Lullaby Bell and the Gatecrasher | A drowsy Gatecrasher breaks gates slower, which buys time to defeat it. |
| Jam Pot and anything | Its slow lingers 3.0 s, so towers further down the road get more time. |
| Night Bell and Firework Tower | Drowsy flyers stay in the bursts longer. In the campaign, nothing else slows a flyer that is not lured low (5.15). |
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

### 5.12 Bramble Cottage

A cottage under a crown of thorns. Every second, its thorns scratch every walker in its ring. Cannot hit flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Ring | Extra |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Bramble Cottage | `bramble_cottage` | 120 | 120 | 10 | 1.0 | 1.0 | 2.0 | none |
| 2 | Bramble Cottage | `bramble_cottage` | 130 | 250 | 14 | 1.0 | 1.0 | 2.5 | none |
| 3 | Wild Bramble | `wild_bramble` | 230 | 480 | 20 | 1.0 | 1.0 | 3.0 | none |
| 3 | Holly Crown | `holly_crown` | 230 | 480 | 24 | 1.0 | 1.0 | 2.5 | Ignores armor |

- It is an attacking tower with a reload timer (5.2), but it aims at nothing and has no targeting mode.
- When its timer is 0 or less and at least one creature it can hit is in its ring, it pulses: every creature it can hit whose center is within the ring takes the hit. Then its reload starts, as for any tower (5.2). With nothing it can hit in its ring, its timer waits at 0, so it never saves up a pulse.
- The creatures it can hit are walkers and low flyers (5.15). Hidden creatures (6.2, Mist) count. Creatures that are out of reach or napping (8.8) do not.
- Its rings grow as a Bell's and a Scarecrow's do. A ring of 2.0 covers the eight tiles around it and the four tiles two steps away in a straight line. A ring of 2.5 covers every tile of the 5 by 5 block around it except the four corners. The Wild Bramble's ring of 3.0 covers the whole block, and the four tiles three steps away in a straight line.
- Wild Bramble: a wider ring for a spot that sees two roads.
- Holly Crown: sharp holly that ignores armor, for Shellbacks and Yawners at a bend.

### 5.13 Scarecrow

A straw scarecrow on a post. Creatures in its ring get frightened and take more damage from every hit. Deals no damage. Has no reload and no targeting.

| Tier | Name | Id | Price | Total spent | Fright | Ring | Affects |
|---|---|---|---|---|---|---|---|
| 1 | Scarecrow | `scarecrow` | 100 | 100 | 15% | 2.0 | Walkers |
| 2 | Scarecrow | `scarecrow` | 100 | 200 | 25% | 2.5 | Walkers |
| 3 | Tall Scarecrow | `tall_scarecrow` | 190 | 390 | 40% | 2.5 | Walkers |
| 3 | Crow Keeper | `crow_keeper` | 190 | 390 | 25% | 3.0 | Walkers and flyers |

- It is a ring tower like the Lullaby Bell. Bakeries never boost it, and it never boosts anything.
- Every tick, each creature of the right kind in its ring gets its fright with 1.0 s left, so the fright lingers 1.0 s after a creature leaves the ring, as a Bell's slow does. A low flyer counts as a walker here (5.15). Creatures that are out of reach or napping get no fright (8.8).
- A frightened creature takes more damage from every hit, worked out after armor (8.3). Example: a Stone Sling (20) hits a Shellback (armor 4) with 25% fright: 16 becomes 20.
- A creature holds one fright at a time. A higher fright replaces it. An equal one keeps the longer time. Frights never add up (8.7).
- Bosses are frightened too. A bubble still blocks the whole hit.
- Tall Scarecrow: the strongest fright.
- Crow Keeper: a wider ring that frightens flyers too.

### 5.14 Snow Fort

A round fort of snow bricks. It rolls a big snowball in a straight line, and every walker in its path is hit. Cannot hit flyers.

| Tier | Name | Id | Price | Total spent | Damage | Reload (s) | Rate per s | Range | Line width | Damage per s per walker hit |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Snow Fort | `snow_fort` | 140 | 140 | 16 | 3.0 | 0.3 | 3.0 | 0.8 | 5.3 |
| 2 | Snow Fort | `snow_fort` | 150 | 290 | 28 | 3.0 | 0.3 | 3.5 | 0.8 | 9.3 |
| 3 | Big Snowball | `big_snowball` | 260 | 550 | 64 | 3.5 | 0.3 | 4.0 | 1.0 | 18.3 |
| 3 | Flurry | `flurry` | 260 | 550 | 24 | 1.5 | 0.7 | 3.5 | 0.8 | 16.0 |

- It picks a target in range by its targeting mode, like any attacking tower (8.2).
- The line is a straight segment. It starts at the tower's center, runs through the target's center, and goes on until it is as long as the tower's range, or until it reaches the map's edge, whichever comes first. Every creature it can hit whose center is within half the line width of that segment is hit, the target included. The contract sets the integer math.
- The creatures it can hit are walkers and low flyers (5.15), when they are not out of reach and not napping (8.8). A hidden walker (6.2, Mist) can be hit by the line, though it can never be its target.
- The line ignores roads. A line that crosses grass and another road hits walkers on both.
- Only a low flyer can be at the tower's own center. If the target is there, the shot hits that target alone.
- Big Snowball: one huge, wider snowball for armored columns and bosses.
- Flurry: quick snowballs, twice as often, for long crowds.

### 5.15 Moth Lantern

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
- A lure is part of the hit. A bubble that blocks the hit blocks the lure too: the flyer stays high, and only the bubble pops (8.3).
- A lure counts at once. Towers that act later in the same tick, in spot order (3.4), can already aim at the lured flyer as if it were a walker.
- A low flyer still flies its straight line, still ignores roads and gates, and still counts as a flyer for every other rule. But every tower can aim at it and hit it as if it were a walker: Catapult splash, Longbow arrows, Bramble rings and Snow Fort lines reach it, every Bell slows it and every Scarecrow frightens it. Sling Posts and Fireworks hit it as before.
- Bosses can be lured. The Moon Moth is the one flying boss, and the flyers a boss releases can be lured too.
- Beacon Lantern: reaches far and holds flyers low longer.
- Lantern Garland: lures three flyers with each shot, for flocks.

## 6. Creatures

### 6.1 Creature numbers

Numbers at strength 100. Health, heal and regrow amounts, and bounty scale with strength (6.4). Armor, speed and lives never do.

| Creature | Id | Health | Armor | Speed | Moves | Lives lost | Bounty | Special |
|---|---|---|---|---|---|---|---|---|
| Scamp | `scamp` | 40 | 0 | 1.0 | Walks | 1 | 5 | None. The basic creature. |
| Pip | `pip` | 21 | 0 | 1.2 | Walks | 1 | 3 | None. Comes in crowds. |
| Skitter | `skitter` | 30 | 0 | 2.0 | Walks | 1 | 5 | None. Very fast. |
| Flitter | `flitter` | 30 | 0 | 1.2 | Flies | 1 | 5 | Flies (6.5). |
| Shellback | `shellback` | 90 | 4 | 0.7 | Walks | 2 | 12 | Armor. |
| Bubbler | `bubbler` | 50 | 0 | 0.9 | Walks | 1 | 7 | Bubble (6.2). |
| Puffball | `puffball` | 60 | 0 | 0.8 | Walks | 2 | 5 | Splits into 3 Puffs (6.2). |
| Puff | `puff` | 12 | 0 | 1.3 | Walks | 1 | 2 | Only comes from a Puffball. |
| Mender | `mender` | 70 | 1 | 0.7 | Walks | 1 | 10 | Heals others (6.2). |
| Gatecrasher | `gatecrasher` | 160 | 2 | 0.8 | Walks | 3 | 25 | Breaks gates (7.7). |
| Dusk Moth | `dusk_moth` | 120 | 5 | 0.8 | Flies | 2 | 15 | Armored flyer. |
| Mossbud | `mossbud` | 80 | 0 | 0.8 | Walks | 1 | 10 | Regrows 4 health every 1.0 s (6.2). |
| Mistwisp | `mistwisp` | 50 | 0 | 1.0 | Walks | 1 | 10 | Creatures on its tile or the four tiles next to it cannot be aimed at (6.2). |
| Gleamer | `gleamer` | 160 | 0 | 0.8 | Walks | 2 | 18 | Dazzles: every tower in range aims at it (6.2). |
| Sleepyhead | `sleepyhead` | 90 | 0 | 0.9 | Walks | 1 | 12 | Naps once for 2.0 s, then wakes with half its max health (6.2). |
| Snowroller | `snowroller` | 40 | 0 | 1.0 | Walks | 1 | 8 | Grows by 10% of its starting max health at each tile, up to 3 times that health (6.2). |
| Yawner | `yawner` | 110 | 2 | 0.7 | Walks | 2 | 15 | Every 4.0 s, towers within 1.5 tiles doze for 2.0 s (6.2). |
| Blinker | `blinker` | 60 | 0 | 0.9 | Walks | 1 | 9 | Every 3.0 s, it blinks 2 tiles ahead (6.2). |
| Hootling | `hootling` | 80 | 1 | 0.9 | Walks | 1 | 11 | No creature within 1.5 tiles of it can be slowed (6.2). |

That is 18 creature types, plus the Puff that only a Puffball makes, plus one boss per region (6.3). The last eight come in regions 5 to 8, two a region (12.2). All eight walk: flyers keep coming in every region, as Flitters, Dusk Moths and boss releases, so gates are never a complete answer.

### 6.2 Special rules

Bubble (Bubbler):

- A Bubbler starts with its bubble up.
- A hit on a creature with its bubble up pops the bubble and does nothing else. No damage, no slow.
- The bubble comes back 2.0 s after it popped. If it comes back on the same tick as a hit, it blocks that hit (8.1).
- Splash pops each bubble it reaches, one per creature.
- A Bell's slow and a Mender's heal are not hits. The bubble does not stop them.
- So a single slow tower that reloads in 2.0 s or more never hurts a Bubbler alone. Quick hitters lose at most one hit in four.

Splits (Puffball):

- When a Puffball is defeated, it releases 3 Puffs at the spot where it fell. The first appears in the spawn step of the next tick (8.1), the second 0.3 s after the first and the third 0.6 s after the first.
- Puffs belong to the Puffball's wave and use its strength. They follow the shortest open route from that spot.
- A Puffball that reaches the base costs 2 lives and releases nothing.

Releases (Puffs and boss batches):

- A release is a Puffball's 3 Puffs, or one batch of creatures from a boss: Grumblesack's 2 Scamps, the Moon Moth's 3 Flitters, Old Tusk's 4 Dusk Moths, Burrowbelly's 2 Mistwisps or Glimmertoad's 6 Flitters (6.3).
- Every creature in a release appears at the spot where the release began: where the Puffball fell, or where the boss stood when that batch began. The later ones appear at that same spot, even though the boss has moved on.
- A release that has begun always finishes, even if the boss is defeated or gets through in the meantime.
- A released walker first finishes the step its releaser was on, then takes the shortest open route from there (7.3). A released flyer flies straight from that spot to the base.
- A release that begins in a tunnel or during a stump step follows 3.6 and 3.9.
- Released creatures belong to their releaser's wave and use its strength (6.4).

Heals (Mender):

- Every 2.0 s, starting 2.0 s after it appears, every other creature within 1.5 tiles of the Mender gains 8 health, scaled by strength, up to its max health.
- It does not heal itself. It heals walkers and flyers, bosses included.
- Menders walk slowly, so they tend to trail behind their group. Towers set to Last find them (8.2).

Breaks gates (Gatecrasher): see 7.7.

Regrow (Mossbud):

- Every 1.0 s, starting 1.0 s after it appears, it gains 4 health, scaled by strength, up to its max health.
- It regrows out of reach too (8.8). A Mender still heals it as well, and the two each apply on their own (8.7).

Mist (Mistwisp):

- Mist covers tiles. A creature on a Mistwisp's tile, or on one of the four tiles next to it (north, south, east and west), is hidden. No tower can aim at a hidden creature. A creature's tile is the tile its center is in, so a flyer over those tiles is hidden too.
- Splash, Bramble rings and Snow Fort lines still hit hidden creatures, and Bells and Scarecrows still reach them. Only aiming stops.
- A Mistwisp is never hidden, even beside another Mistwisp. A Mistwisp that is out of reach still hides (8.8).
- Hiding is worked out at the start of the towers step each tick, from the tiles the Mistwisps stand on then (8.1).

Dazzle (Gleamer, Old Hayrick):

- Every tower that can aim at a dazzling creature in its range aims at it, whatever its targeting mode. With several in range, the tower's mode picks among them.
- A tower with more than one target per shot (Triple Bow, Lantern Garland, and in runs Twin Pebbles and Volley) puts its first target on a dazzling creature and picks the rest by its mode.
- A hidden creature cannot be aimed at, so a hidden Gleamer dazzles nothing.
- Splash, lines and pulses still reach the creatures around it. That is the answer.

Nap (Sleepyhead, Old Hayrick). Napping is its own status, stricter than out of reach (8.8):

- The first time its health falls to 0 or less, it is not popped. In the defeats step of that tick, its health is set to the value it will wake with, half its max health, rounded half up, and it starts napping for 2.0 s (Old Hayrick 3.0 s). Any slow or fright it held ends.
- While napping it does not move, blink, regrow, yawn, break a gate, summon or release. No tower can aim at it or hit it: splash, Bramble rings and Snow Fort lines skip it, and Bells and Scarecrows do not reach it. No heal reaches it. A napping Old Hayrick cannot be aimed at, so it dazzles nothing.
- Its break timer and its summon timer pause during the nap and go on from where they were when it wakes. A regrow, blink or yawn that comes due during the nap is skipped, and the next one comes at its usual time. Speed ups and health releases are not checked while it naps. From the tick it wakes they are checked again, against its health at that time.
- A release that began before the nap still finishes (Releases above).
- No creature that naps also heals others or digs. The data check refuses a creature with both (docs/ARCHITECTURE.md 14.4).
- When the nap ends, in the timers step, it wakes and walks on with that health.
- The next time its health falls to 0 or less, it pops for good, pays its bounty and counts as defeated.
- A nap is not a defeat: no bounty and no release. A napping creature keeps its wave running, and its bounty counts toward the early call bonus like any creature on the map (4.9).
- The creature panel says "Napping" and the time left. Its health shows the value it will wake with (9.4).

Grow (Snowroller, Snowsnore):

- Each time a Snowroller reaches a tile center after its entrance's, its max health and its health both rise by 10% of its starting max health, rounded half up. Its max health never goes above 3 times its starting max health: a rise that would pass that cap adds only what fits, to both, and after that it stops growing. Snowsnore grows by 2% at each tile, capped at 1.5 times (6.3).
- Starting max health is its max health when it appears, after strength and any Twist or risk card.
- Its drawing grows with it, up to 1.5 times its size, so growth reads by shape.

Yawn (Yawner, Snowsnore):

- 4.0 s after a Yawner appears, and every 4.0 s after that, it yawns: every attacking tower whose center is within 1.5 tiles of the Yawner's center dozes for 2.0 s.
- A dozing tower does not fire, and its reload timer does not run down. A new doze keeps the longer time.
- In the timers step, doze timers run down first and new yawns land after. So a new doze already stops that tick's towers step and lasts its full time.
- Every doze ends when a build phase begins. A wave cleared while another wave still runs starts no build phase (4.1), so dozes keep running down as usual.
- Bells, Scarecrows and Bakeries never doze.
- It yawns out of reach too: under a mound, it still makes the towers beside the mound doze.

Blink (Blinker, Glimmertoad):

- 3.0 s after a Blinker appears, and every 3.0 s after that, it blinks: in the movement step it first moves 2 tiles further along its route at once, then walks on as usual. It decides at every tile center on the way, as 7.3 says. A stump step counts as one tile.
- A blink that would pass the base ends there, and the creature gets through.
- A slow never shortens a blink. A napping creature never blinks.

Wake (Hootling, Glimmertoad):

- Awake is worked out once a tick, in the timers step. Every creature whose center is within 1.5 tiles of a Hootling's center, the Hootling included, is awake for that tick, and any slow it holds ends. Glimmertoad does the same within 2.0 tiles.
- An awake creature gets no slow during that tick, from a Bell, a Jam Pot or anything else.
- So a breaker near a Hootling breaks gates at full speed (7.7).
- Wake changes slows only. Frights and lures still work.

### 6.3 Bosses

A boss always comes in the final wave of its level or run. A boss that reaches the base costs 20 lives, which loses any Normal game. That holds in runs too: lives never rise above the starting lives (4.4), so on Normal a run's boss must be beaten. On Relaxed, a player with more than 20 lives left survives it and can still win the level or run. That is intended: Relaxed exists so a player who is stuck can move on, and such a win earns star 1 only. Bosses can be slowed, with one exception: Glimmertoad, which no slow reaches (6.2, Wake). Its card says so. The Moon Moth is a flyer, so the flyer rule decides (6.5): a Night Bell slows it, in runs so does any Lullaby Bell with the Frost Chime card (14.6), and once a Moth Lantern lures it low, every Bell does (5.15).

| Boss | Id | Region | Health | Armor | Speed | Moves | Lives lost | Bounty | Special |
|---|---|---|---|---|---|---|---|---|---|
| Grumblesack | `grumblesack` | 1 | 2000 | 0 | 0.4 | Walks | 20 | 100 | Every 6.0 s it drops 2 Scamps. |
| Ironshell | `ironshell` | 2 | 2500 | 10 | 0.4, rising | Walks | 20 | 150 | Gets faster as it is hurt. |
| Moon Moth | `moon_moth` | 3 | 1600 | 3 | 0.3 | Flies | 20 | 200 | Every 6.0 s, 3 Flitters fly out. |
| Old Tusk | `old_tusk` | 4 | 3000 | 4 | 0.35 | Walks | 20 | 250 | Breaks gates in 2.0 s. At half health, 4 Dusk Moths fly out. |
| Burrowbelly | `burrowbelly` | 5 | 3200 | 2 | 0.4 | Walks | 20 | 300 | Digs under for 2.0 s every 8.0 s. Comes up with 2 Mistwisps. |
| Old Hayrick | `old_hayrick` | 6 | 2600 | 0 | 0.4 | Walks | 20 | 300 | Dazzles. Popped once, it naps 3.0 s and gets up with half its health. |
| Snowsnore | `snowsnore` | 7 | 3400 | 3 | 0.35 | Walks | 20 | 350 | Grows as it walks, up to 1.5 times. Every 6.0 s, towers within 2.0 tiles doze for 3.0 s. |
| Glimmertoad | `glimmertoad` | 8 | 3600 | 4 | 0.35 | Walks | 20 | 400 | Hops 3 tiles ahead every 6.0 s. Cannot be slowed. At half health, 6 Flitters fly out. |

Exact boss rules:

- Grumblesack: 6.0 s after it appears, and every 6.0 s after that, 2 Scamps appear at its spot, the second 0.3 s after the first. They walk on from there.
- Ironshell: the first time its health falls to 75% of its max or below, its speed goes up by 0.1. The same happens at 50% and at 25%. Its speed goes 0.4, 0.5, 0.6, 0.7.
- Moon Moth: 6.0 s after it appears, and every 6.0 s after that, 3 Flitters appear at its spot, 0.3 s apart. They fly straight to the base from there.
- Old Tusk: follows the Gatecrasher rules (7.7) but breaks a gate in 2.0 s. The first time its health falls to 50% or below, 4 Dusk Moths appear at its spot, 0.3 s apart, starting on the next tick. This happens even if the same hit defeats it.
- Burrowbelly: 6.0 s after it appears, and every 8.0 s after that, it digs under for 2.0 s. Under the ground it keeps walking its route and is out of reach (8.8). Each time it comes up, that is 8.0 s after it appears and every 8.0 s after that, 2 Mistwisps appear at its spot, 0.3 s apart, and walk on from there. This is a summon, as Grumblesack's. The Mistwisps hide it from aim as they come out on its tile. They walk faster than it, so they soon move ahead and hide the creatures in front of it instead. Rings, lines and splash carry the fight.
- Old Hayrick: it dazzles (6.2). It naps once, as a Sleepyhead does (6.2), for 3.0 s: its health is set to half its max health when the nap starts, and it gets up with that. It pays its bounty only when popped for good. In a run, its escort walks on while every tower aims at it. In the campaign its wave brings no escort (12.5).
- Snowsnore: it grows by 2% of its starting max health at each tile center, up to 1.5 times (6.2, Grow). 6.0 s after it appears, and every 6.0 s after that, it yawns: every attacking tower within 2.0 tiles dozes for 3.0 s (6.2, Yawn).
- Glimmertoad: 6.0 s after it appears, and every 6.0 s after that, it hops 3 tiles ahead along its route, as a blink does (6.2). No creature within 2.0 tiles of it can be slowed, itself included (6.2, Wake). The first time its health falls to 50% or below, 6 Flitters appear at its spot, 0.3 s apart, starting on the next tick. This is a release, as Old Tusk's, and happens even if the same hit defeats it.
- Every creature a boss releases belongs to the boss's wave and uses its strength.
- Where released creatures appear, and what happens when a boss falls in the middle of a batch, is in Releases (6.2).

### 6.4 Strength

- Every wave has a strength, a whole percent. 100 means the numbers in 6.1 and 6.3.
- Strength scales health, heal and regrow amounts, bounties, the wave clear bonus and risk card rewards. Each is the base number times strength / 100, rounded half up, at least 1.
- Strength never changes armor, speed, tower damage or lives lost.
- Campaign: each level has a strength (12.3). By default every wave in the level uses it. The level designer may give single waves their own strength.
- Runs: waves 1 to 17 have strength 100 + 10 times (w minus 1). Wave 18, the boss wave, has the strength its boss pack sets (14.1, 14.3).
- Puffs and boss summons use the strength of their wave.
- Twists (13) and risk cards (14.5) change creatures after strength, and each step rounds by its own rule. With Thick Hides, a Scamp at strength 150 has 60 health, then 90.

Example: a Shellback at strength 150 has 135 health, armor 4, speed 0.7, and pays 18 gold.

### 6.5 Flyers, gates and anti air

- A flyer appears at its entrance and flies in a straight line to the center of the base at its speed. A flyer released by a boss starts from the spot where its release began (6.2).
- Flyers ignore roads, gates and gate sockets. They never open or break a gate.
- Only the Sling Post, the Firework Tower and the Moth Lantern, at every tier, can hit flyers. The Pumpkin Catapult, Longbow Loft, Bramble Cottage and Snow Fort cannot, until a Moth Lantern lures a flyer low: then every tower can hit it as if it were a walker (5.15).
- Bells slow flyers only as a Night Bell, in runs with the Frost Chime card (14.6), or once a flyer is lured low. A Bell that slows flyers slows every flyer in its ring, bosses included. Scarecrows frighten flyers only as a Crow Keeper, or once a flyer is lured low (5.13).
- A flyer that reaches the base costs lives like a walker.
- Flyers appear from level 1-5 on, so gates are never a complete answer.
- When the next wave has flyers, the map shows their straight line during the build phase (7.5).

### 6.6 One-line creature cards

| Creature | Line |
|---|---|
| Scamp | A small night creature. Each one that gets through costs a life. |
| Pip | Small, but comes in big crowds. Splash clears them. |
| Skitter | Very fast. Give it a long road, or make it drowsy. |
| Flitter | Flies straight over roads and gates. Not every tower can hit it. |
| Shellback | Its shell blocks 4 damage from every hit. Big hits get through. |
| Bubbler | Its bubble blocks one whole hit and returns in 2 seconds. Quick hits pop it. |
| Puffball | Bursts into 3 Puffs when popped. Splash catches them. |
| Puff | Three come out of every popped Puffball. Splash catches them. |
| Mender | Heals the creatures near it every 2 seconds. Stop it first. |
| Gatecrasher | Heads for your gates and breaks one open in 4 seconds. |
| Dusk Moth | An armored flyer. Small hits barely scratch it. |
| Grumblesack | Huge and slow. Drops 2 Scamps every 6 seconds. |
| Ironshell | Armor 10. It gets faster each time it loses a quarter of its health. |
| Moon Moth | A flying boss with armor 3. Every 6 seconds, 3 Flitters fly out. |
| Old Tusk | Armor 4. Breaks gates in 2 seconds. At half health, 4 Dusk Moths fly out. |
| Mossbud | Regrows a little health every second. Big hits beat it. Slows give it time. |
| Mistwisp | Others on its tile or beside it can't be aimed at. Splash still hits them. |
| Gleamer | Every tower that can reach it aims at it. Others slip past. |
| Sleepyhead | Popped once, it naps for 2 seconds, then gets up with half its health. |
| Snowroller | Grows with every tile it walks, up to 3 times its health. Pop it early. |
| Yawner | Every 4 seconds it yawns, and towers right beside it doze for 2 seconds. |
| Blinker | Every 3 seconds it blinks 2 tiles ahead along the road. |
| Hootling | Its hoots keep everything near it awake. Nothing near it can be slowed. |
| Burrowbelly | Digs under, out of reach, for 2 seconds every 8. Comes up with 2 Mistwisps. |
| Old Hayrick | Every tower aims at it. Popped once, it naps 3 seconds and gets up again. |
| Snowsnore | Grows as it walks. Every 6 seconds it yawns and towers near it doze. |
| Glimmertoad | Hops ahead every 6 seconds. Can't be slowed. At half health, 6 Flitters fly out. |

- Player-facing text says "pop" for a defeated creature, never "puff", because the Puff is a creature. That covers card lines, hints, messages, and Twist and card text.

## 7. Gates and routes

### 7.1 Sockets and gates

- Gate sockets are road tiles marked in the level.
- A level gives a set number of gates: 0 to 3 in the campaign (12.3), 1 to 3 in runs (14.1).
- A placed gate closes its socket to walkers.
- Levels have more sockets than gates, so where to put them is a choice. Suggested socket counts are in 12.3.

### 7.2 Placing, moving and removing

- In a build phase the player can place a gate on an empty socket, move a placed gate to another empty socket, or remove a gate back to the gate tray.
- A move is one step. The gate leaves its old socket and closes the new one at the same moment. The refusal check (7.4) looks at the result.
- Removing a gate is always allowed.

### 7.3 The shortest open route

Walkers always take the shortest open route to the base. Exactly:

1. Road tiles are nodes. A bridge tile is two nodes: its north-south road and its east-west road (3.7). A walker on a bridge tile is on the node of the road it came in on.
2. A step joins two neighbor nodes, north, south, east or west. On a bridge, the north-south node joins only its north and south neighbors, and the east-west node only its east and west neighbors.
3. An ice slide tile has one way out: the way its arrow points. No step goes onto an ice slide tile against its arrow, that is, from the tile its arrow points to (3.8).
4. Twin hollow stumps are joined by one more step, both ways (3.9).
5. A node is open unless a closed gate stands on it. The distance of an open node is the fewest steps from it to the base along open nodes, using only the steps above. The base has distance 0.
6. A walker standing on a node center picks its next node from the open nodes one step away whose distance is exactly one less than its own. Tie break: if more than one node qualifies, it takes the first in this fixed order: south, west, east, north, then the stump step. These are grid directions (3.1), the same in any screen layout.
7. A walker decides only at tile centers. Between centers it keeps going to the node it picked.
8. A walker's first step is from its entrance tile center.

On maps with no map feature, every road tile is one node and every step joins two neighbor tiles, so these rules give the same routes as before the features. Gatecrashers and Old Tusk walk the same steps as if no gates were placed (7.7). A placement is refused when any entrance would have no open route (7.4). Gates never close during a wave, so a walker always keeps a route.

Players never need the tie break or these points in words. The route line (7.5) always shows the result.

### 7.4 Refusal

- A placement or move is refused if, after it, any entrance would have no open route to the base.
- When refused, the gate does not stay. The socket shows a crossed-out gate icon for 1.5 s, a one-line message says "That would close every road.", and a short refusal sound plays. Nothing else changes.

### 7.5 The route line

- During every build phase, the map shows a solid route line from each entrance to the base. It follows exactly the route a walker appearing there would take (7.3).
- While the player drags a gate over a socket, the lines show the result as if the gate were dropped there. Over a socket that would be refused, the crossed-out gate icon shows instead.
- If the next wave has a Gatecrasher or Old Tusk, its route shows as a dashed line, with a crack icon on each closed gate it would break.
- If the next wave has flyers, a dotted straight line runs from each entrance they use to the base.
- "The next wave" is the wave as it will really come, with the level's Twist and any waiting risk card. With Gateless Night waiting, the lines show every gate open (14.5).
- Map features (3.5): a line runs under a tunnel's mound, into one mouth and out of the other. At a bridge it goes over the deck or under it, and under the deck it is cut by the bridge, so over and under read by shape. A route may cross itself at a bridge. On an ice slide the line's arrows agree with the slide's chevrons. At a hollow stump the line runs into the stump and starts again at its twin.
- The lines are hidden during wave phases. The creatures show the way.

### 7.6 Locked during waves, and broken gates

- From the moment a wave starts until the next build phase begins, gates cannot be placed, moved or removed, even while paused. Tapping a gate then says "Gates are locked until the wave is over."
- A gate broken by a Gatecrasher or Old Tusk is open to every walker until the next build phase begins. Then it mends by itself, closed, on the same socket.
- In runs, the Iron Gate card locks placed gates for good each time a wave starts (14.6), and Gateless Night opens every gate from the start of its wave until the next build phase (14.5).

### 7.7 The Gatecrasher

The same rules apply to Old Tusk, with 2.0 s instead of 4.0 s.

- A Gatecrasher follows its own route: the shortest route as if no gates were placed, with the same tie break (7.3).
- When the next tile on that route has a closed gate, it stops at the center of the tile before the gate and starts breaking it. Breaking takes 4.0 s.
- A slow slows the breaking by the same percent. At a 45% slow, each second of play counts as 0.55 s of breaking.
- When the time is up, the gate is broken (7.6). The Gatecrasher walks on. If its route meets another closed gate, it breaks that one too.
- If it is defeated while breaking, the gate stays closed and the breaking is lost.
- Each Gatecrasher keeps its own timer. Two at one gate do not add up. The gate breaks when the first timer runs out.

### 7.8 Walkers changing route during a wave

- Gates never close during a wave. They can only break open.
- When a gate breaks, distances are worked out again at once.
- Every walker except Gatecrashers and Old Tusk uses the new distances from its next tile center. A walker may turn back if the new shortest route lies behind it, along the steps of 7.3 only, so never against an ice slide's arrow.
- Gatecrashers and Old Tusk keep their own route, which never depends on gates.

## 8. How combat resolves

### 8.1 Tick order

The sim runs on a fixed timestep (docs/ARCHITECTURE.md). Each tick runs these steps in this order:

1. Spawns. Creatures due this tick appear, in the order of their groups in the wave data, then Puffs and boss summons that are due. Every creature gets the next spawn number when it appears. Burrowbelly's Mistwisps come as summons, and Glimmertoad's Flitters as a release (6.3).
2. Timers. Bubbles that are due come back. Slow timers run down and expire. Menders that are due heal. Breaking timers of Gatecrashers and Old Tusk run down, and a gate whose timer runs out breaks now; distances are worked out again. Then, in this order (6.2, 6.3): Mossbuds that are due regrow; naps that end (the creature wakes); digging that starts or ends; doze timers run down, then yawns that are due give new dozes; lure and fright timers run down. Last, wake: every creature in a Hootling's or Glimmertoad's reach is awake for this tick, and its slow ends.
3. Rings. Every creature of the right kind in a Bell's ring gets that Bell's slow (8.5), except an awake creature. Every creature of the right kind in a Scarecrow's ring gets its fright (5.13).
4. Movement. Creatures move, in id order. A creature whose blink or hop is due blinks first, then walks its usual step for the tick (6.2). Stump steps (3.9) and growth at tile centers (6.2) happen as it walks. A creature that reaches the base is removed and costs its lives. If lives are 0 or less, the game is lost at once.
5. Towers. Hidden creatures are worked out first (6.2, Mist). Attacking towers act in spot order, row by row from the top (3.4). A dozing tower skips its turn. Each other tower runs down its reload timer, picks targets, dazzle included (6.2), fires, and its hits land at once (8.3, 8.4). Pulses, lines and lures land at once too, and a lure already counts for the towers that act after it (5.15). A creature at 0 health or less is down: it cannot be targeted or hit again this tick.
6. Defeats and boss events. Every creature that is down is defeated, except a Sleepyhead or Old Hayrick that is down for the first time: its health is set to its wake value and its nap starts (6.2). Bounties are paid. Puffballs queue their Puffs, and the first appears on the next tick. Boss health events happen: Ironshell's speed rises from the next tick, and Old Tusk's moths and Glimmertoad's Flitters appear on the next tick.
7. Wave checks. A wave runs from the moment it starts until it is cleared. A running wave with nothing left on the map and nothing left to spawn is cleared and pays its clear bonus. A napping or out of reach creature is on the map, so it keeps its wave running (8.8). Then, if no wave is still running, one of two things happens: if every wave has started and lives are above 0, the game is won (4.1); if not, the build phase begins. While any wave is still running, neither happens, even if the final wave is already cleared.

Combat never uses randomness. The campaign uses no randomness at all. Runs use seeded randomness only to build the run and draw cards (14).

### 8.2 Targeting

- Every attacking tower has a targeting mode, except the Bramble Cottage, which aims at nothing (5.12). The default is First. The player can change it at any time, even mid-wave. It stays through upgrades.
- First: the creature nearest the base. For a walker this is its remaining route: the distance of the node it is walking to, plus the part of the current step it has left. On a bridge that is the node it is on (3.7), and a stump step counts as one step (3.9). A Gatecrasher's or Old Tusk's remaining route is measured on its own route. For a flyer, low or not, it is the straight-line distance to the base center.
- Last: the creature farthest from the base, measured the same way.
- Strong: the creature with the highest max health. Ties go by First.
- Any other tie: the creature with the lowest spawn number.
- A tower picks again every time it fires.
- Only creatures in range, and of a kind the tower can hit, count. A low flyer counts for every tower: as a walker for towers that hit walkers, and still as a flyer for towers that hit flyers (5.15). Hidden creatures (6.2, Mist), and creatures that are out of reach or napping (8.8), never count.
- A dazzling creature in range comes first, whatever the mode (6.2, Dazzle).
- Triple Bow: picks up to 3 different creatures, in its mode's order.
- Moth Lantern: aims at flyers that are not low first. The Lantern Garland picks up to 3 different flyers the same way (5.15).
- Snow Fort: aims like any tower, and its line runs on through its target (5.14).

### 8.3 Damage, armor and bubbles

For each creature a hit reaches:

1. If its bubble is up, the bubble pops. Nothing else happens.
2. Hit damage = the tower's damage plus the best Bakery damage bonus on that tower (8.6) plus any run card bonus (14.5).
3. If the tower ignores armor (Longbow Loft at every tier, Skyrocket, Holly Crown), damage taken = hit damage. Otherwise damage taken = hit damage minus armor, but at least 1.
4. If the creature is frightened (5.13), damage taken = that number times (100 + fright) / 100, rounded half up.
5. The creature's health goes down by the damage taken. At 0 or less it is defeated, or it naps instead (6.2, 8.1).
6. If the tower is a Jam Pot, the creature gets the Jam slow (8.5). If the tower is a Moth Lantern, the flyer is lured low (5.15).

### 8.4 Splash

- A splash attack picks its target as usual.
- Its hit reaches every creature of the kind it can hit whose center is within the splash radius of the target's center, the target included. Catapult splash reaches walkers and low flyers (5.15). Firework splash reaches flyers only, low or not.
- Splash still hits hidden creatures (6.2). It skips creatures that are out of reach or napping (8.8).
- Each creature takes the full hit separately, with its own armor, bubble and fright.
- Bramble pulses (5.12) and Snow Fort lines (5.14) reach many creatures in the same way: each takes the full hit separately.

### 8.5 Slows

- A slow is a percent. A slowed creature moves at its speed times (1 minus the slow). Gate breaking also runs at (1 minus the slow).
- A creature holds one slow at a time: a percent and a time left.
- A new slow replaces the held one if its percent is higher. If the percent is equal, the time left becomes the longer of the two. If it is lower, nothing changes.
- When the time left runs out, the creature is no longer slowed.
- Bells: every tick, every creature of the right kind in the ring gets the Bell's slow with 1.0 s left. So the slow lingers 1.0 s after it leaves the ring.
- Jam Pot: 40% with 3.0 s left, on each walker it damages.
- Slows never add up. Only the strongest applies.
- An awake creature gets no slow, and an awake creature's slow ends (6.2, Wake). A creature that starts a nap loses its slow (6.2, Nap).

### 8.6 Bakery boosts

- A Bakery boosts every attacking tower whose tile center is within its reach of its own: 1.5 tiles, or 2.5 with the Warm Ovens card (14.5). That includes the Bramble Cottage, the Snow Fort and the Moth Lantern. It never boosts Bells, Scarecrows, other Bakeries or itself (5.8).
- A rate boost makes the tower's reload timer run faster by that percent (5.2). A +25% boost means 1.25 times as many shots.
- A tower takes only the best rate boost and the best damage bonus from all the Bakeries that reach it. Boosts of the same kind never add up. A tower next to a Grand Oven and a Spice Kitchen takes +40% rate from the first and +2 damage from the second.
- Boosts change at once when a Bakery is built, upgraded or sold.

### 8.7 What stacks

| Effect | Adds up? | Rule |
|---|---|---|
| Armor | No | Subtracted from each hit, at least 1 damage gets through. Longbow Loft, Skyrocket and Holly Crown ignore it. |
| Slows | No | One slot per creature. The strongest wins (8.5). |
| Bakery rate boosts | No | The best one counts. |
| Bakery damage bonuses | No | The best one counts. |
| A rate boost and a damage bonus from two Bakeries | Yes | One of each kind can apply together. |
| Run card bonuses | Yes | They change the tower's own numbers: added amounts first, then percents (14.6). Bakery bonuses come on top. |
| Splash | Yes | Every creature in the radius takes the full hit. |
| Several towers on one creature | Yes | Every hit is separate. |
| Bubbles | One per creature | Blocks one hit, back 2.0 s after it pops. |
| Healing | Yes | Each Mender heals on its own. A Mossbud's regrowth comes on top. |
| Frights | No | One fright per creature. The strongest wins, and an equal one keeps the longer time (5.13). |
| A fright and armor | In order | Armor comes off first, then the fright adds its percent (8.3). |
| Lures | No | One per flyer. A new lure keeps the longer time (5.15). |
| Dozes | No | One per tower. A new doze keeps the longer time (6.2). |
| Out of reach, hidden, awake | No | Each is on or off (8.8). |

### 8.8 Statuses

Out of reach. Tunnels (3.6), stump steps (3.9) and Burrowbelly's digging (6.3) share one status:

- A creature that is out of reach cannot be aimed at or hit by any tower. Splash, Bramble rings and Snow Fort lines skip it. Bells and Scarecrows do not reach it.
- A slow or fright it already holds keeps running down as usual.
- Creatures' own effects still work: a Mender still heals it, a Mossbud still regrows, a Mistwisp still hides the creatures on and beside its tile, and a Yawner still yawns.
- It still costs lives at the base, and its wave is not cleared while it is on the map.
- A flyer is never out of reach because of a map feature.
- A nap (6.2) is not this status. It is its own, stricter status: a napping creature does not move, blink, regrow, yawn, break a gate, summon or release, and no heal reaches it.

Every status, and how it shows. Each one reads by shape, never by color alone (9.7). The marks are the art director's (docs/art/).

| Status | Who | Shown as | Stacks |
|---|---|---|---|
| Slowed | Creatures in a Bell's ring, or hit by a Jam Pot | A sleepy "z z" mark | One slow. The strongest wins (8.5) |
| Bubble | Bubblers, and every creature on Bubble Night | A ring outline | One per creature (6.2) |
| Out of reach | In a tunnel or a stump step, Burrowbelly while dug under | Hidden under the mound, a few sparkles at the stump it entered, a moving dirt mound with claw tips | On or off |
| Hidden | On or next to a Mistwisp's tile (6.2) | The Mistwisp's curl, small, above the creature's head | On or off, worked out at the start of the towers step |
| Napping | Sleepyhead, Old Hayrick (6.2) | Lying on its side with a small crescent moon above. The panel says "Napping" | Once per creature |
| Frightened | In a Scarecrow's ring (5.13) | Two small zigzag shiver lines on each side | One fright. The strongest wins |
| Low | A flyer a Moth Lantern hit (5.15) | Flying just above its shadow, with a pale ring at the shadow | One lure. The longest wins |
| Awake | Near a Hootling or Glimmertoad (6.2) | A small open eye above it | On or off, worked out once a tick in the timers step |
| Dozing | Attacking towers near a yawn (6.2) | One big "z" over the tower, unlike a slowed creature's smaller "z z" | One doze. The longest wins |

## 9. Information on screen

### 9.1 Wave preview

- The preview of the next wave is always on screen, open or folded.
- Open, it lists each group in spawn order: the creature's silhouette and name, how many, and the entrance letter.
- Folded, it is a strip one line tall: each group's silhouette, how many and the entrance letter, in spawn order. When the groups do not fit on that line, the strip shows as many as fit and a "+N" chip for the rest.
- During waves the preview is folded.
- In landscape it is always open in a build phase. In portrait a build phase starts with it open only when it fits in the room under the map. Otherwise the build phase starts with it folded, and the strip still shows what is coming, how many and from which entrance. On the Fold5 cover screen that happens on every 12 and 13 row map, and on shorter maps for some big or boss waves. Phones with shorter screens start it folded more often.
- One tap on the strip opens the preview over the map, and one tap on its header folds it again. That choice holds until the next build phase or the next change of layout.
- A creature the player has never seen has a "New" tag, in the open list and in the strip, until the wave that brings it starts.
- A boss row adds its one-line ability (6.6).
- Tapping a row opens that creature's card with its numbers for that wave: health, heal amount and bounty at the wave's strength.
- The preview shows the wave as it will really come, with the level's Twist and any waiting risk card.
- In runs, a waiting risk card shows first: as a row at the top of the open list with its effect, and as a chip at the start of the strip. A group that a risk card adds comes after the wave's own groups.
- During build phases the map also shows the route lines for the next wave (7.5).

### 9.2 Info cards

- The first time a creature appears in a preview, its card opens by itself in that build phase: silhouette, name, its one line (6.6) and its numbers at that wave's strength.
- If a creature the player has never seen reaches the map before its card has opened, the game pauses and its card opens. That happens when its wave was called early, and for a creature that a Puffball or a boss releases.
- The first time a tower is available, its card opens at the start of that level (5.9). In runs, it opens when the player picks the card that adds the tower.
- Each card opens by itself once per player. It counts as seen when the player closes it, and that is saved. Cards can be reopened from the preview, the build menu and the Info screen.

### 9.3 Tapping a tower

| Tower kind | Shows |
|---|---|
| Attacking towers | Name, tier and path. Damage per hit, with any Bakery bonus shown as "+2". Rate (attacks per second, one decimal, boosts included). Range in tiles. On a Bramble Cottage that row reads "Ring" instead of "Range", here and in its upgrade numbers (9.5), because its thorns hit everything in it. What it hits: walkers, flyers or both. Special: splash radius, ignores armor, targets per shot when more than 1, slow percent and time, line width (Snow Fort), how long a flyer stays low (Moth Lantern), or that it hits every creature in its ring (Bramble Cottage). Bakery boost received. Dozing, with the time left, while it dozes. Targeting mode, which can be changed here, except on a Bramble Cottage. Total spent. Sell value right now. |
| Lullaby Bell | Name, tier and path. Slow percent. Range. Linger 1.0 s. Affects walkers, or walkers and flyers. Total spent. Sell value. |
| Scarecrow | Name, tier and path. Fright percent. Range. Linger 1.0 s. Affects walkers, or walkers and flyers. Total spent. Sell value. |
| Bakery | Name, tier and path. Rate boost and damage bonus. Reach. How many towers it boosts right now. Total spent. Sell value. |

### 9.4 Tapping a creature

Name. Health now and max. Armor. Speed now and base, in tiles per second to two decimals. Walks or flies. Its one line. Lives lost if it gets through. Gold when defeated. Status: slowed (percent and time left), bubble (up, or back in so many seconds), breaking a gate (time left), frightened (percent and time left), low (time left), hidden, out of reach, awake, and napping (time left). While it naps, its health shows the value it will wake with (6.2). A Snowroller's or Snowsnore's max health is the one it has grown to. Once it has grown, its status also says "Grown", with the max health it started with (6.2, Grow).

### 9.5 Placing and upgrading

- When the player picks a tower for a spot, its range ring shows before confirming. A Bell's ring is its slow zone, a Scarecrow's its fright zone, and a Bramble Cottage's the reach of its thorns. A Bakery shows the eight tiles it reaches and marks the towers it would boost.
- An upgrade shows every number that changes as its before and after values side by side, with an arrow drawn between them, and the price, before confirming.
- At tier 3 both paths show side by side, each with its numbers. The screen says the choice is permanent for this tower.

### 9.6 Hints and highlights

- Early levels, and any level that brings something new, have one one-line hint and one highlighted thing: a spot or a socket on the map, or the call button (12.4).
- The hint shows at the start of the level the first time it is played, and always on the level card. It closes when the player taps it or the first wave starts.
- When the highlight is the call button (level 2-1), the button wears a pulsing ring whenever it offers an early call, until the player first calls a wave early. It never glows in a build phase, where the same button starts the next wave.
- There is no other tutorial text. The Info screen holds the full rules from this file.

### 9.7 Signals that never rely on color

- Route lines differ by line style: solid for walkers, dashed for Gatecrashers, dotted for flyers.
- A refused gate shows a crossed-out gate icon and a message.
- A broken gate has a crack shape.
- A slowed creature shows a sleepy "z z" mark. A bubble is a ring outline. "New" is a word.
- Every other status has a mark of its own shape (8.8). A dozing tower shows one big "z", unlike a slowed creature's smaller "z z".
- Map features read by shape: the tunnel's mound, the bridge's plank deck, the slide's chevrons and the stumps' carved symbols (3.5).
- The art director owns the look. Every tower and creature must read by silhouette alone.

## 10. Stars

### 10.1 Star 1

Win the level, on Normal or Relaxed. Card text: "Win the level."

### 10.2 Star 2

Win on Normal with 15 or more lives left. The same rule on every level. Card text: "Keep 15 lives."

### 10.3 Star 3

Win on Normal while meeting the level's challenge. Each level uses one of these types (12.4 lists them by level):

| Type | Card text, for example | Met when |
|---|---|---|
| No lives lost | Lose no lives. | Lives at the win equal starting lives. |
| Tower limit | Have at most 4 towers. | The number of towers on the map was never above N. Every tower counts, Bells, Scarecrows and Bakeries included. |
| Tower ban | Build no Sling Posts. | That tower was never built in the level. |
| Gate limit | Use at most 1 gate. Or: Use no gates. | At the start of every wave, at most N gates were placed. |
| Tier cap | Upgrade no towers. Or, with a cap of tier 2: No tower above tier 2. | No tower went above tier N (1 or 2) in the level, even one sold later. A cap of tier 1 always reads "Upgrade no towers." (Bart, hard stop B) |
| Early calls | Call 4 waves early. | At least N waves were called early (4.9). |
| Kinds limit | Use at most 3 kinds of tower. | At most N different tower types were built in the level. |
| Gates whole | Use every gate and keep them whole. | At the start of every wave all the level's gates were placed, and no gate was broken in the level. |

Rule for star 3 challenges: a challenge must always leave at least two kinds of attacking tower usable, so no level ever asks for a one-tower solution.

### 10.4 Earning and keeping stars

- Each star is earned the first time its rule is met in a win, and kept for good.
- The three stars can come from different wins.
- A Relaxed win earns star 1 only.
- The balance bots must find, for every level, one Normal win that earns all three stars at once.

### 10.5 The level card

The level card shows the level name, number of waves, number of gates, the three star lines, which stars are earned, the hint, the Normal or Relaxed choice, and the Twist once it is unlocked.

### 10.6 Stars during play

Only in a campaign level that is not a Twist. Twists, runs and the daily have no stars, so they show no star lines and no warnings.

- The Pause menu shows the level's three star lines, with the same sentences as the level card. A resumed game opens on this menu too.
- Each line ends with one word:
  - "Earned": the player already has this star for this level.
  - "Not yet": a win from this moment can still earn it.
  - "Lost": this game can no longer earn it. The line is also struck through, so it never relies on color. Star 2 is lost once lives fall below 15. Star 3 is lost once its rule is broken (10.3), or for "Call N waves early" once too few waves are left to call.
  - "Normal only": lines 2 and 3 on Relaxed, unless already earned. These lines are not struck through, because nothing was lost.
- Warnings. On Normal, while star 3 is not yet earned for the level and this game can still earn it, the game warns before a tap that would lose it. The warning is an empty star with the words "Loses the third star." It shows:
  - in the build menu, on a tower that would break the rule: one tower over the limit, a banned tower, or a kind of tower over the limit;
  - on an upgrade that would go above the tier cap.
  The player can still go ahead.
- Gates. When placing a gate puts more gates on the map than the rule allows, the gate message says "Start a wave with this gate and the third star is lost." Placing it loses nothing: the star is lost only if a wave starts with too many gates placed, so the player can still take one back.
- There is no warning on Relaxed, once star 3 is earned, or once it is lost.

## 11. Relaxed difficulty

Relaxed gives more lives and more starting gold. Nothing else changes: same maps, waves, creatures, towers, prices, bounties and rules.

| | Normal | Relaxed |
|---|---|---|
| Lives, campaign and runs | 20 | 40 |
| Starting gold, campaign | The level's value (12.3) | 1.5 times Normal, rounded up to a multiple of 10 (listed in 12.3) |
| Starting gold, runs | 300 | 450 |

- The player picks Normal or Relaxed before each level or run. Normal is the default.
- Relaxed wins earn star 1 only (10.4). Star 1 is all that progress needs (16).
- Twists: the Twist's change applies first, then Relaxed. Five Lives gives 5 lives on Normal and 10 on Relaxed. Thin Purse halves the gold first, then Relaxed adds half again.
- The daily challenge is always Normal.
- After a Normal loss of a campaign level that is not a Twist, or of a normal run, the loss panel adds one line: "Stuck? Relaxed gives 40 lives and more gold." The number comes from the rules data.

## 12. Campaign

### 12.1 Regions

| Region | Name | Id | Setting | Towers it brings | Creatures it brings | Boss | Map feature |
|---|---|---|---|---|---|---|---|
| 1 | Lantern Hill | `lantern_hill` | The village meadow at dusk | Sling Post, Pumpkin Catapult | Scamp, Pip, Flitter | Grumblesack | none |
| 2 | Millbrook | `millbrook` | River, mills and fords | Lullaby Bell, Longbow Loft | Skitter, Shellback, Bubbler | Ironshell | none |
| 3 | Willow Fen | `willow_fen` | Marsh boardwalks and reeds | Firework Tower | Puffball, Dusk Moth | Moon Moth | none |
| 4 | Moonspire Keep | `moonspire_keep` | The old castle town on the hilltop | Bakery | Mender, Gatecrasher | Old Tusk | none |
| 5 | Hollow Lanes | `hollow_lanes` | Sunken lanes under arching hedgerows | Bramble Cottage | Mossbud, Mistwisp | Burrowbelly | Tunnels |
| 6 | Russet Orchards | `russet_orchards` | Autumn orchards, hay barns and cart bridges | Scarecrow | Gleamer, Sleepyhead | Old Hayrick | Bridges |
| 7 | Frostpine Ridge | `frostpine_ridge` | A snowy pine ridge with sled runs and ski huts | Snow Fort | Snowroller, Yawner | Snowsnore | Ice slides |
| 8 | Starglen | `starglen` | A glade of glowing toadstools and hollow stumps | Moth Lantern | Blinker, Hootling | Glimmertoad | Hollow stumps |

Every region has its own ground colors and scenery (docs/art/EXPANSION_LOOK.md 3). Lantern Hill keeps the meadow. Bart gave regions 2 to 4 grounds of their own on 2026-10-27. That is art only: play is the same on every ground, and the region is never a game signal.

### 12.2 Unlock order

Each line is one new thing, in the order the player meets it.

| Level | New |
|---|---|
| 1-1 | Sling Post, Pumpkin Catapult, Scamp |
| 1-2 | Gates (1 gate) |
| 1-3 | Upgrades (taught, no new content) |
| 1-4 | Pip |
| 1-5 | Flitter, the first flyer |
| 1-6 | Tier 3 paths (taught), Grumblesack |
| 2-1 | Skitter, early calls (taught) |
| 2-2 | Lullaby Bell |
| 2-3 | Longbow Loft, Shellback |
| 2-4 | A second gate |
| 2-5 | Bubbler |
| 2-6 | Ironshell |
| 3-1 | Firework Tower |
| 3-2 | Puffball |
| 3-3 | A third gate |
| 3-4 | Dusk Moth |
| 3-5 | Nothing new |
| 3-6 | Moon Moth |
| 4-1 | Bakery |
| 4-2 | Mender, targeting modes (taught) |
| 4-3 | Gatecrasher |
| 4-4 | Nothing new |
| 4-5 | Nothing new |
| 4-6 | Old Tusk |
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

- A level's towers are every tower brought up to and including that level. Replays use the same list. So a level offers 7 kinds of tower from 5-2, 8 from 6-2, 9 from 7-2 and all 10 from 8-2.
- From region 5 on, each region's first level brings only its map feature and has one entrance, so the feature is its only new idea. Its hint and highlight teach it, as 1-2 taught gates.
- Level 1-1 opens with two towers so that the brief's check, that no single tower type earns three stars alone, can pass on every level, the first one included (brief section 11).

### 12.3 Levels

"First wave" is the wave where the new creature first appears, alone. Gate sockets are suggestions for the level designer. Gold is starting gold.

Region 1, Lantern Hill:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 1-1 | First Lanterns | Build towers on the spots by the road. | Sling Post, Pumpkin Catapult, Scamp | 1 | 0 (0) | 8 | 100 | 200 | 300 |
| 1-2 | The Fork | A gate closes a road. Creatures take the shortest open road. | Gates | none | 1 (2) | 8 | 100 | 250 | 380 |
| 1-3 | Tall Posts | Upgrade towers when spots run out. | none | none | 1 (2) | 9 | 100 | 250 | 380 |
| 1-4 | Pumpkin Patch | Splash beats crowds. | Pip | 3 | 1 (3) | 9 | 100 | 300 | 450 |
| 1-5 | Wings at Dusk | Flyers ignore roads and gates. | Flitter | 3 | 1 (3) | 10 | 100 | 300 | 450 |
| 1-6 | Grumblesack | Tier 3 paths, then a boss. | Grumblesack | 10 | 1 (3) | 10 | 100 | 350 | 530 |

Region 1 waves set their own strength where TUNING_R1.md lists one: tougher Scamp waves at 140 to 180, and the 1-6 boss wave at 50, so Grumblesack has 1000 health there.

Region 2, Millbrook:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 2-1 | Mill Race | Calling waves early pays gold. | Skitter | 2 | 1 (3) | 10 | 130 | 350 | 530 |
| 2-2 | Sleepy Mill | Drowsy crowds bunch up for splash. | Lullaby Bell | none | 1 (3) | 10 | 135 | 400 | 600 |
| 2-3 | Shell Road | Armor blocks small hits. Longbows ignore it. | Longbow Loft, Shellback | 3 | 1 (3) | 10 | 140 | 400 | 600 |
| 2-4 | Two Fords | Two gates make one long road. | Second gate | none | 2 (4) | 11 | 145 | 450 | 680 |
| 2-5 | Bubble Brook | Quick hits pop bubbles, big hits land after. | Bubbler | 2 | 2 (4) | 11 | 150 | 450 | 680 |
| 2-6 | Ironshell | Keep the boss drowsy and pierce its shell. | Ironshell | 12 | 2 (5) | 12 | 160 | 500 | 750 |

Region 3, Willow Fen:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 3-1 | Lantern Festival | Anti air hits whole flocks. | Firework Tower | none | 2 (4) | 11 | 170 | 500 | 750 |
| 3-2 | Puffball Pond | Catch a splitter's pieces with splash. | Puffball | 2 | 2 (4) | 11 | 175 | 550 | 830 |
| 3-3 | Reed Maze | Some sockets matter more than others. | Third gate | none | 3 (5) | 12 | 180 | 550 | 830 |
| 3-4 | Moth Lights | Armored flyers need a heavy anti air shot. | Dusk Moth | 3 | 2 (5) | 12 | 185 | 600 | 900 |
| 3-5 | Two Shores | Split the defense between two entrances. | none | none | 3 (6) | 12 | 190 | 600 | 900 |
| 3-6 | Moon Moth | A flying boss. Gates cannot help. | Moon Moth | 12 | 3 (6) | 12 | 200 | 650 | 980 |

Region 4, Moonspire Keep:

| Level | Name | The one idea it teaches | New | First wave | Gates (sockets) | Waves | Strength | Gold, Normal | Gold, Relaxed |
|---|---|---|---|---|---|---|---|---|---|
| 4-1 | Bakers' Row | Support towers boost their neighbors. | Bakery | none | 2 (5) | 12 | 210 | 650 | 980 |
| 4-2 | Mending Lane | Stop the healers first. | Mender | 2 | 2 (5) | 12 | 220 | 700 | 1050 |
| 4-3 | Gatecrash | Guard the gate a breaker heads for. | Gatecrasher | 3 | 3 (6) | 12 | 230 | 700 | 1050 |
| 4-4 | Market Square | Three roads, everything at once. | none | none | 3 (6) | 12 | 240 | 750 | 1130 |
| 4-5 | Castle Steps | Flyers, breakers and healers together. | none | none | 3 (6) | 12 | 250 | 750 | 1130 |
| 4-6 | Old Tusk | The final boss breaks gates. | Old Tusk | 12 | 3 (6) | 12 | 260 | 800 | 1200 |

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

Suggested entrances: one in region 1, one or two in region 2, two in region 3 from 3-2 on, two or three in region 4. Level 3-1 keeps one entrance, so the Firework Tower is its only new idea. The second entrance joins on 3-2, first in a wave of its own. Level 3-5 has two and 4-4 has three. Region 5: one, then two from 5-5. Regions 6 and 7: one on the first level, then two. Region 8: one on 8-1, then two, and three on 8-5.

Regions 5 to 8 aim for 6 to 9 minutes a level at 1x. Their strength rises slowly, 230 to 300, because the new difficulty comes from new ideas, not bigger numbers.

From region 2 on, most waves set their own strength in the level file, often below the level's, which is the default for a wave that sets none. Pip waves stay at 115 or less where a tier 2 Catapult should pop a Pip in one hit, and from region 3 on a late Pip crowd may come at 160 to 210 (12.5). Boss waves set theirs too: Grumblesack at 50 on 1-6 (1000 health), Ironshell at 100 on 2-6 (2500 health) and the Moon Moth at 70 on 3-6 (1120 health). The boss waves of regions 5 to 8 start at: Burrowbelly at 80 on 5-6 (2560 health), Old Hayrick at 75 on 6-6 (1950, then 975 more after its nap), Snowsnore at 70 on 7-6 (2380, growing to 3570) and Glimmertoad at 50 on 8-6 (1800). The level designer tunes them with the bots. Glimmertoad starts lower than the others. Its hops carry it down the road about 2.4 times as fast as it walks, and no Bell slows it, so the same towers deal it less than half the damage they deal Old Tusk, which comes at 70 on 4-6 (E8.1a). The region 8 tuning raised it to 55 on 8-6 (1980 health). At 50 it never threatened the base: the plain mixed recipe won at every gate placement, and the boss wave cost none of them a life. At 55 the recipe wins only where its gates close the stump or the short road to the base, and in Double Trouble the second Glimmertoad comes 12.0 s after the first (12.5, docs/design/TUNING_R8.md).

### 12.4 Level cards: star 3, hint and highlight

The number in each star 3 rule is a starting target. The level designer confirms it with the bots once the map exists.

| Level | Star 3 | Hint | Highlight |
|---|---|---|---|
| 1-1 | Upgrade no towers. | Tap a glowing spot to build a tower by the road. | The best first build spot |
| 1-2 | Upgrade no towers. | Tap the glowing road to drop your gate there. The line shows their new way. | The socket that makes the long road |
| 1-3 | Have at most 2 towers. | Build on the glow, then tap your tower to upgrade it. | The spot that sees the most road |
| 1-4 | Upgrade no towers. | Pips come in crowds. Catapults hit the whole crowd. | The spot at the busiest bend |
| 1-5 | No tower above tier 2. | Flitters fly over roads and gates. Only Sling Posts hit them. | A spot under the flight line |
| 1-6 | Use no gates. | At tier 3, a tower picks one of two paths for good. | The spot beside the boss's longest stretch |
| 2-1 | Call 6 waves early. | Doing well? Call the next wave early for bonus gold. | The call button |
| 2-2 | Use no gates. | Bells make walkers drowsy. Slow crowds are easy Catapult targets. | A spot whose ring covers a bend beside a Catapult spot |
| 2-3 | No tower above tier 2. | Longbows ignore armor but can't hit flyers. Keep a Sling Post for the Flitters. | A spot that sees two stretches of road |
| 2-4 | Use at most 1 gate. | Two gates now. Make their road as long as you can. | The socket that starts the longest road |
| 2-5 | Build no Longbow Lofts. | A bubble stops one hit. Quick Sling Posts pop it for the big hitters. | A spot near the start of the road |
| 2-6 | Use at most 3 kinds of tower. | Ironshell gets faster as it gets hurt. Keep it drowsy. | The spot beside its longest stretch |
| 3-1 | Build no Sling Posts. | Fireworks hit only flyers, but the whole flock at once. | A spot under the flight line |
| 3-2 | No tower above tier 2. | Puffballs burst into three Puffs. Pop them near a Catapult. | The spot where the road bunches |
| 3-3 | Have at most 5 towers. | Three gates. Try each socket and watch the line. | A socket that looks good but is not the best |
| 3-4 | Build no Sling Posts. | Dusk Moths wear armor. Build a Firework on the glow and upgrade it early. | A spot under both flight lines |
| 3-5 | No tower above tier 2. | none | none |
| 3-6 | Build no Sling Posts. | The Moon Moth flies straight in. Line its path with Fireworks. | A spot under its flight line |
| 4-1 | Have at most 6 towers. | Bakeries speed up nearby towers. Close one side high and the other side low. | The center of a cluster of spots |
| 4-2 | Build no Pumpkin Catapults. | Menders heal their friends. Set a tower to Last to hit them first. | A spot that sees the back of the groups, where Menders trail |
| 4-3 | Use every gate and keep them whole. | Gatecrashers break gates. Guard the gate on their dashed line. | The socket on the dashed line |
| 4-4 | Use at most 3 kinds of tower. | none | none |
| 4-5 | Call 6 waves early. | none | none |
| 4-6 | Lose no lives. | Old Tusk breaks gates fast. Don't count on them to hold. | The spot beside its route |
| 5-1 | Have at most 4 towers. | Creatures in a tunnel are out of reach. Close the tunnel road with a gate. | The socket that closes the tunnel road |
| 5-2 | No tower above tier 2. | Bramble Cottages scratch every walker around them. Build where roads bend. | A spot the road wraps around |
| 5-3 | Have at most 4 towers. | Mossbuds regrow. Big hits beat them. Slows only give them time. | The spot beside the longest stretch |
| 5-4 | Build no Sling Posts. | Mistwisps hide creatures near them. Pop the wisp, or use rings and splash. | A spot the road wraps around |
| 5-5 | Use at most 3 kinds of tower. | none | none |
| 5-6 | Build no Sling Posts. | Burrowbelly digs under, then comes up with Mistwisps. Keep Brambles near. | A spot beside its longest open stretch |
| 6-1 | No tower above tier 2. | At a bridge one road crosses over another. Walkers go straight across. | The socket that sends walkers over the bridge and back under it |
| 6-2 | Have at most 6 towers. | Walkers near a Scarecrow take more damage. Put it where your towers aim. | A spot whose ring covers the road that most spots reach |
| 6-3 | Build no Longbow Lofts. | Every tower aims at a Gleamer. Splash and rings still hit the rest. | A spot beside the road for a Catapult |
| 6-4 | No tower above tier 2. | Sleepyheads nap once and get up. Keep towers further down the road. | A spot further down the road |
| 6-5 | Call 6 waves early. | none | none |
| 6-6 | Lose no lives. | Old Hayrick draws every shot and gets up once. Frighten it with a Scarecrow. | A spot beside its longest stretch |
| 7-1 | Have at most 6 towers. | Ice slides only go the way their arrows point. Watch the line. | The socket that sends walkers around the slide loop |
| 7-2 | Build no Pumpkin Catapults. | Snow Forts roll snowballs in a line. Build them at the end of a straight road. | A spot at the end of a long straight road |
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

Star 2 on every level: "Keep 15 lives."

Region 1's star 3 rules were set with the bots (TUNING_R1.md): a rule that limits spending is what stops one tower type from earning all three stars. Level 1-6 no longer asks for early calls, which level 2-1 teaches.

Region 2 keeps five of its six rules (TUNING_R2.md). They hold because 2-1, 2-4 and 2-5 bring a dense crowd early (12.5), 2-3 brings a few Flitters, so a tower that cannot hit flyers can never keep 15 lives there (12.6), and Ironshell's shell stops pebbles (6.3). Level 2-2 now asks for no gates: on its short road only Bells and splash keep up, and a lone Sling Post never wins there.

Region 3's third stars were set with the campaign pass (TUNING_CAMPAIGN.md). Under the old rules of 3-1 and 3-6 (Lose no lives), 3-2 (Have at most 6 towers) and 3-3 (Use at most 2 gates), a lone Sling Post with Bells earned all three stars: those rules take away nothing it needs, and the early waves bring no crowd before the gold (12.5). On the three levels about flyers (3-1, 3-4 and 3-6), the third star now asks the player to stop every flyer with Fireworks, so it bans the Sling Post. On 3-2 and 3-5 it caps towers at tier 2. On 3-3 it allows 5 towers, so the three gates must make the road long.

Regions 5 to 8's third stars are starting targets from docs/design/EXPANSION.md 6.4. Most limit spending, which 12.5 found is what makes the mix matter. No two levels in a row share a rule, and no level's Twist repeats its star 3. On 7-3, "Use no gates." asks the player to win on the short road near the entrance, because a long road feeds Snowrollers. On 8-2, "Build no Sling Posts." asks for the region's new answer, Moth Lanterns or Fireworks with ground towers under the flight line, as region 3's flyer levels do. On 8-4, "Build no Lullaby Bells." points away from Bells, which do nothing near a Hootling. On 6-6 and 8-6, "Lose no lives." may hold, because these boss levels bring flyers and a boss that needs several kinds of tower. If the bots find one tower type earning all three stars there, the fallback is "Have at most 8 towers."

Region 5's third stars after its balance pass (2026-10-29, docs/design/TUNING_R5.md). Under the starting rules a lone Sling Post with Bells earned all three stars on 5-1, 5-3, 5-4 and 5-6. Levels 5-1 and 5-3 now allow 4 towers and 5-6 allows 6. Under those limits, searches that may use every tower found three-star wins, and two searches of 6000 builds each found none for a lone Sling Post. On 5-4 only a ban held. With at most 5 towers, with at most 4 (once the stronger Bramble Cottage made 4 towers enough for anyone), with at most 1 gate and with no gates at all, a lone Sling Post still earned all three stars: a Mistwisp is never hidden itself, so pebbles pop it, and Bells give them time. A tier 2 cap left no three-star win for anyone. So 5-4 bans the Sling Post, which is its lesson as a challenge: mist stops aim, so rings, lines and splash carry the level. Its Twist banned the Sling Post too, so the Twist is now No Gates (13). Region 5's rules are now a tower limit, a tier cap, a tower limit, a ban, a kinds limit and a tower limit. No two levels in a row share a rule, and no third star repeats its level's Twist.

Region 6's third stars after the level designer's first searches (2026-10-28). Against a lone Sling Post with Bells, a late Pip crowd (12.5) and "No tower above tier 2." work as a pair: the crowd is too much for tier 2 pebbles, and the cap keeps Quickshots out. Level 6-1 had the crowds, at strength 190 and 200, with "Use at most 1 gate." as its third star. One search of 6000 builds found 966 lone Sling Post builds there with all three stars, with Quickshots and Bells. The same search, with the same seed, under "No tower above tier 2." found none: every win it found needed a tower above tier 2. The plain mixed recipe buys no tier 3 path there and keeps 17 lives with its best gate, so all three stars stay in reach. So 6-1 now caps towers at tier 2. Level 6-4 already has the cap but no late crowd: its Pip waves stay at 125 or less, and a lone Sling Post at tier 2 keeps all 20 lives there. So 6-4 keeps its third star, and the region 6 tuning gives its waves a late crowd. If a lone Sling Post still earns all three stars there after that, the tuning sets a new third star. The two levels are not neighbors, so they may share the rule.

Regions 6 and 7 after their balance pass (2026-10-29, docs/design/TUNING_R67.md). The pass found two levels where a lone Sling Post with Bells and Scarecrows earned all three stars: 6-4 under "No tower above tier 2.", whose Pip waves were at 125 or less, and 7-4 under "Have at most 7 towers.", where five tier 3 Sling Posts with a Hush Bell and a Scarecrow kept all 20 lives through crowds in waves 7 and 11. Both keep their third stars and get a late crowd in wave 5 (12.5): 56 Pips at strength 160, all from one entrance on 6-4 and 28 from each entrance on 7-4. Two lone Sling Post searches on each level then found no three-star win, and on 7-4 no win at all. Searches with every tower found 1215 three-star builds in 3000 on 6-4 and 1097 on 7-4, and the plain mixed recipe kept its best result on both. Every other third star of regions 6 and 7 held.

Regions 5 and 8 after their balance pass (2026-10-30, docs/design/TUNING_R8.md). On 5-6, under "Have at most 6 towers.", one of two lone Sling Post searches of 6000 builds found 650 builds with all three stars: six towers leave room for a line of Sling Posts with Bells and a Bakery. No tighter rule of that kind could be met at all: with at most 5 towers, at most 4, or no tower above tier 2, searches that may use every tower found no three-star win, and at 5 none in two more searches of 6000 builds. So 5-6 bans the Sling Post, as 5-4 does, with 5-5 between them. A search without it found 1130 three-star builds in 3000, 1127 of them with a Bramble Cottage, as the hint says. Region 5's rules are now a tower limit, a tier cap, a tower limit, a ban, a kinds limit and a ban. On 8-6 a lone Sling Post earned all three stars under "Lose no lives." too, 323 builds on one seed of two, because Glimmertoad at strength 50 never needed anything more. The rule stays, and the boss wave now comes at 55 (12.3): two lone Sling Post searches then won nothing in 2500 builds each, and a search with every tower found 1007 three-star builds in 3000. Every other third star of regions 5 and 8 held.

The final pass (2026-10-30, docs/design/TUNING_FINAL.md). On 3-5, under "No tower above tier 2.", one lone Sling Post search of four found 59 builds with all three stars in 6000: nine tier 2 Sling Posts that kept exactly 15 lives, every life lost to the 32 Pips of the last wave. A tower limit let the lone build earn the star far more often, "Upgrade no towers." left no three-star win for any search, and "Build no Sling Posts." would give 3-4, 3-5 and 3-6 one rule. So the third star stays, and the last wave brings 33 Pips. At strength 120 a Pip takes four tier 2 pebbles, while a tier 2 Catapult's splash takes the whole crowd. With one more Pip the lone builds kept 13 lives, and lone Sling Post searches on the seed that found them and on two new seeds found no three-star win. Searches of 3000 builds with every tower found no three-star build there, as the final pass's first search had found none before the change, and the hunts of 12.6 then found 1731 and 1568 in 6000 builds each. Every other third star held.

### 12.5 Building waves: a guide for the level designer

- A wave is a list of groups. Each group: creature, count, entrance, start time (seconds after the wave starts) and gap (seconds between its creatures). A wave may also set its own strength (6.4).
- A new creature's first wave holds only that creature: 3 to 5 of them. A boss comes only in the final wave. Never two new things in one wave. A new tower is ready at the start of its level.
- A boss group holds one boss, so its gap changes nothing on Normal. Double Trouble doubles the group (13), and then the gap is the time between the two bosses. Boss levels keep a gap of 1.0 s, except 8-6. Glimmertoad hops ahead and no slow holds it, so two that come 1.0 s apart cross the defense together, and every tower aims at the first. The plain mixed recipe then won that Twist at 1 gate placement of 46, and searches won nothing. On 8-6 the gap is 12.0 s: the second Glimmertoad reaches the strongest towers once the first is down or nearly so. A much longer gap would make the Twist no harder than Normal: with Glimmertoad at 55 and a gap of 16 s or more, the plain mixed recipe won the Twist at exactly the gate placements where it won Normal (docs/design/TUNING_R8.md).
- Typical gaps:

| Creature | Gap (s) |
|---|---|
| Scamp | Spread out: 1.3 to 2.0. Packs for splash: 0.2 to 0.3 |
| Pip | 0.1 to 0.3, in crowds |
| Skitter | 0.5 to 1.0 |
| Flitter | 0.3 to 0.5, in flocks |
| Shellback | 1.2 to 2.0 |
| Bubbler | 1.0 to 1.5 |
| Puffball | 1.2 to 2.0 |
| Mender | Spawn it just after the group it should heal |
| Gatecrasher | 3.0 to 6.0 |
| Dusk Moth | 1.5 to 3.0 |
| Mossbud | 1.0 to 1.5 |
| Mistwisp | 2.0 to 4.0, as a group that starts inside another group's time, so the wisps walk among them |
| Gleamer | 2.0 to 4.0, at the front of a group |
| Sleepyhead | 1.0 to 1.5 |
| Snowroller | 0.5 to 1.0 |
| Yawner | 2.0 to 4.0 |
| Blinker | 0.8 to 1.2 |
| Hootling | Spawn it just after the group it should keep awake, like the Mender |

- Difficulty targets. They replace the old guide of wave health against gold on hand, which did not measure difficulty: towers keep firing every wave, so the same ratio gave a free win on one level and a wall on the next.

| Level | A thoughtful player wins on the first try, Normal |
|---|---|
| 1-1 | 95% |
| 1-2 | 90% |
| 1-3 | 85% |
| 1-4 | 85% |
| 1-5 | 75% |
| 1-6 | 70% |

  A thoughtful player reads the hint and the wave preview, builds the towers the waves call for where they see the most road, and upgrades as gold allows. The bots cannot play like that, so they check what they can instead (12.6): the plain mixed recipe must win, and random strategies must rarely earn all three stars. Random strategies pick their tower mix by chance and never buy more than their list, so their win rate is a floor for comparing levels, not a target. Bart's playtest at hard stop B was the real check for region 1. Later regions: aim for about 85% on each region's first level, falling to about 65% on its boss level.
- Giving each tower its job. Spread-out Scamps, and tougher Scamps from waves at strength 140 to 180 spaced 1.6 to 2.0 s, are the Sling Post's job: they walk farther apart than a pumpkin splashes. Packs of Scamps and Pip crowds are the Catapult's job. Flitters need Sling Posts. A Pip crowd and a Flitter flock arriving together is the hardest moment for one tower type alone.
- A crowd before the gold. From region 2 on, tier 3 paths and Bells let one tower type buy its way through almost any wave once it has the gold. It cannot do that early, while gold is short. A dense crowd by wave 5 uses that: 36 to 40 Pips 0.05 s apart, at strength 115 or less (30 was not enough on 2-5). Levels 2-1, 2-4 and 2-5 have one, and on each it took a lone Sling Post's best under the level's third star from 19 or 20 lives down to 9 to 13, while mixed builds still keep all 20 (TUNING_R2.md). A crowd after wave 6 does not do it: by then the gold is there.
- Pip health and splash. A Pip at strength 115 or less has 24 health or less, so one pumpkin from a tier 2 Catapult or a Jam Pot pops it. At strength 120 to 230 it takes two of those, and one from a Prize Pumpkin. Keep a Pip wave at 115 or less when tier 2 Catapults should clear it.
- A late crowd. From region 3 on, the starting gold buys a lot before wave 1, so a crowd before the gold bites less, and a crowd at 115 or less after wave 6 never did. A stronger late crowd still bites: 30 to 64 Pips 0.05 s apart at strength 160 to 210, in one or two waves from wave 5 on. Such a Pip has 34 to 44 health. One Prize Pumpkin or Big Snowball pops it, and so do two pumpkins from a tier 2 Catapult or a Jam Pot, but a tier 2 Sling Post or a Quickshot needs 5 or 6 pebbles. Levels 3-3, 4-3 to 4-6, most of region 6 and 7-4 have one, and any level of regions 3 to 8 may. The wave's strength raises every creature in it, so give the crowd light company, such as Flitters, Skitters or two Gatecrashers, and keep the wave at 80 creatures or fewer. On 6-1, with "No tower above tier 2.", a search found no win for a lone Sling Post with Bells that kept to the cap (12.4). Wave 5 is the strongest place for it, because the gold for tier 3 paths is not there yet. On 6-4 and 7-4 a wave 5 crowd of 56 Pips at strength 160 stopped a lone Sling Post. On 7-4, crowds in waves 7 and 11, at strength 165 and 200, had not. A stronger wave also pays more gold, so the plain mixed recipe kept its best result on both (docs/design/TUNING_R67.md).
- A short road favors splash. Single-target towers need time to work through a crowd, so they need a long road. Splash and slows need a crowd that is packed, not time, so they hold a short road too. This is why "Use no gates" asks for a mix on 2-2.
- Third stars that bite. A star 3 rule that limits spending (Upgrade no towers, No tower above tier 2, Have at most N towers) makes the mix matter. In region 1, rules that limit nothing about towers (Call N waves early, Lose no lives) did not stop one tower type from earning all three stars: it bought its way through. Use no gates works on 1-6 only because its late waves are hard, and on 2-2 because a short road favors splash. Region 3 showed the same: Lose no lives, Use at most 2 gates and Have at most 6 towers let a lone Sling Post earn all three stars there. A ban on the tower that would do every job also works when another tower can take that job: Build no Sling Posts on the flyer levels, where Fireworks take the flyers. Region 5 showed that hiding does not stop pebbles: on 5-4 a lone Sling Post with Bells earned all three stars even with no gates, because a Mistwisp is never hidden itself and the Bells give the pebbles time. A ban held there, and on 5-6 too, where six towers still left room for a line of Sling Posts. On a boss level, Lose no lives holds only while the boss itself needs more than one kind of tower: on 8-6 it held once Glimmertoad was too strong for pebbles alone (12.4).
- Largest wave: one wave spawns at most 120 creatures, counting 3 Puffs for every Puffball, with the level's Twist applied. Boss summons depend on how long the boss lives, so the bots report the real peak. At most 2 waves run at once (4.9). That is the contract's performance ceiling. Aim for 80 or fewer per wave so the screen stays readable.
- Hootlings and Mistwisps, from region 5 on and in run packs. Count them as the 120 bound counts creatures: with the level's Twist, or in a run with any one risk card, and without boss summons. A wave brings at most 6 Hootlings, so the wake checks stay cheap, and at most 6 Mistwisps, so the mist marks stay readable (docs/art/EXPANSION_LOOK.md 6). Measure the most crowded new wave on the phone before release (contract 9.4).
- Groups per wave. The folded preview strip is one line (9.1), with room for about 4 groups on the cover screen. Prefer 4 groups or fewer a wave, so even a folded preview shows the whole wave. This is a guide, not a limit.
- Map height: see 3.1. On a 13 row map the bottom row is scenery only. Ranges are long on a 7-wide map by design: a Longbow Loft in the middle column reaches both side lanes.
- Level length: 5 to 10 minutes at 1x, measured as the sum of the wave phases with no early calls, plus 15 s for each build phase.
- Every level must pass the balance checks in 12.6.

### 12.6 Balance checks

Each balance pass covers every campaign level and every Twist built so far, because tuning can move older levels. The report gives its seeds, so every number can be repeated.

Towers by level, from 12.2. A Twist that bans a tower takes it out.

| Levels | Attacking towers | Support towers |
|---|---|---|
| 1-1 to 2-1 | Sling Post, Pumpkin Catapult | none |
| 2-2 | Sling Post, Pumpkin Catapult | Lullaby Bell |
| 2-3 to 2-6 | Sling Post, Pumpkin Catapult, Longbow Loft | Lullaby Bell |
| 3-1 to 3-6 | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower | Lullaby Bell |
| 4-1 to 5-1 | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower | Lullaby Bell, Bakery |
| 5-2 to 6-1 | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower, Bramble Cottage | Lullaby Bell, Bakery |
| 6-2 to 7-1 | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower, Bramble Cottage | Lullaby Bell, Bakery, Scarecrow |
| 7-2 to 8-1 | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower, Bramble Cottage, Snow Fort | Lullaby Bell, Bakery, Scarecrow |
| 8-2 to 8-6 | Sling Post, Pumpkin Catapult, Longbow Loft, Firework Tower, Bramble Cottage, Snow Fort, Moth Lantern | Lullaby Bell, Bakery, Scarecrow |

**The plain mixed recipe.** It stands in for a thoughtful player on a first try. It builds where the most road is, mixes the attacking towers so every job is covered, adds one of each support tower in a plain place, upgrades everything once before anything twice, and uses the best gates, which the hint points to. It has no randomness:

1. Spot order. Rank the build spots by road seen: the number of road tiles whose centers are within 2.5 tiles of the spot's center, not counting tunnel tiles. Most first. Ties go in cell order (3.4).
2. Bakery, when the level offers it: on the spot with the most other build spots among its 8 neighbors. Ties go to the spot earlier in the spot order. If no spot has 2 or more neighboring spots, the recipe builds no Bakery.
3. Lullaby Bell, when the level offers it: one Bell, on the third spot in the spot order, or on the fourth if the Bakery has the third. Scarecrow, when the level offers it: one Scarecrow, on the fifth spot in the spot order, or on the sixth if the Bakery has the fifth.
4. Every other spot gets an attacking tower, in spot order, taking the level's attacking towers in turn: Sling Post, Pumpkin Catapult, Longbow Loft, Bramble Cottage, Snow Fort, Firework Tower, Moth Lantern, then the Sling Post again. The Firework Tower and the Moth Lantern are in the turn only on a level whose waves bring flyers: a flying creature, or a boss that flies or releases flyers.
5. Buying. First build every tower in spot order, the Bakery last. Then upgrade every tower to tier 2 in the same order, the Bakery last. From region 2 on, then upgrade every attacking tower to tier 3 in spot order, each on its first path: Quickshot, Prize Pumpkin, Giant Bow, Star Bloom, Wild Bramble, Big Snowball, Beacon Lantern. Bells, Scarecrows and Bakeries stay at tier 2. In region 1 the recipe stops at tier 2, because tier 3 is taught on 1-6.
6. It buys only in build phases, strictly in this order, and waits when the next purchase costs more than the gold on hand. Every tower aims at First. It never calls a wave early, never sells and never moves a gate.
7. Gates. It is played once for every placement of up to the level's number of gates that seals no entrance, the placement with no gates included, with the gates placed before wave 1. Its result is its best placement: a win with the most lives left, or if nothing wins, the loss that clears the most waves. The report also gives the result with no gates and with the worst placement.

In region 1 this is exactly the recipe of the region 1 tuning (TUNING_R1.md): Sling Posts and Catapults in turn, most road first, each upgraded once, with the best gate. On regions 1 to 4 the parts added for regions 5 to 8 change nothing: those levels have no tunnels and no newer towers. The recipe for regions 5 to 8 is a starting point (docs/design/EXPANSION.md 11.2), which the first balance pass of region 5 confirms.

Every campaign level must pass these checks:

| Check | Bar |
|---|---|
| The plain mixed recipe on Normal | Region 1: it keeps 15 lives or more on 1-1 to 1-5, and wins 1-6. Regions 2 to 8: it keeps 15 lives or more on each region's first two levels, and wins the other four. |
| The plain mixed recipe on Relaxed | It wins with no gates placed, and with its best placement. |
| All three stars | A search finds one Normal win that earns all three stars. On a level whose star 3 bans a tower, the search may use only the other towers: a search that may use every tower seldom finds builds that leave one tower out (docs/balance/campaign-2026-10-25.md, F6). On a level whose star 3 is a tower limit, a kinds limit or a tier cap ("Upgrade no towers." or "No tower above tier 2."), a search finds builds inside the limit late, so a first search of 3000 builds that finds none does not decide: up to two more searches of 6000 builds, with different seeds, come before the star is called out of reach, and one three-star win is enough. In the final pass 3-5 (a tier cap), 4-4, 5-3 and 8-5 needed them: their first three-star builds came after 1600 to 4700 builds (docs/balance/final-2026-10-30.md, section 2.3). |
| No super tower | For each attacking tower the level offers, searches that may use only that tower plus the level's support towers find no Normal win with all three stars. Bells, Scarecrows and Bakeries never defeat anything alone, so they need no search of their own. Each attacking tower gets two searches with different seeds, each of at least 6000 builds. If neither of the two has won a single game after 2500 builds, both may stop there. A tower that cannot hit flyers lets every flyer through, so it needs no search on a level whose flyers in the wave data cost 6 lives or more: it can never keep 15 lives there. In the same way the Firework Tower and the Moth Lantern, which cannot hit walkers, need no search on a level whose walkers cost 6 lives or more. The tower that the level's star 3 bans needs no search either: it can never earn star 3. |
| Random play | Random strategies earn all three stars in under 10% of plays. |
| Length | 5 to 10 minutes at 1x (12.5). |
| Size and speed | The report gives the largest wave, the most creatures on the map at once and the time per tick. |

The "No super tower" check is stricter than the brief's words, "no single tower type earns three stars alone". One attacking tower type with Bells, Scarecrows or Bakeries still has one tower doing every job, so it counts as that tower alone.

Why two searches of 6000 builds: a search starts from random builds and edits the best ones, so it can get stuck. On 2-2 a lone Sling Post lost every build of one 2500 build search, a 6000 build search found no three-star win, and another 6000 build search found its first one at build 3872 (docs/balance/region2-2026-10-24.md, F7). A draft of the new 2-5 did the same: its 2500 build search found a best of 14 lives, and a 6000 build search found three-star builds from build 4783 on (TUNING_R2.md). Earlier passes used 2500 builds (TUNING_R1.md: on some levels the first single-tower win turned up after 1000 to 2200).

Every Twist: some strategy wins it on Normal (13). A search of 1500 builds comes first. If it wins nothing, two searches of 6000 builds with different seeds decide, and one win is enough. The 3-2 Twist needed them (docs/balance/campaign-2026-10-25.md, F5).

Across the campaign: every tower type, the Lullaby Bell, the Scarecrow and the Bakery included, is part of some three-star win (brief section 11). The report also counts each tier 3 path in three-star wins. A path that never shows up is a flag for the game designer, not a failed check.

And the same inputs always give the same result.

## 13. Twists

- A level's Twist unlocks when that level has 3 stars.
- A Twist is the same map and the same waves with one rule changed.
- Twists have no stars. A win on either difficulty marks the level's Twist as cleared.
- The bots must confirm every Twist can be won on Normal.
- A Twist that changes creatures changes every creature of every wave: bosses, Puffs and the creatures a boss releases included.
- A Twist that changes how many creatures come changes only the groups in the level's wave data. A Puffball still releases 3 Puffs, and a boss releases its usual batches.
- The level card shows the Twist's name and its card text from the table. The level designer copies both into the level file. Card text is at most 80 characters.

| Level | Twist | The one rule changed | Card text |
|---|---|---|---|
| 1-1 | Thin Purse | Start with half the gold, rounded down to a multiple of 10. | Start with half the gold. |
| 1-2 | Stuck Gate | The level's gate starts placed on a socket the level sets. It cannot be moved or removed, and there is no other gate. | Your gate is stuck on one socket for the whole level. |
| 1-3 | Tier 2 Cap | No tower can go above tier 2. | No tower can go above tier 2. |
| 1-4 | No Catapults | The Pumpkin Catapult cannot be built. | Pumpkin Catapults cannot be built. |
| 1-5 | Twice the Wings | Every group of flyers has twice as many. | Twice as many flyers in every wave. |
| 1-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |
| 2-1 | Hurry | Every creature moves 20% faster. | Every creature moves 20% faster. |
| 2-2 | No Bells | The Lullaby Bell cannot be built. | Lullaby Bells cannot be built. |
| 2-3 | Thick Shells | Every creature has 2 more armor. | Every creature has 2 more armor. |
| 2-4 | No Gates | The level gives 0 gates. | You get no gates. |
| 2-5 | Bubble Night | Every creature carries a bubble. | Every creature carries a bubble that comes back 2 seconds after it pops. |
| 2-6 | Stuck Gates | Both of the level's gates start placed on sockets the level sets. They cannot be moved or removed, and there are no others. | Both gates are stuck on their sockets for the whole level. |
| 3-1 | No Fireworks | The Firework Tower cannot be built. | Firework Towers cannot be built. |
| 3-2 | No Catapults | The Pumpkin Catapult cannot be built. | Pumpkin Catapults cannot be built. |
| 3-3 | One Gate | The level gives 1 gate instead of 3. | You get 1 gate instead of 3. |
| 3-4 | Twice the Wings | Every group of flyers has twice as many. | Twice as many flyers in every wave. |
| 3-5 | Tier 2 Cap | No tower can go above tier 2. | No tower can go above tier 2. |
| 3-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |
| 4-1 | Thin Purse | Start with half the gold, rounded down to a multiple of 10. | Start with half the gold. |
| 4-2 | No Longbows | The Longbow Loft cannot be built. | Longbow Lofts cannot be built. |
| 4-3 | Quick Crashers | Gatecrashers break gates in 2.0 s instead of 4.0 s. | Gatecrashers break gates in 2 seconds instead of 4. |
| 4-4 | No Selling | Towers cannot be sold. | Towers cannot be sold. |
| 4-5 | Five Lives | Start with 5 lives. | Start with 5 lives, or 10 on Relaxed. |
| 4-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |
| 5-1 | One Gate | The level gives 1 gate instead of 2. | You get 1 gate instead of 2. |
| 5-2 | No Catapults | The Pumpkin Catapult cannot be built. | Pumpkin Catapults cannot be built. |
| 5-3 | Tier 2 Cap | No tower can go above tier 2. | No tower can go above tier 2. |
| 5-4 | No Gates | The level gives 0 gates. | You get no gates. |
| 5-5 | Five Lives | Start with 5 lives. | Start with 5 lives, or 10 on Relaxed. |
| 5-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |
| 6-1 | Stuck Gates | Both of the level's gates start placed on sockets the level sets. They cannot be moved or removed, and there are no others. | Both gates are stuck on their sockets for the whole level. |
| 6-2 | No Bells | The Lullaby Bell cannot be built. | Lullaby Bells cannot be built. |
| 6-3 | Twice the Wings | Every group of flyers has twice as many. | Twice as many flyers in every wave. |
| 6-4 | No Selling | Towers cannot be sold. | Towers cannot be sold. |
| 6-5 | Thin Purse | Start with half the gold, rounded down to a multiple of 10. | Start with half the gold. |
| 6-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |
| 7-1 | No Gates | The level gives 0 gates. | You get no gates. |
| 7-2 | No Longbows | The Longbow Loft cannot be built. | Longbow Lofts cannot be built. |
| 7-3 | Hurry | Every creature moves 20% faster. | Every creature moves 20% faster. |
| 7-4 | Thick Shells | Every creature has 2 more armor. | Every creature has 2 more armor. |
| 7-5 | Bubble Night | Every creature carries a bubble. | Every creature carries a bubble that comes back 2 seconds after it pops. |
| 7-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |
| 8-1 | One Gate | The level gives 1 gate instead of 2. | You get 1 gate instead of 2. |
| 8-2 | No Fireworks | The Firework Tower cannot be built. | Firework Towers cannot be built. |
| 8-3 | No Bells | The Lullaby Bell cannot be built. | Lullaby Bells cannot be built. |
| 8-4 | Twice the Wings | Every group of flyers has twice as many. | Twice as many flyers in every wave. |
| 8-5 | Five Lives | Start with 5 lives. | Start with 5 lives, or 10 on Relaxed. |
| 8-6 | Double Trouble | Every group in the final wave has twice as many. Two bosses. | The final wave is twice as big, with two bosses. |

- Level 5-4's Twist was No Sling Posts until the region 5 tuning, when its third star took that ban (12.4). It is now No Gates: with no gates the walkers take the short middle road through both tunnels, under the mist.
- Every Twist of regions 5 to 8 uses a change that regions 1 to 4 already use, so none needs a new effect type (contract 2.8). Each fits its level's lesson and none repeats the level's star 3 (docs/design/EXPANSION.md 8).
- Twice the Wings goes only on levels whose waves bring flyers, so it always changes something. The level designer keeps flyer groups in the waves of 6-3 and 8-4.
- Double Trouble on 5-6 and 8-6: two Burrowbellies summon 4 Mistwisps at a time, and two Glimmertoads release 12 Flitters. On 8-6 the second Glimmertoad comes 12.0 s after the first, as the gap of the level's boss group sets (12.5).
- Bubble Night: every creature starts with a bubble that works exactly like a Bubbler's (6.2). It blocks one whole hit, and it comes back 2.0 s after it pops, every time. So on this Twist every slow hitter needs a quick partner to pop bubbles for it. A Bubbler is unchanged.

## 14. Roguelite mode

### 14.1 Run shape

| Item | Value |
|---|---|
| Waves | 18. Wave 18 is a boss wave. |
| Length | About 12 to 16 minutes at 1x, about 15 to 20 of real play with card picks (Bart, 2026-10-25). Minutes at 1x are counted as for levels (12.5). |
| Strength of wave w | Waves 1 to 17: 100 + 10 times (w minus 1). Wave 1 is 100, wave 17 is 260. Wave 18, the boss wave, has the strength its boss pack sets (14.3). |
| Starting gold | 300 on Normal, 450 on Relaxed. |
| Starting lives | 20 on Normal, 40 on Relaxed. Lives never rise above the starting lives (4.4). |
| Starting towers | The Sling Post only. Other towers come from cards. |
| Content | The towers, creatures, bosses and maps of the run's content tier and those below it (14.9). Tier 0 is everything of regions 1 to 4. |
| Gates | 1 at the start, up to 3 from cards. |
| Cards | One draft after each of waves 1 to 17. |
| End | The run is won like a level (4.1): when wave 18 has started and no wave is still running, with lives above 0. Clearing wave 18 is not enough while an older wave is still on the map. It is lost when lives reach 0. A boss that gets through costs 20 lives, so on Normal the boss must be beaten (6.3). |

All core rules (4 to 9) apply in runs: phases, pause, speeds, early calls, selling, gates, the route line and the wave preview.

### 14.2 Maps from segments

- A run map is 7 columns by 13 rows, made of three hand-built segments stacked: a top segment of 4 rows, a middle segment of 5 rows and a bottom segment of 4 rows. The middle one gets the extra row because it holds the forks.
- The last row of every bottom segment is scenery only, because it is the bottom row of a 13 row map (3.1). The base and everything else in a bottom segment sit in its first 3 rows.
- Top segments hold 1 or 2 entrances, on the top edge or the side edges of that segment. Middle segments hold forks and gate sockets. Bottom segments hold the base. Any segment may have build spots and sockets.
- The columns where a segment's road crosses its top row and its bottom row are its ports, read from its grid. On those rows no two road tiles sit side by side. Two segments join only if the bottom ports of the upper one are exactly the top ports of the lower one.
- The run's seed picks a top segment, then a middle segment that joins it, then a bottom segment that joins that. Each pick is even among the eligible segments that fit (14.9).
- Every way of joining a top, a middle and a bottom segment that fit must give a valid map: 11 or 12 build spots, 2 to 5 gate sockets, and the same checks as a campaign map. Every top segment has at least one middle that fits under it, and every such middle has at least one bottom.
- Every such map has a Bakery spot: a build spot with at least 3 other build spots among its eight neighbors, so a Bakery there reaches 3 towers (5.8).
- Lanes that run side by side all the way to the base, where a gate can only move the creatures from one lane to the other, make walls (docs/design/TUNING_RUNS.md 1.5). Where a middle segment carries two lanes, join them, so the run's first gate can make a detour.
- Map features (3.5). Each of regions 5 to 8 adds two or three middle segments with its feature, using the ports of the other segments, so every top and bottom still fits. A segment holds at most one feature, in its middle three rows, and its top and bottom rows stay plain road. A segment is eligible only when its tier is at most the run's tier (14.9).
- Every stack, at every tier, still meets the rules above: 11 or 12 spots, 2 to 5 sockets and the Bakery spot. No tunnel tile is next to a socket on any stack, across the seams between segments too (3.6).
- The ground of a run map. A run map takes the ground of the region whose feature it holds: Hollow Lanes for tunnels, Russet Orchards for bridges, Frostpine Ridge for ice slides, Starglen for hollow stumps. A map with no feature keeps Lantern Hill's meadow. Only middles hold features, one at most, so a map never has two. This is art only.
- The level designer builds the segments. Tests check every way they can join, at every tier.

### 14.3 Waves in a run

- Run waves come from hand-built wave packs. A pack is 3 waves in a row.
- The 18 waves are 6 bands of 3. For each band the seed picks one pack from that band's eligible packs (14.9). Each band has at least 4 packs of tier 0, so a tier 0 run keeps the packs of regions 1 to 4.

| Band | Waves | Creatures its packs may use, on top of earlier bands | Added by tiers 1 to 4 (14.9) |
|---|---|---|---|
| 1 | 1 to 3 | Scamp, Pip. Wave 1 is Scamps only. | none |
| 2 | 4 to 6 | Skitter, Flitter, Shellback | Mossbud (tier 1), Sleepyhead (tier 2), both first in band 3 packs (below) |
| 3 | 7 to 9 | Bubbler, Puffball | Gleamer (tier 2), Snowroller (tier 3), Blinker (tier 4) |
| 4 | 10 to 12 | Mender, Dusk Moth | Mistwisp (tier 1), Yawner (tier 3) |
| 5 | 13 to 15 | Gatecrasher | Hootling (tier 4) |
| 6 | 16 to 18 | All. Wave 18 is a boss with its escort. | The bosses of tiers 1 to 4 |

- The seed picks the run's boss from the eligible bosses: the four of regions 1 to 4, and one more for each tier the run has (14.9). Band 6 uses a pack made for that boss.
- Each of regions 5 to 8 adds packs that use its creatures: at least one in each band from the first band where a pack can show one of its creatures as new up to band 5, plus two band 6 packs for its boss. That first band is band 3 for every region. A band 2 pack has no room, because its three waves already show Skitter, Flitter and Shellback as new and no wave shows two creatures as new (below). So the Mossbud and the Sleepyhead, which the table lists in band 2, first come in band 3 packs. Tier 1's packs start in band 3, and so do those of tiers 2 to 4.
- Each band 6 pack sets the strength of its third wave, the boss wave, as a campaign boss wave does (12.3). Every other pack wave takes the strength of 14.1. The level designer tunes each boss wave to the target in 14.8. Starting values:

| Band 6 pack | Boss | Boss wave strength | Boss health |
|---|---|---|---|
| `b6_grumble_hill` | Grumblesack | 290 | 5800 |
| `b6_grumble_march` | Grumblesack | 270 | 5400 |
| `b6_iron_road` | Ironshell | 150 | 3750 |
| `b6_iron_gate` | Ironshell | 150 | 3750 |
| `b6_moon_rise` | Moon Moth | 150 | 2400 |
| `b6_moon_tide` | Moon Moth | 140 | 2240 |
| `b6_tusk_charge` | Old Tusk | 200 | 6000 |
| `b6_tusk_night` | Old Tusk | 180 | 5400 |
| `b6_burrow_deep` | Burrowbelly | 120 | 3840 |
| `b6_burrow_mist` | Burrowbelly | 140 | 4480 |
| `b6_hayrick_field` | Old Hayrick | 175 | 4550, then 2275 after its nap |
| `b6_hayrick_barn` | Old Hayrick | 165 | 4290, then 2145 after its nap |
| `b6_snore_ridge` | Snowsnore | 110 | 3740, growing to 5610 |
| `b6_snore_drift` | Snowsnore | 100 | 3400, growing to 5100 |
| `b6_toad_glen` | Glimmertoad | 50 | 1800 |
| `b6_toad_hollow` | Glimmertoad | 50 | 1800 |

- Every boss of the game now has its band 6 packs in this table. Glimmertoad's two joined in the region 8 tuning at 50, the lowest strength a band 6 pack may set, down from 80 and 70 (docs/design/TUNING_R8.md). The final pass read them again with the tower cards of tier 4 settled, and both stay at 50: on the second reading of 14.8, 75.4% and 67.6% of the runs that start wave 18 win, the first at the ceiling within noise (docs/design/TUNING_FINAL.md).
- Packs name entrance A or B. On a map with one entrance, B means A.
- A creature a run has not shown yet comes in its own group, first in its wave, and no group of that wave starts before it. No wave brings two such creatures. Risk cards are the only exception, and their card says what they add.
- Creatures of tiers 1 to 4 in packs. Every pack shows each tier 1 to 4 creature it uses as if it were new. That creature comes in the first group of the first wave of the pack that has it, no group of that wave starts before it, and a wave shows at most one such creature. The rule above for creatures the run has not shown yet still holds, and no wave shows two creatures as new, counting both kinds. Tests check every choice of packs at every tier. Why: the player has met these creatures in the campaign, but a run can bring them in any band, so each pack brings them in gently, at the front, where the player sees them first.
- Room for them. Every pack of bands 1 to 5 shows the tier 0 creatures its band adds as new, one a wave. So a band 3 or band 4 pack has one wave left and uses at most one tier creature. A band 5 pack has two waves left, and a band 6 pack the two before its boss wave. Region 6's band 3 and band 4 packs each use the Gleamer or the Sleepyhead, not both. Region 7's band 3 packs can use only the Snowroller, since the Yawner joins in band 4, and its band 4 packs use the Yawner or the Snowroller, not both. Region 8's band 3 and band 4 packs can use only the Blinker, since the Hootling joins in band 5.
- Yawners come a few to a wave, in band 4 or later: every run map has a Bakery spot with 3 neighbors (14.2), exactly what a Yawner punishes.
- No pack has a group of Puffs. Puffs only come from Puffballs.
- Every pack wave stays within the 120 creature bound of 12.5, counting 3 Puffs for every Puffball, with no risk card and with any one risk card applied. The boss wave never gets a risk card (14.4).
- Health, heals, bounties and clear bonuses follow the wave's strength.
- The level designer builds the packs, like levels.

### 14.4 The card draft

- After each of waves 1 to 17 is cleared, the player picks 1 card from 3. The draft opens in the next build phase.
- If waves were called early, the drafts wait and come one after another, in wave order, at the next build phase. The next wave cannot start until every waiting draft is picked. A draft cannot be skipped.
- That holds for early calls too. A wave cleared while another wave is still on the map owes its draft at once, and from then on the next wave cannot be called until the build phase, where the waiting drafts are picked first. Tapping the call button meanwhile says "Pick your card after this wave." In a build phase with a draft waiting, it says "Pick a card first."
- A draft opens only in a build phase. If wave 18 is called early and wave 17 is cleared after that, no build phase follows, so the draft for wave 17 never opens.
- Card type weights: tower 30, tower perk 25, extra gate 10, economy 20, risk 15.
- Drawing a draft: for each of the 3 slots, pick a type by weight among the types that still have an eligible card, then pick a card of that type evenly. No card appears twice in one draft. If fewer than 3 cards are eligible, the draft offers fewer.
- While the run has fewer than 3 kinds of tower, the first slot is always a tower card, if one is eligible.
- Eligible cards:
  - A card only when its tier is at most the run's tier (14.9).
  - A tower card only for a tower not yet in the run.
  - A tower perk only for a tower in the run.
  - An unlocked tower perk (14.6) only while no base tower perk (14.5), of any tier, is eligible. So until every tower in the run holds its base perk, perk slots offer only base perks, exactly as with no unlocks. A new tower card brings its tower's base perk into the drafts, and the unlocked perks wait again until it is taken.
  - A card marked once is gone after it is taken.
  - An extra gate only while the run has fewer than 3 gates, placed and in hand together, and fewer gates than the map has sockets.
  - At most one risk card per draft. None while another risk card is waiting. None once wave 17 has started, so the boss wave is never changed. That covers the draft after wave 17, and also the draft after wave 16 when wave 17 was called early, because that draft opens only after wave 17 has started.
- A risk card changes the next wave that starts. Its reward is paid with that wave's clear bonus (14.5).
- Each draft uses its own random generator, seeded from the run seed and the wave number. Earlier picks never change which random numbers later drafts get. The architect sets how the seed is mixed.

### 14.5 Base cards

Every player has these from the start. The cards of the towers of regions 5 to 8 join a run only once their tier is in it (14.9). Gold rewards on risk cards are base numbers, scaled by the strength of the wave they change and rounded half up.

Tower cards (5, and 4 more by tier). Each adds one tower to the run: Pumpkin Catapult, Lullaby Bell, Longbow Loft, Firework Tower, Bakery. From tier 1 on the Bramble Cottage, from tier 2 the Scarecrow, from tier 3 the Snow Fort and from tier 4 the Moth Lantern.

Tower perks (6, and 4 more by tier). Each is once per run.

| Card | Tower | Effect |
|---|---|---|
| Sharp Pebbles | Sling Post | Deals 1 more damage per hit. |
| Wide Splash | Pumpkin Catapult | Splash radius is 0.25 tiles bigger. |
| Deep Lullaby | Lullaby Bell | Slows are 10 points stronger. 35% becomes 45%. |
| Steady Aim | Longbow Loft | Reload times are 20% shorter. 2.5 s becomes 2.0 s. |
| Bigger Bangs | Firework Tower | Deals 5 more damage per hit. |
| Warm Ovens | Bakery | Reaches 2.5 tiles instead of 1.5. |
| Thorn Tips | Bramble Cottage | Deals 2 more damage per hit. |
| Big Hat | Scarecrow | Its ring reaches 0.5 tiles further. |
| Packed Snow | Snow Fort | Deals 6 more damage per hit. |
| Bright Wick | Moth Lantern | Reaches 1 tile further. |

The last four are base perks of their tower's tier, not unlockable perks. Once their tier is in the run, 14.4 treats them exactly as the other base perks, so an unlocked perk waits until no base perk, old or new, is eligible.

Extra gate (1).

| Card | Effect | Taken |
|---|---|---|
| Spare Gate | Gain 1 gate, up to 3. | Again and again |

Economy (5).

| Card | Effect | Taken |
|---|---|---|
| Gold Purse | Gain 100 gold plus 10 for each wave cleared so far. | Again and again |
| Fat Bounties | Creatures give 20% more gold for the rest of the run, rounded half up. The early call bonus counts the bigger bounties. | Once |
| Feast Days | Wave clear bonuses are 50% bigger for the rest of the run, rounded half up. Risk card rewards stay the same. | Once |
| Fair Trade | Selling refunds 90% instead of 70% for the rest of the run. | Once |
| Tea Break | Gain 5 lives, but never more than the starting lives (4.4). Card text: "Gain 5 lives, but never more than you started with." | Again and again |

Risk (5). Each changes the next wave only.

| Card | Next wave | Reward |
|---|---|---|
| Crowded Night | Every group has 50% more creatures, rounded up. | 100 gold |
| Thick Hides | Creatures have 50% more health, rounded half up. | 120 gold |
| Hurry Night | Creatures move 50% faster. | 60 gold |
| Gateless Night | Your gates stand open. They block nothing and cannot be broken. | 60 gold |
| Flock | 8 extra Flitters come from entrance A, 0.4 s apart, starting 2.0 s after the last of the wave's own groups starts. | 80 gold |

- A risk card's reward is paid together with its wave's clear bonus, when that wave is cleared. If the run ends before that, nothing is paid.
- A risk card's changes reach every creature of its wave, the Puffs of that wave included.
- A change to how many creatures come (Crowded Night) changes only the wave's own groups from its pack. A group a risk card adds always comes with the count its card says, and a Puffball still releases 3 Puffs.
- A group a risk card adds belongs to its wave and comes after the wave's own groups, in the preview too. It comes from entrance A, which every map has.
- Gateless Night opens every gate from the moment its wave starts until the next build phase begins. Gates never close during a wave (7.8), so any other wave on the map in that time, including one called early, finds them open too. Gatecrashers and Old Tusk walk through without stopping. In the build phase before that wave, the route lines already show the roads with every gate open. When the next build phase begins, every gate stands closed again on its socket.

### 14.6 Unlockable cards

- Playing unlocks new cards into the pool. Each one is a sidegrade: it changes how something works and carries a cost, so it adds variety, never raw power. Nothing is bought.
- An unlocked card joins the pool from the next run on. A run's pool is fixed when the run starts and is saved with it.
- The daily challenge always uses every card of its tier, unlocked or not (15).
- The six unlocked tower perks come into a run's drafts only once every tower in the run holds its base perk (14.4). Until then a draft is the same as with no unlocks, so unlocking them never makes the base perks rarer. After that they are a second perk for a tower. The other six unlocked cards join their kinds at once.

| Card | Type | Effect | Unlocked by |
|---|---|---|---|
| Twin Pebbles | Tower perk, Sling Post | Hits 2 targets per shot, but deals 2 less damage per hit. Once. | Reach wave 6 in a run |
| Heavy Pumpkins | Tower perk, Pumpkin Catapult | Deals 10 more damage, but reloads 0.5 s slower. Once. | Reach wave 12 in a run |
| Frost Chime | Tower perk, Lullaby Bell | Also slows flyers, the Moon Moth included, but its range is 0.25 tiles shorter. Once. | Finish a daily challenge, won or lost |
| Volley | Tower perk, Longbow Loft | Hits one more target per shot, but each arrow deals 15% less damage, rounded half up. Once. | Win a run |
| Long Fuse | Tower perk, Firework Tower | Reaches 1 tile further, but reloads 0.25 s slower. Once. | Win a run on Normal |
| Spice Rack | Tower perk, Bakery | Also adds 2 damage per hit to the towers it reaches, but its speed boost is 10 points smaller. 25% becomes 15%. Once. | Earn 24 stars |
| Piggy Bank | Economy | When each build phase begins, after the clear bonus is paid, gain 10% of the gold you hold, rounded down, up to 50. Once. | Earn 36 stars |
| Bargain | Economy | New towers cost 20 more. Upgrades cost 20 less. Once. | Earn 48 stars |
| Iron Gate | Extra gate | Gain 2 gates, up to 3. When a wave starts, placed gates lock for good. Once. | Clear any Twist |
| Moonlit Wager | Risk | Next wave: creatures have twice the health. Reward: 250 gold. | Earn 60 stars |
| Crasher Escort | Risk | Next wave: 2 Gatecrashers join from entrance A at the wave's start, 3.0 s apart. Reward: 150 gold. | Win a run after taking 3 or more risk cards in it |
| Pip Parade | Risk | Next wave: a crowd of 16 Pips joins from entrance A, 0.3 s apart, starting 1.0 s after the wave starts. Reward: 120 gold. | Earn 72 stars |

- Daily runs count as runs for these conditions.
- Frost Chime changes every tier and path of the Lullaby Bell, like every tower perk. Its Bells slow every flyer in their ring, the Moon Moth included (6.3), so a Hush Bell with Frost Chime slows the Moon Moth by 60%. A Night Bell already slows flyers, so for it the card only shortens the ring.
- Unlock progress is kept in these counters: `best_run_wave` (the highest wave number started in any run or daily; it only goes up), `runs_won`, `runs_won_normal`, `dailies_finished` and `risky_wins` (runs won after taking 3 or more risk cards in them). Stars and Twist clears come from the level records (16).
- "Reach wave N" means wave N has started, an early call included. The counters change when a run ends: won, lost or abandoned.
- Card changes to a tower's numbers apply in order: added amounts first, then percents, then Bakery boosts on top (8.7). No card takes a number below its floor: a price of 10, a reload of 0.05 s, damage 1, 1 target, a slow from 1% to 90%, a range above 0, and no boost below 0. Nothing caps them from above, so Volley gives a Triple Bow 4 targets.
- Iron Gate locks nothing at the moment it is taken. In that build phase every gate can still be placed, moved and removed, so a mistaken drop can be fixed. From then on, each time a wave starts, every gate on a socket locks there for the rest of the run and can never be moved or removed again. That includes gates placed before the card was taken. Gates still in the tray stay free until they are placed and a wave starts. A locked gate can still be broken by a Gatecrasher or Old Tusk, and it mends on its socket as usual (7.6).

### 14.7 Leaving, losing and results

- A run can be left at any time and resumed later at the exact moment it was left, from the Continue card or its own mode button (4.10).
- A run ends when lives reach 0, when the player abandons it from Pause after a confirm, or when the player starts a new run of the same mode over it (4.10). An abandoned run counts as a loss at its current wave, and so does a run that was started over.
- A run's result is: won or lost, waves cleared, and lives left.
- Runs carry nothing over except progress toward unlocks (14.6).

### 14.8 Targets for the balance bots

Every run and daily report in docs/balance/ checks these. The bots and their strategies are in docs/balance/README.md. Unless a row says otherwise: Normal, the base cards (no unlocks), the 16 named strategies, run seeds 1 to 200, and every check at tier 0 and again at tier 4 (14.9). Each region's balance pass also checks its own tier, 1 to 3, against the same bars, because a run should be as winnable at every tier. The bots are a floor. They never aim at Strong, sell to rebuild for the boss or read the preview, so a thoughtful player should win more often than the best of them. From tier 2 on they keep two habits a thoughtful player has: they build no Scarecrow before 9 waves have started, as they already wait for a Bakery, and they keep at least 55% of their attacking towers able to hit flyers, about the share they keep at tier 0 (docs/design/TUNING_R67.md).

Reading the bars from tier 2 on. From tier 2 on, the bars on how often runs are won and lost (Normal, Relaxed, the boss, fair maps and fair packs) are read on the second reading: the same seeds with the tower cards of tiers 2 to 4 (Scarecrow, Snow Fort, Moth Lantern) and their perks (Big Hat, Packed Snow, Bright Wick) out of the pool. Both sides of a bar are read there, its floor and its ceiling. The report gives the first reading, the pool as the player has it, beside each of these bars, as a number and not as a bar. Why: a player can always pass on a tower card, so the second reading is a fair floor for a thoughtful player, and the card experiment below already reports tower cards rather than holding them to its bar. The final pass measured the gap (docs/balance/final-2026-10-30.md, section 3). On the first reading the 16 together won 30.0%, 28.4% and 24.8% at tiers 2, 3 and 4, and the best strategy 50.0%, 39.5% and 36.5%. On the second they won 38.8%, 41.9% and 44.4%, and the best strategy 56.5%, 56.0% and 59.5%. The cost is spread over the three cards, so no one card can be tuned to remove it: at tier 4, taking any one of them out with its perk gives back 4.5 to 4.9 of the 19.6 points, and any one alone in the pool costs 7.8 to 11.0. The other rows keep the pool as the player has it: a seed can be won when some strategy wins it with the cards it is offered, and the rows on unlocks, card values, risk cards, length and same seeds measure the game as it is played. So do the daily's bars (15), with every card of its tier. If the second reading misses a bar, the content the tier adds is tuned: its packs, its boss's packs or its segments. A pack or segment of an earlier tier that meets its bar at its own tier is reported at later tiers, not tuned there: tier 0's can never change (14.9), and what changed is the bots' towers, not the pack. Tier 1 has no second reading: its tower, the Bramble Cottage, was tuned for runs on these bars (docs/design/TUNING_R5.md).

| Check | Bar |
|---|---|
| Every run can be won | On every run seed from 1 to 50, one of the 16 named strategies or one of up to 100 random strategies wins. |
| Normal | The best named strategy wins 55% to 75% of its runs. The 16 together win 35% to 55%. |
| Relaxed | The best named strategy wins at least 90%. The 16 together win at least 80%. |
| Every card unlocked | On Normal and on Relaxed, the 16 together win within 5 points of the same seeds with no unlocks, higher or lower. Unlocks add variety (14.6): they should neither help nor hurt. |
| The boss | For each band 6 pack, 50% to 75% of the named strategies' runs that start wave 18 win. |
| Fair maps | For each segment, runs on maps that use it win at least 75% as often as all runs. No stack that 4 or more seeds use loses more than 10% of its plays by wave 6. |
| Fair packs | No pack of bands 1 to 5 loses more than 10% of the runs that reach its first wave. |
| No card decides a run | In the card experiment (each offered card taken in turn, then the run played on), no perk, gate, economy or risk card raises the win rate by more than 5 points. Tower cards are reported, not held to it: what a new tower is worth to the bots depends mostly on where their build rule puts it. |
| Risk cards trade fairly | In the risk replay of waves 2 to 8 (each risk card played on the same wave, with the same towers), every risk card's extra gold for each extra life lost lies between half and twice the middle value of the risk cards. Gateless Night is reported, not held to it: the bots' gate rule is too simple to price it. |
| Length | Won runs average about 12 to 16 minutes at 1x, counted as for levels (12.5). |
| Same seed, same run | The same seed, tier and picks always play the same, also across a save and load in the middle of a wave or with a draft open. A tier 0 run plays exactly as it did before regions 5 to 8 joined (14.9). |

### 14.9 Content tiers

The towers, creatures, bosses and map features of regions 5 to 8 join runs and the daily once the player has met them in the campaign, one region at a time (Bart, 2026-10-27).

- A region's content joins when its boss level is cleared, on Normal or Relaxed.
- The player's tier is the number of these boss levels cleared, 0 to 4. It comes from the level records, so nothing new is saved for it.

| Tier | Boss level cleared | Towers | Creatures | Bosses | Map feature |
|---|---|---|---|---|---|
| 0 | none | The six of regions 1 to 4 | Every creature of regions 1 to 4 | Grumblesack, Ironshell, Moon Moth, Old Tusk | none |
| 1 | 5-6 | Bramble Cottage | Mossbud, Mistwisp | Burrowbelly | Tunnels |
| 2 | 6-6 | Scarecrow | Gleamer, Sleepyhead | Old Hayrick | Bridges |
| 3 | 7-6 | Snow Fort | Snowroller, Yawner | Snowsnore | Ice slides |
| 4 | 8-6 | Moth Lantern | Blinker, Hootling | Glimmertoad | Hollow stumps |

- Everything else takes its tier from this table. A card's tier is its tower's tier, and a card with no tower is tier 0. A pack's tier is the highest tier among its creatures and its boss, counting the creatures they summon, split into or release. A segment's tier is the highest tier of the map features it holds. Anything not in the table is tier 0.
- A run uses only things whose tier is at most the run's tier: cards (14.4, 14.5), segments (14.2), packs and bosses (14.3).
- A normal run's tier is the player's tier when it starts. The run keeps that tier to its end, saved with the run. The daily's tier is set by 15.
- A tier 0 run is exactly the run of regions 1 to 4. Things of tiers 1 to 4 are left out of every list before any pick, and the picks walk the lists in file order, as they always have (contract 3.4). So the same seed gives the same boss, map, packs, waves and offers as before regions 5 to 8 joined, and a tier 0 daily is the same daily as before on every date. Tests pin this.
- Why per region and not per level: packs and segments are hand-built, and each mixes several new things. Joining per level would give the bots 21 states to check instead of 5. A player who has met a tower in the campaign waits at most four levels to see it in runs.

## 15. Daily challenge

- One run per calendar day, built exactly like a roguelite run (14), with these differences:
  - Seed: the phone's local date as the number YYYYMMDD, for example 20261023. The same date and the same tier give the same run on every phone with the same app version. No network.
  - Always Normal.
  - Uses every card of its tier (14.9), unlocked or not, so every player at that tier draws from the same pool.
  - Opens together with the roguelite mode (16).
- Its tier (Bart chose this on 2026-10-27). The daily uses only things whose tier is at most its tier (14.9), so every player at the same stage shares the same daily.
  - The daily's tier is the player's tier when they start that day's first daily. It holds for the whole day: the day's record keeps it with the day's best, and a daily in progress keeps it in its save. A tier earned later that day joins tomorrow's daily, so the day's best always compares the same run.
  - A tier 0 daily is exactly the daily of regions 1 to 4 for that date (14.9).
  - The Daily button names the regions the daily covers, for example "Regions 1 to 6", so two friends can see why their runs differ.
- The player may try as often as they like. Each finished try is compared with the day's best.
- Best result: a win beats a loss. Between wins, more lives left is better. Between losses, more waves cleared is better. A tie keeps the earlier result.
- A daily run belongs to the date it started, even if it ends after midnight.
- If the phone's date is before 2026 or after 2200, the Daily button says "Check the phone's date." and starts no new daily. A saved daily still resumes.
- Streak. The phone keeps a streak count and the last date it counted.
  - When a daily run ends (won, lost or abandoned), look at the date it belongs to.
  - If that date is the day after the last counted date, the streak grows by 1.
  - If it is the last counted date itself, or an earlier date, nothing changes. This covers a phone whose date moved backward.
  - Otherwise the streak starts again at 1.
  - The screen shows the streak while the last counted date is today or yesterday, and 0 after that.
- The day's best result and the streak are saved on the phone only.
- The bots check the daily over the 400 days after each report (14.8), at each of the five tiers: at least 98% of the days are won by one of the 16 named strategies or by one of up to 400 random strategies, no two days in a row go unwon, and the named strategies alone win at least 60% of the days.

## 16. Progression

| Unlock | Needs |
|---|---|
| Region 1, level 1-1 | Nothing. Open from the start. |
| The next level in a region | Clearing the level before it. |
| Region 2 | Level 1-6 cleared and 6 stars. |
| Region 3 | Level 2-6 cleared and 12 stars. |
| Region 4 | Level 3-6 cleared and 18 stars. |
| Region 5 | Level 4-6 cleared and 24 stars. |
| Region 6 | Level 5-6 cleared and 30 stars. |
| Region 7 | Level 6-6 cleared and 36 stars. |
| Region 8 | Level 7-6 cleared and 42 stars. |
| Roguelite mode and daily challenge | 12 stars. |
| A content tier for runs and the daily | Each boss level of regions 5 to 8 cleared, on Normal or Relaxed, adds one tier (14.9). |
| A level's Twist | 3 stars on that level. |
| Towers in the campaign | Reaching the level that brings them (12.2). |
| Unlockable cards | Their conditions (14.6). |

Why a player at one or two stars per level still reaches the end:

- Every cleared level gives at least 1 star, on Normal or Relaxed.
- Levels open in order. Clearing every level of a region once gives exactly 6 stars for that region. That meets every region's star count: 6, 12, 18, 24, 30, 36 and 42.
- Relaxed is always available, and a Relaxed win is enough to move on.
- Content tiers need only the boss levels cleared, so a one-star player earns every tier on the way.
- Second and third stars open only Twists and some roguelite cards. Both are variety, never needed to finish.
- A player with two stars per level reaches 12 stars after region 1 and can open the roguelite early. A one-star player opens it after region 2.
- The campaign holds 144 stars. The card unlocks at 24, 36, 48, 60 and 72 stars stay where they were, so they come earlier in the whole journey. They add variety, never power (14.6).

## 17. Answers to the architecture assumptions

The first draft of docs/ARCHITECTURE.md was written before this file and lists 19 assumptions in its section 11. One row per item. Where this file already decided, its rule stands.

| # | Contract assumption | Answer | RULES.md |
|---|---|---|---|
| 1 | Stat block fields, creature fields, rules.json keys | Settled by the tables here. Tower blocks also need: targets per shot, a damage bonus (Bakery), the Bell's slow as a ring with a 1.0 s linger, and which kinds a Bell slows. No shot speed (row 12). Creatures also need: a bubble that returns after 2.0 s, heal (amount, 1.5 range, every 2.0 s), split (Puff, 3, 0.3 s apart), gate breaking time, and boss events. rules.json values: refund 70%, early call 50% rounded up, Relaxed lives 200% and gold 150% rounded up to a multiple of 10, region stars 6, 12 and 18 plus the boss, roguelite 12 stars, 2 waves at once, clear bonus 20 plus 5 per wave, star 2 at 15 lives. | 4.4 to 4.9, 5.3 to 5.8, 6.1 to 6.3, 10, 11, 16 |
| 2 | Effect types; one effect per Twist | Agree that each Twist changes one rule. The changes needed are in 13, 14.5 and 14.6. The game designer's report lists them as effect types for phase 4. | 13, 14.5, 14.6 |
| 3 | Targeting is First | Three modes, changeable at any time: First (the default), Last and Strong. Ties go to the lowest spawn number. | 8.2 |
| 4 | Tick order | Use 8.1. Bells slow before movement, a leak that ends the game ends the tick, and hits land at once, so there is no shot step. | 8.1 |
| 5 | Refunds: each build phase and each wave is a phase | Rule chosen instead: only purchases made in the current build phase refund in full. Anything bought during a wave refunds 70% at once. This follows brief 3.1. | 4.6 |
| 6 | Early call during a wave, at once, with a bonus, at most 2 waves running | Agree, with two details: only after the newest wave has spawned all its groups, and the bonus is half the bounty of the newest wave's creatures still on the map, rounded up. | 4.9 |
| 7 | Clear gold set per wave in the level file | Rule chosen instead: a formula, (20 + 5 times the wave number) times strength / 100, rounded half up. Levels need no per-wave gold. They need a strength instead (6.4). | 4.5, 6.4 |
| 8 | Star kinds, stars as bits, the union kept, Relaxed earns only the win | Agree. Star 2 and the eight star 3 kinds are in 10.2 and 10.3. A Twist win stores only the win bit. | 10, 13 |
| 9 | Gate breaker | Agree, plus: slows slow the breaking, a breaker defeated while breaking loses its progress, each breaker keeps its own timer, it breaks every closed gate on its route in turn, and Old Tusk takes 2.0 s. | 7.6, 7.7 |
| 10 | Flyers fly straight from entrance to base | Agree. Flyers released by a boss start at the boss. There are no flyer-only entrances. | 6.5 |
| 11 | A placement seals when any entrance loses its last route | Agree. | 7.4 |
| 12 | Homing shots with a flight time | Rule chosen instead: an attack lands on the tick the tower fires. Projectiles are only drawn. | 5.2, 8.1 |
| 13 | No chance in battle rules | Agree. Runs use their seed only to build the run and draw cards. | 8.1, 14 |
| 14 | Runs from one top, one middle and one bottom segment; waves made at the start; one draft per cleared wave | Agree. Segments are 4, 5 and 4 rows. Waves come from hand-built packs in six bands. The boss wave owes no draft. | 14.2 to 14.4 |
| 15 | Daily uses the starting pool, counts for its start day, streak counts finished days | Rule chosen instead for the pool: the daily uses every card, unlocked or not. The other two parts: agree. | 15 |
| 16 | 7 columns by 8 to 13 rows; entrances on the edge | Agree. | 3.1, 3.2 |
| 17 | One saved session at a time; starting something new asks first | Not a game rule. Bart decides (contract question 3). If one session: an ended run counts as abandoned, and an ended daily counts as finished for the streak. Bart chose one saved game per mode at hard stop A (4.10). | 4.10, 14.7, 15 |
| 18 | The difficulty choice is not remembered | Agree. Normal is preselected for every level and run. | 11 |
| 19 | A tower counts as unlocked once a level offering it was played | Agree in effect. Each level offers every tower brought up to it, listed in its file, and runs offer every tower through cards. Nothing extra is saved. | 12.2, 14.3, 14.5 |

Other differences for phase 4, outside the 19 items:

- Tie break order: this file says south, west, east, north (7.3). The draft says up, right, down, left.
- Levels and run waves need a strength (6.4).
- A hint may highlight the call button instead of a cell (12.4, level 2-1).
- Spot order: this file now uses the contract's cell order (3.4).
- Progress counters are named in 14.6.

On the contract's open question 2, map width. Yes, 7 columns by up to 13 rows is enough room for good fork and gate puzzles:

- Roads are one tile wide, so 7 columns fit up to three lanes side by side with build spots between them. The gate puzzle lives in those in-between spots: a spot between two lanes sees both, and closing a lane decides which towers the creatures pass.
- Width limits sideways detours to about 6 steps, so maps get their length from rows: switchbacks and stacked forks. With 10 to 13 rows a map can stack two or three fork sections, which gives three gates real choices and routes of about 15 to 35 steps. That is what the wave lengths and ranges in this file assume.
- 8 rows is enough only for the first teaching maps, which is why region 1 may use 8 to 11 rows and later regions 10 to 13 (3.1).
- I would not trade touch size for width. 8 or 9 columns drop below 48 dp on the cover screen.
- On old 16:9 phones 13 rows give about 39 dp (contract 7.4). If that matters, the fix should be a slimmer portrait HUD, not fewer rows. The puzzles would still work at 12 rows if it comes to that.

## 18. Brief section 3 coverage

| Brief item | Covered in |
|---|---|
| 3.1 Waves come down roads; each creature at the base costs lives; out of lives loses | 4.1, 4.4, 6.1 |
| 3.1 Build phase with no time pressure; real time in waves | 4.1, 4.2, 4.3 |
| 3.1 Pause any moment; build, upgrade, sell, inspect while paused | 4.7 |
| 3.1 Speeds 1x, 2x, 3x | 4.8 |
| 3.1 Early call bonus | 4.9 |
| 3.1 Gold from kills and clears; full refund in the same build phase, part after | 4.5, 4.6 |
| 3.2 Six towers with one job each, from the six archetypes | 5.1 to 5.8. Bart added four more for regions 5 to 8 on 2026-10-27: 5.12 to 5.15. |
| 3.2 Three tiers, a permanent pick of two at tier 3 | 4.6, 5.3 to 5.8, 5.12 to 5.15, 9.5 |
| 3.2 No tower best everywhere; each right somewhere | 5.1, 5.10, 5.11, 10.3, 12.5, 12.6 |
| 3.2 Build spots; limited spots are part of the puzzle | 3.4, 12.5 |
| 3.3 About ten creatures plus one boss per region, from the starting set | 6.1 to 6.3. Regions 5 to 8 add eight creatures and four bosses (Bart, 2026-10-27). |
| 3.3 Flyers ignore roads and gates | 6.5, 7.5 |
| 3.3 New creature alone first with an info card; never two new things per wave | 9.2, 12.2, 12.3, 12.5, 14.3 |
| 3.4 Hand-built forks; some road cells are gate sockets | 3.2, 3.3, 7.1 |
| 3.4 0 to 3 gates; a gate closes the road at its socket | 7.1, 12.3 |
| 3.4 Walkers take the shortest open route | 7.3, 7.8. Map features change which steps exist, never the rule: 3.5 to 3.9. |
| 3.4 A placement that seals every route is refused with feedback | 7.4 |
| 3.4 Route line while placing or moving | 7.5 |
| 3.4 Place, move, remove in build phases; locked in waves; mid-wave switch proposal | 7.2, 7.6, 19.2 |
| 3.5 Wave preview: what, how many, which entrance | 9.1. The folded strip shows all three too. |
| 3.5 Tapping shows real numbers | 9.3, 9.4 |
| 3.5 Range shown on placing; before and after on upgrades | 9.5 |
| 3.5 Color never the only signal; silhouettes | 9.7. The art director owns silhouettes. |
| 3.5 Touch only, one thumb, 48 dp | 3.1 sizes the grid for 48 dp. The UI engineer owns controls. |
| 3.6 About 24 levels in 4 regions of 6; each region brings 1 or 2 towers and 2 or 3 creatures and ends with a boss | 12.1, 12.2, 12.3. Bart made it 48 levels in 8 regions on 2026-10-27. Regions 5 to 8 each bring one tower, two creatures, a boss and a map feature. |
| 3.6 Levels take 5 to 10 minutes at 1x | 12.3, 12.5 |
| 3.6 Three stars; one for winning; second and third defined and shown on the level card | 10, 12.4. Shown in Pause during play: 10.6 |
| 3.6 First levels teach one idea with a one-line hint and a highlighted spot; Info holds the full rules | 9.6, 12.3, 12.4 |
| 3.6 Twist after three stars; the Twist list | 13 |
| 3.7 Runs of 15 to 20 waves, 15 to 25 minutes, ending in a boss | 14.1, 14.3 |
| 3.7 Maps from hand-built segments | 14.2 |
| 3.7 One of three cards after each wave, five card types | 14.4, 14.5 |
| 3.7 Losing ends the run; leave and resume at any wave | 14.7 |
| 3.7 Unlocks join the pool; variety, never power; nothing bought | 14.6 |
| 3.8 One seeded run per day from the local date, same on every phone, no network | 15. Since the expansion, the same for every player at the same content tier (14.9; Bart, 2026-10-27). |
| 3.8 Best result for the day and a streak, on the phone only | 15 |
| 3.9 Stars unlock regions and the roguelite; towers unlock as the campaign brings them | 12.2, 14.9, 16 |
| 3.9 Everything earned; no grind walls | 16 |
| 3.9a Normal and Relaxed, picked per level or run, Normal by default | 11 |
| 3.9a Relaxed numbers; nothing else changes | 11, 12.3 |
| 3.9a A Relaxed win earns one star; stars 2 and 3 need Normal | 10.4, 11 |
| 3.9a The daily is always Normal | 11, 15 |
| 3.10 Resuming after leaving | 4.10, 14.7. Bart chose the exact moment at hard stop A. |
| 3.11 Plain classes, fixed timestep, seeded randomness | 5.2, 8.1, 14.4, 15. No randomness in combat. |

## 19. For Bart at hard stop A

Nothing in this section is a rule. Engineers do not build from it.

### 19.1 Choices for Bart to approve

1. Names. Every tower, path, creature, boss, region and level name is a working name. The art director may want changes to fit the silhouettes.
2. The tower roster and jobs (5.1). The Firework Tower hits only flyers, the Sling Post hits both, the Lullaby Bell deals no damage, and the Bakery boosts attack rate.
3. Level 1-1 opens with two towers. Brief section 11 says no single tower type may earn three stars alone on any level. With one tower in the first levels that check cannot pass. The other choice is to open with the Sling Post alone and exempt the first levels from that check.
4. Star rules (10). Star 2 is always "Keep 15 lives". Star 3 is one of eight challenge types per level (12.4). Stars can be earned in different wins.
5. Relaxed numbers (11). 40 lives instead of 20, and 1.5 times the starting gold.
6. The Twist list (13).
7. The campaign plan (12): the order things arrive, gate counts, wave counts, strengths and starting gold.
8. Economy (4.5 to 4.9). Bounties, the clear bonus formula, the early call bonus of half the bounty still on the map from the newest wave, and refunds of 70% for anything not bought in the current build phase, including anything bought during a wave.
9. Gatecrasher rules (7.7). It walks the route it would take with no gates, and broken gates mend at the next build phase.
10. Route lines show during the whole build phase, not only while dragging a gate (7.5).
11. The roguelite (14). 18 waves, three segments per map, 22 base cards, and 12 unlockable cards with their conditions.
12. Roguelite and daily open together at 12 stars, and runs use every tower and creature, even ones the campaign has not brought yet. Each shows its info card the first time. The other choice is to open the daily only after level 4-3, when the player has met everything.
13. Daily rules (15). Unlimited tries, how the best result is chosen, and how the streak counts.
14. Every level and run starts at 1x speed (4.8).
15. Map size (3.1): 7 columns by 8 to 13 rows, as the contract proposes. My view on the width question is at the end of section 17.
16. Attacks land the moment a tower fires, and projectiles are only drawn (5.2). The contract's first draft assumed flying shots.
17. At most 2 waves on the map at once (4.9). This comes from the contract's performance budget and limits how far early calls can be chained.

### 19.2 Suggestions beyond brief section 3

1. Mid-wave gate switch. I propose not adding one to the campaign. The campaign's pleasure is solving the map in the calm build phase and then watching the plan work. A mid-wave switch turns that into reflex play under time pressure on a one-thumb phone screen. Players would also pause to switch, which makes it a chore rather than a skill. It would weaken the Gatecrasher, whose threat is that gates hold only until it arrives. If Bart wants to try the idea, the smallest safe version is one unlockable roguelite card, "Swing Gate": once per wave, move one gate during the wave; the new socket closes 2.0 s after the drop, and the move is refused if any walker on the map would be left with no route. It stays optional, adds variety, and costs little to build and test.
2. Remember the speed setting between levels instead of starting each level at 1x.
3. Show "damage dealt this level" when a tower is tapped, so players can see which towers carry their defense.
