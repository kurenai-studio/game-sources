# #293 — the TESTS menu loses its first entry after scrolling down and back

## Root cause, confirmed by reproduction

`ScrollPane#scrollTo` only guarantees the *minimal* scroll needed to bring a rectangle into
view — and confirmed against the real `com.badlogic.gdx.scenes.scene2d.ui.ScrollPane` class
(1.14.2), outside this codebase, that minimum can land exactly on the boundary scroll offset where
the target row has **zero** pixels of overlap with the viewport, not one.

Reproduced with a small standalone program (not part of this repo) built against the real
`ScrollPane`/`WidgetGroup` classes, laying out ten fixed-size rows with a trailing gap after every
row — the same shape `MenuEntries.add`'s `cell.padBottom(16f)` builds (issue #276) — inside a
100 px-tall viewport, then driving focus down through all ten rows and back up one row at a time,
calling `scrollTo` exactly as `TestMenuScreen#addScrollingEntry` does. The down pass behaves
correctly throughout. On the up pass, every row from index 8 down to 1 lands with the target row
fully visible — except row 0: `scrollTo`'s own clamp brings the pane's scroll offset to exactly the
value where row 0's rectangle touches the viewport's edge with zero-height overlap, which draws as
"not there at all". Every other row has slack on at least one side of that clamp because it either
still has un-scrolled rows above or below it; only the very first row has no row above it to use as
slack, since it starts already at the top of the content.

**This also answers the acceptance criterion the owner's report left open**: OSCILLATE was
**selectable while invisible, not unreachable**. `MenuNavigator`'s focus state and the `ScrollPane`'s
visual scroll offset are two independent things — `KeyboardFocusable#setFocused(true)` still ran
(`button.setChecked(true)`, the `"> "` prefix, `MenuEntries.activate` still reachable through
`activate()`) regardless of whether `scrollTo` managed to bring the row into view. Pressing Enter
while it was invisible would still have started `test-path-oscillate`.

## Fix

Entirely inside `TestMenuScreen.addScrollingEntry`, in
`game/src/tests/java/dev/luchoc/littlespaceship/game/screen/TestMenuScreen.java`. The very first
entry (`focusables.isEmpty()` at the moment it is added) no longer calls `scrollPane.scrollTo(...)`
on focus; it calls `scrollPane.setScrollY(0f)` instead — the same "pin to the top, don't trust the
minimal-move clamp" guard the constructor already applies once at construction time for the initial
open (issue #276). Every other entry keeps using `scrollTo`, which the reproduction above showed
working correctly for all nine of them in both directions.

`BaseUiScreen`, `MenuEntries` and `MenuNavigator` are untouched — the fix did not need any of them.

Re-ran the same standalone reproduction with this special case applied for row 0: the up pass now
ends at `scrollY = 0.00` exactly (previously `12.00`, with row 0 fully scrolled out), for the same
ten-row, trailing-gap, 100 px-viewport geometry that reproduced the bug.

## What I did not build

A symmetric special case for the *last* entry (BACK) scrolling to `scrollPane.getMaxY()`. The same
reproduction shows the down pass already lands with BACK fully visible and comfortable slack
(4 px short of `maxY` in the reproduction's placeholder geometry, well inside the viewport) — the
asymmetry exists because the last row's rectangle is not the topmost content, so `scrollTo`'s clamp
always has room on at least one side. Nothing in this issue's report or acceptance criteria pointed
at BACK, and the reproduction shows no defect there to fix.

## Verification

**Launched once to confirm the menu starts** (`docs/plan/how-to-run-a-phase.md`, "Running the game
is not playing it") — no navigation, no scrolling, per this issue's explicit instruction not to
repeat the mistake made twice already in this phase.

- `./gradlew.bat build --console=plain` — `BUILD SUCCESSFUL in 5s`.
- `./gradlew.bat :desktop:build -Ptests --console=plain` — `BUILD SUCCESSFUL in 3s`, `:game:compileJava`
  actually ran (not `UP-TO-DATE`/cached), confirming the changed file compiled under the `-Ptests`
  flavour.
- **Absence criterion**:
  - `./gradlew.bat :web:gdx_teavm_web_js_build --console=plain` — `BUILD SUCCESSFUL in 36s`. Then
    `grep -c "TestMenuScreen" web/build/dist/js/webapp/app.js` → `0`;
    `grep -c "TestScenarios" web/build/dist/js/webapp/app.js` → `0`.
  - `unzip -l game/build/libs/game.jar | grep -i "TestMenu\|TestScenarios"` → no match (grep exit
    code 1).
- `./gradlew.bat :desktop:run -Ptests --console=plain`, foregrounded the LWJGL3 window (had to retry
  `SetForegroundWindow` a few times against `AttachThreadInput` before it took — see
  `[[windows-desktop-screenshot-verification]]` in agent memory), screenshotted: the TESTS menu opens
  with `> PATH: OSCILLATE` focused and fully visible at the top, `PATH: TURN`/`MIRROR`/`WAIT`/`LOOP`
  visible below it. Confirms the screen still starts correctly with the fix in place.

**Not checked**: whether scrolling down and back up in the real, running game now shows OSCILLATE —
that requires navigating past the opening screen, which this task's instructions explicitly reserve
for the project owner. To see it: launch `./gradlew.bat :desktop:run -Ptests`, press DOWN eight times
to reach BACK, then press UP eight times back to `PATH: OSCILLATE`; it should be focused and fully
visible at the top of the list, not cut off.

## Acceptance criteria

- Scrolling down and back leaves every entry drawable, the first included: fixed per the argument
  and reproduction above; **not checked on a real run**, per the instructions.
- Said plainly whether the first entry was selectable while invisible or unreachable: **selectable
  while invisible** (see "Root cause" above).
- Absence criterion: holds, both targets, checked above.
- `./gradlew build` green: checked above.
- Shipped screens unchanged: `BaseUiScreen`, `MenuEntries` and `MenuNavigator` were not touched; the
  whole fix is one changed method in `TestMenuScreen`.
