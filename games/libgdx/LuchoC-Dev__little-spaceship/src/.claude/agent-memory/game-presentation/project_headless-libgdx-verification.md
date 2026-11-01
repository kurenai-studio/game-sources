---
name: headless-libgdx-verification
description: How to exercise real libGDX-dependent game code (JsonContentSource, InputAdapter) without a display, LWJGL, or an Application context
metadata:
  type: project
---

Verified two pieces of production code end to end in a session with no display, no GPU, and no
running `Application` — worth keeping since "cannot verify without a display" was this project's
default excuse for anything touching libGDX, and it turned out narrower than assumed.

**Content loading needs no `Gdx.app` at all.** `com.badlogic.gdx.files.FileHandle` has a public
constructor taking a plain `java.io.File`. `JsonReader.parse(FileHandle)` just opens a stream through
it. A `ContentSource` implementation built this way (`new FileHandle(new File(path))`) runs identically
outside any libGDX backend — compiled and ran a throwaway `main()` against the real `JsonContentSource`
class with `java -cp core.jar;game.jar;gdx.jar`, no `Application`, no window.

**Input code needs `Gdx.input`/`Gdx.graphics`, but both are just public static fields of interface
type — assignable directly.** `java.lang.reflect.Proxy.newProxyInstance` against `Input.class` /
`Graphics.class` stands in for the backend, answering only the methods actually called
(`isKeyPressed`, `getDeltaX`, `getWidth`) and a sane default (false/0/null by return type) for
everything else. None of the methods `InputAdapter` touches reach native code, so this works without
LWJGL on the classpath at all. This let the real `InputAdapter.sample()` be called with a scripted
keyboard+mouse state and its `InputFrame` output asserted on — proof the summing/cancelling logic
works, not just that it reads correctly.

**How to apply:** before writing off an acceptance criterion as "needs a display, cannot verify," check
whether the actual behaviour in question is reachable through pure logic plus a couple of interface
methods. Rendering genuinely needs a display (`SpriteBatch`/`Texture` want a GL context); reading
input and reading content generally do not.

**Neither program was committed** — thrown together in the session scratch directory, not the repo.
`test-engineer` owns turning this into a real test if it's worth keeping; the dynamic-proxy trick for
`Input`/`Graphics` is the reusable part.

See [[transform-coordinate-space]], the bug this same verification pass caught while proving the
world was non-empty.
