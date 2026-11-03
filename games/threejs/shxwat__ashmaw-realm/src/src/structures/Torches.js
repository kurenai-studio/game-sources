/**
 * Torches.
 *
 * Hundreds of flames, a handful of lights. The posts and baskets are two
 * InstancedMeshes; the flames are a single Points cloud with a procedural fire
 * shader; and only the N nearest torches to the camera get a real PointLight,
 * recycled from a pool each frame. That's how you get a village that looks lit
 * by fifty torches while paying for seven.
 */
import * as THREE from 'three';
import * as BGU from 'three/addons/utils/BufferGeometryUtils.js';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';
import { G } from '../materials/GlobalUniforms.js';
import { makeRng } from '../utils/Noise.js';
import { TAU } from '../utils/MathX.js';
import { WORLD, height, canBuild } from '../world/Heightfield.js';

const flameVert = /* glsl */`
attribute float aSeed;
attribute float aScale;
varying float vSeed;
varying float vScale;
uniform float uTime;
uniform float uWindStrength;
uniform vec2  uWindDir;

void main(){
  vSeed = aSeed;
  vScale = aScale;
  vec3 p = position;
  // Lean downwind and flutter.
  float t = uTime * (2.2 + aSeed * 1.7) + aSeed * 40.0;
  p.xz += uWindDir * (0.28 + 0.22 * sin(t)) * uWindStrength * aScale;
  p.y += sin(t * 1.7) * 0.05 * aScale;
  vec4 mv = modelViewMatrix * vec4(p, 1.0);
  gl_Position = projectionMatrix * mv;
  // ~1.6 m flame: worldSize * (0.5*viewportH / tan(halfFov)) / dist ≈ *1000/dist
  gl_PointSize = aScale * 6.5 * (300.0 / max(-mv.z, 1.0));
}`;

const flameFrag = /* glsl */`
precision highp float;
varying float vSeed;
varying float vScale;
uniform float uTime;
uniform float uEmberMood;

${NOISE_GLSL}

void main(){
  vec2 uv = gl_PointCoord * 2.0 - 1.0;
  uv.y = -uv.y;                            // point coords are y-down

  // Teardrop mask: narrow at the top, fat at the base.
  float taper = mix(1.25, 0.42, clamp(uv.y * 0.5 + 0.5, 0.0, 1.0));
  float r = length(vec2(uv.x / taper, (uv.y - 0.12) * 0.85));

  // Flicker the silhouette with advected noise.
  float t = uTime * 3.4 + vSeed * 50.0;
  float n = fbm(vec3(uv * 2.6, t * 0.9), 4);
  r += n * 0.34 * (0.5 + uv.y * 0.5 + 0.5);

  float body = 1.0 - smoothstep(0.42, 0.95, r);
  if (body < 0.01) discard;

  float core = 1.0 - smoothstep(0.0, 0.44, r);
  vec3 col = fireRamp(core * 0.75 + body * 0.35 + 0.12);
  col *= 0.5 + core * 0.85;

  gl_FragColor = vec4(col * uEmberMood, body * (0.42 + core * 0.4));
}`;

export class Torches {
  constructor(materials, settings, { extraSpots = [] } = {}) {
    this.group = new THREE.Group();
    this.group.name = 'Torches';
    const rng = makeRng(1414);

    // ── where the torches go ────────────────────────────────────────
    const spots = [];
    const V = WORLD.village;

    // Village lanes.
    for (const laneA of [0.4, 2.1, 4.0]) {
      for (let s = 14; s < 130; s += 22) {
        for (const side of [-1, 1]) {
          const x = V.x + Math.cos(laneA) * s + Math.cos(laneA + Math.PI / 2) * 6.5 * side;
          const z = V.z + Math.sin(laneA) * s + Math.sin(laneA + Math.PI / 2) * 6.5 * side;
          if (canBuild(x, z)) spots.push([x, z, 1.0]);
        }
      }
    }
    // Plaza ring.
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TAU;
      spots.push([V.x + Math.cos(a) * 13, V.z + Math.sin(a) * 13, 1.15]);
    }
    // Temple approach.
    for (let i = 0; i < 6; i++) {
      const t = i / 5;
      spots.push([
        WORLD.temple.x + 30 + t * 40,
        WORLD.temple.z - 20 + t * 44,
        0.9,
      ]);
    }
    spots.push(...extraSpots);

    this.spots = spots.map(([x, z, s]) => new THREE.Vector3(x, height(x, z), z));
    const scales = spots.map((s) => s[2]);

    // ── posts + baskets ─────────────────────────────────────────────
    const postGeo = (() => {
      const parts = [];
      const p = new THREE.CylinderGeometry(0.11, 0.16, 4.2, 6);
      p.translate(0, 2.1, 0);
      parts.push(p);
      const g = BGU.mergeGeometries(parts);
      parts.forEach((x) => x.dispose());
      return g;
    })();
    const basketGeo = (() => {
      const parts = [];
      const b = new THREE.CylinderGeometry(0.46, 0.3, 0.7, 8, 1, true);
      b.translate(0, 4.35, 0);
      parts.push(b);
      const ring = new THREE.TorusGeometry(0.46, 0.055, 4, 10);
      ring.rotateX(Math.PI / 2);
      ring.translate(0, 4.7, 0);
      parts.push(ring);
      const g = BGU.mergeGeometries(parts);
      parts.forEach((x) => x.dispose());
      return g;
    })();

    const n = this.spots.length;
    const posts = new THREE.InstancedMesh(postGeo, materials.get('woodDark'), n);
    const baskets = new THREE.InstancedMesh(basketGeo, materials.get('iron'), n);
    posts.castShadow = baskets.castShadow = true;
    posts.name = 'TorchPosts';

    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion();
    const pos = new THREE.Vector3();
    const scl = new THREE.Vector3();
    const up = new THREE.Vector3(0, 1, 0);
    for (let i = 0; i < n; i++) {
      const s = scales[i] * (0.9 + rng() * 0.25);
      pos.copy(this.spots[i]);
      q.setFromAxisAngle(up, rng() * TAU);
      // Lean a couple of degrees; nothing in a village is plumb.
      q.multiply(new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0.3).normalize(), (rng() - 0.5) * 0.09));
      scl.setScalar(s);
      m.compose(pos, q, scl);
      posts.setMatrixAt(i, m);
      baskets.setMatrixAt(i, m);
      this.spots[i].y += 4.5 * s;   // flame height
    }
    this.group.add(posts, baskets);

    // ── flames ──────────────────────────────────────────────────────
    const geo = new THREE.BufferGeometry();
    const pArr = new Float32Array(n * 3);
    const seed = new Float32Array(n);
    const sc = new Float32Array(n);
    for (let i = 0; i < n; i++) {
      pArr[i * 3] = this.spots[i].x;
      pArr[i * 3 + 1] = this.spots[i].y;
      pArr[i * 3 + 2] = this.spots[i].z;
      seed[i] = rng();
      sc[i] = scales[i] * (0.85 + rng() * 0.4);
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pArr, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1));
    geo.setAttribute('aScale', new THREE.BufferAttribute(sc, 1));
    geo.computeBoundingSphere();

    // Glow volume: a wide soft sphere of scattered light around each flame.
    // Cheap, and it is the difference between "a dot" and "a lamp in fog".
    const glowGeo = geo.clone();
    this.glow = new THREE.Points(glowGeo, new THREE.ShaderMaterial({
      uniforms: {
        uTime: G.uTime, uEmberMood: G.uEmberMood,
        uSprite: { value: materials.T.glow },
        uNight: { value: 1 },
      },
      vertexShader: /* glsl */`
        attribute float aSeed;
        attribute float aScale;
        varying float vS;
        uniform float uTime;
        uniform float uNight;
        void main(){
          vS = aSeed;
          vec4 mv = modelViewMatrix * vec4(position, 1.0);
          gl_Position = projectionMatrix * mv;
          float flick = 0.86 + 0.14 * sin(uTime * (5.0 + aSeed * 7.0) + aSeed * 30.0);
          gl_PointSize = aScale * 12.0 * flick * (0.6 + uNight * 0.7) * (300.0 / max(-mv.z, 1.0));
        }`,
      fragmentShader: /* glsl */`
        precision highp float;
        varying float vS;
        uniform sampler2D uSprite;
        uniform float uEmberMood;
        uniform float uNight;
        void main(){
          vec4 s = texture2D(uSprite, gl_PointCoord);
          float a = s.a * s.a * (0.022 + uNight * 0.05);
          if (a < 0.003) discard;
          gl_FragColor = vec4(vec3(1.0, 0.55, 0.22) * uEmberMood * 0.9, a);
        }`,
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    }));
    this.glow.frustumCulled = false;
    this.glow.name = 'TorchGlow';
    this.group.add(this.glow);

    this.flames = new THREE.Points(geo, new THREE.ShaderMaterial({
      vertexShader: flameVert, fragmentShader: flameFrag,
      uniforms: {
        uTime: G.uTime, uEmberMood: G.uEmberMood,
        uWindDir: G.uWindDir, uWindStrength: G.uWindStrength,
      },
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    }));
    this.flames.name = 'TorchFlames';
    this.group.add(this.flames);

    // ── light pool ──────────────────────────────────────────────────
    this.lights = [];
    for (let i = 0; i < settings.torchLights; i++) {
      const l = new THREE.PointLight(0xff8f3c, 0, 90, 1.55);
      l.castShadow = false;
      this.group.add(l);
      this.lights.push(l);
    }
    this._order = this.spots.map((_, i) => i);
  }

  applyQuality(settings) {
    while (this.lights.length > settings.torchLights) {
      const l = this.lights.pop();
      this.group.remove(l);
      l.dispose?.();
    }
    while (this.lights.length < settings.torchLights) {
      const l = new THREE.PointLight(0xff8f3c, 0, 90, 1.55);
      this.group.add(l);
      this.lights.push(l);
    }
  }

  /** Assign the light pool to the nearest torches; flicker each one. */
  /** @param nightness 0 = daylight, 1 = full night — drives the glow volumes. */
  setNightness(n) {
    this.glow.material.uniforms.uNight.value = n;
  }

  update(dt, camera, elapsed, intensity = 1) {
    const cp = camera.position;
    // Partial selection: we only need the k smallest, and k is tiny.
    const k = this.lights.length;
    if (!k) return;
    const best = [];
    for (let i = 0; i < this.spots.length; i++) {
      const d = this.spots[i].distanceToSquared(cp);
      if (d > 260 * 260) continue;
      if (best.length < k) { best.push([d, i]); best.sort((a, b) => a[0] - b[0]); }
      else if (d < best[k - 1][0]) { best[k - 1] = [d, i]; best.sort((a, b) => a[0] - b[0]); }
    }
    for (let j = 0; j < k; j++) {
      const l = this.lights[j];
      if (j >= best.length) { l.intensity = 0; continue; }
      const idx = best[j][1];
      l.position.copy(this.spots[idx]);
      const f = 0.62 + 0.38 * Math.sin(elapsed * (7 + idx % 5) + idx)
              * Math.sin(elapsed * (3.1 + (idx % 3)) + idx * 2.7);
      // Fade out with distance so pool churn is never visible as a pop.
      const fade = 1 - Math.min(1, Math.sqrt(best[j][0]) / 260);
      // decay 1.55 with a 90 m radius: a visible pool on the ground rather
      // than a pinprick that inverse-square swallows in two metres.
      l.intensity = 19 * f * fade * intensity;
    }
  }

  dispose() { this.group.traverse((o) => o.geometry?.dispose()); }
}
