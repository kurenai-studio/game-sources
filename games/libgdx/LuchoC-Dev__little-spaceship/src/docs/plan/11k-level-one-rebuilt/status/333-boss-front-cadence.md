# 333 — lower the boss's front-weapon cadence from N=3 to N=2

**Branch:** `fix/boss-front-cadence`. **Closes:** [#333](https://github.com/LuchoC-Dev/little-spaceship/issues/333).
`core-domain`, `core/` only: `core/src/main/java/.../domain/system/BossSystem.java` and its own test,
`BossSystemTest.java`. Built on top of #329 (merged as PR #332 into `phase/11k-level-one-rebuilt`).

## What changed

**`FRONT_SHOTS_PER_CYCLE` goes from 3 to 2.** One line. `frontPeriod = rearCycleDuration /
FRONT_SHOTS_PER_CYCLE` goes from ≈0.763 s to ≈1.145 s against real content
(`patternCooldown` 0.7 s), and the front fires two shots per cycle (one independent, one coincident
with the rear volley) instead of three. Nothing else about the mechanism changed: the coincidence
still happens the same way, in `updateTelling`, at the instant the rear volley fires; the independent
clock still runs in `updateFrontWeapons`, called every tick of `FIGHT` regardless of `fightStage`.

## The argument that inverts, and why it does not mean the front weapon is now gated

#329 chose `N = 3` over the numerically closer `N = 2` specifically because `N = 2`'s one independent
shot lands at exactly half the cycle, which — in the steady-state order `MOVING → COOLDOWN → TELLING`
that #329's own review correction established — falls inside `COOLDOWN` (36.7%–63.3% of the cycle),
never inside `MOVING` (the first 36.7%). That was written as a hard acceptance criterion: "a front shot
fires while `fightStage == MOVING`, proven by a test."

**The owner played `N = 3`, found it too hard, and asked for the cadence to be lowered — and that
instruction overrides the criterion, not the other way around.** The criterion was the coordinator's
own hardening of the owner's original ask, which was narrower and remains true at `N = 2`: the front
weapon must not be *gated* by movement — it must fire on its own clock whether the boss is stopped or
travelling, never waiting for a move to end or refusing to run during one. That property is untouched:
`updateFrontWeapons` is still called unconditionally every tick of `FIGHT`, still never reads or writes
`fightStage`, and its clock still advances through the entire `MOVING` window without pausing — proven
below. What is given up is only the *stronger*, coordinator-added claim that a shot demonstrably lands
inside `MOVING` at this specific ratio — which was never something the owner asked for by name, only a
way of making "not gated" checkable that stopped being achievable once the owner chose a slower
cadence.

`BossSystem`'s own `FRONT_SHOTS_PER_CYCLE` javadoc is rewritten to say this — not deleted, corrected —
including that the front period at `N = 2` (≈1.145 s against real content) lands closer to the owner's
original "around 1.2 s" suggestion from #329 than `N = 3`'s 0.763 s ever did.

## The test that had to fail, and what replaced it

`frontFiresWhileMoving` (from #329) asserted a pure front-only shot with `isMoving() == true` appears
in a 320-tick trace. At `N = 2` this is now false — the independent shot lands in `COOLDOWN` for this
fixture — and the test failed exactly as expected once `FRONT_SHOTS_PER_CYCLE` changed. **It is
deleted, not weakened or commented out.** Asserting its negation ("never during `MOVING`") would have
been a fact about this one ratio, not about the design, and would silently start passing again the
moment `FRONT_SHOTS_PER_CYCLE` is retuned back toward 3 — telling a future reader nothing true about
what the design actually guarantees either way.

**What replaces it:** `frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage`, which
asserts the property that survives — the front clock is never paused by `fightStage`, `MOVING`
included — without needing a shot to actually land inside `MOVING`. **This fixture's own numbers**
(`boss()`'s `patternCooldown` 0.2 s, `TELL_DURATION` 0.75 s, `MOVE_DURATION` 0.84 s, cycle 1.79 s) give
a front period of 1.79 / 2 = **0.895 s** — a number that belongs to the *test fixture*, not to real
content, which gives ≈**1.145 s** instead (`patternCooldown` 0.7 s, cycle 2.29 s; see "Fire rate"
below). The two are both correct — one per `patternCooldown` — and are named as such here so neither
looks like a mistake next to the other.

The test finds the first rear/front coincidence, finds the very next fire event (the independent shot,
confirmed to be a pure ten-projectile, 160-speed volley), and asserts the tick delta between the two is
the fixture's own front period, 0.895 s, **within two ticks (≈0.033 s)** — not merely that it exceeds
`MOVE_DURATION`. See "Correction after coordinator review" below for why the bound has to be two-sided.

It also records, as a fact rather than a requirement, that this shot lands in `COOLDOWN` rather than
`MOVING` at this ratio.

## Fire rate, measured

All computed from the class's own constants, not observed in a play session — the same method #329's
fragment used.

- **Before this change** (`N = 3`, PR #332): cycle 2.29 s (real content), rear 1 volley/cycle, front 3
  volleys/cycle → ≈1.31 fire ticks/s, ≈17.47 projectiles/s.
- **After this change** (`N = 2`): same 2.29 s cycle, rear 1 volley/cycle, front 2 volleys/cycle (one
  independent, one coincident) → ≈0.873 fire ticks/s, **≈13.10 projectiles/s** — a 25% reduction from
  `N = 3`.
- For context, against the pre-#329 baseline (alternating spread/sweep, ≈5.28 projectiles/s): `N = 2`
  is still ≈2.48× that baseline, against `N = 3`'s ≈3.31× — lower, but still a real increase over what
  the owner approved before #329, consistent with the front weapon still existing and still firing
  independently of movement.

## The lever not taken: fewer rays per front volley

Lowering `FAN_COUNT` for the front weapon alone (below five rays) would reduce front damage while
keeping `N = 3`'s faster rhythm and keeping a shot provably inside `MOVING`. The coordinator raised
both levers with the owner; the owner's instruction was the cadence, not the ray count. Recorded here,
not attempted: `FAN_COUNT` is currently one constant shared by both the rear and front weapons
(`fireAimedFan` takes no per-weapon ray count), so splitting it would need its own constant, not a
value change — worth knowing before the next tuning pass reaches for it.

## Tests

`BossSystemTest.java`:

- `frontFiresWhileMoving` (#329) — **deleted**, per the reasoning above.
- `frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage` — **new**, replaces it.
- `frontFiresMoreOftenAndCoincidesWithEveryRearVolley` (#329) — unmodified, still passes: it reads
  `BossSystem.FRONT_SHOTS_PER_CYCLE` generically, so it now checks "exactly 1 (N−1) independent shot
  between two coincidences" without any source change, and would still fail if the ratio drifted.
- `rearVolleyFansFiveRaysPerPodAndFiresTogetherWithTheFront`, `movesTakeTheSameFixedDurationRegardlessOfDistance`
  and every other #329/#325 test — unmodified, still pass: none of them depended on the value of
  `FRONT_SHOTS_PER_CYCLE`.
- `FireEvent` gained a `tick` field (1-based, from `traceFireEvents`) to support the delta-timing
  assertion above; every existing caller of `FireEvent`/`traceFireEvents` needed no other change.

**No replay test reaches this code**, unchanged from #329: all three `BossReplayTest` fixtures set
`patternCooldown: 1000f` or configure no boss, so `TELLING` is never reached in a full-pipeline replay.

## Acceptance criteria

- [x] `FRONT_SHOTS_PER_CYCLE` is 2, and exactly one front shot falls between two rear volleys —
  `frontFiresMoreOftenAndCoincidesWithEveryRearVolley` (unmodified, parametric on the constant).
- [x] They still fire together at every rear volley, with no drift over many cycles — same test.
- [x] The front clock still runs regardless of `fightStage`, asserted by a test —
  `frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage`.
- [x] The reasoning in the javadoc and this fragment describes the real steady-state cycle order
  (`MOVING`, then `COOLDOWN`, then `TELLING`) and says where the shot now lands (`COOLDOWN`, for this
  fixture and for real content).
- [x] The new fire rate is measured and stated: ≈17.47 → ≈13.10 projectiles/s (a 25% reduction).
- [x] The rear volley, the fixed move duration, the star movement and the single assignment site of
  `FightStage.MOVING` are unchanged — no edit touched `fireRearVolley`, `beginMove`, `updateMoving`,
  `STAR_X`/`STAR_Y`, or the `fightStage = FightStage.MOVING` line.
- [x] `./gradlew build` green; no replay cites this code as evidence.
- [ ] Whether the fight is now right — the project owner's, not attempted here.

## Correction after coordinator review

The first version of `frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage` asserted
only `deltaSeconds > MOVE_DURATION` (0.84 s), reasoning that a front clock paused through `MOVING`
would arrive later and so fail that bound. **It would not have.** Arriving later makes the delta
*larger*, and a larger value still satisfies `>` — the bound was one-sided where the property needed
two. A normally-running clock lands at the fixture's front period, ≈0.895 s; a clock paused for the
whole `MOVE_DURATION` window would land at ≈0.895 + 0.84 = **1.735 s** instead — and both numbers are
greater than 0.84 s, so the one-sided bound could not tell the two behaviours apart. This is exactly
the vacuous-test shape phase 11a measured across this codebase, reproduced here despite the explicit
instruction not to when replacing `frontFiresWhileMoving`.

**Fixed** by bounding the delta on both sides: it must equal the fixture's own front period (0.895 s)
within two ticks, not merely exceed `MOVE_DURATION`. **Falsified before keeping it**, per the
coordinator's instruction: in a scratch copy of the repository outside this worktree (never the tracked
source), `updateFrontWeapons` was given an early `return` when `isMoving()` — the front clock paused
exactly through `MOVING`. Under the original one-sided bound this passes (both 0.895 s and 1.735 s
exceed 0.84 s); under the corrected two-sided bound it fails as expected:

```
org.opentest4j.AssertionFailedError: the independent front shot must land at the front period (0.895s),
not merely after MOVE_DURATION has elapsed — a front clock paused during MOVING would land about
MOVE_DURATION (0.84s) later than this; observed delta was 1.7333335s ==> expected: <0.895> but was:
<1.7333335>
```

The observed delta, 1.7333335 s, matches the predicted 0.895 + 0.84 = 1.735 s to within float
rounding — confirming the test now distinguishes the two behaviours it claims to. The scratch copy was
deleted after the run; nothing in the tracked worktree was mutated to produce or revert this result.
`BossSystem`'s own javadoc on `FRONT_SHOTS_PER_CYCLE` and `frontClockAdvances…`'s own javadoc are both
corrected to state the two-sided argument rather than the false one-sided implication.

## Commands run

- `./gradlew :core:compileJava` — green.
- `./gradlew :core:test --tests "dev.luchoc.littlespaceship.core.domain.system.BossSystemTest"` —
  green, 18 tests (17 pre-existing unmodified, 1 deleted, 1 new — later corrected in place, still 18
  total, all green).
- `./gradlew build` — green across every module (`core`, `game`, `web`, `desktop`, `rngparity`).
- Falsification: scratch copy at a temp path outside the worktree, `updateFrontWeapons` given an early
  `return` on `isMoving()`, ran
  `./gradlew :core:test --tests "...BossSystemTest.frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage"`
  — red, with the exact failure message quoted above. Scratch copy deleted afterward.
