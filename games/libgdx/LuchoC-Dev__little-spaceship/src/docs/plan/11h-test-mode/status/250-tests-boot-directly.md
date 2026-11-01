# 11h issue #250 — `-Ptests` boots straight into the TESTS menu · status

**Issue:** #250 · **Branch:** `feat/tests-boot-directly` · **Owner:** `game-presentation`

Correction the project owner asked for after reviewing PR #249, not new scope: the `-Ptests`
build was showing the ordinary main menu with a TESTS entry, when the build is run for exactly
one purpose and the main menu is a step with no reason to exist in it.

## What I changed

Extended the `TestMode` seam from task 1 (issue #244) with a second static method,
`startScreen(LittleSpaceshipGame)`, following the same "stub answers no, real answers yes" shape
as `addMenuEntry`:

- **Stub** (`game/src/teststub/java`, compiled whenever `-Ptests` is absent): returns `null`,
  meaning "no test mode".
- **Real** (`game/src/tests/java`, compiled only with `-Ptests`): returns `new TestMenuScreen(game)`.

`LittleSpaceshipGame.create()` now reads that before falling back to `MenuScreen`:

```java
Screen testScreen = TestMode.startScreen(this);
setScreen(testScreen != null ? testScreen : new MenuScreen(this));
```

No second mechanism, no runtime flag check in `create()` itself — the same absence-by-source-set
guarantee task 1 established still holds, because the branch lives entirely inside which
`TestMode.java` Gradle compiles.

`TestMode` had to become `public` (it was package-private) so `LittleSpaceshipGame`, in a
different package, can call `startScreen`. `addMenuEntry` stays package-private; only the method
that crosses the package boundary needed the wider visibility.

## Where BACK/ESC lead now — decided, not accidental

**Only the startup edge changes.** Every other path that used to lead to `MenuScreen` still does:

- `TestMenuScreen`'s own BACK entry: unchanged, still `new MenuScreen(game)`.
- `PlayScreen`'s pause menu "QUIT TO MENU", `DefeatScreen`, `VictoryScreen`'s "CONTINUE",
  `ShipSelectScreen`'s BACK, `FarewellScreen`'s "BACK TO MENU": all untouched, all in `main`, all
  still resolve to the ordinary `MenuScreen`.

This is deliberate rather than an oversight: `MenuScreen` still exists and still carries the TESTS
entry in the `-Ptests` flavour (via `TestMode.addMenuEntry`, unchanged from task 1), so BACK never
strands the tester — it is one more click from any of those screens back to TESTS. The alternative
— rerouting every one of those five navigation edges to `TestMenuScreen` instead — would have
meant threading test-mode awareness into `PlayScreen`, `DefeatScreen`, `VictoryScreen` and
`ShipSelectScreen`, all `main`-source-set files shared by both build flavours, for a benefit (one
fewer click, only in a flavour nobody but the project owner runs) the plan never asked for. Only
the one place named in the issue — `LittleSpaceshipGame.create()` — changes.

Documented in `TestMenuScreen`'s class javadoc so the next reader does not have to reconstruct
this from the diff.

## Observations (not claims)

- `./gradlew clean :game:compileJava -Ptests` — **BUILD SUCCESSFUL**. Both `TestMode.startScreen`
  variants and the changed `LittleSpaceshipGame` compile together with the real flavour.
- `./gradlew clean :game:compileJava` (no property) — **BUILD SUCCESSFUL**. Same file compiles
  against the stub flavour.
- `./gradlew build` (no property) — **BUILD SUCCESSFUL**, all modules including `:web`.
- `unzip -l game/build/libs/game.jar | grep -i test` (built by the plain `./gradlew build` above,
  no property) — printed exactly one line, `dev/luchoc/littlespaceship/game/screen/TestMode.class`
  (the stub). No `TestMenuScreen` or `TestScenarios` in the jar `:desktop` and `:web` both depend
  on — same result task 1's fragment recorded, unaffected by this change.
- `./gradlew :web:gdx_teavm_web_js_build` (not `:web:build`, which reports `compileTeavmJava
  NO-SOURCE` and proves nothing) — **BUILD SUCCESSFUL**.
- `grep -io "TestMenuScreen\|TestScenarios" web/build/dist/js/webapp/app.js | sort | uniq -c` —
  **no output**: neither name appears anywhere in the emitted `app.js`. Absence holds after this
  change, the same as before it.
- Launched `:desktop:run -Ptests` once (the one launch this task used), waited ~6s, foregrounded
  the window and screenshotted it: the screen shown at startup is TESTS — WAVE 4 / WAVE 9 /
  WAVE 12 / BOSS / BACK, WAVE 4 focused — with no main menu screen ever shown first. Did not click
  into any scenario and did not launch the ordinary (no-property) build separately, since its
  absence of test-mode code was already established by inspecting the jar and `app.js` above, and
  a second launch was not needed to observe what those files already show.
- Did not check: whether each scenario still starts and plays correctly from this new entry point
  — that would mean playing, which is the project owner's job, not mine.

## What's unchanged

Task 1's file, `docs/plan/11h-test-mode/status/244-test-build-flavour.md`, still describes
everything else about the mechanism accurately: the mutually-exclusive source directories, the
`addMenuEntry` half of the seam, the scenario ids, the reasoning for two source sets over a
runtime flag. This fragment only adds the `startScreen` half and the startup-navigation decision
the project owner asked for.
