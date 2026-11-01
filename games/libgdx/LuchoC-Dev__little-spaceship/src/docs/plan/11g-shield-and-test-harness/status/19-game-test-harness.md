# Task 2 — a way to test `game` at all · issue #19 (the unblocked half)

**Branch:** `test/game-test-harness` off `phase/11g-shield-and-test-harness` · **Closes:** nothing — `#19` stays open, its other half stays scheduled to the 12 group per D5 in `docs/plan/11a-rule-asserting-tests/status.md`.

## What the harness is

A JDK dynamic-proxy stand-in for `Gdx.input` and `Gdx.graphics`, committed under `game/src/test/java`:

- `dev.luchoc.littlespaceship.game.testsupport.FakeInput` — an `InvocationHandler` implementing
  `com.badlogic.gdx.Input`. Every method `InputAdapter` calls (`isKeyPressed`, `isKeyJustPressed`,
  `isButtonPressed`, `isButtonJustPressed`, `getDeltaX`, `getDeltaY`, `isCursorCatched`,
  `setCursorCatched`) is backed by mutable state set through fluent builder methods
  (`pressKey`, `justPressKey`, `pressButton`, `justPressButton`, `mouseDelta`). Any other `Input`
  method returns the type's default rather than throwing, so building a proxy for the whole
  interface never requires knowing every method on it.
- `dev.luchoc.littlespaceship.game.testsupport.FakeGraphics` — the same idea, sized to answer only
  `getWidth()`, the one `Graphics` method `InputAdapter` reads.
- `dev.luchoc.littlespaceship.game.adapter.input.InputAdapterTest` — the one real test, assigning
  the proxies to the static `Gdx.input`/`Gdx.graphics` fields directly (the same seam production
  code reads through) and restoring them to `null` in `@AfterEach` so no fake leaks into another
  test class sharing the JVM.

No new dependency: `java.lang.reflect.Proxy` and `InvocationHandler` are JDK, present under TeaVM.
No thread, no clock read, no `Math.random()`. `Gdx.input`/`Gdx.graphics` are confirmed interfaces
with no abstract method count that would force implementing more than the handler dispatches
(checked with `javap -classpath gdx-1.14.2.jar com.badlogic.gdx.Input`/`Graphics`, both printed
`public interface`). `com.badlogic.gdx.utils.viewport.Viewport` has no abstract methods of its own
(`javap` on it lists none), so the test builds a bare `new Viewport() {}` and sets world width/height
directly — no camera, no LWJGL, no display.

## Why this shape

Phase 03's two throwaway programs already proved the technique works (`docs/plan/03-first-playable/status.md`):
input summing and cancellation, verified against the real `InputAdapter`, with `Gdx.input`/
`Gdx.graphics` proxied the same way. The defect was never the technique — it was that neither
program was committed. This task is that same technique, moved into `game/src/test/java` where
`./gradlew build` runs it every time. No new mocking library was added: JDK dynamic proxies need
none, which is part of why phase 03 reached for them in the first place and why D5 called this path
"not blocked" independent of the `JsonContentSource` question.

## The one real test, and the rule it defends

`InputAdapterTest` has two cases:

1. **`keyboardAloneReachesTopSpeed`** — a key held alone drives the ship at exactly
   `balance.playerSpeed()`, proving the harness actually reaches `InputAdapter.sample()`'s real
   keyboard path.
2. **`keyboardAndMouseCancelExactly`** — a keyboard hold and an opposing mouse delta, chosen so
   their contributions match in magnitude, cancel to `(0, 0)`. This is `InputAdapter`'s own javadoc
   claim and the additive-devices rule from `10-mvp-initial-values.md`: two input devices are summed
   before the core ever sees them, so holding them in opposite directions leaves the ship still
   instead of one device silently overriding the other. This is the same rule phase 03's second
   throwaway program checked and never committed.

## Evidence the harness can fail

Changed the first test's expected `moveX` from `140f` to `999f` and reran
`./gradlew :game:test --tests "*InputAdapterTest*"`: it failed —
`InputAdapterTest > keyboard alone drives the ship at the balance-defined top speed FAILED,
org.opentest4j.AssertionFailedError at InputAdapterTest.java:62`, `2 tests completed, 1 failed`,
`BUILD FAILED`. Reverted the line back to `140f` and reran; it passed again. The harness is not a
test that cannot fail.

## Test counts

- `game` module: **0 tests before this branch, 2 after** — confirmed by
  `game/build/test-results/test/TEST-...InputAdapterTest.xml`, `tests="2" failures="0" errors="0"`.
- `core` module: unaffected — **332 tests**, `core/build/test-results/test/*.xml`, all still green
  under the same `./gradlew build` run.
- `./gradlew build` ran clean end to end (all six subprojects: `core`, `game`, `desktop`, `web`,
  `rngparity`), `BUILD SUCCESSFUL`, and it exercised `:game:test` as part of `:game:check`.

## What it cannot do

- It does not test rendering, `WorldRenderer`, `PixelPerfectViewport`'s resize behaviour, or
  anything that needs an actual `GL20`/`SpriteBatch` — those touch native code this proxy technique
  cannot stand in for. A `Viewport` subclass works here only because `InputAdapter` calls exactly
  one no-op-safe method (`getWorldWidth()`) on it.
- It does not cover `JsonContentSource`, `JsonBalanceValues`'s parsing path, or any `FileHandle`
  reader — deliberately out of scope, scheduled to the 12 group per D5.
- It proves the harness works for `Input`/`Graphics`. Whether the same proxy approach extends
  cleanly to `Audio`, `Files`, or other libGDX interfaces `game` also touches is not checked here —
  the next person reaching for one of those should confirm the interface has no method the fake
  needs to answer non-trivially before assuming the same pattern applies for free.

## What the next person needs

- To test `JsonContentSource`/`JsonBalanceValues`'s error paths (the other half of #19, 12 group):
  reuse `FileHandle` directly rather than proxying it — `com.badlogic.gdx.files.FileHandle` is a
  concrete class backed by a real `java.io.File`/classpath resource in the headless case, not an
  interface, so it needs no proxy; a real temp file with malformed JSON is the more direct fixture.
  Not checked here — this task's scope stopped at `Input`/`Graphics`.
- `FakeInput`/`FakeGraphics` are reusable as-is for any future `game` test touching those two
  interfaces; extend them (new builder methods) rather than duplicating the proxy-construction
  boilerplate.
- Remember to null out any `Gdx.*` static field a test assigns, in `@AfterEach`, exactly as
  `InputAdapterTest` does — these are shared JVM-wide statics, not instance state.

## What was not checked

- Whether the same technique works for TeaVM's own `Input`/`Graphics` backend specifically — this
  test runs on the JVM only, under `./gradlew :game:test`, never compiled through TeaVM. `game`'s
  test source set is not part of the `web` module's TeaVM compilation, so this is not something the
  web build would catch either way. Not checked.
- Whether a human moving a physical mouse behaves identically to the synthetic deltas used here —
  same gap phase 03 already recorded as open.
