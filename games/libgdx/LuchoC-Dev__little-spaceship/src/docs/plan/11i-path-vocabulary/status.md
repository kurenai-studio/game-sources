# Phase 11i — A path is a list of segments, and a shape can be mirrored · status

**State:** **done and merged into `dev`** in [#284](https://github.com/LuchoC-Dev/little-spaceship/pull/284), with the project owner's approval on 04/09/2026. Eleven issues closed through eleven pull requests, all merged into the phase branch on 04/09/2026, CI green. **The project owner played the five path scenarios and approved the system.** All eleven issues were closed by hand in the same pass, since GitHub does not auto-close on a merge to a phase branch.
**Updated:** 04/09/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by whoever did that task on its own branch. Eleven fragments.

## Why this phase existed

The project owner drew eleven enemy paths on 03/09/2026 and **the movement vocabulary could not express any of them**. It needed segments, waits and bounded loops, plus mirroring so that a shape and its mirror are not two hand-written entries.

## Done

| Task | Issue | What | PR |
|---|---|---|---|
| 1 | [#259](https://github.com/LuchoC-Dev/little-spaceship/issues/259) | The path contract, its evaluation, and where mirroring belongs | [#263](https://github.com/LuchoC-Dev/little-spaceship/pull/263) |
| 2 | [#264](https://github.com/LuchoC-Dev/little-spaceship/issues/264) | The loader, and mirroring | [#267](https://github.com/LuchoC-Dev/little-spaceship/pull/267) |
| 3 | [#271](https://github.com/LuchoC-Dev/little-spaceship/issues/271) | Four paths and a scenario each | [#272](https://github.com/LuchoC-Dev/little-spaceship/pull/272) |
| 4 | [#260](https://github.com/LuchoC-Dev/little-spaceship/issues/260) | A dropped pickup falls, closing [#252](https://github.com/LuchoC-Dev/little-spaceship/issues/252) | [#262](https://github.com/LuchoC-Dev/little-spaceship/pull/262) |
| — | [#261](https://github.com/LuchoC-Dev/little-spaceship/issues/261) | The fall speed actually read from `balance.json` | [#268](https://github.com/LuchoC-Dev/little-spaceship/pull/268) |
| — | [#265](https://github.com/LuchoC-Dev/little-spaceship/issues/265) | `expireProjectiles` renamed to what it does | [#266](https://github.com/LuchoC-Dev/little-spaceship/pull/266) |
| — | [#269](https://github.com/LuchoC-Dev/little-spaceship/issues/269) | The loader tests, broken by integration | [#270](https://github.com/LuchoC-Dev/little-spaceship/pull/270) |
| — | [#274](https://github.com/LuchoC-Dev/little-spaceship/issues/274) | The scenarios listed in the TESTS menu | [#275](https://github.com/LuchoC-Dev/little-spaceship/pull/275) |
| — | [#276](https://github.com/LuchoC-Dev/little-spaceship/issues/276) | The TESTS menu overflowing nine entries | [#277](https://github.com/LuchoC-Dev/little-spaceship/pull/277) |
| — | [#278](https://github.com/LuchoC-Dev/little-spaceship/issues/278) | An oscillating loop — the shape the owner drew | [#279](https://github.com/LuchoC-Dev/little-spaceship/pull/279) |
| — | [#281](https://github.com/LuchoC-Dev/little-spaceship/issues/281) | That scenario listed in the menu | [#282](https://github.com/LuchoC-Dev/little-spaceship/pull/282) |

**Four planned tasks and seven defects found while the phase ran.** Six of the seven were found by someone who was not looking for them.

`reviewer` audited the four planned tasks and accepted all four; #272 with two corrections to its status fragment, applied by the coordinator before merge. The rest were audited by the coordinator, and each fragment says which.

## What the vocabulary is

`assets/data/trajectories.json` now carries **twelve** entries: the four `constant` and three `arc` shapes 11c built, plus four `path` entries and one mirror.

A `path` is `segments: [{vx, vy, duration}]`, with a `{"wait": seconds}` shorthand, and optional `loopStart`/`loopCount` for a **bounded** repeat. `{"mirrorOf": "<id>"}` produces the horizontally negated shape in one line — resolved at load, in any declaration order, and a mirror may point at another mirror.

**Bounding the loops is what made this phase small**, and it was the project owner's decision. `shape-catalogue.md` refused waypoints because *"each costs per-entity path state well beyond the elapsed-time clock"*. With bounded segments of known duration a path is **still a pure function of `elapsed`** — walk the list accumulating durations — so `Trajectory` still holds exactly `trajectoryId` and `elapsed`, and nothing was added. **The refusal was dissolved, not overridden**, and `enterAndHold`'s was genuinely reopened by a written case that did not exist. Both are struck through and dated in that file, saying which is which.

The one real contract change: `vx()` was fixed for an entity's whole life, and a path that turns needs the horizontal component to be a function of elapsed time too.

## The phase's own result

**Seven defects, and the phase was only asked to build four things.**

- **A tuning knob that was not connected.** #260 made pickups fall at `balance.pickupFallSpeed()` — a `default` on the port returning `20f`. `JsonBalanceValues` never read the key, and the balance parser does not reject unknown keys, so `assets/data/balance.json`'s `"pickupFallSpeed": 20.0` was **silently inert**. The value existed only so the owner could tune it by playing. A knob that is not connected is worse than no knob: the first session spent on it produces a conclusion about a number that never changed.
- **And nothing could have caught it.** `reviewer`'s finding: *"nothing in this PR's own test suite distinguishes 'value came from the interface default' from 'value came from parsed JSON'"*. #261 wired it **and** created the first test class `JsonBalanceValues` has ever had, with a fixture value that cannot pass against the default. **Its other twenty fields are still in that position** — none is asserted against a parsed fixture.
- **CI was red for four consecutive runs and nobody looked.** #260 added a key that `tools/build-level-docs.js` prints, and did not regenerate. `tools/pre-pr-check` does not run the generator; `./gradlew build` does not either, and that is what the coordinator ran after every merge — green every time, and the wrong instrument. **It was found because `level-designer` noticed a line in the generated document was not theirs**, and it was fixed by accident, when a later task regenerated for its own content. Had task 3 not needed to, the phase would have reached this pull request red.
- **Two branches, each green alone, red together.** #264's loader tests build their own `balance.json`; #261 made a key mandatory. The fixture became malformed content the instant the key existed. **That is the guarantee working** — malformed content dies at startup with the file named. Neither author nor either `reviewer` could have seen it: each ran a green build on a tree where the other change did not exist.
- **A description that disagreed with its own JSON.** `reviewer` re-derived `sweep-wait-drop`'s arithmetic instead of reading it, and every timestamp after the wait was half a second late — the wait's duration had been added to the sweep's *claimed* end rather than its real one. **The JSON was always right.** This is the failure task 3 was written to be able to produce, which is the only reason it was asked to write down what each path is meant to look like.
- **A menu that could not show nine entries.** `BaseUiScreen` has no `ScrollPane` and no clip, so two of the four paths and BACK were unreachable. `docs/STATUS.md` records the same cause from 25/08/2026 — *"`BaseUiScreen.content` has no clip"* — fixed then by making that screen fit rather than by making the container hold more. **Every screen since has been one entry away from it.**
- **The menu list cost three round trips.** It is hardcoded in `game/`, so every scenario needs a code change by a different agent than the one who wrote it. 11h chose that for four fixed entries and was right; it is now nine.

## Verified by the project owner

**Played on 04/09/2026 and approved.** The four paths read as intended; `stair-descent`'s staircase matched what its fragment said it would look like before they looked. The oscillation was added and approved afterwards.

**They also read the consequence of the format themselves**, which is what set 11j's agenda: since a segment is velocity × duration, raising speed **scales the shape** — an L becomes a bigger L. Useful, and it makes an absolute placement expensive to author.

## Decisions taken while implementing

- **Mirroring lives in the loader, not in `core`.** Every kind is a public record readable through its accessors, so a mirror composes at load time from existing constructors — no new `core` API and no fourth kind.
- **The `default` on `BalanceValues` stays.** `JsonBalanceValues` is the sole other implementer, and making the method abstract would break `game`'s compile from inside `core`'s module, which a `core-domain` task may not do. **The test is what makes a future unwired value visible; removing the default was not available.**
- **The `default` on `TrajectoryDefinition` is legitimate and the one on `BalanceValues` was a trap** — the same construct used for two different things. `horizontalVelocityAt` returning `vx()` states a permanent fact: neither `constant` nor `arc` has a case for horizontal acceleration. The other stood in for something unbuilt.
- **A pickup that falls off the bottom uncollected is destroyed with no event.** `EnemyDestroyed` is the only concrete `GameEvent` in the codebase; nothing downstream expected one.
- **The oscillation leaves through the side, by necessity rather than by choice.** See below.

## What is open

- **[#280](https://github.com/LuchoC-Dev/little-spaceship/issues/280) — a loop is always the tail of a path.** The range is `[loopStart, segments.size())`, so nothing can follow it and the exit is the last loop segment extrapolated. A zero-drift oscillation therefore *must* leave sideways. Sound for that shape and forced, not chosen: *"circle three times and then dive"* is currently unsayable. **No sketch the owner has drawn needs it yet.**
- **[#255](https://github.com/LuchoC-Dev/little-spaceship/issues/255)** — content cannot place a power-up, only an enemy carrying one. The 12 group.
- **`JsonBalanceValues`'s other twenty fields** are unverified against a parsed fixture. Not filed as an issue; recorded here and in #261's fragment.
- **Whether `tools/pre-pr-check` should run `node tools/build-level-docs.js`.** It is the one check a local build cannot reproduce, and this phase spent four red runs proving it. *"The coordinator should check CI"* is not a fix — that instruction already existed and was not followed.
- **Whether the TESTS list should be discovered from `assets/data/test-*.json`.** Now a measured cost, not a prediction.

## Notes for whoever comes next

**Phase 11j is the one this was built for**, and its agenda came out of the owner playing this phase rather than out of a plan:

1. **An absolute authoring syntax**, and it costs nothing in `core`. *"Entry point, exit point, speed"* is a reparameterization — `direction = normalize(B − A)`, `duration = |B − A| / speed` — and the loader hands `core` the same `PathSegment`. The same category as `mirrorOf` and `wait`. **The cost to accept knowingly: an absolutely-authored path can only happen in one place**, because a wave's `atX` stops meaning anything for it.
2. **A speed multiplier — and *"faster"* means two different things.** Same shape *bigger* (raise velocities: what happens today) versus same shape, same size, traversed sooner (raise velocities and divide durations). Not yet chosen. Scaling also has a ceiling nobody had stated: the playfield is 208×270, so a shape already crossing half the screen leaves it when doubled.
3. **Curves, which are the expensive one.** A semicircle out of constant-velocity segments is a polygon, unreadable in JSON past a few segments. True circular motion needs a rotating velocity, i.e. sin/cos — and `BossSystem` was deliberately built from vector arithmetic and `Math.sqrt` instead, *"so that determinism survives TeaVM"*. Its own decision, with a measured constraint.
4. **Level 1's redesign**, which is what all of it is for.

**Two coordinator errors, recorded rather than corrected quietly.** The phase was told not to touch `waves.json`, which was wrong — that file is the shared wave library, not level 1's content, and a wave has nowhere else to live; `level-designer` reported the violation with the evidence rather than hiding it, twice. And task 5's brief told an agent the standalone-pickup gap was filed as #252 when it was not, which reached a status fragment before `reviewer` caught it by checking the citation against what the issue actually said.

**The phase's own opening went through a pull request**, unlike 11g's and 11h's, which both landed their opening commit directly on the phase branch. That pattern is stopped.
