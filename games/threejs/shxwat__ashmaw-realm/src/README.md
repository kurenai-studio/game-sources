# ASHMAW — Realm of the Emberwyrm

A real-time cinematic WebGL fantasy: an ancient volcanic kingdom ruled by a giant
dragon. ~13k lines across 45 modules, **zero assets of any kind** — no models, no
textures, no rig. Every mesh, texture, normal map and sprite is synthesised in
code at boot. The whole repo is ~600 KB of source and two CDN imports.

```bash
git clone https://github.com/shxwat/ashmaw-realm && cd ashmaw-realm
python3 -m http.server 8000      # or: npx serve -p 8000
open http://localhost:8000
```

No build step. Native ES modules + an import map (three r169, GSAP from CDN).
Requires WebGL2.

---

## Controls

| | |
|---|---|
| `1`–`5` | camera: cinematic · orbit · follow dragon · free flight · walk |
| `C` | restart the cinematic sequence · `V` next shot |
| `F` | breathe fire · `L` land · `T` take off · `R` roar |
| `E` | erupt the volcano |
| `X` cycle weather · `N` moonlight · `[` `]` nudge time of day |
| `Space` pause · `H` hide UI |
| walk/free | `WASD` move, `Shift` run, mouse look (click to capture), `Esc` release |

Camera, weather and the dragon's actions are also on the HUD. Render-effect
toggles and quality-tier buttons were deliberately removed from it — they are
instrumentation for developing a renderer, not controls for watching a dragon.
Quality is auto-detected at boot (`detectTier()`) and then adapted at runtime by
`PerfMonitor`; `App.setFx()` and `App.setQuality()` still work from the console.

---

## Architecture

```
src/
  core/        App (composition root), Settings (quality tiers), EventBus, PerfMonitor
  loaders/     AssetLoader — GLTF + DRACO + KTX2 + RGBE, wired but unused (see below)
  shaders/lib/ noise.glsl.js (simplex/fbm/ridged/curl/voronoi + fire & lava ramps)
               wind.glsl.js  (one gust field shared by all vegetation and cloth)
  materials/   GlobalUniforms (shared uniform objects), ProceduralTextures (the
               texture forge), MaterialLibrary (+ injectWind / injectAmbient)
  scene/       Sky (analytic dome → PMREM env), Clouds (two decks + ground fog)
  lights/      LightRig — key/fill/rim/caldera/hero, shadow-frustum tracking
  world/       Heightfield (the canonical landscape), Terrain, Ribbon, Lava,
               Water, Ocean (Gerstner), Volcano, Rocks, Vegetation, Birds
  structures/  Blocks (modular masonry kit), Castle, Village, Ruins, Torches
  dragon/      Dragon (procedural body), DragonAnimator (state machine),
               Flight (the lesser wyrms), FireBreath
  particles/   Atmosphere (ash/embers/dust/wind/leaves), Rain
  effects/     PostFX (the chain), CinematicPass (the grade)
  camera/      CameraRig, CinematicDirector (shot list), WalkController
  weather/     WeatherSystem — eight declarative presets, cross-faded
  events/      Eruption — the multi-system set piece
  ui/          UI — DOM ↔ event-bus translation only
```

**One source of truth for space.** `world/Heightfield.js` exposes `height(x, z)`
as a pure analytic function. The terrain mesh, every prop placement, the walk
controller's feet, lava channel depth, water level, camera collision and the
dragon's ground clearance all sample it — so nothing can ever disagree about
where the ground is.

**One source of truth for time.** `materials/GlobalUniforms.js` holds shared
uniform *objects*. Three compares uniform identity per material, so one write
per frame drives fifty materials. That's why the whole realm is in phase: trees,
grass, banners, awnings, torch flames and the volcano's plume all lean on the
same travelling gust.

**Systems talk over a bus**, never directly. The volcano doesn't know the camera
exists; it emits `SHAKE`, and the rig listens.

---

## What's actually interesting in here

**The dragon is not a model.** It's ~26 spine nodes, each a critically-damped
spring, re-skinned on the CPU every frame. The tail whips because it is genuinely
lagging; the neck overshoots because it is genuinely sprung. The wing is a 3-bone
arm with a *phase delay* down the chain (shoulder → elbow → wrist), which is the
entire reason it looks like it's pushing air rather than waving; the membrane
sags between four raked finger struts by an amount proportional to flap velocity,
so it billows on the downstroke and snaps taut on the up. Landing, takeoff,
banking and circling are all one continuous flight solver — states only retarget
scalars (speed, altitude, flap amplitude, wing spread) which GSAP eases, so
transitions come out looking authored without being authored.

**Fire lights the world for real.** `injectAmbient()` patches every opaque
material with a distance-attenuated, N·L-shaded term reading a shared fire
uniform. So when the dragon breathes, the village walls, the water, the statues
and the terrain all respond in the same frame — and the heat-distortion post pass
reads the same origin, so the refraction sits exactly on the flame.

**Lava is three ideas stacked**: fbm sampled at a position that moves downstream
(plates translate instead of shimmering), voronoi plate boundaries that crack
open to expose magma, and shear at the banks that drags the crust into streaks.

**The texture forge** synthesises every map from *periodic* value noise so it
tiles seamlessly, writing colour + height + roughness in one pass and deriving
the normal map by Sobel from that same height buffer — which keeps detail
perfectly registered across channels.

**LOD that actually culls.** The forest is diced into a 3×3 tile grid; each tile
owns detailed and reduced InstancedMeshes and swaps on camera distance. Three's
frustum culling then works per tile instead of all-or-nothing on one giant mesh.

**Torches**: 56 flames, 7 lights. The light pool is reassigned to the nearest
torches each frame with a distance fade, so pool churn is never visible.

---

## Post-processing

`RenderPass → SSAO → Bokeh(DoF) → Bloom → CinematicPass → OutputPass → SMAA/FXAA`

AO must multiply into the beauty pass before bloom reads it; DoF must precede
bloom or out-of-focus highlights lose their halation; the grade runs on linear
HDR so god rays and lens dirt *add* energy rather than clip; ACES tonemap and
sRGB conversion happen last, then AA on the LDR result.

`CinematicPass` is one fragment shader carrying god rays (luminance-masked radial
gather from the sun's screen position), heat distortion, directional motion blur
from camera velocity, chromatic aberration, lens dirt energised by frame
brightness, split-tone grade with a **shadow lift**, vignette and
luminance-weighted grain — one full-screen read instead of eight.

---

## Performance

Measured (Chrome/ANGLE-Metal, 1512×800, `high` tier): ~190 draw calls and ~850k
triangles on a wide establishing shot, rising to ~290 / 1.3M on a close chase
where the camera pulls more terrain and props into frustum. ~4.6 ms/frame.

The background flight is four extra dragons for 46 draw calls total — less than
the hero alone costs — because `Dragon` takes a `simple` flag that drops the legs
(28 of its 40 meshes) and shadow casting. CPU skinning was never the constraint:
0.077 ms per creature per frame.

Budgets live in `core/Settings.js`, auto-detected from GPU string and core count
and overridable in the HUD. `PerfMonitor` also does adaptive resolution: sustained
frames under the floor shave render scale rather than letting everything chug, and
it creeps back when there's headroom.

---

## Honest limitations

- **No SSR.** Water reflections are image-based (the live PMREM of our own sky)
  plus Fresnel, not screen-space ray marching. At grazing angles it's convincing;
  it will not mirror the dragon.
- **Motion blur is camera-only**, approximated from camera angular velocity —
  there's no velocity buffer, so fast-moving objects don't smear individually.
- **Volumetric lighting is faked** — god rays are a screen-space radial gather,
  and "volumetric" fog is soft billboards, not ray-marched media.
- **Wind displacement isn't in the shadow pass**, so foliage shadows don't sway
  with the leaves. Imperceptible in practice, but it is a real mismatch.
- **A quality-tier change doesn't rebuild the world.** Tree/particle counts are
  baked at boot; switching tiers changes resolution, shadows, post and light
  pools, not instance counts. Rebuilding would cost a multi-second hitch.
- **`AssetLoader` is plumbing for assets that don't exist yet.** DRACO/KTX2/RGBE
  decoders are wired and lazily instantiated, so dropping a compressed glTF into
  `/assets` and adding it to a manifest is a one-line change — but nothing ships
  through it today, which is why first paint is instant.
- **Contact shadows / true AO on foliage** rely on SSAO, which is screen-space
  and therefore misses off-screen occluders.

## Bugs worth remembering

Every one of these produced a dramatic, confusing symptom from a small cause, and
every one was found by measuring rather than by staring at the code.

1. **The dragon shook in flight — twice, for different reasons.**
   Bank rotates the whole body frame, so anything noisy in it becomes a full-body
   wobble. First version differentiated an already-smoothed heading and divided by
   frame time: unbounded derivative noise. The fix — take bank from the lateral
   component of the steering force — looked principled and was *worse*, because
   `steer` is the **control error** (desired velocity − actual velocity), a small
   difference of two nearly-equal vectors whose sign flips on every over- and
   under-shoot. Measured on a background wyrm in steady circling flight, bank
   swung between −0.59 and +0.59 rad continuously, at 40× the hero's frame-to-frame
   jerk. The hero only *looked* fine because its bank was saturated against the
   ±0.8 clamp, which pinned it and hid the identical oscillation.
   Bank now comes from the curvature of the flown path: low-pass the heading
   first, *then* differentiate. Smoothing a derivative doesn't work; differentiating
   a smoothed signal does. A coordinated turn then gives the angle in closed form,
   `tan φ = v·ω / g`, so there's no invented gain — and the measured bank now
   matches that prediction to within a few percent across every creature.

2. **Elliptical orbits advanced as if they were circles.**
   `orbitAngle += speed / r · dt` is only the arc-length rate when the orbit is a
   circle. On an ellipse `(r, r·ry)` the target point slowed to `ry` of nominal
   near the minor axis while the body was held at constant speed — so it overtook
   the target through the slow arc and fell behind through the fast one, every lap,
   forever. Eccentricity predicted the wobble exactly: `ry = 0.74` swung ±0.75 rad,
   `ry = 0.92` barely moved. Dividing by the true `|dP/dθ|` fixed it.

3. **`Spring3` sub-stepped with a frame-time-dependent step size.**
   `steps = min(4, ceil(dt / (1/90)))` makes the integration step a *discontinuous*
   function of frame time, and an explicit integrator's effective damping depends
   on that step — so the spine's response changed with ordinary browser jitter.
   Now solved in closed form. Reaching t = 0.5 s across eight different frame rates
   used to vary by 0.031; it now varies by 0.00016.

4. **The grade had no blacks.** The shadow lift was added in *linear HDR* before
   the ACES tonemap. A linear 0.119 floor on pure black comes out around 38% grey,
   so every shadow, silhouette and night sky in the project sat on a grey plateau.
   Contrast is now a gain in log space about middle grey, and the lift is a filmic
   toe that only touches the bottom stop.

5. **The dragon was self-illuminating.** With *every light in the scene set to
   zero*, the torso still rendered at (250, 176, 79). An ember belly-glow using
   `pow(1 − dorsal, 2)` covers most of a tube's silhouette, not just its belly —
   at 0.75 strength it buried the black obsidian hide under a self-lit cream wash.

6. **Storms filled the screen with hard rectangles.** The wind-streak sprite
   computed `d = length(r.x * 0.16, …)` where `r.x ∈ [−0.5, 0.5]` — so the largest
   `d` reachable along the streak was 0.08, and the 0.5 alpha cutoff was *never hit*.
   The streak wasn't fading out, it was being clipped by its own quad.

7. **Three normal maps were fighting.** The terrain summed a base map (17 m tile),
   a triplanar detail map (31 m) and an fbm micro-normal — uncorrelated fields at
   overlapping frequencies, which beat into a shimmer that read as blue-grey TV
   static crawling over the rock. One map at distance-faded scales replaced all three.

8. **The title rendered as "ASHMA".** Painted with `background-clip:text`, so the
   element's box *is* the paint surface — the letter-spaced text needed 656 px in a
   512 px box, and a glyph outside the box has no background to be clipped to. The
   final "W" was drawn every frame and was simply invisible.

9. **Roof geometry was wound inside-out.** Back-face culling hid both slopes and
   left the soffit facing the sky, so every cottage rendered as a white table with
   a dark cap. Six reversed index triplets.

10. **Night was pinned to a hard-coded key intensity of 0.5**, ignoring the preset
    entirely — so with the time-of-day slider at either extreme (both ends of a
    0..1 cycle are midnight) the world went literally black. The slider now maps
    onto dawn→dusk, and night has a moonlight floor and a lifted shadow pedestal,
    because a readable night is stylised, never physical.
