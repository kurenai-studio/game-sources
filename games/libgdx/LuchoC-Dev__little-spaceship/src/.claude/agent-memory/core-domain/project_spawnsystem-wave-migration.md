---
name: spawnsystem-wave-migration
description: Migrating SpawnSystem from a flat WaveTimeline cursor to WavePlacement/WaveDefinition (#112) — the first-tick scheduling bug, how to trust an inherited uncommitted diff, when a ContentSource method may actually be defaulted, a self-equality test trap a reviewer's mutation testing caught, and the first-wave one-tick head start.
metadata:
  type: project
---

Phase 11b, task 4 (#112, PR #121 against `phase/11b-wave-system`). Picked up from a previous
`core-domain` run killed mid-work by a spend limit, with a large uncommitted diff already in the
worktree. `SpawnSystem` now walks `ContentSource.placements(levelId)` — an ordered list of
`WavePlacement`, each resolving a `WaveDefinition` via `ContentSource.wave(String)` — instead of a
single cursor over `WaveTimeline.events()`. See [[project_wave-content-contract]] for the content
types this builds on.

**A clamp meant for one case silently broke a different, earlier case — and only running the
inherited tests unmodified caught it.** `scheduleNext(previousEndTime)` clamps a placement's start
forward to `levelTime` so a negative offset following a late-detected `Cleared` wave never schedules
into the past — correct and necessary. But the inherited `update()` called `levelTime += step` *before*
scheduling the level's very first placement, so that same clamp also pushed the first wave's start
from 0 to one step, delaying every one of its spawn events by exactly one tick. Nothing in the new
code's own logic looked wrong in isolation; what surfaced it was running the *old*, unmodified
`SpawnSystemTest` (before rewriting it) against the *new* `SpawnSystem` — 16 of 24 tests failed with
entities not spawning at all. Fixed by scheduling the first placement before the step is added, so it
starts at level time zero, matching what the old flat-cursor system did. **Lesson: when inheriting
unfinished work whose own tests haven't been migrated yet, run the untouched old test file against the
new production code first, before rewriting the tests — it is a free regression check that a rewritten
test file can no longer give you, since a bug and its test can both be wrong the same way.**

**A type signature change (`WaveOrigin.waveId` from `int` to `String`) breaks compilation at every
call site, not just the ones the task's own file list names.** `SpawnerSystemTest` and `WorldTest` —
neither mentioned in the task brief's list of files to touch — both constructed `new WaveOrigin(1)`
directly and failed to compile once the field became a `String`. `./gradlew :core:compileTestJava`
(not just the target test class) is what caught these; a partial test run would have stayed green while
the whole module failed to build.

**`WaveTimeline`'s "superseded, not yet retired" state (see [[project_wave-content-contract]]) held
past this task too, for the same reason.** `game`'s `JsonContentSource` still populates it for
`level-01.json`, not yet migrated (issue #114) — `core-domain` may not edit `game`. Checked this held
by grepping `game/src` for `WaveOrigin`/`SimpleWaveTimeline` usage and running a whole-repo
`./gradlew compileJava compileTestJava` before opening the PR — clean.

**Correction, caught by `reviewer`: `ContentSource.timeline(String)` should not have become a
`default`, and I wrote it as one on my first pass without checking whether the reason actually applied.**
I copied `wave(String)`'s justification ("kept defaulted because `game`'s `JsonContentSource` still
overrides it") without checking whether `timeline()` had the same *gap in implementers* that
justifies a default there — it doesn't: both `JsonContentSource` and `TestContent` already implement
`timeline()` on this branch, so nothing forces the demotion; `./gradlew build` stays green with it
abstract. **The actual rule a `default` on `ContentSource` is for: at least one production
implementer genuinely doesn't have the method yet** (true for `wave`/`placements`, both waiting on
issue #113's loader), not "this method is part of the same retirement story as another one that is."
Before defaulting a `ContentSource` method, grep every known implementer (`game`'s adapter, `core`'s
`TestContent`) for an existing override, not just reuse a neighbouring method's stated reason.

**A conditional final step in an issue comment needs the actual PR state checked, not just a local
branch grep.** #112's issue comment said to flip `ContentSource.wave(String)` to abstract only once
#113 is merged into `phase/11b-wave-system`. `git log phase/11b-wave-system | grep 113` found nothing
(no commit trailer names it), but the reliable check was `gh pr list --base phase/11b-wave-system`,
which showed #113's implementation (PR #120) still `DRAFT`, plus confirming `JsonContentSource` has no
`wave(String)` override yet. Left the default in place, per the comment's own instruction not to block
on it.

**Correction, caught by `reviewer` via mutation: a test that reuses the same object instance across
two "different" inputs and asserts equality proves nothing, however real the surrounding setup looks.**
My first version of `movingAPlacementEarlierChangesNoOtherOffset` built two `List<WavePlacement>` by
hand, put the *same* `WavePlacement` object in both, and asserted it equalled itself — it never called
`SpawnSystem`, `World` or `update()`, so it stayed green under every mutation `reviewer` tried,
including deleting the `do { … } while (progressed)` re-check loop that a real test
(`negativeOffsetOverlapsTwoWaves`) correctly caught. **Lesson: a rule-named test for a
`SpawnSystem`/timing property must actually run `SpawnSystem`; a test that only exercises the record's
own `equals()` or constructor is testing a different, much weaker claim than its `@DisplayName` states.**

**Rewriting that test surfaced a genuine, separate tick-quantisation asymmetry worth knowing about
`SpawnSystem`: the level's very first wave gets a real one-tick head start no later-scheduled wave
gets.** The first placement is scheduled *before* `levelTime += step` on tick 1 (see the fix above), so
its clock starts at level time 0. Every other wave is scheduled from inside `resolveEnded`, which runs
*after* the increment, so its clock starts at whatever `levelTime` already reached that tick — but
thanks to the `do { … } while (progressed)` loop, it still gets to fire its own zero-offset spawn event
in that same tick, not the next one. Net effect: comparing "tick wave-A's own spawn fires" to "tick
wave-B's own spawn fires" is invariant to what precedes wave-A *only if wave-A is never itself the
level's literal first placement* in either scenario being compared — otherwise the comparison silently
mixes in this one-tick artefact and produces a real, reproducible off-by-one (measured directly: 5 vs.
6 ticks) that has nothing to do with the property under test. Fixed by anchoring the wave under test
behind an unrelated filler wave in both scenarios. **Lesson: a test that runs two scenarios through a
tick-quantised system and diffs a derived tick count needs to rule out boundary-only differences
(here, "is this entity's wave the very first one") before trusting the diff means what the test claims.**
