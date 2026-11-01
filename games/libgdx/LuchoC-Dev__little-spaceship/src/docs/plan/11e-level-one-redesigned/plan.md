# Phase 11e — Level 1 redesigned, balance and the boss

**Lane:** code + content · **Owner:** `level-designer`, with `core-domain` for the boss and the stats · **Depends on:** 11a, 11b, 11c, 11d

## Before you start

**Read, in this order:**

1. [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md), "Balance, the boss, and level length", and the fourteen-beat list under "Waves, first".
2. `docs/planning/04-campaign-and-levels.md`, "Level 1 design → Provisional sequence". It is the design the current 92-row timeline is a transcript of, and this phase is recovering it.
3. `docs/STATUS.md`, "Post-MVP backlog, from real play on 25/08" — the boss diagnosis is there and it is the player's own, and better than the fix that was tried.
4. `docs/planning/08-decisions-and-open-items.md`, "Level 1 climax and length" **and** "The wave system, 27/08/2026". The second reopens part of the first; read both and note which sentence won.
5. `docs/planning/10-mvp-initial-values.md` — the numbers as they stand, several of them still placeholder.

## Goal

**Level 1 is fourteen beats of about three minutes, and it is no longer too easy.**

## What was decided, and by whom

Decided by the project owner on 27/08/2026:

- **The target is around three minutes, boss included, and the number is fixed by playing rather than
  by arithmetic.** The boss enters at 302 s today.
- **The boss redesign travels with the rebalance**, in this phase, because tuning a fight against a
  pacing that no longer exists is doing the work twice.

**This reopens a decision, deliberately.** `08-decisions-and-open-items.md`, "Level 1 climax and
length", decided on 21/08/2026 that *"Level 1 runs four minutes or more, boss included"*, with the
content cost accepted explicitly. The project owner reopened it on 27/08 after playing the shipped
build and finding five minutes too long. That is recorded as a dated reopening in the decisions file,
not as an oversight — and the other two decisions in that same subsection, the boss's single phase
with two alternating patterns and a clear tell, and the strong encounter being two heavy carriers,
**still stand**.

**And this stays decided:** balance is tuned by playing, not by arithmetic. It has been decided twice,
on 22/08 and on 25/08.

## Tasks

1. **Rebuild level 1 as fourteen waves**, one per beat, using the mechanism 11b built and the shapes
   11c built. The beats, from `04-campaign-and-levels.md`: audiovisual introduction · initial calm ·
   first isolated basics · light/fast · combined formations · tanks and shifts in priority ·
   super-fast · one or two heavy carriers · evolved basics/shooters · high-pressure combinations · **a
   difficult encounter that delivers the attachment** · brief rest · final escalation · boss.
   *(Fourteen, not thirteen. The count was wrong in this repository until 26/08 and it matters,
   because this is the list the level gets rebuilt from.)*
2. **Bring the length to around three minutes** and record the number you landed on and what it felt
   like. This is where the "rest before the climax" beat earns its place or does not.
3. **Give the enemies real numbers.** Enemy health is still placeholder — a heavy carrier dies in
   about 1.2 s against the 32 s its stretch reserves. `docs/STATUS.md` states the honest open tension
   and leaves it for a play session: the spec asks the basic for "low health and a slow shot", and at
   one-hit health its rate-of-fire contrast against the shooter is invisible. A small `Health` of 2–3
   on `enemy-basic` and `enemy-light` is the candidate fix and it is a real balance change against
   `weaponProjectileDamage: 10`.
4. **Redesign the boss's attack, not its volume.** The player's diagnosis: the spread always points
   outward and the sweep inward, so a player parked in the centre is never threatened — a positioning
   problem solved once, not a dodge. Tripling the fan to three rays per part barely moved it.
   Suggested and not mandated: five rays, aimed at the player rather than at fixed outward angles.
   **Weighed against the tell staying honest**, which is what makes this fight fair and is a decided
   rule from 21/08.
5. **Watch the four things `docs/STATUS.md` asks the next session to watch**, and answer them in
   `status.md`: whether the basic reads as firing less often than the shooter or just dies too fast to
   tell; whether the boss at `patternCooldown` 0.7 feels like a boss; whether `enemy-rush`'s single
   likely shot reads as "shoots little" rather than "does not shoot"; and whether `enemy-light`'s
   130 u/s projectile is dodgeable.
6. **Regenerate the per-level document** and check that it describes the level you actually built.
7. **Close [#23](https://github.com/LuchoC-Dev/little-spaceship/issues/23) or confirm it is closed.** A
   designed drop delivered once per formation slot instead of once is a live rules bug, and beat 11 —
   the difficult encounter that hands over the attachment — is exactly what it breaks. 11a should have
   caught it with a test; this is the phase that depends on it being right.

## The running order

Decided by the project owner on 31/08/2026, when the phase opened. It is here rather than in
`status.md` because it is a decision about how the phase is run, not a record of how far it has got —
and because a coordinator who loses the session needs it before anything else.

**The phase cannot close without a play session, and no agent can supply one.** The acceptance
criteria say the verdict comes from playing; `docs/STATUS.md` calls playing *"the only source this
project trusts for balance"*; and all four of task 5's watch-items are questions about how something
reads in play. So the phase runs in two halves:

| Half | What happens | Who |
|---|---|---|
| **Build the candidate** | Tasks 1, 3, 4, 6, 7 — the fourteen waves, the stat changes, the boss change, the regenerated document, and #23 confirmed | `level-designer` on `assets/data/` and the beats; `core-domain` on the boss and on any rule a stat change touches; the coordinator on `tools/` and the merges |
| **Play, then tune** | Tasks 2 and 5, and whatever the session changes | **the project owner plays**; `level-designer` tunes from what they report |

**The candidate is not the deliverable.** It is a level built from arithmetic and from the fourteen
beats, and this project has refused arithmetic as a verdict twice, on 22/08 and 25/08. It must not be
merged into `dev` as though the phase were done — an unplayed batch of numbers reaching the published
site is what the four-level branch regime exists to prevent.

**The session to ask for, when the candidate is ready.** `./gradlew :desktop:run`, and these five
questions, four of them inherited from `docs/STATUS.md` and the fifth being the phase's own goal:

1. Does `enemy-basic` read as firing less often than `enemy-shooter`, or does it just die too fast to
   tell? (This is what the candidate `Health` of 2–3 on the basic is meant to answer.)
2. Does the boss at `patternCooldown 0.7` feel like a boss — and after task 4's change, is the tell
   still honest?
3. Does `enemy-rush`'s single likely shot per pass read as "shoots little" rather than "does not
   shoot"?
4. Is `enemy-light`'s 130 u/s projectile dodgeable?
5. Is the length right? The target is around three minutes against 302 s today, and the number is
   fixed by playing.

**"Still not clear" is an acceptable answer to any of them** and the acceptance criteria say so. It is
recorded as that, not resolved by guessing.

## What is already answered, so nobody re-derives it

**Task 7 is done.** [#23](https://github.com/LuchoC-Dev/little-spaceship/issues/23) is closed and the
rule is tested: `core/domain/system/SpawnSystem.java` attaches the `Drop` only when
`i == event.dropSlot()`, and `SpawnSystemTest.designedDropAttachesToExactlyOneSlot` asserts
`world.drops().size() == 1` and checks the surviving entity's x against the named slot's offset.
`dropSlotOutsideFormationFails` covers the typo. It is recorded in `status.md` with that evidence;
confirming it does not need its own branch.

## Acceptance criteria

- ~~Level 1 is fourteen waves, one per beat, and each wave's id names its beat.~~ **Reopened by the
  project owner on 01/09/2026, after playing the candidate.** Level 1 is **fourteen beats, twelve of
  which carry a wave**, and each wave's id names its beat. Beat 1 (audiovisual introduction) and beat
  14 (boss) carry none: the session found enemies at the very start and enemies still arriving as the
  boss entered, and called both wrong. `shape-catalogue.md`'s original beat map had already said "none"
  for those two, and `JsonContentSource.loadWaves` rejects a wave with no spawns, so the alternative
  has no representation in `assets/data/`. Recorded in `docs/planning/08-decisions-and-open-items.md`
  under "Level 1 played, 01/09/2026".
- The boss enters at the decided time, and the decided time is written down with the session that
  produced it.
- **The verdict comes from playing.** A session played, what it felt like, what changed as a result.
  A balance change justified by arithmetic alone does not satisfy this criterion — that has been the
  rule here since 22/08.
- The four watch-items from `docs/STATUS.md` are each answered, including "still not clear" where that
  is the honest answer.
- The rule-asserting tests from 11a are still green, and any that had to change did so because a rule
  changed, with the rule change written down.
- The generated document matches the level, and CI proves it.
- `docs/planning/10-mvp-initial-values.md` reflects the numbers that shipped, or says which are still
  placeholder.

## What is out of scope

- **Levels 2 and 3.** Phase 12, and phase 12 is the first honest measurement of whether this group
  worked — the roadmap says to treat that as an acceptance criterion rather than a hope.
- **A boss engine.** [#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88). This phase
  changes level 1's boss; it does not generalise `BossSystem`.
- **New mechanisms.** If a beat needs something 11b and 11c did not build, that is a finding to report,
  not a system to add here.
- **The intensity-curve tooling.** Carried as non-blocking since the level's length was first decided
  and still open. If it turns out to be what this phase actually needs, say so — do not build it
  silently.
- The four web defects. [11f](../11f-web-defects/plan.md).

## Risks

**Balancing by spreadsheet.** The decided rule is that the numbers are tuned by playing, and this
phase is the one most able to violate it, because it has fourteen waves and a stats table in front of
it and no player in the loop unless someone stops and plays.

**Changing the boss's nature and losing the tell.** The tell is what makes the fight fair and it is a
decided rule. An attack aimed at the player is harder to read than one at fixed angles; if the tell
stops being honest, the fix is worse than the problem.

**Rebuilding beats that the migration already got right.** 11b translated the 92 rows into waves
mechanically. Some of those waves are already the beat. Rewriting them for the sake of rewriting them
costs a play session's worth of tuning.

**Silently deciding an open gameplay item.** `08-decisions-and-open-items.md` lists several as open on
purpose — the respawn gap next to a slow enemy, which archetypes count as "weak", the player's
starting position. A play session is a good place to answer them, and answering one means writing it
into that file, not into a level's JSON.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull
request against `phase/11e-level-one-redesigned`, then `status.md` before review.
