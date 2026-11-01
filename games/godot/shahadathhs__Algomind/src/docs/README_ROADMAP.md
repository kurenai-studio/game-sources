# Algomind — Roadmap

> **Purpose:** The order of work from here to a complete game, with what each step delivers and when it is done. The day-to-day checklist is [../TODO.md](../TODO.md).  
> **Status:** the first roadmap (2026-10-19) is done; the next work is in the two plans in section 3 (2026-10-31).  
> **Related:** rules and the world ladder in [README_GAME_RULES.md](README_GAME_RULES.md); points, leaderboards, daily challenge, and sharing in [README_SOCIAL_PLAN.md](README_SOCIAL_PLAN.md); the dashboard in [README_DASHBOARD_PLAN.md](README_DASHBOARD_PLAN.md).

## 1. Principle

**Levels first, then the feature a later world needs, then that world's levels.** Worlds 1 and 2 need no new mechanic, so they come first. Every later world needs a mechanic that does not exist yet, so its levels wait for it. Quality over count: a level joins the campaign only if it teaches one new idea and passes the quality bar in section 4.

The game is called Algomind, so the campaign must teach algorithms, not only paths. From world 3 on, each world is built around one algorithmic idea (see the ladder in [README_GAME_RULES.md](README_GAME_RULES.md), section 5).

## 2. Where things stand

**Done** (steps 1 to 7 of the first roadmap, agreed 2026-10-19, all on `dev`)

- The public site, the `/play` browser build, the download page, and the level catalog.
- Player accounts, progress sync, and the sign-in screens.
- The campaign: 20 worlds and 113 levels (restructured on 2026-10-31 from 10 worlds and 82 levels; worlds 1 to 12 from existing mechanics, worlds 13 to 20 new), with their mechanics: `REPEAT`, `REPEAT_UNTIL`, `IF` and sensors, `PROC` and `CALL`, multi-board levels, the counter and nested loops, breadcrumbs, and the `visit_all` goal. Each is in the contract, the validator, the TypeScript and GDScript simulators, the fixtures, the dashboard, and the game editor.
- Points, verified submissions, leaderboards, the daily challenge, sharing, achievements, and level statistics (see [README_SOCIAL_PLAN.md](README_SOCIAL_PLAN.md)).

**Not done**

- No screen of the recent work has been looked at in screenshots or on a device; the list is in [../TODO.md](../TODO.md).
- No playtest by other people.
- The web app has no automated tests.
- The campaign ramp (first loop at about level 11, first `IF` at 22) and the 20-world ladder are built but unmeasured: nobody has played worlds 13 to 20.

## 3. What comes next

Two plans, agreed in direction on 2026-10-31, run in parallel:

| Plan                                                  | Delivers                                                                                                                              | Status                                                                                                                                                                |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [World restructure](README_WORLD_RESTRUCTURE_PLAN.md) | 20 worlds with a faster ramp (loops at about level 11): worlds 1 to 12 from existing mechanics, then patrols, items, tiles, recursion | Order approved; all 20 worlds built (patrols, keys and doors, delivery, switches, ice and belts, teleporters, recursion, capstone); playtests and a device check next |
| [Depth look](README_3D_VIEW_PLAN.md)                  | A new theme, UI, and 2.5D board, behind a Flat or Depth setting until approved on a device                                            | Built through phase 6 (tokens, screens, board, motion, public site); a device check is still open                                                                     |

They touch different files, except that the depth look's phases 1 and 2 must land before the patrol world, so patrols are built once in the new view. The earlier ordering (levels first, then the feature a later world needs) still applies inside the restructure plan.

## 4. The quality bar for every level

1. It teaches one idea the previous level did not.
2. No accidental shortcuts: the solver shows the intended route is the only cheap one. On open boards the solver is the judge of par, never the author's eye.
3. The command limit sits where it forces a decision: at par, or between par and the obvious route. In a loop world, flat par is above the limit, so a loop is required.
4. Difficulty comes from measured numbers (par, decoy cost, flat-versus-loop ratio), not guesses.
5. Hints are progressive and never give the solution away. Each level has a title and a recorded solved playtest.
6. The seed validates and solves it at startup, and fails loudly otherwise.

## 5. Rules for all steps

- The shared contract and its fixtures are the source of truth; a rule change changes the TypeScript and GDScript implementations together.
- Docs change in the same change as the code. `make check` is green before a step is called done.
- UI work is checked in screenshots at 390x844, 360x640, and 412x915 in both themes, and the web with JavaScript disabled, before it is called done.
- Nothing is committed or pushed until asked.
- The database may be reset until the first public release; after that, published versions are immutable and the seed only adds.

## 6. Risks

- **Content is the bottleneck.** The level lab and solver speed it up, but each level still needs a human eye. Keep the count small and the quality high.
- **Each mechanic is a full change:** contract, both simulators, fixtures, editor UI, and the version gate. Do one at a time.
- **The web app has no tests** and is the only way to create levels. Add tests for the publish flow before the dashboard grows (step 2).
- **Scope.** The social plan is large. Build phases 1 and 2 first and check that people play before building more.
