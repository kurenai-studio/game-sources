import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { createWorld, U, heightAt, collide, litAt } from './world.js';
import { NODES, LINKS, LANTERNS } from './data.js';
import { rng, smoothstep } from './noise.js';
import { buildCar, buildWalker, buildHollowMeshes, buildTrafficMeshes, softTexture } from './actors.js';
import { audio } from './audio.js';
import { createHud } from './hud.js';

const $ = (id) => document.getElementById(id);
const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const TAU = Math.PI * 2;
const wrapAngle = (a) => ((((a + Math.PI) % TAU) + TAU) % TAU) - Math.PI;
const ease = (t) => 1 - (1 - clamp(t, 0, 1)) ** 3;
const fmtTime = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;

/* ---------- renderer and scene ---------- */

const renderer = new THREE.WebGLRenderer({ powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.5));
renderer.setSize(innerWidth, innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.prepend(renderer.domElement);

const scene = new THREE.Scene();
const NIGHT_FOG = new THREE.Color('#120f2a'), DAWN_FOG = new THREE.Color('#d9a99a');
scene.fog = new THREE.Fog(NIGHT_FOG.clone(), 90, 720);
const camera = new THREE.PerspectiveCamera(62, innerWidth / innerHeight, 0.5, 4000);
const hemi = new THREE.HemisphereLight('#6a6fc0', '#1a2a2e', 2.2);
const moon = new THREE.DirectionalLight('#a9b6ff', 1.3);
moon.position.set(-0.5, 0.35, -0.8);
scene.add(hemi, moon);

const world = createWorld(scene);
const hud = createHud(world.mapCanvas);

const target = new THREE.WebGLRenderTarget(innerWidth, innerHeight, { type: THREE.HalfFloatType, samples: 4 });
const composer = new EffectComposer(renderer, target);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.62, 0.5, 0.9);
composer.addPass(bloom);
composer.addPass(new OutputPass());
composer.setPixelRatio(renderer.getPixelRatio());

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  composer.setSize(innerWidth, innerHeight);
});

/* ---------- actors ---------- */

const car = buildCar();
const walker = buildWalker();
scene.add(car.root, walker.root);
const carryLight = new THREE.PointLight('#ffad5c', 0, 30, 1.4);
scene.add(carryLight);

function makeParticles(n, size) {
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(n * 3), col = new Float32Array(n * 3);
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  const points = new THREE.Points(geo, new THREE.PointsMaterial({
    size, map: softTexture(), vertexColors: true, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
  }));
  points.frustumCulled = false;
  scene.add(points);
  const vel = new Float32Array(n * 3), life = new Float32Array(n), max = new Float32Array(n), base = new Float32Array(n * 3), grav = new Float32Array(n);
  let next = 0;
  return {
    emit(x, y, z, count, color, spread = 4, up = 2, ttl = 1, gravity = 0) {
      for (let k = 0; k < count; k++) {
        const i = next++ % n;
        pos.set([x, y, z], i * 3);
        vel.set([(Math.random() - 0.5) * spread, up + (Math.random() - 0.5) * spread, (Math.random() - 0.5) * spread], i * 3);
        life[i] = max[i] = ttl * (0.6 + Math.random() * 0.6);
        base.set(color, i * 3);
        grav[i] = gravity;
      }
    },
    update(dt) {
      for (let i = 0; i < n; i++) {
        if (life[i] <= 0) continue;
        life[i] -= dt;
        const f = Math.max(0, life[i] / max[i]);
        for (let a = 0; a < 3; a++) {
          pos[i * 3 + a] += vel[i * 3 + a] * dt;
          vel[i * 3 + a] *= 1 - 1.2 * dt;
          col[i * 3 + a] = base[i * 3 + a] * f;
        }
        vel[i * 3 + 1] -= grav[i] * dt;
      }
      geo.attributes.position.needsUpdate = geo.attributes.color.needsUpdate = true;
    },
  };
}
const sparks = makeParticles(1800, 0.75);
const smoke = makeParticles(600, 10);
const AMBER = [3, 1.6, 0.45], VIOLET = [1.4, 0.2, 2], DUST = [0.12, 0.1, 0.14], STEAM = [0.16, 0.15, 0.2];

const MAX_EMBERS = 820;
const emberMesh = new THREE.InstancedMesh(new THREE.OctahedronGeometry(0.55), new THREE.MeshBasicMaterial({ color: new THREE.Color(3.4, 1.7, 0.5) }), MAX_EMBERS);
emberMesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
emberMesh.frustumCulled = false;
scene.add(emberMesh);

const MAX_HOLLOWS = 70;
const hollowMeshes = buildHollowMeshes(scene, MAX_HOLLOWS);
const denSpikes = new THREE.InstancedMesh(new THREE.OctahedronGeometry(1).scale(0.55, 3.2, 0.55), new THREE.MeshBasicMaterial({ color: '#100820' }), 80);
const denGlow = new THREE.InstancedMesh(new THREE.PlaneGeometry(26, 26).rotateX(-Math.PI / 2),
  new THREE.MeshBasicMaterial({ color: new THREE.Color(0.55, 0.06, 0.7), map: softTexture(), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }), 16);
scene.add(denSpikes, denGlow);

const TRAFFIC = 46;
const trafficMeshes = buildTrafficMeshes(scene, TRAFFIC);
const trafficColors = ['#e9d8b4', '#d0644f', '#3f8c8a', '#e0a64a', '#5a5f8f', '#c9c3d6'];
const traffic = Array.from({ length: TRAFFIC }, (_, k) => {
  const r = rng(900 + k);
  trafficMeshes.body.setColorAt(k, new THREE.Color(trafficColors[k % trafficColors.length]));
  return { alongZ: k % 2 === 0, line: (Math.floor(r() * 7) - 3) * 80, dir: r() < 0.5 ? 1 : -1, pos: (r() - 0.5) * 480, top: 11 + r() * 6, speed: 0 };
});

const shock = new THREE.Mesh(new THREE.RingGeometry(0.92, 1, 96).rotateX(-Math.PI / 2),
  new THREE.MeshBasicMaterial({ color: new THREE.Color(3, 1.7, 0.6), transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
shock.visible = false;
scene.add(shock);

/* ---------- graph rules ---------- */

const nodeIndex = Object.fromEntries(NODES.map((n, i) => [n.id, i]));
const BEACON = nodeIndex.beacon;
const neighbors = NODES.map(() => []);
for (const [a, b] of LINKS) {
  neighbors[nodeIndex[a]].push(nodeIndex[b]);
  neighbors[nodeIndex[b]].push(nodeIndex[a]);
}

let S, P, C, embers, dens, hollows;

function available(i) {
  if (S.nodes[i].lit) return false;
  if (i === BEACON) return S.nodes.every((n, k) => k === BEACON || n.lit);
  return neighbors[i].some((k) => S.nodes[k].lit);
}

function autoPin() {
  const open = NODES.map((n, i) => i).filter(available).sort((a, b) => NODES[a].cost - S.nodes[a].progress - (NODES[b].cost - S.nodes[b].progress));
  S.pin = open.length ? open[0] : null;
}

const land = (x, z, r = 1.2) => heightAt(x, z) > 0.9 && Math.hypot(x, z) < 610 && !collide(x, z, r).hit;

function addEmber(x, z, value = 1, phase = Math.random() * 6) {
  if (embers.length >= MAX_EMBERS || !land(x, z)) return false;
  embers.push({ x, z, y: heightAt(x, z), value, alive: true, pull: false, phase });
  return true;
}

function dropEmbers(x, z, count) {
  for (let k = 0, tries = 0; k < count && tries < count * 8; tries++) {
    const a = Math.random() * TAU, d = 4 + Math.random() * 7;
    if (addEmber(x + Math.cos(a) * d, z + Math.sin(a) * d)) k++;
  }
}

function placeEmbers(seed) {
  const r = rng(seed);
  embers = [];
  for (let z = 285; z > 170; z -= 9) addEmber(r() * 4 - 2, z, 1, r() * 6);
  for (let k = 0; k < 52; k++) {
    const road = world.roads[Math.floor(r() * world.roads.length)];
    const s = Math.floor(r() * (road.pts.length - 12)), off = (r() - 0.5) * 5;
    for (let m = 0; m < 5; m++) {
      const [x, z] = road.pts[s + m * 2];
      addEmber(x + off, z + off, 1, m * 0.6);
    }
  }
  for (let k = 0, made = 0; made < 26 && k < 400; k++) {
    const a = r() * TAU, d = Math.sqrt(r()) * 540, cx = Math.cos(a) * d, cz = Math.sin(a) * d;
    if (!land(cx, cz, 4)) continue;
    made++;
    for (let m = 0; m < 7; m++) addEmber(cx + Math.cos((m / 7) * TAU) * 4.5, cz + Math.sin((m / 7) * TAU) * 4.5, 1, m);
  }
  NODES.forEach((n, i) => {
    if (!i) return;
    for (let m = 0; m < 6; m++) addEmber(n.pos[0] + Math.cos((m / 6) * TAU + i) * 28, n.pos[1] + Math.sin((m / 6) * TAU + i) * 28, 1, m);
  });
  for (const [lx, lz] of LANTERNS) {
    for (let f = 1; f > 0.5; f -= 0.02) if (addEmber(lx * f, lz * f, 5)) break;
  }
}

function placeHollows(seed) {
  const r = rng(seed * 7 + 3);
  dens = [];
  hollows = [];
  NODES.forEach((n, i) => {
    if (!i) return;
    for (let c = 0; c < (i === BEACON ? 2 : 1); c++) {
      for (let tries = 0; tries < 60; tries++) {
        const a = r() * TAU, d = 42 + r() * 40, x = n.pos[0] + Math.cos(a) * d, z = n.pos[1] + Math.sin(a) * d;
        if (!land(x, z, 4) || litAt(x, z) > 0.05) continue;
        const den = { x, z, node: i, level: 2 + Math.floor(n.cost / 30), alive: true, fade: 1, spikes: [] };
        for (let s = 0; s < 5; s++) den.spikes.push({ dx: (r() - 0.5) * 6, dz: (r() - 0.5) * 6, s: 0.6 + r() * 0.8, tilt: (r() - 0.5) * 0.6, ry: r() * 6 });
        for (let k = 0; k < 6; k++) hollows.push({ den, k, x, z, vx: 0, vz: 0, a: r() * TAU, bob: r() * 6, alive: k < den.level, respawn: 0, stun: 0, fade: 0 });
        dens.push(den);
        break;
      }
    }
  });
}

/* ---------- run lifecycle ---------- */

function reset(seed) {
  S = {
    seed, t: 0, embers: 0, cap: 30, boost: 1, inCar: false, perks: new Set(), stockCap: 25,
    nodes: NODES.map((n, i) => ({ lit: i === 0, progress: 0, stock: i === 0 ? 6 : 0, litT: i === 0 ? -10 : 0 })),
    stats: { gathered: 0, banished: 0, lanterns: 0, robbed: 0 },
    pin: nodeIndex.midtown, dawnT: null, won: false, combo: 0, comboT: 0, hurt: 0, shake: 0, chargeAcc: 0, hintedHollow: false, graceT: 0,
  };
  U.uNodes.value.forEach((v, i) => v.set(NODES[i].pos[0], NODES[i].pos[1], i === 0 ? NODES[0].radius : 0, i === 0 ? 1 : 0));
  U.uDawn.value = 0;
  P = { x: 4, z: 289, y: heightAt(4, 289), vx: 0, vz: 0, vy: 0, heading: Math.PI };
  C = { x: 3.5, z: 285, heading: Math.PI, vx: 0, vz: 0, steer: 0, vf: 0, roll: 0 };
  placeEmbers(seed);
  placeHollows(seed);
  dens.forEach((d, di) => d.spikes.forEach((s, k) => setSpike(di * 5 + k, d, s, 1)));
  denSpikes.count = dens.length * 5;
  denSpikes.instanceMatrix.needsUpdate = true;
  dens.forEach((d, di) => setDenGlow(di, d, 1));
  denGlow.count = dens.length;
  embers.forEach((e, i) => (e.i = i));
  cam.yaw = Math.PI;
}

const m4 = new THREE.Matrix4(), q = new THREE.Quaternion(), v3 = new THREE.Vector3(), s3 = new THREE.Vector3(), eul = new THREE.Euler();
function setMatrix(mesh, i, x, y, z, ry, sx, sy = sx, sz = sx, rx = 0, rz = 0) {
  q.setFromEuler(eul.set(rx, ry, rz, 'YXZ'));
  mesh.setMatrixAt(i, m4.compose(v3.set(x, y, z), q, s3.set(sx, sy, sz)));
}
function setSpike(i, d, s, k) {
  setMatrix(denSpikes, i, d.x + s.dx, heightAt(d.x + s.dx, d.z + s.dz) + 1.5 * s.s * k, d.z + s.dz, s.ry, s.s * k, s.s * k, s.s * k, s.tilt, s.tilt * 0.7);
}
function setDenGlow(i, d, k) {
  setMatrix(denGlow, i, d.x, heightAt(d.x, d.z) + 0.4, d.z, 0, k);
  denGlow.instanceMatrix.needsUpdate = true;
}

function restore(i) {
  const n = NODES[i], st = S.nodes[i];
  st.lit = true;
  st.litT = S.t;
  U.uNodes.value[i].w = 1;
  if (n.perk === 'carry') S.cap += 15;
  if (n.perk === 'stock') S.stockCap = 50;
  if (n.perk === 'dawn') { S.dawnT = S.t; audio.dawn(); }
  S.perks.add(n.perk);
  hud.toast(`${n.name} restored`, n.perkText, 'big');
  audio.restore();
  S.shake = 0.7;
  const y = world.nodeVis[i].y;
  for (let k = 0; k < 6; k++) sparks.emit(n.pos[0], y + 3 + k * 2.5, n.pos[1], 40, AMBER, 26, 6, 2.2, 6);
  shock.position.set(n.pos[0], y + 1, n.pos[1]);
  shock.userData.t0 = S.t;
  shock.visible = true;
  dens.forEach((d) => {
    if (d.node === i) d.alive = false;
    else if (d.alive && d.level < 6) d.level++;
  });
  for (const h of hollows) {
    if (h.den.alive && !h.alive && h.k < h.den.level && !h.respawn) h.respawn = S.t + 8;
  }
  if (S.pin === i || S.pin === null || S.nodes[S.pin].lit) autoPin();
  if (i !== BEACON && available(BEACON)) hud.toast('The Summit Beacon answers', 'Every substation is live. Climb the mountain and end the night.', 'big');
}

function win() {
  S.won = true;
  document.exitPointerLock?.();
  let best = null;
  try {
    best = Number(localStorage.getItem('afterglow-best')) || null;
    if (!best || S.t < best) localStorage.setItem('afterglow-best', String(S.t));
  } catch { /* storage unavailable */ }
  $('endStats').innerHTML = [
    ['Night length', fmtTime(S.t)],
    ['Best night', fmtTime(best && best < S.t ? best : S.t)],
    ['Embers gathered', S.stats.gathered],
    ['Hollows banished', S.stats.banished],
    ['Wishing lanterns', `${S.stats.lanterns} / ${LANTERNS.length}`],
    ['Times robbed', S.stats.robbed],
  ].map(([k, v]) => `<div><span>${k}</span><b>${v}</b></div>`).join('');
  $('end').classList.remove('hidden');
}

/* ---------- input ---------- */

const keys = new Set();
const cam = { yaw: Math.PI, pitch: 0.32, lastMouse: -99, fov: 62 };
let mode = 'title', mapOpen = false;
const lockPointer = () => renderer.domElement.requestPointerLock?.()?.catch?.(() => {});

addEventListener('keydown', (e) => {
  if (e.code === 'Tab') e.preventDefault();
  if (e.repeat) return keys.add(e.code);
  keys.add(e.code);
  if (mode !== 'play') return;
  if (e.code === 'KeyM') toggleMap();
  if (e.code === 'KeyN') hud.toast(audio.toggleMute() ? 'Sound off' : 'Sound on');
  if (mapOpen) return;
  if (e.code === 'KeyE') toggleCar();
  if (e.code === 'Tab') {
    const open = NODES.map((n, i) => i).filter(available);
    if (open.length) S.pin = open[(open.indexOf(S.pin) + 1) % open.length];
  }
});
addEventListener('keyup', (e) => keys.delete(e.code));
addEventListener('blur', () => keys.clear());
addEventListener('mousemove', (e) => {
  if (mode !== 'play' || mapOpen) return;
  if (document.pointerLockElement || e.buttons & 1) {
    cam.yaw -= e.movementX * 0.0026;
    cam.pitch = clamp(cam.pitch + e.movementY * 0.002, -0.05, 1.15);
    cam.lastMouse = performance.now() / 1000;
  }
});
renderer.domElement.addEventListener('click', () => {
  if (mode === 'play' && !mapOpen && !S.won) lockPointer();
});
$('bigmap').addEventListener('click', (e) => {
  const i = hud.mapHit(e);
  if (i !== null && !S.nodes[i].lit) S.pin = i;
});
$('mapList').addEventListener('click', (e) => {
  const li = e.target.closest('li');
  if (li && !S.nodes[li.dataset.node].lit) S.pin = Number(li.dataset.node);
});

function toggleMap() {
  mapOpen = !mapOpen;
  $('map').classList.toggle('hidden', !mapOpen);
  if (mapOpen) document.exitPointerLock?.();
}

function toggleCar() {
  if (!S.inCar && Math.hypot(P.x - C.x, P.z - C.z) < 4.8) {
    S.inCar = true;
    cam.lastMouse = -99;
  } else if (S.inCar && Math.abs(C.vf) < 8) {
    for (const side of [1, -1]) {
      const x = C.x + Math.cos(C.heading) * 2.6 * side, z = C.z - Math.sin(C.heading) * 2.6 * side;
      if (!collide(x, z, 0.6).hit && heightAt(x, z) > 0.4) {
        Object.assign(P, { x, z, vx: 0, vz: 0, vy: 0, heading: C.heading });
        S.inCar = false;
        return;
      }
    }
  }
}

$('startBtn').addEventListener('click', () => {
  audio.init();
  mode = 'play';
  S.t = 0;
  $('title').classList.add('hidden');
  $('hud').classList.remove('hidden');
  lockPointer();
  [
    ['Halcyon County is dark', 'The Works is the last live substation. Its light keeps the Hollows out.'],
    ['Gather embers', 'They glow along the roads. Your tank holds 30.'],
    ['Feed the grid', 'Hold F inside a substation ring to restore it. Links only carry power from a live neighbor.'],
  ].forEach(([a, b], k) => setTimeout(() => hud.toast(a, b), 600 + k * 4800));
});
$('againBtn').addEventListener('click', () => {
  $('end').classList.add('hidden');
  reset((S.seed * 16807 + 11) % 2147483647);
  lockPointer();
});
$('roamBtn').addEventListener('click', () => {
  $('end').classList.add('hidden');
  lockPointer();
});

/* ---------- simulation ---------- */

function updateCar(dt) {
  const fx = Math.sin(C.heading), fz = Math.cos(C.heading), rx = -Math.cos(C.heading), rz = Math.sin(C.heading);
  let vf = C.vx * fx + C.vz * fz, vl = C.vx * rx + C.vz * rz;
  const thr = (keys.has('KeyW') || keys.has('ArrowUp') ? 1 : 0) - (keys.has('KeyS') || keys.has('ArrowDown') ? 1 : 0);
  const steerIn = (keys.has('KeyD') || keys.has('ArrowRight') ? 1 : 0) - (keys.has('KeyA') || keys.has('ArrowLeft') ? 1 : 0);
  const brake = keys.has('Space');
  C.steer += (steerIn - C.steer) * Math.min(1, dt * 7);
  const boosting = keys.has('ShiftLeft') && S.boost > 0.02 && thr > 0;
  const top = 36 * (S.perks.has('speed') ? 1.15 : 1) * (boosting ? 1.45 : 1);
  if (thr > 0) vf += (boosting ? 36 : 21) * dt * Math.max(0, 1 - vf / top);
  else if (thr < 0) vf = Math.max(-13, vf - (vf > 1 ? 40 : 15) * dt);
  else vf -= Math.sign(vf) * Math.min(Math.abs(vf), 5 * dt);
  if (vf > top) vf -= (vf - top) * dt * 2;
  vf -= ((heightAt(C.x + fx * 2, C.z + fz * 2) - heightAt(C.x - fx * 2, C.z - fz * 2)) / 4) * 16 * dt;
  if (brake) vf -= Math.sign(vf) * Math.min(Math.abs(vf), 12 * dt);
  if (!thr && Math.abs(vf) < 1.5) vf = 0;
  vl *= Math.exp(-(brake ? 1.4 : 7.5) * dt);
  C.vx = fx * vf + rx * vl;
  C.vz = fz * vf + rz * vl;
  C.heading -= C.steer * 2.1 * clamp(Math.abs(vf) / 7, 0, 1) * Math.sign(vf) / (1 + Math.abs(vf) / 50) * (brake ? 1.45 : 1) * dt;
  S.boost = clamp(S.boost + (boosting ? -0.3 : 0.075 * (S.perks.has('boost') ? 2 : 1)) * dt, 0, 1);

  const nx = C.x + C.vx * dt, nz = C.z + C.vz * dt;
  if (heightAt(nx, nz) < 0.35) {
    C.vx *= -0.3; C.vz *= -0.3;
  } else {
    const res = collide(nx, nz, 1.75);
    C.x = res.x; C.z = res.z;
    if (res.hit) {
      const vn = C.vx * res.nx + C.vz * res.nz;
      if (vn < 0) {
        C.vx -= res.nx * vn * 1.35; C.vz -= res.nz * vn * 1.35;
        if (-vn > 7) { S.shake = Math.min(1, -vn / 30); audio.hit(); sparks.emit(C.x - res.nx * 2, heightAt(C.x, C.z) + 1, C.z - res.nz * 2, 20, [2, 1.4, 1], 8, 2, 0.5, 10); }
      }
    }
  }
  C.vf = vf;
  if (boosting) sparks.emit(C.x - fx * 2.6, heightAt(C.x, C.z) + 0.9, C.z - fz * 2.6, 3, AMBER, 2, 0.5, 0.5);
  if ((brake && Math.abs(vf) > 10) || Math.abs(vl) > 6) smoke.emit(C.x - fx * 1.6, heightAt(C.x, C.z) + 0.5, C.z - fz * 1.6, 1, DUST, 2, 1, 1.4);
  audio.engine(vf, true, boosting);

  // body pose from the ground under each wheel
  const hf = heightAt(C.x + fx * 1.6, C.z + fz * 1.6), hb = heightAt(C.x - fx * 1.6, C.z - fz * 1.6);
  const hl = heightAt(C.x - rx * 1.1, C.z - rz * 1.1), hr = heightAt(C.x + rx * 1.1, C.z + rz * 1.1);
  C.roll += (clamp(-C.steer * vf * 0.004, -0.09, 0.09) - C.roll) * Math.min(1, dt * 5);
  car.root.position.set(C.x, (hf + hb + hl + hr) / 4, C.z);
  car.root.rotation.set(-Math.atan2(hf - hb, 3.2), C.heading, Math.atan2(hl - hr, 2.2), 'YXZ');
  car.body.rotation.z = C.roll;
  car.body.position.y = Math.sin(S.t * 18) * Math.min(0.03, Math.abs(vf) * 0.001);
  for (const w of car.wheels) {
    w.wheel.rotation.x += (vf * dt) / 0.52;
    if (w.front) w.pivot.rotation.y = -C.steer * 0.42;
  }
  return Math.abs(vf);
}

function updateWalker(dt) {
  const ix = (keys.has('KeyD') || keys.has('ArrowRight') ? 1 : 0) - (keys.has('KeyA') || keys.has('ArrowLeft') ? 1 : 0);
  const iz = (keys.has('KeyW') || keys.has('ArrowUp') ? 1 : 0) - (keys.has('KeyS') || keys.has('ArrowDown') ? 1 : 0);
  const fx = Math.sin(cam.yaw), fz = Math.cos(cam.yaw);
  let dx = fx * iz - Math.cos(cam.yaw) * ix, dz = fz * iz + Math.sin(cam.yaw) * ix;
  const len = Math.hypot(dx, dz);
  const sprint = keys.has('ShiftLeft') ? 12.5 : 7.5;
  if (len) { dx /= len; dz /= len; }
  P.vx += (dx * sprint - P.vx) * Math.min(1, dt * 10);
  P.vz += (dz * sprint - P.vz) * Math.min(1, dt * 10);
  const ground = heightAt(P.x, P.z);
  if (keys.has('Space') && P.y <= ground + 0.05) P.vy = 7.5;
  P.vy -= 22 * dt;
  P.y = Math.max(ground, P.y + P.vy * dt);
  if (P.y === ground) P.vy = 0;
  const nx = P.x + P.vx * dt, nz = P.z + P.vz * dt;
  if (heightAt(nx, nz) > 0.3) {
    const res = collide(nx, nz, 0.55);
    P.x = res.x; P.z = res.z;
  }
  const speed = Math.hypot(P.vx, P.vz);
  if (len) P.heading += wrapAngle(Math.atan2(dx, dz) - P.heading) * Math.min(1, dt * 12);
  walker.phase += speed * dt * 1.5;
  const swing = Math.sin(walker.phase) * Math.min(1, speed / 6) * 0.8;
  walker.legs[0].rotation.x = swing; walker.legs[1].rotation.x = -swing;
  walker.arms[0].rotation.x = -swing * 0.5 - 0.35; walker.arms[1].rotation.x = swing;
  walker.root.position.set(P.x, P.y + Math.abs(Math.sin(walker.phase)) * Math.min(0.12, speed * 0.01), P.z);
  walker.root.rotation.y = P.heading;
  walker.lanternMat.color.setRGB(1 + S.embers * 0.09, 0.5 + S.embers * 0.045, 0.15 + S.embers * 0.01);
  audio.engine(0, false, false);
  return speed;
}

function updateEmbers(dt, pl) {
  const reach = (S.inCar ? 7.5 : 4.5) * (S.perks.has('magnet') ? 2 : 1);
  const full = S.embers >= S.cap;
  S.comboT -= dt;
  if (S.comboT <= 0) S.combo = 0;
  for (const e of embers) {
    if (!e.alive) continue;
    const dx = pl.x - e.x, dz = pl.z - e.z, d = Math.hypot(dx, dz);
    if (d < reach && !full) e.pull = true;
    if (e.pull && !full && d > 0.01) {
      const step = Math.min(d, (18 + (reach - d) * 6) * dt);
      e.x += (dx / d) * step; e.z += (dz / d) * step;
      e.y = heightAt(e.x, e.z);
    }
    if (d < 1.8 && !full) {
      e.alive = false;
      S.embers = Math.min(S.cap, S.embers + e.value);
      S.stats.gathered += e.value;
      S.combo++;
      S.comboT = 1.6;
      sparks.emit(e.x, e.y + 1.4, e.z, e.value > 1 ? 60 : 10, AMBER, e.value > 1 ? 10 : 4, 3, 0.8, 4);
      if (e.value > 1) {
        S.stats.lanterns++;
        audio.lantern();
        hud.toast('Wishing lantern', `${S.stats.lanterns} of ${LANTERNS.length} found · +${e.value} embers`);
      } else audio.pickup(S.combo);
      if (S.embers >= S.cap) hud.toast('Tank full', 'Feed a substation or empty a stockpile run.');
    }
  }
  embers.forEach((e, i) => {
    const s = e.alive ? (e.value > 1 ? 2.3 : 1) * (1 + Math.sin(S.t * 4 + e.phase) * 0.12) : 0;
    setMatrix(emberMesh, i, e.x, e.y + 1.3 + Math.sin(S.t * 2 + e.phase) * 0.28, e.z, S.t * 1.6 + e.phase, s);
  });
  emberMesh.count = embers.length;
  emberMesh.instanceMatrix.needsUpdate = true;
}

function updateHollows(dt, pl, speed) {
  const safe = litAt(pl.x, pl.z) > 0.35;
  const slow = S.perks.has('ward') ? 0.65 : 1;
  hollows.forEach((h, i) => {
    const den = h.den;
    if (!den.alive && h.alive) {
      h.alive = false;
      sparks.emit(h.x, heightAt(h.x, h.z) + 1.5, h.z, 30, VIOLET, 6, 3, 1.4);
    }
    if (!h.alive && den.alive && h.respawn && S.t > h.respawn && h.k < den.level) {
      Object.assign(h, { alive: true, respawn: 0, x: den.x, z: den.z, fade: 0 });
    }
    h.fade = Math.min(1, h.fade + dt * (h.alive ? 0.8 : -3));
    if (!h.alive) {
      setMatrix(hollowMeshes.bodies, i, h.x, -50, h.z, 0, 0);
      setMatrix(hollowMeshes.eyes, i, h.x, -50, h.z, 0, 0);
      setMatrix(hollowMeshes.aura, i, h.x, -50, h.z, 0, 0);
      return;
    }
    const dx = pl.x - h.x, dz = pl.z - h.z, d = Math.hypot(dx, dz) || 1;
    let tx, tz, sp;
    if (h.stun > 0) {
      h.stun -= dt;
      tx = h.x - dx; tz = h.z - dz; sp = 7;
    } else if (d < 55 && !safe && h.fade > 0.9) {
      tx = pl.x; tz = pl.z; sp = 10.5 * slow;
      if (!S.hintedHollow && d < 40) {
        S.hintedHollow = true;
        hud.toast('Hollows', 'They drain carried embers. Outrun them, stay in the light, or ram them at speed.', 'warn');
      }
    } else {
      h.a += dt * 0.3;
      tx = den.x + Math.cos(h.a + h.k * 1.05) * (14 + h.k * 3);
      tz = den.z + Math.sin(h.a + h.k * 1.05) * (14 + h.k * 3);
      sp = 4;
    }
    const ex = tx - h.x, ez = tz - h.z, el = Math.hypot(ex, ez) || 1;
    h.vx += ((ex / el) * sp - h.vx) * Math.min(1, dt * 3);
    h.vz += ((ez / el) * sp - h.vz) * Math.min(1, dt * 3);
    const nx = h.x + h.vx * dt, nz = h.z + h.vz * dt;
    if (litAt(nx, nz) < 0.5 && heightAt(nx, nz) > 0.2) { h.x = nx; h.z = nz; }

    if (d < (S.inCar ? 2.9 : 1.6) && h.stun <= 0 && h.fade > 0.9 && (S.t > S.graceT || (S.inCar && speed > 13))) {
      if (S.inCar && speed > 13) {
        h.alive = false;
        h.respawn = S.t + 40;
        S.stats.banished++;
        sparks.emit(h.x, heightAt(h.x, h.z) + 1.5, h.z, 50, VIOLET, 12, 4, 1.2, 6);
        dropEmbers(h.x, h.z, 2);
        audio.banish();
        S.shake = 0.35;
      } else {
        const lost = Math.ceil(S.embers * 0.4);
        if (lost) {
          S.embers -= lost;
          S.stats.robbed++;
          dropEmbers(pl.x, pl.z, Math.floor(lost / 2));
          hud.toast(`A Hollow took ${lost} embers`, 'Some scattered nearby. Grab them before it turns back.', 'warn');
        }
        h.stun = 4;
        S.graceT = S.t + 3;
        S.hurt = 1;
        S.shake = 0.6;
        audio.hit();
        if (S.inCar) { C.vx += (dx / d) * 10; C.vz += (dz / d) * 10; } else { P.vx += (dx / d) * 14; P.vz += (dz / d) * 14; P.vy = 5; }
      }
    }
    const y = heightAt(h.x, h.z), wob = 1 + Math.sin(S.t * 7 + h.bob) * 0.06, ry = Math.atan2(h.vx, h.vz), f = h.fade;
    const bobY = y + 0.4 + Math.sin(S.t * 2.5 + h.bob) * 0.35;
    setMatrix(hollowMeshes.bodies, i, h.x, bobY, h.z, ry, wob * f, (2 - wob) * f * 1.1, wob * f, Math.sin(S.t * 3 + h.bob) * 0.12);
    setMatrix(hollowMeshes.eyes, i, h.x, bobY, h.z, ry, f, f * 1.1, f, Math.sin(S.t * 3 + h.bob) * 0.12);
    setMatrix(hollowMeshes.aura, i, h.x, y + 0.25, h.z, 0, f * (1 + 0.15 * Math.sin(S.t * 4 + h.bob)));
  });
  for (const m of Object.values(hollowMeshes)) {
    m.count = hollows.length;
    m.instanceMatrix.needsUpdate = true;
  }
  dens.forEach((d, di) => {
    if (d.alive || d.fade <= 0) return;
    d.fade = Math.max(0, d.fade - dt * 0.8);
    d.spikes.forEach((s, k) => setSpike(di * 5 + k, d, s, d.fade));
    denSpikes.instanceMatrix.needsUpdate = true;
    setDenGlow(di, d, d.fade);
    if (Math.random() < 0.5) sparks.emit(d.x, heightAt(d.x, d.z) + 2, d.z, 3, VIOLET, 5, 5, 1.2);
  });
}

function updateTraffic(dt) {
  traffic.forEach((c, k) => {
    const x = c.alongZ ? c.line - c.dir * 2.4 : c.pos, z = c.alongZ ? c.pos : c.line + c.dir * 2.4;
    const fx = c.alongZ ? 0 : c.dir, fz = c.alongZ ? c.dir : 0;
    const lit = litAt(x, z) > 0.6;
    const ahead = (C.x - x) * fx + (C.z - z) * fz, side = Math.abs((C.x - x) * fz - (C.z - z) * fx);
    const blocked = ahead > 0 && ahead < 11 && side < 2.6;
    c.speed += ((blocked ? 0 : c.top) - c.speed) * Math.min(1, dt * (blocked ? 4 : 1));
    c.pos += c.dir * c.speed * dt;
    if (c.pos > 246) c.pos = -246;
    if (c.pos < -246) c.pos = 246;
    const ry = c.alongZ ? (c.dir > 0 ? 0 : Math.PI) : c.dir > 0 ? Math.PI / 2 : -Math.PI / 2;
    const s = lit ? 1 : 0;
    setMatrix(trafficMeshes.body, k, x, heightAt(x, z), z, ry, s);
    setMatrix(trafficMeshes.lamps, k, x, heightAt(x, z), z, ry, s);
    if (lit && S.inCar) {
      const dx = C.x - x, dz = C.z - z, d = Math.hypot(dx, dz);
      if (d < 3.4 && d > 0.01) {
        C.x = x + (dx / d) * 3.4; C.z = z + (dz / d) * 3.4;
        const vn = C.vx * (dx / d) + C.vz * (dz / d);
        if (vn < 0) { C.vx -= (dx / d) * vn * 1.4; C.vz -= (dz / d) * vn * 1.4; }
      }
    }
  });
  trafficMeshes.body.instanceMatrix.needsUpdate = trafficMeshes.lamps.instanceMatrix.needsUpdate = true;
}

const tmpColor = new THREE.Color();
function updateNodes(dt, pl) {
  const yieldRate = 0.1 * (S.perks.has('yield') ? 1.5 : 1);
  let near = null;
  NODES.forEach((n, i) => {
    const st = S.nodes[i], vis = world.nodeVis[i], u = U.uNodes.value[i];
    const open = !st.lit && available(i), pinned = S.pin === i;
    if (st.lit) {
      st.stock = Math.min(S.stockCap, st.stock + yieldRate * dt);
      u.z = n.radius * ease((S.t - st.litT) / 3.5);
      if (i === BEACON) u.z = n.radius + 1500 * smoothstep(0, 12, S.t - st.litT);
    }
    const pulse = 0.65 + 0.35 * Math.sin(S.t * 3 + i);
    if (st.lit) vis.glow.color.setRGB(2.2, 1.2, 0.4);
    else if (open) vis.glow.color.setRGB(0.25 * pulse, 1.7 * pulse, 1.45 * pulse);
    else vis.glow.color.setRGB(0.3, 0.14, 0.55);
    vis.beamMat.uniforms.uColor.value.copy(vis.glow.color).multiplyScalar(st.lit ? 0.24 : open ? 0.32 : 0.3);
    if (pinned && !st.lit) vis.beamMat.uniforms.uColor.value.lerp(tmpColor.setRGB(1.1, 1.1, 1.2), 0.5);
    vis.padMat.color.copy(vis.glow.color).multiplyScalar(0.12);
    const spin = st.lit ? 1.4 : open ? 0.5 : 0.08;
    vis.rings.forEach((r, k) => {
      r.rotation.z += dt * spin * (k % 2 ? -1 : 1);
      r.rotation.x = Math.PI / 2 + Math.sin(S.t * spin + k) * 0.15;
      r.position.y = 4.5 + k * 4 + Math.sin(S.t * 1.5 + k) * 0.3 * spin;
    });
    vis.orb.visible = st.lit;
    vis.orb.scale.setScalar(0.35 + (st.stock / S.stockCap) * 1.5);
    vis.orb.rotation.y += dt;
    if (Math.hypot(pl.x - n.pos[0], pl.z - n.pos[1]) < 12) near = i;
  });
  world.cables.forEach((c) => {
    const la = S.nodes[c.a].lit, lb = S.nodes[c.b].lit;
    if (la && lb) c.mat.color.setRGB(2.4, 1.3, 0.45).multiplyScalar(0.75 + 0.25 * Math.sin(S.t * 4));
    else if (la || lb) c.mat.color.setRGB(0.08, 0.45, 0.4);
    else c.mat.color.set('#2a2740');
  });

  if (near === null) return '';
  const n = NODES[near], st = S.nodes[near], y = world.nodeVis[near].y;
  if (st.lit) {
    const take = Math.min(Math.floor(st.stock), S.cap - S.embers);
    if (take > 0) {
      st.stock -= take;
      S.embers += take;
      S.stats.gathered += take;
      audio.pickup(8);
      sparks.emit(n.pos[0], y + 18, n.pos[1], 30, AMBER, 6, -4, 1.2);
      if (take >= 3) hud.toast(`+${take} from ${n.name}`, 'Stockpiles refill over time.');
    }
    return `${n.name} · stockpile ${Math.floor(st.stock)} / ${S.stockCap}`;
  }
  if (!available(near)) return near === BEACON ? 'The Beacon needs every substation live' : `${n.name} has no live link — restore a neighbor first`;
  if (keys.has('KeyF') && S.embers > 0) {
    S.chargeAcc += dt * 26;
    while (S.chargeAcc >= 1 && S.embers > 0 && st.progress < n.cost) {
      S.chargeAcc--;
      S.embers--;
      st.progress++;
      audio.charge(st.progress / n.cost);
    }
    sparks.emit(pl.x, (S.inCar ? heightAt(pl.x, pl.z) + 2 : P.y + 1.4), pl.z, 2, AMBER, 1, 0, 0.5);
    sparks.emit(n.pos[0], y + 3 + Math.random() * 10, n.pos[1], 2, [0.4, 2, 1.7], 3, 2, 0.6);
    if (st.progress >= n.cost) restore(near);
  }
  return `Hold F — feed ${n.name}   ${Math.floor(st.progress)} / ${n.cost}`;
}

/* ---------- camera ---------- */

const lookAt = new THREE.Vector3();
function updateCamera(dt, pl, speed) {
  const now = performance.now() / 1000;
  const idle = now - cam.lastMouse > 1.4;
  if (S.inCar && idle) cam.yaw += wrapAngle(C.heading - cam.yaw) * Math.min(1, dt * 3.2);
  if (!S.inCar && idle && speed > 1) cam.yaw += wrapAngle(P.heading - cam.yaw) * Math.min(1, dt * 1.1);
  const reveal = S.dawnT === null || S.won ? 0 : smoothstep(0, 12, S.t - S.dawnT);
  if (idle) cam.pitch += ((S.inCar ? 0.26 : 0.3) + reveal * 0.35 - cam.pitch) * Math.min(1, dt * 1.5);
  let dist = (S.inCar ? 11.5 + speed * 0.07 : 7) + reveal * 40;
  const baseY = S.inCar ? heightAt(C.x, C.z) + 1.8 : P.y + 1.7;
  lookAt.set(pl.x, baseY, pl.z);
  for (let f = 0.2; f <= 1; f += 0.1) {
    const bx = pl.x - Math.sin(cam.yaw) * dist * f, bz = pl.z - Math.cos(cam.yaw) * dist * f;
    if (collide(bx, bz, 0.5, true).hit) { dist *= Math.max(0.25, f - 0.1); break; }
  }
  const cx = pl.x - Math.sin(cam.yaw) * Math.cos(cam.pitch) * dist;
  const cz = pl.z - Math.cos(cam.yaw) * Math.cos(cam.pitch) * dist;
  let cy = baseY + Math.sin(cam.pitch) * dist + 1.2;
  cy = Math.max(cy, heightAt(cx, cz) + 1.2);
  camera.position.lerp(v3.set(cx, cy, cz), 1 - Math.exp(-dt * (S.inCar ? 9 : 12)));
  const sh = S.shake * S.shake;
  camera.position.x += (Math.random() - 0.5) * sh * 1.2;
  camera.position.y += (Math.random() - 0.5) * sh * 1.2;
  camera.lookAt(lookAt);
  const fov = 60 + (S.inCar ? speed * 0.42 : 0);
  cam.fov += (fov - cam.fov) * Math.min(1, dt * 3);
  camera.fov = cam.fov;
  camera.updateProjectionMatrix();
}

/* ---------- hud ---------- */

const marker = $('marker');
function updateHud(prompt, pl) {
  hud.setText('emberCount', String(S.embers));
  hud.setText('emberCap', String(S.cap));
  $('emberBar').style.width = `${(S.embers / S.cap) * 100}%`;
  $('boostWrap').style.opacity = S.inCar ? 1 : 0;
  $('boostBar').style.width = `${S.boost * 100}%`;
  hud.setText('speed', `${Math.round(Math.abs(C.vf) * 3.6)} km/h`);
  hud.setText('clock', fmtTime(S.t));
  hud.setText('grid', `${S.nodes.filter((n) => n.lit).length - 1} / ${NODES.length - 1} restored`);

  if (!prompt && !S.inCar && Math.hypot(P.x - C.x, P.z - C.z) < 4.8) prompt = 'E — drive';
  hud.setText('prompt', prompt);
  $('prompt').classList.toggle('show', !!prompt);
  $('hurt').style.opacity = S.hurt;

  if (S.pin !== null && !S.nodes[S.pin].lit) {
    const n = NODES[S.pin], st = S.nodes[S.pin], need = n.cost - Math.floor(st.progress);
    const d = Math.round(Math.hypot(n.pos[0] - pl.x, n.pos[1] - pl.z));
    hud.setText('objTitle', n.name);
    hud.setText('objSub', !available(S.pin)
      ? S.pin === BEACON ? `Restore every substation first · ${S.nodes.filter((x) => x.lit).length - 1} / ${NODES.length - 2}` : 'No live link yet — restore a neighbor first'
      : S.embers >= need ? `You carry enough. Bring ${need} embers in · ${d} m` : `Needs ${need} embers · you carry ${S.embers} · ${d} m`);
    v3.set(n.pos[0], world.nodeVis[S.pin].y + 22, n.pos[1]).project(camera);
    const sx = (v3.x * 0.5 + 0.5) * innerWidth, sy = (-v3.y * 0.5 + 0.5) * innerHeight;
    const onScreen = v3.z < 1 && sx > 30 && sx < innerWidth - 30 && sy > 100 && sy < innerHeight - 40;
    marker.style.transform = `translate(${sx}px, ${sy}px)`;
    hud.setText('markerDist', `${d} m`);
    marker.style.opacity = onScreen ? 1 : 0;
  } else {
    hud.setText('objTitle', S.won ? 'Morning in Halcyon County' : 'Roam the county');
    hud.setText('objSub', S.won ? 'The grid holds. Wander as long as you like.' : 'Press M to plan your next link.');
    marker.style.opacity = 0;
  }
}

function mapView(pl) {
  return {
    nodes: S.nodes, available, pin: S.pin, t: S.t, dawn: U.uDawn.value, uniforms: U.uNodes.value,
    player: { x: pl.x, z: pl.z, heading: S.inCar ? C.heading : P.heading }, car: C, inCar: S.inCar, camYaw: cam.yaw,
    embers: embers.filter((e) => e.alive), radarAll: S.perks.has('radar'), radarRange: 90,
    hollows: hollows.filter((h) => h.alive),
  };
}

/* ---------- loop ---------- */

reset(20261101);
const clock = new THREE.Clock();
let titleT = 0, lastSteam = 0;

function frame() {
  const dt = Math.min(clock.getDelta(), 1 / 20);
  const running = mode === 'play' && !mapOpen;

  if (mode === 'title') {
    titleT += dt * 0.05;
    camera.position.set(Math.sin(titleT) * 300, 120 + Math.sin(titleT * 0.7) * 20, Math.cos(titleT) * 300 + 60);
    camera.lookAt(0, 20, 40);
    walker.root.position.set(P.x, P.y, P.z);
    car.root.position.set(C.x, heightAt(C.x, C.z), C.z);
    car.root.rotation.y = C.heading;
    S.t += dt;
    const far = { x: 1e5, z: 1e5 };
    updateEmbers(dt, far);
    updateHollows(dt, far, 0);
    updateNodes(dt, far);
  }

  if (running) {
    S.t += dt;
    const speed = S.inCar ? updateCar(dt) : updateWalker(dt);
    if (S.inCar) { P.x = C.x; P.z = C.z; P.y = heightAt(C.x, C.z); }
    const pl = S.inCar ? C : P;
    walker.root.visible = !S.inCar;
    updateEmbers(dt, pl);
    updateHollows(dt, pl, speed);
    updateTraffic(dt);
    const prompt = updateNodes(dt, pl);
    updateCamera(dt, pl, speed);
    updateHud(prompt, pl);
    S.hurt = Math.max(0, S.hurt - dt * 1.5);
    S.shake = Math.max(0, S.shake - dt * 2);
    carryLight.position.set(pl.x, heightAt(pl.x, pl.z) + 7, pl.z);
    carryLight.intensity = 14 + S.embers * 1.2;
    car.tankMat.color.setRGB(0.15 + (S.embers / S.cap) * 1.8, 0.08 + (S.embers / S.cap) * 0.95, 0.03 + (S.embers / S.cap) * 0.25);
    if (S.dawnT !== null) {
      const k = smoothstep(0, 12, S.t - S.dawnT);
      U.uDawn.value = k;
      if (k >= 1 && !S.won) win();
    }
    if (shock.visible) {
      const a = S.t - shock.userData.t0;
      shock.scale.setScalar(4 + a * 110);
      shock.material.opacity = Math.max(0, 1 - a / 2.4);
      shock.visible = a < 2.4;
    }
    hud.drawMini(mapView(pl));
  }
  if (mapOpen) hud.drawMap(mapView(S.inCar ? C : P));

  const d = U.uDawn.value;
  scene.fog.color.copy(NIGHT_FOG).lerp(DAWN_FOG, d);
  hemi.intensity = 2.2 + d * 1.2;
  hemi.color.set('#6a6fc0').lerp(tmpColor.set('#ffd9c0'), d);
  moon.color.set('#a9b6ff').lerp(tmpColor.set('#ffb27a'), d);
  moon.intensity = 1.3 + d * 2;

  const t = performance.now() / 1000;
  if (t - lastSteam > 0.12) {
    lastSteam = t;
    for (const [x, y, z] of world.steam) smoke.emit(x + (Math.random() - 0.5) * 8, y, z + (Math.random() - 0.5) * 8, 1, STEAM, 2, 4, 5);
  }
  world.update(t, dt, camera.position);
  sparks.update(dt);
  smoke.update(dt);
  composer.render();
  requestAnimationFrame(frame);
}

$('loading').remove();
requestAnimationFrame(frame);
