# 11h task 1 — a test build flavour and the TESTS menu · status

**Issue:** #244 · **Branch:** `feat/test-build-flavour` · **Owner:** `game-presentation`

## What I built

`-Ptests` on any Gradle invocation makes `game/build.gradle.kts` add `game/src/tests/java` to
the `main` source set instead of `game/src/teststub/java`. Both directories define the same class,
`dev.luchoc.littlespaceship.game.screen.TestMode`, package-private, with one static method,
`addMenuEntry(Table, LittleSpaceshipGame, Skin, List<KeyboardFocusable>)`. `MenuScreen` calls it
unconditionally, right after OPTIONS:

- **Stub** (`src/teststub/java`, compiled whenever `-Ptests` is absent): the method body is empty.
  This is the only trace of the flavour in every build that reaches a player.
- **Real** (`src/tests/java`, compiled only with `-Ptests`): adds a TESTS entry that opens
  `TestMenuScreen`, also under `src/tests/java`, alongside `TestScenarios` (the hardcoded list of
  four `(levelId, label)` pairs).

`TestMenuScreen` lists the four scenarios plus BACK, following `MenuEntries`/`MenuNavigator`
exactly as every other screen does. Choosing a scenario calls a new method,
`LittleSpaceshipGame.overrideLevelId(String)` (in `main`, always present — a small, generic seam,
not test-mode code itself; its javadoc says the ordinary build never calls it), then opens
`PlayScreen` directly, skipping `ShipSelectScreen` — a scenario's starting weapon/lives/bombs is
the level file's own decision, per the plan, not something this screen should re-offer.

## Why a mutually exclusive pair of source directories, not `-Prelease`'s single flag

`web/build.gradle.kts`'s `-Prelease` only changes *how* the same source is compiled (optimisation
level). This task's criterion is that the ordinary build's compiled output contains **no trace** of
the test screens — not merely that they're unreachable at runtime. A runtime `if (testMode)` check
would still put `TestMenuScreen.class` and `TestScenarios.class` inside `game.jar` and therefore
inside `:web`'s TeaVM-compiled `app.js` on every build, since TeaVM walks everything reachable from
`main`. Two mutually exclusive source directories, following the `tools` source-set precedent
(kept out of `main` for the same reachability reason), make the classes literally not exist in the
compilation unless `-Ptests` is passed — verified by inspecting the compiled output, not by reading
the code (see below).

I considered putting the stub/real split behind a single `TestMode.java` in `src/main/java` with
`sourceSets.main.java.exclude(...)` toggled by the property, but `exclude` patterns apply to the
whole merged `SourceDirectorySet`, not per source directory — excluding `**/screen/TestMode.java`
would exclude the real variant too if it lived at the same relative path. Two independent
directories, only one of which is ever added, avoids that collision entirely and needs no
`exclude` at all.

## The naming convention I assumed for scenario ids

`level-designer` is writing the four scenario files in parallel and the plan does not name their
ids. I assumed, and hardcoded in `TestScenarios`:

| Scenario | assumed levelId |
|---|---|
| Wave 4 | `test-wave-04` |
| Wave 9 | `test-wave-09` |
| Wave 12 | `test-wave-12` |
| The boss | `test-boss` |

If `level-designer`'s files use different ids, only `TestScenarios.ALL` needs to change — one
list, four lines.

## Observations (not claims)

- `./gradlew clean :game:compileJava` (no property), then `find game/build/classes/java/main
  -iname "TestMenu*" -o -iname "TestScenarios*"` — **no output**: absent.
- `./gradlew clean :game:compileJava -Ptests`, same `find` — printed
  `TestMenuScreen.class`, `TestScenarios$Scenario.class`, `TestScenarios.class`: present.
- `./gradlew clean build` (no property) then `unzip -l game/build/libs/game.jar | grep -i test` —
  printed exactly one line, `dev/luchoc/littlespaceship/game/screen/TestMode.class` (the stub).
  No `TestMenuScreen` or `TestScenarios` in the jar `:desktop` and `:web` both depend on.
- `./gradlew build` (no property): **BUILD SUCCESSFUL**, all modules including `:web`.
- Launched `:desktop:run -Ptests` once, screenshotted the main menu: PLAY / OPTIONS / TESTS / QUIT
  render in that order, TESTS between OPTIONS and QUIT. Did not click into TESTS or any scenario —
  that would start gameplay, which is the project owner's to judge, not mine. Killed the process
  immediately after the screenshot. This was the one launch this task used; I did not also launch
  the ordinary (no-property) build, since its absence of test-mode code was already established by
  inspecting the jar above, and the rule allows at most one launch.
- Did not check: whether each of the four scenarios actually starts and plays correctly — the
  scenario files do not exist on this branch (`level-designer`'s task, in parallel); whether the
  web target happens to run with `-Ptests` — not checked, and per the plan not a deliverable.
- `docs/levels/level-01.md` regeneration: not touched by this task since `assets/data/level-01.json`
  was not touched; not re-run here since level-designer's scenario files, which are the ones that
  interact with the generator, don't exist on this branch yet.

## What's open for the next person

- If `level-designer`'s scenario ids differ from the four assumed above, `TestScenarios.ALL` is the
  one place to fix.
- Task 3 (the record in `docs/planning/08-decisions-and-open-items.md`) is the coordinator's, at
  close.
