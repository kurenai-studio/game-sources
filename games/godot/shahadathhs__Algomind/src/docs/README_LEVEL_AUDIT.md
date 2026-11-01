# Algomind — Level Audit (restructure phase 0)

> **Status:** the pick list for phase 1 of [README_WORLD_RESTRUCTURE_PLAN.md](README_WORLD_RESTRUCTURE_PLAN.md), now carried out in the seed (2026-10-31) except where section 8 says otherwise. Sections 1 to 7 are the analysis as written before the change.
> **Written:** 2026-10-31, from `apps/game/data/campaign.json`, the 82 level files, and the seed (`starter-campaign.data.ts`). The numbers are computed; the keep and cut choices are judgments from the numbers, titles, and hints. **No level was played**, so a human pass is still needed (section 7).

## 1. Method

For each of the 82 levels: world and chapter, board size and wall count, number of boards, par (commands and steps), the command limit and its slack (limit minus par), difficulty tag, and the first hint. Look-alikes were found by comparing the first board under all eight rotations and mirrors (walls, start, goal). Choices follow the quality bar in [README_ROADMAP.md](README_ROADMAP.md) section 4: one new idea per level, a limit that forces a decision, no near-duplicates.

## 2. Findings

1. **The bundled par was wrong for levels with extra boards or IF and PROC (fixed in `scripts/bundle-levels.mjs`).** The server's par is right: `analyzeLevel` uses the reference solution for a level with test boards and the better of the solver and the reference for IF and PROC. The bundle script then overwrote it with `solve(content)`, which reads the first board only. So the offline bundle in `apps/game/data/campaign.json` showed, for example, par 2 for `wider-mazes` (reference solution: 21 slots), and stars and points on a device that was offline used it. The script now keeps the server's par and uses the solver only when the server gave none. An earlier version of this audit blamed the solver and the server; that was wrong. The bundle must be regenerated (`make game-bundle`) for the fix to show.
2. **One look-alike pair:** `look-ahead` and `the-other-way` are the same board mirrored (same size, par 14 and 33).
3. **Repeated hints and the same program:** all five maze levels of world 5 share one hint and one solution (a right-hand follower); `first-part`, `used-again`, `third-time` share one hint; so do `part-with-a-loop`, `loop-inside`, `longer-part`, and `two-parts` with `two-parts-longer`. These are the same idea at a larger size, not new ideas.
4. **Limits that do not bind or repeat:** world 9 (Memory) is 21 for every level, with slack 2 to 19; world 10 (Sweep) is limit 11 for six levels, the same lawnmower; `any-length` is par 1 against limit 2.
5. **Early worlds repeat.** World 1: `count-the-cells`, `beside-the-wall`, and `long-run` are all "move forward N" (par 4, 4, 6, on 5x5 or 5x7). World 2: five detour levels with par 10 to 17 and slack 1 to 3.
6. **Facts that disagree with the docs:** world 8 has 6 levels (docs said 8); the count is hard-coded as 82 in `apps/api/test/starter-campaign.test.ts`.

## 3. The pick list for worlds 1 to 12

"Keep" means reused as is (reorder only). "New" means to be designed. Counts are the plan's targets.

| New world       | Levels | Keep                                                                                                   | New                                                                                       |
| --------------- | ------ | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| 1 Basics        | 5      | `first-step`, `beside-the-wall`, `first-turn`, `turn-around`, `two-corners`                            | none                                                                                      |
| 2 Routes        | 5      | `around-the-wall`, `dead-end`, `two-ways`, `fewer-turns`, `gauntlet`                                   | none                                                                                      |
| 3 Loops         | 6      | `say-it-once`, `run-turn-run`, `stairs`, `run-and-climb`, `climb-and-run`, `final-climb`               | none                                                                                      |
| 4 Until         | 5      | `to-the-wall`, `any-distance`, `the-hall`, `steps-to-the-wall`, `round-and-in`                         | none                                                                                      |
| 5 Decisions     | 5      | `look-ahead`, `both-ways`                                                                              | 3: an `IF` on the goal ahead, an `ELSE` branch that matters, and a combined sensor level  |
| 6 Wall follower | 5      | `small-maze`, `square-maze`, `big-maze`                                                                | 2: a left-hand variant and a maze that needs the start facing a new way                   |
| 7 Procedures    | 6      | `first-part`, `used-again`, `part-with-a-loop`, `loop-inside`, `longer-part`, `two-parts`              | none                                                                                      |
| 8 Debug         | 5      | none                                                                                                   | 5 (plan section 4, phase 2)                                                               |
| 9 Generalize    | 6      | `any-length`, `any-staircase`, `any-corner`, `any-bend`, `any-maze`, `every-board`                     | none                                                                                      |
| 10 Counters     | 6      | all six (`wider-steps`, `growing-diagonal`, `tall-steps`, `small-spiral`, `left-spiral`, `big-spiral`) | none                                                                                      |
| 11 Breadcrumbs  | 6      | `first-loop`, `three-mazes`, `long-halls`, `many-dead-ends`, `large-mazes`, `tangle`                   | none                                                                                      |
| 12 Sweep        | 6      | `small-room`, `big-room`, `comb`, `spiral-hall`, `maze-sweep`                                          | 1: the same room with a step budget that makes wandering fail (the "waste no steps" idea) |

Worlds 13 to 20 are all new and were built after the audit (see [README_WORLD_RESTRUCTURE_PLAN.md](README_WORLD_RESTRUCTURE_PLAN.md) for each decision):

| New world        | Levels | Slugs                                                                                                                         |
| ---------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------- |
| 13 Patrol        | 6      | `first-guard`, `cross-the-beat`, `wait-for-it`, `gate-keeper`, `two-beats`, `crossing-paths`                                  |
| 14 Keys          | 6      | `first-key`, `side-room`, `two-doors`, `maze-gate`, `guarded-key`, `keys-and-a-guard`                                         |
| 15 Delivery      | 6      | `first-parcel`, `behind-the-start`, `two-parcels`, `full-hands`, `behind-the-door`, `guarded-parcel`                          |
| 16 Switches      | 6      | `first-switch`, `twice-over`, `two-gates`, `flip-flop`, `gate-and-crate`, `gate-and-guard`                                    |
| 17 Ice and belts | 6      | `first-slide`, `three-ice-cells`, `pushed-aside`, `belt-line`, `ice-and-belts`, `belts-and-a-guard`                           |
| 18 Teleporters   | 5      | `first-portal`, `far-corner`, `two-pairs`, `hop-and-walk`, `guarded-portal`                                                   |
| 19 Recursion     | 5      | `long-hall`, `hall-and-turn`, `right-and-ahead`, `return-trip`, `snake`                                                       |
| 20 Capstone      | 8      | `frozen-key`, `gate-by-belt`, `portal-freight`, `key-gate-guard`, `slip-and-jump`, `belt-freight`, `four-tools`, `everything` |

Totals for worlds 1 to 12: 66 levels, 55 reused, 11 new (plus the 5 of world 8 counted among the new). The plan said "about 62 reused"; this is 55, because the world 5 and world 6 splits need new levels (finding 2 and 3).

## 4. The cut list

| Cut                                                              | World today | Reason                                                                                                        |
| ---------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------- |
| `count-the-cells`, `long-run`                                    | 1           | "Move forward N", covered by `first-step` and `beside-the-wall`                                               |
| `left-turn`                                                      | 1           | Same idea as `first-turn`; check that a left turn is still used in `turn-around` or `two-corners` (section 7) |
| `find-the-gap`, `the-long-wall`                                  | 2           | The same detour idea as `around-the-wall`, longer                                                             |
| `no-spare-tiles`, `count-the-turns`, `one-route`                 | 2           | Budget ideas covered by `fewer-turns` and `gauntlet`                                                          |
| `wide-steps`, `sideways-steps`, `grand-staircase`, `long-way-up` | 3           | The same staircase loop at a different size; `grand-staircase` is 11x11 with 100 walls                        |
| `stop-short`, `zigzag`, `long-way-round`                         | 4           | A wall inside the board is a detail of `any-distance`; the other two repeat `the-hall`                        |
| `the-other-way`                                                  | 5           | A mirror of `look-ahead` (found by the symmetry check)                                                        |
| `wide-maze`, `long-maze`                                         | 5           | The same right-hand program on a larger maze                                                                  |
| `third-time`, `two-parts-longer`                                 | 6           | The same idea as `used-again` and `two-parts`, one size up                                                    |
| `any-room`, `big-and-small`                                      | 7           | `any-room` repeats `any-corner`; `big-and-small` repeats `any-maze`                                           |
| `two-mazes`, `wider-mazes`                                       | 9           | `two-mazes` repeats `first-loop`; `wider-mazes` has a first board that a 2-command program solves (finding 1) |
| `tall-room`, `wide-room`, `long-comb`                            | 10          | The same lawnmower as `small-room`, `big-room`, and `comb`                                                    |

## 5. Fixes to the kept levels

- **Par in the bundle:** fixed in the script (finding 1); regenerate the bundle with the restructured campaign.
- **Limits (worlds 9 and 11 in the new order):** set each limit to bind, at or just above the best known program, not 21 everywhere; `every-board` (slack 2) and `any-length` (slack 1) are tightened the same way.
- **Hints:** the five-times-repeated "keep a hand on the right wall" and the repeated procedure hints become progressive hints that differ per level (the quality bar, point 5).
- **Difficulty tags:** reset from the measured numbers after the pars are fixed; today world 1 is all "easy" and world 11 is all "hard".
- **World 2's ending:** the plan said "a limit that flat code cannot meet", which is impossible without loops. The last level is `gauntlet` (19 tiles, the longest flat program), so a loop is wanted when world 3 starts.

## 6. What the restructure touches besides the data

| Place                                                         | What breaks or changes                                                                                                                                                            |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `apps/api/src/modules/seed/starter-campaign.data.ts`          | Worlds, chapters, and levels (4,943 lines of data); `daily-pool.data.ts` does not use any cut slug                                                                                |
| `apps/api/test/starter-campaign.test.ts` and four other tests | The level count (82), and about 15 checks that key off the world titles ("Counters", "Memory", "Procedures", and the chapter names); `if-levels.test.ts` uses `small-maze` (kept) |
| `scripts/api-social-smoke.mjs`                                | Uses `count-the-cells`, which is cut: change it to `first-step`                                                                                                                   |
| `scripts/concept-3d/depth.mjs`                                | Uses `wide-maze` for the large-board image, which is cut: change it to `square-maze`                                                                                              |
| `apps/web/src/lib/landing-level.ts`                           | Uses `around-the-wall` (kept); `landing-sync.test.ts` checks its level number, which changes from 9 to a smaller number                                                           |
| The game's saved progress                                     | Progress for a removed slug is kept and ignored (game test exists). Achievements use their own slugs, not level slugs                                                             |
| `apps/game/data` (bundle)                                     | Regenerated with `make game-bundle`; the script deletes level files that are no longer in the campaign                                                                            |
| The database                                                  | May be reset before the first public release; after that the seed only adds                                                                                                       |

## 7. Not verified, and what a human must check

- **Nobody played these levels for this audit.** Keep and cut are judgments from numbers and text. Each kept level needs a solved playtest (quality bar, point 5).
- **Left turns:** whether `turn-around` or `two-corners` need a left turn, so that cutting `left-turn` loses nothing.
- **Breadcrumb levels:** whether each kept world 11 level really needs the marks. Old pars (11 to 19) are below the 21-slot breadcrumb program, which is a sign that a shorter program may exist on the first board only. Re-check against all boards once par is fixed.
- **The five new world 5 and 6 levels and the world 12 level** are only described here, not designed.

## 8. What was built, and where it differs from the pick list

- **Done:** the cuts in section 4, the order in section 3, and 6 new levels: `left-hall`, `first-door`, and `follow-the-bends` (Decisions); `left-hand` and `facing-away` (Wall follower). The seed has 60 levels. Memory is still called Memory, not Breadcrumbs.
- **`follow-the-bends` replaces the planned stairs level:** a staircase is periodic, and a plain loop alone solved it in 5 slots, so it did not need `IF`. The new board is an irregular winding corridor with no repeating pattern.
- **`first-door` needed a different program from the first design:** after turning at the door the hall is still on the automaton's left, so the program turns and steps through in one branch (5 slots).
- **World 12 (Sweep) has 5 levels, not 6:** the planned "tight budget" level is already how every Sweep level works (a test enforces a step budget within 1.3 times the reference run), so it was not added.
- **World 8 (Debug) is not built;** it needs a prefilled tape. The campaign skips it for now, so Generalize is world 8 in the data.
- **The two new mazes** were generated with a fixed seed, checked to be simply connected, not a rotation or mirror of an existing board, and to need at least 12 turns. Nobody has played them.
