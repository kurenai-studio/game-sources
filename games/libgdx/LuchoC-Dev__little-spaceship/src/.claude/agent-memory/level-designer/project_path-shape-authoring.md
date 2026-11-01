---
name: path-shape-authoring
description: What the path trajectory kind forces on a shape's author — the loop range always ends the segment list, so a non-advancing loop can only exit sideways — plus the lead-in leg that centres an oscillation
metadata:
  type: project
---

Learned authoring `descend-and-oscillate` (phase 11i, #278). Companion to
[[shape-placement-arithmetic]], which covers `arc` and `constant` placement.

**A `path`'s loop range always runs to the end of the segment list.** `loopStart` marks a *trailing*
range — `PathTrajectoryDefinition.segmentAt` — so **nothing can be authored after the loop**. There is
no "loop three times, then a final exit segment". Past the last repeat the definition holds the last
segment's velocity forever, and that extrapolation *is* the exit.

The consequence is a real design constraint, not a detail: **a loop with zero net vertical drift can
only leave through the side.** Its last segment is horizontal by construction, because any downward
component inside the loop makes it a staircase. Wanting a downward exit means giving up the
non-advancing loop. Say which you chose and why; do not discover it halfway through the arithmetic.

**A pure two-leg oscillation (`-v` then `+v`, equal durations) sits entirely on one side of its spawn
column.** Prepending a lead-in leg of *half* the loop leg's duration at `+v` shifts the whole swing so
it is symmetric about that column, and costs one segment. Verified by integrating
`horizontalVelocityAt` at 1/100 s: `dx` ran between -30 and +30 and returned to exactly +30 at every
repeat boundary.

**Zero drift is achievable exactly, not approximately.** Two legs sharing one speed and one duration
cancel to 0.00 px per iteration in the integrated output. Do not settle for "near zero" when the
mechanism gives you zero — a drift of even a few px per repeat reads as a staircase over three
repeats.

**An oscillation is the only centre shape so far.** Its `atX` window is bounded on *both* sides:
`amplitude + radius <= x0 <= 208 - amplitude - radius`. The other four paths are all one-sided shapes
with a minimum or a maximum `atX` only.

**The scratchpad is not empty between tasks.** A stale `LoadCheck.class` at the scratchpad root, left
by an earlier session, sat first on a stale `rargs.txt` classpath and ran instead of the freshly
compiled one — the symptom was an `ArrayIndexOutOfBoundsException` on a line that was a list literal,
which is impossible and wasted three runs. Give the throwaway main a task-specific class name and
rewrite the argfile every time.
