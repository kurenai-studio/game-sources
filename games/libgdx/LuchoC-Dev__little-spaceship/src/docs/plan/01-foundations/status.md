# Phase 01 — Foundations · status

**State:** done
**Updated:** 20/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

Everything the plan asks for, merged into `main` through pull request [#2](https://github.com/LuchoC-Dev/little-spaceship/pull/2), which closed issue #1.

- **Gradle skeleton.** Wrapper 9.7.0, root build, and the modules `core`, `game`, `desktop` and `web` with the versions verified in the spike. `core` declares no dependency, so the libGDX invariant is enforced by the compiler.
- **ECS.** `EntityId` and `EntityRegistry` (int handle with a generation, recycled slots), `ComponentStore` (sparse array for lookup, dense array for iteration), and the components `Transform`, `Motion`, `Collider` and `Sprite`.
- **System order.** `SystemOrder` holds the ten stages; `GameSystem` declares its stage and `SystemPipeline` runs them by stage. No system is implemented yet.
- **`GameLoop`.** Fixed step of 1/60, accumulator, clamp at 0.25 s.
- **`Rng`.** 32-bit xorshift, only xor and shifts, with three pinned sequences.
- **Ports.** `InputFrame`, `SpriteId`, `SpriteVisitor`, `WorldView`, `ContentSource`, `BalanceValues`, `GameEventSink`, plus `GameEvent` and the queue that drains after each tick.
- **Tests.** 91, all passing, none needing libGDX: determinism of a whole run, the pinned generator, the loop at five frame rates, the dependency rule between layers, the forbidden APIs, and what the boundary is allowed to expose.

Every acceptance criterion in `plan.md` passes. The table in the pull request lists them one by one.

The review left three follow-up issues open: [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3), stripping comments before the forbidden-API search; [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4), `PublicContractTest` checking a narrower rule than the criterion claims; [#5](https://github.com/LuchoC-Dev/little-spaceship/issues/5), `rngcheck` living in a throwaway directory. None of them blocks phase 02.

## In progress

Nothing. `reviewer` accepted the phase and the pull request is merged.

## Blocked

Nothing.

## Decisions taken while implementing

None of these changes a game rule, so none of them belongs in `08-decisions-and-open-items.md`.

- **`Simulation` takes a seed, not an `Rng`.** The sketch in `12-architecture.md` builds the generator in the composition root. Taking the seed instead keeps every source of randomness inside `core`, and it is what makes it impossible for `game` to inject another one.
- **`WorldView` ships with `forEachSprite` only.** `PlayerStatus` and `BossStatus` need a player and a boss to report on, and neither exists yet. They join with phases 03 and 07.
- **`ContentSource` ships with `balance()` only.** Enemy definitions and level timelines are the content pipeline, phase 04. `BalanceValues` declares only the values already decided in `10-mvp-initial-values.md`.
- **A fourth component, `Sprite`, beyond the three the plan lists.** Without it the render contract has nothing to walk and could not be tested. It carries the content identifier, the animation frame and the rotation.
- **`GameEvent` has no concrete events yet.** Inventing their fields before a system emits them would be guessing. The queue is tested with an event belonging to the test.
- **`GameLoop` accumulates time in double.** With a float accumulator one second becomes fifty-nine ticks at some frame rates and sixty at others, which is the frame-rate dependency the loop exists to remove. What the systems receive is still the fixed float step, so determinism is untouched.
- **The `web` module applies the gdx-teavm plugin with its target block commented out.** The plugin needs a real main class to configure a target, and `WebLauncher` belongs to phase 03. `./gradlew build` passes as it stands.
- **No comment in `core` may spell out a forbidden API name.** The check is a plain text search, on purpose, so it finds exactly what a reviewer greps by hand. The `Rng` documentation talks around the two names and says why.

## Notes for whoever comes next

- **Where a new system goes.** Add its stage to `SystemOrder` if it needs a new one, implement `GameSystem`, and register it in `Simulation.mvpPipeline()`. Registration order is irrelevant; the stage decides.
- **Where a new component goes.** A class in `domain.component` with public fields and no logic, a store in `World`, and a line in `World.destroyEntity`. That method is the one place that has to know every store, and forgetting it there is what leaves data hanging from a recycled slot.
- **The tests can build a `Simulation` with systems of their own** through the package-private constructor. That is how the determinism test works without any game rule existing.
- **Regenerating the pinned `Rng` sequences invalidates every replay.** If `RngTest` fails, the question is whether the algorithm changed on purpose.
- **`Rng` parity under TeaVM: measured, not just argued.** Verified on 19/08/2026 by compiling the class itself through TeaVM and running it on Node: the integer stream, the float stream and the zero-seed stream are identical to the JVM, bit for bit, and match the pinned sequences. The check lives in `spikes/web-viability/rngcheck/`.

  **Corrected 26/08/2026 by phase 10a**, which found this sentence and `docs/STATUS.md` contradicting each other ([#5](https://github.com/LuchoC-Dev/little-spaceship/issues/5)): this said the check can be re-run whenever the algorithm is touched, and `STATUS.md` offered the spike for deletion. What is there is weaker than "re-runnable" sounds — `rngcheck` holds **its own copy** of `Rng.java`, so re-running it means updating the copy by hand first, and a copy that drifted would pass while proving nothing. Decided in `docs/plan/10a-honest-documentation/decisions.md` (D1): the check moves onto the real class as a Gradle task, [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52), and until it does, the spike is not deletable.
