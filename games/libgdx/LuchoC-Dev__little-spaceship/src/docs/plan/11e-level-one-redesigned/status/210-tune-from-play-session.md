# 210 — Tune the candidate from the 01/09 play session

Issue [#210](https://github.com/LuchoC-Dev/little-spaceship/issues/210), branch
`feat/tune-from-play-session`, `level-designer`. Task 2 of phase 11e: the project owner played the
candidate built on #198 and #199 on 01/09/2026, and this is the change their session asked for.
**Every number below was decided by the project owner, not proposed here.**

## What moved

### Enemy health — `assets/data/enemies.json`

| archetype | was | now | projectiles to kill at `weaponProjectileDamage` 10 |
|---|---|---|---|
| `enemy-basic` | 30 | 20 | 3 -> 2 |
| `enemy-light` | 20 | **no `health` component** | 2 -> 1 |
| `enemy-shooter` | 40 | 30 | 4 -> 3 |
| `enemy-tank` | 300 | 200 | 30 -> 20 |
| `enemy-carrier` | 1000 | 700 | 100 -> 70 |
| `enemy-rush` | none | none | 1 (untouched) |

`enemy-light`'s component was **removed**, not set to 10 or below. `DamageSystem` treats any value at
or below `weaponProjectileDamage` exactly like no component, so a `health` of 10 would have read in
the JSON as a decision while behaving as an absence. The generated Roster confirms it: `enemy-light`
now prints `health none`, `shots to kill 1`.

### Waves removed

`l1-intro-flyover` (beat 1, the audiovisual introduction, 5.0 s) and `l1-boss-approach` (beat 14, the
escort over the boss's descent, 7.0 s) are gone from **both** `level-01.json` (the placements) and
`waves.json` (the definitions). `docs/levels/waves.md` lists twelve waves, every one of them placed,
and no `unplaced` marking — the only occurrence of the word in that file is the paragraph that
explains what the marking would mean.

Twelve waves now serve fourteen beats. That is what `docs/plan/11c-movement-shapes/shape-catalogue.md`
already said for those two beats (beat 1 "none; no enemies", beat 14 the boss), and the acceptance
criterion that says "fourteen waves" is being rewritten by the coordinator on a parallel branch —
untouched here, as the issue instructed.

The first thing the player now meets is `l1-opening-calm`, whose single spawn sits at `at 5.0` inside
an 8.0 s wave. The level therefore opens on five seconds of empty sky, which is exactly what the
owner asked for.

### Boss

`spreadProjectileSpeed` 95 -> 85, `sweepProjectileSpeed` 140 -> 125. **Nothing else about the boss
moved** except `entersAt`, and that only follows the chain.

### Timing

| | was | now |
|---|---|---|
| placements | 14 | 12 |
| the waves end at | 146.5 s | **134.5 s** |
| `boss.entersAt` | 139.5 s | **134.5 s** |
| gap between them | -7.0 s | **0.0 s** |

The chain now starts at 0.0 s and `entersAt` moved the same 5.0 s earlier that the front lost. Because
the 7.0 s escort at the back is also gone, the boss no longer enters over a running wave: the last
wave ends and the boss's entrance begins on the same instant. The generated Checks section lost its
`boss.entersAt is earlier than the last placement's end` finding as a result. Nothing else was
re-timed — the owner played this pacing and approved it.

## The carrier at 700 — checked, and it is the finding of this task

The mechanism needs the carrier alive for 4.0 s: `Spawner.timer` is initialised to `interval`
(`core/domain/component/Spawner.java:52`), so the **first** child arrives one full interval after the
carrier spawns, not at zero. At 700 hp the player must land under 175 damage per second for that to
happen.

From the generated Roster and Drops sections, and `WeaponSystem`'s 1/2/3/5 projectiles per pull at
shot levels 1-4 (`core/domain/system/WeaponSystem.java:96`) at `weaponFireCooldown` 0.15:

| beat | carrier appears | upgrades taken by then (11.0, 48.0, 86.0 s) | shot level | ideal sustained dps | time to kill |
|---|---|---|---|---|---|
| `l1-heavy-carrier` | 67.0 s | 2 | 3 | 200 | **3.5 s** |
| `l1-twin-carriers-attachment` | 97.5 s | 3 | 4 | 333 | **2.1 s** |

**Both are under 4.0 s, so under ideal fire 700 does not survive to spawn a child.** Applied as
decided, and reported rather than changed.

Two things keep this from being the 80 hp defect #199 fixed. "Ideal" means perfectly aligned, firing
without pause, from the instant the carrier crosses the top edge and never dodging; and in both beats
the carrier arrives alongside other enemies that take fire and force movement. A real player will not
hold 200 or 333 dps on a carrier for its whole life. What 700 removes is the margin 1000 had, where
even shot level 4 needed 3.0 s and any interruption at all cleared the 4.0 s bar.

**This is the first thing the next play session should report: do the carriers spawn children?** If
they do not, the lever is the carrier's health or the `Spawner` interval — not the beat's length.

## Also worth the next session's attention

- **Beats pressured by durability are now cheaper and were deliberately not re-timed**, per the issue.
  `l1-first-basics` (13 basics at 2 projectiles each instead of 3) and `l1-light-and-fast` (13 lights,
  now one-hit kills) are the two that lost the most. `l1-light-and-fast` in particular is a beat whose
  only archetype now dies to a single projectile at every shot level; if any stretch reads as starved,
  it is that one. Reported, not fixed.
- **`enemy-tank` at 200 is 1.0 s of held fire at shot level 3.** Its beat, `l1-tanks-and-priority`,
  starts at 46.0 s, two seconds before the second upgrade at 48.0 s, so the priority shift it is built
  on rests on a target that dies in one to one and a half seconds. Not named by the session, not
  changed.
- **`bombDamage` 50 now removes 7% of a carrier**, up from 5%. `02-mvp-functional-spec.md` asks the
  bomb for "heavy damage to resistant enemies"; 7% still is not that. Recorded as open in
  `10-mvp-initial-values.md`, unchanged here because the bomb also lands on the boss's parts.
- **A stale comment in `core/`, out of this task's scope.** `LevelScoreReplayTest`'s javadoc
  (`core/src/test/java/dev/luchoc/littlespaceship/core/application/LevelScoreReplayTest.java:32-33`)
  says the tank and carrier "carry the same `health` points `assets/data/enemies.json` gives them (40
  and 80)". That was already wrong before this change and is now wrong twice over. The fixture is
  built in-test and reads no content file, so nothing breaks — but the comment claims a link that does
  not exist. `core-domain`'s to fix.

## Documentation

- `docs/planning/10-mvp-initial-values.md`: the health section is rewritten from "a candidate set,
  proposed 01/09/2026" to "decided 01/09/2026", with the new table, the carrier warning above, the
  corrected `weapon-upgrade` times (11.0 / 48.0 / 86.0 s, previously recorded as 21.0 / 133.5 / 256.0
  from a pre-11e level) and the bomb figure at 7%. The boss section carries a new bullet for the two
  projectile speeds and now says `entersAt 134.5`, correcting a stale `entersAt 302`.
- `docs/levels/level-01.md` and `docs/levels/waves.md` regenerated with `node tools/build-level-docs.js`.

## Checks section, in full

Two findings remain, both pre-existing and both deliberate — the generator prints every negative
offset by design:

- placement #9 `l1-high-pressure`, `offset -2.0`, overlapping `l1-evolved-shooters` by 2.0 s.
- placement #10 `l1-twin-carriers-attachment`, `offset -1.5`, overlapping `l1-high-pressure` by 1.5 s.

The third finding the previous run carried — the boss entering over a running wave — is gone.

## Verified

- `./gradlew build` — `BUILD SUCCESSFUL in 3s`. `./gradlew test --rerun-tasks` — `BUILD SUCCESSFUL in
  10s`, 9 tasks executed, nothing cached. No 11a rule-asserting test was touched and no rule changed.
- `node tools/build-level-docs.js` — `updated docs/levels/level-01.md`, `updated docs/levels/waves.md`;
  both committed.
- The whole content set loaded through the real parser: a throwaway `main` constructing
  `new JsonContentSource(new FileHandle(new File("assets/data")), "level-01")` printed
  `placements=12`, `boss.entersAt=134.5`, `boss.spread=85.0 sweep=125.0`, and five component specs for
  `enemy-light`, matching `enemy-rush` (the other archetype with no `health`) against six for
  every archetype that has one. `game/` has no test source
  set, so this cannot be a JUnit test.
- **Not checked:** the level was not played. Everything above about how it feels is arithmetic over the
  generated document, which is the point of the next session.

## Coordinator addendum, 01/09/2026 — the `Spawner` interval, 4.0 s to 3.0 s

**Added by the coordinator after this task reported, on the project owner's decision.** The finding
below was put to the owner with three options: keep 700 and let the next session judge, raise the
carrier back toward 850, or lower the `Spawner` interval. **They chose the interval, at 3.0 s.**

`assets/data/enemies.json`, `enemy-carrier.components.spawner.interval`: **4.0 -> 3.0**. Nothing else
moved, and the health stays at the 700 the session decided.

**The reasoning is the one this fragment already named:** the defect is that the carrier dies before
its mechanism runs, and the mechanism is the interval, not the health. Fixing it in the health would
have walked back the difficulty the owner approved by playing, one question after they approved it.

**What it closes, and what it does not — measured, not assumed:**

| beat | ideal time to kill | first child at 3.0 s? |
|---|---|---|
| `l1-heavy-carrier` (67.0 s, shot level 3) | 3.5 s | **yes, by 0.5 s** |
| `l1-twin-carriers-attachment` (97.5 s, shot level 4) | 2.1 s | **no — still under** |

**Beat 11 is not closed and this is stated rather than rounded away.** At shot level 4 an ideally
firing player kills a carrier in 2.1 s, so no interval above 2.0 s delivers a child there — and beat
11 is the difficult encounter that hands over the attachment, the beat where the mechanism matters
most. Going below 3.0 s was not taken: a carrier producing a child every 2 s is a different encounter
rather than the same one repaired. The project owner was told this before the number was applied.

**Still the first thing the next session should report, and now in two parts:** does the carrier spawn
children in beat 8, and does it in beat 11? They are no longer the same question.

`docs/planning/10-mvp-initial-values.md` is updated: the spawner section records `interval 3.0` as
decided on 01/09/2026 with its reason, and the carrier warning carries the table above.

**Re-run after the change:** `node tools/build-level-docs.js` (`level-01.md` updated, `waves.md`
unchanged) and `./gradlew build`, green.

**This task was merged without a `reviewer` pass**, on the project owner's explicit instruction. The
coordinator verified the five health values, the twelve wave definitions and twelve placements,
`boss.entersAt 134.5`, the two projectile speeds and the Checks section directly against
`assets/data/` before merging. That is a coordinator's check, not an independent audit, and it is
recorded here as such.
