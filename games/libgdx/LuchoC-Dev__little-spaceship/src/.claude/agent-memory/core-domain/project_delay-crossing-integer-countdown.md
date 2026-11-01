---
name: delay-crossing-integer-countdown
description: Why the delayed-slot crossing moved from a float elapsed<=0f comparison to an integer Trajectory.delayTicks countdown, and what threading step through SpawnSystem cost.
metadata:
  type: project
---

Issue #337 (phase 11k) fixed a defect [[formation-slot-delay]] and its loader half both missed: a
delayed formation slot's crossing (`Trajectory.elapsed <= 0f`) compared two different float
arithmetic paths to the same nominal target — `elapsed` reached by repeated `+= step` accumulation,
versus `delaySeconds` reached by a single multiplication (the loader's quantisation, or a test
fixture's `delayTicks * step`). Those do not generally agree bit-for-bit. Swept over delays of 1..300
ticks, the crossing landed one tick early, permanently, for the bands **18–40 and 258–300** — about
22% of all tick counts, including the flagship `0.3s` (18-tick) example two prior tasks both used and
both happened to test with values (1 and 12) outside those bands.

**Fix:** `Trajectory.elapsed` never goes negative anymore. A new `int Trajectory.delayTicks` field
counts down instead — decremented by exactly one per tick in `MotionSystem.advanceTrajectories`,
`elapsed` untouched until the countdown hits zero. `SpawnSystem.applySlotDelay` sets it via
`Math.round(delaySeconds / step)`. The lesson generalizes: **when a "hold until a time value crosses
zero" pattern is fed a value that was itself constructed by different float arithmetic than the one
doing the accumulating, don't fix the comparison operator (`<=` vs `<`) — replace the float crossing
with an integer tick count entirely.** A single multiplication and N additions of the same nominal
target are not the same float in general, no matter how the comparison is spelled.

**Threading `step` into `SpawnSystem` cost three method signature changes** (`spawnDue`, `spawnWave`,
`applySlotDelay`) that had never needed it before — `SpawnSystem.update(world, step, input)` already
had `step` in scope, but nothing below it used to need the tick length. Any future `core` fix that
needs to convert a content-authored float into a tick count inside `SpawnSystem` will hit the same
threading cost; there's no shortcut around it since `GameLoop.STEP` living in `core.application`
cannot be imported from `core.domain` (would invert the dependency direction — checked by grep, no
existing domain class imports `application`).

**Proving the joint property (loader quantisation + `core` pipeline) required a `waves.json`/`"waves"`
level file, not the legacy flat `"events"` list** the existing `JsonContentSourceFormationDelayTest`
fixture writes for `level-test.json`. `SpawnSystem` reads `ContentSource.placements(levelId)`, which
only the `"waves"` format populates — `ContentSource.timeline(levelId)` (fed by legacy `"events"`) is
dead as far as `SpawnSystem` is concerned. A test driving a real `SpawnSystem` through `JsonContentSource`
must write its own `waves.json` + a `"waves"`-shaped level file, overwriting the shared fixture's
legacy `level-test.json` after calling it.

**`ComponentStore`'s dense array is append-only and insertion-ordered** (documented on the class
itself) — a test needing to tell two same-tick-spawned entities apart, once a field that used to
distinguish them (negative `elapsed`) no longer can, can rely on `entityAt(0)`/`entityAt(1)` matching
spawn order deterministically, as long as nothing has been destroyed yet.
