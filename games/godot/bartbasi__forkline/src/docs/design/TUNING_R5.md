# Region 5 tuning plan (E5.3)

Owner: game designer. 2026-10-29 (task E5.3). Answers the region 5 balance report, docs/balance/region5-2026-10-28.md (E5.2, played on commit e6beedc). RULES.md holds the rules and numbers. This file says what changes, why, and exactly what each owner types in. Section 5 lists every text a player sees that changes. The DM may follow its own advice at the expansion's gates (CLAUDE.md, 2026-10-28), so these changes go ahead now, and the DM tells Bart each text change.

## 1. Decisions

### 1.1 The Bramble Cottage: harder thorns and wider rings

| | Price | Damage before | Damage now | Ring before | Ring now |
|---|---|---|---|---|---|
| Tier 1, Bramble Cottage | 120 | 4 | 10 | 1.5 | 2.0 |
| Tier 2, Bramble Cottage | 130 | 7 | 14 | 1.5 | 2.5 |
| Tier 3, Wild Bramble | 230 | 10 | 20 | 2.0 | 3.0 |
| Tier 3, Holly Crown | 230 | 12, ignores armor | 24, ignores armor | 1.5 | 2.5 |

Prices, the 1.0 s reload, what it hits and every card line stay as they are. So does Thorn Tips, its run perk (2 more damage per hit).

Why it needed more:

- In the campaign it was weak where it should shine. It stood in 740 of the 4208 three-star builds on the levels that offer it (17.6%): 83 of 1028 on 5-2, the level that brings it, and 16 of 694 on 5-6, whose hint says "Keep Brambles near" (E5.2 section 3).
- In runs it was a trap. The bots take its card in 9 of 10 tier 1 runs. With the card in the pool the 16 strategies won 23.8%, without it 47.0% (E5.2 section 5). Taken, the card was worth 7.2 points below the average of the three cards offered with it, the worst of any tower card.
- The numbers say why. A ring of 1.5 holds about 2.2 tiles of a straight road beside the spot. A Scamp crosses that in about 2 seconds and takes 2 pulses: 9 of its 40 health at tier 1. A Mossbud regrows 4 a second, as much as a tier 1 cottage deals, and armor 1 or 2 takes a quarter to half of each pulse.

Why these numbers. In the analyst's what-ifs (E5.2 section 5), more damage alone or a wider ring alone each won back 4 to 8 points. Both together won back 15: with twice the damage and a ring of 2.5 the 16 strategies won 38.0% over all 200 seeds, inside their bar of 35 to 55%. The best strategy won 54.5%, half a point under its floor and well inside the noise (its standard error is 3.5 points). Both Burrowbelly packs moved into their bar (52.7% and 73.9%). Three times the damage did better in runs (43.0% on 50 seeds), but twice already changes the campaign a lot (below).

My tier 1 differs from that what-if in one way: its ring is 2.0, not 2.5, and its damage 10, not 8. So the cottage's rings grow as a Bell's and a Scarecrow's do (2.0, then 2.5, then 3.0 on the wide path), and a first cottage must stand right beside the road, best where it bends. In runs the two read the same: on seeds 1 to 100 the 16 strategies won 36.1% with my numbers and 36.9% with the analyst's, and the best strategy 51% and 52% (3.1). In the campaign mine keep the gates in play. With a tier 1 ring of 2.5, the plain mixed recipe won every gate placement of 5-5, the placement with no gates included, and 5-2 with no gates kept 13 lives instead of 5. With 2.0, 5-5 stays a gate puzzle (4 placements of 29 win, the best with 16 lives), and 5-2 with no gates keeps 5 lives, as before.

What the tower is now. At tier 1 a Scamp on a straight road beside the spot takes about 35 of its 40 health, and a Pip at strength 115 or less is popped in the ring. A crowd that walks a bend around the spot is popped there. Its weaknesses stay: it cannot hit flyers that are not lured low, armor 4 takes 4 of a tier 1 pulse's 10 damage (the Holly Crown ignores armor), a Mossbud regrows 4 of the 10 damage of each tier 1 pulse, and it is worth only the road near its spot.

Reading the bars: with the default bots, as the DM leaned. This answers the analyst's open question (E5.2 section 8). The bots take the card nine runs in ten and lose with it. A player who builds the cottage in a plain place loses with it too. Limiting the bots to one cottage (E5.2's option (b), 34.4%) would hide the weakness, not fix it, and it still misses the floor.

What the buff does to the campaign. The plain mixed recipe, before (E5.2) and now (my plays, 3.1):

| Level | Bar | Normal, placements won, before / now | Normal, best lives, before / now | Normal, no gates, before / now | Relaxed, no gates, before / now |
|---|---|---|---|---|---|
| 5-2 | 15 lives | 13 of 13 / 13 of 13 | 18 / 18 | won, 5 / won, 5 | 40 / 40 |
| 5-3 | win | 13 of 13 / 13 of 13 | 18 / 18 | won, 5 / won, 5 | 40 / 40 |
| 5-4 | win | 6 of 35 / 28 of 35 | 7 / 7 | lost in wave 7 / won, 7 | 30 / 32 |
| 5-5 | win | 3 of 29 / 4 of 29 | 13 / 16 | lost in wave 2 / lost in wave 3 | 20 / 25 |
| 5-6 | win | 1 of 23 / 1 of 23 | 6 / 8 | lost in wave 2 / lost in wave 4 | 3 / 7 |

5-1 does not offer the cottage. Section 1.5 says why 5-4 and 5-5 keep their waves. The level smoke test, which plays one fixed recipe on every level, shows the cottage reaching region 6 too: 6-5 goes from 11 lives to 20, 6-3 from 7 to 9 and 6-2 from 19 to 20 (3.3). Region 7 does not move. E6.2 measures region 6 on the new numbers.

How strong is too strong. With the new numbers the cottage stands in nearly every three-star build of region 5 (3.1): all 1072 on 5-2, all 980 on 5-3 under its 4-tower limit (823 of them Holly Crowns), all 1490 on 5-4 without the Sling Post, all 87 that one search found on 5-5, and 244 of the 249 that two searches found on 5-6 under its 6-tower limit. Before, it stood in 18%. Where towers are few it takes the Catapult's place: the Catapult stands in 61 of 980 on 5-3 and in none of the 87 on 5-5, though still in nearly all of 5-2's. That is region 5 as planned: it plays as hide and seek, and its answers are gates that keep walkers out of the tunnels and towers that need no aim (EXPANSION.md 2.1). It is not a super tower in the sense of RULES 12.6: it cannot hit flyers, which cost 34 to 60 lives on every region 5 level, so a lone cottage can never keep 15 lives.

The watch item, for E5.5 and the region 6 pass, is in RULES 5.10: if the cottage stands in more than 9 of every 10 three-star builds on levels of regions 6 to 8, the Holly Crown's damage comes down first, from 24 to 20, to match the Wild Bramble's, so the two paths differ only by ring and armor. Tier 1's comes next, 10 to 8. I did not trim the Holly Crown now: the runs need every point (1.6), and region 5 wants a strong cottage.

Not chosen:

- Three times the damage (12, 21, 30, 36). It reads 43.0% for the 16 in runs, but twice already makes the ground of 5-4 the cottage's job. Three times would make it the ground answer everywhere.
- Cheaper (26.2%), or hitting flyers (25.6%; 33.2% with twice the damage). Flyers would erase its weakness and blur it with the Sling Post.
- A stronger Thorn Tips. The perk stays at 2: no card may decide a run (RULES 14.8).

### 1.2 Region 5's third stars

| Level | Its idea (RULES 12.3) | Third star before | Third star now | Evidence |
|---|---|---|---|---|
| 5-1 Under the Hedges | Walkers in a tunnel are out of reach. Gate them out of it. | Have at most 6 towers. | Have at most 4 towers. | 696 three-star builds in 2500 (first at build 937). Lone Sling Post: none in two searches of 6000 (2562 and 2834 wins). |
| 5-2 Bramble Bend | Thorns hit everything around them. Build where the road wraps. | No tower above tier 2. | unchanged | Lone Sling Post: none in two searches of 6000 (E5.2). |
| 5-3 Mossy Hollow | Big hits beat regrowth. Slows only give it time. | Build no Lullaby Bells. | Have at most 4 towers. | 741 three-star builds in 3000 (first at 1155). Lone Sling Post: none in two searches of 6000 (3033 and 2933 wins). [New cottage: 980 in 3000, first at 33.] |
| 5-4 Mist Lane | Hidden creatures need splash, rings or lines. | Have at most 7 towers. | Build no Sling Posts. | 860 three-star builds in 2500 without the Sling Post (first at 951). [New cottage: 1490 in 3000, first at 42.] The Sling Post can never earn it. |
| 5-5 Badger Hill | Two entrances, a tunnel on each road. | Use at most 3 kinds of tower. | unchanged | A lone Sling Post cannot win 5-5 (E5.2). |
| 5-6 Burrowbelly | A boss you cannot always reach, hidden by mist. | Have at most 8 towers. | Have at most 6 towers. | 340 three-star builds in 2500 (first at 1563). Lone Sling Post: none in two searches of 6000 (2077 and 1299 wins). [New cottage: 77 and 172 in two searches of 3000, first at 2613 and 2345.] |

Under the old rules a lone Sling Post with Bells earned all three stars on 5-1, 5-3, 5-4 and 5-6: 2344, 4548, 3143 and 1615 three-star builds in two searches of 6000 builds each (E5.2 section 2). The first numbers in the evidence column are E5.2's own what-ifs, played with the old cottage. The lone Sling Post searches stand as they are: no lone Sling Post search uses the cottage, and no wave of these levels changes. The bracketed numbers are my searches with the new cottage (3.1).

The shape of the region: a tower limit, a tier cap, a tower limit, a ban, a kinds limit and a tower limit. No two levels in a row share a rule, and no third star repeats its level's Twist (One Gate, No Catapults, Tier 2 Cap, No Gates, Five Lives, Double Trouble).

Why each:

- 5-1. With 4 towers on 12 spots, the two gates must keep walkers out of the tunnel and on the road past those 4 towers. That is the level's lesson as a challenge. The tier 2 cap also passed (796), but 5-2 has it, and neighbors must differ.
- 5-3. Section 1.3.
- 5-4. Section 1.4.
- 5-6. From 8 towers to 6. At most 5 left no three-star win at all (0 in 3000). The ban also passed (756, and 1107 in 3000 with the new cottage), but 5-4 now has it, and with the new cottage it asks little: most good builds carry no Sling Post anyway. A limit makes the six towers a puzzle on the boss level: which six beat a boss that digs, its mist and the flyers. For the bots it is a hunt, as 3-3's 5 towers were: three searches found 340, 77 and 172 three-star builds, the first after build 1500 each time. E5.5 searches it with 6000 builds.

### 1.3 Level 5-3: a tower limit, and the waves stay

E5.2 called 5-3 soft in two ways (its item 3): a lone Sling Post earned three stars in 38% of its builds, and the any-tower search in 49%. E5.2 and the DM named the Sling Post ban as the lever, and it works on 5-3 (1059 three-star builds in 2500 without the Sling Post, and 1455 in 3000 with the new cottage). But 5-4 needs the ban more (1.4), and neighbors must differ.

"Have at most 4 towers." answers both. No lone Sling Post build earned it in two searches of 6000, and it is the tighter star. With the new cottage, 980 of 3000 searched builds earned three stars under it, against 1455 under the ban, whose very first build already did. Four towers cannot afford chip damage, so the Mossbud waves need big hits, which is the lesson. The cost: nearly every one of those builds holds a cottage, mostly a Holly Crown, with Sling Posts and a Firework Tower, and the Catapult stands in only 61 of them. Under the ban it would stand in 1233 of 1455.

The waves stay:

- The plain recipe keeps 18 lives with its best gate, as on 5-1 and 5-2, and needs that gate: with none it wins with 5 lives. A first-time player meets the level as hard as its neighbors.
- More creatures mostly reward the gate the player has found. With 80% more, the best gate still keeps 20 lives, while the play with no gates already loses at 10% more (E5.2 section 2). That makes 5-3 a gate puzzle, and its lesson is the Mossbud.

If E5.5 finds random play earning three stars in 10% of plays or more, every group count on 5-3 rises 20%, rounded up. With a 4-tower limit I do not expect it.

### 1.4 Level 5-4: the ban as its third star, and No Gates as its Twist

Decision: the third star is "Build no Sling Posts.", and the Twist changes from No Sling Posts to No Gates (`set_gates` 0, card text "You get no gates.", as on 2-4 and 7-1). No wave changes.

Nothing but the ban stops a lone Sling Post with Bells on 5-4:

| Third star tried | Three-star builds, any allowed tower | Lone Sling Post three-star builds |
|---|---|---|
| Have at most 5 towers. (E5.2, old cottage) | 813 in 2500 | 633 and 325 in two of 6000 |
| Have at most 4 towers. (E5.2, old cottage) | 0 in 3000 | not needed |
| Have at most 4 towers. (mine, new cottage) | 946 in 3000 | 0 and 671 in two of 6000 |
| No tower above tier 2. (E5.2, old cottage) | 0 in 2500 | 0 |
| Use at most 1 gate. (mine, new cottage) | 1387 in 3000 | 1559 in one of 6000 |
| Use no gates. (mine, new cottage) | 1322 in 3000 | 1044 and 1213 in two of 6000 |
| Build no Sling Posts. | 860 in 2500 (E5.2); 1490 in 3000 with the new cottage (mine) | it can never earn it |

The gate rules were my hope for a different kind of star: with no gates the walkers take the short middle road through both tunnels, under the mist. They failed. So did a 4-tower limit once the new cottage made it reachable at all: one of two lone searches found 671 three-star builds. A Mistwisp is never hidden itself, so pebbles pop it and the creatures behind it come back into sight, and Bells give the pebbles time. The lone builds that earned it hold six to eight Sling Posts, most of them Quickshots or Stone Slings, and one to three Bells. A Bell ban would not help either: in E5.2's lone searches, 1207 of 1674 and 786 of 1469 three-star builds used no Bell.

Why the ban and not wave changes:

- The ban is the lesson as a challenge. Mist stops aim, so the player leans on rings, lines and splash. The hint already says so: "Pop the wisp, or use rings and splash."
- It is certain. The Sling Post can never earn it, and no other lone tower can keep 15 lives on 5-4 (its flyers cost 34 lives, its walkers 288). Wave changes, such as a crowd before the gold (RULES 12.5), would take rounds of searches, and they would make 5-4 harder for everyone, while the plain recipe already keeps only 7 lives there.
- The old Twist banned the Sling Post too, so it had to go. No Gates fits the level: the walkers must take the short road through both tunnels, where the Mistwisps hide them, and the player builds rings and splash along it. It is clearly winnable: the plain recipe wins 5-4 with no gates (7 lives) and so does a lone Sling Post (1.4's table). A Twist needs only one Normal win (RULES 13).

### 1.5 Levels 5-4 and 5-5 after the buff: the waves stay

E5.2 expected both to get much easier. They get wider, not easy:

- 5-4. Placements won rise from 6 to 28 of 35, but the best still keeps 7 lives. The recipe now loses lives only in waves 2, 5, 7, 8 and 10, the waves with Flitters or a Dusk Moth, because it builds one Firework Tower. The ground is now the cottages' job, and the air still asks for Fireworks.
- 5-5. Placements won rise from 3 to 4 of 29, and the best from 13 lives to 16, so the plain recipe now earns two stars. With no gates it still loses, now in wave 3 instead of 2, so the gates stay the puzzle of a level with a tunnel on each road. Its bar is a win. Its three stars stay a hunt: with the new cottage one search found 87 in 3000, the first at build 2558 (E5.2: 1 in 3000, then 1443 and 1498 in two of 6000). Every one of the 87 uses a cottage, a Longbow Loft and a Firework Tower, the three kinds its third star allows.

So neither changes. E5.5 confirms both.

### 1.6 Runs at tier 1

E5.2 found 6 of 17 tier 1 bars missed. The cottage explains most of it (1.1). Three more fixes go to the level designer:

1. **b3_mossy_ruts, wave 1.** Scamps 12 to 8 and Pips 18 to 12. The four Mossbuds still come first. Without the cottage card in the pool this took the runs lost inside the pack from 22.6% to 6.3% (E5.2 section 5). With the stronger cottage, before this fix, it was 11.2% (bar 10%).
2. **The tunnel middles.** Since G3, every middle segment with two lanes lets the run's first gate make a detour (TUNING_RUNS.md 1.5). The three tunnel middles of E5.1 break that. On mid_hedge under top_fork and top_twin, the first gate cannot lengthen the road. On mid_tunnel above bot_yard, the shortest road already skips the tunnel, so a gate can only send walkers into it. On mid_burrow both lanes are equally long, so closing the tunnel lane gains no road. That is where the tunnel stacks lose: 26.0% against 43.9% for the other stacks, with the stronger cottage. The new grids put each tunnel on the shorter lane, so with no gates the walkers go through it, and the gate a run starts with closes the tunnel lane and sends them down a lane 2 steps longer, all of it in reach. That is region 5's lesson in a run: gate them out of the tunnel. On every one of the 22 stacks the best single gate now gives 2 to 4 more steps of road in reach than before (3.2). The wall `top_pair, mid_tunnel, bot_yard` goes from 16 to 20.
3. **Burrowbelly's packs.** With the stronger cottage, b6_burrow_deep won 52.7% of the runs that start wave 18, and b6_burrow_mist 73.9% (bar 50 to 75%). Fixes 1 and 2 make every tier 1 run a little stronger, which would push b6_burrow_mist over the bar. b6_burrow_deep's boss wave goes from strength 130 to 120 (3840 health), and b6_burrow_mist's from 120 to 140 (4480). By the slope G3 measured on other packs, about 0.6 points of win rate per point of strength, both land near the middle of the bar. b6_burrow_mist gets the stronger boss because it was the easier pack.

What I expect after E5.4, which E5.5 measures. On seeds 1 to 100 my cottage reads 36.1% for the 16 strategies and 51% for the best. There the tunnel stacks won 20.6% and the others 41.9%. If the new grids bring the tunnel stacks halfway to the others, and b3_mossy_ruts stops losing runs, the 16 should read about 40% (bar 35 to 55%) and the best about 55% (bar 55 to 75%). The best strategy is the bar at risk. If it stays under 55%, the next step is a what-if, on runs and on 5-2 to 5-6 together, of the cottage's tier 2 damage (14 to 16) and of Thorn Tips (2 to 3). Neither changes until measured.

The five tier 0 boss packs that stayed under 50% at tier 1 even with the stronger cottage should rise with the rest. If the two Moon Moth packs stay under 50% while every other bar holds, that is the bots: a quarter of their towers are now ground towers, and they never rebuild for a flying boss (open question 1).

### 1.7 The thin Twists, and 5-6 on Relaxed: no change

- 5-5 Five Lives: 80 of 1500 builds won. RULES 13 asks for one Normal win, and a Relaxed win (10 lives) also clears a Twist. 4-1's Thin Purse was as narrow (78 of 1500) and stayed (TUNING_CAMPAIGN.md 1.5). The stronger cottage widens it: the plain recipe now wins every placement of the level itself.
- 5-6 Double Trouble: 0 of 1500, then 0 and 2054 of 6000 in the two long searches. It is narrow but won, as 3-2's No Catapults was (TUNING_CAMPAIGN.md 1.3). Two Burrowbellies bring 4 Mistwisps at a time, which hide them from aim. Rings and splash hit through mist, so the stronger cottage widens this one most.
- 5-6 on Relaxed with no gates: 3 lives before, 7 with the stronger cottage. The bar is a win. The hint still teaches the boss, and the route lines show the tunnel roads.

If either Twist wins nothing in its three searches in E5.5, the first lever is the level's last wave: on 5-6 the boss wave's strength from 80 to 70 (2240 health for each Burrowbelly), on 5-5 one Dusk Moth fewer in each of waves 7, 10 and 12.

## 2. Changes per owner

### 2.1 Game designer (done in this step)

- data/stats/towers.json: the Bramble Cottage's two tiers and two paths, as in 1.1. Nothing else in data/stats/ changes.
- RULES.md: the change note; 5.1 (the cottage's weakness now reads "spots with little road near them"); 5.10 (its model rows, a note that the model overrates it, and the watch item); 5.12 (its table and how far each ring reaches); 12.4 (the four third stars and a paragraph on region 5); 12.5 (one line in "Third stars that bite"); 13 (5-4's Twist and a note); 14.3 (Burrowbelly's two boss waves).
- EXPANSION.md: notes in 4.3, 4.8 and 8 that point to this file and RULES.md for the current numbers.

### 2.2 Level designer (E5.4)

The DM passes these on; the same text is in the session's scratch folder as e5_handoff.md. In short: the third stars of r5_l1, r5_l3, r5_l4 and r5_l6 and the 5-4 Twist, with their rows in tests/levels/test_level_design.gd; new grids for mid_hedge, mid_tunnel and mid_burrow; in packs.json, b3_mossy_ruts wave 1 and the boss waves of b6_burrow_deep and b6_burrow_mist. No level's waves, map or hint change.

Keep every map, name, gate count, socket, tower list, starting gold, strength, hint, highlight and wave of every level, and every Twist but 5-4's. Make only the edits below. Each "before" is the current text, so you can search for it.

I applied exactly these edits to a clean copy of HEAD 3fb2285 with the new data/stats/towers.json: `godot --headless --path . --script res://tests/run_tests.gd -- --only=levels,run` gives "Ran 357 tests in 18 files: 357 passed, 0 failed." That run's smoke plays: 5-1 17 lives, 5-2 18, 5-3 18, 5-4 7 (with no gates), 5-5 16, 5-6 8. On an earlier copy (HEAD ed0ff35 with region 7 uncommitted) the run, UI and sim tests with these edits failed only the 3 tests that copy failed without them.

#### 2.2.1 Third stars (data/levels/)

r5_l1.json:

```
before: "star3": {"kind": "towers_at_most", "value": 6},
after:  "star3": {"kind": "towers_at_most", "value": 4},
```

r5_l3.json:

```
before: "star3": {"kind": "tower_ban", "tower": "lullaby_bell"},
after:  "star3": {"kind": "towers_at_most", "value": 4},
```

r5_l4.json, the third star and the Twist (the Twist's name, text and effect all change; the Twist used to ban the Sling Post, which is now the third star):

```
before: "star3": {"kind": "towers_at_most", "value": 7},
after:  "star3": {"kind": "tower_ban", "tower": "sling_post"},

before: "twist": {"name": "No Sling Posts", "text": "Sling Posts cannot be built.",
                  "effects": [{"type": "ban_tower", "tower": "sling_post"}]}
after:  "twist": {"name": "No Gates", "text": "You get no gates.",
                  "effects": [{"type": "set_gates", "count": 0}]}
```

r5_l6.json:

```
before: "star3": {"kind": "towers_at_most", "value": 8},
after:  "star3": {"kind": "towers_at_most", "value": 6},
```

The UI builds the sentences from the data: 5-1 "Have at most 4 towers.", 5-3 "Have at most 4 towers.", 5-4 "Build no Sling Posts.", 5-6 "Have at most 6 towers.". The 5-4 Twist's name and text are the same as 2-4's and 7-1's.

#### 2.2.2 The PLAN rows (tests/levels/test_level_design.gd)

```
before: "r5_l1": {..., "star3": ["towers_at_most", 6], "highlight": "socket"},
after:  "r5_l1": {..., "star3": ["towers_at_most", 4], "highlight": "socket"},
before: "r5_l3": {..., "star3": ["tower_ban", "lullaby_bell"], "highlight": "spot"},
after:  "r5_l3": {..., "star3": ["towers_at_most", 4], "highlight": "spot"},
before: "r5_l4": {..., "star3": ["towers_at_most", 7], "highlight": "spot"},
after:  "r5_l4": {..., "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
before: "r5_l6": {..., "star3": ["towers_at_most", 8], "highlight": "spot"},
after:  "r5_l6": {..., "star3": ["towers_at_most", 6], "highlight": "spot"},
```

The "..." parts do not change. In TWISTS, one row changes:

```
before: "r5_l4": [{"type": "ban_tower", "tower": "sling_post"}],
after:  "r5_l4": [{"type": "set_gates", "count": 0}],
```

#### 2.2.3 Run segments (data/segments/)

The rule since G3 (TUNING_RUNS.md 1.5): a middle with two lanes lets the run's first gate make a detour. The three tunnel middles break it. The new grids put each tunnel on the shorter lane, so with no gates walkers go through it, and one gate on the tunnel lane sends them down a lane 2 steps longer, all of it in reach. Each grid keeps its ports, its 4 build spots, and 2 or 3 sockets, and no socket touches a tunnel tile. Section 3.2 has the road in reach on all 22 stacks, before and after: the best single gate now adds 2 to 4 steps on every stack, and `top_pair, mid_tunnel, bot_yard` goes from 16 to 20.

mid_hedge.json, grid (top ports 1 and 5, bottom port 3; the east lane now runs out to column 6, so it is 2 steps longer than the tunnel lane):

```
before          after
".#.o.#.",      ".#.o.#.",
".##G##.",      ".##G###",
"oT.o.Go",      "oT.o.oG",
".#G###.",      ".#G####",
"...#..."       "...#..."
```

mid_tunnel.json, grid (top port 3, bottom ports 1 and 5; the tunnel moves to the east lane, which is now the shorter one on both bottoms, and the west lane runs out along column 0; the spot at (0, 0) moves to (1, 2), inside the west bend):

```
before          after
"o..#..o",      "...#..o",
".#G###.",      "####G#.",
".T.o.#.",      "Go.o.T.",
".T.o.G.",      "##.o.T.",
".#...#."       ".#...#."
```

mid_burrow.json, grid (top port 3, bottom port 3; the east lane runs out to column 6, 2 steps longer than the tunnel lane):

```
before          after
"o..#..o",      "o..#..o",
".#G###.",      ".#G####",
".T.o.Go",      ".T.o.oG",
".#####.",      ".######",
"...#..."       "...#..."
```

You may reshape these if you keep what they are for: on every stack, the best single gate gives at least 2 more steps of road outside tunnels than the old grid did, the tunnel lane is the shortest way with no gates, and every map rule still holds.

#### 2.2.4 Wave packs (data/segments/packs.json)

b3_mossy_ruts, wave 1: only two counts change.

```
before: {"groups": [{"enemy": "mossbud", "count": 4, "entrance": 1, "at_ms": 0, "every_ms": 1300}, {"enemy": "scamp", "count": 12, "entrance": 2, "at_ms": 7000, "every_ms": 300}, {"enemy": "pip", "count": 18, "entrance": 1, "at_ms": 14000, "every_ms": 150}]},
after:  {"groups": [{"enemy": "mossbud", "count": 4, "entrance": 1, "at_ms": 0, "every_ms": 1300}, {"enemy": "scamp", "count": 8, "entrance": 2, "at_ms": 7000, "every_ms": 300}, {"enemy": "pip", "count": 12, "entrance": 1, "at_ms": 14000, "every_ms": 150}]},
```

b6_burrow_deep, wave 3 (the boss wave): strength 130 to 120. Nothing else in the line changes.

```
before: {"strength": 130, "groups": [{"enemy": "burrowbelly", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "mossbud", ...
after:  {"strength": 120, "groups": [{"enemy": "burrowbelly", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "mossbud", ...
```

b6_burrow_mist, wave 3 (the boss wave): strength 120 to 140. Nothing else in the line changes.

```
before: {"strength": 120, "groups": [{"enemy": "burrowbelly", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "mender", ...
after:  {"strength": 140, "groups": [{"enemy": "burrowbelly", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "mender", ...
```

RULES 14.3's table already says 120 (3840 health) and 140 (4480).

#### 2.2.5 Not changed, on purpose

- No wave of any campaign level changes. 5-3 stays as built (1.3); 5-4 and 5-5 keep their waves after the stronger cottage (1.5).
- No hint changes, and no other Twist. Only 5-4's Twist changes (2.2.1 and 1.4).
- No tier 0 file. These edits touch only tier 1 segments and packs, so tier 0 runs and the tier 0 golden test do not move.
- Your region 7 work is untouched. The new cottage numbers reach regions 6 and 7 too: a level of yours that leaned on the old, weak cottage will play easier.

### 2.3 Balance analyst (E5.5)

Play everything on the commit that holds E5.3 and E5.4, from a clean copy, with the bots as you left them. Seeds as in E5.2 unless a row says otherwise.

#### 2.3.1 Campaign, region 5

1. The whole pass of region 5 (run_pass.sh and run_pass_post.sh for r5_l1 to r5_l6, SEED_SHIFT=100000), Twists included, so every table of your section 2 comes again on the new data.
2. The "All three stars" search on 5-4 uses only the towers its ban leaves (`mode=need` gives it from the level file). On 5-5 and 5-6 use 6000 builds, as for 3-3: their three stars are a hunt. With the new cottage my 3000 build searches found 87 on 5-5 (first at build 2558) and 77 and 172 on 5-6 (first at 2613 and 2345).
3. Lone Sling Post searches: none are new. 5-1 ("at most 4"), 5-3 ("at most 4") and 5-6 ("at most 6") have your E5.2 checks of two searches of 6000 builds each, and they still hold: no wave of those levels changes, and no lone Sling Post search uses the cottage. 5-4 bans the Sling Post, so it needs none. 5-2 and 5-5 as before. If your pass script plays them anyway, they should come back with no three-star build.
4. The Bramble Cottage's share of the three-star builds on 5-2 to 5-6, with each path. My searches found it in nearly all of them, mostly as a Holly Crown on 5-3 and 5-4 (3.1). In region 5 that is the plan. Report the same for regions 6 and 7 in their passes: the watch item of RULES 5.10 (the cottage in more than 9 of every 10 three-star builds on levels of regions 6 to 8) brings the Holly Crown's damage down from 24 to 20 first.
5. Random play on the four new third stars, and on the 5-4 Twist (No Gates).
6. Every region 5 Twist, the new 5-4 one included. The two thin ones, 5-5 Five Lives and 5-6 Double Trouble, need one Normal win in their 1500 build search or in two of 6000.
7. Optional, for the record: the forced lone Bramble Cottage searches of run_e52.sh BR on 5-2 and 5-4. RULES 12.6 needs none, because flyers cost 34 to 60 lives there.

#### 2.3.2 Runs and the daily

1. Tier 1, as in E5.2 (`TIER=1 ... run_b4.sh A 4`): the 16 strategies on seeds 1 to 200, Normal and Relaxed, base cards and every card, the card experiment, the risk replay, and the daily at tier 1 over 400 days.
2. Phase C for the stacks that changed: every stack that holds mid_hedge, mid_tunnel or mid_burrow, forced onto seeds 1 to 200 with `stop=6` (22 stacks). The bar: none loses more than 10% by wave 6.
3. The two Burrowbelly packs: 50% to 75% of the runs that start wave 18.
4. Tier 0: the tier 0 golden test is enough. No tier 0 file changed. If you want the proof in numbers, one `rates` job at tier 0 equal to B5's row is plenty.

Bars, from RULES 14.8 and 15: the 16 at 35% to 55%, the best at 55% to 75%, each band 6 pack 50% to 75%, each segment at least 0.75 of all runs, no stack of 4 or more seeds losing more than 10% by wave 6, no pack of bands 1 to 5 losing more than 10% inside.

What I expect: the 16 at about 40% and the best at about 55%, the bar most at risk (1.6). If a tier 0 boss pack stays under 50% at tier 1 while every other bar holds, report which and by how much, and whether the run's towers at wave 18 can hit its boss. The Moon Moth packs are the ones to watch (open question 1).

#### 2.3.3 Regions 6 and 7

The cottage's new numbers apply there from now on. Their passes (E6.2 and E7.2) measure them on these numbers. Nothing extra here.

### 2.4 Everyone else

No test outside tests/levels pins the cottage's numbers, region 5's third stars or its Twists, so the DM gets no test patch, and there is no e5_dm_test_patches.diff. The whole suite passes on a clean copy of HEAD 3fb2285 with this step (3.3).

## 3. Evidence

### 3.1 My searches

On a copy of the working tree of HEAD ed0ff35 with the then uncommitted region 7 files, with the bots of tools/balance as E5.2 left them, from its root. Since then neither region 5's data nor the bots changed. The sim did (S12, load ceilings for numbers that grow in play), and the smoke plays of regions 5 to 7 came out the same on the new HEAD (3.3). The new cottage came in through `towers=`, the third stars through `tweak=star3:`. Outcomes are builds lost / won with 1, 2 and 3 stars.

Searches. "Analyst's cottage" is E5.2's what-if (tier 1 damage 8 at ring 2.5); every other row has the new numbers of 1.1. The lone Sling Post searches use no cottage, so the numbers do not matter there.

| Level, rule, towers | Seed | Builds | Lost / 1 / 2 / 3 stars | First three-star build | What the three-star builds hold |
|---|---|---|---|---|---|
| 5-4, Use no gates., any tower (analyst's cottage) | 534000 | 3000 | 1251 / 237 / 190 / 1322 | 210 | a cottage in all 1322, a Catapult in 408 |
| 5-4, Use no gates., lone Sling Post | 534001 | 6000 | 3361 / 1112 / 483 / 1044 | 2700 | Sling Posts and Bells |
| 5-4, Use no gates., lone Sling Post | 534011 | 6000 | 3160 / 1070 / 557 / 1213 | 2959 | 610 of them with no Bell |
| 5-4, Use at most 1 gate., any tower (analyst's cottage) | 534100 | 3000 | 1268 / 224 / 121 / 1387 | 102 | a cottage in all 1387 |
| 5-4, Use at most 1 gate., lone Sling Post | 534111 | 6000 | 3155 / 1152 / 134 / 1559 | 2270 | (its twin, seed 534101, was stopped once this one had failed the rule) |
| 5-4, Build no Sling Posts., every tower but the Sling Post | 535400 | 3000 | 1317 / 193 / 0 / 1490 | 42 | a cottage in all 1490 (Holly Crown 1410), a Catapult in 614, a Longbow Loft in 782 |
| 5-4, Have at most 4 towers., any tower | 535440 | 3000 | 1536 / 356 / 162 / 946 | 1002 | a Sling Post in all 946, a cottage in 930, a Catapult in 81 |
| 5-4, Have at most 4 towers., lone Sling Post | 535441 | 6000 | 3144 / 483 / 2373 / 0 | none | |
| 5-4, Have at most 4 towers., lone Sling Post | 535451 | 6000 | 4063 / 978 / 288 / 671 | 2663 | fails |
| 5-3, Have at most 4 towers., any tower | 535300 | 3000 | 1470 / 305 / 245 / 980 | 33 | a cottage in all 980 (Holly Crown 823), a Catapult in 61 |
| 5-2, its rule (No tower above tier 2.), any tower | 535200 | 3000 | 1418 / 321 / 189 / 1072 | 1057 | a cottage in all 1072, a Catapult in 1069, a Longbow Loft in 186 |
| 5-5, its rule (Use at most 3 kinds of tower.), any tower | 535500 | 3000 | 1999 / 862 / 52 / 87 | 2558 | a cottage, a Longbow Loft and a Firework Tower in all 87 |
| 5-6, Have at most 6 towers., any tower | 535600 | 3000 | 1821 / 291 / 811 / 77 | 2613 | a cottage in 73; a Catapult, a Longbow Loft and a Firework Tower in all 77 |
| 5-6, Have at most 6 towers., any tower | 535620 | 3000 | 1894 / 117 / 817 / 172 | 2345 | a cottage in 171; a Sling Post, a Longbow Loft, a Firework Tower and a Bell in all 172 |
| 5-3, Build no Sling Posts., every tower but the Sling Post (not chosen) | 535310 | 3000 | 1334 / 211 / 0 / 1455 | 1 | a cottage in 1420, a Catapult in 1233, a Longbow Loft in 1182 |
| 5-6, Build no Sling Posts., every tower but the Sling Post (not chosen) | 535610 | 3000 | 1736 / 157 / 0 / 1107 | 1046 | a cottage in 1103, a Catapult in 995 |

The plain mixed recipe with the new numbers, Normal and Relaxed, every gate placement (`mode=plain`): the table of 1.1. With the analyst's cottage it is E5.2's what-if table (`whatif_plain`), which differs from mine on 5-2 (no gates: 13 lives, not 5) and on 5-5 (29 of 29 placements won, not 4; no gates won with 8).

Runs at tier 1 (`runs.gd mode=rates`, base cards, Normal, the 16 strategies):

| Cottage | Seeds | The 16 together | Best strategy | Tunnel stacks / other stacks | Runs that start wave 18 won, by boss |
|---|---|---|---|---|---|
| As built (E5.2) | 1 to 100 | 22.8% | 39.0% | 9.3% / 27.8% | Burrowbelly 52.9%, Grumblesack 39.5%, Ironshell 40.7%, Moon Moth 44.3%, Old Tusk 41.9% |
| No cottage card (E5.2) | 1 to 100 | 46.4% | 69.0% | 31.7% / 51.9% | 70.4%, 67.0%, 59.7%, 63.8%, 63.5% |
| Analyst's (E5.2) | 1 to 100 | 36.9% | 52.0% | 22.7% / 42.2% | 60.4%, 57.3%, 50.8%, 42.7%, 52.9% |
| Mine | 1 to 100 | 36.1% | 51.0% | 20.6% / 41.9% | 60.1%, 57.3%, 50.9%, 42.9%, 52.5% |

Each row is 1600 plays. Seeds 1 to 50 alone: mine 37.2%, the analyst's 38.2%, both with a best of 56%.

### 3.2 Road in reach on the tunnel stacks

Steps of the shortest route that are not in a tunnel, for the entrance with the fewest. "Best gate" is the best single gate, the one a run starts with. Worked out from the grids with the routing rule of RULES 7.3.

| Stack | Old: no gate | Old: best gate | New: no gate | New: best gate |
|---|---|---|---|---|
| top_twin, mid_hedge, bot_square | 12 | 13 | 12 | 15 |
| top_twin, mid_hedge, bot_porch | 14 | 15 | 14 | 17 |
| top_fork, mid_hedge, bot_square | 14 | 15 | 14 | 17 |
| top_fork, mid_hedge, bot_porch | 16 | 17 | 16 | 19 |
| top_wing, mid_hedge, bot_square | 17 | 22 | 17 | 24 |
| top_wing, mid_hedge, bot_porch | 19 | 24 | 19 | 26 |
| top_bend, mid_tunnel, bot_gate | 20 | 22 | 20 | 24 |
| top_bend, mid_tunnel, bot_yard | 21 | 21 | 19 | 25 |
| top_side, mid_tunnel, bot_gate | 22 | 24 | 22 | 26 |
| top_side, mid_tunnel, bot_yard | 23 | 23 | 21 | 27 |
| top_meet, mid_tunnel, bot_gate | 15 | 17 | 15 | 19 |
| top_meet, mid_tunnel, bot_yard | 16 | 16 | 14 | 20 |
| top_pair, mid_tunnel, bot_gate | 15 | 17 | 15 | 19 |
| top_pair, mid_tunnel, bot_yard | 16 | 16 | 14 | 20 |
| top_bend, mid_burrow, bot_square | 21 | 22 | 21 | 24 |
| top_bend, mid_burrow, bot_porch | 23 | 24 | 23 | 26 |
| top_side, mid_burrow, bot_square | 23 | 24 | 23 | 26 |
| top_side, mid_burrow, bot_porch | 25 | 26 | 25 | 28 |
| top_meet, mid_burrow, bot_square | 16 | 17 | 16 | 19 |
| top_meet, mid_burrow, bot_porch | 18 | 19 | 18 | 21 |
| top_pair, mid_burrow, bot_square | 16 | 17 | 16 | 19 |
| top_pair, mid_burrow, bot_porch | 18 | 19 | 18 | 21 |

With no gates, the walkers on the bot_yard stacks of mid_tunnel now go through the tunnel (2 steps fewer in reach), as they do on every other tunnel stack. The gate a run starts with is what takes them out.

### 3.3 Tests

All on copies in the session's scratch folder, never on the repo itself.

- A clean copy of HEAD 3fb2285 (region 7 committed) with this step's four files (data/stats/towers.json, RULES.md, EXPANSION.md and this file): `godot --headless --path . --script res://tests/run_tests.gd` gives "Ran 1618 tests in 116 files: 1618 passed, 0 failed."
- The same copy with every E5.4 edit of 2.2: `-- --only=levels,run` gives "Ran 357 tests in 18 files: 357 passed, 0 failed."
- The level smoke test in that `levels,run` run plays one fixed recipe on every level. Lives left, before and after: 5-1 17 / 17, 5-2 18 / 18, 5-3 18 / 18, 5-4 7 / 7 (now with no gates), 5-5 13 / 16, 5-6 6 / 8; 6-1 17 / 17, 6-2 19 / 20, 6-3 7 / 9, 6-4 17 / 17, 6-5 11 / 20, 6-6 7 / 7; every region 7 level the same. Every level stays inside 5 to 10 minutes at 1x.
- Earlier, on HEAD ed0ff35 with region 7 still uncommitted, the whole suite with this step and every E5.4 edit failed only the 3 tests that the same tree failed without them, all from region 7's data, since fixed in HEAD.

### 3.4 How to repeat

From the root of a copy of the commit that holds this step (so data/stats/towers.json holds the new cottage), after `godot --headless --path . --import`. The level designer's E5.4 edits are not needed for these: `tweak=star3:` sets a third star in memory. The analyst's tier 1 ring of 2.5 is `towers=` with a copy of towers.json whose cottage tiers read damage 8 and 14 at reach 250, and paths 20 at 300 and 24 at 250, as E5.2's `towers_d2r250.json`.

```
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r5_l4 seed=534001 evals=6000 stop_dry=2500 only=solo:sling_post "tweak=star3:gates_at_most;0" out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r5_l4 seed=534000 evals=3000 only=any "tweak=star3:gates_at_most;0" towers=PATH/towers_d2r250.json out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r5_l4 seed=535400 evals=3000 only=lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower,bakery,bramble_cottage "tweak=star3:tower_ban;sling_post" out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r5_l3 seed=535300 evals=3000 only=any "tweak=star3:towers_at_most;4" out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r5_l5 out=OUT.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=base relaxed=0 tier=1 out=OUT.json
```

The other searches of 3.1 differ only in level, seed and rule. The second `rates` job is `first=51`. The road table of 3.2 comes from the grids with the routing rule of RULES 7.3 (a breadth first search from the base, the tie break south, west, east, north); the session's scratch folder holds the small script (e53_py/segtable.py).

## 4. For Bart

These change what Bart approved, so the DM tells him. Under the night rule of 2026-10-28 they go ahead now.

1. **The Bramble Cottage hits harder and reaches further.** Damage 4, 7, 10 and 12 (tier 1, tier 2, Wild Bramble, Holly Crown) becomes 10, 14, 20 and 24. Its rings of 1.5, 1.5, 2.0 and 1.5 become 2.0, 2.5, 3.0 and 2.5, so they grow as a Bell's and a Scarecrow's do. Prices and card lines stay. Why: it was weak on its own levels and a trap card in runs. Its card cost the run bots 23 points.
2. **Four third stars change.** 5-1 and 5-3 now allow 4 towers, 5-4 bans the Sling Post, and 5-6 allows 6 towers (section 5 has the exact lines). Why: under the old ones, Sling Posts alone could earn all three stars on these levels.
3. **Level 5-4's Twist changes** from No Sling Posts to No Gates, because its third star now bans the Sling Post.
4. **Runs that include region 5 content** (after 5-6 is cleared): three tunnel map pieces change shape, so the first gate can steer walkers out of the tunnel; the first Mossbud wave is smaller; and Burrowbelly's two run boss waves change strength. Why: those runs lost far more often than runs of regions 1 to 4.

No hint, card line, run card text or creature line changes.

## 5. Every text a player sees that changes

Every line below shows on a level card, in Pause, in a panel or in the Info screen. Card lines, hints, run card texts and creature lines do not change.

| Where | Before | Now |
|---|---|---|
| 5-1 Under the Hedges, third star | Have at most 6 towers. | Have at most 4 towers. |
| 5-3 Mossy Hollow, third star | Build no Lullaby Bells. | Have at most 4 towers. |
| 5-4 Mist Lane, third star | Have at most 7 towers. | Build no Sling Posts. |
| 5-6 Burrowbelly, third star | Have at most 8 towers. | Have at most 6 towers. |
| 5-4 Mist Lane, Twist name | No Sling Posts | No Gates |
| 5-4 Mist Lane, Twist card text | Sling Posts cannot be built. | You get no gates. |
| Bramble Cottage panels and Info, damage (tier 1, tier 2, Wild Bramble, Holly Crown) | 4, 7, 10, 12 | 10, 14, 20, 24 |
| Bramble Cottage panels and Info, ring | 1.5, 1.5, 2.0, 1.5 tiles | 2.0, 2.5, 3.0, 2.5 tiles |
| Run previews and creature cards, Burrowbelly's health in its two run packs (boss wave) | 4160 (b6_burrow_deep), 3840 (b6_burrow_mist) | 3840, 4480 |
| Run preview of b3_mossy_ruts' first wave | 4 Mossbuds, 12 Scamps, 18 Pips | 4 Mossbuds, 8 Scamps, 12 Pips |

The sentences come from the data (contract 2.7), so the UI changes nothing. The two Twist lines are the same as 2-4's and 7-1's.

## 6. Open questions

1. **For the DM, after E5.5:** if every tier 1 bar holds except the two Moon Moth packs (under 50% of the runs that start wave 18), do we read that as the bots? At tier 1 a quarter of the bots' towers are ground towers, which cannot touch a flying boss, and the bots never rebuild for the boss (RULES 14.8 calls the bots a floor for that reason). My advice: yes, if E5.5 shows those runs reach wave 18 with fewer towers that hit flyers than at tier 0. The Snow Fort at tier 3 will raise the same question.
2. **For the DM, for planning:** the new cottage reaches regions 6 and 7. The level smoke test shows region 6 easier: 6-5 from 11 lives to 20, 6-3 from 7 to 9 (3.3). Region 7 does not move. E6.2 should measure region 6 on the new numbers before its tuning, and the level designer may find a region 6 level that leaned on the old, weak cottage.

## 7. Suggestions beyond the task

1. A rule for the run bots that keeps their share of towers that can hit flyers when a ground tower joins the run, as a thinking player does. It would let the tier bars measure the runs rather than the bots' habits, here and at tier 3. It is the balance analyst's call, and it changes no game rule.
2. The new mid_tunnel runs its west lane along the left edge of the map. The art director may want a look on the phone, though roads on the edge are already common.
