
// ================= 常數與工具 =================
let THREE, OrbitControls, CSS2DRenderer, CSS2DObject, RoundedBoxGeometry, BufferGeometryUtils, SimplexNoise;

const R = 2.02, SPACING = 2.28, TOP = 0.65, WATER_Y = -0.18;
const SQ3 = Math.sqrt(3);
const IS_MOBILE = matchMedia('(max-width: 800px)').matches;
const PAL = {
  coral: '#db6a41', ink: '#211d1d', cream: '#fff8f4', yellow: '#fcea8b', stone: '#c5b5a7', green: '#71806a',
  glass: '#86a8a6', wood: '#b48560', teal: '#3e7c8c', plants: ['#9cc27a', '#8db86f', '#728f5f'],
  pastel: ['#f2b5c6', '#58a6a6', '#6f7fb5'], glow: '#ffc777',
};

function mulberry32(a) {
  return function () {
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
const rand = mulberry32(20261029);
const rr = (a, b) => a + (b - a) * rand();
const pick = (arr) => arr[Math.floor(rand() * arr.length)];
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const smooth = (a, b, x) => { const t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); };
const easeInOutCubic = (t) => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

// 語言：#en 切英文
let LANG = 'zh';
function readLang() { LANG = location.hash.replace('#', '') === 'en' ? 'en' : 'zh'; }
readLang();
const tr = (zh, en) => (LANG === 'en' && en) ? en : zh;
function applyStaticLang() {
  document.documentElement.lang = LANG === 'en' ? 'en' : 'zh-Hant';
  document.querySelectorAll('[data-en]').forEach((el) => {
    if (el.dataset.zh === undefined) el.dataset.zh = el.textContent;
    el.textContent = LANG === 'en' ? el.dataset.en : el.dataset.zh;
  });
  document.querySelectorAll('[data-en-ph]').forEach((el) => {
    if (el.dataset.zhPh === undefined) el.dataset.zhPh = el.placeholder;
    el.placeholder = LANG === 'en' ? el.dataset.enPh : el.dataset.zhPh;
  });
  document.querySelectorAll('[data-en-label]').forEach((el) => {
    if (el.dataset.zhLabel === undefined) el.dataset.zhLabel = el.getAttribute('aria-label') || '';
    el.setAttribute('aria-label', LANG === 'en' ? el.dataset.enLabel : el.dataset.zhLabel);
  });
}

const store = {
  get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* 無痕或封鎖時略過 */ } },
};

// 六角座標：pointy-top，頂點朝 ±z
function axialToWorld(q, r) { return { x: SQ3 * SPACING * (q + r / 2), z: 1.5 * SPACING * r }; }
// 第 k 個頂點（k=0..5），角度 a = π/6 + kπ/3；世界座標 (r cos a, -r sin a)
function hexVert(k, rad) { const a = Math.PI / 6 + k * Math.PI / 3; return [rad * Math.cos(a), -rad * Math.sin(a)]; }
// 第 k 條邊中點（介於頂點 k-1 與 k 之間，角度 kπ/3）
function hexMid(k, rad) { const a = k * Math.PI / 3, m = rad * Math.cos(Math.PI / 6); return [m * Math.cos(a), -m * Math.sin(a)]; }
function hexGeo(rad) { return new THREE.CircleGeometry(rad, 6).rotateZ(Math.PI / 6).rotateX(-Math.PI / 2); }
function hexRingGeo(r0, r1) { return new THREE.RingGeometry(r0, r1, 6, 1).rotateZ(Math.PI / 6).rotateX(-Math.PI / 2); }

// ================= 全域狀態 =================
const S = {
  renderer: null, labelRenderer: null, scene: null, camera: null, controls: null,
  dirty: true, time: 0, minute: 600, clockPaused: false, reduced: matchMedia('(prefers-reduced-motion: reduce)').matches,
  center: null, islands: [], islandById: {}, itemById: {}, uTime: { value: 0 }, night: 0,
  fly: null, cardOpen: false, overview: false,
};
const markDirty = () => { S.dirty = true; };

// ================= 渲染器／相機／控制 =================
function setupRenderer() {
  const stage = document.getElementById('stage');
  const r = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
  r.setPixelRatio(Math.min(devicePixelRatio, IS_MOBILE ? 1.4 : 1.75));
  r.setSize(innerWidth, innerHeight);
  r.shadowMap.enabled = true; r.shadowMap.type = THREE.PCFSoftShadowMap;
  r.outputColorSpace = THREE.SRGBColorSpace;
  r.toneMapping = THREE.ACESFilmicToneMapping; r.toneMappingExposure = 1;
  stage.appendChild(r.domElement);
  r.domElement.setAttribute('tabindex', '0');
  r.domElement.setAttribute('aria-label', tr('3D 議題城市，方向鍵旋轉鏡頭', '3D issue city, arrow keys rotate'));
  S.renderer = r;

  const lr = new CSS2DRenderer({ element: document.getElementById('labels') });
  lr.setSize(innerWidth, innerHeight);
  S.labelRenderer = lr;

  S.scene = new THREE.Scene();
  S.scene.fog = new THREE.Fog(0xf4eee3, 42, 150);
  S.camera = new THREE.PerspectiveCamera(32, innerWidth / innerHeight, 0.3, 320);

  const c = new OrbitControls(S.camera, r.domElement);
  c.enableDamping = true; c.dampingFactor = 0.07; c.enablePan = false;
  c.minPolarAngle = THREE.MathUtils.degToRad(25); c.maxPolarAngle = THREE.MathUtils.degToRad(70);
  c.minDistance = 3; c.maxDistance = 70;
  c.addEventListener('change', markDirty);
  S.controls = c;
  r.domElement.addEventListener('pointerdown', () => { S.fly = null; });

  new ResizeObserver(() => {
    const w = innerWidth, h = innerHeight;
    S.renderer.setSize(w, h); S.labelRenderer.setSize(w, h);
    S.camera.aspect = w / h; S.camera.updateProjectionMatrix(); markDirty();
  }).observe(document.body);
}

const OVERVIEW_DIR = () => new THREE.Vector3(.24, .33, .87).normalize();
function overviewDist() { const a = innerWidth / innerHeight; return a > 1.3 ? 28.5 : a > .8 ? 38 : 56; }

// 飛行：同時插值 position 與 target；reduced-motion 時瞬移
function flyTo(target, pos) {
  if (S.reduced) {
    S.controls.target.copy(target); S.camera.position.copy(pos); S.controls.update(); S.fly = null; markDirty(); return;
  }
  S.fly = { t0: performance.now(), p0: S.camera.position.clone(), t0v: S.controls.target.clone(), p1: pos.clone(), t1: target.clone() };
  markDirty();
}
function goOverview(instant) {
  S.overview = false;
  const t = S.center.clone(); const p = t.clone().addScaledVector(OVERVIEW_DIR(), overviewDist());
  if (instant) { S.controls.target.copy(t); S.camera.position.copy(p); S.controls.update(); markDirty(); }
  else flyTo(t, p);
}
function stepFly(now) {
  if (!S.fly) return;
  const k = clamp((now - S.fly.t0) / 800, 0, 1), e = easeInOutCubic(k);
  S.camera.position.lerpVectors(S.fly.p0, S.fly.p1, e);
  S.controls.target.lerpVectors(S.fly.t0v, S.fly.t1, e);
  if (k >= 1) S.fly = null;
  markDirty();
}
