# Kapadokya Balonu v2 upgrade brief — for Claude Opus 5.5

## What the game is now
Single-file Three.js wind puzzle: burner and vent only, four wind layers per flight (`FLIGHTS`, ~507), envelope lag (`physStep`, ~736), 12 flights, 36 stars; MPC bot flies 12/12, 36/36 (`CORE`, 474-1035, DOM-free).
Play opens the region map first (`openMap`, ~2379): 2 clicks to fly. Teaching = timed text hints (`updateHUD`, ~1970). The wind ladder shows every layer from the first frame (`buildLadder`, ~1872). Terrain colour is soft noise (`triColor`, ~1243); no facts anywhere.
KEEP COUNTS STABLE: 12 flights, 36 stars, 3 regions.

## Upgrade items (priority order)

### 1. One-click takeoff and an input-driven coach
- why: Play -> map -> Take off (~2379); hints fade by time, not by what the player did.
- build: Play/Continue calls `startFlight(nextOpen())`; the map stays on title, pause and result. In flights 1-2 a 4-step strip ticks on real input: hold burner to lift, read the green ladder arrow, vent into it, release burner early near the field. "Skip tips" toggle. Keep `?auto` working (`autoUpdate`, ~2428).
- done-when: one click from load gives `window.kapadokya.screen === 'play'`; steps tick only after the matching input; `?auto` 12/12.

### 2. Pilot balloon: reading wind is a skill
- why: the ladder gives away the puzzle.
- build: key `B` releases a pibal (rises ~4 m/s, drifts with `windAt`, smoke trail) that reveals each layer as it passes. From flight 3 unsampled upper layers show `?`; flights 1-2 show all. Cooldown 15 s, unlimited. Render-side only, not in `CORE`, so bot results stay identical.
- done-when: `?flight=5` shows `?` on upper layers, `B` reveals them; `window.kapadokya.revealed`; `?auto` still 36/36.

### 3. Valley Notebook
- why: 7 landmarks (`LANDMARKS`, ~495) are only photo targets.
- build: a notebook screen (title and pause) with cards; a successful photo (`photoOk`, ~1745) or a finished flight unlocks a card, shown on the polaroid (`takeSnapshot`, ~1983) and the result card. Facts below in one table. Save ids in new `PROG.notes`.
- done-when: first photo shows a fact; locked/unlocked states persist; old saves load.

### 4. Dawn mass launch and tuff strata (visual bar)
- why: `triColor` banding is faint; the launch field is empty although 36 balloons exist (`buildCrowd`, ~1466).
- build: 4-5 tuff tones in 5-8 m bands on slopes > 0.35 plus pale pumice stripes at rims; 10-14 balloons inflate and lift off near the launch field in the first 40 s (reuse `spawnCrowd`) with warm burner glow. Stay near 27-31 draw calls.
- done-when: screenshots at t=0 and t=30 show balloons rising; `?debug` calls < 40.

### 5. Gust telegraph
- why: gusty flights (3, 6, 12) shake layers +-32 % / +-14 deg (`layerVec`, ~701) but the ladder shows only the mean.
- build: a faint spread wedge per layer sized by `F.gust`, a windsock on launch and landing fields following ground wind, a soft rumble 1-2 s before a strong gust (render-side).
- done-when: flight 3 shows wedges and a moving sock; flight 1 has none.

### 6. Daily Flight (optional extra)
- why: nothing to replay after 36 stars.
- build: a title button (Play stays first): a date-seeded variant of one existing flight (winds +-40 deg, +-2 m/s; same goals), best score in new key `arena.kapadokya.daily`, never touches `PROG`.
- done-when: `?daily=2026-10-28` gives the same winds each reload; stars stay 0-36.

## Facts for in-game cards
1. TR: Peri bacaları, yanardağ püskürtülerinden kalan tüf ve ignimbritten doğar; sert üst kat altındaki yumuşak kayayı korur. EN: Fairy chimneys form from volcanic tuff and ignimbrite; a hard top layer shields the soft rock below. Source: https://iugs-geoheritage.org/geoheritage_sites/the-miocene-cappadocian-ignimbrites-sequence/
2. TR: Derinkuyu yaklaşık 85 m iner; kat sayısı kaynağa göre 8-20 arasındadır. EN: Derinkuyu goes about 85 m deep; sources give 8 to 20 floors. Source: https://en.wikipedia.org/wiki/Derinkuyu_underground_city
3. TR: Bölgede 200'den fazla yeraltı şehri olduğu söylenir. EN: More than 200 underground cities are said to exist in the region. Source: https://www.ntv.com.tr/yerel-haberler/galeri-hristiyanlarin-ilk-siginagiydi-200den-fazla-yer-alti-sehriyle-biliniyor-1721209
4. TR: 2025'te Türkiye'de yaklaşık 40.000 balon uçuşunda yaklaşık 915.000 yolcu taşındı; uçuşların %80'inden fazlası Kapadokya'daydı. EN: In 2025 about 40,000 balloon flights carried about 915,000 passengers; over 80% were in Cappadocia. Source: https://www.ntv.com.tr/ntvpara/308-bin-yolcu-balona-bindi-1731394
5. TR: Türkiye'de SHGM yetkili 71 işletme ve 530 balon var. EN: Turkey has 71 licensed operators and 530 balloons. Source: https://www.ntv.com.tr/ntvpara/308-bin-yolcu-balona-bindi-1731394
6. TR: Kapadokya'da 2025'te 223 gün uçuş yapılabildi; uçuş günü hava koşuluna bağlıdır. EN: In Cappadocia balloons flew on 223 days in 2025; flyable days depend on the weather. Source: https://www.benguturk.com/gundem/kapadokyada-balon-turlarina-754-bin-98-kisi-katildi-259819h

## Mascot
Yes, small: on the landing report the white Turkish Van kitten peeks over the basket rim, waves a paw on a soft landing (score 65+), puffs up on a hard bump. Downscaled copy in `assets/mascot/`; hidden with `?noassets`.

## Do not break
`window.kapadokya`, `window.kapadokyaSim`, flags `?auto ?debug ?sim ?low ?flight ?speed ?lang ?nosave ?noassets`; keys `arena.kapadokya.settings|save|best` (add fields only); `CORE` physics, wind and goals unchanged and DOM-free; fixed step 1/30; Play first; full TR/EN.

The shared rules in `_sablonlar/arena-upgrade-common.md` (and `_sablonlar/arena-round6-common.md`) are appended to this brief.
