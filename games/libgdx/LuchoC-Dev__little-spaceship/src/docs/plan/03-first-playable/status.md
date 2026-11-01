# Phase 03 — First playable · status

**State:** done — both criteria that were waiting on phase 04 are now earned
**Updated:** 20/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Acceptance criteria against `plan.md` — read this first

| Criterion | Status | Why |
|---|---|---|
| `./gradlew :desktop:run` opens the game and the ship responds to keyboard and mouse | **met** | Opens cleanly, no exception (`timeout 20 ./gradlew :desktop:run`, killed by the timeout, no stack trace). The ship now exists from tick zero (phase 04's `Simulation` fix) and `InputAdapter.sample()` is called every render frame and fed through `GameLoop.advance` into the real pipeline. Verified headlessly with the actual production classes — not a display, but not "probably works" either — see "How the two blocked criteria were verified" below. |
| Moving mouse right and pressing left at once leaves the ship still | **met** | `InputAdapter`'s real `sample()` method, called with `Gdx.input`/`Gdx.graphics` replaced by JDK dynamic proxies (keyboard LEFT held, a mouse `getDeltaX()` of 7px), returns `InputFrame(moveX=0.0, moveY=0.0, ...)` exactly. See below for the full method and output. |
| The window scales at x2, x3 and x4 with no blurring and no fractional scaling | **implemented, unverifiable without a display** | Unchanged from before: `PixelPerfectViewport` computes an integer-only scale, `resize()` is wired, but nobody has watched a window being resized to confirm no blur. Left as-is on explicit instruction not to upgrade a row that has not genuinely been observed. |
| A checkerboard test texture shows no distortion at any window size | **implemented, unverifiable without a display** | Same as above. |
| Nothing in `game` reads or writes ECS components directly | **met** | `grep -rn "core\.domain\." game/src desktop/src web/src` returns zero matches, re-checked after this round's changes. |
| The render loop allocates nothing per frame | **met by code inspection, not measured** | Unchanged: `WorldRenderer` implements `SpriteVisitor` on itself; the atlas now covers seven sprites instead of one but still builds its texture once, in the constructor. No profiler was run. |

## How the two blocked criteria were verified

Phase 04's `core` side landed (`Simulation`'s constructor now spawns the player from tick zero, and a new 4-argument overload wires `SpawnSystem`), and its `game`-side loader — the piece the coordinator asked for in this same round, closing GitHub issue #18 — gave `LittleSpaceshipGame` a real `ContentSource` and a level id to pass. Full detail on the loader itself is in `docs/plan/04-content-pipeline/status.md`; this section only covers what that unblocked here.

Two small headless programs, run against the actual shipped classes (not a reimplementation of their logic), because this session still has no display to watch a window with:

**1. The world is not empty.** A program builds a real `JsonContentSource` from `assets/data/`, a real `Simulation` with `JsonContentSource.LEVEL_ID`, ticks it for 660 steps (11 simulated seconds) with `InputFrame.IDLE`, and walks `WorldView.forEachSprite`. Output:

```
Loaded content OK. Balance playerStartX=104.0 playerStartY=30.0
Entities after 11s: 11
  ship-basic@(104.0,30.0)
  enemy-basic@(84.0,95.799164)
  enemy-basic@(104.0,95.799164)
  enemy-basic@(124.0,95.799164)
  enemy-light@(-53.233418,-14.833385)
  ... (all six archetypes present, positions matching their scripted trajectories)
```

The player exists at exactly `balance.json`'s `playerStartX`/`playerStartY`, and all six level 1 archetypes spawn from `level-01.json`'s timeline at the scheduled times. This is the same proof `LevelContentIntegrationTest` already gives inside `core`, run here through `game`'s actual JSON files and loader instead of an inline test fixture.

**2. Keyboard and mouse really do sum, and really do cancel.** `Gdx.input` and `Gdx.graphics` are both interfaces; a JDK dynamic proxy (`java.lang.reflect.Proxy`) stands in for each, since none of the methods `InputAdapter` calls (`isKeyPressed`, `getDeltaX`, `getWidth`) touch native code — no LWJGL, no `Application`, no display needed. The real `InputAdapter.sample()` is called three times:

```
keyboard RIGHT alone: moveX=140.0
mouse alone (dx=7px): moveX=140.0
```
```
moveX=0.0 moveY=0.0
PASS: keyboard LEFT and an opposing mouse delta cancel to a still ship.
```

Both devices alone produce the ship's full top speed (140 units/s, `balance.json`'s `playerSpeed`); held in opposite directions with the mouse delta chosen to match the keyboard's magnitude exactly, they sum to precisely zero — the rule `10-mvp-initial-values.md` states ("the same intensity" is what the mouse delta was chosen to produce) and `InputAdapter`'s javadoc has claimed since phase 03 first shipped it, now actually exercised rather than only read.

**What this does not prove:** that a human moving a physical mouse while a window is on screen produces the same result pixel-for-pixel, or that the window itself renders without visual artifacts. That gap is real and stays open — it is exactly the two rows above still marked "unverifiable without a display."

## Done (unchanged from before this round)

Everything already reported: desktop launcher, `InputAdapter`'s summing logic, `WorldRenderer`/`PixelPerfectViewport`/`PlaceholderAtlas`/`CheckerboardBackground`, `assets/startup-logo.png`, the composition root. See git history for the original detail; this file no longer repeats it now that the acceptance table above supersedes the earlier "waiting on phase 04" framing.

## What changed this round

- **`JsonContentSource`, `JsonBalanceValues`, `JsonComponentSpecs`** (`game/adapter/content/`) replace the old `PlaceholderContentSource`/`PlaceholderBalanceValues` — phase 04's loader, detailed in `docs/plan/04-content-pipeline/status.md`.
- **`assets/data/*.json`** — the five content files.
- **A real bug found and fixed: `WorldRenderer` was not translating `Transform.x` from playfield-local `[0, 208]` coordinates into the logical 480-wide resolution.** Invisible while the world was empty (phase 03), would have put every entity 136 units too far left the instant one existed (phase 04). Fixed by adding `playfieldLeft` to `WorldRenderer`'s constructor and applying it in `accept()`. `y` needed no equivalent fix — the playfield is the full 270-unit logical height.
- **`PlaceholderAtlas`** grew the six enemy archetypes at their exact sizes from `docs/design/02-sprite-sizes.md`, in the same one-texture atlas.
- **`LittleSpaceshipGame`** now builds `JsonContentSource` from `Gdx.files.internal("data")` and passes `JsonContentSource.LEVEL_ID` to `Simulation`'s 4-argument constructor.

## Verification performed this round

| Check | How | Result |
|---|---|---|
| `./gradlew build` | ran | succeeds; `core` at 167 tests, all passing |
| `./gradlew :desktop:run` | ran, 20s, killed by timeout | opens, no exception |
| World is non-empty after content loads | headless program against real `JsonContentSource`/`Simulation` | player + all six archetypes present, positions match their trajectories |
| `InputAdapter` responds to each device alone | headless program against real `InputAdapter`, `Gdx.input`/`Gdx.graphics` proxied | keyboard alone and mouse alone both produce `moveX=140.0` |
| `InputAdapter` cancels opposing keyboard+mouse | same method | `moveX=0.0, moveY=0.0` exactly |
| No `core.domain` import in `game`/`desktop`/`web` | `grep -rn "core\.domain\." game/src desktop/src web/src` | zero matches |
| Integer scaling / checkerboard distortion | not observed | still no display in this session; rows left unverified as instructed |

## Notes for whoever comes next

- **The playfield x-offset fix matters for anyone adding a new renderer path.** Any code that reads `Transform.x`/`Transform.y` directly from `core` and draws it must add `playfieldLeft` (136 logical units) to `x` first. `y` needs nothing. `WorldRenderer` is the one place this happens today.
- **The two headless verification programs are throwaway, not committed.** They live in this session's scratch directory, not the repository — `test-engineer` may want to turn the `InputAdapter` one into a real test with a proper mocking approach, since `JDK dynamic proxies over Gdx.input/Gdx.graphics` is a viable pattern for testing input code without a display, now proven to work for the methods `InputAdapter` actually calls.
- **`InputAdapter` still has no committed unit test.** Same note as before this round — it is exercised by the desktop build and, now, by an ad hoc headless check, but not by anything in the repository's own test suite.
