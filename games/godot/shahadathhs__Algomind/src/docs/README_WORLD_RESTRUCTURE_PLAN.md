# Algomind — World Restructure Plan (20 worlds)

> **Status:** the world order (section 3) is approved by the owner; the phases are not yet started. The 2.5D board view is planned separately in [README_3D_VIEW_PLAN.md](README_3D_VIEW_PLAN.md). Nothing in the code, seed, or rules has changed. When this plan is agreed, section 3 replaces the ladder in [README_GAME_RULES.md](README_GAME_RULES.md) (section 5) and [README_ROADMAP.md](README_ROADMAP.md) is updated to point here.
> **Written:** 2026-10-31, from a read of the shipped data (`apps/game/data`), the seed (`starter-campaign.data.ts`), and the docs. No level was played or re-solved for this plan; numbers come from `campaign.json` and the level files.

## 1. Why restructure

| Finding                                                                                                                                                                                                                   | Evidence                                            |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| The first algorithmic idea (loops) arrives at level 19, conditions at 37, the first named algorithm (wall following) at 40.                                                                                               | worlds 1 and 2 hold 18 levels with three commands   |
| 72 of 82 levels have the goal "reach the tile". Only world 10 has another goal.                                                                                                                                           | `goal.type` in every level                          |
| Worlds 1 and 2 repeat: world 1 is eight easy 5x5 levels, world 2 has five levels that are mostly detours of the same kind.                                                                                                | par 2 to 10 and 10 to 17                            |
| Near-duplicates and flat limits: `look-ahead` and `the-other-way` have the same size and par; world 10's first six levels all have limit 11; world 9 is 21 on every level; `wider-mazes` has par 2 against a limit of 21. | level files                                         |
| The docs and data disagree: world 8 has 6 levels, the doc says 8.                                                                                                                                                         | `campaign.json` against README_GAME_RULES section 5 |
| The game is called Algomind but the first 18 levels teach paths, not algorithms.                                                                                                                                          | README_ROADMAP section 1                            |

## 2. Principles

1. **A new idea almost every world, 5 to 6 levels each.** Variety comes from goals and constraints before it comes from count.
2. **Introduce, twist, combine.** Teach in isolation, test with a twist, then combine with earlier worlds. A sawtooth, not a ramp: an easier level after a hard one.
3. **Cheap changes first.** Worlds 1 to 12 use only mechanics that exist (data-only). Worlds 13 to 19 each need a full engine change, so they come after the first part ships and is playtested.
4. **One mechanic at a time**, following the checklist in section 6. A rule change changes the TypeScript and GDScript simulators together.
5. **Quality bar unchanged** ([README_ROADMAP.md](README_ROADMAP.md), section 4): one new idea, no shortcut, a limit that forces a decision, measured difficulty, progressive hints, solved by the seed at startup.
6. **Scope.** The "not included" list in [README_PROJECT_OVERVIEW.md](README_PROJECT_OVERVIEW.md) still holds: no multiplayer, no general-purpose language, no scripts from the server. A world needing any of those is out.

## 3. The target ladder

"Existing" means levels reused from the current 82, picked and reordered with the level lab and solver. "New" means designed from scratch. Engine cost: **none** (data only), **S/M/L** (a full mechanic change, by size).

| #   | World             | Idea and algorithm                                            | Needs                             | Levels | Source                        |
| --- | ----------------- | ------------------------------------------------------------- | --------------------------------- | ------ | ----------------------------- |
| 1   | Basics            | Sequencing and turning                                        | none                              | 5      | 5 of the 8 existing           |
| 2   | Routes            | Planning and budgets; ends on the longest flat program        | none                              | 5      | 5 of the 10 existing          |
| 3   | Loops             | `REPEAT`, pattern detection                                   | none                              | 6      | 6 of 10                       |
| 4   | Until             | `REPEAT_UNTIL`, search with a stop condition                  | none                              | 5      | 5 of 8                        |
| 5   | Decisions         | `IF` and sensors                                              | none                              | 5      | 2 existing plus 3 new         |
| 6   | Wall follower     | Right-hand rule                                               | none                              | 5      | 3 existing plus 2 new         |
| 7   | Procedures        | `PROC` and `CALL`, abstraction                                | none                              | 6      | 6 of 8                        |
| 8   | Debug             | Fix a program that is wrong                                   | prefilled tape (to be checked), S | 5      | new                           |
| 9   | Generalize        | One program, many boards                                      | none                              | 6      | 6 of 8                        |
| 10  | Counters          | Accumulation, nested loops                                    | none                              | 6      | existing 6                    |
| 11  | Breadcrumbs       | Marks, Tremaux search                                         | none                              | 6      | 6 of 8, limits and pars fixed |
| 12  | Sweep             | Coverage and efficiency (`visit_all`)                         | none                              | 5      | 5 of 8                        |
| 13  | Patrol            | Timing and prediction: obstacles that move in a fixed pattern | moving obstacles (patrol), L      | 6      | new                           |
| 14  | Keys and doors    | Dependencies and ordering                                     | items and doors, M                | 6      | new                           |
| 15  | Delivery          | Carry and drop, sub-goals                                     | same item system as 14, S         | 6      | new                           |
| 16  | Switches          | State machines, toggled gates                                 | toggle tile, M                    | 6      | new                           |
| 17  | Ice and conveyors | Predict side effects of a move                                | forced-move tiles, M              | 6      | new                           |
| 18  | Teleporters       | Graph jumps                                                   | paired tiles, S                   | 5      | new                           |
| 19  | Recursion         | Base case and self-call                                       | depth limit and `CALL` rules, L   | 6      | new                           |
| 20  | Capstone          | Choose the right tool from all worlds                         | none                              | 8      | new, built last               |

About 114 levels: 55 reused and 59 new (worlds 1 to 12 are built, Debug included: 65 levels) (the per-level pick list is in [README_LEVEL_AUDIT.md](README_LEVEL_AUDIT.md)). The first loop moves from level 19 to level 11, and the first `IF` from 37 to 22.

**Patrols are taught once and reused.** World 13 teaches only the idea (read the pattern, then time your moves). From world 14 on, the last chapter of every world is "with patrols": two or more levels of that world's own idea with a moving obstacle added, which is data only once the mechanic exists. The capstone has at least four. Worlds 1 to 12 stay as they are for the first release; patrol chapters can be added to them later as a data update, once the app version that supports patrols has shipped. The rule is in [README_GAME_RULES.md](README_GAME_RULES.md), section 3.9.

**Dropped from the first list:** weighted ground (a step cost per tile) made room for patrols. Other alternatives, each another full mechanic change: boolean logic (`AND`, `OR`, `NOT` in conditions), a second counter and compare. Parallel automata and sorting are left out (scope and engine size).

## 4. Phases

Sizes are relative. There are no dates; a phase is done when its exit criteria are met.

### Phase 0 — Agree and prepare (S) — analysis done: [README_LEVEL_AUDIT.md](README_LEVEL_AUDIT.md)

- Decide the open questions in section 8; fix the list for worlds 13 to 19.
- Update the ladder in `README_GAME_RULES.md` section 5 and this plan's status; fix the "eight levels" mismatch for world 8 (now 10).
- Run the audit of the current 82 levels in the level lab: par, decoy cost, flat-versus-loop ratio, look-alikes, limits that bind. Output the pick list for each world.
- **Exit:** a signed-off ladder and a written pick list (slug, keep or cut, reason).

### Phase 1 — Restructure worlds 1 to 12, data only (M) — done 2026-10-31, see [README_LEVEL_AUDIT.md](README_LEVEL_AUDIT.md) section 8 and `TODO.md`

1. Reorder and trim worlds 1 and 2 to 5 and 5 levels. End world 2 on `gauntlet`, the longest flat program, so loops are wanted when world 3 starts.
2. Split world 5 into Decisions (2 existing, 3 new) and Wall follower (3 existing, 2 new); `the-other-way` is a mirror of `look-ahead` and is cut.
3. Fix the other anomalies (the bundled par is already fixed in the script, audit finding 1): world 9 limits and the par on `wider-mazes`, world 10 repeated limit 11, the near-duplicate pair in world 5, world 8 count.
4. Edit `starter-campaign.data.ts`: worlds, chapters, order, titles, hints, difficulty from measured numbers. Update `daily-pool.data.ts` if it uses any removed level.
5. Update tests: `starter-campaign.test.ts` (the level count is hard-coded to 82), world and chapter counts, and any test that names a removed slug.
6. Reset the local database (`make db-reset`), regenerate the bundle (`make game-bundle` or `scripts/bundle-levels.mjs`), and run `make check`.
7. Docs: rules section 5, README status, `TODO.md`, the architecture doc if it states counts.

- **Progress safety.** Saved progress for a removed slug is kept and ignored, never a crash (`test_progress_for_a_removed_level_is_kept_and_ignored`). Check that points, stars, achievements, leaderboards, and the daily challenge do not depend on a removed slug. Until the first public release the database may be reset; after that, published versions are immutable and the seed only adds.
- **Exit:** the seed validates and solves every level at startup; the game plays them; the dashboard lists them; screenshots at 390x844, 360x640, 412x915 in both themes looked at; a playtest of worlds 1 to 6 with real people.

### Phase 2 — World 8, Debug (S to M) — built 2026-10-31 except dashboard authoring

- Check whether the contract and both editors can start a level with a prefilled program (a broken one the player must fix). If not, add it as a level field: contract, validator, both simulators if needed, fixtures, the game's tape, the dashboard editor, publish gate.
- Design 5 levels: an off-by-one count, a missing turn, a loop that never ends, a wrong branch, a wrong procedure call.
- **Exit:** the checklist in section 6 for the new field, plus five solved playtests.

**Phase 2 as built:** the contract has an optional `startProgram` (types, the TypeScript and GDScript validators, both JSON schemas, 5 shared fixtures, a negative control that proved the game's validator is held to them); the API gate `start_program` (code `START_PROGRAM_SOLVES`) and the mechanic `start_program` in the client registry; the game loads the program onto the tape (`TapeModel.load_program`) and the objective reads FIX THE PROGRAM; the seed has the Debug world after Procedures with five levels (`off-by-one`, `missing-turn`, `never-ends`, `wrong-way-round`, `wrong-part`), each with its fix as the reference solution. Rules: [README_GAME_RULES.md](README_GAME_RULES.md) section 3.10. **Not built:** authoring a start program in the dashboard (an existing one survives an edit, because the editor spreads the level, but it cannot be made or changed there); the levels have not been played by anyone.

### Phase 3 — Patrol, world 13 (L) — built 2026-10-31

**As built:** patterns back and forth and loop (blink left out), the collision rule of the rules' section 3.9 (same cell or swap, checked before the goal), the contract with fixtures run by both simulators, the exact solver over (cell, facing, step), the `patrol` mechanic and publish analysis, guards on both boards, and six levels (`first-guard`, `cross-the-beat`, `wait-for-it`, `gate-keeper`, `two-beats`, `crossing-paths`). Not built: the stop-by-step strip, authoring patrols in the dashboard, and playtests of the six levels.

- **First, measure.** Prototype the solver with the step number in the search state, on small boards, and record the cost (as the loop prototype did). If par becomes too slow, limit board size or the number of patrols for these levels.
- **Rules.** Write section 3.9 of the rules (patterns, collision, preview) and agree it before any code; then the checklist in section 6.
- **Design in the depth look.** The guard, its route, and the guard timeline are designed in [README_3D_VIEW_PLAN.md](README_3D_VIEW_PLAN.md); build them in the new view, not the flat one.
- **Exit:** the checklist in section 6; fixtures for every pattern and collision case passing in both simulators; six solved playtests.

### Phase 4 — Items: worlds 14 and 15 (M, then S)

**World 14 built 2026-10-31:** keys and doors as `locks` (automatic pickup on entering a cell, a shut door blocks like a wall, `BLOCKED_BY_DOOR`), contract and both simulators with fixtures, the solver with keys held, the `keys` mechanic, drawing on both boards, six levels (`first-key`, `side-room`, `two-doors`, `maze-gate`, `guarded-key`, `keys-and-a-guard`). **World 15 built 2026-10-31:** `deliveries` (crates and docks). Decision: dropping is automatic on entering the dock of the carried item, so no new tile; hands hold one crate; the target counts only when every crate is delivered (`UNDELIVERED`). Contract and both simulators with 25 fixtures, the solver with carried and delivered in the state, the `delivery` mechanic, crates and docks on both boards, six levels (`first-parcel`, `behind-the-start`, `two-parcels`, `full-hands`, `behind-the-door`, `guarded-parcel`).

**World 16 built 2026-10-31:** `switches` (a switch flips its gate every time it is entered; a gate may start open; `BLOCKED_BY_GATE`, event `SWITCHED`), contract and both simulators with fixtures, the solver with the switches flipped in the state, the `switch` mechanic, drawing on both boards, six levels (`first-switch`, `twice-over`, `two-gates`, `flip-flop`, `gate-and-crate`, `gate-and-guard`).

**World 17 built 2026-10-31:** `ice` and `belts`. Decisions: a slide is one step and goes through every cell it passes (effects fire in each, a target in the middle ends the run); a belt carries once per action, after any action, and neither chains nor slides; guards are checked where the step ends. Because movement now has several cases, the simulator and the solver share one `World` class and the game one `RunWorld`; trace entries gain `path` on levels with ice or belts. Six levels (`first-slide`, `three-ice-cells`, `pushed-aside`, `belt-line`, `ice-and-belts`, `belts-and-a-guard`).

**World 18 built 2026-10-31:** `teleports` (a pair of cells; entering one end puts the automaton on the other in the same step, facing the same way, with no bounce back; `TELEPORTED`). It is one rule in `World`, so the solver needed no change. Five levels (`first-portal`, `far-corner`, `two-pairs`, `hop-and-walk`, `guarded-portal`).

**World 19 built 2026-10-31:** `recursion`. Decisions: the level lists the mechanic (like `nested_loops`); a CALL may stand directly in a procedure body and may carry a sensor (`when`), which is the base case (no new tile and no CALL inside an IF branch); the depth limit is 24 calls and ends the run with `TOO_DEEP`; the solver stays out of procedures, so the limit is the reference solution's slots and a test checks the plain par against it. Levels offer movement and `PROC` only. Five levels (`long-hall`, `hall-and-turn`, `right-and-ahead`, `return-trip`, `snake`). No guard chapter (see 3.16).

- Build the item and door mechanic once (key, door, pick up, drop) and use it for both worlds. New commands or automatic pickup is a decision for the design step; prefer the smallest change that teaches ordering.
- Each world ends with its "with patrols" chapter.
- **Exit:** checklist in section 6; world 14 playable, then world 15 as a data-and-small-rule extension.

### Phase 5 — Tiles that act on the automaton: worlds 16, 17, 18 (M, M, S)

- 16 toggle switch and gate; 17 ice and conveyors (forced movement); 18 paired teleporters. One mechanic and one world at a time; do not start the next before the previous is done. Each ends with a "with patrols" chapter.

### Phase 6 — Recursion, world 19 (L)

- A procedure that calls itself, with a depth limit and a rule for the base case. Highest risk for both simulators and the solver; design it last of the mechanics and prototype the solver bounds first (the loop prototype measured par search costs; do the same here).

### Phase 7 — Capstone, world 20 (S)

- Eight levels that use any tool from worlds 1 to 19, at least four with patrols. Built last, because it needs every mechanic and measured numbers from playtests.

**Built 2026-10-31:** eight levels (`frozen-key`, `gate-by-belt`, `portal-freight`, `key-gate-guard`, `slip-and-jump`, `belt-freight`, `four-tools`, `everything`) found by a random search over boards with the exact solver; each tool is needed, five have a guard. They use the board tools of worlds 13 to 18 with movement only; mixing in loops, `IF` and procedures needs a bounded solver for par and is left for later. The measured numbers from playtests are still missing.

## 5. Parallel tracks

| Track         | Work                                                                                                                                                                                                                                                                 |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UX            | The world map is a list: with 20 worlds it needs a stronger progress view. Palette labels shrink to 8 px on dense tapes; fix by regrouping or scrolling (see `game-ux-mobile`).                                                                                      |
| Visual review | The pending review in `TODO.md` (screenshots, tap flows, a real device) before any of this is called done.                                                                                                                                                           |
| Look and feel | The depth view: a new theme, UI, and 2.5D board, approved in direction. See [README_3D_VIEW_PLAN.md](README_3D_VIEW_PLAN.md). It touches different files from phase 1, so it runs in parallel, and it should land before phase 3 so the new tiles are designed once. |
| Playtesting   | After phases 1, 3, and 5, put real people on the new worlds and record where they stop.                                                                                                                                                                              |
| Social plan   | Points, leaderboards, daily challenge exist. Check that points rules and the daily pool still fit the new level set.                                                                                                                                                 |
| Web tests     | The web app has no automated tests; add them for the publish flow before the dashboard learns new mechanics.                                                                                                                                                         |
| Docs          | Every phase updates the rules, README status, and TODO in the same change.                                                                                                                                                                                           |

## 6. Checklist for every new mechanic

1. Rule written in `README_GAME_RULES.md` (what it does, what it does not, edge cases).
2. Contract: JSON Schema, TypeScript types, validator, reference simulator, solver (and par), capabilities registry entry.
3. Fixtures that exercise it, in `packages/level-contract/fixtures`.
4. GDScript validator and simulator; the fixtures pass in both languages.
5. API: publish gate and client-compatibility (a new mechanic needs an app release; the dashboard may only publish what the deployed client declares support for).
6. Dashboard editor and preview.
7. Game: tape and palette, board rendering, result messages, hint text. Check labels stay readable at 360 px.
8. Levels, hints, and seed entries for its world; solved by the seed at startup.
9. Tests in each package, then `make check` green.
10. Screenshots at 390x844, 360x640, 412x915 in both themes, looked at.

## 7. Risks

| Risk                                                            | Mitigation                                                                                                     |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Content is the bottleneck: 50 new levels each need a human eye. | Use the level lab and solver; keep worlds to 5 or 6 levels; stage by phase.                                    |
| Each mechanic is a full change in two languages.                | One at a time; the checklist; fixtures must pass in both.                                                      |
| Recursion and weighted cost can break the solver bounds.        | Prototype and measure before design; bound depth and cost.                                                     |
| Players lose progress when the ladder changes.                  | Progress for removed slugs is kept; check points, stars, and the daily pool; reset the DB only before release. |
| Faster ramp is too steep for new players.                       | Playtest after Phase 1; sawtooth difficulty; a skip option is a separate decision.                             |
| The scope grows past what one person can finish.                | Ship after Phase 1 and playtest before Phase 3. Worlds 13 to 20 can be released as updates.                    |

## 8. Decisions

**Made:** the world order (section 3) is approved; patrols are world 13 and are reused in later worlds as a closing chapter; the depth look is the chosen direction (README_3D_VIEW_PLAN.md).

**Still open:**

1. **Skip-ahead.** A placement test or open worlds for experienced players: a new feature, not in this plan unless approved.
2. **Release order.** Ship worlds 1 to 12 first and add 13 to 20 as updates (recommended), or hold the release until all 20 exist.
3. **World 20 as a capstone,** or ten more levels spread through the earlier worlds.
4. **The patrol collision rule** (section 3.9 of the rules): confirm that swapping places with a guard counts as a collision.
