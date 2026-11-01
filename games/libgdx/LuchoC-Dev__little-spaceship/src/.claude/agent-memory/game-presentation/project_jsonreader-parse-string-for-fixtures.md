---
name: jsonreader-parse-string-for-fixtures
description: JsonReader.parse(String) exists and is the right tool for a fixture-based content-parsing test — no FileHandle or temp file needed
metadata:
  type: project
---

`com.badlogic.gdx.utils.JsonReader` overloads `parse` for `String`, `Reader`, `InputStream`,
`FileHandle` and `char[]` — confirmed by decompiling `gdx-1.14.2.jar`'s `JsonReader.class` with
`javap` (no source jar was on hand, only the compiled one, so `javap -p` on the extracted `.class`
was the fastest way to get a real signature instead of guessing from memory).

So a unit test for any `Json*Values.from(JsonValue root)` factory (see
`JsonBalanceValues`/`JsonContentSource` in `game/adapter/content/`) can build its fixture as a Java
text block (`"""..."""`) and call `new JsonReader().parse(FIXTURE)` directly — no temp file, no
`FileHandle`, no classpath resource. This is the missing piece that made issue #261's test possible:
the project's own convention (`JsonReader`/`JsonValue`, never the reflection-based `Json` class,
per `CLAUDE.md`'s web pitfalls) applies exactly the same way to a test as to production code.

**Why this matters beyond one test.** Before #261, no test class existed for `JsonBalanceValues`, and
none exists yet for `JsonContentSource` either — every field either class reads from JSON has, so
far, only ever been read by production code. Any future task closing that gap should reach for this
same technique first, rather than assuming a fixture needs an on-disk file under `assets/data/`.

**Mutation-testing habit reused a third time.** The project already treats "prove the test can fail"
as a named requirement (see `docs/plan/11i-path-vocabulary`, issue #261's own text, and this
project's decided standard cited in `reviewer`'s finding on PR #262). Concretely: comment out /
revert the wiring line, run the single test with
`./gradlew :<module>:test --tests "*ClassName*" --console=plain`, confirm red, then restore and
confirm green. Cheap (a few seconds per run under Gradle's up-to-date checking) and it is the only
thing that actually distinguishes "this test checks something" from "this test always passes".
