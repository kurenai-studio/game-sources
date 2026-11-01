# Region 2 tuning plan

Owner: game designer. 2026-10-24 (task G2). Answers the region 2 balance report docs/balance/region2-2026-10-24.md (B1, commit ec871fc). RULES.md holds the rules and numbers; this file says what changed for region 2, why, and exactly what the level designer types in. Section 7 answers the level designer's open questions from region 3.

## 1. Decision

The "No super tower" check now passes on all six region 2 levels, with five of their six third stars kept as Bart approved them. One creature number changes (Ironshell's armor), four levels get small wave changes, and one third star changes (2-2). There is no contract change.

### 1.1 The check stays as set at G1

The check stays "one attacking tower plus the level's Bells and Bakeries" (RULES 12.6). Relaxing it to the brief's literal words would not help, so there is nothing to ask Bart. In B1's own searches, a lone attacker with no Bell at all still earned three stars on five of the six levels:

| Level | Lone-attacker three-star builds in B1 | Of them with no Bell |
|---|---|---|
| 2-1 | 925 (Sling Post) | 925 (2-1 offers no Bell) |
| 2-2 | 252 (Sling Post) | 0 |
| 2-3 | 1764 (Pumpkin Catapult) | 269 |
| 2-4 | 1203 (Sling Post) | 133 |
| 2-5 | 609 (Sling Post) | 142 |
| 2-6 | 1873 (Sling Post) | 1500 |

### 1.2 The cause, one step further than B1

B1 is right that flyers make the Sling Post required: on every level with Flitters, nothing else can stop them. But being required does not make a tower enough. What made it enough is that, given time and gold, tier 3 Sling Posts and Bells can buy their way through almost any region 2 wave:

- On 2-3, which has no flyers, a lone Sling Post still earned three stars under a Catapult ban (415 builds, B1).
- On 2-4, four tier 3 Sling Posts, most often with nothing else, earned three stars with 20 lives under "Have at most 4 towers" (285 builds).
- B1's lone-Sling champions on 2-1 end the level with 700 to 1100 gold unspent.
- The level designer met the same thing on 3-2 ("7 towers let Sling Posts alone reach three stars") and in the first drafts of region 4.

So the fix is to give each level something a lone Sling Post cannot buy its way through:

1. **A dense crowd before the gold.** Early, gold is short and tier 3 is far away. A crowd of 36 to 40 Pips 0.05 s apart by wave 5, at strength 115 or less, is easy work for Catapults and too much for pebbles. On 2-1, 2-4 and 2-5 this one change took the lone Sling Post's best under each level's third star from 19 or 20 lives to 10, 13 and 9, in two searches of 6000 builds each, while mixed builds keep all 20.
2. **A shell that only arrows pierce.** Ironshell's armor goes from 6 to 10. A Stone Sling now does 10 per hit instead of 14, a Quickshot 1 instead of 2. A lone Sling Post can no longer beat the boss at all: it won none of 12,000 builds in two searches. Giant Bows ignore armor, and mixed builds still find 821 three-star wins on 2-6.
3. **A short road on the Bell level.** Level 2-2's third star becomes "Use no gates." Without the gate the road is 17 steps instead of 25. Single-target towers need time, so they need a long road; Bells and splash need a packed crowd, so they hold a short road too. A lone Sling Post never won 2-2 without a gate, and Bells are in 89% of the three-star wins.
4. **Flyers on the armor level.** Level 2-3 gets 2 Flitters in each of waves 4, 6 and 8 (B1's S2, smaller). A tower that cannot hit flyers lets all 6 through, so it can never keep 15 lives there. That is certain, not a search result. The tier 2 cap still stops the Sling Post.

### 1.3 What I chose not to do

- **Tier caps on 2-1, 2-2, 2-4 and 2-5 (B1's S1).** They work, but region 2 would then have five "No tower above tier 2" rules right after region 1's four tier caps. It would also lock tier 3, which arrives on 1-6, out of three-star play for most of region 2, and drop the third stars that teach each level's idea (early calls on 2-1, a gate limit on 2-4, a Longbow ban on 2-5). With this plan region 2 has one tier cap (2-3), as before.
- **"Have at most 4 towers".** It works on 2-2 (B1) but not on 2-1 (16 lone-Sling three-star builds), 2-4 (285) or 2-5 (32).
- **A weaker Sling Post.** Replays of the lone-Sling champions with a slower Quickshot (0.25 s or 0.3 s), a 7 damage Quickshot, or a 16 damage Stone Sling showed a cliff, not a slope. With the 0.25 s Quickshot, every 2-1 champion that kept 15 to 17 lives lost in wave 9 or 10. The same cliff would hit ordinary mixed builds (the Quickshot is in 4133 of B1's 9853 three-star wins) and every run, where the Sling Post is the starting tower.
- **"Use no gates" on 2-1, 2-4 or 2-5.** It works on all three (section 5.2), but 2-4's Twist is No Gates, so the two would be the same challenge. On 2-1 and 2-5 the original third stars now hold, and they teach more.
- **A softer wave 3 on 2-2 (B1's S4).** See section 6.
- **Ironshell armor 8.** It also stopped the lone Sling Post in a 2500 build search, but one of B1's 28 lone-Sling champions still won 2-6 with 20 lives at armor 8. At armor 10, none of them did.
- **More Ironshell health instead of armor.** Health slows every build down alike, Giant Bows included. Armor only hurts the towers that should not carry this boss.
- **A weaker Bell.** Bells are what let a lone Sling Post hold crowds: a slow gives every tower in its ring more time, single-target towers too, not only splash (RULES 5.10's note that a Bell is a poor pick without splash was wrong, and the bots show it). But Bells were in only 1307 of B1's 5569 region 2 three-star wins (23%), so a weaker Bell would be a dead tower in mixed play. The new rules work on the same weakness without touching the Bell: a Bell does not help much against a dense crowd while gold is short, and on 2-2's short road the Bell's partner has to be splash. In the G2 three-star wins Bells are in 1907 of 5247 (36%, section 4).

### 1.4 Region 2's third stars after G2

| Level | Third star | Changed? |
|---|---|---|
| 2-1 | Call 6 waves early. | no |
| 2-2 | Use no gates. | yes, was "Have at most 6 towers." |
| 2-3 | No tower above tier 2. | no |
| 2-4 | Use at most 1 gate. | no |
| 2-5 | Build no Longbow Lofts. | no |
| 2-6 | Use at most 3 kinds of tower. | no |

## 2. Number changes in data/stats/ (done)

| What | Before | After | Why |
|---|---|---|---|
| Ironshell armor | 6 | 10 | Its lesson is "pierce its shell". At 6 a Stone Sling did 70% of its damage to it and a lone Sling Post beat it. |
| Ironshell card line (enemies.json `info`, RULES 6.6) | Armor 6. It gets faster each time it loses a quarter of its health. | Armor 10. It gets faster each time it loses a quarter of its health. | The number on the card. |

Nothing else in data/stats/ changes. RULES 5.10's Ironshell columns are recomputed: tier 1 Catapult 3.3 to 1.7; tier 3 Quickshot 2.4 to 1.2, Stone Sling 6.8 to 4.9, Prize Pumpkin 3.7 to 3.3, Jam Pot 2.5 to 1.9. The Longbow, Giant Bow and Triple Bow values do not move, because they ignore armor.

Damage to Ironshell per hit, before and after:

| Tower | Armor 6 | Armor 10 |
|---|---|---|
| Sling Post, tier 1 or 2, and Quickshot | 1 to 2 | 1 |
| Stone Sling | 14 | 10 |
| Pumpkin Catapult tier 1, tier 2, Jam Pot | 8, 18, 18 | 4, 14, 14 |
| Prize Pumpkin | 44 | 40 |
| Longbow Loft (every tier) | full | full |

Where Ironshell appears: only level 2-6 in the campaign, and in runs the band 6 packs `b6_iron_road` and `b6_iron_gate` (section 8).

## 3. Instructions for the level designer

For every region 2 level keep the map, name, gates, sockets, towers, starting gold, hint, highlight and Twist. Make only the changes below. Every time stays a multiple of 50 ms, no wave gains a new creature, and the largest wave stays 80 (2-2). The tested files are in the scratch folder named in section 5.6 if you want to copy them.

tests/levels/test_level_design.gd needs one new PLAN value: `"r2_l2"` star 3 `["gates_at_most", 0]`.

### 2-1 Mill Race

Star 3 unchanged: Call 6 waves early. Wave 5's Pip crowd is bigger and dense (30 to 36 Pips, 0.1 s to 0.05 s apart). Wave 10 drops from strength 120 to 115, so its Pips have 24 health and one tier 2 pumpkin pops each (at 120 they had 25 and took two).

Wave 5, before and after:

```json
{"strength": 110, "groups": [{"enemy": "pip", "count": 30, "entrance": 1, "at_ms": 0, "every_ms": 100}, {"enemy": "skitter", "count": 8, "entrance": 1, "at_ms": 5000, "every_ms": 900}]}
{"strength": 110, "groups": [{"enemy": "pip", "count": 36, "entrance": 1, "at_ms": 0, "every_ms": 50}, {"enemy": "skitter", "count": 8, "entrance": 1, "at_ms": 5000, "every_ms": 900}]}
```

Wave 10, before and after:

```json
{"strength": 120, "groups": [{"enemy": "skitter", "count": 16, "entrance": 1, "at_ms": 0, "every_ms": 700}, {"enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 4000, "every_ms": 400}, {"enemy": "pip", "count": 40, "entrance": 1, "at_ms": 9000, "every_ms": 100}]}
{"strength": 115, "groups": [{"enemy": "skitter", "count": 16, "entrance": 1, "at_ms": 0, "every_ms": 700}, {"enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 4000, "every_ms": 400}, {"enemy": "pip", "count": 40, "entrance": 1, "at_ms": 9000, "every_ms": 100}]}
```

### 2-2 Sleepy Mill

Star 3: Use no gates. Before: Have at most 6 towers. Data: `"star3": {"kind": "gates_at_most", "value": 0}`. The waves do not change.

### 2-3 Shell Road

Star 3 unchanged: No tower above tier 2. Waves 4, 6 and 8 each gain one Flitter group, second in the wave's list because it starts at 2.0 s, before the groups that follow it:

```json
{"enemy": "flitter", "count": 2, "entrance": 1, "at_ms": 2000, "every_ms": 400}
```

Waves 4, 6 and 8 after:

```json
{"strength": 110, "groups": [{"enemy": "pip", "count": 24, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "flitter", "count": 2, "entrance": 1, "at_ms": 2000, "every_ms": 400}, {"enemy": "shellback", "count": 3, "entrance": 1, "at_ms": 6000, "every_ms": 2000}]}
{"strength": 115, "groups": [{"enemy": "pip", "count": 40, "entrance": 1, "at_ms": 0, "every_ms": 100}, {"enemy": "flitter", "count": 2, "entrance": 1, "at_ms": 2000, "every_ms": 400}, {"enemy": "shellback", "count": 5, "entrance": 1, "at_ms": 4000, "every_ms": 1600}, {"enemy": "skitter", "count": 8, "entrance": 1, "at_ms": 10000, "every_ms": 900}]}
{"strength": 115, "groups": [{"enemy": "pip", "count": 50, "entrance": 1, "at_ms": 0, "every_ms": 50}, {"enemy": "flitter", "count": 2, "entrance": 1, "at_ms": 2000, "every_ms": 400}, {"enemy": "shellback", "count": 7, "entrance": 1, "at_ms": 5000, "every_ms": 1400}, {"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 8000, "every_ms": 1300}]}
```

Why 2 each and not B1's 2, 3 and 4: 6 Flitters are the fewest that take a tower which cannot hit flyers below 15 lives (20 minus 6 is 14). B1's 9 cost the plain recipe 9 lives, these cost it 6 (section 4).

### 2-4 Two Bridges

Star 3 unchanged: Use at most 1 gate. Wave 5's Pip crowd is bigger and dense (28 to 40 Pips, 0.1 s to 0.05 s apart). Wave 5, before and after:

```json
{"strength": 110, "groups": [{"enemy": "pip", "count": 28, "entrance": 1, "at_ms": 0, "every_ms": 100}, {"enemy": "skitter", "count": 8, "entrance": 1, "at_ms": 5000, "every_ms": 800}, {"enemy": "shellback", "count": 2, "entrance": 1, "at_ms": 12000, "every_ms": 2000}]}
{"strength": 110, "groups": [{"enemy": "pip", "count": 40, "entrance": 1, "at_ms": 0, "every_ms": 50}, {"enemy": "skitter", "count": 8, "entrance": 1, "at_ms": 5000, "every_ms": 800}, {"enemy": "shellback", "count": 2, "entrance": 1, "at_ms": 12000, "every_ms": 2000}]}
```

### 2-5 Bubble Brook

Star 3 unchanged: Build no Longbow Lofts. Wave 4's Pip crowd is bigger and dense (24 to 36 Pips, 0.1 s to 0.05 s apart). Wave 4, before and after:

```json
{"strength": 110, "groups": [{"enemy": "pip", "count": 24, "entrance": 1, "at_ms": 0, "every_ms": 100}, {"enemy": "bubbler", "count": 4, "entrance": 1, "at_ms": 5000, "every_ms": 1300}]}
{"strength": 110, "groups": [{"enemy": "pip", "count": 36, "entrance": 1, "at_ms": 0, "every_ms": 50}, {"enemy": "bubbler", "count": 4, "entrance": 1, "at_ms": 5000, "every_ms": 1300}]}
```

Not 30: with 30 Pips a 6000 build search found 225 lone-Sling three-star builds at exactly 15 lives, the first at build 4783, though a 2500 build search had found none (section 5.1).

### 2-6 Ironshell

No change to the level file. Ironshell's armor 10 comes from data/stats/.

### Region 3 and 4

No change is needed for G2. Section 8 lists what to check when you next run your searches.

## 4. Results: every RULES 12.6 check on the new region 2

All Normal unless a column says Relaxed. "Lone Sling" is the Sling Post plus the level's Bells: two searches of 6000 builds per level (section 5.1). The any-tower searches tried 2500 builds.

| Level | Lone Sling, B1: three-star builds; best lives | Lone Sling, G2: three-star builds; best lives under the level's third star | Any tower, G2: three-star builds (first found at); best lives | Plain recipe, Normal: best placement / no gates | Plain, Relaxed: no gates / best | Bar |
|---|---|---|---|---|---|---|
| 2-1 | 565 and 360; 20 | 0 and 0; 10 | 888 (489); 20 | 18 / 10 (B1: 18 / 12) | 40 / 40 | 15 lives: met |
| 2-2 | 252 in 6000; 19 | 0 and 0; it never won without a gate | 898 (39); 20 | 19 / lost in wave 3 (unchanged) | 39 / 39 | 15 lives: met |
| 2-3 | Catapult 841 and 923; 20 | 0 and 0; the Sling Post never won under the tier cap. The Catapult can keep at most 14 lives, by the flyers | 617 (895); 20 | 9 / lost in wave 6 (B1: 15) | 30 / 34 | win: met |
| 2-4 | 730 and 473; 20 | 0 and 0; 13 | 1023 (782); 20 | 18 / lost in wave 4 (B1: 14) | 14 / 38 | win: met |
| 2-5 | 336 and 273; 20 | 0 and 0; 9 | 1000 (496); 20 | 16 / lost in wave 4 (B1: 15) | 18 / 36 | win: met |
| 2-6 | 373 and 0; 20 | 0 and 0; it never won: it dies at the boss | 821 (914); 20 | 12 / lost in wave 6 (B1: 13) | 5 / 37 | win: met |

Lone Pumpkin Catapult and lone Longbow Loft: every region 2 level now has flyers worth 6 lives or more (2-1: 20, 2-2: 32, 2-3: 6, 2-4: 31, 2-5: 22, 2-6: 21). A tower that cannot hit flyers lets all of them through, so it can never keep 15 lives on any of them (RULES 12.6). On 2-1, 2-2, 2-4, 2-5 and 2-6 it cannot even win, since the flyers alone cost 20 lives or more.

Tower use in the G2 three-star builds (any-tower searches): the Sling Post is in every one, and the Pumpkin Catapult in every one but a single 2-6 build. Bells: 2-1 none offered, 2-2 795 of 898, 2-3 234 of 617, 2-4 620 of 1023 (Hush Bell 385), 2-5 258 of 1000, 2-6 0 of 821. On 2-5 the Jam Pot is in 743 of the 1000: it fires often enough that every other shot gets past a bubble. Longbow Lofts: 2-3 207 of 617, 2-4 391 of 1023, 2-6 821 of 821 (Giant Bow 796). Every region 2 tower is in some three-star win.

Twists, Normal (RULES 13: some strategy wins):

| Level | Twist | Plain recipe | Search, 1500 builds |
|---|---|---|---|
| 2-1 | Hurry | won, 17 lives (2 of 4 placements) | not needed |
| 2-2 | No Bells | waves unchanged: B1's 4 of 4, 20 lives | B1: 867 wins |
| 2-3 | Thick Shells | won, 1 life (1 of 4) | 715 wins |
| 2-4 | No Gates | lost in wave 4 (as in B1) | 605 wins, best 20 lives (B1: 561) |
| 2-5 | Bubble Night | lost in wave 4 (as in B1) | 208 wins, best 13 lives (B1: 146, best 16) |
| 2-6 | Stuck Gates | lost to the boss in wave 12 (B1: won, 13 lives) | 448 wins, best 20 lives (B1: 337) |

Not rerun here, for B3: random play, level length and the size and speed checks. No change here should move them much: the largest wave stays 80 (2-2), 2-4's wave 5 grows from 38 to 50 creatures and 2-5's wave 4 from 28 to 40, and the dense crowds make those waves shorter, not longer.

## 5. Evidence

### 5.1 Full-size confirmations: two lone Sling Post searches of 6000 builds per level (RULES 12.6 as now written)

Each row is one search of 6000 builds on the level as section 3 leaves it. Outcomes are wins with 1, 2 and 3 stars. "Under the rule" counts the wins that met the level's third star.

| Level | Seed | Wins (1 / 2 / 3 stars) | Wins under the rule, best lives | Three-star builds |
|---|---|---|---|---|
| 2-1 | 922101 | 2122 (2122 / 0 / 0) | 1178, 10 | 0 |
| 2-1 | 922111 | 2307 (2307 / 0 / 0) | 1401, 10 | 0 |
| 2-2 | 922201 | 1276 (1276 / 0 / 0) | 0 | 0 |
| 2-2 | 922211 | 1448 (1448 / 0 / 0) | 0 | 0 |
| 2-3 | 922301 | 2182 (811 / 1371 / 0) | 0 | 0 |
| 2-3 | 922311 | 2157 (853 / 1304 / 0) | 0 | 0 |
| 2-4 | 922401 | 2068 (1159 / 909 / 0) | 0 | 0 |
| 2-4 | 922411 | 1990 (1990 / 0 / 0) | 1609, 13 | 0 |
| 2-5 | 923501 | 324 (324 / 0 / 0) | 324, 6 | 0 |
| 2-5 | 923511 | 1235 (1235 / 0 / 0) | 1235, 9 | 0 |
| 2-6 | 922601 | 0 | 0 | 0 |
| 2-6 | 922611 | 0 | 0 | 0 |

What the rows say: on 2-3 and 2-4 a lone Sling Post can still keep 15 or more lives, but only by breaking the third star (tier 3 on 2-3, both gates on 2-4). On 2-1 and 2-5 it cannot keep 15 lives at all, on 2-2 it cannot win without a gate, and on 2-6 it cannot win.

The first try at 2-5, with 30 Pips in wave 4, failed this check: seed 922501 found 225 three-star builds at exactly 15 lives, the first at build 4783, while the 2500 build search (seed 907501) had found a best of 14. Each of those builds lost exactly 5 lives in wave 4 and none after, so wave 4 now has 36 Pips. That is S8's point made again: 2500 builds can miss what 6000 find.

### 5.2 What each change does alone

| What-if | Level | Lone Sling | Any tower |
|---|---|---|---|
| Ironshell armor 8, B1's 28 lone-Sling champions replayed | 2-6 | 1 of 28 still wins, 20 lives | 13 of 14 champions still win |
| Ironshell armor 10, the same replays | 2-6 | 0 of 28 | 13 of 14 |
| Ironshell armor 8, search | 2-6 | 0 wins in 2500 | not run |
| Ironshell armor 10, search | 2-6 | 0 wins in 2500 | 821 three-star in 2500 |
| Have at most 4 towers | 2-1 | 16 three-star (best 17, first at build 2216) | not run |
| Have at most 4 towers | 2-4 | 285 three-star (best 20) | not run |
| Have at most 4 towers | 2-5 | 32 three-star (best 20) | not run |
| Have at most 4 towers, wave 5 dense, wave 10 at 115 | 2-1 | 708 wins, best 11 | 845 three-star |
| Use no gates | 2-1 | 1139 wins, none without a gate | 913 three-star |
| Use no gates | 2-2 | 116 wins, none without a gate | 898 three-star, Bells in 795 |
| Use no gates | 2-4 | 1112 wins, none without a gate | 769 three-star |
| Use no gates | 2-5 | 783 wins, none without a gate | 534 three-star, Longbows in 532 |
| Use no gates, wave 3 softened to 24 Pips 0.15 s apart (S4) | 2-2 | 825 wins, none without a gate | 844 three-star, Bells in only 320 |
| Use at most 1 gate, wave 5 at 34 dense Pips | 2-4 | 177 three-star (best 16) | not run |
| Use at most 1 gate, wave 5 at 34 and wave 7 dense | 2-4 | 358 three-star (best 19) | not run |
| Use at most 1 gate, wave 5 at 40 dense Pips (chosen) | 2-4 | 682 wins, best 10 | 1023 three-star |
| Call 6 waves early, wave 5 dense, wave 10 at 115 (chosen) | 2-1 | 945 wins, best 12 | 888 three-star |
| Build no Longbow Lofts, wave 4 at 30 dense Pips | 2-5 | 211 wins, best 14; but 225 three-star in a 6000 build search (5.1) | 966 three-star |
| Build no Longbow Lofts, wave 4 at 36 dense Pips (chosen) | 2-5 | best 6 and 9 in two 6000 build searches (5.1) | 1000 three-star |
| 2, 3 and 4 Flitters (B1's S2), in time order | 2-3 | not run | 591 three-star; plain recipe 6 lives |
| 2, 2 and 2 Flitters (chosen) | 2-3 | Catapult capped at 14 by the flyers | 617 three-star; plain recipe 9 lives |

On 2-4 the lone Sling Post's champions with 34 dense Pips lost exactly 4 lives in wave 5 and none after. Their gold at the start of waves 3 to 9 was between 4 and 190: the early waves are where they cannot buy. A dense crowd in wave 7 came too late (358 three-star builds).

### 5.3 A weaker Sling Post (dropped)

Replays of the 14 lone-Sling "Have at most 4 towers" champions of 2-1 and of 2-4, under each change:

| Change | 2-1 champions (were 15 to 17 lives) | 2-4 champions (were 20 lives) |
|---|---|---|
| none | 14 of 14 three-star | 14 of 14 three-star |
| Quickshot reload 0.25 s | 0 wins, lost in wave 9 or 10 | 6 wins, 3 three-star |
| Quickshot reload 0.3 s | 0 wins, lost in wave 5 or 7 | 1 win |
| Quickshot damage 7 | 3 wins, 2 to 5 lives | 14 wins, 4 three-star |
| Quickshot 0.25 s and Stone Sling damage 16 | 0 wins | 1 win, 11 lives |

A 20% slower Quickshot turns builds that kept 15 to 17 lives into losses. That is a cliff, and mixed builds and runs would fall off it too.

### 5.4 Seeds

Every seed below is in the result files, so each number can be repeated. B1's seeds and files are in docs/balance/region2-2026-10-24.md.

| Job | Seed |
|---|---|
| 2-6 armor 10: lone Sling, any tower | 901601, 901600 |
| 2-6 armor 8: lone Sling | 902601 |
| 2-1, 2-4, 2-5 at most 4 towers: lone Sling | 902101, 902401, 902501 |
| Use no gates: 2-4 any, 2-4 lone, 2-5 lone | 903400, 903401, 903501 |
| Use no gates: 2-2 any, 2-2 lone, 2-5 any | 904200, 904201, 904500 |
| Use no gates: 2-1 any, 2-1 lone | 905100, 905101 |
| 2-1 at most 4 towers with the new waves: lone, any | 906101, 906100 |
| Chosen 2-1, 2-4 (34 Pips), 2-5: lone | 907101, 907401, 907501 |
| 2-4 at 40 Pips, 2-4 with wave 7 dense, 2-2 softened: lone | 908401, 908411, 908201 |
| Chosen 2-4, 2-5, 2-1: any | 910400, 910500, 910100 |
| 2-2 softened, 2-3 with 2, 3, 4 Flitters: any | 911200, 911300 |
| Chosen 2-3: any | 912300 |
| Twists: 2-6, 2-4, 2-3 | 912600, 913400, 913300 |
| 2-5 with 30 Pips: Twist, first 6000 build lone search | 912500, 922501 |
| 2-5 with 36 Pips (chosen): any tower, Twist | 923500, 923520 |
| 6000 build confirmations | 922101 and 922111 (2-1), 922201 and 922211 (2-2), 922301 and 922311 (2-3), 922401 and 922411 (2-4), 923501 and 923511 (2-5), 922601 and 922611 (2-6) |

### 5.5 How to repeat

From the repo root, with the level file of section 3 saved somewhere (any path):

```
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r2_l4 level_file=PATH/r2_l4.json seed=922401 evals=6000 only=solo:sling_post out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r2_l2 "tweak=star3:gates_at_most;0" seed=904200 evals=2500 only=any out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r2_l3 level_file=PATH/r2_l3.json out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search twist=1 level=r2_l6 seed=912600 evals=1500 out=OUT.json
```

Once the level designer's changes are in data/levels/, drop `level_file=`. The 2-6 jobs need nothing extra, because armor 10 is in data/stats/ now. The armor 8 what-if used `enemies=` with a copy of enemies.json.

The champion replays (5.2, 5.3) used a small scratch script that extends tools/balance/run.gd, loads the strategies saved in B1's raw files and plays each again under `towers=`, `enemies=` or `tweak=`. It is not in the repo. A `mode=replay` like it in tools/balance/run.gd would be a cheap first screen for any what-if; that is a suggestion in my G2 report.

### 5.6 Scratch files

The tested level files, stat variants and every raw result are outside the repo, in the session scratch folder under `g2/` (levels/, stats/, out/). They are not needed to build anything: section 3 has every change.

## 6. B1's other findings and suggestions

- **S1, S2, S3.** Answered in section 1.
- **S4, 2-2's wave 3.** Kept as it is. Softening it to 24 Pips 0.15 s apart only moved the plain recipe's no-gate loss from wave 3 to wave 4, and it took Bells out of most no-gate three-star wins (from 89% to 38%). Wave 3 is where 2-2 teaches its idea: drowsy crowds bunch up for splash. Whether a first-time player finds the gate is for Bart's phone, as B1 says.
- **S5, Bubble Night and 2-5.** Bubble Night is still the narrowest Twist, but winnable: 208 of 1500 searched builds won (B1: 146), best 13 lives. The plain recipe now keeps 16 lives on plain 2-5 (was 15). No change to the Twist.
- **S6, 2-6 on Relaxed.** Unchanged: with no gates the plain recipe wins by 5 lives, because the boss gets through and costs 20. RULES 6.3 accepts that: Relaxed exists so a stuck player can move on, and such a win earns one star. With its best gates it keeps 37.
- **S7, the Bell paths and the Triple Bow.** Better than in B1 but still thin: in the G2 three-star wins the Hush Bell shows up 385 times on 2-4 and the Night Bell 513 times on 2-2 (B1: 34 and 66 across both regions). The Triple Bow stays rare in region 2; its job, armored groups, grows in regions 3 and 4. A flag for B3, not a change.
- **S8, the search minimum.** Taken: RULES 12.6 now asks for two searches of at least 6000 builds per attacking tower, with an early stop when neither search has won any game by 2500 builds, and with no search needed for a tower that cannot hit the level's flyers (or walkers) when they cost 6 lives or more. The 6000 build searches take 15 to 30 minutes each on this PC; the shortcuts remove most Catapult, Longbow and Firework searches.

## 7. Region 3: the level designer's open questions

1. **3-2's third star.** "Have at most 6 towers", as the level file has it. RULES 12.4 now says 6. The number in each star 3 rule is a starting target for the level designer to confirm with the bots, and 7 let Sling Posts alone earn three stars. B3 checks it with the new search minimum.
2. **3-1 with one entrance.** Accepted, and RULES 12.3 now says so. The Firework Tower is 3-1's one new idea; a second entrance would be a second one. On 3-2 the second entrance joins in wave 4, a wave of its own with only Scamps, after the Puffball's first wave, so no wave brings two new things.
3. **The Moon Moth's wave at strength 70 (1120 health).** Accepted for now, and RULES 12.3 now lists each boss wave's strength. My view: the Moon Moth flies a straight line of about 11.7 tiles at 0.3 tiles a second, so it is on the map for about 39 s, and only anti air hurts it. One Skyrocket beside its path deals roughly 1100 to 1600 in the time the moth is in its range, so a build with two or three anti-air towers kills it, and a build that ignores it loses. That seems right for "a flying boss, gates cannot help". What B3 should report so G4 can decide: whether the plain recipe kills it, how much health it has left when it reaches the middle of its path, and whether Double Trouble (two Moon Moths) is still won. If it dies before it is halfway, raise the wave to 85 to 100.
4. **Dusk Moths against tier 1 and 2 Fireworks.** No stat change, I think. "Small hits barely scratch it" is the Dusk Moth's whole idea: a tier 1 Firework does 7 a hit, a tier 2 15, a Star Bloom 25, and the Skyrocket (90, ignores armor) and Stone Sling (15) are the answers. The level designer's low strengths for the early Dusk Moth waves (50 to 120) are the right lever. G4 decides after B3. If B3 finds the plain recipe, which always takes the Star Bloom, losing lives to Dusk Moths on 3-4 or 3-5, lower those waves further before touching a tower.
5. **RULES 4.10.** Starting a new run or daily over a saved one now has its rule: it asks first, then the saved run ends as if abandoned, counts as lost at its current wave and records its counters, and a daily's try counts for the day's best and the streak. This is what the UI does already (App.request_start_run). RULES 14.7 says so too.

## 8. Effects beyond region 2, and what to re-check

- **Region 1.** Nothing changes. Ironshell is not in region 1, and no tower number moves. B1's region 1 results stand. B3 runs region 1's lone-tower searches at the new minimum; the 2026-10-24 report's 8000 build searches and the exhaustive check of 1-3 found nothing, so I expect no change.
- **Region 3 and 4 levels.** Ironshell is not in them, so the stat change does not move them. RULES 12.6's new search minimum applies from B3 on: 3-2's "at most 6 towers" and each region 4 level's lone-Sling result should be checked with two searches of 6000 builds before they land. RULES 12.5's new guide (a dense crowd before the gold, Pip health and splash, short roads favor splash) is the first lever if a lone Sling Post earns three stars there. The level designer's region 4 approach, Pip crowds at strength 160 to 210, also works: from strength 120 a Pip takes two tier 2 pumpkins but one Prize Pumpkin.
- **Runs (G3).** Ironshell is the boss of band 6 packs `b6_iron_road` and `b6_iron_gate`, at strength 270: 6750 health and now armor 10. B2, which is running now on armor 6, will be out of date for those runs. A run with no Longbow Loft card meets a boss that a Stone Sling hits for 10, a Prize Pumpkin for 40 and a Quickshot for 1. G3 should re-check runs with Ironshell as the boss. If they are too hard, the levers are those packs' escorts (packs.json, the level designer's), or Ironshell's health with 2-6's boss wave strength raised to match, so 2-6 stays as tested. Pack waves cannot set their own strength (contract 2.9). I would not lower the armor again: 2-6 needs it.

## 9. Tests

With the new data/stats/ the whole suite passes: `godot --headless --path . --script res://tests/run_tests.gd`, 979 tests in 70 files, 979 passed, 0 failed, exit code 0 (on the working tree of 2026-10-24, which includes the level designer's region 4 work in progress). No test in any area pins Ironshell's armor or its card line: the tests read them from the catalog.

The level changes need one test change by the level designer: the PLAN row of `r2_l2` in tests/levels/test_level_design.gd, star 3 `["gates_at_most", 0]`.

## 10. For Bart

These change things Bart approved, so they are for the DM to tell him:

1. Level 2-2's third star changes from "Have at most 6 towers." to "Use no gates." It makes Bells the key to the third star (they are in 89% of its three-star wins). The other rule that works there is B1's "Have at most 4 towers.", but with it Bells are in only 3% of the three-star wins.
2. Ironshell's armor goes from 6 to 10, and its card says "Armor 10."
3. Level 3-2's third star is "Have at most 6 towers." (RULES said 7.)
4. Level 3-1 has one entrance (RULES suggested two in region 3).
5. Region 2's waves change a little: dense early Pip crowds on 2-1, 2-4 and 2-5, six Flitters on 2-3, and 2-1's last wave at strength 115.

The check itself does not need Bart: the stricter reading stays, and relaxing it would not have helped (section 1.1).

One open point, for Bart's playtest more than for the bots: the plain recipe now keeps 9 lives on 2-3 (it was 15). It lets all six new Flitters through, because its Sling Posts are not near the flight line, which runs along the top row from entrance A to the base. A thoughtful player who reads the preview and the dotted flight line should put a Sling Post up there. If the phone says 2-3 is too hard, soften its other waves rather than cutting the Flitters below 6, the fewest that keep the check certain.

For the DM, not Bart: the new search minimum (RULES 12.6, B1's S8) makes each balance pass longer. A 6000 build search takes about 15 to 30 minutes on this PC, two per attacking tower that can win the level. The shortcuts for towers that cannot hit flyers or walkers remove most of the Catapult, Longbow and Firework searches.
