---
name: seeded-rng-first-pick-lookup
description: reproduce the project's xorshift Rng in a short Python script to find which seed produces which first draw, instead of guessing seeds and re-running gradle
metadata:
  type: feedback
---

When a test needs two specific seeds that make a seeded `Rng`'s *first* draw land on two different,
sufficiently-different outcomes (e.g. two star-point indices at very different distances, for
`BossSystemTest`'s move-duration test), guessing seed values and re-running `./gradlew :core:test`
each time is slow and can silently pick two seeds that collide on the same first draw (happened here:
seeds 1 and 4 both produced index 5).

**Why:** `Rng` (`core/src/main/java/.../domain/rng/Rng.java`) is Marsaglia's 32-bit xorshift plus a
fixed scramble step, built entirely from `^`, `<<`, `>>>` — trivial to reproduce exactly in a short
Python script (mask to 32 bits, treat `>>>` as unsigned right shift, mind the `>> ` vs `& MASK`
subtleties). Reproducing it once let me tabulate `Rng(seed).nextInt(10)` for seeds 1–40 in a single
`python3 -` heredoc and pick seeds 1 and 6 (indices 5 and 0, a 1.65x distance ratio) with certainty,
instead of iterating gradle runs.

**How to apply:** before writing a test that depends on a specific seeded-Rng outcome, reproduce the
generator's bit operations in Python (or any fast scripting tool) and brute-force the seed space there
first. Much faster than round-tripping through the JVM test runner to discover a seed collision.
