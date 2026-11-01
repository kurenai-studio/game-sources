# Testing

Core runs three independent test suites: 

- unit tests
- architecture test
- integration tests

Each one checks something different and costs something different to run.

Unit tests check engine, config, parsing, and input classes in isolation. 
Most of the engine has no libGDX dependency by design, so
these run fast and never touch a real `Gdx` static.

Architecture test enforces the hot-path rules
described in [ARCHITECTURE.md](ARCHITECTURE.md).

Integration tests boot the real game and check what unit
tests can't reach on their own: asset loading, screen
construction, and the wiring between them.

## Integration tests

### Running tests

```
./gradlew :core:integrationTest
```

It's wired into `check` and CI alongside the unit and architecture suites.

### Writing tests

Annotate the test class with `@IntegrationTest`. When the test runs,
it will boot a fresh game before each test and tear it down afterward.

The harness exposes the running game and its input dispatchers, 
so a test scripts the player's actions directly instead of
faking mouse or keyboard events.

Screen transitions and asset loading happen on the headless application's 
own background loop, in real wall-clock time, not on the test thread. 

Awaitility should be used to wait game states rather 
than asserting immediately or sleeping a fixed amount.

### Notes

`gdx-backend-headless` runs libGDX without a window or GPU.
It mocks enough of `Gdx` to let a game boot, but it leaves
gaps a real game hits immediately:

- `Gdx.gl` is left unset, so any real texture or shader load crashes
- The window size always reports as zero, so layout code that reads it directly breaks

The test harness patches around both, installing a no-op GL stand-in
and a fixed window size before the game's startup code runs. Beyond
that, everything is real: the atlas, the fonts, the map, the shaders.

libGDX's `Gdx` statics are process-wide, so only one
headless application can safely run in the JVM at once.

The integration suite runs single-forked with JUnit's
parallel execution disabled, so tests never overlap.
