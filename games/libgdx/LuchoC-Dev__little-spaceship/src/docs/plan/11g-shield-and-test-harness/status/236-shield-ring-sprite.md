# 236 — the shield shell sprite

`visual-designer`, 02/09/2026, branch `feat/shield-ring-sprite`.

Refs [#236](https://github.com/LuchoC-Dev/little-spaceship/issues/236). It does **not** close it:
this is the art and the specification, and nothing draws `fx-shield` yet.

## What the owner decided, and what this branch decided

The owner played level 1 on 02/09/2026, found `icon-shield` lit in the HUD with nothing on the ship,
and chose a ring around the ship over two refused alternatives. That overrules
`docs/design/04-hud-layout.md`'s "Invulnerability is shown on the ship, not in the plate", which
listed exactly three ship-shown states and deliberately excluded an active shield.

What was left to decide here was the ring itself.

| | Decision |
|---|---|
| Id | `fx-shield` |
| Size | 21x23 — 3 px of clearance on all four sides of the 15x17 `ship-basic` |
| Colour | `G3` across each plate, `G2` on the two pixels running into a seam. No `N0` outline |
| Shape | rounded shell in four plates, one seam on each diagonal |
| Animation | none, one static frame |

**No `N0` outline** is a deliberate cost: an outlined shell would be 3 px thick and start eating the
space the player reads bullets in. The shell is therefore thin, and against a bright late-campaign
background it will lean on `G3` alone. If it ever stops reading there, the fix is a darker inner
pixel, not a black one — there is no dark gameplay colour below `V4`.

## How it stays distinct from the invulnerability flash

This was the stated risk. The comparison is against what is actually drawn, not against the
document: `game/adapter/render/WorldRenderer.java:270-279` draws the power-up aura as a **1 px `C1`
square outline, 21x21, behind the ship**, from four `batch.draw` calls on a pixel texture. The other
two grace periods are an alpha blink (respawn) and an `N7` tint (damage absorbed) — both are changes
*to the ship*, and neither adds a shape around it, so only the aura can be confused with this.

Three axes separate them at once, and the player has to remember none of them:

- **shape** — rounded and segmented against a hard square;
- **colour** — green against cyan. Cyan was already spent twice: it is the ship's own engine and
  fire (`ship-basic` uses `c`/`C`), and it is the aura. A cyan shell hugging the hull would read as
  the ship glowing rather than as a second thing around it;
- **proportion** — 21x23, taller than wide, following the hull, against a 21x21 square.

Green is defensible beyond "it is not cyan": it is the colour of the capsule that granted it
(`pickup-shield`'s shell is `G2`/`G3`), no enemy fire can be green because hostile fire owns hues
320-350 campaign-wide, and no background may hold `G2` or `G3` at all.

Both can be on screen together — shield up *and* the invulnerability power-up. That case was
rendered and looked at before committing, not reasoned about.

## Handoff to `game-presentation`

Everything the wiring needs:

- **Region** `fx-shield` in `assets/atlas/sprites.png`, 21x23. It is a real region, not an alias.
- **Position** centred on the player's `Transform`, no offset — the same rule as every other sprite,
  and unlike `module-satellite`'s ±7 px flank.
- **Draw order** behind `ship-basic` and in front of the `C1` aura, so that when both are up the
  ship stays the brightest thing and the two shapes stay separate.
- **No animation, no tint, no alpha.** One static frame, drawn at full opacity.
- **Lifetime** exactly while the shield is present. `core/domain/component/Shield.java` is a bare
  marker with no durability and `core/domain/system/DamageSystem.java` removes it in one hit, so
  there is nothing partial to draw and nothing to fade.
- Whether the shell is visible must come through the existing read-only boundary, the way
  `WorldRenderer` already reads `playerStatus`. **No new `core` state.**

## Findings, reported and not acted on

- **`04-hud-layout.md` and `WorldRenderer` disagree about the aura.** The document says "`C1` aura
  ring, 21x21, **2-frame loop**"; `WorldRenderer.drawAura` draws one static square outline with no
  loop. Left alone: the invulnerability states are explicitly out of scope for #236.
- **The HUD codes shield as cyan and this shell is green.** `icon-shield` in
  `docs/design/mockups/src/01-sprites.js` is drawn in `C1`, while `icon-invuln` is `W4`/`F1` amber —
  so the plate already codes the two states apart, and it codes shield with the one colour the
  playfield could not use for it. Not changed: recolouring a HUD icon changes what the owner has
  been looking at all phase, and legibility in the playfield outranks colour agreement with a
  margin. Worth raising with the owner if it ever reads as an inconsistency.

## Verified

- `node docs/design/mockups/check.js` — `pass 35 sprites match their declared size, characters and
  odd dimensions`, all scene, screen and page checks pass, exit 0.
- `node docs/design/atlas/build-atlas.js` — `sprites.png - 132x163, 35 sprites` /
  `sprites.atlas - 35 regions + 6 aliases`. The page grew from 128x163 to 132x163 and 34 to 35
  sprites; the shelf packer moved existing regions, which is why the `.atlas` diff is large. Both
  files are regenerated, never hand-edited.
- The shell was **rendered and looked at** at 1x, 3x and 6x on an `N2` ground, in four cells: ship
  alone, ship + shell, ship + aura, ship + both. It reads as a green shell at 1x and does not
  collide with the aura. The script is a scratch throwaway and is not committed.
- `./gradlew :desktop:run` started and ran until it was killed at the timeout, with no exception and
  no missing-sprite warning — so the regenerated atlas still loads.

## Not checked

- How the shell reads **in motion**, in play, against a moving level-1 background. Nobody but the
  project owner can check that, by the rule that running the game is not playing it.
- The menu **rendering** on screen. The process started clean; no window was looked at.
- The web target.
