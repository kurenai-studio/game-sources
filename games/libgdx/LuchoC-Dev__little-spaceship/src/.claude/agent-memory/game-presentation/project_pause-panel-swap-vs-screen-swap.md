---
name: pause-panel-swap-vs-screen-swap
description: Why the in-game options panel (#42) swaps PlayScreen's own pause Table in place instead of pushing OptionsScreen, and how MenuNavigator forces a rebuild rather than a resize
metadata:
  type: project
---

`LittleSpaceshipGame#setScreen` disposes the outgoing screen the instant a new one is set (this is
already documented on `OptionsScreen`'s BACK-as-`Supplier<Screen>` choice). That rules out reaching a
full-screen `OptionsScreen` from `PlayScreen`'s pause overlay without either running two `Stage`s at
once or replacing `PlayScreen` itself and tearing down its `Simulation`. The fix that avoids both: keep
one `Table` (`pausePanel`) inside `PlayScreen`'s existing pause `Stage`, and give it two build methods —
`buildPauseMenuPanel()` and `buildPauseOptionsPanel()` — that call `clearChildren()` and repopulate it.
The frozen playfield behind it, and the pointer-lock/input-processor state `pauseGameplay()` already
set, never move.

`MenuNavigator` takes a fixed `List<KeyboardFocusable>` once in its constructor and adds one keyDown
listener straight to the `Stage`'s root — there is no "replace the list" method. Swapping between two
panels with different-length entry lists means constructing a fresh `MenuNavigator` each time, and
`pauseStage.getRoot().clearListeners()` has to run first or the old one keeps intercepting keys
alongside the new one (both fire on every keyDown, since scene2d dispatches to every listener that
returns unhandled up to that point — confirmed by reading `Stage.keyDown`'s dispatch loop, not by
seeing the double-input bug live).

Whichever panel state was open when `pauseGameplay()` is next called must be reset to the main
RESUME/OPTIONS/QUIT state on that same call — otherwise a player who died mid-options resumes into a
volume slider instead of RESUME the next time they pause. Cheapest fix: call the menu-panel builder
unconditionally inside `pauseGameplay()`, before setting the input processor.

See also [[pointer-lock-loss-detection]] — the same `pauseGameplay()` is also the #41 fallback when
pointer lock is lost unexpectedly, so both entry points share this same reset for free.
