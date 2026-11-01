# 269 — The path loader tests fail once `pickupFallSpeed` is mandatory

**Done by the coordinator**, on `fix/path-loader-test-fixture`. A defect found while the phase runs, on the integrated phase branch, and invisible from either branch that caused it.

## What was wrong

All eleven tests of `JsonContentSourcePathTrajectoryTest` failed on `phase/11i-path-vocabulary` once PRs #267 and #268 were both merged. **Both branches were green alone**, and `reviewer` accepted each after running `./gradlew build` on it.

#264's tests build a whole minimal content directory in a temp dir — including their own `balance.json` — and load it through the real `JsonContentSource` constructor. That is the right way to test a loader, and it is what makes them worth having.

#261 then made `JsonBalanceValues.from` call `root.getFloat("pickupFallSpeed")`, and `JsonValue.getFloat(String)` throws when the key is absent. **The fixture became malformed content the moment the key became mandatory.**

## Why this is the guarantee working

Malformed content dies at startup with the file named. That is the property `JsonContentSource` exists to preserve and `CLAUDE.md` records — a typo is a startup failure, not a mystery at second 90. The fixture was content, and it was incomplete.

**Nothing in the loader or in the wiring was wrong.** Two parallel branches in the same module could not see each other, and neither the authors nor either `reviewer` pass could have caught it: each ran a green build on a tree where the other change did not exist.

## The fix

One line: `"pickupFallSpeed": 20.0` in `writeFixedFixtures`.

## Verified

- `./gradlew :game:test` — green.
- **The tests can still fail.** Removed the horizontal negation from `mirror`'s `PathSegment` loop — `-segment.vx()` to `segment.vx()` — and the suite went red; restored it and it went green, with a clean tree. Separately, replacing `root.getFloat("pickupFallSpeed")` with a literal turned `JsonBalanceValuesTest` red, so #261's own mutation check still holds on the integrated tree.

## What is worth recording rather than only fixing

**Every fixture that hand-writes a `balance.json` is now coupled to `JsonBalanceValues`'s exact field list**, and there is more than one. Whether that coupling should exist — a shared fixture, or a builder — is a real question and it is **not** this issue's. It is the second thing this phase has found about that class: #261 established that none of its other twenty fields is asserted against a parsed fixture at all.

**And it is an argument for integrating early.** This phase merged four branches before this one and each was green in isolation. The only instrument that found it was building the tree that actually ships.
