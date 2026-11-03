// Spellus: knoopt fysica, Spot, wereld, invoer, score, geluid en opslag aan elkaar.
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { R, newBall, step, predictLanding } from './physics.js';
import { newDog, update as denk, command, reward, pet, applyAway, serialize, COMMANDS } from './brain.js';
import { createDog } from './dogModel.js';
import { furMesh } from './fur.js';
import { SPOT } from './dogs.js';
import { createWorld, GRENZEN, OBSTAKELS, SPELER } from './world.js';
import { createThrow } from './throw.js';
import { createPhoto, filterShader } from './photo.js';
import { LEVEN, newBurst, explode, stepBurst } from './burst.js';

const $ = (id) => document.getElementById(id);
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const rnd = (a, b) => a + Math.random() * (b - a);
const params = new URLSearchParams(location.search);
const mobiel = matchMedia('(pointer: coarse)').matches;
// Kwaliteit: telefoons krijgen minder vachtlagen, gras en schaduwdetail.
const Q = mobiel
  ? { dpr: 1.5, lagen: 8, gras: 30000, schaduw: 1024, neerslag: 1500, aa: 0, envElke: 8 }
  : { dpr: 2, lagen: 18, gras: 140000, schaduw: 2048, neerslag: 5000, aa: 4, envElke: 3 };
const BELICHTING = 0.5;
const STAP = 1 / 240;
const OPSLAG = 'spot-fetch-v1';

// ---------- opslag ----------
let bewaard = {};
try {
  if (!params.has('reset')) bewaard = JSON.parse(localStorage.getItem(OPSLAG)) || {};
} catch { /* geen opslag (privévenster): dan begint Spot gewoon opnieuw */ }
const dog = newDog(SPOT, bewaard);
if (bewaard.t) applyAway(dog, (Date.now() - bewaard.t) / 1000);
let score = bewaard.score | 0, beste = bewaard.beste | 0;
function bewaar() {
  try {
    localStorage.setItem(OPSLAG, JSON.stringify({ ...serialize(dog), score, beste, t: Date.now() }));
  } catch { /* vol of geblokkeerd: het spel loopt door zonder opslag */ }
}
setInterval(bewaar, 5000);
addEventListener('pagehide', bewaar);

// ---------- beeld ----------
const canvas = $('c');
const renderer = new THREE.WebGLRenderer({ canvas, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, Q.dpr));
renderer.shadowMap.enabled = true;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = BELICHTING;
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(55, 1, 0.05, 1500);
camera.position.set(SPELER.x, 1.65, SPELER.z + 2); // de speler staat iets achter het punt waar Spot de bal brengt
const composer = new EffectComposer(renderer, new THREE.WebGLRenderTarget(1, 1, { type: THREE.HalfFloatType, samples: Q.aa }));
const filter = new ShaderPass(filterShader);
composer.addPass(new RenderPass(scene, camera));
composer.addPass(new OutputPass());
composer.addPass(filter);

const world = createWorld(scene, renderer, Q);
if (params.has('tijd')) { world.st.tijd = clamp(+params.get('tijd') || 0, 0, 23.99); world.st.vast = true; }
if (params.has('weer')) { world.setWeer(params.get('weer'), true); world.st.vast = true; }
const model = createDog(SPOT, Q.lagen);
scene.add(model.group);

// ---------- bal ----------
function viltTextuur() {
  const W = 512, H = 256, c = document.createElement('canvas');
  c.width = W; c.height = H;
  const g = c.getContext('2d');
  g.fillStyle = '#cde23c';
  g.fillRect(0, 0, W, H);
  for (let i = 0; i < 9000; i++) {
    g.fillStyle = i % 2 ? 'rgba(255,255,200,0.1)' : 'rgba(90,110,0,0.1)';
    g.fillRect(Math.random() * W, Math.random() * H, 2, 2);
  }
  // De naad: de bekende gebogen lijn over de bol, uitgerold op de kaart.
  g.fillStyle = '#f4f4ea';
  for (let t = 0; t < Math.PI * 2; t += 0.004) {
    const x = 0.75 * Math.cos(t) + 0.25 * Math.cos(3 * t), y = 0.75 * Math.sin(t) - 0.25 * Math.sin(3 * t), z = 0.866 * Math.sin(2 * t);
    const theta = Math.acos(clamp(y, -1, 1)), px = ((Math.atan2(z, -x) / (Math.PI * 2) + 1) % 1) * W;
    for (const dx of [-W, 0, W]) {
      g.beginPath();
      g.ellipse(px + dx, (theta / Math.PI) * H, 4 / Math.max(0.2, Math.sin(theta)), 4, 0, 0, 7);
      g.fill();
    }
  }
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}
const balGeo = new THREE.SphereGeometry(R, 32, 20);
const balMesh = furMesh(balGeo, {
  kleur: 0xffffff, map: viltTextuur(), lengte: 0.002, cel: 0.0007, lagen: Math.ceil(Q.lagen / 2),
  maat: [2 * Math.PI * R, Math.PI * R], ruw: 0.95, hang: 0, wortel: 0.7,
});
scene.add(balMesh);
const balMats = balMesh.children.map((m) => m.material);

let ball = newBall();
let mode = 'hand'; // 'hand' | 'vrij' | 'bek'
let geland = true, acc = 0, landT = 0, slepend = false, gegooid = false;
const env = { surfaceAt: world.surfaceAt, nat: 0, grenzen: GRENZEN, obstakels: OBSTAKELS };
const hand = new THREE.Vector3(), sleepPos = new THREE.Vector3(), v3 = new THREE.Vector3(), UP = new THREE.Vector3(0, 1, 0);
const quat = new THREE.Quaternion(), ray = new THREE.Raycaster(), muis = new THREE.Vector2();

// ---------- doelwit en score ----------
const doel = new THREE.Group();
for (const [r0, r1, kleur] of [[0, 0.45, 0xd8232a], [1.5, 1.75, 0xffffff], [3.1, 3.35, 0xffffff]]) {
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(r0, r1, 48).rotateX(-Math.PI / 2),
    new THREE.MeshBasicMaterial({ color: kleur, transparent: true, opacity: 0.8, depthWrite: false }));
  ring.position.y = 0.14;
  doel.add(ring);
}
const paal = new THREE.Mesh(new THREE.CylinderGeometry(0.015, 0.015, 1.6, 6), new THREE.MeshStandardMaterial({ color: 0xeeeeee }));
paal.position.y = 0.8;
const vlag = new THREE.Mesh(new THREE.PlaneGeometry(0.45, 0.28), new THREE.MeshStandardMaterial({ color: 0xd8232a, side: THREE.DoubleSide }));
vlag.position.set(0.24, 1.44, 0);
doel.add(paal, vlag);
scene.add(doel);
function nieuwDoel() {
  doel.position.set(rnd(-13, 13), 0, rnd(-14, 3));
}
nieuwDoel();
// Kring op het water bij een plons
const kring = new THREE.Mesh(
  new THREE.RingGeometry(0.85, 1, 40).rotateX(-Math.PI / 2),
  new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0, depthWrite: false }));
scene.add(kring);
let kringT = 1;
// Wat er bij een inslag opspat: druppels, sneeuw, zand of aarde
const burst = newBurst(48);
const spatten = new THREE.Points(
  new THREE.BufferGeometry().setAttribute('position', new THREE.BufferAttribute(burst.p, 3)),
  new THREE.PointsMaterial({ size: 5, sizeAttenuation: false, transparent: true, opacity: 0, depthWrite: false })); // vaste maat: een verre inslag blijft te zien
spatten.frustumCulled = false; // de punten verhuizen bij elke inslag
scene.add(spatten);
const ZAND = 0xeedfb4, AARDE = 0x5a4526, MODDER = new THREE.Color(0x3a2a17);
function spat(e, kracht) {
  const kleur = spatten.material.color;
  if (e.type === 'plons' || e.surf === 'sneeuw') kleur.setScalar(2.5); // feller dan wit, anders valt het weg tegen water en sneeuw
  else if (e.surf === 'gras') kleur.set(AARDE).lerp(MODDER, world.st.nat);
  else if (e.surf === 'zand') kleur.set(ZAND);
  else return; // beton, hout en de vijverbodem spatten niet
  kleur.multiplyScalar(1 - 0.75 * world.st.nacht); // onverlicht, dus 's nachts zelf dimmen
  explode(burst, e.x, e.type === 'plons' ? -0.04 : 0.03, e.z, kracht);
}

// ---------- geluid: korte gesynthetiseerde klanken ----------
let ac = null, stil = false, regenGain = null;
function geluidAan() {
  if (ac) return;
  try {
    ac = new AudioContext();
  } catch { return; }
  const buf = ac.createBuffer(1, ac.sampleRate, ac.sampleRate), d = buf.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  ac.ruis = buf;
  const bron = ac.createBufferSource(), lp = ac.createBiquadFilter();
  bron.buffer = buf; bron.loop = true;
  lp.frequency.value = 2500;
  regenGain = ac.createGain();
  regenGain.gain.value = 0;
  bron.connect(lp).connect(regenGain).connect(ac.destination);
  bron.start();
}
// Zoals Phaser bij een verborgen tabblad: geluid uit, anders regent het op de achtergrond door.
document.addEventListener('visibilitychange', () => ac && (document.hidden ? ac.suspend() : ac.resume()));
function klank({ ruis, type = 'sine', f0, f1 = f0, duur, vol, wacht = 0 }) {
  if (!ac || stil) return;
  const t = ac.currentTime + wacht, g = ac.createGain();
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + duur);
  let bron;
  if (ruis) {
    bron = ac.createBufferSource();
    bron.buffer = ac.ruis;
    const bp = ac.createBiquadFilter();
    bp.type = 'bandpass';
    bp.frequency.setValueAtTime(f0, t);
    bp.frequency.exponentialRampToValueAtTime(f1, t + duur);
    bron.connect(bp).connect(g);
  } else {
    bron = ac.createOscillator();
    bron.type = type;
    bron.frequency.setValueAtTime(f0, t);
    bron.frequency.exponentialRampToValueAtTime(f1, t + duur);
    bron.connect(g);
  }
  g.connect(ac.destination);
  bron.start(t);
  bron.stop(t + duur);
}
const SFX = {
  stuit: (v = 1) => klank({ f0: 190, f1: 60, duur: 0.09, vol: 0.5 * v }),
  plons: (v = 1) => klank({ ruis: true, f0: 1500, f1: 300, duur: 0.5, vol: 0.5 * v }),
  zwiep: () => klank({ ruis: true, f0: 600, f1: 2400, duur: 0.18, vol: 0.2 }),
  pak: () => klank({ ruis: true, f0: 900, f1: 500, duur: 0.06, vol: 0.25 }),
  koek: () => klank({ type: 'triangle', f0: 880, f1: 1320, duur: 0.12, vol: 0.2 }),
  blaf: (v = 1) => klank({ type: 'sawtooth', f0: 420, f1: 170, duur: 0.16, vol: 0.3 * v }),
  vogel: () => [0, 0.14, 0.3].forEach((w) => klank({ f0: 2600, f1: 3900, duur: 0.09, vol: 0.12, wacht: w })),
};

// ---------- HUD ----------
let toastT = 0;
function zeg(tekst) {
  $('toast').textContent = tekst;
  $('toast').classList.add('aan');
  toastT = 3.2;
}
const balken = Object.fromEntries([...document.querySelectorAll('[data-stat]')].map((el) => [el.dataset.stat, el]));
const knoppen = Object.fromEntries([...document.querySelectorAll('[data-cmd]')].map((el) => [el.dataset.cmd, el]));
function hud() {
  for (const k in balken) {
    const v = Math.round(dog.stats[k]);
    balken[k].style.setProperty('--v', `${v}%`);
    balken[k].setAttribute('aria-valuenow', v);
    // Honger en dorst zijn erger naarmate ze hoger staan.
    balken[k].classList.toggle('slecht', k === 'honger' || k === 'dorst' ? v > 70 : v < 25);
  }
  for (const c of COMMANDS) knoppen[c].style.setProperty('--m', `${Math.round(dog.mastery[c] * 100)}%`);
  $('score').textContent = score;
  $('beste').textContent = beste;
  const { tijd, weer } = world.st;
  $('klok').textContent = `${String(Math.floor(tijd)).padStart(2, '0')}:${String(Math.floor((tijd % 1) * 60)).padStart(2, '0')} · ${weer}`;
}
setInterval(hud, 200);

const ctx = {
  ball: { mode, p: ball.p, rust: false }, land: null, worp: 0, nat: 0,
  player: SPELER, hand, bowls: world.bowls, vijverRand: world.vijverRand,
  surfaceAt: world.surfaceAt, grenzen: GRENZEN, obstakels: OBSTAKELS, events: [], rand: Math.random, say: zeg,
};

for (const c of COMMANDS)
  knoppen[c].addEventListener('click', () => {
    geluidAan();
    command(dog, c, ctx);
  });
$('beloon').addEventListener('click', () => {
  geluidAan();
  SFX.koek();
  const cmd = reward(dog);
  zeg(cmd ? `Brave hond! Spot beheerst "${cmd}" nu voor ${Math.round(dog.mastery[cmd] * 100)}%` : 'Spot smult van het koekje');
});
function vul(soort) {
  world.bowls[soort].vol = 1;
  zeg(soort === 'voer' ? 'Voerbak gevuld' : 'Waterbak gevuld');
}
$('voer').addEventListener('click', () => vul('voer'));
$('water').addEventListener('click', () => vul('water'));
$('geluid').addEventListener('click', () => {
  geluidAan();
  stil = !stil;
  $('geluid').setAttribute('aria-pressed', stil);
  $('geluid').textContent = stil ? 'Geluid uit' : 'Geluid aan';
});
// Volledig scherm zonder navigatiebalk waar dat kan, zoals toggleFullscreen van de ScaleManager van Phaser.
const scherm = $('scherm');
scherm.hidden = !document.fullscreenEnabled; // Safari op de iPhone kan het niet
scherm.addEventListener('click', () => {
  if (document.fullscreenElement) document.exitFullscreen();
  else document.documentElement.requestFullscreen({ navigationUI: 'hide' }).catch(() => { /* geweigerd: het spel blijft in het venster */ });
});
document.addEventListener('fullscreenchange', () => scherm.setAttribute('aria-pressed', !!document.fullscreenElement));

// ---------- fotomodus ----------
// Het oog went aan het donker: 's nachts gaat de belichting omhoog, anders is een zwarte hond onvindbaar.
const belichting = () => BELICHTING * (1 + 3 * world.st.nacht);
const focus = new THREE.Vector3();
const render = () => composer.render();
const foto = createPhoto({
  renderer, camera, canvas, pass: filter, render, belichting,
  focus: () => focus.set(dog.pos.x, 0.45, dog.pos.z),
  ui: { lens: $('lens'), lensUit: $('lensUit'), belichting: $('belichting'), belichtingUit: $('belichtingUit'), filter: $('filter'), sluiter: $('sluiter'), flits: $('flits') },
});
$('foto').addEventListener('click', () => foto.zet(true));
$('fotoUit').addEventListener('click', () => foto.zet(false));

// ---------- invoer ----------
function straal(e) {
  muis.set((e.clientX / innerWidth) * 2 - 1, -(e.clientY / innerHeight) * 2 + 1);
  ray.setFromCamera(muis, camera);
  return ray.ray;
}
const pakBal = createThrow(canvas, {
  // De bal pakken: aanraking in de buurt van de bal in de hand.
  grijp(e) {
    if (mode !== 'hand') return false;
    v3.copy(hand).project(camera);
    return Math.hypot(((v3.x + 1) / 2) * innerWidth - e.clientX, ((1 - v3.y) / 2) * innerHeight - e.clientY) < Math.max(70, innerHeight * 0.1);
  },
  sleep(x, y) {
    slepend = true;
    straal({ clientX: x, clientY: y }).at(0.9, sleepPos);
  },
  worp: gooi,
});
canvas.addEventListener('pointerdown', (e) => {
  geluidAan();
  if (foto.aan || pakBal(e)) return;
  // Tik op Spot om te aaien, op een bak om hem te vullen.
  const r = straal(e);
  if (r.distanceToPoint(v3.set(dog.pos.x, 0.45, dog.pos.z)) < 0.45) {
    if (pet(dog)) zeg('Spot geniet van de aai');
    return;
  }
  for (const soort of ['voer', 'water']) if (r.distanceToPoint(v3.set(world.bowls[soort].x, 0.05, world.bowls[soort].z)) < 0.3) vul(soort);
});

// w: { speed, yaw, elev, zijspin, backspin } uit throwFromDrag, of null als er niet gegooid is
function gooi(w) {
  slepend = false;
  if (!w || mode !== 'hand') return;
  const ce = Math.cos(w.elev);
  const dir = new THREE.Vector3(Math.sin(w.yaw) * ce, Math.sin(w.elev), -Math.cos(w.yaw) * ce);
  const as = v3.crossVectors(dir, UP).normalize(); // backspin draait om richting × omhoog
  // Zijspin om de verticale as; het teken volgt uit ω × v: een bocht naar rechts geeft een baan naar rechts.
  ball = newBall(balMesh.position, dir.multiplyScalar(w.speed), { x: as.x * w.backspin, y: -w.zijspin, z: as.z * w.backspin });
  mode = 'vrij';
  geland = false;
  acc = landT = 0;
  ctx.worp++;
  ctx.land = predictLanding(ball, env);
  if (!gegooid) $('hint').hidden = gegooid = true;
  SFX.zwiep();
}

function balGebeurtenis(e) {
  const hard = clamp(e.speed / 8, 0.1, 1);
  if (e.type === 'plons') {
    SFX.plons(hard);
    kring.position.set(e.x, -0.04, e.z);
    kringT = 0;
  } else SFX.stuit(hard * (e.surf === 'beton' ? 1 : 0.5));
  spat(e, hard);
  if (geland || e.surf === 'hout') return; // een boomstam telt niet als landing
  geland = true;
  // Trefzekerheid: hoe dichter de eerste landing bij het midden, hoe meer punten.
  const mis = Math.hypot(e.x - doel.position.x, e.z - doel.position.z);
  const punten = Math.round(100 * Math.max(0, 1 - mis / 6));
  score += punten;
  beste = Math.max(beste, punten);
  zeg(punten ? `${punten} punten — ${mis.toFixed(1).replace('.', ',')} m van het midden` : `Mis: ${mis.toFixed(1).replace('.', ',')} m naast het doel`);
}

function laatVallen() {
  model.mouth.getWorldPosition(v3);
  ball = newBall(v3, { x: Math.sin(dog.heading) * 0.8, y: 0.6, z: Math.cos(dog.heading) * 0.8 });
  mode = 'vrij';
  acc = 0;
}
function hondGebeurtenis(e) {
  if (e.type === 'pak') {
    mode = 'bek';
    SFX.pak();
  } else if (e.type === 'blaf') {
    model.bark();
    SFX.blaf();
  } else if (e.type === 'val' || !e.bijSpeler) laatVallen();
  else {
    mode = 'hand';
    if (e.netjes) {
      score += 25;
      zeg('Netjes losgelaten: 25 punten erbij. Vergeet de beloning niet');
    }
    nieuwDoel();
    bewaar();
  }
}

function simuleer(dt) {
  env.nat = ctx.nat = world.st.nat;
  if (mode === 'vrij') {
    acc += dt;
    for (; acc >= STAP; acc -= STAP) step(ball, STAP, env);
    for (const e of ball.events.splice(0)) balGebeurtenis(e);
    if (!ball.rust && ball.p.y > 1 && (landT -= dt) <= 0) {
      landT = 0.25;
      ctx.land = predictLanding(ball, env);
    }
  }
  // Wat dichtbij gebeurt leidt meer af dan wat ver weg is.
  ctx.events = world.events.splice(0).map((e) => {
    if (e.klank) SFX[e.klank](0.4);
    const ver = Math.hypot(e.pos.x - dog.pos.x, e.pos.z - dog.pos.z);
    return { ...e, sterkte: e.sterkte * clamp(1.4 - ver / 18, 0.15, 1) };
  });
  Object.assign(ctx.ball, { mode, p: ball.p, rust: ball.rust });
  denk(dog, dt, ctx);
  for (const e of dog.events.splice(0)) hondGebeurtenis(e);

  if ((toastT -= dt) <= 0) $('toast').classList.remove('aan');
  if (kringT < 1) {
    kringT += dt / 0.9;
    kring.scale.setScalar(0.15 + kringT * 1.2);
    kring.material.opacity = 0.6 * (1 - kringT);
  }
  if (stepBurst(burst, dt)) {
    spatten.geometry.attributes.position.needsUpdate = true;
    spatten.material.opacity = Math.max(0, 1 - burst.t / LEVEN);
  }
}

// ---------- lus ----------
const kijk = new THREE.Vector3(0, 0.7, 0), wil = new THREE.Vector3();
function resize() {
  const w = innerWidth, h = innerHeight;
  renderer.setSize(w, h, false);
  composer.setSize(w, h);
  camera.aspect = w / h;
  if (!foto.aan) camera.fov = w < h ? 68 : 55; // staand scherm: wijder, anders valt Spot buiten beeld
  camera.updateProjectionMatrix();
}
addEventListener('resize', resize);
resize();

let vorig = performance.now();
function frame(nu) {
  requestAnimationFrame(frame);
  const echt = Math.min((nu - vorig) / 1000, 0.1);
  vorig = nu;
  const dt = foto.aan ? 0 : echt; // in fotomodus staat het spel stil
  if (dt > 0) simuleer(dt);
  world.update(dt, focus.set(dog.pos.x, 0, dog.pos.z));
  model.update(dt, dog);
  if (regenGain) regenGain.gain.value = stil ? 0 : 0.1 * world.st.regen;

  if (!foto.aan) {
    renderer.toneMappingExposure = belichting();
    // De camera kijkt mee met de bal of met Spot.
    const p = mode === 'vrij' ? ball.p : dog.pos;
    if (mode === 'hand') wil.set(0, 0.7, 0);
    else wil.set(p.x * 0.7, 0.5 + 0.3 * (mode === 'vrij' ? Math.min(ball.p.y, 8) : 0), p.z * 0.7);
    kijk.lerp(wil, 1 - Math.exp(-2.5 * echt));
    camera.lookAt(kijk);
    camera.updateMatrixWorld();
    hand.set(0, -0.33, -0.9).applyMatrix4(camera.matrixWorld);
  }
  foto.update();

  if (mode === 'hand') balMesh.position.copy(slepend ? sleepPos : hand);
  else if (mode === 'bek') model.mouth.getWorldPosition(balMesh.position);
  else {
    balMesh.position.copy(ball.p);
    const w = v3.copy(ball.w), hoek = w.length() * dt;
    if (hoek > 1e-6) balMesh.quaternion.premultiply(quat.setFromAxisAngle(w.normalize(), hoek));
  }
  doel.children.forEach((ring, i) => i < 3 && (ring.material.opacity = 0.8 - 0.5 * world.st.nacht)); // onverlichte ringen verblinden 's nachts
  for (const m of balMats) m.color.setScalar((m === balMats[0] ? 0.85 : 1) * (1 - 0.3 * world.st.nat)); // nat vilt is donkerder

  // Wijzer rond de bal als hij ver weg ligt en anders nauwelijks te zien is.
  const wijzer = $('balwijzer');
  const ver = mode === 'vrij' && !foto.aan && camera.position.distanceTo(balMesh.position) > 7;
  wijzer.hidden = !ver;
  if (ver) {
    v3.copy(balMesh.position).project(camera);
    wijzer.style.transform = `translate(${((v3.x + 1) / 2) * innerWidth}px, ${((1 - v3.y) / 2) * innerHeight}px)`;
  }
  render();
}
requestAnimationFrame(frame);

// Voor tests en nieuwsgierigen: de toestand van het spel in de console.
window.spot = { dog, world, gooi, ctx, camera, foto, doel, burst, get ball() { return ball; }, get mode() { return mode; } };
