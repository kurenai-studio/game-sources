# Changelog

## Unreleased

- Fixed a freeze: unpausing and then restarting a run before the next frame
  could bring the old, already stopped scene back and stop the game loop.

## 1.1.0 - 2026-10-23

- Depth II, the Drowned Belfry: beating the first Tollmother opens a well
  down to a second layout with a second Tollmother.
- Two new enemies on Depth II: the ashmoth and the chimewraith.
- The toll bell (Space or the TOLL button): 15 resolve for 45 damage to every
  enemy in the chamber, with an 8 second cooldown.
- Removed the process docs and the exact npm version requirement.

## 1.0.0 - 2026-08-02

- Title screen, a run through one depth, death, restart and victory.
- Seeded layouts of 5 to 8 connected chambers with a treasure room, the boss
  in the room farthest from the start, doors that seal during a fight, and a
  minimap.
- Four enemies, including the three-phase Tollmother.
- Eight stackable relics; stats are recomputed from the relic counts on every
  pickup, so the order you pick them up in does not matter.
- Keyboard controls, and two thumbsticks that work at the same time on touch
  screens.
- All art drawn with code and all sounds synthesized at runtime.
- A read-only `window.__game` snapshot for the browser tests, plus test-only
  controls in dev builds.
- Unit tests, Playwright desktop and mobile tests, CI and GitHub Pages
  deployment.
