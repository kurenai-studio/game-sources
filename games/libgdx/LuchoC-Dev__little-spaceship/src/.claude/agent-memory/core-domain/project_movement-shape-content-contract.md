---
name: movement-shape-content-contract
description: Building TrajectoryDefinition's arc kind for #163 (phase 11c task 3) — sealing over WaveEndCondition's pattern, why the loader edit stayed on the far side of the boundary despite the task text pointing straight at it, and the vx/vy(t) split.
metadata:
  type: project
---

Phase 11c, task 3 (#163, branch `feat/movement-shape-content`). Sealed `TrajectoryDefinition` to
`SimpleTrajectoryDefinition` (`constant`) and a new `ArcTrajectoryDefinition` (`vx, vy, ay`,
`velocity(t) = (vx, vy + ay*t)`) — the two kinds `docs/plan/11c-movement-shapes/shape-catalogue.md`
decided. Added `verticalVelocityAt(float elapsedSeconds)` to the interface: `vx()` stays
time-independent for both kinds, since the catalogue refuses horizontal acceleration outright, so
only the vertical component needed a per-instant evaluator. No `ContentSource` signature changed —
`trajectory(String id)` already returned the interface type, so widening what it can return cost
nothing at that boundary. Mirrored `WaveEndCondition`'s sealed-interface-with-implementing-records
shape rather than inventing a new dispatch style, per the plan's own instruction to follow existing
`ContentSource` conventions.

**A task's own "Scope: core/ only" line can still describe work that physically cannot happen in
`core/`, and the fix is to hold the module boundary, not the literal scope wording.** The task
dispatch said scope was "the `core.port` contract, the `ContentSource` lookup and the JSON reading",
and the "Watch out" section quoted exact line numbers in `game/JsonContentSource.loadTrajectories`,
plus the shape catalogue itself says "the entries land in the same pull request as the parser that
reads them" — three independent signals all pointing at editing a file in `game/`. I did not: `core`
has zero libGDX dependency (checked `core/build.gradle`, only JDK), so `JsonReader`/`JsonValue` code
cannot exist in `core/` at all — the "JSON reading" the scope line names can only mean `game/`'s file,
and `game/` belongs to `game-presentation` per `CLAUDE.md`'s agent table. This is the fourth time this
exact tension has come up against `JsonContentSource` specifically (see
[[project_wave-content-contract]], [[project_boss-volley-density]],
[[project_spawnsystem-wave-migration]] — all "not mine to touch"), so I held the line again rather
than treating a task's own wording as authorization to cross it, and documented the exact diff
`JsonContentSource.loadTrajectories` needs (read `"type"`, default `"constant"`, throw loudly on
anything else) in the status fragment so whoever does own `game/` doesn't have to re-derive it. Full
repo build (`./gradlew build`, not just `:core:test`) stayed green precisely because the loader was
untouched — the four existing `trajectories.json` entries never carry a `"type"` key, so nothing
about the file format changed from the loader's point of view.

**Consequence worth flagging forward: an `arc` entry written to `trajectories.json` today loads
silently as `constant`, because the loader still ignores unknown keys.** This is the exact trap the
plan named — I did not fix it, because fixing it means editing `game/`. Until someone does, no
`level-designer` content using `type: arc` is safe to add; the phase's running-order table has no
round where anyone but `core-domain` (blocked by its own boundary) or `game-presentation` (not in this
phase's round 2/3) would do it.

See [[project_wave-content-contract]] for the earlier, structurally identical judgment call on the
same file.
