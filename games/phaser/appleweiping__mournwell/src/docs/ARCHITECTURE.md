# How Mournwell is put together

A static site: Phaser runs the game loop, physics and drawing, plain
TypeScript holds the rules, and a small DOM layer draws the menus, HUD and
touch controls. There is no server.

## Scenes

1. `BootScene` draws every sprite (player, enemies, relics, the well) with
   Phaser `Graphics` and turns them into textures. Nothing is downloaded.
2. `MenuScene` is the animated backdrop behind the HTML title screen.
3. `GameScene` runs one depth: it builds the layout from the seed, loads
   rooms, spawns waves, and handles combat, pickups, the bell and the well.
   Descending restarts the scene with `floor: 2` and a `carry` object
   (relics, resolve, run clock and counters).

`systems/ui.ts` listens to events from the scene (`snapshot`, `phase`,
`toast`, `result`) and updates the DOM. The DOM never decides anything about
combat.

## Seeds and layouts

`systems/rng.ts` hashes a string seed into named streams (`<seed>::dungeon`,
`::loot`, `::room::<id>`, ...), so a cosmetic random draw never changes the
layout. `systems/dungeon.ts` grows a 5-8 room grid and `validateDungeon`
checks that every room is reachable, doors are two-way, and the boss sits on
a dead end at least three doors from the start. `tests/dungeon.test.ts` runs
the validator over 10,000 seeds.

Depth I uses the run seed as is (so seeds from 1.0 replay the same); Depth II
uses `<seed>::depth-2` (`data/floors.ts`), which also lists each depth's
enemy roster, the Tollmother's summons and the colours.

## Enemies

Each enemy kind is a small state machine in `entities/Enemy.ts` (for example
the chimewraith goes `drift -> veiled -> chiming -> drift`). Timing comes from
the scene's run clock, and AI "randomness" is derived from the clock and the
entity id rather than `Math.random`, so a fight plays out the same way for
the same inputs.

## The toll bell

`systems/bell.ts` is the whole rule set: `tollBell(hp, now, readyAt)` either
refuses (cooldown, or not enough resolve to survive paying) or returns the
new resolve, the next ready time, the damage and how long enemies freeze.
`GameScene.tollBell` applies it to every enemy in the room and then clears
enemy shots, so the embers of an ashmoth the bell kills are cleared too.
Space is queued on the key's `down` event instead of `JustDown`, because a
tap shorter than one frame would otherwise be lost.

## Relics

`data/items.ts` recomputes the player's stats from the base stats and the
stack count of each relic every time something is picked up, instead of
multiplying the previous result, so the order of pickups does not matter.

## Tests

- `tests/` (Vitest): dungeon validity, RNG, relic maths, save-file parsing,
  the bell rules, and the depth definitions.
- `e2e/` (Playwright): plays the dev build with real keyboard and touch
  input (moving, shooting, killing, picking up relics, dying, winning,
  ringing the bell, descending to Depth II), plus a smoke test of the
  production build.

The game exposes a read-only `window.__game.getSnapshot()` that the
Playwright tests poll. Dev builds opened with `?qa=1` also get
`window.__game.test` (reset to a fixture, spawn enemies, enter a room, ...);
production builds do not include it.
