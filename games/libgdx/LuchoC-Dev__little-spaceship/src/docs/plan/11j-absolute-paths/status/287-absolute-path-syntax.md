# 287 — a path segment written as where it goes and how fast

**Branch:** `feat/absolute-path-syntax`. **Closes:** [#287](https://github.com/LuchoC-Dev/little-spaceship/issues/287).

## What shipped

`game/adapter/content/JsonContentSource.java` gained a second way to author a `path` trajectory's
legs. A `path` entry now takes exactly one of:

- `"segments"` — unchanged: `{vx, vy, duration}` or `{"wait": seconds}`, relative — a velocity held
  for a duration.
- `"waypoints"` — new: a list of points. The first is the entry point, `{"x", "y"}` only. Every
  element after it is either a destination, `{"x", "y", "speed"}` — the leg from the previous point
  to this one, at this speed — or `{"wait": seconds}`, which pauses without moving the running
  position. Each destination leg becomes exactly the `PathSegment(vx, vy, duration)` a hand-written
  `"segments"` entry would produce: `direction = normalize(B − A)`, `duration = |B − A| / speed`.
  No new `core` API — the same `construct`/`inFile` wrapping, the same
  `PathTrajectoryDefinition(id, segments, loopStart, loopCount)` call `parseSegments` already ends
  at.

Declaring both keys, or neither, on one `path` entry fails at load, naming the id. New methods:
`parseWaypoints` and `requirePlayfieldBounds`, both private, both in `JsonContentSource.java`. Two
new private constants, `PLAYFIELD_WIDTH = 208f` and `PLAYFIELD_HEIGHT = 270f`, duplicated locally —
`core.domain.system.MotionSystem`/`SpawnSystem` own the real ones, and `game` does not depend on
`core.domain`. `PlayScreen` already carries the same `208f` literal for the identical reason.

The syntax was posted on issue #287 as a comment before this fragment was written, per the phase's
own instruction that task 3 must not guess.

## The three decisions, argued

### 1. How a reader tells at a glance which kind of path they have

**The key, not the shape of the object.** `"segments"` means relative — velocity held for a
duration, the form `shape-catalogue.md` built. `"waypoints"` means absolute — a point to reach and
the speed to reach it at. These are two different top-level keys on the trajectory entry, not two
shapes the same array could take, so there is no segment-by-segment guessing: opening a `path`
entry and looking at which array it declares answers the question immediately, without reading a
single leg.

I considered making the *distinction* live inside one shared `"segments"` array instead — e.g. a
segment object could carry either `{vx, vy, duration}` or `{toX, toY, speed}`, distinguished by
which fields are present. I rejected this: it would let one path silently contain a mix of the two,
each leg individually readable but the *path as a whole* not answerable at a glance without reading
every entry, which is exactly the "puzzle" the task warns against. Two distinct top-level keys make
the answer a one-word scan of the entry, and make mixing a structural impossibility rather than
something a validator has to catch after the fact (though it still does, belt and braces — see
decision 2).

### 2. Whether mixing the two forms inside one path is allowed or refused

**Refused, loudly, naming the id.** `hasSegments == hasWaypoints` (both true or both false) fails
before either array is parsed. Once a path declares `"waypoints"`, every leg in it is a destination
or a wait — there is no per-leg fallback to `vx`/`vy`/`duration`.

The argument for allowing it would be flexibility — an author might want one turn expressed by
velocity and the next by destination. I rejected this because the whole point of decision 1 is that
the *kind of a path* is answered by its key, once, at the top. Allowing per-leg mixing inside
`"waypoints"` would mean the key no longer answers the question — a reader would still have to walk
every leg to know whether a `vx` might show up. Since nothing written asks for mixed authoring
(invariant 6) and the cost of refusing it is one comment posted early enough for `level-designer` to
design around, refusal costs nothing and keeps the "tells you at a glance" property actually true
rather than true-in-the-common-case.

### 3. Whether an absolute path should declare itself, so a level using it with an `atX` fails loudly

**It already does, syntactically — `"waypoints"` versus `"segments"` is the self-declaration this
question asks for. What is missing is a *runtime* check against how a wave actually places it, and
I did not build one.**

The reasoning: an absolute path's coordinates only mean what they literally say when the wave
placing it uses `atX = 0` — the first waypoint *is* the path's local origin, exactly the point
`atX` normally offsets. A loud failure here would mean: when a wave places a trajectory whose
`trajectories.json` entry used `"waypoints"`, at a nonzero `atX`, fail at load. Building that check
requires the loader to know, while parsing `trajectories.json`, which waves later reference which
trajectory ids and at which `atX` — information that today lives in a completely separate file
(`waves.json`), parsed independently, with no cross-reference from one to the other anywhere in
this class. `SpawnEvent`'s own `trajectoryId` is resolved lazily by `SpawnSystem` at runtime (this
agent's own memory on that point), not validated at content-load time, so there is no existing seam
to hang this check on without adding one.

I judged building that cross-reference machinery out of proportion to this task: it is a
level-content concern (which wave uses which trajectory at which `atX`) more than a
`JsonContentSource` concern (what one file's own entries mean), and `level-designer` — who owns
`waves.json` and writes task 3 next — is better placed to decide whether it is worth a real check
or a documented convention. I recorded it here and in the issue #287 comment instead of building it
silently, the same way #280 (a loop is always a path's tail) was recorded rather than fixed. **This
is the one place this task's own boundary — "you may not touch `core/`, and task 3 writes
trajectories, not you" — actually shaped the answer**: enforcing the constraint would need either a
`core` contract change (a trajectory declaring its own placement requirement) or a `waves.json`
cross-check, and neither is this task's to build.

If this surfaces as a real mistake once `level-designer` starts writing absolute paths, the fix is
small: a `waypoints`-declared trajectory's id could carry a naming convention (e.g. a `-fixed`
suffix), or `loadWaves` could be taught to reject a `SpawnEvent` whose `atX != 0` names a trajectory
id this loader already knows used `"waypoints"` — the two files are loaded by the same constructor,
in sequence, so the information is available by the time `loadLevel`/`loadWaves` run. That is future
work, not built here.

## Rule 3, tried rather than trusted

The task's own instruction was to try to break rule 3 through the absolute form rather than trust
the existing tests. A destination leg can never end at rest: its velocity is `(dx, dy) / duration`,
and a zero-distance destination (the only way both components could be zero) is refused explicitly
before a `PathSegment` is even constructed — "destination equals the previous point" fails loudly
first. The one way left to end an absolute path at rest is a trailing `{"wait": seconds}`, and that
reaches `core`'s own `PathTrajectoryDefinition` rule-3 refusal unchanged, wrapped with the
trajectory id by the same `construct()` this loader already used for the relative form.
`absolutePathEndingOnAWaitFailsCoresRuleThreeNamingFileAndId` in the test file exercises exactly
this. **No defect found**: the absolute form cannot express anything `core` cannot already bound,
because every path it produces is still just a `List<PathSegment>` handed to the same constructor.

## What did not change

- `core/` — not touched, per the task's boundary. No new `core` API.
- `assets/data/trajectories.json` and `assets/data/level-01.json` — not touched; every test below
  builds its own in-memory content directory.
- The speed multiplier (task 2) — not built.
- `mirror()` and `resolveMirror()` — unchanged; they operate on a `PathTrajectoryDefinition`'s
  already-resolved segment list, so mirroring a waypoint-authored path needed no new code, only a
  test confirming it (`mirroringWorksOnAWaypointAuthoredPathToo`).

## Verified

- `./gradlew :game:test --tests "*JsonContentSourceAbsolutePathTest*"` — green, 14 tests, in the new
  file `game/src/test/java/dev/luchoc/littlespaceship/game/adapter/content/JsonContentSourceAbsolutePathTest.java`
  (kept separate from `JsonContentSourcePathTrajectoryTest.java` so task 2, landing in the same
  production file, does not also collide on the same test file):
  - `waypointsProduceTheSamePathSegmentAHandWrittenVelocityAndDurationWould` — the equivalence claim
    itself, checked against arithmetic worked out by hand (a 30/40/50 triangle at speed 10), not
    just against the loader agreeing with itself.
  - `waypointsChainFromTheEntryPointThroughEveryDestinationInOrder`
  - `waitShorthandPausesWithoutMovingTheRunningPosition`
  - `mixingSegmentsAndWaypointsOnOnePathFailsAtLoadNamingFileAndId`
  - `pathTypeWithNeitherSegmentsNorWaypointsFailsAtLoadNamingFileAndId`
  - `destinationOutsidePlayfieldFailsAtLoadNamingFileAndId`
  - `entryPointOutsidePlayfieldFailsAtLoadNamingFileAndId`
  - `nonPositiveSpeedFailsAtLoadNamingFileAndId`
  - `destinationEqualToTheStartFailsAtLoadNamingFileAndId`
  - `onlyOneWaypointFailsAtLoadNamingFileAndId`
  - `entryPointWithASpeedFailsAtLoadNamingFileAndId`
  - `absolutePathEndingOnAWaitFailsCoresRuleThreeNamingFileAndId` — the deliberate rule-3 break
    attempt.
  - `mirroringWorksOnAWaypointAuthoredPathToo`
  - `loopStartAndLoopCountStillApplyToWaypointDerivedSegments`
- `./gradlew :game:test --tests "*JsonContentSourcePathTrajectoryTest*"` — green, all 11 pre-existing
  tests unaffected.
- `./gradlew build` — green, full repo.
- `grep -rn "core\.domain" game/src/main/java game/src/test/java` — every hit is either a pre-existing
  import in `AudioDirector.java` (untouched by this change) or a `{@code}`/javadoc-only mention; no
  real import of `core.domain` was added.
- Read JSON with `JsonReader`/`JsonValue` throughout — no `Json` serialisation class used.
- `./gradlew :desktop:run`, launched and left running ~20s: only standard LWJGL/JVM warnings in the
  log (native-access, `sun.misc.Unsafe`, a JNI-version notice), no exception, no crash; then killed
  via `taskkill`. This is "launch once to confirm it starts", not play — level 1's content carries
  no `waypoints` entry (task 3's job), so there was nothing new to watch even had it been played,
  which it was not.
- **Not checked**: the web (TeaVM) target was not launched in a real browser. `./gradlew build`
  compiles `web`'s module against the same `JsonContentSource`, but per `CLAUDE.md` headless Chrome
  cannot validate the runtime, and this task added no web-specific code path.
- **Not checked**: `gh run list --branch feat/absolute-path-syntax` before opening the pull request
  — will be re-checked immediately before opening it, per the task's own instruction.
