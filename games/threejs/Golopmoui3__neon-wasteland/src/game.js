// ============================================================================
//  NEON WASTELAND — процедурный 3D шутер на выживание
//  Открытый мир · Волны врагов · Боссы · Лут · Прокачка · Магазин · Квесты
// ============================================================================
import * as THREE from 'three';

// ---------------------------------------------------------------------------
// УТИЛИТЫ
// ---------------------------------------------------------------------------
const rand = (a, b) => a + Math.random() * (b - a);
const randi = (a, b) => Math.floor(rand(a, b + 1));
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, t) => a + (b - a) * t;
const smoothstep = (a, b, x) => { const t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); };
const V3 = (x = 0, y = 0, z = 0) => new THREE.Vector3(x, y, z);

// --- Детерминированный шум для рельефа ---
function hash2(x, z) { const s = Math.sin(x * 127.1 + z * 311.7) * 43758.5453; return s - Math.floor(s); }
function vnoise(x, z) {
  const ix = Math.floor(x), iz = Math.floor(z);
  const fx = x - ix, fz = z - iz;
  const ux = fx * fx * (3 - 2 * fx), uz = fz * fz * (3 - 2 * fz);
  const a = hash2(ix, iz), b = hash2(ix + 1, iz), c = hash2(ix, iz + 1), d = hash2(ix + 1, iz + 1);
  return lerp(lerp(a, b, ux), lerp(c, d, ux), uz);
}
function fbm(x, z) {
  let v = 0, amp = 0.5, f = 1;
  for (let i = 0; i < 4; i++) { v += amp * vnoise(x * f, z * f); amp *= 0.5; f *= 2.1; }
  return v;
}
function terrainH(x, z) {
  const d = Math.sqrt(x * x + z * z);
  let h = (fbm(x * 0.008 + 13.7, z * 0.008 + 91.2) - 0.5) * 36
        + (fbm(x * 0.03 + 4.2, z * 0.03 + 7.7) - 0.5) * 10
        + (fbm(x * 0.11, z * 0.11) - 0.5) * 2.2;
  h *= smoothstep(24, 60, d);                       // плоская арена в центре
  h += smoothstep(235, 300, d) * 55;                // горы по краю мира
  return h;
}

// ---------------------------------------------------------------------------
// АУДИО (синтез, без файлов)
// ---------------------------------------------------------------------------
const SFX = (() => {
  let ctx = null, master = null, noiseBuf = null;
  function init() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return; }
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    master = ctx.createGain(); master.gain.value = 0.16; master.connect(ctx.destination);
    noiseBuf = ctx.createBuffer(1, ctx.sampleRate * 1, ctx.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  function tone(f0, f1, dur, type = 'square', vol = 0.5, delay = 0) {
    if (!ctx) return;
    if (ctx.state === 'suspended') ctx.resume();
    const t = ctx.currentTime + delay;
    const o = ctx.createOscillator(), g = ctx.createGain();
    o.type = type; o.frequency.setValueAtTime(f0, t);
    o.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t + dur);
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    o.connect(g); g.connect(master);
    o.onended = () => { try { g.disconnect(); o.disconnect(); } catch (_) {} };
    o.start(t); o.stop(t + dur + 0.02);
  }
  function noise(dur, vol = 0.5, freq = 800, delay = 0) {
    if (!ctx) return;
    if (ctx.state === 'suspended') ctx.resume();
    const t = ctx.currentTime + delay;
    const s = ctx.createBufferSource(); s.buffer = noiseBuf; s.loop = true;
    const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = freq;
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    s.connect(f); f.connect(g); g.connect(master);
    s.onended = () => { try { f.disconnect(); g.disconnect(); s.disconnect(); } catch (_) {} };
    s.start(t); s.stop(t + dur + 0.02);
  }
  return {
    init,
    shootPistol() { tone(900, 240, 0.09, 'square', 0.35); },
    shootShotgun() { noise(0.18, 0.7, 900); tone(220, 60, 0.16, 'sawtooth', 0.4); },
    shootRail() { tone(1600, 80, 0.4, 'sawtooth', 0.5); noise(0.3, 0.4, 3000); },
    hit() { tone(300, 180, 0.06, 'triangle', 0.3); },
    kill() { noise(0.25, 0.5, 500); tone(400, 50, 0.3, 'sawtooth', 0.35); },
    hurt() { tone(130, 60, 0.22, 'sawtooth', 0.55); },
    pickup() { tone(660, 990, 0.1, 'sine', 0.4); tone(990, 1320, 0.1, 'sine', 0.3, 0.07); },
    levelup() { [523, 659, 784, 1047].forEach((f, i) => tone(f, f, 0.14, 'square', 0.3, i * 0.09)); },
    buy() { tone(880, 880, 0.08, 'sine', 0.4); tone(1175, 1175, 0.12, 'sine', 0.4, 0.08); },
    error() { tone(220, 110, 0.2, 'square', 0.35); },
    wave() { tone(196, 392, 0.5, 'sawtooth', 0.35); },
    boss() { tone(80, 40, 1.2, 'sawtooth', 0.7); noise(1.0, 0.5, 300); },
    empty() { tone(700, 500, 0.05, 'square', 0.15); },
    spit() { tone(500, 200, 0.15, 'triangle', 0.3); },
  };
})();

// ---------------------------------------------------------------------------
// РЕНДЕР / СЦЕНА
// ---------------------------------------------------------------------------
const canvas = document.createElement('canvas');
document.body.appendChild(canvas);
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
renderer.setSize(innerWidth, innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.1;

const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x06030f, 0.0055);
const camera = new THREE.PerspectiveCamera(72, innerWidth / innerHeight, 0.1, 1500);
camera.rotation.order = 'YXZ';
scene.add(camera);

// --- Процедурные 3D-модели оружия от первого лица (FPS Viewmodel) ---
const weaponHolder = new THREE.Group();
camera.add(weaponHolder);
weaponHolder.position.set(0.28, -0.24, -0.48);
let weaponRecoil = 0, weaponRecoilRot = 0;
const weaponMeshes = [];

{
  // 1. Плазма-пистолет
  const grp = new THREE.Group();
  const body = new THREE.Mesh(
    new THREE.BoxGeometry(0.065, 0.09, 0.32),
    new THREE.MeshStandardMaterial({ color: 0x151825, metalness: 0.8, roughness: 0.3 })
  );
  grp.add(body);
  const core = new THREE.Mesh(
    new THREE.BoxGeometry(0.025, 0.025, 0.33),
    new THREE.MeshBasicMaterial({ color: 0x00ffff })
  );
  core.position.set(0, 0.025, -0.01);
  grp.add(core);
  const grip = new THREE.Mesh(
    new THREE.BoxGeometry(0.05, 0.14, 0.07),
    new THREE.MeshStandardMaterial({ color: 0x0a0c14, roughness: 0.7 })
  );
  grip.position.set(0, -0.09, 0.08);
  grip.rotation.x = -0.35;
  grp.add(grip);
  const neon = new THREE.Mesh(
    new THREE.BoxGeometry(0.068, 0.012, 0.12),
    new THREE.MeshBasicMaterial({ color: 0x00ffff })
  );
  neon.position.set(0, 0.01, 0.02);
  grp.add(neon);
  weaponHolder.add(grp);
  weaponMeshes.push(grp);
}
{
  // 2. Дробовик «Гром»
  const grp = new THREE.Group();
  const b1 = new THREE.Mesh(
    new THREE.CylinderGeometry(0.026, 0.026, 0.44, 8),
    new THREE.MeshStandardMaterial({ color: 0x1e1820, metalness: 0.85, roughness: 0.25 })
  );
  b1.rotation.x = Math.PI / 2;
  b1.position.set(-0.026, 0.015, -0.05);
  grp.add(b1);
  const b2 = b1.clone();
  b2.position.set(0.026, 0.015, -0.05);
  grp.add(b2);
  const rec = new THREE.Mesh(
    new THREE.BoxGeometry(0.1, 0.11, 0.24),
    new THREE.MeshStandardMaterial({ color: 0x241410, metalness: 0.6, roughness: 0.4 })
  );
  rec.position.set(0, -0.01, 0.14);
  grp.add(rec);
  const heat = new THREE.Mesh(
    new THREE.BoxGeometry(0.088, 0.018, 0.28),
    new THREE.MeshBasicMaterial({ color: 0xff8800 })
  );
  heat.position.set(0, 0.045, -0.05);
  grp.add(heat);
  const grip = new THREE.Mesh(
    new THREE.BoxGeometry(0.055, 0.15, 0.08),
    new THREE.MeshStandardMaterial({ color: 0x0d0d12, roughness: 0.8 })
  );
  grip.position.set(0, -0.11, 0.18);
  grip.rotation.x = -0.3;
  grp.add(grip);
  grp.visible = false;
  weaponHolder.add(grp);
  weaponMeshes.push(grp);
}
{
  // 3. Рельсотрон «Копьё»
  const grp = new THREE.Group();
  const rail1 = new THREE.Mesh(
    new THREE.BoxGeometry(0.022, 0.038, 0.58),
    new THREE.MeshStandardMaterial({ color: 0x181024, metalness: 0.9, roughness: 0.2 })
  );
  rail1.position.set(-0.034, 0.01, -0.1);
  grp.add(rail1);
  const rail2 = rail1.clone();
  rail2.position.set(0.034, 0.01, -0.1);
  grp.add(rail2);
  const beam = new THREE.Mesh(
    new THREE.BoxGeometry(0.024, 0.024, 0.54),
    new THREE.MeshBasicMaterial({ color: 0xff00ff })
  );
  beam.position.set(0, 0.01, -0.1);
  grp.add(beam);
  for (let k = 0; k < 4; k++) {
    const ring = new THREE.Mesh(
      new THREE.BoxGeometry(0.11, 0.08, 0.028),
      new THREE.MeshBasicMaterial({ color: 0xff00ff })
    );
    ring.position.set(0, 0.01, -0.28 + k * 0.11);
    grp.add(ring);
  }
  const stock = new THREE.Mesh(
    new THREE.BoxGeometry(0.085, 0.13, 0.26),
    new THREE.MeshStandardMaterial({ color: 0x100a18, metalness: 0.7, roughness: 0.4 })
  );
  stock.position.set(0, -0.03, 0.22);
  grp.add(stock);
  grp.visible = false;
  weaponHolder.add(grp);
  weaponMeshes.push(grp);
}

function updateWeaponViewModel() {
  for (let i = 0; i < weaponMeshes.length; i++) {
    weaponMeshes[i].visible = (i === weaponState.cur);
  }
}

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

// --- Свет ---
const hemi = new THREE.HemisphereLight(0x4466ff, 0x110522, 0.7);
scene.add(hemi);
const sun = new THREE.DirectionalLight(0xaaccff, 1.2);
scene.add(sun);
const sunOrb = new THREE.Mesh(
  new THREE.SphereGeometry(18, 16, 16),
  new THREE.MeshBasicMaterial({ color: 0xffd9a0, fog: false })
);
scene.add(sunOrb);

// --- Звёзды ---
{
  const n = 900, pos = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) {
    const th = Math.random() * Math.PI * 2, ph = Math.acos(rand(0.1, 1));
    const r = 750;
    pos[i * 3] = r * Math.sin(ph) * Math.cos(th);
    pos[i * 3 + 1] = r * Math.cos(ph);
    pos[i * 3 + 2] = r * Math.sin(ph) * Math.sin(th);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  window._stars = new THREE.Points(g, new THREE.PointsMaterial({ color: 0x9fd8ff, size: 2.2, sizeAttenuation: false, transparent: true, opacity: 0.9, fog: false }));
  scene.add(window._stars);
}

// ---------------------------------------------------------------------------
// МИР: рельеф, деревья, кристаллы, камни, маяк
// ---------------------------------------------------------------------------
const colliders = []; // {x,z,r}

// --- Земля ---
{
  const SIZE = 640, SEG = 140;
  const geo = new THREE.PlaneGeometry(SIZE, SIZE, SEG, SEG);
  geo.rotateX(-Math.PI / 2);
  const pos = geo.attributes.position;
  const colors = new Float32Array(pos.count * 3);
  const cLow = new THREE.Color(0x120a2a), cMid = new THREE.Color(0x241a5e),
        cHigh = new THREE.Color(0x0e4a5e), cPeak = new THREE.Color(0x123a68);
  const tmp = new THREE.Color();
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getZ(i);
    const h = terrainH(x, z);
    pos.setY(i, h);
    if (h < 2) tmp.lerpColors(cLow, cMid, clamp((h + 8) / 12, 0, 1));
    else if (h < 14) tmp.lerpColors(cMid, cHigh, (h - 2) / 12);
    else tmp.lerpColors(cHigh, cPeak, clamp((h - 14) / 30, 0, 1));
    tmp.offsetHSL(0, 0, (hash2(Math.round(x * 3), Math.round(z * 3)) - 0.5) * 0.05);
    colors[i * 3] = tmp.r; colors[i * 3 + 1] = tmp.g; colors[i * 3 + 2] = tmp.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  geo.computeVertexNormals();
  geo.computeBoundingBox();
  geo.computeBoundingSphere();
  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.92, metalness: 0.15 });
  scene.add(new THREE.Mesh(geo, mat));
}

// --- Неоновая сетка на арене ---
{
  const grid = new THREE.GridHelper(120, 40, 0x00ffff, 0x004466);
  grid.material.transparent = true; grid.material.opacity = 0.28;
  grid.position.y = 0.06;
  scene.add(grid);
}

// --- Инстансинг: деревья / кристаллы / камни ---
const dummy = new THREE.Object3D();
const crystalsList = [];
function scatter(count, minR, maxR, cb) {
  for (let i = 0; i < count; i++) {
    const a = Math.random() * Math.PI * 2, r = rand(minR, maxR);
    const x = Math.cos(a) * r, z = Math.sin(a) * r;
    cb(x, z, i, terrainH(x, z));
  }
}
{
  // деревья (неоновые ёлки)
  const trunkG = new THREE.CylinderGeometry(0.25, 0.4, 2.4, 5);
  const trunkM = new THREE.MeshStandardMaterial({ color: 0x1a1030, roughness: 1 });
  const leafG = new THREE.ConeGeometry(1.5, 4.2, 6);
  const leafM = new THREE.MeshStandardMaterial({ color: 0x0d2b3a, emissive: 0x00ffcc, emissiveIntensity: 0.35, roughness: 0.8 });
  const N = 340;
  const trunks = new THREE.InstancedMesh(trunkG, trunkM, N);
  const leaves = new THREE.InstancedMesh(leafG, leafM, N);
  let placed = 0;
  scatter(N, 26, 270, (x, z, i, h) => {
    if (h > 26) return;
    const s = rand(0.8, 1.7);
    dummy.position.set(x, h + 1.1 * s, z); dummy.scale.setScalar(s); dummy.rotation.set(0, rand(0, 6.28), 0);
    dummy.updateMatrix(); trunks.setMatrixAt(placed, dummy.matrix);
    dummy.position.y = h + 3.4 * s; dummy.updateMatrix(); leaves.setMatrixAt(placed, dummy.matrix);
    colliders.push({ x, z, r: 0.8 * s });
    placed++;
  });
  trunks.count = placed; leaves.count = placed;
  trunks.instanceMatrix.needsUpdate = true; leaves.instanceMatrix.needsUpdate = true;
  trunks.frustumCulled = false; leaves.frustumCulled = false;
  scene.add(trunks); scene.add(leaves);
}
{
  // кристаллы
  const g = new THREE.OctahedronGeometry(1.2);
  const m = new THREE.MeshStandardMaterial({ color: 0x30104a, emissive: 0xff00ff, emissiveIntensity: 0.9, roughness: 0.3, metalness: 0.4, flatShading: true });
  const N = 90;
  const inst = new THREE.InstancedMesh(g, m, N);
  let placed = 0;
  scatter(N, 22, 265, (x, z, i, h) => {
    if (h > 24) return;
    const s = rand(0.7, 2.1);
    dummy.position.set(x, h + 0.9 * s, z);
    dummy.scale.set(s, s * rand(1.3, 2.2), s);
    dummy.rotation.set(rand(-0.15, 0.15), rand(0, 6.28), rand(-0.15, 0.15));
    dummy.updateMatrix(); inst.setMatrixAt(placed, dummy.matrix);
    colliders.push({ x, z, r: 1.1 * s });
    crystalsList.push({ x, z });
    placed++;
  });
  inst.count = placed;
  inst.instanceMatrix.needsUpdate = true;
  inst.frustumCulled = false;
  scene.add(inst);
  window._crystalMat = m;
}
{
  // камни
  const g = new THREE.DodecahedronGeometry(1.6);
  const m = new THREE.MeshStandardMaterial({ color: 0x2a2a3a, roughness: 1, flatShading: true });
  const N = 70;
  const inst = new THREE.InstancedMesh(g, m, N);
  let placed = 0;
  scatter(N, 20, 268, (x, z, i, h) => {
    if (h > 30) return;
    const s = rand(0.6, 1.8);
    dummy.position.set(x, h + 0.5 * s, z);
    dummy.scale.setScalar(s);
    dummy.rotation.set(rand(0, 3), rand(0, 6.28), rand(0, 3));
    dummy.updateMatrix(); inst.setMatrixAt(placed, dummy.matrix);
    colliders.push({ x, z, r: 1.5 * s });
    placed++;
  });
  inst.count = placed;
  inst.instanceMatrix.needsUpdate = true;
  inst.frustumCulled = false;
  scene.add(inst);
}

// --- Маяк (магазин) в центре ---
const BEACON = { x: 0, z: 0, r: 3 };
{
  const grp = new THREE.Group();
  const base = new THREE.Mesh(
    new THREE.CylinderGeometry(3.4, 4.2, 1.2, 8),
    new THREE.MeshStandardMaterial({ color: 0x0a0a18, roughness: 0.6, metalness: 0.7 })
  );
  base.position.y = 0.6; grp.add(base);
  const pillar = new THREE.Mesh(
    new THREE.ConeGeometry(1.1, 9, 6),
    new THREE.MeshStandardMaterial({ color: 0x00223a, emissive: 0x00ffff, emissiveIntensity: 1.4, roughness: 0.2, metalness: 0.6, flatShading: true })
  );
  pillar.position.y = 5.6; grp.add(pillar);
  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(2.4, 0.12, 8, 40),
    new THREE.MeshBasicMaterial({ color: 0x00ffff })
  );
  ring.position.y = 4.5; ring.rotation.x = Math.PI / 2; grp.add(ring);
  window._beaconRing = ring;
  const beam = new THREE.Mesh(
    new THREE.CylinderGeometry(0.35, 0.05, 60, 8, 1, true),
    new THREE.MeshBasicMaterial({ color: 0x00ffff, transparent: true, opacity: 0.16, depthWrite: false, side: THREE.DoubleSide })
  );
  beam.position.y = 38; grp.add(beam);
  const light = new THREE.PointLight(0x00ffff, 3, 40);
  light.position.y = 6; grp.add(light);
  colliders.push(BEACON);
  scene.add(grp);
}

// ---------------------------------------------------------------------------
// ПУЛ ЭФФЕКТОВ: искры, лучи, кольца, вспышки, цифры урона
// ---------------------------------------------------------------------------
const sparks = (() => {
  const MAX = 700;
  const pos = new Float32Array(MAX * 3);
  const col = new Float32Array(MAX * 3);
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  const pts = new THREE.Points(geo, new THREE.PointsMaterial({ size: 0.22, vertexColors: true, transparent: true, opacity: 0.95, blending: THREE.AdditiveBlending, depthWrite: false }));
  pts.frustumCulled = false;
  scene.add(pts);
  const pool = [];
  for (let i = 0; i < MAX; i++) pool.push({ life: 0, v: V3(), x: 0, y: -999, z: 0 });
  let cursor = 0;
  return {
    burst(p, color, n = 14, speed = 6) {
      const c = new THREE.Color(color);
      for (let k = 0; k < n; k++) {
        const idx = cursor; cursor = (cursor + 1) % MAX;
        const s = pool[idx];
        s.life = rand(0.3, 0.8);
        s.x = p.x; s.y = p.y; s.z = p.z;
        s.v.set(rand(-1, 1), rand(-0.2, 1.2), rand(-1, 1)).normalize().multiplyScalar(rand(speed * 0.4, speed));
        geo.attributes.color.setXYZ(idx, c.r, c.g, c.b);
      }
      geo.attributes.color.needsUpdate = true;
    },
    update(dt) {
      let dirty = false;
      for (let i = 0; i < MAX; i++) {
        const s = pool[i];
        if (s.life > 0) {
          s.life -= dt; dirty = true;
          s.v.y -= 9 * dt;
          s.x += s.v.x * dt; s.y += s.v.y * dt; s.z += s.v.z * dt;
          if (s.y < terrainH(s.x, s.z)) s.y = terrainH(s.x, s.z);
          pos[i * 3] = s.x; pos[i * 3 + 1] = s.y; pos[i * 3 + 2] = s.z;
          if (s.life <= 0) {
            pos[i * 3 + 1] = -999;
            dirty = true;
          }
        }
      }
      if (dirty) geo.attributes.position.needsUpdate = true;
    }
  };
})();

const beams = (() => {
  const pool = [];
  const geo = new THREE.BoxGeometry(1, 1, 1);
  for (let i = 0; i < 24; i++) {
    const m = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color: 0x00ffff, transparent: true, opacity: 0 }));
    m.visible = false; scene.add(m);
    pool.push({ m, life: 0 });
  }
  let cursor = 0;
  return {
    fire(from, to, color, width = 0.06) {
      const b = pool[cursor]; cursor = (cursor + 1) % pool.length;
      const dir = to.clone().sub(from);
      const len = dir.length();
      b.m.visible = true;
      b.m.material.color.set(color);
      b.m.material.opacity = 0.9;
      b.m.position.copy(from).add(dir.clone().multiplyScalar(0.5));
      b.m.scale.set(width, width, len);
      b.m.lookAt(to);
      b.life = 0.12;
    },
    update(dt) {
      for (const b of pool) {
        if (b.life > 0) {
          b.life -= dt;
          b.m.material.opacity = Math.max(0, b.life / 0.12) * 0.9;
          if (b.life <= 0) b.m.visible = false;
        }
      }
    }
  };
})();

const rings = (() => {
  const pool = [];
  for (let i = 0; i < 8; i++) {
    const m = new THREE.Mesh(
      new THREE.TorusGeometry(1, 0.15, 6, 32),
      new THREE.MeshBasicMaterial({ color: 0xffaa00, transparent: true, opacity: 0 })
    );
    m.rotation.x = Math.PI / 2; m.visible = false; scene.add(m);
    pool.push({ m, life: 0, max: 1, grow: 10 });
  }
  return {
    spawn(p, color, grow = 14, life = 0.6) {
      const r = pool.find(r => r.life <= 0) || pool[0];
      r.m.visible = true;
      r.m.material.color.set(color);
      r.m.position.copy(p); r.m.position.y += 0.3;
      r.life = life; r.max = life; r.grow = grow;
      r.m.scale.setScalar(0.5);
    },
    update(dt) {
      for (const r of pool) {
        if (r.life > 0) {
          r.life -= dt;
          const t = 1 - r.life / r.max;
          r.m.scale.setScalar(0.5 + t * r.grow);
          r.m.material.opacity = (1 - t) * 0.8;
          if (r.life <= 0) r.m.visible = false;
        }
      }
    }
  };
})();

const dmgNums = (() => {
  const pool = [];
  for (let i = 0; i < 22; i++) {
    const cv = document.createElement('canvas'); cv.width = 128; cv.height = 64;
    const tex = new THREE.CanvasTexture(cv);
    const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }));
    sp.scale.set(1.6, 0.8, 1); sp.visible = false;
    scene.add(sp);
    pool.push({ sp, cv, tex, life: 0, vy: 0 });
  }
  return {
    show(p, text, color = '#fff') {
      const d = pool.find(d => d.life <= 0) || pool[0];
      const c = d.cv.getContext('2d');
      c.clearRect(0, 0, 128, 64);
      c.font = 'bold 44px Segoe UI, sans-serif';
      c.textAlign = 'center'; c.textBaseline = 'middle';
      c.shadowColor = color; c.shadowBlur = 12;
      c.fillStyle = color; c.fillText(text, 64, 34);
      d.tex.needsUpdate = true;
      d.sp.position.copy(p); d.sp.position.y += rand(1.5, 2.2);
      d.sp.material.opacity = 1; d.sp.visible = true;
      d.life = 0.8; d.vy = 2.4;
    },
    update(dt) {
      for (const d of pool) {
        if (d.life > 0) {
          d.life -= dt;
          d.sp.position.y += d.vy * dt;
          d.sp.material.opacity = clamp(d.life / 0.8, 0, 1);
          if (d.life <= 0) d.sp.visible = false;
        }
      }
    }
  };
})();

const flashLight = new THREE.PointLight(0xffffff, 0, 18);
scene.add(flashLight);
let flashTime = 0;
function muzzleFlash(p, color, intensity = 6) {
  flashLight.position.copy(p);
  flashLight.color.set(color);
  flashLight.intensity = intensity;
  flashTime = 0.06;
}

// ---------------------------------------------------------------------------
// ИГРОК
// ---------------------------------------------------------------------------
const player = {
  pos: V3(0, 0, 12),
  vel: V3(),
  yaw: Math.PI, pitch: 0,
  hp: 100, maxHp: 100,
  onGround: true,
  radius: 0.6,
  kills: 0, coins: 0, level: 1, xp: 0,
  bestCombo: 0,
  damageMult: 1, fireRateMult: 1, speedMult: 1,
  bobT: 0,
};

let combo = 0, comboTimer = 0;
const COMBO_MAX_TIME = 10.0;
function updateComboHUD() {
  const badge = $('combo-badge');
  if (!badge) return;
  if (combo >= 2 && comboTimer > 0) {
    badge.style.opacity = '1';
    $('combo-text').textContent = `🔥 КОМБО x${combo} (${comboTimer.toFixed(1)}с)`;
    const pct = clamp(comboTimer / COMBO_MAX_TIME * 100, 0, 100);
    $('combo-bar').style.width = pct + '%';
  } else {
    badge.style.opacity = '0';
  }
}

const XP_NEEDED = lvl => Math.floor(80 * Math.pow(lvl, 1.35));

// --- Оружие ---
const WEAPONS = [
  { id: 'pistol', name: 'ПЛАЗМА-ПИСТОЛЕТ', dmg: 13, interval: 0.24, spread: 0.012, pellets: 1, ammo: Infinity, color: 0x00ffff, beamW: 0.05, sfx: 'shootPistol', shake: 0, kick: 0.06, kickRot: 0.1 },
  { id: 'shotgun', name: 'ДРОБОВИК «ГРОМ»', dmg: 8, interval: 0.85, spread: 0.09, pellets: 8, ammo: 24, color: 0xff8800, beamW: 0.04, sfx: 'shootShotgun', shake: 0.25, kick: 0.12, kickRot: 0.18 },
  { id: 'rail', name: 'РЕЛЬСОТРОН «КОПЬЁ»', dmg: 95, interval: 1.5, spread: 0, pellets: 1, ammo: 10, color: 0xff00ff, beamW: 0.14, sfx: 'shootRail', shake: 0.5, pierce: true, kick: 0.16, kickRot: 0.24 },
];
const weaponState = { cur: 0, cooldown: 0 };

// ---------------------------------------------------------------------------
// ВРАГИ И ПУЛ РЕСУРСОВ
// ---------------------------------------------------------------------------
const SHARED_RES = {
  enemyBodyGeo: new THREE.IcosahedronGeometry(1, 0),
  enemyEyeGeo: new THREE.SphereGeometry(0.28, 8, 8),
  enemyEyeMat: new THREE.MeshBasicMaterial({ color: 0xffffff }),
  hpBgMat: new THREE.SpriteMaterial({ color: 0x000000 }),
  hpFgMat: new THREE.SpriteMaterial({ color: 0x22ff44 }),
  projGeo: new THREE.SphereGeometry(0.25, 8, 8),
  projMat: new THREE.MeshBasicMaterial({ color: 0x00ff88 }),
  coinGeo: new THREE.CylinderGeometry(0.32, 0.32, 0.08, 12),
  coinMat: new THREE.MeshStandardMaterial({ color: 0x332200, emissive: 0xffcc00, emissiveIntensity: 1.2, metalness: 0.8, roughness: 0.3 }),
  healthGeo: new THREE.BoxGeometry(0.55, 0.55, 0.55),
  healthMat: new THREE.MeshStandardMaterial({ color: 0x003300, emissive: 0x00ff44, emissiveIntensity: 1.0 }),
  ammoGeo: new THREE.BoxGeometry(0.6, 0.4, 0.4),
  ammoMat: new THREE.MeshStandardMaterial({ color: 0x001133, emissive: 0x00aaff, emissiveIntensity: 1.0 }),
};

const TYPES = {
  grunt:   { name: 'ГРУНТ',    hp: 32,  speed: 3.4, dmg: 9,  scale: 1.0, color: 0xff3344, xp: 20, coins: [1, 2], coinChance: 0.65, hitR: 1.0 },
  speeder: { name: 'СПРИНТЕР', hp: 16,  speed: 7.2, dmg: 5,  scale: 0.7, color: 0xffaa00, xp: 15, coins: [1, 1], coinChance: 0.5, hitR: 0.7 },
  spitter: { name: 'ПЛЕВУН',   hp: 26,  speed: 2.6, dmg: 11, scale: 0.9, color: 0x00ff88, xp: 25, coins: [1, 2], coinChance: 0.6, hitR: 0.9, ranged: true },
  brute:   { name: 'ГРОМИЛА',  hp: 130, speed: 2.1, dmg: 22, scale: 1.9, color: 0xff00ff, xp: 60, coins: [3, 5], coinChance: 1, hitR: 1.1 },
  boss:    { name: 'БОСС',     hp: 650, speed: 2.5, dmg: 30, scale: 3.0, color: 0xffff00, xp: 400, coins: [14, 18], coinChance: 1, hitR: 1.6, boss: true },
};

const enemies = [];
function makeEnemy(type, x, z) {
  const T = TYPES[type];
  const hpScale = 1 + (wave.num - 1) * 0.13;
  const g = new THREE.Group();
  const bodyMat = new THREE.MeshStandardMaterial({
    color: 0x111122, emissive: T.color, emissiveIntensity: 1.1,
    roughness: 0.4, metalness: 0.5, flatShading: true,
  });
  const body = new THREE.Mesh(SHARED_RES.enemyBodyGeo, bodyMat);
  body.scale.set(1, 1.25, 1);
  g.add(body);
  const eye = new THREE.Mesh(SHARED_RES.enemyEyeGeo, SHARED_RES.enemyEyeMat);
  eye.position.set(0, 0.25, -0.85);
  g.add(eye);
  g.scale.setScalar(T.scale);

  // полоска HP
  const hpBg = new THREE.Sprite(SHARED_RES.hpBgMat);
  const hpFg = new THREE.Sprite(SHARED_RES.hpFgMat);
  const bw = 1.4 * T.scale;
  hpBg.scale.set(bw, 0.14, 1); hpFg.scale.set(bw, 0.1, 1);
  hpBg.position.y = 1.9 * T.scale; hpFg.position.y = 1.9 * T.scale;
  g.add(hpBg); g.add(hpFg);

  const e = {
    type, T, group: g, body, bodyMat, hpFg, hpBarW: bw,
    hp: T.hp * hpScale, maxHp: T.hp * hpScale,
    pos: V3(x, terrainH(x, z) + 1.2 * T.scale, z),
    speed: T.speed * rand(0.9, 1.1),
    atkCd: rand(0, 0.6), flash: 0, bobT: rand(0, 6),
    shockCd: 3,
  };
  g.position.copy(e.pos);
  scene.add(g);
  enemies.push(e);
  return e;
}
function killEnemy(e, byPlayer = true) {
  const i = enemies.indexOf(e);
  if (i < 0) return;
  enemies.splice(i, 1);
  scene.remove(e.group);
  e.bodyMat.dispose();
  const p = e.pos.clone();
  sparks.burst(p, e.T.color, e.T.boss ? 60 : 18, e.T.boss ? 12 : 7);
  rings.spawn(p, e.T.color, e.T.boss ? 22 : 6, e.T.boss ? 1.2 : 0.5);
  SFX.kill();
  if (byPlayer) {
    combo++;
    comboTimer = COMBO_MAX_TIME;
    if (combo > player.bestCombo) player.bestCombo = combo;
    const comboMult = 1 + Math.min(combo - 1, 20) * 0.15;
    const xp = Math.round(e.T.xp * comboMult);
    player.xp += xp; player.kills++;
    if (combo >= 2) {
      dmgNums.show(player.pos.clone().add(V3(0, 1.8, 0)), `x${combo} СЕРИЯ!`, '#ffcc00');
    }
    updateComboHUD();
    if (e.T.boss) {
      addKillFeed(`БОСС ПОВЕРЖЕН! +${xp} XP`);
      showToast('БОСС ПОВЕРЖЕН!', 2.5);
      shake += 0.6;
      SFX.boss();
    } else addKillFeed(`${e.T.name} уничтожен · +${xp} XP`);
    // лут
    if (Math.random() < e.T.coinChance) {
      const n = randi(e.T.coins[0], e.T.coins[1]);
      for (let k = 0; k < n; k++) spawnPickup('coin', p.x + rand(-1.5, 1.5), p.z + rand(-1.5, 1.5));
    }
    if (combo >= 5 && Math.random() < 0.4) spawnPickup('coin', p.x, p.z);
    if (e.T.boss || Math.random() < 0.08) spawnPickup('ammo', p.x + rand(-2, 2), p.z + rand(-2, 2));
    if (e.T.boss || Math.random() < 0.06) spawnPickup('health', p.x + rand(-2, 2), p.z + rand(-2, 2));
    checkLevel();
    Quests.onKill(e.type);
    Ach.onKill(e.type);
  }
  updateWaveCounter();
}

// --- Вражеские снаряды ---
const projectiles = [];
function spawnProjectile(from, target, dmg, color = 0x00ff88) {
  const m = new THREE.Mesh(SHARED_RES.projGeo, color === 0x00ff88 ? SHARED_RES.projMat : new THREE.MeshBasicMaterial({ color }));
  m.position.copy(from);
  const dir = target.clone().sub(from).normalize();
  scene.add(m);
  projectiles.push({ m, dir, speed: 14, dmg, life: 4, customMat: color !== 0x00ff88 ? m.material : null });
  SFX.spit();
}

// ---------------------------------------------------------------------------
// ЛУТ
// ---------------------------------------------------------------------------
const pickups = [];
function spawnPickup(kind, x, z) {
  let m;
  const y = terrainH(x, z);
  if (kind === 'coin') {
    m = new THREE.Mesh(SHARED_RES.coinGeo, SHARED_RES.coinMat);
    m.rotation.x = Math.PI / 2;
  } else if (kind === 'health') {
    m = new THREE.Mesh(SHARED_RES.healthGeo, SHARED_RES.healthMat);
  } else {
    m = new THREE.Mesh(SHARED_RES.ammoGeo, SHARED_RES.ammoMat);
  }
  m.position.set(x, y + 0.8, z);
  scene.add(m);
  pickups.push({ kind, m, x, z, baseY: y + 0.8, t: rand(0, 6) });
}

// ---------------------------------------------------------------------------
// ВОЛНЫ
// ---------------------------------------------------------------------------
const wave = { num: 0, state: 'idle', timer: 3, spawnQueue: [], alive: 0 };
function startWave() {
  wave.num++;
  wave.state = 'active';
  const n = 5 + wave.num * 2;
  wave.spawnQueue = [];
  const boss = wave.num % 5 === 0;
  if (boss) {
    wave.spawnQueue.push('boss');
    for (let i = 0; i < Math.floor(n * 0.6); i++) wave.spawnQueue.push(pickType());
    showToast(`⚠ ВОЛНА ${wave.num} — БОСС! ⚠`, 3);
    SFX.boss();
  } else {
    for (let i = 0; i < n; i++) wave.spawnQueue.push(pickType());
    showToast(`ВОЛНА ${wave.num}`, 2);
    SFX.wave();
  }
  wave.spawnTimer = 0;
  document.getElementById('wave-num').textContent = `ВОЛНА ${wave.num}`;
  updateWaveCounter();
}
function pickType() {
  const w = wave.num, r = Math.random();
  if (w >= 4 && r < 0.12) return 'brute';
  if (w >= 3 && r < 0.3) return 'spitter';
  if (w >= 2 && r < 0.55) return 'speeder';
  return 'grunt';
}
function updateWaveCounter() {
  const left = wave.spawnQueue.length + enemies.length;
  document.getElementById('enemies-left').textContent = `Врагов: ${left}`;
  if (wave.state === 'active' && left === 0) {
    wave.state = 'intermission';
    wave.timer = 8;
    const bonus = 20 + wave.num * 8;
    player.coins += bonus;
    showToast(`Волна ${wave.num} зачищена! +${bonus} ⬡`, 2.5);
    SFX.buy();
    Quests.onWave(wave.num);
    updateHUD();
    saveGame();
    Ach.onWave(wave.num);
    Ach.onCoins(player.coins);
  }
}

// ---------------------------------------------------------------------------
// КВЕСТЫ
// ---------------------------------------------------------------------------
const Quests = {
  list: [
    { id: 'k10',  title: 'Уничтожить 10 врагов',     cur: 0, goal: 10,  reward: 60,  done: false, kind: 'kill' },
    { id: 'c100', title: 'Собрать 100 монет',        cur: 0, goal: 100, reward: 120, done: false, kind: 'coins' },
    { id: 'w5',   title: 'Пережить волну 5',         cur: 0, goal: 5,   reward: 200, done: false, kind: 'wave' },
    { id: 'b3',   title: 'Купить 3 улучшения',       cur: 0, goal: 3,   reward: 150, done: false, kind: 'buy' },
    { id: 'l5',   title: 'Достичь 5 уровня',         cur: 0, goal: 5,   reward: 250, done: false, kind: 'level' },
    { id: 'k50',  title: 'Уничтожить 50 врагов',     cur: 0, goal: 50,  reward: 300, done: false, kind: 'kill' },
    { id: 'boss', title: 'Победить босса',           cur: 0, goal: 1,   reward: 500, done: false, kind: 'boss' },
    { id: 'w10',  title: 'Пережить волну 10',        cur: 0, goal: 10,  reward: 600, done: false, kind: 'wave' },
    { id: 'k150', title: 'Уничтожить 150 врагов',    cur: 0, goal: 150, reward: 800, done: false, kind: 'kill' },
  ],
  onKill(type) {
    for (const q of this.list) {
      if (q.done) continue;
      if (q.kind === 'kill') this.bump(q, 1);
      if (q.kind === 'boss' && type === 'boss') this.bump(q, 1);
    }
  },
  onWave(w) {
    for (const q of this.list) {
      if (q.done || q.kind !== 'wave') continue;
      q.cur = Math.min(q.goal, w);
      this.check(q);
      this.render();
    }
  },
  onBuy() {
    for (const q of this.list) if (!q.done && q.kind === 'buy') this.bump(q, 1);
  },
  onLevel() {
    for (const q of this.list) if (!q.done && q.kind === 'level') q.cur = Math.min(q.goal, player.level), this.check(q), this.render();
  },
  bump(q, n) {
    q.cur = Math.min(q.goal, q.cur + n);
    this.check(q);
    this.render();
  },
  check(q) {
    if (q.cur >= q.goal && !q.done) {
      q.done = true;
      player.coins += q.reward;
      showToast(`✅ КВЕСТ: ${q.title} · +${q.reward} ⬡`, 3);
      SFX.levelup();
      updateHUD();
    }
  },
  render() {
    const el = document.getElementById('quest-list');
    el.innerHTML = this.list.map(q =>
      `<div class="quest ${q.done ? 'done' : ''}">${q.title}<br><span class="qprog">${Math.min(q.cur, q.goal)}/${q.goal}</span></div>`
    ).join('');
  },
};
// монеты: накопительный счётчик собранных
let coinsCollectedTotal = 0;
Quests.onCoinsPickup = function (val = 1) {
  coinsCollectedTotal += val;
  for (const q of this.list) if (!q.done && q.kind === 'coins') { q.cur = Math.min(q.goal, coinsCollectedTotal); this.check(q); }
  this.render();
};

Quests.render();

// ---------------------------------------------------------------------------
// МАГАЗИН
// ---------------------------------------------------------------------------
const shop = {
  open: false,
  items: [
    { id: 'heal',   name: '🧪 Полное восстановление', base: 30,  desc: 'HP на максимум',                 apply() { player.hp = player.maxHp; } },
    { id: 'sgammo', name: '🔶 Патроны: дробовик +24',  base: 40,  desc: 'для «Гром»',                     apply() { WEAPONS[1].ammo += 24; } },
    { id: 'rammo',  name: '🔷 Заряды: рельсотрон +10', base: 60,  desc: 'для «Копьё»',                    apply() { WEAPONS[2].ammo += 10; } },
    { id: 'hp',     name: '❤️ Прочность +25',          base: 80,  desc: 'максимум HP',                    apply() { player.maxHp += 25; player.hp += 25; } },
    { id: 'dmg',    name: '⚔️ Урон +20%',              base: 120, desc: 'ко всем видам оружия',           apply() { player.damageMult += 0.2; } },
    { id: 'rof',    name: '⚡ Скорострельность +15%',  base: 110, desc: 'все стволы',                     apply() { player.fireRateMult += 0.15; } },
    { id: 'spd',    name: '👟 Скорость +10%',          base: 90,  desc: 'передвижение',                   apply() { player.speedMult += 0.1; } },
  ],
  counts: {},
  price(it) { return Math.round(it.base * Math.pow(1.55, this.counts[it.id] || 0)); },
  buy(it) {
    const p = this.price(it);
    if (player.coins < p) { SFX.error(); return; }
    player.coins -= p;
    this.counts[it.id] = (this.counts[it.id] || 0) + 1;
    it.apply();
    SFX.buy();
    Quests.onBuy();
    saveGame();
    updateHUD();
    this.render();
  },
  render() {
    document.getElementById('shop-coins').textContent = `Монеты: ${player.coins} ⬡`;
    const box = document.getElementById('shop-items');
    box.innerHTML = '';
    for (const it of this.items) {
      const p = this.price(it);
      const row = document.createElement('div');
      row.className = 'shop-item';
      row.innerHTML = `<div><div style="color:#0ff;font-size:16px">${it.name}</div>
        <div style="color:#6cc;font-size:12px">${it.desc} · куплено: ${this.counts[it.id] || 0}</div></div>`;
      const btn = document.createElement('button');
      btn.textContent = `${p} ⬡`;
      btn.style.color = player.coins >= p ? '#0f0' : '#f55';
      btn.style.borderColor = player.coins >= p ? '#0f0' : '#f55';
      btn.onclick = () => this.buy(it);
      row.appendChild(btn);
      box.appendChild(row);
    }
  },
  show() {
    this.open = true;
    this.render();
    document.getElementById('shop-screen').style.display = 'flex';
    document.exitPointerLock();
  },
  hide() {
    this.open = false;
    document.getElementById('shop-screen').style.display = 'none';
    lockPointer();
  },
};
document.getElementById('btn-shop-close').onclick = () => shop.hide();

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------
const $ = id => document.getElementById(id);
let toastTimer = null;
function showToast(text, dur = 2) {
  const t = $('toast');
  t.textContent = text;
  t.style.opacity = 1;
  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.style.opacity = 0; }, dur * 1000);
}
function addKillFeed(text) {
  const kf = $('killfeed');
  const line = document.createElement('div');
  line.className = 'kf-line';
  line.textContent = text;
  kf.appendChild(line);
  while (kf.children.length > 6) kf.removeChild(kf.firstChild);
  setTimeout(() => { line.style.opacity = 0; }, 3500);
  setTimeout(() => { if (line.parentNode) line.parentNode.removeChild(line); }, 4600);
}
function updateHUD() {
  $('hp-text').textContent = `${Math.max(0, Math.ceil(player.hp))}/${player.maxHp}`;
  $('hp-bar').style.width = `${clamp(player.hp / player.maxHp * 100, 0, 100)}%`;
  $('xp-bar').style.width = `${clamp(player.xp / XP_NEEDED(player.level) * 100, 0, 100)}%`;
  $('lvl').textContent = player.level;
  $('coins').textContent = player.coins;
  $('kills').textContent = player.kills;
  $('dmgstat').textContent = Math.round(WEAPONS[weaponState.cur].dmg * player.damageMult);
  $('rofstat').textContent = 'x' + player.fireRateMult.toFixed(1);
  $('weapon-name').textContent = WEAPONS[weaponState.cur].name;
  $('ammo').textContent = WEAPONS[weaponState.cur].ammo === Infinity ? '∞' : WEAPONS[weaponState.cur].ammo;
}
function checkLevel() {
  while (player.xp >= XP_NEEDED(player.level)) {
    player.xp -= XP_NEEDED(player.level);
    player.level++;
    player.maxHp += 6;
    player.hp = player.maxHp;
    player.damageMult += 0.04;
    $('levelup-flash').style.opacity = 1;
    setTimeout(() => $('levelup-flash').style.opacity = 0, 350);
    showToast(`⬆ УРОВЕНЬ ${player.level}! HP восстановлено`, 2.5);
    SFX.levelup();
    Quests.onLevel();
    Ach.onLevel(player.level);
    saveGame();
  }
  updateHUD();
}

// --- Миникарта ---
const mmCanvas = $('minimap');
const mmCtx = mmCanvas.getContext('2d');
let mmScale = 0.32;
function drawMinimap() {
  const W = mmCanvas.width, H = mmCanvas.height;
  mmCtx.fillStyle = 'rgba(0,8,16,0.9)';
  mmCtx.fillRect(0, 0, W, H);
  const cx = W / 2, cy = H / 2;
  const wx = x => cx + (x - player.pos.x) * mmScale;
  const wz = z => cy + (z - player.pos.z) * mmScale;
  // маяк
  mmCtx.fillStyle = '#0ff';
  mmCtx.beginPath(); mmCtx.arc(wx(0), wz(0), 4, 0, Math.PI * 2); mmCtx.fill();
  // кристаллы
  mmCtx.fillStyle = '#f0f';
  for (const c of crystalsList) {
    mmCtx.fillRect(wx(c.x) - 1.5, wz(c.z) - 1.5, 3, 3);
  }
  // сетка-кольцо арены
  mmCtx.strokeStyle = '#0ff3';
  mmCtx.beginPath(); mmCtx.arc(wx(0), wz(0), 295 * mmScale, 0, Math.PI * 2); mmCtx.stroke();
  // враги
  for (const e of enemies) {
    mmCtx.fillStyle = e.T.boss ? '#ff0' : '#f44';
    const r = e.T.boss ? 4 : 2.4;
    mmCtx.beginPath(); mmCtx.arc(wx(e.pos.x), wz(e.pos.z), r, 0, Math.PI * 2); mmCtx.fill();
  }
  // лут
  mmCtx.fillStyle = '#fd0';
  for (const p of pickups) { mmCtx.fillRect(wx(p.x) - 1, wz(p.z) - 1, 2.5, 2.5); }
  // игрок (стрелка)
  mmCtx.save();
  mmCtx.translate(cx, cy);
  mmCtx.rotate(-player.yaw);
  mmCtx.fillStyle = '#fff';
  mmCtx.beginPath();
  mmCtx.moveTo(0, -6); mmCtx.lineTo(4, 5); mmCtx.lineTo(-4, 5);
  mmCtx.closePath(); mmCtx.fill();
  mmCtx.restore();
  mmCtx.strokeStyle = '#0ff6';
  mmCtx.strokeRect(0, 0, W, H);
}

// ---------------------------------------------------------------------------
// ВВОД
// ---------------------------------------------------------------------------
const keys = {};
let mouseDown = false;
let started = false;
let paused = false;
let gameOver = false;

function resetInput() {
  for (const k in keys) keys[k] = false;
  mouseDown = false;
}
window.addEventListener('blur', resetInput);
document.addEventListener('visibilitychange', () => { if (document.hidden) resetInput(); });

function setPaused(val) {
  if (!started || gameOver || shop.open) return;
  paused = val;
  const pScreen = $('pause-screen');
  if (pScreen) pScreen.style.display = paused ? 'flex' : 'none';
  if (paused) {
    resetInput();
    if (document.pointerLockElement === canvas) {
      document.exitPointerLock?.();
    }
  } else {
    lockPointer();
  }
}

function lockPointer() {
  if (gameOver || shop.open) return;
  try {
    const p = canvas.requestPointerLock?.();
    if (p && typeof p.catch === 'function') p.catch(() => {});
  } catch (_) { /* повторный запрос слишком рано — игнорируем */ }
}
canvas.addEventListener('click', () => {
  SFX.init();
  if (started && !gameOver && !shop.open) {
    if (paused) setPaused(false);
    else lockPointer();
  }
});
const pauseScreenEl = $('pause-screen');
if (pauseScreenEl) {
  pauseScreenEl.addEventListener('click', e => {
    if (e.target === pauseScreenEl) setPaused(false);
  });
}
const btnResume = $('btn-resume');
if (btnResume) {
  btnResume.onclick = () => {
    SFX.init();
    setPaused(false);
  };
}

document.addEventListener('pointerlockchange', () => {
  const locked = document.pointerLockElement === canvas;
  if (!locked) {
    resetInput();
    if (started && !gameOver && !shop.open) {
      setPaused(true);
    }
  } else {
    paused = false;
    if (pauseScreenEl) pauseScreenEl.style.display = 'none';
  }
});
document.addEventListener('mousemove', e => {
  if (document.pointerLockElement !== canvas) return;
  const s = 0.0023;
  player.yaw -= e.movementX * s;
  player.pitch = clamp(player.pitch - e.movementY * s, -1.45, 1.45);
});
document.addEventListener('mousedown', e => { if (e.button === 0) mouseDown = true; });
document.addEventListener('mouseup', e => { if (e.button === 0) mouseDown = false; });
document.addEventListener('keydown', e => {
  keys[e.code] = true;
  if (e.code === 'Escape') {
    if (shop.open) {
      shop.hide();
    } else if (started && !gameOver) {
      setPaused(!paused);
    }
    return;
  }
  if (!started || paused) return;
  if (e.code === 'Digit1') switchWeapon(0);
  if (e.code === 'Digit2') switchWeapon(1);
  if (e.code === 'Digit3') switchWeapon(2);
  if (e.code === 'KeyE') {
    const d = Math.hypot(player.pos.x - BEACON.x, player.pos.z - BEACON.z);
    if (shop.open) shop.hide();
    else if (d < 8) shop.show();
    else showToast('Магазин — у Маяка в центре арены', 1.5);
  }
  if (e.code === 'KeyM') {
    const isLarge = mmScale <= 0.2;
    mmScale = isLarge ? 0.32 : 0.12;
    const size = isLarge ? 180 : 320;
    mmCanvas.width = mmCanvas.height = size;
    mmCanvas.style.width = mmCanvas.style.height = size + 'px';
  }
});
document.addEventListener('keyup', e => { keys[e.code] = false; });
function switchWeapon(i) {
  if (i === weaponState.cur) return;
  if (WEAPONS[i].ammo <= 0 && i !== 0) { showToast(`${WEAPONS[i].name}: нет патронов!`, 1.5); SFX.empty(); return; }
  weaponState.cur = i;
  weaponState.cooldown = Math.max(weaponState.cooldown, 0.25);
  updateWeaponViewModel();
  SFX.buy();
  updateHUD();
}

// ---------------------------------------------------------------------------
// СОХРАНЕНИЯ И ДОСТИЖЕНИЯ
// ---------------------------------------------------------------------------
const SAVE_KEY = 'nw_save_v1';
const ACH_KEY = 'nw_achievements_v1';

function saveGame() {
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify({
      wave: wave.num,
      level: player.level,
      xp: player.xp,
      coins: player.coins,
      coinsCollectedTotal,
      kills: player.kills,
      maxHp: player.maxHp,
      damageMult: player.damageMult,
      fireRateMult: player.fireRateMult,
      speedMult: player.speedMult,
      shotgunAmmo: WEAPONS[1].ammo,
      railAmmo: WEAPONS[2].ammo,
      shopCounts: shop.counts,
      questProgress: Quests.list.map(q => ({ id: q.id, cur: q.cur, done: q.done })),
      ts: Date.now(),
    }));
  } catch (_) { /* приватный режим — играем без сейвов */ }
}
function loadGame() {
  try { return JSON.parse(localStorage.getItem(SAVE_KEY)); } catch (_) { return null; }
}
function clearGame() { try { localStorage.removeItem(SAVE_KEY); } catch (_) {} }

const Ach = {
  defs: [
    { id: 'first-blood', title: 'Первая кровь',   hint: 'Убей первого врага' },
    { id: 'wave-5',      title: 'Ветеран',        hint: 'Переживи волну 5' },
    { id: 'wave-10',     title: 'Легенда пустошей', hint: 'Переживи волну 10' },
    { id: 'boss-1',      title: 'Голова с плеча', hint: 'Убей первого босса' },
    { id: 'coins-100',   title: 'Банкир',         hint: 'Имей 100 монет' },
    { id: 'coins-500',   title: 'Магнат',         hint: 'Имей 500 монет' },
    { id: 'level-5',     title: 'Закалённый',     hint: 'Достигни 5 уровня' },
    { id: 'kills-50',    title: 'Громила-истребитель', hint: '50 убийств' },
  ],
  unlocked: (() => { try { return JSON.parse(localStorage.getItem(ACH_KEY)) || {}; } catch (_) { return {}; } })(),
  unlock(id) {
    if (this.unlocked[id]) return;
    this.unlocked[id] = Date.now();
    try { localStorage.setItem(ACH_KEY, JSON.stringify(this.unlocked)); } catch (_) {}
    const def = this.defs.find(d => d.id === id);
    if (def) showToast(`🏆 ДОСТИЖЕНИЕ: ${def.title}`, 3);
    SFX.levelup();
  },
  onKill(type) {
    this.unlock('first-blood');
    if (type === 'boss') this.unlock('boss-1');
    if (player.kills >= 50) this.unlock('kills-50');
  },
  onWave(w) {
    if (w >= 5) this.unlock('wave-5');
    if (w >= 10) this.unlock('wave-10');
  },
  onCoins(c) {
    if (c >= 100) this.unlock('coins-100');
    if (c >= 500) this.unlock('coins-500');
  },
  onLevel(l) { if (l >= 5) this.unlock('level-5'); },
  count() { return Object.keys(this.unlocked).length; },
};

$('btn-play').onclick = () => {
  SFX.init();
  clearGame();
  resetInput();
  started = true;
  $('start-screen').style.display = 'none';
  wave.state = 'intermission';
  wave.timer = 4;
  showToast('Приближается волна 1…', 3);
  lockPointer();
};

// продолжение: восстановить статы и вернуться прямо в интермиссию следующей волны
$('btn-continue').onclick = () => {
  const s = loadGame();
  if (!s) return;
  SFX.init();
  resetInput();
  player.level = s.level; player.xp = s.xp; player.coins = s.coins;
  if (s.coinsCollectedTotal !== undefined) coinsCollectedTotal = s.coinsCollectedTotal;
  player.kills = s.kills; player.maxHp = s.maxHp; player.hp = player.maxHp;
  player.damageMult = s.damageMult; player.fireRateMult = s.fireRateMult; player.speedMult = s.speedMult;
  WEAPONS[1].ammo = s.shotgunAmmo; WEAPONS[2].ammo = s.railAmmo;
  if (s.shopCounts) shop.counts = s.shopCounts;
  if (s.questProgress) {
    for (const saved of s.questProgress) {
      const q = Quests.list.find(x => x.id === saved.id);
      if (q) { q.cur = saved.cur; q.done = saved.done; }
    }
    Quests.render();
  }
  wave.num = s.wave;
  document.getElementById('wave-num').textContent = `ВОЛНА ${wave.num}`;
  started = true;
  $('start-screen').style.display = 'none';
  wave.state = 'intermission';
  wave.timer = 5;
  wave._lastCount = undefined;
  showToast(`Продолжаем с волны ${s.wave}. Снова в бой!`, 3);
  updateHUD();
  lockPointer();
};
// показать кнопку продолжения, если есть сейв
if (loadGame()) $('btn-continue').style.display = 'inline-block';

// ---------------------------------------------------------------------------
// СТРЕЛЬБА
// ---------------------------------------------------------------------------
function shoot() {
  const w = WEAPONS[weaponState.cur];
  if (weaponState.cooldown > 0) return;
  if (w.ammo !== Infinity && w.ammo <= 0) {
    SFX.empty();
    showToast(`${w.name}: нет патронов! Найди ящик с лутом или купи у Маяка [E]`, 2);
    weaponState.cooldown = 0.4;
    return;
  }
  weaponState.cooldown = w.interval / player.fireRateMult;
  if (w.ammo !== Infinity) { w.ammo--; updateHUD(); }
  SFX[w.sfx]();
  shake += w.shake;
  weaponRecoil = w.kick || 0.08;
  weaponRecoilRot = w.kickRot || 0.14;

  const origin = camera.position.clone();
  const baseDir = new THREE.Vector3(0, 0, -1).applyEuler(camera.rotation);
  const rightDir = new THREE.Vector3(1, 0, 0).applyEuler(camera.rotation);
  const upDir = new THREE.Vector3(0, 1, 0).applyEuler(camera.rotation);
  const muzzle = origin.clone()
    .add(baseDir.clone().multiplyScalar(0.6))
    .add(new THREE.Vector3(0.25, -0.2, 0).applyEuler(camera.rotation));
  muzzleFlash(muzzle, w.color, 7);

  // Оптимизированный расчет предельной дистанции по рельефу и препятствиям
  let sharedMaxT = 130;
  for (let t = 2; t < sharedMaxT; t += 4) {
    const px = origin.x + baseDir.x * t, py = origin.y + baseDir.y * t, pz = origin.z + baseDir.z * t;
    if (py < terrainH(px, pz)) { sharedMaxT = t; break; }
  }
  for (const c of colliders) {
    const dx = c.x - origin.x, dz = c.z - origin.z;
    const t = dx * baseDir.x + dz * baseDir.z;
    if (t > 0.5 && t < sharedMaxT) {
      const perpX = origin.x + baseDir.x * t - c.x;
      const perpZ = origin.z + baseDir.z * t - c.z;
      if (perpX * perpX + perpZ * perpZ < c.r * c.r) {
        sharedMaxT = t;
      }
    }
  }

  let anyHit = false;
  for (let p = 0; p < w.pellets; p++) {
    const dir = baseDir.clone();
    if (w.spread) {
      dir.addScaledVector(rightDir, rand(-w.spread, w.spread))
         .addScaledVector(upDir, rand(-w.spread, w.spread))
         .normalize();
    }
    const maxT = sharedMaxT;

    // пересечение со сферами врагов
    const hits = [];
    for (const e of enemies) {
      const toE = e.pos.clone().sub(origin);
      const t = toE.dot(dir);
      if (t < 0.5 || t > maxT) continue;
      const closest = origin.clone().add(dir.clone().multiplyScalar(t));
      const d = closest.distanceTo(e.pos);
      if (d < e.T.hitR * e.T.scale + 0.25) hits.push({ e, t });
    }
    hits.sort((a, b) => a.t - b.t);
    if (hits.length) {
      anyHit = true;
      const list = w.pierce ? hits : [hits[0]];
      for (const h of list) damageEnemy(h.e, w.dmg * player.damageMult, dir);
      const hitDist = w.pierce ? maxT : Math.max(0.7, list[0].t);
      beams.fire(muzzle, origin.clone().add(dir.clone().multiplyScalar(hitDist)), w.color, w.beamW);
    } else {
      beams.fire(muzzle, origin.clone().add(dir.clone().multiplyScalar(maxT)), w.color, w.beamW);
    }
  }
  if (anyHit) SFX.hit();
}
function damageEnemy(e, dmg, dir) {
  e.hp -= dmg;
  e.flash = 0.12;
  dmgNums.show(e.pos, String(Math.round(dmg)), e.T.boss ? '#ff0' : '#fff');
  sparks.burst(e.pos, '#ff5555', 5, 4);
  e.pos.add(dir.clone().multiplyScalar(e.T.boss ? 0 : 0.25));
  if (e.hp <= 0) killEnemy(e);
  else e.hpFg.scale.x = e.hpBarW * clamp(e.hp / e.maxHp, 0, 1);
}

// ---------------------------------------------------------------------------
// УРОН ИГРОКУ / ЭФФЕКТЫ
// ---------------------------------------------------------------------------
let shake = 0;
let invulnT = 0;
function damagePlayer(dmg, fromPos) {
  if (invulnT > 0 || gameOver) return;
  invulnT = 0.35;
  player.hp = Math.max(0, player.hp - dmg);
  if (combo > 1) {
    showToast(`Серия прервана! (Комбо x${combo})`, 1.5);
  }
  combo = 0;
  comboTimer = 0;
  updateComboHUD();
  SFX.hurt();
  shake += 0.3;
  if (fromPos) {
    const push = player.pos.clone().sub(fromPos).setY(0);
    if (push.lengthSq() > 0.001) push.normalize().multiplyScalar(2.2);
    player.vel.add(push);
  }
  $('damage-vignette').style.boxShadow = `inset 0 0 120px 40px rgba(255,0,0,${clamp(0.15 + dmg / 60, 0, 0.6)})`;
  setTimeout(() => { $('damage-vignette').style.boxShadow = 'inset 0 0 120px 40px rgba(255,0,0,0)'; }, 250);
  updateHUD();
  if (player.hp <= 0) doGameOver();
}
function doGameOver() {
  gameOver = true;
  combo = 0;
  comboTimer = 0;
  updateComboHUD();
  const pScreen = $('pause-screen');
  if (pScreen) pScreen.style.display = 'none';
  document.exitPointerLock?.();
  const mins = Math.floor(gameTime / 60), secs = Math.floor(gameTime % 60);
  $('gameover-stats').innerHTML =
    `Волна: <b style="color:#0ff">${wave.num}</b><br>` +
    `Убийств: <b style="color:#0ff">${player.kills}</b><br>` +
    `Макс. серия: <b style="color:#ffcc00">x${player.bestCombo}</b><br>` +
    `Уровень: <b style="color:#0ff">${player.level}</b><br>` +
    `Монет собрано: <b style="color:#0ff">${coinsCollectedTotal}</b><br>` +
    `Время: <b style="color:#0ff">${mins}м ${secs}с</b><br>` +
    `Достижений: <b style="color:#ff0">${Ach.count()} / ${Ach.defs.length}</b>`;
  $('gameover-screen').style.display = 'flex';
  clearGame();
}

// ---------------------------------------------------------------------------
// ГЛАВНЫЙ ЦИКЛ
// ---------------------------------------------------------------------------
let last = performance.now();
let gameTime = 0;
let dayT = 0.35; // фаза суток

const cNight = new THREE.Color(0x05030e), cDawn = new THREE.Color(0x2a1040), cDay = new THREE.Color(0x0a1830);
const fogNight = new THREE.Color(0x06030f), fogDay = new THREE.Color(0x0a1a2e);

function movePlayer(dt) {
  const sp = (keys['ShiftLeft'] || keys['ShiftRight'] ? 11 : 6.5) * player.speedMult;
  const f = new THREE.Vector3(-Math.sin(player.yaw), 0, -Math.cos(player.yaw));
  const r = new THREE.Vector3(Math.cos(player.yaw), 0, -Math.sin(player.yaw));
  const wish = new THREE.Vector3();
  if (keys['KeyW']) wish.add(f);
  if (keys['KeyS']) wish.sub(f);
  if (keys['KeyD']) wish.add(r);
  if (keys['KeyA']) wish.sub(r);
  if (wish.lengthSq()) wish.normalize().multiplyScalar(sp);

  player.vel.x = lerp(player.vel.x, wish.x, 1 - Math.pow(0.0001, dt));
  player.vel.z = lerp(player.vel.z, wish.z, 1 - Math.pow(0.0001, dt));
  player.vel.y -= 22 * dt;
  if (player.onGround && keys['Space']) { player.vel.y = 8.5; player.onGround = false; }

  player.pos.x += player.vel.x * dt;
  player.pos.z += player.vel.z * dt;
  player.pos.y += player.vel.y * dt;

  // коллизии с препятствиями
  for (const c of colliders) {
    const dx = player.pos.x - c.x, dz = player.pos.z - c.z;
    const rr = c.r + player.radius;
    const d2 = dx * dx + dz * dz;
    if (d2 < rr * rr && d2 > 0.0001) {
      const d = Math.sqrt(d2);
      player.pos.x = c.x + dx / d * rr;
      player.pos.z = c.z + dz / d * rr;
    }
  }
  // граница мира
  const dW = Math.hypot(player.pos.x, player.pos.z);
  if (dW > 295) {
    player.pos.x *= 295 / dW;
    player.pos.z *= 295 / dW;
    showToast('Дальше — только Пустошь. Развернись.', 1.2);
  }
  const ground = terrainH(player.pos.x, player.pos.z);
  const distToGround = player.pos.y - ground;
  if (distToGround <= 0) {
    player.pos.y = ground;
    player.vel.y = 0;
    player.onGround = true;
  } else if (distToGround < 0.35 && player.vel.y <= 0 && !keys['Space']) {
    player.pos.y = ground;
    player.vel.y = 0;
    player.onGround = true;
  } else if (distToGround > 0.1) {
    player.onGround = false;
  }

  // покачивание при ходьбе
  const speed2d = Math.hypot(player.vel.x, player.vel.z);
  player.bobT += dt * speed2d * 1.6;
}

function updateEnemies(dt) {
  // разведение врагов
  for (let i = 0; i < enemies.length; i++) {
    const a = enemies[i];
    for (let j = i + 1; j < enemies.length; j++) {
      const b = enemies[j];
      const dx = b.pos.x - a.pos.x, dz = b.pos.z - a.pos.z;
      const rr = (a.T.scale + b.T.scale) * 0.9;
      const d2 = dx * dx + dz * dz;
      if (d2 < rr * rr && d2 > 0.001) {
        const d = Math.sqrt(d2), push = (rr - d) * 0.5 / d;
        a.pos.x -= dx * push; a.pos.z -= dz * push;
        b.pos.x += dx * push; b.pos.z += dz * push;
      }
    }
  }
  for (const e of enemies) {
    const toP = player.pos.clone().sub(e.pos);
    toP.y = 0;
    const dist = toP.length();
    if (dist > 0.001) toP.divideScalar(dist);
    else toP.set(0, 0, 1);

    // удержание врага в пределах арены
    const dW = Math.hypot(e.pos.x, e.pos.z);
    if (dW > 290) {
      e.pos.x *= 290 / dW;
      e.pos.z *= 290 / dW;
    }

    // движение к игроку (дальние — стоят/подходят)
    const wantDist = e.T.ranged ? 16 : Math.max(1.4, e.T.scale * 1.1);
    if (dist > wantDist) {
      e.pos.x += toP.x * e.speed * dt;
      e.pos.z += toP.z * e.speed * dt;
    } else if (e.T.ranged && dist < 10) {
      e.pos.x -= toP.x * e.speed * 0.6 * dt;
      e.pos.z -= toP.z * e.speed * 0.6 * dt;
    }
    // коллизии с миром
    for (const c of colliders) {
      const dx = e.pos.x - c.x, dz = e.pos.z - c.z;
      const rr = c.r + e.T.scale * 0.8;
      const d2 = dx * dx + dz * dz;
      if (d2 < rr * rr && d2 > 0.001) {
        const d = Math.sqrt(d2);
        e.pos.x = c.x + dx / d * rr;
        e.pos.z = c.z + dz / d * rr;
      }
    }
    e.pos.y = terrainH(e.pos.x, e.pos.z) + 1.1 * e.T.scale;

    // атака
    e.atkCd -= dt;
    if (e.T.ranged) {
      if (dist < 34 && e.atkCd <= 0) {
        e.atkCd = rand(1.8, 2.6);
        spawnProjectile(e.pos.clone().setY(e.pos.y + 0.5), player.pos.clone().setY(player.pos.y + 1.4), e.T.dmg, 0x00ff88);
      }
    } else if (dist < 1.2 + e.T.scale * 0.8 + player.radius && e.atkCd <= 0) {
      e.atkCd = 1.1;
      damagePlayer(e.T.dmg, e.pos);
    }
    // боссовая ударная волна
    if (e.T.boss) {
      e.shockCd -= dt;
      if (e.shockCd <= 0 && dist < 12) {
        e.shockCd = 4.5;
        rings.spawn(e.pos, 0xffff00, 16, 0.8);
        SFX.boss();
        if (dist < 10 && player.onGround) damagePlayer(25, e.pos);
      }
    }
    // анимация
    e.bobT += dt * (2 + e.speed);
    e.group.position.set(e.pos.x, e.pos.y + Math.abs(Math.sin(e.bobT)) * 0.25, e.pos.z);
    e.group.rotation.y = Math.atan2(toP.x, toP.z) + Math.PI;
    if (e.flash > 0) {
      e.flash -= dt;
      e.bodyMat.emissiveIntensity = 5;
    } else e.bodyMat.emissiveIntensity = 1.1;
  }
}

function updateProjectiles(dt) {
  for (let i = projectiles.length - 1; i >= 0; i--) {
    const pr = projectiles[i];
    pr.life -= dt;
    pr.m.position.add(pr.dir.clone().multiplyScalar(pr.speed * dt));
    const p = pr.m.position;
    const hitPlayer = p.distanceTo(player.pos.clone().setY(player.pos.y + 1.2)) < 1.0;
    if (hitPlayer) {
      damagePlayer(pr.dmg, p);
      sparks.burst(p, 0x00ff88, 8, 4);
    }
    let hitObstacle = false;
    for (const c of colliders) {
      const dx = p.x - c.x, dz = p.z - c.z;
      if (dx * dx + dz * dz < c.r * c.r && Math.abs(p.y - terrainH(c.x, c.z)) < 6) {
        hitObstacle = true; break;
      }
    }
    if (hitPlayer || hitObstacle || pr.life <= 0 || p.y < terrainH(p.x, p.z)) {
      scene.remove(pr.m);
      if (pr.customMat) pr.customMat.dispose();
      projectiles.splice(i, 1);
    }
  }
}

function updatePickups(dt, t) {
  for (let i = pickups.length - 1; i >= 0; i--) {
    const p = pickups[i];
    p.m.rotation.z = t * 2;
    p.m.position.y = p.baseY + Math.sin(t * 3 + p.t) * 0.2;
    const dx = player.pos.x - p.x, dz = player.pos.z - p.z;
    const d = Math.hypot(dx, dz);
    if (d > 0.001 && d < 7) { // магнит
      p.x += dx / d * 9 * dt;
      p.z += dz / d * 9 * dt;
      p.baseY = terrainH(p.x, p.z) + 0.8;
    }
    p.m.position.x = p.x; p.m.position.z = p.z;
    if (d < 1.6) {
      if (p.kind === 'coin') {
        const v = 5 + Math.floor(wave.num * 0.5);
        player.coins += v;
        Quests.onCoinsPickup(v);
        showToastSilent(v);
      } else if (p.kind === 'health') {
        player.hp = Math.min(player.maxHp, player.hp + 30);
      } else if (p.kind === 'ammo') {
        WEAPONS[1].ammo += 12;
        WEAPONS[2].ammo += 5;
        showToast('📦 Патроны: дробовик +12, рельсотрон +5', 1.6);
      }
      SFX.pickup();
      scene.remove(p.m);
      pickups.splice(i, 1);
      updateHUD();
    }
  }
}
function showToastSilent(v) {
  dmgNums.show(player.pos.clone(), `+${v}⬡`, '#ffcc00');
}

const currentSky = new THREE.Color();
function updateDayNight(dt) {
  dayT = (dayT + dt / 150) % 1; // цикл 150 сек
  const ang = dayT * Math.PI * 2;
  const sx = Math.cos(ang) * 320, sy = Math.sin(ang) * 260, sz = 120;
  sunOrb.position.set(sx, sy, sz);
  sun.position.set(sx * 0.5, Math.max(20, sy * 0.5), sz * 0.5);
  const day = clamp(sy / 200, 0, 1);
  const dusk = clamp(1 - Math.abs(sy) / 160, 0, 1);
  sun.intensity = 0.15 + day * 1.3;
  sun.color.setRGB(1, 0.75 + day * 0.2, 0.55 + day * 0.35);
  hemi.intensity = 0.35 + day * 0.5;
  sunOrb.visible = sy > -60;
  // фон без утечки памяти
  currentSky.copy(cNight);
  if (sy > -20) currentSky.lerp(cDawn, dusk);
  if (sy > 80) currentSky.lerp(cDay, smoothstep(80, 240, sy));
  scene.background = currentSky;
  scene.fog.color.copy(currentSky).lerp(fogDay, day * 0.4);
  window._stars.material.opacity = clamp(1 - day * 2.5, 0.15, 0.9);
  window._crystalMat.emissiveIntensity = 0.7 + (1 - day) * 0.8;
  window._beaconRing.rotation.z += dt * 1.5;
  window._beaconRing.position.y = 4.5 + Math.sin(gameTime * 2) * 0.4;
}

let beaconPromptT = 0;
function animate(now) {
  requestAnimationFrame(animate);
  const dt = Math.min((now - last) / 1000, 0.05);
  last = now;
  const t = now / 1000;

  if (invulnT > 0) invulnT = Math.max(0, invulnT - dt);

  if (started && !paused && !gameOver && !shop.open) {
    gameTime += dt;

    // волны
    if (wave.state === 'intermission') {
      wave.timer -= dt;
      if (Math.ceil(wave.timer) !== wave._lastCount && wave.timer > 0) {
        wave._lastCount = Math.ceil(wave.timer);
        if (wave.timer <= 3) showToast(`Волна через ${wave._lastCount}…`, 1);
      }
      if (wave.timer <= 0) startWave();
    } else if (wave.state === 'active' && wave.spawnQueue.length) {
      wave.spawnTimer -= dt;
      if (wave.spawnTimer <= 0 && enemies.length < 34) {
        wave.spawnTimer = 0.7;
        const type = wave.spawnQueue.shift();
        let candX = 0, candZ = 0, spawned = false;
        for (let tries = 0; tries < 8; tries++) {
          const a = Math.random() * Math.PI * 2;
          const r = rand(40, 60);
          const tx = player.pos.x + Math.cos(a) * r;
          const tz = player.pos.z + Math.sin(a) * r;
          if (Math.hypot(tx, tz) < 275 && terrainH(tx, tz) < 26) {
            candX = tx; candZ = tz; spawned = true; break;
          }
        }
        if (!spawned) {
          const toCenter = new THREE.Vector2(-player.pos.x, -player.pos.z).normalize();
          candX = player.pos.x + toCenter.x * 45;
          candZ = player.pos.z + toCenter.y * 45;
        }
        makeEnemy(type, candX, candZ);
        updateWaveCounter();
      }
    }

    movePlayer(dt);

    // стрельба
    weaponState.cooldown -= dt;
    if (mouseDown && document.pointerLockElement === canvas) shoot();

    updateEnemies(dt);
    updateProjectiles(dt);
    updatePickups(dt, t);
    updateDayNight(dt);

    // подсказка маяка
    const dBeacon = Math.hypot(player.pos.x, player.pos.z);
    if (dBeacon < 8 && !shop.open) {
      beaconPromptT -= dt;
      if (beaconPromptT <= 0) { showToast('⬡ Маяк: нажми [E] — магазин', 1.6); beaconPromptT = 5; }
    }

    // комбо-серия
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        if (combo >= 3) showToast(`Комбо завершено: x${combo} подряд!`, 2);
        combo = 0;
        comboTimer = 0;
      }
      updateComboHUD();
    }
  }

  // камера
  const speed2d = Math.hypot(player.vel.x, player.vel.z);
  const targetBob = speed2d > 0.1 ? Math.sin(player.bobT * 6) * 0.06 : 0;
  player.currentBob = lerp(player.currentBob || 0, targetBob, 1 - Math.pow(0.001, dt));
  const eyeH = 1.75;
  camera.position.set(player.pos.x, player.pos.y + eyeH + player.currentBob, player.pos.z);
  if (shake > 0) {
    shake = Math.max(0, shake - dt * 3);
    camera.position.x += rand(-1, 1) * shake * 0.25;
    camera.position.y += rand(-1, 1) * shake * 0.25;
  }
  camera.rotation.set(player.pitch, player.yaw, 0);

  // процедурная анимация оружия (отдача и покачивание)
  weaponRecoil = lerp(weaponRecoil, 0, 1 - Math.pow(0.0001, dt));
  weaponRecoilRot = lerp(weaponRecoilRot, 0, 1 - Math.pow(0.0001, dt));
  const swayX = Math.cos(player.bobT * 3) * 0.012;
  const swayY = Math.abs(Math.sin(player.bobT * 6)) * 0.014;
  weaponHolder.position.set(0.28 + swayX, -0.24 + swayY - weaponRecoil * 0.3, -0.48 + weaponRecoil);
  weaponHolder.rotation.set(weaponRecoilRot, -swayX * 2, 0);

  // вспышка выстрела
  if (flashTime > 0) { flashTime -= dt; if (flashTime <= 0) flashLight.intensity = 0; }

  sparks.update(dt);
  beams.update(dt);
  rings.update(dt);
  dmgNums.update(dt);
  drawMinimap();

  renderer.render(scene, camera);
}
requestAnimationFrame(animate);

updateHUD();
console.log('%c NEON WASTELAND готов. Выживи. ', 'background:#0ff;color:#000;font-size:16px;padding:4px 10px;');
