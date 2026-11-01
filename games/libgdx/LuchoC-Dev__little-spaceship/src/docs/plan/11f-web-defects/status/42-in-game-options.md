# Task 3 — #42, in-game options · status

**Branch:** `feat/in-game-options`, against `phase/11f-web-defects`.

## What changed

`game/src/main/java/dev/luchoc/littlespaceship/game/screen/PlayScreen.java`'s pause panel gains an
OPTIONS entry between RESUME and QUIT TO MENU. Activating it swaps the same panel `Table`'s children
in place for a volume-only panel (master, music, effects — each a `Slider` built the same way
`OptionsScreen#addSlider` builds one, minus the percentage label to fit the narrower 200 px panel) with
a BACK entry that swaps back. `buildPauseMenuPanel()` and `buildPauseOptionsPanel()` each rebuild
`pausePanel`'s children and replace the pause `Stage`'s `MenuNavigator`, since `MenuNavigator` owns a
fixed list handed to it once and the two states have different-length lists.

`pauseGameplay()` now always calls `buildPauseMenuPanel()` on entry, so pausing never resumes into a
leftover options panel from a previous pause.

No new screen, no change to `OptionsScreen`, `GameSettings` or `AudioDirector`. No new art — the panel
reuses `n2-panel`/`n1-panel` and `Slider`'s existing skin style, all already used by `OptionsScreen`.

## The two open questions, answered

**1. Inline panel in the pause `Stage`, not `OptionsScreen`.** `OptionsScreen` is a full `Screen`, and
`LittleSpaceshipGame#setScreen` disposes the outgoing screen the instant a new one is set (see that
method's own javadoc and `OptionsScreen`'s BACK-as-`Supplier` comment, which exists for the same
reason). Showing `OptionsScreen` over a paused run would mean either running two `Stage`s
simultaneously or replacing `PlayScreen` outright — the latter would tear down `Simulation` and the run
underneath it just to move a slider. The pause panel's own `Table` already exists and already owns a
frozen playfield behind it; swapping its children in place keeps that playfield frozen, keeps the
pointer-lock and input-processor state exactly as `pauseGameplay()` left it, and leaves nothing to
restore on the way back out. This was the deciding fact, not a style preference.

**2. Only master, music and effects volume.** Issue #42 names volume as the one thing worth reaching
mid-run; nothing else was asked for. Mouse control is excluded because toggling it interacts with a
*live* pointer-lock state (issue #41's own subject) in a way a menu-only toggle never has to — a
different and riskier claim than "a slider changes a number," and testing that claim honestly needs a
real browser, which is outside this task's verification budget. Credits and licences are excluded
because they have nothing to do with a paused run in progress and are already one click away from the
main menu. Both stay exactly where `OptionsScreen` already puts them; nothing was moved out of it.

## Spec change

Recorded in `docs/planning/08-decisions-and-open-items.md`, dated entry "In-game options, 01/09/2026",
right after "Level 1 played, 01/09/2026" and before "Campaign and progression". It states plainly that
this changes what `02-mvp-functional-spec.md`'s "Pause" section says the panel offers (RESUME/QUIT TO
MENU only); the functional spec file itself is left untouched, per instructions not to silently edit it.

## Verified

- `./gradlew build -q` — no output, exit clean (Bash tool reported no errors; ran with `-q` so a clean
  run prints nothing).
- `./gradlew :web:gdx_teavm_web_js_build -q` — compiled and copied assets, including
  `assets/startup-logo.png` into `web/build/dist/js/webapp/assets` (12214 bytes, present both as a
  source file and in the copied output).
- `grep -rn "core\.domain\." game/src desktop/src web/src` — only the two pre-existing
  `core.domain.event` references in `AudioDirector.java`/`Sfx.java`, both already inside the allowed
  `core.domain.event`/`core.port` boundary and untouched by this change. This task added no new import
  from `core`.
- Launched the desktop build once, to confirm the game starts and the main menu renders. Did not
  proceed past that: did not start a run, did not open the pause panel, did not test the OPTIONS entry.

## Not checked

Everything about how the new panel actually behaves on screen. Steps for the project owner:

1. Launch the desktop or web build, PLAY into level 1.
2. Press Escape to pause. The panel should read RESUME / OPTIONS / QUIT TO MENU, same plate as before.
3. Select OPTIONS (Enter, or click). The panel should replace its contents with three volume sliders
   (MASTER VOLUME, MUSIC VOLUME, EFFECTS VOLUME) and a BACK entry, arrow-key/mouse navigable the same
   way `OptionsScreen`'s sliders are.
4. Drag or arrow-key-adjust a slider; on the web target in particular, confirm the volume actually
   changes audibly while the run keeps playing underneath (the playfield should still be visibly
   frozen and dimmed behind the panel).
5. Select BACK. The panel should return to RESUME / OPTIONS / QUIT TO MENU.
6. Select RESUME. The run should continue exactly where it was paused, with the new volume applied.
7. Pause again from a fresh state and confirm it opens on RESUME / OPTIONS / QUIT TO MENU, not on
   whichever panel was open last time.
8. Not checked at all: whether the volume set here persists into a later session the same way it does
   from the main menu's `OptionsScreen` (both write through the same `GameSettings`, so it should, but
   this was not run to confirm), and whether pausing on web through an unexpected pointer-lock loss
   (#41's path, `pauseGameplay()` called from `render()`) still opens on the RESUME state correctly —
   it should, since both entry points share the same `pauseGameplay()`, but only a real browser proves
   it.

## Task 5 (#19, no test suite in `game`)

Not addressed here. Plan lists it as task 5 of this phase, separate from #42; left for whoever picks it
up next, or the coordinator if it is still open when the phase closes.
