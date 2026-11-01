# 334 — the loader reads a formation slot's delay

**Branch:** `feat/loader-reads-slot-delay`. **Closes:** [#334](https://github.com/LuchoC-Dev/little-spaceship/issues/334).
`game`, `game/adapter/content/JsonContentSource.java` and `game`'s tests only. Nothing under
`core/`, `assets/data/` or `tools/` touched — the content that uses this (a single-file column in
level 1) is a separate branch, per the issue.

**Update (2026-09-06): [#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337) is fixed.**
The "not yet fixed" note below, and the correction it points at, describe the state between PR #336's
review and #337's fix. `core`'s crossing no longer compares `Trajectory.elapsed` against zero as a
float; it counts down an integer `Trajectory.delayTicks` instead, set from `Math.round(delaySeconds /
step)` in `SpawnSystem.applySlotDelay`. This loader's own quantisation (`Math.round(rawDelaySeconds *
60f) * TICK_SECONDS`, below) needed no change — it already produced the same exact-multiple-of-`step`
value `core`'s fix consumes; the mismatch was entirely inside `core`'s use of that value, never in how
this loader constructed it. `JsonContentSourceFormationDelayTest` gained
`aQuantisedDelayTracesTheLeaderExactlyThroughARealSpawnAndMotionPipeline`, which drives a real
`SpawnSystem`/`MotionSystem` from this loader's own quantisation for a delay in each of the two
previously-failing bands (18 ticks and 280 ticks) and confirms the follower now traces the leader
exactly that many ticks behind.

## What was built

`JsonContentSource.loadFormations` now reads an optional `"delaySeconds"` on each slot in
`formations.json` and constructs the three-argument `FormationSlot(offsetX, offsetY, delaySeconds)`
`core`'s #330 half added. A slot with no `"delaySeconds"` key defaults to `0f` — every formation
shipped before this issue has no such key, so every one of them loads to the identical
`FormationSlot` it always did.

`requireOnlyKeys(slot, "formation '" + id + "' slot", "offsetX", "offsetY", "delaySeconds")` was
added to each slot (there was no per-slot key check before this branch — only `offsetX`/`offsetY`
were ever read, so a typo'd key already loaded clean and was silently ignored). A construction
failure from `FormationSlot`'s own compact constructor (negative, `NaN` or infinite delay) is caught
and rethrown with the formation's id prefixed, then `inFile` adds the file name on top — matching the
pattern every other loader failure in this class already follows.

## The quantisation decision: quantise on parse, in seconds

Chose **option 1** from the `core` fragment: `delaySeconds` stays authored in seconds — consistent
with every other timestamp this content already authors that way (`SpawnEvent.at`, a pickup's
`at`) — and the loader rounds it to the nearest whole tick before it ever reaches `FormationSlot`:

```java
float delaySeconds = Math.round(rawDelaySeconds * 60f) * TICK_SECONDS;
```

where `TICK_SECONDS` is `1f / 60f`, duplicated in `JsonContentSource` from `core.application.GameLoop
.STEP` for the same reason `PLAYFIELD_WIDTH`/`PLAYFIELD_HEIGHT` already are — `game` does not depend
on `core.application`.

**Why this over "author a tick count":** a `"delayTicks"` key removes the rounding question by
construction, but it is a different unit from every other timestamp a level or a formation already
authors, and this content has only ever asked a designer to think in seconds. Quantising on parse
keeps the authoring surface uniform and pushes the actual float-precision problem to the one place
that already knows about it — the loader, not the person writing the JSON.

**What this means for what a designer actually gets:** the seconds typed in `formations.json` are, in
effect, a label for a tick count from the moment they are parsed — `0.3` and `0.31` both mean
"18 ticks", `0.283` and `0.3` mean different things only if they round to different tick counts. It is
not currently surfaced anywhere content authors read besides this fragment and the loader's own
javadoc; if a future task adds authored delays to a shipped level, that javadoc is the one place
documenting the rounding, and a generated doc for formations (there is none yet) would be the natural
place to state it explicitly once one exists. **Correction (`reviewer`, PR #336): a designer currently
gets the nearest tick, or the one before it — see below. This is not yet fixed.**

**The exactness guarantee does not hold in general, and `0.3` — this fragment's own flagship
example — is one of the values where it fails.** The paragraph originally here claimed that quantising
`0.3` to `18 * TICK_SECONDS` reaches `core` as "precisely the value" `SpawnSystemTest`'s exactness
tests already cover. That is wrong. `reviewer` built the check neither this branch nor #330's actually
ran — a scratch fixture driving a real `SpawnSystem`/`MotionSystem` pipeline from a quantised delay —
and found that for `18 * TICK_SECONDS` (`0.3` quantised, this fragment's own example) **the delayed
slot activates a full tick early, permanently**, with both a `constant` and an `arc` trajectory. Swept
over `N = 1..300` ticks, roughly **22% of tick counts fail — the bands 18–40 and 258–300** — because
`MotionSystem` reaches the crossing by *repeated addition* of `TICK_SECONDS` while the delay this
loader constructs (and `core`'s own `SpawnSystemTest` fixtures construct, identically) is a *single
multiplication*, and the two do not generally agree bit-for-bit. This loader's quantisation matches
`core`'s own tested construction exactly — the mismatch is between that construction and
`MotionSystem`'s accumulation, entirely inside `core`, and is **not this branch's to fix**. Filed as
[#337](https://github.com/LuchoC-Dev/little-spaceship/issues/337).

**`SpawnSystemTest.delayedSlotTracesLeaderPositionsExactlyDelayTicksBehind` (`N = 12`) and
`delayedSlotWithOneTickDelayTracesLeaderExactly` (`N = 1`) are not evidence the guarantee holds in
general — do not cite them as such.** Both `N` values happen to fall outside the 18–40 and 258–300
failing bands, which is exactly why the earlier version of this fragment could state the guarantee
confidently and be wrong: nothing in either half of this feature had swept a wider range of `N` before
`reviewer` did. `aDecimalDelayIsQuantisedToTheNearestWholeTick` still correctly pins this loader's own
half — an authored `0.3` loads to `18 * TICK_SECONDS`, not the raw `0.3f` literal — but that is a claim
about what the loader constructs, not about what `MotionSystem` does with it once it is constructed.

## Tests

New file `JsonContentSourceFormationDelayTest`, kept separate from the other `JsonContentSource*Test`
files for the same reason `JsonContentSourceSpeedMultiplierTest` already is — a parallel task landing
in `JsonContentSource` should not also collide on a test file.

- `aSlotWithNoDelayKeyProducesZeroDelay` — the back-compat case the acceptance criteria name
  explicitly: a slot with no `"delaySeconds"` produces exactly what it produced before this branch.
- `aDecimalDelayIsQuantisedToTheNearestWholeTick` — the quantisation decision itself, using `0.3`
  (one of the `core` fragment's five measured values) and asserting the loaded `delaySeconds` equals
  `18 * TICK_SECONDS`, not the raw literal.
- `aWholeTickDelayIsUnchangedByQuantisation` — a delay that is already an exact multiple of the tick
  (`0.2` → 12 ticks) round-trips to the same value.
- `aNegativeDelayFailsAtLoadNamingFileAndFormation` — `FormationSlot`'s own guard surfaces through
  `inFile`'s wrapping, naming both `formations.json` and the formation's id.
- `anUnrecognisedSlotKeyFailsAtLoadNamingFileAndFormation` — the new `requireOnlyKeys` call on each
  slot, naming both the file and the formation.

## Acceptance criteria

- [x] A formation slot in `assets/data/formations.json` can carry a delay, and the loader constructs
  a `FormationSlot` that carries it — not exercised against the shipped file (no level uses this yet,
  per the issue's scope), exercised against fixture JSON in the new test file instead.
- [x] A slot with no delay produces exactly what it produces today — `aSlotWithNoDelayKeyProducesZeroDelay`;
  `node tools/build-level-docs.js` prints `unchanged` for both `docs/levels/level-01.md` and
  `docs/levels/waves.md`; `./gradlew build` green, all five `core` replay test classes
  (`BombReplayTest`, `BossReplayTest`, `DamageReplayTest`, `LevelScoreReplayTest`,
  `SimulationTest`) included and unchanged.
- [x] A malformed or negative delay is refused at load with a message naming the file and the
  formation — `aNegativeDelayFailsAtLoadNamingFileAndFormation`.
- [x] The quantisation decision is implemented, tested, and stated above with the drift measurement
  behind it.
- [x] `./gradlew build` green.

## Commands run

- `./gradlew :game:compileJava --console=plain -q` — clean, no output.
- `./gradlew :game:test --tests "*FormationDelayTest*" --console=plain` — `BUILD SUCCESSFUL`, all 6
  new tests passed.
- `./gradlew build --console=plain` — `BUILD SUCCESSFUL`, every module (`core`, `game`, `web`,
  `desktop`, `rngparity`) built, including `core:test` (the five replay suites) and `game:test`.
- `node tools/build-level-docs.js` — printed `unchanged  docs/levels/level-01.md` and
  `unchanged  docs/levels/waves.md`.
- `tools/pre-pr-check --base phase/11k-level-one-rebuilt` — output pasted into the pull request.
