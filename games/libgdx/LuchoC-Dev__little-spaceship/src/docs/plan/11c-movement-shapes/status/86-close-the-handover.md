# 86 — close the handover from 10c, and correct what the phase falsified

Written by the coordinator, who did this task rather than launching an agent: what was left of it was
verification plus two documentation corrections, and the phase's context was already here.

## What #86 asked, and what was actually left

The plan's task 5 is "close #86, and update `TrajectoryDefinition`'s and `Motion`'s javadocs, both of
which currently state, correctly and about to be falsely, that curves are not here yet."

**`TrajectoryDefinition`'s javadoc was already correct.** #163 rewrote it when it made the type a
sealed interface: it now describes a shape as a function from elapsed time to a velocity, names both
permitted kinds, and says why horizontal velocity does not vary with time. Nothing to do — checked by
reading `core/src/main/java/dev/luchoc/littlespaceship/core/port/TrajectoryDefinition.java` at the
phase branch's tip.

**`Motion`'s javadoc was not.** It said the velocity of a shaped entity is decided by "`Trajectory`'s
`elapsed` time **and origin**". `Trajectory` carried an origin for five commits of #161 and lost it in
`3a88a71`, once #162 decided a shape reads no position. The sentence outlived the field. Corrected
here to name `elapsed` and `verticalVelocityAt` instead.

That correction is worth recording for its own sake: **three agents and two `reviewer` passes did not
catch it.** The audits were looking at what each branch changed; this was a sentence in a file that
branch did not touch, made false by a *removal* two branches earlier. A javadoc goes stale in the diff
nobody is reading.

## `docs/planning/08-decisions-and-open-items.md`

Two passages, treated differently on purpose.

**The 10c review's entry is left as it stands**, with a dated pointer added. It says movement "is the
one real gap" and that a trajectory "is a constant vector resolved once at spawn" — true on
27/08/2026, when the architecture review found it, and that section is a dated record of what a
review found. Rewriting it would falsify the record in the other direction. The pointer says it was
built on 29/08/2026 and where to read the entry that supersedes it.

**The 11c entry's "Not built" is replaced**, because that one was a claim about the present. It now
names the files: the sealed `TrajectoryDefinition` and its two records, `JsonContentSource`'s handling
of the `"type"` key, the three `arc` entries in `assets/data/trajectories.json`, and `SpawnEvent`'s
optional `trajectoryId` re-evaluated every tick by `MotionSystem`. It also keeps the fact that
**no wave points at a shape yet**, which is true and is 11e's decision to change.

## What was checked, and how

- `grep -rn "constant velocit\|not curves\|are not here yet\|constant vector"` across `core/`,
  `game/`, `docs/planning/` and `README.md`, excluding the two phase folders that are dated records.
  Two hits, both handled above; nothing else in the repository still describes movement as a constant
  resolved once.
- The two javadocs #86 names, read in full at the phase branch's tip.
- `./gradlew :core:test` — green, unchanged by a javadoc edit, and run because the diff touches a
  `.java` file at all.

## What #86 does not close

The issue's own words: "not designed here, deliberately: which shapes exist, how they are described,
and where the binding is chosen". All three are now decided and built — #162, #163, #164 — so the
handover is complete. What remains is content, not mechanism: **no level uses a shape**, and that is
[11e](../../11e-level-one-redesigned/plan.md) by the plan's own scope section.
