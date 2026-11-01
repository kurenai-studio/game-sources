---
name: absolute-path-waypoints-syntax
description: Why the absolute path form (#287) got its own top-level "waypoints" key instead of per-segment destination/speed fields, and the atX cost that was documented rather than enforced
metadata:
  type: project
---

Built in phase 11j (issue #287, PR #288), extending `JsonContentSource.parseTrajectory`'s `path`
branch. A `path` entry declares exactly one of `"segments"` (existing, relative: `{vx, vy,
duration}`/`{"wait"}`) or `"waypoints"` (new, absolute) — both present or both absent fails loudly
naming the id.

**Two mutually exclusive top-level keys beat one array whose per-element shape you'd have to guess.**
The task's own risk section warned that both forms produce identical `PathSegment`s, so a reader
must be able to tell the kind "at a glance". A single `"segments"` array where each element could
independently be `{vx,vy,duration}` *or* `{toX,toY,speed}` would satisfy the letter of the acceptance
criterion (each individual leg is self-describing) but not the spirit — a reader would still have to
scan every element to know whether the *path as a whole* ever switches forms. Making `"waypoints"` a
separate array from `"segments"` answers the question with one glance at the entry's keys, and makes
mixing structurally awkward rather than merely forbidden by convention. Reused the same "which of two
mutually exclusive keys" pattern used for `type: constant` vs `"mirrorOf"` at the top of
`loadTrajectories`.

**Waypoints chain a running position**: the first element is `{"x","y"}` only (nothing precedes it,
so no speed); every element after is either a destination `{"x","y","speed"}` (leg from the previous
point, in parse order — not from the origin every time) or `{"wait": seconds}` (pauses, does not
advance the running position). `direction = normalize(B−A)`, `duration = |B−A|/speed`, straight into
`PathSegment` — same constructor and same rule-3 refusal `parseSegments` already relies on, so
mirroring/looping/rule-3 needed zero new code, only tests confirming they still work on a
waypoint-derived segment list.

**`PLAYFIELD_WIDTH`/`PLAYFIELD_HEIGHT` had to be duplicated as private constants in
`JsonContentSource`**, not imported — the real ones live in `core.domain.system.MotionSystem`/
`SpawnSystem`, and `game` does not depend on `core.domain` (only `core.port`). `PlayScreen` already
duplicates `208f` for the identical reason — same pattern, second sighting.

**The unresolved cost, deliberately left unbuilt**: an absolute path's coordinates only mean what
they say when the wave placing it uses `atX = 0` (the first waypoint *is* the local origin `atX`
normally offsets). There is no existing seam to cross-check `trajectories.json` entries against
`waves.json` placements — `SpawnEvent.trajectoryId` already resolves lazily at runtime in
`SpawnSystem`, not validated at content-load time (see `project_spawn-event-trajectory-override.md`).
Built no cross-file check; documented the constraint in the status fragment and the issue comment
instead, explicitly modeled on how #280 (a loop is always a path's tail) was recorded rather than
fixed. If this becomes a real authoring mistake, the fix is cheap since both files load in the same
constructor, in sequence — but that is `level-designer`'s or a future task's call, not something to
add unasked under invariant 6.
