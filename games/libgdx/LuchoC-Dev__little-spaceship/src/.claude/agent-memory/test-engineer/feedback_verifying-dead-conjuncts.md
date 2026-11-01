---
name: verifying-dead-conjuncts
description: Before writing a test for one clause of an && chain, delete just that clause and run the full suite to check it can ever be false where it's read.
metadata:
  type: feedback
---

When a rule is written as `a && b && c` and the task asks for "a test that fails when each conjunct
is broken", check first whether every conjunct is actually reachable in a false state at that line —
an earlier guard in the same method can make one of them provably always true by the time the `&&`
runs, which makes it dead code no test can ever distinguish from its absence.

**How to check, cheaply:** delete just that one clause (not the whole condition) in production code,
run the full module test suite once (`./gradlew :core:test`, no filter), and read whether anything
goes red. If nothing does, don't hunt for a test that "should" catch it — that hunt won't end, because
none exists. Revert and say so as a finding instead: name the earlier guard that shadows it, and write
the test for whatever the *substantive* version of the rule actually is (usually the guard's own
priority over the branch it shadows), not for the literal dead conjunct.

**Why:** found in [[level-completion-rules]] (11a task 4) — `World.outcome()`'s bossless branch reads
`waveTimelineExhausted && noEnemyLeft() && alive`, but an earlier `if (state.lives <= 0) return
DEFEATED` already guarantees `alive` is true by the time that line runs. Deleting `&& alive` alone left
the full suite (291 tests) green. The rule the plan actually wanted tested — "defeat on losing all
lives" beats completion — is real and testable, just not by touching that literal conjunct: it's tested
by breaking the early guard instead (`state.lives <= 0` → `state.lives < 0`), which does turn red.

**How to apply:** any time a task hands you a boolean expression as "the rule" and asks for one test
per operand, read the whole method for an earlier return that could shadow an operand before assuming
the operand is independently testable.
