---
name: movement-state-component
description: Building Trajectory (per-entity elapsed time) for #161 (phase 11c task 1) — a speculative origin field flagged under invariant 6, then removed once the parallel shape-catalogue design (#162) settled the question the other way; the reflection-guard tests that must be extended for any new ComponentStore; the deliberate "advances but nothing reads it yet" scope.
metadata:
  type: project
---

Phase 11c, task 1 (#161) added `core/domain/component/Trajectory.java`, advanced by a new
`MotionSystem.advanceTrajectories` step called right after `applyPlayerInput` and before `integrate`
inside `SystemOrder.MOTION` — no new stage, per invariant 5. Final shape: `elapsed` (mutable float,
seconds since spawn) alone.

**Adding a `ComponentStore` field to `World` requires two guard tests, not one, or the build breaks
for reasons that look unrelated to the change.** `WorldTest.destroyStripsEveryComponent` discovers
every `ComponentStore` field on `World` by reflection and asserts each was populated by
`populateEveryComponent` — that method must be extended by hand for a new component or the whole
test fails with a message naming the missing store. Separately, `World.destroyEntity` must call
`.remove(entity)` on the new store explicitly; nothing catches a forgotten one automatically except
that same reflective test. This is the "reflection-based ComponentStore test guards" mentioned in
earlier memory — this was the first time I actually hit it end to end.

**A speculative field, flagged rather than silently guessed, got corrected by the next task landing —
that is invariant 6 working as designed, not a mistake to avoid repeating.** I first shipped
`Trajectory` with `originX`/`originY` because every shape the roadmap named by example (U-turn,
diagonal, curve) seemed to need a fixed reference point once the entity's `Transform` moves away from
spawn. I flagged this explicitly in the PR/status fragment as a decision the plan didn't cover, rather
than asserting it was obviously right. The parallel task (#162, the shape catalogue) then settled it
the other way: a shape is defined as "a function from elapsed time to velocity, nothing else goes in,"
and neither of the two kinds it allows (`constant`, `arc`) reads a position. The coordinator asked for
the fields to come out on the same branch and PR once that design landed, and removing them was a
small, mechanical change (constructor, two test files, two javadocs) because the field was never
consumed by anything else. **Lesson: when the plan leaves a question the design work of a sibling,
in-flight task will answer, it's fine to make a documented guess to keep moving, as long as the guess
is flagged loudly and cheap to reverse** — don't let "invariant 6 says no speculative fields" become
a reason to stall waiting for a parallel branch; write it down, ship it, and be ready to cut it.

**Task 1 deliberately advances state nobody reads yet.** Nothing in `ComponentFactoryRegistry`
attaches a `Trajectory` to a spawned entity — that's tasks #163/#164, someone else's branch and a
later round. So this PR's own tests have to manually `world.trajectories().set(entity, new
Trajectory())` to exercise the advance at all; there is no way to demonstrate it through the normal
spawn path yet. Determinism replays pass trivially unchanged in this PR because no real entity in the
game carries the new component — that's expected here, not a sign the phase is finished.
