# 301 — the five new trajectory scenarios listed in the TESTS menu

**Branch:** `feat/tests-menu-11j-scenarios`. **Closes:** [#301](https://github.com/LuchoC-Dev/little-spaceship/issues/301). **Written by the coordinator**, because the list lives in `game/` and the content task that produced the scenarios could not reach it.

## What shipped

Five entries added to `TestScenarios.ALL` in
`game/src/tests/java/dev/luchoc/littlespaceship/game/screen/TestScenarios.java`, as one batch at the
front — the list is a stack, newest batch first, per #291, and a batch keeps its internal order
below the newest rather than each entry moving on its own. Nine entries became fourteen.

| id | label | authoring form |
|---|---|---|
| `test-cross` | `LINE: CROSS` | `constant` |
| `test-slide-descend` | `PATH: SLIDE` | relative `"segments"` |
| `test-dive-retreat` | `PATH: RETREAT` | relative `"segments"` |
| `test-hold-line` | `ABS: HOLD LINE` | absolute `"waypoints"` |
| `test-sweep-width` | `ABS: SWEEP` | absolute `"waypoints"` |

## The labels are not the ones `level-designer` proposed

It proposed `PATH:` on all five. Changed, and the class javadoc now carries the rule: **the prefix
names the authoring form the scenario exercises** — `LINE:` for a `constant`, `PATH:` for relative
segments, `ABS:` for absolute waypoints.

Two reasons, both about the one place the project owner reads while choosing what to open.
`test-cross` is a `constant`, deliberately, under the plan's own rule that a path which could be a
`constant` should be one — `PATH: CROSS` would have said what it is not. And the two absolute
entries are what this entire phase exists to build; under a shared `PATH:` prefix they were
indistinguishable from the relative ones.

Every label is at or under the width of `PATH: OSCILLATE`, the longest already in the list.

## Verified

- `./gradlew :game:compileJava -Ptests` — exit 0. `TestScenarios` is compiled **only** under that
  flavour (`game/build.gradle.kts`, the `testsFlavour` source-set switch), so the ordinary build
  never sees this file at all.
- Every id in `ALL` has its content file: a shell loop over the fourteen `new Scenario("…"` ids
  checking `assets/data/<id>.json` printed `ok` for all fourteen, none missing.
- `./gradlew build` — green, via `tools/pre-pr-check`, whose whole output is in the pull request.
- **Not checked: that the menu renders the fourteen entries correctly, or that any scenario opens.**
  Fourteen entries do not fit on screen and reaching the new ones means scrolling the menu, which is
  exactly what `how-to-run-a-phase.md`'s "And the half that is the coordinator's" forbids being
  asked of an agent — a rule this phase wrote after breaking it twice. **It is the project owner's
  to look at**, and it is the last acceptance criterion of the phase.

## The thing this issue is evidence for

**No test can cover this list today**, and that is not laziness. `TestScenarios` exists only in the
`-Ptests` source set, which `game`'s test source set is not compiled against, so asserting "every
id in `ALL` has a file" would need a flavour-aware test source set that does not exist. The check
above was run as a shell loop instead, by hand, once.

That is the third distinct cost of hardcoding this list, after the three round trips 11i measured
and the round trip this issue itself is. **Whether the list should be discovered from
`assets/data/test-*.json` is still open** — recorded again, with the number now larger.
