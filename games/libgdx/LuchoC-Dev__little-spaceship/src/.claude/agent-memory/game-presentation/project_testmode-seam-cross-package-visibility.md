---
name: testmode-seam-cross-package-visibility
description: extending the TestMode stub/real seam to answer a caller outside game.screen forces the whole class public, not just the new method
metadata:
  type: project
---

Issue #250 (11h task 4) extended the `TestMode` seam (`game/src/tests/java` vs.
`game/src/teststub/java`, both defining `dev.luchoc.littlespaceship.game.screen.TestMode`) with a
second static method, `startScreen(LittleSpaceshipGame)`, so `LittleSpaceshipGame.create()` could
ask it what to boot into instead of always constructing `MenuScreen` itself. See
[[hud-icon-wiring-and-satellite-with-no-core-entity]] and
[[worldrenderer-accept-ordering-decides-draw-order]] for two earlier instances of this same
stub/real or boolean-driven-branch shape elsewhere in the codebase.

The original `TestMode` (from #244) was package-private — fine, because its only caller,
`MenuScreen.addMenuEntry(...)`, lives in the same `game.screen` package. `LittleSpaceshipGame`
lives in `game`, one package up, so calling any method on `TestMode` from there requires the
*class itself* to be `public`, not just the new method. Java's package-private visibility blocks
the type reference entirely — `import dev.luchoc.littlespaceship.game.screen.TestMode;` does not
compile against a package-private class from outside its package, regardless of the called
method's own modifier.

`addMenuEntry` itself stayed package-private after this change — no correctness reason to widen a
method nobody outside the package calls, only the class declaration needed `public final class
TestMode` instead of `final class TestMode`. Worth checking, the next time this seam grows a third
hook: whether the new caller is in `game.screen` (method-level visibility is enough) or elsewhere
(the class has to be public, and each variant's javadoc should say so, since the stub and the real
class must independently declare it identically or the mutually-exclusive-source-set trick breaks
with an "incompatible types" style error at the call site instead of a clean absence).
