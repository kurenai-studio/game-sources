---
name: generator-checks-when-authoring-a-level
description: How tools/build-level-docs.js's swept-extent, atX and overlap checks actually behave while authoring a level — the 50% threshold arithmetic, why an overlap is always a "finding", and the constant-velocity over-extrapolation
metadata:
  type: project
---

Learned rebuilding level 1 in phase 11k (#324). Extends [[shape-placement-arithmetic]] and
[[verifying-content-against-the-loader]].

**"Checks clean" can never mean an empty findings list on a level with a negative offset.** The
generator emits one finding line per negative `offset`, unconditionally — it reports *what* an
overlap is, it does not judge it (`tools/build-level-docs.js`, the `for (const row of rows)` loop
after the geometry checks). The pre-11k document printed the same two lines. Read "clean" as "the
list contains only the overlaps you chose", and say so in the fragment rather than trying to reach
zero.

**The swept-extent finding fires at `outsideFraction >= 0.5`, and the fraction is computed from the
spawn *footprint edge*, not from the footprint centre.** For a `constant` with drift `d = vx *
screenTime`, `min = x - r + d` (for `d < 0`), `max = x + r`, `span = max - min = |d| + 2r`, and
`outside = |d| - (x - r)`. So `cut-across-left` (`vx -48`, `vy -46`, `enemy-light` r 4.5, drift
-286.4) is **under** the threshold for any `atX >= 0.69` and clean at 0.95 — 31.6 % outside. Getting
this wrong by using the centre instead of the edge makes a legal placement look impossible.

**A `constant`'s swept extent is extrapolated past its sideways exit.** `screenTime` is
`(270 + radius) / |vy|`, the time to fall the whole playfield height, with no horizontal-exit term.
`cut-across-right` at `atX 0.05` therefore prints a sweep to **301.3** although it crosses x = 208
long before. It over-reports, so it cannot hide a real case, but the figures in the "x swept" column
are not positions for a crossing shape. `pathSweep`, used for `path`, does bound the exit.

**Generated prose goes stale exactly like a hand-written table does.** `build-level-docs.js` prints
*"The veers spawn on the side they veer away from — `veer-left` at `atX >= 0.75`…"* unconditionally,
plus `slow-descent`/`dive`/`veer-*` in its schema examples. Deleting those seven ids from
`trajectories.json` left the generated document explaining a rule for shapes the repository no longer
contains, and nothing failed. `tools/` is not the level designer's to fix — report it.

**A level file can survive a total rebuild untouched.** `level-01.json` came out byte-identical after
all twelve waves were rewritten: placements, order and offsets are a different layer from spawns.
Expect that, and do not treat an unchanged `level-NN.json` as evidence the work did not land — the
proof is `docs/levels/level-01.md` changing.
