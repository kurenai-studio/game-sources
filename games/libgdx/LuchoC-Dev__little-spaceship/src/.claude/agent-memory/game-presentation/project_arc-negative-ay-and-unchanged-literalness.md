---
name: arc-negative-ay-and-unchanged-literalness
description: How build-level-docs.js's arcPlayfieldTime handles ay<=0 (#322), and that "must print unchanged" in a task's watch-out section is literal about the committed bytes, not just about the numbers.
metadata:
  type: project
---

#322: `arcPlayfieldTime` in `tools/build-level-docs.js` computed an "up" root
(`-2*vy/ay`, valid only when `ay > 0` because that is what guarantees the arc actually turns) and then
did `Math.min(down, up)` unconditionally. For a negative `ay` (a steepening dive, `ArcTrajectoryDefinition`'s
own javadoc says this is a legitimate shape, not an error), `up` comes out negative and `Math.min` picks
it over the correct positive `down` root — even though the quadratic's `down` root turns out to be
right already for `ay < 0` (the discriminant `vy^2 - 4a*(h+2r)` with `a = ay/2 < 0` is always `vy^2` plus
a positive term, so it's never negative and `down` is always well-defined). The bug was entirely in
still computing and using `up` when `ay < 0`, not in the down-root formula itself.

`ay == 0` also crashed (division by zero in both the `up` term and the discriminant's `4*a`), and
`ArcTrajectoryDefinition`'s javadoc explicitly says this degenerates to a `constant`'s numbers "as a
coincidence of the maths, not a reason to route it through that record instead" — so it's content the
loader accepts, not something worth flagging as a load-time error. Fixed by solving the linear equation
directly (`target / |vy|`) instead of the quadratic, mirroring `screenTime`'s own `vy===0 -> null`
convention for a motionless case.

**A task's "watch out for" can mean "must print unchanged" literally, byte-for-byte, not "the numbers I
called out by name must not move."** My first pass added an explanatory paragraph in the general prose
below the shapes table (not per-row — a static block of text). It only ever printed the same for
`ay > 0` content, so no number moved, but the bytes of `docs/levels/level-01.md` still changed and
`node tools/build-level-docs.js --check` stopped printing `unchanged`. Reverted the prose addition,
kept only the per-row ternary logic (which is genuinely inert for existing `ay > 0` entries), and the
check passed with zero doc diff. When a task names a specific mechanical check like this, treat it as
the literal acceptance bar, not a paraphrase of "don't break the important part."

See also [[project_absolute-path-atx-check]] and [[project_pathsweep-leading-vs-trailing-edge]] for the
established fixture-promotion technique (`test-*` wave -> scratch `level-99.json`, generate, diff by
hand, delete, never commit) this issue's own acceptance criteria asked to reuse.
