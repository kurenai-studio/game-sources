# Phase 11a — Tests that assert rules · status

**State:** done and on `dev`. All seven tasks merged into `phase/11a-rule-asserting-tests` through
seven pull requests (#100-#103, #105-#107); `reviewer` accepted the branch; the phase merged into
`dev` in [PR #109](https://github.com/LuchoC-Dev/little-spaceship/pull/109) on 27/08/2026, with the
project owner's direct approval, who also instructed the deletion of `spikes/web-viability/` in the
same act. `dev` carries 303 tests. It has **not** reached `main`; that merge is the project owner's
alone.
**Updated:** 27/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

**Task 1 · baseline count** ([#96](https://github.com/LuchoC-Dev/little-spaceship/issues/96)) —
`test-engineer`, branch `docs/test-suite-baseline`. All 289 tests in `core/src/test/` read by hand
against a stated criterion. Headline: **167 assert a rule, 9 assert reproducibility, 4 overlap** (both
in the same test method), 117 are infrastructure/contract tests that are neither. Full method, per-file
table and the reproducible denominator command are in
[`baseline.md`](baseline.md). Taken at commit `4e388067bf7ff01d527c72db9fa8828c79318b8f`.

**The coordinator corrected two classifications before review**, by reading the file rather than by
re-reasoning: `BossReplayTest`'s two tests each pin a `LevelOutcome` as well as self-comparing, which
this document's own criterion calls "Both", so they moved out of reproducibility-only and the rule
headline went 165 → 167. The other five reproducibility-only tests were re-read at the same time and
all five hold. The per-file table was also verified mechanically against
`for f in $(find core/src/test -name "*.java"); do echo "$(grep -c '@Test' "$f") $f"; done` — all 35
rows match.

The roadmap's "the bulk asserts reproducibility" holds for the narrow slice it was actually about — the
five cross-system replay files (9 tests, 8 reproducibility-asserting) — not for `core/src/test/` as a
whole, where the 151 `domain/system/*Test.java` unit tests are already overwhelmingly rule-asserting.
`baseline.md` says so explicitly so tasks 2–4 do not read the roadmap's line as "most of the suite is
weak" when it is not.

**And the roadmap's flagship example is not quite what it says.** `BossReplayTest` was cited as
asserting nothing but determinism; it does pin the level's outcome. What the roadmap gets right is the
half that matters — nothing in that file asserts anything about the boss's modules, so breaking the
module rule leaves both tests green. Task 3 ([#98](https://github.com/LuchoC-Dev/little-spaceship/issues/98))
closes that, and should state the rule about modules rather than about the outcome, which is already
pinned.

**Task 2 · defensive chain** ([#97](https://github.com/LuchoC-Dev/little-spaceship/issues/97)) —
`test-engineer`, branch `test/defensive-chain-rules`. Every decided rule of the chain named in task 2
already had a test that fails when the rule is broken, in `DamageSystemTest` and `PickupSystemTest`
(both pre-existing, from phases 04/05, and already counted as rule-asserting in the baseline). One real
gap found and closed: `02-mvp-functional-spec.md` names losing the attachment, alongside the shield,
explicitly as a case that grants the shorter grace period — "Losing the shield or the attachment also
grants those grace frames" — but no test asserted it for the attachment path;
`shieldDamageGrantsTheShorterInvulnerability` covered the shield half only. Added
`attachmentDamageGrantsTheShorterInvulnerability`.

Rules checked against `DamageSystemTest`/`PickupSystemTest`, and where each already lives:

| Rule (quoted from planning) | Test |
|---|---|
| "invulnerability → shield → attachment → life" (03, 08) | `invulnerabilityAbsorbsTheHitEntirely`, `shieldAbsorbsBeforeAttachmentOrLife`, `attachmentAbsorbsBeforeLife` |
| "Any damage taken grants temporary invulnerability... shorter... than that of respawn" (02) | `shieldDamageGrantsTheShorterInvulnerability`, `lifeLossGrantsTheLongerInvulnerability`, and the new `attachmentDamageGrantsTheShorterInvulnerability` |
| "It absorbs the hit that destroys it, avoiding that life loss" (08) | `attachmentAbsorbsBeforeLife`, `attachmentSurvivesWhileDurabilityRemains` |
| "losing a life does not automatically remove persistent power-ups" (02, 08) | `losingALifeDoesNotClearPersistentPowerUps` |
| Life cap / weapon-upgrade cap (10) | `extraLifeRaisesLivesUpToTheCap`, `extraLifeAtMaximumGrantsPoints`, `weaponUpgradeRaisesShotLevel`, `weaponUpgradeAtMaximumGrantsPoints` (also `bombRechargeRaisesBombsUpToTheCap`/`AtMaximumGrantsPoints`, same cap-then-points shape) |
| "Picking up a power-up already at maximum... turns into points" (10) | one test per kind: `weaponUpgradeAtMaximumGrantsPoints`, `shieldAlreadyPresentGrantsPoints`, `extraLifeAtMaximumGrantsPoints`, `bombRechargeAtMaximumGrantsPoints`, `invulnerabilityAlreadyAtCapGrantsPoints`, `attachmentAlreadyEquippedGrantsPoints`, plus `maxedPickupIncreasesTheScoreOnceSwept` for the score side |
| "Weak enemies... are destroyed in that crash; tanks and heavy carriers are not" (02) | `weakEnemyDiesOnCollision`, `heavyEnemySurvivesCollision` |
| Attachment durability is data per attachment, not a constant (08) | `attachmentDurabilityComesFromDataNotAConstant` (in `PickupSystemTest`) |

**Red demonstrated for the new test.** Removed the `grantInvulnerability(...)` call from the attachment
branch of `DamageSystem.resolvePlayerHit`, ran
`./gradlew :core:test --tests "...DamageSystemTest.attachmentDamageGrantsTheShorterInvulnerability"`,
got:

```
DamageSystemTest > damage absorbed by the attachment also grants the shorter invulnerability, same as the shield FAILED
    java.lang.NullPointerException at DamageSystemTest.java:97
1 test completed, 1 failed
```

then reverted the production line. `git diff -- '*/src/main/*'` is empty on the branch that was
committed.

**One pre-existing test pins an open item; left untouched, out of scope.** `DamageSystemTest.
invulnerabilityAlsoProtectsAgainstConsequencesForTheOther` (phase 04) asserts that an invulnerable
player's crash does not destroy a weak enemy — exactly the behaviour `08-decisions-and-open-items.md`
lists as **open** ("Whether invulnerability should also suppress the consequences for the other
entity"). It predates this phase and the open-items list itself, matches the implementation, is
correctly named, and rewriting or deleting it is out of this task's scope ("rewriting tests that are
fine") and out of `test-engineer`'s boundary either way (the behaviour it pins lives in
`DamageSystem`, not the test). Naming it here so whoever settles that open item in 11e knows this test
will need to move with the decision, not be treated as a second vote for the current reading.

**Not tested, and not treated as a gap:** "the attachment disappears when taking damage and **when
losing a life**" (08, "Resolved contradictions") could read as a second, independent loss trigger
distinct from absorbing the hit. Checked against `DamageSystem.resolvePlayerHit`: the three branches
are mutually exclusive by construction (attachment absorbs before the life branch is ever reached), so
there is no code path today where a life is lost while an attachment is equipped — the "and when losing
a life" clause is satisfied structurally, not by a separate rule to assert. Worth revisiting only if a
future damage source bypasses this ordering.

**Task 3 · the boss's rules** ([#98](https://github.com/LuchoC-Dev/little-spaceship/issues/98)) —
`test-engineer`, branch `test/boss-rules`. Read against `docs/planning/08-decisions-and-open-items.md`
("Level 1 climax and length"), `docs/plan/07-boss/status.md` and `BossSystem`'s and `BossStatus`'s own
class javadoc (which restate those decisions rather than invent new ones). Two of the three
acceptance-criteria clauses already had a test that fails when the rule breaks, both in the
pre-existing `BossSystemTest` (already counted as rule-asserting in the baseline): the third — the
roadmap's own example — had none, anywhere, and is what this task closes.

| Rule (quoted from planning / the code's own javadoc) | Test |
|---|---|
| "The boss has one phase, two alternating attack patterns and a clear tell before each" (08); tell timing from `06-boss-presentation.md`, three 0.25 s beats | `BossSystemTest.tellStepsThroughThreeBeatsThenFires` — asserts the beat progression 1→2→3→fire→0 via real per-tick steps, not a hardcoded duration |
| "spread and sweep alternate every cycle, never chosen" (`BossSystem` javadoc); fan of `FAN_COUNT` rays per side | `BossSystemTest.volleyFansThreeRaysPerSideAndAlternatesPattern` — asserts two consecutive volleys are SPREAD then SWEEP, six rays each, matching the fixed ratio tables |
| "the core is the only part whose death ends the fight... whatever keel, pods or arms remain are destroyed with it" (`BossSystem` javadoc, "Defeat"); the health bar "falls both when a part is hit and, at once, when a part dies and stops contributing anything" (`BossStatus` javadoc) — **the roadmap's own example: the ship destroys a module and the world reflects it** | **Gap, closed.** New `BossReplayTest.destroyingAPodDoesNotEndTheFightAndTheWorldReflectsIt`: through the real `Simulation` pipeline (`WeaponSystem` → `CollisionSystem` → `DamageSystem` → `CleanupSystem` → `BossSystem`), the ship shoots down the boss's left pod alone and the test asserts the fight stays `IN_PROGRESS`, the boss stays `present()`, and `hp` falls by exactly the destroyed pod's health — nothing at either the unit or the replay level tested a non-core part dying alone before this |

`BossSystemTest.defeatingTheCoreWinsTheRun` (pre-existing) covers the other half of the same rule — the
core's own death does end the fight and clears the remaining parts — at the unit level;
`BossReplayTest.victoryIsDeterministic` (pre-existing, counted "Both" in the baseline) pins that the
same thing holds through the full pipeline, but for the core, not for a module dying alone, which is
exactly the gap the new test closes.

**Red demonstrated.** Changed `BossSystem.updateSpawned`'s `if (!world.isAlive(core))` to
`if (!world.isAlive(core) || !world.isAlive(podLeft))`, so a pod's death alone ends the fight exactly
like the core's. Ran
`./gradlew :core:test --tests "...BossReplayTest.destroyingAPodDoesNotEndTheFightAndTheWorldReflectsIt"`,
got:

```
BossReplayTest > destroying a pod alone leaves the fight running, and the health bar reflects the loss FAILED
    org.opentest4j.AssertionFailedError at BossReplayTest.java:75
1 test completed, 1 failed
```

(line 75 is the `LevelOutcome.IN_PROGRESS` assertion, which is exactly the rule the change broke), then
reverted the one line. `git diff -- '*/src/main/*'` is empty on the branch that was committed.

**`./gradlew build` green** after the addition; `BossReplayTest` grew from two tests to three, none of
the earlier two changed.

**Coordinator's correction, and the finding under it.** The new test's javadoc originally sourced the
module rule to `BossSystem`'s and `BossStatus`'s own javadoc — the implementation, which is what this
phase exists to stop tests from asserting. It now cites `docs/plan/07-boss/status.md`, where phase 07
actually decided it: the `DEFEATED` state is reached on the core's destruction and "whatever keel, pods
or arms remain are marked for destruction with it", a part's "own death alone ends nothing", and the
bar "shortens the instant any part is hit or dies, not only the core". The javadocs restate that
decision; they are not its source.

**The finding: the boss's structural rules are not in `docs/planning/` at all.** They are in a phase's
`status.md`. `02-mvp-functional-spec.md:184` still reads "a simple, legible boss appropriate for a
first level; patterns and aesthetics still open", which 08's "Level 1 climax and length" answered on
21/08/2026 and phase 07 then built. `08-decisions-and-open-items.md` decides the *shape* of the fight
(one phase, two alternating patterns, a clear tell) and says nothing about parts, colliders or which
death ends it. That is not wrong — 07's status is a legitimate decision record and it is precise — but
it means "the rule comes from `docs/planning/`" is not always available, and a worker asked to obey it
literally will reach for a javadoc instead. **Left as a finding, not fixed:** correcting
`02-mvp-functional-spec.md` is a planning document edit and outside this phase's scope. It belongs
with 11e, which redesigns the boss and will have to write its rules down somewhere.

**Task 4 · level completion** ([#99](https://github.com/LuchoC-Dev/little-spaceship/issues/99)) —
`test-engineer`, branch `test/level-completion-rules`. Read `World.View.outcome()`'s bossless branch
(`waveTimelineExhausted && noEnemyLeft() && alive`) and `ScoreSystem.completionBonus` against
`docs/planning/02-mvp-functional-spec.md` ("Victory on defeating the boss while keeping at least one
life, or defeat on losing all lives") and `08-decisions-and-open-items.md`, "End-of-level completion
bonus" (`lives * 1000 + bombs * 300`, resolved against a flat-bonus reading). Two of the three
conjuncts, plus the bonus rule, already had a test that fails when broken; one conjunct had none.

| Rule (quoted from planning) | Test |
|---|---|
| The run does not complete before the wave timeline is exhausted (implicit in "Victory on defeating the boss"/completing the level; `waveTimelineExhausted` conjunct) | **Gap, closed.** New `WorldTest.outcomeStaysInProgressWhileTheWaveTimelineIsNotExhausted` |
| The run does not complete while an enemy survives (`noEnemyLeft()` conjunct) | Pre-existing `SpawnSystemTest.notCompleteWhileASpawnedEnemySurvives` — already red-when-broken: after its single `SpawnEvent` fires, `waveTimelineExhausted` is already true for the rest of the test, so this test isolates `noEnemyLeft()` specifically |
| "defeat on losing all lives" (02) wins over completion when both would apply the same tick (`alive` conjunct, in substance) | **Gap, closed.** New `WorldTest.outcomeReportsDefeatOverCompletionWhenTheLastLifeIsLostTheSameTick` |
| "1000 and 300 respectively... per-unit, not flat" (08, "End-of-level completion bonus") | Pre-existing `ScoreSystemTest.completionBonusScalesByRemainingLivesAndBombs` (unit level, calls `ScoreSystem.completionBonus` directly) and `WorldTest.completionBonusReflectsLivesAndBombs` (through `WorldView.completionBonus()`, the real boundary crossing) — both already use differing lives (3) and bombs (2) counts, which is exactly what makes a flat bonus distinguishable from the per-unit one; no gap |

**The `alive` conjunct, read literally, is dead code — a finding, not a gap this task could close by
writing a test for the literal conjunct.** `outcome()` returns `DEFEATED` in an early guard
(`state != null && state.lives <= 0`) *before* the bossless branch's `if (waveTimelineExhausted &&
noEnemyLeft() && alive)` is ever reached, and `alive` is computed right after that guard as
`state == null || state.lives > 0` — so at the point the bossless `if` runs, `alive` is provably always
`true`. Demonstrated directly: removed `&& alive` from that one line (nothing else), ran
`./gradlew :core:test`, and the full suite — 291 tests at the time, none touched — stayed green:

```
BUILD SUCCESSFUL in 6s
```

then reverted. No test, existing or new, can turn red from deleting that literal conjunct, because no
reachable state has `alive == false` there. What the decided rule ("defeat on losing all lives")
actually needs, and what the new `outcomeReportsDefeatOverCompletionWhenTheLastLifeIsLostTheSameTick`
test asserts and is red-when-broken for, is the early guard itself: broke it by loosening
`state.lives <= 0` to `state.lives < 0` (so zero lives no longer trip the guard) and ran
`./gradlew :core:test --tests "*WorldTest.outcomeReportsDefeatOverCompletionWhenTheLastLifeIsLostTheSameTick*"`:

```
WorldTest > a bossless level reports defeat, not completion, when the last life is lost on the same
tick the timeline empties with no enemy left FAILED
    org.opentest4j.AssertionFailedError at WorldTest.java:259
1 test completed, 1 failed
```

then reverted. Also demonstrated the `waveTimelineExhausted` conjunct going red the same way: dropped
it from the bossless `if`, ran
`./gradlew :core:test --tests "*WorldTest.outcomeStaysInProgressWhileTheWaveTimelineIsNotExhausted*"`,
got `AssertionFailedError at WorldTest.java:245`, reverted. And the per-unit bonus: changed
`ScoreSystem.completionBonus` to a capped/flat shape (`lives > 0 ? bonus : 0`), ran both bonus tests,
got both `FAILED`, reverted. `git diff -- '*/src/main/*'` is empty on the branch that was committed.

**The bossless branch's coverage gap for 11b, precisely.** Every test above that reaches
`LevelOutcome.COMPLETED` through the bossless branch — the pre-existing
`SpawnSystemTest.completesOnceTheTimelineIsExhaustedAndNothingIsAlive` (line 340 as of this branch) and
this task's two new tests — drives `noEnemyLeft()` to true by destroying the one spawned enemy by hand
(`world.destroyEntity(enemy)`) or by never spawning one at all, never by advancing a real wave clearing
through combat, drops or the collision pipeline. 11b changes what advances the spawn cursor and what
"cleared" means; nothing in this task's diff, or in the suite before it, exercises the bossless
`COMPLETED` path through the real spawn-and-clear flow `LevelScoreReplayTest` uses for score. That is
the gap task 4's own note in `plan.md` already named, confirmed by re-reading rather than widened.

**`./gradlew build` green** after the two additions.

**Coordinator's addition to that finding, and where it went.** The boss branch's
`bossDefeated && alive` is dead for exactly the same reason and was outside the demonstration above:
the early guard settles `alive` for the whole method, not for one branch of it. So `outcome()` carries
the redundancy twice. Opened as [#104](https://github.com/LuchoC-Dev/little-spaceship/issues/104)
against `core-domain` rather than fixed here — `test-engineer` does not modify production code, and
the choice between deleting both occurrences and restructuring the method so the defeat-beats-
completion priority is expressed once is a design call in `core`. Flagged as worth settling **before
11b**, which changes what advances the spawn cursor and what "cleared" means and will be reading this
method closely.

**Task 5a · forbidden-API check strips comments and literals** ([#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) = [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3)) —
`test-engineer`, branch `test/forbidden-api-strips-comments`. `JavaSource` gained `strip(String)`:
line comments, block comments and string/char literals (escaped quotes, an escaped backslash right
before a closing quote, char literals like `'"'`) are each blanked to a single space before
`containsToken` runs, so a name spelled out in a comment or a string literal no longer counts as a
call. `DeterminismRulesTest.noForbiddenApi` now strips each file before searching it. What `strip`
explicitly does not handle: text blocks (`"""`) — none exist under `core/src/main` today (checked
with `grep -rl '"""' core/src/main --include=*.java`, no output) — documented as a live limitation
in the method's own javadoc rather than guessed at.

**The risk named in the issue — stripping too much and blinding the check — is what most of the new
tests are for**, not the easy "comments are ignored" half. `DeterminismRulesTest` gained five fixture
tests (`stillCatchesARealForbiddenCallAfterStripping`, `ignoresAForbiddenNameInsideALineComment`,
`ignoresAForbiddenNameInsideABlockComment`, `ignoresAForbiddenNameInsideAStringLiteral`,
`catchesARealCallSharingALineWithAMentioningComment`) and a new `JavaSourceTest` gained four more for
the literal-scanning corners named in the plan (an escaped quote inside a string, an escaped
backslash right before a closing quote, a char literal holding a quote, an escaped quote inside a
char literal). All run the same `strip` → `containsToken` pipeline `noForbiddenApi` runs, on fixture
strings, so they do not depend on what `core` happens to contain.

**Red demonstrated, both directions.** First, the case where a defect removes stripping entirely:
temporarily made `strip` a no-op (`return content` before the real body). Ran
`./gradlew :core:test --tests "...DeterminismRulesTest" --tests "...JavaSourceTest"`, got 5 of 13
tests failing (the three comment/literal-ignoring fixtures plus two of the new `JavaSourceTest`
escape cases), then reverted. Second, and this is the one the issue calls the actual risk — a
stripper that strips too much and silently stops catching real calls: temporarily made the string
scanner also trigger on `.` (`c == '"' || c == '.'`), which eats real code after any period. Ran the
same two test classes and got exactly the two "still catches a real call" fixtures red
(`stillCatchesARealForbiddenCallAfterStripping`, `catchesARealCallSharingALineWithAMentioningComment`)
— the ones that exist specifically to catch this failure mode — then reverted. `./gradlew :core:test`
green after both reverts.

**Step 3, the one exception to this agent's boundary (D2).** Rewrote only the class javadoc of
`Rng.java`: it now names `Math.random()` and `java.util.Random` outright and drops the three lines
explaining why it was being coy, since the check no longer reads a javadoc comment as a call.
`git diff phase/11a-rule-asserting-tests -- '*/src/main/*'` shows only that one file, only comment
lines changed — pasted in the pull request.

**Ambiguity in the plan, worth flagging.** Neither the plan nor #53 says where the new fixture tests
should live. Put the five pipeline-level ones (strip + containsToken, mirroring `noForbiddenApi`
exactly) in `DeterminismRulesTest` next to the existing `searchesWholeWords`, and the four
literal-scanning corner cases in a new `JavaSourceTest`, since they are about `JavaSource` in
isolation rather than about the determinism rule itself. A different worker might have put all nine
in one place; naming the split here so it does not look accidental.

**Task 5b · `PublicContractTest` scope** ([#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) = [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4)) —
`test-engineer`, branch `test/public-contract-scope`. Both halves of D3
(`docs/plan/10a-honest-documentation/decisions.md`): the criterion reworded and the test's scope
stated in its own javadoc, plus the two smaller softnesses named alongside it.

**Where the criterion actually lived.** #54's reworded criterion — "no type of `core` reachable from
`game` exposes an implementation class" — has nowhere else to go: `docs/plan/01-foundations/plan.md`
is explicitly left alone by D3's own "Not done in this phase" note, and
`docs/planning/12-architecture.md` was already corrected by phase 10a on 26/08/2026. Grepping the
repository for the old wording (`exposes an implementation class`) after those two exclusions turns up
exactly one live occurrence: `PublicContractTest`'s own class javadoc, which read "No public type of
the core hands an implementation class to the outside" — no `game`-reachability, no scope, no reason.
That is not a second place carrying the overstated claim; it is the only one left, and it is also
where #54 asks the scope statement to go. Reworded in place, with the three facts D3 lists as making
the `core.domain` exclusion safe, verified rather than repeated:
- `GameSystem` (`core.domain.system.GameSystem`) takes a `World` argument, so systems must mutate it
  directly — `grep -n "World" core/src/main/java/dev/luchoc/littlespaceship/core/domain/system/GameSystem.java`.
- `Simulation.world()` is package-private and `Simulation.view()` is public and returns `WorldView` —
  `grep -n "world()\|WorldView view" core/src/main/java/dev/luchoc/littlespaceship/core/application/Simulation.java`,
  lines 142 (`public WorldView view()`) and 219 (`World world()`, no modifier).
- Java without JPMS having no "public within a module" visibility is a language fact, not something to
  grep.

All three still hold; nothing in this task's diff touches `core.domain`, `Simulation`, or `GameSystem`.

**The two narrowings, each demonstrated blind-before and caught-after.**

*`isAllowed` no longer accepts all of `java.util.*`.* Read every public port/application signature
(`grep -rn "java\.util\." core/src/main/java/dev/luchoc/littlespaceship/core/{port,application}`,
then checked which of those imports actually appear in a *public* member, not an internal local): only
`List` and `Map` cross the boundary today (`SimpleEnemyDefinition`, `SimpleFormationDefinition`,
`SimpleWaveTimeline`, `WaveTimeline`, `EnemyDefinition`, `FormationDefinition` for `List`;
`MapComponentSpec`'s constructor for `Map`). `Simulation`'s own public API uses no `java.util` type at
all — its one `ArrayList` is a private local. Narrowed `ALLOWED_JAVA_UTIL_TYPES` to exactly
`{List, Map}`. Demonstrated blind: added a temporary public `ArrayList<String> keys()` to
`MapComponentSpec` (a concrete class, not `ArrayList` itself, per the issue's own example), ran
`./gradlew :core:test --tests "*PublicContractTest*"` before narrowing — green, proving the old check
missed it — then narrowed and re-ran the same command:
```
PublicContractTest > what crosses the boundary is a contract, never the machinery behind it FAILED
    org.opentest4j.AssertionFailedError at PublicContractTest.java:87
2 tests completed, 1 failed
```
then reverted `MapComponentSpec.java` (`git checkout --`) and confirmed `./gradlew :core:test` green
again with the narrowed check against the real, unplanted code — no false positive from the narrowing.

*`LayerDependencyTest`'s `MACHINERY` list becomes a whitelist of the one domain package a port may
name (`domain.event`), instead of a hand-written blocklist of the rest.* The blocklist's gap was wider
than the issue's own example: it named `component`, `entity`, `system`, `World` and `rng`, but not
`collision` or `content`, both of which are domain machinery of the same kind
(`core/src/main/java/dev/luchoc/littlespaceship/core/domain/collision/`,
`.../domain/content/`) and both invisible to it. Demonstrated blind: added a temporary unused
`import dev.luchoc.littlespaceship.core.domain.collision.CollisionHit;` to `SpriteVisitor.java`, ran
`./gradlew :core:test --tests "*LayerDependencyTest*"` before the fix — green, an unnamed-machinery
import passing — then rewrote the check to whitelist `domain.event` and reject every other `domain.*`
import structurally, re-ran the same command:
```
LayerDependencyTest > the ports do not expose the machinery of the domain FAILED
    org.opentest4j.AssertionFailedError at LayerDependencyTest.java:70
4 tests completed, 1 failed
```
then reverted `SpriteVisitor.java` and confirmed `./gradlew :core:test` and `./gradlew build` both
green with the whitelist against the real code — the one legitimate case (`GameEventSink` importing
`domain.event.GameEvent`) still passes, and nothing else in `core.port` or `core.application` imports
`core.domain` at all.

No permanent fixture test was added for either narrowing: unlike task 5a's `JavaSource.strip`, which
operates on fixture strings by design, `PublicContractTest` and `LayerDependencyTest` only ever scan
`CoreSources.all()` — the project's real files — so there is no fixture seam to assert against without
either creating a fake source file the scanner would pick up or reaching into `core/src/main`, which is
out of this task's boundary. The blind-before/caught-after demonstration above, on real files planted
and reverted, is the evidence instead.

`git diff -- '*/src/main/*'` is empty on the branch that was committed;
`git status --short` shows only the two test files changed.

**Task 6 · `Rng` parity as a Gradle task** ([#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52)) —
`test-engineer`, branch `build/rng-parity-task`. New `:rngparity` subproject, registered in
`settings.gradle.kts`, depending on `:core` and applying the raw `org.teavm` plugin (version `0.15.0`,
same as `spikes/web-viability/rngcheck`) directly rather than the `gdx-teavm` wrapper `:web` uses —
there is no libGDX involved. Per D3, `core/build.gradle.kts` was not touched and nothing under
`core/src/main` was touched.

`rngparity/src/main/java/.../Main.java` runs the real `dev.luchoc.littlespaceship.core.domain.rng.Rng`
and checks it against the three sequences copied verbatim from `RngTest` (`pinnedSequence`, `zeroSeed`,
`pinnedFloatSequence`) — not a second, independently derived set. Both runtimes compare against this one
fixed expectation rather than against each other; a JVM/JS divergence still fails the check, because it
would make one of the two runs diverge from the shared expectation. Three Gradle tasks: `runOnJvm`
(`JavaExec`), `runOnNode` (`Exec`, depends on `generateJavaScript`, runs a committed `run.cjs` —
`generateJavaScript` produces the TeaVM module but not a way to invoke it, same as the precedent in
`spikes/web-viability/threadprobe/run.cjs`), and `rngParityCheck`, which depends on both and is the one
task to run:

```
./gradlew :rngparity:rngParityCheck
```

None of the three is wired into `check` or `build` — confirmed with `./gradlew clean build`, which
shows `:rngparity:compileTeavmJava NO-SOURCE` and no `generateJavaScript` anywhere in the log, only
`compileJava`/`jar`/`assemble` for the module. Confirmed the task itself works from a clean state with
`./gradlew clean :rngparity:rngParityCheck`, both runtimes printing:

```
OK   ints[seed=12345]: -598146918, 1963845983, -856963892, 976339029, 1163348040, 664654471, 610463809, 926368756
OK   ints[seed=0]: 2075758394, 25405621, -432837345, -108408265, -1171969584, -50598465, -1463423431, -1252371528
OK   floats[seed=12345]: 0.86073303, 0.4572435, 0.8004725, 0.22732162, 0.27086306, 0.1547519
Rng parity check: all three pinned sequences match on this runtime.
```

**Red demonstrated.** Changed one pinned int in `Main.java`'s `EXPECTED_INTS_SEED_12345`, ran
`./gradlew :rngparity:rngParityCheck`, got `:rngparity:runOnJvm FAILED` with `FAIL
ints[seed=12345]: …` printed and an `IllegalStateException`, then reverted.

`RngTest`'s `pinnedSequence` javadoc now names the task and says it is not part of the per-push CI job.
Node (`v24.19.0`) was available in this environment, so both runtimes were actually run, not just built.

**One deviation from the literal reading of point 1.** `generateJavaScript`'s own output has no runner;
Node needs something that calls `exports.main([])`. `spikes/web-viability/threadprobe/run.cjs` is the
repository's only precedent for this and is a hand-written, committed file, not a Gradle-generated one
(`spikes/web-viability/rngcheck/build/generated/teavm/js/run.cjs` looked auto-generated at first glance
but is an untracked leftover in a gitignored `build/` directory — `git ls-files` confirms nothing under
`spikes/web-viability` other than `threadprobe/run.cjs` is tracked). `rngparity/run.cjs` follows the same
pattern: committed at the project root, `require`s the TeaVM output by its build-relative path, and the
`runOnNode` task sets `workingDir` to the project directory rather than the generated output directory.

**Coordinator's finding on task 6: the copy moved, it did not go.** `#52` opens by objecting that
`spikes/web-viability/rngcheck/` holds its own copy of `Rng.java`, identical today and enforced by
nothing. The copied *class* is genuinely gone — `Main` imports the real one. But `RngTest`'s three
pinned sequences are now transcribed into `Main.java` as literal arrays, verified identical on
27/08/2026 and enforced by nothing. That is the same sentence with a different noun. Opened as
[#108](https://github.com/LuchoC-Dev/little-spaceship/issues/108), with the fix that removes the
duplication rather than checking it: `RngTest` already pins the algorithm on every push, so the
parity task only needs to prove the two runtimes agree — have the JVM run produce what the Node run
is compared against, and no constant is duplicated anywhere. `Main`'s javadoc, which claimed the
arrangement "cannot drift", is corrected to say what is actually true.

**Verified by the coordinator, not read:** `node --version` → `v24.19.0`;
`./gradlew :rngparity:rngParityCheck` runs both halves and prints three `OK` lines each, on the real
`core` `Rng`. `./gradlew build --dry-run` lists no `generateJavaScript`, `runOnJvm`, `runOnNode` or
`rngParityCheck` for `:rngparity` — only `compileJava`/`jar`/`assemble`, which any subproject
contributes and which cost nothing.

## In progress

Nothing. The table below is the phase's final shape: the plan's seven tasks became eight pieces of
work — task 5 split, see D1 — of which seven went to a worker.

| Task | Issue | Worker |
|---|---|---|
| 1 · baseline count | [#96](https://github.com/LuchoC-Dev/little-spaceship/issues/96) | `test-engineer` — done |
| 2 · defensive chain | [#97](https://github.com/LuchoC-Dev/little-spaceship/issues/97) | `test-engineer` — done |
| 3 · the boss's rules | [#98](https://github.com/LuchoC-Dev/little-spaceship/issues/98) | `test-engineer` — done |
| 4 · level completion | [#99](https://github.com/LuchoC-Dev/little-spaceship/issues/99) | `test-engineer` — done |
| 5a · forbidden-API check | [#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) (= [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3)) | `test-engineer` — done |
| 5b · `PublicContractTest` scope | [#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) (= [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4)) | `test-engineer` — done |
| 6 · `Rng` parity as a Gradle task | [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52) | `test-engineer` — done |
| 7 · where [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) goes | — | the coordinator — done, see D5 |

## Blocked

Nothing.

## Decisions taken while implementing

Four, all taken by the coordinator **before any worker was launched**, because each of them would
otherwise have been resolved by an agent in the middle of a task.

### D1 — Task 5 is two workers, not one

The plan's task 5 covers two independent pieces of work duplicated as four issues. They share nothing
but the phase that carries them: [#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) changes
`JavaSource` and `Rng`'s javadoc, [#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) changes
`PublicContractTest` and `LayerDependencyTest`. One worker for both would carry two unrelated diffs into
one pull request, and only one of them needs D2's exception.

### D2 — `test-engineer` may rewrite `Rng`'s class javadoc, and nothing else in `core/src/main`

`test-engineer`'s definition says it does not modify production code, and
`core/src/main/java/dev/luchoc/littlespaceship/core/domain/rng/Rng.java` is `core-domain`'s file.
[#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) step 3 is nevertheless part of the same
piece of work: the javadoc is coy *because* the check greps raw text, so fixing the check is what makes
the plain wording possible, and the two land together or the reason for the change is invisible.

**The exception and its limit:** comment text inside `Rng.java` only. No executable line, no signature,
no annotation, no import, no other file under any module's `src/main`. `git diff -- '*/src/main/*'` on
that branch must show changes to comment lines of that one file and nothing else.

`docs/plan/agent-prompts.md` says to split rather than grant an exception. Splitting here would spend a
whole worker — phase 09 measured a worker at 1.8–6.6 M cached tokens just to start
(`docs/planning/13-working-with-agents.md`) — on four lines of comment that cannot change behaviour and
whose limit a one-line `git diff` enforces.

### D3 — the `Rng` parity check gets its own Gradle subproject; `core` is not touched

[#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52) asks for the real
`dev.luchoc.littlespaceship.core.domain.rng.Rng` to be compiled through TeaVM. Applying the TeaVM plugin
to `:core` would put a libGDX-adjacent toolchain on the module whose whole point is not having one —
invariant 1 says the compiler is what enforces that, and `core/build.gradle.kts` says so in a comment.

So the check lives in a **new subproject** that depends on `:core`, applies the TeaVM plugin itself, and
is registered in `settings.gradle.kts`. `game/src/tools/java` is the precedent: `tools/audio` moved into
its own source set for exactly this reason, and it was verified against the jar that `game.jar` carries
no `tools` classes.

**The limit:** the worker may create that subproject and add one line to `settings.gradle.kts`. It may
not add a dependency to `core/build.gradle.kts` and may not touch anything under `core/src/main`.

### D4 — task 7 is the coordinator's, not a worker's

Deciding where [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) — `game` has no tests —
belongs is a routing decision about phases, not test engineering. It is written below and put to the
project owner rather than handed to an agent.

### D5 — #19 does not go to 11f, and it does not stay open indefinitely: it goes to the 12 group

Task 7 asks where [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19) — `game` has no
tests at all — belongs. The three options the plan names are 11f, a later group, or open.

**Not 11f.** #19's own text says the loader is "the piece with the most ways to fail quietly" and
names its error paths as what a suite would cover: malformed content must fail naming the file and
the offending id, never a `NullPointerException`. Those paths are in `JsonContentSource`, and
**11b rewrites it** — task 5 of `docs/plan/11b-wave-system/plan.md` is
[#87](https://github.com/LuchoC-Dev/little-spaceship/issues/87), loading a level by id, and task 7
is reading `waves.json` and a level's wave references. Tests written in 11f would be written against
a file format with a known expiry date, which is the same "doing the work twice" the roadmap uses to
justify putting waves before balance.

11f's plan already anticipates both halves of this: its task 5 says "decide #19, or execute the
decision 11a made about it", and its "Why this runs in parallel" section calls `game`'s missing suite
"this phase's first question rather than a reason to wait".

**Not open, either.** It has been open since phase 03 and "open" is what let phase 03's coordinate bug
(`Transform.x` is playfield-local `[0,208]`, not logical `[0,480]`) survive a whole phase.

**The 12 group.** `post-mvp-roadmap.md` calls phase 12 "the first real test of whether the code
reordering worked", and levels 2 and 3 are what first exercise a loader keyed by level id — the code
#87 will have just written. The loader is worth testing when there is more than one level to load and
the format has stopped moving, and that is exactly where 12 starts.

**Amended after `reviewer`'s pass, which was asked to argue with this and did.** #19 bundles two
questions, and only one of them is blocked. *What to assert about `JsonContentSource`'s error
messages* depends on the format, and that is the half 11b rewrites. *How to unit-test anything
depending on `FileHandle` without dragging LWJGL into the suite* does not: it is a harness design
question, and #19's own text calls it "the question to answer first". A JDK dynamic-proxy stand-in
for `Gdx.input`/`Gdx.graphics` — which is what phase 03's two throwaway programs used, and
`docs/plan/03-first-playable/status.md` transcribes their output without them ever being committed —
is indifferent to which JSON shape 11b lands on.

So the decision splits:

- **The harness question is not blocked** and can be answered whenever `game-presentation` and
  `test-engineer` next have reason to. Answering it early is what makes the 12 group's half cheap,
  and it is the piece that has been quietly costing this project since phase 03.
- **The assertions about the loader's error paths go to the 12 group**, for the reason above.

Nobody had written that split down before `reviewer` read it this way; it is the finding of the
review pass.

**What this phase owes it:** nothing in code. #19 stays open with this decision recorded on it.

**Put to the project owner**, because it adds scope to a group that is not planned yet.

## The review

`reviewer` audited the whole phase branch on 27/08/2026 against the plan's acceptance criteria and
`CLAUDE.md`'s invariants, and **accepted it**. It was told what the coordinator had already run, so
it spent the pass on what a command cannot see.

What it re-derived rather than took on trust: the `src/main` diff scope; `BossReplayTest`'s aiming
geometry, recomputed by hand from `BossSystem`'s constants (player column x 80, arm centre x 60
radius 14 — missed; pod centre x 70 radius 12 — hit) and the `survivingPods` radius band, which
excludes `CORE_KEEL_RADIUS` 13.0 by strict `<` and every other collider in the scenario; the
unreachability of `alive` in both branches of `outcome()`; every rule-to-test row in tasks 2-4
against the test bodies; and both narrowings, checked for over- and under-narrowing by grepping every
`java.util.*` and `domain.*` import in `core.port` and `core.application`. It confirmed the two open
gameplay items are named and not asserted, and that
`invulnerabilityAlsoProtectsAgainstConsequencesForTheOther` is pre-existing (phase 04, `32b0c80`)
rather than added here.

**No invariant violations, no false claims in this file, no coverage lost by the narrowings.** Its
one substantive contribution is the argument against D5, which is incorporated above.

## Notes for whoever comes next

**The premise you inherit is not the roadmap's.** 167 of the 289 tests already asserted a rule. What
was thin was the five cross-system replay files and a handful of specific clauses, and that is what
this phase closed. Read `baseline.md` before assuming the suite is weak.

**Two things go to `core-domain`, and one of them is worth doing before 11b:**
[#104](https://github.com/LuchoC-Dev/little-spaceship/issues/104), the unreachable `alive` conjunct
in `World.View.outcome()`, in a method 11b will be reading closely; and
[#108](https://github.com/LuchoC-Dev/little-spaceship/issues/108), the pinned sequences duplicated
between `RngTest` and `rngparity/Main.java`.

**11b inherits a described gap**, not a vague one: nothing reaches the bossless `COMPLETED` through
the real spawn-and-clear pipeline. Task 4's entry above says exactly which tests reach it and how
they cheat.

**11e inherits two things.** The boss's structural rules are in `docs/plan/07-boss/status.md` rather
than `docs/planning/`, and `02-mvp-functional-spec.md:184` still calls the boss's patterns open.
And `DamageSystemTest.invulnerabilityAlsoProtectsAgainstConsequencesForTheOther` pins a reading of an
item `08-decisions-and-open-items.md` lists as open — when that item is settled, the test moves with
the decision rather than counting as a vote for the current behaviour.

**`spikes/web-viability/` was deleted on 27/08/2026**, on the project owner's instruction once #52
removed the one thing that kept it. What was done alongside the deletion, so the citations it leaves
behind stay worth something: the last commit containing the directory is `68d002e0560c`, recorded in
`docs/STATUS.md`, in `docs/planning/11-technical-prototype-results.md` — whose every number was
measured on that code and is **not** re-runnable from a checkout of `dev` — and in
`CollisionSystem`'s class javadoc, which cites the benchmark by path. `docs/STATUS.md`'s 8181-vs-8080
trap no longer sends anyone to a README that is gone.

The references left untouched on purpose are in phase plans and status files (01, 03, 09, 10a): those
are dated records of what was true when they were written, and the convention here is that a status
file stays one. The named commit is what makes them chaseable.
