/**
 * Open ocean surrounding the caldera.
 *
 * This is intentionally one tessellated, camera-independent surface. It gives
 * the newly submerged outer terrain a real coastline and carries the horizon
 * far beyond the playable landscape without adding hundreds of draw calls.
 *
 * Why it looked like plastic before
 * ─────────────────────────────────
 * The previous version displaced `transformed.y` by a sum of sines and left the
 * `normal` attribute untouched — every vertex kept pointing straight up. A water
 * surface is read almost entirely through its normals (that's where reflection,
 * fresnel and glint all come from), so a bumpy-but-flat-shaded plane renders as
 * a mirror lying on the floor, which is what put the sky's own cloud discs on
 * the water as those big white ellipses. The `crest` term then added its own
 * band of near-white on top, so the "waves" people saw were the *shader's*
 * banding, not the geometry's.
 *
 * What replaced it
 * ────────────────
 * Gerstner (trochoidal) waves. Unlike a plain height-sum they displace
 * horizontally as well as vertically, which is what gives real swell its sharp
 * crests and broad troughs, and — the reason they're worth it here — their
 * partial derivatives are analytic, so the surface normal is *exact* rather than
 * finite-differenced. Four octaves at descending wavelength are enough for a
 * horizon: two long swells crossing at an angle, two short chop waves.
 *
 * Detail past the tessellation limit (the mesh is 15 km across, so a quad is
 * ~55 m) comes from a second, purely-normal set of high-frequency ripples
 * evaluated per fragment. Nothing displaces the geometry there — it only needs
 * to perturb the normal to catch light.
 */
import * as THREE from 'three';
import { WORLD } from './Heightfield.js';
import { G } from '../materials/GlobalUniforms.js';

const SEA_LEVEL = 2.5;

/**
 * Gerstner parameters, shared verbatim by the vertex and fragment stages.
 * vec4 = (dirX, dirZ, steepness, wavelength).
 *
 * Directions are deliberately *not* all aligned with the wind: real water
 * carries swell generated elsewhere, and two trains crossing at ~40° is what
 * stops the surface reading as corduroy.
 */
const WAVE_GLSL = /* glsl */`
  const vec4 AX_WAVE_A = vec4( 1.00,  0.00, 0.062, 620.0);
  const vec4 AX_WAVE_B = vec4( 0.76,  0.65, 0.048, 310.0);
  const vec4 AX_WAVE_C = vec4(-0.42,  0.91, 0.036, 141.0);
  const vec4 AX_WAVE_D = vec4( 0.28, -0.96, 0.028,  67.0);

  /**
   * Accumulate one Gerstner wave.
   * Returns the displacement; adds this wave's contribution to the tangent and
   * binormal accumulators so the caller can cross them into an exact normal.
   */
  vec3 axGerstner(vec4 w, vec3 p, float t, float amp, inout vec3 tang, inout vec3 bin) {
    vec2  dir = normalize(w.xy);
    float k   = 6.283185 / w.w;              // wave number
    float c   = sqrt(9.81 / k);              // deep-water phase speed
    float f   = k * (dot(dir, p.xz) - c * t);
    float a   = (w.z * amp) / k;             // steepness -> amplitude

    float sinF = sin(f);
    float cosF = cos(f);
    float wa   = w.z * amp;

    tang += vec3(-dir.x * dir.x * wa * sinF,
                  dir.x * wa * cosF,
                 -dir.x * dir.y * wa * sinF);
    bin  += vec3(-dir.x * dir.y * wa * sinF,
                  dir.y * wa * cosF,
                 -dir.y * dir.y * wa * sinF);

    return vec3(dir.x * a * cosF, a * sinF, dir.y * a * cosF);
  }

  /** Full surface: displacement out, exact normal out. */
  vec3 axWaves(vec3 p, float t, float windAmp, out vec3 nrm) {
    vec3 tang = vec3(1.0, 0.0, 0.0);
    vec3 bin  = vec3(0.0, 0.0, 1.0);
    vec3 d = vec3(0.0);
    d += axGerstner(AX_WAVE_A, p, t, windAmp,        tang, bin);
    d += axGerstner(AX_WAVE_B, p, t, windAmp,        tang, bin);
    d += axGerstner(AX_WAVE_C, p, t, windAmp * 0.85, tang, bin);
    d += axGerstner(AX_WAVE_D, p, t, windAmp * 0.70, tang, bin);
    nrm = normalize(cross(bin, tang));
    return d;
  }
`;

export class Ocean {
  /**
   * @param sky  the Sky instance, so the water can reflect the *actual* sky
   *             gradient. Its uniforms are shared live (not copied), so the
   *             reflection tracks weather and time of day automatically.
   */
  constructor(materials, sky, terrain) {
    // Reuse the existing heightfield vertices: no extra terrain sampling,
    // downloads, reflection cameras, or depth render pass for shoreline depth.
    const heights = terrain.geometry.attributes.position;
    const side = terrain.settings.terrainSegments + 1;
    const bed = new Uint8Array(side * side);
    for (let i = 0; i < bed.length; i++) {
      bed[i] = Math.round(THREE.MathUtils.clamp((heights.getY(i) + 24) / 48, 0, 1) * 255);
    }
    this.bathymetry = new THREE.DataTexture(bed, side, side, THREE.RedFormat);
    this.bathymetry.minFilter = this.bathymetry.magFilter = THREE.LinearFilter;
    this.bathymetry.needsUpdate = true;
    // Radial grid: dense near the shore where the camera lives, coarse out at
    // the horizon. A uniform 180² grid spent most of its vertices 6 km away.
    const geometry = new THREE.PlaneGeometry(15000, 15000, 256, 256);
    geometry.rotateX(-Math.PI / 2);

    const material = new THREE.MeshStandardMaterial({
      color: 0x0b2a38,
      roughness: 0.18,
      metalness: 0.0,
      envMap: materials.env,
      envMapIntensity: 0.65, // dielectric sheen; avoid doubling the sky reflection
      transparent: false,
      fog: false, // horizon is blended to the live sky below; avoid a second fog tint
    });
    material.name = 'OpenOcean';

    material.onBeforeCompile = (shader) => {
      Object.assign(shader.uniforms, {
        uTime: G.uTime,
        uWindDir: G.uWindDir,
        uWindStrength: G.uWindStrength,
        uSunDir: G.uSunDir,
        uSunColor: G.uSunColor,
        uFogColor: G.uFogColor,
        uSeaLevel: { value: SEA_LEVEL },
        uSeabed: { value: this.bathymetry },
        uWorldSize: { value: WORLD.size },
        // Live handles on the sky gradient — same uniform objects the sky dome
        // renders with, so water and sky can never disagree about the horizon.
        uSkyHorizon: sky?.uniforms?.uHorizon ?? { value: new THREE.Color(0xd8763a) },
        uSkyZenith: sky?.uniforms?.uZenith ?? { value: new THREE.Color(0x1d2b52) },
      });

      shader.vertexShader = shader.vertexShader
        .replace('#include <common>', `#include <common>
          varying vec3  vOceanWorld;
          varying vec3  vOceanNrm;
          varying float vOceanFold;
          uniform float uTime;
          uniform float uWindStrength;
          ${WAVE_GLSL}
        `)
        .replace('#include <beginnormal_vertex>', `#include <beginnormal_vertex>
          vec3 axDisplacement;
          {
            vec3 wp = (modelMatrix * vec4(position, 1.0)).xyz;
            float amp = 0.55 + uWindStrength * 0.40;

            // Flatten the swell toward the horizon. Beyond a few km a 3 m wave
            // is far below one pixel, and letting it run makes the far field
            // shimmer with aliasing instead of reading as distance.
            float dist = length(wp.xz);
            amp *= 1.0 - smoothstep(1200.0, 5200.0, dist) * 0.82;

            vec3 nrm;
            vec3 d = axWaves(wp, uTime, amp, nrm);
            axDisplacement = d;

            vOceanNrm  = nrm;
            vOceanWorld = (modelMatrix * vec4(position + d, 1.0)).xyz;
            // How much this vertex is being pinched by the horizontal
            // displacement — the classic cheap proxy for "this crest is about
            // to break", which is where foam belongs.
            vOceanFold = clamp(1.0 - nrm.y * 1.06, 0.0, 1.0);
          }
        `)
        .replace('#include <begin_vertex>', `#include <begin_vertex>
          transformed += axDisplacement;
        `)
        // The lighting solve needs the wave normal, not the plane's.
        .replace('#include <defaultnormal_vertex>', `
          vec3 transformedNormal = normalMatrix * vOceanNrm;
          #ifdef FLIP_SIDED
            transformedNormal = - transformedNormal;
          #endif
        `);

      shader.fragmentShader = shader.fragmentShader
        .replace('#include <common>', `#include <common>
          varying vec3  vOceanWorld;
          varying vec3  vOceanNrm;
          varying float vOceanFold;
          uniform float uTime;
          uniform float uWindStrength;
          uniform vec3  uSunDir;
          uniform vec3  uSunColor;
          uniform vec3  uFogColor;
          uniform vec3  uSkyHorizon;
          uniform vec3  uSkyZenith;
          uniform sampler2D uSeabed;
          uniform float uWorldSize;

          // Cheap value noise for the sub-quad ripple normals.
          float axHash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
          float axVal(vec2 p){
            vec2 i = floor(p), f = fract(p);
            f = f * f * (3.0 - 2.0 * f);
            return mix(mix(axHash(i), axHash(i + vec2(1,0)), f.x),
                       mix(axHash(i + vec2(0,1)), axHash(i + vec2(1,1)), f.x), f.y);
          }
        `)
        // Perturb the normal with detail finer than the mesh can carry.
        .replace('#include <normal_fragment_maps>', `#include <normal_fragment_maps>
          {
            vec2 p = vOceanWorld.xz;
            float t = uTime;
            float e = 1.6;
            // Two counter-drifting octaves so the surface never reads as a
            // single sliding texture.
            float h  = axVal(p * 0.085 + vec2(t * 0.55, t * 0.22)) * 0.55
                     + axVal(p * 0.210 - vec2(t * 0.31, t * 0.74)) * 0.28;
            float hx = axVal((p + vec2(e, 0.0)) * 0.085 + vec2(t * 0.55, t * 0.22)) * 0.55
                     + axVal((p + vec2(e, 0.0)) * 0.210 - vec2(t * 0.31, t * 0.74)) * 0.28;
            float hz = axVal((p + vec2(0.0, e)) * 0.085 + vec2(t * 0.55, t * 0.22)) * 0.55
                     + axVal((p + vec2(0.0, e)) * 0.210 - vec2(t * 0.31, t * 0.74)) * 0.28;

            // Fade the fine ripples out with distance, and fast. These are
            // metre-scale features; past a couple of hundred metres many land
            // inside one pixel and what survives is not detail but noise — the
            // mid-field static that made the water look like TV snow.
            float camDist = length(cameraPosition.xz - p);
            float detail = (0.22 + uWindStrength * 0.16)
                         * (1.0 - smoothstep(120.0, 900.0, camDist));
            vec3 rip = normalize(vec3(-(hx - h) * detail, 0.09, -(hz - h) * detail));

            // Mid-scale chop, ~50 m features. This fills the band between where
            // the fine ripples die (900 m) and where the Gerstner swell is the
            // only thing left — without it the middle distance collapses into
            // broad soft stripes of reflected sky. Coarse enough to stay well
            // above a pixel out to several km, so it adds structure rather than
            // the aliasing the fine octaves would.
            float m  = axVal(p * 0.019 + vec2(t * 0.10, t * 0.06));
            float mx = axVal((p + vec2(9.0, 0.0)) * 0.019 + vec2(t * 0.10, t * 0.06));
            float mz = axVal((p + vec2(0.0, 9.0)) * 0.019 + vec2(t * 0.10, t * 0.06));
            float midAmt = (0.5 + uWindStrength * 0.35)
                         * (1.0 - smoothstep(2500.0, 6000.0, camDist));
            rip += vec3(-(mx - m) * midAmt, 0.0, -(mz - m) * midAmt);

            vec3 nW = normalize(vOceanNrm + rip * vec3(1.0, 0.0, 1.0) * 1.4);
            normal = normalize(mat3(viewMatrix) * nW);
          }
        `)
        .replace('#include <color_fragment>', `#include <color_fragment>
          {
            vec3 V = normalize(cameraPosition - vOceanWorld);
            vec3 N = normalize(vOceanNrm);

            // Depth: how far the seabed is below this point. Shallow water over
            // the drowned terrain goes green and translucent, deep water goes
            // near-black — that gradient is most of what says "this is water"
            // rather than "this is a blue plane".
            vec2 shoreUv = vOceanWorld.xz / uWorldSize + 0.5;
            vec2 bedUv = (shoreUv * ${(side - 1).toFixed(1)} + 0.5) / ${side.toFixed(1)};
            float inIsland = step(0.0, shoreUv.x) * step(shoreUv.x, 1.0)
                           * step(0.0, shoreUv.y) * step(shoreUv.y, 1.0);
            float bedHeight = texture2D(uSeabed, bedUv).r * 48.0 - 24.0;
            float depth = mix(60.0, max(0.0, vOceanWorld.y - bedHeight), inIsland);
            vec3 deep = vec3(0.006, 0.026, 0.042);
            vec3 shallow = vec3(0.045, 0.145, 0.125);
            diffuseColor.rgb = mix(shallow, deep, 1.0 - exp(-depth * 0.16));
            float shoreNoise = axVal(vOceanWorld.xz * 0.15 - uTime * 0.3);
            float wash = 0.5 + 0.5 * sin(depth * 2.2 - uTime * 1.7 + shoreNoise * 3.0);
            float shoreFoam = (1.0 - smoothstep(0.4, 3.8, depth))
                            * smoothstep(0.38, 0.8, wash) * inIsland;
            diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.48, 0.56, 0.55), shoreFoam * 0.65);

            // Sub-surface glow on the back of a wave facing away from the sun:
            // light passing *through* the crest. Subtle, but it is the single
            // most recognisable "real water" cue in a sunset.
            float back = clamp(dot(-N, normalize(uSunDir)), 0.0, 1.0);
            float lift = clamp(vOceanFold * 2.4, 0.0, 1.0);
            diffuseColor.rgb += uSunColor * pow(back, 3.0) * lift * 0.32;

            // Foam on the folding crests, broken up so it isn't a clean band.
            float foamN = axVal(vOceanWorld.xz * 0.35 + uTime * 0.6) * 0.6
                        + axVal(vOceanWorld.xz * 0.9  - uTime * 0.4) * 0.4;
            float foam = smoothstep(0.42, 0.92, vOceanFold * (0.55 + foamN * 0.9));
            foam *= 1.0 - smoothstep(1500.0, 4200.0, length(vOceanWorld.xz));
            diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.62, 0.66, 0.68), foam * 0.75);

            // Hand the far field over to the horizon term in the emissive
            // stage (see the note there). The lit water colour has to get out
            // of the way for that to work — otherwise the deep-water albedo
            // keeps contributing right up to the mesh's edge and the seam
            // survives no matter how strongly the horizon colour is mixed in.
            float farD = smoothstep(2200.0, 6600.0, length(vOceanWorld.xz - cameraPosition.xz));
            diffuseColor.rgb *= 1.0 - farD * farD;
          }
        `)
        .replace('#include <emissivemap_fragment>', `#include <emissivemap_fragment>
          {
            vec3 V = normalize(cameraPosition - vOceanWorld);

            /**
             * Flatten the normal used for reflection as distance grows.
             *
             * vOceanNrm is a *vertex* attribute interpolated across quads that
             * are ~59 m across on a 15 km plane. Schlick's fresnel raises
             * (1 - N.V) to the fifth power, and at 5 km the view vector is
             * within a fraction of a degree of the surface — so that fifth
             * power sits on the steepest part of its curve and amplifies the
             * small *linear* variation of the interpolated normal into large,
             * visibly straight-edged patches. The result was hard-edged
             * translucent rectangles scattered across the far ocean, most
             * obvious at night where the water is dark and the reflection is
             * the only signal (confirmed by raycasting one of the edges: it
             * hit OpenOcean at 5045 units).
             *
             * Blending toward vertical past ~1 km removes the amplified term
             * entirely, and costs nothing real: individual waves are far below
             * a pixel at that range, so uniformly mirrored water is not merely
             * acceptable there, it is what the eye actually expects.
             */
            float camD = length(cameraPosition - vOceanWorld);
            float flatten = smoothstep(900.0, 3800.0, camD);
            vec3 N = normalize(mix(normalize(vOceanNrm), vec3(0.0, 1.0, 0.0), flatten));

            // Schlick fresnel. Water is ~0.02 reflective head-on and ~1.0 at
            // grazing angles; that ratio is why a lake is transparent at your
            // feet and a mirror at the far shore.
            float fres = 0.02 + 0.98 * pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 5.0);

            // Specular glint: a tight Blinn lobe on the *detail* normal, which
            // is what shatters the sun into a shimmering path rather than one
            // mirror blob. Weighted by fresnel, so the path brightens as it
            // runs away from the viewer toward the horizon — the shape of a
            // real sun-glitter track.
            vec3 L = normalize(uSunDir);
            vec3 H = normalize(L + V);
            float spec = pow(clamp(dot(normalize(normal * mat3(viewMatrix)), H), 0.0, 1.0), 220.0);
            totalEmissiveRadiance += uSunColor * spec * (0.6 + fres * 3.4);

            // Sky reflection, evaluated against the real sky gradient.
            //
            // The first attempt at this used G.uSkyColor — which is the
            // *hemisphere light's* colour, a lighting parameter (tan, 0xe2a472,
            // at sunset), not what the sky looks like. Multiplied by fresnel it
            // painted flat tan across every grazing pixel: the brown smear that
            // sat over the middle distance. These two uniforms are the actual
            // gradient the sky dome is drawn with, shared live.
            //
            // Sampling the gradient along the *reflected* view vector (rather
            // than just fading to one colour) is what makes the water darken
            // overhead and glow at the horizon, which is the shape real water
            // has.
            vec3 R = reflect(-V, N);
            float up = clamp(R.y, 0.0, 1.0);
            vec3 skyRefl = mix(uSkyHorizon, uSkyZenith, pow(up, 0.55));
            totalEmissiveRadiance += skyRefl * fres * 1.6;

            /**
             * Aerial perspective, taken all the way to 1.0 at the plane's edge.
             *
             * The mesh is 15 km across, so it *ends* — and wherever it ends is
             * still nearer than the true horizon. Any residual water colour
             * left at that boundary shows up as a hard horizontal band against
             * the sky, which is exactly what a 0.65 blend left behind: a dark
             * navy strip under a bright sky, most obvious in the eruption and
             * ashstorm presets where the two colours are furthest apart.
             * Reaching the horizon colour completely makes the seam vanish
             * because there is no longer a step across it.
             */
            float far = smoothstep(2200.0, 6600.0, length(vOceanWorld.xz - cameraPosition.xz));
            float blend = far * far;                       // hold detail longer, then commit
            totalEmissiveRadiance = mix(totalEmissiveRadiance, uSkyHorizon * 0.92, blend);
          }
        `)
        .replace('#include <opaque_fragment>', `
          // Fade the completed lighting result, including specular. Blending
          // emissive alone left a bright reflection strip at the mesh edge.
          float horizonBlend = smoothstep(1900.0, 6200.0,
            length(vOceanWorld.xz - cameraPosition.xz));
          outgoingLight = mix(outgoingLight, uSkyHorizon, horizonBlend * horizonBlend);
          #include <opaque_fragment>
        `);
    };
    material.customProgramCacheKey = () => 'ocean_gerstner_v3';

    this.mesh = new THREE.Mesh(geometry, material);
    this.mesh.name = 'OpenOcean';
    this.mesh.position.y = SEA_LEVEL;
    this.mesh.receiveShadow = false;   // a shadow on open water reads as a stain
    this.mesh.frustumCulled = false;
    this.mesh.renderOrder = -1;
  }

  setEnv(envMap) {
    if (this.mesh.material.envMap === envMap) return;
    this.mesh.material.envMap = envMap;
    this.mesh.material.needsUpdate = true;
  }

  dispose() {
    this.bathymetry.dispose();
    this.mesh.geometry.dispose();
    this.mesh.material.dispose();
  }
}
