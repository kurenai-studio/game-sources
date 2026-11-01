---
name: scrollpane-scrollto-boundary-and-headless-repro
description: ScrollPane#scrollTo can leave a rect with zero-pixel overlap for the topmost row of a list with trailing per-row gaps; how to reproduce gdx scene2d.ui geometry bugs outside the game without a GL context
metadata:
  type: project
---

Issue #293: the TESTS menu's first entry (`PATH: OSCILLATE`) went fully invisible after scrolling
down and back up with the keyboard, even though `TestMenuScreen.addScrollingEntry`'s `scrollTo`
call looked correct and matched every other row's.

**`ScrollPane#scrollTo(x, y, w, h)` only promises the minimal scroll needed to make the rectangle
"in view"**, and its own clamp formula (`amountY = clamp(current, y+height, y+actorArea.height)` —
gdx 1.14.2 source) can resolve to the exact boundary where the target rectangle touches the
viewport edge with **zero-height overlap**, not the nearest position that shows even one pixel of
it. Every row got away with it except the very first, because every other row still has slack on
at least one side of the clamp (there is always another row above or below still partly in view to
absorb the rounding); row 0 has nothing above it, so it is the one row where the boundary case is
reachable by ordinary keyboard navigation. This is a property of the real `ScrollPane` class, not
of anything project-specific — the trailing `padBottom` per row (`MenuEntries.add`, from #276) sets
up the exact geometry that triggers it, but any list where the topmost row's own rect excludes
padding above it can hit this.

**Fix pattern**: don't trust `scrollTo` for the first entry specifically — call
`scrollPane.setScrollY(0f)` on its focus instead, mirroring the "pin to a known-good absolute
position" guard #276 already used once at construction time. A `scrollPane.setScrollY(maxY)`
symmetric case for the *last* entry was considered and explicitly not built: the same reproduction
below showed the down pass already lands with the last row comfortably inside the viewport, no
boundary case reachable there.

**How to reproduce a scene2d.ui layout/scroll bug without touching the game or a GL context**:
`ScrollPane`, `WidgetGroup`, `Actor` and their `layout()`/`validate()`/`scrollTo()` machinery run
on pure math, no OpenGL calls, but three things are needed to run them standalone:
1. `Gdx.app` must be non-null or `Timer.Task`'s constructor (reached indirectly through
   `ScrollPane`'s flick-scroll `GestureDetector`) throws `IllegalStateException`. A JDK dynamic
   proxy of `com.badlogic.gdx.Application` returning defaults (`false`/`0`/`null`) is enough —
   same trick as the existing `Gdx.input`/`Gdx.graphics` proxy note for this project.
2. Do not build the scrolled content with a real `Table`/`Cell` outside a running application:
   `Cell.defaults()` recurses infinitely (`StackOverflowError`) without one, for reasons not worth
   chasing down. Extend `WidgetGroup` directly instead, override `layout()`/`getPrefWidth()`/
   `getPrefHeight()`, and position the fake row actors by hand with `setPosition` — this sidesteps
   `Cell` entirely and still exercises the exact `ScrollPane` code path being tested.
3. Compile against `gdx-1.14.2.jar` alone (found via `find "$HOME/.gradle" -iname "gdx-*.jar"`),
   `javac`/`java` directly, no Gradle project needed for a five-minute throwaway repro.

This is a different, narrower case than "playing the game to verify a fix"
(`[[agent-must-not-play-the-game-to-verify]]`): the repro program is not the game and answers the
mechanism question by argument and a standalone program, exactly what that rule asks for instead of
navigating the real screen.
