# Phase 01 — Foundations

**Lane:** code · **Owner:** `core-domain` · **Depends on:** nothing · **Target:** day 1

## Before you start

**Read, in this order:**

1. `CLAUDE.md` — invariants and conventions.
2. `docs/planning/12-architecture.md` — the whole document. This phase implements its first half.
3. `docs/plan/how-to-run-a-phase.md` — the working cycle.

**Do not re-decide:** the ECS is hand-written without a library, `core` is plain Java with no libGDX, the loop is fixed-step, and there is no concurrency. Each of those was decided with measurements behind it; `docs/planning/11-technical-prototype-results.md` has the numbers.

**Working reference:** `spikes/web-viability/` contains a Gradle build that compiles and ships to the browser. Copy its **configuration** — versions, plugin block, module wiring. Do **not** copy its code: it is a throwaway prototype and its shortcuts are not the architecture.

## Goal

The Gradle skeleton and the beating heart of the simulation: entities, systems, a fixed-step loop, seeded randomness and an immutable input frame — all testable without libGDX.

Nothing is visible on screen at the end of this phase. That is expected: what it buys is that everything after it can be tested in milliseconds.

## The stack, exactly

Verified end to end in the spike, including running in a real browser. Do not upgrade any of these as part of this phase.

| Component | Version |
|---|---|
| Java | 17 (source and target; the installed JDK is 25) |
| Gradle | 9.7.0, via wrapper |
| libGDX | 1.14.2 |
| gdx-teavm plugin | 1.6.1 — `id("com.github.xpenatan.gdx-teavm")` |
| TeaVM | 0.15.0 |
| JUnit | 5 |

The web backend artifact is `backend-web`, not `backend-teavm`; the plugin adds it on its own when a `js {}` or `wasm {}` target is declared. Plugin resolution needs `mavenCentral()` in `pluginManagement`.

## Tasks

1. **Gradle skeleton.** Wrapper, modules `core`, `game`, `desktop`, `web`, root package `dev.luchoc.littlespaceship`. `core` declares **no** libGDX dependency — that is what turns the invariant from a promise into something the compiler enforces.

2. **Entity registry.** An entity is an `int` carrying a generation, so a reference to a destroyed entity can be detected instead of silently pointing at a recycled slot.

3. **Component storage.** Plain data, no logic. Start with `Transform`, `Motion` and `Collider`; the rest arrive with the phase that needs them.

4. **System pipeline.** Fixed execution order, declared in one place. The order is a game rule — changing it changes behaviour. The full sequence, from `12-architecture.md`:

   ```
   1  InputSystem       translates the InputFrame into player intent
   2  MotionSystem      applies velocities and trajectories
   3  WeaponSystem      resolves rates of fire and creates projectiles
   4  SpawnSystem       advances the level timeline
   5  LifetimeSystem    expires projectiles and effects
   6  CollisionSystem   detects impacts and emits collision events
   7  DamageSystem      applies the defensive priority
   8  PickupSystem      resolves power-ups and attachments
   9  ScoreSystem       accumulates score
   10 CleanupSystem     destroys what was marked and frees ids
   ```

   This phase only needs the pipeline to exist and to run systems in that declared order. Most of those systems arrive in later phases.

5. **`GameLoop`.** Accumulator with a 1/60 step, clamping the real delta so a stalled frame cannot cause a spiral of death. The simulation never sees a variable delta.

6. **`Rng`.** This one has a requirement that is easy to miss: **it must produce identical sequences on the JVM and in the browser**, or replays recorded on desktop will diverge on web and the failure will look like a game bug.

   Write it yourself with explicit integer arithmetic — a small xorshift or a linear congruential generator is plenty. Do **not** use `java.util.Random` or anything whose implementation you have not verified under TeaVM. `spikes/web-viability/collisionbench/` contains a generator written for exactly this reason.

   Add a test that pins a known sequence for a known seed, so an accidental change to the algorithm fails loudly instead of silently invalidating every replay.

7. **`InputFrame`.** Immutable record: movement vector, fire, slow, bomb. Built outside the core and handed in once per tick.

8. **`WorldView` and the ports.** The read-only contracts `game` will consume, plus `ContentSource` and `GameEventSink` as the core declares them. `12-architecture.md` sketches their shape; `WorldView` traverses with a visitor so rendering never allocates per entity per frame.

## Acceptance criteria

Verifiable, not opinions:

- `./gradlew :core:test` passes, and `core` compiles **without libGDX on its classpath**.
- Grep finds zero occurrences of `com.badlogic.gdx`, `System.currentTimeMillis`, `System.nanoTime` and `Math.random` inside `core/src/main`.
- Same seed plus same `InputFrame` sequence, twice, produces an identical final state. No real system exists yet at this point, so this is proven with stub systems written inside the test; inventing real ones here would step into phase 02.
- The `Rng` produces the same stream on the JVM and under TeaVM, checked by running the class itself on both.
- The `Rng` reproduces a pinned sequence for a pinned seed.
- The loop runs a fixed number of ticks for a given elapsed time, independent of frame rate.
- No public type in `core` exposes an implementation class.
- An architecture test asserts the dependency rule between layers.
- `./gradlew build` succeeds for every module.

## Risks

**The determinism invariant is silent when broken.** A single `System.nanoTime()` slipped in "just for logging" invalidates every replay without failing a test. The greps above exist for that.

**A divergent `Rng` is the worst version of that failure**, because it only shows up when comparing desktop against web — likely days later, looking like something else entirely.

**Over-engineering the ECS.** Archetypes, queries and bitsets are tempting. The MVP has a few hundred entities. Build the smallest thing the systems actually need.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.
