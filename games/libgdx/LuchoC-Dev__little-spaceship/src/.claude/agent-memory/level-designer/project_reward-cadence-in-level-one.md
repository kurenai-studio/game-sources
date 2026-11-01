---
name: reward-cadence-in-level-one
description: The generated level document has no reward-cadence view, so drop droughts have to be read off the Drops table by hand; and a second shield picked up while one is up does nothing
metadata:
  type: project
---

Found while adding the `shield` drop for #230 (phase 11g, 01/09/2026).

**`docs/levels/level-01.md` charts density and never charts rewards.** The curve is
entities-per-second per placement; drops appear only as a bare `drops` column in the pacing table
and as the "Drops and rewards" table. Neither shows a **gap**, and the gap is the thing that decides
where a new pickup belongs. Read the `at` column of "Drops and rewards" as a list of timestamps and
diff it: for level 1 before 11g that was 11.0, 48.0, 86.0, 92.5, 97.5, 113.5 — a 37-second silence
over the level's first density spike, and it is invisible in the curve, which shows that same
stretch as the tallest bar before 88 s. `tools/build-level-docs.js` could generate this and does
not.

**A second shield is a wasted pickup, not a stacked one.** `PickupSystem.applyShield` returns early
if `world.shields().has(player)` — and `Shield` carries no durability at all, so it is one hit,
whenever that hit comes. Both together mean two shield drops close in time are worth roughly one:
space them across a stretch the player is expected to be hit in, or do not place the second.

**A carrier for a drop has to be slow and durable.** `LifetimeSystem` strips `Drop` from an enemy
that leaves the playfield, so a pickup on `enemy-rush` or a fast `enemy-light` is lost on a miss
with no feedback. Every drop in level 1 rides `enemy-basic`, `enemy-shooter` or `enemy-carrier` on a
slow shape, and that is not a coincidence worth breaking casually.
