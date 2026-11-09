# Codebound — Asset Requirements & Art Direction

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. Nothing is to be downloaded or imported yet. Verify
licences (CC0 / CC-BY) and credit requirements before using any asset.

---

## 1. Visual direction [RECOMMENDED]
- **Style:** top-down pixel art, retro fantasy RPG. [CONFIRMED]
- **One tile size for everything: 16×16 or 32×32 [OPEN D-06].** Recommendation: **16×16** with integer upscaling
  (cheap to find, small files, clean pixel look). Choose 32×32 if you find a better matching pack. Mixing sizes is
  the fastest way to ruin consistency, so pick one *before* shopping.
- **Palette:** cool dark stone (blue-grey / purple-grey), warm torch lighting (orange/yellow), bright colours only
  on *interactive things* (switches, keys, doors, exit). The player's eye should go to puzzle elements first.
- **Readability over detail:** every cell reads at a glance; no decorative clutter on walkable cells.
- **UI style:** pixel panels with thick outlines, block colour-coding by category: Motion (blue), Loops (orange),
  Logic (green), Data (purple), Functions (pink).

## 2. Where to look (shortlist, not downloaded) [RECOMMENDED]
| Source | Why | Caveat |
|---|---|---|
| Kenney.nl (e.g. Tiny Dungeon, Tiny Town, Roguelike/RPG packs, UI Pack Pixel, game icons, audio packs) | CC0, consistent 16×16, huge coverage, UI and audio too | Looks generic; plan a recolour/tint pass |
| itch.io free/low-cost dungeon tilesets | More character | Licences vary; check each |
| OpenGameArt.org | Audio and sprites | Licence variety |
| AI concept art | Mood boards, menu/chapter splash, story illustration only | Do not use for in-game sprites (style inconsistency); check your course's AI-use policy |

Best practice: take **one core pack (Kenney Tiny Dungeon is a natural candidate)** and build everything around it;
add other packs only for gaps and recolour them to match.

## 3. Asset inventory (prioritised)

### P0 — Required for the MVP
| Category | Items | Notes |
|---|---|---|
| Hero | 1 character, 4 directions (can mirror left/right), idle + walk (2–4 frames) | One sprite sheet |
| Floor / walls | Stone floor (2 variants), wall (edge/corner set), pit/void | Autotile/Rule Tile |
| Doors | Closed, open | Tint colour variants if keyed |
| Switches | Lever off/on | |
| Pressure plate | Up/down | |
| Collectibles | Key, treasure/gem | Optional pickup animation |
| Exit | Stairs/portal | |
| Hazards | Spikes (on/off) | Only if conditionals chapter is in MVP |
| UI frames | Panel, button (normal/hover/pressed/disabled), top bar, tooltip | Kenney UI Pack Pixel |
| Block graphics | Block body in 5 colours, notch/slot shapes, container (C-shape) pieces | Made from UI sprite 9-slice |
| Icons | Move, Turn L/R, Interact, Repeat, If, Function, Run, Step, Reset, Hint, Star, Lock | Game-icons pack |
| Fonts | 1 readable pixel font + 1 plain readable for explanations | Licence check |
| SFX | Footstep, turn, lever, door, key, success, failure, drag, drop, click, hint | CC0 audio packs |
| Music | 1–3 looping tracks | |

### P1 — Should have
- Torch, simple lighting/sprite glow (2D light, optional).
- Particle effects: dust on steps, sparkle on key, burst on door open.
- Hero reaction animations: bump (hit wall), success cheer.
- Chapter title cards and background art.
- Highlight overlays: cell flash, path ghost.

### P2 — Could have
- Enemies/guardians, extra tileset themes per chapter (library shelves, machinery for the Architect).
- Cutscene illustrations, achievements icons, animated main menu.

## 4. Reuse strategy [RECOMMENDED]
- One floor/wall set, **recoloured per chapter** with a palette tint or material instead of new art.
- One hero, with optional colour swap per chapter.
- Doors/switches/plates reused for all concepts; only their *links* differ.
- Block visuals built once from 9-slice sprites; categories differ only by colour.
- Library chapter reuses dungeon tiles plus a handful of bookcase/desk props.

## 5. Animations
Hero idle/walk (4 dirs), turn (instant snap is fine), interact (1 short animation), bump, success. Door open,
lever flip, pressure plate press, key pickup. UI: block hover/pick-up/drop squash, panel slide, star pop.
Tweening (via code or a small tweening helper) replaces most hand-drawn animation. [RECOMMENDED]

## 6. Technical asset notes
- Import settings: Filter = Point, Compression = None, Pixels Per Unit = tile size, Sprite Mode multiple/slice.
- Single sprite atlas per category to keep draw calls low.
- Target resolution: reference 1920×1080, world rendered at integer scale.
- Keep source art in `Art/Source` and a `CREDITS.md` file listing every asset, author, licence, and URL from the
  first import.

## 7. AI-generated art guidance [RECOMMENDED, **confirm policy: OPEN D-08**]
Use for concept/mood boards, chapter illustrations, and marketing/presentation visuals. Keep in-game sprites from
a single human-made pack. Disclose AI use in credits and check your university's policy.

## 8. Things to avoid
Mixed pixel densities, dozens of unique props, per-chapter totally new tilesets, high-detail animation, assets
with unclear licences, hand-drawing UI from scratch.
