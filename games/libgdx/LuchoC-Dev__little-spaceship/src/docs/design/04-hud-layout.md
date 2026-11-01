# HUD layout

Every coordinate here is a pixel at the logical resolution of 480x270, and every one of them is
fixed. There is no responsive layout: the logical resolution never changes, only the integer factor
it is scaled by.

## Coordinates

Positions are given **y-down from the top-left corner**, because that is how a panel is read.
libGDX draws y-up, so the renderer converts once, on the way out:

```
y_gdx = 270 - y_down - height
```

Doing it anywhere else is how a HUD ends up half-flipped.

## The three regions

```
 x:0            135 136                      343 344            479
   +--------------+--+--------------------------+--+--------------+  y:0
   |              |  |                          |  |              |
   |  LEFT PLATE  |r |        PLAYFIELD         |r |  RIGHT PLATE |
   |  player      |u |        208 x 270         |u |  score       |
   |  state       |l |                          |l |  and threat  |
   |              |e |                          |e |  boss bar    |
   |              |  |                          |  |              |
   +--------------+--+--------------------------+--+--------------+  y:269
        136 px                  208 px                 136 px
```

| Region | x range | Fill |
|---|---|---|
| Left plate | 0-134 | `N2` |
| Left rule | 135 | `N3`, 1 px |
| Playfield | 136-343 | the level |
| Right rule | 344 | `N3`, 1 px |
| Right plate | 345-479 | `N2` |

The two rules are the playfield's only frame. They also carry the damage feedback, which is why
nothing else is allowed to touch them.

**Content columns are 106 px wide:** `x 12-117` on the left, `x 362-467` on the right. That is 17
characters of `font-mini` or 13 of `font-title`. Every label in this document fits.

## Left plate — player state

| Block | Element | Position | Size |
|---|---|---|---|
| Lives | label `LIVES` | 12, 14 | `font-mini`, `N4` |
| | 5 slots, pitch 12 | 12, 24 | 9x9 each, ends at x 68 |
| Bombs | label `BOMBS` | 12, 44 | `font-mini`, `N4` |
| | 3 slots, pitch 12 | 12, 54 | 9x9 each, ends at x 44 |
| Power | label `POWER` | 12, 74 | `font-mini`, `N4` |
| | 4 segments, pitch 15 | 12, 84 | 13x7 each, ends at x 69 |
| State | label `STATE` | 12, 104 | `font-mini`, `N4` |
| | shield icon | 12, 114 | 13x13 |
| | invulnerability icon | 28, 114 | 13x13 |
| | invulnerability timer | 28, 128 | 13x1 |
| Module | label `MODULE` | 12, 146 | `font-mini`, `N4` |
| | attachment icon | 12, 156 | 17x17 |
| | attachment name | 34, 161 | `font-mini`, `N7`, 13 chars max |

Below y 178 the plate carries decoration and **no information**. That space is the Skin's, and
anything informative that appears there is a defect.

### What each slot looks like

**Specified, not drawn.** `HudRenderer` draws all six as flat rectangles at these coordinates and in
these colours — the geometry, the flashes and the tick counts below are all built and correct, the
*iconography* is not. The five `icon-*` sprites exist in `assets/atlas/sprites.atlas` and nothing
references them. Recorded 26/08/2026; the work belongs to the 11 group, not to this page.

| Element | Filled | Empty |
|---|---|---|
| Life slot | ship silhouette, `N6` body, `C1` engine | `N3` outline only |
| Bomb slot | `W4` core inside an `N6` ring | `N3` outline only |
| Power segment | `C1` body, `C2` top row | `N2` body, `N3` outline |
| Shield icon | arc in `N6` over `C1` | not drawn |
| Invulnerability icon | burst in `W4` over `F1` | not drawn |
| Invulnerability timer | `F1`, shrinking from the right | `N2` |

Five life slots and three bomb slots are always drawn, filled or empty, because they are the caps
from `../planning/10-mvp-initial-values.md` and a player who sees three empty slots understands
there is something to collect. Shield, invulnerability and the whole `MODULE` block appear only
while held: the spec asks for the attachment *if any*, and an empty frame would be the HUD saying
more than it was asked to.

## Right plate — score and threat

| Element | Position | Notes |
|---|---|---|
| label `SCORE` | 362, 14 | `font-mini`, `N4` |
| score value | right edge at 467, top 24 | `font-title`, `N7`, 7 digits, zero-padded |
| label `BOSS` | 362, 44 | `font-mini`, `N4`, only during the fight |
| boss bar frame | 347, 20 | 8x230, 1 px `N0` outline |
| boss bar fill | 348, 21 | 6x228 inner area |

The score is zero-padded — `0012500` — so the field never changes width and nothing beside it
moves.

### The boss bar is vertical, and in the margin

The bar runs down the inner edge of the right plate, next to the playfield. It is anchored at the
top and shortens downward as the boss takes damage. Filled rows are
`round(228 * hp / hpMax)`, drawn in `W4` with a 1 px `W3` column on its right edge; the remainder
is `N2`. Rows lost in a single hit flash `N7` for 2 ticks before going dark.

The obvious alternative — a horizontal bar across the top of the playfield — was rejected. The
playfield is only 208 px wide, and a bar there would cover 208 px of play space at exactly the
moment projectile density peaks. A vertical bar sits in margin that is otherwise empty, stays
adjacent to a boss that enters from the top, and costs the player nothing.

## Invulnerability is shown on the ship, not in the plate

~~This section once said that the *only* player states shown on the ship are the three grace
periods below, and that "a shield is currently active" is shown in the left plate's `STATE` block
and nowhere else.~~ **Overruled by the project owner on 02/09/2026, after playing** ([#236](https://github.com/LuchoC-Dev/little-spaceship/issues/236)):
a shield that is up is now drawn on the ship as well, see *An active shield is drawn on the ship*
below. The rest of this section is unchanged and still holds — the three grace periods stay
ship-shown, and nothing else moved into the playfield.

Grace frames last one or two seconds. A widget that appears and disappears that fast in the corner
of the eye is noise, and the player is looking at their ship anyway.

| Source | Duration | How it reads |
|---|---|---|
| Respawn | 2.0 s, 120 ticks | ship alternates 4 ticks drawn, 4 ticks at alpha 0.35 |
| Damage absorbed by shield or attachment | 1.0 s, 60 ticks | ship alternates 3 ticks tinted `N7`, 3 ticks normal |
| Invulnerability power-up | its own duration | `C1` aura ring, 21x21, 2-frame loop, plus the `STATE` icon and its timer |

The three are deliberately different. Respawn blinks out, absorbed damage flashes white, the
power-up glows steadily — so the player can tell "I just got hit" from "I am currently untouchable"
without reading anything.

Alpha is a batch tint applied at draw time. It is not a colour in the sprite and it does not exist
in the palette.

## An active shield is drawn on the ship

The `STATE` block still lists the shield, and that does not change. What changed is that the plate
was the *only* place it appeared: the player collected a shield, an icon lit in a margin they were
not looking at, and the ship they were looking at was identical to an unshielded one. The plate
answers "what do I have"; the playfield has to answer "am I protected right now", and it was not
answering.

| What | Value |
|---|---|
| Region | `fx-shield`, 21x23, in `assets/atlas/sprites.png` |
| Colour | `G3` across each plate, `G2` on the two pixels running into a seam |
| Position | centred on the ship's `Transform`, no offset |
| Draw order | behind `ship-basic`, in front of the `C1` aura ring |
| Animation | none, one static frame |
| Lifetime | exactly while the shield component is present |

**Built.** `game/adapter/render/WorldRenderer.java`'s `drawShield` reads `fx-shield` and draws it
centred on the player, gated on `core/port/PlayerStatus.shieldActive()` — the same value the left
plate's `STATE` block already reads for `icon-shield`, so the ship and the plate cannot disagree.
The draw order above falls out of `accept()`'s existing sequence rather than being imposed on it:
the aura is drawn, then the shell, then the ship. Delivered by
[#236](https://github.com/LuchoC-Dev/little-spaceship/issues/236) in two parts, the art and this
specification first and the wiring second.

It must never be mistaken for the invulnerability aura, which is the one real risk here, so it
differs from it on three axes at once and the player has to remember none of them:

| | Shield | Invulnerability power-up |
|---|---|---|
| Shape | rounded shell, four plates with a diagonal seam between them | hard square outline |
| Colour | `G3`/`G2` green | `C1` cyan |
| Size | 21x23, taller than wide, hugging the hull | 21x21, square |

Cyan was already spent twice — it is the ship's own engine and fire, and it is the aura — so a cyan
shell hugging the hull would read as the ship glowing rather than as something around it. Green is
the colour of the capsule that granted it, `pickup-shield`; no enemy fire can be green, because
hostile fire owns hues 320-350 campaign-wide; and no background may hold `G2` or `G3` at all.

There are no partial states to draw. `core/domain/component/Shield.java` is a bare marker with no
durability and `core/domain/system/DamageSystem.java` removes it in one hit, so the shell is either
whole or absent. The moment it is spent is already covered by the *Feedback* table below: the icon
flashes and a break effect plays on the ship.

## Feedback

`../planning/02-mvp-functional-spec.md` asks for clear feedback on hits and on losing upgrades.
Every one of them is a change to something already on screen; nothing new appears.

| Event | Feedback |
|---|---|
| Life lost | rightmost filled life slot flashes `N7` 6 ticks, then empties; both playfield rules flash `N7` for 2 ticks, then `W3` for 4 |
| Shield lost | shield icon flashes `N7` 3 ticks, then disappears; a 21x21 break effect plays on the ship |
| Attachment lost | the whole `MODULE` block flashes `N7` 3 ticks, then hides |
| Bomb used | leftmost filled bomb slot flashes `N7` 2 ticks, then empties |
| Weapon level gained | the newly lit segment flashes `F1` for 4 ticks |
| Pickup collected at maximum | the score value flashes `W4` for 6 ticks — **not built, see below** |

There is no full-screen flash for damage. The playfield rules are enough, and a white frame over
208 px of bullets hides exactly what the player needs to see next.

The score has no floating popups. The value flashing on a bonus was meant to cover the one case
— `10-mvp-initial-values.md`'s 500 points for a wasted pickup — where the player would otherwise
wonder what happened.

**That one case is the only row of this table that is not built**, and it cannot be built from what
crosses the boundary today: `enemy-tank`'s kill score and `maxedPickupBonus` are both 500, so a
same-size jump in `score` is ambiguous, and `HudRenderer` has only the `PlayerStatus` snapshot to
diff. Flashing on every score increase would fire on every kill. Closing it needs a signal from
`core` naming the cause — work for the 11 group, weighed against whether the case is worth an event.
`HudRenderer`'s class javadoc has said this since it was written; this page had not.

## Conformance with the specification

The spec's HUD list, and where each item lives. This table is the acceptance criterion *the HUD
shows everything it requires and nothing more*, made checkable.

| Required | Where |
|---|---|
| Remaining lives | `LIVES`, five slots |
| Bomb charges | `BOMBS`, three slots |
| Current score | `SCORE` |
| Power-up status where applicable | `POWER` for the weapon level, `STATE` for shield and invulnerability; extra life folds into `LIVES` and bomb recharge into `BOMBS` |
| Equipped attachment, if any | `MODULE`, hidden when there is none |
| Invulnerability status | on the ship, three distinguishable states |
| Boss health, only during its fight | vertical bar, drawn only then |
| Feedback for hits and lost upgrades | the table above |

**Deliberately absent**, because the spec excludes them: minimap, enemy counter, level progress bar,
detailed statistics, high score, combo or multiplier, timer, weapon-level number, lives counter as a
numeral, and the player's hitbox.

## Screens

The screens of the flow are laid out on the full 480x270, not in the plates. There are seven —
menu, ship selection, options, play with its pause overlay, victory, defeat and credits. They are
built with `scene2d.ui` over a Skin, and the only thing this document fixes about them is the frame
they share:

| Element | Value |
|---|---|
| Screen background | `N1`. A parallax at 30% behind the menu is specified and unbuilt — there is no parallax in the game |
| Title | `font-title` in `N7`, top-left at 40, 32 |
| Menu entry | `font-mini`, 10 px line height, 16 px between entries |
| Entry, selected | `W4`, with a 5x7 `>` marker 12 px to its left |
| Entry, disabled | `N3` |
| Button plate | `N2` with a 1 px `N3` frame, 60x12 minimum |
| Slider track | 80x3, `N2`; knob 5x9, `N6` |
| Safe area | 24 px from every edge, so nothing sits against the letterbox |

Everything else about the screens belongs to `game-presentation` and to the Skin.
