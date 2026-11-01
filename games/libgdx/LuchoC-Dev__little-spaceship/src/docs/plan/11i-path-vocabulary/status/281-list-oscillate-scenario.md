# 281 — The TESTS menu is missing PATH: OSCILLATE

**Done by the coordinator**, on `feat/list-oscillate-scenario`. One line.

`assets/data/test-path-oscillate.json` shipped with #278 and could not be opened: `TestScenarios.ALL` is a hardcoded list in `game/src/tests/java/`, which belongs to `game-presentation`. `level-designer` stopped at the boundary and named the id and the label in its fragment instead of crossing, which is the correct behaviour and the third time in this phase it has cost a round trip.

## Verified

- `./gradlew build` — green.
- **Every menu entry has its file.** Cross-checked each `new Scenario("<id>", ...)` in `TestScenarios.java` against `assets/data/<id>.json`: nine entries, nine files. This is the check no single branch can run, because the menu and the content always live on branches that cannot see each other.
- **The absence criterion still holds.** `unzip -l game/build/libs/game.jar | grep -ci "TestMenuScreen\|TestScenarios"` on a build with no `-Ptests` prints `0`.

## Not checked

How the oscillation looks. The project owner's, and the reason the entry exists.

## The finding, which is not the fix

**Three round trips in one phase.** [#274](https://github.com/LuchoC-Dev/little-spaceship/issues/274) already asked whether the list should be discovered from `assets/data/test-*.json` rather than hardcoded, and deliberately left it undecided — adding a discovery mechanism mid-phase is what invariant 6 exists to slow down.

It is now a measured cost rather than a prediction: **every scenario needs a code change by a different agent than the one who wrote it.** Phase 11h chose the hardcoded list for four fixed entries and was right; the list is now nine. It goes to 11j with the other vocabulary questions.
