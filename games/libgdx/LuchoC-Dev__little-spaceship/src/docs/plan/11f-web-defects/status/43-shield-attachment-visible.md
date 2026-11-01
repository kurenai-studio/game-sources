# Issue #43 — the shield and the attachment are invisible

## What was already in the atlas, referenced by nothing

Confirmed by reading `assets/atlas/sprites.atlas` directly (not by trusting the issue body):
`module-satellite` (7x9), `icon-life` (9x9), `icon-bomb` (9x9), `icon-shield` (13x13), `icon-invuln`
(13x13) and `icon-module` (17x17) all exist, sized exactly to the slots `docs/design/04-hud-layout.md`
already specifies, and neither `HudRenderer` nor `WorldRenderer` referenced any of them before this
change. `docs/design/02-sprite-sizes.md` also already names the attachment as `module-*`, "one per
side, flanking", 7x9, no collider of its own — the shape existed, nothing drew it.

`core.domain.component.Attachment` confirmed to have no `Transform`/`Sprite` of its own: it is a
plain field on the player entity (`Attachment.id`, `Attachment.durability`), read by `DamageSystem`
and `PickupSystem`. There is no independent "attachment entity" `WorldView.forEachSprite` ever visits.
So "draw the attachment at its simulated position, following the ship" is satisfied by drawing
`module-satellite` at a fixed offset from the player's own live position on every frame the player
itself is drawn at — not a new position source, since none exists in `core`.

## What was wired, and where

**`game/.../adapter/render/HudRenderer.java`**
- Constructor now takes a `SpriteAtlas` (third parameter) and resolves `icon-life`, `icon-bomb`,
  `icon-shield`, `icon-invuln` and `icon-module` once, at construction.
- `drawLeftPlate` now draws those five icons where a filled state previously drew a flat rectangle
  (life slot, bomb slot, shield icon, invulnerability-power-up icon, module/attachment icon), tinted
  `N7` for the existing flash states via a batch colour multiply — the same tinting technique
  `WorldRenderer` already used for the damage flash and the boss tell, applied to a real region
  instead of a solid pixel this time.
- Every one of the five call sites falls back to the old rectangle+outline drawing whenever its
  region is `null` — i.e. when running against `PlaceholderAtlas`, which does not cover HUD glyphs.
  This mirrors `WorldRenderer`'s own missing-region tolerance for world sprites, so a checkout with
  no packed atlas still renders a legible HUD instead of throwing.
- The `POWER` segment is unchanged: no `icon-power` exists in the atlas, and `04-hud-layout.md`'s own
  table draws it as flat bars, not an icon — nothing to wire there.

**`game/.../adapter/render/WorldRenderer.java`**
- Added `ATTACHMENT_SPRITE_ID` (`"module-satellite"`, a plain constant like `PLAYER_SPRITE_ID`, built
  once rather than per frame) and `ATTACHMENT_OFFSET_X` (11 logical units).
- `accept()` now draws the satellite flanking the ship, on the right, whenever the entity being drawn
  is the player and `PlayerStatus.attachmentId()` is not empty — reusing that same call's `x`/`y`, so
  it tracks the ship automatically with no extra state to keep in sync.
- Missing-region handling matches the existing pattern: logged once via the same
  `missingSpritesLogged` set `accept()` itself uses, not once per frame.
- The shield itself was deliberately **not** given an on-ship sprite. `04-hud-layout.md`'s "Invulnerability
  is shown on the ship, not in the plate" is scoped to the three `InvulnerabilitySource` grace periods
  (respawn, damage, power-up) — the shield's own state (`shieldActive`) is documented as HUD-only, via
  the `STATE` plate's shield icon, which is now wired. Inventing an on-ship shield ring would be new
  visual direction the document does not ask for, and no shield-ring sprite exists in the atlas to draw
  instead of one — out of this task's scope per the plan's "new art is a conversation, not a decision
  to take alone".

**`game/.../screen/PlayScreen.java`**
- The one call site of `new HudRenderer(...)` updated to pass the already-loaded `atlas` (no new
  atlas load — `PlayScreen` already builds one for `WorldRenderer`).

## Nothing needed new art

Every id this change draws already existed in `assets/atlas/sprites.atlas` at the exact size
`docs/design/04-hud-layout.md`/`02-sprite-sizes.md` specify. No `visual-designer` conversation was
needed.

## Verified

- `./gradlew :game:compileJava :desktop:compileJava :web:compileJava -q` — no output, all three
  compile.
- One desktop launch (`./gradlew :desktop:run`), foregrounded and screenshotted on this Windows
  machine: the window opens and the main menu renders correctly (title, PLAY/OPTIONS/QUIT). Stopped
  there per the project owner's correction mid-task — **playing the build to reach a wave, beat 11 or
  the shield/attachment pickups is the project owner's job, not this agent's**, and everything past
  "it starts and the menu renders" is not checked by this branch.
- `git status --porcelain` shows only the three files above changed; a temporary edit made to
  `assets/data/waves.json` to force an early shield/attachment drop for local verification was fully
  reverted before this fragment was written (`git diff assets/data/waves.json` is empty) — that file
  is level-designer's, not this agent's to touch even temporarily once the correction landed.

## Not checked

- The shield icon, the invulnerability icon, the life/bomb icons and the module icon actually
  appearing on screen at runtime, at the right position, in the right size, with the right flash
  colour. Only read against the code and the atlas' own recorded region sizes (which match the
  design document's table exactly), not observed live.
- The attachment satellite actually following the ship on screen, or its 11 px flank offset reading
  as clear of the ship's silhouette rather than overlapping it, at runtime.
- The N7 flash tint on a real sprite region reading correctly rather than washing it out — verified
  only by code inspection of the same tinting technique already used elsewhere in `WorldRenderer`.
- Any of this in a real browser (Chrome/Firefox) on the deployed web build. Only `:web:compileJava`
  was run.
- Whether `enemy-carrier`'s single designed attachment drop on `l1-twin-carriers-attachment` (beat 11)
  is reachable in reasonable play time; not attempted.

## Steps for the project owner to see this

1. `./gradlew :desktop:run` (or the deployed web build), Play, pick a ship, Launch.
2. **Shield/HUD icons**: pick up any `weapon-upgrade` pickup and take damage to see the life-slot icon
   and its N7 flash; the shield icon only appears if a `"drop": "shield"` pickup is collected —
   `assets/data/level-01.json`'s current wave list has no shield drop in it at all (confirmed by
   `grep -n '"drop"' assets/data/waves.json` — the only kinds present are `attachment`,
   `bomb-recharge`, `extra-life`, `weapon-upgrade`), so the shield pickup is not currently reachable in
   level 1 as authored; that is a `level-designer`/content gap, not something this branch can fix
   without touching `assets/data/`.
3. **Attachment**: level 1's wave `l1-twin-carriers-attachment` (beat 11, roughly 8-9 minutes into the
   level per `assets/data/level-01.json`'s wave offsets) spawns `enemy-carrier` in a `pair` formation
   with `"drop": "attachment"` on `dropSlot": 0`. Destroy that carrier slot and collect the capsule;
   the `MODULE` plate should show the `icon-module` glyph and a `module-satellite` sprite should
   appear flanking the ship's right side and follow it. If it does not depend on beat 11 timing, the
   same fastest local-verification trick used and reverted here — a temporary
   `"drop": "attachment"` added to an early wave in a scratch copy of `assets/data/waves.json`, run,
   observed, then discarded with `git checkout -- assets/data/waves.json` — is the quickest way to
   reach it without playing 8+ minutes of level 1 for real.
