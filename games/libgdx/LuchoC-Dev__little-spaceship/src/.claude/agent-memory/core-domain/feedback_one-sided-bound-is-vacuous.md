---
name: one-sided-bound-is-vacuous
description: a one-sided inequality ("delta > threshold") can be satisfied by both the behavior you want and the behavior you're supposedly ruling out — check that the failing case actually lands outside the assertion, not just that the passing case does
metadata:
  type: feedback
---

Writing `frontClockAdvancesThroughTheWholeMovingWindowRegardlessOfFightStage` for #333, I asserted
`deltaSeconds > MOVE_DURATION` and reasoned in the javadoc that a front clock paused during `MOVING`
would "arrive later and fail that bound." It would not have: arriving later makes the delta *larger*,
and a larger value still satisfies `>`. The clock running normally landed at ≈0.895s; a clock paused
through the whole `MOVE_DURATION` (0.84s) window would land at ≈1.735s instead — both exceed 0.84s, so
the one-sided bound could not distinguish the two behaviors at all. The coordinator caught this before
merge and it is exactly the vacuous-test shape phase 11a measured across the codebase — reproduced here
despite being explicitly warned against it in the same task.

**Why this is easy to miss:** the *passing* case (clock runs normally) does satisfy the bound, and it's
tempting to stop there. The bound only proves something if you also check where the *specific failing
behavior you're trying to catch* would land, and confirm that lands *outside* the assertion. A
one-sided inequality against a lower bound rules out "arrived too early," never "arrived too late in a
way you didn't anticipate" — and a paused-then-resumed clock is a "too late" failure mode, which a `>`
bound is structurally unable to catch.

**How to apply:**
1. When a test's assertion is an inequality (`>`, `<`, `>=`, `<=`) meant to catch a *specific* wrong
   behavior, compute concretely where that wrong behavior's own output would land, and check by hand
   (not by intuition) that it falls on the failing side of the inequality. If it lands on the passing
   side, the bound is one-sided where the property needs two — replace it with an equality-within-
   tolerance (`assertEquals(expected, actual, tolerance)`) or an explicit two-sided range.
2. **Falsify before trusting a test that replaces a deleted one, every time** — not just when told to.
   A scratch mutation (in a copy outside the tracked worktree, never mutating and reverting tracked
   source) that reproduces the exact wrong behavior, run against the test, is the only way to know the
   test's failing branch is reachable at all. Reasoning about it in prose is not enough — the same
   reasoning is what produced the vacuous bound in the first place.
3. This applies most sharply to synchronization/timing tests (clocks, periods, deltas), where "later
   than X" and "much later than X" are both `> X`, and the test author's own narrative ("late means it
   paused") silently assumes the reader stops reading before the second `>`.

See [[boss-front-clock-cycle-fraction]] for the surrounding #329/#333 boss front-weapon cadence context
this test was written for.
