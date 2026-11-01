# Technical prototype results

Run on 18/08/2026 on the `spikes/web-viability` spike, following the approval criteria set in `06-platform-and-technical-validation.md`.

**Where the spike is now.** The directory was deleted on 27/08/2026, once phase 11a moved its one still-live check onto the real class. The last commit containing it is `68d002e0560ce40842dc8f72e876fa5fe78bb3ed`; `git show 68d002e0560c:spikes/web-viability/collisionbench/src/main/java/colbench/Main.java` reads the benchmark behind the collision figure below, and the same form reads any other file of it. The numbers on this page were measured on that code and are not re-runnable from a checkout of `dev` without restoring it first.

## Verdict

**🟢 Web approved.** The candidate becomes the platform decision:

> **Java + libGDX + Gradle + gdx-teavm → browser**, with desktop sharing the same core.

No result forced the game design to be deformed, which was the condition for abandoning the web target.

## Verified stack

| Component | Version |
|---|---|
| libGDX | 1.14.2 |
| gdx-teavm | 1.6.1 (plugin) / `backend-web` |
| TeaVM | 0.15.0 |
| Gradle | 9.7.0 |
| Java | JDK 25 installed, compiling to bytecode 17 |

The `backend-teavm` artifact was renamed to `backend-web`; the plugin adds it only when `js {}` or `wasm {}` is declared.

## Performance

Maximum step of the spike: **4000 moving entities** with collision against the ship. That is an order of magnitude above what level 1 needs.

| Target | FPS | min | p1 | draw | update |
|---|---|---|---|---|---|
| Desktop (JVM, no vsync) | 307 | 65 | 72 | 0.60 ms | 0.02 ms |
| Web JavaScript (release) | 60 | 45 | 50 | 10.34 ms | 0.05 ms |
| Web WebAssembly (release) | 61 | 42 | 56 | 10.05 ms | 0.03 ms |

Reading: in the browser the frame budget at 60 fps is 16.6 ms and drawing consumes 10 ms **in the worst synthetic case**.

The `update` column of this table measures the cheap case —n entities against a single point— and on its own it does not prove that simulation is negligible. The next section repeats the measurement with real n × m collisions.

Desktop has plenty of headroom; it serves as a baseline and confirms that the web ceiling belongs to the browser, not to the design of the core.

## JavaScript versus WebAssembly

| | JavaScript | WebAssembly |
|---|---|---|
| Size | 662 KB | 729 KB |
| Compressed | 192 KB | 245 KB |
| Performance | equivalent | equivalent |

**There is no winner.** Wasm performs marginally better at the 1st percentile and worse at the minimum; the difference is within the noise. JavaScript weighs less and its debugging is better: TeaVM offers source maps and debugging from IntelliJ only for the JS target.

Recommendation: **publish JS**, keeping Wasm available because the same project generates both at no cost. The decision can be revisited once real gameplay exists.

## Rest of the traffic light

| Area | Status | Note |
|---|---|---|
| 2D rendering and pixel-art | 🟢 | Integer scaling and nearest-neighbour without deformation |
| Simultaneous keyboard and mouse | 🟢 | The additive scheme decided for the MVP works |
| Audio | 🟢 | Effects and hot music change, via Howler |
| Asset loading | 🟢 | 62-64 ms in the spike |
| Web build | 🟢 | JS and Wasm from the same core, without per-platform branches |
| Download size | 🟢 | 192 KB compressed leaves plenty of room for art and audio |
| Core shared with desktop | 🟢 | The web launcher needed no specific branch |
| Pointer capture | 🟡 | Not verified; it is needed for the relative mouse |
| Firefox, Edge and Safari | 🟡 | Only Chrome was tested |
| Arbitrary Java dependencies | 🟡 | Still applies: each one must be evaluated for TeaVM compatibility |

## Findings that affect the implementation

**`assets/startup-logo.png` is mandatory.** The backend's preloader always loads it and, if it is missing, the application fails when the preload finishes, with an error that never mentions the logo. It must be included from day one of the real project.

**The canvas needs an explicit size.** With `config.width = 0` and `config.height = 0` the backend inherits the container size, which starts at 0×0 and leaves the preloader without a stage. The canvas resizing policy will have to be decided together with the scaling one.

**Headless Chrome is no use for validating the web runtime.** Under SwiftShader the application fails even though it works in a real browser. Any automated verification of the web target —CI included— needs a real GPU or will be limited to checking that the build compiles.

## Build tool

What had been pending from the start is now resolved: **Gradle**, not Maven.

It is not an aesthetic preference. The gdx-teavm plugin is a Gradle plugin, it resolves the backend, the assets, the `index.html` and the local server by itself, and it generates the JS and Wasm tasks. Reproducing that with Maven would be manual integration with no gain.

## Consequences for the MVP values

The proposed logical resolution of **480×270** with a 208 px playfield was used throughout the spike and worked without scaling problems. It is confirmed as the starting point.

## n x m collisions: correction of the first measurement

The first performance test had a flaw: it compared n entities against **a single point**, the ship. That is 4000 checks against 1, not the projectile × enemy pairs a shoot 'em up needs. It was measuring the cheap case.

Repeated with a real collision benchmark (`spikes/web-viability/collisionbench`), in pure Java so that the same code runs on the JVM and on Node and the comparison measures the runtime, not two implementations.

Each scenario includes player projectiles × enemies, enemy projectiles × player and the movement of everything.

### JavaScript (TeaVM, aggressive optimisation)

| Scenario | Pairs per tick | Naive | Grid |
|---|---|---|---|
| Realistic MVP — 80 bullets, 40 enemies, 300 enemy bullets | 3,500 | 0.028 ms | 0.027 ms |
| Dense — 200, 100, 800 | 20,800 | 0.098 ms | 0.023 ms |
| Very dense — 500, 200, 2000 | 102,000 | 0.423 ms | 0.072 ms |
| Absurd — 1000, 500, 4000 | 504,000 | 2.108 ms | 0.207 ms |

### JVM, same code

| Scenario | Naive | Grid |
|---|---|---|
| Realistic MVP | 0.037 ms | 0.022 ms |
| Dense | 0.032 ms | 0.037 ms |
| Very dense | 0.160 ms | 0.057 ms |
| Absurd | 0.997 ms | 0.227 ms |

### Reading

The frame budget at 60 fps is 16.6 ms.

- The MVP scenario consumes **0.17 %** of the frame. It is not measurable next to drawing.
- Half a million pairs per tick, far above anything this game is going to produce, costs **2.1 ms unoptimised** and **0.21 ms with a grid**: 12.7 % and 1.2 % of the frame.
- JavaScript is roughly twice as slow as the JVM in the naive loop, and practically equal with a grid.

The conclusion does not change: **the bottleneck is drawing, not simulation**. With 4000 entities drawing cost 10 ms; the logic, real collisions included, stays in fractions of a millisecond.

### Where the real lever is

If collision ever became expensive, the solution is **algorithmic, not concurrent**. A uniform grid gave up to a **10× improvement** in the worst scenario, more than eight threads could give — threads the browser does not offer anyway.

The correct optimisation order for this game is:

1. batching and texture atlases, because the cost is in drawing;
2. spatial structures for collision, if it ever becomes necessary;
3. concurrency, which on the web is not available and on desktop would not solve either of the previous two points.

## Concurrency: what the web target really allows

Measured on 18/08/2026 with a pure TeaVM probe (`spikes/web-viability/threadprobe`), run on Node to isolate the concurrency model from libGDX and from the GPU.

### What does not exist

These APIs are **not in the TeaVM 0.15.0 library**. They do not emit a warning: **they break the build**.

| API | Status |
|---|---|
| `java.util.concurrent.Executors` | does not exist |
| `java.util.concurrent.ExecutorService` | does not exist |
| `java.util.concurrent.CompletableFuture` | does not exist |
| `java.util.concurrent.locks.ReentrantLock` | does not exist |

### What exists but does not do what it seems to

`Thread` compiles and `start()` throws no exception, so a multithreaded design *appears* to work. The measurement says otherwise:

| Moment | Worker ticks |
|---|---|
| After 20 million iterations of the main thread, without yielding | **0** |
| After a single `Thread.sleep(50)` on the main thread | 2000, completed |

The worker **did not advance a single time** while the main thread was working. It only progressed when the main thread yielded control.

The model is **cooperative concurrency**, not parallelism. TeaVM emulates it with coroutines on JavaScript's single thread. Two threads never execute at the same time, so splitting work between them does not reduce the total time: it increases it, because of the switching cost.

`synchronized`, `AtomicInteger` and `ConcurrentHashMap` do work, but they protect against a concurrency that cannot happen.

**Trap to avoid:** `Runtime.getRuntime().availableProcessors()` returns **8** in the browser. Sizing anything with that number produces a design that believes itself parallel and is sequential.

### Why this is not a problem for this game

The benchmark itself says so: with 4000 entities, the game logic consumes **0.03-0.05 ms** per frame and drawing **10 ms**. The budget goes entirely into drawing.

Parallelising the simulation would optimise 0.3 % of the frame. There is no measured performance problem that multithreading solves.

### Decision

**Multithreading is discarded** (18/08/2026). It is not a limitation that will be suffered: there is no measured problem it would solve.

### Consequence for the architecture

The core must be designed **single-thread**, with a deterministic update loop. That also:

- makes the simulation reproducible, which is what allows really testing game systems;
- eliminates an entire class of concurrency bugs;
- keeps desktop and web executing exactly the same code.

If a genuinely parallelisable task ever appeared, the way out is not `Thread` but Web Workers with message passing and no shared memory, which gdx-teavm does not abstract and would have to be integrated by hand. It is not worth designing for that without a real case.

## Java version

Measured with a language feature probe (`spikes/web-viability/langprobe`), compiled to TeaVM and run on Node. Stable features only; nothing marked as preview.

### Java 17 — everything works

| Feature | Status |
|---|---|
| `record`, with `equals`, `hashCode` and `toString` | ok |
| `sealed interface` | ok |
| pattern matching for `instanceof` | ok |
| `switch` as an expression | ok |
| text blocks | ok |
| `List.of` / `Map.of` | ok |
| `Optional` | ok |
| lambdas and functional interfaces | ok |
| `String.format` | ok |

### Java 21 — also works

Record patterns and exhaustive `switch` over sealed hierarchies execute correctly. The complete pipeline —libGDX 1.14.2 plus gdx-teavm plus TeaVM— **compiles** with bytecode 21 and produces an artifact of equivalent size.

### Decision: Java 17

17 is chosen on the criterion of sticking to what the runtime has proven, not to the newest:

- The whole spike was run in a real browser with bytecode 17. For 21, the compilation of the pipeline is verified, but not the execution of the complete game in a browser.
- 17 is the usual baseline of the libGDX ecosystem.
- What 21 adds over 17 is modest for this project: with `record`, `sealed` and `instanceof` pattern matching, almost everything the domain needs is already covered.

Both are LTS, so there is no urgency. Moving up to 21 later means changing two lines of the build, and we already know it compiles.

## What remains pending

Closed out on 26/08/2026 against the shipped MVP. Everything here was pending as of 18/08/2026.

- ~~Pointer capture for the relative mouse.~~ **Built and shipped**, using the browser's Pointer Lock
  API. It has a defect: losing the lock breaks mouse control until the page is refocused
  ([#41](https://github.com/LuchoC-Dev/little-spaceship/issues/41)).
- ~~Firefox, Edge and Safari.~~ **Chrome and Firefox verified by hand on 25/08/2026** against the live
  site. Edge was dropped by the project owner's decision; Safari is still unverified.
- ~~Audio behaviour under the browser's user interaction policy.~~ **Confirmed**: the first click
  unlocks audio, as the planned flow expected.
- ~~Measurement with definitive art and audio.~~ **Measured in phase 09**: the Pages artifact is
  2,470,942 bytes across 34 files, and the thirteen main files total ~1.4 MB as actually served,
  because the CDN gzips `app.js` from 1,027,585 to 302,393 bytes. The WAVs are served uncompressed
  and are the single largest remaining win — see `docs/STATUS.md`'s post-MVP backlog.
