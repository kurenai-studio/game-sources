# Region 8 tuning plan (E8.3), with 5-6's third star

Owner: game designer. 2026-10-30 (task E8.3, and the 5-6 follow-up of E5.5). Answers the regions 5 and 8 balance report, docs/balance/region5-8-2026-10-30.md (E5.5 and E8.2, played on f31b761). RULES.md holds the rules and numbers. This file says what changes, why, and exactly what each owner types in. Section 5 lists every text a player sees that changes. The DM may follow its own advice at the expansion's gates (CLAUDE.md, 2026-10-28), so these changes go ahead once the DM accepts them, and the DM tells Bart each text change.

Every number of mine below was measured on a clean copy of 47ccda1 (E6.3 and E7.3 in) with the balance analyst's tools from the working tree. Those tools are byte for byte the ones the DM then committed in 7722851, which changed nothing else the bots read, so the numbers hold on 7722851 too. Between f31b761 and 47ccda1 only 6-4, 7-4, three run packs and one UI file changed, so the analyst's numbers for 5-6, 8-4 and 8-6 stand on 47ccda1. I checked one: the plain recipe on the analyst's `b55` variant of 8-6 gives a file equal to the analyst's in all 92 plays, the saved battle's digest included.

## 1. Decisions

### 1.1 Level 5-6: "Build no Sling Posts."

The DM's call, confirmed. data/levels/r5_l6.json `star3` becomes `{"kind": "tower_ban", "tower": "sling_post"}`. The hint and the highlight stay.

Why, from the analyst's numbers (E5.5 sections 4 and 4.1):

- Under "Have at most 6 towers." a lone Sling Post with Bells and a Bakery found 650 three-star builds in 6000 on one pass seed.
- Six was already the lowest limit that anyone can meet. At 5 towers, at 4, and with a tier 2 cap, searches that may use every tower found no three-star build in 3000, and at 5 none in two more of 6000 (no win at all inside the limit). So no tower limit closes the lone Sling Post and stays reachable.
- With the Sling Post banned, a search that may use the other towers found 1130 three-star builds in 3000, the first at build 765 (seed 1008600). The Sling Post can never earn the star, so it needs no lone search. Every other attacking tower needs none either: flyers cost 56 lives and walkers 325 on 5-6, so a tower that cannot hit one of them can never keep 15 lives (RULES 12.6).
- The hint still reads right. A Bramble Cottage stands in 1127 of those 1130 builds, a Longbow Loft and a Firework Tower in all of them: "Keep Brambles near" is the plan, Longbow Lofts take the boss (a Giant Bow in 785 of the builds), and Fireworks take the flyers that pebbles took before.
- Random play cannot reach the 10% bar. Random strategies won 1 of 750 Normal plays on 5-6 (E5.5), so at most that one could earn three stars under any rule.
- RULES 12.5 asks only that neighbors differ. 5-4 has the same ban, with 5-5 between them, and 5-6's Twist is Double Trouble.

Region 5's third stars are now a tower limit, a tier cap, a tower limit, a ban, a kinds limit and a ban.

### 1.2 Level 8-6: a stronger Glimmertoad, more Dusk Moths, and two Glimmertoads 12 seconds apart in the Twist

Three edits to data/levels/r8_l6.json:

1. Wave 12, the boss wave: strength 50 to 55. Glimmertoad has 1980 health instead of 1800.
2. Wave 12's one group, the Glimmertoad: gap (`every_ms`) 1000 to 12000. With one Glimmertoad this changes nothing. In Double Trouble the second one comes 12.0 s after the first.
3. Wave 9: Dusk Moths 3 to 5.

What it does, with the plain mixed recipe (details in 3.1 and 3.2):

| | As built | Now |
|---|---|---|
| Normal: placements won | 46 of 46 | 20 of 46 |
| Normal: best | 20 lives, three stars (4,4 + 3,5) | 18 lives, two stars (4,4 + 3,9) |
| Normal, no gates | won, 7 lives | lost in wave 12 |
| Relaxed | 46 of 46, no gates 40 lives | 46 of 46, no gates 40 lives |
| Twist (Double Trouble): placements won | 1 of 46 | 9 of 46 |
| Lone Sling Post, seeds 838601 / 868601 | 323 three-star builds / none | no win in 2500 builds / no win in 2500 builds |
| Any tower: three-star builds in 3000 | 1107 (first at 1040) | 1007 (first at 933) |
| Twist search, 1500 builds | none won (and none in two of 6000) | none won; then 2695 and 2788 wins in two of 6000 |

Why each edit:

- **Strength 55: the boss is the finale.** At 50 Glimmertoad never threatened the base: every gate placement won, and its wave cost none of them a life. At 55 the plain mixed recipe wins exactly where its gates close the stump (4,4) or the short road to the base (3,9), 20 placements of 46, about what 7-6 (24 of 47) and 6-6 (20 of 35) ask. That is region 8's own lesson, close the way into the stump (8-1), deciding its last level. Strength 55 also closes the lone Sling Post: a build of Sling Posts with Bells, Scarecrows and Bakeries cannot pop a Glimmertoad of 1980 health. The analyst's `b55` found no win at all in 2500 builds on either pass seed, and the Dusk Moths of edit 3 make it harder still.
- **The gap: the Twist apart from Normal.** Double Trouble doubles only the final wave, and on 8-6 that wave is the boss alone, because a boss's first wave holds only the boss (RULES 12.5). So Normal and the Twist differ only in how the two Glimmertoads come. Glimmertoad hops 3 tiles every 6 s and no slow holds it. Two that come 1.0 s apart cross the defense together, and every tower aiming at First shoots the front one while the second walks through. That is why the Twist was won at one placement while Normal was won at all 46, and why every harder Normal broke the Twist (E8.2 5.2). With the second Glimmertoad 12 s behind, the first is down or nearly down when the second reaches the strongest towers. The gap changes nothing on Normal, where the group holds one boss.
- **Why 12 seconds.** At strength 55 the plain mixed recipe wins the Twist at 1 placement with a gap of 8 s, 5 with 10 s, 9 with 12 s and 14 s, and 20 with 16 s or 20 s. From 16 s on the two Glimmertoads are fought one after the other, and the Twist is exactly as hard as Normal for the recipe. 12 s keeps it clearly harder than Normal (9 placements against 20), in the middle of a flat stretch (12 s and 14 s give the same), so it does not hang on one tick of timing. For comparison, the plain recipe wins the other Double Trouble Twists at 16 of 47 placements on 7-6 (Normal 24), 12 of 20 on 4-6 (Normal 16), 20 of 35 on 6-6 (Normal 20) and 1 of 23 on 5-6 (Normal 1). Next to its own Normal, 8-6's stays the hardest of them, as the last one should.
- **Dusk Moths: lives that gates cannot save.** At every boss strength the best placement kept all 20 lives, because gates decide every walker wave on this map (E8.2 5.2: "Nothing I tried makes the plain recipe lose lives with a good gate"). Flyers ignore gates. Wave 9's armored flyers are the place: two more cost the best placement 2 lives, and every winning placement 2 to 4. A Moth Lantern on their line, ahead of the Giant Bow, is the answer: region 8's lesson, the one its hint names for Glimmertoad's Flitters. With 4 Dusk Moths instead of 5 two placements still kept all 20 lives. Ten Flitters in place of wave 11's six cost nothing more, so that wave stays.

What it does not do. The boss wave itself still costs a winning build no lives with the plain recipe. A Glimmertoad that gets through costs all 20 lives, so on Normal it is popped or the level is lost, and its 6 Flitters, at strength 55, have 17 health and pop at once. Other boss levels are the same: on 1-6, 2-6, 3-6, 5-6, 6-6 and 7-6 no winning placement of the plain recipe loses a life in the boss wave, in the last pass of each. Only Old Tusk's 4 armored Dusk Moths cost lives (4-6, 6 lives). A boss wave that costs lives needs either an escort, which RULES 12.5 rules out for a boss's first wave, or a bigger release, which changes Glimmertoad's card line and its run packs. I kept both out (section 7, suggestion 1). The lives a finale costs now come from wave 9 and from gates that do not close the stump.

Levers I tried and did not take (3.1):

- **The analyst's `c240`** (Pip crowds of waves 7 and 10 at 200 and 240). It closes the lone Sling Post, but it changes nothing for the plain recipe, and 240 is above the late crowd of RULES 12.5 (160 to 210). Strength 55 closes the lone Sling Post too, so the crowds stay.
- **Stronger waves 1 to 11** (`s25`). It brings back the gate lesson, but it broke the Twist's only win, and not because the defense was weaker: the richer waves had paid for all 30 of the recipe's purchases by the boss wave, against 28 as built. That win was decided by when the Giant Bow's first arrow landed, about 2.5 s later under `s25` (3.1). With the gap, earlier waves are free to change later if B7 asks for it.
- **A stronger boss with the gap** (strength 57 to 60). Normal wins 20 placements at 55 to 58 and 9 at 60, but the Twist falls to 5, 3 and 1 placements at 12 s. 55 gives the Twist the most room for the same Normal.
- **An escort in the boss wave.** Against RULES 12.5 (a boss's first wave holds only the boss). At strength 55 the four escorts I measured changed nothing on Normal anyway (3.1).
- **Another Twist.** Not needed. Double Trouble stays on every boss level that has it, so the last level ends the campaign the way 1-6, 3-6, 4-6, 5-6, 6-6 and 7-6 do.

### 1.3 Level 8-4: no change

The Relaxed bar is met with no gates (4 lives of 40) and with the best placement (29). The Twist, Twice the Wings, is won by 729 of the 1500 builds of its search, so it is not thin for a player who builds for flyers; the plain recipe never builds for a Twist. No small change gives a clear margin without moving Normal (3.3):

- Wave 12 with 2 Dusk Moths instead of 4 (one number): no gates on Relaxed keeps 8 lives, but Normal's best goes from 7 lives to 11.
- Waves 8 and 12 with one and two Dusk Moths fewer: 10 lives, Normal's best 13.
- Wave 7's crowd at 160 instead of 170: 8 lives, Normal unchanged. But that crowd is the wave that stops a lone Sling Post there, and an earlier tweak of 8-4's waves let one earn three stars.
- 1000 starting gold instead of 950: 7 lives.

Each gives back 3 to 8 lives on Relaxed with no gates. The Dusk Moth cuts also take 8-4's best on Normal from 7 lives to 11 or 13, above 8-3 (8) and 8-5 (10), so region 8 would get easier just before its boss. The no gate case is a stress test, not a player's path: on Relaxed the four placements that keep 4 lives are no gates and gates that leave the route as it is (1,7 and 1,10), and every other placement keeps 15 to 29 lives. So 8-4 stays as it is.

### 1.4 RULES 12.6: the "All three stars" search on tower and kind limits

As the DM asked: on a level whose star 3 is a tower limit or a kinds limit, a first search of 3000 builds that finds no three-star win does not decide. Up to two more searches of 6000 builds with different seeds come first, and one three-star win is enough. On 5-3, 5-6 and 8-5 the first such build came after 1600 to 4700 builds (E5.5 section 3). The analyst already ran it that way in E5.5, so no report changes.

### 1.5 Tier 4 run packs, provisional until B7

Three edits to data/segments/packs.json, all first numbers that B7 reads again once the tier 4 tower cards are settled:

1. **b6_toad_glen:** the boss wave's strength 80 to 50. Glimmertoad has 1800 health instead of 2880.
2. **b6_toad_hollow:** the boss wave's strength 70 to 50 (2520 to 1800 health). No second lever.
3. **b4_blinking_watch:** its third wave brings 3 Dusk Moths instead of 4.

Why, with both bot habits (the default from tier 2 up), base cards, the 16 strategies, forced onto run seeds 1 to 100 (3.4):

- **b6_toad_glen at 50** wins 53.4% of the 1130 runs that start wave 18 (the analyst: 53.3% on f31b761, against 8.6% at 80). Inside the bar of 50% to 75%, near its floor.
- **b6_toad_hollow at 50** wins 47.1% on seeds 1 to 100 (the analyst: 47.2%), 2.9 points under. I looked for the second lever the DM asked for and found none in the pack: 578 of the 595 runs lost after wave 18 began were lost to Glimmertoad itself getting through. Two Flitters fewer in the escort changed nothing (47.5% against 47.5%, seeds 1 to 50), and 8 Pips fewer as well added 1.1 points, inside the noise. Strength 50 is the floor. The second reading of RULES 14.8, with the tower cards of tiers 2 to 4 and their perks out of the pool, meets the bar with room: 65.8% of 1298 runs. So, under RULES 14.8, the bar is met at 50, and the gap is the bots' tower cards, as for the whole of tier 4 (E8.2 8.1). If B7, with the cards settled, still reads it under 50% in both readings, the next lever is Glimmertoad's health (section 7, suggestion 2), not its escort.
- **b4_blinking_watch** loses 12.6% of the runs that reach it as built (the analyst: 12.1%) and 9.6% with one Dusk Moth fewer in its last wave, both on seeds 1 to 100 (bar 10%). Two Blinkers fewer in that wave instead gave 11.5% on seeds 1 to 50, against 12.2% as built on those seeds. 9.6% is close to the bar, so if B7 reads it over 10% once the cards are settled, the next step is 2 Dusk Moths. The Dusk Moth group stays first in its wave, where it shows the Dusk Moth as new (RULES 14.3).

The four tier 0 packs that lose more than 10% at tier 4 (b4_field_nurses 17.4%, b4_moth_flight 15.5%, b4_long_watch 13.7%, b4_quiet_moths 13.0%) are held to the bar at their own tier, as RULES 14.8 says: each met it at tier 0 in B5 (worst b4_moth_flight 9.5%, then b4_field_nurses 8.5%), and a tier 0 pack can never change without changing every tier 0 run and daily (RULES 14.9). They are reported at tier 4, not tuned. The same holds for the older packs of tiers 2 and 3 that the analyst lists (b3_sleepy_rows, b4_glowing_watch, b3_snowballs, b4_yawning_watch): each is held at its own tier, where it met the bar (b4_glowing_watch, b4_yawning_watch) or E6.3 and E7.3 tuned it (b3_sleepy_rows, b3_snowballs; TUNING_R67.md 1.5). b3_blinking_lanes, the other new tier 4 pack, loses 10.0%: at the bar, so it stays.

### 1.6 The Bramble Cottage watch item: not triggered

The Holly Crown stays at 24 and the cottage's numbers stay. The watch item of RULES 5.10 needs a search without the cottage to find fewer than a quarter as many three-star builds as a search with every tower, on two or more levels of one region. In region 8 it found more, not fewer: 1271 against 1305 on 8-2, 2077 in 6000 against 105 in 3000 on 8-3, and 1455 against 1449 on 8-4 (E5.5 section 6). Region 5 needs no such reading: there the cottage is the plan (RULES 5.10). B7 reads the item again over all 48 levels.

### 1.7 Not changed, on purpose

- **8-6's third star, hint and highlight.** "Lose no lives." holds with the lone Sling Post closed, so the fallback "Have at most 8 towers." (EXPANSION.md 6.4) is not needed. The hint ("Glimmertoad hops ahead and can't be slowed. Lure its Flitters low.") fits the new wave 9 too.
- **Every other level, Twist and third star of regions 5 and 8.** They passed every bar of RULES 12.6 (E5.5 section 2). The hunts of 5-3, 5-6 and 8-5 are not bar misses (1.4).
- **data/stats/.** No tower, creature or rule number moves. Glimmertoad's numbers stay, so its card line and its Info entry stay too.
- **The three newer tower cards at tier 4.** B7 splits them, as the DM decided.

## 2. Changes per owner

### 2.1 Game designer (done in this step)

- RULES.md: the change note; 12.3 (8-6's boss strength), 12.4 (5-6's third star, and a paragraph on regions 5 and 8), 12.5 (the gap of a boss group, and a line in the guide to third stars), 12.6 (the "All three stars" search), 13 (8-6's Double Trouble), 14.3 (Glimmertoad's two run packs).
- This file.
- data/stats/: no change.

### 2.2 Level designer (E8.4)

Exactly these edits. Nothing else in these files changes: no map, hint, highlight, Twist, tower list or starting gold.

data/levels/r5_l6.json, the third star:

```
before:  "star3": {"kind": "towers_at_most", "value": 6},
after:   "star3": {"kind": "tower_ban", "tower": "sling_post"},
```

data/levels/r8_l6.json, wave 9 (the Dusk Moth group, count 3 to 5) and wave 12 (strength 50 to 55, `every_ms` 1000 to 12000):

```
before: {"strength": 125, "groups": [..., {"enemy": "dusk_moth", "count": 3, "entrance": 1, "at_ms": 6000, "every_ms": 2000}]},
after:  {"strength": 125, "groups": [..., {"enemy": "dusk_moth", "count": 5, "entrance": 1, "at_ms": 6000, "every_ms": 2000}]},

before: {"strength": 50, "groups": [{"enemy": "glimmertoad", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}]}
after:  {"strength": 55, "groups": [{"enemy": "glimmertoad", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 12000}]}
```

data/segments/packs.json, three lines (1.5):

```
b6_toad_glen, third wave:       "strength": 80   becomes   "strength": 50
b6_toad_hollow, third wave:     "strength": 70   becomes   "strength": 50
b4_blinking_watch, third wave:  {"enemy": "dusk_moth", "count": 4, "entrance": 2, "at_ms": 0, "every_ms": 2000}
                      becomes   {"enemy": "dusk_moth", "count": 3, "entrance": 2, "at_ms": 0, "every_ms": 2000}
```

tests/levels/test_level_design.gd, the plan row of `r5_l6`: `"star3": ["towers_at_most", 6]` becomes `"star3": ["tower_ban", "sling_post"]`. No other test reads these values (3.5).

### 2.3 Balance analyst (B7)

Once E8.4 is in, in the final pass:

1. 5-6 and 8-6 with every check of RULES 12.6, as changed. On 5-6 the "All three stars" search leaves the Sling Post out and no lone search is needed (`mode=need` reads both from the level file). On 8-6 the lone Sling Post on the pass seeds 838601 and 868601, as in E8.2.
2. 8-6's Twist. The search of 1500 builds wins nothing there, and the two of 6000 win it thousands of times (3.2), as on 7-6. Please also replay the any-tower search's three-star builds of 8-6 under the Twist (`mode=replay twist=1`), so the report says whether good Normal builds carry over.
3. The rule of RULES 12.6 for "All three stars" on every level whose third star is a tower limit or a kinds limit (1.4), as E5.5 already did.
4. Runs at tier 4 with the packs of 1.5, the split of the three newer tower cards, and both readings of RULES 14.8. Glimmertoad's two packs and b4_blinking_watch are read again there; their numbers here are first numbers.
5. The Bramble Cottage watch item (RULES 5.10) over all 48 levels.

The variant files `tools/balance/variants/r8_l6_*.json` are copies of the old 8-6 and go stale with E8.4.

### 2.4 Everyone else

The roguelite engineer, the sim engineer and the UI engineer have nothing to do: no card, run.json, src/ or contract change. The UI builds the star sentence and the previews from the data (contract 2.7).

## 3. Evidence

All of mine on a clean copy of 47ccda1 in the session's scratch folder, with the working tree's tools/balance, from its root after `godot --headless --path . --import`. Level variants came in through `level_file=` and run packs through `tweak=`, so no data file of the copy changed while the bots played. "Plain" is the plain mixed recipe of RULES 12.6 over every gate placement, Normal unless it says otherwise. Outcomes are builds lost / won with 1, 2 and 3 stars.

### 3.1 Level 8-6: boss strength, the gap and the late flyers

The plain recipe, placements won of 46. The Normal column does not depend on the gap, because the boss group holds one Glimmertoad there. Rows marked E8.2 are the analyst's (`whatif86/`), the rest mine.

| Boss wave strength (health) | Normal | Twist, gap 1 s (as built) | 4 s | 8 s | 10 s | 12 s | 14 s | 16 s | 20 s |
|---|---|---|---|---|---|---|---|---|---|
| 50 (1800), as built | 46 (E8.2) | 1 (E8.2) | 1 | 5 | | 9 | | 20 | 46 |
| 55 (1980) | 20 (E8.2) | 0 (E8.2) | | 1 | 5 | **9** | 9 | 20 | 20 |
| 57 (2052) | 20 | | | | | 5 | 5 | 16 | |
| 58 (2088) | 20 | | | | | 3 | 5 | 16 | |
| 60 (2160) | 9 (E8.2) | 0 (E8.2) | | 1 | | 1 | | 5 | 9 |
| 65 (2340) | 9 (E8.2) | 0 (E8.2) | | 0 | | 1 | | 3 | 5 |
| 70 (2520) | 5 | | | 0 | | 0 | | 1 | |
| 80 (2880) | 1 (E8.2) | 0 (E8.2) | | 0 | | 0 | | 0 | |

- At every strength the Normal winners keep the lives they had when wave 12 began: Glimmertoad is popped or it gets through. The best placement keeps 20 lives at every strength.
- With a gap of 20 s the Twist wins exactly the placements Normal wins, at strength 50 and at 55, and at 55 already from 16 s: the two Glimmertoads are fought one after the other.
- At strength 55 the Normal winners are exactly the 20 placements that close the stump (4,4) or the short road to the base (3,9). The Twist winners with a 12 s gap are exactly the 9 that close the stump.

Wave 9's Dusk Moths, with the boss wave at 55 and the gap at 12 s:

| Wave 9 | Normal: won, best | Lives of the Normal winners | Twist: won, best |
|---|---|---|---|
| 3 Dusk Moths (as built) | 20, 20 lives (five placements, three stars) | 17 to 20 | 9, 20 lives |
| 4 Dusk Moths | 20, 20 lives (two placements, three stars) | 15 to 20 | 9, 20 lives |
| **5 Dusk Moths** | **20, 18 lives (4,4 + 3,9)** | **15 to 18** | **9, 18 lives** |
| 5 Dusk Moths, and 10 Flitters in wave 11 | 20, 18 lives | 15 to 18 | 9, 18 lives |

With 5 Dusk Moths, wave 9 costs every winning placement 2 to 4 lives (one Dusk Moth or two), and nothing else changes: the winners are the same 20 placements. On Relaxed all 46 placements win with 40 lives.

The Twist at the best placement as built (4,4 + 3,5 + 3,9, a probe of mine that logs the boss wave): the first Glimmertoad was popped at 14 steps from the base, the second at 3 steps with 3 health left at the last sample. Under `s25` the same placement had the last two upgrades bought, the Giant Bow's first arrow landed about 2.5 s later, and the second Glimmertoad reached the base with 182 health. At strength 55 with the 12 s gap (wave 9 as built), the same probe at 4,4 + 3,5 has the first popped at 9 steps from the base and the second at 4, and 8 other placements win as well.

Other levers, the plain recipe at strength 55 (escorts in wave 12 are against RULES 12.5 and were measured only to see whether they would matter):

| Variant | Normal | Twist, 16 s gap |
|---|---|---|
| 8 Flitters from B with the boss | 20 | 20 |
| 3 Dusk Moths from B with the boss | 20 | 5 |
| 6 Blinkers behind the boss | 20 | 16 |
| 4 Dusk Moths from B with the boss | 20 | 5 |

### 3.2 Level 8-6 as planned: every check of RULES 12.6

The three edits of 1.2 in one level file (`level_file=`), seeds of the 1086000 range for the new jobs and the pass seeds for the lone Sling Post.

| Check | As built (E8.2) | As planned |
|---|---|---|
| Plain, Normal | won, 20 lives, three stars (4,4 + 3,5); 46 of 46 placements | won, 18 lives, two stars (4,4 + 3,9); 20 of 46 |
| Plain, Normal, no gates | won, 7 lives | lost in wave 12 (5 lives when it began) |
| Plain, Relaxed: no gates / best | won, 40 / 40 | won, 40 / 40 (46 of 46) |
| All three stars: any tower, 3000 builds (seed) | 1107, first at 1040 (828600) | 1007, first at 933 (1086000); outcomes 1756 / 67 / 170 / 1007 |
| Lone Sling Post, seed 838601 | 323 three-star builds in 6000 | no win in 2500 (stopped) |
| Lone Sling Post, seed 868601 | no win in 6000 | no win in 2500 (stopped) |
| Random play, three stars | 0.0% of 750 | 0.0% of 750 (no Normal win at all) |
| Length, best placement | 7.4 min | 7.2 min |
| Largest wave | 66 (wave 10) | 66 (wave 10); wave 9 has 16 |
| Twist, plain: placements won | 1 of 46 | 9 of 46, best 18 lives (4,4 + 3,9); Relaxed 46 of 46 |
| Twist search, 1500 builds (seed) | none won (878600) | none won (1087000) |
| Twist searches, 6000 builds (seeds) | none and none (880600, 882600) | 2695 and 2788 wins (1089000, 1089500); no life lost in 2128 and 2434 of them, the first of those at builds 2122 and 2035 |
| Same seed, same play (`mode=det`) | met | met: 24 plays and 72 saves mid-wave equal, the search repeats |

- The lone Sling Post needs the only searches of the "No super tower" check (`mode=need`: flyers cost 32 lives now, walkers 380).
- In the 1007 three-star builds: a Giant Bow and a Moth Lantern in all of them, a Bramble Cottage in 977, a Snow Fort in 826, a Sling Post in 790, a Bell in 596, a Catapult in 580, a Firework Tower in 509, a Scarecrow in 115. A search settles on one family of builds, so these shares say what that family holds, not what every three-star win needs: the Moth Lantern stood in 96 of the 1107 as built, and in 952 of the analyst's 990 at strength 55 alone.
- The Twist search of 1500 builds wins nothing: its random builds spend on Bells, which no Glimmertoad feels, and keep gold they never spend (its best play ended the boss wave with 1508 gold unspent and two Hush Bells). The two searches of 6000 builds get past that and win 2695 and 2788 times. Good Normal builds carry over as well: of the 14 builds the any-tower search saved (its best win, its twelve best three-star builds and its top), all 14 win Normal with 20 lives again, and 5 win the Twist with 20 lives.

### 3.3 Level 8-4

The plain recipe, wave variants (`level_file=`). Twist: Twice the Wings.

| Variant | Normal: won of 45, best | Relaxed: no gates, best | Twist: plain won |
|---|---|---|---|
| As built (E8.2) | 14, 7 lives | 4, 29 | 0 |
| Wave 7 at strength 160 (170 as built) | 14, 7 | 8, 29 | 0 |
| Wave 12: 2 Dusk Moths (4 as built) | 14, 11 | 8, 33 | not played |
| Waves 8 and 12: 2 and 3 Dusk Moths (3 and 4) | 14, 11 | 8, 33 | 0 |
| Waves 8 and 12: 2 and 2 Dusk Moths | 14, 13 | 10, 35 | not played |
| Waves 8 and 12: 2 and 3 Dusk Moths, wave 7 at 160 | 14, 11 | 12, 33 | 0 |
| Wave 6: 6 Flitters (8 as built) | 14, 9 | 6, 31 | not played |
| Starting gold 1000 (950) | 19, 7 | 7, 32 | 0 |

On Relaxed with no gates the plain recipe loses 12 lives to wave 7's Pips, 8 to the Dusk Moths of waves 8 and 12, 6 to Bubblers, 4 to Sleepyheads, 3 to Flitters and 3 to Scamps (a watched replay).

### 3.4 Run packs at tier 4

`runs.gd mode=rates`, tier 4, Normal, the 16 strategies, both habits (`air_floor=55 scarecrow_from=9`), `leaks=1`, base cards unless it says otherwise, the pack forced onto every seed (`pack=`), changes in memory (`tweak=pack_strength:` and `tweak=pack_count:`). Boss packs: the share of the runs that start wave 18 that win (bar 50% to 75%). b4_blinking_watch: stopped when its last wave is done (`stop=12`), the share of the runs that reach its first wave and are lost before its last ends (bar at most 10%), counted as `runs_summary.gd` counts it. Rows marked E8.2 are the analyst's, on f31b761.

| Pack | Change | Seeds | Started wave 18 (boss packs) or reached (b4) | Result |
|---|---|---|---|---|
| b6_toad_glen | as built, strength 80 (E8.2) | 1 to 100 | 1103 | 8.6% won |
| b6_toad_glen | **strength 50** (E8.2) | 1 to 100 | 1103 | 53.3% won |
| b6_toad_glen | **strength 50** | 1 to 100 | 1130 | **53.4% won** |
| b6_toad_hollow | as built, strength 70 (E8.2) | 1 to 100 | 1096 | 14.9% won |
| b6_toad_hollow | **strength 50** | 1 to 100 | 1124 | 47.1% won |
| b6_toad_hollow | 50, Flitters 6 to 4 | 1 to 50 | 570 | 47.5% won |
| b6_toad_hollow | 50, Flitters 6 to 4, Pips 20 to 12 | 1 to 50 | 570 | 48.6% won |
| b6_toad_hollow | **50, second reading** (the tier 2 to 4 tower cards and their perks out) | 1 to 100 | 1298 | **65.8% won** |
| b4_blinking_watch | as built | 1 to 100 | 1392 | 12.6% lost inside (E8.2: 12.1% of 1360) |
| b4_blinking_watch | **Dusk Moths 4 to 3 in its last wave** | 1 to 100 | 1392 | **9.6% lost inside** (9.5% and 9.8% in the two halves) |
| b4_blinking_watch | Blinkers 5 to 3 in its last wave | 1 to 50 | 695 | 11.5% lost inside |

In the runs that started wave 18 with b6_toad_hollow at 50 and were lost, Glimmertoad got through in 578 of 595. Its escort is not what loses them.

### 3.5 Tests

On a second clean copy of 47ccda1 with the working tree's tools/balance and exactly the edits of 2.2 applied (r5_l6.json, r8_l6.json, packs.json and the `r5_l6` row of tests/levels/test_level_design.gd), after `godot --headless --path . --import`: `godot --headless --path . --script res://tests/run_tests.gd` gives "Ran 1634 tests in 117 files: 1634 passed, 0 failed." with exit code 0. The tier 0 golden run (tests/run/test_tier_zero.gd) is among them, and so are the new creature rule for every choice of packs at every tier and the spawn bounds. No doc is read by a test.

The level smoke test in that run plays the plain mixed recipe on every level: 8-6 wins with 18 lives in 7.2 minutes (gates 4,4 and 1,5 and 3,9, which ties with 4,4 and 3,9), 5-6 with 8 lives in 7.5 minutes as before, and every other level as E8.2 found.

### 3.6 How to repeat

From the root of a clean copy of 47ccda1 with the working tree's tools/balance, after `godot --headless --path . --import`. PLANNED is data/levels/r8_l6.json with the edits of 2.2; the grid of 3.1 used the same file with wave 12's strength and the boss group's `every_ms` set as the table says, and the 8-4 rows used data/levels/r8_l4.json with the one edit each row names. The variant files are in the session's scratch folder, under `e83/probe/variants/`.

```
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r8_l6 level_file=PLANNED out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r8_l6 level_file=PLANNED twist=1 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r8_l6 level_file=PLANNED seed=838601 evals=6000 stop_dry=2500 only=solo:sling_post out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r8_l6 level_file=PLANNED seed=868601 evals=6000 stop_dry=2500 only=solo:sling_post out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r8_l6 level_file=PLANNED seed=1086000 evals=3000 only=any out=ANY.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r8_l6 level_file=PLANNED twist=1 seed=1087000 evals=1500 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r8_l6 level_file=PLANNED twist=1 seed=1089000 evals=6000 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=spread level=r8_l6 level_file=PLANNED seed=1081600 n=250 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=det level=r8_l6 level_file=PLANNED seed=1083600 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=replay level=r8_l6 level_file=PLANNED from=ANY.json pick=all twist=1 out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 tier=4 pack=b6_toad_hollow air_floor=55 scarecrow_from=9 leaks=1 "tweak=pack_strength:b6_toad_hollow;50" out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=minus:tower_scarecrow,big_hat,tower_snow_fort,packed_snow,tower_moth_lantern,bright_wick relaxed=0 tier=4 pack=b6_toad_hollow air_floor=55 scarecrow_from=9 leaks=1 "tweak=pack_strength:b6_toad_hollow;50" out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 tier=4 pack=b4_blinking_watch stop=12 air_floor=55 scarecrow_from=9 leaks=1 "tweak=pack_count:b4_blinking_watch;3;dusk_moth;3" out=OUT.json
```

The other jobs differ only in seed, `first`, the pack, the tweak or the level file; the second Twist search of 6000 builds is seed 1089500. The packs' tables count the files' `rows` the way `runs_summary.gd` does (`reached`, `won`, `stopped`). In all, about 9 hours of jobs in about an hour and a quarter, at most 8 of mine at a time.

## 4. For Bart

These change what Bart approved, so the DM tells him. Under the DM's rule of 2026-10-28 they go ahead once the DM accepts them.

1. **5-6 Burrowbelly: the third star is now "Build no Sling Posts."** It was "Have at most 6 towers." Why: with six towers, Sling Posts alone could still earn all three stars, and no smaller limit left a three-star win for anyone. 5-4 has the same rule, with 5-5 between them.
2. **8-6 Glimmertoad is now a real final boss.** It has 1980 health instead of 1800, and wave 9 brings 5 armored Dusk Moths instead of 3. Why: before, every gate choice beat it without losing a single life, and Sling Posts alone could earn all three stars. Now the gates must close the stump or the short road to the base, or Glimmertoad gets through, and the Dusk Moths cost lives unless a Moth Lantern pulls them low in front of the big towers. The hint and the third star ("Lose no lives.") stay.
3. **8-6's Twist, Double Trouble: the second Glimmertoad now comes 12 seconds after the first, not 1.** Why: two side by side were close to unbeatable. The bots won it with 1 gate choice of 46 and never in a search. Now it is clearly harder than the level and still winnable: 9 gate choices of 46, and the bots' long searches win it often. The Twist's name and text stay.
4. **Runs: Glimmertoad is weaker there.** Its two run boss waves give it 1800 health instead of 2880 and 2520. Why: the bots beat it in about 1 run in 10 that reached it, where the target is 1 in 2 to 3 in 4. These are first numbers; the final balance pass checks them again once the newest tower cards are settled.
5. **Runs: one Blinker pack is gentler.** Its last wave brings 3 Dusk Moths instead of 4. Why: it lost 12% of the runs that reached it, over the 10% the run targets allow.
6. **8-4 Hoot Glen stays as it is.** On Relaxed with no gates at all it is close (4 lives of 40 left), but any gate that changes the route keeps 15 or more, and every small change made the level easier on Normal too.

No hint, Twist name or text, card line, run card text or creature line changes.

## 5. Every text a player sees that changes

The level card, Pause, the previews and the panels build their words and numbers from the data (contract 2.7), so the UI changes nothing.

| Where | Before | Now |
|---|---|---|
| 5-6 Burrowbelly: the third star line on the level card and in Pause | Have at most 6 towers. | Build no Sling Posts. |
| 5-6 on Normal, before star 3 is earned: the Sling Post in the build menu | no warning | "Loses the third star." (RULES 10.6), as on 5-4 |
| 8-6 Glimmertoad, wave 9 preview | 8 Snowrollers (B), 3 Yawners (B), 3 Dusk Moths (A) | 8 Snowrollers (B), 3 Yawners (B), 5 Dusk Moths (A) |
| 8-6, wave 12: Glimmertoad's health in the preview and its panel | 1800 | 1980 |
| 8-6, wave 12: the 6 Flitters it lets out, panel | 15 health | 17 health |
| 8-6 Twist, wave 12 preview | 2 Glimmertoads, 1800 health | 2 Glimmertoads, 1980 health (the second now comes 12 s after the first; no text shows the gap) |
| Runs, b6_toad_glen's boss wave: Glimmertoad, and its escort of 12 Scamps, 4 Shellbacks and 4 Flitters | 2880 health; 32, 72 and 24 | 1800 health; 20, 45 and 15 |
| Runs, b6_toad_hollow's boss wave: Glimmertoad, and its escort of 20 Pips, 5 Bubblers and 6 Flitters | 2520 health; 15, 35 and 21 | 1800 health; 11, 25 and 15 |
| Runs, b4_blinking_watch's last wave preview | 4 Dusk Moths, 5 Puffballs, 5 Blinkers, 10 Skitters | 3 Dusk Moths, 5 Puffballs, 5 Blinkers, 10 Skitters |

Gold follows strength (RULES 6.4): on 8-6, wave 9 pays two more Dusk Moth bounties (19 gold each), and Glimmertoad pays 220 instead of 200, with a clear bonus of 44 instead of 40. In runs, Glimmertoad's boss waves pay less, which the end of the run makes moot.

## 6. Open questions

1. **For the DM: the boss wave of 8-6 still costs a winning build no lives** (1.2, "What it does not do"). Goal c asked for it. A Glimmertoad that gets through ends a Normal game, and its Flitters are too weak to leak, so the lives of the finale now come from wave 9 and from gates that leave the stump open. Making the boss wave itself cost lives needs suggestion 1 below, which changes Glimmertoad's card line and its run packs. Do you want it measured for B7, or is wave 9 enough?
2. **For the DM: no second lever on b6_toad_hollow** (1.5). You asked for one. Its escort is not one: 97% of its lost runs are lost to Glimmertoad itself, and trimming the escort moved it by 0 and 1.1 points. Its second reading meets the bar with room (65.8%), which RULES 14.8 counts as met. If you want the first reading inside the bar now, the only lever left is Glimmertoad's health (suggestion 2), which also touches 8-6; I would rather wait for B7's card split.
3. **For the DM: Glimmertoad's run packs at the floor.** Both packs sit at 50, the lowest a band 6 pack may set. If B7, with the tier 4 cards settled, reads them under 50% in both readings of RULES 14.8, strength can go no lower, and the next lever is Glimmertoad's health in data/stats/ (suggestion 2).

## 7. Suggestions beyond the task

1. **A bigger release for Glimmertoad,** if the DM wants its boss wave to cost lives (6, question 1): 10 Flitters at half health instead of 6. At strength 55 they still have 17 health each, so they leak only past a defense with too little anti-air near the base, and the hint ("Lure its Flitters low.") gets a reason. It changes its card line to "At half health, 10 Flitters fly out.", doubles to 20 in the Twist, and moves its run packs, so I have not measured or proposed it.
2. **Glimmertoad's health,** only if B7 needs it (6, questions 2 and 3): 3600 down to 3300, with 8-6's boss wave from 55 to 60 so the level keeps 1980 health. Its run packs could then go down to 1650 health at strength 50. Its card line does not change.
3. **8-6's hint** could name the stump, which now decides the level ("Close the stump. Glimmertoad hops ahead and can't be slowed."). I left it: 8-1 teaches the stump, and the hint's Flitter line now matters in wave 9. It would be a text change for Bart.
