/**
 * Wildfire — the world remembers being burned.
 *
 * Anything that delivers heat to the ground (the dragon's breath, a volcanic
 * bomb, a lightning strike) calls `ignite()`. A *site* is born there: a cluster
 * of flame billboards, a smoke column and a scorch patch. Sites grow, burn,
 * throw spot-fires into neighbouring vegetation, and die back — but the scorch
 * outlives them, its ember cracks cooling from orange to black over a minute.
 *
 * Budget is fixed at boot so a long session can never snowball:
 *   MAX_SITES sites × FLAMES flame quads + SMOKES smoke quads (two instanced
 *   draws), one merged scorch mesh (one draw), and *no* extra lights — the
 *   hottest site borrows the shared fire-light term every material already
 *   evaluates (G.uFirePos), so a burning world costs no per-pixel lighting.
 *
 * Scorch patches are little grids conformed to the analytic heightfield on
 * spawn, so they hug slopes instead of slicing through them like a flat decal.
 */
import * as THREE from 'three';
import { bus, EV } from '../core/EventBus.js';
import { G } from '../materials/GlobalUniforms.js';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';
import { height, canPlant, isOnWater, isOnLava } from './Heightfield.js';
import { TAU, smoothstep, clamp } from '../utils/MathX.js';

const MAX_SITES = 44;
const FLAMES = 12;
const SMOKES = 3;
const GRID = 9;                 // scorch patch resolution (GRID × GRID verts)
const SCORCH_LIFE = 70;         // seconds a burn scar stays visible

const FLAME_VS = /* glsl */`
  attribute vec4 aSite;     // xyz base, w seed
  attribute vec4 aShape;    // x height, y width, z heat, w kind (0 flame, 1 smoke)
  uniform float uTime;
  varying vec2 vUv;
  varying float vHeat;
  varying float vSeed;
  varying float vKind;
  varying float vPhase;

  void main(){
    vUv = uv;
    vHeat = aShape.z;
    vSeed = aSite.w;
    vKind = aShape.w;

    vec3 base = aSite.xyz;
    float h = aShape.x;
    float w = aShape.y;
    vPhase = 0.0;

    if (aShape.w > 0.5) {
      // Smoke puffs loop up the column; each puff has its own phase.
      float ph = fract(uTime * 0.075 + aSite.w * 7.31);
      vPhase = ph;
      base.y += ph * h * 3.2;
      base.x += ph * ph * 60.0 * (0.6 + 0.4 * sin(aSite.w * 11.0));
      base.z += ph * ph * 38.0;
      w *= 0.6 + ph * 2.4;
      h = w;
    }

    // Cylindrical billboard: stays upright, turns to face the camera.
    vec3 toCam = cameraPosition - base;
    vec3 right = normalize(vec3(toCam.z, 0.0, -toCam.x) + 1e-5);
    vec3 up = vec3(0.0, 1.0, 0.0);
    if (aShape.w > 0.5) up = normalize(cross(normalize(toCam), right));

    vec2 q = position.xy;        // plane is [-0.5,0.5] × [0,1] (see geometry)
    vec3 wp = base + right * q.x * w + up * q.y * h;
    gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
  }`;

const FLAME_FS = /* glsl */`
  uniform float uTime;
  uniform float uEmberMood;
  varying vec2 vUv;
  varying float vHeat;
  varying float vSeed;
  varying float vKind;
  varying float vPhase;
  ${NOISE_GLSL}

  void main(){
    if (vHeat <= 0.002) discard;

    if (vKind > 0.5) {
      // ── smoke ──
      vec2 c = vUv - 0.5;
      float n = fbm(vec3(c * 3.0 + vSeed * 9.0, uTime * 0.12 + vSeed), 4);
      float d = length(c) * 2.0 - n * 0.35;
      float a = smoothstep(1.0, 0.25, d);
      a *= sin(vPhase * 3.14159) * vHeat * 0.42;
      // Underlit by the fire for the first stretch of the column.
      vec3 col = mix(vec3(0.05, 0.045, 0.045), vec3(0.42, 0.14, 0.04), (1.0 - vPhase) * (1.0 - vPhase) * 0.8);
      gl_FragColor = vec4(col, a);
      return;
    }

    // ── flame ──
    vec2 p = vec2(vUv.x - 0.5, vUv.y);
    float t = uTime * 1.9 + vSeed * 13.0;
    // Turbulence advected upward, stronger near the tips.
    float n  = fbm(vec3(p.x * 3.2, p.y * 2.2 - t, vSeed * 5.0), 4);
    float n2 = snoise(vec3(p.x * 7.0, p.y * 5.0 - t * 1.7, vSeed));
    float x = p.x + (n - 0.5) * 0.55 * p.y + n2 * 0.06 * p.y;

    // Teardrop silhouette that pinches at the top.
    float width = 0.44 * (1.0 - smoothstep(0.0, 1.0, p.y)) * smoothstep(-0.05, 0.18, p.y);
    float body = 1.0 - smoothstep(width * 0.35, width, abs(x));
    body *= smoothstep(1.0, 0.45 + n * 0.3, p.y);
    body = clamp(body * (0.75 + n), 0.0, 1.0);
    if (body < 0.01) discard;

    float heat = body * (1.15 - p.y * 0.85) * vHeat;
    // Hold it below white-hot: a forest fire is orange, the white is the breath.
    vec3 col = fireRamp(clamp(heat * 0.92, 0.0, 0.84)) * (1.0 + heat * 1.6) * uEmberMood;
    gl_FragColor = vec4(col, body * vHeat);
  }`;

const SCORCH_VS = /* glsl */`
  attribute vec2 aScorch;   // x heat 0..1, y fade 0..1
  attribute float aRad;     // normalized distance from patch centre
  varying vec3 vWPos;
  varying vec2 vScorch;
  varying float vRad;
  #include <fog_pars_vertex>
  void main(){
    vScorch = aScorch;
    vRad = aRad;
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vWPos = wp.xyz;
    vec4 mvPosition = viewMatrix * wp;
    gl_Position = projectionMatrix * mvPosition;
    #include <fog_vertex>
  }`;

const SCORCH_FS = /* glsl */`
  uniform float uTime;
  varying vec3 vWPos;
  varying vec2 vScorch;
  varying float vRad;
  #include <fog_pars_fragment>
  ${NOISE_GLSL}
  void main(){
    float fade = vScorch.y;
    if (fade <= 0.002) discard;
    // Ragged burn edge.
    float edge = fbm(vec3(vWPos.xz * 0.045, 1.7), 4);
    float mask = smoothstep(1.0, 0.55, vRad + (edge - 0.5) * 0.6);
    if (mask < 0.01) discard;

    float grain = fbm(vec3(vWPos.xz * 0.3, 4.0), 3);
    vec3 char = mix(vec3(0.012, 0.010, 0.010), vec3(0.075, 0.062, 0.055), grain);
    // Ember cracks: thin voronoi seams, only some of them alive, and only
    // toward the middle of the burn — the edges cool first.
    vec2 vo = voronoi(vWPos.xz * 0.22 + edge * 2.0);
    float seam = 1.0 - smoothstep(0.0, 0.035, vo.y - vo.x);
    float live = smoothstep(0.45, 0.75, fbm(vec3(vWPos.xz * 0.06, uTime * 0.08), 3));
    float core = smoothstep(0.95, 0.2, vRad);
    float pulse = 0.7 + 0.3 * snoise(vec3(vWPos.xz * 0.05, uTime * 0.7));
    float glow = vScorch.x * pulse * (seam * live * core * 1.4 + core * core * 0.18);
    vec3 col = char + lavaRamp(clamp(glow, 0.0, 0.85)) * glow * 1.1;
    gl_FragColor = vec4(col, mask * fade * 0.92);
    #include <fog_fragment>
  }`;

export class Wildfire {
  constructor(settings) {
    this.group = new THREE.Group();
    this.group.name = 'Wildfire';
    const low = settings?.tier === 'low';
    this.maxSites = low ? 24 : MAX_SITES;

    this.sites = [];
    for (let i = 0; i < this.maxSites; i++) {
      this.sites.push({
        alive: false, scorchAge: 1e9, age: 0, life: 0, heat: 0,
        pos: new THREE.Vector3(), radius: 20, gen: 0, seed: Math.random(),
        spreadT: 0, flames: [],
      });
    }

    this._buildBillboards();
    this._buildScorch();

    this._tmp = new THREE.Vector3();
    this.unsub = bus.on(EV.IGNITE, (e) => { if (e.ignite !== false) this.ignite(e.pos, e); });
  }

  /* ── build ────────────────────────────────────────────────────────── */

  _buildBillboards() {
    const plane = new THREE.PlaneGeometry(1, 1, 1, 1);
    plane.translate(0, 0.5, 0);

    const n = this.maxSites * (FLAMES + SMOKES);
    const geo = new THREE.InstancedBufferGeometry();
    geo.setIndex(plane.index);
    geo.setAttribute('position', plane.attributes.position);
    geo.setAttribute('uv', plane.attributes.uv);
    this._aSite = new THREE.InstancedBufferAttribute(new Float32Array(n * 4), 4);
    this._aShape = new THREE.InstancedBufferAttribute(new Float32Array(n * 4), 4);
    this._aSite.setUsage(THREE.DynamicDrawUsage);
    this._aShape.setUsage(THREE.DynamicDrawUsage);
    geo.setAttribute('aSite', this._aSite);
    geo.setAttribute('aShape', this._aShape);
    geo.instanceCount = n;

    // Two materials over one geometry: smoke first (alpha), flames on top (add).
    const mk = (blending, kindPass) => new THREE.ShaderMaterial({
      uniforms: { uTime: G.uTime, uEmberMood: G.uEmberMood },
      vertexShader: FLAME_VS,
      fragmentShader: FLAME_FS.replace('void main(){',
        `void main(){ if ((vKind > 0.5) != ${kindPass ? 'true' : 'false'}) discard;`),
      transparent: true, depthWrite: false, blending, side: THREE.DoubleSide,
    });
    this.smoke = new THREE.Mesh(geo, mk(THREE.NormalBlending, true));
    this.flames = new THREE.Mesh(geo, mk(THREE.AdditiveBlending, false));
    for (const m of [this.smoke, this.flames]) { m.frustumCulled = false; this.group.add(m); }
    this.smoke.renderOrder = 4;
    this.flames.renderOrder = 5;
    this.billboardGeo = geo;
  }

  _buildScorch() {
    const vPer = GRID * GRID;
    const n = this.maxSites;
    const pos = new Float32Array(n * vPer * 3);
    const sc = new Float32Array(n * vPer * 2);
    const rad = new Float32Array(n * vPer);
    const idx = [];
    for (let s = 0; s < n; s++) {
      const o = s * vPer;
      for (let j = 0; j < GRID; j++) {
        for (let i = 0; i < GRID; i++) {
          const u = i / (GRID - 1) * 2 - 1, v = j / (GRID - 1) * 2 - 1;
          rad[o + j * GRID + i] = Math.hypot(u, v);
          pos[(o + j * GRID + i) * 3 + 1] = -9999;
        }
      }
      for (let j = 0; j < GRID - 1; j++) {
        for (let i = 0; i < GRID - 1; i++) {
          const a = o + j * GRID + i, b = a + 1, c = a + GRID, d = c + 1;
          idx.push(a, c, b, b, c, d);
        }
      }
    }
    const geo = new THREE.BufferGeometry();
    this._sPos = new THREE.BufferAttribute(pos, 3).setUsage(THREE.DynamicDrawUsage);
    this._sSc = new THREE.BufferAttribute(sc, 2).setUsage(THREE.DynamicDrawUsage);
    geo.setAttribute('position', this._sPos);
    geo.setAttribute('aScorch', this._sSc);
    geo.setAttribute('aRad', new THREE.BufferAttribute(rad, 1));
    geo.setIndex(idx);

    const mat = new THREE.ShaderMaterial({
      uniforms: THREE.UniformsUtils.merge([THREE.UniformsLib.fog, { uTime: { value: 0 } }]),
      vertexShader: SCORCH_VS,
      fragmentShader: SCORCH_FS,
      transparent: true, depthWrite: false, fog: true,
      polygonOffset: true, polygonOffsetFactor: -4, polygonOffsetUnits: -4,
    });
    mat.uniforms.uTime = G.uTime;
    this.scorch = new THREE.Mesh(geo, mat);
    this.scorch.frustumCulled = false;
    this.scorch.renderOrder = 2;
    this.group.add(this.scorch);
  }

  /* ── api ──────────────────────────────────────────────────────────── */

  /**
   * Set fire to the ground at `pos`. Re-igniting near a live site feeds it
   * rather than stacking a new one, so a three-second breath raking across a
   * field lays a *line* of fire instead of forty sites in one spot.
   */
  ignite(pos, { radius = 22, strength = 1, gen = 0 } = {}) {
    if (!pos) return null;
    const x = pos.x, z = pos.z;
    if (isOnWater(x, z) || isOnLava(x, z)) return null;

    for (const s of this.sites) {
      if (!s.alive) continue;
      if (Math.hypot(s.pos.x - x, s.pos.z - z) < s.radius * 0.9) {
        s.life = Math.max(s.life, s.age + 14 + strength * 6);
        s.boost = Math.min(1.6, (s.boost ?? 1) + 0.25 * strength);
        return s;
      }
    }

    // Recycle: a dead site with the oldest scar, else the coolest live one.
    let pick = null;
    for (const s of this.sites) {
      if (!s.alive && (!pick || s.scorchAge > pick.scorchAge)) pick = s;
    }
    if (!pick) {
      for (const s of this.sites) if (!pick || s.heat < pick.heat) pick = s;
    }

    const s = pick;
    s.alive = true;
    s.age = 0;
    s.scorchAge = 0;
    s.gen = gen;
    s.boost = 1;
    s.radius = radius * (0.85 + Math.random() * 0.3);
    s.life = 12 + Math.random() * 10 + strength * 6;
    s.spreadT = 2 + Math.random() * 3;
    s.seed = Math.random();
    s.pos.set(x, height(x, z), z);

    // Lay out this site's flames once.
    s.flames.length = 0;
    for (let k = 0; k < FLAMES; k++) {
      const a = Math.random() * TAU;
      const r = Math.sqrt(Math.random()) * s.radius * 0.75;
      const fx = x + Math.cos(a) * r, fz = z + Math.sin(a) * r;
      s.flames.push({
        x: fx, y: height(fx, fz) - 0.5, z: fz,
        h: 14 + Math.random() * 22 * (1 - r / s.radius * 0.5),
        w: 8 + Math.random() * 8,
        seed: Math.random(),
      });
    }
    this._writeScorchPatch(this.sites.indexOf(s), s);
    return s;
  }

  get activeCount() { return this.sites.reduce((n, s) => n + (s.alive ? 1 : 0), 0); }

  /** Put everything out (scars stay). */
  douse() { for (const s of this.sites) s.life = Math.min(s.life, s.age + 1.5); }

  /* ── frame ────────────────────────────────────────────────────────── */

  update(dt, camera, breathActive = false) {
    const aSite = this._aSite.array;
    const aShape = this._aShape.array;
    const sc = this._sSc.array;
    const vPer = GRID * GRID;
    const wet = G.uWetness.value;     // rain shortens burns
    let anyVisible = false;
    let anyScorch = false;

    for (let i = 0; i < this.sites.length; i++) {
      const s = this.sites[i];
      s.scorchAge += dt;

      if (s.alive) {
        s.age += dt * (1 + wet * 1.5);
        const grow = smoothstep(0, 1.6, s.age);
        const die = 1 - smoothstep(s.life - 4, s.life, s.age);
        s.heat = grow * die * (s.boost ?? 1);
        s.boost = Math.max(1, (s.boost ?? 1) - dt * 0.05);
        if (s.age >= s.life) { s.alive = false; s.heat = 0; }

        // Spot-fires: a strong site in vegetation throws embers downwind.
        s.spreadT -= dt;
        if (s.alive && s.spreadT <= 0 && s.gen < 3 && s.heat > 0.6 && wet < 0.4) {
          s.spreadT = 3.5 + Math.random() * 4;
          const wd = G.uWindDir.value;
          const a = Math.atan2(wd.y, wd.x) + (Math.random() - 0.5) * 2.2;
          const d = s.radius * (1.3 + Math.random() * 0.8);
          const nx = s.pos.x + Math.cos(a) * d, nz = s.pos.z + Math.sin(a) * d;
          if (canPlant(nx, nz)) {
            this.ignite(this._tmp.set(nx, 0, nz), { radius: s.radius * 0.9, strength: 0.7, gen: s.gen + 1 });
          }
        }
      }

      // Scorch: hot while burning, then cools; fades out at end of life.
      const cool = s.alive ? s.heat : Math.max(0, 1 - (s.age - s.life) / 25) * 0.6;
      if (!s.alive) s.age += dt;
      const fade = smoothstep(SCORCH_LIFE, SCORCH_LIFE - 12, s.scorchAge) * smoothstep(0, 1.2, s.scorchAge);
      if (fade > 0.002) anyScorch = true;
      const o = i * vPer * 2;
      if (sc[o] !== cool || sc[o + 1] !== fade) {
        for (let v = 0; v < vPer; v++) { sc[o + v * 2] = cool; sc[o + v * 2 + 1] = fade; }
      }

      // Billboards.
      const base = i * (FLAMES + SMOKES);
      for (let k = 0; k < FLAMES + SMOKES; k++) {
        const j = (base + k) * 4;
        const isSmoke = k >= FLAMES;
        const f = s.flames[isSmoke ? (k - FLAMES) * 3 : k];
        if (!s.alive || !f || s.heat <= 0.002) { aShape[j + 2] = 0; continue; }
        anyVisible = true;
        const flick = 0.85 + 0.15 * Math.sin(G.uTime.value * (7 + f.seed * 5) + f.seed * 40);
        aSite[j] = f.x; aSite[j + 1] = f.y; aSite[j + 2] = f.z; aSite[j + 3] = isSmoke ? f.seed + k * 0.37 : f.seed;
        aShape[j] = isSmoke ? 22 : f.h * (0.55 + 0.45 * s.heat) * flick;
        aShape[j + 1] = isSmoke ? 26 + s.radius : f.w;
        aShape[j + 2] = Math.min(1.25, s.heat);
        aShape[j + 3] = isSmoke ? 1 : 0;
      }
    }

    this._aSite.needsUpdate = true;
    this._aShape.needsUpdate = true;
    this._sSc.needsUpdate = true;
    this.flames.visible = this.smoke.visible = anyVisible;
    this.scorch.visible = anyScorch;

    if (!breathActive) this._updateLights(camera);
  }

  /**
   * Light the world from the fire without adding lights.
   *
   * injectAmbient() already gives every opaque material an N·L-shaded,
   * distance-attenuated term from G.uFirePos — it exists for the breath and is
   * paid for whether anything is burning or not. While the dragon isn't
   * breathing, the most significant site near the camera drives it. Two real
   * PointLights did this first; they cost every lit fragment in the scene.
   */
  _updateLights(camera) {
    let best = null, bestScore = 0;
    for (const s of this.sites) {
      if (!s.alive || s.heat < 0.05) continue;
      const d = s.pos.distanceTo(camera.position);
      const score = s.heat * s.radius / Math.max(60, d);
      if (score > bestScore) { best = s; bestScore = score; }
    }
    const target = best ? Math.min(1, best.heat) * 0.75 * (0.85 + 0.15 * Math.sin(G.uTime.value * 13)) : 0;
    if (best) G.uFirePos.value.copy(best.pos).add(this._tmp.set(0, 16, 0));
    G.uFireIntensity.value += (target - G.uFireIntensity.value) * 0.2;
  }

  _writeScorchPatch(i, s) {
    const pos = this._sPos.array;
    const vPer = GRID * GRID;
    const R = s.radius * 1.35;
    for (let j = 0; j < GRID; j++) {
      for (let k = 0; k < GRID; k++) {
        const u = k / (GRID - 1) * 2 - 1, v = j / (GRID - 1) * 2 - 1;
        const x = s.pos.x + u * R, z = s.pos.z + v * R;
        const o = (i * vPer + j * GRID + k) * 3;
        pos[o] = x; pos[o + 1] = height(x, z) + 0.35; pos[o + 2] = z;
      }
    }
    this._sPos.needsUpdate = true;
  }

  dispose() {
    this.unsub?.();
    this.group.traverse((o) => { o.geometry?.dispose(); o.material?.dispose(); });
  }
}
