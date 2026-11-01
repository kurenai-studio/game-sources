# 261 — wire pickupFallSpeed into JsonBalanceValues

Closes #261. Branch `fix/pickup-fall-speed-from-json` against `phase/11i-path-vocabulary`.

## What was wrong

`assets/data/balance.json` already carried `"pickupFallSpeed": 20.0` (from #260 / PR #262), and
`BalanceValues.pickupFallSpeed()` already existed as a `default` method returning `20f`. But
`JsonBalanceValues` — `game`'s sole other implementer, built from the parsed file — had no
`pickupFallSpeed` component and never called `root.getFloat("pickupFallSpeed")`. The parser does
not reject unknown keys, so the JSON value was silently inert: editing it in `balance.json` changed
nothing, because the running game always used the interface's hardcoded `20f`.

## What changed

- `game/src/main/java/.../adapter/content/JsonBalanceValues.java` — added a 21st record component,
  `pickupFallSpeed`, documented in the class javadoc; `from(JsonValue root)` now reads it with
  `root.getFloat("pickupFallSpeed")`, the same required-key style every other field already uses (no
  default, throws if missing — consistent with the class's own stated policy that a missing balance
  number should fail loudly at load, not fall back to a guess).
- `game/src/test/java/.../adapter/input/InputAdapterTest.java` — its hand-built `JsonBalanceValues`
  fixture gained one more constructor argument (`20f`) to match the new arity. No behavioural change
  to that test.
- **New**: `game/src/test/java/.../adapter/content/JsonBalanceValuesTest.java` — the first test class
  for `JsonBalanceValues`. It parses a small JSON fixture string (via `new JsonReader().parse(String)`,
  not a file — no need for one) with every key `from()` reads, sets `pickupFallSpeed` to `33.0` in
  the fixture, and asserts `JsonBalanceValues.from(root).pickupFallSpeed()` returns exactly `33.0f`.

## Why `33.0`, and how the test was proven to be able to fail

`reviewer`'s finding on PR #262 was that no test in this codebase distinguished "value came from the
interface's `default`" from "value came from parsed JSON" — every assertion read a `BalanceValues`
accessor without ever calling `JsonBalanceValues.from(fixture)`. `33.0` was chosen specifically
because it cannot pass against `BalanceValues.pickupFallSpeed()`'s own default of `20f`: if the
`root.getFloat("pickupFallSpeed")` read were removed and the constructor call fell back to a literal
`20f` instead, the assertion `assertEquals(33.0f, balance.pickupFallSpeed())` would fail.

**Verified by mutation, not by inspection.** Temporarily replaced
`root.getFloat("pickupFallSpeed")` with a literal `20f` in `JsonBalanceValues.from`, then ran:

```
$ ./gradlew :game:test --tests "*JsonBalanceValuesTest*" --console=plain
...
JsonBalanceValuesTest > pickupFallSpeed comes from the parsed file, not BalanceValues's default FAILED
    org.opentest4j.AssertionFailedError at JsonBalanceValuesTest.java:68
1 test completed, 1 failed
BUILD FAILED
```

Then reverted the mutation (restored `root.getFloat("pickupFallSpeed")`) and re-ran the same command:

```
$ ./gradlew :game:test --tests "*JsonBalanceValuesTest*" --console=plain
...
BUILD SUCCESSFUL in 3s
```

## What else was checked, and not expanded

The task asked to consider whether the class's other fields are covered by anything at all. Checked:
there is no `JsonContentSourceTest` and, before this change, no test class for `JsonBalanceValues`
either — so **every one of the other 20 fields is in the same position `pickupFallSpeed` was in**:
read from JSON in production code, but never exercised against a parsed fixture in a test. This
issue's own scope is `pickupFallSpeed`; adding fixture coverage for the other 20 fields (or for the
rest of `JsonContentSource`) is a bigger, separate task and was not done here — noted, not expanded.

## Commands run and their output

```
$ ./gradlew :game:test --tests "*JsonBalanceValuesTest*" --console=plain
BUILD SUCCESSFUL in 3s

$ ./gradlew build --console=plain
BUILD SUCCESSFUL in 5s
(all modules: core, rngparity, game, web, desktop — green)

$ find game/build/test-results -name "*.xml" -exec grep -oh \
    'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*" errors="[0-9]*"' {} \;
tests="1" skipped="0" failures="0" errors="0"   (JsonBalanceValuesTest)
tests="2" skipped="0" failures="0" errors="0"   (InputAdapterTest)
```

## Invariants

- No new dependency added; `JsonReader`/`JsonValue` only, per `CLAUDE.md`'s "Web target pitfalls" —
  the fixture is parsed from a Java text block via `JsonReader.parse(String)`, no `Json`
  serialisation class used.
- `game` module only touched: `JsonBalanceValues.java`, `InputAdapterTest.java` (arity fix), and the
  new `JsonBalanceValuesTest.java`. `JsonContentSource.java`, trajectories, and `core/` were not
  touched, per this task's boundary.

## Running the game

Launched once to confirm startup, per the project's rule — not played:

```
$ ./gradlew :desktop:run --console=plain
...
> Task :desktop:run
(LWJGL/JNI warnings only, no error; window process observed running, then terminated manually)
```
