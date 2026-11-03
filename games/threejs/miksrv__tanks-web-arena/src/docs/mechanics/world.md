# World

Code: `src/world/terrain/`, `src/world/props/`, `src/world/buildings/`; numbers: `WORLD`, `WORLD_HALF`, `TERRAIN_RES`

## Terrain

- World ±450 m, heightmap 256 × 256 (≈ 3.5 m per cell), bilinear sampling; beyond the edge — a wall.
- The base terrain is baked into the grid: `17 · k · fbm(0.0038) + 2 · noise(0.03)` (k = 0.75–1.2 per map), then thermal erosion: soil slides off any slope steeper than `maxSlope` = 0.3 (≈ 17°) until none remain. High hills become plateaus with passable slopes, lowlands become flat basins; the height range is preserved. Height = `8 + terrain`; along the perimeter (110 m) mountains up to +70 m with noise (outside erosion), snow above ~50 m.
- Bases (r 70) and settlements (village r 50, city r 95) are flattened to their mean height; the transition to natural terrain is stretched over 0.55–1.7 r so there is no cliff at the boundary.
- A river is present on roughly half the maps (`riverChance`); without a river — three open passages and a city in the centre. Meander `x = 45·sin(0.011 z + φ) + 25·noise`, width 18 m, bed −3.9, water at −1.5; at the fords (z = 0, ±215) the bed is raised to −2 — passable with slowdown. The banks rise to the surrounding terrain over 60 m, mud strip ±16 m.

## Map archetypes (`ARCHETYPES`, `src/world/terrain/style.ts`)

First the terrain type is picked (randomly by weight); it sets the relief, seasons, number of forests, villages, lakes, swamps, bushes and haystacks, and the chance of a river and a railway (the archetype, its season, revetments, the sea side and the railway are rolled from a separate RNG; weather and mode from their own):

| Archetype              | Weight | Relief                                     | Special                                                                                |
| ---------------------- | ------ | ------------------------------------------ | -------------------------------------------------------------------------------------- |
| central Russia (mixed) | 44 %   | as before                                  | river 50 %, railway 30 % on dry maps                                                   |
| steppe                 | 16 %   | almost flat, gullies up to 6.5 m           | 1–4 forests, fields, 70 haystacks, river 30 %, railway 90 %                            |
| swamps                 | 14 %   | plain                                      | 11–16 forests, 5–8 swamps (water 0.5–1 m, passable slowly), corduroy roads; dark water |
| mountain pass          | 12 %   | ridge +24 m across the axis, three saddles | no river; crests rocky, snow-covered in winter                                         |
| coast                  | 14 %   | as central Russia                          | one flank runs into the sea with a beach (sand 0.85), no mountains on that side        |

- Gullies: zeros of low-frequency noise, cut 6.5 m down; after erosion — gentle hollows ~45 m wide.
- Swamps: a shallow bowl with a flat boggy shore (mud up to 1.45 r); unlike lakes they can lie across a road — the road then runs on a corduroy-road embankment (`withCauseway`).
- Mountain pass: the ridge height falls off from 55 to 210 m from the centre line, saddles 28–85 m wide exactly on the lane lines (lane anchors have no lateral scatter).
- Coast: from 240 m from the axis towards the sea the ground drops to a seabed of −6.5 m by 330 m; the water plane is 6 times wider than the map, the sea runs to the horizon. Villages, forests, lakes and swamps keep away from the beach (centre no farther than 210 m − radius); river crossings are shifted away from the sea.

## Railway (`src/world/terrain/railway.ts`, `RAIL`)

- Straight along the line equidistant from the bases (across the axis, through the middle), from the foot of the mountains to the foot (on the coast — to the beach). Railhead = smoothed profile of the natural terrain (window ±80 m, three passes) + 1.8 m: an embankment over lowlands, a cutting through high ground; crest 7 m, slopes 0.45 (passable slowly), at the ends the embankment tapers to nothing.
- At roads (8–22 m) the embankment drops to ground level — level crossings; through the city (centre) it runs at street level, the ruins, church and workshops keep clear of the tracks. Villages, forests and lakes — farther than 18 m + radius.
- Sleepers every 1.6 m, rails in 6 m pieces following the terrain; 1–2 freight trains of 3–6 wagons stand on the tracks outside crossings and bases — hard cover (full-height collider).

## Revetments (`features.revetments`, 50 % of maps, `src/world/buildings/revetments.ts`)

- An earthwork "U" 1.25 m high with sandbags on top, open to the rear: a frontal bank of 8.5 m and two side banks of 6 m. 2–3 in front of each base facing the enemy and two on the high ground of each half. Placed only on flat open ground no closer than 30 m to roads and lane points (so bots on the march do not drive into the "U"); they cover the hull, the turret fires over the top.

## Weather and time of day (`WEATHER`, `src/render/environment.ts`, `src/fx/precipitation.ts`)

- Rolled from a separate RNG by season: clear, overcast, dawn, dusk, fog, rain (summer, autumn), snowfall (winter). Changes the tint of the sky and fog, the light (at dawn and dusk a low sun from its own side and long shadows), the fog distance (fog — 22 % of normal) and the view range of all vehicles (see spotting).
- Rain and snow: 2600 / 2200 particles in a box around the camera, movement entirely in the shader (one draw call, no buffer uploads); hidden in the top-down view. Rain makes noise (looped filtered noise).

## Named maps (`MAP_PRESETS`)

A fixed seed with archetype, season and weather: «Прохоровка» (Prokhorovka), «Курская дуга» (Kursk Bulge; steppe), «Полесье» (Polesia; swamps, fog), «Перевал» (The Pass; winter, snowfall), «Керчь» (Kerch; coast), «Ржев» (Rzhev), «Орёл» (Oryol), «Малиновка» (Malinovka). Selected in the garage; the mode is chosen separately.

## Terrain styles and seasons

- Style (`relief_`): hills (as above), plain (amplitude ×0.4, wider waves), ridges (ridged noise stretched 3:1 in a random direction: long crests and troughs), valley (a lowland along the base-to-base axis, rising towards the flanks by +16 m at 110–420 m from the axis). Erosion with slope ≤ 0.3 is applied to all of them.
- Season (`season`, 50/25/25 %): summer, autumn, winter. The ground and minimap palette is in `PALETTE`; sky, fog and light in `SKY` (`src/render/environment.ts`). Tree crowns are coloured via instanceColor by species: in summer green with variation (birch and willow lighter, oak and spruce darker), in autumn deciduous trees from red to yellow (birch and poplar yellow, oak brown), in winter deciduous trees are bare (brown, smaller), conifers stay green. In winter the snow on the mountains sits lower, bushes and haystacks are faded, water is dark and matte.
- The share of fields and meadows on the map is random (`zoneCut`).

## Map features (`features`)

- Centre: city ruins (65 %) or a factory district (35 %): up to five brick workshops with rows of windows (one destroyed, with rubble), a 24 m chimney, a brick yard wall with gaps. A workshop picks its position, shifting away from the river and roads.
- Villages: a church (70 %; on maps with chapels — a chapel) or a well; stone walls (50 %, OBB 1.1 m high, hull-down cover); an orchard (45 %, a 5×5 grid of low trees nearby).
- Farmsteads (65 % of maps, 1–3): a log house (or a brick house) and a barn facing each other, a fence, sometimes a wall and an orchard; terrain flattening as for villages (r 22).
- Windmill (45 %): the highest open point out of 60 candidates away from the river, roads, forests and lakes; tower, roof, four sails.
- Pillboxes (50 %): concrete boxes 7×5.5×2.4 m with an embrasure, one on each side of the lane halfway to the crossing, offset 17 m sideways from the road.
- Anti-tank obstacles (40 % Czech hedgehogs, 25 % dragon's teeth): rows on both sides of the road halfway to the crossing, the road itself stays clear; for collisions and shells they are "rocks" of r 1.1.
- Avenues (50 %): trees of the map's avenue species every 11 m on both sides of some roads, outside settlements and crossings.

## Biomes

Written into the grid: field (furrows, direction per 90 m cell), meadow, forest, mountain, road, water, mud, village, city, base, sand (beach), railway (ballast). They determine the vertex colour and the speed factor.

## Roads and lanes

- A route to every crossing (or to each of the three passages when there is no river): base → base gate → two intermediate points → crossing → two points → gate → base. The gates are spread 45 m apart across the axis and 40 m from the base centre, so roads do not converge on a single point; the intermediate points are shifted sideways by ±35–45 m, so roads wind.
- A road is a Catmull-Rom spline through all points with a 12 m step (`smoothPath`); the sections between fixed points (embankment and bridge deck) stay straight. Road biome width 9 m. The nearest-road lookup goes through a 48 m grid (exact within a 24 m radius), distant queries scan all segments.
- The same routes (coarse points, no spline) are the lanes for bots.
- Lakes only in lowlands: centre below 13 m and the ring at 2.5 r below 15 m; a basin around the lake: the ground is held no higher than water level + 4 m out to 1.4 r and returns to natural terrain by 2.8 r. The river bank is stretched if the surrounding ground is high; the side slopes of bridge embankments widen in proportion to the height (gradient ≤ 0.33).

## Settlements

- 2 villages: a church with a dome and a cross (or a chapel, or a well) in the centre, 8–11 log houses and barns along two crossing streets, windows, chimneys, fences around. Depending on the map's building kit (see below) some of the log houses are two-storey brick houses, the barns are kolkhoz warehouses, and one village has a water tower.
- The city at the central ford: a grid of 26 m blocks, ruined shells of houses (walls of random height, some demolished, window openings, piles of rubble), a half-ruined church with a tower, the main street along the ford.
- Every building is an OBB with height: cannot be driven through, shot through or seen through.

## Tree species and building kit (`FLORA`, `BUILDING_KIT`, `rollFlora`/`rollKit` in `src/world/terrain/style.ts`)

Each map takes only a limited set out of the eight species and four new buildings, so maps differ from one another. Both rolls come from their own seed-based RNGs (`terrain.flora`, `terrain.kit`) and do not shift the map layout.

| Species | Where             | Look                                                  |
| ------- | ----------------- | ----------------------------------------------------- |
| pine    | conifer           | cone, reddish trunk                                   |
| spruce  | conifer           | three tiered cones, dark                              |
| linden  | deciduous, avenue | rounded crown (the former "deciduous")                |
| birch   | deciduous, avenue | narrow elongated crown, white trunk, yellow in autumn |
| oak     | deciduous         | wide low crown, thick short trunk, brown in autumn    |
| poplar  | avenue            | tall column (≈ 14 m)                                  |
| willow  | by water          | dome with drooping branches, low thick trunk          |
| apple   | orchards          | low wide crown                                        |

- Roles: the conifer species (pine / spruce), deciduous (linden / birch / oak), avenue (linden / birch / poplar) and willow by water — by archetype weights (`FLORA`): steppe — pine, oak, poplars; swamps — spruce, birch, often willow; mountain pass — mostly spruce; coast — pine, oak or linden, poplars. The share of conifers in forests is also specific to each map (`coniferShare`).
- Willow is rolled instead of a separate avenue species (avenues are then made of the map's deciduous species), so a map has 2–3 species plus apple trees in orchards. Willows grow in forests and among the lone trees within ~30 m of a river, lake or swamp; if there are fewer than 15 of them on the map, they become the map's deciduous species (a separate mesh is not worth a handful of trees).
- Buildings (`BUILDING_KIT`): a chapel instead of the village church (35 % of maps; whitewashed, with a bell tower and a spire); two-storey brick houses (50 % of maps, 15–40 % of village log houses and farmstead houses); kolkhoz warehouses instead of village barns (50 %; 9–10 × 17–21 m, placed only if all corners are on dry ground off the roads); a water tower at the edge of the first village (45 %; brick shaft, wooden tank, 15 m). All are OBBs with height, like the other houses: cannot be driven through, a shell hits the box, they block view.

## Props (InstancedMesh)

- Trees: in forests (density 0.02/m²) the map's conifer and deciduous species, 260 lone trees across the map, avenues, orchards. The trunks of all species — one InstancedMesh (scale and bark colour per instance), crowns — one mesh per species, and only for the species present on the map: usually 3–4 crown meshes + trunks (previously 2 + 2). A tank fells a tree on contact (1.1 s fall animation in the direction of travel), slowing to 0.7. Shells ignore trees.
- Bushes: 60 shrub clusters of 3–8 at forest edges and in meadows; standing in a bush = +0.35 camouflage.
- Rocks: 70, in the mountains and meadows; impassable, they stop shells flying below their top (rock ~1.1 r, hedgehogs and dragon's teeth 1.5 m): a shell passing over a rock flies on.
- Haystacks (35, in fields) get crushed; fences in villages get knocked down.

## Performance

- Frame cap: 60 in battle, 30 in the garage (`RENDER` in `src/config/render.ts`); frames are scheduled with a 1/60 s step, so on 75–240 Hz displays the result is an even 60 fps (`src/render/framePacer.ts`).
- Render resolution is adaptive: scale 0.75–1.25 × devicePixelRatio (not above 1.25). If over a second the frames are on average 30 % longer than the target (1/60 s; on 60 Hz that is ≈ 30 % of vsyncs missed) — the scale drops by 0.125; if the overshoot is < 5 % — it rises after a pause (6 s, doubled on every rollback). The current scale is shown in the `P` overlay. Particle size accounts for the render scale and does not change along with it.
- Shadows PCF 2048², the terrain casts no shadows (only receives them). The next map is generated during the result screen, shaders are compiled at startup.
- The HUD writes only changed values to the DOM; the minimap updates 20 times a second, the scoreboard (Tab) — 4 times.
