# Task 3 — the TESTS list is discovered from `assets/data/test-*.json`

Issue [#311](https://github.com/LuchoC-Dev/little-spaceship/issues/311).

## What changed

`TestScenarios.ALL` (a hardcoded `List.of(...)` literal, fourteen entries by phase 11j) is gone.
`TestScenarios.all()` now discovers every `test-*.json` file directly under `assets/data/` at
runtime — through `FileHandle#list(".json")` on `Gdx.files.internal("data")` — and builds a
`Scenario` for each, sorted alphabetically by level id. `TestMenuScreen` calls `TestScenarios.all()`
instead of the old field. Adding a scenario file under `assets/data/` and nothing else now puts it
in the TESTS menu, closing the gap #301 needed a whole second pull request for.

`ALL` became a method (`all()`), not a field, because a field's initializer runs the moment the
class is loaded — which happens the moment a test references *any* member of `TestScenarios`,
including the package-private `discover(FileHandle)` the test exercises directly. An eager field
calling `Gdx.files` failed every test with `ExceptionInInitializerError` in the headless JUnit
process, regardless of which method the test actually called. Discovered by running the test suite
once with the field still eager (all ten failed with the same cause) and fixed by making it lazy.

## The label decision, and why

The plan's own text raised two ways to keep the `LINE:`/`PATH:`/`ABS:` prefix #301 decided: derive
it from a new level-schema key, or derive it from the trajectory the scenario places. Took the
second, as recommended: `JsonContentSource.requireOnlyKeys` needed no change, and the label comes
out right by construction from content that already exists. Concretely:

- If the level file has a `"boss"` key, the label is `BOSS`, no trajectory lookup needed.
- Otherwise, the first spawn (across the level's waves) that carries an explicit `"trajectory"` key
  decides the prefix: `LINE` for a trajectory with no `"type"`, `PATH` for `"type": "path"` with
  `"segments"`, `ABS` for `"type": "path"` with `"waypoints"`, and `ARC` for `"type": "arc"` — a
  fourth prefix #301 never needed because no scenario used an arc yet. `"mirrorOf"` and `"speedOf"`
  are followed to whatever they ultimately derive from, the same way
  `JsonContentSource#resolveDerived` does, with a cycle guard that gives up rather than looping.
- If no spawn overrides its trajectory (an ordinary wave, e.g. `test-wave-04`, which plays its
  archetypes' own default movement), the label falls back to the id itself, uppercased with dashes
  turned into spaces — `test-wave-04` reads `WAVE 04`, not the old hand-picked `WAVE 4`.
- Label derivation never throws. A malformed or missing reference falls back to the id-derived name
  instead of failing the whole menu — the scenario's actual content is still validated, loudly, by
  `JsonContentSource` the moment it is opened; this class only decides what to print on a button
  before that happens.

This reads raw `trajectories.json`/`waves.json` with `JsonReader`/`JsonValue` directly, not through
`JsonContentSource`'s resolved `TrajectoryDefinition` objects — a resolved `PathTrajectoryDefinition`
cannot tell `PATH` from `ABS` apart, since both authoring forms compile down to the same
`PathSegment` list by design (11j). The raw JSON's `"segments"` vs `"waypoints"` key is the only
place that distinction still exists.

Checked against every scenario the repository ships today, with a real `discover()` call against the
actual `assets/data/` (a throwaway classpath run against the compiled `-Ptests` classes, reflection to
reach the package-private method, no game launch):

```
test-100-cross          LINE: CROSS
test-090-slide-descend  PATH: SLIDE DESCEND
test-080-dive-retreat   PATH: DIVE RETREAT
test-070-hold-line      ABS: HOLD LINE
test-060-sweep-width    ABS: SWEEP WIDTH
test-050-path-oscillate PATH: OSCILLATE
test-040-path-turn      PATH: TURN
test-030-path-mirror    PATH: MIRROR
test-020-path-wait      PATH: WAIT
test-010-path-loop      PATH: LOOP
test-boss               BOSS
test-wave-04            WAVE 04
test-wave-09            ARC: WAVE 09
test-wave-12            ARC: WAVE 12
```

The order above is exactly what `discover()` returns — numbered scenarios descending, unnumbered ones
after, alphabetically among themselves — which reproduces the old hardcoded list's order exactly for
the ten renamed scenarios. Most labels come out identical or equivalent to the old hand-picked ones;
`PATH: SLIDE DESCEND`, `PATH: DIVE RETREAT` and `ABS: SWEEP WIDTH` are longer than the old shorthand
(`PATH: SLIDE`, `PATH: RETREAT`, `ABS: SWEEP`) but not wrong, left as an open item below.
`test-wave-09` and `test-wave-12` were expected to fall back to a generic name like `test-wave-04`
does, on the assumption every wave scenario plays its archetypes' own default movement — checking
their actual content (`l1-high-pressure` and `l1-final-escalation`, not `l1-combined-formations`)
shows they do override a spawn's trajectory with an arc shape, so `ARC: WAVE 09`/`ARC: WAVE 12` is the
label deriving correctly from real content, not a bug.

## Ordering, revised: the project owner ruled #291's stack stays

**This section replaces the original answer this task shipped, which was a plain alphabetical sort.
The project owner ruled on it after review: alphabetical does not satisfy #291 and cannot be kept —
the stack stays, last-created first.** The first cut of this task reasoned that nothing about a
filesystem listing carries "when was this added" deterministically, which is true, and concluded the
recency signal had to be dropped. The actual answer is that it has to be carried by the content
instead: a scenario file that wants to sort by recency is named `test-NNN-<name>.json`, where `NNN`
is a number chosen at authoring time. `TestScenarios.rankOf` reads it back out of the level id with a
regex (`^test-(\d+)-(.+)$`), and `discover` sorts numbered scenarios by it, **descending** — the
highest number, first, exactly as the old hand-ordered stack put its newest entry on top. Numbers are
spaced by ten (`010`, `020`, …) so a later scenario can be inserted between two existing ones without
renaming anything, per the project owner's own instruction.

`FileHandle#list()`'s own iteration order is still the filesystem's, unspecified and different across
platforms — the fix is not to trust it, it is still explicitly re-sorted afterward, only now by the
number in the name rather than the whole id. That determinism argument survives from the first cut;
only the conclusion it was used to reach (that recency could not survive) was wrong.

**A level id with no number is not dropped and not placed arbitrarily.** It carries no recency signal
of any kind, so it cannot be honestly interleaved with the numbered ones — every unnumbered scenario
sorts after every numbered one, and alphabetically among its own kind, the same determinism reasoning
applied one level down. `test-boss.json`, `test-wave-04.json`, `test-wave-09.json` and
`test-wave-12.json` are today's only examples: the batch phase 11h authored before this convention
existed. They are deliberately left unrenamed — see "Scope of the rename" below — which means this
policy is exercised by real shipped files, not only by a synthetic fixture.

## Scope of the rename: ten files, not fourteen

The ten scenarios phases 11i and 11j added (`test-cross`, `test-slide-descend`, `test-dive-retreat`,
`test-hold-line`, `test-sweep-width`, `test-path-oscillate`, `test-path-turn`, `test-path-mirror`,
`test-path-wait`, `test-path-loop`) are renamed to `test-NNN-<name>.json`. The batch order the old
hardcoded `TestScenarios.ALL` list already encoded (front = newest) is the source of truth for what
"authored order" means here — reversed to assign ascending numbers from oldest to newest, ten apart,
starting at `010`:

| old file | new file | rank |
|---|---|---|
| `test-path-loop.json` | `test-010-path-loop.json` | oldest of the ten |
| `test-path-wait.json` | `test-020-path-wait.json` | |
| `test-path-mirror.json` | `test-030-path-mirror.json` | |
| `test-path-turn.json` | `test-040-path-turn.json` | |
| `test-path-oscillate.json` | `test-050-path-oscillate.json` | |
| `test-sweep-width.json` | `test-060-sweep-width.json` | |
| `test-hold-line.json` | `test-070-hold-line.json` | |
| `test-dive-retreat.json` | `test-080-dive-retreat.json` | |
| `test-slide-descend.json` | `test-090-slide-descend.json` | |
| `test-cross.json` | `test-100-cross.json` | newest of the ten |

Sorted descending by rank this reproduces the exact order the old hardcoded list had them in —
checked by hand, and by a real `discover()` run against the actual (renamed) `assets/data/`, below.

**The other four scenario files — `test-boss.json`, `test-wave-04.json`, `test-wave-09.json`,
`test-wave-12.json` — are deliberately left unrenamed.** They are the batch phase 11h authored before
this ordering convention existed, and this task's scope, as stated, is "renaming those ten
`test-*.json` files" — a stated exception to `assets/data/` being `level-designer`'s, and not wider
than what was stated. Leaving them also gives the "file that does not match the convention" rule a
real case to prove itself against, rather than only a synthetic one — see the ordering section above
and `TestScenariosTest`'s fixtures shaped to match.

**Only file names changed. No file's contents changed.** A level file's `"waves"` block references a
*wave* id (from `waves.json`), which is independent of the level file's own name — `test-100-cross`
still points at wave id `test-cross` inside `waves.json`, exactly as `test-wave-04` has always pointed
at wave id `l1-combined-formations`, a completely different string. Renaming the level file changes
nothing that any wave, trajectory, formation or enemy definition reads.

### References the rename touches, and references it deliberately does not

Checked every file in the repository containing any of the ten old names
(`grep -rln` across `.md`/`.js`/`.java`/`.json`, excluding `assets/data/` itself and `web/build/`
build output):

- **`docs/levels/waves.md`** and **`docs/planning/08-decisions-and-open-items.md`** reference the
  *wave* ids (`test-cross`, `test-path-turn`, …) and the *unrenamed* level ids
  (`test-wave-04`/`09`/`12`, `test-boss`) — neither changes, because neither is the level filename
  this task renames.
- **`.claude/agent-memory/level-designer/…`** and **`.claude/agent-memory/reviewer/…`** only mention
  the four unrenamed ids. Untouched — not this task's memory to edit even if they had mentioned a
  renamed one.
- **`docs/plan/11h-*/status/`, `docs/plan/11i-*/status/`, `docs/plan/11j-*/status/` and their
  `status.md` files** are dated records of what those phases did, written in the past tense about
  files that had those names at the time. Left exactly as written — rewriting them to use the new
  names would misrepresent what those phases actually shipped and read. This task's own instruction
  said so explicitly, and `docs/plan/11j-absolute-paths/status/301-tests-menu-11j-scenarios.md` in
  particular is exactly this kind of record.
- **This status fragment and `TestScenarios`'s own javadoc** are not sealed history — they are part
  of this same task, not yet reviewed — so both are updated in place to describe the ranked
  convention, rather than kept as a record of the alphabetical answer this task shipped first.
- **Nothing under `tools/`** references any of these ids; confirmed by the same grep. Out of scope
  either way, per this task's own instructions.

## The web-target risk, read and accepted rather than fixed

Read `backend-web-1.6.1-sources.jar` (`com.github.xpenatan.gdx-teavm:backend-web:1.6.1`) out of the
Gradle cache before writing any of this, per the plan's own advice. `WebFiles.getFileDB(FileType.Internal)`
returns an `InternalStorage extends MemoryFileStorage`, and `MemoryFileStorage#list()` walks an
internal `OrderedMap<String, FileData>` that only `writeInternal` (used by `FileType.Local`, i.e.
browser local storage) is ever seen populating in that jar — nothing populates it for a preloaded
internal asset. The actual asset-copy step observed during `:web:gdx_teavm_web_js_build` (every file
under `assets/` listed individually as `Copied [Internal] ...`) is a build-time manifest the TeaVM
plugin bakes in, not something `list()` reads back at run time. This matches `JsonContentSource`'s
own already-documented claim that `FileHandle#list()` "has no answer for the web target's asset
packaging" — I found nothing in the backend to contradict it and one more piece of evidence for it.

Accepted rather than avoided, for three reasons: this class is compiled only under `-Ptests`, which
has never been combined with a `:web` build; on desktop `FileHandle#list()` is backed by a real
`java.io.File#listFiles()` and behaves exactly as needed; and this task's own acceptance criterion is
that the `-Ptests` build *compiles*, not that it runs correctly under TeaVM. If a future phase wants
this flavour on the web target, discovery needs to move to build time (a generated source, the way
the level documents are generated) rather than trusting this backend's `list()` at run time — written
down as an open item below rather than solved here, since solving it is out of this task's scope.

## New test infrastructure

`game/build.gradle.kts` gained a second conditional source directory, `game/src/testsTest/java`,
added to the `test` sourceSet only when `-Ptests` is present — mirroring the existing `main`
sourceSet toggle for `src/tests/java`/`src/teststub/java`. Needed because `TestScenariosTest`
references `TestScenarios` directly, which does not exist as a compiled class outside `-Ptests`, so
an unconditional `src/test/java` file would break `./gradlew :game:test` for everyone else.

`TestScenariosTest` (`game/src/testsTest/java/.../screen/TestScenariosTest.java`) exercises
`TestScenarios.discover(FileHandle)` against a `@TempDir` fixture directory, never against the real
`assets/data/` — fourteen tests: prefix filtering, numbered scenarios sorting by rank descending
regardless of creation order, numbered scenarios sorting before every unnumbered one, unnumbered
scenarios sorting alphabetically among themselves, a numbered scenario's rank disappearing from its
fallback label, an oversized recency number sorting as unnumbered rather than throwing (`reviewer`'s
finding, below), each label kind (`BOSS`, `LINE`, `PATH`, `ABS`, `ARC`), a mirrored trajectory taking
its target's kind, a wave with no trajectory override falling back to its id-derived name, and a
cyclical `mirrorOf` pair falling back rather than looping forever.

## `reviewer`'s finding on PR #313, and the fix

`reviewer` accepted the PR with one defect: `rankOf`'s pattern, `^test-(\d+)-(.+)$`, bounds the digit
count in no way, and the captured group went straight into `Integer.valueOf` with no `try/catch`. A
level id like `test-99999999999999999999-name` matches the pattern and then overflows `int`, throwing
`NumberFormatException` out of `rankOf`, out of `compareByRecency` (the comparator `List.sort` calls
from inside `discover`), out of `discover` itself, and into `TestMenuScreen`'s constructor — which
has no guard around the call. One malformed file name did not cost that one scenario its recency
rank, it crashed the whole TESTS menu at construction. `reviewer` reproduced it directly against an
isolated scratch file before reporting it; reproduced here too, by reverting the fix on this exact
code and re-running `TestScenariosTest`, watching `anOversizedRecencyNumberSortsAsUnnumberedRatherThanThrowing`
fail with `NumberFormatException` at the line the fix removes, then restoring it.

The javadoc's claim that label derivation "never throws" was also imprecise: it genuinely holds for
`labelFor` (which has its own `try/catch`, added in the first cut of this task) but did not extend to
`rankOf`, which decides sort order rather than label text and had none. Fixed both: `rankOf` now
catches `NumberFormatException` and returns `null` — the same value it already returns for a level id
the pattern does not match at all, so no new branch in `compareByRecency` was needed — and the class
javadoc now states the guarantee against both methods, with the reason `rankOf` needs it explicitly:
a level-designer typo must not take the whole menu down with it.

## Verified

- `./gradlew :game:compileJava -Ptests` — `BUILD SUCCESSFUL`.
- `./gradlew :game:test -Ptests` — `BUILD SUCCESSFUL`, all fourteen new tests plus the existing suite
  green.
- `./gradlew :game:clean :game:test` (no `-Ptests`) — `BUILD SUCCESSFUL`, and
  `find game/build/classes -iname "*TestScenarios*"` printed nothing: the ordinary build compiles
  none of it, exactly as before this change.
- `./gradlew :web:gdx_teavm_web_js_build` (no `-Ptests`, the shipped configuration) — run across all
  three revisions of this task (including after `reviewer`'s fix), `BUILD SUCCESSFUL` every time;
  `grep -c "TestMenuScreen\|TestScenarios" web/build/dist/js/webapp/app.js` printed `0` every time.
  `reviewer` independently re-ran this same check and reported `0` too. The shipped web build still
  contains none of it, same proof 11h used.
- Mutation-checked `reviewer`'s finding: reverted `rankOf`'s `try/catch` back to the throwing form,
  re-ran `./gradlew :game:test -Ptests --tests "*TestScenariosTest*"`, watched
  `anOversizedRecencyNumberSortsAsUnnumberedRatherThanThrowing` fail with the exact
  `NumberFormatException` `reviewer` described, then restored the fix and confirmed green again.
- `./gradlew :desktop:run -Ptests` — launched, reached a running LWJGL3 window titled
  `little-spaceship`, no exception in the log (only the usual LWJGL/JDK native-access warnings seen
  on every desktop run in this environment). Killed once confirmed running, per "running the game is
  not playing it" — never navigated the menu, never opened a scenario.
- A real `discover()` call against the renamed `assets/data/` — the throwaway-classpath technique,
  no game launch — printed the fourteen-line table above, confirming the descending-rank/unnumbered
  fallback order and every label against the actual shipped content, not only synthetic fixtures.
- The discovered order and every label: read from the code and asserted by `TestScenariosTest`, not
  observed on screen, per this task's own instruction.

## Acceptance criteria

- [x] Adding a scenario file under `assets/data/` and nothing else puts it in the TESTS menu —
  `discover` reads the directory itself; no code names any scenario by id anymore.
- [x] The stack order #291 decided survives literally, per the project owner's ruling: last-created
  first, via the `test-NNN-<name>.json` convention and a descending sort on `NNN`, argued above and
  asserted by tests with adversarial input order.
- [x] The order is read from the code / asserted by a test, not observed on screen.
- [x] The `-Ptests` build still compiles; the shipped build still contains none of it — proven by
  the real TeaVM compile and a grep of the emitted `app.js`, as above.

## Open items this leaves behind

- Discovery depends on `FileHandle#list()`, which is read-confirmed unreliable on the web target's
  `FileType.Internal` storage. Not a problem today because `-Ptests` is desktop-only in practice, but
  it would need to move to a build-time generated source before this flavour could ever target
  `:web`.
- The auto-derived labels for three renamed scenarios (`test-090-slide-descend`,
  `test-080-dive-retreat`, `test-060-sweep-width`) are longer than the hand-picked ones they replace.
  Not fixed here: shortening them would mean either renaming the files further (this task's rename is
  already a stated, narrow exception to `assets/data/` being `level-designer`'s, and stretching it
  further to also shorten names was not part of what was asked) or reintroducing a hand-maintained
  short name (exactly what discovery removes). Left for the project owner to judge on screen.
- The four unrenamed scenarios (`test-boss`, `test-wave-04`, `test-wave-09`, `test-wave-12`) have no
  recency signal and always sort after every numbered one. If a future phase wants them interleaved
  by actual recency, they would need the same `test-NNN-<name>.json` rename this task gave the other
  ten — a `level-designer` change, not this task's to make unasked.
