# Response to the Phase 4 final critique (`p4-final.md`)

New frames: `shots/p5/` (all eight spots at the four times, plus `og*` and `mobile_*`). Re-recorded cinematic: `recordings/balloon-ride-cinematic.mp4`. Every capture ran on `ANGLE (NVIDIA GeForce RTX 4060 … D3D11)` with no console or shader errors.

## B1. `down*` had no clouds: fixed
- **New cloud layer, `low wisps`** (`src/world/cloudlayers.ts`). It holds 90 small scud puffs with a base at 140–185 m, a half width of 20–64 m and 28–36 lobes each. Most puffs bring one or two smaller companions 140–260 m away, so they drift in loose groups rather than as single dots. The layer has its own wind (the low, easterly layer) and wraps on a 5 km period. The existing puff and cumulus layers keep their seeds and layouts.
- **Believable heights:** from the 300 m `down` eye, the wisps float 120–160 m below the basket, above the roofs. From 500 m they read as a scattered low deck under the bigger puffs at 250–330 m and the cumulus at ~600 m. That is three cloud levels plus the cirrus.
- **The `down` spot** stays at 300 m over the village, with the same eye and heading. It now searches the frozen clock, deterministically, for the moment a drifting wisp crosses the upper left of the view and another wisp's shadow falls on the fields. The clock only changes drift and small animation.
  - In all four `down*` frames, a puff group sits between the basket and the village.
  - In `down` and `down_sunrise`, cloud shadows cross the village and the fields.
  - Blue hour correctly has no shadows, because they fade out at dusk.
- **Cloud shadows were too faint to read.** This was the real reason no shadow ever showed in `down`.
  - The old falloff scaled with the cloud's size, so a big cloud's shadow edge was smeared over hundreds of metres and the darkening was mostly lost in the tone map.
  - The edge is now a fixed ~30 m painted ramp, and the shade is a deeper cool tone (`landMaterials.ts`, `cloudShadow`).
  - Shadows now read as shapes on the fields at every altitude.

## B2. Blurry, flat-based slabs near camera height: fixed
- **Rounded bottoms.** Each cloud lobe is still a ray-traced impostor, but now it is a sphere above its centre and a squashed half-ellipsoid below it (vertical semi-axis 0.6 R). This replaces the old cut plane and its 0.22 R blurred fringe.
  - Seen from the side, a cloud's base is a row of slightly flattened, rounded billow bottoms.
  - From below it is a lilac-shaded underside, with no ruler line anywhere.
- **Soft edges at every distance.** The rim softness is now pixel-based: `fwidth`, about two pixels wide, with no 6 %-of-radius minimum.
  - That minimum was the "out-of-focus" look on big, close lobes, where 6 % of a 150 m lobe is dozens of pixels.
  - The ragged edge noise is kept.
- **The near plane and depth fade were checked.** Lobes are culled only when the eye is inside them (then the whiteout takes over), and the quad keeps its angular size off the near plane.
  - The distance fade is now a shrink. The alpha stays opaque until the last ~30 % of the fade (`min(1, f*3)`), so no cloud is half transparent.
  - The cloud haze starts at 900 m and caps at 60 %, where it was 500 m and 75 %. Distant cumulus stay painted instead of muddy.
- **The 500 m spot** now chases at a 16° pitch instead of 24°.
  - The mid cumulus are no longer sliced by the frame top. They show whole, with lit crowns, cauliflower bumps and rounded shaded bases over the hills (`500m*`).
  - The low puffs and the wisps lie below. Together that is the layered view.
- **Cinematic ending.** The last two keys are now 230 m (at 45 s) and 420 m (at 50 s), up from 210 m and 320 m. The camera finishes above the low puffs instead of level with one.
  - At 48 s, a puff drifts below with its crowns, bumps and lilac shade, over the village and fields. There is no blob filling the top right.

## B3. Flat `cloud_sunrise` puff: fixed
- **Painter's key light.** When the sun is behind the viewer, the key now swings to the side and slightly up, and the lit band narrows. A front-lit cloud keeps a shade side and shaded billow undersides, where before it had its terminator on its outline (`cloudlayers.ts`, the `fr` terms).
  - This only kicks in for front light, so the golden, sunset and blue puffs that already passed are unchanged.
- **Sunrise palette.** The mid and low tones sat next to the top tone in value. They are now a real step down to a cool lilac-grey (`timeofday.ts`: `cTop` 1.0/0.89/0.77, `cMid` 0.68/0.71/0.82, `cLow` 0.40/0.45/0.60).
- **Result:** `cloud_sunrise` shows a peach-cream lit crown, a lilac shade side and shaded bumps.

## B4. Glossy blue-hour backdrop with pink blotches: fixed
`cloudPaint.ts` (the painted backdrop cards) gets a night factor, `smoothstep(0.6, 1.0, uNight)`. At blue hour:
- The warm underside band is cut by 92 %. That band was the pink blotches where the banks met the hills.
- The silver lining is off, and the rim is down 75 %.
- The lit and shade tones are pulled together, so the clouds are matte.
- The haze toward the horizon uses the cool dusk air instead of the pink afterglow.
- The cloud is clamped below the sky colour behind it, so it never outshines the sky.

**Result:** in `50m_blue`, `200m_blue` and `basket_blue`, the banks are dim, cool, matte silhouettes against the afterglow, with no gloss and no glow at their bases. The near indigo clouds are unchanged.

## B5. White starburst "windmill" seen from above: fixed (it was not the windmill)
- **The cause was not the windmill.** Ray-projecting the pixel and bisecting the scene meshes showed that the starburst at (1370, 540) was a dandelion tuft from the wind particles (`windfx.ts`) about a metre from the lens.
  - The pappus is drawn as a 14-filament star with additive blending, so up close it filled ~30 px as a self-lit star.
  - The real windmill is at (385, 465) in `500m` and was always shaded normally.
- **The fix:**
  - Tufts and motes now fade in between 5 and 11 m from the camera, where they used to fade in at 1–3 m. No tuft can sit on the lens.
  - At night they nearly vanish (alpha × (1 − 0.9 uNight)), and their colour is dimmed.
- **Result:** the starburst is gone from every `500m*` frame. The windmill reads as a small matte mill with four sails on its hill.

## Also checked (no regressions)
- **All eight spots at four times, and mobile portrait and landscape.** The ground, burner, basket, 50 m and 200 m frames match p4 apart from the new low wisps in the sky.
- **Draw calls:** at most 107.
- **Programs:** 76.
- **The cinematic:** 3000 frames, 50.0 s, 1920x1080 at 60 fps, h264 (NVENC). The frames at 2, 20 and 48 s were viewed.

## Nice-to-haves touched
- **Dark motes:** these were partly near-lens fluff. The near fade and the night dimming should reduce them, but I did not zoom-check this separately.
- **Not done:** the burner inner disc, the basket floor and rim sliver, the sunset river, the lime hedges, the player balloon at the end of the cinematic, mobile FXAA and the bell tierce.
