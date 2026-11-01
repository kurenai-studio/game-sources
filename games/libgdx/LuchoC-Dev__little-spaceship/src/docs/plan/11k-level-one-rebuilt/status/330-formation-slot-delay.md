# 330 — a formation slot can follow the one ahead of it, delayed in time

**Branch:** `feat/formation-slot-delay`. **Closes:** [#330](https://github.com/LuchoC-Dev/little-spaceship/issues/330).
`core-domain`, `core/` only. The loader (`game/adapter/content/JsonContentSource.java`) and any
content that uses this are separate branches, not touched here.

**Correction (2026-09-06, issue [#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337)):
this fragment's central claim — that a delayed slot traces the leader exactly `N` ticks behind — was
false as written, for roughly a fifth of all tick counts.** The mechanism below backdated
`Trajectory.elapsed` to `-delaySeconds` and held the entity still while that float stayed at or below
zero. That crossing compared two different float arithmetic paths to the same target — the delay
itself, formed by a single multiplication, against `elapsed`'s own repeated addition of `step` — which
do not generally agree bit-for-bit. Swept over delays of 1..300 ticks, the bands **18–40 and 258–300**
crossed zero one tick early, permanently. `#337` replaced the float crossing with an integer tick
countdown (`Trajectory.delayTicks`) and corrected `SpawnSystemTest` to sweep the full 1..300 range
instead of the two values (1 and 12) that happened to sit outside both failing bands. Everything below
this notice describes the design **as it stood before that fix** except where marked otherwise; read
`docs/plan/11k-level-one-rebuilt/status/337-delay-crossing-in-ticks.md` for what changed.

## What was built

`FormationSlot` gained a third field, `delaySeconds` (`float`, must be finite and `>= 0`), plus a
back-compat two-argument constructor that defaults it to `0f` — every existing call site (`game`'s
loader included) compiles unchanged. Position and delay are separate levers, per the issue: a
single-file column is `offsetX 0`, `offsetY 0` and a nonzero delay on the following slots; every
formation that predates this issue keeps its offsets and a delay of `0`.

`SpawnSystem.spawnWave` gained one step, `applySlotDelay`, run right after a slot's `Trajectory` is
attached (whether from the archetype's own default `"motion"` spec or from a spawn event's
override) and right before `positionSpawned`: for a slot with `delaySeconds > 0`, it backdates that
entity's `Trajectory.elapsed` to `-delaySeconds`. No new component, no new field on `Trajectory` —
the one field it already carries (`elapsed`, a plain `float`) simply starts earlier than usual.
`positionSpawned` is untouched: a delayed slot's `offsetX`/`offsetY` still place it exactly where a
non-delayed slot with the same offsets would, which is what lets a single-file column start every
slot at the identical point and only diverge once each one's own delay elapses.

`MotionSystem.advanceTrajectories` gained the other half: while an entity's `Trajectory.elapsed` is
**at or below zero** (`<= 0f`, not `< 0f` — see below), its `Motion` is pinned to `(0, 0)` instead of
being evaluated against the shape at a meaningless negative time. Once `elapsed` becomes strictly
positive, the shape is evaluated exactly as it always was — `definition.horizontalVelocityAt(elapsed)`
/ `verticalVelocityAt(elapsed)` — with no branch specific to a delayed entity at that point, because
by then there is nothing to distinguish it from an entity that was never delayed.

## The decision: present, holding still — not absent

**A delayed slot's entity exists from the tick its wave spawns it**, with a real `Transform`,
`Collider`, `WaveOrigin` and (if the archetype has one) `Health` — everything a non-delayed
sibling gets, spawned the same tick, at the same position. It simply does not move until its own
`Trajectory.elapsed` turns positive.

Reasons, in order of weight:

1. **Invariant 6.** The alternative — the entity does not exist until its delay elapses — needs a
   second spawn-scheduling mechanism sitting alongside `SpawnSystem`'s own wave timeline (something
   has to remember "this slot is still owed an entity, N seconds from now, at this position").
   That is a general per-entity scheduler for the one case this issue actually asks for: a
   single-file column in level 1. The chosen design needs none of that — it reuses the one piece of
   state `Trajectory` already carries.
2. **It stays a pure function of elapsed time.** `Trajectory` already commits, in its own class
   javadoc, to "a function from the entity's own elapsed time to its velocity. Nothing else goes
   in." A negative starting `elapsed` is still exactly that function, just started before the
   entity's first *visible* move — no origin field, no waypoint index, no per-entity flag for
   "have I started yet."
3. **Every existing formation is provably unaffected.** A slot with no delay has `Trajectory.elapsed`
   start at `0`; the very first tick's `elapsed += step` already makes it strictly positive (since
   `step > 0`), so the `<= 0f` branch never fires for it. This is what keeps every one of the five
   replays and every existing `SpawnSystemTest` green with no changes to either.

**Consequences for the two systems the issue named:**

- **The safety box.** Every wave already spawns fully off-screen — `SpawnSystem`'s own javadoc: "the
  slot closest to being visible is measured against the playfield edge, and every other slot ends up
  further above it." A delayed slot at `offsetY 0` (the single-file case) is born at exactly
  `PLAYFIELD_HEIGHT + radius`, off-screen, same as every other slot. Holding still there for
  `delaySeconds` changes nothing about `LifetimeSystem`'s off-screen check or the 128-unit safety
  margin (see `docs/plan/.../entity-lifetime-and-safety-box` in `core-domain`'s agent memory): the
  entity is simply stationary at a point already outside the box, not inside it.
- **A `cleared` wave.** `WaveEndCondition.Cleared` asks "does any entity still carry this wave's
  `WaveOrigin`" — a held-still delayed slot answers "yes" for the whole delay, exactly like a
  non-delayed one answers "yes" for however long it takes to cross the playfield. A `cleared` wave
  with only delayed slots left simply waits longer before it can end; nothing new needed to make that
  correct, since `noEntityCarries` already scans every live entity regardless of whether it has ever
  moved.

## Why `<= 0f`, not `< 0f`

This is the detail the acceptance criterion — "a test that compares positions at `t` and `t − delay`
rather than by watching it move" — actually needs to hold exactly, not approximately.

`MotionSystem` increments `elapsed` before evaluating it. For an undelayed entity, the very first
evaluation happens at `elapsed = step` (one tick in), never at `elapsed = 0` — the position at
`elapsed == 0` (the instant of spawning, no movement yet) is never itself an evaluation point; it is
only ever the *starting* transform. For a slot delayed by exactly `N` ticks (`delaySeconds = N *
step`), if the held branch stopped at `elapsed < 0`, its first *active* evaluation would land at
`elapsed = 0` exactly — one tick earlier, relative to its own delay, than the undelayed entity's own
first evaluation at `elapsed = step`. That one-tick misalignment would show up as a small but
permanent position drift between the two entities' traced paths, not a clean `delay`-seconds offset.

Including `elapsed == 0` in the held branch closes that gap: both entities' first active evaluation
happens on the tick where their own `elapsed` first becomes **strictly positive**, so a slot delayed
by `N` ticks reproduces, from tick `N` onward, the *identical* sequence of velocity evaluations — and
therefore the identical sequence of Euler integration steps in `integrate` — that the undelayed slot
produced from tick `0`. The positions are then not merely close, they are bit-for-bit identical,
`delaySeconds` later. `SpawnSystemTest.delayedSlotTracesLeaderPositionsExactlyDelayTicksBehind`
(`delayTicks = 12`) pins the resulting position match with exact (delta-free) `assertEquals` calls on
the traced `Transform.x`/`y`, comparing the delayed slot's position at tick `t` against the undelayed
slot's own recorded position at tick `t - delayTicks`, using an `ArcTrajectoryDefinition` (a shape
whose velocity actually varies with elapsed time, so a wrong tick alignment could not hide behind a
constant velocity).

**Correction, from `reviewer`'s review of PR #331: that test does not actually exercise the `== 0`
boundary this section argues for.** Float accumulation of `-delaySeconds` by repeated `+= step` does
not, in general, land on exactly `0.0f` at the crossing pass — at `delayTicks = 12` it lands on
`-2.6e-8`, already negative, so `elapsed <= 0f` and `elapsed < 0f` behave identically there and the
test above stays green under either. `delayTicks = 1` and `delayTicks = 2` are the only two counts
where `-N*step + N*step` is an exact float `0.0f` (`-1*step + step` and `-2*step + 2*step` both
round-trip to bit-identical values), so
`SpawnSystemTest.delayedSlotWithOneTickDelayTracesLeaderExactly` (`delayTicks = 1`) is the test that
actually pins the boundary: confirmed by hand that mutating `elapsed <= 0f` to `elapsed < 0f` in
`MotionSystem.advanceTrajectories` turns it red immediately, while leaving the `delayTicks = 12` test
green. The general correctness argument two paragraphs up still holds for every `delayTicks`, exact
float crossing or not — the boundary only becomes *observable* at the two counts where the crossing
happens to land on exactly zero.

## Where it sits in `SystemOrder`

No new system, no change to `SystemOrder`. The backdating happens inside `SpawnSystem` at
`SystemOrder.SPAWN` (unchanged, fifth), the same stage that already turns a `FormationSlot`'s offsets
into a `Transform`. The held-still evaluation happens inside `MotionSystem` at `SystemOrder.MOTION`
(unchanged, second) — the same stage, and the same method (`advanceTrajectories`), that already
re-evaluates every `Trajectory` every tick. Because `MOTION` runs before `SPAWN` in the fixed
pipeline, an entity spawned (and delay-backdated) this tick is never touched by `MOTION` until the
*next* tick — exactly the one-tick lag every entity already has for its first movement, delayed or
not; nothing about this issue changes that ordering or needs to.

## What the loader (the other half) will need

- `FormationSlot` now takes an optional third argument: `new FormationSlot(offsetX, offsetY,
  delaySeconds)` when a slot's JSON has a `"delaySeconds"` (or whatever key name is chosen) field,
  the existing two-argument `new FormationSlot(offsetX, offsetY)` otherwise — both still work, so no
  existing formation's loading code needs to change unless it actually gains a delay.
- `FormationSlot`'s compact constructor throws `IllegalArgumentException` naming the bad value for a
  negative, `NaN` or infinite delay — `JsonContentSource` should let that surface the same way it
  already wraps every other `ContentSource` validation failure with the file name, per that
  interface's class javadoc.
- No change needed to `WaveDefinition`, `SpawnEvent`, or anything else a formation's slot did not
  already touch — `delaySeconds` is entirely local to `FormationSlot`.

### A decimal `delaySeconds` a content author actually types will drift by one tick — read this before authoring one

`reviewer` found this on PR #331 and it belongs here because the loader is where it gets decided and
nobody would otherwise think to look for it. **"Traces exactly" (the claim this fragment and
`SpawnSystemTest` make) only holds when `delaySeconds` is precisely `N * (1/60f)` for some integer
`N`, reached by float addition the same way `MotionSystem` reaches it — not for the decimal a person
would naturally type in JSON.**

`Trajectory.elapsed` is an `IEEE-754 float`. `SpawnSystem` sets it once to `-delaySeconds` (the exact
float bit pattern of whatever literal the loader parsed); `MotionSystem` then reaches zero by adding
`step` (`1f/60f`) to it, once per tick. Those are two different paths to the same target value, and
float rounding does not generally make them agree bit-for-bit. I simulated the five decimal values a
person would plausibly write for a delay — `0.05`, `0.1`, `0.3`, `0.5`, `1/3` — accumulating `step` in
32-bit float exactly the way `MotionSystem` does, and compared the tick on which each one actually
turns active against the tick a whole-number-of-ticks reading of the same value would predict:

```
delaySeconds=                0.05 delay(f32)=0.05000000074505806    active_pass=3    ideal_active_pass=4    drift(ticks)=-1
delaySeconds=                 0.1 delay(f32)=0.10000000149011612    active_pass=7    ideal_active_pass=7    drift(ticks)=0
delaySeconds=                 0.3 delay(f32)=0.30000001192092896    active_pass=18   ideal_active_pass=19   drift(ticks)=-1
delaySeconds=                 0.5 delay(f32)=0.5                    active_pass=30   ideal_active_pass=31   drift(ticks)=-1
delaySeconds=  0.3333333333333333 delay(f32)=0.3333333432674408     active_pass=20   ideal_active_pass=21   drift(ticks)=-1
```

**Four of the five — `0.05`, `0.3`, `0.5` and `1/3` s — turn active one tick earlier than a
whole-number-of-ticks reading predicts; only `0.1` lands exactly right.** Note that `0.5` drifts even
though it is itself exactly representable as a float (`0.5f` is exact): the drift is not in the
literal, it is in the fact that summing `step` thirty times does not land on exactly `0.5f` — the
same rounding this fragment's "Why `<= 0f`, not `< 0f`" section already found for `delayTicks = 30`.
The direction is consistently early by one tick in this sample, but that is an observation about
these five values, not a proven general bound — I have not shown it can never drift by more than one
tick or never drift late.

**Two ways out, neither built here — the loader decides:**

1. **Quantise `delaySeconds` to the nearest whole tick when parsing the JSON**, i.e. compute
   `Math.round(delaySeconds * 60f) * (1f / 60f)` and pass that into `FormationSlot`, so the value
   `SpawnSystem` backdates `elapsed` to is already an exact multiple of `step` reached the same way
   `MotionSystem` reaches zero from it. Keeps the JSON authoring surface in seconds, matching every
   other timestamp in this content (`SpawnEvent.at`, `PlacedPickup.at`).
2. **Require the JSON to carry a tick count instead of seconds** (e.g. `"delayTicks": 12`, converted
   to `delayTicks * (1f / 60f)` before constructing `FormationSlot`) — removes the rounding question
   entirely by construction, at the cost of a delay being authored in a different unit from every
   other timestamp in the content this project has shipped so far.

Reproduction script (Python, mirroring the `float` arithmetic by hand — nothing here needs the JVM):

```python
import struct
def f32(x):
    return struct.unpack('f', struct.pack('f', x))[0]

step = f32(1.0/60.0)
for delaySeconds in [0.05, 0.1, 0.3, 0.5, 1.0/3.0]:
    delay = f32(delaySeconds)
    elapsed = f32(-delay)
    pass_n = 0
    while True:
        elapsed = f32(elapsed + step)
        pass_n += 1
        if elapsed > 0:
            active_pass = pass_n
            break
    ideal_active_pass = round(delaySeconds / (1.0/60.0)) + 1
    print(delaySeconds, delay, active_pass, ideal_active_pass, active_pass - ideal_active_pass)
```

## Acceptance criteria

- [x] A formation slot can carry a delay, and a slot with one traces the same path through the same
  points as the slot ahead of it — `delayedSlotTracesLeaderPositionsExactlyDelayTicksBehind`
  (`delayTicks = 12`) and `delayedSlotWithOneTickDelayTracesLeaderExactly` (`delayTicks = 1`, the
  count that actually pins the `<= 0f` boundary, added after `reviewer`'s finding on PR #331) in
  `SpawnSystemTest`, both comparing positions at `t` and `t − delay` (see above), not by watching
  motion. **Superseded by #337 (2026-09-06): both counts happened to fall outside the two bands
  (18–40 and 258–300) where this guarantee actually failed; #337 replaced them with a swept test over
  the full 1..300 range and replaced the float crossing itself with an integer countdown. See the
  correction notice at the top of this fragment.**
- [x] Its place in `SystemOrder` is stated and justified above; pinned by every existing
  `SystemPipelineTest`/`SimulationTest` assertion on stage order, which needed no change since
  neither stage moved.
- [x] A formation with no delay behaves exactly as before: `./gradlew :core:test` green with zero
  changes to any pre-existing test, and `./gradlew build` (all five replays included) green.
- [x] What a delayed slot is before its path begins — decided above: present, real, holding still.
  Asserted by the same test's "held still before its own path begins" assertions for `t < delayTicks`.
- [x] `core` still has no libGDX on its classpath (`grep -rn "com.badlogic.gdx" core/src/main/java`
  prints nothing), reads no clock, calls no `Math.random()`. `./gradlew build` green.
- [x] The loader half is not built here — see "What the loader will need" above.

## Commands run

- `./gradlew :core:test --console=plain` — green, all new and existing tests pass, no test needed
  modification.
- `./gradlew build --console=plain` — green across every module (`core`, `game`, `web`, `desktop`,
  `rngparity`), confirming the back-compat `FormationSlot` constructor kept `game` compiling with no
  source change on that side.
- `grep -rn "com.badlogic.gdx\|Math.random\|System.currentTimeMillis\|new Thread\|ExecutorService"
  core/src/main` — the one hit is `Rng`'s own class javadoc explaining why it does *not* use
  `Math.random()`; no other match.
- Mutation check on the `<= 0f` boundary, per `reviewer`'s finding: manually changed
  `MotionSystem.advanceTrajectories`'s `elapsed <= 0f` to `elapsed < 0f`, ran
  `./gradlew :core:test --tests "*SpawnSystemTest*delayedSlot*"` — `delayedSlotWithOneTickDelayTracesLeaderExactly`
  (`delayTicks = 1`) failed immediately (`AssertionFailedError`),
  `delayedSlotTracesLeaderPositionsExactlyDelayTicksBehind` (`delayTicks = 12`) stayed green, matching
  `reviewer`'s own report. Reverted the mutation (`git diff` on `MotionSystem.java` empty afterward),
  then reran `./gradlew :core:test` — green.
- `python3` — reproduced the decimal-`delaySeconds` drift table in the loader-facing section above;
  script and output are inline there.
