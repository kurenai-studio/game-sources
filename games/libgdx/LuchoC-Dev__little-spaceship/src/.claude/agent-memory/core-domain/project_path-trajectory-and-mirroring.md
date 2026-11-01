---
name: path-trajectory-and-mirroring
description: Building PathTrajectoryDefinition for #259 (phase 11i) — bounding as the dissolve mechanism for two 11c refusals, mirroring pushed entirely to content-load time with no new sealed permit, and the single last-segment check that answers rule 3.
metadata:
  type: project
---

Phase 11i, task 1 (#259, branch `feat/path-trajectories`). Added `PathTrajectoryDefinition` (ordered
`PathSegment` list, `loopStart`/`loopCount` for a bounded trailing repeat) as the third permit of
`core.port.TrajectoryDefinition`, alongside `SimpleTrajectoryDefinition`/`ArcTrajectoryDefinition`
(see [[movement-shape-content-contract]], [[trajectory-evaluation-wiring]]).

**A "wait" costs no new type.** It is a `PathSegment` with `vx = 0, vy = 0` — a content-authoring
fact, not a core distinction. An "indefinite" wait or a "permanent" loop is simply a very large
`duration` or `loopCount`; core imposes no upper bound on either, because to the player a unit that
lingers 15s and one that lingers "forever" are indistinguishable — they died or dodged long before
either elapses. This is the plan's own reasoning, worth restating because it is what lets the whole
mechanism stay a pure function of `elapsed` with zero new per-entity state, which is the one thing
that makes this phase small.

**Two 11c refusals needed correcting, and they were not the same shape of correction.**
`enterAndHold`/station-keeping was genuinely *reopened*: the unbounded hazard it named (an enemy at
rest deadlocks a `cleared` wave forever) still holds exactly as written — what's new is a written
case (the owner's path sketches) that answers it by bounding. Waypoints/segment-lists was
*dissolved*: the cost it named ("per-entity path state well beyond the elapsed-time clock") simply
stopped applying once every segment/loop got a fixed, known duration/count — the refusal wasn't wrong
when written, its premise just no longer holds. Writing "reopened" vs "dissolved" as two different
verbs in the catalogue, with the date and the reason, is what the phase's own risk section demanded
("a refusal that silently stops being true is worse than one never written") — do this explicitly for
any future un-refusal rather than just deleting the row.

**Rule 3 ("every shape leaves the playfield in finite time") is enforced with exactly one
constructor-time check, not a geometric proof.** The path's evaluation extrapolates the *last*
segment's velocity forever past the authored total duration (needed anyway, since a repeated loop
range always ends at the list's last index, so "last segment" is well-defined whether or not there's
a loop). So the constructor refuses any path whose last segment has `vx == 0 && vy == 0` — that one
check is both necessary and sufficient to eliminate the hold-forever hazard, and it's a load-time
`IllegalArgumentException`, never a runtime surprise. It does *not* prove a path actually reaches the
playfield edge from wherever a wave places it (`atX` still matters, exactly like `arc`'s hand-checked
apex numbers in the catalogue) — that's a placement concern the catalogue already leaves to per-entry
review, not something core can decide generically.

**Mirroring needed no core API change at all — the whole mechanism is `game/`-side composition using
existing public record constructors.** Since `TrajectoryDefinition` was explicitly told not to gain
a fourth sealed permit for "mirror", and every implementing record's fields are readable through
accessors, a mirrored copy of *any* kind (constant, arc, or path) is just: read the original's fields,
negate `vx` (per-segment for a path), build a new instance under a new id. This needs zero new core
surface — I only had to make sure `PathTrajectoryDefinition.segments()` (the record accessor) exposes
enough to do this, which it already does by being a record. Demonstrated with a test that builds a
mirror purely from public accessors with no helper method, to prove the claim rather than assert it.
If a future phase considers giving mirroring a first-class core method, check first whether the
content-load-time composition is actually insufficient in practice — it wasn't here.

**`TrajectoryDefinition.horizontalVelocityAt(float)` as a `default` method returning `vx()`** is the
same "add symmetry without touching the two existing records" trick `verticalVelocityAt` already
established: only the new kind overrides it, so `SimpleTrajectoryDefinition`/`ArcTrajectoryDefinition`
needed zero changes despite the interface widening. `MotionSystem.advanceTrajectories` now writes both
`Motion.vx` and `Motion.vy` from the trajectory every tick (previously only `vy`); for the two
existing kinds this is a no-op by construction (same value every tick), verified by the pre-existing
`constantShapeStaysConstantAcrossTicks`-style tests still passing unmodified.

Related: [[movement-shape-content-contract]], [[trajectory-evaluation-wiring]],
[[movement-state-component]].
