# Phase 10c — triage of the open technical issues

Written on 27/08/2026. This is the record task 3 of [`plan.md`](plan.md) asks for.

**Every open issue in the repository was triaged**, not only the six the plan names. `gh issue list
--state open --limit 60` returned **fifteen** when this phase opened on 27/08/2026, before it created
any of its own; four of them (#40, #41, #42, #43) are the web defects
the roadmap already assigns to phase 11 by the project owner's decision and are listed at the end
without further argument. The other eleven are the technical ones.

**Three buckets**, per the plan: **fixed in the 11 group**, **obsolete**, **architectural**. A fourth
outcome appears once and is stated rather than hidden: **decided here**, for an issue that asked for a
decision rather than for work, which is what this phase exists to give.

Each verdict names what was observed. Where nothing was checked, it says so.

---

## Summary

| Issue | Verdict | One line |
|---|---|---|
| [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3) | Fixed in the 11 group | Decided by 10a; execution is #53. Kept open as the record, by 10a's own decision. |
| [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4) | Fixed in the 11 group | Same shape; execution is #54. |
| [#11](https://github.com/LuchoC-Dev/little-spaceship/issues/11) | **Decided here** | The layer stays. Reason below. |
| [#12](https://github.com/LuchoC-Dev/little-spaceship/issues/12) | Fixed in the 11 group | Still true. Subsumed by #44, with one half of it at risk of being lost. |
| [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) | Fixed in the 11 group | Still true, and #87 makes it more urgent, not less. |
| [#23](https://github.com/LuchoC-Dev/little-spaceship/issues/23) | **Obsolete — fixed on 22/08/2026** | The code fixed it and the issue was never closed. |
| [#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) | Fixed in the 11 group, **first** | A prerequisite for everything else the group changes. |
| [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52) | Fixed in the 11 group | 10a handover. Nothing here changes it. |
| [#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) | Fixed in the 11 group | 10a handover. Nothing here changes it. |
| [#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) | Fixed in the 11 group | 10a handover. Nothing here changes it. |
| [#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56) | Fixed in the 11 group | 10a handover. Nothing here changes it. |

**Nothing was found that requires an architectural change on its own account.** The architectural
work this phase identified came out of the assessment, not out of the backlog — see
[`assessment.md`](assessment.md) and issues #84 to #88.

---

## The ones with something to say

### #23 — a designed drop is attached to every slot of its formation · **obsolete**

**It was fixed five days after it was raised, and nobody closed it.**

Observed: commit `9e7607f`, *fix(core): tie a designed drop to a single formation slot*, dated
`Sat Aug 22 13:35:53 2026`, touching `SpawnEvent.java`, `SpawnSystem.java` and `SpawnSystemTest.java`.
In the code today:

- `SpawnEvent` (`core/port/SpawnEvent.java:19`) carries a sixth component, `dropSlot`, and its javadoc
  quotes this issue's own resolution: "a three-carrier wave with a drop hands out exactly one
  attachment, not three";
- `SpawnSystem.spawnWave` attaches the `Drop` only when `i == event.dropSlot()`
  (`SpawnSystem.java:108-110`);
- `SpawnSystem.requireSlotInRange` (lines 121-128) fails loudly if a wave drops into a slot its
  formation does not have, so a typo in the index is not silent either;
- the content uses it: `assets/data/level-01.json` line 21 reads
  `"drop": "weapon-upgrade", "dropSlot": 1`.

Of the three options the issue left open — a slot index, the first enemy of the wave to die, or a
property of the wave firing once — **the first was taken**.

**One thing carries forward, and it is not a reason to keep the issue open.** The plan flags #23 as
touching wave design, and it does: "a difficult encounter delivers the attachment" is a property of
an *encounter*, and today the mechanism binds a drop to one slot of one `SpawnEvent`. If a wave
becomes a grouping above spawn events, whoever designs it has to say whether a drop belongs to the
wave or to one of its events. That is a design question for the 11 group and it is recorded in
[#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85), not a defect in what exists.

**Action: close #23**, naming the commit.

### #11 — `CollisionLayer.PLAYER` is no longer referenced by production code · **decided here**

The issue asks for a decision — "decide whether the layer stays as a declaration of intent or goes" —
and this is the phase whose job is deciding. So it is decided rather than deferred a fourth time.

**First, what is actually true today**, because the title is slightly wrong and has been for a while.
`CollisionLayer.PLAYER` **is** referenced by production code, once:
`Simulation.java:207` sets the player's collider to it. What no production code does is *read* it:
`grep -rn "\.layer ==\|\.layer !=" core/src/main --include=*.java` returns nine matches, and they
test `ENEMY`, `ENEMY_PROJECTILE` and `PLAYER_PROJECTILE` only — `BombSystem.java:108,115`,
`CleanupSystem.java:90`, `LifetimeSystem.java:47-48`, `World.java:512`, plus three parameterised
comparisons in `CollisionSystem.java:115,143,156` whose arguments are listed at
`CollisionSystem.java:70-78`: `ENEMY_PROJECTILE`, `ENEMY`, `PICKUP` and `PLAYER_PROJECTILE` against
the player resolved by `World.playerEntity()`. `PLAYER` is written and never matched.

**Decision: the layer stays.** Three reasons, in order of weight:

1. **Removing it does not simplify anything; it complicates one thing.** The player's collider has to
   carry *some* layer — `Collider` has no nullable-layer constructor — so deleting the constant means
   either inventing a "none" value or reusing an unrelated one. Both are worse than a constant that
   says what the entity is.
2. **It is the only layer that names an entity rather than a role in a pair**, and that asymmetry is
   the design, not an accident: `CollisionSystem` resolves the player through `World.playerEntity()`
   because there is exactly one and it is never destroyed. Every *other* layer has to be matched
   because its members are many and anonymous.
3. **The issue's own prediction did not come true.** It said the risk "matters in phase 05, when
   `WeaponSystem` and `PickupSystem` start reading the same buffer". Phase 05 shipped, phase 07
   shipped, the MVP shipped, and the layer was still never read. Three phases of evidence against a
   predicted hazard is enough to stop carrying it.

**What was rejected:** deleting the constant, for reason 1; and converting it to a comment on
`Collider`, which trades a checked constant for prose and is the exact move
[`../10a-honest-documentation/mechanism.md`](../10a-honest-documentation/mechanism.md) argues against.

**The real half of the issue survives, and it is not about the enum.** The hazard it describes — a
test fixture carrying the layer but no `Player` component, or the reverse, and passing anyway — is a
fixture-quality problem, and it is exactly the class of thing
[#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) exists to catch. **Folded into #44**
rather than left standing on its own.

**Action: close #11**, recording the decision and the fold.

### #12 — `DamageReplayTest` is not a regression net · **fixed in the 11 group, under #44**

Still exactly true. Observed: `DamageReplayTest`
(`core/src/test/java/dev/luchoc/littlespaceship/core/application/DamageReplayTest.java`) has
**one** `@Test`, named "a scripted damage sequence reproduces the same final state twice" (line 31),
and its class javadoc (lines 21-24) states the same. It runs the scenario twice on one build and
compares. No golden fingerprint is pinned.

#44 states the same defect as a general rule across the suite and names the fix, so #12 is a
particular case of it and does not need separate work.

**One half of #12 is not restated in #44 and would be lost if #12 simply closed:** *"no test pins the
order in which `CollisionSystem` appends hits across pairs."* Round 2 of the phase 02 review proved
by hand that the then-current reorder was safe; nothing stops the next one. That matters more now
than it did, because the order in which hits appear is what `DamageSystem` consumes, and the 11 group
is going to touch spawning and movement around it.

**Action: keep #12 open until #44 absorbs it explicitly**, and add the ordering half to #44 as a
named case so it survives the merge.

### #19 — `game` has no test suite · **fixed in the 11 group, and more urgent than before**

Still true. Observed: `ls game/src/` returns `main` and `tools` — there is no `test` directory.
`core` is at 35 test files (`find core/src/test -name "*Test.java" | wc -l`).

The 11 group makes this worse rather than better, and that is the reason to say so here:
[#87](https://github.com/LuchoC-Dev/little-spaceship/issues/87) turns `JsonContentSource`'s hardcoded
`level-01` into a parameter, and #19's own subject is that the loader's error paths — "malformed
content must fail naming the file and the offending id" — are the piece of `game` with the most ways
to fail quietly and the least coverage. A change to the loader with no tests under it is the shape of
change this issue was raised about.

**Action: no change to #19. Note the interaction on #87.**

### #44 — integration tests should assert behaviour · **fixed in the 11 group, and it goes first**

Not re-argued here; the issue and the roadmap both state it. Recorded in this triage only because
this phase's assessment changes its **position in the order**, not its content:
[`assessment.md`](assessment.md) proposes changes to `SpawnSystem`, to `Motion`, and to what "cleared"
means. Each is a behaviour change under a suite that mostly asserts a run reproduces itself, and a
broken rule breaks identically on both runs.

**Not checked:** this phase did not re-count how many of the 289 tests assert a rule versus
reproducibility. #44's own figures are taken as given.

**Action: #44 gains two named cases** — the hit-ordering half of #12, and the fixture hazard from
#11 — and is ordered before the wave work.

### #3, #4, #52, #53, #54, #56 — 10a handovers · **fixed in the 11 group**

All six were triaged four days ago by phase 10a and nothing this review found changes any of them.
#3 and #4 are kept open as the record of their findings, by 10a's explicit decision recorded in their
comments; the code halves are #53 and #54. #52 and #56 are build and verification work.

Read against this phase's subject, they are unaffected: none of them touches `SpawnSystem`, `Motion`,
`ContentSource` or `SystemOrder`. **Not checked:** whether the `docs-refs` script #56 describes would
need extending to cover a per-level document, since that document's form is the 11 group's decision.

### #40, #41, #42, #43 — the web defects · **fixed in the 11 group**

Assigned to phase 11 by the project owner's decision, recorded in
[`../post-mvp-roadmap.md`](../post-mvp-roadmap.md). Presentation-layer defects, no architectural
content, not re-argued here.

---

## What this triage did not find

No open issue turned out to be an architectural problem in its own right. That is worth stating
plainly rather than leaving as an absence: the backlog is a list of gaps in verification and in
documentation, not a list of places where the design is wrong. The architectural work this phase
identified came from reading the code against what the 11 group needs — issues
[#84](https://github.com/LuchoC-Dev/little-spaceship/issues/84) to
[#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88) — and none of it was visible from the
issue tracker.
