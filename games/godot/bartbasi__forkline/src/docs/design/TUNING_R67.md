# Regions 6 and 7 tuning plan (E6.3 and E7.3)

Owner: game designer. 2026-10-29 (tasks E6.3 and E7.3). Answers the regions 6 and 7 balance report, docs/balance/region6-7-2026-10-29.md (E6.2 and E7.2, played on 3fb2285 with the E5.3 cottage). RULES.md holds the rules and numbers. This file says what changes, why, and exactly what each owner types in. Section 5 lists every text a player sees that changes. The DM may follow its own advice at the expansion's gates (CLAUDE.md, 2026-10-28), so these changes go ahead now, and the DM tells Bart each text change.

Every number of mine below was measured on a clean copy of f31b761 (E5.3, E5.4 and region 8 in) with the balance analyst's tools from the working tree. Nothing in src/ changed between 3fb2285 and f31b761, and nothing that regions 6 and 7 read did either, so the analyst's level numbers stand on f31b761. I checked one: the plain mixed recipe on the 6-4 variant gives a file equal to the analyst's in every field but its run time.

## 1. Decisions

### 1.1 Level 6-4: a late crowd in wave 5, and the third star stays

Wave 5 goes from strength 105 with 40 Pips to strength 160 with 56 Pips. Its 5 Sleepyheads stay. This is the analyst's variant v5 and the DM's call. The third star stays "No tower above tier 2."

Why:

- Under "No tower above tier 2." a lone Sling Post with a Bell, one to three Scarecrows and sometimes a Bakery earned all three stars on one of the two pass seeds: 1216 of 6000 builds (E6.2 section 3). The cap keeps Quickshots out, but no wave tested tier 2 pebbles: every Pip wave was at 125 or less.
- At strength 160 a Pip has 34 health. A tier 2 Sling Post needs 5 pebbles, or 4 with a Scarecrow's 25%. A tier 2 Catapult or a Jam Pot needs 2 pumpkins for the whole crowd, and a tier 2 cottage at a bend pops it in 3 pulses. In wave 5 nobody has the gold for a wall of pebbles yet. This is the late crowd of RULES 12.5, and it also gives the Sleepyheads behind it the level's lesson: keep towers further down the road.
- The plain mixed recipe is not hurt. It still wins 27 of 38 gate placements with a best of 17 lives, and with no gates it now wins with 7 lives instead of 2: a stronger wave also pays more gold.
- It brings the Catapult back. Every one of the 1215 three-star builds the any-tower search found holds a Catapult, and the cottage stands in 693 of them (57%) where it stood in all 1270 before.

Evidence in 3.1.

### 1.2 Level 7-4: a late crowd in wave 5 too, and the third star stays

Decision: waves, not a new third star. Wave 5 goes from strength 105 with two groups of 24 Pips to strength 160 with two groups of 28 Pips (56). Its 8 Skitters stay. The third star stays "Have at most 7 towers." The fallback, "Build no Sling Posts.", is not needed.

Why the waves hold where the analyst saw no lever:

- 7-4's crowds came in waves 7 and 11 (52 Pips at 165 and 64 at 200). By then a lone build has five tier 3 Sling Posts, a Hush Bell and a Scarecrow, and it kept all 20 lives through both. A bigger wave 11 (76 Pips at 210, my variant C) only cost the saved lone builds 3 to 17 lives, and 6 of 28 still earned three stars.
- When wave 5 starts, those builds have spent only 47% to 62% of the gold their final build costs, so most tier 3 paths are still to come. Against 56 Pips at strength 160 every one of the 28 lone three-star builds the pass saved lost the level or kept a single life. The 14 saved any-tower three-star builds all kept three stars with 20 lives, 12 of them with no cottage.
- Two lone Sling Post searches on the two pass seeds, the ones that had found 1200 and 362 three-star builds, then won nothing at all in 2500 builds each (RULES 12.6 lets both stop there). A search with every tower found 1097 three-star builds in 3000.
- The plain mixed recipe keeps everything it had: 6 of 18 placements, a best of 17 lives, and on Relaxed every placement, now with 37 lives with no gates instead of 31. With no gates on Normal it now loses in wave 9 instead of wave 6.
- The same crowd as 6-4's, 56 Pips at 160, makes the two levels one rule in the guide (RULES 12.5), and 7-4 keeps its lesson: the crowd is splash work, and the Yawners still punish towers beside the road.

The gentler variant B (wave 5 at 160 with the counts as built) left the saved lone builds winning with 6 to 10 lives, so its searches would have needed the full 6000 builds and could still have failed. I took the variant with the margin.

Evidence in 3.2.

### 1.3 Runs at tiers 2 and 3: how the bars read

**The miss.** With the default bots, tier 2 wins 25.0% and tier 3 19.4% of the 16 strategies' runs (bar 35 to 55%), and their best strategies 33% and 29% (bar 55 to 75%). Most other bars miss too (E6.2 section 6).

**What a thoughtful player does that the bots did not.** Two habits, both measured by the analyst and both what a player who reads the cards does:

1. **The Scarecrow waits.** It deals no damage. Its fright pays only once several attackers fire into its ring, which is late in a run, as with a Bakery's boost. A bot built the first tower of every kind at once, so it spent its early gold and a good spot on a Scarecrow. The bots already wait until wave 9 for a Bakery (G3, TUNING_RUNS 1.4). They now wait for the Scarecrow too.
2. **Anti-air stays.** Flyers come in every band from band 2 on, and a player reads them in the preview. At tier 0 the bots keep 57% of their attackers able to hit flyers by habit. Each ground tower that joins the pool (cottage, Snow Fort) pushed that share down to 41% at tier 3, and flyers took half the lives of the runs they lost. The floor keeps it at 55%.

These become the bots' defaults from tier 2 on (a request to the balance analyst, 2.3). Measured on f31b761, seeds 1 to 100, Normal, base cards, the 16 strategies:

| Tier | Default bots (E6.2) | With both habits | Best strategy, default / with both | Lives lost to flyers in lost runs, default / with both |
|---|---|---|---|---|
| 2 | 25.0% | 30.8% (SE 1.2) | 33% / 53% | 41.8% / 35.9% |
| 3 | 19.4% | 27.6% (SE 1.1) | 29% / 38% | 49.8% / 43.6% |

The E5.4 data on its own moved nothing measurable at these tiers: with the default bots, seeds 1 to 50 read 25.1% (tier 2) and 22.0% (tier 3) on f31b761 against 24.0% and 21.6% on 3fb2285.

**What is left, and where it comes from.** With the habits on, each tier's own new content meets its bars, apart from b3_sleepy_rows (1.5) and Old Hayrick (1.4). At tier 2, b4_glowing_watch loses 8.2% of the runs that reach it and b5_harvest_siege 2.0%. At tier 3, b3_snowballs loses 9.6%, b4_yawning_watch 9.8% and b5_frost_siege 9.7% (bar 10%), and Snowsnore's packs win 54% and 55% of the runs that start wave 18 (bar 50 to 75%). What loses more runs is older content that did not change. At tier 2, 3 of the 4 packs over the bar are tier 0 packs, and at tier 3, 6 of the 9, every one of them within the bar at tier 0 (B5). The four tier 0 bosses win 21% to 43% of the runs that start wave 18 at tier 3, against 59% to 63% at tier 0 on the same seeds. The difference is on the bots' side. They take a tower card in most drafts and build one tower of every kind they hold, so on 11 or 12 spots they spread over 7.6 kinds of tower at tier 3 against 5.8 at tier 0, and they take a Firework card in the first 9 drafts of 59% of tier 3 runs against 85% at tier 0. With the newest tower cards out of the pool the same seeds read like tier 1: 37.7% at tier 2 and 35.1% at tier 3, against 36.1% at tier 1 (E6.2 section 7). With the habits on as well, and on f31b761, they read 38.6% at tier 2 with a best strategy of 60%, and 40.4% at tier 3 with a best of 54% (seeds 1 to 100, 3.3): inside the bars, apart from tier 3's best strategy, one point under the floor of 55% with a standard error of 5. The re-run on 200 seeds decides that one.

**How the bars read, from now on (RULES 14.8):**

- The same bars at every tier. A player at tier 2 or 3 should find a run as winnable as at tier 0. Each region's pass checks its own tier, and the final pass checks tiers 0 and 4, as before.
- The bots keep the two habits from tier 2 on. Tiers 0 and 1 keep today's bots, so every number of B5 and E5.5 stands.
- When a bar is missed on the hard side, the report gives a second reading beside it: the same seeds with the tower cards of tiers 2 to 4 (Scarecrow, Snow Fort, Moth Lantern) and their perks out of the pool. A thoughtful player can always pass on a tower card, so this reading is a fair floor for them, and RULES 14.8 already reports tower cards in the card experiment rather than holding them to its bar, because what a new tower is worth to the bots depends mostly on where their build rule puts it. If the second reading meets the bar, the bar is met and the game does not get easier: the gap is the bots, and the report names the habit that would close it. If the second reading misses too, the content the tier adds is too hard, and its packs, its boss's packs or its segments are tuned.
- A pack or segment of an earlier tier that meets its bar at its own tier is reported at later tiers, not tuned there. Tier 0's can never change (RULES 14.9), and what changed at the later tier is the bots' towers, not the pack. This matters: with the habits on, even the second reading leaves some tier 0 boss packs under 50% at tiers 2 and 3 (3.3), on samples of 14 to 126 runs a pack.
- A bar missed on the easy side is read with every card in. A thoughtful player wins at least as often as the bots, so too easy for the bots is too easy. That is Old Hayrick (1.4).
- Tier 1 has no second reading. Its tower, the Bramble Cottage, was weak for players as well as bots on its own levels (18% of their three-star builds), so E5.3 made it stronger and tuned it for runs on these bars. The Scarecrow and the Snow Fort are not weak for players (below), so their cost to the bots is the bots'.

**What does not change, and why:**

- **The Scarecrow and the Snow Fort, their cards and perks.** In the campaign both are strong choices: the Scarecrow stands in 11% to 83% of the three-star builds on 6-3 to 7-5, the Snow Fort in 76% to 98% on 7-2 to 7-4. Ten more points of fright moved the run bots by 1.9 points, inside the noise (E6.2 section 7). A Snow Fort with 1.5 times the damage would take over region 7's campaign to fix how the bots place it.
- **Run strengths.** The second reading puts tiers 2 and 3 where tier 1 is. So their creatures, packs and maps do not make runs harder as a whole, and lower strengths would make every run easier for a gap that is the bots' spending.
- **Tier 0.** Nothing here touches a tier 0 file or the tier 0 golden run, and both habits are off below tier 2.

**The next bot habits to try** (for the analyst, not defaults yet): a bot that keeps to a few kinds of tower from tier 2 on, for example one that takes a tower card only while it holds fewer than 6 kinds, the most tier 0 offers; a Scarecrow on the spot whose ring covers the road that most of the bot's attackers reach; and a Snow Fort at the end of a straight road, as `bramble_fit` does for the cottage. Each is what the cards and hints tell a player. If they bring the first reading into the bars, the second reading is no longer needed.

### 1.4 Old Hayrick's run packs: a stronger boss wave

The boss wave of b6_hayrick_field goes from strength 140 to 175, and that of b6_hayrick_barn from 130 to 165. Old Hayrick then has 4550 health and gets up with 2275 in the first, and 4290 and 2145 in the second. This is the analyst's +35 and the DM's call, and my check puts both near the middle of the bar.

Why:

- It was the easiest boss by far. Forced onto 100 seeds at tier 2, 82.4% and 81.2% of the runs that start wave 18 won (bar 50 to 75%), while every other boss sat under the bar at these tiers (E6.2 section 8).
- Forced onto seeds 1 to 50 at tier 2 with the bots' new habits, b6_hayrick_field at 175 wins 64.5% of the 606 runs that start wave 18, and b6_hayrick_barn at 165 wins 66.1% of 617. Both are inside the bar, near its middle. The habits barely move Old Hayrick: the same seeds with the old bots read about 65% at those strengths, between the analyst's points at +0 and +40.
- At tier 3, on natural seeds with the habits, it won 88% (field) and 81% (barn) of the runs that started wave 18 as built, against 72% and 84% at tier 2. Those samples are 47 to 82 runs a pack, so the re-run forces both packs at tiers 2 and 3.
- The bar for a boss won too often is read with every card in (1.3), so these numbers decide.

Its card line does not change. Snowsnore's packs stay (1.7).

### 1.5 The first waves of b3_sleepy_rows and b3_snowballs

Both first waves go from 12 Scamps and 16 Pips to 8 Scamps and 10 Pips. The new creature stays first, at full count: 5 Sleepyheads and 6 Snowrollers.

Why:

- These two packs are copies of b3_mossy_ruts as E5.1 built it, with the Mossbud swapped for the new creature, and they lose their runs where it did: in the first wave, where the new creature, a pack of Scamps and a Pip crowd come one after another in wave 7 (E6.2 6.2). E5.4 fixed b3_mossy_ruts the same way, with fewer Scamps and Pips and the 4 Mossbuds kept.
- Forced onto 100 seeds with the bots' new habits, b3_sleepy_rows loses 16.9% of the runs that reach it as built and 7.1% with this wave; b3_snowballs 4.6% with this wave (bar 10%). Evidence in 3.4.
- I keep the 5 Sleepyheads. Cutting them to 3 as well gives 4.1%, but the pack is where a run first shows the Sleepyhead, and 7.1% already meets the bar with room. If the re-run reads it above 10%, the Sleepyheads go to 3 next (6.5% even with the old bots).

### 1.6 The Bramble Cottage watch item: no trim

The Holly Crown stays at 24. The cottage's numbers do not change.

The watch item of RULES 5.10, as I wrote it in E5.3, is triggered: the cottage stands in 98% to 100% of the three-star builds on 8 of the 12 levels of regions 6 and 7. I do not take the trim, for four reasons:

- **It is not needed.** Searches that left it out still found 455 to 1370 three-star builds in 3000 on every one of those levels (E6.2 5.2). The rarest is 6-4 (455 against 1270), and the 6-4 crowd of 1.1 brings its share there down to 57%.
- **The trim would miss most of the share.** On 6-1, 6-4 and 7-5 the third star caps towers at tier 2, so no Holly Crown stands there, yet the cottage is in 98% to 100% of their builds. The share comes from the cheap tier 1 and 2 cottage at the bends that bridges, loops and slides make.
- **The runs need it.** Its card is now worth about what the other two cards offered are (-1.0 at tier 2, -1.9 at tier 3, against -7.2 before E5.3), and tiers 1 to 3 are all under their bars.
- **It keeps its weakness.** It cannot hit flyers, which cost 18 to 56 lives on every level of regions 6 and 7, so it is never a lone answer.

A share near 100% says the search likes a cheap tower that suits these roads. The watch item now measures need instead (RULES 5.10): if a search without the cottage finds fewer than a quarter as many three-star builds as a search with every tower, on two or more levels of one region, the Holly Crown comes down to 20 first, then tier 1 to 8, with runs measured first. Region 8's pass (E8.2) and the final pass (B7) read it.

### 1.7 Not changed, on purpose

- **Every other third star, wave, hint and Twist of regions 6 and 7.** They passed every bar of RULES 12.6 (E6.2 section 2).
- **Snowsnore's packs** (110 and 100): 56.6% and 55.7% with the default bots, 54% and 55% with the habits. Both in the bar.
- **The bridge stacks.** Forced onto 100 seeds they lose 4.9% to 10.6% by wave 6 (E6.2 6.1). The re-run reads them again with the habits.
- **6-6 and 7-6 Double Trouble** (2 of 1500, and 0 of 1500 then 2376 and 2286 of 6000). Narrow but won, as 5-6's was.
- **6-3**, the tightest level of region 6 before its boss (9 lives, 12 of 38 placements). Inside every bar.
- **Region 8.** The DM noted that 8-6 is easy since the E8.1d Twist fix: every gate placement wins on Normal. Region 8's pass (E8.2) measures it, and its tuning (E8.3) decides. Nothing in this step touches region 8.

## 2. Changes per owner

### 2.1 Game designer (done in this step)

- RULES.md: the change note; 5.10 (the cottage watch item now measures need); 12.4 (a paragraph on regions 6 and 7); 12.5 (where a late crowd bites hardest); 14.3 (Old Hayrick's two boss waves); 14.8 (each region's tier is checked against the same bars, the two bot habits from tier 2 on, and the second reading).
- This file.
- data/stats/: no change. No tower, creature or rule number moves, so the campaign outside 6-4 and 7-4 is untouched.

### 2.2 Level designer (E6.4 and E7.4)

The DM passes these on. The exact before and after lines are in the session's scratch folder as e67_handoff.md, section 1. In short:

- data/levels/r6_l4.json, wave 5: strength 105 to 160, Pips 40 to 56.
- data/levels/r7_l4.json, wave 5: strength 105 to 160, each Pip group 24 to 28.
- data/segments/packs.json: b3_sleepy_rows wave 1 and b3_snowballs wave 1, Scamps 12 to 8 and Pips 16 to 10; the boss wave of b6_hayrick_field, strength 140 to 175, and of b6_hayrick_barn, 130 to 165.

No map, hint, highlight, third star, Twist, tower list or starting gold changes, and no test of tests/levels or tests/run needs a change (3.6).

### 2.3 Balance analyst

Section 2 of e67_handoff.md. In short:

1. Make `scarecrow_from=9` and `air_floor=55` the bots' defaults whenever the run's tier is 2 or more, and keep them off at tiers 0 and 1.
2. Once E6.4 and E7.4 are in: the RULES 12.6 checks of 6-4 and 7-4 and their most crowded wave; runs and the daily at tiers 2 and 3 on seeds 1 to 200 with the second reading of RULES 14.8 beside every bar missed on the hard side; the forced packs of 1.4 and 1.5 and Snowsnore's two packs; the bridge stacks again.
3. Optional what-ifs, if a tier still misses in the first reading: the habits named at the end of 1.3.

### 2.4 Everyone else

The roguelite engineer has nothing to do: no card, run.json or src/run change. The DM gets no test patch: no test outside tests/levels and tests/run reads these values, and those pass with the edits as they are (3.6).

## 3. Evidence

All of mine on a clean copy of f31b761 in the session's scratch folder, with the working tree's tools/balance, from its root after `godot --headless --path . --import`. Level variants came in through `level_file=`, so no data file of the copy changed while the bots played. Outcomes are builds lost / won with 1, 2 and 3 stars.

### 3.1 Level 6-4

The searches are the analyst's (E6.2 4.1 and section 3, raw files `whatif/r6_l4_v5_*` and `r6_l4_*`). The plain recipe on v5 I played again on f31b761: its file equals the analyst's in every field but its run time. The Twist and random play on v5 are mine.

| Check | As built: wave 5 is 40 Pips at 105 | Now: wave 5 is 56 Pips at 160 |
|---|---|---|
| Plain recipe, Normal | 27 of 38 placements, best 17 lives (1,3 + 3,8 + 5,8), no gates won with 2 | 27 of 38, best 17 (the same gates), no gates won with 7 |
| Plain recipe, Relaxed | 38 of 38, best 40, no gates 36 | 38 of 38, best 40, no gates 39 |
| Any tower, 3000 builds (seed) | 1270 three-star builds, first at 210 (826400) | 1215, first at 1007 (991400) |
| Lone Sling Post, first seed | 836401: no three-star build in 6000 (2797 wins, every one above the cap) | 991401: no win in 2500 (stopped) |
| Lone Sling Post, second seed | 866401: **1216** three-star builds in 6000, first at 3034 | 866401: no three-star build in 6000 (2343 wins) |
| Random play, three stars | 0.1% of 750 | 0.1% of 750 (21 wins) |
| Twist (No Selling), plain recipe | 27 of 38 | 27 of 38 |
| Largest wave | 54 | 61 |

In the 1215 three-star builds of the variant: a Catapult in all 1215, a Firework Tower in all, a Longbow Loft in 1213, a Bell in 1076, the cottage in 693, a Sling Post in 622, a Scarecrow in 299, a Bakery in 258.

### 3.2 Level 7-4

First a cheap screen, `mode=replay`: the strategies the pass saved (14 from each lone Sling Post search that found three-star builds, 14 from the any-tower search) and the plain recipe at all 18 gate placements, played again on four wave variants of mine.

| Variant | Change | The 28 saved lone Sling Post three-star builds | The 14 saved any-tower three-star builds | Plain recipe, Normal |
|---|---|---|---|---|
| As built | | all 28 three stars, 20 lives | all 14 three stars, 20 lives | 6 of 18, best 17 |
| **A** | **wave 5: strength 160, Pips 28 + 28** | **6 win with 1 life, 22 lose in wave 5. None three stars** | **all 14, 20 lives (12 have no cottage)** | **6 of 18, best 17** |
| B | wave 5: strength 160, Pips 24 + 24 as built | 26 win with 1 to 10 lives, 2 lose. None three stars | all 14, 20 lives | 13 of 18, best 17 |
| C | wave 11: strength 210, Pips 38 + 38 | all 28 win with 3 to 17 lives; 6 three stars | all 14, 17 to 20 lives | 6 of 18, best 17 |
| D | A and C | all 28 lose (wave 5 or 11) | all 14, 17 to 20 lives | 6 of 18, best 17 |

Then the full checks of RULES 12.6 on A:

| Check | As built (E6.2) | A |
|---|---|---|
| Plain recipe, Normal | 6 of 18, best 17 (1,3 + 5,7), no gates lost in wave 6, worst lost in wave 6 | 6 of 18, best 17 (1,3 + 5,7), no gates lost in wave 9, worst lost in wave 5 |
| Plain recipe, Relaxed | 18 of 18, best 37, no gates 31 | 18 of 18, best 37, no gates 37 |
| Any tower, 3000 builds (seed) | 968 three-star builds, first at 593 (827400) | 1097, first at 1025 (1008400); outcomes 1443 / 349 / 111 / 1097 |
| Lone Sling Post, seed 837401 | **1200** three-star builds in 6000, first at 2596 | no win in 2500 (stopped); the best play lost in wave 5 |
| Lone Sling Post, seed 867401 | **362** in 6000, first at 4646 | no win in 2500 (stopped); the best play lost in wave 5 |
| Random play, three stars | 0.1% of 750 (51 wins) | 0.1% of 750 (48 wins) |
| Twist (Thick Shells) | plain 3 of 18, best 14; search 823 of 1500 won | plain 3 of 18, best 14; search 776 of 1500 won (seed 877400) |
| Largest wave | 66 (wave 11) | 66 (wave 11); wave 5 has 64 |

What A's 1097 three-star builds hold: a cottage in all of them (Holly Crown 572, Wild Bramble 534), a Sling Post in 1095, a Bell in 922, a Scarecrow in 637, a Snow Fort in 229, a Catapult in 174. That search settled on one family of builds. The pass's own family, Snow Forts and Prize Pumpkins with no cottage, still earns three stars on A (12 of the 14 saved builds in the screen), so the cottage is not needed there (1.6).

### 3.3 Runs at tiers 2 and 3

`runs.gd mode=rates`, Normal, base cards, the 16 strategies, `leaks=1`. "Habits" is `scarecrow_from=9 air_floor=55`. "Second reading" adds `pool=minus:tower_scarecrow,big_hat` at tier 2 and `pool=minus:tower_scarecrow,big_hat,tower_snow_fort,packed_snow` at tier 3. Rows marked E6.2 are the analyst's, on 3fb2285.

| Tier | Bots and pool | Commit | Seeds | The 16 together (SE) | Best strategy | Lives lost to flyers, lost runs |
|---|---|---|---|---|---|---|
| 0 | default | E6.2 | 1 to 100 | 50.1% (1.2) | towers_tall 75% | 38.8% |
| 1 | default | E6.2 | 1 to 100 | 36.1% (1.2) | towers_tall 51% | 47.8% |
| 2 | default | E6.2 | 1 to 100 | 25.0% (1.1) | towers_wide 33% | 41.8% |
| 2 | default | f31b761 | 1 to 50 | 25.1% (1.5) | towers_tall_early 38% | 47.4% |
| 2 | habits | f31b761 | 1 to 100 | **30.8% (1.2)** | **towers_wide 53%** | 35.9% |
| 2 | second reading, default bots | E6.2 | 1 to 100 | 37.7% (1.2) | towers_tall 54% | 43.4% |
| 2 | **second reading, habits** | f31b761 | 1 to 100 | **38.6% (1.2)** | **towers_wide 60%** | 30.3% |
| 3 | default | E6.2 | 1 to 100 | 19.4% (1.0) | towers_tall_early 29% | 49.8% |
| 3 | default | f31b761 | 1 to 50 | 22.0% (1.5) | random_wide 34% | 49.1% |
| 3 | habits | f31b761 | 1 to 100 | **27.6% (1.1)** | **random_tall 38%** | 43.6% |
| 3 | second reading, default bots | E6.2 | 1 to 100 | 35.1% (1.2) | random_wide 47% | 48.0% |
| 3 | **second reading, habits** | f31b761 | 1 to 100 | **40.4% (1.2)** | **towers_wide 54%** | 34.5% |

With the habits, the runs that start wave 18 won, by boss (tier 2 / tier 3): Burrowbelly 36% / 37%, Grumblesack 33% / 21%, Ironshell 33% / 24%, Moon Moth 47% / 43%, Old Tusk 38% / 32%, Old Hayrick 80% / 85%, Snowsnore - / 54%. In the second reading with the habits: Burrowbelly 38% / 44%, Grumblesack 44% / 28%, Ironshell 35% / 34%, Moon Moth 69% / 64%, Old Tusk 43% / 48%, Old Hayrick (as built) 80% / 95%, Snowsnore - / 59%. At tier 0 the four tier 0 bosses won 59% to 63% on the same seeds. The anti-air floor moves these both ways: with it alone at tier 2 the Moon Moth went from 35% to 49%, and Grumblesack, Ironshell and Old Tusk went down 6 to 10 points (E6.2's `air` files), because the floor builds anti-air towers where ground towers would have stood.

What the second reading still misses, seeds 1 to 100 (`runs_summary.gd part=fair` and `part=boss`), with the tier each item belongs to:

- Tier 2: the boss packs of Burrowbelly (b6_burrow_mist 26%, tier 1), Grumblesack (32%, 49.5%), Ironshell (20%, 43%) and Old Tusk (b6_tusk_charge 38%) (tier 0); Old Hayrick's (78%, 84%, fixed in 1.4); the segments top_meet (0.750), top_pair, mid_eye (tier 0) and mid_tunnel (tier 1), and mid_planks (0.729, tier 2, which meets the bar in the first reading at 0.915); b2_slow_and_fast (10.1%, tier 0) and b3_sleepy_rows (15.1%, fixed in 1.5).
- Tier 3: the same tier 0 and tier 1 boss packs; Old Hayrick's; the segments mid_cart and mid_planks (tier 2); b4_quiet_moths and b5_broken_bars (tier 0), b4_glowing_watch (10.7%, tier 2) and b3_snowballs (10.9%, fixed in 1.5). Tier 3's own segments and packs meet their bars, and Snowsnore's packs win 59%.

So every bar of each tier's own content is met in one reading or the other, once 1.4 and 1.5 are in. What is left is older content at a later tier, which RULES 14.8 now reports there.

With the habits, the packs of bands 1 to 5 that lose more than 10% of the runs that reach them (natural seeds 1 to 100, `runs_summary.gd part=fair`):

- Tier 2: b3_sleepy_rows 21.1% (tier 2), b4_moth_flight 15.1%, b4_field_nurses 14.6%, b4_split_watch 11.3% (tier 0). Every other pack meets the bar, b4_glowing_watch (8.2%) and b5_harvest_siege (2.0%) included.
- Tier 3: b4_moth_flight 17.8%, b4_quiet_moths 14.4%, b5_broken_bars 13.7%, b4_long_watch 12.6%, b5_siege 11.0%, b4_field_nurses 10.4% (tier 0), b4_misty_watch 11.0% (tier 1), b4_glowing_watch 12.2% and b3_sleepy_rows 12.0% (tier 2). Tier 3's own packs meet it: b3_snowballs 9.6%, b4_yawning_watch 9.8%, b5_frost_siege 9.7%.

How many kinds of tower a run ends with, on average, all 16 strategies: tier 0 5.8, tier 1 6.4, tier 2 6.7 (7.1 with the habits), tier 3 7.3 (7.6 with the habits). The Firework card is taken in the first 9 drafts of 85% of tier 0 runs, 76% at tier 1, 65% at tier 2 and 58% at tier 3 (59% with the habits), though it is offered in 86% or more at every tier.

The named strategies, win rate by tier (E6.2's files, and mine for the habits at tier 3), show the same thing: the strategies that take every tower card fall the most, and with the new cards out of the pool they come back.

| Strategy | Tier 0 | Tier 1 | Tier 2 | Tier 2, no Scarecrow card | Tier 3 | Tier 3, neither new card | Tier 3, habits |
|---|---|---|---|---|---|---|---|
| towers_tall | 75 | 51 | 31 | 54 | 24 | 46 | 35 |
| towers_wide | 59 | 37 | 33 | 43 | 22 | 42 | 37 |
| economy_tall | 57 | 42 | 26 | 43 | 22 | 38 | 24 |
| random_tall | 55 | 34 | 29 | 41 | 24 | 38 | 38 |
| risk_tall | 44 | 28 | 11 | 29 | 14 | 23 | 18 |

### 3.4 The first waves of b3_sleepy_rows and b3_snowballs

Forced onto run seeds 1 to 100 at their own tier, the 16 strategies, stopped when the pack is done (`pack=ID stop=9`), the first wave changed in memory (`tweak=pack_count:ID;1;ENEMY;N`). "Lost inside" is the share of the runs that reach the pack's first wave and are lost before its last; the number in brackets is how many of them are lost in its first wave.

| Pack (tier) | First wave | Default bots (E6.2) | With the habits (mine) |
|---|---|---|---|
| b3_sleepy_rows (2) | 5 Sleepyheads, 12 Scamps, 16 Pips (as built) | 24.4% (284) | 16.9% (212) |
| b3_sleepy_rows (2) | **5 Sleepyheads, 8 Scamps, 10 Pips (chosen)** | 12.4% (102) | **7.1% (71)** |
| b3_sleepy_rows (2) | 3 Sleepyheads, 8 Scamps, 10 Pips | 6.5% (44) | 4.1% (24) |
| b3_snowballs (3) | 6 Snowrollers, 12 Scamps, 16 Pips (as built) | 14.4% (136) | 9.6% on natural seeds |
| b3_snowballs (3) | **6 Snowrollers, 8 Scamps, 10 Pips (chosen)** | 6.6% (35) | **4.6% (21)** |

### 3.5 Old Hayrick's packs

Forced at tier 2 (`pack=ID`), Normal, base cards, the 16 strategies, the boss wave's strength set in memory (`tweak=pack_strength:ID;N`). "Won" is the share of the runs that start wave 18. The default rows are the analyst's (E6.2 section 8); I also give their seeds 1 to 50 alone, the seeds I played.

| Pack | Boss wave strength (Old Hayrick's health) | Bots | Seeds 1 to 100: started, won | Seeds 1 to 50: started, won |
|---|---|---|---|---|
| b6_hayrick_field | 140 (3640) | default | 876, 82.4% | 448, 84.8% |
| b6_hayrick_field | 180 (4680) | default | 876, 57.9% | 448, 62.5% |
| b6_hayrick_field | 220 (5720) | default | 876, 35.0% | 448, 37.1% |
| b6_hayrick_field | **175 (4550)** | **habits** | | **606, 64.5%** |
| b6_hayrick_barn | 130 (3380) | default | 917, 81.2% | 464, 81.5% |
| b6_hayrick_barn | 170 (4420) | default | 917, 57.8% | 464, 61.9% |
| b6_hayrick_barn | 210 (5460) | default | 917, 35.0% | 464, 37.9% |
| b6_hayrick_barn | **165 (4290)** | **habits** | | **617, 66.1%** |

More runs reach wave 18 with the habits (606 and 617 of 800, against 448 and 464), which is the habits at work in waves 1 to 17.

### 3.6 Tests

On a second clean copy of f31b761 with the working tree's tools/balance and exactly the edits of e67_handoff.md section 1 applied to data/levels/r6_l4.json, data/levels/r7_l4.json and data/segments/packs.json (Old Hayrick at 175 and 165): `godot --headless --path . --script res://tests/run_tests.gd` gives "Ran 1633 tests in 116 files: 1633 passed, 0 failed." with exit code 0. The tier 0 golden run (tests/run/test_tier_zero.gd) is among them. No doc is read by a test, and no test needed a change.

The level smoke test in that run plays the plain mixed recipe on every level. With the edits, 6-4 wins with 17 lives in 6.6 minutes and 7-4 with 17 lives in 7.0 minutes, as before (E6.2: 17 and 17, 6.6 and 7.1 minutes). Every other level of regions 6 and 7 plays as E6.2 found.

### 3.7 How to repeat

From the root of a clean copy of f31b761 with the working tree's tools/balance, after `godot --headless --path . --import`. VARIANT is a copy of data/levels/r7_l4.json with wave 5 edited as in e67_handoff.md 1.2; the 6-4 variant is the analyst's tools/balance/variants/r6_l4_v5.json. FROM is the analyst's three saved search files of 7-4 (`r7_l4_solo_sling_post_a.json`, `r7_l4_solo_sling_post_b_full.json`, `r7_l4_search_any.json` of raw/2026-10-29-e67) and `plain`.

```
godot --headless --path . --script res://tools/balance/run.gd -- mode=replay level=r7_l4 level_file=VARIANT from=FROM pick=all out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r7_l4 level_file=VARIANT out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r7_l4 level_file=VARIANT seed=837401 evals=6000 stop_dry=2500 only=solo:sling_post out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r7_l4 level_file=VARIANT seed=1008400 evals=3000 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r7_l4 level_file=VARIANT twist=1 seed=877400 evals=1500 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=spread level=r7_l4 level_file=VARIANT seed=817400 n=250 out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 tier=2 leaks=1 scarecrow_from=9 air_floor=55 out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=minus:tower_snow_fort,packed_snow,tower_scarecrow,big_hat relaxed=0 tier=3 leaks=1 scarecrow_from=9 air_floor=55 out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=100 pool=base relaxed=0 tier=2 pack=b3_sleepy_rows stop=9 scarecrow_from=9 air_floor=55 "tweak=pack_count:b3_sleepy_rows;1;pip;10,pack_count:b3_sleepy_rows;1;scamp;8" out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 tier=2 pack=b6_hayrick_field scarecrow_from=9 air_floor=55 "tweak=pack_strength:b6_hayrick_field;175" out=OUT.json
```

The other jobs differ only in seed, `first`, tier, pool, pack or tweak. The second 7-4 lone search is seed 867401; the runs' second halves are `first=51`. The tables add up the files' `rows`, `outcomes`, `three_star_found` and `three_star_builds_using`; the packs and segments tables are `runs_summary.gd part=fair` and `part=boss` on the rates files renamed `rates_base_r0_N.json`. All of it took about 11 hours of jobs in 2 hours, with at most 6 of mine at a time beside 10 to 14 of other agents'.

## 4. For Bart

These change what Bart approved, so the DM tells him. Under the DM's rule of 2026-10-28 they go ahead now.

1. **Levels 6-4 and 7-4: wave 5 is a big, tough crowd of Pips.** 56 Pips at strength 160 on each, where 6-4 had 40 and 7-4 had 48 at strength 105. Why: on both, Sling Posts alone with Bells could earn all three stars. Wave 5 comes before the gold for tier 3 towers, so the crowd needs a Catapult, a Snow Fort or a Bramble Cottage. The third stars stay as they are.
2. **Old Hayrick is tougher in runs.** Its two run boss waves give it 4550 and 4290 health instead of 3640 and 3380, and it gets up with half of that. Why: in runs it was the easiest boss by far, beaten in about 4 of 5 runs that reach it, where the target is about 3 in 5. It is now about 2 in 3. The campaign's 6-6 does not change.
3. **Two run packs start gentler.** The first wave of the Sleepyhead pack and of the Snowroller pack brings 8 Scamps and 10 Pips instead of 12 and 16. Why: these two packs lost more of the runs that reached them than the 10% the run targets allow, most of them in that first wave.
4. **The run bots now play the Scarecrow and flyers the way a careful player does,** and the run targets are read with that (RULES 14.8). Where the bots still miss a target because they take and build every new tower they are offered, the same runs are checked again with the newer tower cards left out, since a player can always pass on a card. This changes nothing in the game.
5. **The Bramble Cottage stays as it is.** It is in nearly every best build of regions 6 and 7, but good builds without it exist on every level.

No hint, third star, Twist, card line, run card text or creature line changes.

## 5. Every text a player sees that changes

The previews and panels build their numbers from the data (contract 2.7), so the UI changes nothing.

| Where | Before | Now |
|---|---|---|
| 6-4 Nodding Orchard, wave 5 preview | 40 Pips, 5 Sleepyheads | 56 Pips, 5 Sleepyheads |
| 6-4, wave 5 creature panels | Pip 22 health, Sleepyhead 95 | Pip 34 health, Sleepyhead 144 |
| 7-4 Drowsy Huts, wave 5 preview | 24 Pips (A), 24 Pips (B), 8 Skitters (B) | 28 Pips (A), 28 Pips (B), 8 Skitters (B) |
| 7-4, wave 5 creature panels | Pip 22 health, Skitter 32 | Pip 34 health, Skitter 48 |
| Run previews and creature cards, Old Hayrick's health in its two run packs (boss wave) | 3640, then 1820 after its nap (b6_hayrick_field); 3380, then 1690 (b6_hayrick_barn) | 4550, then 2275 (b6_hayrick_field); 4290, then 2145 (b6_hayrick_barn) |
| Run preview of b3_sleepy_rows' first wave | 5 Sleepyheads, 12 Scamps, 16 Pips | 5 Sleepyheads, 8 Scamps, 10 Pips |
| Run preview of b3_snowballs' first wave | 6 Snowrollers, 12 Scamps, 16 Pips | 6 Snowrollers, 8 Scamps, 10 Pips |

Bounties and clear bonuses of the changed waves follow their strength (RULES 6.4): wave 5 on 6-4 and 7-4 pays more, and Old Hayrick's packs pay more for their boss wave.

## 6. Open questions

1. **For the DM: the second reading of RULES 14.8, and older packs at later tiers.** The second reading decides whether a tier that misses a bar on the hard side needs a game change. I made it the rule because it follows what 14.8 already says about tower cards, and because the evidence points at the bots' spending rather than the tiers' content (1.3). It means tiers 2 and 3 can pass with the first reading still under the bars. The same goes for packs and segments of an earlier tier: they are held to their bars at their own tier and reported at later ones. For the final pass that means tier 4 holds the run-wide bars and tier 4's own packs, while the tier 0 boss packs are held at tier 0, where they meet their bar today. If the DM would rather hold the first reading and every pack to the bars at every tier, the way there is bot habits (2.3), not easier runs: tier 0's packs cannot change without changing tier 0, and the final pass at tier 4, with 9 tower cards, will need the habits most.
2. **For the DM: tier 1.** The habits stay off at tier 1 so that E5.5 measures what E5.3 planned. At tier 1 the anti-air floor made no difference (-0.2 points) and there is no Scarecrow, so turning them on there later would change little. I suggest leaving tier 1 as it is.

## 7. Suggestions beyond the task

1. **6-2's third star.** The level that brings the Scarecrow has it in only 31 of its 976 three-star builds (3%), under "Have at most 6 towers.": with six towers, a tower that deals no damage is hard to afford. It passes every bar and was not part of this task, so I left it. If a playtest finds the Scarecrow lesson falls flat there, the next third star to measure is one that does not count towers and does not repeat its Twist (No Bells).
2. **Draft weights at tier 4.** At tier 4, nine tower cards share the tower weight of 30 that five share at tier 0, so each is offered about half as often. If the final pass finds tier 4 short even in the second reading, a tower weight that grows with the tier's tower cards (30 at tier 0, 6 more for each tower card a tier adds) would keep each card as common as at tier 0 and leave tier 0 exactly as it is. It is a rule change for Bart, so I only name it.
