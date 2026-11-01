# 337 — take the float out of a delayed slot's crossing

**Branch:** `fix/delay-crossing-in-ticks`. **Closes:**
[#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337).
`core/` only, plus the two merged status fragments this issue named for correction and this one.

## What was wrong

`MotionSystem.advanceTrajectories` decided whether a delayed formation slot should still be held
still by comparing `Trajectory.elapsed` against zero — `elapsed <= 0f`. `elapsed` reached that
crossing by **repeated addition**, `+= step` once per tick, starting from `-delaySeconds`.
`delaySeconds` itself, wherever it was constructed — the loader's `Math.round(rawDelaySeconds * 60f)
* TICK_SECONDS`, or `core`'s own test fixtures' `delayTicks * step` — was a **single multiplication**.
Those two float arithmetic paths to the same nominal target do not generally agree bit-for-bit. Swept
over delays of 1..300 ticks, the crossing landed one tick early, permanently, for the bands **18–40
and 258–300** — about 22% of all tick counts, including `0.3 s` (18 ticks), the flagship example both
#330 and #334 used.

Neither #330's nor #334's own tests caught it: `SpawnSystemTest` exercised only `delayTicks = 1` and
`delayTicks = 12`, both outside the failing bands, and the loader's tests stopped at parsing without
ever driving a real `SpawnSystem`/`MotionSystem` pipeline. `reviewer` found it on PR #336 by building
the end-to-end check neither half had.

## What was built

**`Trajectory` gained a second field, `delayTicks` (`int`, defaults `0`), alongside `elapsed`.**
`elapsed` no longer ever goes negative: it always starts at, and is held at, `0`. Holding an entity
still is now an integer countdown, decremented by exactly one every tick in
`MotionSystem.advanceTrajectories`, with `elapsed` untouched until the countdown reaches zero:

```java
if (trajectory.delayTicks > 0) {
    trajectory.delayTicks--;
    if (motion != null) {
        motion.vx = 0f;
        motion.vy = 0f;
    }
    continue;
}
trajectory.elapsed += step;
```

`SpawnSystem.applySlotDelay` sets `delayTicks` instead of backdating `elapsed`:
`Math.round(slot.delaySeconds() / step)`. `step` reaches this method by threading it down from
`update` through `spawnDue` and `spawnWave` — none of the three previously took it, since nothing
before this issue needed the tick length inside `SpawnSystem`.

**Why this removes the float entirely, not just moves it.** `delaySeconds` is, by the time it reaches
a slot, already an exact multiple of `step` — the loader quantises it on parse, and every `core`
fixture constructs it as `delayTicks * step` — so `Math.round(delaySeconds / step)` only ever undoes
the single rounding step that produced it; it introduces none of its own. The crossing itself is then
a plain integer comparison (`delayTicks > 0`), never a float compared against a target that could
itself carry rounding error. Once the countdown reaches zero, `elapsed` accumulates from `0` exactly
as an undelayed entity's always has, so the two entities' sequences of velocity evaluations — and
therefore of Euler integration steps — are identical from that point on, not merely close.

**A formation with no delay is untouched.** `delayTicks` defaults to `0`, so the countdown branch
never fires for it and `elapsed` accumulates on the very first tick exactly as before. `node
tools/build-level-docs.js` prints `unchanged` for both generated documents, and all five replay test
classes (`BombReplayTest`, `BossReplayTest`, `DamageReplayTest`, `LevelScoreReplayTest`,
`SimulationTest`) pass unchanged.

## The swept test

`SpawnSystemTest.delayedSlotTracesLeaderExactlyForEveryTickCountInSweptRange` replaces the two
single-value tests (`delayTicks = 1` and `delayTicks = 12`) with a loop over every `delayTicks` from 1
to 300, each one running the same exact-position comparison the old tests did (leader vs. follower
positions through an `ArcTrajectoryDefinition`, delta-free `assertEquals`). This is deliberately a
sweep, not a curated set of "interesting" values: the old tests' two values happening to fall outside
both failing bands is exactly what hid this defect for two tasks in a row, so picking values by hand
again would repeat the same mistake with different numbers.

Follower/leader identification changed too: since `elapsed` can no longer go negative, the old
`trajectory.elapsed < 0f` check to tell the two entities apart no longer works. The test now uses
`ComponentStore`'s own append-only, dense-packed insertion order (documented on the class itself) —
slot 0 (no delay) is always `entityAt(0)`, slot 1 (the delayed one) is always `entityAt(1)`, since
`spawnWave` creates entities in slot order.

## Proving it end to end

The property this issue is actually about — a delay authored in content, through the loader's own
quantisation, through a real `SpawnSystem`/`MotionSystem` run — is a joint one between `core` and the
loader, which is the whole reason this defect existed: each half was verified alone. `game`'s
`JsonContentSourceFormationDelayTest` gained
`aQuantisedDelayTracesTheLeaderExactlyThroughARealSpawnAndMotionPipeline`, which:

1. Writes a `formations.json` with a leader slot (no delay) and a follower slot carrying a
   `delaySeconds` value chosen to land in one of the two failing bands after quantisation (`0.3` → 18
   ticks, and `280 * TICK_SECONDS` → 280 ticks).
2. Loads it through a real `JsonContentSource` (a `waves.json` + a `"waves"`-shaped level file, since
   `SpawnSystem` reads `ContentSource.placements`, not the legacy flat `"events"` list `load`'s shared
   fixture writes — the level-test fixture's existing `"events"` file is unused by this test for that
   reason).
3. Confirms the loaded `FormationSlot.delaySeconds()` already equals the expected tick count.
4. Runs a real `SpawnSystem.update` followed by real `MotionSystem.update` ticks and asserts the
   follower traces the leader exactly `N` ticks behind, for both `N`.

This is the test that crosses the loader seam the issue asked for; the 1..300 sweep in
`SpawnSystemTest` stays `core`-only and exhaustive, while this one confirms the two halves agree at
the two previously-failing points without repeating a 300-iteration sweep through file I/O.

## No `game` production code changed

`JsonContentSource.java` needed no change: its own quantisation
(`Math.round(rawDelaySeconds * 60f) * TICK_SECONDS`) already produced exactly the value `core`'s fixed
crossing consumes correctly. The mismatch was entirely inside `core`'s use of that value, never in how
the loader constructed it — confirmed by the end-to-end test above passing with the loader completely
unchanged.

## The two merged fragments corrected

- `docs/plan/11k-level-one-rebuilt/status/330-formation-slot-delay.md` — a correction notice added at
  the top, dated 2026-09-06, naming the false claim (the exactness guarantee held in general) and the
  failing bands; the relevant acceptance-criterion line is marked superseded.
- `docs/plan/11k-level-one-rebuilt/status/334-loader-reads-slot-delay.md` — an update notice added at
  the top stating #337 is now fixed, that the loader's own quantisation needed no change, and naming
  the new end-to-end test.

## Where it sits in `SystemOrder`

Unchanged. No new system, no change to `SystemOrder`. The countdown happens inside `MotionSystem` at
`SystemOrder.MOTION` (unchanged, second), the same stage and the same method
(`advanceTrajectories`) that already held the entity still under the old design. The countdown's
initial value is still set inside `SpawnSystem` at `SystemOrder.SPAWN` (unchanged, fifth).

## Acceptance criteria

- [x] A delayed slot traces the leader exactly `N` ticks behind for every `N` in a swept range,
  including 18, the whole 18–40 band, and 258–300 —
  `delayedSlotTracesLeaderExactlyForEveryTickCountInSweptRange` sweeps 1..300 inclusive.
- [x] The crossing no longer depends on float accumulation — `Trajectory.delayTicks` is an `int`,
  decremented by integer subtraction; `elapsed` never goes negative and is never compared against
  zero as a crossing decision.
- [x] A formation with no delay is unchanged: `node tools/build-level-docs.js` prints `unchanged` for
  both documents and all five replays reproduce.
- [x] The two fragments named in the issue are corrected to say what is true, with the bands named.

## Commands run

- `./gradlew :core:test --console=plain` — green, including the new 300-iteration sweep and every
  pre-existing test.
- `./gradlew :game:test --tests "*FormationDelayTest*" --console=plain` — green, including the new
  end-to-end test.
- `./gradlew build --console=plain` — `BUILD SUCCESSFUL` across every module (`core`, `game`, `web`,
  `desktop`, `rngparity`), all five replay suites included.
- `node tools/build-level-docs.js` — printed `unchanged  docs/levels/level-01.md` and
  `unchanged  docs/levels/waves.md`.
- `grep -rn "com.badlogic.gdx\|Math.random\|System.currentTimeMillis\|new Thread\|ExecutorService"
  core/src/main/java` — no hit outside `Rng`'s own class javadoc explaining why it avoids
  `Math.random()`.

## Corrected by the coordinator after review, before merge

`reviewer` accepted this branch and found one thing left stale. The correction is the coordinator's
because it is prose in a file this branch deliberately did not change.

**`JsonContentSource.loadFormations`'s javadoc still described the mechanism this fix deleted.** It
justified quantising at load by explaining how `core` crossed from waiting to moving — backdating
`elapsed` to `-delaySeconds` in one assignment against a step added once per tick — and that crossing
no longer exists. Rewritten to say what the quantisation actually buys, with a dated note saying what
the old explanation claimed and why it went.

**The claim "`JsonContentSource` needed no change" was true and is narrower than it reads.** It is a
claim about code: the file's diff on this fix is empty, and the end-to-end test proves the loader's
quantisation was right all along. It is not a claim about the comments in it, and the difference is
where this one hid.

**This is the fifth instance in phase 11k of the code being right and the prose being wrong** — after
a javadoc naming a guard that never fired, five removal times short by a collider radius, an `atX`
window rounded the wrong way, and the boss's cycle order documented backwards. Every one was found by
someone re-deriving rather than reading, and none by a check.

## Two failure rates for one defect, both real

`reviewer` measured **273 of 300** tick counts failing against the pre-fix code when the delay is
constructed directly as `delayTicks * step`, where its original finding on #336 reported bands
totalling about 66 of 300. Both are correct and they measure different inputs to the same crossing:
the first constructs the delay the way `core`'s own test does, the second the way the loader does
after quantising. The quantisation narrowed the failure surface substantially and did not close it,
which is exactly why the fix belonged in `core`.
