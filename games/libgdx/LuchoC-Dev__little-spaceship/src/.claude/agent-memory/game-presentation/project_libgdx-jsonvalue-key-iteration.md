---
name: libgdx-jsonvalue-key-iteration
description: How to walk a com.badlogic.gdx.utils.JsonValue object's own keys to reject unrecognised ones, how to get a runnable classpath for a throwaway verification program without a test source set, and how to reach a private static parsing method via reflection to verify it without building a full ContentSource
metadata:
  type: project
---

**`JsonValue` exposes its children as public fields, not just through the `getX(name)` accessors.**
`child` (the first child, or null) and each child's own `next`/`name` let you walk an object's actual
keys without knowing them in advance — `for (JsonValue c = value.child; c != null; c = c.next)`,
checking `c.name` against an allow-list. This is what closed phase 07's "unknown key loads clean and
silently does nothing" gap in `JsonContentSource`: `getString`/`getInt`/etc. only ever check for a
key's *presence*, never flag one that exists but isn't expected.

**Outdated as of phase 11i (04/09/2026): `game` now has a real test source set.** `game/src/test/java`
exists with JUnit tests (`InputAdapterTest`, and `JsonContentSourcePathTrajectoryTest` added in phase
11i), and `testImplementation`/JUnit are wired at the root `build.gradle.kts` for every subproject —
`./gradlew :game:test` runs them directly, no throwaway classpath needed any more for anything that
fits as a normal test. The classpath trick below is still useful for a one-off script that must not
become a committed test (e.g. exercising a truly private method nobody wants a permanent test class
for), just not for the common case any more.

**Getting a real classpath to run a throwaway verification program against `game`'s compiled
classes, when `game` has no test source set configured (`build.gradle.kts` only declares
`implementation`, no `testImplementation`/JUnit):** append a temporary Gradle task to `game/build.gradle.kts`
that prints `sourceSets["main"].runtimeClasspath.files.joinToString(";") { it.absolutePath }`, run it
once, copy the printed paths, then `git checkout -- game/build.gradle.kts` to discard the temp task.
`javac -cp "<paths>" -d . Scratch.java && java -cp ".;<paths>" Scratch` from a scratch directory runs
against the real `core.jar`/`game` classes plus the real `gdx-1.14.2.jar`, no display needed — the
same "content loading needs no `Gdx.app`" fact `[[headless-libgdx-verification]]` already recorded,
just with a working classpath this time instead of guessing jar locations under `~/.gradle`.

See `[[headless-libgdx-verification]]` for the underlying fact this technique exercises, and
`[[windows-desktop-screenshot-verification]]` for the complementary real-window technique used to
confirm the tell/health bar actually render, not just that the loader parses.

**The same classpath trick reaches a `private static` parsing method directly, via reflection,
without instantiating the whole `JsonContentSource`.** Verifying phase 11c's arc-trajectory parsing
(`JsonContentSource.parseTrajectory`, issue #163) needed only a `JsonValue` entry, not a fully loaded
content source — building one needs `balance.json`, `enemies.json`, `formations.json`,
`attachments.json` and a level file, none of which the change touched. `Class.forName(...)`,
`getDeclaredMethod("parseTrajectory", JsonValue.class).setAccessible(true)`, then `invoke(null, entry)`
runs the real method against hand-built `JsonValue`s (`reader.parse("{...}")` accepts a literal string,
no file needed for a single-object case) and lets a thrown `IllegalArgumentException` surface through
`InvocationTargetException.getCause()`. Cheaper than writing a full fixture file when only one method
in one class needs exercising.
