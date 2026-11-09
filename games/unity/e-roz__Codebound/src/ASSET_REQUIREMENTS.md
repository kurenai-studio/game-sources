# Codebound — Asset Requirements & Art Direction (v2)

Legend: **[CONFIRMED]** · **[RECOMMENDED]** · **[OPEN]**. Nothing is to be downloaded or imported yet. Check licences
and credit requirements for every asset.

---

## 1. Visual direction
- Pixel-art, retro fantasy, top-down. [CONFIRMED]
- One tile size for everything: **16×16 recommended** [OPEN D-06]. Choose before shopping for assets.
- Stone dungeon (cool blue-grey) with warm torchlight; **bright colour reserved for things the code touches** (chests,
  guards, items, threads) so the lesson reads at a glance.
- The Keep scene is a **stage**: objects sit in labelled slots on a grid; no walking maps.
- Code panel uses a clean **monospaced font** (readability beats pixel style for code); the rest of the UI can be
  pixel-style.

## 2. Sources [RECOMMENDED]
| Source | Use |
|---|---|
| Kenney.nl (Tiny Dungeon, UI Pack Pixel, game icons, audio) | Core tiles, props, UI, SFX (CC0) |
| itch.io free dungeon/RPG packs | Characters, extra props (check each licence) |
| OpenGameArt.org | Audio, extra sprites |
| AI concept art | Mood boards, story illustrations only; not in-game sprites. Check course policy [OPEN D-08] |

Build around **one core pack** and recolour other assets to match. Keep `CREDITS.md` from the first import.

## 3. Asset inventory

### P0 — MVP
| Category | Items |
|---|---|
| Keep environment | Floor, wall set, 3 chapter tints (Vaults, Gates, Workshop), torches |
| Code-linked objects | Chest (closed/open/empty), pouch of coins, items (sword, key, potion, scroll), name plaque, list/shelf |
| Guards | 4 recolours of one guard sprite (so variables are distinguishable), name tag UI |
| Threads | Reference thread (animated line sprite or LineRenderer), cut-thread effect |
| Gate/door pieces | Gate (open/closed), turnstile, roll-call board |
| Workshop props | 3–4 machines (heal machine, counter, log printer), alarm light |
| Characters | Bato (portrait + small sprite), Tala lantern (sprite + glow), player sprite (single or name-only) |
| Effects | Sparkle, flash, alarm pulse, success/fail burst |
| UI | Panels, buttons, tabs, speech bubbles, tooltip, star, lock, progress pips, code panel frame, watch panel, test runner panel |
| Icons | Run, Step, Reset, Hint, Watch, Breakpoint, Log, Test, Inspector |
| Fonts | 1 pixel UI font, 1 monospaced code font (licence checked) |
| Audio | 3 music loops (one per chapter), UI clicks, chest/thread/gate/alarm, test pass/fail, hint, success |

### P1 — Should have
Chapter title cards, simple cutscene panels for story beats, Drift shadow effect, ambient lighting.

### P2 — Could have
Chapter 4–7 sets (library shelves, great hall, towers, Architect's chamber), achievements, animated main menu.

## 4. Reuse strategy
- One floor/wall set, recoloured per chapter.
- Chest/guard/item sprites are reused in every room; only their arrangement changes.
- Threads and highlights are code-driven, not hand-drawn animations.
- Tween animations (code) replace most hand-drawn frames.

## 5. Technical notes
Point filtering, no compression, Pixels Per Unit = tile size, 1920×1080 reference, integer scaling, atlases per
category, art source files kept separately.

## 6. Avoid
Mixed pixel densities, per-room unique art, high-detail animation, unclear licences, reading code in a pixel font.
