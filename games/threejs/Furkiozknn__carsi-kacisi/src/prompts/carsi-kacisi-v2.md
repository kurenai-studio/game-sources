# Çarşı Kaçışı v2 upgrade brief — for Claude Haiku 5.5

## What the game is now
Single-file Three.js rooftop runner: 10 levels as layout strings (`LEVELS`, 373; tokens R B O M G L U D k P W C Z via `parseLevel`, ~496), run, jump + air jump, slide, domes, laundry lines, breaking tiles, gusts, night levels. Stars: target time (`par` = length/5), 80 % lokum, no falls. `?auto` clears 10/10, 0 falls, 53 draw calls.
Play already starts a level in one click. Nothing teaches the air jump, dome slide or lines. The cat keeps a fixed ~10-unit lead (`updateCat`, ~753) and is a speck. One grey dome colour and one stone tone everywhere (`COL`, ~488).
KEEP COUNTS STABLE: 10 levels, 3 stars each.

## Upgrade items (priority order)

### 1. First-encounter prompts
- why: only a static title line explains controls; level 1 opens with gaps and planks (~377).
- build: the first time each obstacle (gap, dome, rope, plank, breaking tile, gust, pigeons) is within ~8 units, show a short in-world prompt with the key or touch icon; once per type, saved in new `SAVE.seen`. Never blocks movement.
- done-when: fresh save in level 1 shows gap, double-jump and plank prompts; seen types stay silent after reload.

### 2. A cat that reacts
- why: constant lead, no tension.
- build: the lead shrinks to 6 units while the runner moves without stopping ~4 s (a "flow" meter) and grows to 13 after a fall; the cat looks back and hisses at short gaps; larger model and shadow. Lead never below 5 so `CAT_R2` catch is unchanged. The cat is a white Turkish Van pattern (white body, auburn tail and ear patches).
- done-when: `window.carsi.lead` and `.flow` exist; a fall opens the gap; bot still 10/10.

### 3. Gates and split times (18 gates, fact 2)
- why: checkpoints (`C`, ~526) are invisible flags; par is one number at the end.
- build: draw each checkpoint as a numbered stone gate arch; on passing show the split vs that gate's target (par by distance) as "+0.4 s"; best splits saved in new `BEST.lv[i].splits`. Star rules unchanged; `par` may be recomputed as measured bot time x 1.25.
- done-when: gates visible in every level; result card lists splits; they persist.

### 4. Lonca signs: an optional high route
- why: one line of travel per level; no reason to explore.
- build: one hidden guild sign per level on a side roof or above a laundry line, reachable with normal moves (double jump, rope + jump); collecting it opens a notebook card with a fact below and counts X/10 on the roof map. No star, no time effect; new `SAVE.signs`. The bot ignores signs.
- done-when: each sign hand-reachable (list the ones you tested); notebook shows collected facts.

### 5. A unique finale per level
- why: levels are chained verified segments (comment above `LEVELS`) and strings repeat (levels 2 and 5 share `B8 G3` runs, levels 1 and 4 share `M4 G2 M4`).
- build: give each level a unique last 20 units before `Z` from existing tokens (e.g. dome -> line -> gust gap on level 6; tiles over a wind gate on level 5). Verify with `?auto`.
- done-when: all ten final 20-unit strings differ; `?auto` 10/10 with 0 falls.

### 6. Each level has its own trade and light (visual bar)
- why: `paint(g, hex)` (~543) gives no variation; screenshots 01-06 differ only by sky.
- build: per-level palette and props in `buildLevel` (~986): copper domes with hanging pots, carpets on lines, gold finials with glints, spice sacks; +-6 % vertex-colour variation; 20-30 instanced awning strips on roof edges. Instance everything.
- done-when: levels 1, 4, 8, 10 look clearly different; `?debug` calls <= 65.

## Facts for in-game cards
1. TR: Fatih Sultan Mehmed, Cevahir Bedesteni'ni 1455/56 kışında yaptırmaya başladı; yapı 1460/61'de bitti. EN: Mehmed the Conqueror began the Cevahir Bedesten in the winter of 1455/56; it was finished in 1460/61. Source: https://en.wikipedia.org/wiki/Grand_Bazaar,_Istanbul
2. TR: 1638 civarında çarşıda yaklaşık 3.000 dükkan ve 18 kapı vardı; 1890'da 4.399 aktif dükkan ve 24 han kayıtlıydı. EN: Around 1638 the bazaar had about 3,000 shops and 18 gates; in 1890, 4,399 active shops and 24 hans were recorded. Source: https://en.wikipedia.org/wiki/Grand_Bazaar,_Istanbul
3. TR: Esnaf, kethüdanın başkanlığındaki loncalardaydı; loncalar 1913'te kaldırıldı. EN: Tradesmen were organised in guilds led by a kethüda; guilds were abolished in 1913. Source: https://en.wikipedia.org/wiki/Grand_Bazaar,_Istanbul
4. TR: 1943 ve 1954 yangınlarının onarımı 28 Temmuz 1959'da bitti. EN: Repairs after the fires of 1943 and 1954 were finished on 28 July 1959. Source: https://en.wikipedia.org/wiki/Grand_Bazaar,_Istanbul
5. TR: Çatı restorasyonu Temmuz 2016'da başladı, 630 iş günü sürdü; 800 bin kiremit ve 40.000 m² çatı yenilendi. EN: The roof restoration began in July 2016 and took 630 working days, with 800,000 tiles over 40,000 m² of roof. Source: https://www.karar.com/james-bondun-tahrip-ettigi-kapalicarsi-yenilendi-1509359
6. TR: Skyfall çekimindeki motosikletler 2012'de kiremitleri kırmıştı. EN: Motorcycles used in the filming of Skyfall broke tiles in 2012. Source: https://www.karar.com/james-bondun-tahrip-ettigi-kapalicarsi-yenilendi-1509359

## Mascot
Yes: the thief cat is the white Turkish Van kitten (item 2 recolours the 3D cat). On the result card and ending the kitten image (`kedi-tamam.png`, `kedi-kutlama.png`) sits on the jeweller's counter. Downscaled in `assets/mascot/`; hidden with `?noassets`.

## Do not break
`window.carsi` (mode, level, time, lokum, falls, position, `setBot`), `window.carsiSim`; flags `?auto ?debug ?low ?sim ?lang ?noassets`; keys `arena.carsi.settings|save|best` (`done[]`, `lv[]`; add fields only); layout token grammar, `STEP` 1/120, physics constants; 10 levels, 3 stars; bot 10/10 with 0 falls; touch controls; Play first; full TR/EN.

The shared rules in `_sablonlar/arena-upgrade-common.md` (and `_sablonlar/arena-round6-common.md`) are appended to this brief.
