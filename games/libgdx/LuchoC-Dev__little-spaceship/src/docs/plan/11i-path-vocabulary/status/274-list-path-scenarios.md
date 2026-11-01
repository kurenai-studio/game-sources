# 274 — list the four path scenarios in the TESTS menu · status

**Issue:** #274 · **Branch:** `feat/list-path-scenarios` · **Owner:** `game-presentation`

A defect found while phase 11i runs, reported by `level-designer` on
[#271](https://github.com/LuchoC-Dev/little-spaceship/issues/271): task 3 shipped four path
scenario files but the TESTS menu's list was hardcoded in `game/`, so `level-designer` could not
add them and correctly stopped and reported instead of crossing into a module it does not own.

## What I built

Four entries added to `TestScenarios.ALL` in
`game/src/tests/java/dev/luchoc/littlespaceship/game/screen/TestScenarios.java`, using
`level-designer`'s own suggested labels from
`docs/plan/11i-path-vocabulary/status/271-path-entries.md` (read via
`git show origin/feat/path-entries:...`, since that branch is not merged):

```java
new Scenario("test-path-turn", "PATH: TURN"),
new Scenario("test-path-mirror", "PATH: MIRROR"),
new Scenario("test-path-wait", "PATH: WAIT"),
new Scenario("test-path-loop", "PATH: LOOP")
```

The class javadoc was extended to name the four new ids alongside the existing four, so the next
reader does not have to reconstruct the assumption from the diff.

## What I could not check

**The four scenario files live on `feat/path-entries`, which is not merged into this branch or
into the phase branch yet.** My branch (`feat/list-path-scenarios`, from `phase/11i-path-vocabulary`)
has no `assets/data/test-path-*.json`. I added the ids by contract only — they are fixed by
`level-designer`'s fragment, not discovered from files that exist here. **The coordinator must
verify the pairing (the four ids resolve to the four files, and each of the four new menu entries
actually starts) once both branches are merged into the phase branch.** Until then this branch's
own `-Ptests` build lists eight menu entries, but four of them would fail to load a level file if
launched in isolation on this branch — not checked, because doing so would require content this
branch does not own and is not supposed to add.

## Worth deciding, not building

This is the second time (after phase 11h shipping four fixed entries, then `level-designer` hitting
the same wall on #271) that a hardcoded `List.of(...)` in `game/` has meant a scenario written by
one agent needs a code change by a different one to become reachable. I think it is worth
discovering the list from `assets/data/test-*.json` instead — turning "add a scenario" into a pure
content change, which is what actually gets a tool used repeatedly. I did not build it: it is a real
architectural change to a test-only seam, mid-phase, and invariant 6 exists precisely to slow that
down until there is a third or fourth confirmed case rather than a second.

## Observations (not claims)

- `./gradlew clean build` (no property) — **BUILD SUCCESSFUL**, all modules including `:web`.
- `unzip -l game/build/libs/game.jar | grep -i test` (built by the plain `./gradlew clean build`
  above) — printed exactly one line, `dev/luchoc/littlespaceship/game/screen/TestMode.class` (the
  stub). No `TestMenuScreen` or `TestScenarios` in the jar `:desktop` and `:web` both depend on.
- `./gradlew :web:gdx_teavm_web_js_build` (not `:web:build`, which reports `compileTeavmJava
  NO-SOURCE` and proves nothing) — **BUILD SUCCESSFUL**.
- `grep -io "TestMenuScreen\|TestScenarios" web/build/dist/js/webapp/app.js | sort | uniq -c` — no
  output: neither name appears anywhere in the emitted `app.js`. Absence holds after adding the four
  entries, same as before.
- `./gradlew clean :game:compileJava -Ptests`, then `find game/build/classes/java/main -iname
  "TestMenu*" -o -iname "TestScenarios*"` — printed `TestMenuScreen.class`,
  `TestScenarios$Scenario.class`, `TestScenarios.class`: present with the property.
- Launched `:desktop:run -Ptests` once (the one launch this task used), foregrounded the window and
  screenshotted it: the TESTS menu lists, in order, WAVE 4 (focused), WAVE 9, WAVE 12, BOSS, PATH:
  TURN, PATH: MIRROR, with PATH: WAIT and PATH: LOOP scrolled below the visible fold (the list is
  taller than the window at eight entries plus BACK, unchanged UI behaviour from phase 11h — a
  `MenuNavigator` list, not a new scroll concern this task introduces). Did not click into any
  scenario — that would start gameplay, which is the project owner's to judge, not mine, and per
  the rule for this issue I may not play the path scenarios at all. Killed the process immediately
  after the screenshot.
- **Not checked**: whether each of the four new scenarios actually starts and loads its level file
  — the scenario files are not present on this branch (see above); the coordinator verifies this
  after both branches merge. **Not checked**: how any of the four paths looks — that is the entire
  point of the phase and it is the project owner's to judge, not mine.

## What's open for the coordinator

- Merge `feat/path-entries` (#271) and this branch (#274) into `phase/11i-path-vocabulary`, then
  relaunch `:desktop:run -Ptests` once and confirm each of the four new PATH entries starts without
  error. That launch is the one this fragment could not make.
