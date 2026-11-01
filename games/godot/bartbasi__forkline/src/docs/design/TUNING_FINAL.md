# Final tuning plan (G7): the answer to the final balance pass

Owner: game designer. 2026-10-30 (task G7). Answers the final balance report of version 1, docs/balance/final-2026-10-30.md (B7, played on 5b960f2). RULES.md holds the rules and numbers. This file says what changes, why, and exactly what each owner types in. Section 5 lists every text a player sees that changes. Region 3 is content Bart played before the expansion, so its one change is kept small: a wave count, which goes ahead under the DM's standing go ahead (CLAUDE.md, 2026-10-28), and the DM tells Bart.

Every number of mine below was measured on a clean `git archive` of fcffe99 in the session's scratch folder, with the working tree's tools/balance/ copied in: the analyst's three new job scripts, which are not committed, and without the nine 8-6 variants the analyst deleted. Nothing the bots read changed between 5b960f2 and fcffe99, which touched only the HUD. I checked it by play: on 3-5 the plain mixed recipe gives files equal to the analyst's (Normal and the Twist, every field but run time and digest), and the 14 saved lone builds, the 42 saved three-star builds of three any-tower searches and the 14 saved Twist builds all replay to exactly their saved lives and stars. Level variants came in through `level_file=`, so no data file of the copy changed while the bots played. While I worked, main moved to c17c26f (U9 and the B7 commit). Between fcffe99 and c17c26f, data/ and src/sim/ did not change, and tools/balance/ is byte for byte the copy I used, so these numbers hold on c17c26f too.

## 1. Decisions

### 1.1 Level 3-5 Two Shores: one more Pip in the last wave

data/levels/r3_l5.json, wave 12: the Pip group's count goes from 32 to 33. Nothing else in the level changes: the map, gold, gates, the other eleven waves, the other three groups of wave 12, the third star "No tower above tier 2.", the empty hint and highlight, and the Twist.

Why:

- B7 found the miss on one lone Sling Post search of four (seed 1063501): 59 three-star builds in 6000, the first at build 5600. Each is nine Sling Posts with no tower above tier 2 and no Bell, and each wins with exactly 15 lives, the line of the second star. All five lives it loses leak in wave 12: five of its 32 Pips.
- Wave 12 brings its Pips at strength 120, with 25 health each, 0.05 s apart: about two tiles of road from the first to the last. A tier 2 Sling Post needs 4 pebbles for each Pip. A tier 2 Catapult needs 2 pumpkins for the whole crowd, because its splash covers it. So one more Pip costs a line of pebbles more time and costs splash nothing. With 33 Pips the saved lone builds let 7 through and keep 13 lives, and the 42 saved mixed three-star builds still keep all 20 (3.1).
- The searches agree (3.2). With 33 Pips, the lone Sling Post search on the seed that found the builds and on two new seeds found no three-star build in 6000 builds each. On two of the seeds their best wins inside the cap kept 13 lives, and on the third there was no win inside the cap at all.
- Every other check of RULES 12.6 holds (3.3). The plain mixed recipe plays every gate placement exactly as before, on Normal, on Relaxed and under the Twist. All three stars are reached: the two searches of 3000 builds I ran found none, as B7's first search found none as built, and the two hunts of 6000 builds of RULES 12.6 then found 1731 and 1568 three-star builds, more and sooner than as built (744 and 1067). The Twist search wins 597 of its 1500 builds. Random play earns no three stars. The length stays 7.8 minutes, and the largest wave grows from 56 creatures to 57.
- 33 is the smallest change that closes it, as the DM asked. 34 and 36 close it too, with a little more room: the saved lone builds keep 12 and 10 lives, and the lone searches' best wins inside the cap kept 12 and 11 lives at 34, and 10 and 10 at 36. But from 34 on, some of the saved mixed builds start to leak too, one or two Pips or a Skitter. At 33 a mixed defense loses nothing.
- The third star stays, as the DM asked. B7 showed why the other rules fail (B7 2.4): a tower limit of 8, 7 or 6 lets the lone Sling Post earn the star far more often (2232, 1996 and 1828 three-star builds of 6000), "Upgrade no towers." left no three-star win for any search, and "Build no Sling Posts." would give 3-4, 3-5 and 3-6 the same rule three levels in a row, which the third stars avoid everywhere else (RULES 12.4). 3-5 has no hint, so no text on the level card changes.

Gold follows strength (RULES 4.5): the extra Pip pays 4 gold.

### 1.2 RULES 14.8: the second reading is the bar from tier 2 on

The DM's call, written into RULES 14.8. From tier 2 on, the bars on how often runs are won and lost (Normal, Relaxed, the boss, fair maps and fair packs) are read with the tower cards of tiers 2 to 4 (Scarecrow, Snow Fort, Moth Lantern) and their perks (Big Hat, Packed Snow, Bright Wick) out of the pool. The first reading, the pool as the player has it, is reported beside them, not held to them. The other rows of 14.8 keep the player's pool: every run can be won, every card unlocked, no card decides a run, risk cards trade fairly, length and same seed, and the daily's bars (RULES 15).

Why:

- A player can always pass on a tower card. The bots cannot: they take a tower card in most drafts and build one tower of every kind they hold, so on 11 or 12 spots they spread thinner with every kind the pool adds (TUNING_R67.md 1.3). The second reading is the fair floor for a thoughtful player, as 14.8 already said for a bar missed on the hard side.
- The gap is the bots' spending, not the tier's content, and it is spread over the three cards. At tier 4, taking any one card out with its perk gives back 4.5 to 4.9 of the 19.6 points the three cost together, and any one card alone in the pool costs 7.8 to 11.0 (B7 3.2, the table in 3.4 below). So no one card can be tuned to close it. The analyst's pointer: with the cards in, 26% of tier 4 plays never build a Longbow Loft, the boss and armor tower, against 6% at tier 0.
- Both sides of a bar now read the second reading. A thoughtful player wins at least as often as the bots, so too easy for the better of the two bots is too easy (TUNING_R67.md 1.3). The old rule read a ceiling with every card in, because then the first reading was the bar.

What it does to B7's results: every bar of 14.8 is met at tiers 2, 3 and 4, apart from two results at the edge of a bar, both well inside one standard error (3.4):

- **b6_toad_glen** (tier 4 boss pack): 75.4% of 2643 runs that start wave 18 win, forced onto every seed. The ceiling is 75%. That is 0.4 points over, with a standard error of 0.8. Its first reading is 52.9%.
- **mid_hollow** (tier 4 segment): 0.746 times all runs on its 10 natural seeds, against a bar of 0.75. That is 0.004 under, with a standard error of about 0.09. Its first reading is 1.132.

Both are noise, as G5 decided for `towers_tall` at 75.5% and `mid_eye` at 0.748 (TUNING_RUNS.md 9.1), and nothing changes for them. I checked mid_hollow the way B5 checked `mid_eye`: its eight stacks forced through whole runs on seeds 1 to 50 read 0.741 times all runs, with a standard error of 0.06 over the seeds, so at the bar again (3.6). With every card in, the same check reads 0.790 (standard error 0.07), not the 1.132 of its 10 natural seeds, which were a lucky draw. So mid_hollow is the tier 4 segment nearest its bar in both readings: fair, but not by much. Nothing changes now. If there is another pass, it is the one segment I would ask the level designer to look at, starting with its stacks under top_meet and over bot_square, the hardest in both readings.

Relaxed at tier 4 had only a first reading in B7 (98.0% for the best strategy, 88.6% for the 16 together), so I played its second reading: the best strategy wins 98.5% and the 16 together 94.3%, against bars of 90% and 80% (3.5).

### 1.3 b6_toad_hollow and b4_yawning_watch: no change

Both meet their bars under 1.2, so neither changes.

- **b6_toad_hollow**, Glimmertoad's second run pack: 67.6% of 2650 runs that start wave 18 win on the second reading (bar 50% to 75%). The first reading is 46.6%.
- **b4_yawning_watch**, a tier 3 pack of band 4: 7.3% of 3016 runs that reach it are lost inside it on the second reading (bar 10% at most). The first reading is 12.7%.

I looked for a reason to change them anyway and found none. Glimmertoad's packs already sit at strength 50, the floor of a band 6 pack, and its first reading is what the bots do with three tower cards they spend poorly. The only lever left there is Glimmertoad's health in data/stats/ (TUNING_R8.md, suggestion 2), which also moves 8-6 and its Twist, both tuned and passing. b4_yawning_watch loses its runs where Yawners make towers beside the road doze, which is the lesson of 7-4: a player who sets towers back keeps them awake, and the bots do not read that. The levers stay named for later, in case players find either one hard: Glimmertoad's health 3600 to 3300 with 8-6's boss wave from 55 to 60, and the last wave of b4_yawning_watch with 3 Dusk Moths instead of 4, the step that took b4_blinking_watch from 12.6% to 9.6% (TUNING_R8.md 1.5).

### 1.4 RULES 12.6: a tier cap gets the hunts too

As the DM asked. On a level whose third star is a tier cap ("Upgrade no towers." or "No tower above tier 2."), a first search of 3000 builds that finds no three-star win no longer decides. Up to two more searches of 6000 builds with different seeds come first, and one three-star win is enough, as E8.3 wrote for tower limits and kinds limits. The analyst already ran 3-5 that way in B7: its first search found none (seed 1023500), and its two hunts found 744 and 1067 three-star builds, the first at builds 4450 and 3808. 8-3, also a tier cap, found its first at build 2537 of 3000. So a tier cap finds its builds as late as the other limits. The 12.6 row now names 3-5, 4-4, 5-3 and 8-5 as the levels that needed hunts in the final pass.

### 1.5 Noise and the thin Twist of 6-6: no change

- **`towers_tall` at tier 0, 75.5%** (ceiling 75%, standard error 3.0) **and `mid_eye`, 0.748** (bar 0.75): the same rows as B5, which G5 judged noise (TUNING_RUNS.md 9.1). B5 then forced all eight `mid_eye` stacks through whole runs on seeds 1 to 200: 0.800 times all runs, with a standard error of 0.010. Both are tier 0 results, which can never change without changing every tier 0 run and daily (RULES 14.9). No change.
- **6-6 Old Hayrick, Double Trouble: 2 wins in the first search of 1500 builds.** RULES 12.6 asks that some strategy wins it, which holds. The search is what is thin, not the Twist: the plain mixed recipe wins it at 20 of 35 gate placements, exactly as many as it wins on Normal, with the same best of 7 lives, and at every placement it wins the Twist with exactly the lives it keeps on Normal: both Old Hayricks are popped before either reaches the base. I also replayed the 14 builds the any-tower search of 6-6 saved, all of them three-star wins with 20 lives on Normal (E6.2, seed 826600), under the Twist. All 14 lose it, each in the boss wave, where one of the two Old Hayricks walks through. Each of them starts that wave with 650 to 1560 gold it never spends, because a saved build buys only what its list holds. A player sees two Old Hayricks in the preview and spends it. So the Twist asks for a stronger finale than Normal, which is what Double Trouble is for, and a plain mix that takes its attackers to tier 3 has it. No change.

### 1.6 Not changed, on purpose

- **3-5's third star, hint, highlight and Twist.** "No tower above tier 2." stays, the hint and highlight stay empty, and the Twist stays Tier 2 Cap.
- **data/stats/.** No tower, creature or rule number moves.
- **Every other level, Twist, pack and segment.** They met every bar in B7.
- **RULES 12.6's other checks** and the daily's bars of RULES 15.

## 2. Changes per owner

### 2.1 Game designer (done in this step)

- RULES.md: the change note; 12.4 (a paragraph on 3-5); 12.6 (the "All three stars" row now names tier caps); 14.8 (the second reading is the bar from tier 2 on).
- This file.
- data/stats/: no change.

### 2.2 Level designer

Exactly this edit. Nothing else in the file changes: no map, gold, gate, other wave, third star, hint, highlight or Twist.

data/levels/r3_l5.json, wave 12 (the last line of `waves`), its first group:

```
before:  {"strength": 120, "groups": [{"enemy": "pip", "count": 32, "entrance": 2, "at_ms": 0, "every_ms": 50}, {"enemy": "skitter", ...
after:   {"strength": 120, "groups": [{"enemy": "pip", "count": 33, "entrance": 2, "at_ms": 0, "every_ms": 50}, {"enemy": "skitter", ...
```

No test reads the count: the plan row of `r3_l5` in tests/levels/test_level_design.gd holds the gates, sockets, wave count, strength, gold, third star and highlight, which all stay. The level smoke test plays the plain mixed recipe, which plays 3-5 exactly as before (3.1). On a second clean copy of fcffe99 with exactly this edit, after `godot --headless --path . --import`, `godot --headless --path . --script res://tests/run_tests.gd` gives "Ran 1635 tests in 117 files: 1635 passed, 0 failed." with exit code 0, and on a clean copy of c17c26f with the edit "Ran 1636 tests in 117 files: 1636 passed, 0 failed.", exit code 0. Its line for 3-5: won with gates (0, 3), (2, 8) and (4, 8), 12 lives left, 7.8 minutes at 1x.

### 2.3 Balance analyst

Nothing to play for this step: my numbers in section 3 stand for 3-5, and the reading of 14.8 uses the files B7 already has. If there is another pass:

1. 3-5 with every check of RULES 12.6 on its usual seeds. The "All three stars" search may need the hunts of 12.6 again: on B7's seed 1023500 the first search of 3000 builds finds no three-star build, as built and as changed.
2. The bars of tiers 2 to 4 read on the second reading (the `tN_nocards` folders), both sides, with the first reading beside them. Relaxed at tier 4 needs its second reading too; section 3.5 has one.
3. Your README's B7 section can say the second reading is now the bar from tier 2 on. That file is yours, so I have not touched it.

### 2.4 Everyone else

The roguelite engineer, the sim engineer and the UI engineer have nothing to do: no card, run file, src/ or contract change. The wave preview, the panels and the Info screen build their numbers from the level data (contract 2.7).

## 3. Evidence

### 3.1 Level 3-5: the saved builds, replayed with more Pips

The cheap first screen: the builds that B7's searches saved, played again on 3-5 with wave 12's Pip group at each count (`mode=replay`). The lone builds are the 14 that the lone Sling Post search of seed 1063501 saved: its best win, its twelve best three-star builds and its top build. The mixed three-star builds are the 42 that three searches with every tower saved: B7's two hunts (seeds 943500 and 943501) and B3's first search (seed 823500). The Twist builds are the 14 of B7's Twist search (seed 873500). Stars count 1 to 3.

| Wave 12 Pips | 14 lone builds (nine tier 2 Sling Posts) | 42 mixed three-star builds | 14 Twist builds |
|---|---|---|---|
| 32, as built | all 15 lives, 3 stars; 5 Pips through | all 20 lives, 3 stars | all won, 20 lives |
| **33** | all 13 lives, 2 stars; 7 Pips through | **all 20 lives, 3 stars** | all won, 20 lives |
| 34 | all 12 lives, 2 stars; 8 Pips through | 34 with 20 lives and 8 with 19, all 3 stars | all won, 20 lives |
| 36 | all 10 lives, 2 stars; 10 Pips through | 34 with 20, 1 with 18 and 7 with 17, all 3 stars | all won, 13 with 20 lives and 1 with 18 |
| 38 | all 9 lives; 11 Pips through | 34 with 20 and 2 with 15 or 16, 3 stars; 6 with 14, 2 stars | all won, 13 with 20 and 1 with 18 |
| 40 | all 7 lives; 13 Pips through | 34 with 20, 3 stars; 8 with 12 or 14, 2 stars | all won, 13 with 20 and 1 with 18 |

Every life the lone builds lose is a Pip of wave 12: 5 of 32, 7 of 33, 8 of 34 and 10 of 36. The mixed builds lose nothing at 33, because their Catapult splashes the whole crowd at once. From 34 on some of them let one or two Pips or a Skitter through, as the longer crowd keeps their towers busy.

The plain mixed recipe plays every gate placement exactly the same at 32, 33, 34, 36, 38, 40 and 44 Pips, on Normal and Relaxed and under the Twist: the same wins, lives and stars at every placement, and on its best placement the same ticks. It loses no Pip in wave 12.

### 3.2 Level 3-5: the searches

Lone Sling Post searches of 6000 builds (`only=solo:sling_post`, so Bells were allowed; B7's 59 three-star builds held no Bell), any-tower searches of 3000 builds, and the Twist search of 1500 builds. "Inside the cap" counts the wins with no tower above tier 2, and gives the most lives any of them kept: 15 or more would be a three-star build.

| Search (seed) | 32, as built (B7) | **33** | 34 | 36 |
|---|---|---|---|---|
| Lone Sling Post (1063501, the seed that found it) | **59 three-star builds**, first at 5600; inside the cap 2156 wins, best 15 lives | **none**; inside the cap 2047 wins, best 13 lives | none; inside the cap 1941 wins, best 12 lives | none; inside the cap 1700 wins, best 10 lives |
| Lone Sling Post (1203501, new) | not played | **none**; no win inside the cap (3067 wins in all) | none; no win inside the cap (3069 wins in all) | none; no win inside the cap |
| Lone Sling Post (1233501, new) | not played | **none**; inside the cap 2001 wins, best 13 lives | none; inside the cap 1946 wins, best 11 lives | none; inside the cap 1761 wins, best 10 lives |
| Any tower, 3000 builds (823500, B3's seed) | 616 three-star builds, first at 1662 (B3) | none | 677, first at 1272 | 713, first at 1193 |
| Any tower, 3000 builds (1023500, B7's seed) | none (B7) | none | none | none |
| Any tower, hunts of 6000 builds (943500, 943501) | 744 and 1067, first at 4450 and 3808 (B7) | **1731 and 1568, first at 2175 and 2839** | not played | not played |
| Twist, 1500 builds (873500) | 614 wins (B7) | 597 wins | 607 wins | 589 wins |
| Random play, 750 plays (813500) | 4 wins, no three stars (B7) | 4 wins, no three stars | 4 wins, no three stars | 4 wins, no three stars |

B7's other lone seeds (833501 and 863501 of B3, 1033501 and 1133501 of B7) found no three-star build as built, so I spent the searches on new seeds.

### 3.3 Level 3-5 as planned: every check of RULES 12.6

| Check of RULES 12.6 | As built (B7) | 33 Pips |
|---|---|---|
| The plain mixed recipe on Normal (bar: it wins) | won, 12 lives, 1 star; 24 of 32 gate placements | the same at every placement |
| The plain mixed recipe on Relaxed: no gates, best | won, 36 and 36 lives; 32 of 32 | the same at every placement |
| All three stars | first search of 3000 builds: none (1023500); hunts of 6000: 744 and 1067 three-star builds | first searches of 3000 builds: none (823500 and 1023500); hunts of 6000 builds: 1731 and 1568 three-star builds, the first at 2175 and 2839, each with a Sling Post and a Catapult, nearly all with a Firework Tower; and all 42 saved mixed three-star builds keep 20 lives and three stars (3.1) |
| No super tower: the lone Sling Post, the only attacker that needs a search (`mode=need`: flyers cost 76 lives) | **fails**: 59 three-star builds on seed 1063501 | **passes**: none on 1063501, 1203501 and 1233501, 6000 builds each |
| Random play: three stars in under 10% | 0.0% of 750 | 0.0% of 750 (4 wins, none with three stars) |
| Length: 5 to 10 minutes at 1x | 7.8 | 7.8 (the same ticks) |
| Size | largest wave 56; most creatures at once 61 (a lone search) | largest wave 57; most creatures at once 64 (a lone search) |
| The Twist is won on Normal | 614 of 1500 builds | 597 of 1500 builds; all 14 saved Twist builds win with 20 lives |
| Same inputs, same result | met | met: `mode=det` on Normal and the Twist, 24 plays and 72 saves in the middle of a wave equal each, and the search repeats |

### 3.4 Runs at tiers 2 to 4: the bars on both readings

From B7's raw files (`raw/2026-10-30-b7/r/tN` and `r/tN_nocards`), Normal, base cards, the 16 named strategies, run seeds 1 to 200, both bot habits, read with `runs_summary.gd ... tier=N part=b4`. I printed the second reading's tables of tiers 2, 3 and 4 again from those files with the same tool on my copy, and they equal the analyst's line for line. At tier 3 mine also prints the forced b4_yawning_watch, 7.3% of 3016, which B7's report gives. A pack, segment or stack is read at the tier that adds it (RULES 14.8). "Forced" is the pack forced onto all 200 seeds; the other numbers are natural seeds. In each cell the second reading, which is now the bar, comes first, and the first reading follows in brackets.

| Bar | Tier 2 | Tier 3 | Tier 4 |
|---|---|---|---|
| Normal, the 16 together (35% to 55%) | **38.8%** (30.0%) | **41.9%** (28.4%) | **44.4%** (24.8%) |
| Normal, the best strategy (55% to 75%) | **towers_wide 56.5%** (50.0%) | **towers_wide 56.0%** (39.5%) | **towers_tall 59.5%** (36.5%) |
| Relaxed (the best at least 90%, the 16 at least 80%) | not played in either reading | not played in either reading | **economy_tall 98.5%, the 16 94.3%** (98.0%, 88.6%), my runs (3.5) |
| The boss: packs of the tier (50% to 75% of the runs that start wave 18 win) | b6_hayrick_barn **63.7%** of 245 (63.3%), b6_hayrick_field **68.7%** of 150 (57.7%) | b6_snore_drift **66.5%** of 167 (forced 58.3%), b6_snore_ridge **50.9%** of 106 (forced 50.8%) | b6_toad_glen **75.4%** of 2643 forced, at the ceiling (forced 52.9%); b6_toad_hollow **67.6%** of 2650 forced (forced 46.6%) |
| Fair maps: segments of the tier (at least 0.75 times all runs) | mid_cart **1.031** (1.029), mid_planks **0.755** (0.867) | mid_chute **1.306** (1.118), mid_drift **1.107** (1.320) | mid_hollow **0.746**, at the bar, and **0.741** forced through whole runs (1.132, forced 0.790), my runs (3.6); mid_knot **1.144** (1.289); mid_roots **1.103** (1.468) |
| Fair maps: stacks of the tier that 4 or more seeds use (at most 10% lost by wave 6) | worst top_side, mid_planks, bot_yard **4.7%** (10.9%; forced 3.4%) | none has 4 seeds | top_pair, mid_hollow, bot_porch **3.1%** (12.5%; forced 2.9%) |
| Fair packs: packs of the tier (at most 10% lost inside) | b3_sleepy_rows **7.4%**, b4_glowing_watch **6.0%**, b5_harvest_siege **3.6%** (7.2%, forced 8.1%, 7.2%) | b3_snowballs **2.7%**, b5_frost_siege **2.2%**, b4_yawning_watch **4.2%**, forced **7.3%** of 3016 (4.6%, 7.7%, forced 12.7%) | b3_blinking_lanes **4.5%**, b4_blinking_watch **4.7%**, b5_hoot_siege **1.4%** (forced 9.2%, forced 9.6%, 0.8%) |
| Length, won runs (12 to 16 minutes) | 12.8 (12.9) | 12.7 (12.8) | 12.5 (12.7) |

The rows that keep the player's pool, all met in B7: every run can be won (at tiers 2, 3 and 4, 48, 47 and 41 of seeds 1 to 50 won by a named strategy, the rest by one of the first 100 random ones), every card unlocked (-1.1, -1.8 and +0.1 points on Normal, -1.2 on Relaxed at tier 4), no card decides a run (the largest at tier 4 is Deep Lullaby, +4.8), risk cards trade fairly (all 8 between 24 and 51 gold a life, against 17.9 to 71.8), the same seed plays the same (0 failures), and the daily at every tier.

The cost of the three cards at tier 4 (B7 3.2: base cards, the 16 strategies, seeds 1 to 200):

| Pool at tier 4 | The 16 together | Best strategy | Against all three in |
|---|---|---|---|
| All three cards in (the player's pool) | 24.8% | towers_tall 36.5% | |
| Scarecrow out | 29.3% | towers_wide 41.5% | +4.5 |
| Snow Fort out | 29.3% | towers_tall 45.5% | +4.5 |
| Moth Lantern out | 29.7% | towers_tall 43.5% | +4.9 |
| All three out (the second reading) | 44.4% | towers_tall 59.5% | +19.6 |
| Only the Scarecrow in | 34.7% | towers_tall 55.5% | 9.7 under all out |
| Only the Snow Fort in | 36.6% | towers_tall 52.5% | 7.8 under all out |
| Only the Moth Lantern in | 33.4% | towers_tall 49.0% | 11.0 under all out |

Each card alone costs 7.8 to 11.0 points, and each one out gives back only 4.5 to 4.9, because the three costs overlap: together they cost 19.6, less than the 28.5 of the three alone. With 3200 plays a row the standard error is 0.8, so the three cards are within about 3 points of each other.

### 3.5 Relaxed at tier 4, second reading

`runs.gd mode=rates`, tier 4, Relaxed, base cards with the three tower cards of tiers 2 to 4 and their perks out (`pool=minus:...`), the 16 strategies, both habits, run seeds 1 to 200 in four jobs of 50.

| Reading | The 16 together (at least 80%) | Best strategy (at least 90%) | Lowest strategy |
|---|---|---|---|
| First, every card of the tier in (B7) | 88.6% (2835 of 3200) | economy_tall 98.0% | |
| **Second, the three cards out (mine)** | **94.3% (3019 of 3200)** | **economy_tall 98.5% (197 of 200)** | risk_wide_early 86.5% |

Both bars are met with room in both readings.

### 3.6 mid_hollow forced through whole runs, on both readings

As B5 did for `mid_eye`: each of the eight stacks that can hold mid_hollow (a top of top_bend, top_meet, top_pair or top_side, and bot_porch or bot_square) forced onto run seeds 1 to 50, tier 4, Normal, base cards, the 16 strategies, whole runs (`stack=`), once on each reading. The eight stacks are equally likely in a draw: each of those tops fits 9 middles, and mid_hollow fits 2 bottoms. So their mean is the segment's own win rate. It is compared with all runs on the same seeds, from B7's `t4_nocards/rates_base_r0_1.json` and `t4/rates_base_r0_1.json`.

| Stack (top, middle, bottom) | Second reading: won (lost by wave 6) | First reading: won (lost by wave 6) |
|---|---|---|
| top_bend, mid_hollow, bot_porch | 50.0% (0.1%) | 28.1% (2.3%) |
| top_bend, mid_hollow, bot_square | 30.3% (0.6%) | 16.9% (2.9%) |
| top_meet, mid_hollow, bot_porch | 25.9% (1.1%) | 12.0% (5.0%) |
| top_meet, mid_hollow, bot_square | 24.9% (1.0%) | 13.8% (4.9%) |
| top_pair, mid_hollow, bot_porch | 35.9% (0.4%) | 19.5% (3.1%) |
| top_pair, mid_hollow, bot_square | 24.4% (0.5%) | 14.6% (3.9%) |
| top_side, mid_hollow, bot_porch | 46.4% (0.3%) | 28.9% (2.0%) |
| top_side, mid_hollow, bot_square | 26.9% (0.5%) | 15.6% (2.4%) |
| The eight together | 33.1% (2116 of 6400) | 18.7% (1195 of 6400) |
| All runs on seeds 1 to 50, natural maps (B7) | 44.6% (357 of 800) | 23.6% (189 of 800) |
| **Times all runs (bar 0.75)** | **0.741**, standard error 0.06 | **0.790**, standard error 0.07 |
| Natural seeds, all 200 (B7) | 0.746 (10 seeds) | 1.132 (10 seeds) |

The standard errors come from resampling the 50 seeds, because all runs give only 16 plays a seed. Every stack meets the stack bar of 10% lost by wave 6 in both readings.

### 3.7 How to repeat

From the root of a clean copy of fcffe99 with the working tree's tools/balance/, after `godot --headless --path . --import`. P33 is data/levels/r3_l5.json with wave 12's first group, the Pips, at count 33 (`jq '(.waves[11].groups[0].count) = 33'`), and the other counts the same way. Saved builds for the replays: B7's `b/r3_l5_solo_sling_post_b.json` (lone), `final/r3_l5_search_any_h0.json` and `_h1.json` and B3's `r3_l5_search_any.json` (mixed), `a/r3_l5_search_twist.json` (Twist), and E6.2's `r6_l6_search_any.json` (6-6).

```
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r3_l5 level_file=P33 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r3_l5 level_file=P33 twist=1 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=replay level=r3_l5 level_file=P33 from=SAVED.json pick=all out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r3_l5 level_file=P33 seed=1063501 evals=6000 stop_dry=2500 only=solo:sling_post out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r3_l5 level_file=P33 seed=823500 evals=3000 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r3_l5 level_file=P33 seed=943500 evals=6000 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r3_l5 level_file=P33 twist=1 seed=873500 evals=1500 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=spread level=r3_l5 level_file=P33 seed=813500 n=250 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=det level=r3_l5 level_file=P33 seed=853500 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=replay level=r6_l6 twist=1 from=R6_L6_SEARCH_ANY.json pick=all out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=minus:tower_scarecrow,big_hat,tower_snow_fort,packed_snow,tower_moth_lantern,bright_wick relaxed=1 tier=4 leaks=1 out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=minus:tower_scarecrow,big_hat,tower_snow_fort,packed_snow,tower_moth_lantern,bright_wick relaxed=0 tier=4 leaks=1 stack=top_bend,mid_hollow,bot_porch out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 tier=4 leaks=1 stack=top_bend,mid_hollow,bot_porch out=OUT.json
godot --headless --path . --script res://tools/balance/runs_summary.gd -- dir=B7_RAW/r/t4_nocards tier=4 part=b4
```

The other jobs differ only in the level file, the seed, `first`, the stack or `twist=1`. The ratios of 3.6 and their standard errors come from the rows of those files, resampling the 50 seeds. The Twist determinism check is `mode=det twist=1 seed=883500`. In all about 15 hours of jobs in about two and a quarter hours of wall time, at most 8 Godot processes on the machine at once, each in `timeout`.

## 4. For Bart

These change what Bart approved or sees, so the DM tells him. Under the DM's rule of 2026-10-28 they go ahead once the DM accepts them.

1. **3-5 Two Shores: the last wave brings 33 Pips instead of 32.** Why: nine Sling Posts, none above tier 2, could still earn all three stars there, with exactly 15 lives left, and every life they lost was a Pip of that last crowd. With one more Pip they keep only 13, so the third star needs a mix again. A defense with a Catapult loses nothing, because its splash pops the whole crowd at once. The third star, the Twist and the rest of the level stay as they are.
2. **How the bots judge runs once region 6, 7 or 8 is cleared.** Not a change to the game. When the bots measure those runs, they now leave out the three newest tower cards (Scarecrow, Snow Fort, Moth Lantern), because a player can always pass on a card and the bots play those three poorly. Measured that way, every run target is met. The cards stay in the drafts as before.

No hint, Twist, card line, run card or creature line changes.

## 5. Every text a player sees that changes

The wave preview builds its rows from the level data (contract 2.7), so the UI changes nothing.

| Where | Before | Now |
|---|---|---|
| 3-5 Two Shores, wave 12 preview, open list and folded strip, on Normal, on Relaxed and in the Twist | 32 Pips (B), 10 Skitters (A), 2 Dusk Moths (B), 12 Flitters (A) | 33 Pips (B), 10 Skitters (A), 2 Dusk Moths (B), 12 Flitters (A) |

Gold follows strength (RULES 4.5): the 33rd Pip pays 4 gold, like the others at strength 120. The wave's clear bonus does not change. Nothing else a player sees changes: the changes to RULES 12.6 and 14.8 are about how the bots measure.

## 6. Open questions

1. **For the DM: both sides of a bar on the second reading.** You asked that the first reading be reported, not held to a bar. I took that for both sides of each bar: a thoughtful player wins at least as often as the better bot, so a ceiling belongs on the second reading too. It puts two results at the edge, b6_toad_glen at its ceiling (75.4%) and mid_hollow at its floor (0.746 on natural seeds, 0.741 forced), both within noise (1.2). If you would rather keep the old rule for the easy side, a ceiling read with every card in, it is one sentence in 14.8, and nothing in the game changes either way.
2. **For the DM: 33 or 34 Pips.** You asked for the smallest change, and 33 closes the lone Sling Post on all three seeds and costs the saved mixed builds nothing. 34 leaves one more life of room against a lone Sling Post (12 lives instead of 13 for the saved lone builds), and its first search of 3000 builds on B3's seed found three-star builds (677), where at 33 only the hunts did. But it costs some saved mixed builds a life. Both pass every check of RULES 12.6 (3.2, 3.3). I chose 33. If you prefer the margin, 34 is the same edit with one more Pip, and the rest of this plan holds.

## 7. Suggestions beyond the task

1. **A noise rule in RULES 14.8,** for Bart: a result within one standard error of its bar is reported as at the bar, not tuned. G5 and this plan judged four results that way (`towers_tall` at 75.5%, `mid_eye` at 0.748, b6_toad_glen at 75.4% and mid_hollow at 0.746). Written down, it would save the same question in every pass.
2. **3-5's Twist still repeats its third star** (TUNING_CAMPAIGN.md, suggestion 1): Tier 2 Cap is the rule a player with three stars has already won under. No Longbows would fit "split the defense between two entrances", since a Longbow in the middle column covers both shores. It needs a bot check and Bart's word, so I left it.
