# Çini Ustası v2 upgrade brief — for Claude Fable 5.1

## What the game is now
- Single-file Three.js r170 edge-matching tile puzzle in a low-poly Iznik workshop: rotate (ch. 1), swap (ch. 2), fixed and double-sided tiles (ch. 3).
- 30 levels (`LEVEL_DEFS`, line ~409), boards 3x3 to 6x6, generated solved and then scrambled (`generateLevel()`), plus a daily 4x4 board after chapter 1.
- Stars by moves against par (`starsFor()`), 3 hints per level, undo, a kiln sequence on solve, a collection wall of finished panels.
- Strong: look, solver-checked levels, calm audio. Weak: the first level opens a modal how-to, the only "depth" is bigger boards, the wall holds just 12 of 30 panels, nothing teaches the real craft.

## Upgrade items (priority order)
1. **No tutorial wall: coaching inside level 1**
   - why: `startLevel()` (~1669) opens `showHowto(ch)` as an overlay on the first level of every chapter, so Play costs an extra click and a text wall before the first tile.
   - build: remove the automatic overlay (keep `?` / `btnMenuHelp` and `showHowto()` available). Instead show 1-line coach tips over the board: level 1 pulses the first mismatched tile with "Tap to rotate"; the first time a swap/flip/fixed tile appears (levels 11, 21) a one-time banner names the new rule and points at that tile. `progress.seenHowto` is reused to remember which tips were shown.
   - done-when: title Play then first tile rotated in 2 clicks, no overlay; `?nohowto` and `?auto` still work; levels 11 and 21 show their banner once, even on a fresh profile.
2. **Kiln firing as a craft step (research-driven mechanic)**
   - why: the solve sequence (`SEQ`, `updateSequence()` ~1696) is a passive cutscene; the research says Iznik tile is fritware, a quartz body bound by glass frit that melts in the kiln.
   - build: after a solve, an optional "Fire the panel" step (skippable with one click, auto-skipped by `?auto`): a heat gauge rises and the player taps when the needle is inside the glaze band; result is a finish rating (Matte / Glossy / Master glaze) stored on the collection entry as a new field `glaze` and shown as a gloss level on the wall picture and in the collection. Stars and moves are not affected. Fact card 1 appears while the kiln heats.
   - done-when: solve level 1, tap in the band, the wall tile shows the better gloss and `cini.progress.collection[i].glaze` is set; old saves without `glaze` still load.
3. **Weathered tiles: an excavation variant of the daily board (research-driven mechanic)**
   - why: the daily board is the same 4x4 rotate/swap puzzle every day (`DAILY_DEF`, ~422); the research says the Iznik kiln dig is still producing finds.
   - build: on odd days the daily board is an "Excavation board": 3 tiles are weathered (motif drawn at low contrast until the tile touches one correct neighbour edge, then it restores with a shimmer), through a flag on `generateLevel()`; the solution stays the generated one so hints, the solver and `?auto` keep working. Fact card 3 shows on that board's intro.
   - done-when: `?debug` with a forced odd date (add `?daykey=YYYY-MM-DD`) shows 3 faded tiles; matching one edge restores it; the bot solves it; even days unchanged.
4. **Live star target and move feedback**
   - why: 3 stars needs moves <= par, where par is the exact planned solution (`pz.par`, `planMoves()`), yet the HUD only shows live stars (`updateHUD()` ~1796) with no sense of how close the limit is.
   - build: a "moves to next star" meter in the top bar (a thin bar that turns from gold to bronze as the 3-star and 2-star thresholds pass), a soft chime and a small star pop when a threshold is crossed, and a gentle "wasted move" shake when a rotation un-matches an edge. Do not change thresholds or star counts.
   - done-when: rotating a tile past par on level 1 flips the live stars from 3 to 2 with the chime and the meter changes colour.
5. **Master's gallery: all 30 panels kept, with notes**
   - why: `MAX_WALL = 12` (~996) so the workshop wall silently drops the older panels; the collection screen has no story.
   - build: the workshop wall keeps showing the 12 latest, but the Collection screen lists all 30 as a gallery (locked ones as outlines); selecting a panel shows its name, stars, glaze and, per chapter, one unlocked "Craft note" card from the facts table.
   - done-when: with 30 solved panels (`?fill`) the collection shows 30 cells and 4 craft notes; the wall still shows 12.
6. **Board and tile material polish**
   - why: the grout between tiles renders near-black and heavy (docs/chapter3-level22-wall.png), tiles have no specular response, and `updateGlow()` rebuilds a new `BufferGeometry` on every change.
   - build: warm lime-plaster grout colour, a thin bevel highlight on each tile, a one-pass glaze sheen that sweeps over a tile when its last edge matches, and reuse of one preallocated glow geometry (update attributes in place).
   - done-when: screenshot shows light grout and a visible bevel; `?debug` draw calls stay within the old count; `renderer.info.memory.geometries` does not grow while rotating tiles for 60 s.
7. **Portal and English pass**
   - why: line 14-16 load Google Fonts (external request); the HTML default is Turkish; the three-js load-failure message (line ~331) is Turkish-only.
   - build: remove the font links in favour of a system sans stack, make the fallback message bilingual, check every EN string including the new ones.
   - done-when: only the Three.js CDN is requested; `?lang=en` shows no Turkish except the title and level names that already have an EN pair.

## Facts for in-game cards
Use on the kiln step, the Excavation board intro, the collection craft notes and the loading screen. Put the source URL in a code comment per row.
1. TR: İznik çinisi kil değil; ağırlıklı olarak öğütülmüş kuvars, az miktarda cam frit ve kilden yapılan "fritware" malzemedir, fırında cam kısım eriyip gövdeyi bağlar. EN: Iznik tile is not ordinary clay: it is fritware, made mostly of ground quartz with a little glass frit and clay, where the glass melts in the kiln and binds the body. Source: https://www.afar.com/magazine/not-just-a-souvenir-the-untold-story-of-turkeys-iznik-tiles
2. TR: İznik çinisinin yeniden canlanma hikâyesinde İznik Vakfı ve ekonomi profesörü Dr. Işıl Akbaygil öne çıkıyor. EN: The Iznik Foundation and economics professor Dr. Işıl Akbaygil are central to the story of Iznik tile's revival. Source: https://www.frommers.com/destinations/iznik/attractions/the-iznik-foundation/
3. TR: İznik Çini Fırınları kazısı İstanbul Üniversitesi eliyle 41 yıldır sürüyor ve 11 fırın ateşhanesi sayılıyor (CNN Türk haberi). EN: The Iznik tile kiln excavation, run by Istanbul University, is reported to have continued for 41 years and to count 11 kiln fire chambers (CNN Türk report). Source: https://cnnturk.com/turkiye/iznikteki-kazilarda-cini-firinlar-bulundu-670597
4. TR: Kazıdan çıkan bir tabak 2025'te İznik Müzesi'nde ilk kez sergilendi. EN: A plate recovered from the excavation was shown for the first time at the Iznik Museum in 2025. Source: https://doaj.org/article/09b0e3669a2c4fc3849832c7b03cb047

(Skip the "quartz replaced clay in the late 15th century" and "85% quartz" lines: single weak sources. The pigment chemistry is doğrulanmadı.)

## Mascot
No. The workshop already has a cat on the stool (`updateCatModel()`), a second cat would be clutter.

## Do not break
- Flags `?auto ?debug ?low ?lang ?noassets ?nohowto ?fill ?sim`; `window.cini` (`G`, `G.progress`), `window.ciniSim(seconds)`; `tests/core.test.mjs` must still pass (solver solves all 30 levels and daily boards).
- Save keys `arena.cini.settings`, `arena.cini.save` (fields `best`, `collection`, `seenHowto`, `dailyToastShown`; add fields only), legacy migration from `cini-ustasi-v1`.
- Counts and rules: 30 levels in 3 chapters, `LEVEL_DEFS` unchanged, `starsFor()` thresholds, 3 hints per level, daily unlock after level 10, Play stays the first button.
- Controls: click rotate, drag swap, right-click/long-press/`F` flip, `Z H R P M X L`.

The shared rules in `_sablonlar/arena-upgrade-common.md` (and `_sablonlar/arena-round6-common.md`) are appended to this brief.
