---
name: skin-add-drawable-lookup-mismatch
description: scene2d Skin.add(name, resource) stores under the resource's runtime class, but Skin.getDrawable(name) looks it up under the Drawable interface — an implicit add is invisible to it
metadata:
  type: project
---

`com.badlogic.gdx.scenes.scene2d.ui.Skin.add(String, Object)` files the resource under
`resource.getClass()` in its internal type-keyed map. `Skin.getDrawable(name)` (and every style
field a `.json` skin populates through it) looks the resource up under the `Drawable` interface
specifically. A `NinePatchDrawable`, `TextureRegionDrawable` etc. added the implicit way is
therefore invisible to `getDrawable` — it compiles and adds without error, and only throws
`GdxRuntimeException: No Drawable, NinePatch, TextureRegion, Texture, or Sprite registered with
name: X` the moment something reads it, e.g. `new TextButtonStyle().up = skin.getDrawable("x")`.

That delay between the mistake and the failure is what cost the time — the constructor call that
threw wasn't the line that was wrong.

**Fix:** use the explicit 3-arg overload, `skin.add(name, resource, Drawable.class)`, for any
`Drawable` implementation built in code rather than loaded from a `.json` skin file.

Where this showed up: `game/src/main/java/dev/luchoc/littlespaceship/game/ui/GameSkin.java`,
building panel backgrounds as `NinePatchDrawable` in phase 06's screen integration
(`docs/plan/06-presentation/`, tasks 12-14).
