---
name: formation-slot-delay
description: How issue #330 (a formation slot delayed behind the one ahead of it) reused Trajectory.elapsed with no new component, why the held-branch boundary must include elapsed==0, and how to derive an exact (not approximate) tick-alignment test for it.
metadata:
  type: project
---

Issue #330 asked for a single-file column: one formation slot tracing exactly the path the slot
ahead of it traced, delayed in time. The core half — `FormationSlot.delaySeconds`, `SpawnSystem`
backdating `Trajectory.elapsed` to `-delaySeconds`, `MotionSystem` holding velocity at zero while
`elapsed <= 0` — is in `docs/plan/11k-level-one-rebuilt/status/330-formation-slot-delay.md`. What's
worth keeping beyond that fragment:

**A per-entity delay did not need a new field, let alone a new component.** `Trajectory` already
commits, in its own javadoc, to "a function from the entity's own elapsed time to its velocity."
Starting that one existing `float elapsed` at a negative value *is* a delay — nothing else needed to
change to make an entity "not moving yet" fall naturally out of a function that was already being
called every tick. Worth checking, on any "delay X until Y" task on an entity already driven by an
accumulated clock, whether backdating that clock is sufficient before reaching for a new field.

**The boundary of the "held still" branch must be `elapsed <= 0`, not `elapsed < 0`, or the traced
positions drift by exactly one tick.** `MotionSystem` increments `elapsed` *before* evaluating it, so
an undelayed entity's first-ever velocity evaluation happens at `elapsed == step`, never at
`elapsed == 0` — `elapsed == 0` is only ever the *starting* transform, never an evaluation point. A
delayed entity whose held branch stops at `elapsed < 0` gets its own first active evaluation at
`elapsed == 0` exactly, which is one tick earlier, relative to its own delay, than the undelayed
entity's first evaluation. Using `<= 0` shifts the delayed entity's first active tick to line up
exactly: both entities' first evaluation happens on the tick their own `elapsed` first becomes
*strictly positive*. Get this wrong and the bug is not "the delay is off by a small amount" — it is a
byte-exact test failing at the very first sample, which is the good version of this bug (it's loud),
but the reasoning to fix it is non-obvious enough to be worth writing down.

**A "traces the same points" acceptance criterion can be pinned exactly, not approximately, if the
tick alignment is derived by hand first.** Rather than accepting a tolerance and comparing floats
with a delta, derive algebraically which pass-count of the delayed entity corresponds to which
pass-count of the undelayed one (here: delayed-entity-after-N-passes == undelayed-entity-after-(N −
delayTicks)-passes, for N > delayTicks, given the `<= 0` boundary above), then assert with delta-free
`assertEquals(float, float)`. Since both entities run through the identical sequence of float
multiply/adds in the identical order, the positions are bit-for-bit identical, not merely close — a
stronger, more legible test than a tolerance-based one, and it catches an off-by-one tick immediately
rather than needing a tolerance loose enough to hide it. Used `ArcTrajectoryDefinition` (velocity
actually varies with elapsed time) rather than a constant shape, specifically so a wrong tick
alignment could not hide behind velocity that never changes.

**Existence vs. deferred-spawn was a real fork, and invariant 6 decided it, not ergonomics.** The
"does not exist until the delay elapses" alternative needs a second spawn-scheduling mechanism next
to `SpawnSystem`'s own wave timeline (remembering "this slot is still owed an entity, N seconds from
now, at this position") — a general per-entity scheduler for the one column the issue actually asks
for. Worth restating for any future "does X exist yet" fork on this project: check what machinery the
deferred-existence answer would need before comparing it to the present-but-inert answer, because the
machinery cost is usually the actual argument, not just tidiness.
