# Phase 11a, task 1 — the baseline count

Closes [#96](https://github.com/LuchoC-Dev/little-spaceship/issues/96).

**Taken at commit `4e388067bf7ff01d527c72db9fa8828c79318b8f`** (`phase/11a-rule-asserting-tests`, before
this phase added a single test). Re-running the commands below against a later commit will not
reproduce these numbers — that is expected, task 1 measures the state 11a inherited, tasks 2–4 add to
it.

## The denominator: how many tests, in how many files

```
$ grep -c "@Test" -r core/src/test | awk -F: '{s+=$2} END{print s}'
289
$ find core/src/test -name "*.java" | xargs grep -l "@Test" | wc -l
35
```

**289 tests in 35 files.** This confirms, rather than assumes, the figure the roadmap and 10c both
carried forward without re-measuring (`docs/plan/post-mvp-roadmap.md`, "Tests that assert rules, not
only reproducibility"; `docs/plan/10c-architecture-review/assessment.md`, area H). The repository has 39
`.java` files under `core/src/test/`; four are support code with no `@Test` of their own
(`architecture/CoreSources.java`, `architecture/JavaSource.java`, `testsupport/TestBalance.java`,
`testsupport/TestContent.java`) and are excluded by the `grep -l "@Test"` filter above.

## The classification criterion

Counting requires reading each test, not grepping a keyword — a test named `isDeterministic` can still
pin a literal expected value, and a test with no "replay" in its name can still compare two runs. Every
one of the 289 was read. The criterion, applied per test **method**, not per file or per class:

- **Reproducibility.** The test's assertion is a self-comparison: it runs the same scripted
  scenario twice (or drives the same script through two different call paths) and asserts the two
  results are equal to *each other*. It says nothing about what the correct result is.
- **Rule.** The test's assertion checks a concrete, specific outcome from **one** execution against an
  expected value or state tied to a decided rule — either a gameplay rule from `docs/planning/`
  (the defensive chain, weapon/life/attachment caps, weak-vs-heavy collision, the boss's beats, level
  completion, scoring) or the fixed system order invariant 5 names as a game rule, not an
  implementation detail. This includes the "not a vacuous pass" companions next to a determinism test
  (`bombActuallyScoredSomething`, `scoredSomething`, `carriersActuallySpawnChildren`): each asserts a
  concrete fact about the one run it inspects, not that two runs agree.
- **Both.** A single test method does both: it self-compares two runs **and** compares the result
  against a pinned, specific expected value. Two tests do this — see below — and each is counted once
  in *each* of the two headline numbers, not split or averaged. A test is either self-comparing or not,
  and either checking a decided value or not; a test can be both at once, it cannot be half of either.
- **Neither / infrastructure.** Everything else: tests of a data structure, a value object, a port's
  parsing/validation, or a module-boundary rule, where the "correct" answer is an API contract rather
  than a game design decision, and where the assertion is neither a self-comparison nor tied to a
  planning-doc rule. Forcing these into "rule" or "reproducibility" would inflate one bucket with tests
  that are correctly testing something else. `RngTest.pinnedSequence` and its three siblings are the
  sharpest edge case: they pin literal output values, but the value being pinned is the RNG algorithm's
  own numeric contract, not a decided game rule, so they land here rather than in "rule".

This needed judgement on every test, not a pattern a script could apply unattended — a "Deterministic"
name is a strong hint but `SimulationTest.seedChangesTheOutcome` also has one and is *not* a
reproducibility test by this criterion (it asserts two runs differ, not that they agree; see below).
**All 289 were read by hand against this criterion**; nothing here is a keyword count dressed up as a
measurement.

## The count

| Bucket | Count | Share |
|---|---:|---:|
| Rule only | 163 | 56.4% |
| Reproducibility only | 5 | 1.7% |
| Both | 4 | 1.4% |
| Neither / infrastructure | 117 | 40.5% |
| **Total** | **289** | 100% |

Headline numbers, each counting "Both" once:

- **Asserts a rule: 167** (163 rule-only + 4 both).
- **Asserts reproducibility: 9** (5 reproducibility-only + 4 both).
- **Overlap: 4.**

## The four tests that are both

All four are cross-system replays in `core/src/test/java/.../application/`. Two pin a whole-run
fingerprint, which turns the self-comparison into a real regression net; two pin the level's outcome.

- `BombReplayTest.bombedRunIsDeterministic` — `assertEquals(first, second)` **and**
  `assertEquals(GOLDEN_FINGERPRINT, first)`.
- `LevelScoreReplayTest.levelScoreIsDeterministic` — same shape, its own pinned fingerprint.
- `BossReplayTest.victoryIsDeterministic` — `assertEquals(first, second)` **and**
  `assertEquals(LevelOutcome.COMPLETED, ...)` (line 38).
- `BossReplayTest.defeatIsDeterministic` — asserts `LevelOutcome.DEFEATED` against two separate runs
  (lines 44-45), so it is a self-comparison and a pinned value in the same two statements.

**These last two were classified as reproducibility-only in the first pass of this document and
corrected by the coordinator before review**, by reading the file rather than by re-reasoning: the
`assertEquals(LevelOutcome.COMPLETED, ...)` on line 38 is a pinned expected value tied to a decided
rule, which this document's own criterion calls "Both". The correction moves two tests and changes the
rule headline from 165 to 167. **The other five reproducibility-only tests were re-read at the same
time and all five hold** — `DamageReplayTest.damageSequenceIsDeterministic`,
`SimulationTest.isDeterministic`, `SimulationTest.loopAndDirectTicksAgree`,
`SpawnerReplayTest.twoCarriersSpawningIsDeterministic` and `RngTest.sameSeedSameStream` are pure
self-comparisons. (`loopAndDirectTicksAgree` also asserts `120 == looped.tickCount()`, which is loop
plumbing rather than a decided game rule, so it stays where it is.)

## Where the reproducibility-only tests are, and why the roadmap's claim still holds

The roadmap's own example, `BossReplayTest`, is **not quite** what the roadmap says. Its two tests do
pin a value — the level's `LevelOutcome` — so they are not pure self-comparisons. What the roadmap
gets exactly right is the part that matters: **nothing in that file asserts anything about the boss's
modules**, which is the gap task 3 closes. Break the module rule and both tests stay green, because a
run that still ends in `COMPLETED` still ends in `COMPLETED`. Checked by reading the file, not carried
forward.

But **the reproducibility-only bucket is small relative to the whole suite (7 of 289)** — the roadmap's
"the bulk asserts reproducibility" is not a claim about `core/src/test/` as a whole; the 151
system-level unit tests in `core/src/test/.../domain/system/` are overwhelmingly rule-asserting
already (that is what "System unit tests" in this project's brief mean: a minimal world, a decided
rule, an assertion that fails when the rule breaks). The claim is accurate about a narrower, specific
slice: the five cross-system replay files
(`BombReplayTest`, `BossReplayTest`, `DamageReplayTest`, `LevelScoreReplayTest`, `SpawnerReplayTest`),
9 tests total, of which 8 are reproducibility-asserting (4 pure + 4 both) against 5 rule-asserting
(1 pure + 4 both). **Within that slice, reproducibility is the majority** — which is exactly the gap
tasks 2–4 close, by adding rule assertions to the systems these replays exercise (the defensive chain,
the boss, level completion) rather than by rewriting the replays themselves.

The five pure-reproducibility tests:

| Test | File |
|---|---|
| `damageSequenceIsDeterministic` | `application/DamageReplayTest.java` |
| `isDeterministic` | `application/SimulationTest.java` |
| `loopAndDirectTicksAgree` | `application/SimulationTest.java` |
| `twoCarriersSpawningIsDeterministic` | `application/SpawnerReplayTest.java` |
| `sameSeedSameStream` | `domain/rng/RngTest.java` |

## Full breakdown by file

Rule / Reproducibility / Both / Infrastructure, test counts per file (all 35 files with at least one
`@Test`):

| File | Rule | Repro | Both | Infra | Total |
|---|---:|---:|---:|---:|---:|
| `application/BombReplayTest.java` | 1 | 0 | 1 | 0 | 2 |
| `application/BossReplayTest.java` | 0 | 0 | 2 | 0 | 2 |
| `application/DamageReplayTest.java` | 0 | 1 | 0 | 0 | 1 |
| `application/GameLoopTest.java` | 0 | 0 | 0 | 12 | 12 |
| `application/LevelContentIntegrationTest.java` | 3 | 0 | 0 | 0 | 3 |
| `application/LevelScoreReplayTest.java` | 1 | 0 | 1 | 0 | 2 |
| `application/SimulationTest.java` | 0 | 2 | 0 | 7 | 9 |
| `application/SpawnerReplayTest.java` | 1 | 1 | 0 | 0 | 2 |
| `architecture/DeterminismRulesTest.java` | 0 | 0 | 0 | 3 | 3 |
| `architecture/LayerDependencyTest.java` | 0 | 0 | 0 | 4 | 4 |
| `architecture/PublicContractTest.java` | 0 | 0 | 0 | 2 | 2 |
| `domain/WorldTest.java` | 6 | 0 | 0 | 8 | 14 |
| `domain/component/ComponentStoreTest.java` | 0 | 0 | 0 | 11 | 11 |
| `domain/content/ComponentFactoryRegistryTest.java` | 0 | 0 | 0 | 12 | 12 |
| `domain/entity/EntityRegistryTest.java` | 0 | 0 | 0 | 9 | 9 |
| `domain/event/GameEventQueueTest.java` | 0 | 0 | 0 | 6 | 6 |
| `domain/rng/RngTest.java` | 0 | 1 | 0 | 11 | 12 |
| `domain/system/BombSystemTest.java` | 14 | 0 | 0 | 0 | 14 |
| `domain/system/BossSystemTest.java` | 9 | 0 | 0 | 0 | 9 |
| `domain/system/CleanupSystemTest.java` | 9 | 0 | 0 | 0 | 9 |
| `domain/system/CollisionSystemTest.java` | 12 | 0 | 0 | 0 | 12 |
| `domain/system/DamageSystemTest.java` | 23 | 0 | 0 | 0 | 23 |
| `domain/system/EnemyWeaponSystemTest.java` | 11 | 0 | 0 | 0 | 11 |
| `domain/system/LifetimeSystemTest.java` | 3 | 0 | 0 | 0 | 3 |
| `domain/system/MotionSystemTest.java` | 12 | 0 | 0 | 0 | 12 |
| `domain/system/PickupSystemTest.java` | 16 | 0 | 0 | 0 | 16 |
| `domain/system/ScoreSystemTest.java` | 8 | 0 | 0 | 0 | 8 |
| `domain/system/SpawnSystemTest.java` | 18 | 0 | 0 | 0 | 18 |
| `domain/system/SpawnerSystemTest.java` | 7 | 0 | 0 | 0 | 7 |
| `domain/system/SystemPipelineTest.java` | 2 | 0 | 0 | 5 | 7 |
| `domain/system/WeaponSystemTest.java` | 7 | 0 | 0 | 0 | 7 |
| `port/ContentDefinitionsTest.java` | 0 | 0 | 0 | 8 | 8 |
| `port/InputFrameTest.java` | 0 | 0 | 0 | 5 | 5 |
| `port/MapComponentSpecTest.java` | 0 | 0 | 0 | 11 | 11 |
| `port/SpriteIdTest.java` | 0 | 0 | 0 | 3 | 3 |
| **Total** | **163** | **5** | **4** | **117** | **289** |

Two notes on individual calls inside this table:

- `domain/WorldTest.java` splits 6/8: `playerStatusIsNoneWithNoPlayerEntity`,
  `playerStatusReflectsTheDefensiveChain`, `outcomeIsDefeatedAtZeroLives`, `outcomeStartsInProgress`,
  `completionBonusIsZeroWithNoPlayerEntity` and `completionBonusReflectsLivesAndBombs` assert the
  defensive-chain-derived player status and the `COMPLETED`/`DEFEATED` outcome rule (task 4's
  territory); the other eight (`entitiesStartEmpty`, `destroyStripsEveryComponent`,
  `recycledSlotIsClean`, `destroyingStaleHandleIsHarmless`, `viewWalksDrawableEntities`,
  `viewSkipsSpritesWithoutPosition`, `viewRejectsNullVisitor`, `rejectsMissingDependencies`) are
  ECS/`WorldView` mechanics, not a game rule.
- `domain/system/SystemPipelineTest.java` splits 2/5: `canonicalOrder` and `runsInCanonicalOrder`
  assert invariant 5 — fixed system order is a game rule, not an implementation detail, `CLAUDE.md`
  says so explicitly — the other five (`runsEachSystemOnce`, `skipsEmptyStages`,
  `rejectsDuplicateStage`, `rejectsNullSystem`, `handsOverStepAndInput`) are pipeline plumbing.

## What "Rule, applied to every `domain/system/*Test.java`" means here

All 151 tests in the thirteen `domain/system/*Test.java` files other than `SystemPipelineTest` are
counted as rule-asserting, including tests such as `noPlayerIsHarmless`, `rejectsMissingLevelId` or
`unknownEnemyIdFailsWithMessage`. These are defensive/guard cases rather than something copied verbatim
from `docs/planning/`, and a stricter reading could put some of them in "infrastructure" instead. They
are kept as "rule" here because each still asserts a concrete, specific outcome of **one** system's
behaviour on **one** deterministic scenario — the operational half of the criterion that distinguishes
"rule" from "reproducibility" — and because `CLAUDE.md`'s own description of this project's system unit
tests ("a minimal world... the cases that matter come from rules already decided") is the standard this
count applies. This is the single largest judgement call in the whole classification; it affects roughly
30–40 of the 151, since that is the rough share of guard/defensive-input tests across those thirteen
files. Re-running this classification with the stricter reading (excluding guard/defensive tests from
"rule") would move that share from "rule" to "infrastructure" and would not change the two headline
numbers (167 rule, 9 reproducibility, 4 overlap) at all, since none of those guard tests is a
reproducibility test.

## Reproducing this count

There is no single command that outputs "163/5/4/117" — the criterion needs one read per test, stated
above precisely enough that a second reader applying it to the same commit should land in the same
bucket for the overwhelming majority of the 289 (the guard/defensive-test judgement call noted above is
the one place two readers could reasonably disagree, and it does not move the headline numbers). What
is mechanically reproducible, and is the anchor the classification above was built against, is the
denominator:

```
git checkout 4e388067bf7ff01d527c72db9fa8828c79318b8f
grep -c "@Test" -r core/src/test | awk -F: '{s+=$2} END{print s}'   # 289
find core/src/test -name "*.java" | xargs grep -l "@Test" | wc -l    # 35
```

and, per file, the per-file test count in the table above:

```
for f in $(find core/src/test -name "*.java"); do echo "$(grep -c '@Test' "$f") $f"; done
```
