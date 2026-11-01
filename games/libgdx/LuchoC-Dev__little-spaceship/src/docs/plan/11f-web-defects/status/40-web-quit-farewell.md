# Task 1 — #40 QUIT does nothing on the web target

**Branch:** `feat/web-quit-farewell` · **Closes:** [#40](https://github.com/LuchoC-Dev/little-spaceship/issues/40)

## Decision (taken by the project owner on 01/09/2026, not by this agent)

> On the web target, QUIT keeps its slot but means something else: it leads to a farewell screen — a
> "thanks for playing" — with a way back to the menu.

Chosen over hiding the entry on web (the two targets would then show different menus) and over
repurposing the slot as a fullscreen toggle. **On desktop, QUIT still exits** — nothing about the
desktop behaviour changes.

**What the coordinator must carry into `docs/planning/08-decisions-and-open-items.md` and into
`02-mvp-functional-spec.md` at the phase's close** (not touched by this branch, per the plan, since
another agent may be editing the same files for #42):

- The main menu's three entries (Play, Options, Quit) are unchanged in count and order on both
  targets. What QUIT *does* now differs by platform: it exits the process on desktop, and on the web
  target it opens a farewell screen with one way back to the menu, because a page cannot close a tab
  it did not itself open.
- The farewell screen carries no score and none is persisted for it — `GameSettings` persists only
  volume and the mouse toggle, and QUIT lives on the main menu, not the pause panel, so there is no
  run in progress when it is reached.

## How the target is detected

`Gdx.app.getType() == ApplicationType.WebGL`, in `MenuScreen.java`. This is libGDX's own way of
asking, used nowhere else yet in this codebase (checked with a repo-wide grep for `ApplicationType`
before adding it — no prior use to match against). **Confirmed under TeaVM**: `./gradlew
:web:gdx_teavm_web_js_build` compiled clean with this branch's changes and produced a populated
`web/build/dist/js/webapp/`, so the TeaVM transpiler accepts `Gdx.app.getType()` and the
`ApplicationType` enum without complaint. I did not load the produced build in a real browser to see
which branch it takes at runtime — see "Not checked" below.

## What changed

- `game/src/main/java/dev/luchoc/littlespaceship/game/screen/MenuScreen.java` — QUIT's action is now
  `Gdx.app::exit` on desktop and `() -> game.setScreen(new FarewellScreen(game))` on web, chosen by
  `Gdx.app.getType()`. Everything else in the menu (order, labels, keyboard focus) is untouched.
- `game/src/main/java/dev/luchoc/littlespaceship/game/screen/FarewellScreen.java` (new) — modelled
  directly on `CreditsScreen`: `BaseUiScreen`, plain text lines, a single BACK entry through
  `MenuEntries.add` (which registers it with `MenuNavigator` for keyboard access), BACK returns to a
  fresh `MenuScreen`. No score, no persistence, no new art — only `Label` and the existing skin.

## Nothing shared was touched

`BaseUiScreen` and `GameSkin` are unchanged. `PlayScreen.java`, `OptionsScreen.java` and
`docs/planning/08-decisions-and-open-items.md` were not opened by this branch, per the instruction
that another agent holds them for #42.

## Verified

- `./gradlew build` — `BUILD SUCCESSFUL`, `game`, `desktop` and `web` compile modules included.
- `./gradlew :web:gdx_teavm_web_js_build` — completed, copied `startup-logo.png` and the rest of
  `assets/` into `web/build/dist/js/webapp/assets`, no TeaVM transpilation error.
- Launched `:desktop:run` once, foregrounded the LWJGL3 window, took one screenshot: the main menu
  renders with its title, subtitle, and PLAY / OPTIONS / QUIT in that order, PLAY focused with the
  `> ` marker — confirms the menu still renders and QUIT is still in the list. Did not click QUIT, did
  not play past the menu, per "an agent must not play the game to verify a fix". Process stopped
  immediately after with `Stop-Process -Force` on that PID.
- `assets/startup-logo.png` still exists (`ls -la`, 12214 bytes, present in the web dist copy above).

## Not checked — what the project owner should do

- **Reaching the farewell screen on the deployed web build.** Steps: open the deployed build in
  Chrome or Firefox, from the main menu click or keyboard-navigate to QUIT and activate it. Expected:
  a screen titled "THANKS FOR PLAYING" with two lines of text and a single "BACK TO MENU" entry;
  activating it (click or Enter with keyboard focus) returns to the main menu, and QUIT is reachable
  again from there.
- **QUIT still exits on desktop.** Steps: run the desktop build (`./gradlew :desktop:run` or the
  packaged jar), from the main menu activate QUIT. Expected: the window closes, same as before this
  change — this branch does not alter that path (`Gdx.app::exit` is untouched for
  `ApplicationType.Desktop`).
- Keyboard navigation on `FarewellScreen` beyond compiling against `MenuNavigator`/
  `KeyboardFocusable` the same way `CreditsScreen` does — not exercised with an actual key press in
  this session.
- Whether `Gdx.app.getType()` actually returns `ApplicationType.WebGL` inside a running TeaVM build,
  as opposed to compiling — that needs the browser check above.
