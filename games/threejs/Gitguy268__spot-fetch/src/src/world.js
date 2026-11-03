// Het park: ondergronden, gras, lucht met dag-nachtcyclus, weer, en wat Spot kan afleiden.
import * as THREE from 'three';
import { Sky } from 'three/addons/objects/Sky.js';
import { mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';
import { WATER_Y } from './physics.js';
import { createDog } from './dogModel.js';
import { PASSANT } from './dogs.js';

export const GRENZEN = { x0: -30, x1: 30, z0: -34, z1: 15 }; // de heg
export const SPELER = { x: 0, z: 12 };
const VIJVER = { x: 11, z: -7, rx: 7, rz: 5 };
const ZAND = { x0: -17, x1: -8, z0: -7, z1: 1 };
const PAD = { z0: -19, z1: -16.5 };
const TERRAS = 2.4;
const GROND = { x0: -40, x1: 40, z0: -44, z1: 22 };
const DAG = 600; // seconden per etmaal

const rnd = (a, b) => a + Math.random() * (b - a);
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const smooth = (a, b, x) => { const t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); };
const vijverMaat = (x, z) => Math.hypot((x - VIJVER.x) / VIJVER.rx, (z - VIJVER.z) / VIJVER.rz);

// Ondergrond zonder weer. Sneeuw komt er in surfaceAt overheen.
export function zoneAt(x, z) {
  if (vijverMaat(x, z) < 1) return 'water';
  if (x > ZAND.x0 && x < ZAND.x1 && z > ZAND.z0 && z < ZAND.z1) return 'zand';
  if ((z > PAD.z0 && z < PAD.z1) || Math.hypot(x - SPELER.x, z - SPELER.z) < TERRAS) return 'beton';
  return 'gras';
}

// Schildert de zones op een canvas. laag: 'kleur', of een masker voor de sneeuw- of modderlaag.
function paint(W, laag) {
  const s = W / (GROND.x1 - GROND.x0), Hc = Math.round((GROND.z1 - GROND.z0) * s);
  const c = document.createElement('canvas');
  c.width = W; c.height = Hc;
  const g = c.getContext('2d');
  const X = (x) => (x - GROND.x0) * s, Z = (z) => (z - GROND.z0) * s;
  const kleur = laag === 'kleur';
  const vul = (gras, zand, beton, water) => {
    g.fillStyle = gras; g.fillRect(0, 0, W, Hc);
    if (kleur) {
      for (let i = 0; i < 700; i++) { // vlekkerig gazon
        g.fillStyle = ['#5d8f35', '#3f6b28', '#6b9440', '#527c2b'][i % 4];
        g.globalAlpha = 0.12;
        g.beginPath(); g.arc(Math.random() * W, Math.random() * Hc, rnd(15, 90), 0, 7); g.fill();
      }
      g.globalAlpha = 1;
    }
    g.fillStyle = zand; g.fillRect(X(ZAND.x0), Z(ZAND.z0), (ZAND.x1 - ZAND.x0) * s, (ZAND.z1 - ZAND.z0) * s);
    g.fillStyle = beton; g.fillRect(0, Z(PAD.z0), W, (PAD.z1 - PAD.z0) * s);
    g.beginPath(); g.arc(X(SPELER.x), Z(SPELER.z), TERRAS * s, 0, 7); g.fill();
    g.fillStyle = water;
    g.beginPath(); g.ellipse(X(VIJVER.x), Z(VIJVER.z), VIJVER.rx * 1.06 * s, VIJVER.rz * 1.06 * s, 0, 0, 7); g.fill();
  };
  if (laag === 'sneeuw') vul('#fff', '#fff', '#000', '#000');
  else if (laag === 'modder') vul('#fff', '#000', '#000', '#000');
  else {
    vul('#4c7a2e', '#d3bd89', '#a8a7a0', '#3d3626');
    g.strokeStyle = 'rgba(50,50,50,0.35)'; g.lineWidth = 2; // voegen in het pad
    for (let x = GROND.x0; x < GROND.x1; x += 1.5) g.strokeRect(X(x), Z(PAD.z0), 1.5 * s, (PAD.z1 - PAD.z0) * s);
    for (let i = 0; i < 70000; i++) { // korrel
      g.fillStyle = i % 2 ? 'rgba(255,255,235,0.07)' : 'rgba(0,0,0,0.08)';
      g.fillRect(Math.random() * W, Math.random() * Hc, 2, 2);
    }
  }
  const t = new THREE.CanvasTexture(c);
  if (kleur) { t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 8; }
  return t;
}

// Betegelbare rimpel-normalen voor het water, uit een som van sinussen.
function rimpels(n = 128) {
  const golven = Array.from({ length: 7 }, () => [Math.round(rnd(-5, 5)), Math.round(rnd(1, 6)), rnd(0, 7), rnd(0.4, 1)]);
  const h = (x, y) => golven.reduce((s, [fx, fy, p, a]) => s + a * Math.sin(((fx * x + fy * y) / n) * Math.PI * 2 + p), 0);
  const data = new Uint8Array(n * n * 4);
  for (let y = 0; y < n; y++)
    for (let x = 0; x < n; x++) {
      const v = new THREE.Vector3(h(x - 1, y) - h(x + 1, y), h(x, y - 1) - h(x, y + 1), 6).normalize();
      data.set([v.x * 127 + 128, v.y * 127 + 128, v.z * 127 + 128, 255], (y * n + x) * 4);
    }
  const t = new THREE.DataTexture(data, n, n);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.repeat.set(5, 4);
  t.generateMipmaps = true; // zonder mipmaps geeft het water in de verte moiré
  t.minFilter = THREE.LinearMipmapLinearFilter;
  t.magFilter = THREE.LinearFilter;
  t.needsUpdate = true;
  return t;
}

// Graspollen als instanties; wind, sneeuw en modder in de shader.
function gras(aantal, uni) {
  const pos = [], col = [], idx = [];
  for (let b = 0; b < 3; b++) {
    const a = b * 2.1 + 0.3, ca = Math.cos(a), sa = Math.sin(a), w = 0.011, base = pos.length / 3;
    for (const [dwars, h, uit] of [[-w, 0, 0], [w, 0, 0], [-w * 0.7, 0.5, 0.012], [w * 0.7, 0.5, 0.012], [0, 1, 0.035]]) {
      pos.push(ca * dwars + sa * uit, h, -sa * dwars + ca * uit);
      col.push(0.22 + 0.4 * h, 0.36 + 0.5 * h, 0.12 + 0.22 * h);
    }
    idx.push(base, base + 1, base + 2, base + 1, base + 3, base + 2, base + 2, base + 3, base + 4);
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.setAttribute('normal', new THREE.Float32BufferAttribute(pos.map((_, i) => (i % 3 === 1 ? 1 : 0)), 3)); // omhoog: belicht als de grond
  geo.setIndex(idx);

  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1, side: THREE.DoubleSide });
  mat.onBeforeCompile = (sh) => {
    Object.assign(sh.uniforms, uni);
    sh.vertexShader = sh.vertexShader
      .replace('#include <common>', '#include <common>\nuniform float uTijd, uSneeuw, uNat;\nvarying float vH;')
      .replace('#include <begin_vertex>', `vec3 transformed = vec3(position);
        vH = position.y;
        #ifdef USE_INSTANCING
          vec2 ip = instanceMatrix[3].xz;
          float wind = sin(uTijd * 1.6 + ip.x * 0.4 + ip.y * 0.3) + 0.5 * sin(uTijd * 3.7 + ip.x * 1.7);
          transformed.xz += vec2(0.02, 0.012) * wind * vH * vH;
        #endif
        transformed.y *= 1.0 - 0.6 * uSneeuw - 0.25 * uNat;`);
    sh.fragmentShader = sh.fragmentShader
      .replace('#include <common>', '#include <common>\nuniform float uSneeuw, uNat;\nvarying float vH;')
      .replace('#include <color_fragment>', `#include <color_fragment>
        diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.2, 0.15, 0.08), uNat * 0.6 * (1.0 - vH));
        diffuseColor.rgb = mix(diffuseColor.rgb, vec3(0.93), uSneeuw * 0.92);`);
  };

  const mesh = new THREE.InstancedMesh(geo, mat, aantal);
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), p = new THREE.Vector3(), sc = new THREE.Vector3(), up = new THREE.Vector3(0, 1, 0);
  const kleur = new THREE.Color();
  for (let i = 0; i < aantal; ) {
    const x = rnd(GRENZEN.x0, GRENZEN.x1), z = rnd(GRENZEN.z0, GRENZEN.z1 + 1);
    // Dicht bij de speler veel pollen, verderop minder: daar ziet het oog het verschil niet.
    if (zoneAt(x, z) !== 'gras' || Math.random() > Math.max(0.07, 1 / (1 + ((x * x + (z - 13) ** 2) / 90)))) continue;
    const k = rnd(0.8, 1.5);
    m.compose(p.set(x, 0, z), q.setFromAxisAngle(up, rnd(0, 7)), sc.set(k, rnd(0.04, 0.09), k));
    mesh.setMatrixAt(i, m);
    mesh.setColorAt(i, kleur.setHSL(rnd(0.23, 0.3), rnd(0.45, 0.65), rnd(0.36, 0.5)));
    i++;
  }
  mesh.receiveShadow = true;
  mesh.frustumCulled = false;
  return mesh;
}

// Bomen binnen de heg [x, z, schaal]. De bal en Spot botsen op de stammen.
const BOMEN = [[-20, -10, 1], [2, -26, 1.1], [-25, -27, 1.2], [22, -27, 1], [26, -2, 0.9], [-26, 8, 0.9], [14, -23, 0.8]];
export const OBSTAKELS = BOMEN.map(([x, z, s]) => ({ x, z, r: 0.27 * s, h: 3.4 * s }));

function bomen(scene) {
  const plek = [...BOMEN];
  for (let i = 0; i < 46; i++) {
    const a = (i / 46) * Math.PI * 2, r = rnd(44, 70);
    plek.push([Math.cos(a) * r, Math.sin(a) * r - 10, rnd(0.9, 1.7)]);
  }
  // Punten samenvoegen geeft gladde normalen in plaats van facetten.
  let kroonGeo = new THREE.IcosahedronGeometry(1, 3);
  kroonGeo.deleteAttribute('normal');
  kroonGeo.deleteAttribute('uv');
  kroonGeo = mergeVertices(kroonGeo);
  const kp = kroonGeo.attributes.position;
  for (let i = 0; i < kp.count; i++) { // knobbelig: zelfde ruis voor samenvallende punten
    const x = kp.getX(i), y = kp.getY(i), z = kp.getZ(i);
    const n = 1 + 0.13 * Math.sin(x * 7 + y * 5) * Math.cos(z * 6 + y * 3) + 0.05 * Math.sin(x * 17 + z * 13 + y * 19);
    kp.setXYZ(i, x * n, y * n * 0.85, z * n);
  }
  kroonGeo.computeVertexNormals();
  const stam = new THREE.InstancedMesh(
    new THREE.CylinderGeometry(0.2, 0.32, 1, 8).translate(0, 0.5, 0),
    new THREE.MeshStandardMaterial({ color: 0x4a3626, roughness: 1 }), plek.length);
  const kroon = new THREE.InstancedMesh(kroonGeo, new THREE.MeshStandardMaterial({ roughness: 1 }), plek.length * 6);
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), p = new THREE.Vector3(), sc = new THREE.Vector3(), c = new THREE.Color();
  plek.forEach(([x, z, s], i) => {
    stam.setMatrixAt(i, m.compose(p.set(x, 0, z), q, sc.set(s, 3.4 * s, s)));
    for (let b = 0; b < 6; b++) {
      const r = rnd(1.3, 2) * s;
      kroon.setMatrixAt(i * 6 + b, m.compose(p.set(x + rnd(-1.3, 1.3) * s, (3.3 + rnd(0, 2.2)) * s, z + rnd(-1.3, 1.3) * s), q, sc.set(r, r, r)));
      kroon.setColorAt(i * 6 + b, c.setHSL(rnd(0.24, 0.32), rnd(0.4, 0.6), rnd(0.2, 0.3)));
    }
  });
  stam.castShadow = kroon.castShadow = true;
  scene.add(stam, kroon);
}

function meubels(scene) {
  const heg = new THREE.MeshStandardMaterial({ color: 0x2c5425, roughness: 1 });
  const doos = (mat, w, h, d, x, y, z) => {
    const b = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
    b.position.set(x, y, z);
    b.castShadow = b.receiveShadow = true;
    scene.add(b);
  };
  const g = GRENZEN, bx = g.x1 - g.x0 + 3, bz = g.z1 - g.z0 + 3, mz = (g.z0 + g.z1) / 2;
  doos(heg, bx, 1.3, 1.2, 0, 0.65, g.z0 - 0.9);
  doos(heg, 1.2, 1.3, bz, g.x0 - 0.9, 0.65, mz);
  doos(heg, 1.2, 1.3, bz, g.x1 + 0.9, 0.65, mz);
}

function bak(scene, x, z, kleur, inhoud) {
  const g = new THREE.Group();
  const rand = new THREE.Mesh(
    new THREE.CylinderGeometry(0.13, 0.11, 0.07, 24, 1, true),
    new THREE.MeshStandardMaterial({ color: kleur, roughness: 0.3, metalness: 0.6, side: THREE.DoubleSide }));
  rand.position.y = 0.035;
  rand.castShadow = true;
  const vulling = new THREE.Mesh(new THREE.CircleGeometry(0.122, 24).rotateX(-Math.PI / 2), inhoud);
  g.add(rand, vulling);
  g.position.set(x, 0, z);
  scene.add(g);
  return { x, z, vol: 0, vulling, group: g };
}

function eekhoorn() {
  const mat = new THREE.MeshStandardMaterial({ color: 0x9a4a1e, roughness: 0.9 });
  const g = new THREE.Group();
  const bol = (r, x, y, z, sx = 1, sy = 1, sz = 1) => {
    const m = new THREE.Mesh(new THREE.SphereGeometry(r, 10, 8), mat);
    m.position.set(x, y, z); m.scale.set(sx, sy, sz); m.castShadow = true;
    g.add(m);
  };
  bol(0.07, 0, 0.09, 0, 1, 1, 1.6); // lijf
  bol(0.045, 0, 0.14, 0.12); // kop
  bol(0.06, 0, 0.2, -0.14, 0.8, 1.9, 0.9); // pluimstaart
  g.visible = false;
  return g;
}

export function createWorld(scene, renderer, q) {
  const st = { tijd: 10, weer: 'helder', vast: false, regen: 0, sneeuwval: 0, nat: 0, sneeuw: 0, nacht: 0 };
  const events = [];
  const uni = { uTijd: { value: 0 }, uSneeuw: { value: 0 }, uNat: { value: 0 } };

  // Grond, met de vijver als kuil
  const geo = new THREE.PlaneGeometry(GROND.x1 - GROND.x0, GROND.z1 - GROND.z0, 160, 132).rotateX(-Math.PI / 2);
  geo.translate((GROND.x0 + GROND.x1) / 2, 0, (GROND.z0 + GROND.z1) / 2);
  const gp = geo.attributes.position;
  for (let i = 0; i < gp.count; i++) gp.setY(i, -0.75 * (1 - smooth(0.55, 1.08, vijverMaat(gp.getX(i), gp.getZ(i)))));
  geo.computeVertexNormals();
  const grondMat = new THREE.MeshStandardMaterial({ map: paint(2048, 'kleur'), roughness: 1 });
  const grond = new THREE.Mesh(geo, grondMat);
  grond.receiveShadow = true;
  const laag = (kleur, masker, offset) => {
    const m = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
      color: kleur, alphaMap: paint(512, masker), transparent: true, opacity: 0, roughness: 0.9,
      depthWrite: false, polygonOffset: true, polygonOffsetFactor: offset, polygonOffsetUnits: offset,
    }));
    m.receiveShadow = true;
    return m;
  };
  const modder = laag(0x3a2a17, 'modder', -1), sneeuwdek = laag(0xf4f7fb, 'sneeuw', -2);
  // Een ring, geen schijf: anders ligt hij als deksel over de vijverkuil.
  const verte = new THREE.Mesh(new THREE.RingGeometry(32, 700, 48).rotateX(-Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0x446f2b, roughness: 1 }));
  verte.position.set(0, -0.06, (GROND.z0 + GROND.z1) / 2);
  scene.add(grond, modder, sneeuwdek, verte);

  const waterMap = rimpels();
  const water = new THREE.Mesh(
    new THREE.CircleGeometry(1, 64).rotateX(-Math.PI / 2),
    new THREE.MeshPhysicalMaterial({ color: 0x1f3d3a, roughness: 0.06, transparent: true, opacity: 0.86, normalMap: waterMap, normalScale: new THREE.Vector2(0.3, 0.3) }));
  water.scale.set(VIJVER.rx * 1.04, 1, VIJVER.rz * 1.04);
  water.position.set(VIJVER.x, WATER_Y, VIJVER.z);
  scene.add(water);

  scene.add(gras(q.gras, uni));
  bomen(scene);
  meubels(scene);
  const bowls = {
    voer: bak(scene, -2.2, 9.2, 0xb8372c, new THREE.MeshStandardMaterial({ color: 0x6b4423, roughness: 1 })),
    water: bak(scene, -3, 9.5, 0xb9bec4, new THREE.MeshPhysicalMaterial({ color: 0x3f7fb0, roughness: 0.05 })),
  };

  // Lucht en licht
  const sky = new Sky();
  sky.scale.setScalar(1000);
  scene.add(sky);
  const U = sky.material.uniforms;
  const pmrem = new THREE.PMREMGenerator(renderer);
  const luchtScene = new THREE.Scene();
  luchtScene.add(sky.clone());
  let env = null, envT = 0;
  const zon = new THREE.DirectionalLight(0xffffff, 3);
  zon.castShadow = true;
  zon.shadow.mapSize.setScalar(q.schaduw);
  Object.assign(zon.shadow.camera, { left: -16, right: 16, top: 16, bottom: -16, near: 1, far: 140 });
  zon.shadow.bias = -0.0004;
  zon.shadow.normalBias = 0.03;
  const hemel = new THREE.HemisphereLight(0xbcd3e8, 0x4a5a2a, 0.6);
  scene.add(zon, zon.target, hemel);
  scene.fog = new THREE.Fog(0xbcd3e8, 30, 160);
  scene.environmentIntensity = 0.3; // de lucht is als lichtbron veel feller dan als achtergrond
  const sterPos = [];
  for (let i = 0; i < 900; i++) {
    const v = new THREE.Vector3().randomDirection();
    sterPos.push(v.x * 450, Math.abs(v.y) * 450 + 5, v.z * 450);
  }
  const sterren = new THREE.Points(
    new THREE.BufferGeometry().setAttribute('position', new THREE.Float32BufferAttribute(sterPos, 3)),
    new THREE.PointsMaterial({ color: 0xffffff, size: 1.6, sizeAttenuation: false, transparent: true, opacity: 0, fog: false, depthWrite: false }));
  const maan = new THREE.Mesh(new THREE.SphereGeometry(9, 20, 14), new THREE.MeshBasicMaterial({ color: 0xe6ecff, fog: false, transparent: true }));
  scene.add(sterren, maan);

  // Neerslag: één wolk zaadpunten, als strepen (regen) en als vlokken (sneeuw)
  const N = q.neerslag, zaad = new Float32Array(N * 6), eind = new Float32Array(N * 2);
  for (let i = 0; i < N; i++) {
    const x = rnd(-28, 28), y = rnd(0, 16), z = rnd(-30, 16);
    zaad.set([x, y, z, x, y, z], i * 6);
    eind[i * 2 + 1] = 1;
  }
  const neerslagGeo = new THREE.BufferGeometry();
  neerslagGeo.setAttribute('position', new THREE.BufferAttribute(zaad, 3));
  neerslagGeo.setAttribute('eind', new THREE.BufferAttribute(eind, 1));
  const nUni = { uTijd: uni.uTijd, uSterkte: { value: 0 } };
  const regen = new THREE.LineSegments(neerslagGeo, new THREE.ShaderMaterial({
    uniforms: nUni, transparent: true, depthWrite: false,
    vertexShader: `attribute float eind; uniform float uTijd; varying float vA;
      void main() { vec3 p = position;
        p.y = mod(p.y - uTijd * (9.0 + 4.0 * fract(p.x * 13.7)), 16.0) + eind * 0.35; p.x += eind * 0.04;
        vA = 1.0 - eind * 0.7; gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0); }`,
    fragmentShader: 'uniform float uSterkte; varying float vA; void main() { gl_FragColor = vec4(0.75, 0.8, 0.9, 0.45 * uSterkte * vA); }',
  }));
  const sUni = { uTijd: uni.uTijd, uSterkte: { value: 0 } };
  const vlokken = new THREE.Points(neerslagGeo, new THREE.ShaderMaterial({
    uniforms: sUni, transparent: true, depthWrite: false,
    vertexShader: `uniform float uTijd;
      void main() { vec3 p = position;
        p.y = mod(p.y - uTijd * (1.0 + fract(p.z * 7.3)), 16.0); p.x += 0.4 * sin(uTijd * 0.8 + p.z * 3.0);
        vec4 mv = modelViewMatrix * vec4(p, 1.0); gl_PointSize = clamp(90.0 / -mv.z, 1.5, 14.0); gl_Position = projectionMatrix * mv; }`,
    fragmentShader: `uniform float uSterkte;
      void main() { float d = length(gl_PointCoord - 0.5); if (d > 0.5) discard; gl_FragColor = vec4(1.0, 1.0, 1.0, uSterkte * (1.0 - 2.0 * d)); }`,
  }));
  regen.frustumCulled = vlokken.frustumCulled = false;
  scene.add(regen, vlokken);

  // Afleiding: een eekhoorn tussen twee bomen, een hond over het pad, losse geluiden
  const eek = { mesh: eekhoorn(), t: rnd(25, 50), s: -1, pos: { x: 0, z: 0 }, van: { x: -20, z: -10 }, naar: { x: 2, z: -26 }, meld: 0 };
  scene.add(eek.mesh);
  const bo = { model: createDog(PASSANT, Math.ceil(q.lagen / 2)), t: rnd(45, 90), loopt: false, meld: 0,
    d: { pos: { x: -40, z: -17.7 }, heading: Math.PI / 2, speed: 0, pose: 'sta', swim: false, look: null, headDown: 0, sniff: false, pant: 0.5, wag: 0.6, alert: 0, hasBall: false } };
  bo.model.group.visible = false;
  scene.add(bo.model.group);
  let geluidT = rnd(15, 35);

  function afleiding(dt) {
    eek.t -= dt;
    if (eek.s < 0 && eek.t <= 0) {
      eek.s = 0; eek.meld = 0;
      [eek.van, eek.naar] = [eek.naar, eek.van];
      eek.mesh.visible = true;
      eek.mesh.rotation.y = Math.atan2(eek.naar.x - eek.van.x, eek.naar.z - eek.van.z);
    }
    if (eek.s >= 0) {
      const lang = Math.hypot(eek.naar.x - eek.van.x, eek.naar.z - eek.van.z);
      eek.s += (dt * 5.5) / lang;
      const k = Math.min(eek.s, 1), klim = Math.max(0, eek.s - 1) * lang; // na aankomst de boom in
      eek.pos.x = eek.van.x + (eek.naar.x - eek.van.x) * k;
      eek.pos.z = eek.van.z + (eek.naar.z - eek.van.z) * k;
      eek.mesh.position.set(eek.pos.x, klim + 0.07 * Math.abs(Math.sin(eek.s * lang * 2.2)), eek.pos.z);
      eek.mesh.rotation.x = klim > 0 ? -Math.PI / 2 : 0;
      if ((eek.meld -= dt) <= 0 && k < 1) { eek.meld = 2; events.push({ type: 'eekhoorn', pos: eek.pos, sterkte: 0.8 }); }
      if (klim > 3.5) { eek.s = -1; eek.t = rnd(50, 110); eek.mesh.visible = false; }
    }

    bo.t -= dt;
    if (!bo.loopt && bo.t <= 0) {
      bo.loopt = true;
      const naarRechts = Math.random() < 0.5;
      bo.d.pos.x = naarRechts ? -31 : 31;
      bo.d.heading = naarRechts ? Math.PI / 2 : -Math.PI / 2;
      bo.d.speed = 2.4;
      bo.model.group.visible = true;
    }
    if (bo.loopt) {
      bo.d.pos.x += Math.sin(bo.d.heading) * bo.d.speed * dt;
      bo.model.update(dt, bo.d);
      if ((bo.meld -= dt) <= 0) { bo.meld = 3; events.push({ type: 'hond', pos: bo.d.pos, sterkte: 0.7 }); }
      if (Math.abs(bo.d.pos.x) > 32) { bo.loopt = false; bo.t = rnd(70, 140); bo.model.group.visible = false; }
    }

    if ((geluidT -= dt) <= 0) {
      geluidT = rnd(25, 60);
      events.push({ type: 'geluid', klank: Math.random() < 0.6 ? 'vogel' : 'blaf', pos: { x: rnd(-28, 28), z: rnd(-32, -5) }, sterkte: 0.35 });
    }
  }

  const zonRicht = new THREE.Vector3(), kleur = new THREE.Color();
  const DAGLUCHT = new THREE.Color(0xbcd3e8), SCHEMER = new THREE.Color(0xd99a6c), NACHT = new THREE.Color(0x070b16), GRIJS = new THREE.Color(0x8a9199), MAANLICHT = new THREE.Color(0x5f74b8);
  let weerT = rnd(70, 150);

  function setWeer(weer, meteen) {
    st.weer = weer;
    if (meteen) {
      st.regen = weer === 'regen' ? 1 : 0;
      st.sneeuwval = weer === 'sneeuw' ? 1 : 0;
      st.nat = st.regen;
      st.sneeuw = st.sneeuwval;
    }
  }

  // focus: het punt waar de schaduwkaart omheen ligt (Spot)
  function update(dt, focus) {
    uni.uTijd.value += dt;
    if (!st.vast) {
      st.tijd = (st.tijd + (dt * 24) / DAG) % 24;
      if ((weerT -= dt) <= 0) {
        weerT = rnd(70, 150);
        const r = Math.random();
        setWeer(r < 0.5 ? 'helder' : r < 0.78 ? 'regen' : 'sneeuw');
      }
    }
    // Weer loopt geleidelijk op en af; regen laat sneeuw sneller smelten.
    st.regen += clamp((st.weer === 'regen' ? 1 : 0) - st.regen, -dt / 4, dt / 4);
    st.sneeuwval += clamp((st.weer === 'sneeuw' ? 1 : 0) - st.sneeuwval, -dt / 4, dt / 4);
    st.nat = clamp(st.nat + (st.regen > 0.3 ? dt / 15 : -dt / 45), 0, 1);
    st.sneeuw = clamp(st.sneeuw + (st.sneeuwval > 0.3 ? dt / 20 : -dt / (st.regen > 0.3 ? 12 : 40)), 0, 1);
    const bewolkt = Math.max(st.regen, st.sneeuwval);

    // Zon: komt links op, staat 's middags achter de speler, gaat rechts onder.
    const a = ((st.tijd - 6) / 12) * Math.PI;
    zonRicht.set(-Math.cos(a), Math.sin(a) * 0.9, 0.45).normalize();
    const hoog = zonRicht.y;
    st.nacht = smooth(0.06, -0.14, hoog);
    const schemer = clamp(1 - Math.abs(hoog) / 0.3, 0, 1) * (1 - bewolkt) * (1 - st.nacht);
    U.sunPosition.value.copy(zonRicht);
    U.turbidity.value = 2.5 + 8 * bewolkt;
    U.rayleigh.value = 1.3 - 0.6 * bewolkt + 1.5 * schemer;
    U.cloudCoverage.value = 0.3 + 0.7 * bewolkt;
    U.cloudDensity.value = 0.4 + 0.5 * bewolkt;
    U.time.value = uni.uTijd.value * 40;

    if (hoog > -0.04) { // zonlicht
      zon.position.copy(zonRicht).multiplyScalar(60).add(focus);
      zon.intensity = 3.4 * smooth(-0.04, 0.25, hoog) * (1 - 0.7 * bewolkt);
      zon.color.setHex(0xff8c42).lerp(kleur.setHex(0xfff3df), smooth(0, 0.45, hoog));
    } else { // maanlicht van de andere kant
      zon.position.set(-zonRicht.x, Math.max(0.35, -zonRicht.y), zonRicht.z).multiplyScalar(60).add(focus);
      zon.intensity = 1.1 * smooth(-0.04, -0.1, hoog) * (1 - 0.6 * bewolkt);
      zon.color.setHex(0x8fa8ff);
    }
    zon.target.position.copy(focus);
    maan.position.set(-zonRicht.x, Math.max(0.35, -zonRicht.y), zonRicht.z).normalize().multiplyScalar(430);
    maan.material.opacity = st.nacht * (1 - bewolkt);
    sterren.material.opacity = st.nacht * (1 - bewolkt);
    kleur.copy(DAGLUCHT).lerp(SCHEMER, schemer * 0.7).lerp(GRIJS, bewolkt * 0.8).lerp(NACHT, st.nacht);
    scene.fog.color.copy(kleur);
    scene.fog.near = 30 - 18 * bewolkt;
    scene.fog.far = 160 - 95 * bewolkt;
    hemel.color.copy(kleur).lerp(MAANLICHT, st.nacht);
    hemel.intensity = 0.45 + 0.15 * st.nacht; // 's nachts valt het omgevingslicht van de lucht weg
    // De lucht als omgevingslicht en spiegeling; af en toe verversen is genoeg.
    if ((envT -= dt) <= 0 || !env) {
      envT = q.envElke;
      const oud = env;
      env = pmrem.fromScene(luchtScene, 0, 1, 2000);
      scene.environment = env.texture;
      oud?.dispose();
    }

    nUni.uSterkte.value = st.regen;
    sUni.uSterkte.value = st.sneeuwval;
    regen.visible = st.regen > 0.01;
    vlokken.visible = st.sneeuwval > 0.01;
    uni.uSneeuw.value = sneeuwdek.material.opacity = st.sneeuw;
    uni.uNat.value = st.nat;
    modder.material.opacity = st.nat * 0.5 * (1 - st.sneeuw);
    grondMat.roughness = 1 - 0.5 * st.nat;
    grondMat.color.setScalar(1 - 0.25 * st.nat);
    waterMap.offset.x += dt * 0.012;
    waterMap.offset.y += dt * 0.02;
    for (const b of Object.values(bowls)) {
      b.vulling.visible = b.vol > 0.02;
      b.vulling.position.y = 0.012 + 0.045 * b.vol;
    }
    if (dt > 0) afleiding(dt);
  }

  return {
    st, events, bowls, update, setWeer,
    vijverRand: { x: VIJVER.x - VIJVER.rx * 0.75, z: VIJVER.z + VIJVER.rz * 0.75 },
    // Sneeuw dekt gras en zand af; het pad en het water blijven vrij.
    surfaceAt(x, z) {
      const zone = zoneAt(x, z);
      return st.sneeuw > 0.5 && (zone === 'gras' || zone === 'zand') ? 'sneeuw' : zone;
    },
  };
}
