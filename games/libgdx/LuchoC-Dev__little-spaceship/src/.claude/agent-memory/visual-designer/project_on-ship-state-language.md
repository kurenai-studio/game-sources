---
name: on-ship-state-language
description: What is actually drawn on the player ship for each state, which differs from 04-hud-layout.md, and which colours are therefore already spent
metadata:
  type: project
---

The states drawn **on the ship** are not what `04-hud-layout.md` describes, so check the renderer
before designing anything that sits near the hull.

**Why:** the document says the invulnerability power-up is a "`C1` aura ring, 21x21, 2-frame loop".
`game/adapter/render/WorldRenderer.java` (`drawAura`, around lines 270-279 on 02/09/2026) draws a
**1 px `C1` square outline, 21x21, static, behind the ship**, from four `batch.draw` calls on a
pixel texture. Ring vs square is exactly the distinction a new on-ship marker has to be designed
against, and taking the document's word would have got it wrong.

**How to apply:** the on-ship language as built is *respawn = alpha blink*, *damage absorbed = `N7`
tint*, *invulnerability = cyan square outline*, *shield = green segmented shell 21x23 (`fx-shield`,
added 02/09/2026)*. Two consequences:

- **Cyan is spent twice over near the hull** — it is the ship's own engine and fire in `ship-basic`
  *and* the aura. A cyan shape hugging the ship reads as the ship glowing, not as a thing around it.
- The free axes left for a further on-ship marker are hue outside cyan/green, and animation: every
  shape currently up there is static or a blink, so nothing yet owns a slow pulse or a rotation.

Related: [[palette-invariants]], [[hud-and-size-constraints]]
