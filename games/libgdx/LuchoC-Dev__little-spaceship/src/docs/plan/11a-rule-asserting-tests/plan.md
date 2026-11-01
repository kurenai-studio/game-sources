# Phase 11a — Tests that assert rules

**Lane:** code · **Owner:** `test-engineer` · **Depends on:** 10c · **Runs first of the 11 group, and nothing else starts before it**

## Before you start

**Read, in this order:**

1. [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md), "Tests that assert rules, not only reproducibility" and "The order inside this group is not arbitrary". This plan does not restate them.
2. [`../10c-architecture-review/assessment.md`](../10c-architecture-review/assessment.md), area H.
3. `CLAUDE.md` — the six invariants, in particular 2 (determinism) and the commit rules.
4. [`../how-to-run-a-phase.md`](../how-to-run-a-phase.md).
5. Your agent memory in `.claude/agent-memory/test-engineer/` — it is empty; you are the first to write it.

**Do not re-decide:** that this phase runs first. It is decided in the roadmap and confirmed with
evidence by 10c's decision, and the reason is that 11b, 11c and 11e are all behaviour changes.

## Goal

**Breaking a decided game rule turns a test red.** Today, in the general case, it does not: the suite
mostly proves that a run reproduces itself, and a broken rule breaks identically on both runs.

The roadmap's own example is `core/src/test/java/dev/luchoc/littlespaceship/core/application/BossReplayTest.java`
— two tests, both determinism, nothing asserted about the boss's modules.

## Why this runs first

Every phase after this one changes behaviour: 11b changes what advances the spawn cursor, 11c changes
how an entity moves, 11e redesigns the numbers. **Rebalancing without rule-asserting tests is changing
numbers with no net underneath**, and the determinism replays will not catch it.

There is a live example already in the repository. [#23](https://github.com/LuchoC-Dev/little-spaceship/issues/23)
— a designed drop delivered once per formation slot instead of once — is a rules bug that 289 tests did
not catch, and it is exactly the kind of thing waves will depend on.

## Tasks

1. **Establish the baseline, by counting rather than by impression.** How many of the tests in
   `core/src/test/` assert a rule and how many assert reproducibility. 10c explicitly did **not**
   re-count this and marked it "not checked"; the roadmap's figure is inherited, not measured. Write
   the count and the method down.
2. **Assert the decided rules of the defensive chain.** `docs/planning/03-game-systems.md` and
   `08-decisions-and-open-items.md` settle the order invulnerability → shield → attachment → life,
   the attachment absorbing the hit that would cost a life, and temporary invulnerability after any
   damage taken. `DamageSystem`, `HealthDamage` and `PickupSystem` implement it.
3. **Assert the boss's rules**, starting with the roadmap's own example: the ship destroys module 1
   and the world reflects it. `BossSystem` has six colliders and a `SPREAD`/`SWEEP` alternation over a
   fixed tell.
4. **Assert the level-completion rules.** `World.View.outcome()` decides `COMPLETED` from
   `waveTimelineExhausted && noEnemyLeft() && alive`, and `ScoreSystem.completionBonus` pays
   `lives * 1000 + bombs * 300`. The bossless branch of `outcome()` is exercised by exactly one test
   that destroys its enemy by hand (`SpawnSystemTest.completesOnceTheTimelineIsExhaustedAndNothingIsAlive`,
   line 340) — that gap is 11b's first problem and it starts here.
5. **Fix the two test defects 10a decided and handed forward.** They are duplicated as four issues:
   [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3) = [#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53),
   the forbidden-API search does not strip comments and string literals, which forces `Rng.java` to
   describe forbidden APIs obliquely; [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4) =
   [#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54), `PublicContractTest` checks a
   narrower rule than the criterion it is cited for. Close all four, and say in each which of the two
   pieces of work it was.
6. **Resolve [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52).** The cross-runtime
   `Rng` parity check lives in `spikes/web-viability/rngcheck/` and is the only measurement that
   invariant 2 holds on TeaVM. Move it onto the real class as a Gradle task. When it lands, the spike
   directory is deletable — `docs/STATUS.md` says so, and 10a's decision D1 is the record.
7. **Decide what happens to [#19](https://github.com/LuchoC-Dev/little-spaceship/issues/19).** `game`
   has no tests at all. It is not this phase's job to write them — `game` is `game-presentation`'s
   module — but this phase is the one that owns the question of what the suite covers. Decide whether
   it belongs to 11f, to a later group, or stays open, and write the reason.

## Acceptance criteria

- The baseline count exists, with the method used to produce it, and is reproducible by running a
  command the document names.
- The rules in tasks 2, 3 and 4 each have at least one test that **fails when the rule is broken**,
  and each test's name states the rule. Demonstrate the failure, do not assert it: for at least one
  test per task, record the command that broke the rule and the output showing red.
- #3, #4, #52, #53 and #54 are closed. #19 has a written decision.
- The determinism replays still exist and still pass. This phase adds beside them; it removes none.
- `./gradlew build` is green and `tools/pre-pr-check --base phase/11a-rule-asserting-tests` is clean
  on every pull request.

## What is out of scope

- **Waves, movement, balance, the boss's design.** This phase asserts the rules that exist today. It
  does not change one.
- **Writing tests for `game`.** That is #19 and another agent's module. Deciding where it goes is in
  scope; writing them is not.
- Performance. `beyond-mvp.md` already fixes the rule: a profiler, not a hunch.
- Rewriting tests that are fine.

## Risks

**Asserting the code instead of the rule.** A test written by reading `DamageSystem` and restating what
it does passes for ever and proves nothing. The rule comes from `docs/planning/`, and the test's name
states it. If the code and the decided rule disagree, that is a finding, not a test to bend.

**Inventing a rule that was never decided.** `08-decisions-and-open-items.md` separates the decided from
the open, and it lists several gameplay items as open on purpose — whether invulnerability suppresses
the consequence for the other entity, which archetypes count as "weak". **Do not assert an open item.**
Name it and leave it.

**Scope creep into a suite rewrite.** The target is the rules in tasks 2, 3 and 4, plus the five issues.
Not test coverage as a number.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull
request against `phase/11a-rule-asserting-tests`, then `status.md` before review.
