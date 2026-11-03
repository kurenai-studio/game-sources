/**
 * Material library.
 *
 * All surfaces come from here so the realm has one coherent look and one place
 * to retune it. Two shader injections do most of the heavy lifting:
 *
 *  · injectWind()   — world-space foliage/cloth sway, phase-locked globally
 *  · injectAmbient()— ash dusting on up-facing surfaces, wetness gloss, and a
 *                     per-fragment contribution from the dragon's fire light so
 *                     breath actually lights the village instead of faking it.
 */
import * as THREE from 'three';
import { WIND_GLSL } from '../shaders/lib/wind.glsl.js';
import { NOISE_GLSL, AX_GLOBALS } from '../shaders/lib/noise.glsl.js';
import { makeCanopyAtlas } from './CanopyAtlas.js';
import { G } from './GlobalUniforms.js';

/* ── injections ──────────────────────────────────────────────────────── */

/**
 * World-space wind displacement, corrected back into object space so shadows,
 * fog and normals downstream stay consistent.
 * `flexExpr` is GLSL evaluating to 0 (rigid root) … 1 (free tip).
 */
export function injectWind(mat, { flexExpr = 'aFlex', freq = 1.0, amp = 1.0 } = {}) {
  mat.userData.wind = { freq: { value: freq }, amp: { value: amp } };
  const prev = mat.onBeforeCompile;

  mat.onBeforeCompile = (shader, renderer) => {
    prev?.(shader, renderer);
    Object.assign(shader.uniforms, {
      uTime: G.uTime, uWindDir: G.uWindDir,
      uWindStrength: G.uWindStrength, uGustPhase: G.uGustPhase,
      uShockwave: G.uShockwave, uRoarWave: G.uRoarWave,
      uWindFreq: mat.userData.wind.freq,
      uWindAmp: mat.userData.wind.amp,
    });

    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', `#include <common>
        ${flexExpr === 'aFlex' ? 'attribute float aFlex;' : ''}
        uniform float uWindFreq;
        uniform float uWindAmp;
        ${WIND_GLSL}
      `)
      .replace('#include <begin_vertex>', `#include <begin_vertex>
        {
          mat3 m3 = mat3(modelMatrix);
          #ifdef USE_INSTANCING
            m3 = m3 * mat3(instanceMatrix);
          #endif
          vec3 sc = vec3(length(m3[0]), length(m3[1]), length(m3[2])) + 1e-5;
          mat3 rot = mat3(m3[0]/sc.x, m3[1]/sc.y, m3[2]/sc.z);

          vec4 wp = vec4(transformed, 1.0);
          #ifdef USE_INSTANCING
            wp = instanceMatrix * wp;
          #endif
          wp = modelMatrix * wp;

          vec3 woff = windOffset(wp.xyz, 1.0 - clamp(${flexExpr}, 0.0, 1.0), uWindFreq) * uWindAmp;
          transformed += (transpose(rot) * woff) / sc;
        }
      `);
  };
  const key = mat.customProgramCacheKey?.bind(mat);
  mat.customProgramCacheKey = () => `wind_${flexExpr}_${key ? key() : mat.type}`;
  return mat;
}

/**
 * Environmental response every opaque surface shares.
 *  · ash settles on up-facing geometry (grows in ash storms / after eruption)
 *  · rain darkens albedo and sharpens roughness
 *  · the dragon's fire adds a proper distance-attenuated, N·L-shaded term
 */
export function injectAmbient(mat, {
  ashAmount = 1.0,
  wetAmount = 1.0,
  microNormal = 0.18,
  microScale = 0.075,
  grimeAmount = 0.18,
} = {}) {
  const prev = mat.onBeforeCompile;
  mat.userData.ambient = {
    ash: { value: ashAmount },
    wet: { value: wetAmount },
    microNormal: { value: microNormal },
    microScale: { value: microScale },
    grime: { value: grimeAmount },
  };

  mat.onBeforeCompile = (shader, renderer) => {
    prev?.(shader, renderer);
    Object.assign(shader.uniforms, {
      uAshLoad: G.uAshLoad, uWetness: G.uWetness,
      uFirePos: G.uFirePos, uFireIntensity: G.uFireIntensity, uFireColor: G.uFireColor,
      uEmberMood: G.uEmberMood, uTime: G.uTime,
      uAshAmount: mat.userData.ambient.ash,
      uWetAmount: mat.userData.ambient.wet,
      uMicroNormal: mat.userData.ambient.microNormal,
      uMicroScale: mat.userData.ambient.microScale,
      uGrimeAmount: mat.userData.ambient.grime,
    });

    // We need world position + world normal in the fragment stage.
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', `#include <common>
        varying vec3 vWPos_x;
        varying vec3 vWNrm_x;
      `)
      .replace('#include <worldpos_vertex>', `#include <worldpos_vertex>
        vec4 wpx = vec4(transformed, 1.0);
        #ifdef USE_INSTANCING
          wpx = instanceMatrix * wpx;
        #endif
        vWPos_x = (modelMatrix * wpx).xyz;
        // transformedNormal already includes inverse scale, instance rotation,
        // and the model normal matrix. Bring it back from view to world space.
        vWNrm_x = normalize(transformedNormal * mat3(viewMatrix));
      `);

    shader.fragmentShader = shader.fragmentShader
      .replace('#include <common>', `#include <common>
        varying vec3 vWPos_x;
        varying vec3 vWNrm_x;
        uniform float uAshAmount, uWetAmount;
        uniform float uMicroNormal, uMicroScale, uGrimeAmount;
        ${AX_GLOBALS}
        ${NOISE_GLSL}
      `)
      .replace('#include <normal_fragment_maps>', `#include <normal_fragment_maps>
        {
          if (uMicroNormal > 0.025) {
          // One height sample and screen derivatives replace three 4-octave
          // samples. Surface gradients work on walls, roofs and rotated instances.
          vec3 nW = normalize(normal * mat3(viewMatrix));
          vec3 dpX = dFdx(vWPos_x), dpY = dFdy(vWPos_x);
          float h = fbm(vWPos_x * uMicroScale, 3);
          vec3 rX = cross(dpY, nW), rY = cross(nW, dpX);
          float det = dot(dpX, rX);
          vec3 grad = (dFdx(h) * rX + dFdy(h) * rY)
                    * sign(det) / max(abs(det), 1e-6);
          float fade = 1.0 - smoothstep(90.0, 650.0, length(cameraPosition - vWPos_x));
          vec3 pertW = normalize(nW - grad * uMicroNormal * 3.0 * fade);
          normal = normalize(mat3(viewMatrix) * pertW);
          }
        }
      `)
      // Albedo-stage effects.
      .replace('#include <color_fragment>', `#include <color_fragment>
        {
          float up = clamp(vWNrm_x.y, 0.0, 1.0);
          float grit = fbm(vWPos_x * 0.06, 3) * 0.5 + 0.5;
          float ash = uAshLoad * uAshAmount * pow(up, 1.6) * (0.55 + 0.45 * grit);
          diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.30, 0.285, 0.28), clamp(ash, 0.0, 0.85));

          float slopeGrime = smoothstep(0.18, 0.82, 1.0 - up);
          float cavities = 1.0 - smoothstep(0.28, 0.72, grit);
          diffuseColor.rgb *= 1.0 - cavities * slopeGrime * uGrimeAmount * 0.28;

          float wet = uWetness * uWetAmount;
          diffuseColor.rgb *= 1.0 - 0.34 * wet;
        }
      `)
      .replace('#include <roughnessmap_fragment>', `#include <roughnessmap_fragment>
        {
          float wet = uWetness * uWetAmount * clamp(vWNrm_x.y * 1.3, 0.0, 1.0);
          roughnessFactor = mix(roughnessFactor, 0.14, wet * 0.8);
        }
      `)
      // Additive fire lighting, applied after the standard lighting solve.
      .replace('#include <emissivemap_fragment>', `#include <emissivemap_fragment>
        if (uFireIntensity > 0.001) {
          vec3  toFire = uFirePos - vWPos_x;
          float dist   = length(toFire);
          vec3  L      = toFire / max(dist, 0.001);
          float ndl    = clamp(dot(normalize(vWNrm_x), L), 0.0, 1.0);
          // inverse-square with a soft knee so nearby walls don't blow out
          float atten  = 1.0 / (1.0 + dist * dist * 0.0016);
          float flick  = 0.82 + 0.18 * sin(uTime * 37.0 + dist * 0.35);
          totalEmissiveRadiance += uFireColor * (ndl * 0.85 + 0.15) * atten
                                 * uFireIntensity * flick * 1.9 * diffuseColor.rgb;
        }
      `);
  };

  const key = mat.customProgramCacheKey?.bind(mat);
  mat.customProgramCacheKey = () => `amb_v2_${key ? key() : mat.type}`;
  return mat;
}

/**
 * Distance dissolve — dithered discard past `start`, fully gone by `end`.
 *
 * Built for grass. A blade tapers to a ~2 cm tip by design, which is
 * sub-pixel at any distance past a few dozen metres regardless of how the
 * blade is oriented — that's what was reading as bright vertical "streaks" in
 * wide/establishing shots: not a shading bug, just thin geometry aliasing once
 * its on-screen width drops below a pixel. A hard distance cutoff would pop;
 * a per-fragment dithered discard (screen-space hash vs. a smooth fade curve)
 * dissolves it instead, and costs nothing extra since it reuses hash12/
 * vWPos_x that injectAmbient already put in scope earlier in the same chain.
 */
export function injectDistanceFade(mat, { start = 60, end = 120 } = {}) {
  const prev = mat.onBeforeCompile;
  const u = { start: { value: start }, end: { value: end } };
  mat.userData.fade = u;

  mat.onBeforeCompile = (shader, renderer) => {
    prev?.(shader, renderer);
    Object.assign(shader.uniforms, { uFadeStart: u.start, uFadeEnd: u.end });

    shader.fragmentShader = shader.fragmentShader
      .replace('#include <common>', `#include <common>
        uniform float uFadeStart, uFadeEnd;
      `)
      .replace('#include <clipping_planes_fragment>', `#include <clipping_planes_fragment>
        {
          float axDist = length(cameraPosition - vWPos_x);
          float axFade = 1.0 - smoothstep(uFadeStart, uFadeEnd, axDist);
          if (axFade < hash12(gl_FragCoord.xy)) discard;
        }
      `);
  };

  const key = mat.customProgramCacheKey?.bind(mat);
  mat.customProgramCacheKey = () => `fade_${key ? key() : mat.type}`;
  return mat;
}

/* ── library ─────────────────────────────────────────────────────────── */

export class MaterialLibrary {
  constructor(textures, envMap) {
    this.T = textures;
    this.env = envMap;
    this.mats = {};
    this._build();
  }

  _std(name, { map, normalMap, roughnessMap, ...opts } = {}) {
    // Passing undefined for a texture slot makes three warn; omit instead.
    const params = { envMap: this.env, envMapIntensity: 0.72, ...opts };
    if (map) params.map = map;
    if (normalMap) params.normalMap = normalMap;
    if (roughnessMap) params.roughnessMap = roughnessMap;
    const m = new THREE.MeshStandardMaterial(params);
    m.name = name;
    this.mats[name] = m;
    return m;
  }

  _build() {
    const T = this.T;

    const clone = (t, r) => {
      if (!t) return t;
      const c = t.clone();
      c.repeat.set(r, r);
      c.needsUpdate = true;
      return c;
    };
    const set = (name, tex, repeat, opts = {}) => {
      const { ambient, ...materialOpts } = opts;
      const m = this._std(name, {
        map: clone(tex.map, repeat),
        normalMap: clone(tex.normalMap, repeat),
        roughnessMap: clone(tex.roughnessMap, repeat),
        ...materialOpts,
      });
      return injectAmbient(m, ambient ?? {});
    };

    set('stone',   T.stone,   3, { color: 0xb9b0a3, metalness: 0.0, roughness: 0.86, normalScale: new THREE.Vector2(1.55, 1.55), ambient: { microNormal: 0.28, microScale: 0.115, grimeAmount: 0.32 } });
    set('stoneDark', T.stone, 2, { color: 0x7f7b80, metalness: 0.0, roughness: 0.90, normalScale: new THREE.Vector2(1.45, 1.45), ambient: { microNormal: 0.25, microScale: 0.105, grimeAmount: 0.36 } });
    set('rock',    T.rock,    4, { color: 0x8f8982, metalness: 0.03, roughness: 0.82, normalScale: new THREE.Vector2(0.85, 0.85), ambient: { microNormal: 0.34, microScale: 0.15, grimeAmount: 0.34 } });
    set('basalt',  T.rock,    2, { color: 0x5f5960, metalness: 0.06, roughness: 0.78, normalScale: new THREE.Vector2(0.85, 0.85), ambient: { microNormal: 0.38, microScale: 0.14, grimeAmount: 0.28 } });
    set('dirt',    T.dirt,    6, { color: 0xb39773, roughness: 0.92, normalScale: new THREE.Vector2(1.35, 1.35), ambient: { microNormal: 0.18, microScale: 0.11, grimeAmount: 0.22 } });
    set('wood',    T.wood,    2, { color: 0x8c6745, roughness: 0.80, normalScale: new THREE.Vector2(1.35, 1.35), ambient: { microNormal: 0.18, microScale: 0.09, grimeAmount: 0.18 } });
    set('woodDark',T.wood,    3, { color: 0x493223, roughness: 0.86, normalScale: new THREE.Vector2(1.55, 1.55), ambient: { microNormal: 0.22, microScale: 0.10, grimeAmount: 0.24 } });
    set('thatch',  T.thatch,  2, { color: 0x8b7044, roughness: 0.96, normalScale: new THREE.Vector2(1.7, 1.7), ambient: { microNormal: 0.16, microScale: 0.13, grimeAmount: 0.12 } });
    set('tile',    T.tile,    2, { color: 0x6f2e23, roughness: 0.80, normalScale: new THREE.Vector2(1.6, 1.6), ambient: { microNormal: 0.18, microScale: 0.10, grimeAmount: 0.18 } });
    set('plaster', T.plaster, 2, { color: 0xa99e90, normalScale: new THREE.Vector2(0.72, 0.72), roughness: 0.90, ambient: { microNormal: 0.12, microScale: 0.085, grimeAmount: 0.24 } });
    set('bark',    T.bark,    1, { color: 0x8f6a45, roughness: 0.88, normalScale: new THREE.Vector2(1.8, 1.8), ambient: { microNormal: 0.28, microScale: 0.12, grimeAmount: 0.18 } });

    // Statues get a slightly cooler, harder stone.
    set('statue',  T.stone,   1.5, { color: 0xa8a6ad, roughness: 0.76, metalness: 0.04, normalScale: new THREE.Vector2(1.25, 1.25), ambient: { microNormal: 0.18, microScale: 0.10, grimeAmount: 0.30 } });

    // Cloth for banners — lit from both sides.
    const cloth = this._std('cloth', {
      map: clone(T.cloth.map, 1),
      normalMap: clone(T.cloth.normalMap, 1),
      roughnessMap: clone(T.cloth.roughnessMap, 1),
      color: 0xd44a2c, side: THREE.DoubleSide, roughness: 0.82,
    });
    injectAmbient(cloth, { ashAmount: 0.4 });
    injectWind(cloth, { flexExpr: 'uv.x', freq: 2.4, amp: 1.5 });

    // Foliage: double-sided cards with a hint of transmitted light.
    const foliage = this._std('foliage', {
      map: makeCanopyAtlas(),
      color: 0xffffff,
      roughness: 0.85, metalness: 0.0,
      side: THREE.DoubleSide, vertexColors: true,
      alphaTest: 0.38,
    });
    // Foliage uses its own baked branch colour; skip masonry micro-shading.
    injectWind(foliage, { flexExpr: 'aFlex', freq: 1.0, amp: 1.0 });

    // Grass needs its own wind amplitude: displacement is absolute (metres), so
    // sharing the trees' amp smears half-metre blades into 1.6 m arcs.
    const grass = this._std('grass', {
      color: 0xffffff,
      roughness: 0.9, metalness: 0.0,
      side: THREE.DoubleSide, vertexColors: true,
      envMapIntensity: 0.9,
    });
    injectAmbient(grass, { ashAmount: 0.5 });
    injectWind(grass, { flexExpr: 'aFlex', freq: 2.6, amp: 0.10 });
    injectDistanceFade(grass, { start: 60, end: 120 });

    // Trunks sway a little, from the same gust.
    const trunk = this._std('trunk', {
      map: clone(T.bark.map, 1),
      normalMap: clone(T.bark.normalMap, 1),
      roughnessMap: clone(T.bark.roughnessMap, 1),
      color: 0xa8815a,
    });
    injectAmbient(trunk);
    injectWind(trunk, { flexExpr: 'aFlex', freq: 0.7, amp: 0.55 });

    // Dragon hide.
    //
    // Isolated by disabling terms one at a time: normalScale/normalStrength
    // were red herrings — killing the normal map entirely still left visible
    // speckle. Killing envMapIntensity is what made it vanish. Root cause is
    // the *roughness map*: T.scale bakes roughness ~0.3 at each scale centre
    // vs ~0.72 in the gaps, a 0.4 swing — under environment reflection, every
    // individual scale becomes its own tiny mirror at a different angle from
    // its neighbours, i.e. glitter. Dropping the roughness map for a flat
    // scalar (still textured for colour/normal, just not for gloss) removes
    // the per-scale mirror field; a low flat envMapIntensity keeps a believable
    // overall sheen without it separating into sparkle.
    const hide = this._std('hide', {
      map: clone(T.scale.map, 1),
      normalMap: clone(T.scale.normalMap, 1),
      color: 0x181417,
      metalness: 0.04,
      roughness: 0.68,
      envMapIntensity: 0.28,
      normalScale: new THREE.Vector2(1.0, 1.0),
      emissive: new THREE.Color(0x2a0804),
      emissiveIntensity: 0.42,
    });
    injectAmbient(hide, { ashAmount: 0.08, microNormal: 0.20, microScale: 0.18, grimeAmount: 0.06 });

    // Obsidian Counter-shading + Fiery Belly Embers + Rim Fresnel
    {
      const prevHide = hide.onBeforeCompile;
      hide.onBeforeCompile = (shader, renderer) => {
        prevHide(shader, renderer);
        Object.assign(shader.uniforms, { uSkyColor: G.uSkyColor, uTime: G.uTime });
        shader.fragmentShader = shader.fragmentShader
          .replace('#include <color_fragment>', `#include <color_fragment>
            {
              float dorsal = clamp(vWNrm_x.y * 0.5 + 0.5, 0.0, 1.0);
              vec3 darkDorsal = vec3(0.20, 0.18, 0.19);
              vec3 bellyColor = vec3(0.34, 0.19, 0.13);
              diffuseColor.rgb *= mix(bellyColor, darkDorsal, dorsal);
            }
          `)
          .replace('#include <emissivemap_fragment>', `#include <emissivemap_fragment>
            {
              /**
               * Ember glow through the underbelly.
               *
               * This is emissive, so it is added *after* the lighting solve and
               * owes nothing to the light rig — which is exactly how it managed
               * to be the single brightest thing on the creature. Measured with
               * every light in the scene set to zero intensity, the torso still
               * rendered at (250,176,79): a nearly-saturated orange. The body
               * is a tube, so side-on most of its visible surface has a normal
               * pointing somewhat downward (dorsal < 0.5), pow(1-dorsal, 2) was
               * therefore large over most of the silhouette rather than just
               * the belly, and at 0.75 strength it buried the dark obsidian
               * hide under a self-lit cream wash. That is why the dragon read
               * as a pale airliner fuselage instead of a black scaled animal.
               *
               * A much higher exponent confines it to genuinely down-facing
               * surfaces, and a much lower gain keeps it as a hint of heat
               * rather than a light source.
               */
              float dorsal = clamp(vWNrm_x.y * 0.5 + 0.5, 0.0, 1.0);
              float bellyGlow = pow(1.0 - dorsal, 5.0);
              float pulse = 0.8 + 0.2 * sin(uTime * 1.6);
              totalEmissiveRadiance += vec3(1.0, 0.32, 0.08) * bellyGlow * pulse * 0.16;

              // Rim light. Kept deliberately weak for the same reason: it is
              // unlit energy, and a fresnel term covers a lot of a curved
              // silhouette.
              vec3 Vd = normalize(cameraPosition - vWPos_x);
              float fres = pow(1.0 - clamp(dot(normalize(vWNrm_x), Vd), 0.0, 1.0), 4.0);
              totalEmissiveRadiance += uSkyColor * fres * 0.12;
            }
          `);
      };
      const key = hide.customProgramCacheKey.bind(hide);
      hide.customProgramCacheKey = () => `${key()}_cshade_v3`;
    }

    // Emissive helpers.
    this.mats.emberGlass = new THREE.MeshStandardMaterial({
      color: 0x2a1608, emissive: new THREE.Color(0xffb257), emissiveIntensity: 2.4,
      roughness: 0.35, metalness: 0.0,
    });
    this.mats.eyeGlow = new THREE.MeshBasicMaterial({ color: 0xffd27a, toneMapped: false });
    this.mats.hot = new THREE.MeshBasicMaterial({ color: 0xff7a28, toneMapped: false });

    // Metal for hinges, chains, statue swords.
    this._std('iron', { color: 0x6b6467, roughness: 0.48, metalness: 0.85, envMapIntensity: 1.0 });
  }

  get(name) { return this.mats[name]; }

  setEnv(envMap) {
    this.env = envMap;
    for (const m of Object.values(this.mats)) {
      if ('envMap' in m) { m.envMap = envMap; m.needsUpdate = true; }
    }
  }

  setWireframe(on) {
    for (const m of Object.values(this.mats)) if ('wireframe' in m) m.wireframe = on;
  }
}
