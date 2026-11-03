/**
 * Terrain.
 *
 * A single displaced grid built from Heightfield.height(), with per-vertex data
 * baked at generation time and consumed by a custom-injected standard material:
 *
 *   colour   — altitude/slope biome blend (basalt, ash, scorched dirt, moss)
 *   aHeat    — proximity to molten rock; drives glowing cracks in the fragment
 *              shader that pulse and creep, so the ground near the lava looks
 *              like it is cooling rather than painted
 *   aSnow    — high-altitude ash-frost on the massif
 *
 * Triplanar-ish blending: we mix a slope-space rock sample against a flat-space
 * dirt sample using the world normal, which kills the stretching you'd otherwise
 * get on the volcano's flanks.
 */
import * as THREE from 'three';
import { NOISE_GLSL, AX_GLOBALS } from '../shaders/lib/noise.glsl.js';
import { injectAmbient } from '../materials/MaterialLibrary.js';
import { G } from '../materials/GlobalUniforms.js';
import {
  WORLD, height, lavaProximity, slopeAt, isOnWater,
} from './Heightfield.js';
import { noise } from '../utils/Noise.js';
import { smoothstep, clamp } from '../utils/MathX.js';

export class Terrain {
  constructor(materials, settings) {
    this.settings = settings;
    const S = settings.terrainSegments;
    const size = WORLD.size;

    const geo = new THREE.PlaneGeometry(size, size, S, S);
    geo.rotateX(-Math.PI / 2);

    const pos = geo.attributes.position;
    const n = pos.count;
    const colors = new Float32Array(n * 3);
    const heat = new Float32Array(n);
    const frost = new Float32Array(n);

    const cRock   = new THREE.Color(0x4c4944);
    const cBasalt = new THREE.Color(0x221d24);
    const cAsh    = new THREE.Color(0x3e383f);
    const cDirt   = new THREE.Color(0x5b4935);
    const cMoss   = new THREE.Color(0x34452b);
    const cScorch = new THREE.Color(0x1e1516);
    const cFrost  = new THREE.Color(0x8e8c9c);
    const cSulfur = new THREE.Color(0x948e28);
    const cIron   = new THREE.Color(0x4e3224);
    const tmp = new THREE.Color();

    const vol = WORLD.volcano;

    for (let i = 0; i < n; i++) {
      const x = pos.getX(i), z = pos.getZ(i);
      const h = height(x, z);
      pos.setY(i, h);

      const slope = slopeAt(x, z, 6);
      const heatV = lavaProximity(x, z);
      const alt = clamp(h / 300, 0, 1);
      const wet = isOnWater(x, z) ? 1 : 0;
      const patch = noise.fbm2(x * 0.004, z * 0.004, 4) * 0.5 + 0.5;

      const dVol = Math.hypot(x - vol.x, z - vol.z);

      // Biome blend — order matters, later wins.
      tmp.copy(cDirt).lerp(cMoss, smoothstep(0.30, 0.75, patch) * (1 - alt) * (1 - slope));
      tmp.lerp(cRock, smoothstep(0.18, 0.55, slope));
      tmp.lerp(cBasalt, smoothstep(0.35, 0.80, slope) * 0.90);
      tmp.lerp(cAsh, smoothstep(0.28, 0.85, alt) * 0.85);
      tmp.lerp(cIron, smoothstep(0.40, 0.80, alt) * smoothstep(0.2, 0.7, slope) * 0.5);

      /**
       * The volcanic edifice is basalt, and it should read as basalt.
       *
       * Without this the cone inherited the generic slope/altitude biome —
       * dirt and rock greys — and then had a broad sulfur wash laid over it,
       * which came out a uniform khaki-olive that looked like a grassy hill
       * with a hole in the top. A young stratovolcano is dark: fresh basalt,
       * scoria, ash. Darkening by proximity to the vent (not by altitude, so
       * the flanks go dark too) is what makes it read as volcanic rock.
       */
      const edifice = smoothstep(vol.radius * 1.15, vol.radius * 0.25, dVol);
      tmp.lerp(cBasalt, edifice * 0.62);
      tmp.lerp(cAsh, edifice * smoothstep(0.15, 0.5, slope) * 0.35);

      // Sulfur fumarole staining near the rim. Patchy streaks around the
      // vents, not a wash over the whole summit — hence the tighter radius,
      // the much lower weight, and the high-contrast noise threshold that
      // keeps it to discrete patches.
      if (dVol < vol.craterR * 1.9) {
        const sulfDist = smoothstep(vol.craterR * 1.9, vol.craterR * 0.6, dVol);
        const sulfNoise = noise.fbm2(x * 0.035, z * 0.035, 3) * 0.5 + 0.5;
        const patchy = smoothstep(0.52, 0.78, sulfNoise);
        tmp.lerp(cSulfur, sulfDist * patchy * 0.34);
      }

      tmp.lerp(cScorch, smoothstep(0.10, 0.55, heatV));

      // Organic wind-blown ash-frost on cold high massifs (EXCLUDING active volcano summit due to geothermal heat)
      const isGeothermal = dVol < vol.radius * 1.05;
      const frostNoise = noise.fbm2(x * 0.008, z * 0.008, 4) * 0.5 + 0.5;
      const frostV = isGeothermal ? 0.0 : smoothstep(0.72, 0.98, alt) * smoothstep(0.65, 0.2, slope) * smoothstep(0.32, 0.72, frostNoise);
      tmp.lerp(cFrost, frostV * 0.65);
      if (wet) tmp.multiplyScalar(0.55);

      // Slight per-vertex value break-up so large flats never read as flat colour.
      const v = 0.85 + patch * 0.28;
      colors[i * 3]     = tmp.r * v;
      colors[i * 3 + 1] = tmp.g * v;
      colors[i * 3 + 2] = tmp.b * v;
      heat[i]  = heatV;
      frost[i] = frostV;
    }

    // Broad crevice shading baked once from neighbouring grid heights. This
    // grounds gullies and ledges without a fullscreen ambient-occlusion pass.
    const stride = S + 1;
    for (let z = 1; z < S; z++) {
      for (let x = 1; x < S; x++) {
        const i = z * stride + x;
        const bowl = (pos.getY(i - 1) + pos.getY(i + 1)
                    + pos.getY(i - stride) + pos.getY(i + stride)) * 0.25 - pos.getY(i);
        const shade = 1 - clamp(bowl * 0.10, 0, 0.38);
        colors[i * 3] *= shade; colors[i * 3 + 1] *= shade; colors[i * 3 + 2] *= shade;
      }
    }
    geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    geo.setAttribute('aHeat', new THREE.BufferAttribute(heat, 1));
    geo.setAttribute('aFrost', new THREE.BufferAttribute(frost, 1));
    geo.computeVertexNormals();
    geo.computeBoundingSphere();

    this.geometry = geo;
    this.material = this._makeMaterial(materials);

    this.mesh = new THREE.Mesh(geo, this.material);
    this.mesh.receiveShadow = true;
    this.mesh.castShadow = true;    // mountains must cast shadows across their own valleys
    this.mesh.name = 'Terrain';
    this.mesh.matrixAutoUpdate = false;
    this.mesh.updateMatrix();
  }

  _makeMaterial(materials) {
    const T = materials.T;
    const rockMap = T.rock.map.clone();      rockMap.repeat.set(140, 140);
    const rockNrm = T.rock.normalMap.clone(); rockNrm.repeat.set(140, 140);
    const dirtMap = T.dirt.map.clone();      dirtMap.repeat.set(220, 220);
    const dirtNrm = T.dirt.normalMap.clone(); dirtNrm.repeat.set(220, 220);
    for (const t of [rockMap, rockNrm, dirtMap, dirtNrm]) t.needsUpdate = true;

    /**
     * Deliberately NO `normalMap` slot here.
     *
     * There used to be one (rockNrm at repeat 140 — a tile every 17 m) *as
     * well as* the triplanar detail normal this shader applies below (0.032,
     * a tile every 31 m) *as well as* injectAmbient's fbm micro-normal
     * (microScale 0.075, applied at strength 0.18 x 18). Three uncorrelated
     * normal fields at overlapping frequencies, summed. They beat against each
     * other into a dense high-frequency shimmer that read as blue-grey TV
     * static crawling over every rock face — verified by zeroing the base map
     * and the micro term, which removed the speckle completely.
     *
     * One detail normal, applied triplanar and faded with distance (see
     * normal_fragment_maps below), is all this surface needs; the terrain mesh
     * is 9 m per quad, so everything finer than that is the normal map's job
     * and there is no reason to ask three of them to do it at once.
     */
    const mat = new THREE.MeshStandardMaterial({
      vertexColors: true,
      roughness: 0.90,
      metalness: 0.02,
      envMap: materials.env,
      envMapIntensity: 0.65,
    });
    mat.name = 'terrain';

    const uDetail = { value: dirtMap };
    const uDetailN = { value: dirtNrm };
    const uRock = { value: rockMap };

    mat.onBeforeCompile = (shader) => {
      Object.assign(shader.uniforms, {
        uTime: G.uTime,
        uEmberMood: G.uEmberMood,
        uShockwave: G.uShockwave,
        uDetail: uDetail,
        uDetailN: uDetailN,
        uRockN: { value: rockNrm },
        uRockMap: uRock,
      });

      shader.vertexShader = shader.vertexShader
        .replace('#include <common>', `#include <common>
          attribute float aHeat;
          attribute float aFrost;
          varying float vHeat;
          varying float vFrost;
          varying vec3  vTWPos;
          ${AX_GLOBALS}
        `)
        .replace('#include <begin_vertex>', `#include <begin_vertex>
          vHeat = aHeat;
          vFrost = aFrost;
          vTWPos = (modelMatrix * vec4(transformed, 1.0)).xyz;
          // Eruption shockwave ripples the ground as it passes.
          if (uShockwave.w > 0.0) {
            float d = length(vTWPos.xz - uShockwave.xz);
            float band = exp(-pow((d - uShockwave.w) / 46.0, 2.0));
            transformed.y += band * 5.5 * smoothstep(900.0, 120.0, uShockwave.w);
          }
        `);

      shader.fragmentShader = shader.fragmentShader
        .replace('#include <common>', `#include <common>
          varying float vHeat;
          varying float vFrost;
          varying vec3  vTWPos;
          ${AX_GLOBALS}
          uniform sampler2D uDetail;
          uniform sampler2D uDetailN;
          uniform sampler2D uRockN;
          uniform sampler2D uRockMap;
          ${NOISE_GLSL}
        `)
        // Triplanar-ish detail blend on top of the vertex-colour biome.
        .replace('#include <map_fragment>', `
          {
            vec2 uvFlat  = vTWPos.xz * 0.032;
            vec2 uvSideX = vTWPos.zy * 0.008;
            vec2 uvSideZ = vTWPos.xy * 0.008;
            vec3 nAbs = abs(normalize(vWNrm_x));   // world normal, injected by injectAmbient
            float wY = pow(nAbs.y, 4.0);
            vec3 rockS = texture2D(uRockMap, uvSideX).rgb * (1.0 - wY) * nAbs.x
                       + texture2D(uRockMap, uvSideZ).rgb * (1.0 - wY) * nAbs.z;
            float wSum = max((1.0 - wY) * (nAbs.x + nAbs.z), 1e-3);
            rockS /= wSum;
            vec3 flatS = texture2D(uDetail, uvFlat).rgb;
            vec3 det = mix(rockS, flatS, wY);
            // Macro variation stops the 2m detail tile from reading as a pattern.
            float macro = fbm(vTWPos * 0.0028, 4) * 0.5 + 0.5;

            // Strata: noise-warped horizontal bands, only on steep high ground.
            float steep = 1.0 - pow(clamp(nAbs.y, 0.0, 1.0), 2.0);
            float bandY = vTWPos.y * 0.055 + fbm(vTWPos * 0.004, 3) * 1.4;
            float band = sin(bandY * 6.2831);
            float strata = smoothstep(-0.25, 0.55, band) * steep
                         * smoothstep(60.0, 200.0, vTWPos.y);
            det *= 1.0 - strata * 0.34;
            det += vec3(0.05, 0.028, 0.02) * strata;

            float d = det.r * 0.35 + det.g * 0.45 + det.b * 0.20;
            float mod = 0.48 + (d / 0.45) * 0.42 + macro * 0.24;
            // Fade the fine albedo detail toward the macro average with
            // distance, for the same reason the detail normal fades: a 31 m
            // tile stops being texture and starts being noise once it drops
            // under a pixel. "macro" (a 350 m feature) carries the variation
            // that should still be visible from far away.
            float cd = length(cameraPosition - vTWPos);
            float texFade = 1.0 - smoothstep(900.0, 3200.0, cd);
            float macroMod = 0.64 + macro * 0.52;
            // Preserve the scanned surface's fracture contrast. Normalising
            // every texel back to a near-constant value erased the rock itself.
            float surfaceValue = clamp(pow(max(d, 0.005) / 0.12, 0.80), 0.28, 2.5);
            vec3 near = det / max(d, 0.02) * surfaceValue;
            diffuseColor.rgb *= mix(vec3(macroMod), near, texFade);
          }
        `)
        .replace('#include <normal_fragment_maps>', `#include <normal_fragment_maps>
          {
            vec3 nW = normalize(vWNrm_x);
            vec3 w = pow(abs(nW), vec3(4.0));
            w /= max(w.x + w.y + w.z, 1e-4);
            vec3 topN = texture2D(uDetailN, vTWPos.xz * 0.032).xyz * 2.0 - 1.0;
            vec3 sideX = texture2D(uRockN, vTWPos.zy * 0.030).xyz * 2.0 - 1.0;
            vec3 sideZ = texture2D(uRockN, vTWPos.xy * 0.030).xyz * 2.0 - 1.0;
            // Project each tangent slope onto its own world plane. Adding a
            // tangent-space RGB vector directly to a view normal rotated the
            // terrain's lighting with the camera and biased every slope.
            vec3 bump = vec3(-topN.x, 0.0, -topN.y) * w.y
                      + vec3(0.0, -sideX.y, -sideX.x * sign(nW.x)) * w.x
                      + vec3(-sideZ.x * sign(nW.z), -sideZ.y, 0.0) * w.z;
            bump -= nW * dot(bump, nW);
            float nd = length(cameraPosition - vTWPos);
            float fade = 1.0 - smoothstep(400.0, 2300.0, nd);
            normal = normalize(normal + mat3(viewMatrix) * bump * 0.48 * fade);
          }
        `)
        // Molten cracks & Deep Crater Throat Magmatic Incandescence
        .replace('#include <emissivemap_fragment>', `#include <emissivemap_fragment>
          {
            float heat = smoothstep(0.40, 0.98, vHeat);
            vec2 vVent = vec2(-300.0, -470.0);
            float dCrater = length(vTWPos.xz - vVent);

            // Subterranean Magmatic Throat Glow inside the volcano crater bowl
            if (dCrater < 95.0) {
              float depthGlow = smoothstep(95.0, 10.0, dCrater) * smoothstep(380.0, 310.0, vTWPos.y);
              float pulse = 0.75 + 0.25 * sin(uTime * 1.4 + dCrater * 0.15);
              float churning = fbm(vec3(vTWPos.xz * 0.06, uTime * 0.12), 4) * 0.5 + 0.5;
              vec3 magmCol = lavaRamp(0.6 + churning * 0.5) * depthGlow * pulse * 2.8;
              totalEmissiveRadiance += magmCol;
            }

            if (heat > 0.02) {
              /**
               * Molten rock showing through a cooling crust.
               *
               * The old version was a single voronoi cell-border mask at one
               * scale, uniformly bright wherever it was hot. Voronoi borders
               * form a closed, even-width *web* of equal-sized cells — which
               * is a cracked-mud or dragon-scale pattern, not lava. Painted
               * flat over the flank at constant brightness it read exactly as
               * what it was: a decal laid on the surface.
               *
               * Real pahoehoe crust breaks at several scales at once, the
               * incandescence lives *down inside* the cracks (so the glow is
               * strongest where the crust is thinnest, not uniform along every
               * border), and the whole field is stretched along the flow
               * direction rather than isotropic.
               */
              // Domain-warp the sample point instead of scaling the axes.
              //
              // The first attempt at "stretch the crust along the flow" built
              // an anisotropic uv by squashing one axis 0.34x. Voronoi under a
              // per-axis scale does not stretch its cells — it turns them into
              // axis-aligned rectangles, and two such fields at different
              // scales nest into a grid of boxes. The result looked like a
              // printed circuit board laid over the mountain. Warping the
              // *position* with noise elongates the cells along the flow
              // without ever introducing an axis for them to line up with.
              vec3 nW = normalize(vWNrm_x);
              vec2 down = normalize(-nW.xz + vec2(1e-4, 0.0));
              float along = dot(vTWPos.xz, down);
              vec2 flowUv = vTWPos.xz + down * fbm(vec3(vTWPos.xz * 0.012, along * 0.004), 3) * 26.0;

              // Two scales of plate boundary: big slabs, and finer fracture.
              vec2 c1 = voronoi(flowUv * 0.055 + vec2(0.0, uTime * 0.010));
              vec2 c2 = voronoi(flowUv * 0.155 + vec2(3.7, uTime * 0.026));
              float e1 = c1.y - c1.x;
              float e2 = c2.y - c2.x;
              float plate = 1.0 - smoothstep(0.0, 0.20, e1);
              float fract2 = 1.0 - smoothstep(0.0, 0.11, e2);
              // Fine fractures only open up *near* the big plate boundaries.
              float crack = max(plate, fract2 * smoothstep(0.34, 0.02, e1) * 0.75);

              // Depth: the centre of a crack is deeper and hotter than its lip.
              float depth = pow(crack, 2.2);

              // Advected flow so the glow creeps downhill instead of sitting still.
              float flow = fbm(vec3(flowUv * 0.03 - down * uTime * 0.10, uTime * 0.05), 4) * 0.5 + 0.5;
              float breathe = 0.55 + 0.45 * sin(uTime * 0.7 + vTWPos.x * 0.013 + vTWPos.z * 0.011);

              float g = depth * pow(heat, 1.35) * (0.35 + flow * 0.95) * breathe;
              // Kept well under the old gain: molten rock is bright, but pushed
              // past this it clips to white through the tonemap and the channel
              // stops reading as glowing *rock* and starts reading as a light.
              totalEmissiveRadiance += lavaRamp(0.28 + g * 0.62) * g * 0.48 * uEmberMood;

              // Cooled crust: dark, and darkest on the plate interiors where it
              // has had longest to chill and oxidise.
              float crust = (1.0 - crack) * heat;
              diffuseColor.rgb *= 1.0 - crust * 0.62;
              diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.055, 0.045, 0.050), crust * 0.55);
            }
          }
        `);
    };
    mat.customProgramCacheKey = () => 'terrain_v4';

    // microNormal is near-zero here on purpose: it is a *third* normal field
    // (see the note on the material above) and on terrain it only ever added
    // shimmer. The ash/wet response is what this injection is wanted for.
    return injectAmbient(mat, {
      ashAmount: 0.55, wetAmount: 1.0,
      microNormal: 0.02, microScale: 0.020, grimeAmount: 0.22,
    });
  }

  update() { /* terrain animates entirely in-shader */ }

  dispose() {
    this.geometry.dispose();
    this.material.dispose();
  }
}
