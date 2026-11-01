# Platform and technical validation

## Decision status

**Resolved on 18/08/2026.** The technical prototype was run and the web option was approved: `Java + libGDX + Gradle + gdx-teavm`, with desktop sharing the same core. Gradle definitively replaces Maven.

The results, the final traffic light and what remains pending are in `11-technical-prototype-results.md`. The rest of this document is kept as a record of the reasoning prior to the measurement.

## Technical requirements derived from the product

- 2D rendering with sprites and pixel-art.
- Many enemies, projectiles and particles.
- Precise movement and collisions.
- Keyboard and mouse.
- Music, effects and track changes at runtime.
- Menus, HUD and overlays.
- Asset loading and a loading screen.
- Logical resolution and scaling.
- Reasonable debugging from Java.
- Reproducible and publishable build.
- The ability to add targets without coupling the core to a single one.

## Demonstrable portfolio goals

The project must exhibit, all together:

- modular architecture and justified decisions;
- relevant automated testing;
- continuous integration;
- performance measurement and care;
- technical and product documentation;
- artistic and audiovisual finish;
- a reproducible publication and deployment process.

The repository will be private during initial development. Opening it will be reconsidered upon reaching the MVP or on finishing the product. *(Resolved on 25/08/2026: made public on shipping the MVP.)*

## Language and build tool

### Java

Java is a decision about the identity and goal of the project, not an accidental constraint. It remains the main language.

### Maven → provisional Gradle

Maven was the initial preference. Later research indicated that:

- TeaVM has Maven integration;
- libGDX can be used with Maven, especially on desktop;
- the multiplatform flow of libGDX and gdx-teavm is oriented towards Gradle;
- insisting on Maven for that stack would increase manual integration and risk.

Therefore, for the web candidate, the provisional recommendation is **Gradle**. It is not a final choice until the stack is validated.

## Main candidate

**Java + libGDX + Gradle + gdx-teavm → browser**

With a shared core and a possible desktop target.

### Reasons

- libGDX covers 2D rendering, input, audio, UI, assets, cameras and viewports.
- gdx-teavm allows compiling the web project to JavaScript or WebAssembly.
- A local, purely client-side game can be hosted as a static site.
- For a portfolio, “open a link and play” greatly reduces friction.
- The same core can keep a desktop output.

## Hosting

Earlier research considered free options viable for a static build:

- GitHub Pages.
- Cloudflare Pages.
- Vercel.

Hosting is not considered the main risk. The risk lies in compatibility, tooling, build size, debugging and dependencies.

## Risks and constraints

### TeaVM compatibility

TeaVM does not run a full JVM in the browser. It must not be assumed that any dependency from Maven Central will work.

Check especially:

- JVM/desktop-specific APIs;
- JNI or native code;
- direct filesystem access;
- complex reflection;
- incompatible threading;
- libraries relying on capabilities not available on the web.

Proposed rule: every additional dependency must be evaluated both for licence and for TeaVM compatibility.

### Additional backend

gdx-teavm is a project separate from the official libGDX core. Although it was assessed as active and capable of generating JavaScript/Wasm, it adds a technological dependency and extra risk compared with pure desktop.

### Performance

The stack seems appropriate, but performance with high entity and effect density must be measured before closing the decision.

### Browser compatibility

Verify Chrome, Firefox, Edge and Safari within a reasonable scope. Also review audio formats and input/focus behaviour.

## Technical decision prototype

Before implementing the MVP, create a throwaway test that validates infrastructure only:

- massive rendering of sprites/projectiles;
- collisions or updating many entities;
- keyboard and mouse, including their simultaneous and additive use;
- pointer capture (Pointer Lock) for the relative mouse;
- audio, effects and music change;
- loading of textures/atlases/fonts/sounds;
- basic UI/HUD;
- logical resolution and pixel-art scaling;
- JavaScript web build;
- WebAssembly web build if available;
- load times/size;
- source maps and useful stack traces;
- desktop execution from the same core;
- compatibility in the target browsers.

## Choice criteria

Choose web if:

- the test reaches stable performance with headroom;
- the build and debugging flow is reasonable;
- assets and audio work consistently;
- the constraints do not dictate the game design;
- the cost of maintaining web + desktop is acceptable.

Move to desktop if:

- TeaVM constraints affect gameplay or architecture;
- debugging or the build turn out to be fragile;
- performance/compatibility falls short;
- maintaining the web target consumes disproportionate effort.

## Architectural principles already stated

They are not yet a class or module design, but they must guide the future architecture:

- composition over inheritance;
- dependency injection;
- events when they bring real decoupling;
- separation between game logic and platform adapters;
- configurable content so balancing does not require rewriting systems;
- patterns, trajectories, formations and drops decoupled from the enemy archetype;
- avoid implementing an in-house UI framework;
- avoid future abstractions without a real MVP case.

## Alternatives kept on record

### libGDX desktop

The technically most direct path, with a full JVM and fewer constraints. Downside: it requires a download and adds friction to the portfolio.

### Web with JS/TS

More natural for the browser, but it contradicts the desire to keep Java at the core. It was left in the background.

### Other Java frameworks

FXGL was mentioned as an alternative with an affinity for Maven and 2D. It was not selected nor validated at the same level as libGDX + gdx-teavm.
