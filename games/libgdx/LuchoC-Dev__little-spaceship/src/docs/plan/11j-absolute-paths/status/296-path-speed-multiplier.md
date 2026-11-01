# 11j task 2 — the same path run faster, without changing size

**Issue:** [#296](https://github.com/LuchoC-Dev/little-spaceship/issues/296) · **Branch:** `feat/path-speed-multiplier` · **Agent:** `game-presentation`

## What was built

A trajectory may be declared as another trajectory traversed faster:

```json
{ "id": "descend-and-turn-left-fast", "speedOf": "descend-and-turn-left", "multiplier": 2 }
```

`speedOf` names the source, `multiplier` is required, finite and strictly positive; no other key is
allowed on such an entry. `multiplier: 2` means "half the time". The full syntax is posted as a
comment on the issue, per the phase's own rule, so the content task does not guess.

It lands in `game/src/main/java/dev/luchoc/littlespaceship/game/adapter/content/JsonContentSource.java`:

- `loadTrajectories` now collects **derived** entries — `mirrorOf` (#264) *and* `speedOf` — into one
  map and resolves them in the same second pass. `resolveMirror` became `resolveDerived` and
  dispatches on which key the entry carries.
- `faster(id, original, multiplier)` is the new builder, symmetric with the existing `mirror(...)`:
  composition over the public record constructors, **no new `core` API**.
- `requireMultiplier(entry, id)` validates the number.

Tests are in `game/src/test/java/.../JsonContentSourceSpeedMultiplierTest.java`, a new file (kept
separate so a parallel task in the same production file does not also collide on a test file, the
same reason `JsonContentSourceAbsolutePathTest` is separate). 16 tests.

## Where it resolves, and why — the decision the task asked to argue

**At load.** Both were considered:

- **At load (chosen).** Authoring sugar over the records `core` already takes, exactly like
  `mirrorOf` and the `wait` shorthand. It costs one named entry per speed, and at this scale that is
  a feature: 11k reads `trajectories.json` as a vocabulary, and a wave saying "use `dive-fast`" is
  more readable than a numeric field on a spawn event. `core` is untouched, so nothing crossed a
  module boundary that is not mine.
- **On the spawn event (not built).** `SpawnEvent` already carries a per-spawn `trajectoryId`
  override, so a `speedMultiplier` beside it would be structurally natural — and it buys a **different
  capability**, not the same one built differently: one shape at two speeds *inside one wave*, or a
  speed that varies without a named entry per value. It costs a `core` contract change (a
  `SpawnEvent` field and `SpawnSystem` applying it), which is `core-domain`'s module. **Nothing
  written asks for two speeds of one shape in one wave** — the plan asks for "the same path run
  faster" — so invariant 6 refuses it. The two would compose if it is ever wanted: it is the same
  arithmetic, applied at a different moment.

## The arithmetic, and the one part that is not obvious

The transform is the substitution `t -> k·t` applied to each kind's own closed form, so the traced
curve is pointwise the same set of positions:

| Kind | Transform |
|---|---|
| `constant` | `vx`, `vy` × k — the ray keeps its direction, both components scale together |
| `arc` | `vx`, `vy` × k and **`ay` × k²** |
| `path` | per segment: `vx`, `vy` × k, `duration` ÷ k; `loopStart`/`loopCount` copied |

**`ay` takes the square, and that is the whole subtlety.** From `y = vy·t + ay·t²/2`, the scaled arc
evaluated at `t/k` gives `k·vy·(t/k) + k²·ay·(t/k)²/2 = vy·t + ay·t²/2` — the same parabola. Scaling
`ay` linearly, which is what "make everything faster" suggests, would produce a *different curve*.

Both `path` authoring forms are covered: `"segments"` (relative) and `"waypoints"` (absolute, #287).
A waypoint path sped up still reaches exactly the coordinates it names, sooner. A `{"wait": s}` stays
a wait and lasts `s/k` — zero velocity times anything is zero.

## Evidence

- `./gradlew :game:test --tests '*SpeedMultiplier*'` → `tests="16" skipped="0" failures="0"
  errors="0"` (read from `game/build/test-results/test/TEST-...SpeedMultiplierTest.xml`).
- `./gradlew build` → `BUILD SUCCESSFUL`.
- **The geometry claim is mutation-checked, not assumed.** With `faster` mutated to the *other*
  meaning of faster — velocities up, durations left alone, i.e. a `scale` — the run was
  `16 tests completed, 5 failed`:
  `aPathRunFasterTracesTheSameGeometryInAFractionOfTheTime`,
  `everySegmentKeepsItsDirectionAndDisplacementWhileTheTotalDurationIsDivided`,
  `aWaypointAuthoredPathCanBeSpedUpToo`, `aLoopingPathKeepsItsLoopRangeAndRepeatCount` and
  `anArcRunFasterKeepsItsParabolaAndItsCurvature` (that last one also covers the `ay × k` mutation,
  applied in the same run). The mutation was reverted; the diff is the unmutated code.
- The geometry tests **do not recompute the loader's arithmetic**: they integrate `core`'s own
  `horizontalVelocityAt`/`verticalVelocityAt` and compare the fast trajectory at `t/k` against the
  original at `t`, *and* both against positions worked out by hand from the JSON written directly
  above them.
- **The shipped `assets/data` still parses.** Checked with a throwaway test constructing
  `new JsonContentSource(new FileHandle(new File("../assets/data")), "level-01")` — `BUILD
  SUCCESSFUL` — then deleted, because `assets/data` is off limits to this task and a test asserting
  anything about its contents would collide with `level-designer`'s parallel branch.
- **The game was launched once, to confirm it starts** (`./gradlew :desktop:run`, killed after 45 s,
  no exception in the log). Not played, and not navigated: real content loads in `PlayScreen`, past
  the menu, so that launch is *not* evidence that `trajectories.json` parses — the throwaway test
  above is.

## Acceptance criteria

| Criterion | State |
|---|---|
| Same trajectory faster without changing size, with a test asserting the geometry is unchanged | **Pass** — traced through `core`'s evaluation and against hand-computed positions; mutation-checked |
| Every new failure names the file and the id | **Pass** — zero, negative, non-finite and missing multiplier, extra key, unknown source, cycle; each test asserts both `trajectories.json` and the id appear |
| Rule 3 still holds, tried through the new form | **Pass** — the derived path goes back through `PathTrajectoryDefinition`'s constructor; a zero velocity × k is still zero, so a path that ends at rest cannot be laundered through `speedOf`. `aMultiplierCannotLaunderAPathThatEndsAtRestPastRule3` |
| Every expressible path still leaves the playfield in finite time | **Pass** — `PathTrajectoryDefinitionTest` (in `core`) unchanged and green in `./gradlew build` |
| `./gradlew build` green | **Pass** |
| CI green | **Checked on the branch after pushing — see the pull request** |

## Notes for whoever comes next

- **A `scale` was not built**, deliberately. The mutation run above is what the other meaning of
  "faster" looks like, and it is exactly what the tests refuse.
- **`speedOf` and `mirrorOf` now share one resolution pass.** Adding a third derivation is a branch in
  `resolveDerived` and a builder beside `mirror`/`faster`; cycle detection and order-independence come
  for free.
- **An absolute (`waypoints`) path sped up inherits #287's unresolved cost unchanged**: its
  coordinates only mean what they say at `atX = 0`. Nothing here makes that better or worse.

## Corrected by the coordinator after review, before merge

`reviewer` accepted this branch with one finding, and the correction is the coordinator's because the
worker was already closed. It is prose in two files, no behaviour changed.

`faster()`'s javadoc and the test then called
`aMultiplierThatUnderflowsASegmentDurationFailsNamingTheDerivedId` both said an absurd multiplier is
refused because it **underflows a duration to zero**. It is not. With that test's own numbers —
`vy = -30`, `multiplier = 3e38` — `vy * multiplier` is `-9e39`, which overflows to negative infinity
and trips `PathSegment`'s finiteness check on the **velocity**, while `duration / multiplier` is
`3.33e-39`: subnormal, and not zero. `reviewer` reproduced this by constructing a `PathSegment`
directly in a scratch copy; the coordinator re-derived the arithmetic before applying the fix.

The guard named was one that, at any velocity worth authoring, never fires. **The observable
behaviour was always right** — it fails, and it names the file and the derived id — so this changed
no test's assertion, only what the test and the javadoc claim about *why*. The test is now
`aMultiplierThatPushesASegmentOutOfFloatsRangeFailsNamingTheDerivedId`, and both places say the
velocity gives way first.

Worth noting where the wrong claim came from: the syntax comment posted on
[#296](https://github.com/LuchoC-Dev/little-spaceship/issues/296) hedged it correctly — "a velocity
**or** a duration out of range". The narrower, wrong version appeared only when it was written into
the code.

`./gradlew :game:test --tests '*SpeedMultiplier*'` after the change: green.
