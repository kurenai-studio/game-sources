# little-spaceship

A vertical shoot 'em up built from scratch in Java: pixel-art, single-player, one level. It runs
on [libGDX](https://libgdx.com/) and ships to the browser through [TeaVM](https://teavm.org/), with
a desktop target sharing the same simulation core. It is a portfolio piece, so architecture, tests,
CI, documentation and deployment count as part of the deliverable, not just a game that runs.

It is not a remake. No code or assets from any earlier project were reused; the only thing carried
over is the fantasy — piloting a ship against threats that come from above.

## Play it

**<https://luchoc-dev.github.io/little-spaceship/>**

Nothing to install. Verified by hand in Chrome and Firefox on Windows; other modern desktop
browsers are expected to work but have not been checked. Click once to start audio and capture the
mouse — browsers require a user gesture before either will work.

## Controls

| Action | Keyboard | Mouse (optional) |
|---|---|---|
| Move | Arrow keys | Cursor movement, relative — the ship follows displacement, not the pointer's position |
| Fire | Space | Left button |
| Bomb / special | X | Right button |
| Slow / precise movement | Shift | — |

Keyboard and mouse are additive: with the mouse enabled, both contribute a movement vector at once
and opposite inputs cancel out rather than one device overriding the other. The mouse can be turned
off from the Options screen. Gamepad and touch are not implemented.

The mouse is relative and needs the pointer captured to keep producing movement past the window
edge; clicking captures it, Escape releases it. This uses the browser's Pointer Lock API on the web
build.

## Running it locally

Requires a JDK 17 and the bundled Gradle wrapper — no local Gradle install needed.

### Desktop

```
./gradlew desktop:run
```

Launches the game in an LWJGL3 window at the fixed logical resolution, integer-scaled with
letterboxing.

### Web

```
./gradlew web:gdx_teavm_web_js_run
```

Compiles the TeaVM/JavaScript build and serves it at **<http://localhost:8080>**. Open that URL in
a real browser — headless browsers cannot run the WebGL context this needs.

A production build (minified, no source maps) is produced with:

```
./gradlew web:gdx_teavm_web_js_build -Prelease
```

which writes the static site to `web/build/dist/js/webapp/`, the same output GitHub Pages serves.

## Building and testing

```
./gradlew build
```

Compiles every module, assembles the desktop and web jars, and runs the full test suite — 289
tests, all in `core`, with no libGDX on that module's classpath (see below). `game`, `desktop` and
`web` have no tests yet; that is an open item, not an oversight.

CI runs this same build plus the TeaVM web build on every push and on every pull request against
`main`, on a JDK 17 runner (Ubuntu). It proves the code compiles and the tests pass; it does not
prove the web build runs in a browser. Headless Chrome under SwiftShader fails to validate this
project's WebGL context even when a real browser works fine, so that check stays manual, in a real
browser, every time. See `.github/workflows/ci.yml`.

## Architecture

```
little-spaceship/
  core/        Pure Java. ECS, systems, game rules. No libGDX — not even its math.
  game/        libGDX. Rendering, HUD, audio, input, screens.
  desktop/     LWJGL3 launcher, sharing game/ and core/ as-is.
  web/         TeaVM launcher, same core and game, compiled to JavaScript.
  assets/      Content as JSON, sprites, fonts and audio — read without reflection.
```

Dependencies point one way only: `desktop` and `web` depend on `game`, which depends on `core`.
`core` never imports libGDX, and `game` never touches the ECS directly — it reads the world through
a read-only `WorldView`.

A few decisions are load-bearing enough to be worth stating here rather than only in code:

- **Deterministic simulation.** The core runs a fixed step (1/60 s), takes an immutable
  `InputFrame` per tick, and draws randomness from a seeded `Rng`. It never reads the system clock
  and never calls `Math.random()`. This is what makes recorded replays reproducible, and breaking it
  fails silently rather than throwing.
- **Single-threaded, on purpose, not by default.** The web target has no real parallelism —
  TeaVM has no `ExecutorService`, `CompletableFuture` or `ReentrantLock`, and using any of them
  breaks the build — and simulation cost is small enough against drawing that concurrency would not
  pay for itself even on desktop.
- **Fixed system execution order.** The order systems run in is part of the game's rules, not an
  implementation detail left to convenience.
- **No abstraction without a concrete case in the MVP.** The codebase is intentionally smaller than
  a "proper engine" would be.

The reasoning behind each of these, and the platform validation that grounds them, is in
`CLAUDE.md` (the invariants and the web-target pitfalls) and `docs/planning/` (the full design and
technical record, including `11-technical-prototype-results.md`, where the platform choices were
measured rather than assumed).

## Status

This is a shipped MVP, not a finished game: one level, one ship, one boss. `docs/STATUS.md` keeps
an honest account of what is done and what is deliberately left for later — among other things, a
sustained-fire audio glitch, an occasional frame-rate dip, and an unencoded music track that makes
the download heavier than it needs to be. None of it blocks playing the level.

## License

[MIT](LICENSE). The licence covers the whole repository, art and audio included.
