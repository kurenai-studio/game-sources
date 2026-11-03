# Tanks

Code: `src/tank/tank.ts`, model: `src/tank/tankView.ts` and `src/tank/model/`, stats and look: one file per vehicle in `src/config/vehicles/ussr/` and `src/config/vehicles/germany/` (garage order — the nation's `index.ts`)

## Vehicles

| Vehicle         | Class  | HP   | Speed   | Armour hull / turret (front/side/rear) | Gun                                     | Penetration / damage / reload | View range | Camouflage |
| --------------- | ------ | ---- | ------- | -------------------------------------- | --------------------------------------- | ----------------------------- | ---------- | ---------- |
| T-70            | light  | 420  | 47 km/h | 50/25/20 · 45/30/25                    | 45 mm                                   | 62 / 55 / 2.4 s               | 400        | 0.28       |
| T-34-85         | medium | 760  | 54      | 95/55/45 · 90/75/52                    | 85 mm                                   | 128 / 185 / 5.6               | 380        | 0.16       |
| IS-2            | heavy  | 1250 | 36      | 155/90/60 · 110/95/90                  | 122 mm                                  | 178 / 390 / 11.5              | 350        | 0.07       |
| SU-100          | TD     | 820  | 47      | 110/45/45 (casemate)                   | 100 mm, ±9°                             | 178 / 300 / 7.5               | 370        | 0.30       |
| SU-122          | SPG    | 480  | 40      | 60/45/40                               | 122 mm howitzer, ±10°                   | 50 (HE) / 450 / 14            | 300        | 0.20       |
| Pz. II Luchs    | light  | 400  | 58      | 35/25/20 · 35/25/20                    | 50 mm                                   | 72 / 70 / 2.7                 | 410        | 0.26       |
| Pz. IV H        | medium | 720  | 41      | 85/35/25 · 55/35/30                    | 75 mm                                   | 118 / 140 / 4.3               | 390        | 0.14       |
| Tiger I         | heavy  | 1200 | 38      | 105/82/82 · 110/82/82                  | 88 mm                                   | 150 / 245 / 7.2               | 370        | 0.06       |
| KV-1 753(r)     | heavy  | 1100 | 31      | 95/75/70 · 95/75/75                    | 75 mm KwK 40 L/48 (captured KV-1)       | 118 / 140 / 4.4               | 350        | 0.07       |
| StuG III G      | TD     | 780  | 40      | 95/35/30 (casemate)                    | 75 mm, ±10°                             | 118 / 140 / 4.0               | 370        | 0.32       |
| Hummel          | SPG    | 450  | 40      | 40/25/20, open casemate                | 150 mm howitzer, ±8°                    | 55 (HE) / 620 / 18            | 300        | 0.20       |
| T-60            | light  | 340  | 43      | 35/15/15 · 25/15/15                    | 20 mm autocannon                        | 35 / 14 / 0.55                | 390        | 0.34       |
| T-34-76         | medium | 680  | 54      | 95/55/45 · 70/60/50                    | 76 mm                                   | 86 / 115 / 3.9                | 370        | 0.18       |
| KV-1            | heavy  | 1100 | 31      | 95/75/70 · 95/75/75                    | 76 mm                                   | 90 / 115 / 4.2                | 340        | 0.07       |
| KV-2            | heavy  | 1150 | 27      | 95/75/70 · 75/75/70                    | 152 mm, HE by default, splash 5 m       | 75 / 700 / 20                 | 330        | 0.04       |
| SU-85           | TD     | 760  | 49      | 95/45/45 (casemate)                    | 85 mm, ±10°                             | 128 / 185 / 5.2               | 360        | 0.31       |
| SU-76M          | SPG    | 380  | 47      | 35/15/15, open casemate                | 76 mm howitzer, ±15°, splash 4 m        | 40 (HE) / 250 / 5.5           | 300        | 0.26       |
| SU-152          | TD     | 950  | 34      | 75/60/60 (casemate)                    | 152 mm, ±10°, splash 5 m                | 125 / 700 / 16                | 340        | 0.20       |
| Pz. II F        | light  | 330  | 40      | 35/20/15 · 30/15/15                    | 20 mm autocannon                        | 35 / 14 / 0.55                | 380        | 0.32       |
| Pz. III J       | medium | 560  | 50      | 60/30/30 · 55/30/30                    | 50 mm L/60                              | 85 / 70 / 2.4                 | 380        | 0.20       |
| Panther D       | medium | 1000 | 47      | 135/45/40 · 100/45/45                  | 75 mm L/70                              | 170 / 140 / 5.0               | 390        | 0.10       |
| Marder III      | TD     | 420  | 43      | 25/12/10, open casemate                | 76 mm Pak 36(r), ±16°                   | 125 / 160 / 5.0               | 370        | 0.36       |
| Nashorn         | TD     | 620  | 43      | 30/20/20, open casemate                | 88 mm L/71, ±15°                        | 200 / 245 / 7.5               | 380        | 0.30       |
| Ferdinand       | TD     | 1400 | 25      | 200/80/80 (casemate)                   | 88 mm L/71, ±14°                        | 200 / 245 / 7.2               | 350        | 0.05       |
| Wespe           | SPG    | 380  | 45      | 30/15/10, open casemate                | 105 mm howitzer, ±17°                   | 45 (HE) / 380 / 10            | 300        | 0.24       |
| StuH 42         | TD     | 760  | 40      | 80/30/30 (casemate)                    | 105 mm, HE by default, splash 4 m, ±10° | 64 / 380 / 9                  | 360        | 0.30       |
| BM-13 Katyusha  | SPG    | 300  | 58      | 10/8/8, ZiS-6 truck                    | 16 × 132 mm rockets, ±10°               | 30 (HE) / 130 × 16 / 28       | 320        | 0.22       |
| Panzerwerfer 42 | SPG    | 320  | 50      | 10/8/8, half-track                     | 10 × 150 mm Nebelwerfer, ±13°           | 30 (HE) / 200 × 10 / 32       | 320        | 0.22       |

Gun types: regular (AP by default), SPG howitzers (`howitzer`: indirect fire, top-down view), "derp guns" (`derp`: direct fire, HE by default), autocannons (`bloomShot` 0.35: a burst barely opens up the reticle) and rocket launchers (`salvo`: one press launches a series of rockets at 0.1 s intervals along the current position of the rails, each with its own dispersion; HE only; howitzer ballistics). The team composition is picked by roles, the vehicle within a role is chosen at random.

Armour is given "effective" against a vertical plate: the slope of the front plates of the T-34, IS-2 and SU-100 is already included in the number. Roof 10–30 mm — for splash and indirect fire.

## Movement

- Throttle W/S: target speed = `speed · surface · slope`, acceleration `accel` (braking ×2.2). Surfaces: road 1.15, field/meadow 1, forest 0.85, ruins 0.75, mud by the river 0.6, ford 0.35; deeper than 1.3 m — a wall.
- Climbing: −4.5 % speed per degree; a slope steeper than 31° — a wall. The slope also stops reversing.
- Houses, walls, rocks, tree trunks: the hull is pushed outward and slides along the obstacle; the speed is damped proportionally to cos² of the angle between the heading and the normal (×4 1/s), so at a tangent the tank drives almost without losing speed, while head-on it stops against it.
- Hull turn `hullTurn` rad/s, ×0.65 at full speed; in reverse the steering is mirrored. A knocked-off track — no driving, no turning.
- Suspension: each track is sampled at five points along its length (±0.4 L), a line is fitted through them; pitch is the average slope of the two lines, roll is the difference of their heights at the centre (limited to ±34°), hull height is the average of the two tracks, but not lower than the ground under the centre − 0.15 m. Smoothed over time (14/s). The bridge deck counts only when the hull centre is on it (then the support is flat). Road wheels spin by the distance travelled.
- Collisions: houses and rocks (OBB/circles) push out at three hull points; tanks are circles with mass = HP; trees fall at speed ≥ 2.5 m/s (slowdown 0.7), slower — the trunk simply stops the tank, haystacks are crushed, fences are flattened.

## Turret and gun

- The turret target is the aim point (for the player — the camera ray through the screen centre; while RMB is held, the aim is kept and «обзор» (look around) lights up under the reticle). The turret traverses at `turretTurn`.
- Turretless vehicles: sector `±arc`; if the target is outside the sector and there is no manual steering, the hull turns itself.
- Elevation/depression by class (−5…−8° / +16…+17°, howitzers up to +69°), speed 1.5 rad/s.

## Model (`tankView.ts`, `src/tank/model/`)

Each vehicle describes its look in its own file, in `shape`. The top-level dimensions (`hullL/W/H`, `tW/tL/tH/tZ`, `trackH`) are also the hitboxes; the rest affects only the look. Model coordinate system: +z forward, +y up, +x — left side.

- `hullLook` — hull: side profile `outline` (normalised: z 0 = rear … 1 = nose, y 0 = fender line … 1 = roof), `roofW` — narrowing towards the roof for sloped sides (T-34, Panther), `lowerNose` — lower glacis between the tracks, `drums` — external fuel tanks, `spareTracks` — spare track links on the front, `skirts` — side skirts.
- `turretLook` — turret or casemate: `welded` (a profile extruded across the width with side slope `roofW`) or `round` (cast/faceted, `facets` faces: 6 — the T-34 "nut", 8 — T-60, 12 — cast), `bustle` — rear bustle, `x` — turret ring offset (T-60/T-70 — to the left), `cupola` — commander's cupola, `twinHatches` — two hatches, `stowage` — a box on the turret rear, `skirts` — turret side skirts (Pz. IV H), `sideTracks` — track links on the turret sides (Tiger), `mountY` — trunnion height.
- `gunLook` — mantlet (`box`, `round`, `ball`, `saukopf`, `shield`), muzzle brake (`none`, `single`, `double`, `multi`), `sleeve` — recoil system sleeve.
- `running` — running gear: `tracks`, `halftrack` or `truck`; number and radius of road wheels, `layout` (`even`, `paired` — bogies of the Pz. IV and Ferdinand, `interleaved` — staggered on the Tiger, Panther, Luchs), return rollers, drive sprocket at the front (Germans, T-60/70, SU-76) or at the rear (T-34, KV, IS, Ferdinand), truck axles.
- The upper hull is drawn from the fender line, the roof is at height `trackH·0.72 + hullH`; the upper run of the track with its rollers is visible. The track band is a profile around the idler, the drive sprocket and the road wheels.
- On TDs and SPGs the casemate is part of the hull, only the gun turns (within the `arc` sector) around its mantlet; on turreted vehicles the whole turret turns.
- Details: exhaust at the rear plate, headlight on the nose, antenna, tow hooks, spares and tools stowage on the fender.
- Paint: 4BO (USSR) / dunkelgelb with green patches (Germany), per-vertex noise; Balkenkreuz on the hull and turret (on the Tiger — hull only), a red star on the turret or casemate (on the T-34-76 with the faceted turret — on the hull side).
- Everything static is three meshes (hull with casemate, turret, gun) with vertex colours and one material per tank, road wheels are a single InstancedMesh (tyre + painted disc); about 1000–1600 triangles per vehicle. Wrecks — dark colour, turret tilted.
