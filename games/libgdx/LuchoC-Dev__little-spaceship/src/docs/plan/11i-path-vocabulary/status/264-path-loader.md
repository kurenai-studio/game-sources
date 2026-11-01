# 264 — the loader reads path trajectories, and mirrors a shape

**Branch:** `feat/path-loader`. **Closes:** [#264](https://github.com/LuchoC-Dev/little-spaceship/issues/264).

## What shipped

Both things the issue asked for, in `game/adapter/content/JsonContentSource.java`.

### 1. The `path` kind

`parseTrajectory` gained a third branch alongside `"constant"` and `"arc"`: `"path"` reads
`segments` (an array of `{vx, vy, duration}` or the `{"wait": seconds}` shorthand the issue #259
comment offered — translated here to `PathSegment(0, 0, seconds)`, since `core` only ever sees the
three-field record) plus optional `loopStart`/`loopCount`, and constructs a
`PathTrajectoryDefinition`. `requireOnlyKeys` covers the new top-level keys, so an unrecognised one
still fails loudly, exactly as it already does for `"constant"`/`"arc"`.

### 2. Mirroring — a `"mirrorOf"` key, resolved at content-load time

`loadTrajectories` now reads `trajectories.json` in two passes: every entry with a `"type"` (or the
implicit `"constant"` default) is parsed straight into the registry; every entry with a `"mirrorOf"`
key instead is deferred to `resolveMirror`, which:

- looks the referenced id up in the already-parsed registry, or recursively resolves it if it is
  itself a pending mirror entry (**a mirror of a mirror works**, chosen deliberately over refusing it,
  since nothing in the mechanism cares whether the id it negates is an authored shape or another
  mirror, and the issue only asked that *a cycle* fail);
- fails loudly, naming the offending id, if the referenced id resolves to neither an authored entry
  nor a pending mirror (**a bad mirror reference**);
- fails loudly, naming the whole chain (`a -> b -> a`), if resolving an id re-enters it (**a mirror
  cycle**), via a `LinkedHashSet` of ids currently being resolved.

The mirror itself — `mirror(String id, TrajectoryDefinition original)` — is composition, not a new
type: an `instanceof`-pattern chain over the three sealed permits, each branch calling that kind's own
public constructor with `vx` negated (per-segment, for a path) and every vertical field and
loop/duration parameter untouched. No new `core` API, no fourth kind, exactly as `core-domain` argued
on `TrajectoryDefinition`'s own javadoc and on issue #259.

**Why `"mirrorOf"` and not, say, a boolean flag or a derived id convention:** the id still needs to be
authored (content ids are not guessable from the original's), and naming the source explicitly is one
key, resolved once, versus a naming convention a loader would have to parse back apart. It also reads
directly against the issue's own worked example (`{"id": "veer-right-path", "mirrorOf":
"veer-left-path"}`), so there was no second syntax to argue for.

A mirror entry's schema is `"id"` + `"mirrorOf"` only — `requireOnlyKeys` rejects any other key on it
(covers the case of an author leaving a stray `"vx"` on a mirror entry by mistake, which would
otherwise load clean and silently be ignored).

### The one gap closed beyond the issue's own example

`core`'s own validation (e.g. `PathTrajectoryDefinition`'s rule-3 check, or a non-finite `vx`/`vy`/`ay`)
correctly names no id or file — see that class's javadoc, it is not `core`'s job. Wrapping every
`construct(...)` call in `parseTrajectory` with a try/catch that prefixes the trajectory id was needed
to keep "fails at load, naming the file and the id" true for the path-ends-at-rest case, which
otherwise surfaced only `core`'s own message with no id attached. This applies to all three kinds now,
not only `path` — `constant`/`arc` construction failures get the same id prefix.

## What did not change

`assets/data/trajectories.json` — untouched, per the task's own boundary (`level-designer`'s territory,
task 3). No test scenario or trajectory entry was added to it; every test below builds its own
in-memory content directory instead.

## Verified

- `./gradlew :game:test --tests "*JsonContentSourcePathTrajectoryTest*"` — green, 11 tests, in
  `game/src/test/java/dev/luchoc/littlespaceship/game/adapter/content/JsonContentSourcePathTrajectoryTest.java`.
  Each builds a minimal, self-contained content directory (`@TempDir`, `FileHandle(File)`, no
  `Gdx.app` needed) and calls the real `JsonContentSource` constructor:
  - `pathTrajectoryLoadsWithTurnWaitAndBoundedLoop` — a turn, a wait, and a bounded loop in one path,
    checked against `TrajectoryDefinition.vx()/vy()` and `horizontalVelocityAt`/`verticalVelocityAt` at
    several points in elapsed time, i.e. the exact interface `MotionSystem` reads.
  - `waitShorthandTranslatesToAZeroVelocitySegment`
  - `mirroringComposesFromTheOriginalWithNoSecondDefinition` — a path mirror, asserting every mirrored
    segment's `vx` is the negation of the original's and every other field is untouched.
  - `mirroringWorksForConstantAndArcKindsToo`
  - `mirrorOfAMirrorResolvesRegardlessOfDeclarationOrder` — `c` mirrors `b` mirrors `a`, declared in
    reverse order in the file.
  - `unknownTypeFailsAtLoadNamingFileAndId`
  - `malformedSegmentFailsAtLoadNamingFileAndId` — a segment missing `duration`.
  - `pathThatEndsAtRestFailsAtLoadNamingFileAndId` — the catalogue's rule 3, exercised through the
    loader rather than only in `core`'s own test.
  - `badMirrorReferenceFailsAtLoadNamingFileAndId`
  - `mirrorCycleFailsAtLoadNamingFileAndId`
  - `mirrorEntryRejectsAnyKeyOtherThanIdAndMirrorOf`
- `./gradlew build` — green, full repo.
- No `com.badlogic.gdx` import added anywhere outside `game/` — only `JsonContentSource.java` touched
  in `main`, plus the new test file.
- Read JSON with `JsonReader`/`JsonValue` throughout, per `CLAUDE.md`'s web-target pitfall — no `Json`
  serialisation class used anywhere in this change.
- `game/adapter/content/JsonBalanceValues.java` — not touched, per the task's explicit boundary
  (parallel task #261).
- `assets/data/level-01.json`, `waves.json`, `formations.json` — not touched.
- `./gradlew :desktop:run` launched and stayed up until manually terminated (no exception, no crash);
  the process was then killed via `taskkill`. This is "launch once to confirm it starts", not play —
  level 1's content carries no `path` or `mirrorOf` entry yet (task 3 is `level-designer`'s), so there
  was nothing new to watch even if it had been played, which it was not.
- **Not checked**: the web (TeaVM) target was not launched in a real browser this task — `./gradlew
  build` compiles `web`'s module against the same `JsonContentSource`, but per `CLAUDE.md` headless
  Chrome cannot validate the runtime and a real-browser check was outside what this task's change
  touches (no new web-specific code path).
