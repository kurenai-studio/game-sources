/**
 * Atmosphere — everything drifting in the air.
 *
 * All five systems (ash, embers, dust, wind streaks, leaves) share one GPU
 * particle design: positions live in a static attribute buffer and the *entire*
 * simulation happens in the vertex shader as a function of (seed, time). Nothing
 * is written back from the CPU, so 10k+ particles cost one draw call and zero
 * per-frame JS.
 *
 * Particles live inside a moving cell centred on the camera, wrapped with mod()
 * — so the air is always populated wherever you go, without ever allocating for
 * the whole 2.4km map.
 */
import * as THREE from 'three';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';
import { G } from '../materials/GlobalUniforms.js';

const vert = /* glsl */`
attribute vec3  aSeed;
attribute float aSize;
attribute float aSpin;

varying float vSeed;
varying float vFade;
varying float vSpin;
varying float vHeat;

uniform float uTime;
uniform vec3  uCameraPos;
uniform vec3  uCell;         // half-extents of the wrap volume
uniform vec2  uWindDir;
uniform float uWindStrength;
uniform float uFall;         // + = sinks, - = rises
uniform float uTurbulence;
uniform float uSizeScale;
uniform float uDrift;        // horizontal advection multiplier
uniform float uEmberMood;
uniform float uSpawnJitter;

${NOISE_GLSL}

void main(){
  vSeed = aSeed.x;
  vSpin = aSpin;

  vec3 p = position;

  // Advection.
  float t = uTime;
  vec3 wind = vec3(uWindDir.x, 0.0, uWindDir.y) * uWindStrength * uDrift;
  p += wind * t;
  p.y -= uFall * t;

  // Turbulence: two octaves of curl at different scales/rates.
  vec3 q = p * 0.004 + vec3(0.0, t * 0.03, 0.0);
  vec3 c1 = curlNoise(q);
  vec3 c2 = curlNoise(q * 4.3 + 11.7);
  p += (c1 * 26.0 + c2 * 7.0) * uTurbulence;

  // Flutter — ash and leaves scull sideways as they fall.
  p.x += sin(t * (0.7 + aSeed.y) + aSeed.z * 30.0) * 2.4 * uTurbulence;
  p.z += cos(t * (0.6 + aSeed.z) + aSeed.y * 30.0) * 2.4 * uTurbulence;

  // Wrap into a cell that follows the camera.
  vec3 rel = p - uCameraPos;
  rel = mod(rel + uCell, uCell * 2.0) - uCell;
  vec3 world = uCameraPos + rel;

  // Fade at the cell boundary so wrapping is invisible.
  vec3 edge = 1.0 - smoothstep(vec3(0.55), vec3(1.0), abs(rel) / uCell);
  vFade = min(min(edge.x, edge.y), edge.z);

  // Embers cool as they rise; ash never glows.
  vHeat = clamp(1.0 - abs(rel.y) / (uCell.y * 0.7), 0.0, 1.0);

  vec4 mv = modelViewMatrix * vec4(world, 1.0);
  // Keep large ash sprites out of the lens. Without this near fade, the
  // camera-following particle cell can place an ash card a metre away, which
  // reads as a huge white bokeh blob instead of distant airborne ash.
  vFade *= smoothstep(110.0, 260.0, -mv.z);
  gl_Position = projectionMatrix * mv;
  gl_PointSize = aSize * uSizeScale * (330.0 / max(-mv.z, 1.0));
}`;

const frag = /* glsl */`
precision highp float;
varying float vSeed;
varying float vFade;
varying float vSpin;
varying float vHeat;

uniform sampler2D uSprite;
uniform int   uMode;         // 0 sprite, 1 ember, 2 streak, 3 flake
uniform vec3  uColor;
uniform float uOpacity;
uniform float uTime;
uniform float uEmberMood;
uniform vec3  uSkyTint;

${NOISE_GLSL}

void main(){
  vec2 uv = gl_PointCoord - 0.5;
  float a = 0.0;
  vec3 col = uColor;

  if (uMode == 0) {                       // soft sprite (dust, ash cloud)
    vec4 s = texture2D(uSprite, gl_PointCoord);
    a = s.a;
    col *= 0.7 + s.a * 0.6;
  } else if (uMode == 1) {                // ember: hot core + halo, flickering
    float r = length(uv);
    float flick = 0.55 + 0.45 * sin(uTime * (18.0 + vSeed * 26.0) + vSeed * 60.0);
    float core = 1.0 - smoothstep(0.0, 0.14, r);
    float halo = 1.0 - smoothstep(0.05, 0.5, r);
    a = clamp(core + halo * 0.55, 0.0, 1.0) * flick;
    col = fireRamp(0.45 + core * 0.55) * (0.9 + core * 1.8) * uEmberMood;
  } else if (uMode == 2) {                // wind streak
    /**
     * Rotate into the streak's own frame, then draw a thin capsule.
     *
     * The axis scales have to be chosen so the falloff actually *completes*
     * inside the quad. gl_PointCoord gives uv in [-0.5, 0.5] here, so the
     * largest |r.x| a fragment can reach is 0.5 — and the previous scale of
     * 0.16 put the maximum possible d along the streak's length at 0.08,
     * nowhere near the 0.5 threshold where alpha reaches zero. The result was
     * a bar at constant alpha running clean off the edge of its own sprite:
     * the streak never faded out, it was simply clipped by the quad, which is
     * why storms filled the screen with hard-edged translucent rectangles.
     *
     * 1.05 on the long axis means d crosses the threshold just before the
     * sprite boundary, so the capsule closes properly at both ends.
     */
    float c = cos(vSpin), s = sin(vSpin);
    vec2 r = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    float d = length(vec2(r.x * 1.05, r.y * 5.2));
    a = (1.0 - smoothstep(0.16, 0.5, d)) * 0.5;
  } else {                                // flake / leaf: rotating quad
    float c = cos(vSpin + uTime * 2.0), s = sin(vSpin + uTime * 2.0);
    vec2 r = vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c) + 0.5;
    if (r.x < 0.0 || r.x > 1.0 || r.y < 0.0 || r.y > 1.0) discard;
    vec4 t = texture2D(uSprite, r);
    a = t.a;
    col *= t.rgb * 1.6;
  }

  // Unlit particles are the classic giveaway: at night they float as grey
  // blobs on a black ground. Tie the non-emissive modes to ambient brightness.
  if (uMode == 0 || uMode == 3) {
    float amb = clamp(dot(uSkyTint, vec3(0.33)) * 3.1, 0.18, 1.5);
    col *= amb;
  }
  a *= vFade * uOpacity;
  if (a < 0.004) discard;
  gl_FragColor = vec4(col, a);
}`;

function makeField({
  count, cell, sprite, mode, color, opacity, size, fall, turbulence, drift, blending, spinRange = Math.PI,
}) {
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(count * 3);
  const seed = new Float32Array(count * 3);
  const sz = new Float32Array(count);
  const spin = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    pos[i * 3] = (Math.random() * 2 - 1) * cell[0];
    pos[i * 3 + 1] = (Math.random() * 2 - 1) * cell[1];
    pos[i * 3 + 2] = (Math.random() * 2 - 1) * cell[2];
    seed[i * 3] = Math.random();
    seed[i * 3 + 1] = Math.random();
    seed[i * 3 + 2] = Math.random();
    sz[i] = size * (0.45 + Math.random() * 1.2);
    spin[i] = Math.random() * spinRange;
  }
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 3));
  geo.setAttribute('aSize', new THREE.BufferAttribute(sz, 1));
  geo.setAttribute('aSpin', new THREE.BufferAttribute(spin, 1));

  const mat = new THREE.ShaderMaterial({
    vertexShader: vert, fragmentShader: frag,
    uniforms: {
      uTime: G.uTime,
      uWindDir: G.uWindDir,
      uWindStrength: G.uWindStrength,
      uEmberMood: G.uEmberMood,
      uCameraPos: { value: new THREE.Vector3() },
      uCell: { value: new THREE.Vector3(...cell) },
      uFall: { value: fall },
      uTurbulence: { value: turbulence },
      uSizeScale: { value: 1 },
      uDrift: { value: drift },
      uSprite: { value: sprite ?? null },
      uMode: { value: mode },
      uColor: { value: new THREE.Color(color) },
      uOpacity: { value: opacity },
      uSpawnJitter: { value: 1 },
      uSkyTint: G.uFogColor,
    },
    transparent: true,
    depthWrite: false,
    blending: blending ?? THREE.NormalBlending,
  });

  const pts = new THREE.Points(geo, mat);
  pts.frustumCulled = false;
  return pts;
}

export class Atmosphere {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Atmosphere';
    this.fields = {};

    const T = materials.T;

    // Volcanic ash — the signature of the realm. Big cell, slow fall.
    this.fields.ash = makeField({
      count: settings.ashCount, cell: [700, 340, 700], sprite: T.smoke, mode: 0,
      color: 0x8a8280, opacity: 0.12, size: 10, fall: 5.5, turbulence: 0.7, drift: 5.5,
    });

    // Embers rising off the lava, blown downwind.
    this.fields.ember = makeField({
      count: settings.emberCount, cell: [420, 200, 420], sprite: null, mode: 1,
      color: 0xff7a2a, opacity: 0.60, size: 2.1, fall: -7.5, turbulence: 0.55, drift: 7.0,
      blending: THREE.AdditiveBlending,
    });

    // Fine dust close to the ground — reads as scale.
    this.fields.dust = makeField({
      count: settings.dustCount, cell: [260, 90, 260], sprite: T.glow, mode: 0,
      color: 0xb8a390, opacity: 0.10, size: 1.7, fall: 1.2, turbulence: 0.4, drift: 3.0,
      blending: THREE.AdditiveBlending,
    });

    // Wind streaks — long, faint, fast. Sells air movement in a storm.
    this.fields.wind = makeField({
      count: settings.windCount, cell: [340, 180, 340], sprite: null, mode: 2,
      color: 0xcfd6e0, opacity: 0.0, size: 46, fall: 0.4, turbulence: 0.25, drift: 26.0,
      blending: THREE.AdditiveBlending, spinRange: 0.6,
    });

    // Leaves torn off the forest.
    this.fields.leaf = makeField({
      count: settings.leafCount, cell: [240, 70, 240], sprite: T.leaf, mode: 3,
      color: 0xffffff, opacity: 0.55, size: 3.2, fall: 4.0, turbulence: 0.85, drift: 6.0,
      spinRange: Math.PI * 2,
    });

    for (const f of Object.values(this.fields)) this.group.add(f);
    this.setWeather({ ash: 0.35, ember: 1, dust: 1, wind: 0, leaf: 0.6 });
  }

  /** Per-field opacity multipliers, driven by the weather system. */
  setWeather({ ash, ember, dust, wind, leaf }) {
    this._base = this._base ?? {};
    // Hard caps. Weather multipliers stack (ash storm × eruption boost reached
    // 6.6×), and past 1.0 a soft smoke sprite stops being soft — it draws as an
    // opaque disc. Which is exactly what the eruption sky filled up with.
    const set = (k, v, base, cap) => {
      if (v == null) return;
      const o = Math.min(base * v, cap);
      this._base[k] = o;
      this.fields[k].material.uniforms.uOpacity.value = o;
    };
    set('ash', ash, 0.24, 0.42);
    set('ember', ember, 0.60, 0.85);
    set('dust', dust, 0.14, 0.26);
    set('wind', wind, 0.30, 0.40);
    set('leaf', leaf, 0.55, 0.70);
  }

  update(dt, camera) {
    for (const f of Object.values(this.fields)) {
      f.material.uniforms.uCameraPos.value.copy(camera.position);
    }
    // Leaves and dust belong to the ground layer. The wrap cell follows the
    // camera, so without this they'd swarm around you at 400 m — reading as
    // bats, not litter. Fade them out with altitude instead.
    const alt = camera.position.y;
    const ground = 1 - Math.min(1, Math.max(0, (alt - 90) / 130));
    this.fields.leaf.material.uniforms.uOpacity.value = this._base.leaf * ground;
    this.fields.dust.material.uniforms.uOpacity.value = this._base.dust * ground;
  }

  dispose() {
    for (const f of Object.values(this.fields)) { f.geometry.dispose(); f.material.dispose(); }
  }
}

/* ── rain ─────────────────────────────────────────────────────────────── */

export class Rain {
  constructor(settings) {
    const count = settings.rainCount;
    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(count * 3);
    const seed = new Float32Array(count);
    const len = new Float32Array(count);
    const cell = [220, 160, 220];
    for (let i = 0; i < count; i++) {
      pos[i * 3] = (Math.random() * 2 - 1) * cell[0];
      pos[i * 3 + 1] = (Math.random() * 2 - 1) * cell[1];
      pos[i * 3 + 2] = (Math.random() * 2 - 1) * cell[2];
      seed[i] = Math.random();
      len[i] = 2.4 + Math.random() * 5.5;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1));
    geo.setAttribute('aLen', new THREE.BufferAttribute(len, 1));

    // Drops are line segments stretched along their velocity — points can't
    // convey rain speed, streaks can.
    const mat = new THREE.ShaderMaterial({
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
      uniforms: {
        uTime: G.uTime,
        uCameraPos: { value: new THREE.Vector3() },
        uCell: { value: new THREE.Vector3(...cell) },
        uWindDir: G.uWindDir,
        uWindStrength: G.uWindStrength,
        uOpacity: { value: 0 },
        uSpeed: { value: 78 },
      },
      vertexShader: /* glsl */`
        attribute float aSeed;
        attribute float aLen;
        varying float vFade;
        varying float vSeed;
        uniform float uTime, uSpeed, uWindStrength;
        uniform vec3 uCameraPos, uCell;
        uniform vec2 uWindDir;
        void main(){
          vSeed = aSeed;
          vec3 p = position;
          p.y -= uTime * uSpeed * (0.75 + aSeed * 0.5);
          p.xz += uWindDir * uTime * uWindStrength * 16.0;
          vec3 rel = mod(p - uCameraPos + uCell, uCell * 2.0) - uCell;
          vec3 w = uCameraPos + rel;
          vec3 edge = 1.0 - smoothstep(vec3(0.6), vec3(1.0), abs(rel) / uCell);
          vFade = min(min(edge.x, edge.y), edge.z);
          vec4 mv = modelViewMatrix * vec4(w, 1.0);
          gl_Position = projectionMatrix * mv;
          gl_PointSize = (1.0 + aLen * 0.35) * (300.0 / max(-mv.z, 1.0));
        }`,
      fragmentShader: /* glsl */`
        varying float vFade;
        varying float vSeed;
        uniform float uOpacity;
        void main(){
          vec2 uv = gl_PointCoord - 0.5;
          // Vertical capsule — the drop's motion blur.
          float d = length(vec2(uv.x * 6.0, uv.y * 0.9));
          float a = (1.0 - smoothstep(0.1, 0.5, d)) * vFade * uOpacity;
          if (a < 0.006) discard;
          gl_FragColor = vec4(vec3(0.72, 0.80, 0.92), a);
        }`,
    });

    this.points = new THREE.Points(geo, mat);
    this.points.frustumCulled = false;
    this.points.name = 'Rain';
    this.group = this.points;
    this.strength = 0;
  }

  setStrength(v) {
    this.strength = v;
    this.points.material.uniforms.uOpacity.value = v * 0.55;
    this.points.visible = v > 0.01;
  }

  update(dt, camera) {
    this.points.material.uniforms.uCameraPos.value.copy(camera.position);
  }

  dispose() { this.points.geometry.dispose(); this.points.material.dispose(); }
}
