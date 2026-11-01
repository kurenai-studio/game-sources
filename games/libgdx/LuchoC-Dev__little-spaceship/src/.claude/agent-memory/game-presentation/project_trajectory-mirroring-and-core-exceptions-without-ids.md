---
name: trajectory-mirroring-and-core-exceptions-without-ids
description: How JsonContentSource resolves a "mirrorOf" trajectory (chains, cycles, order-independence) and why core's own validation exceptions need an id wrapped around them by the loader
metadata:
  type: project
---

Built in phase 11i (issue #264, PR #267), against `core-domain`'s task-1 contract (issue #259):
`PathSegment`/`PathTrajectoryDefinition` plus a widened `TrajectoryDefinition` sealed interface with
`horizontalVelocityAt`. `core` deliberately exposes no mirroring API — every kind is a public record,
so mirroring is composition at content-load time, in `game`.

**Two-pass load, not one.** `trajectories.json` entries either carry a `"type"` (parsed straight into
the registry) or a `"mirrorOf"` key (deferred). Resolving deferred entries only after every direct
entry exists means a `mirrorOf` can point at an entry declared *later* in the file — order in JSON
shouldn't matter to a content author, and a single forward-only pass would have made it matter.

**Mirror-of-a-mirror is supported, not refused**, via recursion with a `LinkedHashSet<String>` of ids
currently being resolved: resolving `id` checks the already-built registry first, then the pending
mirror-entry map, recursing on `mirrorOf` before building `id`'s own mirror. `Set.add` returning false
is the cycle signal — reusing the same set across the recursion for the "id already being resolved"
check turned out to be exactly the ingredients a cycle detector needs, no separate visited/recursion-
stack pair required the way a graph textbook would suggest.

**`core`'s own construction exceptions (e.g. `PathTrajectoryDefinition`'s "last segment ends at rest"
refusal, or a non-finite `vx`/`vy`/`ay`) never mention which trajectory id failed — correctly, per
that class's own javadoc, since `core` knows no ids or files.** The acceptance criterion "fails at
load, naming the file and the id" therefore needs the loader to catch and rewrap every trajectory
kind's constructor call with the id, not just `path`'s. Missing this made one test
(`pathThatEndsAtRestFailsAtLoadNamingFileAndId`) fail with a message that had the file (from `inFile`)
but not the id — worth checking for on *any* future `core` record whose constructor validates and
whose exception is surfaced through this loader.
