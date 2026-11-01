---
name: boss-front-clock-cycle-fraction
description: how a "shot must land in phase X" acceptance criterion was chosen (N=3), corrected for a cycle-order mistake, then overridden by a later play-tuning instruction (N=2) — and how the test for it changed each time, not just the constant
metadata:
  type: project
---

For #329 (front weapon on its own clock, synced to the rear cycle by `frontPeriod =
rearCycleDuration / FRONT_SHOTS_PER_CYCLE`), the naive choice of `N` — closest numeric match to the
owner's suggested period — was wrong, and the reason only shows up when you check *where in the cycle*
each independent shot's fixed time-fraction lands, not just its absolute period.

**The structural insight, still true:** with a single independent shot per cycle (`N=2`), that shot
always lands at exactly the 50% mark of the cycle, deterministically, every single cycle — nothing
varies it. Whether that mark falls inside a required phase or not is fixed by the phase boundaries as
fractions of the whole cycle, not by anything probabilistic — no amount of tracing changes it. `N=3`
puts shots at 1/3 and 2/3 instead, giving two chances instead of one.

**The mistake I made in #329, caught by `reviewer`:** I assumed the cycle's steady-state segment order
was `COOLDOWN → TELLING → MOVING` (the shape of the *very first* cycle, which has no leading move) and
generalised that onto every cycle. The real order, from `updateTelling`'s own code (`beginMove(world)`
called immediately after the front-clock reset, in the same tick the rear volley fires) is
**`MOVING → COOLDOWN → TELLING`** in steady state — `MOVING` first, not last. This flipped which
independent shot (first vs. second) landed in `MOVING`, though it did not change which `N` satisfied
the requirement at the time (`N=3`). `reviewer` caught it with a reflection probe tracing real ticks
against the real compiled classes, not by re-reading the prose.

**Then, in #333, the requirement itself was overridden by play-testing.** The owner played `N=3`,
found the fight too hard, and asked for a lower cadence — `N=2`. At `N=2` the independent shot never
lands in `MOVING` (it lands in `COOLDOWN`), which is exactly the situation #329's acceptance criterion
was written to reject. The resolution was **not** to weaken the criterion into something vacuous or to
delete the test silently: the original ask (owner) was narrower than the hardened criterion
(coordinator) — "the front weapon must not be *gated* by movement" is not the same claim as "a shot
must land inside a move." The narrower claim still holds at `N=2`, so the test was replaced with one
that proves the narrower, still-true claim (the front clock keeps advancing through the whole `MOVING`
window rather than pausing for it) using a different, more robust technique: comparing the tick delta
between a coincidence and the next independent shot against `MOVE_DURATION`, which is provable without
any shot actually needing to land inside `MOVING`.

**How to apply:**
1. When synchronising an independent periodic clock to phases of a state machine with a "must fire
   during phase X" requirement, check the *phase boundary as a fraction of the whole cycle* against
   each candidate `N`'s shot fractions (`k/N` for `k=1..N-1`), not just how close the resulting period
   is to a target number. A period can be numerically ideal and still structurally incapable of landing
   in the required phase.
2. **Don't infer a state machine's steady-state segment order from its first iteration.** Trace the
   actual reset/transition call sites (`grep` the method that resets your clock and see what it calls
   right next to that reset) rather than reasoning from an enum's declaration order or an assumed
   narrative.
3. **When a later instruction (play-testing, a product decision) breaks a prior hard test, ask whether
   the test encoded the actual requirement or a stricter proxy for it invented to make the requirement
   checkable.** Here the proxy ("a shot lands in the phase") was stricter than the real ask ("not
   gated by the phase"). Deleting the failing test and replacing it with one that asserts the real,
   narrower property (found via a different technique — a timing-delta argument, not a direct
   observation) kept the test suite honest instead of just green.
4. When a reviewer or a later instruction specifically distrusts an explanation but accepts the
   conclusion, re-derive the numeric argument from the code's actual call order before touching the
   comment text — the fix is in the math, not the wording.

See [[boss-star-movement]] for the move-duration and cycle-length context this built on.
