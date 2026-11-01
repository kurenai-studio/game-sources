# 310 — `tools/build-level-docs.js` understands a `path` trajectory

**Branch:** `fix/level-docs-reads-paths`. **Closes:** [#310](https://github.com/LuchoC-Dev/little-spaceship/issues/310).
`game-presentation`, on `tools/build-level-docs.js` only (the plan's scope exception for `tools/`),
plus this fragment and the regenerated `docs/levels/level-01.md`.

## What shipped

Before this task, `path` trajectories were invisible to the generator: `resolve(trajectories, id,
...)` returned the raw JSON entry, and every downstream function assumed `.type`/`.vx`/`.vy`/`.ay` —
fields a `path` entry does not carry at its top level, and fields `mirrorOf`/`speedOf` entries carry
*none* of. Confirmed before touching anything: copying `assets/data/test-hold-line.json` to
`assets/data/level-99.json` and running `node tools/build-level-docs.js` on the unmodified script
crashed with `TypeError: Cannot read properties of undefined (reading 'toFixed')` at `s1(t.vx)` in
the shapes table — not a clean `die()`, an uncaught exception.

**The fix resolves every trajectory kind up front, once, into a uniform shape**, reproducing
`JsonContentSource`'s own arithmetic rather than inventing a second definition of it:

```
{ id, kind: 'constant', vx, vy }
{ id, kind: 'arc', vx, vy, ay }
{ id, kind: 'path', segments: [{vx, vy, duration}, ...], loopStart, loopCount }
```

`main()` now does `trajectories: resolveTrajectories(index(readJson('trajectories.json')...))`
instead of handing the raw indexed JSON straight to every consumer. `resolveTrajectories` is a lazy,
memoised recursive resolver — mirroring `JsonContentSource.resolveDerived` — so `mirrorOf`/`speedOf`
resolve in either declaration order, and a cycle or a dangling reference dies naming the file and the
id (`assets/data/trajectories.json: trajectory derivation cycle: a -> b -> a`, `...derives from
unknown trajectory 'x'`) instead of recursing forever or crashing on `undefined`. Every place that
used to read `t.type === 'arc'` now reads `t.kind`, generalised to three values instead of two.

**`waypoints` are resolved into the same `{vx, vy, duration}` legs `segments` produces** —
`resolveWaypointsField` is `JsonContentSource.parseWaypoints`'s arithmetic ported directly:
`direction = normalize(B - A)`, `duration = |B - A| / speed`. This is the point of the task: once
resolved, an absolutely-authored path and a relatively-authored one are indistinguishable to
everything downstream, exactly as they are to `core` — the delta from the spawn point is all either
form ever produces. **`ay`'s multiplier-squared rule for `speedOf` is ported unchanged**
(`ay * multiplier * multiplier`, not `ay * multiplier`), the exact trap 11j's status fragment names.

**This task deliberately does not reimplement `JsonContentSource`'s validation** (missing keys, a
waypoint outside the playfield, a non-positive duration) — a malformed entry is caught by the real
loader in CI long before this tool would see it, and duplicating that validation is the second-
definition risk the plan warns against. What had to be right here is the arithmetic, not the
guardrails.

## The two new pieces: swept extent and screen time, for a `path`

`constant` gets its screen time from `screenTime` (a closed-form division) and `arc` from
`arcPlayfieldTime` (a quadratic root) — both purely vertical, ignoring any horizontal exit entirely.
A `path` cannot reuse either: its velocity is piecewise constant, not one line or one parabola, so
`pathSweep` walks the expanded leg list (`expandPathLegs`, which unrolls the loop range exactly as
`PathTrajectoryDefinition.segmentAt` does) and finds, leg by leg, the first moment it crosses a
playfield boundary.

**I made a deliberate departure from the constant/arc convention here, and it is load-bearing.**
`constant`/`screenTime` and `arc`/`arcPlayfieldTime` only ever check the *vertical* exit — a
horizontal drift is allowed to run arbitrarily far past `[0, 208]`, flagged afterward by the existing
`offScreen`/`outsideFraction` checks but never used to stop the clock. I initially wrote `pathSweep`
the same way and it does not terminate for `hold-the-line-and-exit`: its **last leg has `vy = 0`** —
a slide to the right edge at a fixed height — which is legal under rule 3 (nonzero velocity on
*either* axis) but means "when does it leave vertically" has no answer; the extrapolation step would
divide by zero. `crossLeg`/`pathSweep` therefore check **all four boundaries — top, bottom, left,
right** — and stop at whichever a leg reaches first, using the formation's own footprint (`at.min`,
`at.max`) for the horizontal pair so a wide formation is checked by its edges, not its anchor point.
This is more accurate than the constant/arc convention, not merely different — a path is the shape
most likely to travel far sideways by design, and `hold-the-line-and-exit` is real, shipped content
that needs exactly this. It means a `path`'s reported "x swept" is capped at the moment it first
leaves any edge, where a `constant`/`arc`'s can run past `208` and get flagged **`leaves`** — two
different but each-correct notions of "how far it goes", and the difference is worth knowing before
reading the two side by side.

**A bug this surfaced, unrelated to `path` support in isolation:** the "x swept" column's `same`
shortcut compared `Math.abs(swept.drift) < 0.05`, where `drift` was a single number. For
`constant`/`arc` that is always the final and only horizontal displacement, so it is a correct proxy
for "unchanged". For a `path` whose legs can drift in *opposite* directions (`descend-and-turn-left`
moves left then holds), `minDrift` can be large while `maxDrift` (the field I plugged into `drift`)
sits at zero, and the shortcut printed `same` for a shape that had in fact swept all the way to the
left edge. Caught by reasoning through `descend-and-turn-left` at `atX 0.85` by hand before trusting
the tool's own output, then confirmed by the wrong output itself. Fixed by comparing the actual
`swept.min`/`swept.max` against the spawn-instant footprint instead of the single `drift` field —
this also changes the display for constant/arc, but only in the (already-impossible-for-them, since
their drift is monotonic) case the old check got wrong, so no existing document's numbers moved.

**Roster and stagger's "screen time" column falls back to `varies (path)`, matching the existing
`varies (arc)` precedent, and I chose not to give it a real number even though one is computable.**
That column has no spawn context (no `atX`, no formation) — it describes the archetype's own default
shape in isolation — and a `path`'s horizontal-exit time genuinely depends on where it is placed,
unlike its vertical-exit time. Giving a number there would either silently assume `atX 0` (wrong for
most placements) or require threading a formation/`atX` into a column that has never needed one.
`sweptExtent`, which does have that context, reports the exact number for a `path`'s actual
placement — that is where the criterion "a correct screen time for it" is met.

## The shapes table

Section 7's `vx`/`vy`/`ay` columns describe a line or a parabola and have nothing to say about a
path. Added a `legs (path only)` column instead of inventing pseudo-`vx`/`vy` values: each leg in
order, `vx, vy for Ns` or `wait Ns`, with a leg inside the repeated range bracketed and the loop count
noted once (`stair-descent` prints `vx 0.0, vy -50.0 for 1.20s → [vx -45.0, vy 0.0 for 0.80s] → [vx
0.0, vy -45.0 for 0.80s] (loop x4)`). This shows the *authored* legs, unaffected by `pathSweep`'s
boundary-aware truncation — the shapes table is what the content says, the wave-by-wave section is
what happens where it is placed, and those are two different questions with two different answers on
purpose (`hold-the-line-and-exit`'s last leg is authored `1.49s` long but is only `on screen` for
part of that at `atX 0.50`, since it starts already inside the last few units before the edge).

Also extended "## The format"'s `trajectories.json` example to show `path` (`segments` and
`waypoints` forms) and `mirrorOf`/`speedOf` — it previously showed only `constant` and `arc`, which
was already a documentation gap independent of this task, but leaving it while making the tool
understand the other three forms would have been a stranger inconsistency than fixing it.

## Verification

**Idempotency, the acceptance criterion that must survive:**
```
$ node tools/build-level-docs.js && node tools/build-level-docs.js --check
unchanged  docs/levels/level-01.md
unchanged  docs/levels/waves.md
unchanged  docs/levels/level-01.md
unchanged  docs/levels/waves.md
```
`level-01.md` did change once, from the old code to the new — 36 insertions, 11 deletions, all of it
the new `path`/`mirrorOf`/`speedOf` documentation examples and the shapes table's new column, none of
it a number derived from `level-01.json`'s own content (checked by diff; every numeric row is byte
identical). That single regeneration is committed.

**The before/after demonstration** (#177's format), using every path-placing fixture already in the
repository (`assets/data/test-*.json`, all of them `mirrorOf`, `waypoints`, `loopStart`/`loopCount`
or multi-leg `segments`), each temporarily copied to a `level-9N.json` and generated, then deleted —
none of this is committed, `git status` is clean on `assets/data/` and `docs/levels/` beyond
`level-01.md`:

- **Before:** `TypeError: Cannot read properties of undefined (reading 'toFixed')` on the very first
  `path`-placing fixture tried (`test-hold-line`).
- **After**, spot-checked against 11j's own status fragment where it gives numbers to compare against
  (all edge-of-collider positions, matching that fragment's own "measured, not assumed" convention):
  - `hold-the-line-and-exit` at `atX 0.50` on `enemy-shooter`: `x at spawn` 97.5..110.5, `x swept`
    97.5..208.0 (capped at the right edge — see "deliberate departure" above).
  - `descend-and-turn-left`/`-right` (mirror pair) at `atX 0.85`/`0.15`: `0.0..187.3` and
    `20.7..208.0` — each reaches the edge it turns towards, symmetrically.
  - `slide-left-then-descend`/`-right-` (mirror pair) at `atX 0.80`/`0.20`: `60.9..171.9` and
    `36.1..147.1` — edge-of-collider version of 11j's own centre-position numbers (66.4 and 141.6;
    `66.4 - 5.5 = 60.9`).
  - `stair-descent` (a 4x loop): `22.3..187.3`, i.e. `166.3 - 4*36` — matches the loop unrolling by
    hand.
  - `dive-and-retreat` (`vx` is always 0): `same` — correctly unaffected by the `same`-shortcut bug
    above, since its drift really is zero on both ends.
  - An unknown `type` (`"spiral"`) and a `mirrorOf` naming a nonexistent id each die naming the file
    and the id, not `undefined`:
    ```
    build-level-docs: assets/data/trajectories.json: trajectory 'bad-shape' has an unknown type 'spiral'
    build-level-docs: assets/data/trajectories.json: trajectory derives from unknown trajectory 'does-not-exist'
    ```

**`varies (path)` and `varies (arc)`, both checked**, by temporarily pointing an archetype's default
`motion.trajectory` at `strike-run` (arc) and then at `hold-the-line-and-exit` (path), regenerating,
reading the roster row, and reverting `assets/data/enemies.json` before finishing (`git diff` on it is
now empty).

**`./gradlew build` and the Java toolchain**: not run. This task touches only `tools/`, a plain Node
script with no Java dependency; nothing here changes what `JsonContentSource` does or compiles.

## What I judged rather than found written down

- **Which convention "screen time" and "swept extent" should follow for a path** — vertical-only
  (matching precedent, but non-terminating for a real shape) versus dual-axis (correct, but a
  different notion of "on screen" than constant/arc use). Chose dual-axis, argued above.
- **Whether roster's screen-time column should print a real number for `path`** — chose `varies
  (path)`, matching the existing `arc` precedent, on the grounds that the number depends on a spawn
  context that column has never had.
- **Whether to extend "## The format"'s syntax example to cover `path`/`mirrorOf`/`speedOf`.** Did,
  since leaving it silent while making the tool understand those forms seemed like a worse
  inconsistency than the extra lines.

## Acceptance criteria

- [x] `node tools/build-level-docs.js` prints `unchanged` for both documents on content that has not
  changed — shown above, after the one real regeneration this task's own change causes.
- [x] A level file placing a `path` trajectory generates a document with a correct swept extent and a
  correct screen time for it, each derived from the resolved segments — shown above against every
  `path`-placing fixture in the repository, cross-checked by hand against 11j's own numbers.
- [x] `mirrorOf` and `speedOf` resolve, in either order — `resolveTrajectories` is order-independent
  by construction (lazy, memoised, recursive); exercised via `cross-right`/`descend-and-turn-right`/
  `slide-right-then-descend` (`mirrorOf`) — no `speedOf` entry exists in the shipped content yet to
  exercise end-to-end, so this is verified by code review of `fasterTrajectory` against
  `JsonContentSource.faster` rather than by a fixture; the arithmetic is line-for-line the same.
- [x] An unknown or unresolvable trajectory kind dies naming the file and the id — shown above, two
  cases.
- [x] Demonstrated the way #177 was — shown above, before/after on `test-hold-line`.

## Not this task

Task 2 (checking an absolute path's `atX` against its entry waypoint) and everything after it in the
plan's sequencing — this branch is task 1 only, closing #310.
