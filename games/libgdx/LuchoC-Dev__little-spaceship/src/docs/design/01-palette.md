# Palette — `ls32`

Thirty-two colours, closed. Nothing is drawn outside this list; a colour that is missing is a
mistake in the drawing, not a gap in the palette.

Machine-readable copies live next to this document: [`palette/ls32.gpl`](palette/ls32.gpl) for
Aseprite, GIMP and Krita, and [`palette/ls32.hex`](palette/ls32.hex) for anything else.

## How it is structured

The palette is not a list of nice colours. It is **two disjoint sets**:

- **Background-legal** — everything scenery, parallax and ambient events may use.
- **Gameplay-only** — the player, enemies, projectiles, pickups, explosions and the HUD.

A background cannot be bright enough to swallow a bullet because the colours that would make it
bright are not available to it. That is the whole mechanism, and it holds without anyone
remembering to apply it.

Two colours are exempt, because their job is separation rather than visibility: **N0**, the outline
every gameplay sprite carries, and **H1**, the enemy bullet's own outline. Both are dark by
definition.

## The table

`L*` is CIE lightness, 0 to 100. `H` is hue in degrees.

### Background-legal

| id | hex | H | L* | Used for |
|---|---|---|---|---|
| N0 | `#0B0E14` | 220 | 3.9 | void, letterbox, every outline |
| N1 | `#161B26` | 221 | 9.8 | deepest background mass |
| N2 | `#242C3B` | 219 | 17.9 | background mass, HUD plate |
| N3 | `#3B475C` | 218 | 29.9 | background detail, panel frame, playfield rule |
| N4 | `#5C6B85` | 218 | 44.9 | distant relief, lit Moon rock, HUD labels |
| B1 | `#0E1730` | 224 | 8.3 | night sky, deep space |
| B2 | `#1A2C55` | 222 | 18.7 | atmosphere, city haze |
| B3 | `#2A4680` | 220 | 30.5 | mid distance, orbital limb |
| T1 | `#10333A` | 190 | 19.2 | glass, water, coolant |
| T2 | `#1C5C63` | 186 | 35.6 | lit teal surface, signage |
| W1 | `#43231A` | 13 | 17.8 | ember, brick, dark rust |
| W2 | `#8A4020` | 18 | 36.3 | fire glow below, mid rust |
| G1 | `#1B4A34` | 152 | 27.8 | vegetation, dark alien tech |
| V1 | `#201530` | 264 | 9.5 | alien dark |
| V2 | `#382050` | 270 | 17.7 | alien mid |
| V3 | `#58347A` | 271 | 29.2 | biomechanical tissue (stage 4) |
| M1 | `#2E1A16` | 10 | 11.8 | organic dark |
| M2 | `#5E3028` | 9 | 25.7 | organic mid |

### Gameplay-only

| id | hex | H | L* | Used for |
|---|---|---|---|---|
| N5 | `#8D9CB5` | 218 | 64.0 | hull shade, human and alien metal |
| N6 | `#C9D6E8` | 215 | 85.2 | hull light |
| N7 | `#FFFFFF` | — | 100.0 | white: impact frame, HUD value text |
| C1 | `#2FBFD4` | 188 | 71.3 | player engine, player fire body |
| C2 | `#9DF2FA` | 185 | 90.6 | player fire core, thruster peak |
| W3 | `#E5822C` | 28 | 64.0 | explosion body, human aircraft markings |
| W4 | `#FFC94A` | 42 | 83.7 | explosion peak, muzzle flash, boss bar fill |
| F1 | `#FFF6D9` | 46 | 96.9 | hottest explosion frame, pickup sparkle |
| G2 | `#34A75C` | 141 | 60.9 | pickup body |
| G3 | `#7FE08A` | 127 | 81.7 | pickup highlight |
| V4 | `#8E5CB8` | 273 | 48.1 | alien hull light — the colour enemies are made of |

### Reserved — enemy fire and nothing else

| id | hex | H | L* | Used for |
|---|---|---|---|---|
| H1 | `#8C0F4B` | 331 | 30.5 | enemy bullet outline |
| H2 | `#FF3D8A` | 336 | 58.4 | enemy bullet body |
| H3 | `#FFD9EA` | 333 | 90.2 | enemy bullet core |

## The three rules the palette enforces

**1. The reserved hue band.** Hues between **320 and 350 degrees** exist only in H1, H2 and H3, and
only enemy fire may use them. No background of any stage, no enemy hull, no explosion, no pickup and
no HUD element enters that band. This is why stage 4's biomechanical tissue is violet (V3, hue 271)
and its dark organics are maroon-brown (M1, M2, hues 9-10) rather than pink.

**2. The value ceiling.** No background pixel exceeds **L\* 45**. The brightest background-legal
colour is N4 at 44.9.

**3. The gameplay floor.** Every gameplay sprite contains pixels at **L\* 48 or above** — at least a
fifth of its non-outline area. The darkest gameplay colour is V4 at 48.1.

Rules 2 and 3 leave a gap of 3.2 points of lightness that nothing may cross. Enemy fire clears it by
a wide margin: H2 at 58.4 and H3 at 90.2 sit far above anything a background can produce.

## Checking it

[`palette/check.py`](palette/check.py) recomputes every number in the tables above from the hex
values and verifies the three rules. It is plain Python with no dependencies:

```
python docs/design/palette/check.py
```

It prints the full table and fails loudly if a colour is added that breaks the split. Run it after
touching the palette; the numbers in this document come from it.

The companion, [`palette/lint-art.py`](palette/lint-art.py), checks a finished PNG instead of the
palette: it reports every pixel that is not a palette colour and every colour the asset was not
allowed to use.

```
python docs/design/palette/lint-art.py assets/bg-city.png background
python docs/design/palette/lint-art.py assets/enemy-tank.png gameplay
```

Run it on each sprite as it is finished. A background that reached for a gameplay colour is
invisible until the level is running and something disappears behind it.

## Notes for whoever draws

- **No dithering in gameplay sprites.** At 480x270 a dithered enemy at speed reads as noise, and
  noise is what bullets hide in. Dithering is allowed in background ramps, where it is stationary.
- **No anti-aliasing anywhere.** There is no in-between colour available for it.
- **Ramps are for shading, not for inventing colour**, and a ramp never crosses the split. A
  gameplay sprite may use gameplay colours plus N0; a background may use background colours plus N0.
  Nothing mixes.

  | Ramp | Steps | For |
  |---|---|---|
  | Human metal | N0 -> N5 -> N6 -> N7 | the player ship, structures, HUD plates |
  | Alien hull | N0 -> **V4** -> N5 -> N6 | every enemy, campaign-wide |
  | Fire | W2 -> W3 -> W4 -> F1 | backgrounds may start it at W2; sprites start at W3 |
  | Enemy fire | H1 -> H2 -> H3 | nothing else, ever |

  **The alien ramp has one chromatic step.** V4 is the only violet above the gameplay floor, so an
  enemy is violet mass with *cold metal* highlights, not with lighter violet, and its interior
  shadow is N0 rather than a darker violet. V1, V2 and V3 are scenery — they exist for stage 4's
  biomechanical walls, which are background, and they may never appear inside an enemy.

  If a second gameplay violet is ever needed it goes **between V4 (48.1) and N5 (64.0)**, around
  `L*` 56. It cannot go between V3 and V4: anything below 48.1 is background-class by rule 3 and the
  audit rejects it inside a sprite. An earlier note in `../plan/06-presentation/status.md` said the
  opposite and was wrong.
- **Transparency is binary.** A pixel is drawn or it is not. The only place alpha varies is the
  invulnerability blink, which is a tint applied at draw time and not a colour in the sprite.
