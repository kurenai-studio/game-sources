---
name: rule-vs-reproducibility-classification
description: What classifying core's 289 tests into rule vs reproducibility taught, beyond the numbers themselves, which live in the phase's baseline.md.
metadata:
  type: project
---

For phase 11a task 1, all 289 tests in `core/src/test/` were read by hand and classified. **The numbers
and the criterion live in `docs/plan/11a-rule-asserting-tests/baseline.md`** and are deliberately not
repeated here — two copies of a count end with one of them stale, and this file already did that once
before the coordinator corrected it.

What is worth keeping is the method, and the three ways it went wrong:

**A figure that three documents repeat can still be wrong about the aggregate.** The roadmap's "the
bulk asserts that a run reproduces itself" was carried into 10c's assessment and into 11a's plan
without anyone re-measuring it. Measured, it is accurate about its own example and wrong about
`core/src/test/` as a whole, because `domain/system/*Test.java` is already overwhelmingly
rule-asserting. **How to apply:** when a plan cites a suite-wide count traceable to an "inherited,
never measured" figure, expect it to be right about the example that produced it and wrong about the
population.

**A test name is a hint, not a classification.** `SimulationTest.seedChangesTheOutcome` and
`inputChangesTheOutcome` read like determinism tests and assert that two runs *differ*.
`RngTest.pinnedSequence` pins a literal and looks like a rule test, but what it pins is the RNG
algorithm's numeric contract, not a decided game rule. Every one of the 289 needed the assertion read.

**Reading the name of the *assertion* is not enough either — read the whole method.** The first pass of
this classification put `BossReplayTest`'s two tests in reproducibility-only on the strength of their
names and their `assertEquals(first, second)`. Both also pin a `LevelOutcome` on the next line, which
makes them "both" by the criterion this very document had written. **Why it matters:** the mistake
pointed the wrong way — it made the suite look weaker than it is, in the one file the roadmap holds up
as its example. **How to apply:** a determinism test with an extra `assertEquals` below the
self-comparison is the common shape here; check every assertion in the method before bucketing it.

The pattern worth reusing when a replay should be more than a self-comparison: `assertEquals(first,
second)` plus `assertEquals(GOLDEN_FINGERPRINT, first)` against a committed literal built from world
state. `BombReplayTest` and `LevelScoreReplayTest` do it; `DamageReplayTest` and `SpawnerReplayTest`
do not, and a rule that breaks identically on both runs leaves them green.
