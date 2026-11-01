---
name: pathsweep-leading-vs-trailing-edge
description: The "which footprint edge does a boundary check compare against" trap in tools/build-level-docs.js's pathSweep/crossLeg, and how to hand-derive the correct answer from the core removal rule instead of guessing.
metadata:
  type: project
---

Issue #314, fixing task 1's own `pathSweep`/`crossLeg` in `tools/build-level-docs.js`
(see [[project_build-level-docs-path-trajectory-resolution]] for the task that introduced them).

**The bug:** the horizontal boundary check compared the footprint's edge in the *direction of travel*
(leading edge — `at.min` going left, `at.max` going right) against `0`/`width`. That answers "when
does this first touch the boundary", not "when is it fully gone" — the two differ by exactly the
footprint's own width (`at.max - at.min`, `2*radius` for a single-slot formation) divided by `|vx|`,
because both edges translate together at the same speed. A `constant`/`arc`'s vertical-only check
never had this problem because it was ported straight from `LifetimeSystem.isFullyOffPlayfield`; the
horizontal check was invented fresh for `path` support and used the wrong edge by an intuitive but
wrong analogy ("the front reaches the wall" reads as "gone" if you don't separate the two questions).

**How to derive the right edge without guessing:** don't reason about "leading"/"trailing" in the
abstract — read the two conditions `isFullyOffPlayfield` actually tests (`x + radius < 0` for a
leftward exit, `x - radius > width` rightward) and match the sign. `x + radius` is the entity's
*rightmost* point; requiring it to clear `0` means the rightmost (trailing, when moving left) edge is
the one that gates removal. This generalizes past a single-slot footprint: for a formation, `at.max`
and `at.min` already are the swept rectangle's edges, so the same substitution holds regardless of
formation width — no need to special-case wide formations.

**Verifying a hand derivation is worth the arithmetic.** For `hold-the-line-and-exit` the corrected
edge check doesn't find a crossing within the leg's own authored duration at all (the true full-exit
time exceeds it) — it falls through to the "extrapolate the last leg forever" branch, a structurally
different code path than the old (wrong) answer used. A derivation that only patches the formula
without tracing which branch actually executes would have missed this; running the tool on a scratch
`level-9N.json` copy of the fixture and reading its own output back is what caught it, matching the
issue's own "roughly 221" estimate to the decimal once traced through correctly.

**Reachability side effect:** fixing this makes `**leaves**` fire on shipped `assets/data/test-*.json`
fixtures that could never trigger it before (`test-path-mirror`, `test-path-oscillate`, `test-cross`).
That is a finding about those fixtures being real sideways exits, not a regression — per the issue's
own instruction, report it and leave the threshold alone rather than tuning until it goes quiet.
