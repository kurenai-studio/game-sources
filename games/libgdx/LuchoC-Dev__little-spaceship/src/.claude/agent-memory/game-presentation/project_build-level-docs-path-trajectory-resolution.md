---
name: build-level-docs-path-trajectory-resolution
description: How tools/build-level-docs.js resolves a path trajectory, and the dual-axis exit case a purely-vertical convention cannot terminate on
metadata:
  type: project
---

#310 (phase 11k, task 1) made `tools/build-level-docs.js` resolve `path` trajectories (`segments` and
`waypoints`), `mirrorOf` and `speedOf` into one uniform shape — before this, the generator crashed
with `TypeError: ... reading 'toFixed'` the instant a level placed a `path`, since every downstream
function assumed a top-level `vx`/`vy`/`ay` no `path` entry carries. See
`docs/plan/11k-level-one-rebuilt/status/310-level-docs-reads-paths.md` for the full account; this
entry is the part worth keeping past that phase closing.

**A path's last leg can be purely horizontal, and a vertical-only exit check hangs on it.**
`constant`'s `screenTime` and `arc`'s `arcPlayfieldTime` only ever check vertical exit — a horizontal
drift is allowed to run arbitrarily far and gets flagged afterward by `offScreen`/`outsideFraction`,
never used to stop the clock. That convention divides by zero (or loops forever) on
`hold-the-line-and-exit`, whose authored last leg is `vy 0` (a slide to the right edge at a fixed
height) — legal under `PathTrajectoryDefinition`'s rule 3 (nonzero velocity on *either* axis, not
specifically `vy`). The fix (`pathSweep`/`crossLeg` in `tools/build-level-docs.js`) checks all four
playfield boundaries per leg and stops at whichever comes first, using the formation's own footprint
(not a single anchor point) for the horizontal pair. This is a genuinely different, more accurate
notion of "on screen" than constant/arc use, not an inconsistency to later reconcile — a `path` is
the shape most likely to travel far sideways by design.

**A `drift`-based "same" shortcut breaks the moment a shape's horizontal legs can point in opposite
directions.** The wave-by-wave table's `x swept` column used to print `same` whenever
`Math.abs(swept.drift) < 0.05`, which was a correct proxy for constant/arc (their drift is a single
monotonic number) but silently wrong for a `path` like `descend-and-turn-left` (moves left, then
holds): `minDrift` is large and negative while the final `maxDrift` sits near zero, so the shortcut
reported "same" for a shape that swept all the way to the left edge. Any future column that
summarizes a range by a single derived number should be re-checked against `min`/`max` directly, not
trusted just because it worked for the two shapes that existed when it was written.

**Verifying a doc-generator change against real fixtures without touching `assets/data/`:** copy an
existing `assets/data/test-*.json` scenario file to a throwaway `assets/data/level-9N.json` (the
generator only picks up `level-\d+\.json`), run the generator, read the output, then delete the
temp files before committing — `git status` on `assets/data/`/`docs/levels/` should come back clean
beyond the one real file this task's content targets. This is how every path-placing fixture already
in the repo (mirror pairs, a loop, a wait, an absolute waypoint path) got exercised without a second
task's content ever landing early.
