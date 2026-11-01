# #276 — the TESTS menu overflows: nine entries do not fit

## What was wrong

`TestScenarios.ALL` (added by #274) lists eight scenarios, plus BACK: nine entries at
`BaseUiScreen`'s 16 px-between-entries layout (`docs/design/04-hud-layout.md`, "Screens" table),
inside a `Table` (`content`) with no `ScrollPane` and no clip. `PATH: WAIT`, `PATH: LOOP` and BACK
sat below the visible 480x270 frame with no way to reach them — two of the four paths phase 11i
exists to demonstrate, and the only way out of the screen.

## Decision: a scrolling list, not a tighter layout and not a cap

The three options from the issue, and why the other two lost:

- **Fitting more (two columns, tighter rows)** is cheaper today but does not solve the actual
  problem — the next scenario `level-designer` or anyone adds to `TestScenarios.ALL` overflows it
  again, just one entry later. This screen's whole reason to exist is that adding a scenario is
  meant to be cheap; a layout that has to be revisited each time a line is added defeats that.
- **A hard cap** is honest about the constraint but actively hostile to that same purpose: it turns
  "add a scenario" into "add a scenario, and hope you're still under the cap, and if not go trim the
  layout again."
- **A scroll** is the only option of the three that holds for any number of entries, which is
  exactly what a menu whose whole job is "list every test scenario" wants. It costs the most
  machinery of the three, but this screen is the one place in the entire flow where an
  unboundedly-growing entry list is the expected shape, so it is also the one place that earns
  that cost. Every other screen in the game (`MenuScreen`, `OptionsScreen`, ship select, pause) has
  a small, fixed number of entries decided once and not revisited — a scroll there would be
  solving a problem those screens do not have.

**Stakes, as the issue asked to note explicitly:** this screen exists only in the `-Ptests` build
flavour and never ships (`TestMode`, `game/build.gradle.kts`; the absence criterion below is what
keeps that true). A `ScrollPane` with no visible scrollbar and no styling beyond
`setScrollingDisabled`/`setOverscroll` would be too plain for a shipped menu; here it is exactly
proportionate; nobody but the agent running `-Ptests` ever sees it, and correctness (every entry
reachable) matters far more than polish.

## What changed, and what did not

Everything lives in `game/src/tests/java/dev/luchoc/littlespaceship/game/screen/TestMenuScreen.java`
only. `BaseUiScreen`, `MenuEntries` and `MenuNavigator` — shared by every screen, shipped ones
included — are untouched:

- The entries now go into their own `Table` (`entries`), wrapped in a `ScrollPane`, which is added
  as `content`'s single child instead of holding the buttons directly. `content.add(scrollPane)`
  still uses the exact same `expand().fill()` `BaseUiScreen` already gave it.
- `MenuEntries.add` is still called once per entry, against `entries` instead of `content` —
  `MenuEntries` itself needed no change.
- A small wrapper (`addScrollingEntry`) decorates each `KeyboardFocusable` `MenuEntries.add` builds:
  gaining focus now also calls `scrollPane.scrollTo(button.getX(), button.getY(), ...)`, so
  navigating with the keyboard keeps the focused entry on screen. `MenuNavigator` needed no change
  either — it never sees the scroll pane, it only sees the same fixed list of focusables it always
  did.

**One real bug found and fixed along the way**, not a design choice: `MenuNavigator`'s constructor
focuses the first entry immediately, before the stage has ever laid anything out, so the first
`scrollTo` call ran against `button.getX()/getY()` still at `(0, 0)` — and scrolling to the
rectangle at `(0, 0)` does not mean "do nothing", it means "show the area near the *bottom* of the
list", because y grows upward in this coordinate system and the last row (BACK) is the one actually
near y = 0. Confirmed on a real launch (see below): the menu opened scrolled to `PATH: LOOP` and
BACK, not WAVE 4. Fixed with `content.validate()` before constructing `MenuNavigator`, so the first
`scrollTo` call runs against real coordinates, plus an explicit `scrollPane.setScrollY(0f)`
immediately after as a second, independent guarantee that the screen always opens scrolled to the
top — not relying on `scrollTo`'s own "minimal distance to make visible" rounding to land exactly
at y = 0 for the very first entry.

## The general question, named and left alone

Whether `BaseUiScreen` itself should stop silently dropping content that overflows `content` — for
every screen, shipped ones included — is the real, general version of this issue. This is the
fourth instance of the same failure shape (`docs/STATUS.md`, "The UI pass, 25/08 — closed"), and
nothing stops a fifth. My own view: the general fix is *not* "wrap `content` in a `ScrollPane` by
default" — a shipped menu should never need to scroll, and a scrollbar appearing on `MenuScreen` or
`OptionsScreen` would itself be a defect, since their entry counts are small, fixed, and known at
design time. The general fix, if one is ever wanted, is closer to `BaseUiScreen` **asserting** that
`content`'s preferred height fits inside the safe area at construction time — failing loudly in a
test or at startup rather than drawing an unreachable BACK button — which turns "a screen quietly
grew past its budget" into a build-time or test-time failure instead of a runtime one nobody
notices until they count entries on a screenshot. That is a change to a shared, shipped class and
belongs to its own issue; not built here, per invariant 6 and per the issue's own instruction not to
fix it in this task.

## Verification

**Launched to confirm the menu renders and every entry is reachable** (`docs/plan/how-to-run-a-phase.md`,
"Running the game is not playing it" — this is exactly what that rule allows). Not played past
opening the entries.

- `./gradlew.bat :desktop:run -Ptests --console=plain`, foregrounded the LWJGL3 window, screenshotted:
  - On open: `WAVE 4` focused (`> WAVE 4`) and visible at the top of the list — confirms the
    `content.validate()` / `setScrollY(0f)` fix; before it, the same launch opened scrolled past
    WAVE 4, into `WAVE 9`.. `PATH: MIRROR`.
  - After eight synthetic `VK_DOWN` presses (via `keybd_event` with the real scan code — see
    `[[windows-desktop-screenshot-verification]]` in agent memory for why the scan code, not the
    virtual-key code, is required to reach a GLFW window): `BACK` focused and fully visible at the
    bottom of the list, with `PATH: TURN`, `PATH: MIRROR`, `PATH: WAIT`, `PATH: LOOP` above it —
    confirms both previously-unreachable path scenarios and BACK are all now reachable.
- `./gradlew build` — `BUILD SUCCESSFUL in 9s`.
- `./gradlew :desktop:build -Ptests` — `BUILD SUCCESSFUL in 4s`, confirms the `-Ptests` flavour
  still compiles clean with the change.
- **Absence criterion, both targets**:
  - `./gradlew :web:gdx_teavm_web_js_build` — `BUILD SUCCESSFUL in 19s`. Then
    `grep -c "TestMenuScreen" web/build/dist/js/webapp/app.js` → `0`;
    `grep -c "TestScenarios" web/build/dist/js/webapp/app.js` → `0`.
  - `unzip -l game/build/libs/game.jar | grep -i "TestMenu\|TestScenarios"` → no match (grep exit
    code 1).

Not checked: the web build under a real browser (no dependency touched here that would change that
answer; `TestMenuScreen`/`TestScenarios` are absent from `app.js` either way, so the question does
not even arise for this change).
