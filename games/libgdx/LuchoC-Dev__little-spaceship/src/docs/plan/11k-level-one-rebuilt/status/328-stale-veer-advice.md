# Task: stale veer-side advice in the generated level document (#328)

## What was wrong

`assets/data/trajectories.json` no longer has `veer-left`, `veer-right`, `slow-descent`, `swoop`,
`dive`, `crawl` or `strike-run` (task 6, PR closing #324, deleted the seven 11c trajectories). Three
static strings in `tools/build-level-docs.js` still named `veer-left`/`veer-right` and `swoop`
unconditionally:

- the "Movement shapes" section's rule paragraph (source `:1058-1059` before this change),
- the "x swept" column explanation, which used `swoop` and `veer-right` as worked examples
  (`:919-922`),
- the "What was checked" list entry (`:1289`).

A fourth spot was not named by the issue but is the same defect and is functional, not just prose:
the per-spawn finding in the Checks section (`:1314-1325`) computed a real condition
(`t.kind === 'arc' && vx` sign vs. `atX`) but always printed the literal string `veer-right`/
`veer-left` as the advice's subject, regardless of which trajectory actually triggered it. Today
that only matters for `dive-across-left`/`dive-across-right` (the only `arc` trajectories left), but
the printed sentence would have named a fictional shape the moment it fired.

## Derived or dropped, and why

**Dropped**, not derived. I considered deriving a general "spawn on the side you drift away from"
rule from the swept extent the generator already computes, but the threshold the old prose used
(`atX >= 0.75`, `atX <= 0.25`) was a property of the specific old arcs' own drift magnitude and
duration, not a universal constant — a different shape's safe range is a different pair of numbers,
and printing a made-up universal threshold would be exactly the kind of invented constraint this
phase has already been burned by twice (#310, #322). The generic per-spawn finding that already
exists (the "sweeps X .. Y over Zs .. about N% outside .. reads in range at the spawn instant and
is not" sentence) already says everything the veer-specific addendum was for: which spawn, which
trajectory, its actual swept range, and that it was hidden at the spawn instant. Dropping the
addendum removes the false claim without losing any information a designer needs — it is the "or
drop it" branch the issue offered, taken because the swept-extent check already covers the case.

I also fixed the functional bug in the Checks-section finding (the hardcoded `veer-right`/
`veer-left` strings inside the dynamic per-spawn message) rather than leaving a latent copy of the
same defect — it is not one of the three lines the issue named because it happens to be silent on
current content (only `dive-across-*` are arcs today, and neither currently crosses the
`outsideFraction >= 0.5` threshold), but it is the same shape of bug and would have produced a
fictional trajectory name the moment it fired.

## What else I touched and did not

- Rewrote the "x swept" column explanation to describe the mechanism generically (any shape with
  drift can spend its whole flight off screen while reading in range at spawn) instead of using a
  worked example that named two now-deleted trajectories.
- Reworded the doc comment above `sweptExtent` (not printed in generated output) from present tense
  ("two of the seven trajectories are veers") to past tense, crediting #328, since it is a historical
  rationale for why the function exists and was left claiming something no longer true.
- **Left the JSONC schema-illustration blocks alone** (`tools/build-level-docs.js` around the "How a
  level names things" section, printed at `docs/levels/level-01.md:73,88,90,112`). They use `dive`,
  `slow-descent`, `strike-run`, `dive-fast` as illustrative ids to show the shape of `constant`,
  `arc`, `path` and `speedOf` JSON — they are schema syntax examples, not claims about what
  `assets/data/trajectories.json` currently contains, and they predate this defect. The issue named
  three specific lines and the task's own scope note warns against creep; touching illustrative
  syntax examples is a different, much larger concern (they'd need to be regenerated as schema
  documentation independent of content, which is out of this task's scope).

## Diff to `docs/levels/level-01.md`

`node tools/build-level-docs.js` reports `updated docs/levels/level-01.md`, `unchanged
docs/levels/waves.md` (waves.md carries no trajectory geometry, so it is untouched, as expected).
The diff is exactly the three sites above:

1. The "x swept" column paragraph, reworded to be generic (see above).
2. The "veers spawn on the side..." paragraph in "Movement shapes" — deleted outright.
3. The "What was checked" list — the `, and the veer-side rule when a veer is the cause` clause
   removed from the swept-extent bullet.

No other line changed. A second run of the generator reports `unchanged` for both documents,
confirming the mechanism is stable.

## Verification

- `node tools/build-level-docs.js` twice: first run `updated docs/levels/level-01.md` / `unchanged
  docs/levels/waves.md`; second run `unchanged` for both.
- `grep -n "veer-left\|veer-right\|slow-descent\|swoop\|\bcrawl\b\|strike-run" docs/levels/level-01.md
  docs/levels/waves.md` — no hits.
- `grep -n "\bdive\b" docs/levels/level-01.md` — hits only inside the JSONC schema-illustration block
  (see above), not in derived content.
- `tools/pre-pr-check --base phase/11k-level-one-rebuilt` — output pasted into the pull request.

## Acceptance criteria

- No line of either generated document names a trajectory that `assets/data/trajectories.json` does
  not contain, **except** the pre-existing JSONC schema-illustration examples, which were out of
  this task's scope and are not claims about real content (see "What else I touched and did not").
- Whatever replaces the veer advice is derived from the content or is gone: **gone**, with the
  reasoning above. Pass.
- `node tools/build-level-docs.js` regenerates and its output is committed; the diff is explained
  above. Pass.
