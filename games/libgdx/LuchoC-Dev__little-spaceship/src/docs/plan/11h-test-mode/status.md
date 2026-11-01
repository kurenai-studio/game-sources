# Phase 11h — A test mode, so a wave can be looked at without playing to it · status

**State:** **done and merged into `dev`** in [#249](https://github.com/LuchoC-Dev/little-spaceship/pull/249), with the project owner's direct approval on 03/09/2026. Four tasks, four pull requests, all accepted by `reviewer` and merged on 03/09/2026 — two planned, and two asked for by the project owner while reviewing the phase. **Verified by the project owner**, who approved the pull request directly.
**Updated:** 03/09/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by whoever did that task on its own branch.

## Why this phase exists

The project owner decided on 03/09/2026 to keep going on level 1 and give it **more depth**, and defined that as **movement and grouping** — how enemies enter, move and combine. Three things were ruled out in the same conversation: the boss moves as little as possible, no new enemy archetypes, and obstacles wait until the story and the final background exist. All of it is recorded in `docs/planning/08-decisions-and-open-items.md` under "A test mode, and what level 1's depth means, 03/09/2026".

**The tool comes first, and that was the owner's call.** Every iteration of movement work has to be judged by playing — the rule this project has now decided three times — and judging one wave costs playing the level up to it. The boss costs 134.5 s.

## Done

| Task | Issue | What | PR |
|---|---|---|---|
| 1 | [#244](https://github.com/LuchoC-Dev/little-spaceship/issues/244) | The `-Ptests` build flavour and the TESTS menu | [#247](https://github.com/LuchoC-Dev/little-spaceship/pull/247) |
| 2 | [#245](https://github.com/LuchoC-Dev/little-spaceship/issues/245) | The four scenarios, as level files | [#246](https://github.com/LuchoC-Dev/little-spaceship/pull/246) |
| 4 | [#250](https://github.com/LuchoC-Dev/little-spaceship/issues/250) | `-Ptests` boots straight into the TESTS menu | [#254](https://github.com/LuchoC-Dev/little-spaceship/pull/254) |
| 5 | [#251](https://github.com/LuchoC-Dev/little-spaceship/issues/251) | The boss scenario carries no prelude enemies | [#253](https://github.com/LuchoC-Dev/little-spaceship/pull/253) |

Task 3, the record in `08-decisions-and-open-items.md`, is the coordinator's and carries no issue.

**Tasks 4 and 5 were asked for by the project owner reviewing [#249](https://github.com/LuchoC-Dev/little-spaceship/pull/249)**, before approving it — the phase working as intended rather than the phase going wrong. They are numbered 4 and 5 because 3 is the coordinator's record, written before they existed.

**All four branches were audited by `reviewer` and all four accepted.** Three with no findings; [#253](https://github.com/LuchoC-Dev/little-spaceship/pull/253) with one documentation finding, corrected below.

## The phase's own result

**Nothing had to be invented, and that is the finding.**

Every piece of this phase already existed in the repository, unused, waiting for the case that invariant 6 requires:

- **A scenario is a level file.** `game/adapter/content/JsonContentSource.java:349` accepts `boss`, `events` and `waves` and rejects everything else, so a file naming one wave placement already *is* "start at that wave" and a file with a boss block already *is* "start at the boss". No format change, no new key.
- **Which level runs was already one field.** `game/LittleSpaceshipGame.java:42`, and its own javadoc had predicted this: *"the day a level-select flow exists, this field is the one place that changes"*. It was.
- **Both halves of the build flavour had precedents.** The `tools` source set in `game/build.gradle.kts`, kept out of `main` because *"TeaVM compiles every class reachable from `main`"*, and the `-Prelease` property in `web/build.gradle.kts`.

The whole phase is 13 files and one afternoon, and it is that small because the design was read out of the code rather than proposed on top of it.

## The absence criterion, and how it was proved

**The criterion was that the test-mode code is absent from the shipped build, not hidden in it.** A runtime boolean would have left `TestMenuScreen` and `TestScenarios` compiled into the published `app.js`, and nobody would have noticed until a stranger found them.

`game/build.gradle.kts` swaps two mutually exclusive source directories — `game/src/tests/java` and `game/src/teststub/java` — which define the same class `TestMode`, one real and one a no-op. `MenuScreen` calls it unconditionally and does not know which one it got.

**`reviewer` went one layer past what was asked and past what the author had checked.** The author verified `game/build/classes/java/main` and `game/build/libs/game.jar`. `reviewer` ran the actual TeaVM compile — `./gradlew :web:gdx_teavm_web_js_build`, noting that the obvious `:web:build` reports `compileTeavmJava NO-SOURCE` and proves nothing — and grepped the emitted `app.js`: **zero occurrences of `TestMenuScreen` or `TestScenarios`, four of the harmless stub.** That is the strongest available evidence and it is stronger than the criterion required.

## Decisions taken while implementing

- **The level format cannot express a starting player state, and no key was invented.** `Simulation.java:66` fixes `PLAYER_INITIAL_SHOT_LEVEL = 1`. `test-boss.json` reaches weapon level 4 through content instead — three overlapping `l1-first-basics` placements whose `weapon-upgrade` drops land before the boss enters at 26.0 s. `reviewer` reconstructed `SpawnSystem.scheduleChain`'s arithmetic by hand and reproduced the author's numbers exactly.
- **The three wave scenarios start cold, at weapon level 1**, on the argument that movement and grouping — what 11i works on — read the same at any weapon level, and that the only available prelude costs ~20 s and contaminates the density under test. **That argument is untested until the owner plays it.**
- **`overrideLevelId(String)` exists in every build, including the published one.** `reviewer` grepped the whole tree: its only caller anywhere is `TestMenuScreen`, which compiles only under `-Ptests`. A real but dead surface, judged acceptable.
- **The scenarios are deliberately not named `level-NN.json`**, because `tools/build-level-docs.js:1027` globs `/^level-\d+\.json$/` and would otherwise have generated a document for each.

## What is open

- **The acceptance criterion no agent can satisfy: the project owner has not played the scenarios.** Neither branch launched the game beyond one start-up check on the TESTS menu, and neither could have — the menu and the scenario files lived on branches that could not see each other until they merged. **Whether each scenario starts where it should is unverified.**
- **Two things for that session specifically.** Whether wave 12 read cold at weapon level 1 is useful or misleading, and whether `test-boss`'s 26.0 s prelude is the right trade — it saves 108 s of the 134.5, and its own basics may still be alive when the boss enters. Both are design calls the owner owns.
- **[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255) — content cannot place a power-up**, only an enemy that carries one. Found while building the boss scenario, when the owner asked for *"at most leave power-ups"* and it turned out not to be expressible. It is why `test-boss.json` starts at weapon level 1.
- **[#252](https://github.com/LuchoC-Dev/little-spaceship/issues/252) — a dropped pickup has no `Motion`** and hangs in the air where its carrier died. Raised by the owner in the same review. **Scheduled to 11i, not here**: it is a game rule with a balance consequence on a level the owner already approved — five drops become five drops that can be missed — and that needs a play verdict rather than an argument.
- **Not checked: the web target**, beyond `reviewer`'s proof that the test-mode classes are absent from `app.js`. `CLAUDE.md` records that headless Chrome cannot validate the web runtime.

## Notes for whoever comes next

**The two branches never saw each other and converged anyway.** `game-presentation` assumed the scenario ids `test-wave-04`, `test-wave-09`, `test-wave-12`, `test-boss` and wrote the assumption down for `level-designer` to reconcile; `level-designer` had already shipped exactly those names. That is a coincidence, not foresight — the coordinator verified it after the fact rather than before, and a different guess would have cost a follow-up branch. **Naming a shared contract in the plan, rather than leaving each side to assume it, is the cheap fix and it was not done here.**

**A second coordinator error, and `reviewer` is what caught it.** Task 5's launch prompt told its agent that the missing standalone-pickup placement was "filed as issue #252". It was not — #252 is a different problem, a dropped pickup having no `Motion`. The agent wrote the number it was given into its status fragment, and `reviewer` found it by **checking the citation against what the issue actually said rather than against what it was called**. The real gap is now [#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255) and the fragment is corrected and dated. **A wrong reference travels further than a wrong sentence**, because the next reader follows it and finds a plausible-looking issue about pickups.

**A coordinator error, recorded rather than corrected quietly.** The phase's opening commit landed **directly on the phase branch** instead of arriving through a documentation pull request — the same mistake phase 11g recorded two days earlier, which makes it a pattern rather than a slip. It was not rewritten: `CLAUDE.md` forbids force-pushing and the branch was already published. What the shortcut bypassed was recovered instead — `tools/pre-pr-check --base origin/dev` was run on the phase branch afterwards and returned **PASS** on all eleven checks. The honest reading is that the check passing does not make the route correct.

**Phase 11i is what this phase exists for.** Movement and grouping: trajectories, formations, entrances, simultaneous pressure. `docs/plan/11c-movement-shapes/shape-catalogue.md` refuses eight shapes with reasons, and one of them — `sine` / weaving — carries its own reopening condition, written before anyone knew it would be needed: *"the first candidate to revisit if 11e plays beat 10 and finds that crossing arcs do not move the safe corridor enough"*. **Read the refusals before proposing a ninth shape.** And note what `docs/levels/level-01.md` shows today: of 61 spawn events, the arc shapes 11c built carry 13, and the rest are descents.
