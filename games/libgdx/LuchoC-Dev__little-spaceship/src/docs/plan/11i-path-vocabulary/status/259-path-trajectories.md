# 259 — a path is a list of bounded segments, and a shape can be mirrored

**Branch:** `feat/path-trajectories`. **Closes:** [#259](https://github.com/LuchoC-Dev/little-spaceship/issues/259).

## What shipped

A third `TrajectoryDefinition` kind, `PathTrajectoryDefinition`, and a small companion record,
`PathSegment` (`vx`, `vy`, `duration`) — both in `core/port/`.

- **Segments.** A path is an ordered, non-empty list of `PathSegment`s. Evaluating at a given
  `elapsedSeconds` walks the list accumulating durations to find the active segment — arithmetic on
  the definition's own fixed parameters, no per-entity state beyond what `Trajectory` already holds
  (`trajectoryId`, `elapsed`).
- **Waits.** Not a distinct case: a wait is a `PathSegment` with `vx = 0, vy = 0`. An "indefinite"
  wait is the same thing with a very large `duration`.
- **Bounded repeats.** `loopStart` (index into `segments`) and `loopCount` (>= 1, repeats including
  the first pass) mark a trailing range that plays `loopCount` times before the path continues past
  it. A "permanent" loop is a large `loopCount`, not a fourth case.
- **The turn.** `TrajectoryDefinition` gained `horizontalVelocityAt(float elapsedSeconds)`, a
  `default` method returning `vx()` unconditionally — exactly right, and a no-op, for `constant` and
  `arc`. Only `PathTrajectoryDefinition` overrides it. `MotionSystem.advanceTrajectories` now writes
  both `Motion.vx` and `Motion.vy` from the trajectory's evaluation each tick, symmetric with the
  existing `vy`-only re-evaluation `#164` built.
- **Mirroring.** Not a fourth sealed permit and no new core API: every kind here is a public record
  whose fields are all readable through their accessors, so a mirrored copy of any of them — negate
  `vx` (per-segment, for a path), keep every vertical field, assign a new id — is built with the same
  public constructor the original went through. This lives entirely at content-load time, in
  `game/`, task 2's territory; `core` needs to know nothing about it. Argued in
  `TrajectoryDefinition`'s own javadoc and demonstrated by
  `PathTrajectoryDefinitionTest.mirroringIsComposedFromTheSamePublicConstructor`, which builds a
  mirror from `veerLeft.segments()` without touching any new type.

## Rule 3 — every expressible path leaves the playfield in finite time

**Answered by making the one shape that could violate it unconstructible, at load, not at runtime.**
`PathTrajectoryDefinition`'s compact constructor throws `IllegalArgumentException` if the *last*
segment in the list — which is also the last segment of any loop range, since a loop range always
ends at the list's end — has `vx == 0 && vy == 0`. Past a path's authored total duration, evaluation
holds that last segment's velocity indefinitely (the extrapolation this same check relies on), so a
path that could never leave is refused before it can ever be attached to an entity.

This is a *necessary* condition, not a proof that every authored path geometrically crosses the
playfield's edge from wherever a wave places it — that still depends on `atX`, exactly as
`shape-catalogue.md` already checks arc's entries by hand. What is refused unconditionally is the one
case that is wrong regardless of placement: a path that comes to rest and stays there.

Tests carrying the rule by name:
`everyPathMustLeaveThePlayfield_pathThatEndsAtRestIsUnconstructible`,
`everyPathMustLeaveThePlayfield_loopEndingAtRestIsUnconstructible`
(`core/src/test/java/dev/luchoc/littlespaceship/core/port/PathTrajectoryDefinitionTest.java`).

## The two refusals, struck through and dated

`docs/plan/11c-movement-shapes/shape-catalogue.md`, "What is refused":

- **`enterAndHold` / station-keeping — reopened.** The hazard it named still holds for the
  *unbounded* case; the project owner's own sketches are the written case that did not exist when it
  was refused, and phase 11i answers by bounding every wait and every loop.
- **Waypoints, splines, segment lists — dissolved, not overridden.** The cost the refusal named —
  "per-entity path state well beyond the elapsed-time clock" — stopped applying once every segment's
  duration and every loop's count are fixed at content-load time; the evaluation is still a pure
  function of `elapsed` and the definition's own parameters.

## The shared JSON contract

Posted on the issue: https://github.com/LuchoC-Dev/little-spaceship/issues/259#issuecomment-5543095453

`"type": "path"`, a `segments` array of `{vx, vy, duration}`, optional `loopStart`/`loopCount`.
Mirroring is a loader-side concern (a `mirrorOf` key resolved against an already-parsed definition,
or however `game-presentation` prefers to spell it) — `core` exposes no API for it because none is
needed.

## What is not mine and was not touched

`core/domain/system/CleanupSystem.java`, `core/domain/component/Motion.java`,
`core/domain/system/LifetimeSystem.java`, `assets/data/balance.json`, and `game/` — the loader
(task 2) and any content entries (task 3) are out of scope here.

## Verified

- `./gradlew :core:test` — green. New tests: `PathTrajectoryDefinitionTest` (15 cases) and one
  addition to `MotionSystemTest` (`pathShapeTurnsHorizontalVelocity`).
- `./gradlew build` — green, full repo, confirming `game/`, `desktop/` and `web/` still compile
  against the widened `TrajectoryDefinition` (no exhaustive `switch` on the sealed type existed
  outside `core`, so adding the third permit broke nothing there).
- No `com.badlogic.gdx` import anywhere touched — `core/build.gradle` unchanged, JDK-only
  dependencies.
- No clock read, no `Math.random()`, no thread/executor/lock anywhere touched.
- No per-frame allocation in the evaluation path: `segmentAt` uses only primitive locals and
  `List.get`, no new object per call.
- **Not checked**: the game was not launched this task — nothing here touches `game/`, `desktop/` or
  `web/` beyond compiling against the widened interface, so there is nothing runnable to confirm that
  "launch once to see it start" would add.
