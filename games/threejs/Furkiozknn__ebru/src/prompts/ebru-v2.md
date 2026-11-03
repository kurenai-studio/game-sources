# Ebru v2 upgrade brief — for Claude Fable 5.1

## What the game is now
Single-file Three.js marbling puzzle: deterministic sim (`Marble`, `StrokeRunner`, `TOOL`, ~620), 18 lessons in 3 chapters as stroke recipes (`LESSONS`, ~854), live match % (`matchScore`, ~949), 3 stars per lesson, free tray + 12-sheet gallery. `?auto`: 18/18, 48/54 stars.
Flow: Play -> map (`openMap`, ~1650) -> lesson -> intro card -> Begin (`bBegin`, ~1665): 4 clicks before the first drop. A failed sheet says only "At least 80 % match needed" (`finishSheet`, ~1423).
KEEP COUNTS STABLE: 18 lessons, 3 chapters, 54 stars; new content is optional extras.

## Upgrade items (priority order)

### 1. One-click start and a coached first lesson
- why: 4 clicks (~1650, `startLesson` ~1470); the ghost hint (`showHint`, ~1355) hides behind `H`.
- build: Play/Continue calls `startLesson(firstUnsolved())` straight into play; the master's note becomes a dismissible card that fades at the first stroke. Map stays reachable from HUD, pause, result. In lessons 1-3 auto-show the first stroke's ghost and pulse "Lay the paper" at match >= 80 %. Update `botStep` (~1698) so `?auto` still starts.
- done-when: one click, then a stroke can be dragged (`window.ebru.state === 'play'`); `?auto` 18/18.

### 2. Master's critique
- why: `matchScore` already computes per-pigment area and centroid (`classStats`, ~941) but the player never sees it.
- build: name the worst two deviations (pigment unused, too little/much, wrong place) on the failed result card and as a live line by the match bar, e.g. "Add more Red ochre, upper right" (TR/EN via `PAL`). Extra chime at 90 %, soft rim glow at 80 %.
- done-when: lesson 5 with only blue used names the missing colour.

### 3. Master's Seal: apprentice to master
- why: stars ignore whether you learned the recipe or leaned on the hint (`G.hint`).
- build: a lesson solved at >= 90 %, <= par, with no hint earns a red seal (map button, result card), stored in new `PROG.seals`. Ranks: Çırak 0-5, Kalfa 6-11, Usta 12-18 seals on title and ending. Stars and 54 total unchanged.
- done-when: hint use blocks the seal; old saves load.

### 4. Water thickness in the free tray
- why: `TOOL` constants (~620) are fixed; real ebru is worked on thickened water.
- build: free tray only: a 3-step thickness control (thin / medium / thick) scaling drop `spread` and awl/comb `lam`, `mu`. Lessons and bot use medium, so every target stays bit-identical.
- done-when: the same stroke spreads differently thin vs thick; lesson targets unchanged.

### 5. Bind it into a book
- why: the finished sheet only hangs on the line (`setHangingTexture`, ~1161); the book-cover use (fact 3) is never shown.
- build: a "Bind it" button on result card and free-tray save: 2D composite of the sheet as endpaper on a cover (spine, corners, title strip); saving keeps the normal JPEG in `arena.ebru.gallery` plus a `bound` flag list in new key `arena.ebru.bound`.
- done-when: a bound sheet shows its cover in the gallery; old entries load.

### 6. Source-clean notes, add facts
- why: notes carry unsourced dates/names (`hatip` d. 1773, `lale` 1883-1976, `papatya` 1920-1990, ~895-907); the rules allow only listed facts.
- build: keep technique text, delete those names/dates (keep UNESCO 2014). Add a "Did you know" line to result and loading from the facts below (data table, URL in a comment).
- done-when: no year other than 2014 in note texts; result shows a fact in both languages.

## Facts for in-game cards
1. TR: Ebru, 2014'te UNESCO Somut Olmayan Kültürel Miras Temsili Listesi'ne girdi. EN: Ebru, Turkish art of marbling, was inscribed on UNESCO's Representative List in 2014. Source: https://ich.unesco.org/en/RL/ebru-turkish-art-of-marbling-00644 and https://ich.unesco.org/en/decisions/9.COM/10.44
2. TR: Pigmentler koyulaştırılmış suya serpilir ve fırçayla işlenir; desen kâğıda alınır. EN: Pigments are sprinkled on thickened water and worked with a brush; the pattern is taken up on paper. Source: https://ich.unesco.org/en/RL/ebru-turkish-art-of-marbling-00644
3. TR: Ebru cilt ve kitap süslemede kullanılır. EN: Ebru is used to decorate book covers and bindings. Source: https://ich.unesco.org/en/RL/ebru-turkish-art-of-marbling-00644
4. TR: Temel beceri için en az iki yıl gerekir; usta-çırak yoluyla aktarılır, yaş, cinsiyet ya da köken engeli yoktur. EN: The basic skill takes at least two years, passed from master to apprentice, with no barrier of age, gender or origin. Source: https://ich.unesco.org/en/RL/ebru-turkish-art-of-marbling-00644

## Mascot
Yes, small: the white Turkish Van kitten sits on the workshop windowsill (billboard sprite, tail flick) and on the result card appears with `kedi-kutlama` (3 stars) or `kedi-dusunuyor` ("Not yet"). Downscaled in `assets/mascot/`; hidden with `?noassets`.

## Do not break
`window.ebru`, `window.ebruSim`, `window.ebruDebug`; flags `?auto ?debug ?sim ?low ?lesson ?free ?lang ?nosave ?noassets &jitter`; keys `arena.ebru.settings|save|best|gallery` (add only); deterministic sim and all 18 recipes; 9-10 draw calls; Play first; full TR/EN.

The shared rules in `_sablonlar/arena-upgrade-common.md` (and `_sablonlar/arena-round6-common.md`) are appended to this brief.
