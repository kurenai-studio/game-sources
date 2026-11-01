---
name: game-module-test-harness
description: JDK dynamic proxies for Gdx.input/Gdx.graphics let `game` be tested with no LWJGL; how to check an interface is proxy-safe before assuming it.
metadata:
  type: project
---

`game`'s test source set (`game/src/test/java`) did not exist before phase 11g task 2 (issue #19,
the unblocked half of D5 in [[project_rule-vs-reproducibility-classification]]'s phase). Root
`build.gradle.kts` already applies `testImplementation junit-jupiter` to every subproject, so
adding `game/src/test/java/...Test.java` was enough — no build file edit needed for JUnit itself.

**`Gdx.input`/`Gdx.graphics` are plain public static fields typed as interfaces** (`com.badlogic.gdx.Input`,
`com.badlogic.gdx.Graphics` — confirmed with `javap -classpath gdx-<version>.jar com.badlogic.gdx.Input`,
prints `public interface`). A `java.lang.reflect.Proxy` backed by a hand-written `InvocationHandler`
stands in for either with zero new dependencies and no LWJGL on the test classpath — the proxy only
needs to answer the specific method names the production code under test actually calls; every other
method on the interface can fall through to a default-by-return-type branch (`false`/`0`/`null`) and
never gets hit. Assign the proxy directly to the static field before the call, and null it in
`@AfterEach` — these are JVM-wide statics, not instance state, and leaking one into another test
class in the same JVM run is a real risk since JUnit doesn't isolate static state between test
classes.

**Before reusing this pattern for a different libGDX interface** (`Audio`, `Files`, `Batch`, …):
run `javap` on it first. `Input`/`Graphics` happened to be safe because every method the code under
test calls is a getter/predicate with an obvious return-type default for the ones you don't
implement. An interface with a method whose *un*-implemented default breaks the code under test
(e.g. a null a caller immediately dereferences) needs that method explicitly handled, not skipped.

**`com.badlogic.gdx.utils.viewport.Viewport` has no abstract methods** (`javap` confirms) despite
being declared `abstract class` — `new Viewport() {}` compiles and works standalone; you only need
`setWorldWidth`/`setWorldHeight`, no camera, no `GL20`, no display.

See [[project_rng-parity-task-wiring]] for the sibling case of keeping a libGDX/TeaVM-touching
module's tests out of the main suite when that's the right call instead — here it was not: `game`'s
tests run under plain `./gradlew build` like `core`'s, no separate task needed.
