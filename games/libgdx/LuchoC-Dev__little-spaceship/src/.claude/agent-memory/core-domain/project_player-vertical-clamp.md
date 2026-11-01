---
name: player-vertical-clamp
description: MotionSystem's x-only clamp was a real absence, not a wrong value; how the vertical bound was decided and where PLAYFIELD_HEIGHT already lived.
metadata:
  type: project
---

`MotionSystem.clampPlayerToPlayfield` clamped `transform.x` only — no `y` clamp existed, so the player
could fly off the top or bottom indefinitely. Fixed by clamping `y` to
`[margin, SpawnSystem.PLAYFIELD_HEIGHT - margin]`, same collider-radius-as-margin rule as x.

`SpawnSystem.PLAYFIELD_HEIGHT` was already the shared vertical-bound constant before this fix —
`LifetimeSystem`, `BombSystem` and `BossSystem` all reference it via `SpawnSystem.PLAYFIELD_HEIGHT`.
No need to relocate it for `MotionSystem` to use it too; that cross-system reuse was already the
established pattern, not something this fix introduced.

No planning doc fixes the vertical movement range explicitly. `01-vision-and-scope.md` says only "free
ship movement inside the playable area" — no separate top/bottom zone. Decision made here: full
playfield height, symmetric with x, using the ship's own edge (collider radius) against both
boundaries. `playerStartY: 30` near the bottom is a spawn point, not a movement-zone rule — do not
conflate the two.

Reminder for next time: a "does not clamp Y at all" bug will not show up in a test that checks position
after one tick — the position after one tick under strong input is still inside bounds. Drive dozens of
ticks of sustained input toward the edge to actually reach and cross it.
