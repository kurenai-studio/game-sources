---
name: wave-migration-mechanics
description: How WaveDefinition/WavePlacement actually behave, learned migrating level-01.json to waves (phase 11b, task 6, #114)
metadata:
  type: project
---

Learned migrating `assets/data/level-01.json`'s 92 flat events into `assets/data/waves.json` (13
`WaveDefinition`s, 15 `WavePlacement`s), verified with a from-scratch Python reconstruction of every
original absolute spawn time plus a live scratch run against the real content (see PR #125 against
`phase/11b-wave-system`, and that phase's `status.md`, task 6).

**A wave's `FixedDuration` is one value shared by every placement that references it — it is not
per-placement.** Reusing a wave id at several points in a level, where the real gap to whatever
follows differs each time, means the wave's own declared duration has to be the *smallest* of those
gaps (or smaller), and every placement immediately after an occurrence makes up the rest of its own
real gap through its own `offset`. This is exactly the mechanism that let `l1-tank-solo` (a single
`enemy-tank`/`single`/`atX 0.5` spawn, the only exact spawn-composition duplicate anywhere in
level 1) get placed three times at 86.0s, 126.5s and 297.0s with real subsequent gaps of 6.0s, 2.5s
and "nothing, it's last" — duration pinned at 1.0s, offsets of 5.0 and 1.5 made up the difference
after the first two.

**A negative `WavePlacement` offset was a no-op when this was written, and no longer is.** Re-checked 31/08/2026 on `phase/11d-per-level-document`: `SpawnSystem.scheduleChain` now resolves a `FixedDuration` wave's follower *predictively*, at the instant the wave starts, and only the reactive `Cleared` path clamps forward to `levelTime` — so a negative offset genuinely overlaps two `FixedDuration` waves and both sit in `activeWaves` at once. The paragraph below records what was observed during 11b and is kept because the reasoning about the clamp is still how the `Cleared` case behaves.

**As of 11b (superseded above):** a negative offset was a no-op — checked by
reading `SpawnSystem.scheduleNext`/`resolveEnded`: `scheduleNext`'s `previousEndTime` argument is
always exactly the current `levelTime` at the instant it's called (either the explicit `0f` at level
start, or `levelTime` passed straight through from `resolveEnded`), so `Math.max(previousEndTime +
offset, levelTime)` clamps any negative offset straight back to `previousEndTime` itself, identical
to offset `0`. The class javadoc's own framing ("a negative offset can therefore place the next
wave's start before that detection tick... clamped forward") reads as if overlap is achievable this
way; observed behaviour says it isn't, for either end-condition kind, since the clamp source and the
comparison value are the same variable at every call site. Worth a second look — possibly by
`core-domain` — before a future phase (11c/11d) designs a beat around a negative offset expecting it
to overlap something.

**No automated test exercises the real `assets/data/level-01.json`.** `LevelScoreReplayTest` (the
"determinism replay" the 11b plan's acceptance criteria hinge on) builds its own level entirely
in-test through `TestContent`/`SimpleWaveDefinition`/`withSingleWavePlacement` and never touches
`assets/data/` — confirmed by reading the test file. Content correctness there has to be verified by
hand: a from-scratch reconstruction of expected absolute times, or a live run.

**A live run of the real content is doable without a full libGDX application context.**
`com.badlogic.gdx.files.FileHandle` has a public constructor over a plain `java.io.File`, and
`JsonReader`/`JsonValue` need no `Gdx.app` either, so a standalone `main` compiled against
`core.jar` + `game.jar` + `gdx-<version>.jar` (found under
`~/.gradle/caches/modules-2/files-2.1/com.badlogicgames.gdx/gdx/`) can build a real
`JsonContentSource` over the actual `assets/data` directory and tick a real `Simulation` through it,
watching `WorldView.forEachSprite`/`bossStatus` for when things actually spawn. This is faster than
`./gradlew :desktop:run` and screenshots when the question is "did the spawn timing come out right",
not "does it look right".
