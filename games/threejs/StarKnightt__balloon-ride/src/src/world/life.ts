/**
 * Small life on the land: flocks of sheep and herds of cows grazing in some pastures (slow drifting
 * wander, each animal facing the way it drifts), a horse cart and a couple of cars on the roads,
 * chimney smoke (soft painted puffs rising and leaning downwind), and two flocks of birds wheeling
 * below the balloon. All instanced; animals and vehicles move on the CPU (a few thousand matrices),
 * smoke and wing beats in the vertex shader.
 */
import * as THREE from "three";
import { mulberry32, range } from "../core/rng";
import { ID, M, box, merge, prep, sphere, xf, cyl } from "./geo";
import { COMMON, G, uber } from "../render/materials";
import { LAYER_SHADOW, onLayers } from "../render/lightpasses";
import { MAP_HALF, ROAD_PATHS, VILLAGE } from "./layout";
import { groundHeight } from "./heightfield";
import type { Parcel } from "./parcels";
import { edgeDist, pointInPoly } from "./vegetation";

interface Animal {
  hx: number;
  hz: number;
  a: number;
  w1: number;
  w2: number;
  p1: number;
  p2: number;
  s: number;
}

function sheepGeo(): THREE.BufferGeometry {
  const body = sphere(0.62, "#f4f0e6", M.plain, 8, 6);
  body.scale(1.0, 0.72, 0.62);
  xf(body, 0, 0.62, 0);
  const head = box(0.3, 0.3, 0.26, "#2c2622");
  xf(head, 0.62, 0.66, 0);
  const legs: THREE.BufferGeometry[] = [];
  for (const [x, z] of [[-0.35, -0.16], [-0.35, 0.16], [0.35, -0.16], [0.35, 0.16]]) legs.push(xf(box(0.09, 0.36, 0.09, "#2c2622"), x, 0.18, z));
  return merge([body, head, ...legs]);
}

function cowGeo(): THREE.BufferGeometry {
  const body = box(2.1, 1.0, 0.85, "#ffffff");
  xf(body, 0, 1.0, 0);
  const head = box(0.55, 0.5, 0.45, "#ffffff");
  xf(head, 1.25, 1.2, 0);
  const legs: THREE.BufferGeometry[] = [];
  for (const [x, z] of [[-0.8, -0.3], [-0.8, 0.3], [0.8, -0.3], [0.8, 0.3]]) legs.push(xf(box(0.18, 0.6, 0.18, "#ffffff"), x, 0.3, z));
  return merge([body, head, ...legs]);
}

function carGeo(color: string): THREE.BufferGeometry {
  const b = box(4.0, 1.0, 1.75, color, M.metal);
  xf(b, 0, 0.75, 0);
  const cab = box(2.1, 0.75, 1.6, "#e8e4d8", M.metal);
  xf(cab, -0.3, 1.55, 0);
  const wheels: THREE.BufferGeometry[] = [];
  for (const [x, z] of [[-1.3, 0.85], [-1.3, -0.85], [1.3, 0.85], [1.3, -0.85]]) {
    const w = cyl(0.36, 0.36, 0.25, "#222222", M.plain, 8);
    w.rotateX(Math.PI / 2);
    wheels.push(xf(w, x, 0.36, z));
  }
  return merge([b, cab, ...wheels]);
}

function cartGeo(): THREE.BufferGeometry {
  const bed = box(2.6, 0.6, 1.6, "#8a6440", M.planks);
  xf(bed, -1.3, 1.1, 0);
  const hay = sphere(0.9, "#d8bc6a", M.plain, 8, 6);
  hay.scale(1.3, 0.7, 0.9);
  xf(hay, -1.3, 1.65, 0);
  const wheels: THREE.BufferGeometry[] = [];
  for (const z of [0.9, -0.9]) {
    const w = cyl(0.6, 0.6, 0.12, "#4a3a2a", M.planks, 10);
    w.rotateX(Math.PI / 2);
    wheels.push(xf(w, -1.3, 0.6, z));
  }
  const horse = box(1.8, 0.8, 0.6, "#6a4630", M.plain);
  xf(horse, 1.3, 1.35, 0);
  const neck = box(0.5, 0.8, 0.4, "#6a4630", M.plain);
  xf(neck, 2.1, 1.85, 0, 0, 0, -0.5);
  const legs: THREE.BufferGeometry[] = [];
  for (const [x, z] of [[0.6, 0.2], [0.6, -0.2], [2.0, 0.2], [2.0, -0.2]]) legs.push(xf(box(0.16, 0.95, 0.16, "#5a3a26"), x, 0.48, z));
  return merge([bed, hay, ...wheels, horse, neck, ...legs]);
}

/** A bird: a body and two swept wings (the uber "butterfly" surface beats them in the shader). */
function birdGeo(): THREE.BufferGeometry {
  const g = new THREE.BufferGeometry();
  // Wings along x (|x| = span), body along z (forward +z).
  const p = [
    0, 0, 0.35, -0.7, 0.05, -0.05, 0, 0, -0.2,
    0, 0, 0.35, 0, 0, -0.2, 0.7, 0.05, -0.05,
    0, 0, 0.45, -0.06, 0, -0.35, 0.06, 0, -0.35,
  ];
  g.setAttribute("position", new THREE.Float32BufferAttribute(p, 3));
  g.computeVertexNormals();
  return prep(g, "#3a3430", M.butterfly);
}

// ------------------------------------------------------------------ smoke

const SMOKE_VS = /* glsl */ `
${COMMON}
in vec4 aPuff;   // chimney xyz, phase
out vec2 vQ;
out float vA;
out vec3 vWPos;
out float vSeed;
void main(){
  float period = 12.0;
  float a = fract(uTime / period + aPuff.w);
  float seed = fract(aPuff.w * 7.13 + aPuff.x * 0.013);
  vec3 c = aPuff.xyz;
  vec3 drift = vec3(uWindDir.x, 0.0, uWindDir.y);
  // A warm column rises straight off the pot first, then slows and bends away downwind.
  float rise = 1.0 - (1.0 - a) * (1.0 - a);
  c += drift * (a * a * a * 16.0 + a * 1.0) + vec3(0.0, rise * 11.0 + a * 2.0, 0.0);
  c.x += sin(uTime * 0.7 + seed * 6.0) * a * 0.9;
  c.z += cos(uTime * 0.5 + seed * 4.0) * a * 0.9;
  float size = 1.1 + a * 4.6;
  vec3 right = vec3(viewMatrix[0][0], viewMatrix[1][0], viewMatrix[2][0]);
  vec3 up = vec3(viewMatrix[0][1], viewMatrix[1][1], viewMatrix[2][1]);
  vec3 wp = c + (right * position.x + up * position.y) * size;
  vQ = position.xy;
  // Many faint, overlapping puffs that fade early: one soft wisp, not a chain of bubbles.
  vA = smoothstep(0.0, 0.1, a) * pow(1.0 - a, 2.6) * 0.2;
  vSeed = seed;
  vWPos = wp;
  gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
}
`;

const SMOKE_FS = /* glsl */ `
${COMMON}
layout(location = 0) out vec4 gColor;
layout(location = 1) out vec4 gNormal;
in vec2 vQ;
in float vA;
in vec3 vWPos;
in float vSeed;
void main(){
  float r = length(vQ);
  float n = vnoise(vQ * 2.5 + vSeed * 17.0);
  float k = 1.0 - smoothstep(0.0, 0.5, r + (n - 0.5) * 0.12);
  float a = k * k * vA;
  if (a < 0.01) discard;
  // A pale wisp: sunlit cream on the sun side, a soft blue in its own shade (never grey).
  float lit = clamp(0.5 + dot(normalize(vec3(vQ, 0.4)), vec3(0.0, 0.6, 0.3)) * 0.5, 0.0, 1.0);
  vec3 shade = mix(uShadowTint, vec3(0.74, 0.82, 0.96), 0.55) * 1.05 + uSkyMid * 0.15;
  vec3 col = mix(shade, uSunColor * 1.05 + vec3(0.04, 0.05, 0.08), lit * 0.7 + 0.2);
  col = applyFog(col, vWPos);
  gColor = vec4(safe3(col), safe1(a));
  gNormal = vec4(0.5, 0.5, 0.0, 0.0);
}
`;

function smokeMesh(chimneys: THREE.Vector3[], seed: number): THREE.Mesh {
  const r = mulberry32(seed * 71 + 1);
  const K = 30;
  const smoking = chimneys.filter(() => r() < 0.3);
  const quad = new THREE.PlaneGeometry(1, 1);
  const g = new THREE.InstancedBufferGeometry();
  g.index = quad.index;
  g.setAttribute("position", quad.attributes.position);
  const puff = new Float32Array(smoking.length * K * 4);
  let o = 0;
  for (const c of smoking) {
    const ph = r();
    for (let k = 0; k < K; k++) {
      puff[o++] = c.x;
      puff[o++] = c.y;
      puff[o++] = c.z;
      puff[o++] = (ph + k / K) % 1;
    }
  }
  g.setAttribute("aPuff", new THREE.InstancedBufferAttribute(puff, 4));
  g.instanceCount = smoking.length * K;
  g.boundingSphere = new THREE.Sphere(new THREE.Vector3(VILLAGE.x, 20, VILLAGE.z), 5000);
  const m = new THREE.Mesh(
    g,
    new THREE.ShaderMaterial({
      glslVersion: THREE.GLSL3,
      uniforms: { ...G },
      vertexShader: SMOKE_VS,
      fragmentShader: SMOKE_FS,
      transparent: true,
      depthWrite: false,
    }),
  );
  m.name = "chimney smoke";
  m.renderOrder = 5;
  m.frustumCulled = false;
  return m;
}

// ------------------------------------------------------------------ assembly

export interface Life {
  group: THREE.Group;
  update(t: number): void;
  info(): Record<string, number>;
}

export function buildLife(parcels: Parcel[], chimneys: THREE.Vector3[], seed: number): Life {
  const r = mulberry32(seed * 1291 + 5);
  const group = new THREE.Group();
  group.name = "life";

  // Flocks and herds in pastures near enough to be seen (nearest first, capped).
  const sheep: Animal[] = [], cows: Animal[] = [];
  const cowTint: THREE.Color[] = [];
  const stocked = parcels
    .filter((p) => p.stock !== "none" && Math.max(Math.abs(p.cx), Math.abs(p.cz)) < MAP_HALF - 200)
    .sort((a, b) => Math.hypot(a.cx, a.cz) - Math.hypot(b.cx, b.cz));
  let flocks = 0, herds = 0;
  for (const p of stocked) {
    const isSheep = p.stock === "sheep";
    if (isSheep ? flocks >= 46 : herds >= 26) continue;
    isSheep ? flocks++ : herds++;
    const n = isSheep ? Math.round(range(r, 14, 34)) : Math.round(range(r, 6, 13));
    // Animals keep loosely together round one or two spots in the field.
    const centres = [[p.cx, p.cz]];
    for (let i = 0, tries = 0; i < n && tries < n * 20; tries++) {
      const [cx, cz] = centres[0];
      const rad = isSheep ? 34 : 40;
      const x = cx + (r() - 0.5) * rad * 2, z = cz + (r() - 0.5) * rad * 2;
      if (!pointInPoly(x, z, p.poly) || edgeDist(x, z, p.poly) < 7) continue;
      const a: Animal = { hx: x, hz: z, a: r() * 6.28, w1: range(r, 0.008, 0.025), w2: range(r, 0.006, 0.02), p1: r() * 6.28, p2: r() * 6.28, s: range(r, 0.85, 1.15) };
      (isSheep ? sheep : cows).push(a);
      if (!isSheep) {
        const k = r();
        cowTint.push(k < 0.15 ? new THREE.Color("#7a4a30") : k < 0.6 ? new THREE.Color("#ece4d4") : k < 0.82 ? new THREE.Color("#2a2624") : new THREE.Color("#c89a64"));
      }
      i++;
    }
  }
  const animalMat = uber(ID.fence, 0.6);
  const sheepIM = new THREE.InstancedMesh(sheepGeo(), animalMat, Math.max(1, sheep.length));
  const cowIM = new THREE.InstancedMesh(cowGeo(), animalMat, Math.max(1, cows.length));
  sheepIM.count = sheep.length;
  cowIM.count = cows.length;
  cows.forEach((_, i) => cowIM.setColorAt(i, cowTint[i]));
  for (const im of [sheepIM, cowIM]) {
    im.name = im === sheepIM ? "sheep" : "cows";
    im.frustumCulled = false;
    im.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    onLayers(im, LAYER_SHADOW);
    group.add(im);
  }

  // Vehicles: a hay cart near the village and two cars on the main roads.
  const roads = Object.fromEntries(ROAD_PATHS.map((p) => [p.name, p.path]));
  const vehicles = [
    { mesh: new THREE.Mesh(cartGeo(), uber(ID.boat, 0.8)), path: roads["south"], v: 1.6, s0: 160, side: 1.2 },
    { mesh: new THREE.Mesh(carGeo("#b83a2e"), uber(ID.boat, 0.8)), path: roads["east"], v: 9, s0: 300, side: 1.4 },
    { mesh: new THREE.Mesh(carGeo("#3a6ea0"), uber(ID.boat, 0.8)), path: roads["west"], v: 8, s0: 2600, side: 1.4 },
    { mesh: new THREE.Mesh(carGeo("#e6d6a8"), uber(ID.boat, 0.8)), path: roads["north"], v: 7, s0: 900, side: 1.3 },
  ].map((v) => {
    const cum = [0];
    for (let i = 1; i < v.path.length; i++) cum.push(cum[i - 1] + Math.hypot(v.path[i][0] - v.path[i - 1][0], v.path[i][1] - v.path[i - 1][1]));
    v.mesh.name = "vehicle";
    v.mesh.matrixAutoUpdate = true;
    onLayers(v.mesh, LAYER_SHADOW);
    group.add(v.mesh);
    return { ...v, cum, L: cum[cum.length - 1] };
  });

  // Birds: two flocks wheeling over the village and the river meadows.
  const birdIM = new THREE.InstancedMesh(birdGeo(), uber(ID.butterfly, -1, THREE.DoubleSide), 40);
  birdIM.name = "birds";
  birdIM.frustumCulled = false;
  birdIM.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  group.add(birdIM);
  const birds = Array.from({ length: 40 }, (_, i) => ({
    flock: i < 22 ? 0 : 1, r: range(r, 18, 46), ph: r() * 6.28, h: range(r, -12, 12), w: range(r, 0.16, 0.22) * (r() < 0.5 ? 1 : 1),
  }));
  const flockC = [
    { x: -60, z: 60, y: 85, cr: 110 },
    { x: 420, z: 260, y: 70, cr: 160 },
  ];

  group.add(smokeMesh(chimneys, seed));

  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), e = new THREE.Euler(), v = new THREE.Vector3(), sc = new THREE.Vector3();
  const place = (im: THREE.InstancedMesh, i: number, x: number, z: number, yaw: number, s: number) => {
    const y = groundHeight(x, z) - 0.05;
    m.compose(v.set(x, y, z), q.setFromEuler(e.set(0, yaw, 0)), sc.set(s, s, s));
    im.setMatrixAt(i, m);
  };
  let frame = 0;
  return {
    group,
    update(t) {
      // Grazing drift: a few metres round each animal's spot, a fraction of a metre a second.
      const drift = (a: Animal, k: number, im: THREE.InstancedMesh, i: number) => {
        const x = a.hx + Math.sin(t * a.w1 + a.p1) * k + Math.sin(t * a.w2 * 2.3 + a.p2) * k * 0.4;
        const z = a.hz + Math.cos(t * a.w2 + a.p2) * k;
        const dx = Math.cos(t * a.w1 + a.p1) * a.w1 + Math.cos(t * a.w2 * 2.3 + a.p2) * a.w2 * 0.92;
        const dz = -Math.sin(t * a.w2 + a.p2) * a.w2;
        place(im, i, x, z, Math.atan2(-dz, dx), a.s);
      };
      // Animals move slowly: every other frame is plenty.
      if (frame++ % 2 === 0) {
        sheep.forEach((a, i) => drift(a, 9, sheepIM, i));
        cows.forEach((a, i) => drift(a, 12, cowIM, i));
        sheepIM.instanceMatrix.needsUpdate = true;
        cowIM.instanceMatrix.needsUpdate = true;
      }
      for (const vh of vehicles) {
        // Up and down the road (turning round off the map's edge, out of sight).
        let s = (vh.s0 + t * vh.v) % (vh.L * 2);
        const back = s > vh.L;
        if (back) s = vh.L * 2 - s;
        let i = 1;
        while (i < vh.cum.length - 1 && vh.cum[i] < s) i++;
        const k = (s - vh.cum[i - 1]) / Math.max(1e-3, vh.cum[i] - vh.cum[i - 1]);
        const [ax, az] = vh.path[i - 1], [bx, bz] = vh.path[i];
        let dx = bx - ax, dz = bz - az;
        const l = Math.hypot(dx, dz) || 1;
        dx /= l;
        dz /= l;
        if (back) [dx, dz] = [-dx, -dz];
        // Keep to the left-hand side of the lane (English lanes).
        const x = ax + (bx - ax) * k - dz * vh.side, z = az + (bz - az) * k + dx * vh.side;
        vh.mesh.position.set(x, groundHeight(x, z) + 0.02, z);
        vh.mesh.rotation.set(0, Math.atan2(-dz, dx), 0);
      }
      birds.forEach((b, i) => {
        const f = flockC[b.flock];
        const cx = f.x + Math.sin(t * 0.03 + b.flock) * f.cr, cz = f.z + Math.cos(t * 0.025 + b.flock * 2) * f.cr;
        const a = t * b.w + b.ph;
        const x = cx + Math.cos(a) * b.r, z = cz + Math.sin(a) * b.r;
        const y = groundHeight(cx, cz) + f.y + b.h + Math.sin(t * 0.4 + b.ph) * 4;
        // Facing along the circle (tangent), banked into the turn.
        const tx = -Math.sin(a), tz = Math.cos(a);
        m.compose(v.set(x, y, z), q.setFromEuler(e.set(0, Math.atan2(tx, tz), 0.35, "YXZ")), sc.set(1.6, 1.6, 1.6));
        birdIM.setMatrixAt(i, m);
      });
      birdIM.instanceMatrix.needsUpdate = true;
    },
    info: () => ({ sheep: sheep.length, cows: cows.length }),
  };
}
