# Balloon Ride — research notes

Short and concrete. Each section ends with numbers or decisions we actually use.

---

## a. How real hot air balloons fly

**Burner bursts and the "standard burn".** The FAA *Balloon Flying Handbook* (FAA-H-8083-11B, ch. 7 "Flight maneuvers") defines a *standard burn* as **4 s**, and tells new pilots to expect roughly **one standard burn every 25–40 s** to hold level flight. Heavier load, warmer ambient air and sunshine shorten the interval. Level flight is "a series of standard burns", not a continuous flame.
Source: https://www.faa.gov/regulations_policies/handbooks_manuals/aviation/Balloon_Flying_Handbook_FAA-H-8083-11B/bfh_chapter_7.pdf

**The lag.** Firing the burner "does not translate into an immediate gain in altitude; there is some lag involved", and pilots learn what a burst does to climb rate by experience (EAA, *Low and Slow*). Steering explainers stress that every input is delayed by the envelope's thermal and vertical inertia. In practice the envelope (~2,000–3,000 m³ of air) heats over several seconds; the balloon first stops sinking, then climbs, and keeps climbing well after the flame stops. The same inertia applies in reverse after venting.
Sources: https://inspire.eaa.org/2024/07/17/low-and-slow/ · https://flyawaysimulation.com/ask/answers/hot-air-balloons-stay-aloft-steer/

**Flying light / heavy, overcontrol.** The handbook notes novices overcontrol: they burn, overshoot, then pull the vent line and oscillate. Good pilots make small, early inputs. (FAA ch. 7, above.) That oscillation is the natural "skill" of the toy and needs no score.

**The vent / parachute valve.** The top of the envelope is a fabric disc (~6 m across on a passenger balloon) held shut by the hot air's own pressure and centring lines. Pulling the red line draws it down and lets hot air out of the crown; releasing it lets the pressure reseal it. Short pulls are used to stop a climb or start a descent; the full pull is for deflation after landing.
Sources: https://patents.google.com/patent/US4402476 · AAIB bulletin, Cameron O-120 G-BVXF: https://assets.publishing.service.gov.uk/media/5422fab2ed915d13740007bb/Cameron_O-120_hot_air_balloon__G-BVXF_10-11.pdf

**Climb and sink rates.** Most pilots keep climbs to **200–800 ft/min (1–4 m/s)**, and ~1,000 ft/min (5 m/s) is the common practical maximum for a round envelope. The FAA advisory circular AC 91-71 uses **175–300 ft/min (0.9–1.5 m/s)** for an initial climb over obstacles. Terminal descent with the envelope cooling is **~750 ft/min (3.8 m/s)** for a light balloon, up to ~1,200 ft/min (6 m/s) for a heavy one. Cameron's Cloudhopper flight manual limits descent to 800 ft/min (4 m/s). Final approach is very slow.
Sources: https://seattleballooning.com/lowflyinghotairballoons/ · https://www.faa.gov/documentLibrary/media/Advisory_Circular/ac91-71.pdf · https://www.cameronballoons.co.uk/c/download/Cloudhopper.pdf

**Wind layers and steering by altitude.** A balloon has no steering. It moves with the air, and the pilot picks a height whose wind goes the right way: "a shift of just a few hundred feet can completely change the course". Wind usually veers (turns clockwise) and strengthens with height. Pilots read surface wind from smoke, flags and the ripples on ponds. The textbook case is the **Albuquerque Box**: a cool drainage flow from the north near the ground, a southerly wind a few hundred metres up. Balloons go south low, climb, come back north. It forms only in the first hours after dawn (about 30 % of early-October mornings).
Sources: https://www.weatherzone.com.au/news/understanding-hot-air-balloon-navigation/1889914 · https://rainbowryders.com/about/blog/how-pilots-steer-hot-air-balloon/ · https://www.weather.gov/abq/clifeatures_balloonfiesta · https://physicstoday.aip.org/quick-study/ballooning-in-albuquerque-whats-so-special · https://theweatherprediction.com/weatherpapers/107/index.html

**Typical altitudes.** Passenger flights range "from treetops up to 2,500 ft" (~0–750 m AGL). Most sightseeing time is spent at **300–1,000 ft (100–300 m)**, where houses, animals and people still read clearly. Pilots also do low contour flying (a few metres over fields) and occasional climbs to 600–900 m for the view.
Source: https://www.sundanceballoons.com/faqs/

**Why dawn and dusk, and festival mornings.** Flights happen in the first ~2 hours after sunrise and the last ~2 before sunset. The sun-heated ground makes thermals in the middle of the day, and thermals make altitude control unsafe. The air is calmest and coolest around sunrise. Passenger flights need surface winds **< 10 kt**. Festival mass ascensions (Albuquerque, Bristol, Château-d'Œx) launch in waves at sunrise, so many balloons sit at different heights in low, raking, golden light, often above ground mist.
Sources: https://www.virginballoonflights.co.uk/blog/why-hot-air-balloon-flights-happen-at-dawn-and-dusk/ · https://www.airandspace.si.edu/air-and-space-quarterly/issue-10/albuquerque-balloon-fiesta · https://en.wikipedia.org/wiki/Hot_air_ballooning

### Tuning numbers for our physics

| Parameter | Value | Note |
|---|---|---|
| Envelope heat state `h` | 0..1 relative to equilibrium; buoyancy ∝ h − h_eq | first-order model |
| Burner heating rate | +0.10 /s while held | a 4 s burn ≈ +0.4 |
| Heat time constant (lag) | τ ≈ **5 s** first-order smoothing from heat to lift, plus vertical-velocity inertia τ_v ≈ **3 s** | climb starts ~2–3 s after burner on and peaks ~8 s later |
| Passive cooling | −0.012 /s toward ambient | hold level ≈ 4 s burn every ~30 s, as the FAA says |
| Vent | −0.08 /s while held, takes effect faster (τ ≈ 2 s) | venting dumps hot air at the crown |
| Vertical speed | soft clamp ±3 m/s typical, hard clamp **+5 / −4 m/s** | tanh-style saturation |
| Ground | soft spring below 0.5 m AGL, damping 0.8, no bounce > 0.3 m/s | "gentle contact" |
| Start altitude | ~120 m AGL, in equilibrium | |
| Ceiling | soft at ~900 m (burner efficiency falls off), hard 1,200 m | |
| Wind low (< 150 m) | 2.5 m/s toward **east** | drift ~9 km/h |
| Wind mid (150–400 m) | 4 m/s toward **north-east** | |
| Wind high (> 400 m) | 6 m/s toward **north** | |
| Layer blend | smoothstep over ±40 m around 150 and 400 | veering with height, as in reality |
| Gusts | ±10 % speed, ±8° direction, 20–40 s period noise | |
| Basket sway | ≤ 1.5°, 6–8 s period, kicks on burner start | pendulum, ~15 m rope + envelope |

---

## b. Large stylized terrain, villages and cloud layers in Three.js

**Chunk + instance.** Split the world into tiles. Give each tile its own `InstancedMesh` per prop type so frustum culling drops whole tiles. Keep 2–3 LOD levels per tile, and let fog hide the transitions. Codrops' fluffy-grass write-up used a 16×16 chunk grid, 3 LODs, and matched ground colour to grass to hide pop-in.
https://tympanus.net/codrops/?p=83092 · https://discourse.threejs.org/t/seeking-optimization-tips-big-map-with-trees-and-rocks/68251

**InstancedMesh vs BatchedMesh vs merge.** InstancedMesh: one geometry, many transforms, one draw call. BatchedMesh: many geometries with one material, per-object transforms and culling (it needs an explicit `computeBoundingSphere`). `mergeGeometries`: cheapest to draw, but one bounding sphere and no per-object transforms, so use it only for static tile-local clusters (a village block, a hedge row).
https://threejs.org/docs/pages/BatchedMesh.html · https://discourse.threejs.org/t/merging-three-geometry/29103 · https://www.ui-skills.com/skills/cloudai-x/threejs-performance

**Impostors for far trees.** One three.js demo drew 200k trees on a 3 km terrain: real meshes to ~100 units, octahedral impostors beyond. An impostor holds up while its screen footprint is no larger than its bake resolution. A unit-quad impostor template needs an explicit bounding sphere, or the whole forest gets culled.
https://discourse.threejs.org/t/a-forest-of-octahedral-impostors/85735 · https://app.cinevva.com/blog/2026-05-04-open-world-browser-part-19-imposters · https://discourse.threejs.org/t/procedural-instanced-forest-high-performance-real-trees/88610

**Clouds: painted sprites vs volumetric.** A 2025 Staffordshire dissertation measured raymarched volumetric clouds as far more expensive than billboards; they are worth it only when dynamic fidelity matters. Common three.js practice is volumetric on WebGPU and billboards on WebGL2/mobile. For a painted (Ghibli/Shinkai) look, layered alpha sprites with a hand-painted lobe texture and soft depth fade are cheaper and *more* on-style.
https://gradex.staffs.ac.uk/wp-content/uploads/2025/05/5270_FYP-Dissertation.docx · https://skills.cat/skills/ck42bb/procedural-clouds-threejs · https://discourse.threejs.org/t/how-do-you-use-a-shader-to-create-clouds-in-three-js-part-2/9224/3

**Fog / aerial perspective.** Distance haze is what sells scale from 500 m. A height-aware exponential fog that tints toward the sky colour along the view ray (warm toward the sun, cool away) is cheap and already in our reused uber-shader (`G` uniforms). The full LUT approach (Bruneton/Hillaire, see the installed `threejs-atmosphere-aerial-perspective` skill) is overkill for a toon look.

### Decisions for this game
1. **Ground**: 6 × 6 km heightfield, 16 tiles of 1.5 km, each with 3 LOD meshes (129² / 65² / 33² verts). Field colours come from a procedural patchwork mask in the ground shader (no textures).
2. **Props** (trees, hedges, sheep, houses): one `InstancedMesh` per prop type per tile, with 2 LODs (real mesh < ~800 m, cheap card/box beyond) and no shadows past ~600 m.
3. **Village**: houses built procedurally from a few part geometries and merged per village block (static), 1 draw call per block per material. Church/windmill as our own Blender GLBs.
4. **Far forest**: instanced camera-facing painted cards (simple impostors) beyond 1.5 km. Set explicit bounding spheres.
5. **Clouds**: reuse Bay Ride's painted cumulus (`cloudPaint.ts`, `sky.ts`): layered sprites at 3 heights (~250 m, ~600 m, ~1,100 m) so the player can rise *through* the lowest. No raymarching.
6. **Haze**: reuse the uber-shader fog, strengthened with height, tinted by time of day. It doubles as the LOD cross-fade.
7. **Budget**: < 250 draw calls, < 1.5 M tris on screen, 60 fps on the RTX 4060 at 1600×900, render scale 1 with SMAA.

---

## c. Calm and wonder: research → design

| Research | Finding | Design ideas |
|---|---|---|
| **Attention Restoration Theory**: S. Kaplan (1995), *The restorative benefits of nature*, J. Environ. Psych. 15, 169–182. https://en.wikipedia.org/wiki/Attention_restoration_theory · https://psych.utah.edu/_resources/documents/psych4130/Kaplan_S.pdf | Directed attention fatigues. Natural scenes restore it through *soft fascination*: clouds, leaves and water hold attention effortlessly and leave room for reflection. Other ingredients are *being away*, *extent* (a world that feels large and coherent) and *compatibility*. (Critique: Joye & Dewitte 2018 argue the constructs are loosely defined.) | 1) Fill the view with slow, gently moving, low-contrast detail: cloud drift, cloud shadows sliding over fields, tree sway, sparkle on the river. Never anything that *demands* a look (no flashing, no pop-ups). 2) *Extent*: the world must keep going to a hazy horizon in every direction, with no visible edge. |
| **Awe**: Keltner & Haidt (2003), *Approaching awe*, Cognition & Emotion 17(2), 297–314. https://pubmed.ncbi.nlm.nih.gov/29715721/ | Awe needs **perceived vastness** plus a **need for accommodation** (something the mind has to stretch to take in). | 1) Planned reveals: rising through the cloud deck into open golden light, and a slow camera pullback from the basket to the whole valley (cinematic mode). 2) Scale cues: tiny sheep, toy houses and distant balloons at several depths, so vastness reads at once. |
| **Views of nature**: Ulrich (1984), *View through a window may influence recovery from surgery*, Science 224, 420–421. https://www.wrrc.arizona.edu/sites/default/files/ulrich-view%20through%20a%20window.pdf | Patients with a view of trees had shorter stays, needed fewer strong painkillers and drew fewer negative nurse notes than patients facing a brick wall. | 1) Keep trees, water and sky in frame at every camera, never a wall of buildings. The village is small and embedded in greenery. 2) Water (river, lake) visible from most altitudes. |
| **Nature sounds**: Alvarsson, Wiens & Nilsson (2010), *Stress recovery during exposure to nature sound and environmental noise*, IJERPH 7, 1036–1046. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2872309/ | After a stressor, skin-conductance recovery was faster with nature sound (fountain + birdsong) than with road noise. | 1) The soundscape is synthesized wind plus distant birds, sheep, a church bell and water, mixed by altitude (birds and sheep fade as you climb, wind takes over). 2) The burner roar is the only loud sound. It is short, has a soft attack and release, and ducks nothing else harshly. |
| **Colour and arousal**: Valdez & Mehrabian (1994), *Effects of color on emotions*, J. Exp. Psych.: General 123(4). https://pubmed.ncbi.nlm.nih.gov/7996122/ · Wilms & Oberfeld (2018) https://www.staff.uni-mainz.de/oberfeld/downloads/Wilms-Oberfeld2018_Article_ColorAndEmotionEffectsOfHueSat.pdf | Arousal rises with **saturation** and falls with brightness. Pleasure rises with brightness. | 1) Grade: medium saturation, high value, warm-biased midtones. Keep fully saturated colour for small accents only (balloon envelopes, roofs). 2) No pure black: lift shadows toward warm violet/blue, as in Shinkai skies. |
| **Fractal fluency**: R. Taylor et al. (U. Oregon). https://bpb-us-e1.wpmucdn.com/blogs.uoregon.edu/dist/e/12535/files/2016/02/Fractal-Fluency-Chapter-1mjdxj5.pdf | Mid-complexity fractals (D ≈ 1.3–1.5), like clouds, coastlines and tree canopies, are processed fluently and linked to lower physiological stress. (Effect sizes come mostly from secondary reporting.) | 1) Cloud silhouettes, field boundaries, river meanders and tree-cluster edges use 2–3 octaves of noise. Not perfectly smooth, not busy. 2) The patchwork fields are irregular polygons, never a ruled grid. |
| **Pace** (applies the above) | Low arousal needs slow change and no time pressure. | 1) The camera eases at every transition (≥ 1.5 s blends), and there is no screen shake. 2) Time-of-day changes cross-fade over ~4 s. No timers, no fail states. |
