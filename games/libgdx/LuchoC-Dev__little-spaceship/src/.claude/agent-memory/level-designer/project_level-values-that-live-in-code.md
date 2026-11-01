---
name: level-values-that-live-in-code
description: Values a level is designed against that are constants in core/ rather than fields in assets/data/ — where each one is, and why that matters when writing or generating anything that describes a level
metadata:
  type: project
---

Found writing the per-level document contract (phase 11d, #180), by asking of every section "which
JSON field is this derived from" and finding four that had no answer.

**Four things a level designer designs against are `public static final` constants in `core/`, not
content.** Grep before assuming a number is tunable from `assets/data/`:

- **the six recognised drop kinds** — `PickupSystem.java:39-71`. There is no `drops.json`. Only
  `"attachment"` is content-driven, through `attachments.json`'s `durability`;
- **the boss's geometry** — `BossSystem.java:140-150`: the spread/sweep velocity ratios and
  `CORE_SPAWN_Y`. The level's `boss` block gives `combatY` and speeds; the angles that decide whether
  the boss can reach the player at all are code;
- **the enemy projectile radius (`2.0f`) and the one real `pattern` string** —
  `EnemyWeaponSystem.java:35,37`. `"straight-single"` is the only shape that system builds, so a
  `pattern` value is content that names a code branch;
- **the playfield dimensions** — `MotionSystem.PLAYFIELD_WIDTH:57` (208) and
  `SpawnSystem.PLAYFIELD_HEIGHT:92` (270). Deliberately not balance values.

**Why this is worth remembering rather than re-deriving.** Any document *generated* from
`assets/data/` can only quote these, and a stale quote survives regeneration untouched — the
regenerate-and-diff check cannot see it. So the moment you write a passage about a level that
mentions one of them, name the file in backticks: it is the only thing that makes the staleness
findable later.

**The gap that has no workaround at all is design intent.** JSON admits no comments, and
`JsonContentSource.requireOnlyKeys` now rejects unrecognised keys, so there is nowhere in
`assets/data/` to say *why* a wave exists — not even a `"note"` string, which would need a parser
change and therefore `core-domain` and `game-presentation`. Anything asking "what beat is this wave
for" is answered by `docs/planning/04-campaign-and-levels.md` and by hand-written mapping tables like
the one in `docs/plan/11c-movement-shapes/shape-catalogue.md`, never by the content.

See [[wave-migration-mechanics]] and [[level-one-content-mechanics]] for the format's behaviour
itself.

**Boss entrance arithmetic, learned 03/09/2026 (#251).** `entersAt` is the wait, not the arrival.
The core spawns at `BossSystem.CORE_SPAWN_Y = PLAYFIELD_HEIGHT + (CORE_KEEL_RADIUS -
CORE_KEEL_OFFSET_Y)` = `270 + (13 - (-27))` = **310** (`BossSystem.java:163,82,92`) and descends to
`combatY` at `entranceSpeed`. For level 1's 175.0 / 25.0 that is 135 px, **5.4 s** of descent on top
of `entersAt`. So a boss-only scenario at `entersAt` 2.0 has the boss fighting at t ≈ 7.4 s.

**A level may declare `"waves": []`.** `JsonContentSource.loadLevel` only requires that exactly one
of `events`/`waves` be *present*; `parsePlacements` iterates zero entries into an empty list, and it
loads. That is how a boss-only level is expressed — the boss block plus an empty placement array.
(Distinct from a *wave* with no spawns, which is rejected; see [[shape-placement-arithmetic]].)

**A power-up cannot be placed on its own.** A pickup only ever comes from a dying holder's `Drop`
(`CleanupSystem.java:65`, `spawnDropIfAny`), so "start the player with a weapon upgrade" is not
content's to express at all — it needs a new mechanism in `core/`. Filed as issue #252.
