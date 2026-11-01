# 236 — draw the shield shell

`game-presentation`, 02/09/2026, branch `feat/draw-shield-ring`.

Closes [#236](https://github.com/LuchoC-Dev/little-spaceship/issues/236). The art and specification
landed in [#235](https://github.com/LuchoC-Dev/little-spaceship/issues/235)'s
`docs/plan/11g-shield-and-test-harness/status/236-shield-ring-sprite.md`; this is the wiring that
fragment named as the remaining half.

## How the shield state already crossed the boundary

`core.port.PlayerStatus.shieldActive()` already exists and already crosses `WorldView`/`draw()`:
`WorldRenderer.draw(WorldView, SpriteBatch, PlayerStatus)` stores the snapshot in
`this.playerStatus` every frame, and `HudRenderer` reads the same field to light `icon-shield`. No
new channel was needed — `WorldRenderer.accept` already had `playerStatus` in scope for the
existing invulnerability-source branches, so reading `playerStatus.shieldActive()` there is the same
pattern `drawAttachment` already uses for `attachmentId()`.

## What changed

`game/src/main/java/dev/luchoc/littlespaceship/game/adapter/render/WorldRenderer.java`:

- Added `SHIELD_SPRITE_ID = new SpriteId("fx-shield")`, a plain constant like `PLAYER_SPRITE_ID` and
  `ATTACHMENT_SPRITE_ID`.
- Added `drawShield(float, float)`, modelled directly on `drawAttachment`: resolves the region from
  `atlas`, skips silently (logging once through the existing `missingSpritesLogged` set) if the
  region is absent, and draws it centred on the given position with no tint, no alpha, no offset.
- In `accept`, inserted `if (isPlayer && playerStatus.shieldActive()) { drawShield(logicalX, y); }`
  directly after the existing `if (source == InvulnerabilitySource.POWERUP) { drawAura(...); }`
  block and before the ship's own `batch.draw` call. That ordering is what puts the shell behind
  `ship-basic` (drawn afterwards) and in front of the aura (drawn beforehand, when both are up) —
  the exact order the handoff specified.

No `core` change. Nothing new imported beyond what `WorldRenderer` already imports.

## Was the specified draw order implementable as given?

Yes, without any friction. `accept` already draws the aura before the ship sprite in the same
method, so inserting the shield draw between those two calls produces "behind ship-basic, in front
of the aura" for free — no reordering of existing code, no new state needed to remember "did I
already draw the ship this frame".

## Steps for the project owner

1. Launch level 1 and let it run to **37.0 s**.
2. Watch the **middle slot of `line-3`** in the `l1-combined-formations` wave — three `enemy-basic`
   entering left of centre, spanning x 37..88 — and kill the **middle** one.
3. Collect the capsule it drops.
4. **Expected**: a thin green rounded shell appears around the ship immediately, hugging the hull
   (21x23, taller than wide), staying centred on the ship as it moves. `icon-shield` should already
   be lit in the HUD `STATE` block, as before — that part did not change.
5. Take a hit. **Expected**: the shell disappears on that same frame — no fade, no partial shell —
   while the ship plays its existing "damage absorbed" white flash (`04-hud-layout.md`'s 1.0 s tint)
   and the HUD's shield-lost flash/hide sequence, both of which existed before this change.

## Verified

- `./gradlew :game:compileJava -q` — no output, compiles clean.
- `./gradlew build -q` — no output, no failures.
- `./gradlew web:gdx_teavm_web_js_build -q` — completed; the asset-copy log shows
  `assets/atlas/sprites.atlas` (4112 bytes) and `assets/atlas/sprites.png` (2247 bytes) — the same
  regenerated atlas from #235's branch, carrying `fx-shield` — copied into
  `web/build/dist/js/webapp/assets`.
- `assets/atlas/sprites.atlas` region for `fx-shield`: `size: 21, 23`, matching the handoff exactly.
- `./gradlew :desktop:run -q`, run to a 20 s timeout and killed — no exception, and no "no
  placeholder region for sprite id" log line (which `drawShield` would print if `fx-shield` failed
  to resolve), meaning the atlas lookup succeeds. Per `how-to-run-a-phase.md`'s "Running the game is
  not playing it", this only confirms the process starts; the run was not steered toward the shield
  drop.

## Not checked

- How the shell reads **in motion**, in play, against a moving level-1 background, or its actual
  colour/legibility on screen — no screenshot was taken and the game was not played. Reserved for
  the project owner per the rule above.
- The menu **rendering** on screen — the desktop process started and exited cleanly on timeout with
  no exception logged, but no window was screenshotted to confirm what is drawn.
- The web target running in a real browser — only the TeaVM build compiling was verified.
- Whether the shield and the invulnerability aura are visually distinguishable together in an actual
  play session — `visual-designer`'s fragment reports this was rendered and looked at in a scratch
  script during art authoring, but that observation is theirs, not reproduced here.
