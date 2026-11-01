# #305 — PLAY starts the last test scenario instead of level 1

Defect found while phase 11j ran, not one of its three tasks.

## Fix

`LittleSpaceshipGame.levelIdOverride` was set by `TestMenuScreen` (`-Ptests` only) and never
cleared. Added `LittleSpaceshipGame.clearLevelIdOverride()` and call it from `MenuScreen`'s
constructor — `game/src/main/java/dev/luchoc/littlespaceship/game/screen/MenuScreen.java`.

## Where the override is cleared, and why not the other place

The issue named two candidates:

- **When the main menu is entered** (chosen). Covers every path back to the menu, including
  defeat and victory, not only choosing PLAY. One line in `MenuScreen`'s constructor.
- **When PLAY is chosen.** Narrower: it would leave the override live while sitting at the main
  menu, and ties the reset to one specific entry instead of to "you are back at the menu now".
  It would have bought nothing this task needs — nothing currently reads `levelId()` while the
  main menu itself is showing — and it means touching the PLAY lambda specifically rather than
  the screen's own constructor, for no behavioural gain.

Both are equally not-flavour-aware: `levelIdOverride` lives in `LittleSpaceshipGame` (`main`
source set) and is already always `null` outside `-Ptests`, so `clearLevelIdOverride()` is a
no-op there regardless of which call site invokes it. `MenuScreen` gained no test-flavour branch;
it now unconditionally clears a field that a non-test build never sets.

Updated `overrideLevelId`'s javadoc: it no longer claims the override lasts "for the rest of this
run" — it lasts until the main menu is entered again, and now points at
`clearLevelIdOverride()`.

## Acceptance criteria

- After opening a scenario and returning to the menu, PLAY starts level 1: `TestMenuScreen`'s
  BACK entry constructs `new MenuScreen(game)`, whose constructor now clears the override before
  `PLAY`'s own `ShipSelectScreen` → `PlayScreen` path reads `game.levelId()`. Code confirms this;
  not checked on screen — that is the project owner's, per the task.
- Opening a scenario still starts that scenario: `TestMenuScreen`'s scenario entries call
  `game.overrideLevelId(scenario.levelId())` and go straight to `new PlayScreen(game)`, with no
  `MenuScreen` in between — unchanged, so the override is still live when `PlayScreen` reads it.
- `MenuScreen` carries no runtime check for the test flavour: confirmed by reading the diff —
  `clearLevelIdOverride()` is called unconditionally, no `TestMode` reference added.
- `./gradlew build` green: ran locally, `BUILD SUCCESSFUL in 5s`.
- `./gradlew :game:compileJava -Ptests` green: ran locally, `BUILD SUCCESSFUL in 2s`.
- CI green: not checked yet at the time of writing this fragment — see the PR for the run link.

## Verification

Launched `./gradlew :desktop:run` once to confirm the build starts (LWJGL window opened, no
crash); did not play. Per `docs/plan/how-to-run-a-phase.md`, whether the fix behaves correctly on
screen is the project owner's to confirm.
