# Region 1 tuning plan

Owner: game designer. 2026-10-24. Answers the balance report docs/balance/region1-2026-10-23.md (commit a240283). RULES.md holds the rules and numbers; this file says what changed in region 1, why, and exactly what the level designer types in. Section 9 records the independent rerun, docs/balance/region1-2026-10-24.md, which confirms this plan.

## 1. Decision on S2: option (b)

The check "no single tower type earns three stars alone" now passes on all six region 1 levels, at the analyst's full search sizes and on a second seed (section 6). There is no contract change. Not option (c): it changes the brief, and it is not needed. Not option (a): not needed either, and it would make the third star a box to tick instead of a puzzle.

Why the first report found no window, and what fixes each cause:

| Cause | Fix |
|---|---|
| A Pip had 12 health: two Quickshot pebbles or one stone. Sling Posts cleared crowds as well as Catapults did. | Pip health 21. Now four tier 1 pebbles, three Quickshot pebbles or two stones, but one tier 2 pumpkin. |
| A tier 1 Catapult reached 3.0 tiles, a tier 1 Sling Post 2.5. On 1-1 the Catapult's spots saw 46% more road (38 cells against 26), so it beat the Sling Post even against single walkers. | Tier 1 Catapult range 2.5. Tier 2 brings 3.0 back with a much wider splash. |
| The star 3 rules (lose no lives, use no gates, call 4 waves early, at most 3 or 4 towers) left room for one tower type to buy its way through. Bigger waves only made it buy more. | Star 3 rules that limit spending, and waves that always hold both jobs (section 3). |

The result: Sling Posts alone can still win every region 1 level. They often keep two stars on 1-1, 1-2, 1-4 and 1-6, but rarely on 1-3 and 1-5: 9 to 15 and about 100 two-star wins in 2500 to 3000 searched builds. Catapults alone can win 1-1 to 1-4 (on Normal, Flitters stop them from 1-5 on, as before). They keep two stars on 1-2 and 1-4 only, and win 1-1 and 1-3 with one star. The third star needs both towers. These sentences were corrected on 2026-10-24 from the rerun (section 9).

## 2. Number changes in data/stats/ (done)

| What | Before | After | Why |
|---|---|---|---|
| Pumpkin Catapult, tier 1 range | 3.0 | 2.5 | Same reach as a tier 1 Sling Post, so the Sling Post is the better buy against single walkers. |
| Pumpkin Catapult, tier 2 splash | 0.75 | 1.25 | From tier 2, crowds are clearly the Catapult's job. |
| Prize Pumpkin splash | 1.25 | 1.5 | Stays the widest splash. It was in only 3 to 13% of three-star builds. |
| Jam Pot splash | 1.0 | 1.25 | Not narrower than tier 2. |
| Pip health | 12 | 21 | As above. |
| Pip bounty | 2 | 3 | Gold per point of health stays close to before. |

One text change goes with the Pip (DM decision, 2026-10-24): its card line in enemies.json and RULES 6.6 now reads "Small, but comes in big crowds. Splash clears them.", because at 21 health pebbles no longer pop it easily.

Nothing else changes: every Sling Post number, the other towers and creatures, and rules.json. Grumblesack keeps its numbers; level 1-6 sets the boss wave's strength instead (S3).

Tried and dropped (section 6.3): tier 1 Catapult splash 1.0, Jam Pot damage 16 or 20, Pip health 18, Grumblesack dropping Pips, tower caps on 1-6, and "Lose no lives" on 1-5.

## 3. Instructions for the level designer

For every region 1 level keep the map, name, gates, sockets, towers, starting gold and hint. Replace `star3` and `waves` with the ones below. Level 1-6 also changes `strength` from 110 to 100. Wave counts stay 8, 8, 9, 9, 10, 10. The largest wave holds 74 creatures, every time is a multiple of 50 ms, and each new creature still comes alone first. The six finished files, r1_l1.json to r1_l6.json, sit in docs/balance/raw/2026-10-23-design/final/ (git ignored) for copying; the other files there are tested variants.

tests/levels/test_level_design.gd needs new PLAN values: star 3 as below, and `r1_l6` strength 100.

### 1-1 First Lanterns

Star 3: No tower above tier 1. Before: Lose no lives. Data: `"star3": {"kind": "tier_at_most", "value": 1}`.

Waves 2 and 3 are spread-out Scamps: an all-Catapult start leaks there. From wave 4 come packs 0.2 to 0.25 s apart: five tier 1 Sling Posts leak there. The third star asks for the right mix of tier 1 towers.

```json
"waves": [
  {"groups": [{"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 0, "every_ms": 1500}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1200}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 1200}]},
  {"groups": [{"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1300}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 10000, "every_ms": 250}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 12000, "every_ms": 250}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 250}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 6000, "every_ms": 1300}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 18000, "every_ms": 250}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "scamp", "count": 12, "entrance": 1, "at_ms": 14000, "every_ms": 250}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 20000, "every_ms": 1300}]},
  {"groups": [{"enemy": "scamp", "count": 14, "entrance": 1, "at_ms": 0, "every_ms": 200}, {"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 6000, "every_ms": 1200}, {"enemy": "scamp", "count": 12, "entrance": 1, "at_ms": 20000, "every_ms": 200}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 28000, "every_ms": 1200}]}
]
```

### 1-2 The Fork

Star 3: No tower above tier 1. Before: Have at most 4 towers. Data: `"star3": {"kind": "tier_at_most", "value": 1}`.

The 1-1 pattern at about the same size. With no tier 2, a build also needs the gate's long road.

```json
"waves": [
  {"groups": [{"enemy": "scamp", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 1500}]},
  {"groups": [{"enemy": "scamp", "count": 7, "entrance": 1, "at_ms": 0, "every_ms": 1300}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1200}]},
  {"groups": [{"enemy": "scamp", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 1300}, {"enemy": "scamp", "count": 7, "entrance": 1, "at_ms": 10000, "every_ms": 250}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 14000, "every_ms": 250}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 250}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 6000, "every_ms": 1300}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 20000, "every_ms": 250}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "scamp", "count": 12, "entrance": 1, "at_ms": 16000, "every_ms": 200}, {"enemy": "scamp", "count": 5, "entrance": 1, "at_ms": 22000, "every_ms": 1300}]},
  {"groups": [{"enemy": "scamp", "count": 13, "entrance": 1, "at_ms": 0, "every_ms": 200}, {"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 6000, "every_ms": 1200}, {"enemy": "scamp", "count": 12, "entrance": 1, "at_ms": 22000, "every_ms": 200}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 30000, "every_ms": 1200}]}
]
```

### 1-3 Tall Posts

Star 3: Have at most 2 towers. Before: Have at most 3 towers. Data: `"star3": {"kind": "towers_at_most", "value": 2}`.

Tough spread-out Scamps (waves at strength 160 and 180, 1.6 to 2.0 s apart) are Sling Post work. Scamp packs, ending with 24 at strength 140, are Catapult work. Two towers earn the third star only as one of each, upgraded.

```json
"waves": [
  {"groups": [{"enemy": "scamp", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 1500}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1400}]},
  {"groups": [{"enemy": "scamp", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 1500}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 9000, "every_ms": 300}]},
  {"strength": 160, "groups": [{"enemy": "scamp", "count": 7, "entrance": 1, "at_ms": 0, "every_ms": 2000}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 250}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 6000, "every_ms": 1500}]},
  {"strength": 180, "groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 2000}]},
  {"groups": [{"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1500}, {"enemy": "scamp", "count": 14, "entrance": 1, "at_ms": 10000, "every_ms": 200}]},
  {"strength": 180, "groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 1800}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 20000, "every_ms": 250}]},
  {"strength": 140, "groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 1600}, {"enemy": "scamp", "count": 24, "entrance": 1, "at_ms": 18000, "every_ms": 200}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 26000, "every_ms": 1600}]}
]
```

### 1-4 Pumpkin Patch

Star 3: No tower above tier 1. Before: Use no gates. Data: `"star3": {"kind": "tier_at_most", "value": 1}`.

Pip crowds 0.1 to 0.2 s apart are Catapult work. Tough spread-out Scamps at strength 160 in waves 5 and 7 are Sling Post work.

```json
"waves": [
  {"groups": [{"enemy": "scamp", "count": 3, "entrance": 1, "at_ms": 0, "every_ms": 1500}, {"enemy": "scamp", "count": 3, "entrance": 1, "at_ms": 9000, "every_ms": 1500}]},
  {"groups": [{"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 9000, "every_ms": 400}]},
  {"groups": [{"enemy": "pip", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 400}]},
  {"groups": [{"enemy": "pip", "count": 20, "entrance": 1, "at_ms": 0, "every_ms": 200}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 6000, "every_ms": 1300}]},
  {"strength": 160, "groups": [{"enemy": "scamp", "count": 14, "entrance": 1, "at_ms": 0, "every_ms": 1600}]},
  {"groups": [{"enemy": "pip", "count": 30, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 6000, "every_ms": 1300}, {"enemy": "pip", "count": 20, "entrance": 1, "at_ms": 14000, "every_ms": 150}]},
  {"strength": 160, "groups": [{"enemy": "scamp", "count": 17, "entrance": 1, "at_ms": 0, "every_ms": 1600}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 24000, "every_ms": 400}]},
  {"groups": [{"enemy": "pip", "count": 36, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 6000, "every_ms": 1200}, {"enemy": "pip", "count": 24, "entrance": 1, "at_ms": 16000, "every_ms": 150}]},
  {"groups": [{"enemy": "scamp", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "pip", "count": 36, "entrance": 1, "at_ms": 6000, "every_ms": 100}, {"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 14000, "every_ms": 1200}, {"enemy": "pip", "count": 20, "entrance": 1, "at_ms": 20000, "every_ms": 100}]}
]
```

### 1-5 Night Wings

Star 3: No tower above tier 2. Before: Lose no lives. Data: `"star3": {"kind": "tier_at_most", "value": 2}`.

Pip crowds and Flitter flocks arrive together in waves 7, 9 and 10. A tier 2 Sling Post needs three pebbles per Pip, so a Sling Post only build leaks too many. Catapults cannot touch the Flitters.

```json
"waves": [
  {"groups": [{"enemy": "scamp", "count": 3, "entrance": 1, "at_ms": 0, "every_ms": 1500}, {"enemy": "scamp", "count": 3, "entrance": 1, "at_ms": 9000, "every_ms": 1500}]},
  {"groups": [{"enemy": "pip", "count": 10, "entrance": 1, "at_ms": 0, "every_ms": 300}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 8000, "every_ms": 1200}]},
  {"groups": [{"enemy": "flitter", "count": 4, "entrance": 1, "at_ms": 0, "every_ms": 500}]},
  {"groups": [{"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1200}, {"enemy": "flitter", "count": 4, "entrance": 1, "at_ms": 8000, "every_ms": 500}]},
  {"groups": [{"enemy": "pip", "count": 18, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 8000, "every_ms": 1200}]},
  {"groups": [{"enemy": "flitter", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 500}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 6000, "every_ms": 1200}]},
  {"groups": [{"enemy": "pip", "count": 20, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "flitter", "count": 4, "entrance": 1, "at_ms": 3000, "every_ms": 500}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 12000, "every_ms": 1200}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "flitter", "count": 6, "entrance": 1, "at_ms": 8000, "every_ms": 400}]},
  {"groups": [{"enemy": "pip", "count": 24, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "flitter", "count": 6, "entrance": 1, "at_ms": 3000, "every_ms": 400}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 12000, "every_ms": 1000}]},
  {"groups": [{"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "pip", "count": 26, "entrance": 1, "at_ms": 6000, "every_ms": 150}, {"enemy": "flitter", "count": 6, "entrance": 1, "at_ms": 9000, "every_ms": 400}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 18000, "every_ms": 1000}]}
]
```

### 1-6 Grumblesack

Star 3: Use no gates. Before: Call 4 waves early. Data: `"star3": {"kind": "gates_at_most", "value": 0}`. Level strength: `"strength": 100`, before 110.

Waves 6 to 9 bring dense Pip crowds (0.1 s apart) together with a Flitter flock, so a Catapult-heavy build still needs Sling Posts and a Sling-heavy build needs Catapults (S4). The boss wave sets strength 50, so Grumblesack has 1000 health. That is below S3's 70 to 90: at 70 no build at all earned three stars without the gate (0 of 800), and the first report found that at 50 about half the random plays that reach the boss beat it. Without the gate the road is 13 steps, not 17.

```json
"waves": [
  {"groups": [{"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 0, "every_ms": 1300}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 8000, "every_ms": 1300}]},
  {"groups": [{"enemy": "pip", "count": 14, "entrance": 1, "at_ms": 0, "every_ms": 200}, {"enemy": "scamp", "count": 3, "entrance": 1, "at_ms": 6000, "every_ms": 1500}]},
  {"groups": [{"enemy": "flitter", "count": 5, "entrance": 1, "at_ms": 0, "every_ms": 500}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 5000, "every_ms": 1300}]},
  {"groups": [{"enemy": "pip", "count": 20, "entrance": 1, "at_ms": 0, "every_ms": 150}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 5000, "every_ms": 1400}]},
  {"strength": 140, "groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1600}, {"enemy": "flitter", "count": 4, "entrance": 1, "at_ms": 8000, "every_ms": 500}]},
  {"groups": [{"enemy": "pip", "count": 24, "entrance": 1, "at_ms": 0, "every_ms": 100}, {"enemy": "flitter", "count": 6, "entrance": 1, "at_ms": 2000, "every_ms": 400}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 10000, "every_ms": 1400}]},
  {"groups": [{"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 0, "every_ms": 1300}, {"enemy": "pip", "count": 28, "entrance": 1, "at_ms": 6000, "every_ms": 100}, {"enemy": "flitter", "count": 5, "entrance": 1, "at_ms": 8000, "every_ms": 400}]},
  {"groups": [{"enemy": "pip", "count": 30, "entrance": 1, "at_ms": 0, "every_ms": 100}, {"enemy": "flitter", "count": 7, "entrance": 1, "at_ms": 2000, "every_ms": 400}, {"enemy": "scamp", "count": 6, "entrance": 1, "at_ms": 12000, "every_ms": 1200}]},
  {"groups": [{"enemy": "scamp", "count": 8, "entrance": 1, "at_ms": 0, "every_ms": 1000}, {"enemy": "pip", "count": 34, "entrance": 1, "at_ms": 8000, "every_ms": 100}, {"enemy": "flitter", "count": 7, "entrance": 1, "at_ms": 10000, "every_ms": 400}, {"enemy": "scamp", "count": 4, "entrance": 1, "at_ms": 16000, "every_ms": 1000}]},
  {"strength": 50, "groups": [{"enemy": "grumblesack", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}]}
]
```

## 4. Difficulty targets (RULES 12.5)

The old guide (wave health about 0.8 times the gold on hand) is gone. It did not measure difficulty: towers keep firing every wave. The target is a first-try win rate for a thoughtful player, checked by Bart's playtest at hard stop B. The bots check what they can: the plain mixed recipe must win, and random play must rarely earn three stars.

| Level | Thoughtful first try, Normal (target) | Plain mixed recipe, Normal: best gate / worst gate | Plain mixed recipe, Relaxed | Random typical style, Normal | Random, all styles, Relaxed | Random plays with three stars |
|---|---|---|---|---|---|---|
| 1-1 | 95% | won, 16 lives / won, 16 lives | won, 40 lives | 73% | 92% | 5% |
| 1-2 | 90% | won, 19 lives / won, 10 lives | won, 40 lives | 58% | 89% | 2% |
| 1-3 | 85% | won, 17 lives / won, 9 lives | won, 40 lives | 47% | 85% | 0% |
| 1-4 | 85% | won, 20 lives / won, 20 lives | won, 40 lives | 73% | 72% | 2% |
| 1-5 | 75% | won, 19 lives / won, 16 lives | won, 39 lives | 21% | 66% | 1% |
| 1-6 | 70% | won, 15 lives / lost in wave 10 | won, 40 lives | 13% | 25% | 0% |

Random strategies pick their tower mix by chance and only buy their fixed list, so they never spend Relaxed's extra gold. Their rates are a floor for comparing levels. On 1-5 and 1-6, which need both towers, a random mix fails often by design: Catapult-heavy mixes cannot hit Flitters, and Sling-heavy mixes leak Pip crowds.

## 5. Relaxed and Grumblesack

A Relaxed player who lets Grumblesack through on 1-6 and still has lives left wins with one star. That is fine, and RULES 6.3 now says so:

- Relaxed exists so a stuck player can move on (brief 3.9a). Forty lives is exactly what lets one boss through.
- The player still has to hold waves 1 to 9 with more than 20 lives to spare, so it is not a free pass.
- The win earns star 1 only. Stars 2 and 3 still need Normal, where the boss must fall.
- With the boss wave at strength 50 (1000 health), most players who reach it will pop it anyway.

## 6. Evidence

All runs use the analyst's bots (tools/balance/bot.gd) and seeds (README: 2000 + 100n for the any-tower search, 3000 + 100n Sling Post only, 4000 + 100n Catapult only, 1000 + 100n spread), with data/stats/ as now changed and the level files in section 3.

### 6.1 The check, at full size

| Level | Star 3 | Any tower: three-star builds | Sling Post only | Pumpkin Catapult only | Sling Post only: wins, of them two stars | Catapult only: wins |
|---|---|---|---|---|---|---|
| 1-1 | No tower above tier 1. | 830 of 3000 | 0 of 2500 | 0 of 2500 | 2047, 1669 | 1366 |
| 1-2 | No tower above tier 1. | 751 of 3000 | 0 of 2500 | 0 of 2500 | 1699, 1143 | 1722 |
| 1-3 | Have at most 2 towers. | 774 of 3000 | 0 of 2500 | 0 of 2500 | 1188, 15 | 1038 |
| 1-4 | No tower above tier 1. | 1010 of 3000 | 0 of 2500 | 0 of 2500 | 1538, 1124 | 1801 |
| 1-5 | No tower above tier 2. | 1068 of 3000 | 0 of 2500 | 0 of 800 | 966, 89 | 0 |
| 1-6 | Use no gates. | 1027 of 3000 | 0 of 2500 | 0 of 800 | 1190, 781 | 0 |

Second seed (3001 + 100n and 4001 + 100n, 2500 builds each): 1-1 Sling Post only 0 of 2500, Catapult only 0 of 2500; 1-2 Sling Post only 0 of 2500, Catapult only 0 of 2500; 1-3 Sling Post only 0 of 2500, Catapult only 0 of 2500; 1-4 Sling Post only 0 of 2500, Catapult only 0 of 2500; 1-5 Sling Post only 0 of 2500; 1-6 Sling Post only 0 of 2500. Catapult only cannot win 1-5 or 1-6 on Normal (it cannot hit Flitters).

### 6.2 Win rates, recipes, paths and length

| Level | Random typical style, Normal | Random, all styles, Normal | Random, all styles, Relaxed | Random mixes of 25 to 74% Sling Posts, Normal / Relaxed | Typical win at 1x |
|---|---|---|---|---|---|
| 1-1 | 73% | 61% | 92% | 67% / 97% | 5.5 min (211 s of waves, plus 15 s a build phase) |
| 1-2 | 58% | 49% | 89% | 71% / 94% | 5.3 min (197 s of waves, plus 15 s a build phase) |
| 1-3 | 47% | 23% | 85% | 37% / 93% | 6.0 min (222 s of waves, plus 15 s a build phase) |
| 1-4 | 73% | 55% | 72% | 88% / 96% | 5.8 min (213 s of waves, plus 15 s a build phase) |
| 1-5 | 21% | 11% | 66% | 21% / 80% | 5.6 min (187 s of waves, plus 15 s a build phase) |
| 1-6 | 13% | 7% | 25% | 11% / 33% | 6.1 min (217 s of waves, plus 15 s a build phase) |

Spread: 1-1 250, 1-2 250, 1-3 250, 1-4 250, 1-5 250, 1-6 250 plays per style on Normal and on Relaxed.

One-tower recipes on Relaxed, the no grind wall check (the plain mixed recipe is in section 4):

| Level | Sling Posts only, tier 2, Relaxed: best gate / worst gate | Quickshots, Relaxed | Catapults only, tier 2, Relaxed |
|---|---|---|---|
| 1-1 | won, 40 lives / won, 40 lives | won, 40 lives / won, 40 lives | won, 30 lives / won, 30 lives |
| 1-2 | won, 36 lives / won, 36 lives | won, 36 lives / won, 36 lives | won, 31 lives / won, 30 lives |
| 1-3 | won, 30 lives / won, 23 lives | won, 34 lives / won, 26 lives | won, 37 lives / won, 27 lives |
| 1-4 | won, 40 lives / won, 33 lives | won, 40 lives / won, 39 lives | won, 40 lives / won, 40 lives |
| 1-5 | won, 31 lives / won, 18 lives | won, 38 lives / won, 19 lives | won, 5 lives / won, 3 lives |
| 1-6 | won, 38 lives / lost in wave 7 | won, 40 lives / lost in wave 7 | won, 6 lives / lost in wave 10 |

Tier 3 paths in three-star builds (a build counts once per path it plans):

| Level | Three-star builds (any tower) | Quickshot | Stone Sling | Prize Pumpkin | Jam Pot |
|---|---|---|---|---|---|
| 1-3 | 774 | 346 | 189 | 299 | 315 |
| 1-6 | 1027 | 949 | 336 | 145 | 311 |

Every tier 3 path is part of some three-star win. Only 1-3 and 1-6 allow tier 3 for the third star; the other levels cap the tier by rule.

### 6.3 What-ifs that chose the numbers

Screens used 400 to 1200 builds per search; only full-size runs count as proof (single-tower wins first appeared after 1029 to 2157 builds on some levels).

Three-star builds found (tries per search in the count):

| What-if | Level | Sling Post only | Catapult only | Any tower | Raw files in out/ |
|---|---|---|---|---|---|
| Wider Catapult splash on every tier, denser Pip crowds, old star 3 | 1-4 | 230 of 500 | 294 of 500 | 264 of 500 | x1t1A |
| Spread and packs, star 3 Lose no lives | 1-1 | 244 of 500 | 0 of 500 | 220 of 500 | x1t1A |
| Same waves, star 3 No tower above tier 1 | 1-1 | 0 of 500 | 149 of 500 | 173 of 500 | x1t1At1 |
| Final 1-1 waves, tier 1 Catapult splash 1.0 | 1-1 | 0 of 1200 | 120 of 1200 | 427 of 1200 | xBt9 |
| Final 1-1 waves, final numbers (splash 0.75) | 1-1 | 0 of 1200 | 0 of 1200 | 360 of 1200 | xBt14 |
| Tough 1-2 waves, No tower above tier 2 | 1-2 | 119 of 1200 | 255 of 1200 | 395 of 1200 | xBt14 |
| Tough 1-2 waves, Have at most 2 towers | 1-2 | 152 of 1200 | 106 of 1200 | 320 of 1200 | xCG1c2 |
| Pip health 18 (a stone pops it), 1-6 crowds | 1-6 | 47 of 400 | - | 0 of 400 | x5pip |
| Pip health 21, 1-4 waves, Use no gates | 1-4 | 12 of 400 | 135 of 400 | 184 of 400 | x7E14 |
| Same, Jam Pot damage 16 | 1-4 | 12 of 400 | 133 of 400 | 171 of 400 | x9j16 |
| Same waves, No tower above tier 2 | 1-4 | 98 of 400 | 192 of 400 | 200 of 400 | x8E14t2 |
| Same waves, Have at most 3 towers | 1-4 | 66 of 400 | 177 of 400 | 173 of 400 | x8E14c3 |
| Same waves, No tower above tier 1, at full size (the final adds 3 tough Scamps) | 1-4 | - | 61 of 2500 | - | zF |
| Softer 1-6 waves, Call 4 waves early | 1-6 | 102 of 600 | - | 190 of 600 | x7H60 |
| Softer 1-6 waves, Have at most 4 towers | 1-6 | 162 of 600 | - | 145 of 600 | x8H60c4 |
| Softer 1-6 waves, Grumblesack drops 5 Pips every 5 s | 1-6 | 81 of 600 | - | 41 of 600 | x9e4 |
| 1-6 crowds with flocks, Use no gates, boss at 70 | 1-6 | 0 of 800 | - | 0 of 800 | xBI70100 |
| Same at boss 50, before the denser last waves | 1-6 | 83 of 1200 | - | 373 of 1200 | xDI |
| Harder 1-5 waves, Lose no lives, full size | 1-5 | 291 of 2500 | - | 921 of 3000 | zF |
| Same with 0.1 s crowds, Lose no lives | 1-5 | 297 of 2500 | - | 366 of 1500 | zGE4a |
| Final 1-5 waves, Lose no lives | 1-5 | 176 of 1200 | - | 289 of 1200 | xCF |

### 6.4 How to repeat

Once the levels are in data/levels/, the analyst's own job list repeats section 6.1 exactly: `bash tools/balance/run_region1.sh <date> <jobs>`. The what-ifs ran through a small harness that extends tools/balance/run.gd and only swaps in a level file and stat files. It, the job lists and every raw result are in docs/balance/raw/2026-10-23-design/ (git ignored). One job, for example:

```
godot --headless --path . --script docs/balance/raw/2026-10-23-design/tools/tune.gd -- mode=search level=r1_l5 level_file=docs/balance/raw/2026-10-23-design/final/r1_l5.json seed=3500 evals=2500 only=sling_post out=OUT.json
```

## 7. Tests that need new numbers

With the new data/stats/ alone: 461 tests, 456 pass and 5 fail, all in tests/sim/, all pinning old numbers. With the new levels as well (run on a scratch copy of the project, with the five fixes below and the PLAN change applied): 460 pass and 1 fails, in tests/render/. So the level change and these test fixes should land in one integration step.

| Test | Owner | Change |
|---|---|---|
| tests/sim/test_catalog.gd `test_every_tower_field_of_2_6_is_read` | sim engineer | Prize Pumpkin splash 150, Jam Pot splash 125 (lines 72 and 74). |
| tests/sim/test_battle_combat.gd `test_prize_pumpkin_rules_5_4` | sim engineer | The third Scamp is now inside the 1.5 splash. Start the second and third Scamps at 1500 and 1550 ms (30000 and 31000 behind) and update the comment. |
| tests/sim/test_battle_combat.gd `test_a_defeated_creature_is_not_targeted_again_rules_8_1` | sim engineer | A stone (20) no longer pops a 21 health Pip. Use a Puff (12 health, speed 1.3, bounty 2): expected position + (0, 1300), gold 2. |
| tests/sim/test_battle_flow.gd `test_bounties_are_paid_on_defeat_rules_4_5` | sim engineer | Bounty 3 x 1.5 = 4.5, rounded half up: 5. Gold after the wave 5 + 38 = 43. |
| tests/sim/test_battle_flow.gd `test_early_bonus_counts_only_the_newest_wave_rules_4_9` | sim engineer | Three Pips of bounty 3: half of 9 rounded up is 5. |
| tests/render/test_map_view.gd `test_nodes_follow_creatures_and_nothing_leaks` | render engineer | It plays the real 1-5 and assumes wave 5 never has more than 6 creatures more on screen than wave 4. The new wave 5 is a denser Pip crowd. Compare with the second wave's own peak instead, for example `v.sprite_count() <= v.tower_count() + maxi(peak, peak2) + 4`. |
| tests/levels/test_level_design.gd PLAN | level designer | The star 3 rows and `r1_l6` strength 100 (section 3). |

All of it was proven on a scratch copy of the project with the new stats, the new levels and these seven changes: 461 tests, 461 pass, exit code 0. The exact diffs are in docs/balance/raw/2026-10-23-design/: sim_test_changes.diff, render_test_change.diff and level_test_plan.diff (git ignored).

## 8. Open points

- For Bart: five third stars changed, and region 1 now uses "No tower above tier 1" three times (1-1, 1-2, 1-4). On those levels it was the only rule tried that stopped both towers alone (section 6.3). Tier 3 arrives with 1-6, so the early third stars never need it.
- For Bart and phase 7: 1-3's Twist "No Upgrades" is probably not winnable with the new 1-3 waves. No tier 1 only win turned up in 1200 builds. A Twist must be winnable on Normal (RULES 13). Suggestion: make it "Tier 2 Cap" (the plain mixed tier 2 recipe wins 1-3 with 9 to 17 lives), or settle it in the phase 7 Twist pass. Settled 2026-10-24: the DM chose Tier 2 Cap (RULES 13).
- For Bart: random bots win 1-5 and 1-6 on Normal rarely, because those levels need both towers. The plain mixed recipe wins both. If the playtest finds them too hard, the first lever is fewer Pips in their late crowds. On 1-5 the tier 2 rule keeps the check; on 1-6 "Use no gates" needs the hard late waves.
- For phase 7: at region 2 strengths (130 to 160) a Pip has 27 to 34 health, more than a tier 2 pumpkin's 24. Region 2 Pip waves should set a lower strength of their own.
- For the balance analyst: run single-tower searches at 2500 builds or more. On some versions the first single-tower three-star win appeared only after 1029 to 2157 builds. Optional: `level_file=`, `towers=` and `enemies=` options in tools/balance/run.gd would let wave what-ifs run on your own tool.

## 9. The independent rerun, 2026-10-24

The balance analyst reran region 1 on these levels at commit 473d768, with new seeds, longer searches and checks this plan did not run: about 520,000 plays (docs/balance/region1-2026-10-24.md). It confirms the plan.

- No single tower type earns three stars on any level: 0 in all 24 one-tower searches (3000 builds each, two new seeds per tower and level), 0 in 8 longer searches of 8000 builds, and 0 in an exhaustive check of 1-3 (162,720 builds per tower).
- The plain mixed recipe keeps exactly the lives in section 4, and the random rates reproduce within their error.
- Every tower and all four tier 3 paths are part of some three-star win.
- Levels take 5.2 to 6.6 minutes at 1x, the largest wave holds 74 creatures, and the same inputs always give the same result.

What it adds, and my answers:

- S1. The thinnest margin is 1-3, Catapult only, under "Have at most 2 towers": best 14 lives, one under star 2. Any change that makes the Catapult stronger, 1-3's Scamps weaker or star 2 lower must rerun `bash tools/balance/run_exhaust.sh <date> <jobs>` before it lands.
- S2. Answered in docs/design/FUN_REVIEW_R1.md: yes, with the star lines in the Pause menu.
- S3. 1-5's third star does not bite: 82% of wins meet it. Kept for now. 1-5's job is the flyer lesson, star 2 does the work there, and tier 3 is taught on 1-6. Revisit after the playtest.
- S4. The 1-3 Twist "No Upgrades" cannot be won on Normal: 0 wins in 29,880 tier 1 builds of up to 4 towers, and 0 of 250 casual plays (a tower on every spot, never upgraded). RULES 13 stays as it is until the phase 7 Twist pass, because the playtest may change 1-3's waves and the replacement is Bart's call. My lean: Tier 2 Cap, which the plain mixed recipe wins with 9 to 17 lives. Settled 2026-10-24: the DM chose Tier 2 Cap, and RULES 13 now has it.
- S5. Section 1 is corrected.
- S6, S7 and the RULES 12.5 targets: no change before Bart's playtest. FUN_REVIEW_R1.md gives the reasons and the levers.
