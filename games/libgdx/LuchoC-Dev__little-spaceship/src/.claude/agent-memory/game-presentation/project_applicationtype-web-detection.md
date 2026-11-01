---
name: applicationtype-web-detection
description: how to detect the web target from game code, and what "confirmed under TeaVM" honestly means for it
metadata:
  type: project
---

`Gdx.app.getType() == ApplicationType.WebGL` is libGDX's own way to ask which platform is running,
and as of phase 11f (#40, QUIT's web-only farewell screen) it was not used anywhere in this codebase
before — a repo-wide grep for `ApplicationType` across `game`/`desktop`/`web` came back empty first.

**What "confirmed under TeaVM" meant here, honestly**: `./gradlew :web:gdx_teavm_web_js_build`
transpiled clean with the branching code in place and produced a populated
`web/build/dist/js/webapp/`. That proves TeaVM accepts `Gdx.app.getType()` and the `ApplicationType`
enum at compile/transpile time. It does **not** prove the running build actually takes the WebGL
branch — that needs a real browser loading the deployed page and clicking through to the branch's
visible effect (see [[feedback_agent-must-not-play-the-game-to-verify]] for why this agent stopped at
"the menu renders" rather than clicking further). Recorded as "not checked" in the PR rather than
inferred from the successful transpile.
