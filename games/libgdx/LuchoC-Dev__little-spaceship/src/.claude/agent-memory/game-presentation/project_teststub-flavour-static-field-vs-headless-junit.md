---
name: teststub-flavour-static-field-vs-headless-junit
description: why TestScenarios.ALL had to become a method, and how a second -Ptests-only source directory lets a test compile against a class that does not exist outside that flavour
metadata:
  type: project
---

Issue #311 (11k task 3): `TestScenarios`'s hardcoded `List.of(...)` became a discovery call,
`FileHandle#list(".json")` on `Gdx.files.internal("data")`, sorted alphabetically by level id
(mtime is unusable for "newest" — it resets to checkout time on a fresh clone, so it is exactly the
kind of filesystem-dependent non-determinism invariant 2 rules out for the simulation, and the same
reasoning applies here). See [[trajectory-mirroring-and-core-exceptions-without-ids]] for the
`mirrorOf`/`speedOf`-following pattern this class's label derivation copies from
`JsonContentSource#resolveDerived`, read-only, against raw `JsonValue` rather than resolved
`TrajectoryDefinition` objects — resolved `PathTrajectoryDefinition` cannot tell a `segments`-authored
path from a `waypoints`-authored one apart, since both compile down to the same `PathSegment` list by
design (11j), so the `PATH:`/`ABS:` label distinction needs the raw JSON specifically.

**A static field's initializer runs at class load, not at first genuine use of that field.**
Turning `TestScenarios.ALL` into `static final List<Scenario> ALL = discover(Gdx.files.internal(...))`
broke every test in a new `TestScenariosTest`, even ones that only ever call the package-private
`discover(FileHandle)` method directly and never touch `ALL` — referencing *any* member of a class
loads it, which runs every static initializer in source order, and `Gdx.files` does not exist in a
headless JUnit process (no `Gdx.app` bootstrapped, see
[[headless-libgdx-verification]]). Fixed by making it a method, `all()`, called only from
`TestMenuScreen`; discovery itself stays a separate, directly-testable static method that never
touches `Gdx` except through the `FileHandle` a caller (real code or a test) already supplies.

**Extended the `-Ptests` flavour to the `test` sourceSet, not just `main`.** `TestScenariosTest`
references `TestScenarios`, a class that plain `./gradlew :game:test` never compiles (see
[[gradle-source-set-flavour-for-code-absence]] for why `main` is split this way already). Added a
second conditional `sourceSets { test { if (testsFlavour) java.srcDir("src/testsTest/java") } }` in
`game/build.gradle.kts`, mirroring the existing `main` toggle — an unconditional `src/test/java` file
referencing `TestScenarios` would have broken `./gradlew :game:test` for everyone not passing
`-Ptests`. Verified by `./gradlew :game:clean :game:test` (no property): builds green, and
`find game/build/classes -iname "*TestScenarios*"` prints nothing — the ordinary test run neither
compiles nor runs `TestScenariosTest`.

**`FileHandle#list()` on the web target: read the actual backend jar rather than trust the existing
"has no answer" comment blindly, then still sided with it.** Extracted
`backend-web-1.6.1-sources.jar` (`com.github.xpenatan.gdx-teavm:backend-web:1.6.1`, in the Gradle
module cache) and read `WebFiles`/`MemoryFileStorage`/`InternalStorage`: `FileType.Internal` is
backed by an `OrderedMap` that only `writeInternal` (the `FileType.Local`/browser-storage write path)
is ever seen populating — nothing in that jar populates it for a preloaded internal asset, so
`list()` on the web target most likely returns nothing there. This is one concrete piece of evidence
behind `JsonContentSource`'s existing javadoc claim (see [[filehandle-list-avoided-for-teavm]]); it
does not fully prove the negative (some other class in the dependency graph could populate it and
wasn't found), but it is enough to make the same call that class already made. Accepted the risk
here rather than avoiding `list()` altogether because this code is `-Ptests`-only, has never shipped
combined with `:web`, and the task's own acceptance criterion was "the `-Ptests` build compiles," not
"runs correctly under TeaVM."

**Alphabetical-by-id was the wrong ordering call, and the project owner corrected it after review**
(still #311, same PR). The reasoning that no recency signal survives a filesystem listing was correct
and stood; the conclusion drawn from it — that #291's "newest first" stack had to be dropped — was
not the owner's to make and was wrong. The actual fix: the recency signal moves into the file name
itself, `test-NNN-<name>.json`, and discovery reads the number back out with a regex and sorts
descending. A level id with no number sorts after every numbered one, alphabetically among its own
kind — a policy that turned out to have a real, non-synthetic test case already on disk: the four
scenario files phase 11h authored (`test-boss`, `test-wave-04/09/12`) before this convention existed.
**Lesson for next time:** when a task explicitly hands ordering to "no signal survives, sort
alphabetically," treat that as the *safe* answer to fall back to, not the first thing to ship, if the
task also references a specific numbered decision (#291) by name — the decision that named it is the
one to satisfy, not reason past. Worth pausing to ask, rather than answering the letter of "make it
deterministic" while missing the actual constraint the issue number was pointing at.

**A regex capture group feeding straight into `Integer.valueOf` is an unbounded-input bug, and
`reviewer` (not this agent) found it.** `rankOf`'s pattern, `^test-(\d+)-(.+)$`, bounds the digit
*shape* but not the digit *count* — `\d+` matches any length, so a level id with an absurdly long
number matches the pattern and then overflows `int`, throwing `NumberFormatException` out of a
comparator `List.sort` drives, with no guard anywhere between it and the screen constructor that
calls `discover()`. The general shape to watch for: any regex-then-`Integer.valueOf`/`parseInt` on
data that ultimately comes from a file name or user-authored content needs its own `try/catch`
independent of whatever `try/catch` sits around the method that calls it — `labelFor`'s existing
lenience did not automatically cover `rankOf`, because they are separate call paths from `discover`,
not nested. Mutation-checking this one was cheap and exact: revert the `try/catch` to nothing,
re-run the one new test, watch the precise exception `reviewer` described, restore it.
