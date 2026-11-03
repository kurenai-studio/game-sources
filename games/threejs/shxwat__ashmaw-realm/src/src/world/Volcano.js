/**
 * Ashmaw itself — the vent, its permanent smoke column, and the eruption.
 *
 * The idle plume is a stack of ~200 soft billboards that rise, expand, cool
 * from ember-orange to grey and curl downwind. Because they share the global
 * wind uniforms' direction, the column leans the same way the trees do.
 *
 * Erupting reuses the same particle pool with different launch parameters and
 * adds: a ballistic bomb-and-boulder fountain (instanced rock with real spin),
 * an expanding shock ring, a lava fountain, and a pyroclastic surge that races
 * down the flank. The camera shake, flash, light punch and ash-load ramp are
 * broadcast on the bus so every other system can react.
 */
import * as THREE from 'three';
import { NOISE_GLSL } from '../shaders/lib/noise.glsl.js';
import { G } from '../materials/GlobalUniforms.js';
import { bus, EV } from '../core/EventBus.js';
import { WORLD, height } from './Heightfield.js';
import { TAU, clamp, smoothstep } from '../utils/MathX.js';

/* ── shared billboard smoke/ember shader ───────────────────────────────── */

const smokeVert = /* glsl */`
attribute vec3  aSeed;      // random per particle
attribute float aBirth;
attribute float aLife;
attribute float aSize;
attribute float aHeat;      // 0 = cold ash, 1 = incandescent

varying float vT;
varying float vHeat;
varying float vSeed;
varying float vFade;

uniform float uTime;
uniform vec3  uOrigin;
uniform vec2  uWindDir;
uniform float uWindStrength;
uniform float uRise;
uniform float uSpread;
uniform float uSurge;
uniform float uDrift;   // extra downwind travel with age — makes an anvil

${NOISE_GLSL}

void main(){
  float age = mod(uTime - aBirth, aLife) / aLife;
  vT = age;
  vHeat = aHeat;
  vSeed = aSeed.x;

  // Ballistic rise, decelerating as the parcel cools and entrains air.
  float rise = uRise * (0.5 + aSeed.y) * (age - age * age * 0.34) * 2.0;
  rise *= 1.0 + uSurge * 2.4;

  vec3 pos = uOrigin;
  pos.y += rise;

  // Turbulent spread grows with height (a real plume is a cone).
  float spread = uSpread * (0.25 + age * 1.5) * (0.4 + aSeed.z);
  vec3 curl = curlNoise(vec3(aSeed.xy * 4.0, uTime * 0.06 + age * 1.2));
  pos.xz += curl.xz * spread;
  pos.y  += curl.y * spread * 0.35;

  // Downwind shear — stronger the higher you go.
  pos.xz += uWindDir * rise * 0.35 * uWindStrength * (0.6 + aSeed.x * 0.8);

  // Directed drift. The curl term above spreads a parcel *radially*, which is
  // right for a rising column but wrong for the high ash veil: given a large
  // spread it inflates into a sphere of smoke centred on the mountain rather
  // than shearing off into an anvil, and at the veil's old settings that put
  // 200-pixel puffs up to a kilometre out in every direction — smoke across
  // the whole sky, including out over open ocean nowhere near the vent.
  // Travel along the wind instead, so distance from the vent reads as age.
  pos.xz += uWindDir * uDrift * age * (0.55 + aSeed.z * 0.9);

  float grow = aSize * (0.35 + age * 2.1) * (1.0 + uSurge * 0.8);
  vFade = sin(age * 3.14159) * smoothstep(0.0, 0.06, age);

  vec4 mv = modelViewMatrix * vec4(pos, 1.0);
  gl_Position = projectionMatrix * mv;
  gl_PointSize = grow * (215.0 / max(-mv.z, 1.0));
}`;

const smokeFrag = /* glsl */`
precision highp float;
varying float vT;
varying float vHeat;
varying float vSeed;
varying float vFade;

uniform sampler2D uSprite;
uniform vec3  uCool;
uniform vec3  uWarm;
uniform float uOpacity;
uniform float uEmberMood;
uniform vec3  uSunDir;
uniform vec3  uSunColor;
uniform vec3  uSkyColor;
uniform float uTime;

${NOISE_GLSL}

void main(){
  vec2 uv = gl_PointCoord;
  vec2 c = uv * 2.0 - 1.0;
  float r2 = dot(c, c);
  if (r2 > 1.0) discard;

  vec4 s = texture2D(uSprite, uv);

  // ── cauliflower silhouette ───────────────────────────────────────────
  // A convecting ash column is lumpy at every scale.
  //
  // The previous mask was "1 - smoothstep(0.30 + lump*0.34, 1.0, r)", which
  // only moved the *inner* edge of the falloff: the outer edge stayed pinned
  // at r = 1.0 for every ray, so no matter what the noise did, each particle
  // still faded out along a perfect circle over a very wide (0.4–0.7) ramp.
  // That is the definition of a soft disc, and it is why the plume read as a
  // stack of grey bubbles rather than as smoke.
  //
  // Displacing the *edge position itself* per direction is what makes the
  // silhouette ragged, and a much tighter ramp keeps it from dissolving back
  // into a gradient. Same cost, completely different read.
  float r = sqrt(r2);
  float lump = fbm(vec3(c * 2.2, uTime * 0.18 + vSeed * 40.0), 4);
  float edge = 0.70 + lump * 0.34;
  float mask = 1.0 - smoothstep(edge - 0.40, edge, r);
  float a = s.a * mask * 2.1 * vFade * uOpacity;
  if (a < 0.004) discard;

  // ── fake volume ──────────────────────────────────────────────────────
  // Treat the billboard as a sphere and light it. This is the cheapest
  // convincing volumetric trick there is: a lit crown and a dark belly turn
  // flat sprites into something with mass.
  vec3 n = normalize(vec3(c, sqrt(max(1.0 - r2, 0.0))));
  vec3 Lv = normalize((viewMatrix * vec4(normalize(uSunDir), 0.0)).xyz);
  float ndl = dot(n, Lv) * 0.5 + 0.5;

  float heat = vHeat * (1.0 - smoothstep(0.0, 0.42, vT));

  vec3 shadowed = uCool * 0.34 + uSkyColor * 0.28;
  vec3 lit      = uCool * 1.25 + uSunColor * 0.55;
  vec3 col = mix(shadowed, lit, pow(ndl, 1.5));

  // Sky bounce on the top of every puff, ember uplight underneath.
  col += uSkyColor * 0.35 * clamp(n.y, 0.0, 1.0);
  col += uWarm * uEmberMood * 0.30 * clamp(-n.y, 0.0, 1.0) * (0.35 + heat);

  // Incandescence while the parcel is still hot.
  col = mix(col, fireRamp(0.38 + heat * 0.55), heat * 0.72);
  col *= 1.0 + heat * uEmberMood * 0.9;

  // Thickness: the interior of a puff is denser and therefore darker.
  col *= 0.72 + 0.5 * s.a;

  gl_FragColor = vec4(col, a);
}`;

function makePlume({ count, sprite, origin, rise, spread, size, heat, cool, warm, opacity, blending, drift = 0 }) {
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(count * 3);      // unused (position comes from uniform) but required
  const seed = new Float32Array(count * 3);
  const birth = new Float32Array(count);
  const life = new Float32Array(count);
  const sz = new Float32Array(count);
  const ht = new Float32Array(count);

  for (let i = 0; i < count; i++) {
    seed[i * 3] = Math.random();
    seed[i * 3 + 1] = Math.random();
    seed[i * 3 + 2] = Math.random();
    life[i] = 9 + Math.random() * 16;
    birth[i] = Math.random() * life[i];
    sz[i] = size * (0.5 + Math.random() * 1.1);
    ht[i] = heat * (0.4 + Math.random() * 0.8);
  }

  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 3));
  geo.setAttribute('aBirth', new THREE.BufferAttribute(birth, 1));
  geo.setAttribute('aLife', new THREE.BufferAttribute(life, 1));
  geo.setAttribute('aSize', new THREE.BufferAttribute(sz, 1));
  geo.setAttribute('aHeat', new THREE.BufferAttribute(ht, 1));
  geo.boundingSphere = new THREE.Sphere(new THREE.Vector3(origin.x, origin.y + 300, origin.z), 1400);

  const mat = new THREE.ShaderMaterial({
    vertexShader: smokeVert,
    fragmentShader: smokeFrag,
    uniforms: {
      uTime: G.uTime,
      uWindDir: G.uWindDir,
      uWindStrength: G.uWindStrength,
      uEmberMood: G.uEmberMood,
      uSunDir: G.uSunDir,
      uSunColor: G.uSunColor,
      uSkyColor: G.uSkyColor,
      uOrigin: { value: origin.clone() },
      uRise: { value: rise },
      uSpread: { value: spread },
      uDrift: { value: drift },
      uSurge: { value: 0 },
      uSprite: { value: sprite },
      uCool: { value: new THREE.Color(cool) },
      uWarm: { value: new THREE.Color(warm) },
      uOpacity: { value: opacity },
    },
    transparent: true,
    depthWrite: false,
    blending: blending ?? THREE.NormalBlending,
  });

  const pts = new THREE.Points(geo, mat);
  pts.frustumCulled = false;
  return pts;
}

/* ── the volcano ──────────────────────────────────────────────────────── */

export class Volcano {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Volcano';
    this.settings = settings;
    this.surge = 0;
    this.erupting = false;
    this._t = 0;

    const V = WORLD.volcano;
    // Sit the vent *inside* the crater so the column grows out of the bowl
    // instead of hovering above the rim.
    this.vent = new THREE.Vector3(V.x, V.height - V.craterDepth * 0.62, V.z);

    // ── permanent column ────────────────────────────────────────────
    this.plume = makePlume({
      count: Math.round(settings.smokeCount * 2.4),
      sprite: materials.T.smoke,
      origin: this.vent,
      rise: 340, spread: 62, size: 118, heat: 0.5, drift: 120,
      cool: 0x5a5257, warm: 0xff7a2e,
      opacity: 0.52,
    });
    this.plume.name = 'AshmawPlume';
    this.group.add(this.plume);

    // Lower, denser skirt of smoke sitting in the crater.
    this.skirt = makePlume({
      count: Math.round(settings.smokeCount * 0.9),
      sprite: materials.T.smoke,
      origin: this.vent.clone().setY(this.vent.y - 6),
      rise: 74, spread: 88, size: 120, heat: 1.0,
      cool: 0x453538, warm: 0xff5a14,
      opacity: 0.62,
    });
    this.group.add(this.skirt);

    // Downwind ash veil: the column shears off into a long anvil. Without it
    // the plume looks like a chimney instead of an eruption cloud.
    this.veil = makePlume({
      count: Math.round(settings.smokeCount * 1.4),
      sprite: materials.T.smoke,
      origin: this.vent.clone().setY(this.vent.y + 120),
      // Radial spread stays modest; the length of the anvil comes from `drift`,
      // which carries parcels downwind as they age instead of inflating a ball
      // of smoke around the mountain.
      rise: 120, spread: 95, size: 190, heat: 0.06, drift: 620,
      cool: 0x6a6266, warm: 0xa06038,
      opacity: 0.30,
    });
    this.group.add(this.veil);

    // Secondary cone.
    const V2 = WORLD.volcano2;
    this.plume2 = makePlume({
      count: Math.round(settings.smokeCount * 0.5),
      sprite: materials.T.smoke,
      origin: new THREE.Vector3(V2.x, V2.height - 12, V2.z),
      rise: 130, spread: 60, size: 90, heat: 0.3,
      cool: 0x4d474b, warm: 0xd06a30,
      opacity: 0.32,
    });
    this.group.add(this.plume2);

    // ── eruption-only systems ───────────────────────────────────────
    this.fountain = makePlume({
      count: Math.round(settings.fireParticles * 1.4),
      sprite: materials.T.flame,
      origin: this.vent,
      rise: 420, spread: 42, size: 44, heat: 1.0,
      cool: 0x361008, warm: 0xffb257,
      opacity: 0.0,
      blending: THREE.AdditiveBlending,
    });
    this.group.add(this.fountain);

    // The vent glows and lights the base of its own column.
    this.ventLight = new THREE.PointLight(0xff5a14, 3200, 850, 1.6);
    this.ventLight.position.copy(this.vent).add(new THREE.Vector3(0, 15, 0));
    this.group.add(this.ventLight);

    this._buildCraterPool(materials);
    this._buildBombs(materials, settings);
    this._buildShockRing();
    this._buildPyroclast(materials, settings);
  }

  /** Churning molten magma lake sitting inside the abyssal vent throat. */
  _buildCraterPool(materials) {
    const V = WORLD.volcano;
    const poolR = V.craterR * 0.58;
    const geo = new THREE.CircleGeometry(poolR, 48);
    geo.rotateX(-Math.PI / 2);

    const mat = new THREE.ShaderMaterial({
      uniforms: {
        uTime: G.uTime,
        uSurge: { value: 0 },
        uEmberMood: G.uEmberMood,
      },
      vertexShader: /* glsl */`
        varying vec2 vUvPool;
        varying vec3 vWPosPool;
        ${NOISE_GLSL}
        uniform float uTime;
        uniform float uSurge;
        void main() {
          vUvPool = uv;
          vec3 p = position;
          // Subterranean churning heave
          p.y += (sin(uTime * 1.8 + p.x * 0.12) * 1.8 + fbm(vec3(p.xz * 0.08, uTime * 0.35), 4) * 2.8) * (1.0 + uSurge * 2.0);
          vec4 mv = modelViewMatrix * vec4(p, 1.0);
          vWPosPool = (modelMatrix * vec4(p, 1.0)).xyz;
          gl_Position = projectionMatrix * mv;
        }
      `,
      fragmentShader: /* glsl */`
        precision highp float;
        varying vec2 vUvPool;
        varying vec3 vWPosPool;
        uniform float uTime;
        uniform float uSurge;
        uniform float uEmberMood;
        ${NOISE_GLSL}
        void main() {
          vec2 c = vUvPool * 2.0 - 1.0;
          float r2 = dot(c, c);
          if (r2 > 1.0) discard;

          vec2 cell = voronoi(vUvPool * 12.0 + vec2(uTime * 0.04, -uTime * 0.02));
          float crack = 1.0 - smoothstep(0.0, 0.14, cell.y - cell.x);

          float churn = fbm(vec3(vUvPool * 8.0, uTime * 0.4), 5) * 0.5 + 0.5;
          float heat = crack * 0.95 + churn * 0.45 + uSurge * 0.5;
          heat = clamp(heat, 0.0, 1.8);

          vec3 col = lavaRamp(heat) * (1.5 + uSurge * 2.0);
          // Dark cooling crust in center of Voronoi plates
          float crust = (1.0 - crack) * (1.0 - churn * 0.6);
          col *= 1.0 - crust * 0.65;

          gl_FragColor = vec4(col, 1.0);
        }
      `,
      side: THREE.DoubleSide,
    });

    this.craterPool = new THREE.Mesh(geo, mat);
    this.craterPool.position.copy(this.vent).setY(V.height - V.craterDepth * 0.78);
    this.craterPool.name = 'CraterMagmaPool';
    this.group.add(this.craterPool);
  }

  /** Ballistic ejecta: instanced boulders with per-body spin and impact dust. */
  _buildBombs(materials, settings) {
    const n = Math.round(clamp(settings.rockCount * 0.09, 24, 90));
    const geo = new THREE.IcosahedronGeometry(1, 0);
    // Rough them up so they don't read as dice.
    const p = geo.attributes.position;
    for (let i = 0; i < p.count; i++) {
      const s = 0.7 + Math.random() * 0.6;
      p.setXYZ(i, p.getX(i) * s, p.getY(i) * s, p.getZ(i) * s);
    }
    geo.computeVertexNormals();

    const mat = materials.get('basalt').clone();
    mat.emissive = new THREE.Color(0xff4a12);
    mat.emissiveIntensity = 1.4;
    mat.onBeforeCompile = materials.get('basalt').onBeforeCompile;
    mat.customProgramCacheKey = materials.get('basalt').customProgramCacheKey;

    this.bombs = new THREE.InstancedMesh(geo, mat, n);
    this.bombs.castShadow = true;
    this.bombs.frustumCulled = false;
    this.bombs.visible = false;
    this.bombs.name = 'VolcanicBombs';
    this.bombData = [];
    for (let i = 0; i < n; i++) {
      this.bombData.push({
        p: new THREE.Vector3(), v: new THREE.Vector3(),
        spin: new THREE.Vector3(), q: new THREE.Quaternion(),
        s: 2 + Math.random() * 9, alive: false, delay: 0,
      });
    }
    this.group.add(this.bombs);
  }

  _buildShockRing() {
    const geo = new THREE.RingGeometry(1, 1.08, 128, 1);
    geo.rotateX(-Math.PI / 2);
    const mat = new THREE.ShaderMaterial({
      transparent: true, depthWrite: false, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      uniforms: { uOpacity: { value: 0 }, uTime: G.uTime },
      vertexShader: /* glsl */`
        varying vec2 vUvR;
        void main(){ vUvR = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }`,
      fragmentShader: /* glsl */`
        varying vec2 vUvR;
        uniform float uOpacity;
        void main(){
          float e = smoothstep(0.0, 0.35, vUvR.y) * smoothstep(1.0, 0.6, vUvR.y);
          gl_FragColor = vec4(vec3(1.0, 0.72, 0.45) * e * 2.2, e * uOpacity);
        }`,
    });
    this.shock = new THREE.Mesh(geo, mat);
    this.shock.visible = false;
    this.shock.frustumCulled = false;
    this.group.add(this.shock);
  }

  /** Pyroclastic surge — a wall of ash sliding down the flank. */
  _buildPyroclast(materials, settings) {
    this.surgeCloud = makePlume({
      count: Math.round(settings.smokeCount * 0.9),
      sprite: materials.T.smoke,
      origin: this.vent.clone(),
      rise: 40, spread: 260, size: 190, heat: 0.35,
      cool: 0x504749, warm: 0xc06030,
      opacity: 0.0,
    });
    this.surgeCloud.name = 'PyroclasticSurge';
    this.group.add(this.surgeCloud);
  }

  /** Kick off the full sequence. Returns its total duration in seconds. */
  erupt() {
    if (this.erupting) return 0;
    this.erupting = true;
    this._t = 0;
    this.bombs.visible = true;
    this.shock.visible = true;

    const V = WORLD.volcano;
    for (const b of this.bombData) {
      b.alive = false;
      b.delay = Math.random() * 2.6;
    }

    bus.emit(EV.ERUPTION, { stage: 'blast', pos: this.vent.clone() });
    bus.emit(EV.SHAKE, { amplitude: 2.4, duration: 7.5, frequency: 22 });
    bus.emit(EV.FLASH, { intensity: 0.55, duration: 0.6, color: '#ffd9a8' });
    return 26;
  }

  _launchBomb(b) {
    const V = WORLD.volcano;
    const a = Math.random() * TAU;
    const r = Math.random() * V.craterR * 0.6;
    b.p.set(this.vent.x + Math.cos(a) * r, this.vent.y + 8, this.vent.z + Math.sin(a) * r);
    const speed = 62 + Math.random() * 78;
    const elev = 1.05 + Math.random() * 0.42;         // radians from horizontal
    const dir = Math.random() * TAU;
    b.v.set(
      Math.cos(dir) * Math.cos(elev) * speed,
      Math.sin(elev) * speed,
      Math.sin(dir) * Math.cos(elev) * speed,
    );
    b.spin.set((Math.random() - 0.5) * 6, (Math.random() - 0.5) * 6, (Math.random() - 0.5) * 6);
    b.q.identity();
    b.alive = true;
  }

  update(dt, camera) {
    const t = this._t;

    // Idle plume pressure breathes even when calm.
    const idle = 0.06 + 0.06 * Math.sin(G.uTime.value * 0.13);

    if (this.erupting) {
      this._t += dt;

      // Envelope: blast → sustained column → decay.
      const s = t < 1.2 ? smoothstep(0, 1.2, t)
              : t < 12 ? 1.0
              : smoothstep(26, 12, t);
      this.surge = s;

      this.fountain.material.uniforms.uOpacity.value = 0.30 * s;
      this.surgeCloud.material.uniforms.uOpacity.value = 0.52 * smoothstep(0.6, 3.5, t) * smoothstep(22, 8, t);

      // Shock ring expands at ~330 m/s then fades.
      const R = t * 330;
      if (R < 1500) {
        this.shock.position.set(this.vent.x, this.vent.y * 0.55, this.vent.z);
        this.shock.scale.setScalar(R);
        this.shock.material.uniforms.uOpacity.value = smoothstep(1500, 200, R) * 0.7;
        G.uShockwave.value.set(this.vent.x, this.vent.y, this.vent.z, R);
      } else {
        this.shock.visible = false;
        G.uShockwave.value.w = -1;
      }

      // Bombs.
      for (const b of this.bombData) {
        if (!b.alive) {
          if (t > b.delay && t < 11) this._launchBomb(b);
          continue;
        }
        b.v.y -= 42 * dt;                      // heavy, so arcs stay readable
        b.v.multiplyScalar(1 - 0.12 * dt);     // drag
        b.p.addScaledVector(b.v, dt);
        b.q.multiply(new THREE.Quaternion().setFromEuler(
          new THREE.Euler(b.spin.x * dt, b.spin.y * dt, b.spin.z * dt),
        ));
        const ground = height(b.p.x, b.p.z);
        if (b.p.y < ground + b.s * 0.5) {
          b.alive = false;
          // Incandescent rock sets what it lands on alight. Not every bomb, or
          // the flanks would eat the whole wildfire budget in one eruption.
          bus.emit(EV.IGNITE, {
            pos: b.p.clone(), radius: 10 + b.s * 1.5,
            strength: 0.45, impact: true, ignite: Math.random() < 0.3,
          });
          if (Math.hypot(b.p.x - camera.position.x, b.p.z - camera.position.z) < 400) {
            bus.emit(EV.SHAKE, { amplitude: 0.35, duration: 0.5, frequency: 30 });
          }
        }
      }
      this._writeBombs();

      if (t > 26) {
        this.erupting = false;
        this.surge = 0;
        this.bombs.visible = false;
        this.shock.visible = false;
        G.uShockwave.value.w = -1;
        this.fountain.material.uniforms.uOpacity.value = 0;
        this.surgeCloud.material.uniforms.uOpacity.value = 0;
        bus.emit(EV.ERUPTION, { stage: 'end' });
      }
    }

    // Vent breathing, and a hard flare while erupting.
    this.ventLight.intensity = 2400 * (0.75 + 0.25 * Math.sin(G.uTime.value * 0.7))
                             * (1.0 + this.surge * 6.0);

    const sg = Math.max(this.surge, idle * 0.5);
    for (const p of [this.plume, this.skirt, this.veil, this.plume2, this.fountain, this.surgeCloud, this.craterPool]) {
      p.material.uniforms.uSurge.value = sg;
    }

    /**
     * Scale the idle column with how much ash the air is actually carrying.
     *
     * A dormant-but-smoking cone on a clear windless afternoon vents a thin
     * wisp; the dense grey column belongs to an eruption. The plume used to
     * render at full opacity in every preset, so "Clear Day" put a bank of
     * white cotton wool over the summit that hid the mountain underneath it.
     *
     * The signal here is uAshLoad, not uEmberMood. uEmberMood was the obvious
     * first choice and is wrong: it measures how strongly the *ember light*
     * bleeds into the scene, so the Moonlight preset sets it to 1.8 purely to
     * make the lava glow read against a dark sky — which drove the plume to
     * maximum density on a calm night. uAshLoad means what it says (0.25 in
     * clear presets, 0.85 ashstorm, 1.0 eruption) and is what the column
     * should follow.
     */
    const ash = G.uAshLoad.value;
    const anger = clamp((ash - 0.25) / 0.60, 0, 1) + this.surge * 0.9;
    const dens = clamp(0.26 + anger * 0.90, 0, 1.25);
    this.plume.material.uniforms.uOpacity.value = 0.52 * dens;
    this.skirt.material.uniforms.uOpacity.value = 0.62 * dens;
    this.veil.material.uniforms.uOpacity.value  = 0.30 * dens;
    this.plume2.material.uniforms.uOpacity.value = 0.32 * dens;
  }

  _writeBombs() {
    const m = new THREE.Matrix4();
    const s = new THREE.Vector3();
    for (let i = 0; i < this.bombData.length; i++) {
      const b = this.bombData[i];
      s.setScalar(b.alive ? b.s : 0.0001);
      m.compose(b.p, b.q, s);
      this.bombs.setMatrixAt(i, m);
    }
    this.bombs.instanceMatrix.needsUpdate = true;
  }

  dispose() {
    this.group.traverse((o) => { o.geometry?.dispose(); o.material?.dispose(); });
  }
}
