// engine.mjs — motor 3D primera persona de "The Bathrooms".
// Streaming de chunks del laberinto (maze-core), render low-poly instanciado desde los
// datos del protocolo (window.GAME), luces fluorescentes parpadeantes (fx-logic.lightState),
// charcos reflectantes, niebla densa, camara FPS con pointer lock y colision, todo
// entregado a traves del pase VHS y el paisaje sonoro sintetizado.
import * as THREE from 'three';
import { generateChunk, chunksInRadius, resolveMovement } from './maze-core.mjs';
import { lightState, attenuation } from './fx-logic.mjs';
import { createVHS } from './vhs.mjs';
import { createAudio } from './audio.mjs';

// Mundo 100% determinista: una unica seed constante (nada de Math.random en la generacion).
const SEED = 0x0BA7;
const VOX = 0.25; // 1 voxel = 0.25m (celda = 2m)

// Zumbido (hum) local a la luz viva mas cercana: pleno bajo la luz, apagado a HUM_MAX.
const HUM_REF = 1.0; // m: dentro de este radio el hum toma toda la intensidad de la luz
const HUM_MAX = 6.0; // m: a esta distancia la contribucion de esa luz al hum se anula

// tipo de prop de maze-core -> estructura de GAME.VOXELS (null = sin malla).
// v3: shower/dryer/mop_bucket/bench de la variedad de salas nueva. Si el artefacto aun no
// trajera alguna, buildStruct devuelve null y el prop se omite (degradacion con gracia).
const PROP_STRUCT = {
  stall: 'stall_unit', sink: 'sink_unit', mirror: 'sink_unit',
  urinal: 'urinal_unit', dispenser: 'dispenser_empty', bin: 'bin_full', pipes: null,
  shower: 'shower_unit', dryer: 'dryer_unit', mop_bucket: 'mop_bucket', bench: 'bench_unit',
};
const TOILET = 'toilet_unit'; // estructura v2 (si el artefacto aun no la trae, degrada a stall_unit)

// v3: tinte sutil del piso por tipo de sala (multiplica el mapa de azulejo; blanco = neutro).
// 5=duchas (frio/verdoso humedo), 6=limpieza/vestuario (calido apagado).
const FLOOR_TINT = { 5: [0.80, 0.90, 0.85], 6: [0.92, 0.86, 0.78] };

function clamp(v, lo, hi) { return v < lo ? lo : (v > hi ? hi : v); }
function rgb(GAME, name) {
  const c = (GAME.MATERIALS[name] || { color: [255, 0, 255] }).color;
  return new THREE.Color(c[0] / 255, c[1] / 255, c[2] / 255);
}
// id estable por celda mundial (para lightState): entero no negativo
function stableId(wx, wz) { return (Math.imul(wx, 73856093) ^ Math.imul(wz, 19349663)) >>> 0; }

// mini-textura procedural de azulejo con lineas de GROUT (sin assets)
function tileTexture(base, grout) {
  const s = 64;
  const cv = document.createElement('canvas');
  cv.width = cv.height = s;
  const g = cv.getContext('2d');
  g.fillStyle = 'rgb(' + base[0] + ',' + base[1] + ',' + base[2] + ')';
  g.fillRect(0, 0, s, s);
  g.strokeStyle = 'rgb(' + grout[0] + ',' + grout[1] + ',' + grout[2] + ')';
  g.lineWidth = 5;
  g.strokeRect(0, 0, s, s);
  g.fillStyle = 'rgba(' + grout[0] + ',' + grout[1] + ',' + grout[2] + ',0.28)';
  g.fillRect(s * 0.62, s * 0.12, 11, 9); // mancha de moho
  const t = new THREE.CanvasTexture(cv);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  return t;
}

// cache de geometrias/materiales por tipo, creado una vez y reusado entre chunks
function makeCache(GAME, P, cs) {
  const wallTex = tileTexture(GAME.MATERIALS.TILE_WALL.color, GAME.MATERIALS.GROUT.color);
  wallTex.repeat.set(1, 2);
  const floorTex = tileTexture(GAME.MATERIALS.TILE_FLOOR.color, GAME.MATERIALS.GROUT.color);
  floorTex.repeat.set(2, 2);
  return {
    geo: {
      wall: new THREE.BoxGeometry(cs, P.wallHeight, cs),
      floor: new THREE.BoxGeometry(cs, 0.1, cs),
      ceil: new THREE.BoxGeometry(cs, 0.1, cs),
      water: new THREE.BoxGeometry(cs, 0.06, cs),
      vox: new THREE.BoxGeometry(VOX, VOX, VOX),
      circ: new THREE.CircleGeometry(1, 18),
    },
    mat: {
      wall: new THREE.MeshStandardMaterial({ map: wallTex, roughness: 0.96 }),
      floor: new THREE.MeshStandardMaterial({ map: floorTex, roughness: 0.9 }),
      ceil: new THREE.MeshStandardMaterial({ color: rgb(GAME, 'CEILING'), roughness: 1 }),
      water: new THREE.MeshStandardMaterial({ color: rgb(GAME, 'WATER'), roughness: 0.15, metalness: 0.6, transparent: true, opacity: 0.85 }),
      puddle: new THREE.MeshStandardMaterial({ color: rgb(GAME, 'WATER'), roughness: 0.08, metalness: 0.85 }),
      prop: new THREE.MeshStandardMaterial({ roughness: 0.85, metalness: 0.05 }),
      fix: new THREE.MeshStandardMaterial({ roughness: 0.5, emissive: rgb(GAME, 'LIGHT_ON'), emissiveIntensity: 0.55 }),
    },
  };
}

// InstancedMesh de cajas identicas (solo traslacion) a partir de una lista [mx, mz].
// colors (opcional): tinte por instancia (array [r,g,b] 0..1 o null) para variar salas.
function instBoxes(geo, mat, list, y, colors) {
  if (!list.length) return null;
  const mesh = new THREE.InstancedMesh(geo, mat, list.length);
  const m = new THREE.Matrix4();
  for (let i = 0; i < list.length; i++) { m.makeTranslation(list[i][0], y, list[i][1]); mesh.setMatrixAt(i, m); }
  mesh.instanceMatrix.needsUpdate = true;
  if (colors) {
    const col = new THREE.Color();
    for (let i = 0; i < colors.length; i++) {
      const c = colors[i] || [1, 1, 1];
      col.setRGB(c[0], c[1], c[2]);
      mesh.setColorAt(i, col);
    }
    if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
  }
  return mesh;
}

// paredes / piso / techo / agua de un chunk (cada categoria = 1 InstancedMesh)
function buildCells(GAME, chunk, cs, cache, P) {
  const size = chunk.size;
  const wall = [], floor = [], floorCol = [], ceil = [], water = [];
  for (let dz = 0; dz < size; dz++) {
    for (let dx = 0; dx < size; dx++) {
      const v = chunk.cells[dz * size + dx];
      const mx = (chunk.cx * size + dx + 0.5) * cs;
      const mz = (chunk.cz * size + dz + 0.5) * cs;
      if (v === 0) { wall.push([mx, mz]); continue; }
      floor.push([mx, mz]); ceil.push([mx, mz]);
      floorCol.push(FLOOR_TINT[v] || null); // tinte sutil en salas de duchas (5)/limpieza (6)
      if (v === 4 || v === 5) water.push([mx, mz]); // tipo 5: piso mojado reflectivo extra
    }
  }
  return [
    instBoxes(cache.geo.wall, cache.mat.wall, wall, P.wallHeight / 2),
    instBoxes(cache.geo.floor, cache.mat.floor, floor, -0.05, floorCol),
    instBoxes(cache.geo.ceil, cache.mat.ceil, ceil, P.wallHeight + 0.05),
    instBoxes(cache.geo.water, cache.mat.water, water, 0.05),
  ];
}

// InstancedMesh que replica los voxels de una estructura para cada emplazamiento
// (placements: [{wx, wz, rot}] en coords de celda mundial). Nunca 1 Mesh por voxel.
function buildStruct(GAME, name, places, cs, baseY, geoVox, mat) {
  const st = GAME.VOXELS[name];
  if (!st || !places.length) return null;
  const vox = st.voxels, half = cs / 2;
  const mesh = new THREE.InstancedMesh(geoVox, mat, places.length * vox.length);
  const m = new THREE.Matrix4(), rotM = new THREE.Matrix4(), off = new THREE.Vector3(), col = new THREE.Color();
  let i = 0;
  for (const pl of places) {
    // ROTACION REAL: makeRotationY(90*rot) sobre el offset centrado, luego traslacion al
    // centro de la celda. rot 0..3 => frente hacia +z,+x,-z,-x (estructuras disenadas a +z).
    rotM.makeRotationY((pl.rot || 0) * Math.PI / 2);
    const cxm = pl.wx * cs + half, czm = pl.wz * cs + half;
    for (const v of vox) {
      off.set(v.x * VOX + VOX / 2 - half, 0, v.z * VOX + VOX / 2 - half).applyMatrix4(rotM);
      m.makeTranslation(cxm + off.x, baseY + v.y * VOX + VOX / 2, czm + off.z);
      mesh.setMatrixAt(i, m);
      const rc = (GAME.MATERIALS[v.m] || { color: [255, 0, 255] }).color;
      col.setRGB(rc[0] / 255, rc[1] / 255, rc[2] / 255);
      mesh.setColorAt(i, col);
      i++;
    }
  }
  mesh.instanceMatrix.needsUpdate = true;
  if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
  return mesh;
}

// ~25% de los 'stall' pasan a toilet_unit (cubiculo roto con retrete expuesto),
// deterministicamente por celda mundial mezclada con la seed. Degrada a stall_unit si el
// artefacto todavia no define toilet_unit.
function stallStruct(GAME, wx, wz) {
  if (GAME.VOXELS[TOILET] && (Math.imul(stableId(wx, wz) ^ SEED, 2654435761) >>> 30) === 0) return TOILET;
  return 'stall_unit';
}

// mobiliario del chunk: agrupar props por estructura y una InstancedMesh por grupo
function buildProps(GAME, chunk, cs, cache) {
  const size = chunk.size, groups = {};
  for (const p of chunk.props) {
    const wx = chunk.cx * size + p.x, wz = chunk.cz * size + p.z;
    let name = PROP_STRUCT[p.type];
    if (name === 'stall_unit') name = stallStruct(GAME, wx, wz);
    if (!name) continue;
    (groups[name] || (groups[name] = [])).push({ wx, wz, rot: p.rot });
  }
  const out = [];
  for (const name in groups) {
    const m = buildStruct(GAME, name, groups[name], cs, 0, cache.geo.vox, cache.mat.prop);
    if (m) out.push(m);
  }
  return out;
}

// luces del chunk: fixtures visuales + entradas para la iluminacion dinamica
function buildLights(GAME, chunk, cs, cache, P) {
  const size = chunk.size;
  const places = [], entries = [];
  for (const l of chunk.lights) {
    const wx = chunk.cx * size + l.x, wz = chunk.cz * size + l.z;
    places.push({ wx, wz, rot: 0 });
    entries.push({ mx: (wx + 0.5) * cs, mz: (wz + 0.5) * cs, id: stableId(wx, wz) });
  }
  const mesh = buildStruct(GAME, 'light_fixture', places, cs, P.wallHeight - 2 * VOX, cache.geo.vox, cache.mat.fix);
  return { mesh, entries };
}

// charcos: discos brillantes horizontales (InstancedMesh de circulos escalados)
function buildPuddles(chunk, cs, cache) {
  const size = chunk.size, list = chunk.puddles;
  const mesh = new THREE.InstancedMesh(cache.geo.circ, cache.mat.puddle, list.length);
  const m = new THREE.Matrix4();
  const q = new THREE.Quaternion().setFromEuler(new THREE.Euler(-Math.PI / 2, 0, 0));
  const pos = new THREE.Vector3(), scl = new THREE.Vector3();
  const centers = [];
  for (let i = 0; i < list.length; i++) {
    const p = list[i];
    const wx = chunk.cx * size + p.x, wz = chunk.cz * size + p.z;
    const r = (p.r || 0.3) * cs, mx = (wx + 0.5) * cs, mz = (wz + 0.5) * cs;
    pos.set(mx, 0.03, mz); scl.set(r, r, 1);
    m.compose(pos, q, scl); mesh.setMatrixAt(i, m);
    centers.push({ mx, mz, r });
  }
  mesh.instanceMatrix.needsUpdate = true;
  return { mesh, centers };
}

function buildChunk(GAME, chunk, cs, cache, P) {
  const group = new THREE.Group();
  for (const m of buildCells(GAME, chunk, cs, cache, P)) if (m) group.add(m);
  for (const m of buildProps(GAME, chunk, cs, cache)) group.add(m);
  const lg = buildLights(GAME, chunk, cs, cache, P);
  if (lg.mesh) group.add(lg.mesh);
  const pud = buildPuddles(chunk, cs, cache);
  group.add(pud.mesh);
  return { group, lights: lg.entries, puddles: pud.centers };
}

function disposeGroup(group) {
  group.traverse((o) => { if (o.isInstancedMesh && o.dispose) o.dispose(); });
}

// ---------------------------------------------------------------------------

export function startGame(opts) {
  const GAME = (opts && opts.GAME) || window.GAME;
  const P = GAME.platform, cs = P.cellSize;
  const mount = (opts && opts.mount) || document.body;
  const overlay = opts && opts.overlay;

  const renderer = new THREE.WebGLRenderer({ antialias: false });
  renderer.setPixelRatio(1);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.autoClear = false;
  mount.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const fogCol = rgb(GAME, 'MOLD');
  scene.fog = new THREE.FogExp2(fogCol.getHex(), 0.085);
  scene.background = fogCol.clone().multiplyScalar(0.35);
  scene.add(new THREE.AmbientLight(0x0a0c08, 0.2));

  const camera = new THREE.PerspectiveCamera(72, window.innerWidth / window.innerHeight, 0.05, 60);
  camera.rotation.order = 'YXZ';

  const cache = makeCache(GAME, P, cs);
  const vhs = createVHS(THREE, renderer, mount, GAME);
  const audio = createAudio(GAME);

  // pool de PointLights dinamicas asignadas a las luces mas cercanas
  // Alcance/decay algo mayores para reconocer siluetas a 4-6 m de un fixture VIVO; las
  // luces muertas siguen en 0 => las zonas muertas conservan su oscuridad opresiva.
  const pool = [];
  for (let i = 0; i < 8; i++) {
    const L = new THREE.PointLight(rgb(GAME, 'LIGHT_ON').getHex(), 0, cs * 6, 1.7);
    scene.add(L); pool.push(L);
  }

  const state = { px: 0.5, pz: 0.5, yaw: 0, pitch: 0, bob: 0, dist: 0, started: false };
  const keys = {};
  const loaded = new Map();
  let gLights = [], gPuddles = [];

  window.addEventListener('keydown', (e) => { keys[e.code] = true; });
  window.addEventListener('keyup', (e) => { keys[e.code] = false; });
  document.addEventListener('mousemove', (e) => {
    if (document.pointerLockElement !== renderer.domElement) return;
    state.yaw -= e.movementX * 0.0022;
    state.pitch = clamp(state.pitch - e.movementY * 0.0022, -1.4, 1.4);
  });
  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    vhs.setSize(window.innerWidth, window.innerHeight);
  });

  function enter() {
    if (state.started) return;
    state.started = true;
    if (overlay) overlay.style.display = 'none';
    renderer.domElement.requestPointerLock();
    audio.start();
  }
  (overlay || renderer.domElement).addEventListener('click', enter);

  function syncChunks() {
    const want = chunksInRadius(state.px, state.pz, P.viewChunks, { chunkSize: P.chunkSize });
    const wanted = new Set(want.map((c) => c.cx + ',' + c.cz));
    for (const c of want) {
      const k = c.cx + ',' + c.cz;
      if (loaded.has(k)) continue;
      const data = generateChunk(SEED, c.cx, c.cz, { chunkSize: P.chunkSize });
      const built = buildChunk(GAME, data, cs, cache, P);
      scene.add(built.group);
      loaded.set(k, built);
    }
    for (const k of [...loaded.keys()]) {
      if (wanted.has(k)) continue;
      const b = loaded.get(k);
      scene.remove(b.group); disposeGroup(b.group); loaded.delete(k);
    }
  }

  function aggregate() {
    gLights = []; gPuddles = [];
    for (const b of loaded.values()) { gLights.push(...b.lights); gPuddles.push(...b.puddles); }
  }

  function updateLights(tMs) {
    const px = state.px * cs, pz = state.pz * cs;
    gLights.sort((a, b) => (a.mx - px) * (a.mx - px) + (a.mz - pz) * (a.mz - pz)
      - ((b.mx - px) * (b.mx - px) + (b.mz - pz) * (b.mz - pz)));
    for (let i = 0; i < pool.length; i++) {
      const e = gLights[i];
      if (!e) { pool[i].intensity = 0; continue; }
      pool[i].position.set(e.mx, P.wallHeight - 0.4, e.mz);
      pool[i].intensity = lightState(SEED, e.id, tMs).intensity * 4.5;
    }
  }

  // Nivel 0..1 del zumbido: intensidad (flicker-aware) de la luz VIVA mas cercana atenuada
  // por su distancia. Casi 0 lejos de toda luz; sigue el parpadeo de una luz flicker.
  function humLevel(tMs) {
    const px = state.px * cs, pz = state.pz * cs;
    let bestD = Infinity, level = 0;
    for (const e of gLights) {
      const st = lightState(SEED, e.id, tMs);
      if (st.mode === 'dead') continue; // las luces muertas no zumban
      const d = Math.hypot(e.mx - px, e.mz - pz);
      if (d >= bestD) continue;
      bestD = d;
      level = st.intensity * attenuation(d, HUM_REF, HUM_MAX);
    }
    return level;
  }

  function nearPuddle() {
    const px = state.px * cs, pz = state.pz * cs;
    for (const c of gPuddles) if (Math.hypot(c.mx - px, c.mz - pz) < c.r + 0.7) return true;
    return false;
  }

  function move(dt) {
    const f = (keys.KeyW ? 1 : 0) - (keys.KeyS ? 1 : 0);
    const r = (keys.KeyD ? 1 : 0) - (keys.KeyA ? 1 : 0);
    if (!f && !r) return;
    const y = state.yaw;
    let mx = -Math.sin(y) * f + Math.cos(y) * r;
    let mz = -Math.cos(y) * f - Math.sin(y) * r;
    const len = Math.hypot(mx, mz) || 1; mx /= len; mz /= len;
    const run = (keys.ShiftLeft || keys.ShiftRight) ? 1.7 : 1;
    const spd = (P.playerSpeed / cs) * run * dt;
    const np = resolveMovement(SEED, { x: state.px, z: state.pz }, { x: mx * spd, z: mz * spd }, P.playerRadius);
    state.px = np.x; state.pz = np.z;
    state.dist += spd * cs; state.bob += spd * 7;
    if (state.dist > 0.9) { state.dist = 0; audio.footstep(nearPuddle()); }
  }

  function updateCamera() {
    camera.position.set(state.px * cs, P.eyeHeight + Math.sin(state.bob) * 0.05, state.pz * cs);
    camera.rotation.set(state.pitch, state.yaw, 0);
  }

  const clock = new THREE.Clock();
  function frame() {
    const dt = Math.min(clock.getDelta(), 0.05);
    const tMs = performance.now();
    if (state.started) move(dt);
    syncChunks();
    aggregate();
    updateLights(tMs);
    updateCamera();
    audio.update(tMs, humLevel(tMs));
    vhs.render(scene, camera, tMs);
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);

  return { scene, camera, renderer, state };
}
