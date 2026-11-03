/**
 * Water: the meltwater river, the plunge pool, and the falls.
 *
 * Surfaces are real MeshStandardMaterials — so they receive shadows, the sun,
 * the torches and the dragon's fire like everything else — with three
 * injections layered in:
 *
 *  · dual scrolling normal samples in a *world-space* tangent frame (water is
 *    horizontal, so a fixed basis is exact and avoids relying on three's
 *    internal tbn naming)
 *  · flow-aligned foam that accumulates at banks and obstacles
 *  · a depth tint so shallow edges read sandy and the middle reads deep
 *
 * Reflections are image-based (the live PMREM of our own sky) plus Fresnel —
 * with an optional true planar mirror for the pool on the top quality tier.
 */
import * as THREE from 'three';
import { NOISE_GLSL, AX_GLOBALS } from '../shaders/lib/noise.glsl.js';
import { G } from '../materials/GlobalUniforms.js';
import { injectAmbient } from '../materials/MaterialLibrary.js';
import { buildRibbon, buildBasin } from './Ribbon.js';
import { RIVER_PATH, RIVER_WIDTH, WORLD } from './Heightfield.js';

function makeWaterMaterial(materials, {
  flow = 1.0, ripple = 0.55, foam = 1.0, color = 0x12222c, opacity = 0.9, scale = 1.0,
} = {}) {
  const nrm = materials.T.waterNormal.clone();
  nrm.wrapS = nrm.wrapT = THREE.RepeatWrapping;
  nrm.needsUpdate = true;

  const mat = new THREE.MeshStandardMaterial({
    color, roughness: 0.075, metalness: 0.02,
    normalMap: nrm,
    envMap: materials.env, envMapIntensity: 1.35,
    transparent: true, opacity,
    side: THREE.DoubleSide,
    depthWrite: true,
  });
  mat.name = 'water';

  const u = {
    uFlow:   { value: flow },
    uRipple: { value: ripple },
    uFoam:   { value: foam },
    uScale:  { value: scale },
  };
  mat.userData.water = u;

  mat.onBeforeCompile = (shader) => {
    Object.assign(shader.uniforms, { uTime: G.uTime, ...u });

    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', `#include <common>
        attribute float aAlong;
        attribute float aAcross;
        varying float vAlongW;
        varying float vAcrossW;
        varying vec2  vWaterUv;
        ${AX_GLOBALS}
        uniform float uFlow;
        ${NOISE_GLSL}
      `)
      .replace('#include <begin_vertex>', `#include <begin_vertex>
        vAlongW = aAlong;
        vAcrossW = aAcross;
        vWaterUv = uv;
        {
          float shear = 1.0 - clamp(aAcross, 0.0, 1.0);
          vec3 wp = (modelMatrix * vec4(transformed, 1.0)).xyz;
          // Gerstner-ish chop: two crossed waves plus fbm swell.
          float w = sin(wp.x * 0.16 + uTime * 1.7) * 0.16
                  + sin(wp.z * 0.21 - uTime * 2.1) * 0.13
                  + fbm(vec3(wp.xz * 0.06, uTime * 0.35), 3) * 0.34;
          transformed.y += w * shear;
        }
      `);

    shader.fragmentShader = shader.fragmentShader
      .replace('#include <common>', `#include <common>
        varying float vAlongW;
        varying float vAcrossW;
        varying vec2  vWaterUv;
        ${AX_GLOBALS}
        uniform float uFlow, uRipple, uFoam, uScale;
        ${NOISE_GLSL}
      `)
      // Foam + depth tint on the albedo.
      .replace('#include <color_fragment>', `#include <color_fragment>
        {
          float shear = 1.0 - clamp(vAcrossW, 0.0, 1.0);
          float t = uTime * uFlow;
          float streak = fbm(vec3(vWaterUv.x * 9.0 * uScale, vWaterUv.y * 3.0 * uScale - t * 0.5, t * 0.15), 4) * 0.5 + 0.5;
          float bankFoam = smoothstep(0.62, 1.0, vAcrossW) * (0.4 + streak * 1.1);
          float churn = smoothstep(0.55, 0.95, streak) * uFoam * 0.55 * (0.35 + shear);
          float foam = clamp((bankFoam * uFoam + churn), 0.0, 1.0);

          diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.06, 0.11, 0.13), shear * 0.6);
          diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.86, 0.90, 0.92), foam);
          diffuseColor.a *= mix(1.0, 0.82, shear) ;
          diffuseColor.a = mix(diffuseColor.a, 1.0, foam);
        }
      `)
      // World-space dual normal scroll — replaces three's tangent-frame path.
      .replace('#include <normal_fragment_maps>', `
        {
          float t = uTime * uFlow;
          vec2 uvA = vWaterUv * vec2(3.0, 1.6) * uScale + vec2( t * 0.03, -t * 0.10);
          vec2 uvB = vWaterUv * vec2(7.0, 3.4) * uScale + vec2(-t * 0.05, -t * 0.18);
          vec3 nA = texture2D(normalMap, uvA).xyz * 2.0 - 1.0;
          vec3 nB = texture2D(normalMap, uvB).xyz * 2.0 - 1.0;
          vec3 mapN = normalize(nA + nB * 0.65);
          vec3 T  = normalize((viewMatrix * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
          vec3 Bv = normalize((viewMatrix * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
          normal = normalize(normal + (mapN.x * T + mapN.y * Bv) * uRipple);
        }
      `);
  };
  mat.customProgramCacheKey = () => 'water_v1';

  return injectAmbient(mat, { ashAmount: 0.0, wetAmount: 0.0, microNormal: 0.0, grimeAmount: 0.0 });
}

export class Water {
  constructor(materials, settings) {
    this.group = new THREE.Group();
    this.group.name = 'Water';
    this.materials = [];

    // ── river ────────────────────────────────────────────────────────
    const riverMat = makeWaterMaterial(materials, { flow: 1.5, ripple: 0.7, foam: 0.9, scale: 1.0 });
    const river = new THREE.Mesh(
      buildRibbon(RIVER_PATH, {
        width: RIVER_WIDTH, widthJitter: 0.3, yOffset: -6.5,
        segmentsPerUnit: 1 / 6, uvScale: 0.02,
      }),
      riverMat,
    );
    river.name = 'River';
    river.receiveShadow = true;
    this.group.add(river);
    this.materials.push(riverMat);

    // ── plunge pool ──────────────────────────────────────────────────
    const P = WORLD.pool;
    const poolMat = makeWaterMaterial(materials, {
      flow: 0.55, ripple: 0.45, foam: 0.35, color: 0x0d1b24, opacity: 0.94, scale: 0.35,
    });
    const pool = new THREE.Mesh(
      buildBasin(P.x, P.z, P.radius, P.y, { segments: 128, rings: 8, wobble: 0.14 }),
      poolMat,
    );
    pool.name = 'Pool';
    pool.receiveShadow = true;
    this.group.add(pool);
    this.materials.push(poolMat);

    // ── the falls ────────────────────────────────────────────────────
    this.group.add(this._buildFalls(materials));

    // ── wet rocks behind the falls read as a dark, glossy face ───────
    this._buildSpray(materials, settings);
  }

  _buildFalls(materials) {
    const F = WORLD.falls;
    const g = new THREE.Group();
    g.name = 'Waterfall';

    // Two curtains at slightly different depths/speeds for parallax.
    for (let layer = 0; layer < 2; layer++) {
      const w = 30 - layer * 7;
      const topY = F.top - layer * 4;
      const botY = WORLD.pool.y + 1.5;
      const segs = 40;

      const pos = [], uv = [], across = [], along = [], idx = [];
      for (let i = 0; i <= segs; i++) {
        const t = i / segs;
        const y = topY + (botY - topY) * t;
        // Ballistic bulge: the sheet leaves the lip, then falls away and spreads.
        const bulge = Math.sin(t * Math.PI * 0.55) * 10 + t * t * 16;
        const width = w * (1 + t * 0.7);
        const x = F.x - bulge - layer * 3;
        const z = F.z + Math.sin(t * 2.2) * 3;
        for (let s = -1; s <= 1; s++) {
          pos.push(x, y, z + s * width * 0.5);
          uv.push((s + 1) * 0.5, t * 3.0);
          across.push(Math.abs(s));
          along.push(t);
        }
      }
      for (let i = 0; i < segs; i++) {
        const a = i * 3, b = (i + 1) * 3;
        idx.push(a, b, a + 1,  b, b + 1, a + 1);
        idx.push(a + 1, b + 1, a + 2,  b + 1, b + 2, a + 2);
      }
      const geo = new THREE.BufferGeometry();
      geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
      geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
      geo.setAttribute('aAcross', new THREE.Float32BufferAttribute(across, 1));
      geo.setAttribute('aAlong', new THREE.Float32BufferAttribute(along, 1));
      geo.setIndex(idx);
      geo.computeVertexNormals();

      const mat = makeWaterMaterial(materials, {
        flow: 9.0 + layer * 3, ripple: 0.9, foam: 2.1,
        color: 0x25333a, opacity: layer ? 0.55 : 0.9, scale: 1.6,
      });
      const m = new THREE.Mesh(geo, mat);
      m.name = `FallsCurtain${layer}`;
      g.add(m);
      this.materials.push(mat);
    }
    return g;
  }

  /** Mist plume at the base of the falls — soft additive billboards. */
  _buildSpray(materials, settings) {
    const F = WORLD.falls;
    const count = Math.round(settings.smokeCount * 0.35);
    const geo = new THREE.PlaneGeometry(1, 1);
    const inst = new THREE.InstancedMesh(
      geo,
      new THREE.MeshBasicMaterial({
        map: materials.T.smoke, transparent: true, depthWrite: false,
        blending: THREE.NormalBlending, opacity: 0.085, color: 0xb9c7ce, toneMapped: true,
      }),
      count,
    );
    inst.frustumCulled = false;
    inst.name = 'FallsMist';
    this._mist = inst;
    this._mistData = [];
    const m = new THREE.Matrix4();
    for (let i = 0; i < count; i++) {
      this._mistData.push({
        x: F.x - 12 - Math.random() * 46,
        y: WORLD.pool.y + Math.random() * 46,
        z: F.z + (Math.random() - 0.5) * 60,
        s: 16 + Math.random() * 34,
        vy: 2 + Math.random() * 5,
        life: Math.random(),
        rot: Math.random() * Math.PI,
      });
      inst.setMatrixAt(i, m);
    }
    this.group.add(inst);
  }

  update(dt, camera) {
    // Billboard + advect the mist.
    if (!this._mist) return;
    const m = new THREE.Matrix4();
    const q = camera.quaternion;
    const s = new THREE.Vector3();
    const p = new THREE.Vector3();
    for (let i = 0; i < this._mistData.length; i++) {
      const d = this._mistData[i];
      d.life += dt * 0.13;
      d.y += d.vy * dt;
      d.x -= dt * 3.2;
      if (d.life > 1) {
        d.life = 0;
        d.y = WORLD.pool.y + Math.random() * 6;
        d.x = WORLD.falls.x - 12 - Math.random() * 30;
        d.z = WORLD.falls.z + (Math.random() - 0.5) * 60;
      }
      const fade = Math.sin(d.life * Math.PI);
      const size = d.s * (0.5 + d.life * 1.3);
      p.set(d.x, d.y, d.z);
      s.setScalar(size * fade + 0.001);
      m.compose(p, q, s);
      this._mist.setMatrixAt(i, m);
    }
    this._mist.instanceMatrix.needsUpdate = true;
  }

  dispose() {
    this.group.traverse((o) => { o.geometry?.dispose(); o.material?.dispose(); });
  }
}
