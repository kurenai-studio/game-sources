# TODO

The plan and the reasons are in [docs/README_ROADMAP.md](docs/README_ROADMAP.md). Tick items as they are done. Detail grows as each step is reached.

## Pending: visual review (not done)

**Not done: no screen has been looked at for the work below. It needs a window, so the owner will run it in another session at home.** Everything here passes the headless checks only (lint, typecheck, tests, fixtures). Nothing was tested on a device or in a browser.

- [ ] Run `make game-shots` (3 sizes x 2 themes: 390x844, 360x640, 412x915) and look at every image before calling a screen done (AGENTS.md, "Verify before you claim")
- [ ] Social screens: home link row, world (stars on tiles), account link row, solved play screen (Share, Ranking), profile, badges, leaderboard, daily (list in [docs/README_SOCIAL_PLAN.md](docs/README_SOCIAL_PLAN.md), section 6)
- [ ] Repeat until (world 4): the palette tile, the UNTIL header and the round count while running
- [ ] If and sensors (world 5): the six-tile palette at 360 px (labels such as END LOOP may clip), nested IF brackets inside a loop bracket, the dashed ELSE divider, select-then-cycle on the IF header, `play_debug.gd` has no IF syntax for screenshots yet
- [ ] Tap flows in the running game: report confirm, MORE paging, COPIED, clipboard; the browser build hides Daily, Leaderboard, Profile and Badges
- [ ] Dashboard in a real browser: the Repeat until and If editors, the par wording for If levels, Daily, Badges, Reports, Statistics (`make web-smoke` does not cover them)
- [ ] An Android device: install the build against the production API
- [ ] Procedures (world 6): the palette with up to ten tiles in two rows at 360 px, definition groups at the start of the tape, the CALL highlight while running, scrolling a long program
- [ ] Playtest the 24 levels of worlds 4 to 6 with real people

## Done 2026-10-31: the dashboard and the site learn the new worlds

- [x] Dashboard: the Board tab places ice, belts, keys and doors, crates and docks, switches and gates, teleporters and guards (two clicks for a pair, a route for a guard, an erase tool, a side list with "gate starts open" and the guard's pattern); Commands and limits has a Recursion switch; calls in procedure bodies carry a sensor; the Solution tab has a start program for debug levels; par is the reference solution where the exact search cannot give it (tiles with loops). Checked in a browser against a real API; `make web-smoke` still passes
- [x] The board renderer (flat and depth) draws every tile, so the dashboard preview, the levels page and the share image show them
- [x] Site: worlds grouped into five acts on the home page and the levels index, a legend of the tiles and a section on recursion on the how-to-play page, new failure messages
- [ ] The dashboard has no automated tests (checked by hand and by the publish smoke test); the tile tools are pure functions in `lib/admin/tile-tools.ts` and want unit tests
- [ ] Shut doors and gates are drawn flat on the depth board of the site and the dashboard; the game raises them

## Done 2026-10-31: the Capstone world (restructure phase 7, world 20)

- [x] Eight levels that mix two to four board tools, five with a guard (113 levels, 20 worlds); tests check that every tool is needed and the plain par is beaten
- [ ] Playtests of worlds 13 to 20 (45 levels); the capstone pars (14 to 19) are long for a phone, watch where players stop
- [ ] Mix loops, `IF` and procedures into capstone levels once par for them can be measured

## Done 2026-10-31: the Recursion world (restructure phase 6, world 19)

- [x] The mechanic `recursion` in the contract (a CALL in a procedure body, `when` on a CALL, the depth limit and `TOO_DEEP`, fixtures, both simulators, both validators, the schema), the API mechanic, the tape editor (Call tile into an open definition, sensor tool on a call), five levels (105 levels, 19 worlds)
- [ ] A solved playtest of the five Recursion levels; check the tape editor flow for a recursive procedure on a device
- [ ] No solver for procedures: a player's shorter recursive program is not detected as better than the reference; consider a bounded search over recursive programs for par

## Done 2026-10-31: the Teleporters world (restructure phase 5, world 18)

- [x] `teleports` in the contract (types, both validators, both schemas, both simulators, 23 fixtures), the API mechanic `teleport`, teleporters on both boards, five levels (100 levels, 18 worlds)
- [ ] A solved playtest of the five Teleporters levels; look at teleporters and the appear animation on a device

## Done 2026-10-31: the Ice and belts world (restructure phase 5, world 17)

- [x] `ice` and `belts` in the contract (types, both validators, both schemas, both simulators, 25 fixtures, trace `path`); the simulator and the solver now share the `World` class (`RunWorld` in the game), which also replaced the solver's separate state code for keys, crates and switches; the API mechanics `ice` and `belts`; ice and belts on both boards with a step-by-cell slide animation; six levels (95 levels, 17 worlds)
- [ ] A solved playtest of the six Ice and belts levels; look at ice, belts and the slide on a device
- [ ] The slide is animated cell by cell in one step time; check on a device that it reads (and with reduce motion)

## Done 2026-10-31: the Switches world (restructure phase 5, world 16)

- [x] `switches` in the contract (types, both validators, both schemas, both simulators, the solver with the switches flipped, 26 fixtures; the pair validator was split into `validate-pairs.ts` and `pair_validator.gd`), the API mechanic `switch`, switches and gates on the flat and depth boards, six levels (89 levels, 16 worlds)
- [ ] A solved playtest of the six Switches levels; look at switches and gates on a device

## Done 2026-10-31: the Delivery world (restructure phase 4, world 15)

- [x] `deliveries` in the contract (types, both validators, both schemas, both simulators, the solver with carried and delivered in the state, 25 fixtures), the API mechanic `delivery`, crates and docks on the flat and depth boards, six levels (83 levels, 15 worlds)
- [ ] A solved playtest of the six Delivery levels; look at crates and docks on a device
- [x] Authoring deliveries and locks in the dashboard (Board tab, Tiles tools)

## Done 2026-10-31: the Keys world (restructure phase 4, world 14)

- [x] `locks` in the contract (types, both validators, both schemas, both simulators, the solver with keys held, 23 fixtures), the API mechanic `keys`, keys and doors on the flat and depth boards, six levels (77 levels, 14 worlds)
- [ ] Mark the shut door itself on failure
- [ ] A solved playtest of the six Keys levels; look at keys and doors on a device

## Done 2026-10-31: the Patrol world (restructure phase 3)

- [x] `patrols` in the contract (types, both validators, both schemas, both simulators, the solver over time, 30 fixtures), the API mechanic `patrol` and analysis, guards on the flat and depth boards, six levels (71 levels, 13 worlds)
- [ ] The stop-by-step strip and numbered stops for patrols (guards can now be authored in the dashboard)
- [ ] A solved playtest of the six Patrol levels; look at the guard on a device
- [ ] Reset Render's database when deploying (a new world was added after Sweep)

## Done 2026-10-31: the Debug world (restructure phase 2)

- [x] `startProgram` in the contract (types, both validators, both schemas, 5 fixtures), the API gate and mechanic, the game's tape and objective, and five levels (65 levels, 12 worlds)
- [x] Author a start program in the dashboard (Solution tab)
- [ ] A solved playtest of the five Debug levels; Reset must be checked to restore the start program on a device
- [ ] Reset Render's database when deploying (the seed only adds, and the Debug world sits between existing worlds)

## Done 2026-10-31: depth look phase 6 (the public site)

- [x] Depth tokens as scoped CSS (`depth-tokens.css`, generated, tested); `Key`; buttons, wordmark, header, frames, number tiles; depth drawings (`look="depth"`: keys, trough, extruded board); the dashboard stays flat
- [ ] Look at the site on a phone, light and dark; check `/play` with a browser build present (its frame is still flat); the share image is done
- [ ] Decide whether the web needs a test runner for `board-projection.ts` (the game tests the same geometry)

## Done 2026-10-31: depth look phase 4 (motion)

- [x] Eased slide, lift between cells, turning wedge, rising goal pad, keys that sink and spring back; one shared reduce-motion flag; nothing runs while idle (9 tests)
- [x] The world list is plates with a picture of each world's first level, and the menu shows the next level as a full-width board (3 tests)
- [ ] Watch a run on a device at each run speed and with reduce motion on; check each duration is under 250 ms

## Done 2026-10-31: depth look phase 1 (tokens and key kit)

Plan: [docs/README_3D_VIEW_PLAN.md](docs/README_3D_VIEW_PLAN.md).

- [x] Depth tokens in `packages/design-tokens/tokens.json`; the generator derives lips and shades and writes `depth_palette.gd`; contrast and docs-table tests
- [x] `DepthKit` (gradient, keys, soft shadows, trough) and `DepthKitSample`; `--screen=depth_kit` in `make game-shots`; 7 GUT tests
- [ ] Run `make game-shots` and look at the depth-kit sample on a real Android device; measure frame time with about 20 keys on screen (8 shadow layers a key)
- [x] Phase 2: `BoardView25D` (adaptive camera, plate, low walls, goal pad, trail, breadcrumbs, sweep), `BoardViews.make`, the Look setting (default flat, local), `--look=depth` in the shot tool, 13 tests
- [x] A STYLE row (flat or depth) in Settings, saved with the other settings
- [ ] Look at the depth board on a real Android device (`make game-apk`, set the look) and measure frame time with the animation running on the 12x10 board
- [x] Phase 3: the screens in the depth look (palette override, `TileDraw`, `TileButton` keys, trough, gradient, board area), 17 depth shots in `make game-shots`
- [ ] Look at every depth screen on a real device and at 3 sizes in both themes there; the pause panel frame and the tape's loop brackets are still flat shapes
- [x] Depth is the default look (`Settings.LOOK_DEFAULT`); flat stays in Settings. Rebuild the debug APK (`make game-apk`) or run `make game-run` to see it; an APK built earlier still shows the old look
- [ ] After the device test, confirm depth stays the default or set `LOOK_DEFAULT` back to flat

## Done 2026-10-31: restructure phase 1 (worlds 1 to 12, data only)

Plan: [docs/README_WORLD_RESTRUCTURE_PLAN.md](docs/README_WORLD_RESTRUCTURE_PLAN.md). Picks and reasons: [docs/README_LEVEL_AUDIT.md](docs/README_LEVEL_AUDIT.md).

- [x] The seed is 11 worlds, 22 chapters, 60 levels (was 10, 20, 82); the first loop is level 11 and the first `IF` is level 22
- [x] Worlds 1 and 2 cut to 5 levels each; Decisions split into Decisions and Wall follower; 27 repeated levels cut
- [x] Six new levels: `left-hall`, `first-door`, `follow-the-bends` (Decisions) and `left-hand`, `facing-away` (Wall follower); the reference solutions pass the seed's checks at startup
- [x] `starter-campaign.test.ts`, `landing-sync.test.ts` data (`apps/web/src/lib/landing-level.ts`), the smoke script, and the game's `test_campaign.gd` updated
- [x] Bundled par fixed (`scripts/bundle-levels.mjs` no longer overwrites the server's par with a first-board solver result)
- [x] Local database reset and reseeded; the game bundle regenerated from the API (`make game-bundle`)
- [x] API tests (294) and the GDScript tests (394) pass
- [ ] Reset Render's database when deploying (the seed only adds; the old 82 levels stay otherwise)
- [ ] Look at the 6 new levels and the changed order on a screen; a solved playtest for every level of worlds 1 to 12
- [ ] The Debug world (needs a prefilled tape, restructure phase 2) and the new world 12 level the plan asked for (dropped: every Sweep level already has a tight step budget)
- [ ] Limits in Memory (21 on every level) and the repeated hints in Procedures and Wall follower, from the audit, section 5

## Done earlier: step 1, worlds 1 and 2 (18 levels, since replaced by the restructure)

**Level lab** (`scripts/level-lab/`, see its README)

- [x] Candidate families for worlds 1 and 2: straight runs, turns, the U-turn, detours, tight budgets, decoy routes
- [x] Scoring from the real solver: par, moves, turns, wall cost, decoy cost, number of shortest programs, dead ends
- [x] Look-alike removal (rotations and mirrors) and a varied shortlist
- [x] Contact-sheet renders in the house style, light and dark (SVG; convert to PNG to view)
- [x] A constrained maze generator (a unique cheap route and deliberate dead ends); today only random wall segments (`carve.mjs`: `maze`, family `budget-tree-maze`)
- [x] Rejection rules across a set: par equal to an earlier level, a limit that does not force a decision (`check`: equal par in a chapter, a loop that is optional, slack on a budget level)
- [x] A better decoy builder: the random one finds few candidates and the decoy is small (1 to 2 commands) (`carve.mjs`: `decoy`, family `budget-carved-decoy`; 164 candidates on seed 1 against 22)

**Curriculum**

- [x] One-line idea for each of the 18 levels (world 1: Basics, 8; world 2: Routes, 10), in order
- [x] Shortlists per chapter (Moves, Turns, Detours, Budgets); picked by the assistant on the owner's instruction ("just get it done")
- [x] Titles, progressive hints (1 to 3, no spoilers), difficulty from measured numbers
- [x] Decide which of the current 19 levels, if any, are kept (none: all replaced)

**Seed and data**

- [x] New seed data file (`starter-campaign.data.ts`) replacing the 19 starters; the seed still validates and solves every level at startup
- [x] Seed and campaign tests (`apps/api/test/starter-campaign.test.ts`)
- [x] Update the docs that say "nineteen" (`README_ARCHITECTURE.md`, `DEPLOY.md`)
- [x] Reset the local database and reseed (`make db-reset`)
- [ ] Reset Render's database when deploying
- [x] Regenerate the game's bundled levels (`scripts/bundle-levels.mjs`)
- [x] Saved progress for removed slugs is kept and ignored, never crashes (game test `test_progress_for_a_removed_level_is_kept_and_ignored`; the API merge stores any slug)

**Verify**

- [x] `make check` green (lint, typecheck, API and game tests pass; the full run is not yet repeated) (green on `dev` after the refactor)
- [x] Game plays the new levels (screenshots checked; every level offers Move, Left and Right from the start, by the owner's call: a new player can handle three tiles)
- [x] `/levels` and the home page show the new levels (both render per request now; the home drawings are computed from a real level and guarded by a test)
- [ ] Dashboard lists the new levels; `/play` shows them
- [x] Screenshots reviewed at 360x640 and 412x915 (play ready, running, failed, solved, big board; pause; worlds; world; home; settings; account; how-to-play): the pause scrim is now opaque. Not every one of the 102 was looked at by eye; the rest were checked identical before and after the `play.gd` split

## Next: step 2, `REPEAT` in the editor and the dashboard

**Game**

- [x] Tape model for loop groups: a count tile and body tiles (`tape_model.gd`)
- [x] Repeat tile in the palette; append, remove, reorder, change the count (minus and plus tools)
- [x] Slot counter ("5 / 5") and the command limit counted in slots
- [x] Run and step animation: the current body tile and the round on the count tile ("2/6")
- [x] A failure inside a loop puts the X on the body tile and shows the round on the count tile
- [x] Result screen and local best use slots (sync merge unchanged: it stores the command count)
- [x] GUT tests for the tape model and the play session with loops (`test_tape_loops.gd`)
- [x] Update `README_VISUAL_DESIGN.md` for the loop group and the Repeat tile
- [x] In-game how-to-play teaches loops (a Repeat row and a Loops paragraph; checked at 390x844 and 360x640, both themes)

**Dashboard and API**

- [x] Solution editor and preview support `REPEAT` (loop rows with a rounds field and a body; checked in a browser on a temporary page)
- [x] Publish gates: par from the loop solver (already), budget against par in slots, and a `LOOP_NOT_REQUIRED` warning when flat par fits the limit (`apps/api/test/loops.test.ts`)
- [x] Import and export of loop levels (the contract validator and the API pass loop nodes through; no change needed)
- [x] Dashboard validation panel and diff texts mention loops (checked in the live editor; the publish review diff gained a Solution row with slots and loops)
- [x] Client registry and the game both list the `repeat` mechanic (the seed's registry row and `Campaign.SUPPORTED_MECHANICS`)
- [x] Bump the game version when loops ship in a release (0.1.0; the release itself is the owner's call)
- [x] Web test for the publish flow (`make web-smoke`: Playwright driving Chrome; local, needs a running API and web app, not in CI)
- [x] How-to-play page and the browser build teach loops (the browser build uses the game screen)

## Then: step 3, world 3 (Loops)

- [x] Pattern families: stairs, wide steps, run and climb, ridge, crossing, rooms
- [x] Gate: flat par above the limit; loop par at or below the limit (`starter-campaign.test.ts`: every Loops level needs a loop)
- [ ] 8 to 10 levels chosen, titled, hinted, and playtested by real people
- [x] Seed, bundle, and screenshots

## Later

- [x] Step 4: verified submissions, points ledger, stars, result screen, player management (see [docs/README_SOCIAL_PLAN.md](docs/README_SOCIAL_PLAN.md), section 6 for what is built and what is not)
- [x] Step 5a: world 4, Until (`REPEAT_UNTIL`): contract, both simulators, solver, fixtures, dashboard and game editors, 8 levels in 2 chapters (see [docs/README_GAME_RULES.md](docs/README_GAME_RULES.md), section 3.2). Open: look at the new tile and header on screen at all three sizes in both themes, and playtest the 8 levels with real people
- [x] Step 5b: world 5, Decisions (`IF` sensors, `REPEAT_UNTIL GOAL`): contract, both simulators, editors, 8 levels in 2 chapters (see [docs/README_GAME_RULES.md](docs/README_GAME_RULES.md), section 3.3). Open: look at the new tape (nested IF brackets, six-tile palette) at all three sizes in both themes, and playtest the 16 levels of worlds 4 and 5 with real people
- [x] Step 6: leaderboards, daily challenge, sharing, badges, level statistics, profile, stars on tiles (see [docs/README_SOCIAL_PLAN.md](docs/README_SOCIAL_PLAN.md), section 6). Open: look at the new game screens at all three sizes in both themes (a screenshot run needs a window; only 360x640 was reviewed), try the tap flows in the running game (report confirm, MORE paging, COPIED, clipboard), and test the browser build hides the four screens
- [x] Step 7a: world 6, Procedures (`PROC` and `CALL`): contract, both simulators, editors, 8 levels in 2 chapters (see [docs/README_GAME_RULES.md](docs/README_GAME_RULES.md), section 3.4)
- [x] Step 7b: world 7, Generalize (test boards: `extraBoards`, `simulateAll`): contract, both simulators, editors, API gates, 8 levels in 2 chapters (see [docs/README_GAME_RULES.md](docs/README_GAME_RULES.md), section 3.5). Open: look at the board tabs and the per-board results on screen
- [x] Step 7c: worlds 8 to 10, Counters (a counter and loops in loops), Memory (breadcrumbs, else-if chains, the search of Tremaux), Sweep (visit every cell): contract, both simulators, editors, API gates, 22 levels (see [docs/README_GAME_RULES.md](docs/README_GAME_RULES.md), sections 3.6 to 3.8). Open: look at the new tape, breadcrumbs and sweep readouts on screen; playtest worlds 4 to 10

## Open items

- [ ] Add the ten-world ladder and multi-board levels to the architecture doc's contract section when world 7 is designed
- [ ] Move the API's in-memory rate limiter to a shared store before running more than one instance
