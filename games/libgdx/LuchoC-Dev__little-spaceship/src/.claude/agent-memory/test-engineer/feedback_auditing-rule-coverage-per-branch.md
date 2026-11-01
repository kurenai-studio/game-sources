---
name: auditing-rule-coverage-per-branch
description: How to find real gaps in a system whose sibling branches already look well tested (used on 11a task 2, the defensive chain)
metadata:
  type: feedback
---

When a system has several branches that share the same shape (here: `DamageSystem.resolvePlayerHit`'s
shield/attachment/life branches, each removing a layer and granting invulnerability), a test suite that
looks exhaustive at a glance can still miss one branch's copy of a side effect the others have covered.

**What worked:** read the rule's exact wording in `docs/planning/` first (here, `02-mvp-functional-
spec.md`: "Losing the shield **or the attachment** also grants those grace frames"), then check each
noun the sentence lists has its own assertion — not just the branch's primary effect (layer removed,
no life lost) but every side effect the rule names. `DamageSystemTest` had
`shieldDamageGrantsTheShorterInvulnerability` but no attachment equivalent, even though
`attachmentAbsorbsBeforeLife` existed and looked like it covered the same ground — it asserted the
layer was consumed, not that invulnerability was granted.

**Why:** in `little-spaceship`, `03-game-systems.md`/`08-decisions-and-open-items.md` state the
defensive chain's *order* very visibly (invulnerability → shield → attachment → life), which pulls test
authors toward writing one test per order-transition and away from re-checking each transition's
secondary effects individually.

**How to apply:** for phases 11a tasks 3/4 (boss rules, level completion) or any future rule audit,
list every clause of the quoted rule sentence as a separate checkbox before reading the test file, then
match tests to clauses — not the other way around (reading the test file first and asking "does this
look thorough" undercounts silently).

See [[project_rule-vs-reproducibility-classification]] for the companion finding from task 1: most of
`DamageSystemTest`/`PickupSystemTest` (23 + 16 tests) already counted as rule-asserting in the baseline,
and task 2 confirmed by reading that essentially every decided rule of the chain already had a test —
the baseline's count was not an illusion for this pair of files.
