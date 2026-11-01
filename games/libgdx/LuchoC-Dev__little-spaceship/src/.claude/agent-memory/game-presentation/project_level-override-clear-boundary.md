---
name: level-override-clear-boundary
description: Where to clear a session-wide override field on LittleSpaceshipGame, and why "entering the menu" beat "choosing PLAY" for #305
metadata:
  type: project
---

`LittleSpaceshipGame.levelIdOverride` (set only by `-Ptests`' `TestMenuScreen`) had no clear
call at all before #305 — its own javadoc said "for the rest of this run" but nothing ever ran at
the end of a run, so it really meant "for the rest of the process". Fixed by adding
`LittleSpaceshipGame.clearLevelIdOverride()` and calling it from `MenuScreen`'s constructor
(`main` source set), not from the PLAY entry.

**Why the constructor and not the PLAY lambda:** every path back to the main menu — BACK from
TESTS, defeat, victory, OPTIONS back — reconstructs a `MenuScreen`, so clearing there is one line
that catches all of them. Clearing only at PLAY would leave the override live while sitting at
the menu, for no benefit, since nothing reads `levelId()` while the menu itself is showing.

**General lesson:** a composition-root field meant to live "for this run" needs an explicit
place where a run is considered to end, decided *before* the field is added — not discovered
later as a defect. `MenuScreen` re-entry already doubles as that boundary elsewhere in this class
(`setScreen` stops music for every non-`PlayScreen` screen), so "the menu is the reset point" is
already the codebase's own convention, not a new one invented for this fix.

Clearing the field is not a flavour concern even though only `-Ptests` ever sets it:
`levelIdOverride` lives in `main`, so `clearLevelIdOverride()` is a no-op in every ordinary build
already. `MenuScreen` gained no `TestMode` reference to fix this.
