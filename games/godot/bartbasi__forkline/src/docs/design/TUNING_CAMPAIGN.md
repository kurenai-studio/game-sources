# Campaign tuning plan (G4)

Owner: game designer. 2026-10-25 (task G4). Answers the campaign pass, docs/balance/campaign-2026-10-25.md (B3, played on commit b1137be, findings F1 to F10), and QA's open question on Twists in docs/reviews/qa-2026-10-25.md. RULES.md holds the rules and numbers. This file says what changes in the campaign, why, and exactly what each owner types in. Section 4 lists what changes Bart's approvals.

## 1. Decisions

### 1.1 Region 3's third stars

The "No super tower" check failed on 3-1, 3-2, 3-3 and 3-6: a lone Sling Post with Bells earned all three stars (B3 F2). Their rules take away nothing a lone Sling Post needs, and their early waves bring no crowd before the gold (RULES 12.5). I replace the four third stars with rules the analyst has already checked at full size. None of them needs a wave change, so B3's searches are the verdict, except on 3-6, whose waves change for Relaxed (1.2).

| Level | Its idea (RULES 12.3) | Third star before | Third star now |
|---|---|---|---|
| 3-1 Lantern Festival | Anti air hits whole flocks. | Lose no lives. | Build no Sling Posts. |
| 3-2 Puffball Pond | Catch a splitter's pieces with splash. | Have at most 6 towers. | No tower above tier 2. |
| 3-3 Reed Maze | Some sockets matter more than others. | Use at most 2 gates. | Have at most 5 towers. |
| 3-4 Moth Lights | Armored flyers need a heavy anti-air shot. | Build no Sling Posts. | unchanged |
| 3-5 Two Shores | Split the defense between two entrances. | No tower above tier 2. | unchanged |
| 3-6 Moon Moth | A flying boss. Gates cannot help. | Lose no lives. | Build no Sling Posts. |

The shape of the region: the three levels about flyers (3-1, 3-4 and 3-6) ask the player to stop every flyer with Fireworks, the region's new tower. The other three limit spending, two with a tier cap and one with a tower limit. No two levels in a row share a rule.

Why each one:

- **3-1: Build no Sling Posts.** The level brings the Firework Tower. With no Sling Posts, the Firework is the only tower that can hit flyers, so the third star asks for exactly what the hint teaches: "Fireworks hit only flyers, but the whole flock at once." Its Twist, No Fireworks, is the mirror. Any tower but the Sling Post: 2090 and 2145 three-star builds in two 6000 build searches. The Sling Post can never earn this star, and a lone Catapult, Longbow or Firework cannot keep 15 lives here (flyers cost 108 lives, walkers 322). The tier 2 cap also works (799 in 2500), but it says nothing about Fireworks.
- **3-2: No tower above tier 2.** It replaces "Have at most 6 towers.", which Bart approved through TUNING_R2.md after the level designer found that 7 towers let Sling Posts alone earn three stars. B3 shows that 6 lets them too: 667 and 517 lone Sling Post three-star builds in two 6000 build searches. No tower limit works on 3-2. At most 5 failed the 6000 build check (138 lone three-star builds), and at most 4 leaves no three-star win for anyone. A tier cap fits the lesson: a Puff has 17 health even in the level's strongest wave (strength 145), so one tier 2 pumpkin pops it, and catching the pieces needs no tier 3. Any tower: 873 three-star builds in 2500. Lone Sling Post: none in two 6000 build checks (2416 and 2091 wins, none under the rule). Banning the Sling Post also works (2474 and 2393), but I keep the ban for the flyer levels.
- **3-3: Have at most 5 towers.** Its old rule, two of the three gates, fits the lesson best, but a lone Sling Post earned three stars under it (1156 and 806). With 5 towers on 9 spots, the three gates must make the road long, so the gate lesson stays in the star, and the five towers must cover every job. In my 6000 build search every three-star build has a Sling Post, a Catapult and a Firework, and the other two vary. The best keep 20 lives behind all three gates, at 1,3, 5,5 and 1,7. Lone Sling Post: none in two 6000 build checks. B3's 2500 build screen made it look thin: 92 three-star builds, the first at build 2073. My 6000 build search found 1429, the first at build 2140, and 915 of them keep all 20 lives (3.3). So the hard part is finding the build, not holding it, which is the puzzle the star should be. The fallback, if a later pass finds no three-star build, is "No tower above tier 2." (404 in 2500, lone Sling Post none in two 6000 build checks).
- **3-6: Build no Sling Posts.** The only rule tried that works. A tier cap leaves no three-star win (the boss needs tier 3), and with at most 6 towers a lone Sling Post keeps 20 lives (394 three-star builds in 2500). It fits the boss: the Moon Moth, its Flitters and the Dusk Moths fall to Fireworks alone, and the hint already says "Line its path with Fireworks." Any tower but the Sling Post: 1905 and 2114 three-star builds in two 6000 build searches on the waves as they are, and 2129 in a 6000 build search on the waves of 1.2, 1499 of them with all 20 lives (3.3).

Not chosen:

- **Only bans, or only caps.** With 3-4's ban and 3-5's cap already there, four bans or four caps out of six would make region 3 one rule.
- **Wave changes** (a dense Pip crowd by wave 5, RULES 12.5). Not tested, and a third star is cheaper to check. On 3-6 harder early waves would also work against 1.2.
- **The rules B3 found failing:** at most 5 towers on 3-1 or 3-2, at most 4 on 3-2, no gates on 3-3, at most 6 towers on 3-6, a tier cap on 3-6.

### 1.2 Level 3-6 on Relaxed: fewer Pips in waves 5 and 9

The Relaxed bar of RULES 12.6 stays as written: the plain recipe must win on Relaxed with no gates placed. I soften the level to meet it. I do not read the bar differently for 3-6. Relaxed is how the campaign keeps its promise of no grind wall (brief 3.9, RULES 16), and 3-6 is the level that opens region 4.

The change: in wave 5 the Pip group goes from 24 to 18, and in wave 9 from 30 to 22. Nothing else moves. Wave 5 shrinks from 56 creatures to 50 and wave 9 from 74 to 66. The largest wave stays 75 (wave 11).

Why counts and not strength, which B3 named as the lever: with no gates, entrance B's walkers take a straight road of 11 steps down the right edge, past few splash towers. At strength 115, where one pumpkin pops a Pip, the plain recipe still lost 17 lives in wave 5 and won with only 3 lives. The Pips leak because of the road, so fewer Pips is what helps. Section 3.2 has every variant I played.

| 3-6 | Relaxed, no gates | Relaxed placements won | Normal, best placement | Normal placements won |
|---|---|---|---|---|
| As now | lost in wave 9 (lost 20 lives in wave 5, the last 18 in wave 9) | 23 of 27 | won, 14 lives | 16 of 27 |
| Waves 5 and 9 at strength 115 | won, 3 lives | 26 of 27 | won, 14 lives | 19 of 27 |
| Chosen: 18 and 22 Pips | won, 12 lives | 27 of 27 | won, 14 lives | 18 of 27 |

12 lives on Relaxed with no gates is in line with region 2's gate and boss levels (2-4: 14, 2-5: 18, 2-6: 5). On Normal the best placement keeps 14 lives as before, because it lost no Pips in those waves, and the level still needs gates on Normal (no gates loses in wave 5, as before).

### 1.3 The 3-2 Twist (No Catapults): no change

It is fair, and narrow on purpose. The 1500 build search won nothing, but two 6000 build searches won 1711 and 1229 builds, the best with all 20 lives (B3 F5). The best win is a plain build: seven Sling Posts (three of them Quickshots and one a Stone Sling) and two Longbows, behind gates at 5,6 and 3,4, buying during waves. The Twist asks the player to hold Pip crowds and Puffs with no splash, which 1-4's Twist (also No Catapults) taught first. A narrow Twist is fine: it opens only after three stars, it earns no stars, and a Relaxed win clears it too (RULES 13).

QA's open question is answered by B3: the 3-2 Twist is won on Normal (two long searches), and the three-star wins QA's 1500 tries missed on 4-1 and 4-5 exist (864 and 940 in 3000, the first at builds 1050 and 1139). RULES 12.6 now says that a Twist a 1500 build search does not win gets two searches of 6000 builds.

### 1.4 RULES 12.6 and third stars that ban a tower

The reading needs one correction. The lone searches ("No super tower") are not what missed builds. It is the any-tower search of the "All three stars" check: a search that may use every tower seldom finds builds that leave one tower out entirely, because its random builds almost always hold the banned tower and its edits change one to three things at a time. On 3-4 and 4-2 it found no three-star build in 3000, and searches over the allowed towers found 2226 and 2077 (3-4) and 2015 and 2128 (4-2) in 6000 (B3 F6). So the levels pass, and the check was what needed fixing.

RULES 12.6 now says:

- **All three stars:** on a level whose star 3 bans a tower, the search may use only the other towers.
- **No super tower:** the tower the level's star 3 bans needs no lone search. It can never earn star 3. After G4 that covers 3-1, 3-4 and 3-6 (the Sling Post) and 2-5 and 4-2, whose banned towers were already skipped by the flyer rule. It saves the analyst six 6000 build searches a pass.
- **Twists:** a search of 1500 builds first. If it wins nothing, two searches of 6000 builds with different seeds decide, and one win is enough.

Levels with a ban after G4: 2-5 (Longbow Loft), 3-1, 3-4 and 3-6 (Sling Post), 4-2 (Pumpkin Catapult).

### 1.5 The thin margins

I change only what a first-time player needs. Every bar in RULES 12.6 is met on all of these.

| Item | Decision | Why |
|---|---|---|
| 2-3: the plain recipe keeps 9 lives | New hint (1.6). No wave change. | The bar is a win, met. 6 of the 11 lost lives are the six Flitters of waves 4, 6 and 8, which the recipe never shoots: its Sling Posts stand by the walkers' road, and the flight line runs along the top row. The three-star builds keep 20 lives with Sling Posts on the top spots 3,2 (at tier 2) and 6,2. G2 kept six Flitters as the fewest that keep the check certain, so the hint is the lever. |
| 4-1: needs the zigzag gates | New hint (1.6). No wave change. | The bar is 15 lives, met with 18. The two winning pairs are one side's high socket with the other side's low socket (1,3 with 5,7, or 5,3 with 1,7). The best single gate keeps 3 lives, both gates on one side lose in wave 5, and no gates loses in wave 4. A first-time player needs to be pointed there. |
| 4-6: the plain recipe keeps 10 lives | No change. | The bar is a win, met on 16 of 20 placements. 6 of the 10 lost lives are three of the four Dusk Moths Old Tusk releases at half health, which its card and the preview announce. 608 three-star builds keep all 20. A final boss may cost a first try some lives (RULES 12.5 aims at about 65% first-try wins on a boss level). |
| 4-5 Five Lives | No change. | 540 of 1500 searched builds win (36%), and the best keeps all 5 lives. Not a lottery. |
| 1-6 Double Trouble | No change. | 737 of 1500 win (49%), the best with 20 lives. |
| 2-5 Bubble Night | No change. | 326 of 1500 win (22%, up from 10% in B1), the best with 17 lives. |
| 4-1 Thin Purse | No change. For the phone. | The narrowest Twist by the search: 78 of 1500 win (5%), the best with 10 lives. Its best win is a plain build: Catapults first for the Pip crowds, Fireworks for the flyers, Sling Posts later, behind the same zigzag gates the new 4-1 hint teaches. If Bart's phone says it is too hard, the lever is 4-1's starting gold. That also moves the level itself, so it needs a new lone Sling Post check: today a lone Sling Post keeps at most 14 lives there under "Have at most 6 towers". |

### 1.6 Hints and highlights

| Level | Hint before | Hint now | Highlight |
|---|---|---|---|
| 2-3 | Armor blocks small hits. Longbow arrows go straight through. | Longbows ignore armor but can't hit flyers. Keep a Sling Post for the Flitters. | unchanged: 3,6, a spot that sees both side roads |
| 3-4 | Dusk Moths wear armor. Skyrockets punch through it. | Dusk Moths wear armor. Build a Firework on the glow and upgrade it early. | unchanged: 3,8, 0.4 tiles from both flight lines |
| 3-5 | none | none | none |
| 3-6 | The Moon Moth flies straight in. Line its path with Fireworks. | unchanged | unchanged: 3,5, 0.2 tiles from the Moon Moth's line |
| 4-1 | Bakeries make the towers around them faster. | Bakeries speed up nearby towers. Close one side high and the other side low. | unchanged: 3,4, the middle of the cluster |

Why:

- **3-4 and 3-6 already glow on a spot under the flight line.** On 3-4, spot 3,8 is 0.4 tiles from both lines. On 3-6, spot 3,5 is 0.2 tiles from the Moon Moth's line. The plain recipe never puts a Firework there (it builds a Sling Post on its best spot), which is why its moths get past (F9). So the cells stay, and 3-4's text now says what to build on the glow. "Upgrade it early" is the level's idea, a heavy anti-air shot, in first-try terms. The first Dusk Moths come in wave 3 at strength 50: 60 health, armor 5. A tier 1 Firework on the glow deals 7 a burst and gets about 6 bursts while one flies past, so it cannot pop one. A tier 2 deals 15 and needs 4. The Skyrocket still shows on the upgrade card with its numbers. 3-6's text already says to line the path with Fireworks, so it stays.
- **3-5 keeps no hint.** RULES 9.6 gives hints to the early levels and to levels that bring something new. 3-5, 4-4 and 4-5 bring nothing new and are where the player plays without help. The plain recipe wins 24 of 32 placements, and the dotted flight lines show in every build phase before a flyer wave. A hint there would be the first on a level with nothing new.
- **2-3:** the level's idea stays first (Longbows ignore armor, as their card says), and the second sentence says what a Longbow cannot do and which tower covers it.
- **4-1:** the Bakery stays first. "One side high and the other side low" names both winning pairs without naming sockets, and the route line shows the zigzag.

The texts are 79, 73 and 76 characters (the limit is 80). No highlighted cell moves, so the highlight checks in tests/levels still hold (3.4).

### 1.7 Moon Moth and Dusk Moths: no change, confirmed

- **Moon Moth.** G2's rule was to raise its wave to strength 85 to 100 if it died before halfway. In 62 watched flights it never did: every Moon Moth was alive at halfway with 50% to 81% of its health, and the earliest fell at 61% of its line (B3 F8). Its wave stays at 70 (1120 health). The new third star does not change that: the searches without the Sling Post found about 2000 three-star wins in 6000 on 3-6, each one beating the moth with Fireworks.
- **Dusk Moths.** No stat change. Tier 2 Fireworks are enough when they stand under the line: the three-star champions of 3-4 and 3-5 keep 18 to 20 lives with no tower above tier 2 (B3 F9). The plain recipe loses lives to them because of where it builds, and the 3-4 hint now points at the right spot.

### 1.8 The Bakery: a flag, no change

The Bakery is in 465 of 18730 three-star wins (2.5%), the Grand Oven in 22 and the Spice Kitchen in 18 (B3 F7). The checks that the brief and RULES 12.6 ask for both pass: the Bakery and both its paths are part of some three-star win. Where it is rare, the maps explain it. Only 4-1 has a real cluster of spots, where a Bakery can reach up to 6 towers. On 4-2, 4-3 and 4-5 it reaches one at most, on 4-6 two, and on 4-4 none, so a fifth attacker is usually the better buy. On 4-1 the third star (at most 6 towers) counts the Bakery as one of the six, yet 58 of its 864 three-star wins have one. Where its job is, it shows: 324 of the 608 three-star wins on 4-6 have a Bakery, and in runs, where every map has a Bakery spot that reaches three others, a Bakery stood at the end of 95% of the runs that reached wave 10 (TUNING_RUNS.md 1.4).

I change no number. A cheaper or stronger Bakery would move every region 4 level and every run without a measured need. If Bart's playtest finds it pointless, the levers are its tier 1 price (130) or its tier 1 boost (+15%), checked first with `stat=` what-ifs on 4-1 and 4-6 and a run pass.

## 2. Changes per owner

### 2.1 Level designer (data/levels/, tests/levels/)

In every file keep the map, name, gates, sockets, towers, starting gold, strengths, highlight cells and Twist. Make only these changes. I applied exactly these edits to a scratch copy of commit 38909ba, and its level tests pass (3.4).

r3_l1.json, star 3:

```json
"star3": {"kind": "tower_ban", "tower": "sling_post"},
```

Before: `"star3": {"kind": "no_lives_lost"},`

r3_l2.json, star 3:

```json
"star3": {"kind": "tier_at_most", "value": 2},
```

Before: `"star3": {"kind": "towers_at_most", "value": 6},`

r3_l3.json, star 3:

```json
"star3": {"kind": "towers_at_most", "value": 5},
```

Before: `"star3": {"kind": "gates_at_most", "value": 2},`

r3_l6.json, star 3:

```json
"star3": {"kind": "tower_ban", "tower": "sling_post"},
```

Before: `"star3": {"kind": "no_lives_lost"},`

r3_l6.json, waves 5 and 9: only the Pip group's count changes. Before and after:

```json
{"strength": 130, "groups": [{"enemy": "puffball", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1400}, {"enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 4000, "every_ms": 350}, {"enemy": "pip", "count": 24, "entrance": 2, "at_ms": 8000, "every_ms": 50}]},
{"strength": 130, "groups": [{"enemy": "puffball", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1400}, {"enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 4000, "every_ms": 350}, {"enemy": "pip", "count": 18, "entrance": 2, "at_ms": 8000, "every_ms": 50}]},
```

```json
{"strength": 145, "groups": [{"enemy": "puffball", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "flitter", "count": 12, "entrance": 1, "at_ms": 3000, "every_ms": 250}, {"enemy": "pip", "count": 30, "entrance": 2, "at_ms": 7000, "every_ms": 50}]},
{"strength": 145, "groups": [{"enemy": "puffball", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "flitter", "count": 12, "entrance": 1, "at_ms": 3000, "every_ms": 250}, {"enemy": "pip", "count": 22, "entrance": 2, "at_ms": 7000, "every_ms": 50}]},
```

Hints (text only, the cells stay):

```json
"hint": {"text": "Longbows ignore armor but can't hit flyers. Keep a Sling Post for the Flitters.", "cell": [3, 6]},
```

in r2_l3.json (before: "Armor blocks small hits. Longbow arrows go straight through.").

```json
"hint": {"text": "Dusk Moths wear armor. Build a Firework on the glow and upgrade it early.", "cell": [3, 8]},
```

in r3_l4.json (before: "Dusk Moths wear armor. Skyrockets punch through it.").

```json
"hint": {"text": "Bakeries speed up nearby towers. Close one side high and the other side low.", "cell": [3, 4]},
```

in r4_l1.json (before: "Bakeries make the towers around them faster.").

tests/levels/test_level_design.gd, four PLAN values:

| Row | star3 now | Before |
|---|---|---|
| `r3_l1` | `["tower_ban", "sling_post"]` | `["no_lives_lost", 0]` |
| `r3_l2` | `["tier_at_most", 2]` | `["towers_at_most", 6]` |
| `r3_l3` | `["towers_at_most", 5]` | `["gates_at_most", 2]` |
| `r3_l6` | `["tower_ban", "sling_post"]` | `["no_lives_lost", 0]` |

The comment above PLAN says 3-2's star 3 is "Have at most 6 towers". It should now point to this file instead, for example: "Region 3's third stars changed on 2026-10-25 (TUNING_CAMPAIGN.md)." Every other test in tests/levels already passes on the new files.

### 2.2 Balance analyst (the next pass)

1. **The tools, for RULES 12.6 as revised.** `mode=need` and `run_pass.sh` still list the Sling Post as needing a lone search on 3-1 and 3-6 (I ran `mode=need` on the new files). Skip the lone search of the tower that a level's star 3 bans. For "All three stars" on a level with a ban (2-5, 3-1, 3-4, 3-6, 4-2), search over the allowed towers, as `run_special.sh` part 3 did. A Twist that a 1500 build search does not win gets two searches of 6000 builds.
2. **What still needs a run.** For 3-1, 3-2 and 3-3, B3's what-if searches played the same level with the same rule, so they stand: no lone Sling Post three-star build in two 6000 build checks for 3-2 and 3-3, and on 3-1 the ban means no lone search is needed. Level 3-6 changed, so it needs the full set on the new file: the plain recipe on Normal and Relaxed, the allowed-tower search, the Twist search, random play, length, and size and speed. My numbers for it are in 3.2 and 3.3.
3. **3-3's new rule.** A 2500 build screen found only 92 three-star builds and a 6000 build search 1429, the first after build 2000 in both (3.3). Use 6000 builds for 3-3's any-tower search. If it ever finds none, tell the DM: the fallback is "No tower above tier 2." (1.1).
4. **Random play** on the four new third stars. My screens are in 3.3.
5. **Not needed:** a new lone search for 3-2 or 3-3, or any check on the hints.

### 2.3 Game designer: RULES.md (done in this step)

12.4: the four third stars, the three hints, 3-4's highlight described as "A spot under both flight lines" (the cell does not move), and a note on region 3 after the table that replaces the sentence on 3-2's six towers. 12.5: one line on region 3 in "Third stars that bite". 12.6: the three sentences of 1.4. The change note at the top of RULES.md.

### 2.4 Everyone else

No change. data/stats/ does not change. The UI builds every third star sentence from the data (contract 2.7), and "Build no Sling Posts." already shows on 3-4. No contract change.

## 3. Evidence

All plays are Normal unless a table says Relaxed. My runs used a clean copy of commit 38909ba (`git archive`), whose campaign plays equal b1137be's (B3 replayed all 48 determinism jobs on c5d36b8 with the same hashes, and no campaign level or stat file changed since). In it, only the files of 2.1 changed, and the project's name, so the copy kept its own user folder.

### 3.1 B3's searches behind each new third star

From B3 F2, "What-if" and "Longer checks". A rule passes when an allowed search finds three-star wins and no lone Sling Post search does.

| Level | Rule | Three-star builds, any allowed tower | Lone Sling Post |
|---|---|---|---|
| 3-1 | Build no Sling Posts. | 2090 and 2145 in two 6000 build searches without the Sling Post (seeds 963102, 963112) | cannot earn it |
| 3-2 | No tower above tier 2. | 873 in 2500 (seed 896200) | none in two 6000 build checks: 2416 and 2091 wins (963201, 963211) |
| 3-3 | Have at most 5 towers. | 92 in 2500 (seed 895300), and 1429 in 6000 (seed 974300, 3.3) | none in two 6000 build checks: 2396 and 2389 wins (963301, 963311) |
| 3-6 | Build no Sling Posts. | 1905 and 2114 in two 6000 build searches (963602, 963612), and 2129 on the new waves (seed 974600, 3.3) | cannot earn it |

The other lone attackers need no search on any of the four (RULES 12.6): flyers cost 108, 46, 77 and 90 lives, and walkers 322, 313, 381 and 307 (3-6 with the new waves; `mode=need` on the new files).

### 3.2 Level 3-6: every variant played

The plain recipe at all 27 gate placements on Normal and on Relaxed (`mode=plain` with `level_file=`). Waves 5 and 9 are the fifth and ninth in the file. Each has one Pip group from entrance B, 0.05 s apart: 24 Pips at strength 130 and 30 at strength 145.

| Variant | Relaxed, no gates | Lives it lost in wave 5, in wave 9 | Relaxed placements won | Normal, best placement | Normal placements won |
|---|---|---|---|---|---|
| As now | lost in wave 9 | 20, 18 | 23 of 27 | won, 14 lives (gates 1,3 and 5,5) | 16 of 27 |
| Waves 5 and 9 at strength 115 | won, 3 lives | 17, 14 | 26 of 27 | won, 14 | 19 of 27 |
| Wave 5 at 115 | lost in wave 9 | 17, 17 | 23 of 27 | won, 14 | 19 of 27 |
| Wave 9 at 115 | won, 4 lives | 20, 14 | 26 of 27 | won, 14 | 16 of 27 |
| Wave 5 at 120, wave 9 at 125 | lost in wave 9 | 19, 15 | 23 of 27 | won, 14 | 19 of 27 |
| Pips 0.1 s apart in both | lost in wave 9 | 21, 17 | 26 of 27 | won, 14 | 15 of 27 |
| Pips from entrance A in both | won, 38 lives | 0, 0 | 27 of 27 | won, 14 | 9 of 27 |
| Wave 5: 18 Pips | won, 4 lives | 14, 20 | 27 of 27 | won, 14 | 18 of 27 |
| Wave 9: 20 Pips | won, 8 lives | 20, 10 | 27 of 27 | won, 14 | 16 of 27 |
| 20 and 24 Pips | won, 8 lives | 16, 14 | 27 of 27 | won, 14 | 16 of 27 |
| 20 and 26 Pips, both at 115 | won, 11 lives | 13, 10 | 26 of 27 | won, 14 | 19 of 27 |
| **18 and 22 Pips (chosen)** | **won, 12 lives** | **14, 12** | **27 of 27** | **won, 14** | **18 of 27** |
| 16 and 20 Pips | won, 16 lives | 12, 10 | 27 of 27 | won, 14 | 18 of 27 |

A loss in wave 9 means the lives left at its start were all lost there. Wave sizes with the chosen counts: 12, 22, 28, 12, 50, 12, 52, 29, 66, 43, 75, 1.

Moving the Pips to entrance A helps Relaxed most, but it cuts Normal's winning placements from 16 to 9: it changes the gate puzzle, so I did not take it. 16 and 20 Pips would give more room, but 18 and 22 already clear the bar with 12 lives and keep more of the crowd.

### 3.3 New searches and random play

| Search | Seed | Builds | Wins | Wins that met star 3 | Three-star builds (first at build) | Of them with 20 lives |
|---|---|---|---|---|---|---|
| 3-3, any tower, Have at most 5 towers | 974300 | 6000 | 2380 | 1961 | 1429 (2140) | 915 |
| 3-6 with the new waves, every tower but the Sling Post, Build no Sling Posts | 974600 | 6000 | 2740 | 2740 | 2129 (2057) | 1499 |

The 3-3 three-star builds: a Sling Post, a Catapult and a Firework in all 1429, a Longbow in 305, a Bell in 52. 1204 of them use 5 towers, 223 use 4 and 2 use 3. Paths: Quickshot 1009, Star Bloom 1010, Jam Pot 910, Stone Sling 642, Prize Pumpkin 514, Skyrocket 435, Triple Bow 182, Giant Bow 63, Hush Bell and Night Bell 18 each.

The 3-6 three-star builds: a Firework, a Catapult and a Longbow in all 2129, a Bell in 745. Paths: Star Bloom 1613, Skyrocket 1243, Prize Pumpkin 988, Triple Bow 811, Hush Bell 414, Jam Pot 366, Giant Bow 319, Night Bell 74. B3's two searches on the old waves found 1905 and 2114, with 1207 and 1386 at 20 lives.

Random play, 250 strategies per style on Normal and on Relaxed, with B3's seeds (813100, 813200, 813300, 813600). The strategies are the same as B3's, so only the third star differs, and on 3-6 the waves. RULES 12.6 asks for three stars in under 10% of plays.

| Level | Normal wins | Three stars, new rule | Three stars, B3 | Relaxed wins, new (B3) |
|---|---|---|---|---|
| 3-1 | 3 of 750 | 0 | 0 | 60 of 750 (60) |
| 3-2 | 24 of 750 | 0 | 2 (0.3%) | 91 of 750 (91) |
| 3-3 | 0 of 750 | 0 | 0 | 18 of 750 (18) |
| 3-6 | 3 of 750 | 0 | 0 | 35 of 750 (33) |

The 3-6 Twist (Double Trouble) with the new waves, plain recipe: Normal wins on 18 of 27 placements (B3: 16), the best with 14 lives (B3: 14). Relaxed with no gates wins with 12 lives (B3: lost in wave 9).

### 3.4 Tests

The edits of 2.1, applied to the scratch copy: `godot --headless --path . --script res://tests/run_tests.gd -- --only=levels`, "Ran 60 tests in 5 files: 60 passed, 0 failed.", exit code 0. That includes the PLAN rows, the rule that every third star leaves two attacking towers usable, the highlight checks (each highlighted spot sees the open route, in rows 0 to 8), the free hint row on tall maps, the spawn bound with each Twist, and the smoke play of every level (3-6 won with 14 lives in 8.6 minutes at 1x).

The real tree layout checks on the same copy: `godot --headless --path . --script res://tests/ui/real_tree_checks.gd`, "25275 checks, 0 failed", exit code 0. They show every level's real hint, and every Twist's, on the Fold5 cover layout, and check that it covers no spot, socket, entrance, base or highlighted cell, stays inside the safe area and is a 48 dp target. So the longer hints fit.

The repo itself is untouched outside docs/design/.

### 3.5 How to repeat

From the root of a clean copy (`git archive HEAD`, then `godot --headless --path . --import`), with the level files of 2.1 saved anywhere:

```
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r3_l6 level_file=PATH/r3_l6.json out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r3_l3 seed=974300 evals=6000 only=any "tweak=star3:towers_at_most;5" out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=search level=r3_l6 level_file=PATH/r3_l6.json seed=974600 evals=6000 only=lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=need level=r3_l6 level_file=PATH/r3_l6.json out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=plain level=r3_l6 level_file=PATH/r3_l6.json twist=1 out=OUT.json
godot --headless --path . --script res://tools/balance/run.gd -- mode=spread level=r3_l2 "tweak=star3:tier_at_most;2" seed=813200 n=250 out=OUT.json
godot --headless --path . --script res://tests/ui/real_tree_checks.gd
```

The balance jobs work before the level designer's change: `level_file=` plays the new 3-6 file, and `tweak=` sets a new third star in memory. The random play jobs use the seeds of 3.3 with each level's new rule. Once the files of 2.1 are in data/levels/, drop both. The real tree checks and the level tests read data/levels/ and tests/levels/, so they need the files of 2.1 in place. My own runs differ only in form: the 3-6 search used a file with only the wave change plus `"tweak=star3:tower_ban;sling_post"`, which plays the same, and the random play and the tests ran on a copy whose data/levels already held the files of 2.1. The variants of 3.2 are the same plain command with the wave edits named in each row. The scratch copy, the variant files and every result file are in the session scratch folder under `g4/`. They are not needed to build anything: 2.1 has every change.

## 4. For Bart

These change what Bart approved, so they are for the DM to tell him:

1. **Four third stars in region 3.** With the old rules, Sling Posts alone could earn all three stars on these levels.
   - 3-1, from "Lose no lives." to "Build no Sling Posts."
   - 3-2, from "Have at most 6 towers." to "No tower above tier 2." The 6 came through TUNING_R2.md.
   - 3-3, from "Use at most 2 gates." to "Have at most 5 towers."
   - 3-6, from "Lose no lives." to "Build no Sling Posts."
2. **Level 3-6's waves 5 and 9 bring fewer Pips** (24 to 18 and 30 to 22), so a stuck player can win on Relaxed without placing a gate.
3. **Three hints change:** 2-3 "Longbows ignore armor but can't hit flyers. Keep a Sling Post for the Flitters.", 3-4 "Dusk Moths wear armor. Build a Firework on the glow and upgrade it early.", 4-1 "Bakeries speed up nearby towers. Close one side high and the other side low." No glowing spot moves.
4. **For the record, not for a decision:** RULES 12.6's checks for the bots now search the allowed towers on a level that bans one, skip the lone search of a banned tower, and give a Twist two long searches when a short one finds no win.

No Twist and no number changes.

## 5. Open questions

1. **For the DM:** the hint changes alter approved player text. I treat them like G2's third star changes (apply now, tell Bart). If the DM wants Bart to see the three lines first, the level designer can apply the rest without them.
2. **For the next pass:** the any-tower search finds 3-3's "Have at most 5 towers" builds only after about 2000 builds (1.1). If a pass ever finds none, switch to "No tower above tier 2." and tell Bart.

## 6. Suggestions beyond the task

1. **3-5's Twist repeats its third star.** The third star is "No tower above tier 2." and the Twist is Tier 2 Cap ("No tower can go above tier 2."). A player who has three stars there has already won under the Twist's rule. Both were approved at hard stop A, so this is for Bart. A Twist that fits "split the defense between two entrances" would be No Longbows, because a Longbow in the middle column covers both shores. It would need a bot check first.
2. **The analyst's tools.** `mode=need` could also print the skip for a banned tower, so each report shows why that search is missing.
