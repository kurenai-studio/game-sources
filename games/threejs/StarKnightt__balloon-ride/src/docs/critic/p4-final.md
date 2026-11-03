# Critic: Phase 4 final (shots/p4 + cinematic recording)

VERDICT: FAIL

## What I reviewed
- **All 38 frames in `shots/p4`.** Each spot (`ground`, `50m`, `200m`, `500m`, `down`, `basket`, `burner`, `cloud`, `incloud`) at golden (no suffix), `_sunrise`, `_sunset` and `_blue`, plus `mobile_portrait` and `mobile_landscape`.
- **Zoomed crops** of the `500m` / `500m_sunset` sky band, the `50m` clouds and motes, the `50m_blue` / `200m_blue` / `basket_blue` backdrop clouds, the `500m_blue` windmill, the `50m_blue` hedges and the `down` rim.
- **Cinematic frames** from `recordings/balloon-ride-cinematic.mp4` (h264, 1920x1080, 60 fps, 50.0 s) at 2 / 10 / 20 / 30 / 40 / 48 s, decoded with `-hwaccel cuda`. Below they are called c2 to c48, with coordinates at 1280 px wide.
- **A scene-change scan of all 3000 frames** (`select=gt(scene,0.08)`). No frame triggered it, so there are no cuts, pops or jumps.
- **References:** `refs/bristol_mass_ascent.jpg`, `refs/aerial_combe_village.jpg`, `F:\summer-cycle\refs\user_village_field.jpg` and `F:\summer-cycle\shots\tod\open_sunset.png`.

The game is now close. The world, the balloon, the festival, the cameras, the cinematic and mobile are all good. The remaining failures are in the clouds (at sunrise and at camera height), the blue-hour backdrop, one emissive artefact, and the definition-of-done `down` frame, which has no clouds.

| # | System | Verdict |
|---|---|---|
| 1 | World / terrain / village | **PASS** |
| 2 | Balloon | **PASS** |
| 3 | Clouds and wind | **FAIL** |
| 4 | Other balloons | **PASS** |
| 5 | Look-down / basket camera | **PASS** |
| 6 | Time of day | **FAIL** |
| 7 | Cinematic | **PASS** (its last shot is covered by blocker B2) |
| 8 | Mobile UI | **PASS** |
| 9 | Polish | **FAIL** |
| — | Audio (code review) | **PASS** |
| — | Definition of done (visual) | **FAIL** (`down` has no clouds) |

---

## 1. World / terrain / village: PASS
- **`50m`:** gabled houses with red, grey and slate roofs, gardens with lawns, hedged plots, sheep dots, lavender strips, a rapeseed field, and the river with tree reflections.
- **`200m`:** dense patchwork, the lake, the windmill (70, 380), the village spine, orchards in rows (1400–1600, 480–560) and a curving lane (1150–1600, 600–800).
- **`500m`:** a tiny village with a spire, a meandering river, a forest mass and cloud shadows sweeping across the fields.
- **`down`:** the hero view reads as a painted miniature. It shows a round green, the church (900, 265), a crossroads market square with stalls (770, 385), terraces, back gardens, allotments and long tree shadows.
- **Against `aerial_combe_village.jpg`:** the warm low light and long shadows match. Against the Summer Cycle frames, the ink, the flat-banded toon shading and the painterly grade are the same family.

## 2. Balloon: PASS
- **Inverted-pear envelope:** the gores bulge, and the load tapes and mouth band read clearly in `50m` and `50m_sunrise`.
- **The envelope is now matte and banded,** with no specular sheen. The p3 nice-to-have B-n1 is done.
- **The burner close-ups are excellent at all four times** (`burner*`): a twin can, a layered flame climbing into the mouth, converging wires and a glowing skirt. In `burner_blue` the skirt glows against the stars.
- **Nice-to-have:** in `burner*` a darker red disc inside the lower envelope (x≈375–1225, y 0–310) meets the bright red outer gores along a soft vertical edge (x≈375, x≈1225). It reads a little like a second translucent shell.

## 3. Clouds and wind: FAIL
**The p3 blockers:**
- **C3 (in-cloud): fixed.** All four `incloud*` frames are an opaque, luminous whiteout with drifting density, warm toward the sun. There are no geometry ghosts and no land shows through.
- **C2: fixed at golden, sunset and blue.** The `cloud` puff now has smooth round lobes, lilac shade and a warm bounce, with no facets and no stepped edges. The `ground` cumulus have lit cream tops over lavender bases.
- **C2 at sunrise: not fixed.** See B3.
- **C1: half fixed.** The backdrop cards no longer end on the ridge line, but the mid cumulus seen from 500 m still read as slabs. See B2.

**B2. BLOCKER: mid-layer cumulus near the camera's height render as blurry, flat-based slabs.**
- In `500m`, `500m_sunrise`, `500m_sunset` and `500m_blue`, the top band (x≈40–1180, y≈0–60) is a row of soft "bread loaf" shapes.
- They have smooth sides, no billows and dead-straight horizontal bottoms (`500m_sunset` crop: y≈55, muddy mauve and semi-translucent).
- At the end of the cinematic, **c48 (790–1280, 0–235)** is a huge featureless out-of-focus blob with a ruled flat base, filling the top-right quarter of the final wide shot.
- Fix either:
  - give the lobes their crisp lit tops and cauliflower bumps at this range, and stop the softening, or
  - route the c48 camera and the 500 m spot so no cloud sits that close. Doing both is better.

**B3. BLOCKER: the `cloud_sunrise` puff is a flat cream silhouette.**
- The same puff that is shaded at golden, sunset and blue is near-uniform cream at sunrise (610–1045, 440–840).
- There is almost no terminator and no shaded base, so it reads like a paper cut-out pasted on the fields, which was C2's original complaint.
- The sunrise light/shade ramp is saturating. Restore a lavender-grey shade side and base.

**Wind (nice-to-have, carried from C-n1):** the motes are still dark specks.
- In the `50m` crop (980–1280, 250–370), about 15 black dots float over the hill.
- `mobile_portrait` has dark flecks around the basket (480–640, 1300–1500).
- They read as dirt or flies. Make them warm, bright and sun-catching, or drop them.

## 4. Other balloons: PASS
- **D1 (variety): fixed.** There is now a blue/yellow chevron, a rainbow, a red/white, a gold and a purple/orange balloon. They stay distinct as specks at every time of day (for example the rainbow in `50m` at 1125, 337 and in `200m_blue` at 1118, 303).
- **D2 (count and depth): fixed.**
  - There are 4–5 on screen per chase frame.
  - The near chevron is about 50–60 px with readable gores (`50m` at 460, 265; `basket` at 505, 62).
  - The others are layered in depth, like `bristol_mass_ascent.jpg`.

## 5. Look-down / basket camera: PASS
- **E1: fixed.**
  - `down` now has a padded suede rim roll with ink, a corner upright, a coiled rope and woven inner walls.
  - The frame reads unmistakably as "leaning out of a basket", not as a roof.
- **E2: fixed.**
  - `basket` is framed by both corner uprights, with the rim pillows, a rope coil and the continuous cane weave on the inner wall.
  - The view looks over the spire, the lake and the river. It is a lovely composition at all four times.
- **L1: fixed.** The river in `down` is blue-grey with ripple marks (0–500, 490–630), and in `down_sunrise` it is clearly blue.
- **Nice-to-haves:**
  - The basket takes about 40% of `down` (lower right). A slightly further-out eye would show more village.
  - The basket floor is one flat brown panel with a single seam (720–1100, 690–900).
  - An unexplained cream-and-teal sliver shows under the rim at `down` (740–880, 680–700), in all four times.
  - In `down_sunset` the river (lilac-grey) is close in value to the roads.

## 6. Time of day: FAIL
The four times are clearly distinct:
- **Sunrise:** a teal-cyan sky, with valley mist lying in banks (`200m_sunrise`, `500m_sunrise`, `basket_sunrise`).
- **Golden:** warm cream haze.
- **Sunset:** a dark-blue zenith over a peach-pink horizon, and mauve fields.
- **Blue:** indigo, with stars (`ground_blue`), lit cottage windows (`50m_blue`, `200m_blue`) and a glowing burner skirt (`burner_blue`).

Sunrise, golden and sunset are beautiful.

**B4. BLOCKER: the blue-hour backdrop cumulus look like glossy inflatables with pink light leaks.**
- In `50m_blue` (10–590, 110–250), `200m_blue` (100–1340, 0–80) and `basket_blue` (20–560, 60–135), the far backdrop clouds are smooth, plasticky lavender blobs.
- They are lit brighter than the sky around them, while the nearer clouds in the same frames are correctly dark indigo.
- Their bases carry **bright pink glowing blotches** where they meet the hills: `50m_blue` at about (300–450, 300) and (690–720, 300), and `200m_blue` at (650–700, 145) and (870–900, 150).
- Dim the backdrop clouds for blue hour to sit with the near clouds, and remove the base glow.

**Nice-to-haves:**
- **The `50m_blue` hedges keep bright lime highlights** (950–1550, 580–700), which read slightly emissive at night.
- **The sunset river is still pink** (`50m_sunset`, `200m_sunset`), as PROGRESS acknowledges.

## 7. Cinematic: PASS
- **Smooth.** The scene-change scan over all 3000 frames found no frame above 0.08, so there are no cuts, pops or snaps. It is 50 s at 1080p60, as specified.
- **Beat by beat:**
  - **c2:** close on the burner, twin flames firing into the glowing skirt, the envelope filling the top right, and the sun and clouds behind. Good.
  - **c10:** pulled back, the balloon centred over golden fields with hedges, sheep and haze.
  - **c20:** the reveal. The village, spire, bridge, river and lake, with festival balloons beyond. This is the best frame of the project.
  - **c30:** over the village from above, with the river curving and the bridge reading.
  - **c40 and c48:** gliding wide over the fields.
- **The B2 issue in c48:** the final shot loses its top-right quarter to the blurry cloud blob. It is counted under B2, and fixing B2 fixes this.
- **Nice-to-have:** the player balloon is absent from c40 and c48. A distant glimpse of it in the last wide shot would close the loop.

## 8. Mobile UI: PASS
- **Layout.** `mobile_portrait` and `mobile_landscape` put the flame button bottom-left, the vent button bottom-right and a smaller eye (V) button above the vent.
- **Size.** The buttons are about 80 CSS px translucent discs with clear icons, inside the safe areas.
- **Nothing in the top-right corner, and no stray text.**
- **Nice-to-have:** both mobile frames look soft and aliased, because of the DPR cap 1.75 against a 3x device. The hedges and the envelope outline stair-step (`mobile_landscape`, envelope edge 1130–1145, 330–450). Consider FXAA on the phone tier.

## 9. Polish: FAIL
**B5. BLOCKER: the windmill seen from above is a self-lit white starburst.**
- In `500m`, `500m_sunrise`, `500m_sunset` and `500m_blue` at about (1370, 540), the windmill's sails render as a roughly 16-spoke white star.
- In `500m_blue` it is the brightest object in the frame and plainly unlit, so it reads as a lens sparkle or a bug.
- Light it like the rest of the world and give it a 4-sail read from above.

**Other polish (nice-to-have):** the dark motes (see 3), the down-rim sliver (see 5), the burner double-shell edge (see 2), and a row of identical pellet puffs at `50m` (1000–1460, 290–325, best seen in the crop).

## Audio (code review: `src/flight/audio.ts`, `src/sound/*`): PASS
- **Everything is synthesised.** There is no `fetch`, `decodeAudioData`, `new Audio` or audio file anywhere in `src/`, and `public/` holds only `models/balloon.glb`.
- **Burner:**
  - The roar is brown noise through a 420–460 Hz lowpass plus band-passed pink noise at 1.1 kHz.
  - Two LFOs (6.7 Hz and 2.3 Hz) flutter it, and a little goes to the reverb.
  - It starts with a fast attack and an ignition whoosh, and its tail falls in pitch as the lowpass drops to 170 Hz. That is the right shape for a burner.
- **Vent:** a high-passed white-noise hiss.
- **Wind:** the reused `air.ts` layer, driven by height above ground, ground speed and climb rate, with gust noise that grows with height. That is sensible.
- **Birds:** chirps, trills, warbles and whistles, plus skylarks. They are dense low down and thin out by about 450 m, dimmed at night with skylarks muted at night, and panned and randomised in rate. Good.
- **Bells:** a ring of six (G5 down to Bb4) rung in rounds at about 0.46 s with a handstroke gap, 2–4 rows every 70–140 s within about 2.3 km of the village. They are quieter with altitude and wet through a 3.2 s reverb. Each bell is nine partials, each with a beating doublet, plus a clapper thump. Convincing.
  - **Nice-to-have:** the tierce partial is 1.25 (a major third). Real church bells have a minor-third tierce of about 1.19–1.2, which gives the characteristic bell colour.
- **Other:** wicker creaks after burns, a master level of 0.55, start on first gesture and a smooth M mute. All fine.

## Definition of done (visual): FAIL
| Frame | Houses | Patchwork | Roads | River | Layered clouds |
|---|---|---|---|---|---|
| `50m` | yes, tiny and detailed | yes | yes (village street, lane at 1000, 380) | yes | yes (near cumulus, far cumulus, backdrop) |
| `200m` | yes | yes | yes (lane at 1150–1600, 600–800) | yes, plus the lake | yes (mid cumulus above, far cards) |
| `500m` | yes (tiny village, spire) | yes, dense | yes (lanes at 0–600, 560–700) | yes | yes (low puffs below the camera, mid above) |
| `down` | yes, superb | yes, at the edges | yes (the crossroads) | yes | **NO**: no puff, wisp or cloud shadow in any of the four `down*` frames |

**B1. BLOCKER: the straight-down frame has no cloud layer.**
- Put a low puff or wisp drifting below the basket in the `down` spot, at about 150–250 m under a 300 m eye.
- Alternatively, at least let a cloud shadow cross the village in frame.
- The definition of done requires layered clouds in this view.

---

## Blockers (fix, re-shoot)
1. **B1:** `down*` has no clouds at all, so the definition of done is unmet.
2. **B2:** mid cumulus near the camera's height are blurry, flat-based slabs (`500m*` top band; c48 top-right blob).
3. **B3:** the `cloud_sunrise` puff is a flat, unshaded cream cut-out.
4. **B4:** the blue-hour backdrop cumulus are glossy, too bright, and have pink glow blotches at their bases (`50m_blue`, `200m_blue`, `basket_blue`).
5. **B5:** the windmill from above is a self-lit white starburst (`500m*` at 1370, 540).

## Nice-to-haves (do not block)
- Dark wind motes (`50m`, `mobile_portrait`).
- The burner's inner-disc edge.
- A smaller basket share in `down`, the flat basket floor and the sliver under the rim.
- The lilac or pink sunset river.
- Lime hedge highlights at blue hour.
- The player balloon absent from the cinematic's end.
- Mobile antialiasing.
- The row of pellet puffs at `50m`.
- The bell tierce ratio.

## What works
1. **The `down` village:** a genuinely hand-painted miniature.
2. **c20, the cinematic reveal,** and the `basket` V view: postcard compositions at every time of day.
3. **The festival** now reads like the Bristol ascent: distinct saturated balloons in depth.
4. **Sunrise valley mist and the warm golden haze:** distinct, beautiful light.
5. **The in-cloud whiteout and the burner close-ups.**
