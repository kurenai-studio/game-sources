# Run tuning plan (G3)

Owner: game designer. 2026-10-25 (task G3). Answers the first run and daily report, docs/balance/runs-2026-10-24.md (B2, commit da1fc38). RULES.md holds the rules and numbers; this file says what changes for runs and the daily, why, and exactly what each owner types in. Section 7 lists what changes Bart's approvals.

Section 9 (task G5, 2026-10-26) answers the second report, docs/balance/runs-2026-10-26.md (B4). Its 9.3 lists what changes Bart's approvals, and it ends with the changes per owner.

## 1. Decisions

### 1.1 The final boss must be beaten

On Normal a run is won by beating its boss. Outliving it no longer works. This is my call as designer, for four reasons:

1. It is already the rule. RULES 6.3 says a boss that reaches the base costs 20 lives, "which loses any Normal game". Runs broke that by accident: Tea Break lifts lives above 20 with no ceiling, and 20 is exactly what a boss costs.
2. A run should end in a fight (brief 3.7: "ending in a boss"). With outliving, 57.6% of the bots' Normal wins let the boss walk in. The last wave was a toll of 20 lives, not a climax.
3. It made one card the whole plan. Runs that picked no Tea Break won 6.2%, runs with three or more 64.5% (section 5.1). Skill should decide runs (brief 3.7), not how many copies of one card a draft happens to offer.
4. It gives late gold a job (1.3).

How: **lives never rise above the starting lives**, 20 on Normal and 40 on Relaxed. Tea Break stays as a repair card: "Gain 5 lives, but never more than you started with." So on Normal a boss that gets through always ends the run. On Relaxed a run that kept more than 20 lives still survives it, exactly as a Relaxed campaign level does (RULES 6.3, 11).

The other levers in B2, and why not:

- A weaker or once-only Tea Break. Both still let a run outlive the boss (B2: at 3 lives, 19.1% of runs still won), and both weaken the repair, which is the part worth keeping.
- More lives lost to the boss. The 20 is in enemies.json and shared with the campaign, where it is right: a Relaxed player with spare lives may move on.
- A lower strength step. It eases every wave to fix one (1.7). The boss needs its own number (1.2).

### 1.2 Each boss wave sets its own strength

With the cap alone and the boss at strength 270, only 18.5% of the runs that start wave 18 win: Ironshell 5.4%, the Moon Moth 1.8% (5.1). At 270 the bosses have 2.7 to 5.4 times the health of the campaign's boss waves, which set their own strengths (RULES 12.3: 50, 100, 70 and 70), plus an escort.

So a band 6 pack's third wave, the boss wave, sets its own strength, as a campaign boss wave does. Waves 1 to 17 keep 100 + 10 x (w - 1). This needs one contract change (3.1). The strength is per pack, not per boss, because the escorts differ: at the same strength the Moon Moth's two packs were won 86% and 58% of the time.

The target: about 62% of the named bots' Normal runs that start wave 18 win (RULES 14.8 allows 50% to 75% per pack). The boss is a skill check, not a coin flip: towers-first strategies beat it far more often than economy-first ones, because a varied board is what beats a boss (5.2). People also aim towers at Strong and rebuild for the boss, which the bots never do. Aiming alone is worth a lot: with every attacking tower set to Strong when the boss wave starts, the same bots won 74.4% of their boss waves instead of 61.8%, and 62.1% of their runs instead of 51.6% (the candidate before the last card changes, seeds 1 to 50).

| Pack | Boss | Strength | Boss health | Its escort |
|---|---|---|---|---|
| b6_grumble_hill | Grumblesack | 290 | 5800 | Scamps, Pips |
| b6_grumble_march | Grumblesack | 270 | 5400 | Menders, Skitters, Scamps |
| b6_iron_road | Ironshell | 150 | 3750 | Scamps, Flitters, Skitters |
| b6_iron_gate | Ironshell | 150 | 3750 | Shellbacks, Skitters, Flitters |
| b6_moon_rise | Moon Moth | 150 | 2400 | Pips, Scamps, Shellbacks |
| b6_moon_tide | Moon Moth | 140 | 2240 | Shellbacks, Bubblers, Skitters |
| b6_tusk_charge | Old Tusk | 200 | 6000 | Skitters, Shellbacks, Scamps |
| b6_tusk_night | Old Tusk | 180 | 5400 | Gatecrashers, Scamps, Flitters |

These come from a calibration of each pack (5.2), checked on 200 seeds (section 4). The last card changes (Sharp Pebbles and Volley) made every boss wave a little harder: on 200 seeds the packs were won 55% to 67% of the time, with the two Grumblesack packs lowest, at 55% (grumble_hill, then at 300) and 58% (grumble_march, then at 280). Both moved 10 down, which by their measured slopes is about 6 points back toward 62%. The other six stay as measured. B4 confirms all eight with the real data.

Grumblesack is the easiest boss for a mixed board (no armor, every attacking tower hits it), so its waves are the strongest. grumble_march is lower than grumble_hill because its Menders heal the boss.

### 1.3 Late gold

From wave 14 every spot held a tier 3 tower and gold piled up: 4,600 unspent when the boss wave started (B2 F6). Three changes, no new rule:

1. **It is the boss budget now.** The boss shows in the folded preview from the start of wave 17 and in the open preview of the last build phase. Since it must be beaten, the gold on hand (3,500 median in the final candidate) pays for selling and rebuilding toward it: Skyrockets on the Moon Moth's line, Giant Bows by Ironshell's road. Refunds are 70%, so a full tier 3 swap costs about 150.
2. **More board.** Every run map gets 12 build spots instead of 9 to 11 (1.5). The board now fills during waves 14 and 15 instead of 12 to 14 (5.5).
3. **A home for the Bakery.** Every map gets a spot whose eight neighbors hold 3 other spots, so a Grand Oven by three big hitters is the late buy RULES 5.1 meant it to be ("late waves, bosses").

Not chosen: less late income. Once the board is full, less gold changes nothing. A gold use beyond the brief (a card that buys power) is a suggestion for Bart, in my report.

### 1.4 Tea Break, the unlock cards, the risk cards and the Bakery card

- **Tea Break** is no longer dominant: it repairs lost lives and no longer banks them. Runs that took no Tea Break now win 35.6%, one 54.9%, three or more 54.0% (B2: 6.2%, 27.8%, 62.2% and up). In the card experiment it is worth -1.0 points with the base cards (+1.0 before the last card changes) and +2.5 with every card (B2: +9.6 and +11.6).
- **Sharp Pebbles** then became the card that decides runs: +10.0 points with the base cards, +9.8 with every card (B2: +6.3). It adds 2 damage to the one tower every run starts with and builds most, which is +25% to +33% a hit on a Sling Post and +50% against a Shellback's shell, so taking it is never a choice. It now adds 1 damage (section 4 gives its new value).
- **The unlock cards.** B2 blamed the drop with every card unlocked on Tea Break being diluted. With the cap that cause is gone, yet every card unlocked still won 16.7 points less than the base cards (seeds 1 to 34). Moving one group of unlock cards at a time into the base pool shows where it comes from (5.8): the six unlock perks cost 13.0 points, the three unlock risk cards 0.5, and Piggy Bank, Bargain and Iron Gate 2.0. Of the perks, Volley is the one that loses in almost every build. At 40% less damage a Triple Bow does less even against crowds (4 arrows at 60% against 3 at 100%), and against a boss every Longbow loses 40%: runs with Volley beat Ironshell 28.8% of the time, runs without it 47.9%. Its arrows now lose 25%: a Triple Bow breaks even against crowds, tier 1 and 2 Lofts and Giant Bows gain against them, and a single target takes 25% less. Section 4 gives what is left of the gap; the pool weights stay as they are.
- **Risk cards.** In a replay of each wave with each risk card (5.7), five cards traded 33 to 37 gold for each life they cost in waves 2 to 8, where risk cards matter most. Three did not:
  - Hurry Night cost 0.55 lives for 139 gold (251 gold a life): nearly free. Now creatures move 50% faster and the reward is 60 gold. Replayed: 1.24 lives for 78 gold (63 a life).
  - Gateless Night cost 0.69 lives for 166 gold (242 a life). The reward drops to 60. The bots place gates by a simple rule and lose little when gates open, so they still rate it cheap (119 a life); a player who builds around gates pays more. I chose not to change its effect.
  - Pip Parade cost 10.4 lives early and lost 40% of the waves it touched: a trap. Now 16 Pips and a 120 gold reward: 6.4 lives for 185 gold (29 a life), 10.5% of waves lost.
- **The Bakery card** was a trap because no run map had a spot that reached two others (B2 F8). Every map now has one that reaches three (1.5). The bots also built a Bakery the moment they drew its card, which hurts any support tower early; in my what-ifs they wait for wave 9, and I ask the balance analyst to make that the bots' rule (3.5). With both, a Bakery stands at the end of 95.3% of the final candidate's runs that reach wave 10.

### 1.5 Run maps: the walls

B2's walls were the stacks that use `mid_cross` or `mid_ladder`, and the bottoms and tops paired with them (B2 F7). My static check of every stack (5.3) shows why:

- Those stacks had 9 build spots. Every other stack had 10 or 11. With the board full by wave 14, spots decide the late game: in B2, runs on 9-spot maps won 8.1% and lost 30.2% by wave 6, on 10-spot maps 29.7% and 7.2%, on 11-spot maps 37.5% and 6.4%.
- In both middles the two lanes ran side by side to the base, and a gate could only move the creatures from one lane to the other. The road stayed 12 to 15 steps, and the run's first gate made no detour. With two entrances (`top_twin`), the defense was split in two for the whole map.

Adding spots alone (12 everywhere) did not remove the early walls: those stacks still lost 12% to 62% of plays by wave 6. Redrawing the two middles did. In the new `mid_cross` and `mid_ladder` one lane zigzags and a short link joins the lanes, so the starting gate on the straight lane sends the creatures down the zigzag: 4 more steps on every stack that uses them. The exact grids are in 3.4.

Result in the final candidate: maps with `mid_cross` won 53.9% and lost 3.7% by wave 6 (B2: 10.6% and 45.6%); `mid_ladder` 59.3% and 1.0% (B2: 6.3% and 18.9%); all maps 47.4%. Every segment's maps now win within the bar of 14.8, and one stack is left for the level designer (section 4, 3.4).

### 1.6 Band 2 and the Moon Moth packs

- **Band 2.** On the new maps the three packs B2 named lose 5% to 8% of the runs that reach them even unchanged (B2: 14% to 20%, mostly on wall maps). Their common cause is Shellbacks: 8 or 9 in the band, the first ones in wave 4 or 5 when a run has mostly Sling Posts, which armor blunts, and Pips arriving on top of them. The easy packs bring 3. I cut them to 5 or 6, and in two packs the crowd that followed the run's first Shellbacks starts 3 s later. Every new creature still comes first in its wave. In the final candidate they lose 2.4% to 5.4% (section 4).
- **Band 4** became the mid-run hurdle once lives could no longer be banked: `b4_field_nurses` lost 13.1% of the runs that reached it, `b4_moth_flight` 12.4%. The first brings the run's first Menders together with 5 Shellbacks they heal; the second ends with 5 Dusk Moths at strength 210. Now 3 Shellbacks that start after the Menders, and 4 Dusk Moths, which brought them to 9.2% and 9.1%. The weaker Sharp Pebbles then pushed three band 4 packs back to 10.1% to 11.1%; 3.4 proposes one more small cut in each.
- **The Moon Moth packs** lost 80% to 86% of the runs that reached them because the Moon Moth at 270 had 4,320 health and only Sling Posts and Fireworks can hit it. At 150 and 140 it has 2,400 and 2,240 health, and its packs are won within the bar like every other boss (section 4).
- **The one unwon day,** 2026-12-01, was `top_fork, mid_cross, bot_gate` with the Moon Moth: a wall map and the hardest boss. Section 4 gives the daily again.

### 1.7 The strength step stays at 10

I tried 12 and 14 (5.6). They push every wave harder, but they also raise income by the same share, so the board fills earlier again and the late gold comes back (at 14: 69% of runs had nothing to buy at wave 14, against 30% at 10). The boss strengths give the run its difficulty without that cost. Waves 1 to 17 keep 100 + 10 x (w - 1).

### 1.8 Run length, for Bart

Won runs last about 13 minutes at 1x by the levels' count, the wave phases plus 15 s for each build phase (RULES 12.5): 13.1 in the final candidate, 14.3 with no early calls, 9.8 minutes of wave time. RULES 14.1 says about 15 to 20.

I do not want to lengthen the waves. More creatures would bring more gold and more of the same, and wider gaps would only slow the pace; neither adds a decision. A run's build phase also holds a card draft, which a level's does not, so 15 s undercounts it. At 30 s a build phase, won runs average 16.6 minutes.

Proposal for Bart: RULES 14.1 says "About 12 to 16 minutes at 1x, counted as for levels (12.5). With a card to read in every build phase, about 15 to 20 minutes of real play." This changes an approved number, so RULES 14.1 still carries the approved text with this proposal beside it, and Bart decides. The DM's run check on the Fold5 (contract 13) can time a real run.

Bart chose this range on 2026-10-25, and RULES 14.1 now states it.

## 2. Targets

Section 12 of the contract asked for the win-rate bars for runs, judged from the best bots, and the bar for the daily. They are now RULES 14.8 and the end of RULES 15. The three asked for:

- **Normal:** the best of the 16 named strategies wins 55% to 75% of its runs on seeds 1 to 200, and the 16 together win 35% to 55%. The bots are a floor: they never aim at Strong, sell to rebuild for the boss or read the preview, so a thoughtful player should win more often than the best of them.
- **Relaxed:** the best named strategy wins at least 90%, the 16 together at least 80%.
- **The daily:** over the next 400 days, at least 98% are won by one of the 16 named strategies or by one of up to 400 random strategies, no two days in a row go unwon, and the named strategies alone win at least 60% of the days. This is B2's proposal plus two guards: an unwinnable day should never come twice in a row, and a typical day should fall to a plain strategy, not only to a long search. 100% is not the bar: one seed fixes a whole run, and chasing the last hard seed would mean hand-tuning single dates.

RULES 14.8 adds checks that keep this plan's fixes from coming back: every seed winnable, every card unlocked within 5 points of none, each boss pack 50% to 75%, fair maps, fair packs, no card other than a tower card worth more than 5 points, risk card rewards in line, length, and the same seed playing the same.

## 3. Changes per owner

Each change below was played in a scratch copy of da1fc38 (section 6). Nothing here touches the campaign: the lives cap only matters where something adds lives, which only run cards do, and the boss wave strength is a pack field.

### 3.1 Contract changes (architect, through the DM)

1. **2.8, `add_lives`:** "Gain lives, never above the battle's starting lives (`start_lives`). A gain never lowers lives." So a saved battle with more lives than it started with keeps them.
2. **2.9, wave packs:** a band 6 pack's third wave, its boss wave, has a `strength` (50 to 1,000), required there and allowed on no other pack wave. The pack shape of 3.4 carries it. Today the rule reads "exactly 3 waves in the level wave shape of 2.4, without `strength`".
3. **3.4, MapAssembler step 4:** waves 1 to 17 get `strength_start + strength_step * (w - 1)`; wave 18 gets its band 6 pack's boss wave strength. **2.10:** the run.json check becomes "wave 17's strength at most 1,000".
4. **2.9, a level design rule like the 13 row rule** (checked by tests/levels, not on load): every stack has a build spot with at least 3 other build spots among its eight neighbors.
5. **Text only:** 2.10's run.json example and 2.11's card example and table carry numbers this plan changes: `"spots": [11, 12]`; `sharp_pebbles` `tower_add` damage 1 and the text "Sling Posts deal 1 more damage per hit."; `hurry_night` `speed_pct` 150 and `reward_gold` 60; `gateless_night` `reward_gold` 60; `pip_parade` `add_group` count 16 and `reward_gold` 120; `volley` `tower_pct` damage 75.

### 3.2 Sim engineer (S3, after 3.1)

`Battle.add_effects`, `add_lives`: `lives = maxi(lives, mini(lives + amount, start_lives))`. A test in tests/sim: on a battle with 20 starting lives, at 18 lives Tea Break's effect gives 20, at 20 it gives 20, and a restored battle at 25 lives stays at 25.

### 3.3 Roguelite engineer (R3)

data/cards/cards.json, six cards. Every other card is unchanged.

| id | Field | Now | New |
|---|---|---|---|
| `tea_break` | text | Gain 5 lives. | Gain 5 lives, but never more than you started with. |
| `sharp_pebbles` | effects | `tower_add` damage, `amount` 2 | `tower_add` damage, `amount` 1 |
| `sharp_pebbles` | text | Sling Posts deal 2 more damage per hit. | Sling Posts deal 1 more damage per hit. |
| `hurry_night` | effects | `speed_pct` 125, `reward_gold` 100 | `speed_pct` 150, `reward_gold` 60 |
| `hurry_night` | text | Next wave: creatures move 25% faster. Reward: 100 gold, more later. | Next wave: creatures move 50% faster. Reward: 60 gold, more later. |
| `gateless_night` | effects | `reward_gold` 120 | `reward_gold` 60 |
| `gateless_night` | text | Next wave: your gates stand open. Reward: 120 gold, more later. | Next wave: your gates stand open. Reward: 60 gold, more later. |
| `pip_parade` | effects | `add_group` pip, `count` 24; `reward_gold` 100 | `add_group` pip, `count` 16; `reward_gold` 120 (entrance, at_ms, every_ms and after_last unchanged) |
| `pip_parade` | text | Next wave: 24 more Pips. Reward: 100 gold, more in later waves. | Next wave: 16 more Pips. Reward: 120 gold, more in later waves. |
| `volley` | effects | `tower_pct` damage, `pct` 60 | `tower_pct` damage, `pct` 75 (the `tower_add` targets 1 is unchanged) |
| `volley` | text | Longbow Lofts hit 1 more target, but deal 40% less damage. | Longbow Lofts hit 1 more target, but deal 25% less damage. |

data/runs/run.json: `"spots": [8, 12]` becomes `"spots": [11, 12]`, so every stack's spot count is checked. Nothing else changes: `strength_start` 100, `strength_step` 10, `start_gold` 300, `gates` 1, the bands and the weights stay.

src/run/: contract changes 2 and 3 of 3.1 (RunData.check for the boss wave strength and the wave 17 limit, MapAssembler step 4), with tests/run for both, including a hostile pack with a strength on a non-boss wave.

tests/run/test_real_data.gd pins two things this plan changes: the risk rewards (`test_risk_cards_name_a_reward_and_gate_the_next_wave_only`: Hurry Night 60, Gateless Night 60, Pip Parade 120) and run.json's spots and sockets (line 87: `[11, 12, 2, 5]`). With the new cards, the rewards test was the only one that failed in my copy, apart from the source rules test that my scratch hooks break on purpose; I left run.json's spots at `[8, 12]` there, so line 87 did not fail.

### 3.4 Level designer (L5)

data/segments/: six segment files and packs.json. The other eleven segments and index.json stay as they are. The grids below are the ones I played (section 4). You may redraw them, as long as every stack keeps 11 or 12 spots, a Bakery spot that reaches 3 others, a first gate that makes a detour where these do, and the bars of RULES 14.8; B4 then checks them.

`mid_cross` and `mid_ladder`, redrawn. One lane zigzags, a link joins it to the straight lane, and the straight lane's socket sends the creatures down the zigzag:

```
mid_cross (was)   mid_cross (new)     mid_ladder (was)  mid_ladder (new)
.#...#.           .#...#.             .#...#.           .#...#.
.###o#.           .#o###.             .#.o.#.           .###o#.
.Go###.           .###o.o             .#####.           o.o###.
.#.o.G.           .Go###.             .G.o.G.           .###oG.
.#...#.           .#...#.             o#...#.           .#...#.
```

Ports stay 1 and 5 at the top and the bottom, so every stack that used them still forms. Each has 4 spots and 1 socket (was 3 spots and 2 sockets). Every stack keeps 2 to 3 sockets.

The four bottoms gain a Bakery cluster: a spot with 3 other spots among its eight neighbors. Roads, ports and the base do not move:

```
bot_square        bot_porch         bot_gate          bot_yard
(was)   (new)     (was)   (new)     (was)   (new)     (was)   (new)
...#... ...#...   ..o#... ..o#...   o#...#. .#.o.#.   .#...#. .#.o.#.
.o.#o.. ...#oo.   ...###o .oo###.   .G.o.#o .Gooo#o   .#.o.Go .#oooGo
..oB... ..oBoo.   ..o.oB. ..o.oB.   .##B##. .##B##.   o###B#. .###B#.
....... .......   ....... .......   ....... .......   ....... .......
```

Every stack then has 12 build spots (was 9 to 11).

packs.json, band 2: three packs, Shellbacks cut from 8 or 9 to 5 or 6. Only the groups named here change; every other group keeps its creature, count, entrance and times.

| Pack | Wave | Group | Now | New |
|---|---|---|---|---|
| `b2_night_wings` | 2 | shellback (first) | 3, every 1800 | 2, every 2500 |
| `b2_night_wings` | 2 | shellback (last) | 2 | 1 |
| `b2_night_wings` | 3 | shellback | 3 | 2 |
| `b2_hard_shells` | 1 | scamp | at 6000 | at 9000 |
| `b2_hard_shells` | 2 | shellback | 3 | 2 |
| `b2_hard_shells` | 3 | shellback | 4 | 2 |
| `b2_slow_and_fast` | 1 | pip | 10 at 7000 | 8 at 10000 |
| `b2_slow_and_fast` | 1 | scamp | at 12800 | at 15000 |
| `b2_slow_and_fast` | 2 | shellback | 3 | 2 |
| `b2_slow_and_fast` | 3 | shellback | 3 | 2 |

packs.json, band 4: two packs, tested.

| Pack | Wave | Group | Now | New |
|---|---|---|---|---|
| `b4_field_nurses` | 1 | shellback | 5 at 0 | 3 at 3000 |
| `b4_moth_flight` | 3 | dusk_moth | 5 | 4 |

After the last card changes made every run a little harder, three band 4 packs sit just over the 10% bar on 200 seeds: `b4_quiet_moths` 11.1%, `b4_moth_flight` 10.6%, `b4_field_nurses` 10.1%. Each loses most in one wave: quiet_moths in its first (6.3% of the runs that reach the pack: Menders arriving with Bubblers they heal), moth_flight in its third (6.2%), field_nurses in its second (4.6%: the first Dusk Moths, then 24 Pips). Untested proposals, one group each, for you to confirm with the bots: `b4_quiet_moths` wave 1 bubbler 6 to 4; `b4_moth_flight` wave 3 flitter 8 to 6; `b4_field_nurses` wave 2 pip 24 to 20. The target is RULES 14.8's: at most 10% of the runs that reach a pack lost inside it.

packs.json, band 6: the third wave of each pack gets the `strength` of 1.2, once contract change 2 is in: grumble_hill 290, grumble_march 270, iron_road 150, iron_gate 150, moon_rise 150, moon_tide 140, tusk_charge 200, tusk_night 180. For example `{"strength": 150, "groups": [{"enemy": "ironshell", ...`. Escorts do not change.

One stack is left for you: `top_fork, mid_merge, bot_square` lost 17.5% of its plays by wave 6 (5 seeds of 200; RULES 14.8 allows 10%). It is the shortest map (15 steps, and no single gate lengthens it), and five of its twelve spots, the `bot_square` cluster and its neighbor, see 2 to 4 road tiles because `bot_square`'s road is 2 steps long. Moving that cluster up beside the middle's exit, or giving `bot_square` a longer road, are the two fixes I would try. I did not test either.

tests/levels, new checks: every stack has a spot with 3 other spots among its eight neighbors; every band 6 pack's third wave has a strength, and no other pack wave has one. The existing checks all pass on the new files (section 6).

### 3.4a What L5 changed from this plan

L5 (commit fdbfec7) applied 3.4 with three differences, which the DM accepted (items 1 to 3). Everything else in 3.4 went in as written. Item 4 checks whole runs on the final data, and item 5 is a DM decision. The new `mid_merge`:

```
mid_merge (was)   mid_merge (new)
.#.o.#.           .#.o.#.
.#####.           .######
oG.o.Go           oG.o.oG
.#####.           .######
...#...           ...#...
```

1. **`mid_merge` is redrawn,** though 3.4 left it as it was. The right side of its ring now runs to column 6, so the two lanes differ in length and the run's first gate makes a detour (RULES 14.2). It keeps its 4 spots, its 2 sockets and its ports. On `top_fork, mid_merge, bot_square` the road is still 15 steps with no gate. A gate on the left lane now makes it 17, where before no single gate lengthened it. Why: 3.4's `bot_square` changes alone did not fix that stack. With every run on seeds 1 to 200 forced onto it (3,200 plays), it lost 10.3% by wave 6 with 3.4's grids, and 5.1% with the new `mid_merge` and 3.4's `bot_square`. Section 4's 17.5% came from only 80 plays. `top_twin, mid_merge, bot_square` went from 2.8% to 1.8%.
2. **`b4_field_nurses`** has only the tested change: wave 1's Shellbacks, 5 at 0, are now 3 at 3000. 3.4's Pip cut (wave 2, 24 to 20) is not in. It changed nothing (9.3% with it), and without it the pack lost 9.0% of the runs that reached it over 200 seeds, already under the 10% bar.
3. **`b4_quiet_moths`** has 3.4's cut, wave 1 Bubblers 6 to 4, and one more: wave 3 Dusk Moths 4 to 3. Its losses in wave 12, its third wave, came from the Dusk Moths, not the Shellbacks. It lost 14.1% before the cuts, and 8.5% (seeds 1 to 100) and 8.2% (seeds 101 to 200) after. **`b4_moth_flight`** has both of 3.4's cuts in wave 3, Dusk Moths 5 to 4 and Flitters 8 to 6: 9.1% over 200 seeds.
4. **Whole runs on the final data,** base cards, seeds 1 to 50 (800 plays): the 16 strategies won 50.6%, within the 35% to 55% bar, and lost 2.1% by wave 6 (section 4: 47.4% and 3.2%, on 200 seeds). `towers_tall` won 78.0% of its 50 runs, over the 55% to 75% bar. Section 4 measured it at 68.5% on 200 seeds, and on 50 runs one strategy's rate has a standard error of about 6 points, so B4 checks it on 200 seeds (3.5).
5. **Run maps need no hint row.** The campaign's 12 and 13 row maps keep a row free for the first hint (contract 7.4, tests/levels). Of the 42 run stacks, one has none: `top_pair, mid_eye, bot_porch`. Runs show no hint (contract 3.4, step 5), so the DM decided run maps need none.

**Later: L8 (commit 496cd46, 2026-10-26) moved `mid_merge`'s spots again.** B4 found two walls on its `bot_porch` stacks (`top_fork` 19.7% and `top_twin` 11.9% lost by wave 6, forced). L8 keeps the road, both sockets, the ports and the spot at the right end of the ring's inside, and moves the other three spots: to the top row's left edge, next to that spot inside the ring, and to the bottom row. This is the `mid_merge` the game uses now:

```
mid_merge (L5)    mid_merge (L8)
.#.o.#.           o#...#.
.######           .######
oG.o.oG           .G..ooG
.######           .######
...#...           ...#.o.
```

L8's numbers, as the DM reported them: every `mid_merge` stack, forced onto seeds 1 to 200, loses 2.6% or less by wave 6. On Normal with the base cards the 16 together win 52.6% (B4: 50.4%), `towers_tall` wins 151 of 200 (75.5%, ceiling 75%), and `mid_eye` is 0.748 times all runs (bar 0.75). G5 decides that both are within noise (9.1).

### 3.5 Balance analyst (B4)

- Build a Bakery only from wave 9 on (my what-ifs: `FL_BAKERY_WAIT=9`, section 6). Today the bots build every new tower type at once, which turns a Bakery drawn in the first drafts into a wasted spot.
- Give the bots a perk choice that fits their towers, so the every-card bar measures the cards and not the bots: for example, pass on a sidegrade whose cost falls on the towers the run has built most (Volley with Giant Bows, Twin Pebbles with Stone Slings, Long Fuse with Skyrockets).
- Report the bars of RULES 14.8 and 15 with the real data once R3, S3 and L5 are in, on the seeds of RULES 14.8 (run seeds 1 to 200 unless a row says otherwise) and the days of RULES 15, and the card experiment on 200 seeds.
- Include `mid_merge` in the fair maps check: L5 redrew it after section 4 was measured (3.4a).
- Force each stack that fails a check onto every seed from 1 to 200, as L5 did (3.4a), before calling it a wall. Natural runs give a stack only about 5 seeds (80 plays). Section 4's 17.5% came from such a sample; forced, the same grids lost 10.3%.
- Check `towers_tall` on seeds 1 to 200. On the final data it won 78.0% of 50 runs, over the 55% to 75% bar, against 68.5% on 200 seeds in section 4 (3.4a).
- Useful, not required: a bot that aims at Strong in the boss wave. My what-if hook for it is in section 6.

### 3.6 Game designer: RULES.md (done in this step)

4.4 and 6.3 (lives never rise above the starting lives), 6.4 and 14.1 (wave 18's strength), 14.2 (11 or 12 spots and the Bakery spot), 14.3 (the boss wave strengths), 14.5 and 14.6 (the six cards), the new 14.8 (targets) and the end of 15 (the daily bar). 14.1 gives the run length Bart chose on 2026-10-25 (1.8). Section 1 and 14.8 match it.

### 3.7 data/stats/

No change. No tower or creature number moves, so the campaign is untouched.

## 4. Results: the final candidate against the targets

The final candidate is every change of section 3, played in a scratch copy (section 6): the six segments, the band 2, 4 and 6 packs, the six cards, the lives cap, and bots that wait for wave 9 to build a Bakery. It was measured with grumble_hill at 300 and grumble_march at 280, before the last step of 1.2. Normal, base cards, the 16 named strategies, run seeds 1 to 200 (3,200 plays), unless a row says otherwise. Some checks were run one step earlier, before the Sharp Pebbles and Volley changes ("earlier" in the table), and Relaxed two steps earlier, with grumble_hill at 320 and band 4 unchanged ("first"). The later changes move those rows a little, some up and some down; none is near enough to its bar to cross it.

| RULES 14.8 check | Bar | B2 (da1fc38) | This plan | Met |
|---|---|---|---|---|
| Every run can be won | every seed 1 to 50 | every seed, some only by random strategies | every seed, each by a named strategy | yes |
| Normal, best strategy | 55% to 75% | 51.5% (economy_tall) | 68.5% (towers_tall) | yes |
| Normal, the 16 together | 35% to 55% | 24.8% | 47.4% | yes |
| Relaxed, best and the 16 | at least 90% and 80% | 96.0% and 83.6% | 99.0% and 94.4% (first, seeds 1 to 100) | yes |
| Every card unlocked, Normal | within 5 points | -11.9 (24.8% to 12.9%) | -10.2 (44.0% to 33.8%, seeds 1 to 100) | no, see below |
| Every card unlocked, Relaxed | within 5 points | -10.5 | -7.8 (95.8% to 88.0%, first, seeds 1 to 50) | no, see below |
| The boss: each band 6 pack | 50% to 75% of the runs that start wave 18 win | 15% to 57% | 55% to 67% | yes |
| Fair maps: each segment against all maps | at least 0.75 times | 0.25 to 1.87 times | 0.80 to 1.30 times | yes |
| Fair maps: stacks with 4 or more seeds, lost by wave 6 | at most 10% | 12 stacks above, up to 70.3% | one: top_fork, mid_merge, bot_square, 17.5% | no, see 3.4 (L5's results: 3.4a) |
| Fair packs: bands 1 to 5 | at most 10% lost inside | up to 20.1% | up to 11.1% (three band 4 packs at 10.1% to 11.1%) | no, see 3.4 (L5's results: 3.4a) |
| No card decides a run | at most +5 points, tower cards reported | Tea Break +9.6, Sharp Pebbles +6.3 | Sharp Pebbles +6.1, standard error 2.4 (40 seeds); the Longbow Loft card +6.1, reported | not yet: within one standard error, see below |
| Risk cards trade fairly | 18 to 71 gold a life (half and twice the middle, 35.5) | Pip Parade 8, Hurry Night 148 | 29 to 63 (Gateless Night 119, reported) | yes |
| Length | about 12 to 16 minutes at 1x (Bart, 2026-10-25) | 13.3 | 13.1 (14.3 with no early calls, 9.8 of wave time; 16.6 at 30 s a build phase) | yes |
| The daily (RULES 15) | 98% of 400 days; no two unwon in a row; 60% by the named | 97.5% with 100 random strategies, 99.75% with 1,500; 2026-12-01 unwon; 70.0% by the named | 400 of 400 days; none unwon; 97.2% by the named (earlier) | yes |
| Same seed, same run | | 50 of 50 | not run: nothing in the repo changed yet; B4 checks it | for B4 |

Where runs end: 3.2% by wave 6, 19.7% in waves 7 to 17 (band 4 is the busiest), and 29.7% at the boss, which 61.5% of the runs that start it beat. By boss: Grumblesack 56.7% (before its last step), Ironshell 63.7%, Moon Moth 63.2%, Old Tusk 63.4%. Gold unspent when the boss wave starts: 3,498 (median). Tea Break: runs with none won 35.6%, one 54.9%, two 59.8%, three or more 54.0%. Day 2026-12-01, B2's one unwon day, was won by 7 of the 16 named strategies.

**What is not met, and what next.**

- **The unlock cards still cost the bots about 10 points** (5.8). Volley's change gained 2.8 points with every card (33.5% to 36.3% on seeds 1 to 67), and weakening Sharp Pebbles narrowed the gap again, because the base pool, where it comes up twice as often, leaned on it most. What is left comes from the five other sidegrade perks: the bots take them without asking whether they suit their towers, and with every card unlocked the pure perks come up half as often. A person who picks with care should lose less than the bots, but I cannot measure that. I kept the bar at 5 points, because unlocks must not change power either way (brief 3.7). Next: B4 gives the bots a perk choice that fits their towers (3.5), and G5, the last run tuning, softens the sidegrades' costs if the gap stays above 5.
- **No card decides a run:** Sharp Pebbles fell from +10.0 to +6.1, within one standard error of the bar on 40 seeds; B4's 200 seed experiment decides, and if it stays above 5, G5 looks at it again. The Longbow Loft card also measured +6.1. The bar now leaves tower cards out (they are reported): a tower card's value to the bots is mostly where their build rule puts the tower, as the Catapult card at -8.2 shows below, and the Longbow Loft brings the answer to two of the four bosses a run must now beat. I would not weaken a campaign tower to move it.
- **Fair maps and fair packs** each miss by one stack and three band 4 packs, with the fixes in 3.4 for the level designer to confirm with the bots.
- **The bottom of the card table**, for B4: with these bots the Pumpkin Catapult card is worth -8.2 points and the Bakery card -5.8. The bots build a new tower at once on their best spot; a Catapult there cannot touch band 2's Flitters, and a Bakery card is a lost pick until wave 9. I expect smarter bots to move both toward 0, so I changed neither.

## 5. Evidence: what each change does

All plays are Normal with the base cards and the 16 named strategies unless a table says otherwise. "Started 18" is the share of plays that started the boss wave, "won of those" the share of those that won. Each row is one scratch copy of da1fc38 with only the named change (section 6).

### 5.1 The lives cap and the boss wave's strength (the maps of da1fc38, seeds 1 to 50, 800 plays a row)

| What-if | Won | Started 18 | Won of those | Grumblesack | Ironshell | Moon Moth | Old Tusk | Wins where the boss reached the base |
|---|---|---|---|---|---|---|---|---|
| da1fc38 as it is | 25.4% | 63.4% | 40.0% | 58.7% | 36.1% | 21.4% | 38.4% | 57.6% |
| Lives cap, boss wave at 270 | 11.5% | 62.1% | 18.5% | 47.0% | 5.4% | 1.8% | 11.9% | 7.6% |
| Cap, boss wave at 80 | 56.9% | 62.1% | 91.5% | 99.3% | 79.2% | 94.5% | 92.7% | 0.9% |
| Cap, boss wave at 120 | 47.5% | 62.1% | 76.5% | 99.3% | 60.0% | 67.9% | 73.4% | 3.7% |
| Cap, boss wave at 160 | 33.9% | 62.1% | 54.5% | 94.0% | 28.5% | 33.0% | 53.2% | 4.1% |
| Cap, boss wave at 200 | 24.6% | 62.1% | 39.6% | 81.9% | 13.1% | 18.3% | 34.9% | 3.6% |

The boss columns are "won of those" for runs with that boss. With the cap, the few "reached the base" wins are bosses defeated on the base tile itself, before its center.

Tea Break, da1fc38: runs that picked none won 6.2%, one 31.3%, two 42.0%, three or more 64.5%. With the cap and the boss wave at 120: 27.4%, 66.7%, 66.1% and 70.6%. A second and third copy no longer add anything; the gap between none and one is mostly which strategies take economy cards at all (1.4 gives the card experiment).

### 5.2 Calibrating the boss waves (the new maps, packs and cap; seeds 1 to 100, 1,600 plays a row)

The share of the named strategies' runs that started wave 18 and won, by band 6 pack, with every boss wave of a boss at the strength shown:

| Pack | Level 0 | Level 1 | Level 2 | Level 3 | 62% at |
|---|---|---|---|---|---|
| b6_grumble_hill | 180: 99% | 210: 96% | 240: 91% | 270: 81% | 323 |
| b6_grumble_march | 180: 97% | 210: 90% | 240: 82% | 270: 65% | 275 |
| b6_iron_gate | 90: 90% | 110: 83% | 130: 72% | 150: 62% | 150 |
| b6_iron_road | 90: 91% | 110: 84% | 130: 72% | 150: 60% | 147 |
| b6_moon_rise | 100: 97% | 120: 89% | 140: 73% | 160: 59% | 155 |
| b6_moon_tide | 100: 87% | 120: 78% | 140: 63% | 160: 48% | 142 |
| b6_tusk_charge | 100: 100% | 125: 96% | 150: 89% | 175: 77% | 206 |
| b6_tusk_night | 100: 96% | 125: 93% | 150: 79% | 175: 62% | 175 |
| All runs won | 76.4% | 71.4% | 62.7% | 51.4% | |
| Started 18, won | 94.1% | 88.1% | 77.3% | 63.3% | |

The first chosen values were these, in multiples of 10, except grumble_hill: 323 is past the last level tried, and at 320 only 48% of its boss waves were won on 200 seeds, under the bar. Between 270 (81%) and 320 (48%), 62% falls near 300. Section 1.2 gives the last step, after the card changes.

By strategy at level 3, the boss is a check of the board, not a coin flip: towers_tall started wave 18 in 93% of its runs and won 79.6% of those; economy_wide 92% and 53.3%; risk_wide 63% and 58.7%. Strategies that pick tower cards first own every tower by the boss.

### 5.3 The maps (static check of every stack)

| Stacks | Build spots | Bakery spot reaches | Shortest route, no gate | With the best single gate |
|---|---|---|---|---|
| top_fork with mid_cross or mid_ladder, before | 9 | 0 or 1 | 14 to 15 | 15 to 16 |
| the same, after | 12 | 3 | 14 to 16 | 18 to 20 |
| top_twin with mid_cross or mid_ladder, before (two entrances) | 9 | 0 or 1 | 12 to 14 | 13 to 14 for the shorter entrance |
| the same, after | 12 | 3 | 12 to 17 | 16 to 18 for both entrances |
| top_wing with mid_cross or mid_ladder, before | 9 | 0 or 1 | 18 to 19 | 21 to 22 |
| the same, after | 12 | 3 | 18 to 22 | 21 to 23 |
| every other stack, before | 10 or 11 | 0 or 1 | 13 to 26 | 13 to 26 |
| the same, after | 12 | 3 | unchanged | unchanged |

### 5.4 The map changes one at a time (seeds 1 to 50 unless shown)

| What-if | Won | Lost by wave 6 | mid_cross maps won | mid_ladder maps won |
|---|---|---|---|---|
| da1fc38, no cap, boss at 270 | 25.4% | 17.2% | 10.8% | 4.4% |
| 12 spots and Bakery clusters only, no cap, boss at 270 | 30.1% | 21.4% | 21.6% | 21.2% |
| The same, only the runs that drew no Bakery card in their first five picks | 41.3% | 16.7% | | |
| 12 spots, clusters, new band 2 packs, cap, bots wait for wave 9 to build a Bakery, boss level 1 (100 seeds) | 67.4% | 6.6% | | |
| The same with the redrawn middles (100 seeds) | 71.4% | 2.4% | 80.3% | 75.3% |
| The redrawn maps with the old band 2 packs, boss level 1 | 73.0% | 4.4% | | |

Spots and clusters alone lifted the walls' late game but not their early game. Their early losses rose because the bots built a Bakery as soon as they drew its card: runs that drew it in the first five picks lost 23.9% by wave 6. The redrawn middles removed the early walls.

### 5.5 Gold (the named strategies with no early calls)

| | Gold unspent when wave 18 starts (median) | Nothing left to buy at the start of wave 13 / 14 / 15 |
|---|---|---|
| da1fc38 | 4,584 | 39% / 83% / 99% |
| New maps, packs and cap, boss level 1 | 3,762 | 3% / 30% / 78% |
| The same at strength step 12 | 4,433 | 6% / 49% / 95% |
| The same at strength step 14 | 5,272 | 16% / 69% / 100% |

### 5.6 The strength step (new maps, packs and cap, boss level 2, seeds 1 to 50)

| Step | Won | Best strategy | Started 18 | Won of those | Lost by wave 6 |
|---|---|---|---|---|---|
| 10 (100 seeds) | 62.7% | 81.0% | 81.1% | 77.3% | 2.4% |
| 12 | 61.8% | 82.0% | 78.5% | 78.7% | 2.8% |
| 14 | 53.9% | 78.0% | 70.5% | 76.4% | 4.4% |

A higher step mostly moves losses into waves 7 to 17 and fills the board sooner (5.5). The boss waves do the same job without the gold.

### 5.7 Risk cards (the risk replay: economy_wide on seeds 1 to 30, every card, each of waves 2 to 17 played again with each risk card on the same towers and no more buying)

Extra lives lost and extra gold gained against the same wave with no risk card, waves 2 to 8:

| Card | B2 (da1fc38): lives, gold, gold a life | New maps, cards as they are | New maps, new cards |
|---|---|---|---|
| Crowded Night | +5.33, +151, 28 | +4.96, +168, 34 | unchanged |
| Thick Hides | +4.15, +119, 29 | +3.79, +139, 37 | unchanged |
| Flock | +4.29, +139, 32 | +4.00, +144, 36 | unchanged |
| Moonlit Wager | +8.25, +211, 26 | +8.09, +264, 33 | unchanged |
| Crasher Escort | +6.64, +190, 29 | +6.37, +224, 35 | unchanged |
| Pip Parade | +9.98, +80, 8 | +10.39, +100, 10 | 16 Pips, 120 gold: +6.43, +185, 29 |
| Hurry Night | +0.89, +131, 148 | +0.55, +139, 251 | 50% faster, 60 gold: +1.24, +78, 63 |
| Gateless Night | +1.44, +150, 104 | +0.69, +166, 242 | 60 gold: +0.69, +81, 119 |

Pip Parade also lost 40% of the early waves it touched, and now 10.5%. In waves 9 to 17 every risk card is cheaper, because the board is bigger; that is the natural shape (risks pay most when gold is short and cost least when the board is strong), so I left it.

### 5.8 Where the unlock cards' gap comes from (the candidate before the Sharp Pebbles and Volley changes, seeds 1 to 34, 544 plays a row)

Each row moves one group of unlock cards into the base pool, so it is offered from the first run.

| Pool | Won | Best strategy | Started 18 | Won of those |
|---|---|---|---|---|
| Base cards | 47.6% | 79.4% | 82.0% | 58.1% |
| Base and the six unlock perks | 34.6% | 52.9% | 77.4% | 44.7% |
| Base and the three unlock risk cards | 47.1% | 79.4% | 80.1% | 58.7% |
| Base and Piggy Bank, Bargain, Iron Gate | 45.6% | 73.5% | 80.5% | 56.6% |
| Every card | 30.9% | 50.0% | 73.2% | 42.2% |

The bots pick a perk among those offered without asking whether it suits their towers, so a sidegrade costs them more than it costs a person. In the every-card runs, the runs that took a sidegrade won the boss wave about as often as the runs that did not, or more often, with one exception, Volley against the bosses Longbows answer: Ironshell 28.8% with it, 47.9% without; Old Tusk 34.3% and 37.8%. Steady Aim, its pure counterpart, went the other way: 48.2% against 32.7% on Ironshell.

## 6. How to repeat

The levers in this plan do not exist in the repo yet, so I played them in scratch copies of da1fc38 (`git archive da1fc38`, then `godot --headless --path . --import`) with five small hooks that read environment variables. With no variable set, each copy plays exactly as da1fc38 does. None of this is meant for the repo.

| Hook | File | What it does |
|---|---|---|
| `FL_LIVES_CAP=1` | src/sim/battle.gd, `add_lives` | `lives = maxi(lives, mini(lives + amount, start_lives))` |
| `FL_BOSS_STRENGTH=N` | src/run/map_assembler.gd, step 4 | wave 18's strength is N |
| `FL_BS_<boss id>=N`, `FL_PS_<pack id>=N` | the same | wave 18's strength is N when the run's boss, or its band 6 pack, is that one |
| `FL_BAKERY_WAIT=W` | tools/balance/run_bot.gd, `_next_step` | the bot builds no Bakery before wave W |
| `FL_BOSS_AIM=1` | tools/balance/run_bot.gd, `play` | when the boss wave starts, every attacking tower aims at Strong |

The data what-ifs are plain file edits in a copy: the six segment files and the packs of 3.4, and the cards of 3.3. The final candidate is all of them together, with the cap, `FL_BAKERY_WAIT=9` and the eight pack strengths of 1.2. The Sharp Pebbles and Volley changes came last, after 5.8, and section 4 says which rows include them. Two steps before that, grumble_hill was at 320 and band 4 was unchanged; section 4 also says where that candidate is used. For example, from the copy's root:

```
FL_LIVES_CAP=1 FL_BAKERY_WAIT=9 FL_PS_b6_grumble_hill=290 FL_PS_b6_grumble_march=270 FL_PS_b6_iron_gate=150 FL_PS_b6_iron_road=150 FL_PS_b6_moon_rise=150 FL_PS_b6_moon_tide=140 FL_PS_b6_tusk_charge=200 FL_PS_b6_tusk_night=180 godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=34 pool=base relaxed=0 out=OUT.json
```

The same arguments with `mode=daily from=0 count=134 extra=400`, `mode=cardvalue first=1 count=20 pool=base`, `mode=risk first=1 count=10 strat=economy_wide` and `relaxed=1` or `pool=all` give the other tables. The strength step what-ifs use runs.gd's own `tweak=strength_step:12`. Run seeds, days and strategy seeds are runs.gd's own (docs/balance/README.md), so B2's seeds give B2's plays. Once S3, R3 and L5 land, the same runs.gd jobs need no hooks except the Bakery rule, which belongs in the bots (3.5).

Tests on the final scratch copy, with every data change of section 3 except the untested band 4 proposals: `godot --headless --path . --script res://tests/run_tests.gd -- --only=levels,run` ran 220 tests, 218 passed. Every tests/levels check passed: every stack is a valid map with a gate that steers, every bottom's last row is scenery, the new creature rule holds for every choice of packs, and the spawn bound holds. The two failures are expected: the risk reward pins in tests/run/test_real_data.gd (R3 updates them, 3.3), and tests/run/test_source_rules.gd, which my hooks break on purpose.

The scratch copies, the hooks and every result file stay in the session's scratch folder under `g3/`. Section 3 has every change, so nothing there is needed to build.

## 7. For Bart

These change what Bart approved at hard stop A, so they are for the DM to tell him:

1. **A run's boss must be beaten on Normal.** Lives never rise above the starting lives, so Tea Break repairs lost lives but cannot bank extra ones. Its card says "Gain 5 lives, but never more than you started with." On Relaxed, a run with more than 20 lives can still survive the boss, as in the campaign.
2. **Each run boss wave has its own strength,** from 140 to 290 by pack, instead of 270 for all (1.2). The Moon Moth, Ironshell and Old Tusk come weaker than now, Grumblesack stronger.
3. **Run maps hold 12 build spots** (were 9 to 11), every map has a spot where a Bakery reaches 3 towers, and two middle segments are redrawn so the first gate makes a detour.
4. **Five more cards:** Sharp Pebbles adds 1 damage (was 2), Hurry Night is 50% faster for 60 gold (was 25% for 100), Gateless Night pays 60 gold (was 120), Pip Parade brings 16 Pips for 120 gold (was 24 for 100), and Volley's arrows deal 25% less damage (was 40%).
5. **Five wave packs** ease a little: three in band 2 bring 5 or 6 Shellbacks instead of 8 or 9, and two in band 4 bring fewer Shellbacks with the first Menders and one Dusk Moth fewer. Three more small band 4 cuts are proposed for the level designer to confirm.
6. **Run length, for Bart to choose** (1.8): keep "about 15 to 20 minutes at 1x" and lengthen the waves, or take "about 12 to 16 minutes at 1x counted as for levels, about 15 to 20 minutes of real play with the card drafts". I recommend the second. Bart chose the second on 2026-10-25.
7. **New bars** for the bots (RULES 14.8, 15). They are checks, not rules a player sees.

Nothing in the campaign changes.

## 8. Open questions

1. The DM: contract changes 1 to 5 of 3.1 need the architect. Until changes 2 and 3 land, the level designer can make every segment and band 2 and 4 change but not the boss wave strengths, and runs keep a boss at 270, which the lives cap alone would make nearly unbeatable (5.1: 18.5% of the runs that reach it win). So S3's cap and R3 and L5's boss strengths should land together, or the cap should wait for them.
2. Bart: run length (7.6). Decided on 2026-10-25: Bart chose the second, now in RULES 14.1.
3. Three bars are not met yet (section 4): every card unlocked (about 10 points, mostly the bots' blind perk picks; B4 and G5), one map stack, and three band 4 packs (both for L5, with B4 confirming; L5's results: 3.4a). Sharp Pebbles is within one standard error of its bar; B4's larger card experiment decides.
4. The DM, on the Fold5 run check (contract 13): how long a real run takes, with drafts. That settles 1.8 better than any count.

## 9. G5: the second run tuning (2026-10-26)

Task G5 answers the second run and daily report, docs/balance/runs-2026-10-26.md (B4, commit e9b8e11). B4 met every bar of RULES 14.8 and 15 but three. This section settles two of them: every card unlocked, and Deep Lullaby. The third, two map walls on `mid_merge`, was the level designer's. L8 has fixed it (3.4a), and item 3 of 9.1 answers the two checks that L8 moved. Nothing here changes a map, a pack or a base card.

### 9.1 Decisions

#### 1. Every card unlocked: unlocked tower perks wait for the base perks, and three of them cost less

B4 measured the 16 strategies with every card unlocked at 13.3 points below the base cards on Normal (37.1% against 50.4%; the bar is 5 points either way). Its F5 traced the gap to the six unlocked tower perks, and found that bots that never take one still lose 8.0 points: with every card a draft holds 12 tower perks instead of 6, so each base perk comes up about half as often.

I played 12 candidates on seeds 1 to 100, and the main ones again with L8's `mid_merge` (9.2). The numbers below are L8's. What they show:

- **Numbers alone cannot reach the bar.** The analyst's three softer sidegrades (option a) gain 4.6 points, to -8.4. Making all six nearly free still leaves -4.8, on the bar's edge, with cards that no longer cost anything (RULES 14.6). Stronger sidegrades also break another bar: at 10% less damage Volley measured +6.0 in the card experiment with every card, and Twin Pebbles at 1 less damage +5.7, over the +5 of "No card decides a run".
- **With fair numbers, what is left is dilution.** With softer Frost Chime, Volley and Long Fuse (candidate E) the gap is still -10.2. The bots took 2.4 base perks a run instead of 3.8. Setting right two of the bots' fit pairs (9.4) gained only 0.6. A careful player feels the same thing: Sharp Pebbles comes up half as often.
- **Moving the bar would mean accepting that.** A bar that fair cards meet would have to allow about 12 points below, nearly all of what B4 found. Unlocks are a reward for playing. They must never make runs easier (brief 3.7), and they should not make them harder either. So I did not choose option c.
- **A draft rule that removes the dilution meets the bar.** Rule 1, "a tower's unlocked perk only once the run holds that tower's base perk", reads more easily but removes only half of it, because an unlocked perk still competes with the other towers' base perks: -8.1. Rule 2, "unlocked tower perks only while no base tower perk can be offered", keeps every draft the same as with no unlocks until every tower in the run holds its base perk. Then the unlocked perks come in as a second perk for a tower. Alone it measured -4.2. With E's numbers: **-2.9 on Normal and -1.1 on Relaxed**, from -13.0 and -4.7 on the same seeds.

So the decision is option b, Rule 2, with three fairer sidegrades. Rule 2 changes the draft rule of RULES 14.4, which Bart approved (9.3).

What Rule 2 costs: an unlocked tower perk is offered 1.4 times a run instead of 7.2, mostly in the last third of a run, and a new tower card hides the unlocked perks again until its base perk is taken. Unlocks still add variety. The six other unlockable cards (Piggy Bank, Bargain, Iron Gate and three risk cards) join their kinds at once, as now. And the perks come when a run has little else to choose: B4 found that from wave 16 every play had nothing left to buy (F1), so a late card that gives gold does nothing.

The three cards. Each still has a real cost, also when taken after its base perk:

| Card | Now | New | Why |
|---|---|---|---|
| Frost Chime | Bells reach 0.5 tiles less | 0.25 tiles less | A ring 0.5 tiles shorter took 44% of a tier 1 Bell's area and 36% of a tier 2 one's. It was the worst pick with every card: -4.8 in B4's card experiment, below zero on both halves of the seeds. At 0.25 tiles it takes 23% and 19%. |
| Volley | arrows deal 25% less damage | 15% less | At 25% less a Triple Bow's 4 arrows (4 x 53 = 212 damage) did no more against a crowd than its own 3 (210), and every single target, the boss too, took a quarter less. It was -3.0 in the card experiment, and it cost 3.5 points when added to the pool (F5). At 15% less: 4 x 60 = 240, and a single target takes 15% less. At 10% less it measured +6.0. |
| Long Fuse | reloads 0.5 s slower | 0.25 s slower | At 0.5 s a tier 1 or 2 Firework Tower fired a third less often for a third more reach. At 0.25 s it fires a fifth less often. It cost 1.4 points when added to the pool (F5). |

Twin Pebbles stays at 2 less damage. Its card is already a good pick (+2.4 with every card), and at 1 less it measured +5.7. What it cost in F5 (2.6 points when added to the pool) was dilution of Sharp Pebbles, which Rule 2 removes.

#### 2. Deep Lullaby: no change

B4 measured it at +5.8 points with every card (bar +5), on 162 offers with a standard error of 1.9. By seed it is +7.8 on seeds 1 to 100 and +3.9 on 101 to 200, and with the base cards +1.9 on 369 offers. Steady Aim swung the other way (+2.1 and +8.4). That is noise, as the analyst says. Part of it was also the weak cards it was offered with: a card's gain is counted against the other cards in its draft, and Frost Chime, the other Bell perk, was the worst pick. With Rule 2 and the new numbers it measured +0.2 on seeds 1 to 100, with a standard error of 1.3 on 185 offers (9.2). Weakening it would change a base card, and with it every base bar. If B5's experiment on 200 seeds still puts it above +5, it becomes +5 slow (35% becomes 40%) in the next tuning, and the base bars are measured again.

#### 3. After L8: `towers_tall` at 75.5% and `mid_eye` at 0.748 need no change

L8's `mid_merge` (3.4a) removed both walls. With it, two base-card checks sit a hair past their bars (RULES 14.8), on L8's measurement over seeds 1 to 200:

- `towers_tall` wins 151 of 200 runs: 75.5% against the 75% ceiling. That is one run over the line, and one strategy's rate over 200 runs has a standard error of 3.1 points; B4's four chunks of 50 seeds ran from 70% to 78%. It rose by two runs because two walls are gone, not because the strategy got stronger: the 16 together rose too, from 50.4% to 52.6%, inside 35% to 55%. Taking back one win in 200 would mean making Normal harder for every strategy, to answer noise. On seeds 1 to 100 it is 75.0% (9.2).
- `mid_eye` is 0.748 times all runs against the 0.75 bar. Its own runs did not change: no `mid_eye` map uses `mid_merge`, and they still win 39.4% of their plays. The ratio fell only because all runs rose. One segment's ratio on about 30 seeds has a standard error of about 0.1 times (B4 F3), and its stacks lose 3.7% or less by wave 6, so it is no wall.

Both are within noise, and neither needs a change. G5 changes no base card, so B5 will measure the same two numbers on the same seeds. B5 reports them as at the bar, with their standard errors. If a later data change moves either one further out, its owner looks again: the level designer for `mid_eye`, and I for `towers_tall`. The check that would show a real weakness in `mid_eye` is B4's suggestion 7, its eight stacks forced through whole runs.

### 9.2 Measured candidates

Every card unlocked, the 16 named strategies, run seeds 1 to 100 (1,600 plays a row), B4's bots (Bakery from wave 9, perks that fit, no boss aim). The gap is the row's win rate less the base cards' on the same seeds and strategies. Its standard error counts each seed as one sample. The bar is 5 points either way. Two maps: L5's `mid_merge`, which B4 measured (base cards 48.4% on Normal, 94.9% on Relaxed), and L8's (50.1% and 95.3%), which changes only the 18 of these seeds whose map uses `mid_merge` (9.4). "Offered, taken" is how often a run is offered, and takes, one of the six unlocked tower perks.

| Candidate | What changes | Normal, L5 map | Normal, L8 map | Relaxed, L5 map | Relaxed, L8 map | Offered, taken |
|---|---|---|---|---|---|---|
| Today | nothing | -12.4 (1.5) | -13.0 (1.5) | -4.8 (0.9) | -4.7 (0.9) | 7.2, 1.3 |
| a, the analyst's | Volley 15% less, Twin Pebbles 1 less, Long Fuse 0.25 s | -8.0 (1.4) | -8.4 (1.5) | | | 7.2, 1.3 |
| B | a, but Volley 10% less; Frost Chime 0.25 tiles | -6.6 (1.3) | | -1.8 (0.8) | | 7.2, 1.3 |
| B' | a with Frost Chime 0.25 tiles | -6.9 (1.3) | | | | 7.2, 1.3 |
| E | B' with Twin Pebbles as it is | -9.8 (1.4) | -10.2 (1.5) | | | 7.2, 1.3 |
| C, the bound | all six nearly free: Volley 5% less, Twin Pebbles 1 less, Long Fuse 0.1 s, Frost Chime 0.25 tiles, Heavy Pumpkins 0.25 s, Spice Rack 5 points | -4.9 (1.3) | -4.8 (1.4) | | | 7.2, 1.3 |
| Rule 1 | today's numbers | -8.4 (1.3) | -8.1 (1.3) | | | 3.7, 0.9 |
| Rule 1 with a | | -5.7 (1.2) | | | | 3.7, 0.9 |
| Rule 1 with B | | -4.6 (1.2) | | | | 3.7, 0.9 |
| Rule 2 | today's numbers | -4.1 (1.2) | -4.2 (1.2) | | | 1.4, 0.5 |
| Rule 2 with a | | -2.6 (1.1) | | | | 1.4, 0.5 |
| **Rule 2 with E: chosen** | | **-2.9 (1.2)** | **-2.9 (1.2)** | **-1.1 (0.8)** | **-1.1 (0.7)** | **1.4, 0.5** |
| B, two fit pairs set right | the bots pass Twin Pebbles on Quickshots and Long Fuse on Star Blooms; seeds 1 to 50 | +0.6 (1.2) against B | | | | |

Gaps in points, standard errors in brackets.

- **Base cards unchanged.** No candidate changes a base card, and both rules touch only unlocked perks, so a pool with no unlocks plays exactly as today. I checked it for the chosen candidate: its copy, with the rule and the new cards, played the base cards on seeds 1 to 50 (L5's map) and gave B4's 800 rows field for field.
- **The chosen candidate's Normal runs on the L8 map,** against today's every card and the base cards: won 47.2% (37.1%, 50.1%), lost by wave 6 3.0% (3.5%, 1.6%), lost in waves 7 to 17 18.6% (22.9%, 16.0%), lost at the boss 31.2% (36.5%, 32.3%). Of the runs that start wave 18: Grumblesack 64% won, Ironshell 56%, Moon Moth 64%, Old Tusk 55%. Its best strategy is `towers_tall` at 74.0%. The bots take 3.7 base perks a run (3.8 with no unlocks, 2.4 today).
- **The card experiment with every card,** the chosen candidate, seeds 1 to 100, L8 map (1,541 drafts): no base perk, gate, economy or risk card is above +5. The highest are Iron Gate +3.2 and Crasher Escort +1.8. Deep Lullaby is +0.2 (standard error 1.3, 185 offers), Steady Aim +0.0 and Sharp Pebbles -0.5. The Longbow Loft card is +8.0 (a tower card, reported). The six unlocked perks are offered only 11 to 34 times each, too few to judge: Long Fuse +9.1 (standard error 6.5, 11 offers) and Volley +5.6 (6.2, 18 offers) sit within one standard error of the bar. Offered all run, without the rule (candidate E, seeds 1 to 50), they measured +3.6 and +4.2 on 46 and 48 offers. For comparison, on the same seeds B4 had Deep Lullaby at +7.8, Volley -2.2 and Frost Chime -3.9, and candidate B had Volley at +6.0 and Twin Pebbles +5.7.

### 9.3 For Bart

These change what Bart approved, so they are for the DM to tell him:

1. **Unlocked tower perks wait for the basic perks (RULES 14.4).** In a run, the six unlockable tower perks (Twin Pebbles, Heavy Pumpkins, Frost Chime, Volley, Long Fuse, Spice Rack) are offered only once every tower in the run has its basic perk (Sharp Pebbles, Wide Splash and so on). Until then a draft is the same as with no unlocks. Why: with every card unlocked, each basic perk came up half as often, so unlocking cards made runs harder: the bots won 13 points less with every card than with none. With this rule and item 2 they win about 3 points less on Normal and 1 on Relaxed, inside the bar of 5. The cost: unlocked perks show up about a fifth as often as now, mostly late in a run, as a second perk for a tower.
2. **Three unlockable cards cost less (RULES 14.6).** Frost Chime's Bells reach 0.25 tiles less (was 0.5). Volley's arrows deal 15% less damage (was 25%). Long Fuse reloads 0.25 s slower (was 0.5 s). Frost Chime and Volley were traps: taking them did worse than the other cards on offer. Each still has a real cost, and their card texts change to match.
3. Not chosen: keep the draft as it is and let the bots' bar allow about 12 points less with every card. Unlocked perks would show up as often as now, and runs would get harder as cards unlock.
4. After the level designer's fix of two map walls, two bot checks sit a hair past their bars: the best strategy wins 75.5% (ceiling 75%), and one map segment is 0.748 times all runs (bar 0.75). Both are within noise, so nothing changes (9.1, item 3).

### 9.4 How to repeat

Every row was played in scratch copies of 53d6ad7 (`git archive`, the working tree's tools/balance/ copied over, then `godot --headless --path . --import`), at most 3 jobs at once. For runs, 53d6ad7 plays exactly as B4's e9b8e11: every card on seeds 1 to 50 gave B4's 800 rows field for field. Since then only L8 (496cd46) changed run data, and the L8 rows below use its committed `mid_merge`. So B4's raw files (docs/balance/raw/2026-10-25-b4/: `rates_base_r0`, `rates_all_r0`, `rates_base_r1` and `rates_all_r1`, seeds 1 to 100) are the L5 map's baselines. A candidate is a copy whose data/cards/cards.json carries the numbers of 9.2. Each row is two jobs, for example:

```
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=1 count=50 pool=all relaxed=0 out=OUT_1.json
godot --headless --path . --script res://tools/balance/runs.gd -- mode=rates first=51 count=50 pool=all relaxed=0 out=OUT_51.json
```

with `relaxed=1` for Relaxed, `pool=base` for the base check, and `mode=cardvalue first=1 count=50 pool=all` (and `first=51`) for the card experiment.

- **The rules** were a few lines in the copy's src/run/run_session.gd, `_eligible()`. Rule 1 skips a perk that has an unlock condition unless the picks hold a perk of the same tower with none. Rule 2 builds the list as today, then, if the list holds a perk with no unlock condition, drops every perk that has one.
- **The fit what-if** changed two pairs in the copy's tools/balance/run_bot.gd `UNFIT`: `twin_pebbles` to `quickshot`, and `long_fuse` to `star_bloom`. G3 3.5 had them backwards: Twin Pebbles' flat cost falls hardest on small hits, so it suits Stone Slings, and Long Fuse's extra reload costs a Star Bloom (1.0 s) more than a Skyrocket (1.5 s).
- **The L8 map.** A seed's map comes from its seed alone, so L8's `mid_merge` changes only the seeds whose map uses it: 4, 10, 26, 28, 39, 41, 44, 45, 51, 52, 74, 79, 80, 83, 84, 86, 89 and 100 of 1 to 100. I played those seeds again in copies with L8's data/segments/mid_merge.json (`first=4 count=1` and so on) and put their rows in place of the old ones. A one-seed job gives exactly the rows of a full job: seed 4's 16 rows matched B4's.

Nothing in the repo changed to play any of this. The copies, hooks, job list and result files stay in the session's scratch folder under `g5/`.

### 9.5 Open questions

1. The DM: a saved run or daily that has already taken Frost Chime, Volley or Long Fuse will not load after this change. RunSession.from_data ties the battle's card effects to the picks' effects in the current cards.json (contract 5.6), and the App deletes a saved game that fails a check at launch. G3's card changes did the same. Before release that costs a tester one run. After release every card number change would cost players their saved run, so the DM may want a rule for it before then.

### 9.6 Changes per owner

#### Roguelite engineer

data/cards/cards.json, three cards. Every other card is unchanged.

| id | Field | Now | New |
|---|---|---|---|
| `frost_chime` | effects | `tower_add` reach, `amount` -50 | `tower_add` reach, `amount` -25 (`tower_hits_air` unchanged) |
| `frost_chime` | text | Lullaby Bells also slow flyers, but reach 0.5 tiles less. | Lullaby Bells also slow flyers, but reach 0.25 tiles less. |
| `volley` | effects | `tower_pct` damage, `pct` 75 | `tower_pct` damage, `pct` 85 (`tower_add` targets 1 unchanged) |
| `volley` | text | Longbow Lofts hit 1 more target, but deal 25% less damage. | Longbow Lofts hit 1 more target, but deal 15% less damage. |
| `long_fuse` | effects | `tower_add` reload_ms, `amount` 500 | `tower_add` reload_ms, `amount` 250 (`tower_add` reach 100 unchanged) |
| `long_fuse` | text | Firework Towers reach 1 tile further, but reload 0.5 s slower. | Firework Towers reach 1 tile further, but reload 0.25 s slower. |

src/run/run_session.gd, `_eligible()`, once the contract has the rule: build the list as today; then, if it holds a perk whose `unlock` is empty, drop every perk whose `unlock` is not empty. The rule reads only the pool, the picks and the run's towers, so offers stay a function of the saved state, and a restored run shows the same offers.

tests/run:
- test_real_data.gd pins Volley (lines 199 to 202): its text and `pct` 75 become the new text and 85.
- test_run_session.gd, `test_offers_are_pinned_for_fixed_seeds`, pins the every-card drafts of five seeds. Several offer Twin Pebbles before Sharp Pebbles is taken, so those pins change under the rule; work them out again. The base-card pins stay.
- New tests: with every card and only the Sling Post, no unlocked perk is offered until Sharp Pebbles is taken, and Twin Pebbles can be offered after it. A new tower card hides the unlocked perks again until its base perk is taken. A pool with no unlocked cards gives the same offers as today. A pool that lacks a tower's base perk still offers that tower's unlocked perk once no base perk is eligible.

#### Architect, through the DM

- 3.4, drafts, eligible cards, one more line: "a perk with an unlock condition (RULES 14.6) only while no perk without one is eligible".
- 2.11's card table, text only: `frost_chime` `tower_add` reach -25; `volley` `tower_pct` damage 85; `long_fuse` `tower_add` reload_ms 250.

#### UI engineer

src/ui/info_screen.gd, "Cards" section. After "Playing unlocks new cards for later runs. Each one is a sidegrade: it changes how something works and carries a cost." add: "A tower perk you unlocked is offered only once every tower in your run has its basic perk." (The DM dropped the example: Info names no tower or card, and two UI tests guard that.) Card texts come from cards.json, so nothing else changes on screen.

#### Game designer (done in this step)

RULES 14.4 (the rule), 14.6 (three rows, and a line on when unlocked perks come), and the change note at the top. The bars of 14.8 do not change. TUNING_RUNS 3.4a now shows L8's `mid_merge`, and this section.

#### Balance analyst (B5)

No bot or bar changes. On the committed data, with the seeds and days of RULES 14.8 and 15:

1. Every card unlocked, Normal and Relaxed (bar 5 points either way). Mine on seeds 1 to 100 with L8's map: -2.9 and -1.1.
2. The card experiment, base cards and every card: no perk, gate, economy or risk card above +5, Deep Lullaby and the three changed cards especially. Under Rule 2 the six unlocked perks are offered about 1.4 times a run, so each rests on few offers (11 to 34 on my 100 seeds). Give their offers and standard errors next to their gains, and read a gain within one standard error of +5 as noise.
3. The base cards. G5 changes none, so the base bars are L8's. Report `towers_tall` (75.5%) and `mid_eye` (0.748) as at the bar, with their standard errors (9.1, item 3).
4. The daily over the same 400 days (it uses every card), against RULES 15.
5. Same seed, same run, with a wave save and with a draft open (`mode=det`): a draft's offers now depend on which base perks were picked.
6. The risk replay. It uses every card, so its towers change a little.
7. With L8's `mid_merge`: the forced stacks (phase C) and the fair maps. Useful, not required: B4's suggestion 7, `mid_eye`'s eight stacks forced through whole runs.

#### Nobody else

- Sim engineer: nothing. tests/sim/test_battle_effects.gd builds its own Twin Pebbles and Frost Chime effects (-2 damage, -50 reach) to test the sim and does not read cards.json, so it still passes.
- Level designer: nothing here. L8 stays as it is (9.1, item 3).
- data/stats/: no change. Nothing in the campaign changes.
