/**
 * Fire breath.
 *
 * Five layers, because a single particle system can't do this:
 *
 *  1. Core jet    — a cone of additive billboards advected along the breath
 *                   direction with curl turbulence, colour-ramped from white
 *                   core through orange to black smoke as each parcel ages.
 *  2. Sparks      — ballistic points with gravity and drag that survive past
 *                   the flame front and bounce off the ground.
 *  3. Smoke       — slow dark puffs shed from the tail of the jet.
 *  4. Ground fire — a decal-ish patch of flame where the jet hits terrain,
 *                   plus a scorch that lingers.
 *  5. Light       — a travelling PointLight at the jet's midpoint, plus the
 *                   global fire uniform that makes *every* surface shader in
 *                   the realm respond (that's what lights up the village).
 *
 * The heat-distortion post pass reads the same origin/strength, so refraction
 * always sits exactly on the flame.
 */
import * as THREE from 'three';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';
import { G } from '../materials/GlobalUniforms.js';
import { bus, EV } from '../core/EventBus.js';
import { height } from '../world/Heightfield.js';
import { clamp, smoothstep, TAU } from '../utils/MathX.js';

/* ── core jet ─────────────────────────────────────────────────────────── */

const jetVert = /* glsl */`
attribute vec3  aSeed;
attribute float aOffset;    // 0..1 position along the jet at birth
attribute float aSize;

varying float vLife;
varying float vSeed;
varying float vTurb;
varying float vNear;

uniform float uTime;
uniform vec3  uOrigin;
uniform vec3  uDir;
uniform float uLength;
uniform float uSpread;
uniform float uSpeed;
uniform float uActive;      // 0..1 envelope
uniform float uAge;         // seconds since ignition

${NOISE_GLSL}

void main(){
  vSeed = aSeed.x;

  // Each parcel cycles along the jet; stagger by aOffset for a continuous stream.
  float period = uLength / max(uSpeed, 1.0);
  float life = fract((uTime / period) + aOffset);
  vLife = life;

  // The front of the jet has to *arrive* — clamp reach by how long we've been
  // breathing, so ignition reads as a whip-crack rather than a switch.
  float reach = min(1.0, uAge * uSpeed / uLength);
  life = min(life, reach);

  vec3 dir = normalize(uDir);
  vec3 up = abs(dir.y) > 0.95 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
  vec3 right = normalize(cross(up, dir));
  vec3 realUp = normalize(cross(dir, right));

  // Cone: widens with distance, and the parcels swirl around the axis.
  float dist = life * uLength;
  float widen = uSpread * (0.06 + life * 1.0);
  float ang = aSeed.y * 6.2831 + life * (1.5 + aSeed.z * 3.0);
  float rad = widen * (0.25 + aSeed.z * 0.9);

  vec3 p = uOrigin + dir * dist
         + right * cos(ang) * rad
         + realUp * sin(ang) * rad;

  // Turbulence grows downstream — the tail of a flame is chaos.
  vec3 q = p * 0.06 + vec3(0.0, uTime * 0.9, 0.0);
  vec3 curl = curlNoise(q);
  float turbAmt = life * life * uSpread * 1.6;
  p += curl * turbAmt;
  vTurb = length(curl) * 0.5;

  // Buoyancy: the far end of the jet lifts.
  p.y += life * life * uLength * 0.10;

  float grow = aSize * (0.35 + life * 2.6);
  vec4 mv = modelViewMatrix * vec4(p, 1.0);
  gl_Position = projectionMatrix * mv;

  /**
   * Near-camera fade. The jet is additive point sprites, and a sprite's screen
   * size goes as 1/depth — so when the chase cam sits behind the dragon, the
   * parcels nearest the lens became screen-filling discs, hundreds of them
   * stacked additively, and the whole frame clipped to flat white. Fading
   * parcels out inside ~70 m and capping sprite size keeps the jet a jet.
   */
  vNear = smoothstep(14.0, 70.0, -mv.z);
  gl_PointSize = min(grow * (300.0 / max(-mv.z, 1.0)), 180.0) * uActive;
}`;

const jetFrag = /* glsl */`
precision highp float;
varying float vNear;
varying float vLife;
varying float vSeed;
varying float vTurb;

uniform float uTime;
uniform float uActive;
uniform float uEmberMood;

${NOISE_GLSL}

void main(){
  vec2 uv = gl_PointCoord * 2.0 - 1.0;
  float r = length(uv);

  // Erode the billboard with animated noise so parcels aren't discs.
  float n = fbm(vec3(uv * 2.2, uTime * 2.2 + vSeed * 40.0), 4);
  float mask = 1.0 - smoothstep(0.25 + n * 0.28, 1.0, r);
  if (mask < 0.01) discard;

  // Temperature falls along the jet; the head is white-hot.
  float heat = (1.0 - vLife) * (1.0 - vLife) * 1.35 + 0.12;
  heat *= 0.75 + mask * 0.55;
  heat -= vTurb * 0.12;

  vec3 col = fireRamp(clamp(heat, 0.0, 1.0));
  col *= (0.9 + heat * 2.7) * uEmberMood;

  // Alpha: opaque near the mouth, wispy at the tail.
  float a = mask * uActive * vNear * mix(0.62, 0.14, smoothstep(0.35, 1.0, vLife));
  gl_FragColor = vec4(col, a);
}`;

/* ── sparks ───────────────────────────────────────────────────────────── */

const sparkVert = /* glsl */`
attribute vec3  aVel;
attribute vec3  aSeed;
attribute float aBirth;
attribute float aLife;

varying float vT;
varying float vSeed;

uniform float uTime;
uniform vec3  uOrigin;
uniform float uActive;
uniform float uEmitTime;

void main(){
  // Staggered by aBirth so the stream is continuous, then each spark recycles.
  float t = mod(max(0.0, uTime - uEmitTime - aBirth * aLife), aLife);
  vT = t / aLife;
  vSeed = aSeed.x;

  vec3 p = uOrigin + aVel * t;
  p.y -= 9.8 * t * t * 0.5;
  // Drag.
  p -= aVel * t * t * 0.055;

  vec4 mv = modelViewMatrix * vec4(p, 1.0);
  gl_Position = projectionMatrix * mv;
  gl_PointSize = (1.4 + (1.0 - vT) * 4.5) * (300.0 / max(-mv.z, 1.0)) * uActive;
}`;

const sparkFrag = /* glsl */`
precision highp float;
varying float vT;
varying float vSeed;
uniform float uActive;
uniform float uTime;
uniform float uEmberMood;
${NOISE_GLSL}
void main(){
  vec2 uv = gl_PointCoord - 0.5;
  float r = length(uv);
  float core = 1.0 - smoothstep(0.0, 0.22, r);
  float halo = 1.0 - smoothstep(0.1, 0.5, r);
  float flick = 0.5 + 0.5 * sin(uTime * (30.0 + vSeed * 40.0) + vSeed * 90.0);
  float fade = (1.0 - vT) * (1.0 - vT);
  float a = (core + halo * 0.5) * fade * flick * uActive;
  if (a < 0.01) discard;
  vec3 col = fireRamp(0.55 + core * 0.45 - vT * 0.35) * (1.3 + core * 1.9) * uEmberMood;
  gl_FragColor = vec4(col, a);
}`;

/* ── system ───────────────────────────────────────────────────────────── */

export class FireBreath {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'FireBreath';
    this.group.visible = false;

    this.active = 0;
    this.age = 0;
    this.duration = 0;
    this.origin = new THREE.Vector3();
    this.dir = new THREE.Vector3(0, 0, -1);
    this.length = 150;

    this.jet = this._buildJet(settings);
    this.sparks = this._buildSparks(settings);
    this.smoke = this._buildSmoke(materials, settings);
    this.impact = this._buildImpact(materials);

    this.group.add(this.jet, this.sparks, this.smoke, this.impact.group);

    // Lights: one at the mouth, one riding the middle of the jet, one at impact.
    this.mouthLight = new THREE.PointLight(0xffb257, 0, 220, 2);
    this.jetLight = new THREE.PointLight(0xff7a28, 0, 340, 2);
    this.impactLight = new THREE.PointLight(0xff5a18, 0, 300, 2);
    this.group.add(this.mouthLight, this.jetLight, this.impactLight);
  }

  _buildJet(settings) {
    const count = settings.fireParticles;
    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(count * 3);
    const seed = new Float32Array(count * 3);
    const off = new Float32Array(count);
    const size = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      seed[i * 3] = Math.random();
      seed[i * 3 + 1] = Math.random();
      seed[i * 3 + 2] = Math.random();
      off[i] = i / count + Math.random() * (0.6 / count);
      size[i] = 16 + Math.random() * 26;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 3));
    geo.setAttribute('aOffset', new THREE.BufferAttribute(off, 1));
    geo.setAttribute('aSize', new THREE.BufferAttribute(size, 1));
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e6);

    const mat = new THREE.ShaderMaterial({
      vertexShader: jetVert, fragmentShader: jetFrag,
      uniforms: {
        uTime: G.uTime, uEmberMood: G.uEmberMood,
        uOrigin: { value: new THREE.Vector3() },
        uDir: { value: new THREE.Vector3(0, 0, -1) },
        uLength: { value: 150 },
        uSpread: { value: 16 },
        uSpeed: { value: 120 },
        uActive: { value: 0 },
        uAge: { value: 0 },
      },
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    });
    const p = new THREE.Points(geo, mat);
    p.frustumCulled = false;
    return p;
  }

  _buildSparks(settings) {
    const count = settings.sparkCount;
    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(count * 3);
    const vel = new Float32Array(count * 3);
    const seed = new Float32Array(count * 3);
    const birth = new Float32Array(count);
    const life = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      seed[i * 3] = Math.random();
      seed[i * 3 + 1] = Math.random();
      seed[i * 3 + 2] = Math.random();
      birth[i] = Math.random();
      life[i] = 1.1 + Math.random() * 2.2;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aVel', new THREE.BufferAttribute(vel, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 3));
    geo.setAttribute('aBirth', new THREE.BufferAttribute(birth, 1));
    geo.setAttribute('aLife', new THREE.BufferAttribute(life, 1));
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e6);

    const mat = new THREE.ShaderMaterial({
      vertexShader: sparkVert, fragmentShader: sparkFrag,
      uniforms: {
        uTime: G.uTime, uEmberMood: G.uEmberMood,
        uOrigin: { value: new THREE.Vector3() },
        uActive: { value: 0 },
        uEmitTime: { value: 0 },
      },
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
    });
    this._sparkVel = vel;
    this._sparkGeo = geo;
    const p = new THREE.Points(geo, mat);
    p.frustumCulled = false;
    return p;
  }

  _buildSmoke(materials, settings) {
    const count = Math.round(settings.smokeCount * 0.7);
    const geo = new THREE.BufferGeometry();
    const pos = new Float32Array(count * 3);
    const seed = new Float32Array(count * 3);
    const off = new Float32Array(count);
    const size = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      seed[i * 3] = Math.random();
      seed[i * 3 + 1] = Math.random();
      seed[i * 3 + 2] = Math.random();
      off[i] = Math.random();
      size[i] = 40 + Math.random() * 70;
    }
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 3));
    geo.setAttribute('aOffset', new THREE.BufferAttribute(off, 1));
    geo.setAttribute('aSize', new THREE.BufferAttribute(size, 1));
    geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(), 1e6);

    const mat = new THREE.ShaderMaterial({
      vertexShader: jetVert,
      fragmentShader: /* glsl */`
        precision highp float;
        varying float vLife;
        varying float vSeed;
        varying float vTurb;
        uniform sampler2D uSprite;
        uniform float uActive;
        void main(){
          vec4 s = texture2D(uSprite, gl_PointCoord);
          float a = s.a * smoothstep(0.15, 0.55, vLife) * (1.0 - smoothstep(0.6, 1.0, vLife)) * uActive * 0.55;
          if (a < 0.005) discard;
          vec3 col = mix(vec3(0.16, 0.13, 0.13), vec3(0.42, 0.20, 0.12), 1.0 - vLife);
          gl_FragColor = vec4(col * (0.6 + s.a * 0.7), a);
        }`,
      uniforms: {
        uTime: G.uTime, uEmberMood: G.uEmberMood,
        uOrigin: { value: new THREE.Vector3() },
        uDir: { value: new THREE.Vector3(0, 0, -1) },
        uLength: { value: 190 },
        uSpread: { value: 30 },
        uSpeed: { value: 55 },
        uActive: { value: 0 },
        uAge: { value: 0 },
        uSprite: { value: materials.T.smoke },
      },
      transparent: true, depthWrite: false,
    });
    const p = new THREE.Points(geo, mat);
    p.frustumCulled = false;
    return p;
  }

  /** Where the jet meets the ground: a pool of flame and a lingering scorch. */
  _buildImpact(materials) {
    const group = new THREE.Group();
    const geo = new THREE.PlaneGeometry(1, 1, 24, 24);
    geo.rotateX(-Math.PI / 2);
    const mat = new THREE.ShaderMaterial({
      transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
      uniforms: {
        uTime: G.uTime, uEmberMood: G.uEmberMood,
        uActive: { value: 0 },
      },
      vertexShader: /* glsl */`
        varying vec2 vUvI;
        void main(){
          vUvI = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }`,
      fragmentShader: /* glsl */`
        precision highp float;
        varying vec2 vUvI;
        uniform float uTime, uActive, uEmberMood;
        ${NOISE_GLSL}
        void main(){
          vec2 c = vUvI * 2.0 - 1.0;
          float r = length(c);
          float n = fbm(vec3(c * 3.0, uTime * 1.6), 4) * 0.5 + 0.5;
          float body = (1.0 - smoothstep(0.25, 1.0, r + n * 0.35 - 0.18));
          if (body < 0.01) discard;
          vec3 col = fireRamp(0.35 + body * 0.75) * (0.8 + body * 2.2) * uEmberMood;
          gl_FragColor = vec4(col, body * uActive * 0.85);
        }`,
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.frustumCulled = false;
    mesh.visible = false;
    group.add(mesh);
    return { group, mesh, mat };
  }

  /** Begin a breath. */
  ignite({ origin, dir, duration = 3.4, length = 165 }) {
    this.group.visible = true;
    this.age = 0;
    this.duration = duration;
    this.length = length;
    this.origin.copy(origin);
    this.dir.copy(dir).normalize();

    // Re-seed spark velocities in a cone around the breath direction.
    const up = Math.abs(this.dir.y) > 0.95 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
    const right = new THREE.Vector3().crossVectors(up, this.dir).normalize();
    const realUp = new THREE.Vector3().crossVectors(this.dir, right).normalize();
    const v = this._sparkVel;
    const tmp = new THREE.Vector3();
    for (let i = 0; i < v.length / 3; i++) {
      const speed = 45 + Math.random() * 105;
      const a = Math.random() * TAU;
      const spread = Math.pow(Math.random(), 1.7) * 0.42;
      tmp.copy(this.dir)
        .addScaledVector(right, Math.cos(a) * spread)
        .addScaledVector(realUp, Math.sin(a) * spread)
        .normalize().multiplyScalar(speed);
      v[i * 3] = tmp.x; v[i * 3 + 1] = tmp.y; v[i * 3 + 2] = tmp.z;
    }
    this._sparkGeo.attributes.aVel.needsUpdate = true;
    this.sparks.material.uniforms.uEmitTime.value = G.uTime.value;

    bus.emit(EV.DRAGON_FIRE, { origin: origin.clone(), dir: dir.clone(), duration });
    bus.emit(EV.SHAKE, { amplitude: 0.45, duration: 0.6, frequency: 26 });
  }

  update(dt, camera) {
    if (!this.group.visible) return;
    this.age += dt;

    // Envelope: fast attack, sustain, soft release.
    const a = smoothstep(0, 0.22, this.age);
    const r = 1 - smoothstep(this.duration, this.duration + 0.7, this.age);
    this.active = a * r;

    if (this.active <= 0.001 && this.age > this.duration + 0.8) {
      this.group.visible = false;
      G.uFireIntensity.value = 0;
      this.impact.mesh.visible = false;
      return;
    }

    // Feed the jet, smoke and sparks.
    for (const p of [this.jet, this.smoke]) {
      const u = p.material.uniforms;
      u.uOrigin.value.copy(this.origin);
      u.uDir.value.copy(this.dir);
      u.uActive.value = this.active;
      u.uAge.value = this.age;
    }
    this.jet.material.uniforms.uLength.value = this.length;
    this.smoke.material.uniforms.uLength.value = this.length * 1.25;
    this.sparks.material.uniforms.uOrigin.value.copy(this.origin);
    this.sparks.material.uniforms.uActive.value = this.active;

    // ── impact ───────────────────────────────────────────────────────
    // March the jet axis until it crosses the terrain; that's where fire pools.
    const hit = this._raycastGround();
    if (hit) {
      this.impact.mesh.visible = true;
      this.impact.mesh.position.copy(hit).add(new THREE.Vector3(0, 1.2, 0));
      const spread = 60 + this.active * 40;
      this.impact.mesh.scale.setScalar(spread);
      this.impact.mat.uniforms.uActive.value = this.active;
      // Hung higher and dimmer than before: at 14 m an inverse-square light of
      // 900 put ~4.6 on the ground beneath it, which tonemaps to flat white.
      this.impactLight.position.copy(hit).add(new THREE.Vector3(0, 26, 0));
      this.impactLight.intensity = 700 * this.active;

      // Leave the ground burning. Wildfire merges hits that land on a live
      // site, so this lays a trail along the strafe rather than a pile.
      this._igniteT = (this._igniteT ?? 0) - dt;
      if (this.active > 0.5 && this._igniteT <= 0) {
        this._igniteT = 0.18;
        const jitter = new THREE.Vector3((Math.random() - 0.5) * 30, 0, (Math.random() - 0.5) * 30);
        bus.emit(EV.IGNITE, { pos: hit.clone().add(jitter), radius: 24, strength: 1 });
      }
    } else {
      this.impact.mesh.visible = false;
      this.impactLight.intensity = 0;
    }

    // ── lights ───────────────────────────────────────────────────────
    const flick = 0.82 + 0.18 * Math.sin(G.uTime.value * 31);
    this.mouthLight.position.copy(this.origin);
    this.mouthLight.intensity = 420 * this.active * flick;

    const mid = this.origin.clone().addScaledVector(this.dir, this.length * 0.45);
    this.jetLight.position.copy(mid);
    this.jetLight.intensity = 950 * this.active * flick;

    // The global fire light every material samples.
    G.uFirePos.value.copy(hit ? hit.clone().add(new THREE.Vector3(0, 10, 0)) : mid);
    G.uFireIntensity.value = this.active * 1.15;
  }

  _raycastGround() {
    const step = this.length / 14;
    const p = new THREE.Vector3();
    for (let i = 1; i <= 14; i++) {
      p.copy(this.origin).addScaledVector(this.dir, step * i);
      const h = height(p.x, p.z);
      if (p.y <= h + 2) return p.setY(h);
    }
    return null;
  }

  dispose() {
    this.group.traverse((o) => { o.geometry?.dispose(); o.material?.dispose(); });
  }
}
