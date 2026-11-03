/**
 * Molten rock.
 *
 * One shader serves the channel, the lake and the eruption's fresh flows. The
 * look comes from three stacked ideas:
 *
 *  1. Advected fbm — the crust pattern is sampled at a position that *moves
 *     downstream*, so plates translate instead of shimmering in place.
 *  2. Voronoi plate boundaries — the cooled black crust cracks apart along cell
 *     edges, and the gaps expose the bright magma underneath. Plate interiors
 *     cool (darken) with age, edges stay incandescent.
 *  3. Shear at the banks — flow speed falls to zero at the edge, which drags
 *     the crust into the long streaks real pahoehoe shows.
 *
 * Emission is written un-tonemapped and well above 1.0 so bloom does the rest.
 */
import * as THREE from 'three';
import { NOISE_GLSL, AX_GLOBALS } from '../shaders/lib/noise.glsl.js';
import { G } from '../materials/GlobalUniforms.js';
import { buildRibbon, buildBasin } from './Ribbon.js';
import { LAVA_PATH, LAVA_WIDTH, WORLD } from './Heightfield.js';

const vert = /* glsl */`
attribute float aAlong;
attribute float aAcross;
varying float vAlong;
varying float vAcross;
varying vec2  vUvL;
varying vec3  vWPos;
${AX_GLOBALS}
uniform float uSurge;

${NOISE_GLSL}

void main(){
  vAlong = aAlong;
  vAcross = aAcross;
  vUvL = uv;
  vec3 p = position;

  // Slow swell — the surface heaves as pressure passes through.
  float shear = 1.0 - vAcross;
  p.y += (sin(uTime * 0.55 + aAlong * 38.0) * 0.55
        + fbm(vec3(p.xz * 0.05, uTime * 0.09), 3) * 1.1) * shear * (0.6 + uSurge * 2.2);

  vWPos = (modelMatrix * vec4(p, 1.0)).xyz;
  gl_Position = projectionMatrix * viewMatrix * vec4(vWPos, 1.0);
}`;

const frag = /* glsl */`
precision highp float;
varying float vAlong;
varying float vAcross;
varying vec2  vUvL;
varying vec3  vWPos;

${AX_GLOBALS}
uniform float uFlow;       // m/s downstream
uniform float uSurge;      // eruption boost 0..1
uniform vec3  uCameraPos;
uniform float uCrustScale;
uniform float uHeatBias;

${NOISE_GLSL}

void main(){
  // Shear profile: fast liquid flow in the middle, slower along banks
  float centerDist = abs(vAcross * 2.0 - 1.0); // 0 at center, 1 at banks
  float shear = pow(1.0 - clamp(centerDist, 0.0, 1.0), 0.6);
  float flow = uTime * uFlow * (0.3 + shear * 0.8);

  vec2 uvA = vec2(vUvL.x * 2.2, vUvL.y * 1.2 - flow * 0.04);
  vec2 uvB = vec2(vUvL.x * 6.0, vUvL.y * 2.8 - flow * 0.06);

  // Voronoi crust plates
  vec2 cell = voronoi(uvA * uCrustScale * 2.8);
  float edge = 1.0 - smoothstep(0.0, 0.14, cell.y - cell.x);
  float plateAge = hash12(floor(uvA * uCrustScale * 2.8));

  // Fluid turbulence
  float turb = fbm(vec3(uvB * 3.2, uTime * 0.3), 5) * 0.5 + 0.5;
  float turb2 = fbm(vec3(uvB * 10.0, uTime * 0.7), 3) * 0.5 + 0.5;

  // Heat field — center stream stays molten hot
  // Heat field. These terms used to sum past 1.0 almost everywhere (a plate
  // interior on the centreline scored ~1.6 before surge), so the whole lake
  // saturated lavaRamp's white end and read as a flat glowing slab. Rebalanced
  // so plates sit in the dark-crust band and only seams + the stream run hot.
  float heat = edge * 0.57
             + (1.0 - plateAge * 0.7) * 0.16
             + turb * 0.24 + turb2 * 0.08
             + shear * 0.20
             + uHeatBias;

  // Fluid molten core in the middle of the river
  float coreStream = smoothstep(0.7, 0.0, centerDist);
  heat += coreStream * 0.18 * (0.6 + turb);

  heat = clamp(heat * (0.9 + uSurge * 1.0), 0.0, 1.8);

  // Cooled pahoehoe skin: darkens plate interiors to deep red-black, but preserves glowing fissures
  float skin = smoothstep(0.3, 0.85, plateAge) * (1.0 - edge) * (1.0 - coreStream * 0.6);
  float finalHeat = heat * (1.0 - skin * 0.7);

  vec3 col = lavaRamp(clamp(finalHeat, 0.0, 0.84 + uSurge * 0.16));

  // Incandescent scatter into the viewer at grazing angles
  vec3 V = normalize(uCameraPos - vWPos);
  float graze = pow(1.0 - abs(V.y), 2.2);
  col += vec3(1.0, 0.45, 0.12) * graze * finalHeat * finalHeat * 0.45;

  // Natural bank transition: warm incandescent border blending into terrain
  float bankEdge = smoothstep(0.8, 1.0, centerDist);
  col = mix(col, vec3(0.18, 0.04, 0.02), bankEdge * 0.65);
  // (This used to be weighted by (1 − bankEdge) — i.e. the *interior* — which
  // washed a flat orange over every crust plate. It belongs at the border.)
  col += vec3(1.0, 0.35, 0.08) * smoothstep(0.55, 0.9, centerDist) * (1.0 - bankEdge) * 0.25;

  float emissive = (0.45 + finalHeat * 1.25) * uEmberMood * (1.0 + uSurge * 1.2);
  vec3 outCol = col * emissive;

  // Exponential-squared fog
  float dist = length(uCameraPos - vWPos);
  float f = 1.0 - exp(-pow(dist * uFogDensity * 0.85, 2.0));
  outCol = mix(outCol, uFogColor * (0.6 + finalHeat * 1.8) + outCol * 0.30, clamp(f, 0.0, 0.90));

  gl_FragColor = vec4(max(outCol, 0.0), 1.0);
}`;

export function makeLavaMaterial({ flow = 1.0, crustScale = 1.0, heatBias = 0.0 } = {}) {
  const uniforms = {
    uTime:       G.uTime,
    uEmberMood:  G.uEmberMood,
    uFlow:       { value: flow },
    uSurge:      { value: 0 },
    uCameraPos:  { value: new THREE.Vector3() },
    uCrustScale: { value: crustScale },
    uHeatBias:   { value: heatBias },
    uFogColor:   G.uFogColor,
    uFogDensity: G.uFogDensity,
  };
  const m = new THREE.ShaderMaterial({
    vertexShader: vert, fragmentShader: frag, uniforms,
    side: THREE.DoubleSide,
    toneMapped: true,
  });
  m.name = 'lava';
  return m;
}

export class Lava {
  constructor() {
    this.group = new THREE.Group();
    this.group.name = 'Lava';
    this.materials = [];

    // ── main channel ────────────────────────────────────────────────
    const riverGeo = buildRibbon(LAVA_PATH, {
      width: LAVA_WIDTH, widthJitter: 0.34, yOffset: -3.2,
      segmentsPerUnit: 1 / 5, uvScale: 0.008,
    });
    const riverMat = makeLavaMaterial({ flow: 3.4, crustScale: 1.0, heatBias: 0.04 });
    const river = new THREE.Mesh(riverGeo, riverMat);
    river.name = 'LavaChannel';
    this.group.add(river);
    this.materials.push(riverMat);

    // ── lake ────────────────────────────────────────────────────────
    const L = WORLD.lavaLake;
    const lakeGeo = buildBasin(L.x, L.z, L.radius, L.y - 2.2, { segments: 128, wobble: 0.16 });
    const lakeMat = makeLavaMaterial({ flow: 0.6, crustScale: 0.55, heatBias: -0.34 });
    const lake = new THREE.Mesh(lakeGeo, lakeMat);
    lake.name = 'LavaLake';
    this.group.add(lake);
    this.materials.push(lakeMat);

    // ── crater pool ─────────────────────────────────────────────────
    const V = WORLD.volcano;
    const craterGeo = buildBasin(V.x, V.z, V.craterR * 0.78, V.height - V.craterDepth * 0.55, {
      segments: 72, wobble: 0.2,
    });
    const craterMat = makeLavaMaterial({ flow: 0.35, crustScale: 0.7, heatBias: 0.22 });
    const crater = new THREE.Mesh(craterGeo, craterMat);
    crater.name = 'CraterPool';
    this.group.add(crater);
    this.materials.push(craterMat);
    this.craterMaterial = craterMat;

    // Secondary vent.
    const V2 = WORLD.volcano2;
    const c2 = new THREE.Mesh(
      buildBasin(V2.x, V2.z, V2.craterR * 0.7, V2.height - V2.craterDepth * 0.5, { segments: 48, wobble: 0.22 }),
      makeLavaMaterial({ flow: 0.3, crustScale: 0.8, heatBias: 0.05 }),
    );
    this.group.add(c2);
    this.materials.push(c2.material);
  }

  /** 0..1 — eruption pressure. */
  setSurge(v) {
    for (const m of this.materials) m.uniforms.uSurge.value = v;
  }

  update(dt, camera) {
    for (const m of this.materials) m.uniforms.uCameraPos.value.copy(camera.position);
  }

  dispose() {
    this.group.traverse((o) => { o.geometry?.dispose(); o.material?.dispose(); });
  }
}
